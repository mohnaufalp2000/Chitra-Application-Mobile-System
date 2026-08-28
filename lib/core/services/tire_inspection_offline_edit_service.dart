import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'local_database/tire_inspection_offline_edit/tire_inspection_offline_edit_entity.dart';
import '../../objectbox.g.dart';

class TireInspectionOfflineSnapshot {
  const TireInspectionOfflineSnapshot({
    required this.documentId,
    required this.siteId,
    required this.unitNumber,
    required this.inspectionDate,
    required this.data,
    required this.pendingSync,
  });

  final String documentId;
  final String siteId;
  final String unitNumber;
  final String inspectionDate;
  final Map<String, dynamic> data;
  final bool pendingSync;
}

/// Menyimpan snapshot Tire Inspection yang sudah selesai dan antrean edit
/// offline. Antrean selalu mengacu ke ID dokumen inspeksi lama agar edit tidak
/// berubah menjadi dokumen inspeksi baru.
class TireInspectionOfflineEditService {
  TireInspectionOfflineEditService._();

  factory TireInspectionOfflineEditService.forTesting(Store store) {
    final service = TireInspectionOfflineEditService._();
    service.initialize(store);
    return service;
  }

  static final TireInspectionOfflineEditService instance =
      TireInspectionOfflineEditService._();

  static const Duration cacheRetention = Duration(days: 14);
  static const int maxCachedInspections = 500;

  Store? _store;
  bool _isSyncing = false;

  void initialize(Store store) {
    if (_store != null && !identical(_store, store)) {
      throw StateError(
        'Tire Inspection offline edit store is already initialized.',
      );
    }
    _store = store;
    _cleanupCache();
  }

  Box<TireInspectionOfflineEditEntity> get _box {
    final store = _store;
    if (store == null) {
      throw StateError(
        'TireInspectionOfflineEditService.initialize(store) must be called first.',
      );
    }
    return store.box<TireInspectionOfflineEditEntity>();
  }

  TireInspectionOfflineSnapshot cacheInspection({
    required String documentId,
    required Map<String, dynamic> data,
  }) {
    final normalizedDocumentId = documentId.trim();
    if (normalizedDocumentId.isEmpty) {
      throw ArgumentError.value(
        documentId,
        'documentId',
        'must not be empty',
      );
    }

    final existing = _findByDocumentId(normalizedDocumentId);
    if (existing != null && existing.pendingSync) {
      return _snapshotFromEntity(existing)!;
    }

    final safeData = _jsonSafeMap(data);
    if (existing != null) {
      _preserveLocalPhotoPaths(
        safeData,
        _decodeMap(existing.cachedInspectionJson),
      );
    }
    final entity = existing ?? TireInspectionOfflineEditEntity();
    entity
      ..inspectionDocumentId = normalizedDocumentId
      ..siteId = _stringValue(safeData['id_site'] ?? safeData['idSite'])
      ..unitNumber = _normalizeUnitNumber(safeData['unit'])
      ..inspectionDate = _dateKey(safeData['hari'] ?? safeData['tanggal'])
      ..originalHari = _stringValue(safeData['hari'])
      ..cachedInspectionJson = jsonEncode(safeData)
      ..pendingInspectionJson = ''
      ..pendingDailyPressureJson = ''
      ..updatedAtMillis = DateTime.now().millisecondsSinceEpoch
      ..pendingSync = false;

    _box.put(entity);
    return _snapshotFromEntity(entity)!;
  }

  /// Menyimpan path thumbnail lokal tanpa memasukkannya ke payload Firebase.
  /// Path ini membuat foto tetap dapat ditampilkan saat perangkat offline
  /// setelah antrean upload sudah selesai dan entry antrean dihapus.
  void cacheLocalPhotoPath({
    required String inspectionDocumentId,
    required String tirePosition,
    required String filePath,
  }) {
    final entity = _findByDocumentId(inspectionDocumentId.trim());
    if (entity == null || filePath.trim().isEmpty) return;

    final path = filePath.trim();
    final cached = _decodeMap(entity.cachedInspectionJson);
    final pending = _decodeMap(entity.pendingInspectionJson);
    var changed = false;
    changed = _setLocalPhotoPath(cached, tirePosition, path) || changed;
    changed = _setLocalPhotoPath(pending, tirePosition, path) || changed;
    if (!changed) return;

    if (cached != null) entity.cachedInspectionJson = jsonEncode(cached);
    if (pending != null) entity.pendingInspectionJson = jsonEncode(pending);
    entity.updatedAtMillis = DateTime.now().millisecondsSinceEpoch;
    _box.put(entity);
  }

