import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:shared_preferences/shared_preferences.dart';

import 'model/tire_inspection_draft.dart';

/// Persists unfinished Tire Inspection forms independently from Firestore.
///
/// Every draft has its own SharedPreferences entry. The separate metadata
/// index keeps resume prompts lightweight and can be rebuilt if it is corrupt
/// or an app process is stopped between the payload and index writes.
class TireInspectionDraftService {
  TireInspectionDraftService._();

  factory TireInspectionDraftService() => instance;

  static final TireInspectionDraftService instance =
      TireInspectionDraftService._();

  static const int _storageSchemaVersion = 1;
  static const String _indexPreferenceKey =
      'camos.tire_inspection.drafts.index.v1';
  static const String _payloadPreferencePrefix =
      'camos.tire_inspection.draft.v1.';

  Future<void> _operationQueue = Future<void>.value();

  /// Creates or replaces a draft and returns the exact stored snapshot.
  ///
  /// [updatedAt] is refreshed on every call while [createdAt] is preserved.
  Future<TireInspectionDraft> saveDraft(TireInspectionDraft draft) {
    return _enqueue<TireInspectionDraft>(() async {
      final prefs = await SharedPreferences.getInstance();
      final index = await _loadOrRepairIndex(prefs);
      final snapshot = draft.copyWith(updatedAt: DateTime.now());
      final payloadKey = _payloadKey(snapshot.key.storageToken);

      final payloadSaved = await prefs.setString(
        payloadKey,
        jsonEncode(snapshot.toJson()),
      );
      if (!payloadSaved) {
        throw StateError('Failed to persist Tire Inspection draft.');
      }

      index[snapshot.key.storageToken] = snapshot.toMetadata();
      await _writeIndex(prefs, index);
      return snapshot;
    });
  }

