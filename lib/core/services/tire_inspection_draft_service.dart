import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:camos/core/services/local_database/tire_inspection_draft/tire_inspection_draft_entity.dart';
import 'package:camos/objectbox.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'model/tire_inspection_draft.dart';

/// Persists unfinished Tire Inspection forms in ObjectBox.
///
/// Payloads created by the previous SharedPreferences implementation are
/// migrated one at a time and removed only after ObjectBox stores them.
class TireInspectionDraftService {
  TireInspectionDraftService._({
    Store? store,
    SharedPreferences? legacyPreferences,
    DateTime Function()? clock,
    this.retention = defaultRetention,
    this.maxDraftsPerUser = defaultMaxDraftsPerUser,
    this.maxDraftsPerDevice = defaultMaxDraftsPerDevice,
  })  : _store = store,
        _legacyPreferences = legacyPreferences,
        _clock = clock ?? DateTime.now {
    if (retention <= Duration.zero) {
      throw ArgumentError.value(retention, 'retention', 'must be positive');
    }
    if (maxDraftsPerUser < 1) {
      throw ArgumentError.value(
        maxDraftsPerUser,
        'maxDraftsPerUser',
        'must be positive',
      );
    }
    if (maxDraftsPerDevice < maxDraftsPerUser) {
      throw ArgumentError.value(
        maxDraftsPerDevice,
        'maxDraftsPerDevice',
        'must be at least maxDraftsPerUser',
      );
    }
  }

  factory TireInspectionDraftService() => instance;

  factory TireInspectionDraftService.forTesting({
    required Store store,
    SharedPreferences? legacyPreferences,
    DateTime Function()? clock,
    Duration retention = defaultRetention,
    int maxDraftsPerUser = defaultMaxDraftsPerUser,
    int maxDraftsPerDevice = defaultMaxDraftsPerDevice,
  }) {
    return TireInspectionDraftService._(
      store: store,
      legacyPreferences: legacyPreferences,
      clock: clock,
      retention: retention,
      maxDraftsPerUser: maxDraftsPerUser,
      maxDraftsPerDevice: maxDraftsPerDevice,
    );
  }

  static final TireInspectionDraftService instance =
      TireInspectionDraftService._();

  static const Duration defaultRetention = Duration(days: 30);
  // Keep only the two most recently updated unit drafts for each user.
  static const int defaultMaxDraftsPerUser = 2;
  static const int defaultMaxDraftsPerDevice = 300;

  static const String _legacyIndexPreferenceKey =
      'camos.tire_inspection.drafts.index.v1';
  static const String _legacyPayloadPreferencePrefix =
      'camos.tire_inspection.draft.v1.';

  Store? _store;
  SharedPreferences? _legacyPreferences;
  final DateTime Function() _clock;

  final Duration retention;
  final int maxDraftsPerUser;
  final int maxDraftsPerDevice;

  bool _prepared = false;
  Future<void> _operationQueue = Future<void>.value();

  /// Attaches the single application ObjectBox store.
  ///
  /// This call is synchronous and safe before [runApp]. Migration and cleanup
  /// run lazily through [prepareStorage] or the first CRUD operation.
  void initialize(Store store) => attachStore(store);

  void attachStore(Store store) {
    if (_store != null && !identical(_store, store)) {
      throw StateError('Tire Inspection draft store is already initialized.');
    }
    _store = store;
  }

  /// Starts legacy migration, repairs malformed rows, and applies retention.
  Future<void> prepareStorage() {
    return _enqueue<void>(() async {
      await _ensurePrepared();
    });
  }

  /// Creates or replaces a draft and returns the exact stored snapshot.
  ///
  /// [updatedAt] is refreshed on every call while [createdAt] is preserved.
  Future<TireInspectionDraft> saveDraft(TireInspectionDraft draft) {
    return _enqueue<TireInspectionDraft>(() async {
      await _ensurePrepared();

      final token = draft.key.storageToken;
      final existing = _findEntity(token);
      final createdAt = existing != null && existing.createdAtMillis > 0
          ? DateTime.fromMillisecondsSinceEpoch(existing.createdAtMillis)
          : draft.createdAt;
      final snapshot = draft.copyWith(
        createdAt: createdAt,
        updatedAt: _clock(),
      );

      _box.put(_entityFromDraft(snapshot, id: existing?.id ?? 0));
      if (existing == null) {
        _pruneDrafts(protectedToken: token);
      }
      return snapshot;
    });
  }

