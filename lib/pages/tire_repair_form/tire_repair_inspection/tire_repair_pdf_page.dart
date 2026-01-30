import 'dart:io';
import 'dart:typed_data';

import '../../../core/styles/asset_path.dart';
import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/functions/functions.dart';
import '../../../core/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as p;
import 'package:uuid/uuid.dart';

class TireRepairPDFPage extends StatefulWidget {
  static const routeName = '/tire-repair-pdf-page';
  const TireRepairPDFPage({super.key});

  @override
  State<TireRepairPDFPage> createState() => _TireRepairPDFPageState();
}

class _TireRepairPDFPageState extends State<TireRepairPDFPage> {
  final Map<String, List<dynamic>> categorizedImages = {};
  final Map<String, dynamic> data = {};
  // final Set<String> selectedImages = {}; // Menyimpan path yang dipilih
  List<String> selectedImages = [];
  List<String> selectedImageTypes = [];
  Map<String, double> imageRotations = {};
  bool _isGeneratingPdf = false;
  double _pdfProgress = 0; // 0.0 – 1.0

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

    // simpan data tire repair
    data.addAll(args);

    // Simpan ke map gambar kategori untuk looping dinamis
    categorizedImages.addAll({
      'Serial Number': data['sn_pic'],
      'Area Sidewall': data['sidewall_pic'],
      'Area Shoulder': data['shoulder_pic'],
      'Area Bead': data['bead_pic'],
      'Area Tread': data['threat_pic'],
      'Area Inner Linner': data['inner_linner_pic'],
      'Area Chaffer': data['chaffer_pic'],
    });
  }

  void toggleImageSelection(String url, String type) {
    int index = selectedImages.indexOf(url);

    if (index != -1) {
      selectedImages.removeAt(index);
      selectedImageTypes.removeAt(index);
    } else {
      selectedImages.add(url);
      selectedImageTypes.add(type);
    }

    setState(() {});
  }

  String formatDate(String dateStr) {
    // Parsing string ke dalam DateTime
    DateTime date = DateTime.parse(dateStr);

    // Format tanggal sesuai keinginan
    String formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(date);

    return formattedDate;
  }

  Future<Uint8List> getImageFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  }

  void rotateImage(String imagePath) {
    setState(() {
      double currentRotation = imageRotations[imagePath] ?? 0.0;
      imageRotations[imagePath] = currentRotation + (90 * math.pi / 180);
    });
  }

  Future<void> generateInspectionPdf({
    required List<String> selectedImages,
    required List<String> selectedImageTypes,
    required Map<String, double> imageRotations,
    required Map<String, dynamic> data,
    required String imagePath,
    required Function(double) onProgress,
  }) async {
    final totalStep = selectedImages.length + 2;
    int currentStep = 0;

    void update() {
      currentStep++;
      onProgress(currentStep / totalStep);
    }

    // Step 1: init PDF
    await Future.delayed(const Duration(milliseconds: 300));
    update();

    // Step 2: proses gambar
    for (final image in selectedImages) {
      await Future.delayed(const Duration(milliseconds: 300));
      update();
    }

    // Step terakhir: save file
    await Future.delayed(const Duration(milliseconds: 300));
    update();
    List<Map<String, dynamic>> selectedWithType = [];

    for (int i = 0; i < selectedImages.length; i++) {
      final imagePath = selectedImages[i];
      final type = selectedImageTypes[i];
      final rotation = imageRotations[imagePath] ?? 0.0;

      selectedWithType.add({
        'image': imagePath,
        'type': type,
        'rotation': rotation,
      });
    }

    final snImages = selectedWithType
        .where((img) => img['type'] == 'Serial Number')
        .take(1)
        .toList();

    final injuryImages = selectedWithType
        .where((img) => img['type'] != 'Serial Number')
        .take(3)
        .toList();

    final selectedForPdf = [...snImages, ...injuryImages];
    print('selected for pdf : ${selectedForPdf}');

    // Image 1
    final Uint8List imageData1 =
        await getImageFromUrl(selectedForPdf[0]['image'] ?? '');
    final image1 = p.MemoryImage(imageData1);

    // Image 2
    final Uint8List imageData2 =
        await getImageFromUrl(selectedForPdf[1]['image'] ?? '');
    final image2 = p.MemoryImage(imageData2);

    // Image 3
    final Uint8List imageData3 =
        await getImageFromUrl(selectedForPdf[2]['image'] ?? '');
    final image3 = p.MemoryImage(imageData3);

    // Image 4
    final Uint8List imageData4 =
        await getImageFromUrl(selectedForPdf[3]['image'] ?? '');
    final image4 = p.MemoryImage(imageData4);

    final pdf = p.Document();

    final logoCp = (await rootBundle.load('${imagePath}/cp_logo_image.png'))
        .buffer
        .asUint8List();

    pdf.addPage(p.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: p.EdgeInsets.zero,
        orientation: p.PageOrientation.landscape,
        build: (p.Context context) {
          return [
            p.Container(
              height: 570,
              width: 830,
              margin: p.EdgeInsets.only(right: 12, left: 12, top: 12),
              padding: p.EdgeInsets.symmetric(horizontal: 12),
              decoration:
                  p.BoxDecoration(border: p.Border.all(color: PdfColors.blue)),
              child: p.Column(
                  crossAxisAlignment: p.CrossAxisAlignment.start,
                  children: [
                    p.Row(
                        mainAxisAlignment: p.MainAxisAlignment.spaceBetween,
                        children: [
                          p.SizedBox(
                            width: 150,
                            height: 100,
                            child: p.Image(p.MemoryImage(logoCp)),
                          ),
                          p.Text('TIRE REPAIR INSPECTION REPORT',
                              style: p.TextStyle(
                                fontSize: 18,
                              )),
                          p.Container(
                            width: 150,
                            height: 100,
                          ),
                        ]),
                    p.SizedBox(
                      height: 10,
                    ),
                    p.Row(
                        mainAxisAlignment: p.MainAxisAlignment.start,
                        children: [
                          p.Column(
                              crossAxisAlignment: p.CrossAxisAlignment.start,
                              children: [
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width:
                                          150, // Sesuaikan lebar sesuai kebutuhan
                                      child: p.Text('Date Inspect',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text(
                                          '${formatDate(data['date_inspect'])}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Customer',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text('${data['customer']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Site',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text('${data['site']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Report By',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text('${data['report_by']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Padding(
                                    padding:
                                        p.EdgeInsets.symmetric(vertical: 12),
                                    child: p.Container(
                                        color: PdfColors.black,
                                        width: 320,
                                        height: 4)),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Tire Size',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text('${data['tire_size']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Serial Number',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text('${data['sn']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Brand',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text('${data['brand']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Type Construction',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text(
                                          '${data['type_construction']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Pattern',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text('${data['pattern']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('RTD ( mm )',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text(
                                          '${data['rtd1']}/${data['rtd2']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('No. Cargo Manifest',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text(
                                          '${data['no_cargo_manifest']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Date Received',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text(
                                          '${formatDate(data['date_received'])}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Status',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text('${data['status']}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                p.SizedBox(height: 8),
                                p.Row(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    p.Container(
                                      width: 150,
                                      child: p.Text('Remarks',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                    p.Text(' : ',
                                        style: p.TextStyle(fontSize: 12)),
                                    p.Container(
                                      width: 170,
                                      child: p.Text(
                                          '${data['remarks'] ?? 'None'}',
                                          style: p.TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                                (data['status'] != 'REJECT')
                                    ? p.Column(children: [
                                        p.SizedBox(height: 8),
                                        p.Row(
                                          crossAxisAlignment:
                                              p.CrossAxisAlignment.start,
                                          children: [
                                            p.Container(
                                              width: 150,
                                              child: p.Text('Category',
                                                  style: p.TextStyle(
                                                      fontSize: 12)),
                                            ),
                                            p.Text(' : ',
                                                style:
                                                    p.TextStyle(fontSize: 12)),
                                            p.Container(
                                              width: 170,
                                              child: p.Text(
                                                  '${data['repair_duration'] ?? 'None'}',
                                                  style: p.TextStyle(
                                                      fontSize: 12)),
                                            ),
                                          ],
                                        ),
                                      ])
                                    : p.Container(),
                              ]),
                          p.SizedBox(width: 16),
                          p.Column(
                            children: [
                              p.Container(
                                decoration: p.BoxDecoration(
                                  border: p.Border.all(
                                      color: PdfColors.black,
                                      width: 1), // Border sekeliling row
                                ),
                                child: p.Column(
                                  children: [
                                    p.Row(children: [
                                      p.Column(children: [
                                        p.Container(
                                          decoration: p.BoxDecoration(
                                            border: p.Border.all(
                                                color: PdfColors.black,
                                                width:
                                                    1), // Border untuk gambar
                                          ),
                                          child: p.ClipRRect(
                                            child: p.SizedBox(
                                              width: 200,
                                              height: 160,
                                              child: p.Transform.rotate(
                                                angle: -(selectedForPdf[0]
                                                    ['rotation']),
                                                child: p.Image(image1,
                                                    fit: p.BoxFit.cover),
                                              ),
                                            ),
                                          ),
                                        ),
                                        p.Container(
                                          width: 200,
                                          decoration: p.BoxDecoration(
                                            border: p.Border.all(
                                                color: PdfColors.black,
                                                width: 1), // Border untuk text
                                          ),
                                          child: p.Padding(
                                            padding: p.EdgeInsets.all(4),
                                            child: p.Center(
                                                child: p.Text('Serial Number',
                                                    textAlign:
                                                        p.TextAlign.center,
                                                    style: const p.TextStyle(
                                                        fontSize: 20))),
                                          ),
                                        )
                                      ]),
                                      p.SizedBox(width: 12),
                                      p.Column(children: [
                                        p.Container(
                                          decoration: p.BoxDecoration(
                                            border: p.Border.all(
                                                color: PdfColors.black,
                                                width: 1),
                                          ),
                                          child: p.ClipRRect(
                                            child: p.SizedBox(
                                              width: 200,
                                              height: 160,
                                              child: p.Transform.rotate(
                                                angle: -(selectedForPdf[1]
                                                    ['rotation']),
                                                child: p.Image(image2,
                                                    fit: p.BoxFit.cover),
                                              ),
                                            ),
                                          ),
                                        ),
                                        p.Container(
                                          width: 200,
                                          decoration: p.BoxDecoration(
                                            border: p.Border.all(
                                                color: PdfColors.black,
                                                width: 1),
                                          ),
                                          child: p.Padding(
                                            padding: p.EdgeInsets.all(4),
                                            child: p.Center(
                                                child: p.Text(
                                                    '${selectedForPdf[1]['type'] ?? ''}',
                                                    textAlign:
                                                        p.TextAlign.center,
                                                    style: p.TextStyle(
                                                        fontSize: 20))),
                                          ),
                                        )
                                      ])
                                    ]),
                                    p.SizedBox(height: 24),
                                    p.Row(children: [
                                      p.Column(children: [
                                        p.Container(
                                          decoration: p.BoxDecoration(
                                            border: p.Border.all(
                                                color: PdfColors.black,
                                                width: 1),
                                          ),
                                          child: p.ClipRRect(
                                            child: p.SizedBox(
                                              width: 200,
                                              height: 160,
                                              child: p.Transform.rotate(
                                                angle: -(selectedForPdf[2]
                                                    ['rotation']),
                                                child: p.Image(image3,
                                                    fit: p.BoxFit.cover),
                                              ),
                                            ),
                                          ),
                                        ),
                                        p.Container(
                                          width: 200,
                                          decoration: p.BoxDecoration(
                                            border: p.Border.all(
                                                color: PdfColors.black,
                                                width: 1),
                                          ),
                                          child: p.Padding(
                                            padding: p.EdgeInsets.all(4),
                                            child: p.Center(
                                                child: p.Text(
                                                    '${selectedForPdf[2]['type'] ?? ''}',
                                                    textAlign:
                                                        p.TextAlign.center,
                                                    style: p.TextStyle(
                                                        fontSize: 20))),
                                          ),
                                        )
                                      ]),
                                      p.SizedBox(width: 12),
                                      p.Column(children: [
                                        p.Container(
                                          decoration: p.BoxDecoration(
                                            border: p.Border.all(
                                                color: PdfColors.black,
                                                width: 1),
                                          ),
                                          child: p.ClipRRect(
                                            child: p.SizedBox(
                                              width: 200,
                                              height: 160,
                                              child: p.Transform.rotate(
                                                angle: -(selectedForPdf[3]
                                                    ['rotation']),
                                                child: p.Image(image4,
                                                    fit: p.BoxFit.cover),
                                              ),
                                            ),
                                          ),
                                        ),
                                        p.Container(
                                          width: 200,
                                          decoration: p.BoxDecoration(
                                            border: p.Border.all(
                                                color: PdfColors.black,
                                                width: 1),
                                          ),
                                          child: p.Padding(
                                            padding: p.EdgeInsets.all(4),
                                            child: p.Center(
                                                child: p.Text(
                                                    '${selectedForPdf[3]['type'] ?? ''}',
                                                    textAlign:
                                                        p.TextAlign.center,
                                                    style: p.TextStyle(
                                                        fontSize: 20))),
                                          ),
                                        )
                                      ])
                                    ]),
                                  ],
                                ),
                              )
                            ],
                          )
                        ]),
                  ]),
            ),
            p.NewPage(),
            p.Container(
              height: 570,
              width: 830,
              margin: p.EdgeInsets.only(right: 12, left: 12, top: 12),
              padding: p.EdgeInsets.symmetric(horizontal: 24),
              decoration:
                  p.BoxDecoration(border: p.Border.all(color: PdfColors.blue)),
              child: p.Column(
                  crossAxisAlignment: p.CrossAxisAlignment.start,
                  children: [
                    p.Row(
                        mainAxisAlignment: p.MainAxisAlignment.spaceBetween,
                        children: [
                          p.SizedBox(
                            width: 100,
                            height: 50,
                            child: p.Image(p.MemoryImage(logoCp)),
                          ),
                          p.Text('TIRE REPAIR INSPECTION REPORT',
                              style: p.TextStyle(
                                fontSize: 14,
                              )),
                          p.Container(
                            width: 100,
                            height: 50,
                          ),
                        ]),
                    p.SizedBox(
                      height: 10,
                    ),
                    p.Column(
                        crossAxisAlignment: p.CrossAxisAlignment.start,
                        children: [
                          p.Container(
                            width: double.infinity,
                            padding: const p.EdgeInsets.symmetric(vertical: 4),
                            decoration: p.BoxDecoration(
                              border: p.Border.all(width: 1),
                            ),
                            child: p.Center(
                              child: p.Text(
                                'Team Repairman',
                                style: p.TextStyle(
                                  fontSize: 14,
                                  fontWeight: p.FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          p.Container(
                            width: double.infinity,
                            child: p.Table(
                              border: p.TableBorder.all(width: 1),
                              columnWidths: {
                                0: const p.FixedColumnWidth(40), // No
                                1: const p.FixedColumnWidth(300), // Nama
                                2: const p.FixedColumnWidth(100), // B/N
                                3: const p.FixedColumnWidth(100), // E-Sign
                              },
                              children: [
                                // =======================
                                // HEADER ROW
                                // =======================
                                p.TableRow(
                                  decoration: const p.BoxDecoration(),
                                  children: [
                                    _tableHeader('No'),
                                    _tableHeader('Nama'),
                                    _tableHeader('B/N'),
                                    _tableHeader('E-Sign'),
                                  ],
                                ),

                                // =======================
                                // DATA ROWS
                                // =======================
                                // _tableRow('1', 'IDHAM DALIWENG', 'CO25262', ''),
                                // _tableRow('2', 'ANDRE ARIYANTO', 'CO48707', ''),
                                // _tableRow('3', 'GILDEN FIERY', 'CO48587', ''),
                                _tableRow('', '', '', ''),
                                _tableRow('', '', '', ''),
                                _tableRow('', '', '', ''),
                              ],
                            ),
                          ),
                          p.SizedBox(height: 12),
                          p.Container(
                            width: double.infinity,
                            padding: const p.EdgeInsets.all(8),
                            child: p.RichText(
                              textAlign: p.TextAlign.justify,
                              text: p.TextSpan(
                                style: const p.TextStyle(
                                  fontSize: 10,
                                ),
                                children: [
                                  const p.TextSpan(
                                    text:
                                        'Berdasarkan spesifikasi dan hasil inspeksi kondisi luka pada tire tersebut, maka kami menyatakan ',
                                  ),
                                  p.TextSpan(
                                    text: 'layak dan aman',
                                    style: p.TextStyle(
                                      fontWeight: p.FontWeight.bold,
                                      decoration: p.TextDecoration.underline,
                                    ),
                                  ),
                                  const p.TextSpan(
                                    text: ' untuk di lanjutkan proses ',
                                  ),
                                  p.TextSpan(
                                    text: 'repair',
                                    style: p.TextStyle(
                                      fontWeight: p.FontWeight.bold,
                                      decoration: p.TextDecoration.underline,
                                    ),
                                  ),
                                  const p.TextSpan(
                                    text:
                                        '. Kami mohon approval untuk kelengkapan berkas sebagai proses repair selanjutnya.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                          p.Container(
                            width: double.infinity,
                            child: p.Table(
                              border: p.TableBorder.all(width: 1),
                              columnWidths: {
                                0: const p.FixedColumnWidth(30), // Label
                                1: const p.FixedColumnWidth(100), // Content
                              },
                              children: [
                                // =======================
                                // APPROVAL
                                // =======================
                                p.TableRow(
                                  children: [
                                    _leftLabel('Approval'),
                                    _signatureCell(
                                      name: '',
                                      // signedBy:
                                      //     'Digitally signed by\nAulia Rahman',
                                      // reason:
                                      //     'Reason: I am the author of this document',
                                      // location: 'Location:',
                                      // date: 'Date: 2026-01-20\n08:58:08 +08:00',
                                      signatureImage: '', // Uint8List
                                    ),
                                  ],
                                ),
                                _responsibleRow(
                                  'Responsible Person: Inspector Repairman',
                                ),

                                // =======================
                                // ACKNOWLEDGE 1
                                // =======================
                                p.TableRow(
                                  children: [
                                    _leftLabel('Approval'),
                                    _signatureCell(
                                      name: '',
                                      // signedBy:
                                      //     'Digitally signed by\nAndika Septiadi',
                                      // reason:
                                      //     'Reason: I agree this document to continue',
                                      // location: 'Location:',
                                      // date: 'Date: 2026-01-20\n08:58:08 +08:00',
                                      signatureImage: 'signatureAndika',
                                    ),
                                  ],
                                ),
                                _responsibleRow(
                                  'Responsible Person: Approval PJO Chitra Paratama Site',
                                ),

                                // =======================
                                // ACKNOWLEDGE 2
                                // =======================
                                p.TableRow(
                                  children: [
                                    _leftLabel('Approval'),
                                    _signatureCell(
                                      name: '',
                                      // signedBy: 'Digitally signed by dhh4009',
                                      // reason: 'DN: cn=dhh4009',
                                      // location: '',
                                      // date: 'Date: 2026.01.20 11:12:58 +0800',
                                      signatureImage: 'null',
                                    ),
                                  ],
                                ),
                                _responsibleRow(
                                  'Responsible Person: Approval Customers',
                                ),
                              ],
                            ),
                          ),
                          p.Container(
                            width: double.infinity,
                            margin: p.EdgeInsets.only(top: 10),
                            child: p.Text(
                              'F.RPR.REM - 004.00 Tire Inspection Report',
                              textAlign: p.TextAlign.right,
                            ),
                          ),
                        ]),
                  ]),
            ),
          ];
        }));

    final id = Uuid();
    final outputFile = await createFolderPath('${id.v4()}', 'repair',
        // email: user['email'] ?? '',
        // site: user['siteName'] ?? '',
        customer: data['customer'],
        sn: data['sn'],
        date:
            "${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().year}");
    final filePath = await savePdf(pdf, outputFile);

    if (filePath != null || filePath != '') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: green00968A,
          content: Text(
            'Successfull Save Data! Please Check Internal Storage/Download ',
            style: getWhiteTextStyle(),
          )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Choose Image', context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                '*Pilih Max. 1 Foto SN dan Max. 3 Foto Luka',
                style: getRedTextStyle(),
              ),
              const SizedBox(
                height: 12,
              ),
              ListView(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                children: categorizedImages.entries.map((entry) {
                  final category = entry.key;
                  final images = entry.value;

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[300], // warna background
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(category,
                              style: getBlackTextStyle(
                                fontWeight: w700,
                              )),
                        ),
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: images.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                2, // Gambar lebih besar (2 per baris)
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            final imagePath = images[index];

                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () =>
                                      toggleImageSelection(imagePath, category),
                                  child: Transform.rotate(
                                    angle: imageRotations[imagePath] ?? 0.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color:
                                              selectedImages.contains(imagePath)
                                                  ? Colors.green
                                                  : Colors.grey,
                                          width: 2,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        child: Transform.scale(
                                          scale: 1.0,
                                          child: Image.network(
                                            imagePath,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                            height: 160,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.broken_image),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Checkbox(
                                    value: selectedImages.contains(imagePath),
                                    onChanged: (_) => toggleImageSelection(
                                        imagePath, category),
                                    side: const BorderSide(
                                        color: Colors.white, width: 2),
                                    checkColor: Colors.white,
                                    fillColor: MaterialStateProperty
                                        .resolveWith<Color>((states) {
                                      if (states
                                          .contains(MaterialState.selected)) {
                                        return Colors.green;
                                      }
                                      return Colors.transparent;
                                    }),
                                  ),
                                ),
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(
                                          0.6), // Latar belakang gelap semi transparan
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Row(
                                        children: [
                                          Text(
                                            'Rotate',
                                            style: getWhiteTextStyle(),
                                          ),
                                          const SizedBox(
                                            width: 6,
                                          ),
                                          const Icon(Icons.rotate_right,
                                              color: Colors.white, size: 28),
                                        ],
                                      ),
                                      onPressed: () => rotateImage(imagePath),
                                      tooltip: 'Rotate',
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Tombol Clear All
            Expanded(
              flex: 1,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Kosongkan list yang digunakan
                  setState(() {
                    selectedImages.clear();
                    selectedImageTypes.clear();
                    imageRotations.clear();
                  });
                },
                icon: const Icon(
                  Icons.clear,
                  color: Colors.white,
                ),
                label: Text(
                  "Clear All",
                  style: getWhiteTextStyle(
                    fontSize: 10,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.red,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Tombol Generate PDF
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: _isGeneratingPdf
                    ? null
                    : () async {
                        setState(() {
                          _isGeneratingPdf = true;
                          _pdfProgress = 0;
                        });

                        try {
                          await generateInspectionPdf(
                            selectedImages: selectedImages,
                            selectedImageTypes: selectedImageTypes,
                            imageRotations: imageRotations,
                            data: data,
                            imagePath: imagePath,
                            onProgress: (progress) {
                              if (mounted) {
                                setState(() {
                                  _pdfProgress = progress; // contoh: 0.35
                                });
                              }
                            },
                          );
                        } finally {
                          if (mounted) {
                            setState(() {
                              _isGeneratingPdf = false;
                            });
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
                child: _isGeneratingPdf
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              value: _pdfProgress, // ← PROGRESS REAL
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.black),
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            "${(_pdfProgress * 100).toInt()}%",
                            style: getBlackTextStyle(),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.picture_as_pdf, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            "Generate PDF",
                            style: getWhiteTextStyle(),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

p.Widget _tableHeader(String text) {
  return p.Padding(
    padding: const p.EdgeInsets.all(6),
    child: p.Center(
      child: p.Text(
        text,
        style: p.TextStyle(
          fontWeight: p.FontWeight.bold,
          fontSize: 10,
        ),
      ),
    ),
  );
}

p.TableRow _tableRow(String no, String nama, String bn, String eSign) {
  return p.TableRow(
    children: [
      _tableCell(no, align: p.TextAlign.center),
      _tableCell(nama),
      _tableCell(bn, align: p.TextAlign.center),
      _tableCell(
        eSign,
      ), // Kolom E-Sign (kosong)
    ],
  );
}

p.Widget _tableCell(
  String text, {
  p.TextAlign align = p.TextAlign.left,
  double height = 30,
}) {
  return p.Container(
    height: height,
    padding: const p.EdgeInsets.all(6),
    alignment: p.Alignment.centerLeft,
    child: p.Text(
      text,
      textAlign: align,
      style: const p.TextStyle(fontSize: 10),
    ),
  );
}

p.Widget _leftLabel(String text) {
  return p.Container(
    height: 70,
    alignment: p.Alignment.center,
    padding: const p.EdgeInsets.all(8),
    child: p.Text(
      text,
      style: p.TextStyle(
        fontWeight: p.FontWeight.bold,
        fontSize: 11,
      ),
    ),
  );
}

p.Widget _signatureCell({
  required String name,
  // required String signedBy,
  // required String reason,
  // required String location,
  // required String date,
  // Uint8List? signatureImage,
  required String signatureImage,
}) {
  return p.Container(
    height: 70,
    padding: const p.EdgeInsets.all(8),
    child: p.Column(
      crossAxisAlignment: p.CrossAxisAlignment.start,
      mainAxisAlignment: p.MainAxisAlignment.end,
      children: [
        // if (signatureImage != null)
        //   p.Center(
        //     child: p.Image(
        //       p.MemoryImage(signatureImage),
        //       height: 50,
        //     ),
        //   ),
        // p.Text(signatureImage),
        // p.SizedBox(height: 6),
        // p.Text(
        //   '$signedBy\n$reason\n$location\n$date',
        //   style: const p.TextStyle(fontSize: 8),
        // ),
        // p.SizedBox(height: 6),
        p.Center(
          child: p.Text(
            name,
            style: p.TextStyle(
              fontSize: 11,
              fontWeight: p.FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}

p.TableRow _responsibleRow(String text) {
  return p.TableRow(
    children: [
      p.Container(),
      p.Container(
        padding: const p.EdgeInsets.all(6),
        child: p.Text(
          text,
          style: const p.TextStyle(fontSize: 9),
        ),
      ),
    ],
  );
}