  /// Reads a draft. A malformed payload is removed and reported as `null`.
  Future<TireInspectionDraft?> loadDraft(TireInspectionDraftKey key) {
    return _enqueue<TireInspectionDraft?>(() async {
      final prefs = await SharedPreferences.getInstance();
      final index = await _loadOrRepairIndex(prefs);
      final token = key.storageToken;
      final rawPayload = prefs.getString(_payloadKey(token));

      if (rawPayload == null || rawPayload.trim().isEmpty) {
        if (index.remove(token) != null) {
          await _writeIndex(prefs, index);
        }
        return null;
      }

      final draft = _tryDecodeDraft(rawPayload);
      if (draft == null || draft.key != key) {
        await _removePayloadAndIndex(prefs, index, token);
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
      final prefs = await SharedPreferences.getInstance();
      final index = await _loadOrRepairIndex(prefs);
      final token = key.storageToken;
      final existed =
          prefs.containsKey(_payloadKey(token)) || index.containsKey(token);

      await _removePayloadAndIndex(prefs, index, token);
      return existed;
    });
  }

  /// Alias that makes the intended call site after a successful form Save
  /// explicit.
  Future<bool> markCompleted(TireInspectionDraftKey key) {
    return deleteDraft(key);
  }

  /// Lists lightweight metadata for all active (unfinished) drafts.
  ///
  /// Results are newest first. Every filter is optional and compared after
  /// trimming. [inspectionDate] is converted to a local `yyyy-MM-dd` key.
  Future<List<TireInspectionDraftMetadata>> listActiveDrafts({
    String? userId,
    String? siteId,
    String? unitNumber,
    DateTime? inspectionDate,
  }) {
    return _enqueue<List<TireInspectionDraftMetadata>>(() async {
      final prefs = await SharedPreferences.getInstance();
      final index = await _loadOrRepairIndex(prefs);
      final dateKey = inspectionDate == null
          ? null
          : TireInspectionDraftKey.dateKeyFor(inspectionDate);

      final result = index.values.where((metadata) {
        return _matches(
          metadata,
          userId: userId,
          siteId: siteId,
          unitNumber: unitNumber,
          inspectionDate: dateKey,
        );
      }).toList()
        ..sort(
          (a, b) => b.updatedAt.compareTo(a.updatedAt),
        );
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
      final prefs = await SharedPreferences.getInstance();
      final index = await _loadOrRepairIndex(prefs);
      final dateKey = inspectionDate == null
          ? null
          : TireInspectionDraftKey.dateKeyFor(inspectionDate);
      final candidates = index.values.where((metadata) {
        return _matches(
          metadata,
          userId: userId,
          siteId: siteId,
          unitNumber: unitNumber,
          inspectionDate: dateKey,
        );
      }).toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      for (final metadata in candidates) {
        final token = metadata.key.storageToken;
        final rawPayload = prefs.getString(_payloadKey(token));
        final draft = rawPayload == null ? null : _tryDecodeDraft(rawPayload);
        if (draft != null && draft.key == metadata.key) {
          return draft;
        }

        await _removePayloadAndIndex(prefs, index, token);
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
      final prefs = await SharedPreferences.getInstance();
      final index = await _loadOrRepairIndex(prefs);
      final dateKey = inspectionDate == null
          ? null
          : TireInspectionDraftKey.dateKeyFor(inspectionDate);
      final tokens = index.entries
          .where(
            (entry) => _matches(
              entry.value,
              userId: userId,
              siteId: siteId,
              unitNumber: unitNumber,
              inspectionDate: dateKey,
            ),
          )
          .map((entry) => entry.key)
          .toList();

      for (final token in tokens) {
        await prefs.remove(_payloadKey(token));
        index.remove(token);
      }
      await _writeIndex(prefs, index);
      return tokens.length;
    });
  }

  /// Rebuilds metadata from valid payloads and deletes malformed entries.
  Future<List<TireInspectionDraftMetadata>> repairStorage() {
    return _enqueue<List<TireInspectionDraftMetadata>>(() async {
      final prefs = await SharedPreferences.getInstance();
      final index = await _rebuildIndex(prefs);
      final result = index.values.toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return result;
    });
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

  Future<Map<String, TireInspectionDraftMetadata>> _loadOrRepairIndex(
    SharedPreferences prefs,
  ) async {
    final rawIndex = prefs.getString(_indexPreferenceKey);
    if (rawIndex == null || rawIndex.trim().isEmpty) {
      return _rebuildIndex(prefs);
    }

    try {
      final decoded = jsonDecode(rawIndex);
      if (decoded is! Map ||
          decoded['schemaVersion'] != _storageSchemaVersion ||
          decoded['items'] is! Map) {
        return _rebuildIndex(prefs);
      }

      final result = <String, TireInspectionDraftMetadata>{};
      final items = decoded['items'] as Map;
      for (final entry in items.entries) {
        if (entry.value is! Map) return _rebuildIndex(prefs);
        final metadata = TireInspectionDraftMetadata.fromJson(
          Map<String, dynamic>.from(entry.value as Map),
        );
        final token = entry.key.toString();
        if (metadata.key.storageToken != token) {
          return _rebuildIndex(prefs);
        }
        result[token] = metadata;
      }

      final payloadTokens = _payloadTokens(prefs);
      if (payloadTokens.length != result.length ||
          !payloadTokens.every(result.containsKey)) {
        return _rebuildIndex(prefs);
      }
      return result;
    } catch (error, stackTrace) {
      log(
        'Repairing corrupt Tire Inspection draft index: $error',
        stackTrace: stackTrace,
      );
      return _rebuildIndex(prefs);
    }
  }

  Future<Map<String, TireInspectionDraftMetadata>> _rebuildIndex(
    SharedPreferences prefs,
  ) async {
    final result = <String, TireInspectionDraftMetadata>{};
    final payloadKeys = prefs
        .getKeys()
        .where((key) => key.startsWith(_payloadPreferencePrefix))
        .toList();

    for (final payloadKey in payloadKeys) {
      final rawPayload = prefs.getString(payloadKey);
      final draft = rawPayload == null ? null : _tryDecodeDraft(rawPayload);
      if (draft == null) {
        await prefs.remove(payloadKey);
        continue;
      }

      final canonicalToken = draft.key.storageToken;
      final canonicalPayloadKey = _payloadKey(canonicalToken);
      if (payloadKey != canonicalPayloadKey) {
        await prefs.setString(canonicalPayloadKey, rawPayload!);
        await prefs.remove(payloadKey);
      }

      final previous = result[canonicalToken];
      if (previous == null || draft.updatedAt.isAfter(previous.updatedAt)) {
        result[canonicalToken] = draft.toMetadata();
      }
    }

    await _writeIndex(prefs, result);
    return result;
  }

  Set<String> _payloadTokens(SharedPreferences prefs) {
    return prefs
        .getKeys()
        .where((key) => key.startsWith(_payloadPreferencePrefix))
        .map((key) => key.substring(_payloadPreferencePrefix.length))
        .toSet();
  }

  TireInspectionDraft? _tryDecodeDraft(String rawPayload) {
    try {
      final decoded = jsonDecode(rawPayload);
      if (decoded is! Map) return null;
      return TireInspectionDraft.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (error, stackTrace) {
      log(
        'Ignoring corrupt Tire Inspection draft: $error',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<void> _removePayloadAndIndex(
    SharedPreferences prefs,
    Map<String, TireInspectionDraftMetadata> index,
    String token,
  ) async {
    await prefs.remove(_payloadKey(token));
    if (index.remove(token) != null) {
      await _writeIndex(prefs, index);
    }
  }

  Future<void> _writeIndex(
    SharedPreferences prefs,
    Map<String, TireInspectionDraftMetadata> index,
  ) async {
    final items = <String, dynamic>{};
    index.forEach((token, metadata) {
      items[token] = metadata.toJson();
    });

    final saved = await prefs.setString(
      _indexPreferenceKey,
      jsonEncode(<String, dynamic>{
        'schemaVersion': _storageSchemaVersion,
        'items': items,
      }),
    );
    if (!saved) {
      throw StateError('Failed to persist Tire Inspection draft index.');
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

  String _payloadKey(String token) => '$_payloadPreferencePrefix$token';
}
