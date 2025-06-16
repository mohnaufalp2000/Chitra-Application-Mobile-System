import 'dart:io';
import 'dart:typed_data';

import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
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
  }) async {
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
              padding: p.EdgeInsets.all(24),
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
            )
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
            'Successfull Save Data!',
            style: getWhiteTextStyle(),
          )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Choose Image', context),
      body: SafeArea(
        child: ListView(
          children: categorizedImages.entries.map((entry) {
            final category = entry.key;
            final images = entry.value;

            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      crossAxisCount: 2, // Gambar lebih besar (2 per baris)
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
                                    color: selectedImages.contains(imagePath)
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
                              onChanged: (_) =>
                                  toggleImageSelection(imagePath, category),
                              side: const BorderSide(
                                  color: Colors.white, width: 2),
                              checkColor: Colors.white,
                              fillColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                      (states) {
                                if (states.contains(MaterialState.selected)) {
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
              child: ElevatedButton.icon(
                onPressed: () async {
                  await generateInspectionPdf(
                    selectedImages: selectedImages,
                    selectedImageTypes: selectedImageTypes,
                    imageRotations: imageRotations,
                    data: data,
                    imagePath: imagePath,
                  );
                },
                icon: const Icon(
                  Icons.picture_as_pdf,
                  color: Colors.white,
                ),
                label: Text(
                  "Generate PDF",
                  style: getWhiteTextStyle(),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
