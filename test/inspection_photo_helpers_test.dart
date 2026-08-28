import 'dart:convert';

import 'package:camos/core/utils/functions/inspection_photo_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> photo(String doc, int index, String path,
        {String? position}) =>
    {
      'docId': doc,
      'posisiIndex': index,
      'filePath': path,
      if (position != null) 'tirePosition': position,
    };

void main() {
  test('300 dokumen hanya mengembalikan metadata foto dokumen terpilih', () {
    final pending = List.generate(300, (i) => photo('doc-$i', 0, '/photo-$i'));
    final selected = pendingInspectionPhotosForDocument(pending, 'doc-150');
    expect(selected, hasLength(1));
    expect(selected.single['filePath'], '/photo-150');
    expect(pending, hasLength(300));
    expect(pendingInspectionPhotosForDocument(pending, 'missing'), isEmpty);
  });

  test('antrean lama dipulihkan dari index dokumen, bukan index form', () {
    final photos = [photo('doc', 1, '/position-6')];
    expect(
        pendingInspectionPhotoPath(photos, storedIndex: 1, tirePosition: '6'),
        '/position-6');
    expect(
        pendingInspectionPhotoPath(photos, storedIndex: 0, tirePosition: '1'),
        isNull);
  });

  test(
      'metadata antrean lama dilengkapi tanpa duplikasi dan tetap sesudah restart',
      () {
    final pending = [
      photo('doc', 1, '/position-6'),
      photo('other', 1, '/other')
    ];
    expect(
        bindPendingInspectionPhotoPositions(pending, 'doc', [
          {'position': 2},
          {'position': 6},
        ]),
        isTrue);
    expect(pending, hasLength(2));
    expect(pending.first['tirePosition'], '6');
    expect(pending.last.containsKey('tirePosition'), isFalse);
    final restored = (jsonDecode(jsonEncode(pending)) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
    expect(
        pendingInspectionPhotoPath(
          pendingInspectionPhotosForDocument(restored, 'doc'),
          storedIndex: 5,
          tirePosition: '6',
        ),
        '/position-6');
  });

  test('nomor posisi lebih diutamakan daripada index yang telah berubah', () {
    final photos = [
      photo('doc', 0, '/position-6', position: '6'),
      photo('doc', 1, '/position-2', position: '2'),
    ];
    expect(
        pendingInspectionPhotoPath(photos, storedIndex: 1, tirePosition: '6'),
        '/position-6');
    expect(
        pendingInspectionPhotoPath(photos, storedIndex: 0, tirePosition: '9'),
        isNull);
  });

  test('satu foto terbaru untuk tiap posisi legacy', () {
    expect(
        pendingInspectionPhotoPath([
          photo('doc', 0, '/old'),
          photo('doc', 0, '/new'),
        ], storedIndex: 0, tirePosition: '1'),
        '/new');
  });

  test(
      'save berulang foto sama tidak menambah antrean atau mengganti identitas entry',
      () {
    final pending = <Map<String, dynamic>>[];
    expect(
        upsertPendingInspectionPhoto(pending,
            docId: 'doc', filePath: '/one', posisiIndex: 0, tirePosition: '1'),
        isTrue);
    final entry = pending.single;
    for (var i = 0; i < 20; i++) {
      expect(
          upsertPendingInspectionPhoto(pending,
              docId: 'doc',
              filePath: '/one',
              posisiIndex: 0,
              tirePosition: '1'),
          isFalse);
    }
    expect(pending, hasLength(1));
    expect(pending.single, same(entry));
  });

  test(
      'ganti foto mengganti antrean posisi itu saja, entry lama worker tidak aktif',
      () {
    final old = photo('doc', 0, '/old', position: '1');
    final pending = [
      old,
      photo('doc', 1, '/other-pos', position: '2'),
      photo('other-doc', 0, '/other-unit', position: '1')
    ];
    upsertPendingInspectionPhoto(pending,
        docId: 'doc', filePath: '/new', posisiIndex: 0, tirePosition: '1');
    expect(pending, hasLength(3));
    expect(pending.contains(old), isFalse);
    expect(pending.map((item) => item['filePath']),
        containsAll(['/new', '/other-pos', '/other-unit']));
  });

  test('duplikasi legacy dibersihkan saat foto diperbarui', () {
    final pending = [photo('doc', 0, '/old1'), photo('doc', 0, '/old2')];
    upsertPendingInspectionPhoto(pending,
        docId: 'doc', filePath: '/new', posisiIndex: 0, tirePosition: '1');
    expect(pending, hasLength(1));
    expect(pending.single['filePath'], '/new');
  });

  test('upload mengikuti nomor posisi walaupun dokumen hanya sebagian posisi',
      () {
    final positions = [
      {'position': 2},
      {'position': 6}
    ];
    expect(
        inspectionPhotoPositionIndex(positions,
            fallbackIndex: 5, tirePosition: '6'),
        1);
    expect(
        inspectionPhotoPositionIndex(positions,
            fallbackIndex: 0, tirePosition: '9'),
        -1);
    expect(inspectionPhotoPositionIndex(positions, fallbackIndex: 1), 1);
    expect(inspectionPhotoPositionIndex(positions, fallbackIndex: -1), -1);
    expect(inspectionPhotoPositionIndex(positions, fallbackIndex: 6), -1);
  });

  test('save tanpa foto baru mempertahankan pending foto offline', () {
    expect(
        inspectionPhotoFields(
            existingImages: [], existingPending: true, newLocalImagePath: null),
        {'images': [], 'imagePending': true});
  });

  test('foto yang sudah terupload dipertahankan saat hanya mengedit isian', () {
    final fields = inspectionPhotoFields(
        existingImages: ['https://example.test/photo'],
        existingPending: false,
        newLocalImagePath: null);
    expect(fields['images'], ['https://example.test/photo']);
    expect(fields['imagePending'], isFalse);
  });

  test('foto baru mengganti URL lama dan mengaktifkan pending', () {
    expect(
        inspectionPhotoFields(
            existingImages: ['https://example.test/photo'],
            existingPending: false,
            newLocalImagePath: '/new-photo'),
        {'images': [], 'imagePending': true});
  });
}