  /// Reads a draft. A malformed payload is removed and reported as `null`.
  Future<TireInspectionDraft?> loadDraft(TireInspectionDraftKey key) {
    return _enqueue<TireInspectionDraft?>(() async {
      await _ensurePrepared();

      final entity = _findEntity(key.storageToken);
      if (entity == null) return null;
      if (_isExpired(entity)) {
        _box.remove(entity.id);
        return null;
      }

      final draft = _draftFromEntity(entity);
      if (draft == null || draft.key != key) {
        _box.remove(entity.id);
        return null;
      }
      return draft;
    });
  }

  Future<bool> hasDraft(TireInspectionDraftKey key) async {
    return (await loadDraft(key)) != null;
  }

  /// Deletes one draft. This should be called only after Save succeeds or the
  /// user explicitly chooses to discard the unfinished inspection.
  Future<bool> deleteDraft(TireInspectionDraftKey key) {
    return _enqueue<bool>(() async {
      await _ensurePrepared();
      final entity = _findEntity(key.storageToken);
      return entity != null && _box.remove(entity.id);
    });
  }

  /// Alias that makes the intended call site after a successful form Save
  /// explicit.
  Future<bool> markCompleted(TireInspectionDraftKey key) {
    return deleteDraft(key);
  }

  /// Lists lightweight metadata for all active (unfinished) drafts.
  Future<List<TireInspectionDraftMetadata>> listActiveDrafts({
    String? userId,
    String? siteId,
    String? unitNumber,
    DateTime? inspectionDate,
  }) {
    return _enqueue<List<TireInspectionDraftMetadata>>(() async {
      await _ensurePrepared();
      _pruneDrafts();

      final dateKey = inspectionDate == null
          ? null
          : TireInspectionDraftKey.dateKeyFor(inspectionDate);
      final result = <TireInspectionDraftMetadata>[];
      final malformedIds = <int>[];

      for (final id in _allEntityIdsNewestFirst()) {
        final entity = _box.get(id);
        if (entity == null) continue;
        final metadata = _metadataFromEntity(entity);
        if (metadata == null) {
          malformedIds.add(entity.id);
          continue;
        }
        if (_matches(
          metadata,
          userId: userId,
          siteId: siteId,
          unitNumber: unitNumber,
          inspectionDate: dateKey,
        )) {
          result.add(metadata);
        }
      }

      if (malformedIds.isNotEmpty) _box.removeMany(malformedIds);
      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return result;
    });
  }

  /// Loads the newest full draft matching the supplied scope.
  Future<TireInspectionDraft?> loadMostRecentDraft({
    String? userId,
    String? siteId,
    String? unitNumber,
    DateTime? inspectionDate,
  }) {
    return _enqueue<TireInspectionDraft?>(() async {
      await _ensurePrepared();
      _pruneDrafts();

      final dateKey = inspectionDate == null
          ? null
          : TireInspectionDraftKey.dateKeyFor(inspectionDate);
      for (final id in _allEntityIdsNewestFirst()) {
        final entity = _box.get(id);
        if (entity == null) continue;
        final metadata = _metadataFromEntity(entity);
        if (metadata == null) {
          _box.remove(entity.id);
          continue;
        }
        if (!_matches(
          metadata,
          userId: userId,
          siteId: siteId,
          unitNumber: unitNumber,
          inspectionDate: dateKey,
        )) {
          continue;
        }

        final draft = _draftFromEntity(entity);
        if (draft != null && draft.key.storageToken == entity.storageToken) {
          return draft;
        }
        _box.remove(entity.id);
      }
      return null;
    });
  }

