// import 'dart:io';
// import 'dart:typed_data';

// import 'package:camos/core/services/model/site_track.dart';
// import 'package:camos/core/styles/color.dart';
// import 'package:camos/core/styles/text_manager.dart';
// import 'package:camos/core/widgets/appbar_widget.dart';
// import 'package:camos/core/widgets/button_widget.dart';
// import 'package:camos/pages/site_condition/site_condition_pdf.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class SiteConditionReportPage extends StatefulWidget {
//   static const routeName = '/site-condition-report';
//   const SiteConditionReportPage({super.key});

//   @override
//   State<SiteConditionReportPage> createState() =>
//       _SiteConditionReportPageState();
// }

// class _SiteConditionReportPageState extends State<SiteConditionReportPage>
//     with TickerProviderStateMixin {
//   int currentIndex = 0;

//   final date = DateFormat('yyyy-MM-dd || HH:mm:ss').format(DateTime.now());

//   @override
//   Widget build(BuildContext context) {
//     final initialData =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
//     final data = initialData['listSiteTrack'];
//     print('site report ${data}');

//     return Builder(builder: (context) {
//       final TabController tabController =
//           TabController(length: data.length, vsync: this);
//       return Scaffold(
//         appBar: appBarWidget('Site Condition Report', context),
//         body: SafeArea(
//             child: Center(
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24),
//                   child: Column(
//                     children: [
//                       DefaultTabController(
//                           length: data.length,
//                           child: TabBar(
//                             labelColor: black,
//                             labelStyle: getBlackTextStyle(),
//                             controller: tabController,
//                             indicatorSize: TabBarIndicatorSize.tab,
//                             tabs: data.map<Widget>((track) {
//                               final index = data.indexOf(track);
//                               return Tab(
//                                 text: 'Track ${index + 1}',
//                                 icon: Icon(
//                                   Icons.map,
//                                   color: black,
//                                 ),
//                               );
//                             }).toList(),
//                           )),
//                       const SizedBox(
//                         height: 24,
//                       ),
//                       Container(
//                         height: MediaQuery.of(context).size.height * 1.2,
//                         child: TabBarView(
//                             controller: tabController,
//                             children: data.map<Widget>((track) {
//                               final index = data.indexOf(track);
//                               return Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Center(
//                                     child: Container(
//                                       height:
//                                           MediaQuery.of(context).size.height *
//                                               0.33,
//                                       margin: const EdgeInsets.symmetric(
//                                           horizontal: 42),
//                                       child: Stack(
//                                         children: [
//                                           SizedBox(
//                                               width: double.infinity,
//                                               child: Image.memory(
//                                                 track.mapTrack,
//                                                 fit: BoxFit.cover,
//                                               )),
//                                           Positioned(
//                                               bottom: 0,
//                                               left: 0,
//                                               right: 0,
//                                               child: Container(
//                                                 padding: EdgeInsets.symmetric(
//                                                     vertical: 10.0,
//                                                     horizontal: 20.0),
//                                                 decoration: BoxDecoration(
//                                                   gradient: LinearGradient(
//                                                     colors: [
//                                                       Color.fromARGB(
//                                                           200, 0, 0, 0),
//                                                       Color.fromARGB(0, 0, 0, 0)
//                                                     ],
//                                                     begin:
//                                                         Alignment.bottomCenter,
//                                                     end: Alignment.topCenter,
//                                                   ),
//                                                 ),
//                                                 child: Text(
//                                                   'Map of Site Track ${index + 1}',
//                                                   textAlign: TextAlign.center,
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 20,
//                                                     fontWeight: w700,
//                                                   ),
//                                                 ),
//                                               ))
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(
//                                     height: 12,
//                                   ),
//                                   Center(
//                                     child: Container(
//                                       width: MediaQuery.of(context).size.width *
//                                           0.7,
//                                       child: Stack(
//                                         children: [
//                                           SizedBox(
//                                               width: MediaQuery.of(context)
//                                                       .size
//                                                       .width *
//                                                   0.7,
//                                               height: MediaQuery.of(context)
//                                                       .size
//                                                       .height *
//                                                   0.5,
//                                               child: Image.file(
//                                                 File(track.hazardPicture!.path),
//                                                 fit: BoxFit.cover,
//                                               )),
//                                           Positioned(
//                                               bottom: 0,
//                                               left: 0,
//                                               right: 0,
//                                               child: Container(
//                                                 padding: EdgeInsets.symmetric(
//                                                     vertical: 10.0,
//                                                     horizontal: 20.0),
//                                                 decoration: BoxDecoration(
//                                                   gradient: LinearGradient(
//                                                     colors: [
//                                                       Color.fromARGB(
//                                                           200, 0, 0, 0),
//                                                       Color.fromARGB(0, 0, 0, 0)
//                                                     ],
//                                                     begin:
//                                                         Alignment.bottomCenter,
//                                                     end: Alignment.topCenter,
//                                                   ),
//                                                 ),
//                                                 child: Text(
//                                                   'Picture of Site Track ${index + 1}',
//                                                   textAlign: TextAlign.center,
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 20,
//                                                     fontWeight: w700,
//                                                   ),
//                                                 ),
//                                               ))
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(
//                                     height: 24,
//                                   ),
//                                   Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Route Hazard Location',
//                                         style: getBlackTextStyle(fontSize: 16),
//                                       ),
//                                       const SizedBox(
//                                         height: 6,
//                                       ),
//                                       Text(
//                                         '${track.latitude}, ${track.longitude}',
//                                         style: getBlackTextStyle(
//                                             fontSize: 16, fontWeight: w700),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(
//                                     height: 12,
//                                   ),
//                                   Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text(
//                                         'Date Captured',
//                                         style: getBlackTextStyle(fontSize: 16),
//                                       ),
//                                       const SizedBox(
//                                         height: 6,
//                                       ),
//                                       Text(
//                                         date,
//                                         style: getBlackTextStyle(
//                                             fontSize: 16, fontWeight: w700),
//                                       ),
//                                     ],
//                                   ),
//                                 ],
//                               );
//                             }).toList()),
//                       )
//                     ],
//                   ),
//                 ),
//                 const SizedBox(
//                   height: 24,
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                   child: ButtonWidget(
//                       name: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Text(
//                             'Next',
//                             style: getWhiteTextStyle(fontWeight: w700),
//                           ),
//                           const SizedBox(
//                             width: 12,
//                           ),
//                           Icon(
//                             Icons.arrow_forward_ios,
//                             size: 16,
//                           ),
//                         ],
//                       ),
//                       function: () {
//                         Navigator.pushNamed(context, SiteConditionPDF.routeName,
//                             arguments: initialData);
//                       }),
//                 ),
//                 const SizedBox(
//                   height: 24,
//                 ),
//               ],
//             ),
//           ),
//         )),
//       );
//     });
//   }
// }
