import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:camos/core/services/local_database/tire_inspection_draft/tire_inspection_draft_entity.dart';
import 'package:camos/core/services/model/tire_inspection_draft.dart';
import 'package:camos/core/services/tire_inspection_draft_service.dart';
import 'package:camos/objectbox.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory databaseDirectory;
  late Store store;
  late SharedPreferences legacyPreferences;
  late DateTime clock;
  late TireInspectionDraftService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    legacyPreferences = await SharedPreferences.getInstance();
    databaseDirectory =
        await Directory.systemTemp.createTemp('camos-draft-objectbox-');
    store = Store(
      getObjectBoxModel(),
      directory: databaseDirectory.path,
    );
    clock = DateTime.utc(2026, 8, 14, 12);
    service = TireInspectionDraftService.forTesting(
      store: store,
      legacyPreferences: legacyPreferences,
      clock: () => clock,
    );
  });

  tearDown(() async {
    store.close();
    if (await databaseDirectory.exists()) {
      await databaseDirectory.delete(recursive: true);
    }
  });

  test('round-trip menyimpan form dan hanya path gambar', () async {
    final key = _key(user: 'user-1', unit: 'UNIT-01');
    final draft = _draft(
      key,
      createdAt: clock.subtract(const Duration(hours: 2)),
      pressure: '110',
      extraPositionData: <String, dynamic>{
        'remarks': 'Good',
        '_hasUserInput': true,
        '_pressureFromHistory': true,
        'image': <String>['/tmp/tire.jpg|1'],
        'imageBytes': Uint8List.fromList(<int>[1, 2, 3]),
        'imageBase64': 'tidak-boleh-disimpan',
      },
      location: 'Pitstop',
      hm: '1234',
    );

    final saved = await service.saveDraft(draft);
    final restored = await service.loadDraft(key);

    expect(saved.updatedAt, clock);
    expect(restored, isNotNull);
    expect(restored!.hm, '1234');
    expect(restored.location, 'Pitstop');
    expect(restored.positions.single.fields['pressure'], '110');
    expect(restored.positions.single.fields['_hasUserInput'], isTrue);
    expect(restored.positions.single.fields['_pressureFromHistory'], isTrue);
    expect(restored.positions.single.imagePaths, <String>['/tmp/tire.jpg']);
    expect(restored.positions.single.fields, isNot(contains('imageBytes')));
    expect(restored.positions.single.fields, isNot(contains('imageBase64')));

    final entities = store.box<TireInspectionDraftEntity>().getAll();
    expect(entities, hasLength(1));
    expect(
        entities.single.payloadJson, isNot(contains('tidak-boleh-disimpan')));
  });

  test('overwrite key yang sama tidak duplikat dan mempertahankan createdAt',
      () async {
    final key = _key(user: 'user-1', unit: 'UNIT-01');
    final originalCreatedAt = clock.subtract(const Duration(hours: 4));

    await service.saveDraft(
      _draft(key, createdAt: originalCreatedAt, pressure: '100'),
    );
    clock = clock.add(const Duration(minutes: 10));
    final overwritten = await service.saveDraft(
      _draft(
        key,
        createdAt: clock,
        pressure: '125',
      ),
    );

    expect(store.box<TireInspectionDraftEntity>().count(), 1);
    expect(overwritten.createdAt.isAtSameMomentAs(originalCreatedAt), isTrue);
    expect(overwritten.updatedAt, clock);
    final restored = await service.loadDraft(key);
    expect(restored!.positions.single.fields['pressure'], '125');
  });

  test('list dan draft terbaru mempertahankan filter API lama', () async {
    final first = _key(
      user: 'user-a',
      site: '5',
      unit: 'UNIT-A',
      date: DateTime.utc(2026, 8, 14),
    );
    final second = _key(
      user: 'user-a',
      site: '7',
      unit: 'UNIT-B',
      date: DateTime.utc(2026, 8, 14),
    );
    final third = _key(
      user: 'user-b',
      site: '5',
      unit: 'UNIT-C',
      date: DateTime.utc(2026, 8, 13),
    );

    await service.saveDraft(_draft(first));
    clock = clock.add(const Duration(minutes: 1));
    await service.saveDraft(_draft(second));
    clock = clock.add(const Duration(minutes: 1));
    await service.saveDraft(_draft(third));

    final userDrafts = await service.listActiveDrafts(userId: '  user-a  ');
    expect(
      userDrafts.map((item) => item.key.unitNumber),
      <String>['UNIT-B', 'UNIT-A'],
    );

    final filtered = await service.listActiveDrafts(
      userId: 'user-a',
      siteId: '5',
      unitNumber: 'UNIT-A',
      inspectionDate: DateTime.utc(2026, 8, 14),
    );
    expect(filtered.map((item) => item.key), <TireInspectionDraftKey>[first]);

    final mostRecent = await service.loadMostRecentDraft(
      userId: 'user-a',
      inspectionDate: DateTime.utc(2026, 8, 14),
    );
    expect(mostRecent!.key, second);
  });

  test('draft dapat ditandai selesai dan dihapus berdasarkan scope', () async {
    final completedKey = _key(user: 'user-delete', unit: 'DONE-01');
    final remainingKey = _key(user: 'user-delete', unit: 'PENDING-01');
    await service.saveDraft(_draft(completedKey));
    await service.saveDraft(_draft(remainingKey));

    expect(await service.hasDraft(completedKey), isTrue);
    expect(await service.markCompleted(completedKey), isTrue);
    expect(await service.markCompleted(completedKey), isFalse);
    expect(await service.loadDraft(completedKey), isNull);

    expect(await service.deleteDrafts(userId: 'user-delete'), 1);
    expect(await service.loadDraft(remainingKey), isNull);
  });

  test('retensi 30 hari menghapus yang lebih lama dan menjaga batas tepat',
      () async {
    final referenceTime = clock;
    final expiredKey = _key(user: 'user-1', unit: 'EXPIRED');
    final boundaryKey = _key(user: 'user-1', unit: 'BOUNDARY');
    final currentKey = _key(user: 'user-1', unit: 'CURRENT');

    clock = referenceTime.subtract(const Duration(days: 30, seconds: 1));
    await service.saveDraft(_draft(expiredKey));
    clock = referenceTime.subtract(const Duration(days: 30));
    await service.saveDraft(_draft(boundaryKey));
    clock = referenceTime;
    await service.saveDraft(_draft(currentKey));

    final active = await service.listActiveDrafts(userId: 'user-1');
    expect(
      active.map((item) => item.key.unitNumber),
      <String>['CURRENT', 'BOUNDARY'],
    );
    expect(await service.loadDraft(expiredKey), isNull);
    expect(await service.loadDraft(boundaryKey), isNotNull);
  });

  test('batas default menjaga 2 draft terbaru untuk setiap user', () async {
    final keys = <TireInspectionDraftKey>[];
    for (var index = 0; index < 3; index++) {
      final key = _key(
        user: 'cap-user',
        unit: 'UNIT-${index.toString().padLeft(3, '0')}',
      );
      keys.add(key);
      await service.saveDraft(_draft(key));
      clock = clock.add(const Duration(seconds: 1));
    }

    final active = await service.listActiveDrafts(userId: 'cap-user');
    expect(TireInspectionDraftService.defaultMaxDraftsPerUser, 2);
    expect(active, hasLength(2));
    expect(
      active.map((item) => item.key.unitNumber),
      <String>['UNIT-002', 'UNIT-001'],
    );
    expect(await service.loadDraft(keys.first), isNull);
    expect(await service.loadDraft(keys.last), isNotNull);
  });

  test('batas default menjaga maksimal 300 draft di satu device', () async {
    final keys = <TireInspectionDraftKey>[];
    for (var index = 0; index < 301; index++) {
      final key = _key(
        user: 'global-user-$index',
        unit: 'GLOBAL-${index.toString().padLeft(3, '0')}',
      );
      keys.add(key);
      await service.saveDraft(_draft(key));
      clock = clock.add(const Duration(seconds: 1));
    }

    final active = await service.listActiveDrafts();
    expect(TireInspectionDraftService.defaultMaxDraftsPerDevice, 300);
    expect(active, hasLength(300));
    expect(await service.loadDraft(keys.first), isNull);
    expect(await service.loadDraft(keys.last), isNotNull);
  });

  test('migrasi legacy menghapus key lama dan aman dijalankan ulang', () async {
    const payloadPrefix = 'camos.tire_inspection.draft.v1.';
    const indexKey = 'camos.tire_inspection.drafts.index.v1';
    const corruptPayloadKey = '${payloadPrefix}payload-rusak';
    final key = _key(user: 'legacy-user', unit: 'LEGACY-01');
    final expiredKey = _key(user: 'legacy-user', unit: 'LEGACY-EXPIRED');
    final legacyDraft = _draft(
      key,
      createdAt: clock.subtract(const Duration(hours: 2)),
      updatedAt: clock.subtract(const Duration(hours: 1)),
      pressure: '98',
    );
    final expiredDraft = _draft(
      expiredKey,
      createdAt: clock.subtract(const Duration(days: 32)),
      updatedAt: clock.subtract(const Duration(days: 31)),
    );
    final payloadKey = '$payloadPrefix${key.storageToken}';
    final expiredPayloadKey = '$payloadPrefix${expiredKey.storageToken}';
    await legacyPreferences.setString(
      payloadKey,
      jsonEncode(legacyDraft.toJson()),
    );
    await legacyPreferences.setString(
      expiredPayloadKey,
      jsonEncode(expiredDraft.toJson()),
    );
    await legacyPreferences.setString(corruptPayloadKey, '{payload-rusak');
    await legacyPreferences.setString(indexKey, '{index-rusak');

    await service.prepareStorage();

    final migrated = await service.loadDraft(key);
    expect(migrated, isNotNull);
    expect(migrated!.positions.single.fields['pressure'], '98');
    expect(legacyPreferences.containsKey(payloadKey), isFalse);
    expect(legacyPreferences.containsKey(expiredPayloadKey), isFalse);
    expect(legacyPreferences.containsKey(corruptPayloadKey), isFalse);
    expect(legacyPreferences.containsKey(indexKey), isFalse);
    expect(await service.loadDraft(expiredKey), isNull);
    expect(store.box<TireInspectionDraftEntity>().count(), 1);

    await service.prepareStorage();
    expect(store.box<TireInspectionDraftEntity>().count(), 1);
    expect((await service.listActiveDrafts()).single.key, key);
  });

  test('repairStorage menghapus payload korup dan memperbaiki metadata',
      () async {
    final validKey = _key(user: 'valid-user', unit: 'VALID-01');
    await service.saveDraft(_draft(validKey, pressure: '105'));

    final box = store.box<TireInspectionDraftEntity>();
    final validEntity = box.getAll().single;
    validEntity
      ..userId = 'metadata-salah'
      ..positionCount = 999;
    box.put(validEntity);

    box.put(
      TireInspectionDraftEntity(
        storageToken: 'corrupt-token',
        userId: 'corrupt-user',
        siteId: '7',
        unitNumber: 'CORRUPT-01',
        inspectionDate: '2026-08-14',
        createdAtMillis: clock.millisecondsSinceEpoch,
        updatedAtMillis: clock.millisecondsSinceEpoch,
        positionCount: 1,
        payloadJson: '{json-rusak',
      ),
    );

    final repaired = await service.repairStorage();

    expect(repaired, hasLength(1));
    expect(repaired.single.key, validKey);
    expect(repaired.single.positionCount, 1);
    expect(box.count(), 1);
    expect(box.getAll().single.userId, 'valid-user');
  });
}

TireInspectionDraftKey _key({
  required String user,
  String site = '7',
  required String unit,
  DateTime? date,
}) {
  return TireInspectionDraftKey.forDate(
    userId: user,
    siteId: site,
    unitNumber: unit,
    inspectionDate: date ?? DateTime.utc(2026, 8, 14),
  );
}

TireInspectionDraft _draft(
  TireInspectionDraftKey key, {
  DateTime? createdAt,
  DateTime? updatedAt,
  String pressure = '100',
  String location = 'Pitstop',
  String hm = '1234',
  Map<String, dynamic> extraPositionData = const <String, dynamic>{},
}) {
  return TireInspectionDraft.fromFormData(
    key: key,
    positions: <Map<String, dynamic>>[
      <String, dynamic>{
        'position': 1,
        'pressure': pressure,
        ...extraPositionData,
      },
    ],
    tireKeys: const <String?>['tire-1'],
    location: location,
    hm: hm,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