  /// Removes all drafts matching the supplied scope and returns the number of
  /// removed entries. With no filters, it clears all Tire Inspection drafts.
  Future<int> deleteDrafts({
    String? userId,
    String? siteId,
    String? unitNumber,
    DateTime? inspectionDate,
  }) {
    return _enqueue<int>(() async {
      await _ensurePrepared();

      final dateKey = inspectionDate == null
          ? null
          : TireInspectionDraftKey.dateKeyFor(inspectionDate);
      final ids = <int>[];
      for (final id in _allEntityIdsNewestFirst()) {
        final entity = _box.get(id);
        if (entity == null) continue;
        final metadata = _metadataFromEntity(entity);
        if (metadata == null ||
            _matches(
              metadata,
              userId: userId,
              siteId: siteId,
              unitNumber: unitNumber,
              inspectionDate: dateKey,
            )) {
          ids.add(entity.id);
        }
      }
      return ids.isEmpty ? 0 : _box.removeMany(ids);
    });
  }

  /// Repairs malformed rows, reapplies retention, and returns valid metadata.
  Future<List<TireInspectionDraftMetadata>> repairStorage() {
    return _enqueue<List<TireInspectionDraftMetadata>>(() async {
      await _ensurePrepared();
      _repairObjectBoxRows();
      _pruneDrafts();
      return _validMetadataNewestFirst();
    });
  }

  Future<void> _ensurePrepared() async {
    if (_prepared) return;
    _requiredStore;

    try {
      await _migrateLegacyDrafts();
    } catch (error, stackTrace) {
      log(
        'Tire Inspection legacy draft migration failed: $error',
        stackTrace: stackTrace,
      );
    }

    _repairObjectBoxRows();
    _pruneDrafts();
    _prepared = true;
  }