  TireInspectionOfflineSnapshot? loadByDocumentId(String documentId) {
    final entity = _findByDocumentId(documentId.trim());
    return entity == null ? null : _snapshotFromEntity(entity);
  }

  List<TireInspectionOfflineSnapshot> loadForSiteAndDate({
    required String siteId,
    required String inspectionDate,
  }) {
    final query = _box
        .query(TireInspectionOfflineEditEntity_.siteId.equals(siteId.trim()) &
            TireInspectionOfflineEditEntity_.inspectionDate
                .equals(inspectionDate.trim()))
        .build();
    try {
      final snapshots = query
          .find()
          .map(_snapshotFromEntity)
          .whereType<TireInspectionOfflineSnapshot>()
          .toList();
      snapshots.sort((first, second) {
        final firstDate = _recordDate(first.data);
        final secondDate = _recordDate(second.data);
        return secondDate.compareTo(firstDate);
      });
      return snapshots;
    } finally {
      query.close();
    }
  }

  Future<void> enqueueEdit({
    required String inspectionDocumentId,
    required String siteId,
    required String unitNumber,
    required String originalHari,
    required Map<String, dynamic> inspectionData,
    required Map<String, dynamic> dailyPressureData,
  }) async {
    final documentId = inspectionDocumentId.trim();
    if (documentId.isEmpty) {
      throw ArgumentError.value(
        inspectionDocumentId,
        'inspectionDocumentId',
        'must not be empty',
      );
    }

    final safeInspection = _jsonSafeMap(inspectionData);
    final safeDailyPressure = _jsonSafeMap(dailyPressureData);
    final entity = _findByDocumentId(documentId) ??
        TireInspectionOfflineEditEntity(
          inspectionDocumentId: documentId,
        );

    entity
      ..siteId = siteId.trim()
      ..unitNumber = _normalizeUnitNumber(unitNumber)
      ..inspectionDate = _dateKey(
        safeInspection['hari'] ?? safeInspection['tanggal'],
      )
      ..originalHari = originalHari.trim()
      ..cachedInspectionJson = jsonEncode(safeInspection)
      ..pendingInspectionJson = jsonEncode(safeInspection)
      ..pendingDailyPressureJson = jsonEncode(safeDailyPressure)
      ..updatedAtMillis = DateTime.now().millisecondsSinceEpoch
      ..pendingSync = true;

    _box.put(entity);
  }

  void markSynced({
    required String inspectionDocumentId,
    required Map<String, dynamic> inspectionData,
  }) {
    final documentId = inspectionDocumentId.trim();
    if (documentId.isEmpty) return;

    final safeInspection = _jsonSafeMap(inspectionData);
    final entity = _findByDocumentId(documentId) ??
        TireInspectionOfflineEditEntity(
          inspectionDocumentId: documentId,
        );
    entity
      ..siteId = _stringValue(
        safeInspection['id_site'] ?? safeInspection['idSite'],
      )
      ..unitNumber = _normalizeUnitNumber(safeInspection['unit'])
      ..inspectionDate = _dateKey(
        safeInspection['hari'] ?? safeInspection['tanggal'],
      )
      ..originalHari = _stringValue(safeInspection['hari'])
      ..cachedInspectionJson = jsonEncode(safeInspection)
      ..pendingInspectionJson = ''
      ..pendingDailyPressureJson = ''
      ..updatedAtMillis = DateTime.now().millisecondsSinceEpoch
      ..pendingSync = false;
    _box.put(entity);
    _cleanupCache(protectedDocumentId: documentId);
  }

  bool hasPendingForDocument(String documentId) {
    return _findByDocumentId(documentId.trim())?.pendingSync == true;
  }

  /// Mencoba mengirim seluruh edit pending. Item yang gagal tetap tersimpan
  /// dan akan dicoba lagi pada kesempatan berikutnya.
  Future<int> retryPending() async {
    if (_isSyncing) return 0;
    _isSyncing = true;
    int syncedCount = 0;

    final query = _box
        .query(TireInspectionOfflineEditEntity_.pendingSync.equals(true))
        .order(TireInspectionOfflineEditEntity_.updatedAtMillis)
        .build();
    final pendingEntities = query.find();
    query.close();

    try {
      for (final entity in pendingEntities) {
        try {
          await _syncEntity(entity);
          syncedCount++;
        } catch (error, stackTrace) {
          log(
            'Sync offline Tire Inspection edit failed '
            '(${entity.inspectionDocumentId}): $error',
            stackTrace: stackTrace,
          );
        }
      }
    } finally {
      _isSyncing = false;
    }

    return syncedCount;
  }

