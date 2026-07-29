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

  var isLoading = false.obs;
  var isExporting = false.obs;
  var isSending = false.obs;

  var exportProgress = 0.0.obs;
  var sendTireInspectionProgress = 0.0.obs;

  var selectedDateRange = Rxn<DateTimeRange>();
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Jika currentSiteId sudah ada, langsung fetch
    if (homeState.currentSiteId.isNotEmpty) {
      fetchTasks();
    }

    // Listen perubahan currentSiteId (jika belum ready saat onInit)
    ever(homeState.currentSiteIdRx, (String siteId) {
      if (siteId.isNotEmpty) {
        fetchTasks();
      }
    });
  }

  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      final currentIdSite = homeState.currentSiteId;

      log('=== FETCH tire_inspection ===');
      log('currentIdSite: $currentIdSite');

      // Coba fetch semua dulu tanpa filter untuk debug
      final allSnapshot = await firestore.collection('tire_inspection').get();

      log('Total semua dokumen tire_inspection: ${allSnapshot.docs.length}');
      for (final doc in allSnapshot.docs) {
        log('doc id: ${doc.id} | id_site: ${doc.data()['id_site']} | unit: ${doc.data()['unit']}');
      }

      // Fetch dengan filter id_site
      final querySnapshot = await firestore
          .collection('tire_inspection')
          .where('id_site', isEqualTo: currentIdSite)
          .get();

      log('Filtered by id_site=$currentIdSite: ${querySnapshot.docs.length} docs');

      final result = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['doc_id'] = doc.id;
        return data;
      }).toList();

      result.sort((a, b) {
        final dateA = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      tasks.assignAll(result);
      applyFilters();
    } catch (e) {
      log('Error fetching tire_inspection: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    var list = List<Map<String, dynamic>>.from(tasks);

    if (selectedDateRange.value != null) {
      final start = selectedDateRange.value!.start;
      final end = DateTime(
        selectedDateRange.value!.end.year,
        selectedDateRange.value!.end.month,
        selectedDateRange.value!.end.day,
        23,
        59,
        59,
      );

      list = list.where((task) {
        final dateStr =
            task['hari']?.toString(); // ← pakai 'hari' bukan 'tanggal'
        if (dateStr == null || dateStr.isEmpty) return false;
        final date = DateTime.tryParse(dateStr);
        if (date == null) return false;
        return !date.isBefore(start) && !date.isAfter(end);
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list.where((task) {
        return (task['unit'] ?? '').toString().toLowerCase().contains(query);
      }).toList();
    }

    filteredTasks.assignAll(list);
    log('filtered task : $filteredTasks');
  }

  void resetFilters() {
    selectedDateRange.value = null;
    searchQuery.value = '';
    fetchTasks();
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

      final http.Response response = await http.get(uri);

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
    if (index >= rimCondition.length) {
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

      final List<SendTireInspection> sendTireInspectionData = [];

      // Hitung total ban yang akan dikirim
      int totalTires = 0;

      for (final task in filteredTasks) {
        final positions = task['posisi'] as List<dynamic>? ?? [];
        log('posisi ban : ${positions}');
        totalTires += positions.length;
      }

      if (totalTires == 0) {
        throw Exception('Tidak ada data tire inspection yang akan dikirim.');
      }

      int processedTires = 0;

      for (final task in filteredTasks) {
        final positions = task['posisi'] as List<dynamic>? ?? [];

        for (final tire in positions) {
          final rimCondition = tire['rimCondition'] as List<dynamic>? ?? [];

          /// ==========================
          /// CONVERT IMAGE TO BASE64
          /// ==========================

          String imageBase64 = '0';

          final dynamic images = tire['images'];

          log('Raw tire images : $images');
          log('Raw tire images type : ${images.runtimeType}');

          if (images != null) {
            imageBase64 = await imageUrlToBase64(images);
          }

          log(
            'Image converted. Base64 length: '
            '${imageBase64.length}',
          );

          /// ==========================
          /// CREATE INSPECTION
          /// ==========================

          sendTireInspectionData.add(
            SendTireInspection(
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

              /// BARU
              inspectionPeriod: task['periodTypeLabel']?.toString() ?? '',

              tireDamage: tire['damageTire']?.toString() ?? '',

              brokenComponent: tire['brokenComponent']?.toString() ?? '0',

              snTire: tire['sn']?.toString() ?? '',

              rimBaseCondition: _getRimValue(
                rimCondition,
                0,
                'condition',
              ),

              rimBaseRemark: _getRimValue(
                rimCondition,
                0,
                'remark',
              ),

              flangeCondition: _getRimValue(
                rimCondition,
                1,
                'condition',
              ),

              flangeRemark: _getRimValue(
                rimCondition,
                1,
                'remark',
              ),

              lockRingCondition: _getRimValue(
                rimCondition,
                2,
                'condition',
              ),

              lockRingRemark: _getRimValue(
                rimCondition,
                2,
                'remark',
              ),

              /// BARU
              /// index 3 = O-RING
              oRingCondition: _getRimValue(
                rimCondition,
                3,
                'condition',
              ),

              oRingRemark: _getRimValue(
                rimCondition,
                3,
                'remark',
              ),

              /// Index bergeser karena O-RING
              valveCondition: _getRimValue(
                rimCondition,
                4,
                'condition',
              ),

              valveRemark: _getRimValue(
                rimCondition,
                4,
                'remark',
              ),

              coreValveCondition: _getRimValue(
                rimCondition,
                5,
                'condition',
              ),

              coreValveRemark: _getRimValue(
                rimCondition,
                5,
                'remark',
              ),

              nutStudCondition: _getRimValue(
                rimCondition,
                6,
                'condition',
              ),

              nutStudRemark: _getRimValue(
                rimCondition,
                6,
                'remark',
              ),

              temperatureStatus:
                  tire['temperatureStatus']?.toString().toUpperCase() ?? 'HOT',

              site: task['id_site']?.toString() ?? '',
            ),
          );

          processedTires++;

          /// Progress 0 - 80% untuk proses gambar
          sendTireInspectionProgress.value =
              (processedTires / totalTires) * 0.8;
        }
      }

      /// ==========================
      /// CREATE REQUEST
      /// ==========================

      final request = SendTireInspectionRequest(
        moNumber: filteredTasks.isNotEmpty
            ? filteredTasks.first['mo_number']?.toString() ?? ''
            : '',
        inspects: sendTireInspectionData,
      );

      sendTireInspectionProgress.value = 0.85;

      /// Jangan log seluruh Base64 karena bisa sangat besar.
      log('=== TIRE INSPECTION REQUEST ===');
      log('MO Number: ${request.moNumber}');
      log(
        'Total inspections: '
        '${request.inspects.length}',
      );

      /// ==========================
      /// SEND API
      /// ==========================

      sendTireInspectionProgress.value = 0.9;

      await ApiService.sendTireInspection(request);

      sendTireInspectionProgress.value = 1.0;

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF009688),
          content: Text(
            'Send data berhasil!',
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

      // Langsung pass filteredTasks — tidak perlu flatten
      // createTireInspectionExcel sudah handle loop posisi di dalamnya
      exportProgress.value = 0.85;
      // yang bikin error !!
      final cleanedData = takeOutRimCondition(filteredTasks);
      log('filtered data : ${cleanedData.toList()}');

      final bytes =
          await createExcel('tire_inspection', task: cleanedData.toList());
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

  List<Map<String, dynamic>> takeOutRimCondition(List tasks) {
    return tasks.map((task) {
      final newTask = Map<String, dynamic>.from(task);

      if (newTask['posisi'] is List) {
        newTask['posisi'] = (newTask['posisi'] as List).map((pos) {
          final newPos = Map<String, dynamic>.from(pos);

          // 🔥 HAPUS rimCondition
          newPos.remove('rimCondition');

          return newPos;
        }).toList();
      }

      return newTask;
    }).toList();
  }
}
