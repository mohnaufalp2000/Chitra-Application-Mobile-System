import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

/// Identifies one Tire Inspection draft without relying on a Firestore ID.
///
/// A draft is intentionally scoped to the user, site, unit, and local calendar
/// date so data from another shift context cannot be restored accidentally.
class TireInspectionDraftKey {
  TireInspectionDraftKey({
    required String userId,
    required String siteId,
    required String unitNumber,
    required String inspectionDate,
  })  : userId = _requiredValue(userId, 'userId'),
        siteId = _requiredValue(siteId, 'siteId'),
        unitNumber = _requiredValue(unitNumber, 'unitNumber'),
        inspectionDate = _validDateKey(inspectionDate);

  factory TireInspectionDraftKey.forDate({
    required String userId,
    required String siteId,
    required String unitNumber,
    DateTime? inspectionDate,
  }) {
    return TireInspectionDraftKey(
      userId: userId,
      siteId: siteId,
      unitNumber: unitNumber,
      inspectionDate: dateKeyFor(inspectionDate ?? DateTime.now()),
    );
  }

  factory TireInspectionDraftKey.fromJson(Map<String, dynamic> json) {
    return TireInspectionDraftKey(
      userId: json['userId']?.toString() ?? '',
      siteId: json['siteId']?.toString() ?? '',
      unitNumber: json['unitNumber']?.toString() ?? '',
      inspectionDate: json['inspectionDate']?.toString() ?? '',
    );
  }

  final String userId;
  final String siteId;
  final String unitNumber;

  /// Local calendar date in `yyyy-MM-dd` format.
  final String inspectionDate;

  /// Stable, SharedPreferences-safe representation of this identity.
  String get storageToken {
    final bytes = utf8.encode(
      jsonEncode(<String>[
        userId,
        siteId,
        unitNumber,
        inspectionDate,
      ]),
    );
    return base64Url.encode(bytes).replaceAll('=', '');
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'userId': userId,
      'siteId': siteId,
      'unitNumber': unitNumber,
      'inspectionDate': inspectionDate,
    };
  }

  static String dateKeyFor(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  static String _requiredValue(String value, String fieldName) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw FormatException('$fieldName cannot be empty.');
    }
    return normalized;
  }

  static String _validDateKey(String value) {
    final normalized = value.trim();
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(normalized);
    if (match == null) {
      throw const FormatException(
        'inspectionDate must use yyyy-MM-dd format.',
      );
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      throw const FormatException('inspectionDate is not a valid date.');
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is TireInspectionDraftKey &&
            other.userId == userId &&
            other.siteId == siteId &&
            other.unitNumber == unitNumber &&
            other.inspectionDate == inspectionDate;
  }

  @override
  int get hashCode => Object.hash(userId, siteId, unitNumber, inspectionDate);

  @override
  String toString() {
    return 'TireInspectionDraftKey('
        'userId: $userId, '
        'siteId: $siteId, '
        'unitNumber: $unitNumber, '
        'inspectionDate: $inspectionDate)';
  }
}

/// A JSON-safe snapshot of one tire position in the form.
///
/// [fields] deliberately remains flexible so adding a form field does not
/// require a storage migration. Image content is separated into [imagePaths];
/// byte arrays and base64 image fields are never persisted.
class TireInspectionPositionDraft {
  TireInspectionPositionDraft({
    required String identity,
    required String positionLabel,
    String tireKey = '',
    Map<String, dynamic> fields = const <String, dynamic>{},
    List<String> imagePaths = const <String>[],
  })  : identity = _requiredIdentity(identity),
        positionLabel = positionLabel.trim(),
        tireKey = tireKey.trim(),
        fields = Map<String, dynamic>.unmodifiable(_jsonSafeMap(fields)),
        imagePaths = List<String>.unmodifiable(_validImagePaths(imagePaths));

  factory TireInspectionPositionDraft.fromFormData(
    Map<String, dynamic> formData, {
    String? tireKey,
    String? identity,
    String? positionLabel,
  }) {
    final resolvedPosition = _firstNonEmpty(<Object?>[
      positionLabel,
      formData['position'],
      formData['posisi'],
    ]);
    final resolvedTireKey = _firstNonEmpty(<Object?>[
      tireKey,
      formData['kunci_tire'],
      formData['kunciTire'],
    ]);
    final resolvedIdentity = _firstNonEmpty(<Object?>[
      identity,
      resolvedTireKey,
      formData['idInventory'],
      formData['id_inventory'],
      resolvedPosition,
    ]);

    final safeFields = <String, dynamic>{};
    formData.forEach((String key, dynamic value) {
      if (!_isImageContainerKey(key)) {
        safeFields[key] = value;
      }
    });

    return TireInspectionPositionDraft(
      identity: resolvedIdentity,
      positionLabel: resolvedPosition,
      tireKey: resolvedTireKey,
      fields: safeFields,
      imagePaths: _extractImagePaths(formData),
    );
  }