  Future<void> _syncEntity(TireInspectionOfflineEditEntity entity) async {
    final inspectionData = _decodeMap(entity.pendingInspectionJson);
    final dailyPressureData = _decodeMap(entity.pendingDailyPressureJson);
    if (inspectionData == null || dailyPressureData == null) {
      throw const FormatException('Payload edit offline tidak valid.');
    }

    final firestore = FirebaseFirestore.instance;
    final dailyQuery = await firestore
        .collection('daily_pressure')
        .where('unit', isEqualTo: entity.unitNumber)
        .where('hari', isEqualTo: entity.originalHari)
        .limit(10)
        .get(const GetOptions(source: Source.server));

    QueryDocumentSnapshot<Map<String, dynamic>>? matchingDailyDocument;
    for (final document in dailyQuery.docs) {
      final documentSite =
          _stringValue(document.data()['idSite'] ?? document.data()['id_site']);
      if (documentSite.isEmpty || documentSite == entity.siteId) {
        matchingDailyDocument = document;
        break;
      }
    }

    final dailyDocumentId = matchingDailyDocument?.id ??
        _buildDailyDocumentId(
          entity.siteId,
          entity.unitNumber,
          entity.originalHari,
        );

    final oldDailyPositions = matchingDailyDocument?.data()['posisi'];
    final newDailyPositions = dailyPressureData['posisi'];
    if (oldDailyPositions is List && newDailyPositions is List) {
      dailyPressureData['posisi'] = List<Map<String, dynamic>>.generate(
        newDailyPositions.length,
        (index) {
          final oldPosition = index < oldDailyPositions.length &&
                  oldDailyPositions[index] is Map
              ? Map<String, dynamic>.from(oldDailyPositions[index] as Map)
              : <String, dynamic>{};
          final newPosition = newDailyPositions[index] is Map
              ? Map<String, dynamic>.from(newDailyPositions[index] as Map)
              : <String, dynamic>{};
          return <String, dynamic>{...oldPosition, ...newPosition};
        },
      );
    }

    inspectionData
      ..['savedOffline'] = false
      ..['syncStatus'] = 'synced';
    dailyPressureData
      ..['savedOffline'] = false
      ..['syncStatus'] = 'synced';

    final batch = firestore.batch();
    batch.set(
      firestore.collection('tire_inspection').doc(entity.inspectionDocumentId),
      inspectionData,
      SetOptions(merge: true),
    );
    batch.set(
      firestore.collection('daily_pressure').doc(dailyDocumentId),
      dailyPressureData,
      SetOptions(merge: true),
    );
    await batch.commit();

    final latest = _findByDocumentId(entity.inspectionDocumentId);
    if (latest == null || latest.updatedAtMillis != entity.updatedAtMillis) {
      return;
    }

    latest
      ..cachedInspectionJson = jsonEncode(inspectionData)
      ..pendingInspectionJson = ''
      ..pendingDailyPressureJson = ''
      ..pendingSync = false
      ..updatedAtMillis = DateTime.now().millisecondsSinceEpoch;
    _box.put(latest);
    _cleanupCache(protectedDocumentId: latest.inspectionDocumentId);
  }

