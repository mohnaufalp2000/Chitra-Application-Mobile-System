import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/styles/asset_path.dart';
import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/firebase_key/firebase_key.dart';
import '../../../core/utils/functions/functions.dart';
import '../../../core/widgets/button_widget.dart';
import 'tire_repair_inspection_form_page.dart';
// import 'package:camos/pages/tire_repair_form/tire_repair_inspection/tire_repair_inspection_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection/tire_repair_pdf_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class DetailTireRepairInspection extends StatefulWidget {
  static const routeName = '/detail-tire-repair-inspection';

  @override
  State<DetailTireRepairInspection> createState() =>
      _DetailTireRepairInspectionState();
}

class _DetailTireRepairInspectionState extends State<DetailTireRepairInspection>
    with TickerProviderStateMixin {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  late AnimationController _controller;
  Map<String, dynamic> selectedImage = {
    'Serial Number': [],
    'Area Sidewall': [],
    'Area Shoulder': [],
    'Area Bead': [],
    'Area Tread': [],
    'Area Inner Linner': [],
    'Area Chaffer': [],
  };
  final String leaderRepair = 'renaldo@chitraparatama.co.id';

  Future<Uint8List> getImageFromUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.bodyBytes;
    } else {
      throw Exception('Failed to load image');
    }
  }

  Future<void> _pickSignedDocumentImage(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final picker = ImagePicker();
    final storage = FirebaseStorage.instance;
    final firestore = FirebaseFirestore.instance;

    Future<void> _handlePick(ImageSource source) async {
      Navigator.pop(context);

      try {
        final image = await picker.pickImage(
          source: source,
          imageQuality: 80,
        );

        if (image == null) return;

        final fileName =
            'signed_doc_${data['sn']}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final ref = storage.ref().child('signed-document/$fileName');
        final compressedFile = await compressImage(File(image.path));
        await ref.putFile(compressedFile);

        final url = await ref.getDownloadURL();

        final snapshot = await firestore
            .collection(FirestoreKey.tireRepairInspectionReport)
            .where('id', isEqualTo: data['id'])
            .limit(1)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final doc = snapshot.docs.first;
          final List<dynamic> images =
              (doc.data()['signed_document_pic'] ?? []).toList();

          images.add(url);

          await doc.reference.update({
            'signed_document_pic': images,
            'signed_document_at': FieldValue.serverTimestamp(),
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Signed document uploaded')),
        );
      } catch (e) {
        print('error picture : $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Ambil dari Kamera'),
                onTap: () => _handlePick(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Ambil dari Gallery'),
                onTap: () => _handlePick(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<File> compressImage(File file) async {
    final targetPath =
        '${file.parent.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70,
      minWidth: 1280,
      minHeight: 1280,
    );

    return File(result!.path);
  }

  void _showSignedDocumentModal(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final List images = (data['signed_document_pic'] ?? []);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black,
      builder: (_) {
        return SafeArea(
          child: Container(
            height: 340,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                /// HEADER + DOWNLOAD ALL
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Signed Documents',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Download All',
                          icon: const Icon(Icons.download, color: Colors.white),
                          onPressed: () {
                            try {
                              _downloadAllSignedImages(
                                context,
                                images,
                                data['sn'],
                              );
                            } catch (e) {
                              print('error download tire inspection $e');
                            }
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// IMAGE LIST
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final url = images[index];
                      return GestureDetector(
                        onTap: () {
                          _showFullscreenImage(context, url);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              url,
                              width: 240,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullscreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                url,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadAllSignedImages(
    BuildContext context,
    List images,
    String sn,
  ) async {
    print('download');
    try {
      // Permission (Android)
      if (await Permission.storage.request().isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission denied')),
        );
        return;
      }

      final tempDir = await getTemporaryDirectory();
      final dio = Dio();

      for (int i = 0; i < images.length; i++) {
        final url = images[i];

        final filePath =
            '${tempDir.path}/signed_doc_${sn}_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await dio.download(url, filePath);

        final bytes = await File(filePath).readAsBytes();

        await ImageGallerySaver.saveImage(
          bytes,
          name: 'signed-doc-$sn-$i-${DateTime.now().millisecondsSinceEpoch}',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All images saved to gallery')),
      );
    } catch (e) {
      debugPrint('DOWNLOAD ALL ERROR: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to download images')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    initializeIntl();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  initializeIntl() async {
    await initializeDateFormatting('id_ID', null);
  }

  @override
  Widget build(BuildContext context) {
    final id = ModalRoute.of(context)?.settings.arguments as String;

    final tween =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero);
    final animation = tween.animate(_controller);

    return Scaffold(
        body: SafeArea(
            child: SingleChildScrollView(
      child: StreamBuilder(
          stream: firestore
              .collection(FirestoreKey.tireRepairInspectionReport)
              .where('id', isEqualTo: id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            // Ambil data dari snapshot
            List<Map<String, dynamic>> dataList =
                snapshot.data!.docs.map((doc) {
              return doc.data() as Map<String, dynamic>;
            }).toList();

            final data = dataList[0];

            return Stack(
              children: [
                Column(children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF6E92DF),
                          Color(0xFF9CF09E),
                        ],
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(0),
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: 16,
                          left: 16,
                          child: IconButton(
                            icon: Icon(Icons.arrow_back_ios_rounded,
                                color: Colors.black),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, color: Colors.black),
                            onSelected: (String result) async {
                              if (result == 'edit') {
                                Navigator.pushNamed(context,
                                    TireRepairInspectionFormPage.routeName,
                                    arguments: id);
                              } else if (result == 'delete') {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        content: Text(
                                          'Are you sure you want to delete this data?',
                                          style: getBlackTextStyle(),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                'Cancel',
                                                style: getGreyTextStyle(
                                                    grey8391A1),
                                              )),
                                          TextButton(
                                              onPressed: () async {
                                                try {
                                                  final querySnapshot =
                                                      await firestore
                                                          .collection(FirestoreKey
                                                              .tireRepairInspectionReport)
                                                          .where('id',
                                                              isEqualTo: id)
                                                          .get();

                                                  for (var doc
                                                      in querySnapshot.docs) {
                                                    await doc.reference
                                                        .delete(); // Menghapus dokumen
                                                  }

                                                  // Navigator.pushReplacementNamed(
                                                  //     context,
                                                  //     TireRepairInspectionPage
                                                  //         .routeName);
                                                } catch (e) {}
                                              },
                                              child: Text(
                                                'Yes',
                                                style: getRedTextStyle(),
                                              )),
                                        ],
                                      );
                                    });
                              }
                            },
                            itemBuilder: (BuildContext context) =>
                                <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Container(
                                    child: Row(
                                  children: [
                                    Text(
                                      'Edit',
                                      style: getBlackTextStyle(fontWeight: w700)
                                          .copyWith(color: Colors.yellow[800]),
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Icon(
                                      Icons.edit,
                                      color: Colors.yellow[800],
                                    )
                                  ],
                                )),
                              ),
                              (auth.currentUser?.email == leaderRepair)
                                  ? PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Text(
                                            'Delete',
                                            style: getRedTextStyle(
                                                fontWeight: w700),
                                          ),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                          Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          )
                                        ],
                                      ),
                                    )
                                  : PopupMenuItem(child: Container())
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                        color: Color(0xFFFEF7FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        )),
                    child: Column(
                      children: [
                        const SizedBox(
                          height: 48,
                        ),
                        Text(
                          data['brand'],
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            overflow: TextOverflow.ellipsis,
                            shadows: [
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 4.0,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        Text(
                          data['sn'],
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                            overflow: TextOverflow.ellipsis,
                            shadows: [
                              Shadow(
                                offset: Offset(1.0, 1.0),
                                blurRadius: 2.0,
                                color: Colors.grey.withOpacity(0.5),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () {
                                Navigator.pushNamed(
                                  context,
                                  TireRepairPDFPage.routeName,
                                  arguments: data,
                                );
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.picture_as_pdf,
                                    color: white,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    'Generate To PDF',
                                    style: getWhiteTextStyle(),
                                  ),
                                ],
                              )),
                        ),
                        const SizedBox(
                          height: 14,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green),
                                  onPressed: () {
                                    _pickSignedDocumentImage(context, data);
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.camera, color: white),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Upload Signed Document',
                                        style: getWhiteTextStyle(),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              /// 🔥 BUTTON SHOW IMAGE (hanya kalau ada data)
                              if (data['signed_document_pic'] != null &&
                                  (data['signed_document_pic'] as List)
                                      .isNotEmpty) ...[
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                  ),
                                  onPressed: () {
                                    _showSignedDocumentModal(context, data);
                                  },
                                  child: const Icon(Icons.image,
                                      color: Colors.white),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Color(0xFFC8FDB0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextWithDashedLine(
                                  'Date Inspect',
                                  '${formatDate(data['date_inspect'])}',
                                ),
                                _buildTextWithDashedLine(
                                  'Customer',
                                  '${data['customer']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Site',
                                  '${data['site']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Repair Location',
                                  '${data['repair_location']}',
                                ),
                                _yanpagaris(
                                  'Report by',
                                  '${data['report_by']}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Color(0xFFC8FDB0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Text(
                                    'TIRE DETAIL',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                SizedBox(height: 30),
                                _buildTextWithDashedLine(
                                  'Tire Size',
                                  '${data['tire_size']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Serial Number',
                                  '${data['sn']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Brand',
                                  '${data['brand']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Type Construction',
                                  '${data['type_construction']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Pattern',
                                  '${data['pattern']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Status',
                                  '${data['status']}',
                                ),
                                _buildTextWithDashedLine(
                                  'No. Cargo Manifest',
                                  '${data['no_cargo_manifest']}',
                                ),
                                // _buildTextWithDashedLine(
                                //   'Total Injuries',
                                //   '....',
                                // ),
                                _buildTextWithDashedLine(
                                  'RTD (mm)',
                                  '${data['rtd1']}/${data['rtd2']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Date Received',
                                  '${formatDate(data['date_received'])}',
                                ),
                                _remarks('Remarks :', data),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Color(0xFFC8FDB0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Serial Number',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: data['sn_pic'].map<Widget>((e) {
                                    return Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: double
                                                .infinity, // Atur lebar sesuai kebutuhan
                                            height:
                                                200, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .contain, // Sesuaikan cara gambar dipasang dalam kotak
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Color(0xFFC8FDB0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Area Sidewall',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children:
                                      data['sidewall_pic'].map<Widget>((e) {
                                    return Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: double
                                                .infinity, // Atur lebar sesuai kebutuhan
                                            height:
                                                200, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .contain, // Sesuaikan cara gambar dipasang dalam kotak
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Color(0xFFC8FDB0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Area Shoulder',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children:
                                      data['shoulder_pic'].map<Widget>((e) {
                                    return Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: double
                                                .infinity, // Atur lebar sesuai kebutuhan
                                            height:
                                                200, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .contain, // Sesuaikan cara gambar dipasang dalam kotak
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Color(0xFFC8FDB0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Area Bead',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: data['bead_pic'].map<Widget>((e) {
                                    return Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: double
                                                .infinity, // Atur lebar sesuai kebutuhan
                                            height:
                                                200, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .contain, // Sesuaikan cara gambar dipasang dalam kotak
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Color(0xFFC8FDB0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Area Tread',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: data['threat_pic'].map<Widget>((e) {
                                    return Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: double
                                                .infinity, // Atur lebar sesuai kebutuhan
                                            height:
                                                200, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .contain, // Sesuaikan cara gambar dipasang dalam kotak
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Color(0xFFC8FDB0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Area Inner Linner',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children:
                                      data['inner_linner_pic'].map<Widget>((e) {
                                    return Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: double
                                                .infinity, // Atur lebar sesuai kebutuhan
                                            height:
                                                200, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .contain, // Sesuaikan cara gambar dipasang dalam kotak
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            color: Color(0xFFC8FDB0),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                offset: Offset(0, 4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(30.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Area Chaffer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children:
                                      data['chaffer_pic'].map<Widget>((e) {
                                    return Column(
                                      children: [
                                        Center(
                                          child: Container(
                                            width: double
                                                .infinity, // Atur lebar sesuai kebutuhan
                                            height:
                                                200, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .contain, // Sesuaikan cara gambar dipasang dalam kotak
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        )
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 99.0),
                      ],
                    ),
                  ),
                ]),
                Positioned(
                  top: 90,
                  left: MediaQuery.of(context).size.width * 0.2,
                  right: MediaQuery.of(context).size.width * 0.2,
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/images/ban.png',
                        width: 130,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                      SizedBox(height: 2),
                    ],
                  ),
                ),
              ],
            );
          }),
    )));
  }

  Future<dynamic> errorImage(BuildContext context, String type) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text((type == 'Serial Number')
              ? 'You can only select 1 Serial Number image.'
              : 'You can only select Max 3. Injury Tire image'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String formatDate(String dateStr) {
    // Parsing string ke dalam DateTime
    DateTime date = DateTime.parse(dateStr);

    // Format tanggal sesuai keinginan
    String formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(date);

    return formattedDate;
  }

  Widget _buildTextWithDashedLine(String leftText, String rightText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                leftText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              width: 150,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  rightText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.right,
                  // overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        // DashedLine(width: 285, color: Colors.black),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _yanpagaris(String leftText, String rightText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                leftText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                rightText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _remarks(String leftText, Map<String, dynamic> data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                leftText,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        Text(
          '${data['remarks']}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }
}

class ImageContainer extends StatefulWidget {
  const ImageContainer({
    super.key,
    required this.data,
    required this.type,
    required this.mapType,
    required this.addSelectedImage,
  });

  final Map<String, dynamic> data;
  final String type;
  final String mapType;
  final Function(String) addSelectedImage;

  @override
  State<ImageContainer> createState() => _ImageContainerState();
}

class _ImageContainerState extends State<ImageContainer> {
  late List<bool> isCheckedList;

  @override
  void initState() {
    super.initState();
    // Inisialisasi isCheckedList dengan false sebanyak jumlah gambar
    isCheckedList =
        List<bool>.filled(widget.data[widget.mapType].length, false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
        color: Color(0xFFC8FDB0),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: Offset(0, 4),
            blurRadius: 8,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              widget.type,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${widget.type == 'Serial Number' ? 'Choose 1 SN Picture' : ''}',
              style: getRedTextStyle(),
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: widget.data[widget.mapType].map<Widget>((e) {
                int index = widget.data[widget.mapType].indexOf(e);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          isCheckedList[index] = !isCheckedList[index];
                          widget.addSelectedImage(e);
                        });
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Container(
                                width: double
                                    .infinity, // Atur lebar sesuai kebutuhan
                                height: 200, // Atur tinggi sesuai kebutuhan
                                child: Image.network(
                                  e,
                                  fit: BoxFit
                                      .contain, // Sesuaikan cara gambar dipasang dalam kotak
                                ),
                              ),
                            ),
                          ),
                          Checkbox(
                            value: isCheckedList[index],
                            onChanged: (bool? value) {
                              setState(() {
                                isCheckedList[index] = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    )
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