  factory TireInspectionPositionDraft.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final rawImagePaths = json['imagePaths'];

    return TireInspectionPositionDraft(
      identity: json['identity']?.toString() ?? '',
      positionLabel: json['positionLabel']?.toString() ?? '',
      tireKey: json['tireKey']?.toString() ?? '',
      fields: rawFields is Map
          ? Map<String, dynamic>.from(rawFields)
          : const <String, dynamic>{},
      imagePaths: rawImagePaths is List
          ? rawImagePaths
              .whereType<String>()
              .map((String value) => value.trim())
              .where((String value) => value.isNotEmpty)
              .toList()
          : const <String>[],
    );
  }

  final String identity;
  final String positionLabel;
  final String tireKey;
  final Map<String, dynamic> fields;
  final List<String> imagePaths;

  /// Returns a fresh map suitable for merging back into the form's `position`
  /// list. The `image` value contains paths only.
  Map<String, dynamic> toFormData() {
    return <String, dynamic>{
      ..._jsonSafeMap(fields),
      if (positionLabel.isNotEmpty && fields['position'] == null)
        'position': positionLabel,
      'image': List<String>.from(imagePaths),
    };
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'identity': identity,
      'positionLabel': positionLabel,
      'tireKey': tireKey,
      'fields': _jsonSafeMap(fields),
      'imagePaths': List<String>.from(imagePaths),
    };
  }

  static String _requiredIdentity(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw const FormatException('A tire position identity is required.');
    }
    return normalized;
  }

  static List<String> _extractImagePaths(Map<String, dynamic> formData) {
    final result = <String>[];
    final candidates = <dynamic>[
      formData['image'],
      formData['images'],
      formData['imagePaths'],
    ];

    for (final candidate in candidates) {
      final values = candidate is Iterable ? candidate : <dynamic>[candidate];
      for (final value in values) {
        String path = '';
        if (value is String) {
          path = value.split('|').first.trim();
        } else if (value is Map) {
          path = _firstNonEmpty(<Object?>[
            value['path'],
            value['filePath'],
            value['localPath'],
          ]);
        }

        if (_isSafeImagePath(path) && !result.contains(path)) {
          result.add(path);
        }
      }
    }
    return result;
  }

  static List<String> _validImagePaths(Iterable<String> paths) {
    final result = <String>[];
    for (final rawPath in paths) {
      final path = rawPath.split('|').first.trim();
      if (_isSafeImagePath(path) && !result.contains(path)) {
        result.add(path);
      }
    }
    return result;
  }

  static bool _isSafeImagePath(String value) {
    if (value.isEmpty || value.length > 2048) return false;
    return !value.toLowerCase().startsWith('data:image/');
  }

  static String _firstNonEmpty(Iterable<Object?> values) {
    for (final value in values) {
      final normalized = value?.toString().trim() ?? '';
      if (normalized.isNotEmpty) return normalized;
    }
    return '';
  }
}

/// Complete recoverable state for one unfinished Tire Inspection form.
class TireInspectionDraft {
  TireInspectionDraft({
    required this.key,
    required this.positions,
    String periodType = 'PI',
    String location = '',
    String hm = '',
    String unitModel = '',
    String siteName = '',
    String userDisplayName = '',
    Map<String, dynamic> formData = const <String, dynamic>{},
    Map<String, dynamic> navigationData = const <String, dynamic>{},
    DateTime? createdAt,
    DateTime? updatedAt,
    this.schemaVersion = currentSchemaVersion,
  })  : periodType = periodType.trim().isEmpty ? 'PI' : periodType.trim(),
        location = location.trim(),
        hm = hm.trim(),
        unitModel = unitModel.trim(),
        siteName = siteName.trim(),
        userDisplayName = userDisplayName.trim(),
        formData = Map<String, dynamic>.unmodifiable(_jsonSafeMap(formData)),
        navigationData = Map<String, dynamic>.unmodifiable(
          _jsonSafeMap(navigationData),
        ),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now() {
    if (schemaVersion < 1) {
      throw const FormatException('Invalid Tire Inspection draft version.');
    }
  }

