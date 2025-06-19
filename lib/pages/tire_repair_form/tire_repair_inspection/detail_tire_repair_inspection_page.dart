import 'dart:developer';

import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/firebase_key/firebase_key.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection/tire_repair_inspection_form_page.dart';
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
                        // GestureDetector(
                        //   onTap: () async {
                        //     showDialog(
                        //         context: context,
                        //         builder: (context) {
                        //           return WillPopScope(
                        //             onWillPop: () async {
                        //               selectedImage.forEach((key, value) {
                        //                 if (value is List) {
                        //                   value.clear();
                        //                 }
                        //               });
                        //               return true;
                        //             },
                        //             child: AlertDialog(
                        //               content: SingleChildScrollView(
                        //                 child: Column(
                        //                   mainAxisSize: MainAxisSize.min,
                        //                   children: [
                        //                     Row(
                        //                       mainAxisAlignment:
                        //                           MainAxisAlignment
                        //                               .spaceBetween,
                        //                       children: [
                        //                         Text(
                        //                           'Please Choose Image!',
                        //                           style: getBlackTextStyle(
                        //                               fontSize: 18,
                        //                               fontWeight: w700),
                        //                         ),
                        //                         IconButton(
                        //                             onPressed: () {
                        //                               selectedImage.forEach(
                        //                                   (key, value) {
                        //                                 if (value is List) {
                        //                                   value.clear();
                        //                                 }
                        //                               });
                        //                               Navigator.pop(context);
                        //                             },
                        //                             icon: Icon(Icons.close))
                        //                       ],
                        //                     ),
                        //                     Text(
                        //                       '*Max. 1 Serial Number Image & \nMax. 3 Tire Injury Image',
                        //                       style: getRedTextStyle(
                        //                         fontSize: 16,
                        //                       ),
                        //                     ),
                        //                     const SizedBox(
                        //                       height: 12,
                        //                     ),
                        //                     // ERRORNYA DISINI!!!!
                        //                     ImageContainer(
                        //                       data: data,
                        //                       type: 'Serial Number',
                        //                       mapType: 'sn_pic',
                        //                       addSelectedImage: (value) {
                        //                         List<dynamic> image =
                        //                             selectedImage[
                        //                                 'Serial Number'];
                        //                         log('gambar sn 1 ${image}');
                        //                         log('gambar sn cek : ${image.contains(value)}');

                        //                         if (image.contains(value)) {
                        //                           selectedImage['Serial Number']
                        //                               .remove(value);
                        //                         } else {
                        //                           selectedImage['Serial Number']
                        //                               .add(value);
                        //                         }
                        //                         log('gambar sn 2 ${selectedImage['Area Sidewall']}');
                        //                       },
                        //                     ),
                        //                     const SizedBox(
                        //                       height: 12,
                        //                     ),
                        //                     ImageContainer(
                        //                       data: data,
                        //                       type: 'Area Sidewall',
                        //                       mapType: 'sidewall_pic',
                        //                       addSelectedImage: (value) {
                        //                         List<dynamic> image =
                        //                             selectedImage[
                        //                                 'Area Sidewall'];
                        //                         log('gambar sidewall 1 ${image}');
                        //                         log('gambar sidewall cek : ${image.contains(value)}');
                        //                         if (image.contains(value)) {
                        //                           selectedImage['Area Sidewall']
                        //                               .remove(value);
                        //                         } else {
                        //                           selectedImage['Area Sidewall']
                        //                               .add(value);
                        //                         }
                        //                         log('gambar sidewall 2 ${selectedImage['Area Sidewall']}');
                        //                       },
                        //                     ),
                        //                     const SizedBox(
                        //                       height: 12,
                        //                     ),
                        //                     ImageContainer(
                        //                       data: data,
                        //                       type: 'Area Shoulder',
                        //                       mapType: 'shoulder_pic',
                        //                       addSelectedImage: (value) {
                        //                         List<dynamic> image =
                        //                             selectedImage[
                        //                                 'Area Shoulder'];
                        //                         if (image.contains(value)) {
                        //                           selectedImage['Area Shoulder']
                        //                               .remove(value);
                        //                         } else {
                        //                           selectedImage['Area Shoulder']
                        //                               .add(value);
                        //                         }
                        //                       },
                        //                     ),
                        //                     const SizedBox(
                        //                       height: 12,
                        //                     ),
                        //                     ImageContainer(
                        //                       data: data,
                        //                       type: 'Area Bead',
                        //                       mapType: 'bead_pic',
                        //                       addSelectedImage: (value) {
                        //                         List<dynamic> image =
                        //                             selectedImage['Area Bead'];
                        //                         if (image.contains(value)) {
                        //                           selectedImage['Area Bead']
                        //                               .remove(value);
                        //                         } else {
                        //                           selectedImage['Area Bead']
                        //                               .add(value);
                        //                         }
                        //                       },
                        //                     ),
                        //                     const SizedBox(
                        //                       height: 12,
                        //                     ),
                        //                     ImageContainer(
                        //                       data: data,
                        //                       type: 'Area Tread',
                        //                       mapType: 'threat_pic',
                        //                       addSelectedImage: (value) {
                        //                         List<dynamic> image =
                        //                             selectedImage['Area Tread'];
                        //                         if (image.contains(value)) {
                        //                           selectedImage['Area Tread']
                        //                               .remove(value);
                        //                         } else {
                        //                           selectedImage['Area Tread']
                        //                               .add(value);
                        //                         }
                        //                       },
                        //                     ),
                        //                     const SizedBox(
                        //                       height: 12,
                        //                     ),
                        //                     ImageContainer(
                        //                       data: data,
                        //                       type: 'Area Inner Linner',
                        //                       mapType: 'inner_linner_pic',
                        //                       addSelectedImage: (value) {
                        //                         List<dynamic> image =
                        //                             selectedImage[
                        //                                 'Area Inner Linner'];
                        //                         if (image.contains(value)) {
                        //                           selectedImage[
                        //                                   'Area Inner Linner']
                        //                               .remove(value);
                        //                         } else {
                        //                           selectedImage[
                        //                                   'Area Inner Linner']
                        //                               .add(value);
                        //                         }
                        //                       },
                        //                     ),
                        //                     const SizedBox(
                        //                       height: 12,
                        //                     ),
                        //                     ImageContainer(
                        //                       data: data,
                        //                       type: 'Area Chaffer',
                        //                       mapType: 'chaffer_pic',
                        //                       addSelectedImage: (value) {
                        //                         List<dynamic> image =
                        //                             selectedImage[
                        //                                 'Area Chaffer'];
                        //                         if (image.contains(value)) {
                        //                           selectedImage['Area Chaffer']
                        //                               .remove(value);
                        //                         } else {
                        //                           selectedImage['Area Chaffer']
                        //                               .add(value);
                        //                         }
                        //                       },
                        //                     ),
                        //                     const SizedBox(
                        //                       height: 12,
                        //                     ),
                        //                     // Generate PDF after select image
                        //                     ButtonWidget(
                        //                       name: Text(
                        //                         'Generate PDF',
                        //                         style: getWhiteTextStyle(),
                        //                       ),
                        //                       color: Colors.red,
                        //                       function: () async {
                        //                         List<dynamic> snImages =
                        //                             selectedImage[
                        //                                 'Serial Number'];
                        //                         List<dynamic> sidewallImages =
                        //                             selectedImage[
                        //                                 'Area Sidewall'];
                        //                         List<dynamic> shoulderImages =
                        //                             selectedImage[
                        //                                 'Area Shoulder'];
                        //                         List<dynamic> beadImages =
                        //                             selectedImage['Area Bead'];
                        //                         List<dynamic> threatImages =
                        //                             selectedImage['Area Tread'];
                        //                         List<dynamic>
                        //                             innerLinnerImages =
                        //                             selectedImage[
                        //                                 'Area Inner Linner'];
                        //                         List<dynamic> chafferImages =
                        //                             selectedImage[
                        //                                 'Area Chaffer'];
                        //                         int count = sidewallImages
                        //                                 .length +
                        //                             shoulderImages.length +
                        //                             beadImages.length +
                        //                             threatImages.length +
                        //                             innerLinnerImages.length +
                        //                             chafferImages.length;

                        //                         // if (snImages.isEmpty) {
                        //                         //   errorImage(
                        //                         //       context, 'Serial Number');
                        //                         //   return;
                        //                         // }

                        //                         if (snImages.length != 1) {
                        //                           log('list selected image : error sn');
                        //                           errorImage(
                        //                               context, 'Serial Number');
                        //                           return;
                        //                         } else if (count != 3) {
                        //                           log('list selected image : error injury');
                        //                           errorImage(context, 'Injury');
                        //                           return;
                        //                         } else {
                        //                           log('list selected image : ${selectedImage}');
                        //                           List<Map<String, dynamic>>
                        //                               combinedList = [];
                        //                           List<Map<String, String>>
                        //                               combinedList1 = [];

                        //                           selectedImage
                        //                               .forEach((key, value) {
                        //                             if (value is List) {
                        //                               value.forEach((url) {
                        //                                 combinedList1.add({
                        //                                   'type': key,
                        //                                   'url': url,
                        //                                 });
                        //                               });
                        //                             }
                        //                           });

                        //                           // Tampilkan loading indicator
                        //                           showDialog(
                        //                             context: context,
                        //                             barrierDismissible:
                        //                                 false, // Agar dialog tidak bisa ditutup oleh user
                        //                             builder: (context) {
                        //                               return AlertDialog(
                        //                                 content: Row(
                        //                                   children: [
                        //                                     CircularProgressIndicator(),
                        //                                     SizedBox(width: 20),
                        //                                     Text("Loading..."),
                        //                                   ],
                        //                                 ),
                        //                               );
                        //                             },
                        //                           );

                        //                           print(
                        //                               'test combined list : $combinedList1');

                        //                           selectedImage
                        //                               .forEach((key, value) {
                        //                             if (value is List) {
                        //                               combinedList.add({
                        //                                 'type': key,
                        //                                 'value': value
                        //                               });
                        //                             }
                        //                           });

                        //                           // Image 1
                        //                           final Uint8List imageData1 =
                        //                               await getImageFromUrl(
                        //                                   '${combinedList1[0]['url']}');
                        //                           final image1 =
                        //                               p.MemoryImage(imageData1);

                        //                           // Image 2
                        //                           final Uint8List imageData2 =
                        //                               await getImageFromUrl(
                        //                                   '${combinedList1[1]['url']}');
                        //                           final image2 =
                        //                               p.MemoryImage(imageData2);

                        //                           // Image 3
                        //                           final Uint8List imageData3 =
                        //                               await getImageFromUrl(
                        //                                   '${combinedList1[2]['url']}');
                        //                           final image3 =
                        //                               p.MemoryImage(imageData3);

                        //                           // Image 4
                        //                           final Uint8List imageData4 =
                        //                               await getImageFromUrl(
                        //                                   '${combinedList1[3]['url']}');
                        //                           final image4 =
                        //                               p.MemoryImage(imageData4);

                        //                           // Export PDF
                        //                           final pdf = p.Document();

                        //                           final logoCp =
                        //                               (await rootBundle.load(
                        //                                       '${imagePath}/cp_logo_image.png'))
                        //                                   .buffer
                        //                                   .asUint8List();
                        //                           pdf.addPage(p.MultiPage(
                        //                               pageFormat: PdfPageFormat
                        //                                   .a4.landscape,
                        //                               // .applyMargin(
                        //                               //     left: 0,
                        //                               //     top: 0,
                        //                               //     right: 0,
                        //                               //     bottom: 0),
                        //                               margin: p.EdgeInsets.zero,
                        //                               orientation: p
                        //                                   .PageOrientation
                        //                                   .landscape,
                        //                               build:
                        //                                   (p.Context context) {
                        //                                 return [
                        //                                   p.Container(
                        //                                     height: 570,
                        //                                     width: 830,
                        //                                     margin: p.EdgeInsets
                        //                                         .only(
                        //                                             right: 12,
                        //                                             left: 12,
                        //                                             top: 12),
                        //                                     padding:
                        //                                         p.EdgeInsets
                        //                                             .all(24),
                        //                                     decoration: p.BoxDecoration(
                        //                                         border: p.Border.all(
                        //                                             color: PdfColors
                        //                                                 .blue)),
                        //                                     child: p.Column(
                        //                                         crossAxisAlignment:
                        //                                             p.CrossAxisAlignment
                        //                                                 .start,
                        //                                         children: [
                        //                                           p.Row(
                        //                                               mainAxisAlignment: p
                        //                                                   .MainAxisAlignment
                        //                                                   .spaceBetween,
                        //                                               children: [
                        //                                                 p.SizedBox(
                        //                                                   width:
                        //                                                       150,
                        //                                                   height:
                        //                                                       100,
                        //                                                   child:
                        //                                                       p.Image(p.MemoryImage(logoCp)),
                        //                                                 ),
                        //                                                 p.Text(
                        //                                                     'TIRE REPAIR INSPECTION REPORT',
                        //                                                     style:
                        //                                                         p.TextStyle(
                        //                                                       fontSize: 18,
                        //                                                     )),
                        //                                                 p.Container(
                        //                                                   width:
                        //                                                       150,
                        //                                                   height:
                        //                                                       100,
                        //                                                 ),
                        //                                               ]),
                        //                                           p.SizedBox(
                        //                                             height: 10,
                        //                                           ),
                        //                                           p.Row(
                        //                                               mainAxisAlignment: p
                        //                                                   .MainAxisAlignment
                        //                                                   .start,
                        //                                               children: [
                        //                                                 p.Column(
                        //                                                     crossAxisAlignment:
                        //                                                         p.CrossAxisAlignment.start,
                        //                                                     children: [
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150, // Sesuaikan lebar sesuai kebutuhan
                        //                                                             child: p.Text('Date Inspect', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${formatDate(data['date_inspect'])}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Customer', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['customer']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Site', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['site']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Report By', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['report_by']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Padding(padding: p.EdgeInsets.symmetric(vertical: 12), child: p.Container(color: PdfColors.black, width: 320, height: 4)),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Tire Size', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['tire_size']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Serial Number', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['sn']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Brand', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['brand']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Type Construction', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['type_construction']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Pattern', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['pattern']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('RTD ( mm )', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['rtd1']}/${data['rtd2']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('No. Cargo Manifest', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['no_cargo_manifest']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Date Received', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${formatDate(data['date_received'])}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Status', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['status']}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Remarks', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                           p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                           p.Container(
                        //                                                             width: 170,
                        //                                                             child: p.Text('${data['remarks'] ?? 'None'}', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                       (data['status'] != 'REJECT')
                        //                                                           ? p.Column(children: [
                        //                                                               p.SizedBox(height: 8),
                        //                                                               p.Row(
                        //                                                                 crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                                 children: [
                        //                                                                   p.Container(
                        //                                                                     width: 150,
                        //                                                                     child: p.Text('Category', style: p.TextStyle(fontSize: 12)),
                        //                                                                   ),
                        //                                                                   p.Text(' : ', style: p.TextStyle(fontSize: 12)),
                        //                                                                   p.Container(
                        //                                                                     width: 170,
                        //                                                                     child: p.Text('${data['repair_duration'] ?? 'None'}', style: p.TextStyle(fontSize: 12)),
                        //                                                                   ),
                        //                                                                 ],
                        //                                                               ),
                        //                                                             ])
                        //                                                           : p.Container(),
                        //                                                       p.SizedBox(height: 8),
                        //                                                       p.Row(
                        //                                                         crossAxisAlignment: p.CrossAxisAlignment.start,
                        //                                                         children: [
                        //                                                           p.Container(
                        //                                                             width: 150,
                        //                                                             child: p.Text('Warranty / No Warranty', style: p.TextStyle(fontSize: 12)),
                        //                                                           ),
                        //                                                         ],
                        //                                                       ),
                        //                                                     ]),
                        //                                                 p.SizedBox(
                        //                                                     width:
                        //                                                         16),
                        //                                                 p.Column(
                        //                                                   children: [
                        //                                                     p.Container(
                        //                                                       decoration: p.BoxDecoration(
                        //                                                         border: p.Border.all(color: PdfColors.black, width: 1), // Border sekeliling row
                        //                                                       ),
                        //                                                       child: p.Column(
                        //                                                         children: [
                        //                                                           p.Row(children: [
                        //                                                             p.Column(children: [
                        //                                                               p.Container(
                        //                                                                 decoration: p.BoxDecoration(
                        //                                                                   border: p.Border.all(color: PdfColors.black, width: 1), // Border untuk gambar
                        //                                                                 ),
                        //                                                                 child: p.SizedBox(
                        //                                                                   width: 200,
                        //                                                                   height: 160,
                        //                                                                   child: p.Image(image1, fit: p.BoxFit.fitWidth),
                        //                                                                 ),
                        //                                                               ),
                        //                                                               p.Container(
                        //                                                                 width: 200,
                        //                                                                 decoration: p.BoxDecoration(
                        //                                                                   border: p.Border.all(color: PdfColors.black, width: 1), // Border untuk text
                        //                                                                 ),
                        //                                                                 child: p.Padding(
                        //                                                                   padding: p.EdgeInsets.all(4),
                        //                                                                   child: p.Center(child: p.Text('Serial Number', textAlign: p.TextAlign.center, style: p.TextStyle(fontSize: 20))),
                        //                                                                 ),
                        //                                                               )
                        //                                                             ]),
                        //                                                             p.SizedBox(width: 12),
                        //                                                             p.Column(children: [
                        //                                                               p.Container(
                        //                                                                 decoration: p.BoxDecoration(
                        //                                                                   border: p.Border.all(color: PdfColors.black, width: 1),
                        //                                                                 ),
                        //                                                                 child: p.SizedBox(
                        //                                                                   width: 200,
                        //                                                                   height: 160,
                        //                                                                   child: p.Image(image2, fit: p.BoxFit.fitWidth),
                        //                                                                 ),
                        //                                                               ),
                        //                                                               p.Container(
                        //                                                                 width: 200,
                        //                                                                 decoration: p.BoxDecoration(
                        //                                                                   border: p.Border.all(color: PdfColors.black, width: 1),
                        //                                                                 ),
                        //                                                                 child: p.Padding(
                        //                                                                   padding: p.EdgeInsets.all(4),
                        //                                                                   child: p.Center(child: p.Text('${combinedList1[1]['type']}', textAlign: p.TextAlign.center, style: p.TextStyle(fontSize: 20))),
                        //                                                                 ),
                        //                                                               )
                        //                                                             ])
                        //                                                           ]),
                        //                                                           p.SizedBox(height: 24),
                        //                                                           p.Row(children: [
                        //                                                             p.Column(children: [
                        //                                                               p.Container(
                        //                                                                 decoration: p.BoxDecoration(
                        //                                                                   border: p.Border.all(color: PdfColors.black, width: 1),
                        //                                                                 ),
                        //                                                                 child: p.SizedBox(
                        //                                                                   width: 200,
                        //                                                                   height: 160,
                        //                                                                   child: p.Image(image3, fit: p.BoxFit.fitWidth),
                        //                                                                 ),
                        //                                                               ),
                        //                                                               p.Container(
                        //                                                                 width: 200,
                        //                                                                 decoration: p.BoxDecoration(
                        //                                                                   border: p.Border.all(color: PdfColors.black, width: 1),
                        //                                                                 ),
                        //                                                                 child: p.Padding(
                        //                                                                   padding: p.EdgeInsets.all(4),
                        //                                                                   child: p.Center(child: p.Text('${combinedList1[2]['type']}', textAlign: p.TextAlign.center, style: p.TextStyle(fontSize: 20))),
                        //                                                                 ),
                        //                                                               )
                        //                                                             ]),
                        //                                                             p.SizedBox(width: 12),
                        //                                                             p.Column(children: [
                        //                                                               p.Container(
                        //                                                                 decoration: p.BoxDecoration(
                        //                                                                   border: p.Border.all(color: PdfColors.black, width: 1),
                        //                                                                 ),
                        //                                                                 child: p.SizedBox(
                        //                                                                   width: 200,
                        //                                                                   height: 160,
                        //                                                                   child: p.Image(image4, fit: p.BoxFit.fitWidth),
                        //                                                                 ),
                        //                                                               ),
                        //                                                               p.Container(
                        //                                                                 width: 200,
                        //                                                                 decoration: p.BoxDecoration(
                        //                                                                   border: p.Border.all(color: PdfColors.black, width: 1),
                        //                                                                 ),
                        //                                                                 child: p.Padding(
                        //                                                                   padding: p.EdgeInsets.all(4),
                        //                                                                   child: p.Center(child: p.Text('${combinedList1[3]['type']}', textAlign: p.TextAlign.center, style: p.TextStyle(fontSize: 20))),
                        //                                                                 ),
                        //                                                               )
                        //                                                             ])
                        //                                                           ]),
                        //                                                         ],
                        //                                                       ),
                        //                                                     )
                        //                                                   ],
                        //                                                 )
                        //                                               ]),
                        //                                         ]),
                        //                                   )
                        //                                 ];
                        //                               }));
                        //                           final id = Uuid();
                        //                           final outputFile = await createFolderPath(
                        //                               '${id.v4()}', 'repair',
                        //                               // email: user['email'] ?? '',
                        //                               // site: user['siteName'] ?? '',
                        //                               customer:
                        //                                   data['customer'],
                        //                               sn: data['sn'],
                        //                               date:
                        //                                   "${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().year}");
                        //                           final filePath =
                        //                               await savePdf(
                        //                                   pdf, outputFile);

                        //                           selectedImage = {
                        //                             'Serial Number': [],
                        //                             'Area Sidewall': [],
                        //                             'Area Shoulder': [],
                        //                             'Area Bead': [],
                        //                             'Area Tread': [],
                        //                             'Area Inner Linner': [],
                        //                             'Area Chaffer': [],
                        //                           };

                        //                           Navigator.pop(context);
                        //                           Navigator.pop(context);

                        //                           if (filePath != null ||
                        //                               filePath != '') {
                        //                             ScaffoldMessenger.of(
                        //                                     context)
                        //                                 .showSnackBar(SnackBar(
                        //                                     backgroundColor:
                        //                                         green00968A,
                        //                                     content: Text(
                        //                                       'Successfull Save Data!',
                        //                                       style:
                        //                                           getWhiteTextStyle(),
                        //                                     )));
                        //                           }
                        //                         }
                        //                       },
                        //                     )
                        //                   ],
                        //                 ),
                        //               ),
                        //             ),
                        //           );
                        //         });
                        //   },
                        //   child: Container(
                        //     width: MediaQuery.of(context).size.width * 0.9,
                        //     height: 70,
                        //     decoration: BoxDecoration(
                        //       color: Color(0xFFFB8181),
                        //       borderRadius: BorderRadius.circular(20),
                        //       boxShadow: [
                        //         BoxShadow(
                        //           color: Colors.black.withOpacity(0.3),
                        //           offset: Offset(0, 4),
                        //           blurRadius: 8,
                        //         ),
                        //       ],
                        //     ),
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Text(
                        //           'Generate To PDF',
                        //           style: TextStyle(
                        //             color: Colors.black,
                        //             fontSize: 16,
                        //             fontWeight: FontWeight.bold,
                        //           ),
                        //         ),
                        //         SizedBox(width: 20),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        Container(
                          width: double.infinity,
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red),
                              onPressed: () {
                                // final Map<String, dynamic> arguments = {
                                //   'snImages': data['sn_pic'],
                                //   'sidewallImages': data['sidewall_pic'],
                                //   'shoulderImages': data['shoulder_pic'],
                                //   'beadImages': data['bead_pic'],
                                //   'threatImages': data['threat_pic'],
                                //   'innerLinnerImages': data['inner_linner_pic'],
                                //   'chafferImages': data['chaffer_pic'],
                                // };

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
