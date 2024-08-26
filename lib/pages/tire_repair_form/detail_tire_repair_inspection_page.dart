import 'dart:developer';

import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection_form_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late AnimationController _controller;

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

  @override
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
              .collection('tire_repair_ins_report')
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
                                                          .collection(
                                                              'tire_repair_ins_report')
                                                          .where('id',
                                                              isEqualTo: id)
                                                          .get();

                                                  for (var doc
                                                      in querySnapshot.docs) {
                                                    await doc.reference
                                                        .delete(); // Menghapus dokumen
                                                  }

                                                  Navigator.pushReplacementNamed(
                                                      context,
                                                      TireRepairInspectionPage
                                                          .routeName);
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
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Text(
                                      'Delete',
                                      style: getRedTextStyle(fontWeight: w700),
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
                              ),
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
                        GestureDetector(
                          onTap: () async {
                            showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    content: SingleChildScrollView(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Please Choose Image!',
                                            style: getBlackTextStyle(
                                                fontSize: 18, fontWeight: w700),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          ImageContainer(
                                              data: data,
                                              type: 'Serial Number',
                                              mapType: 'sn_pic'),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          ImageContainer(
                                              data: data,
                                              type: 'Area Sidewall',
                                              mapType: 'sidewall_pic'),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          ImageContainer(
                                              data: data,
                                              type: 'Area Shoulder',
                                              mapType: 'shoulder_pic'),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          ImageContainer(
                                              data: data,
                                              type: 'Area Bead',
                                              mapType: 'bead_pic'),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          ImageContainer(
                                              data: data,
                                              type: 'Area Threat',
                                              mapType: 'threat_pic'),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          ImageContainer(
                                              data: data,
                                              type: 'Area Inner Linner',
                                              mapType: 'inner_linner_pic'),
                                          ImageContainer(
                                              data: data,
                                              type: 'Area Chaffer',
                                              mapType: 'chaffer_pic'),
                                        ],
                                      ),
                                    ),
                                  );
                                });

                            // LANGSUNG GENERATE PDF
                            // final pdf = p.Document();

                            // // SN PIC
                            // final Uint8List imageData =
                            //     await getImageFromUrl('${data['sn_pic'][0]}');
                            // final image = p.MemoryImage(imageData);

                            // // Sidewall
                            // final Uint8List imageSidewall =
                            //     await getImageFromUrl(
                            //         '${data['sidewall_pic'][0]}');
                            // final imageSd = p.MemoryImage(imageSidewall);

                            // final logoCp = (await rootBundle
                            //         .load('${imagePath}/cp_logo_image.png'))
                            //     .buffer
                            //     .asUint8List();
                            // pdf.addPage(p.MultiPage(
                            //     pageFormat: PdfPageFormat.a4,
                            //     orientation: p.PageOrientation.landscape,
                            //     build: (p.Context context) {
                            //       return [
                            //         p.Column(
                            //             crossAxisAlignment:
                            //                 p.CrossAxisAlignment.start,
                            //             children: [
                            //               p.Row(
                            //                   mainAxisAlignment: p
                            //                       .MainAxisAlignment
                            //                       .spaceBetween,
                            //                   children: [
                            //                     p.SizedBox(
                            //                       width: 150,
                            //                       height: 100,
                            //                       child: p.Image(
                            //                           p.MemoryImage(logoCp)),
                            //                     ),
                            //                     p.Text(
                            //                         'Tire Repair Inspection Report',
                            //                         style: p.TextStyle(
                            //                           fontSize: 26,
                            //                         )),
                            //                     p.Container(
                            //                       width: 150,
                            //                       height: 100,
                            //                     ),
                            //                   ]),
                            //               p.SizedBox(
                            //                 height: 30,
                            //               ),
                            //               p.Row(
                            //                   mainAxisAlignment: p
                            //                       .MainAxisAlignment
                            //                       .spaceBetween,
                            //                   children: [
                            //                     p.Column(
                            //                         crossAxisAlignment: p
                            //                             .CrossAxisAlignment
                            //                             .start,
                            //                         children: [
                            //                           p.Text(
                            //                               'Date Inspect : ${data['date_inspect']}'),
                            //                           p.Text(
                            //                               'Customer : ${data['customer']}'),
                            //                           p.Text(
                            //                               'Site : ${data['site']}'),
                            //                           p.SizedBox(
                            //                             height: 60,
                            //                           ),
                            //                           p.Text(
                            //                               'Tire Size : ${data['tire_size']}'),
                            //                           p.Text(
                            //                               'Serial Number : ${data['sn']}'),
                            //                           p.Text(
                            //                               'Brand : ${data['brand']}'),
                            //                           p.Text(
                            //                               'Type Construction : ${data['type_construction']}'),
                            //                           p.Text(
                            //                               'Pattern : ${data['pattern']}'),
                            //                           p.Text(
                            //                               'RTD ( mm ) : ${data['rtd1']}/${data['rtd2']}'),
                            //                           p.Text(
                            //                               'No. Cargo Manifest : ${data['no_cargo_manifest']}'),
                            //                           p.Text(
                            //                               'Date Received : ${data['date_received']}'),
                            //                           p.Text(
                            //                               'Status: ${data['status']}'),
                            //                           p.Text(
                            //                               'Remarks: ${data['remark'] ?? 'None'}'),
                            //                         ]),
                            //                     p.Column(children: [
                            //                       p.Row(children: [
                            //                         p.Column(children: [
                            //                           p.SizedBox(
                            //                             width: 400,
                            //                             height: 150,
                            //                             child: p.Image(image),
                            //                           ),
                            //                           p.Text('Serial Number')
                            //                         ]),
                            //                         p.SizedBox(width: 12),
                            //                         p.Column(children: [
                            //                           p.SizedBox(
                            //                             width: 400,
                            //                             height: 150,
                            //                             child: p.Image(imageSd),
                            //                           ),
                            //                           p.Text('Area Sidewall')
                            //                         ])
                            //                       ]),
                            //                       p.SizedBox(height: 24),
                            //                       p.Row(children: [
                            //                         p.Column(children: [
                            //                           p.SizedBox(
                            //                             width: 400,
                            //                             height: 150,
                            //                             child: p.Image(imageSd),
                            //                           ),
                            //                           p.Text('Area Sidewall')
                            //                         ]),
                            //                         p.SizedBox(width: 12),
                            //                         p.Column(children: [
                            //                           p.SizedBox(
                            //                             width: 400,
                            //                             height: 150,
                            //                             child: p.Image(imageSd),
                            //                           ),
                            //                           p.Text('Area Sidewall')
                            //                         ])
                            //                       ]),
                            //                     ]),
                            //                   ]),
                            //             ])
                            //       ];
                            //     }));
                            // final id = Uuid();
                            // final outputFile = await createFolderPath(
                            //     '${id.v4()}', 'repair',
                            //     // email: user['email'] ?? '',
                            //     // site: user['siteName'] ?? '',
                            //     customer: data['customer'],
                            //     sn: data['sn'],
                            //     date:
                            //         "${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().year}");
                            // final filePath = await savePdf(pdf, outputFile);

                            // if (filePath != null || filePath != '') {
                            //   ScaffoldMessenger.of(context)
                            //       .showSnackBar(SnackBar(
                            //           backgroundColor: green00968A,
                            //           content: Text(
                            //             'Successfull Save Data!',
                            //             style: getWhiteTextStyle(),
                            //           )));
                            // }
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Color(0xFFFB8181),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  offset: Offset(0, 4),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Generate To PDF',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 20),
                                // FaIcon(
                                //   FontAwesomeIcons.filePdf,
                                //   color: Colors.black,
                                //   size: 24,
                                // ),
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
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTextWithDashedLine(
                                  'Date Inspect',
                                  '${data['date_inspect']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Customer',
                                  '${data['customer']}',
                                ),
                                _buildTextWithDashedLine(
                                  'Site',
                                  '${data['site']}',
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
                                  '${data['date_received']}',
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
                                          child: SizedBox(
                                            width:
                                                200, // Atur lebar sesuai kebutuhan
                                            height:
                                                300, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .cover, // Sesuaikan cara gambar dipasang dalam kotak
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
                                          child: SizedBox(
                                            width:
                                                200, // Atur lebar sesuai kebutuhan
                                            height:
                                                300, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .cover, // Sesuaikan cara gambar dipasang dalam kotak
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
                                          child: SizedBox(
                                            width:
                                                200, // Atur lebar sesuai kebutuhan
                                            height:
                                                300, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .cover, // Sesuaikan cara gambar dipasang dalam kotak
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
                                          child: SizedBox(
                                            width:
                                                200, // Atur lebar sesuai kebutuhan
                                            height:
                                                300, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .cover, // Sesuaikan cara gambar dipasang dalam kotak
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
                                  'Area Threat',
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
                                          child: SizedBox(
                                            width:
                                                200, // Atur lebar sesuai kebutuhan
                                            height:
                                                300, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .cover, // Sesuaikan cara gambar dipasang dalam kotak
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
                                          child: SizedBox(
                                            width:
                                                200, // Atur lebar sesuai kebutuhan
                                            height:
                                                300, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .cover, // Sesuaikan cara gambar dipasang dalam kotak
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
                                          child: SizedBox(
                                            width:
                                                200, // Atur lebar sesuai kebutuhan
                                            height:
                                                300, // Atur tinggi sesuai kebutuhan
                                            child: Image.network(
                                              e,
                                              fit: BoxFit
                                                  .cover, // Sesuaikan cara gambar dipasang dalam kotak
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

class ImageContainer extends StatelessWidget {
  const ImageContainer(
      {super.key,
      required this.data,
      required this.type,
      required this.mapType});

  final Map<String, dynamic> data;
  final String type;
  final String mapType;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              type,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '*Choose ${type != 'Serial Number' ? '3' : '1'} Image',
              style: getRedTextStyle(),
            ),
            SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: data['${mapType}'].map<Widget>((e) {
                return Column(
                  children: [
                    Center(
                      child: SizedBox(
                        width: 200, // Atur lebar sesuai kebutuhan
                        height: 300, // Atur tinggi sesuai kebutuhan
                        child: Image.network(
                          e,
                          fit: BoxFit
                              .cover, // Sesuaikan cara gambar dipasang dalam kotak
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
    );
  }
}
