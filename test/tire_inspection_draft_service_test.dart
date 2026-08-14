import 'dart:typed_data';

import 'package:camos/core/services/model/tire_inspection_draft.dart';
import 'package:camos/core/services/tire_inspection_draft_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('draft menyimpan nilai form dan hanya menyimpan path gambar', () async {
    final key = TireInspectionDraftKey.forDate(
      userId: 'user-1',
      siteId: '7',
      unitNumber: 'UNIT-01',
      inspectionDate: DateTime(2026, 8, 13),
    );
    final draft = TireInspectionDraft.fromFormData(
      key: key,
      positions: <Map<String, dynamic>>[
        <String, dynamic>{
          'position': 1,
          'pressure': '110',
          'remarks': 'Good',
          'image': <String>['/tmp/tire.jpg|1'],
          'imageBytes': Uint8List.fromList(<int>[1, 2, 3]),
          'imageBase64': 'tidak-boleh-disimpan',
        },
      ],
      tireKeys: const <String?>['tire-1'],
      location: 'Pitstop',
      hm: '1234',
    );

    await TireInspectionDraftService.instance.saveDraft(draft);
    final restored = await TireInspectionDraftService.instance.loadDraft(key);

    expect(restored, isNotNull);
    expect(restored!.hm, '1234');
    expect(restored.location, 'Pitstop');
    expect(restored.positions.single.fields['pressure'], '110');
    expect(restored.positions.single.imagePaths, <String>['/tmp/tire.jpg']);
    expect(restored.positions.single.fields, isNot(contains('imageBytes')));
    expect(restored.positions.single.fields, isNot(contains('imageBase64')));
  });

  test('draft dapat didaftar dan dihapus setelah inspeksi selesai', () async {
    final key = TireInspectionDraftKey.forDate(
      userId: 'user-2',
      siteId: '5',
      unitNumber: 'UNIT-02',
      inspectionDate: DateTime(2026, 8, 13),
    );
    final draft = TireInspectionDraft.fromFormData(
      key: key,
      positions: <Map<String, dynamic>>[
        <String, dynamic>{'position': 1, 'pressure': '95'},
      ],
    );

    await TireInspectionDraftService.instance.saveDraft(draft);
    final active = await TireInspectionDraftService.instance
        .listActiveDrafts(userId: 'user-2');

    expect(active, hasLength(1));
    expect(active.single.key, key);
    expect(
        await TireInspectionDraftService.instance.markCompleted(key), isTrue);
    expect(await TireInspectionDraftService.instance.loadDraft(key), isNull);
  });
}