  TireInspectionOfflineEditEntity? _findByDocumentId(String documentId) {
    if (documentId.isEmpty) return null;
    final query = _box
        .query(TireInspectionOfflineEditEntity_.inspectionDocumentId
            .equals(documentId))
        .build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  TireInspectionOfflineSnapshot? _snapshotFromEntity(
    TireInspectionOfflineEditEntity entity,
  ) {
    final payload =
        entity.pendingSync && entity.pendingInspectionJson.isNotEmpty
            ? entity.pendingInspectionJson
            : entity.cachedInspectionJson;
    final data = _decodeMap(payload);
    if (data == null) return null;

    return TireInspectionOfflineSnapshot(
      documentId: entity.inspectionDocumentId,
      siteId: entity.siteId,
      unitNumber: entity.unitNumber,
      inspectionDate: entity.inspectionDate,
      data: data,
      pendingSync: entity.pendingSync,
    );
  }

  Map<String, dynamic>? _decodeMap(String payload) {
    if (payload.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _jsonSafeMap(Map<String, dynamic> source) {
    return Map<String, dynamic>.from(
      _jsonSafeValue(source) as Map,
    );
  }

  dynamic _jsonSafeValue(dynamic value) {
    if (value is Timestamp) return value.toDate().toIso8601String();
    if (value is DateTime) return value.toIso8601String();
    if (value is GeoPoint) {
      return <String, double>{
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }
    if (value is Iterable) {
      return value.map<dynamic>(_jsonSafeValue).toList(growable: true);
    }
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, item) => MapEntry(key.toString(), _jsonSafeValue(item)),
      );
    }
    return value;
  }

  String _dateKey(dynamic value) {
    final text = _stringValue(value);
    final parsed = DateTime.tryParse(text);
    if (parsed != null) {
      return '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-'
          '${parsed.day.toString().padLeft(2, '0')}';
    }
    return text.length >= 10 ? text.substring(0, 10) : text;
  }

  DateTime _recordDate(Map<String, dynamic> data) {
    return DateTime.tryParse(_stringValue(data['tanggal'])) ??
        DateTime.tryParse(_stringValue(data['hari'])) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _buildDailyDocumentId(
    String siteId,
    String unitNumber,
    String hari,
  ) {
    final parsedDate = DateTime.tryParse(hari) ?? DateTime.now();
    final datePart =
        '${parsedDate.year}${parsedDate.month.toString().padLeft(2, '0')}'
        '${parsedDate.day.toString().padLeft(2, '0')}';
    return 'daily_${_sanitize(siteId)}_${_sanitize(unitNumber)}_$datePart';
  }

  String _sanitize(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  String _normalizeUnitNumber(dynamic value) =>
      _stringValue(value).toUpperCase();

  String _stringValue(dynamic value) => value?.toString().trim() ?? '';

  bool _setLocalPhotoPath(
    Map<String, dynamic>? data,
    String tirePosition,
    String filePath,
  ) {
    if (data == null || data['posisi'] is! List) return false;
    for (final item in data['posisi'] as List) {
      if (item is! Map) continue;
      final itemPosition =
          (item['position'] ?? item['pos'])?.toString().trim() ?? '';
      if (itemPosition != tirePosition.trim()) continue;
      if (item['_cachedLocalImagePath'] == filePath) return false;
      item['_cachedLocalImagePath'] = filePath;
      return true;
    }
    return false;
  }

  void _preserveLocalPhotoPaths(
    Map<String, dynamic> target,
    Map<String, dynamic>? previous,
  ) {
    if (previous == null || target['posisi'] is! List) return;
    final previousPositions = previous['posisi'];
    if (previousPositions is! List) return;

    final previousByPosition = <String, String>{};
    for (final item in previousPositions) {
      if (item is! Map) continue;
      final path = item['_cachedLocalImagePath']?.toString().trim() ?? '';
      final position =
          (item['position'] ?? item['pos'])?.toString().trim() ?? '';
      if (path.isNotEmpty && position.isNotEmpty) {
        previousByPosition[position] = path;
      }
    }
    for (final item in target['posisi'] as List) {
      if (item is! Map) continue;
      final position =
          (item['position'] ?? item['pos'])?.toString().trim() ?? '';
      final path = previousByPosition[position];
      if (path != null && path.isNotEmpty) {
        item['_cachedLocalImagePath'] = path;
      }
    }
  }

  Set<String> _localPhotoPaths(Map<String, dynamic> data) {
    final paths = <String>{};
    final positions = data['posisi'];
    if (positions is! List) return paths;
    for (final item in positions) {
      if (item is! Map) continue;
      final path = item['_cachedLocalImagePath']?.toString().trim() ?? '';
      if (path.isNotEmpty) paths.add(path);
    }
    return paths;
  }

  void _cleanupCache({String? protectedDocumentId}) {
    final cutoff =
        DateTime.now().subtract(cacheRetention).millisecondsSinceEpoch;
    final removable = _box
        .getAll()
        .where((entity) =>
            !entity.pendingSync &&
            entity.inspectionDocumentId != protectedDocumentId)
        .toList()
      ..sort((first, second) =>
          second.updatedAtMillis.compareTo(first.updatedAtMillis));

    final removeIds = <int>[];
    for (int index = 0; index < removable.length; index++) {
      final entity = removable[index];
      if (entity.updatedAtMillis < cutoff || index >= maxCachedInspections) {
        removeIds.add(entity.id);
      }
    }
    if (removeIds.isEmpty) return;

    final removedPaths = <String>{};
    for (final entity
        in removable.where((item) => removeIds.contains(item.id))) {
      final data = _decodeMap(entity.cachedInspectionJson);
      if (data != null) removedPaths.addAll(_localPhotoPaths(data));
    }
    _box.removeMany(removeIds);

    final retainedPaths = <String>{};
    for (final entity in _box.getAll()) {
      final data = _decodeMap(entity.cachedInspectionJson);
      if (data != null) retainedPaths.addAll(_localPhotoPaths(data));
    }
    for (final path in removedPaths.difference(retainedPaths)) {
      try {
        final file = File(path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
  }
}