  Future<void> _migrateLegacyDrafts() async {
    final prefs = _legacyPreferences ??= await SharedPreferences.getInstance();
    final payloadKeys = prefs
        .getKeys()
        .where((key) => key.startsWith(_legacyPayloadPreferencePrefix))
        .toList();

    final retentionCutoff = _clock().subtract(retention).millisecondsSinceEpoch;
    var allProcessed = true;
    for (var index = 0; index < payloadKeys.length; index++) {
      final preferenceKey = payloadKeys[index];
      try {
        final rawPayload = prefs.getString(preferenceKey);
        final legacyDraft = rawPayload == null
            ? null
            : _tryDecodeDraft(rawPayload, source: 'legacy SharedPreferences');

        final isExpired = legacyDraft != null &&
            legacyDraft.updatedAt.millisecondsSinceEpoch < retentionCutoff;
        if (legacyDraft != null && !isExpired) {
          final token = legacyDraft.key.storageToken;
          final existing = _findEntity(token);
          final existingDraft =
              existing == null ? null : _draftFromEntity(existing);
          if (existing == null ||
              existingDraft == null ||
              legacyDraft.updatedAt.isAfter(existingDraft.updatedAt)) {
            _box.put(
              _entityFromDraft(legacyDraft, id: existing?.id ?? 0),
            );
          }
        }

        final removed = await prefs.remove(preferenceKey);
        if (!removed && prefs.containsKey(preferenceKey)) {
          allProcessed = false;
        }
      } catch (error, stackTrace) {
        allProcessed = false;
        log(
          'Failed migrating legacy Tire Inspection draft $preferenceKey: '
          '$error',
          stackTrace: stackTrace,
        );
      }

      if ((index + 1) % 10 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    final legacyPayloadRemains = prefs
        .getKeys()
        .any((key) => key.startsWith(_legacyPayloadPreferencePrefix));
    if (allProcessed && !legacyPayloadRemains) {
      await prefs.remove(_legacyIndexPreferenceKey);
    }
  }

  void _repairObjectBoxRows() {
    final removeIds = <int>[];

    for (final id in _allEntityIdsNewestFirst()) {
      final entity = _box.get(id);
      if (entity == null) continue;
      final draft = _draftFromEntity(entity);
      if (draft == null || draft.key.storageToken != entity.storageToken) {
        removeIds.add(entity.id);
        continue;
      }

      final canonical = _entityFromDraft(draft, id: entity.id);
      if (!_entityMetadataMatches(entity, canonical)) {
        _box.put(canonical);
      }
    }

    if (removeIds.isNotEmpty) _box.removeMany(removeIds);
  }

  void _pruneDrafts({String? protectedToken}) {
    if (_box.isEmpty()) return;

    final removeIds = <int>{};
    final cutoff = _clock().subtract(retention).millisecondsSinceEpoch;
    final expiredQuery = _box
        .query(TireInspectionDraftEntity_.updatedAtMillis.lessThan(cutoff))
        .build();
    try {
      removeIds.addAll(expiredQuery.findIds());
    } finally {
      expiredQuery.close();
    }

    final entries = <_DraftRetentionEntry>[];
    for (final id in _allEntityIdsNewestFirst()) {
      final entity = _box.get(id);
      if (entity == null) continue;
      if (entity.storageToken == protectedToken) {
        removeIds.remove(entity.id);
      }
      if (!removeIds.contains(entity.id)) {
        entries.add(
          _DraftRetentionEntry(
            id: entity.id,
            storageToken: entity.storageToken,
            userId: entity.userId,
            updatedAtMillis: entity.updatedAtMillis,
          ),
        );
      }
    }

    entries.sort((first, second) {
      final firstIsProtected = first.storageToken == protectedToken;
      final secondIsProtected = second.storageToken == protectedToken;
      if (firstIsProtected != secondIsProtected) {
        return firstIsProtected ? -1 : 1;
      }
      final updatedComparison =
          second.updatedAtMillis.compareTo(first.updatedAtMillis);
      if (updatedComparison != 0) return updatedComparison;
      return second.id.compareTo(first.id);
    });

    final userCounts = <String, int>{};
    for (final entry in entries) {
      final count = userCounts[entry.userId] ?? 0;
      if (count >= maxDraftsPerUser) {
        removeIds.add(entry.id);
      } else {
        userCounts[entry.userId] = count + 1;
      }
    }

    var globalCount = 0;
    for (final entry in entries) {
      if (removeIds.contains(entry.id)) continue;
      if (globalCount >= maxDraftsPerDevice) {
        removeIds.add(entry.id);
      } else {
        globalCount++;
      }
    }

    if (removeIds.isNotEmpty) _box.removeMany(removeIds.toList());
  }

  List<TireInspectionDraftMetadata> _validMetadataNewestFirst() {
    final result = <TireInspectionDraftMetadata>[];
    final malformedIds = <int>[];
    for (final id in _allEntityIdsNewestFirst()) {
      final entity = _box.get(id);
      if (entity == null) continue;
      final metadata = _metadataFromEntity(entity);
      if (metadata == null) {
        malformedIds.add(entity.id);
      } else {
        result.add(metadata);
      }
    }
    if (malformedIds.isNotEmpty) _box.removeMany(malformedIds);
    result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return result;
  }

  TireInspectionDraftEntity _entityFromDraft(
    TireInspectionDraft draft, {
    int id = 0,
  }) {
    final metadata = draft.toMetadata();
    return TireInspectionDraftEntity(
      id: id,
      storageToken: draft.key.storageToken,
      userId: draft.key.userId,
      siteId: draft.key.siteId,
      unitNumber: draft.key.unitNumber,
      inspectionDate: draft.key.inspectionDate,
      createdAtMillis: draft.createdAt.millisecondsSinceEpoch,
      updatedAtMillis: draft.updatedAt.millisecondsSinceEpoch,
      periodType: draft.periodType,
      location: draft.location,
      hm: draft.hm,
      unitModel: draft.unitModel,
      siteName: draft.siteName,
      userDisplayName: draft.userDisplayName,
      positionCount: metadata.positionCount,
      imageCount: metadata.imageCount,
      payloadJson: jsonEncode(draft.toJson()),
    );
  }

  TireInspectionDraft? _draftFromEntity(TireInspectionDraftEntity entity) {
    final draft = _tryDecodeDraft(entity.payloadJson, source: 'ObjectBox');
    if (draft == null || draft.key.storageToken != entity.storageToken) {
      return null;
    }
    return draft;
  }

  TireInspectionDraftMetadata? _metadataFromEntity(
    TireInspectionDraftEntity entity,
  ) {
    try {
      if (entity.createdAtMillis <= 0 || entity.updatedAtMillis <= 0) {
        return null;
      }
      return TireInspectionDraftMetadata(
        key: TireInspectionDraftKey(
          userId: entity.userId,
          siteId: entity.siteId,
          unitNumber: entity.unitNumber,
          inspectionDate: entity.inspectionDate,
        ),
        createdAt: DateTime.fromMillisecondsSinceEpoch(entity.createdAtMillis),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(entity.updatedAtMillis),
        periodType: entity.periodType,
        location: entity.location,
        unitModel: entity.unitModel,
        siteName: entity.siteName,
        userDisplayName: entity.userDisplayName,
        positionCount: entity.positionCount,
        imageCount: entity.imageCount,
      );
    } catch (error, stackTrace) {
      log(
        'Ignoring invalid Tire Inspection draft metadata: $error',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  bool _entityMetadataMatches(
    TireInspectionDraftEntity current,
    TireInspectionDraftEntity canonical,
  ) {
    return current.storageToken == canonical.storageToken &&
        current.userId == canonical.userId &&
        current.siteId == canonical.siteId &&
        current.unitNumber == canonical.unitNumber &&
        current.inspectionDate == canonical.inspectionDate &&
        current.createdAtMillis == canonical.createdAtMillis &&
        current.updatedAtMillis == canonical.updatedAtMillis &&
        current.periodType == canonical.periodType &&
        current.location == canonical.location &&
        current.hm == canonical.hm &&
        current.unitModel == canonical.unitModel &&
        current.siteName == canonical.siteName &&
        current.userDisplayName == canonical.userDisplayName &&
        current.positionCount == canonical.positionCount &&
        current.imageCount == canonical.imageCount &&
        current.payloadJson == canonical.payloadJson;
  }

  TireInspectionDraftEntity? _findEntity(String storageToken) {
    final query = _box
        .query(TireInspectionDraftEntity_.storageToken.equals(storageToken))
        .build();
    try {
      return query.findFirst();
    } finally {
      query.close();
    }
  }

  TireInspectionDraft? _tryDecodeDraft(
    String rawPayload, {
    required String source,
  }) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map) return null;
      return TireInspectionDraft.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (error, stackTrace) {
      log(
        'Ignoring corrupt Tire Inspection draft from $source: $error',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  bool _isExpired(TireInspectionDraftEntity entity) {
    return entity.updatedAtMillis <
        _clock().subtract(retention).millisecondsSinceEpoch;
  }

  List<int> _allEntityIdsNewestFirst() {
    final query = _box
        .query()
        .order(
          TireInspectionDraftEntity_.updatedAtMillis,
          flags: Order.descending,
        )
        .order(
          TireInspectionDraftEntity_.id,
          flags: Order.descending,
        )
        .build();
    try {
      return query.findIds();
    } finally {
      query.close();
    }
  }

  bool _matches(
    TireInspectionDraftMetadata metadata, {
    String? userId,
    String? siteId,
    String? unitNumber,
    String? inspectionDate,
  }) {
    final normalizedUserId = userId?.trim();
    final normalizedSiteId = siteId?.trim();
    final normalizedUnitNumber = unitNumber?.trim();

    return (normalizedUserId == null ||
            normalizedUserId.isEmpty ||
            metadata.key.userId == normalizedUserId) &&
        (normalizedSiteId == null ||
            normalizedSiteId.isEmpty ||
            metadata.key.siteId == normalizedSiteId) &&
        (normalizedUnitNumber == null ||
            normalizedUnitNumber.isEmpty ||
            metadata.key.unitNumber == normalizedUnitNumber) &&
        (inspectionDate == null ||
            metadata.key.inspectionDate == inspectionDate);
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _operationQueue = _operationQueue.catchError((_) {}).then((_) async {
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  Store get _requiredStore {
    final value = _store;
    if (value == null) {
      throw StateError(
        'TireInspectionDraftService.initialize(store) must be called first.',
      );
    }
    return value;
  }

  Box<TireInspectionDraftEntity> get _box =>
      _requiredStore.box<TireInspectionDraftEntity>();
}

class _DraftRetentionEntry {
  const _DraftRetentionEntry({
    required this.id,
    required this.storageToken,
    required this.userId,
    required this.updatedAtMillis,
  });

  final int id;
  final String storageToken;
  final String userId;
  final int updatedAtMillis;
}
