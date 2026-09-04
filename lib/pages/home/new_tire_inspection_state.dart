import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/send_tire_inspection.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class NewTireInspectionState extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeState homeState = Get.find<HomeState>();

  var tasks = <Map<String, dynamic>>[].obs;
  var filteredTasks = <Map<String, dynamic>>[].obs;

  static const int _pageSize = 50;
  static const int _sendBatchSize = 50;
  static const Duration _autoRefreshCooldown = Duration(seconds: 30);

  final totalTasks = 0.obs;
  final totalFilteredTasks = 0.obs;
  final isLoadingMore = false.obs;
  final hasMoreTasks = true.obs;
  final isShowingCachedData = false.obs;

  DocumentSnapshot<Map<String, dynamic>>? _lastTaskDocument;
  Timer? _searchDebounce;
  int _loadRequestId = 0;
  bool _isTotalCountKnown = false;
  bool _usesDefaultTodayFilter = true;
  DateTime? _lastServerRefreshAt;

  var isLoading = false.obs;
  var isExporting = false.obs;
  var isSending = false.obs;

  var exportProgress = 0.0.obs;
  var sendTireInspectionProgress = 0.0.obs;

  final selectedDateRange = Rxn<DateTimeRange>(_todayDateRange());
  var searchQuery = ''.obs;

  static DateTimeRange _todayDateRange() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTimeRange(start: today, end: today);
  }

  @override
  void onInit() {
    super.onInit();
    // Jika currentSiteId sudah ada, langsung muat data hari ini.
    if (homeState.currentSiteId.isNotEmpty) {
      reloadForActiveFilters();
    }

    // Listen perubahan currentSiteId (jika belum ready saat onInit)
    ever(homeState.currentSiteIdRx, (String siteId) {
      if (siteId.isNotEmpty) {
        reloadForActiveFilters();
      }
    });
  }

  Future<void> fetchTasks() async {
    final requestId = ++_loadRequestId;
    try {
      isLoading.value = true;
      final currentIdSite = homeState.currentSiteId;

      log('=== FETCH tire_inspection ===');
      log('currentIdSite: $currentIdSite');

      tasks.clear();
      filteredTasks.clear();
      totalTasks.value = 0;
      totalFilteredTasks.value = 0;
      _lastTaskDocument = null;
      hasMoreTasks.value = true;

      final siteQuery = _siteQuery(currentIdSite);

      // Count aggregation hanya mengembalikan angka total. Isi seluruh
      // dokumen tidak ikut dimuat ke heap Android.
      int? serverTotal;
      try {
        final countSnapshot = await siteQuery.count().get();
        serverTotal = countSnapshot.count;
      } catch (e) {
        // List masih dapat memakai cache Firestore ketika aggregation count
        // tidak tersedia, misalnya saat perangkat sedang offline.
        log('Error counting tire_inspection: $e');
      }
      if (requestId != _loadRequestId) return;

      final querySnapshot = await siteQuery.limit(_pageSize).get();
      if (requestId != _loadRequestId) return;

      totalTasks.value = serverTotal ?? querySnapshot.docs.length;
      totalFilteredTasks.value = totalTasks.value;
      _isTotalCountKnown = serverTotal != null;

      log(
        'Filtered by id_site=$currentIdSite: '
        '${querySnapshot.docs.length}/$totalTasks docs',
      );

      final result = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['doc_id'] = doc.id;
        return data;
      }).toList();

      result.sort((a, b) {
        final dateA =
            DateTime.tryParse(a['hari']?.toString() ?? '') ?? DateTime(2000);
        final dateB =
            DateTime.tryParse(b['hari']?.toString() ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      tasks.assignAll(result);
      if (querySnapshot.docs.isNotEmpty) {
        _lastTaskDocument = querySnapshot.docs.last;
      }
      hasMoreTasks.value = querySnapshot.docs.length == _pageSize &&
          (!_isTotalCountKnown || tasks.length < totalTasks.value);
      applyFilters();
      _lastServerRefreshAt = DateTime.now();
    } catch (e) {
      log('Error fetching tire_inspection: $e');
    } finally {
      if (requestId == _loadRequestId) {
        isLoading.value = false;
      }
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 400),
      applyFilters,
    );
  }

  /// Memuat ulang ketika pengguna benar-benar kembali dari Home ke Inspection.
  /// Refresh otomatis dibatasi agar perpindahan tab berulang tidak membuat
  /// pembacaan Firestore yang tidak perlu. Refresh manual tetap tidak dibatasi.
  Future<void> refreshOnOpen() async {
    if (isLoading.value ||
        isLoadingMore.value ||
        isSending.value ||
        isExporting.value) {
      return;
    }

    final didRollToToday = _rollDefaultFilterToToday();
    final lastRefreshAt = _lastServerRefreshAt;
    if (!didRollToToday &&
        lastRefreshAt != null &&
        DateTime.now().difference(lastRefreshAt) < _autoRefreshCooldown) {
      return;
    }

    await reloadForActiveFilters();
  }

  Future<void> selectDateRange(DateTimeRange range) async {
    _usesDefaultTodayFilter = false;
    selectedDateRange.value = range;
    await reloadForActiveFilters();
  }

  bool _rollDefaultFilterToToday() {
    if (!_usesDefaultTodayFilter) return false;

    final currentRange = selectedDateRange.value;
    final todayRange = _todayDateRange();
    final alreadyToday = currentRange != null &&
        _isSameDay(currentRange.start, todayRange.start) &&
        _isSameDay(currentRange.end, todayRange.end);
    if (alreadyToday) return false;

    selectedDateRange.value = todayRange;
    return true;
  }

  Future<void> reloadForActiveFilters() async {
    if (searchQuery.value.trim().isEmpty && selectedDateRange.value == null) {
      await fetchTasks();
      return;
    }

    final requestId = ++_loadRequestId;
    try {
      isLoading.value = true;
      tasks.clear();
      filteredTasks.clear();
      hasMoreTasks.value = false;
      _lastTaskDocument = null;

      // Simpan semua data dalam rentang tanggal yang aktif. Search diterapkan
      // secara lokal agar mengetik di kolom pencarian tidak membaca Firestore
      // lagi pada setiap debounce.
      List<Map<String, dynamic>>? dateScopedTasks;
      var loadedFromCache = false;

      try {
        dateScopedTasks = await _loadAllDateScopedTasks(
          requestId: requestId,
          source: Source.server,
        );
      } catch (error, stackTrace) {
        log(
          'Server tire_inspection tidak tersedia, mencoba cache: $error',
          stackTrace: stackTrace,
        );

        if (requestId != _loadRequestId) return;

        loadedFromCache = true;
        dateScopedTasks = await _loadAllDateScopedTasks(
          requestId: requestId,
          source: Source.cache,
        );
      }

      if (requestId != _loadRequestId || dateScopedTasks == null) return;

      dateScopedTasks.sort((a, b) {
        final dateA = _taskDateTime(a);
        final dateB = _taskDateTime(b);
        return dateB.compareTo(dateA);
      });

      tasks.assignAll(dateScopedTasks);
      totalTasks.value = dateScopedTasks.length;
      isShowingCachedData.value = loadedFromCache;
      applyFilters();
      _lastServerRefreshAt = DateTime.now();
    } catch (e, stackTrace) {
      log('Error filtering tire_inspection: $e', stackTrace: stackTrace);
    } finally {
      if (requestId == _loadRequestId) {
        isLoading.value = false;
      }
    }
  }

  Future<List<Map<String, dynamic>>?> _loadAllDateScopedTasks({
    required int requestId,
    required Source source,
  }) async {
    final result = <Map<String, dynamic>>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;
    var page = 0;

    while (requestId == _loadRequestId) {
      Query<Map<String, dynamic>> query =
          _dateScopedSiteQuery(homeState.currentSiteId).limit(_pageSize);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get(GetOptions(source: source));
      if (requestId != _loadRequestId) return null;

      page++;
      log(
        'Tire inspection page $page '
        'site=${homeState.currentSiteId} '
        'source=${source.name} docs=${snapshot.docs.length}',
      );

      if (snapshot.docs.isEmpty) break;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (_taskMatchesSelectedDate(data)) {
          data['doc_id'] = doc.id;
          result.add(data);
        }
      }

      cursor = snapshot.docs.last;
      if (snapshot.docs.length < _pageSize) break;
    }

    return requestId == _loadRequestId ? result : null;
  }

  Query<Map<String, dynamic>> _siteQuery(String siteId) {
    return firestore
        .collection('tire_inspection')
        .where('id_site', isEqualTo: siteId);
  }

  Query<Map<String, dynamic>> _dateScopedSiteQuery(String siteId) {
    final query = _siteQuery(siteId);
    final range = selectedDateRange.value;
    if (range == null || !_isSameDay(range.start, range.end)) {
      return query;
    }

    return query.where('hari', isEqualTo: _dateKey(range.start));
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> loadMoreTasks() async {
    if (isLoading.value ||
        isLoadingMore.value ||
        !hasMoreTasks.value ||
        _lastTaskDocument == null) {
      return;
    }

    try {
      isLoadingMore.value = true;

      final snapshot = await _siteQuery(homeState.currentSiteId)
          .startAfterDocument(_lastTaskDocument!)
          .limit(_pageSize)
          .get();

      if (snapshot.docs.isEmpty) {
        hasMoreTasks.value = false;
        return;
      }

      final nextTasks = snapshot.docs.map((doc) {
        final data = doc.data();
        data['doc_id'] = doc.id;
        return data;
      });

      tasks.addAll(nextTasks);
      if (totalTasks.value < tasks.length) {
        totalTasks.value = tasks.length;
        totalFilteredTasks.value = totalTasks.value;
      }
      _lastTaskDocument = snapshot.docs.last;
      hasMoreTasks.value = snapshot.docs.length == _pageSize &&
          (!_isTotalCountKnown || tasks.length < totalTasks.value);
      applyFilters();
    } catch (e, stackTrace) {
      log('Error loading more tire_inspection: $e', stackTrace: stackTrace);
    } finally {
      isLoadingMore.value = false;
    }
  }

  void applyFilters() {
    var list = List<Map<String, dynamic>>.from(tasks);
    list = list.where(_taskMatchesActiveFilters).toList();
    list = _latestTaskPerUnit(list);
    list.sort((a, b) {
      final dateA = _taskDateTime(a);
      final dateB = _taskDateTime(b);
      return dateB.compareTo(dateA);
    });

    filteredTasks.assignAll(list);
    totalFilteredTasks.value = list.length;
    log('filtered task : $filteredTasks');
  }

  List<Map<String, dynamic>> _latestTaskPerUnit(
    List<Map<String, dynamic>> source,
  ) {
    final latestByUnit = <String, Map<String, dynamic>>{};

    for (final task in source) {
      final unit = task['unit']?.toString().trim().toUpperCase() ?? '';
      final key = unit.isNotEmpty
          ? unit
          : '__DOC__${task['doc_id']?.toString() ?? latestByUnit.length}';
      final existing = latestByUnit[key];

      if (existing == null ||
          _taskDateTime(task).isAfter(_taskDateTime(existing))) {
        latestByUnit[key] = task;
      }
    }

    return latestByUnit.values.toList();
  }

  DateTime _taskDateTime(Map<String, dynamic> task) {
    final timestamp = DateTime.tryParse(task['tanggal']?.toString() ?? '');
    if (timestamp != null) return timestamp;

    final day = task['hari']?.toString().trim() ?? '';
    final time = task['jam']?.toString().trim() ?? '';
    return DateTime.tryParse(time.isEmpty ? day : '${day}T$time') ??
        DateTime(2000);
  }

  bool _taskMatchesActiveFilters(Map<String, dynamic> task) {
    if (!_taskMatchesSelectedDate(task)) return false;

    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty &&
        !(task['unit'] ?? '').toString().toLowerCase().contains(query)) {
      return false;
    }

    return true;
  }

  bool _taskMatchesSelectedDate(Map<String, dynamic> task) {
    final range = selectedDateRange.value;
    if (range != null) {
      final dateStr = task['hari']?.toString();
      if (dateStr == null || dateStr.isEmpty) return false;

      final date = DateTime.tryParse(dateStr);
      if (date == null) return false;

      final start =
          DateTime(range.start.year, range.start.month, range.start.day);
      final end = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );

      if (date.isBefore(start) || date.isAfter(end)) return false;
    }

    return true;
  }

  void resetFilters() {
    _searchDebounce?.cancel();
    _usesDefaultTodayFilter = true;
    selectedDateRange.value = _todayDateRange();
    searchQuery.value = '';
    reloadForActiveFilters();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }

  /// Convert URL gambar menjadi Base64 Data URI.
  ///
  /// Contoh hasil:
  /// data:image/jpeg;base64,/9j/4AAQSkZJRgABAQ...
  ///
  /// Jika URL kosong, "0", atau download gagal,
  /// akan mengembalikan "0".
  String getFirstImageUrl(dynamic images) {
    if (images == null) {
      return '';
    }

    // Firestore menyimpan images sebagai List
    if (images is List) {
      if (images.isEmpty) {
        return '';
      }

      final firstImage = images.first;

      if (firstImage == null) {
        return '';
      }

      return firstImage.toString().trim();
    }

    // Kalau ternyata memang String
    String value = images.toString().trim();

    // Safety untuk data yang sudah telanjur berbentuk:
    // [https://....jpg]
    if (value.startsWith('[') && value.endsWith(']')) {
      value = value.substring(1, value.length - 1).trim();
    }

    return value;
  }

  Future<String> imageUrlToBase64(dynamic imageData) async {
    try {
      /// 1. Ambil URL asli dari List/String
      final String imageUrl = getFirstImageUrl(imageData);

      log('=== CONVERT IMAGE ===');
      log('Raw image data : $imageData');
      log('Image URL      : $imageUrl');

      if (imageUrl.isEmpty || imageUrl == '0') {
        log('Tidak ada gambar');
        return '0';
      }

      /// 2. Kalau sudah Base64, langsung return
      if (imageUrl.startsWith('data:image/')) {
        log('Image sudah dalam format Base64');
        return imageUrl;
      }

      /// 3. Parse URL
      final Uri? uri = Uri.tryParse(imageUrl);

      if (uri == null) {
        log('Uri.tryParse gagal: $imageUrl');
        return '0';
      }

      log('URI Scheme : ${uri.scheme}');
      log('URI Host   : ${uri.host}');

      if (uri.scheme != 'http' && uri.scheme != 'https') {
        log('Invalid scheme: ${uri.scheme}');
        return '0';
      }

      if (uri.host.isEmpty) {
        log('Invalid host: ${uri.host}');
        return '0';
      }

      /// 4. DOWNLOAD GAMBAR
      log('Downloading image...');

      http.Response? response;
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          response = await http.get(
            uri,
            headers: {'Connection': 'close'},
          ).timeout(const Duration(seconds: 20));

          if (response.statusCode >= 200 && response.statusCode < 300) {
            break;
          }
        } catch (downloadErr) {
          log('Download image attempt $attempt failed: $downloadErr');
          if (attempt == 2) rethrow;
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      if (response == null) {
        log('Gagal download image setelah retry.');
        return '0';
      }

      log('Download status : ${response.statusCode}');
      log('Image bytes     : ${response.bodyBytes.length}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        log(
          'Gagal download image. '
          'Status: ${response.statusCode}',
        );

        return '0';
      }

      if (response.bodyBytes.isEmpty) {
        log('Gambar berhasil didownload tetapi bytes kosong');
        return '0';
      }

      /// 5. Tentukan MIME TYPE
      final String? contentType =
          response.headers['content-type']?.split(';').first.trim();

      final String mimeType;

      if (contentType != null && contentType.startsWith('image/')) {
        mimeType = contentType;
      } else {
        mimeType = _getImageMimeType(imageUrl);
      }

      log('Mime Type : $mimeType');

      /// =================================================
      /// 6. INI BAGIAN YANG MENGUBAH GAMBAR MENJADI BASE64
      /// =================================================

      final String base64Image = base64Encode(response.bodyBytes);

      /// API kamu minta format:
      ///
      /// data:image/jpeg;base64,/9j/4AAQSk...
      ///
      final String base64DataUri = 'data:$mimeType;base64,$base64Image';

      log('Base64 berhasil dibuat');
      log('Base64 length : ${base64DataUri.length}');

      // Jangan log seluruh Base64 karena sangat panjang
      log(
        'Base64 preview : '
        '${base64DataUri.substring(
          0,
          base64DataUri.length > 100 ? 100 : base64DataUri.length,
        )}...',
      );

      return base64DataUri;
    } catch (e, stackTrace) {
      log(
        'Error converting image to Base64: $e',
        stackTrace: stackTrace,
      );

      return '0';
    }
  }

  String _getImageMimeType(String url) {
    final String lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('.png')) {
      return 'image/png';
    }

    if (lowerUrl.contains('.webp')) {
      return 'image/webp';
    }

    if (lowerUrl.contains('.gif')) {
      return 'image/gif';
    }

    if (lowerUrl.contains('.heic')) {
      return 'image/heic';
    }

    if (lowerUrl.contains('.jpeg')) {
      return 'image/jpeg';
    }

    if (lowerUrl.contains('.jpg')) {
      return 'image/jpeg';
    }

    return 'image/jpeg';
  }

  String _getRimValue(
    List<dynamic> rimCondition,
    int index,
    String key,
  ) {
    if (index < 0 || index >= rimCondition.length) {
      return '';
    }

    final item = rimCondition[index];

    if (item is! Map) {
      return '';
    }

    return item[key]?.toString() ?? '';
  }

  Future<void> sendTireInspection(BuildContext context) async {
    try {
      isSending.value = true;
      sendTireInspectionProgress.value = 0.0;
      final batch = <SendTireInspection>[];
      DocumentSnapshot<Map<String, dynamic>>? cursor;
      var scannedTasks = 0;
      var sentInspections = 0;
      var batchNumber = 0;
      var batchMoNumber = '';

      Future<void> sendCurrentBatch() async {
        if (batch.isEmpty) return;

        batchNumber++;
        final request = SendTireInspectionRequest(
          moNumber: batchMoNumber,
          inspects: List<SendTireInspection>.from(batch),
        );

        log('=== TIRE INSPECTION BATCH $batchNumber ===');
        log('MO Number: ${request.moNumber}');
        log('Total inspections: ${request.inspects.length}');

        await ApiService.sendTireInspection(request);
        sentInspections += batch.length;
        batch.clear();
        batchMoNumber = '';
      }

      while (true) {
        Query<Map<String, dynamic>> query =
            _dateScopedSiteQuery(homeState.currentSiteId).limit(_pageSize);
        if (cursor != null) {
          query = query.startAfterDocument(cursor);
        }

        final snapshot = await query.get();
        if (snapshot.docs.isEmpty) break;

        for (final doc in snapshot.docs) {
          scannedTasks++;
          final task = doc.data();

          if (!_taskMatchesActiveFilters(task)) continue;

          final positions = task['posisi'] as List<dynamic>? ?? [];
          for (final rawTire in positions) {
            if (rawTire is! Map) continue;

            if (batch.isEmpty) {
              batchMoNumber = task['mo_number']?.toString() ?? '';
            }

            final tire = Map<String, dynamic>.from(rawTire);
            batch.add(await _createSendInspection(task, tire));

            if (batch.length >= _sendBatchSize) {
              await sendCurrentBatch();
            }
          }

          if (totalTasks.value > 0) {
            sendTireInspectionProgress.value =
                ((scannedTasks / totalTasks.value) * 0.9).clamp(0.0, 0.9);
          }
        }

        cursor = snapshot.docs.last;
        if (snapshot.docs.length < _pageSize) break;
      }

      await sendCurrentBatch();

      if (sentInspections == 0) {
        throw Exception('Tidak ada data tire inspection yang akan dikirim.');
      }

      sendTireInspectionProgress.value = 1.0;

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Color(0xFF009688),
          content: Text(
            'Send data berhasil! $sentInspections inspeksi terkirim.',
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    } catch (e, stackTrace) {
      log(
        'Error send tire inspection: $e',
        stackTrace: stackTrace,
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Send data gagal: $e',
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ),
      );
    } finally {
      await Future.delayed(
        const Duration(milliseconds: 500),
      );

      isSending.value = false;
      sendTireInspectionProgress.value = 0.0;
    }
  }

  Future<SendTireInspection> _createSendInspection(
    Map<String, dynamic> task,
    Map<String, dynamic> tire,
  ) async {
    final rimCondition = tire['rimCondition'] as List<dynamic>? ?? [];
    final valveCapIndex = rimCondition.indexWhere((item) {
      if (item is! Map) return false;

      return item['title']?.toString().trim().toUpperCase() == 'VALVE CAP';
    });
    final nutStudIndex = rimCondition.indexWhere((item) {
      if (item is! Map) return false;

      final title = item['title']?.toString().toUpperCase() ?? '';
      return title.contains('NUT') && title.contains('STUD');
    });
    final effectiveNutStudIndex = nutStudIndex >= 0 ? nutStudIndex : 6;
    var imageBase64 = '0';

    if (tire['images'] != null) {
      imageBase64 = await imageUrlToBase64(tire['images']);
    }

    return SendTireInspection(
      idUnitSite: tire['idUnit']?.toString() ?? '',
      date: task['hari']?.toString() ?? '',
      unitNumber: task['unit']?.toString() ?? '',
      tirePosition: tire['position']?.toString() ?? '',
      pressure: tire['pressure']?.toString() ?? '',
      rtd1: tire['rtd1']?.toString() ?? '',
      hmOnInspect: tire['hm']?.toString() ?? '',
      kmOnInspect: tire['km']?.toString() ?? '0',
      remark: tire['remarks']?.toString() ?? '',
      pics: imageBase64,
      adjPress: tire['adjusmentPressure']?.toString() ?? '0',
      inspectorLocation: task['pit']?.toString() ?? '',
      area: task['pit']?.toString() ?? '',
      inspectionPeriod: task['periodTypeLabel']?.toString() ?? '',
      tireDamage: tire['damageTire']?.toString() ?? '',
      brokenComponent: tire['brokenComponent']?.toString() ?? '0',
      snTire: tire['sn']?.toString() ?? '',
      rimBaseCondition: _getRimValue(rimCondition, 0, 'condition'),
      rimBaseRemark: _getRimValue(rimCondition, 0, 'remark'),
      flangeCondition: _getRimValue(rimCondition, 1, 'condition'),
      flangeRemark: _getRimValue(rimCondition, 1, 'remark'),
      lockRingCondition: _getRimValue(rimCondition, 2, 'condition'),
      lockRingRemark: _getRimValue(rimCondition, 2, 'remark'),
      oRingCondition: _getRimValue(rimCondition, 3, 'condition'),
      oRingRemark: _getRimValue(rimCondition, 3, 'remark'),
      valveCondition: _getRimValue(rimCondition, 4, 'condition'),
      valveRemark: _getRimValue(rimCondition, 4, 'remark'),
      coreValveCondition: _getRimValue(rimCondition, 5, 'condition'),
      coreValveRemark: _getRimValue(rimCondition, 5, 'remark'),
      valveCapCondition: _getRimValue(rimCondition, valveCapIndex, 'condition'),
      valveCapRemark: _getRimValue(rimCondition, valveCapIndex, 'remark'),
      nutStudCondition:
          _getRimValue(rimCondition, effectiveNutStudIndex, 'condition'),
      nutStudRemark:
          _getRimValue(rimCondition, effectiveNutStudIndex, 'remark'),
      temperatureStatus:
          tire['temperatureStatus']?.toString().toUpperCase() ?? 'HOT',
      site: task['id_site']?.toString() ?? '',
    );
  }

  Future<List<Map<String, dynamic>>> _fetchAllMatchingTasks() async {
    final result = <Map<String, dynamic>>[];
    DocumentSnapshot<Map<String, dynamic>>? cursor;

    while (true) {
      Query<Map<String, dynamic>> query =
          _dateScopedSiteQuery(homeState.currentSiteId).limit(_pageSize);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) break;

      for (final doc in snapshot.docs) {
        final task = doc.data();
        if (_taskMatchesActiveFilters(task)) {
          task['doc_id'] = doc.id;
          result.add(task);
        }
      }

      cursor = snapshot.docs.last;
      if (snapshot.docs.length < _pageSize) break;
    }

    return result;
  }

  Future<void> exportToExcel(BuildContext context) async {
    try {
      isExporting.value = true;
      exportProgress.value = 0.1;

      final id = const Uuid();
      await Future.delayed(const Duration(milliseconds: 300));
      exportProgress.value = 0.3;

      // Ambil siteName dari homeState
      final siteName = homeState.siteName.isNotEmpty
          ? homeState.siteName
          : homeState.currentSiteId;

      final file = await createFolderPath(
        id.v4(),
        'tire_inspection',
        email: auth.currentUser?.email ?? 'unknown',
        site: siteName,
      );

      exportProgress.value = 0.65;

      // Ambil seluruh hasil filter per halaman. Dengan begitu export tidak
      // terbatas pada 50 item yang sedang tampil di layar.
      final exportTasks = await _fetchAllMatchingTasks();
      if (exportTasks.isEmpty) {
        throw Exception('Tidak ada data tire inspection yang akan diexport.');
      }

      exportProgress.value = 0.85;
      final bytes = await createExcel('tire_inspection', task: exportTasks);
      await file.writeAsBytes(bytes, flush: true);

      exportProgress.value = 1.0;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF009688),
        content: const Text('Export berhasil!',
            style: TextStyle(color: Colors.white)),
      ));

      await OpenFile.open(file.path);
    } catch (e) {
      log('Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Export gagal: $e'),
      ));
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      isExporting.value = false;
      exportProgress.value = 0.0;
    }
  }
}
