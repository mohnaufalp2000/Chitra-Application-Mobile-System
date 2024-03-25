import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/model/site_track.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/site_condition.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:uuid/uuid.dart';

// class SiteConditionPDF extends StatefulWidget {
//   static const routeName = '/site-condition-pdf';
//   const SiteConditionPDF({super.key});

//   @override
//   State<SiteConditionPDF> createState() => _SiteConditionPDFState();
// }

// class _SiteConditionPDFState extends State<SiteConditionPDF> {
//   ScreenshotController screenshotController = ScreenshotController();
//   final Uuid id = Uuid();
//   bool isLoading = false;
//   bool _isConnected = true;

//   @override
//   void initState() {
//     super.initState();
//   }

//   Future<void> checkConnectivity() async {
//     final isConnected = await InternetConnectionChecker().hasConnection;
//     setState(() {
//       _isConnected = isConnected;
//     });
//   }

//   Future<void> checkConnectivityContinuously() async {
//     InternetConnectionChecker().onStatusChange.listen((status) {
//       setState(() {
//         _isConnected = status == InternetConnectionStatus.connected;
//       });
//       if (!_isConnected) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               'No Internet Connection',
//               style: getWhiteTextStyle(
//                 fontWeight: w600,
//               ),
//             ),
//             backgroundColor: Colors.red,
//             duration: Duration(days: 365),
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       }
//     });
//   }

//   createAndSendPdf() async {
//     print('kirim');
//     final image = await capturePage(screenshotController);
//     print('kirim2');

//     final pdf = createPdf(image!);
//     print('kirim3');

//     final outputFile = await createFolderPath('site-${id.v4()}', 'site');
//     print('kirim4');

//     final filePath = await savePdf(pdf, outputFile);
//     print('kirim5');

//     sendEmailWithAttachment(filePath, 'site');
//     print('kirim6');
//   }

//   createAndSavePdf() async {
//     final image = await capturePage(screenshotController);

//     final pdf = createPdf(image!);

//     final outputFile = await createFolderPath('site-${id.v4()}', 'site');

//     final filePath = await savePdf(pdf, outputFile);

//     if (filePath != null || filePath != '') {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           backgroundColor: green00968A,
//           content: Text(
//             'Successfull Save Data!',
//             style: getWhiteTextStyle(),
//           )));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final initialData =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
//     final data = initialData['listSiteTrack'];
//     final capturedEntireMap = initialData['capturedEntireMap'];
//     final date = DateFormat('yyyy-MM-dd || HH:mm:ss').format(DateTime.now());

