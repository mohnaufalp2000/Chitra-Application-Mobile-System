import 'dart:io';
import 'dart:ui' as ui;

import 'package:camos/pages/pressure_gauge_digital/widget/pending_inspection_photo_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory directory;
  late File file;

  // Native image/file operations run outside the widget test's FakeAsync zone.
  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('camos-photo-preview-');
    file = File('${directory.path}/photo.png');
    final image = await createTestImage(width: 20, height: 10);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    await file.writeAsBytes(bytes!.buffer.asUint8List());
  });
  tearDownAll(() async {
    PaintingBinding.instance.imageCache.clear();
    await directory.delete(recursive: true);
  });

  testWidgets('preview menggunakan foto lokal dengan batas decode 720x720',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final provider = ResizeImage(FileImage(file),
        width: 720, height: 720, policy: ResizeImagePolicy.fit);
    final context = tester.element(find.byType(SizedBox).first);
    await tester.runAsync(() =>
        precacheImage(provider, context).timeout(const Duration(seconds: 5)));

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PendingInspectionPhotoPreview(filePath: file.path))));
    await tester.pumpAndSettle();
    final widget = tester.widget<Image>(find.byType(Image));
    final actual = widget.image as ResizeImage;
    expect(actual.width, 720);
    expect(actual.height, 720);
    expect(actual.policy, ResizeImagePolicy.fit);
    expect((actual.imageProvider as FileImage).file.path, file.path);
    expect(find.text('Foto tersimpan di perangkat • Menunggu upload'),
        findsOneWidget);
    expect(find.text('Foto lokal tidak tersedia. Silakan ambil foto ulang.'),
        findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('handler file hilang menampilkan pesan yang aman',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PendingInspectionPhotoPreview(filePath: file.path))));
    final widget = tester.widget<Image>(find.byType(Image));
    final errorView = widget.errorBuilder!(tester.element(find.byType(Image)),
        const FileSystemException('File no longer exists'), StackTrace.current);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: errorView)));
    expect(find.text('Foto lokal tidak tersedia. Silakan ambil foto ulang.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