  factory TireInspectionDraft.fromFormData({
    required TireInspectionDraftKey key,
    required List<Map<String, dynamic>> positions,
    List<String?> tireKeys = const <String?>[],
    String periodType = 'PI',
    String location = '',
    String hm = '',
    String unitModel = '',
    String siteName = '',
    String userDisplayName = '',
    Map<String, dynamic> formData = const <String, dynamic>{},
    Map<String, dynamic> navigationData = const <String, dynamic>{},
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final positionDrafts = <TireInspectionPositionDraft>[];
    for (var index = 0; index < positions.length; index++) {
      positionDrafts.add(
        TireInspectionPositionDraft.fromFormData(
          positions[index],
          tireKey: index < tireKeys.length ? tireKeys[index] : null,
        ),
      );
    }

    return TireInspectionDraft(
      key: key,
      positions: positionDrafts,
      periodType: periodType,
      location: location,
      hm: hm,
      unitModel: unitModel,
      siteName: siteName,
      userDisplayName: userDisplayName,
      formData: formData,
      navigationData: navigationData,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory TireInspectionDraft.fromJson(Map<String, dynamic> json) {
    final rawKey = json['key'];
    final rawPositions = json['positions'];
    if (rawKey is! Map || rawPositions is! List) {
      throw const FormatException('Invalid Tire Inspection draft payload.');
    }

    final parsedPositions = <TireInspectionPositionDraft>[];
    for (final rawPosition in rawPositions) {
      if (rawPosition is! Map) {
        throw const FormatException('Invalid tire position draft payload.');
      }
      parsedPositions.add(
        TireInspectionPositionDraft.fromJson(
          Map<String, dynamic>.from(rawPosition),
        ),
      );
    }

    return TireInspectionDraft(
      key: TireInspectionDraftKey.fromJson(
        Map<String, dynamic>.from(rawKey),
      ),
      positions: parsedPositions,
      periodType: json['periodType']?.toString() ?? 'PI',
      location: json['location']?.toString() ?? '',
      hm: json['hm']?.toString() ?? '',
      unitModel: json['unitModel']?.toString() ?? '',
      siteName: json['siteName']?.toString() ?? '',
      userDisplayName: json['userDisplayName']?.toString() ?? '',
      formData: json['formData'] is Map
          ? Map<String, dynamic>.from(json['formData'] as Map)
          : const <String, dynamic>{},
      navigationData: json['navigationData'] is Map
          ? Map<String, dynamic>.from(json['navigationData'] as Map)
          : const <String, dynamic>{},
      createdAt: _requiredDateTime(json['createdAt'], 'createdAt'),
      updatedAt: _requiredDateTime(json['updatedAt'], 'updatedAt'),
      schemaVersion: int.tryParse(json['schemaVersion']?.toString() ?? '') ?? 0,
    );
  }

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final TireInspectionDraftKey key;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String periodType;
  final String location;
  final String hm;
  final String unitModel;
  final String siteName;
  final String userDisplayName;
  final List<TireInspectionPositionDraft> positions;
  final Map<String, dynamic> formData;
  final Map<String, dynamic> navigationData;

  TireInspectionDraft copyWith({
    List<TireInspectionPositionDraft>? positions,
    String? periodType,
    String? location,
    String? hm,
    String? unitModel,
    String? siteName,
    String? userDisplayName,
    Map<String, dynamic>? formData,
    Map<String, dynamic>? navigationData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TireInspectionDraft(
      key: key,
      positions: positions ?? this.positions,
      periodType: periodType ?? this.periodType,
      location: location ?? this.location,
      hm: hm ?? this.hm,
      unitModel: unitModel ?? this.unitModel,
      siteName: siteName ?? this.siteName,
      userDisplayName: userDisplayName ?? this.userDisplayName,
      formData: formData ?? this.formData,
      navigationData: navigationData ?? this.navigationData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      schemaVersion: schemaVersion,
    );
  }

  TireInspectionDraftMetadata toMetadata() {
    return TireInspectionDraftMetadata(
      key: key,
      createdAt: createdAt,
      updatedAt: updatedAt,
      periodType: periodType,
      location: location,
      unitModel: unitModel,
      siteName: siteName,
      userDisplayName: userDisplayName,
      positionCount: positions.length,
      imageCount: positions.fold<int>(
        0,
        (int total, TireInspectionPositionDraft item) =>
            total + item.imagePaths.length,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'key': key.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'periodType': periodType,
      'location': location,
      'hm': hm,
      'unitModel': unitModel,
      'siteName': siteName,
      'userDisplayName': userDisplayName,
      'positions': positions
          .map((TireInspectionPositionDraft item) => item.toJson())
          .toList(),
      'formData': _jsonSafeMap(formData),
      'navigationData': _jsonSafeMap(navigationData),
    };
  }
}

/// Lightweight data used to show a "continue unfinished inspection" prompt
/// without decoding every full form payload.
class TireInspectionDraftMetadata {
  TireInspectionDraftMetadata({
    required this.key,
    required this.createdAt,
    required this.updatedAt,
    required this.positionCount,
    required this.imageCount,
    String periodType = 'PI',
    String location = '',
    String unitModel = '',
    String siteName = '',
    String userDisplayName = '',
  })  : periodType = periodType.trim().isEmpty ? 'PI' : periodType.trim(),
        location = location.trim(),
        unitModel = unitModel.trim(),
        siteName = siteName.trim(),
        userDisplayName = userDisplayName.trim() {
    if (positionCount < 0 || imageCount < 0) {
      throw const FormatException('Invalid Tire Inspection draft counters.');
    }
  }

  factory TireInspectionDraftMetadata.fromJson(Map<String, dynamic> json) {
    final rawKey = json['key'];
    if (rawKey is! Map) {
      throw const FormatException('Invalid Tire Inspection draft metadata.');
    }

    return TireInspectionDraftMetadata(
      key: TireInspectionDraftKey.fromJson(
        Map<String, dynamic>.from(rawKey),
      ),
      createdAt: _requiredDateTime(json['createdAt'], 'createdAt'),
      updatedAt: _requiredDateTime(json['updatedAt'], 'updatedAt'),
      periodType: json['periodType']?.toString() ?? 'PI',
      location: json['location']?.toString() ?? '',
      unitModel: json['unitModel']?.toString() ?? '',
      siteName: json['siteName']?.toString() ?? '',
      userDisplayName: json['userDisplayName']?.toString() ?? '',
      positionCount:
          int.tryParse(json['positionCount']?.toString() ?? '') ?? -1,
      imageCount: int.tryParse(json['imageCount']?.toString() ?? '') ?? -1,
    );
  }

  final TireInspectionDraftKey key;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String periodType;
  final String location;
  final String unitModel;
  final String siteName;
  final String userDisplayName;
  final int positionCount;
  final int imageCount;

  bool get hasImages => imageCount > 0;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'key': key.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'periodType': periodType,
      'location': location,
      'unitModel': unitModel,
      'siteName': siteName,
      'userDisplayName': userDisplayName,
      'positionCount': positionCount,
      'imageCount': imageCount,
    };
  }
}

DateTime _requiredDateTime(dynamic rawValue, String fieldName) {
  final value = rawValue?.toString().trim() ?? '';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('$fieldName is not a valid ISO-8601 date.');
  }
  return parsed;
}

bool _isImageContainerKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return normalized == 'image' ||
      normalized == 'images' ||
      normalized == 'imagepath' ||
      normalized == 'imagepaths' ||
      normalized == 'imagebytes' ||
      normalized == 'picture' ||
      normalized == 'pictures' ||
      normalized == 'photo' ||
      normalized == 'photos' ||
      normalized.contains('base64');
}

bool _isBinaryFieldKey(String key) {
  final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  return _isImageContainerKey(key) ||
      normalized.contains('base64') ||
      normalized.contains('bytes') ||
      normalized == 'blob' ||
      normalized == 'bytebuffer' ||
      normalized == 'datauri';
}

Map<String, dynamic> _jsonSafeMap(Map<dynamic, dynamic> source) {
  final seen = HashSet<Object>.identity();
  final result = _jsonSafeValue(source, seen, 0);
  return result is Map<String, dynamic> ? result : <String, dynamic>{};
}

dynamic _jsonSafeValue(dynamic value, Set<Object> seen, int depth) {
  if (depth > 30 || value is TypedData || value is ByteBuffer) {
    return _omittedJsonValue;
  }

  if (value == null || value is String || value is bool || value is int) {
    return value;
  }
  if (value is double) {
    return value.isFinite ? value : _omittedJsonValue;
  }
  if (value is num) {
    final converted = value.toDouble();
    return converted.isFinite ? value : _omittedJsonValue;
  }
  if (value is DateTime) {
    return value.toIso8601String();
  }

  if (value is Map) {
    if (!seen.add(value)) return _omittedJsonValue;
    final result = <String, dynamic>{};
    value.forEach((dynamic rawKey, dynamic rawValue) {
      final key = rawKey.toString();
      if (_isBinaryFieldKey(key)) return;
      final safeValue = _jsonSafeValue(rawValue, seen, depth + 1);
      if (!identical(safeValue, _omittedJsonValue)) {
        result[key] = safeValue;
      }
    });
    seen.remove(value);
    return result;
  }

  if (value is Iterable) {
    if (!seen.add(value)) return _omittedJsonValue;
    final result = <dynamic>[];
    for (final item in value) {
      final safeItem = _jsonSafeValue(item, seen, depth + 1);
      if (!identical(safeItem, _omittedJsonValue)) {
        result.add(safeItem);
      }
    }
    seen.remove(value);
    return result;
  }

  // Unsupported values (File, XFile, controllers, Firestore objects, etc.)
  // are intentionally omitted instead of being stringified unpredictably.
  return _omittedJsonValue;
}

const Object _omittedJsonValue = Object();