//     return Scaffold(
//       appBar: appBar(),
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: SingleChildScrollView(
//             child: Screenshot(
//               controller: screenshotController,
//               child: Column(
//                 children: [
//                   const SizedBox(
//                     height: 24,
//                   ),
//                   Text(
//                     'Site Condition Report',
//                     style: getBlackTextStyle(
//                       fontSize: 20,
//                       fontWeight: w700,
//                     ),
//                   ),
//                   const SizedBox(
//                     height: 24,
//                   ),
//                   Card(
//                     elevation: 2,
//                     child: ClipRRect(
//                       borderRadius: BorderRadius.circular(24),
//                       child: Padding(
//                         padding: const EdgeInsets.all(24.0),
//                         child: Column(
//                           children: [
//                             InkWell(
//                               onTap: () async {
//                                 // await createAndSendPdf();
//                               },
//                               child: Text(
//                                 'Detail Site Location',
//                                 textAlign: TextAlign.center,
//                                 style: getBlackTextStyle(
//                                     fontSize: 16, fontWeight: w700),
//                               ),
//                             ),
//                             const SizedBox(
//                               height: 12,
//                             ),
//                             Column(
//                               children: data.map<Widget>((track) {
//                                 final index = data.indexOf(track);
//                                 final size = data.length;
//                                 return DetailLocation(
//                                     track: track,
//                                     date: date,
//                                     index: index,
//                                     size: size);
//                               }).toList(),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(
//                     height: 24,
//                   ),
//                   Text(
//                     'Map of Site',
//                     style: getBlackTextStyle(
//                       fontSize: 20,
//                       fontWeight: w500,
//                     ),
//                   ),
//                   const SizedBox(
//                     height: 24,
//                   ),
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(24),
//                     child: Container(
//                       width: double.infinity,
//                       color: Colors.red,
//                       height: MediaQuery.of(context).size.height * 0.5,
//                       child: Image.memory(
//                         initialData['capturedEntireMap'],
//                         fit: BoxFit.cover,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(
//                     height: 24,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//       bottomNavigationBar: Container(
//         padding: EdgeInsets.symmetric(vertical: 24, horizontal: 12),
//         color: grey6A707C,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: ButtonWidget(
//                   name: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.picture_as_pdf),
//                       const SizedBox(
//                         width: 12,
//                       ),
//                       Text(
//                         'Save to PDF',
//                         style: getWhiteTextStyle(fontWeight: w700),
//                       ),
//                     ],
//                   ),
//                   function: () async {
//                     await createAndSavePdf();
//                   }),
//             ),
//             const SizedBox(
//               height: 12,
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: ButtonWidget(
//                   name: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.email),
//                       const SizedBox(
//                         width: 12,
//                       ),
//                       Text(
//                         'Send to Email',
//                         style: getWhiteTextStyle(fontWeight: w700),
//                       ),
//                     ],
//                   ),
//                   function: () async {
//                     setState(() {
//                       isLoading = true;
//                     });
//                     await createAndSendPdf();
//                     setState(() {
//                       isLoading = false;
//                     });
//                   }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget appBar() {
//     return AppBar(
//       backgroundColor: Colors.transparent,
//       elevation: 0,
//       title: (isLoading)
//           ? Container(
//               margin: EdgeInsets.only(top: 24),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Wait',
//                     style: getBlackTextStyle(
//                       fontWeight: w700,
//                     ),
//                   ),
//                   const SizedBox(
//                     width: 12,
//                   ),
//                   CircularProgressIndicator(),
//                 ],
//               ),
//             )
//           : Container(
//               margin: EdgeInsets.only(top: 24),
//               child: Text(
//                 '',
//                 style: getBlackTextStyle(fontWeight: w700),
//               ),
//             ),
//       centerTitle: true,
//       leading: Padding(
//         padding: const EdgeInsets.only(left: 16),
//         child: Container(
//           margin: const EdgeInsets.only(top: 14),
//           padding: const EdgeInsets.symmetric(horizontal: 4),
//           decoration: BoxDecoration(
//             color: white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: black),
//           ),
//           child: IconButton(
//               onPressed: () {
//                 back(context);
//               },
//               icon: const Icon(
//                 Icons.arrow_back_ios,
//                 color: black,
//                 size: 24,
//               )),
//         ),
//       ),
//     );
//   }
// }

// class DetailLocation extends StatelessWidget {
//   const DetailLocation({
//     super.key,
//     required this.track,
//     required this.date,
//     required this.size,
//     required this.index,
//   });

//   final SiteTrack track;
//   final String date;
//   final int index;
//   final int size;

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Track ${index + 1}',
//           style: getBlackTextStyle(fontWeight: w600, fontSize: 16),
//         ),
//         const SizedBox(
//           height: 12,
//         ),
//         // Row(
//         //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         //   children: [
//         //     Text(
//         //       'First Location ',
//         //       style: getBlackTextStyle(fontSize: 12),
//         //     ),
//         //     Text(
//         //       '${track.latitude}, ${track.longitude}',
//         //       style: getBlackTextStyle(
//         //         fontWeight: w700,
//         //       ),
//         //     ),
//         //   ],
//         // ),
//         // const SizedBox(
//         //   height: 12,
//         // ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Route Hazard Location',
//               style: getBlackTextStyle(fontSize: 12),
//             ),
//             Text(
//               '${track.latitude}, ${track.longitude}',
//               style: getBlackTextStyle(
//                 fontWeight: w700,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(
//           height: 12,
//         ),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(
//               'Date Captured',
//               style: getBlackTextStyle(fontSize: 12),
//             ),
//             Text(
//               date,
//               style: getBlackTextStyle(
//                 fontSize: 16,
//                 fontWeight: w700,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(
//           height: 12,
//         ),
//         Text(
//           'Picture of Site',
//           style: getBlackTextStyle(),
//         ),
//         const SizedBox(
//           height: 12,
//         ),
//         Center(
//           child: SizedBox(
//             height: MediaQuery.of(context).size.height * 0.3,
//             child: Image.file(File(track.hazardPicture!.path)),
//           ),
//         ),
//         (index != size - 1)
//             ? Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 8.0),
//                 child: Divider(
//                   thickness: 2,
//                 ),
//               )
//             : SizedBox()
//       ],
//     );
//   }
// }

class SiteConditionPDF extends StatefulWidget {
  static const routeName = '/site-condition-pdf';
  const SiteConditionPDF({super.key});
  @override
  State<SiteConditionPDF> createState() => _SiteConditionPDFState();
}

class _SiteConditionPDFState extends State<SiteConditionPDF> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    final data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final listSiteCondition = data['listSiteCondition'] as List<SiteCondition>;
    final siteName = data['siteName'];

    log('jumlah : ${listSiteCondition.length}');

    return Scaffold(
      appBar: appBarWidget('Site Condition Report', context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Screenshot(
            controller: screenshotController,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    siteName,
                    style: getBlackTextStyle(fontSize: 24),
                  ),
                  const SizedBox(
                    height: 24,
                  ),
                  Column(
                    children: listSiteCondition.map((condition) {
                      final index = listSiteCondition.indexOf(condition);
                      log('index : $index');
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Location Point  ${index + 1}',
                            style: getBlackTextStyle(),
                          ),
                          Text(
                            condition.name,
                            style: getBlackTextStyle(
                              fontSize: 24,
                              fontWeight: w700,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Wrap(
                            spacing: 7,
                            children: condition.image.map((img) {
                              return SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.33,
                                  child: Image.file(File(img)));
                            }).toList(),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Divider(),
                          Row(
                            children: [
                              Icon(Icons.access_time),
                              const SizedBox(
                                width: 6,
                              ),
                              Text(
                                '${condition.date}',
                                style: getBlackTextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Row(
                            children: [
                              Icon(Icons.location_pin),
                              const SizedBox(
                                width: 6,
                              ),
                              Text(
                                '${condition.latitude}, ${condition.longitude}',
                                style: getBlackTextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          Divider(),
                          Text(
                            'Remarks',
                            style: getBlackTextStyle(
                              fontWeight: w700,
                            ),
                          ),
                          Text(
                            condition.remarks,
                            style: getBlackTextStyle(),
                          ),
                          (index != listSiteCondition.length - 1)
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0),
                                  child: DottedLine(
                                    lineThickness: 3,
                                    dashGapLength: 5,
                                    dashLength: 20,
                                    dashColor: grey8391A1,
                                    dashRadius: 10,
                                  ),
                                )
                              : const SizedBox(
                                  height: 0,
                                ),
                        ],
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                requestStoragePermission();
                // DateTime now = DateTime.now();
                // String formattedDate =
                //     DateFormat('yyyy-MM-dd HH:mm').format(now);
                final id = Uuid();
                final image = await capturePage(screenshotController);
                final pdf = createPdf(image!);

                final outputFile = await createFolderPath('${id.v4()}', 'site');
                final filePath = await savePdf(pdf, outputFile);
                log('gambar $filePath');

                if (filePath != null || filePath != '') {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: green00968A,
                      content: Text(
                        'Successfull Save Data!',
                        style: getWhiteTextStyle(),
                      )));
                }
              },
              child: Container(
                padding: EdgeInsets.all(24),
                color: blue344BEF,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.save,
                      color: white,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      'SAVE',
                      textAlign: TextAlign.center,
                      style: getWhiteTextStyle(
                        fontSize: 20,
                        fontWeight: w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                // final image = await capturePage(screenshotController);
                // final pdf = createPdf(image!);
                // final outputFile =
                //     await createFolderPath(data['idUnit'], 'tkph');
                // final filePath = await savePdf(pdf, outputFile);
                // sendEmailWithAttachment(filePath, 'tkph');
              },
              child: Container(
                padding: EdgeInsets.all(24),
                color: green00968A,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.share,
                      color: white,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      'SHARE',
                      textAlign: TextAlign.center,
                      style: getWhiteTextStyle(
                        fontSize: 20,
                        fontWeight: w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
