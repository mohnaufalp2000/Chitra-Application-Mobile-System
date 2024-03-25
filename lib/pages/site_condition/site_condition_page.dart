// import 'dart:io';

// import 'package:camos/core/blocs/network/network_bloc.dart';
// import 'package:camos/core/navigator/navigation_route.dart';
// import 'package:camos/core/services/model/site_track.dart';
// import 'package:camos/core/styles/asset_path.dart';
// import 'package:camos/core/styles/color.dart';
// import 'package:camos/core/styles/text_manager.dart';
// import 'package:camos/core/widgets/button_widget.dart';
// import 'package:camos/core/widgets/custom_error_widget.dart';
// import 'package:camos/core/widgets/input_form_widget.dart';
// import 'package:camos/core/widgets/network_checker_widget.dart';
// import 'package:camos/pages/site_condition/site_condition_report_page.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:geolocator/geolocator.dart';
// // import 'package:here_sdk/core.dart';
// // import 'package:here_sdk/mapview.dart';
// // import 'package:here_sdk/routing.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:internet_connection_checker/internet_connection_checker.dart';
// import 'package:screenshot/screenshot.dart';

// class SiteConditionPage extends StatefulWidget {
//   static const routeName = '/site-condition-page';
//   const SiteConditionPage({super.key});

//   @override
//   State<SiteConditionPage> createState() => _SiteConditionPageState();
// }

// class _SiteConditionPageState extends State<SiteConditionPage> {
//   ScreenshotController scController = ScreenshotController();
//   PlatformFile? pickedFile;

//   TextEditingController nameTrackCtrl = TextEditingController();

//   GeoCoordinates? _firstCurrentLocation;
//   GeoCoordinates? _nextCurrentLocation;

//   HereMapController? _hereMapController;
//   List<MapMarker> listMapMarker = [];
//   List<MapPolyline> listMapPolyline = [];
//   List<SiteTrack> listSiteTrack = [];

//   double latitude = 0.0;
//   double longitude = 0.0;
//   double altitude = 0.0;

//   bool isMarked = false;
//   bool isTracking = false;

//   List<GeoCoordinates> _routeCoordinates = [];

//   @override
//   void dispose() {
//     super.dispose();
//   }

//   @override
//   void initState() {
//     super.initState();
//   }

//   Future<Position> _getCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

//     if (!serviceEnabled) {
//       return Future.error('Location services are disabled');
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         return Future.error('Location permission denied');
//       }
//     }

//     return await Geolocator.getCurrentPosition();
//   }

//   Future selectFile() async {
//     final result = await FilePicker.platform.pickFiles();
//     if (result == null) return;

//     setState(() {
//       pickedFile = result.files.first;
//     });
//   }

//   void _onMapCreated(HereMapController? hereMapController) async {
//     _hereMapController = hereMapController;

//     //// Define Here Map Controller
//     _hereMapController?.mapScene.loadSceneForMapScheme(MapScheme.satellite,
//         (MapError? error) async {
//       if (error != null) {
//         print('Map scene not loaded. MapError: ${error.toString()}');
//         return;
//       }

//       // show map to application
//       moveMapCamera();
//     });
//   }

//   moveMapCamera(
//       {double latitude = -1.1787901722446712,
//       double longitude = 116.85378757291771}) {
//     //// set distance map from space
//     const double distanceToEarthInMeters = 1000;
//     MapMeasure mapMeasureZoom =
//         MapMeasure(MapMeasureKind.distance, distanceToEarthInMeters);

//     _hereMapController?.camera.lookAtPointWithMeasure(
//         GeoCoordinates(latitude, longitude), mapMeasureZoom);
//   }

//   // addDataToSiteTrack() {
//   //   listSiteTrack.add(SiteTrack(
//   //       mapTrack: mapTrack,
//   //       hazardPicture: hazardPicture,
//   //       latitude: latitude,
//   //       longitude: longitude,
//   //       altitude: altitude));
//   // }

//   Future<void> addPin(
//       bool isInitialPlace, int drawOrder, GeoCoordinates geoCordinates) async {
//     //// delete recent marker first
//     // removeMapMarkers();

//     try {
//       // get image from asset
//       ByteData fileData = await rootBundle
//           .load('$imagePath/${(isInitialPlace) ? 'engineer.png' : 'poi.png'}');
//       // convert image to Uint8List
//       Uint8List pixelData = fileData.buffer.asUint8List();
//       // define image format
//       MapImage mapimage =
//           MapImage.withPixelDataAndImageFormat(pixelData, ImageFormat.png);
//       // create map marker
//       MapMarker mapMarker = MapMarker(geoCordinates, mapimage);
//       mapMarker.drawOrder = drawOrder;
//       listMapMarker.add(mapMarker);

//       // add map marker to map controller
//       _hereMapController?.mapScene.addMapMarker(mapMarker);
//     } catch (e) {
//       print('error: ${e.toString()}');
//     }
//   }

//   void removeMapMarkers() {
//     if (_hereMapController != null && listMapMarker.isNotEmpty) {
//       _hereMapController?.mapScene.removeMapMarkers(listMapMarker);
//       listMapMarker.clear();
//     }
//   }

//   void removeMapPolyline() {
//     if (_hereMapController != null && listMapPolyline.isNotEmpty) {
//       _hereMapController?.mapScene.removeMapPolylines(listMapPolyline);
//       listMapPolyline.clear();
//     }
//   }

//   Future<void> addRoute(
//       GeoCoordinates startPoint, GeoCoordinates endPoint) async {
//     if (listMapPolyline.isNotEmpty) {
//       _hereMapController?.mapScene.removeMapPolyline(listMapPolyline[0]);
//     }
//     listMapPolyline.clear();
//     RoutingEngine routingEngine = RoutingEngine();

//     Waypoint startWaypoint = Waypoint.withDefaults(startPoint);
//     Waypoint endWaypoint = Waypoint.withDefaults(endPoint);

//     List<Waypoint> waypoints = [startWaypoint, endWaypoint];

//     //// calculate route
//     routingEngine.calculateCarRoute(waypoints, CarOptions.withDefaults(),
//         (error, routing) {
//       if (error == null) {
//         var route = routing!.first;
//         GeoPolyline routeGeoPolyline = route.geometry;
//         double widthInPixels = 20;
//         var mpPolyline =
//             MapPolyline(routeGeoPolyline, widthInPixels, Colors.blue);
//         listMapPolyline.add(mpPolyline);
//         _hereMapController?.mapScene.addMapPolyline(listMapPolyline[0]);
//       }
//     });
//   }

//   // MapPolyline? addRoute(GeoCoordinates startPoint, GeoCoordinates endPoint) {
//   //   if (listMapPolyline.isNotEmpty) {
//   //     _hereMapController?.mapScene.removeMapPolyline(listMapPolyline[0]);
//   //     listMapPolyline.clear();
//   //   }

//   //   List<GeoCoordinates> coordinates = [];
//   //   coordinates.add(startPoint);
//   //   coordinates.add(endPoint);

//   //   GeoPolyline geoPolyline;
//   //   try {
//   //     geoPolyline = GeoPolyline(coordinates);
//   //   } on InstantiationException {
//   //     // Thrown when less than two vertices.
//   //     return null;
//   //   }

//   //   double widthInPixels = 20;
//   //   Color lineColor = Color.fromARGB(160, 0, 144, 138);
//   //   MapPolyline mapPolyline =
//   //       MapPolyline(geoPolyline, widthInPixels, lineColor);
//   //   listMapPolyline.add(mapPolyline);
//   //   _hereMapController?.mapScene.addMapPolyline(listMapPolyline[0]);
//   //   return mapPolyline;
//   // }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         // appBar: appBarWidget('Site Condition', context),
//         body: Stack(
//       children: [
//         DraggableScrollableSheet(
//             initialChildSize: 0.5,
//             minChildSize: 0.5,
//             maxChildSize: 1,
//             snapSizes: [0.5, 1],
//             snap: true,
//             builder: (context, scrollController) {
//               return Container(
//                 child: ListView(
//                   physics: ClampingScrollPhysics(),
//                   padding: EdgeInsets.zero,
//                   controller: scrollController,
//                   children: [
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 12.0),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.stretch,
//                         children: [
//                           Column(
//                             children: [
//                               const SizedBox(
//                                 width: 60,
//                                 child: Divider(
//                                   thickness: 3,
//                                 ),
//                               ),
//                               const SizedBox(
//                                 height: 24,
//                               ),
//                               Text(
//                                 'Site Condition Menu',
//                                 style: getBlackTextStyle(
//                                     fontSize: 20, fontWeight: w700),
//                               ),
//                               const SizedBox(
//                                 height: 24,
//                               ),
//                               ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon((isTracking)
//                                           ? Icons.stop
//                                           : Icons.track_changes),
//                                       const SizedBox(
//                                         width: 12,
//                                       ),
//                                       Text(
//                                         (isTracking)
//                                             ? 'Finish Tracking'
//                                             : 'Start Tracking',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                     ],
//                                   ),
//                                   function: () async {
//                                     // set first location before leave
//                                     if (!isTracking) {
//                                       setState(() {
//                                         isTracking = true;
//                                       });
//                                       final dataFromCurrentLoc =
//                                           await _getCurrentLocation();
//                                       _firstCurrentLocation = GeoCoordinates(
//                                           dataFromCurrentLoc.latitude,
//                                           dataFromCurrentLoc.longitude);
//                                       moveMapCamera(
//                                           latitude:
//                                               _firstCurrentLocation?.latitude ??
//                                                   0,
//                                           longitude: _firstCurrentLocation
//                                                   ?.longitude ??
//                                               0);
//                                       addPin(
//                                           true,
//                                           0,
//                                           GeoCoordinates(
//                                               _firstCurrentLocation?.latitude ??
//                                                   0,
//                                               _firstCurrentLocation
//                                                       ?.longitude ??
//                                                   0));
//                                     } else {
//                                       setState(() {
//                                         isTracking = false;
//                                       });
//                                       removeMapMarkers();
//                                       removeMapPolyline();
//                                     }
//                                   }),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.camera),
//                                       const SizedBox(
//                                         width: 12,
//                                       ),
//                                       Text(
//                                         'Open Camera',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                     ],
//                                   ),
//                                   function: (isMarked && isTracking)
//                                       ? () async {
//                                           final capturedMap =
//                                               await scController.capture();

//                                           ImagePicker imagePicker =
//                                               ImagePicker();
//                                           final capturedPhoto =
//                                               await imagePicker.pickImage(
//                                                   preferredCameraDevice:
//                                                       CameraDevice.rear,
//                                                   source: ImageSource.camera);

//                                           setState(() {
//                                             if (capturedPhoto != null) {
//                                               listSiteTrack.add(SiteTrack(
//                                                   nameTrack: nameTrackCtrl.text,
//                                                   mapTrack: capturedMap,
//                                                   hazardPicture: capturedPhoto,
//                                                   latitude: latitude,
//                                                   longitude: longitude,
//                                                   altitude: altitude));
//                                             }
//                                           });

//                                           print(
//                                             'track site $listSiteTrack',
//                                           );
//                                         }
//                                       : null),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.location_on),
//                                       const SizedBox(
//                                         width: 12,
//                                       ),
//                                       Text(
//                                         'Mark Location',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                     ],
//                                   ),
//                                   function: (isTracking)
//                                       ? () async {
//                                           final dataFromCurrentLoc =
//                                               await _getCurrentLocation();
//                                           _nextCurrentLocation = GeoCoordinates(
//                                               dataFromCurrentLoc.latitude,
//                                               dataFromCurrentLoc.longitude);
//                                           moveMapCamera(
//                                               latitude: _nextCurrentLocation
//                                                       ?.latitude ??
//                                                   0,
//                                               longitude: _nextCurrentLocation
//                                                       ?.longitude ??
//                                                   0);
//                                           addPin(
//                                               false,
//                                               1,
//                                               GeoCoordinates(
//                                                   _nextCurrentLocation
//                                                           ?.latitude ??
//                                                       0,
//                                                   _nextCurrentLocation
//                                                           ?.longitude ??
//                                                       0));
//                                           addRoute(
//                                               GeoCoordinates(
//                                                   _firstCurrentLocation
//                                                           ?.latitude ??
//                                                       0,
//                                                   _firstCurrentLocation
//                                                           ?.longitude ??
//                                                       0),
//                                               GeoCoordinates(
//                                                   _nextCurrentLocation
//                                                           ?.latitude ??
//                                                       0,
//                                                   _nextCurrentLocation
//                                                           ?.longitude ??
//                                                       0));

//                                           setState(() {
//                                             isMarked = true;
//                                             latitude = _nextCurrentLocation
//                                                     ?.latitude ??
//                                                 0;
//                                             longitude = _nextCurrentLocation
//                                                     ?.longitude ??
//                                                 0;
//                                           });
//                                         }
//                                       : null),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.save),
//                                       const SizedBox(
//                                         width: 12,
//                                       ),
//                                       Text(
//                                         'Save',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                     ],
//                                   ),
//                                   function: (listSiteTrack.isNotEmpty)
//                                       ? () async {
//                                           final capturedEntireMap =
//                                               await scController.capture();
//                                           Navigator.pushReplacementNamed(
//                                             context,
//                                             SiteConditionReportPage.routeName,
//                                             arguments: {
//                                               'listSiteTrack': listSiteTrack,
//                                               'capturedEntireMap':
//                                                   capturedEntireMap
//                                             },
//                                           );
//                                         }
//                                       : null)
//                             ],
//                           ),
//                           const SizedBox(
//                             height: 24,
//                           ),
//                           (listSiteTrack.isNotEmpty ||
//                                   listSiteTrack.length != 0)
//                               ? Column(
//                                   crossAxisAlignment:
//                                       CrossAxisAlignment.stretch,
//                                   children: [
//                                     Text(
//                                       'Detail Site Location',
//                                       textAlign: TextAlign.center,
//                                       style: getBlackTextStyle(
//                                           fontSize: 20, fontWeight: w700),
//                                     ),
//                                     const SizedBox(
//                                       height: 24,
//                                     ),
//                                     Column(
//                                       children: listSiteTrack.map((siteTrack) {
//                                         final index =
//                                             listSiteTrack.indexOf(siteTrack);
//                                         return trackInformation(
//                                             siteTrack, index);
//                                       }).toList(),
//                                     )
//                                   ],
//                                 )
//                               : Container(),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }),
//         LayoutBuilder(builder: (context, constraints) {
//           return BlocBuilder<NetworkBloc, NetworkState>(
//             builder: (context, state) {
//               if (state is NetworkConnected) {
//                 return Screenshot(
//                   controller: scController,
//                   child: SizedBox(
//                     height: constraints.maxHeight / 2,
//                     child: HereMap(
//                       onMapCreated: _onMapCreated,
//                     ),
//                   ),
//                 );
//               } else if (state is NetworkDisconnected) {
//                 return NetworkCheckerWidget();
//               } else {
//                 return Container();
//               }
//             },
//           );
//         }),
//       ],
//     ));
//     //     body: SafeArea(
//     //   child: SingleChildScrollView(
//     //     child: Column(
//     //       children: [
//     //         BlocBuilder<NetworkBloc, NetworkState>(
//     //           builder: (context, state) {
//     //             if (state is NetworkConnected) {
//     //               return Screenshot(
//     //                 controller: scController,
//     //                 child: SizedBox(
//     //                   width: double.infinity,
//     //                   height: MediaQuery.of(context).size.height * 0.7,
//     //                   child: HereMap(
//     //                     onMapCreated: _onMapCreated,
//     //                   ),
//     //                 ),
//     //               );
//     //             } else if (state is NetworkDisconnected) {
//     //               return NetworkCheckerWidget();
//     //             } else {
//     //               return Container();
//     //             }
//     //           },
//     //         ),
//     //         const SizedBox(
//     //           height: 24,
//     //         ),

//     //         Padding(
//     //           padding: const EdgeInsets.symmetric(horizontal: 12.0),
//     //           child: Column(
//     //             crossAxisAlignment: CrossAxisAlignment.stretch,
//     //             children: [
//     //               Column(
//     //                 children: [
//     //                   const SizedBox(
//     //                     width: 60,
//     //                     child: Divider(
//     //                       thickness: 3,
//     //                     ),
//     //                   ),
//     //                   const SizedBox(
//     //                     height: 24,
//     //                   ),
//     //                   Text(
//     //                     'Site Condition Menu',
//     //                     style:
//     //                         getBlackTextStyle(fontSize: 20, fontWeight: w700),
//     //                   ),
//     //                   const SizedBox(
//     //                     height: 24,
//     //                   ),
//     //                   ButtonWidget(
//     //                       name: Row(
//     //                         mainAxisAlignment: MainAxisAlignment.center,
//     //                         children: [
//     //                           Icon((isTracking)
//     //                               ? Icons.stop
//     //                               : Icons.track_changes),
//     //                           const SizedBox(
//     //                             width: 12,
//     //                           ),
//     //                           Text(
//     //                             (isTracking)
//     //                                 ? 'Finish Tracking'
//     //                                 : 'Start Tracking',
//     //                             style: getWhiteTextStyle(),
//     //                           ),
//     //                         ],
//     //                       ),
//     //                       function: () async {
//     //                         // set first location before leave
//     //                         if (!isTracking) {
//     //                           setState(() {
//     //                             isTracking = true;
//     //                           });
//     //                           final dataFromCurrentLoc =
//     //                               await _getCurrentLocation();
//     //                           _firstCurrentLocation = GeoCoordinates(
//     //                               dataFromCurrentLoc.latitude,
//     //                               dataFromCurrentLoc.longitude);
//     //                           moveMapCamera(
//     //                               latitude:
//     //                                   _firstCurrentLocation?.latitude ?? 0,
//     //                               longitude:
//     //                                   _firstCurrentLocation?.longitude ?? 0);
//     //                           addPin(
//     //                               true,
//     //                               0,
//     //                               GeoCoordinates(
//     //                                   _firstCurrentLocation?.latitude ?? 0,
//     //                                   _firstCurrentLocation?.longitude ?? 0));
//     //                         } else {
//     //                           setState(() {
//     //                             isTracking = false;
//     //                           });
//     //                           removeMapMarkers();
//     //                           removeMapPolyline();
//     //                         }
//     //                       }),
//     //                   const SizedBox(
//     //                     height: 12,
//     //                   ),
//     //                   ButtonWidget(
//     //                       name: Row(
//     //                         mainAxisAlignment: MainAxisAlignment.center,
//     //                         children: [
//     //                           Icon(Icons.camera),
//     //                           const SizedBox(
//     //                             width: 12,
//     //                           ),
//     //                           Text(
//     //                             'Open Camera',
//     //                             style: getWhiteTextStyle(),
//     //                           ),
//     //                         ],
//     //                       ),
//     //                       function: (isMarked && isTracking)
//     //                           ? () async {
//     //                               final capturedMap =
//     //                                   await scController.capture();

//     //                               ImagePicker imagePicker = ImagePicker();
//     //                               final capturedPhoto =
//     //                                   await imagePicker.pickImage(
//     //                                       preferredCameraDevice:
//     //                                           CameraDevice.rear,
//     //                                       source: ImageSource.camera);

//     //                               setState(() {
//     //                                 if (capturedPhoto != null) {
//     //                                   listSiteTrack.add(SiteTrack(
//     //                                       mapTrack: capturedMap,
//     //                                       hazardPicture: capturedPhoto,
//     //                                       latitude: latitude,
//     //                                       longitude: longitude,
//     //                                       altitude: altitude));
//     //                                 }
//     //                               });

//     //                               print(
//     //                                 'track site $listSiteTrack',
//     //                               );
//     //                             }
//     //                           : null),
//     //                   const SizedBox(
//     //                     height: 12,
//     //                   ),
//     //                   ButtonWidget(
//     //                       name: Row(
//     //                         mainAxisAlignment: MainAxisAlignment.center,
//     //                         children: [
//     //                           Icon(Icons.location_on),
//     //                           const SizedBox(
//     //                             width: 12,
//     //                           ),
//     //                           Text(
//     //                             'Mark Location',
//     //                             style: getWhiteTextStyle(),
//     //                           ),
//     //                         ],
//     //                       ),
//     //                       function: (isTracking)
//     //                           ? () async {
//     //                               final dataFromCurrentLoc =
//     //                                   await _getCurrentLocation();
//     //                               _nextCurrentLocation = GeoCoordinates(
//     //                                   dataFromCurrentLoc.latitude,
//     //                                   dataFromCurrentLoc.longitude);
//     //                               moveMapCamera(
//     //                                   latitude:
//     //                                       _nextCurrentLocation?.latitude ?? 0,
//     //                                   longitude:
//     //                                       _nextCurrentLocation?.longitude ?? 0);
//     //                               addPin(
//     //                                   false,
//     //                                   1,
//     //                                   GeoCoordinates(
//     //                                       _nextCurrentLocation?.latitude ?? 0,
//     //                                       _nextCurrentLocation?.longitude ??
//     //                                           0));
//     //                               addRoute(
//     //                                   GeoCoordinates(
//     //                                       _firstCurrentLocation?.latitude ?? 0,
//     //                                       _firstCurrentLocation?.longitude ??
//     //                                           0),
//     //                                   GeoCoordinates(
//     //                                       _nextCurrentLocation?.latitude ?? 0,
//     //                                       _nextCurrentLocation?.longitude ??
//     //                                           0));

//     //                               setState(() {
//     //                                 isMarked = true;
//     //                                 latitude =
//     //                                     _nextCurrentLocation?.latitude ?? 0;
//     //                                 longitude =
//     //                                     _nextCurrentLocation?.longitude ?? 0;
//     //                               });
//     //                             }
//     //                           : null),
//     //                   const SizedBox(
//     //                     height: 12,
//     //                   ),
//     //                   ButtonWidget(
//     //                       name: Row(
//     //                         mainAxisAlignment: MainAxisAlignment.center,
//     //                         children: [
//     //                           Icon(Icons.save),
//     //                           const SizedBox(
//     //                             width: 12,
//     //                           ),
//     //                           Text(
//     //                             'Save',
//     //                             style: getWhiteTextStyle(),
//     //                           ),
//     //                         ],
//     //                       ),
//     //                       function: (listSiteTrack.isNotEmpty)
//     //                           ? () async {
//     //                               final capturedEntireMap =
//     //                                   await scController.capture();
//     //                               Navigator.pushReplacementNamed(
//     //                                 context,
//     //                                 SiteConditionReportPage.routeName,
//     //                                 arguments: {
//     //                                   'listSiteTrack': listSiteTrack,
//     //                                   'capturedEntireMap': capturedEntireMap
//     //                                 },
//     //                               );
//     //                             }
//     //                           : null)
//     //                 ],
//     //               ),
//     //               const SizedBox(
//     //                 height: 24,
//     //               ),
//     //               (listSiteTrack.isNotEmpty || listSiteTrack.length != 0)
//     //                   ? Column(
//     //                       crossAxisAlignment: CrossAxisAlignment.stretch,
//     //                       children: [
//     //                         Text(
//     //                           'Detail Site Location',
//     //                           textAlign: TextAlign.center,
//     //                           style: getBlackTextStyle(
//     //                               fontSize: 20, fontWeight: w700),
//     //                         ),
//     //                         const SizedBox(
//     //                           height: 24,
//     //                         ),
//     //                         Column(
//     //                           children: listSiteTrack.map((siteTrack) {
//     //                             final index = listSiteTrack.indexOf(siteTrack);
//     //                             return trackInformation(siteTrack, index);
//     //                           }).toList(),
//     //                         )
//     //                       ],
//     //                     )
//     //                   : Container(),
//     //             ],
//     //           ),
//     //         ),

//     //       ],
//     //     ),
//     //   ),
//     // ));

//     //     body: Stack(
//     //   children: [
//     //     BlocBuilder<NetworkBloc, NetworkState>(
//     //       builder: (context, state) {
//     //         if (state is NetworkConnected) {
//     //           return Screenshot(
//     //             controller: scController,
//     //             // child: Container(),
//     //             child: Positioned(
//     //                 bottom: MediaQuery.of(context).size.height * 0.3,
//     //                 child: HereMap(
//     //                   onMapCreated: _onMapCreated,
//     //                 )),
//     //           );
//     //         } else if (state is NetworkDisconnected) {
//     //           return NetworkCheckerWidget();
//     //         } else {
//     //           return Container();
//     //         }
//     //       },
//     //     ),
//     //     Positioned.fill(
//     //         child: DraggableScrollableSheet(
//     //       maxChildSize: 0.7,
//     //       minChildSize: 0.1,
//     //       initialChildSize: 0.2,
//     //       builder: (_, scrollController) {
//     //         return Material(
//     //           elevation: 10,
//     //           borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//     //           child: Container(
//     //             padding: const EdgeInsets.symmetric(horizontal: 24.0),
//     //             child: ListView(
//     //               controller: scrollController,
//     //               children: [
//     //                 Column(
//     //                   crossAxisAlignment: CrossAxisAlignment.stretch,
//     //                   children: [
//     //                     Column(
//     //                       children: [
//     //                         const SizedBox(
//     //                           width: 60,
//     //                           child: Divider(
//     //                             thickness: 3,
//     //                           ),
//     //                         ),
//     //                         const SizedBox(
//     //                           height: 24,
//     //                         ),
//     //                         Text(
//     //                           'Site Condition Menu',
//     //                           style: getBlackTextStyle(
//     //                               fontSize: 20, fontWeight: w700),
//     //                         ),
//     //                         const SizedBox(
//     //                           height: 24,
//     //                         ),
//     //                         ButtonWidget(
//     //                             name: Row(
//     //                               mainAxisAlignment: MainAxisAlignment.center,
//     //                               children: [
//     //                                 Icon((isTracking)
//     //                                     ? Icons.stop
//     //                                     : Icons.track_changes),
//     //                                 const SizedBox(
//     //                                   width: 12,
//     //                                 ),
//     //                                 Text(
//     //                                   (isTracking)
//     //                                       ? 'Finish Tracking'
//     //                                       : 'Start Tracking',
//     //                                   style: getWhiteTextStyle(),
//     //                                 ),
//     //                               ],
//     //                             ),
//     //                             function: () async {
//     //                               // set first location before leave
//     //                               if (!isTracking) {
//     //                                 setState(() {
//     //                                   isTracking = true;
//     //                                 });
//     //                                 final dataFromCurrentLoc =
//     //                                     await _getCurrentLocation();
//     //                                 _firstCurrentLocation = GeoCoordinates(
//     //                                     dataFromCurrentLoc.latitude,
//     //                                     dataFromCurrentLoc.longitude);
//     //                                 moveMapCamera(
//     //                                     latitude:
//     //                                         _firstCurrentLocation?.latitude ??
//     //                                             0,
//     //                                     longitude:
//     //                                         _firstCurrentLocation?.longitude ??
//     //                                             0);
//     //                                 addPin(
//     //                                     true,
//     //                                     0,
//     //                                     GeoCoordinates(
//     //                                         _firstCurrentLocation?.latitude ??
//     //                                             0,
//     //                                         _firstCurrentLocation?.longitude ??
//     //                                             0));
//     //                               } else {
//     //                                 setState(() {
//     //                                   isTracking = false;
//     //                                 });
//     //                                 removeMapMarkers();
//     //                                 removeMapPolyline();
//     //                               }
//     //                             }),
//     //                         const SizedBox(
//     //                           height: 12,
//     //                         ),
//     //                         ButtonWidget(
//     //                             name: Row(
//     //                               mainAxisAlignment: MainAxisAlignment.center,
//     //                               children: [
//     //                                 Icon(Icons.camera),
//     //                                 const SizedBox(
//     //                                   width: 12,
//     //                                 ),
//     //                                 Text(
//     //                                   'Open Camera',
//     //                                   style: getWhiteTextStyle(),
//     //                                 ),
//     //                               ],
//     //                             ),
//     //                             function: (isMarked && isTracking)
//     //                                 ? () async {
//     //                                     final capturedMap =
//     //                                         await scController.capture();

//     //                                     ImagePicker imagePicker = ImagePicker();
//     //                                     final capturedPhoto =
//     //                                         await imagePicker.pickImage(
//     //                                             preferredCameraDevice:
//     //                                                 CameraDevice.rear,
//     //                                             source: ImageSource.camera);

//     //                                     setState(() {
//     //                                       if (capturedPhoto != null) {
//     //                                         listSiteTrack.add(SiteTrack(
//     //                                             mapTrack: capturedMap,
//     //                                             hazardPicture: capturedPhoto,
//     //                                             latitude: latitude,
//     //                                             longitude: longitude,
//     //                                             altitude: altitude));
//     //                                       }
//     //                                     });

//     //                                     print(
//     //                                       'track site $listSiteTrack',
//     //                                     );
//     //                                   }
//     //                                 : null),
//     //                         const SizedBox(
//     //                           height: 12,
//     //                         ),
//     //                         ButtonWidget(
//     //                             name: Row(
//     //                               mainAxisAlignment: MainAxisAlignment.center,
//     //                               children: [
//     //                                 Icon(Icons.location_on),
//     //                                 const SizedBox(
//     //                                   width: 12,
//     //                                 ),
//     //                                 Text(
//     //                                   'Mark Location',
//     //                                   style: getWhiteTextStyle(),
//     //                                 ),
//     //                               ],
//     //                             ),
//     //                             function: (isTracking)
//     //                                 ? () async {
//     //                                     final dataFromCurrentLoc =
//     //                                         await _getCurrentLocation();
//     //                                     _nextCurrentLocation = GeoCoordinates(
//     //                                         dataFromCurrentLoc.latitude,
//     //                                         dataFromCurrentLoc.longitude);
//     //                                     moveMapCamera(
//     //                                         latitude: _nextCurrentLocation
//     //                                                 ?.latitude ??
//     //                                             0,
//     //                                         longitude: _nextCurrentLocation
//     //                                                 ?.longitude ??
//     //                                             0);
//     //                                     addPin(
//     //                                         false,
//     //                                         1,
//     //                                         GeoCoordinates(
//     //                                             _nextCurrentLocation
//     //                                                     ?.latitude ??
//     //                                                 0,
//     //                                             _nextCurrentLocation
//     //                                                     ?.longitude ??
//     //                                                 0));
//     //                                     addRoute(
//     //                                         GeoCoordinates(
//     //                                             _firstCurrentLocation
//     //                                                     ?.latitude ??
//     //                                                 0,
//     //                                             _firstCurrentLocation?.longitude ??
//     //                                                 0),
//     //                                         GeoCoordinates(
//     //                                             _nextCurrentLocation
//     //                                                     ?.latitude ??
//     //                                                 0,
//     //                                             _nextCurrentLocation
//     //                                                     ?.longitude ??
//     //                                                 0));

//     //                                     setState(() {
//     //                                       isMarked = true;
//     //                                       latitude =
//     //                                           _nextCurrentLocation?.latitude ??
//     //                                               0;
//     //                                       longitude =
//     //                                           _nextCurrentLocation?.longitude ??
//     //                                               0;
//     //                                     });
//     //                                   }
//     //                                 : null),
//     //                         const SizedBox(
//     //                           height: 12,
//     //                         ),
//     //                         ButtonWidget(
//     //                             name: Row(
//     //                               mainAxisAlignment: MainAxisAlignment.center,
//     //                               children: [
//     //                                 Icon(Icons.save),
//     //                                 const SizedBox(
//     //                                   width: 12,
//     //                                 ),
//     //                                 Text(
//     //                                   'Save',
//     //                                   style: getWhiteTextStyle(),
//     //                                 ),
//     //                               ],
//     //                             ),
//     //                             function: (listSiteTrack.isNotEmpty)
//     //                                 ? () async {
//     //                                     final capturedEntireMap =
//     //                                         await scController.capture();
//     //                                     Navigator.pushReplacementNamed(
//     //                                       context,
//     //                                       SiteConditionReportPage.routeName,
//     //                                       arguments: {
//     //                                         'listSiteTrack': listSiteTrack,
//     //                                         'capturedEntireMap':
//     //                                             capturedEntireMap
//     //                                       },
//     //                                     );
//     //                                   }
//     //                                 : null)
//     //                       ],
//     //                     ),
//     //                     const SizedBox(
//     //                       height: 24,
//     //                     ),
//     //                     (listSiteTrack.isNotEmpty || listSiteTrack.length != 0)
//     //                         ? Column(
//     //                             crossAxisAlignment: CrossAxisAlignment.stretch,
//     //                             children: [
//     //                               Text(
//     //                                 'Detail Site Location',
//     //                                 textAlign: TextAlign.center,
//     //                                 style: getBlackTextStyle(
//     //                                     fontSize: 20, fontWeight: w700),
//     //                               ),
//     //                               const SizedBox(
//     //                                 height: 24,
//     //                               ),
//     //                               Column(
//     //                                 children: listSiteTrack.map((siteTrack) {
//     //                                   final index =
//     //                                       listSiteTrack.indexOf(siteTrack);
//     //                                   return trackInformation(siteTrack, index);
//     //                                 }).toList(),
//     //                               )
//     //                             ],
//     //                           )
//     //                         : Container(),
//     //                   ],
//     //                 ),
//     //               ],
//     //             ),
//     //           ),
//     //         );
//     //       },
//     //     )),
//     //     Positioned(
//     //       top: 50,
//     //       left: 20,
//     //       child: Container(
//     //         decoration: BoxDecoration(
//     //           color: white,
//     //           borderRadius: BorderRadius.circular(12),
//     //           border: Border.all(color: black),
//     //         ),
//     //         child: IconButton(
//     //             onPressed: () {
//     //               back(context);
//     //             },
//     //             icon: const Icon(
//     //               Icons.arrow_back_ios,
//     //               color: black,
//     //               size: 24,
//     //             )),
//     //       ),
//     //     ),
//     //   ],
//     // ));
//   }

//   Widget trackInformation(SiteTrack siteTrack, int index) {
//     return Column(
//       children: [
//         Card(
//           child: Padding(
//             padding: const EdgeInsets.all(24.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     // Text(
//                     //   'TRACK ${index + 1}',
//                     //   textAlign: TextAlign.center,
//                     //   style: getBlackTextStyle(
//                     //     fontSize: 16,
//                     //     fontWeight: w700,
//                     //   ),
//                     // ),
//                     InputFormWidget(
//                         controller: nameTrackCtrl, hint: 'Masukkan Nama Track'),
//                     const Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 6.0),
//                       child: Divider(
//                         thickness: 1.2,
//                       ),
//                     ),
//                     Text(
//                       'Map Track',
//                       style: getBlackTextStyle(
//                         fontSize: 16,
//                         fontWeight: w700,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Container(
//                       width: double.infinity,
//                       height: 250,
//                       child: Image.memory(siteTrack.mapTrack!),
//                     ),
//                     const SizedBox(
//                       height: 32,
//                     ),
//                     Text(
//                       'Picture of Hazard Location',
//                       style: getBlackTextStyle(
//                         fontSize: 16,
//                         fontWeight: w700,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Container(
//                       width: double.infinity,
//                       height: 200,
//                       child: Image.file(File(siteTrack.hazardPicture!.path)),
//                     ),
//                     const SizedBox(
//                       height: 32,
//                     ),
//                     Text(
//                       'Detail Route Hazard Location',
//                       style: getBlackTextStyle(
//                         fontSize: 16,
//                         fontWeight: w700,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Text(
//                       'Latitude',
//                       style: getBlackTextStyle(fontWeight: w500),
//                     ),
//                     const SizedBox(
//                       height: 6,
//                     ),
//                     Text(
//                       '$latitude',
//                       style: getBlackTextStyle(),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(
//                   height: 12,
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Longitude',
//                       style: getBlackTextStyle(fontWeight: w500),
//                     ),
//                     const SizedBox(
//                       height: 6,
//                     ),
//                     Text(
//                       '$longitude',
//                       style: getBlackTextStyle(),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(
//                   height: 12,
//                 ),
//                 Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Altitude',
//                       style: getBlackTextStyle(fontWeight: w500),
//                     ),
//                     const SizedBox(
//                       height: 6,
//                     ),
//                     Text(
//                       '$altitude',
//                       style: getBlackTextStyle(),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(
//           height: 24,
//         ),
//       ],
//     );
//   }
// }

import 'dart:developer';
import 'dart:io';

import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/site_condition.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/core/widgets/outlined_button_widget.dart';
import 'package:camos/pages/site_condition/site_condition_pdf.dart';
import 'package:camos/pages/site_condition/test_camera.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as p;
import 'package:uuid/uuid.dart';

//////////////////////// TEMPORARY CODE

class SiteConditionPage extends StatefulWidget {
  static const routeName = '/site-condition-page';
  const SiteConditionPage({super.key});

  @override
  State<SiteConditionPage> createState() => _SiteConditionPageState();
}

class _SiteConditionPageState extends State<SiteConditionPage> {
  late Position position;
  List<SiteCondition> listSiteCondition = [];
  List<String> listTmpImg = [];
  CarouselController _carouselController = CarouselController();
  TextEditingController nameCtrl = TextEditingController(text: '');
  TextEditingController remarksCtrl = TextEditingController(text: '');
  bool isConfirmDelete = false;

  Uint8List fileToUint8List(File file) {
    List<int> fileBytes = file.readAsBytesSync();
    Uint8List uint8List = Uint8List.fromList(fileBytes);
    return uint8List;
  }

  void getCurrentLocation() async {
    requestGeolocatorPermission();
    Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      position = currentPosition;
    });
    log('posisi : $position');
  }

  Future<void> showInputDialog(String type,
      {String image: '', SiteCondition? condition}) async {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          switch (type) {
            case 'edit':
              nameCtrl.text = condition!.name;
              remarksCtrl.text = condition.remarks;
              return AlertDialog(
                  // contentPadding: EdgeInsets.zero,
                  content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit),
                        const SizedBox(
                          width: 8,
                        ),
                        Text(
                          'Edit',
                          style:
                              getBlackTextStyle(fontSize: 24, fontWeight: w700),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    Text(
                      'Place Name',
                      style: getBlackTextStyle(),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: InputFormWidget(
                          controller: nameCtrl, hint: 'Place Name'),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      'Remarks',
                      style: getBlackTextStyle(),
                    ),
                    const SizedBox(
                      height: 6,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: InputFormWidget(
                          controller: remarksCtrl, hint: 'Remarks'),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    ButtonWidget(
                        name: Text(
                          'Save',
                          style: getWhiteTextStyle(),
                        ),
                        function: () {
                          for (var i = 0; i < listSiteCondition.length; i++) {
                            log('apakah sama : ${listSiteCondition[i] == condition}');
                            if (listSiteCondition[i] == condition) {
                              listSiteCondition[i].name = nameCtrl.text;
                              listSiteCondition[i].remarks = remarksCtrl.text;
                              log('apakah sama hasilnya : ${listSiteCondition[i]}');
                            }
                          }
                          nameCtrl.clear();
                          remarksCtrl.clear();
                          Navigator.pop(context);
                          setState(() {});
                        }),
                    const SizedBox(
                      height: 12,
                    ),
                    OutlinedButtonWidget(
                        name: Text(
                          'Cancel',
                          style: getBlackTextStyle(),
                        ),
                        function: () {
                          nameCtrl.clear();
                          remarksCtrl.clear();
                          Navigator.pop(context);
                        }),
                    const SizedBox(
                      height: 24,
                    ),
                  ],
                ),
              ));
            case 'add':
              return Scaffold(
                backgroundColor: Colors.transparent,
                body: AlertDialog(
                    contentPadding: EdgeInsets.symmetric(horizontal: 24),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 24,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.edit),
                              const SizedBox(
                                width: 8,
                              ),
                              Text(
                                'Add',
                                style: getBlackTextStyle(
                                    fontSize: 24, fontWeight: w700),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          // Image.file(File(image)),
                          (listTmpImg.isEmpty)
                              ? Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      border: Border.all(color: grey8391A1)),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                                color: grey8391A1,
                                                shape: BoxShape.circle),
                                            child: Icon(
                                              Icons.camera_alt,
                                              color: white,
                                            )),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        Text(
                                          'Click Button to Add Picture!',
                                          textAlign: TextAlign.center,
                                          style: getGreyTextStyle(
                                            grey8391A1,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : SizedBox(
                                  height: 480,
                                  width: 350,
                                  child: CarouselSlider(
                                    carouselController: _carouselController,
                                    items: listTmpImg.map((file) {
                                      log('gambarku : $file');
                                      final indexImg = listTmpImg.indexOf(file);
                                      return Column(
                                        children: [
                                          Image.file(File(file)),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                                onPressed: () {
                                                  if (!isConfirmDelete) {
                                                    setState(() {
                                                      isConfirmDelete = true;
                                                    });
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                            'Press again to delete'),
                                                        duration: Duration(
                                                            seconds: 2),
                                                      ),
                                                    );
                                                    Future.delayed(
                                                        Duration(seconds: 2),
                                                        () {
                                                      setState(() {
                                                        isConfirmDelete = false;
                                                      });
                                                    });
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .hideCurrentSnackBar();
                                                    isConfirmDelete = false;
                                                    listTmpImg
                                                        .removeAt(indexImg);
                                                    Navigator.pop(context);
                                                    showInputDialog('add');
                                                    setState(() {});
                                                  }
                                                },
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.red,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12))),
                                                child: Icon(
                                                  Icons.delete,
                                                  color: white,
                                                )),
                                          )
                                        ],
                                      );
                                    }).toList(),
                                    options: CarouselOptions(
                                      aspectRatio: 0.5,
                                      // height: 300,
                                      enableInfiniteScroll: false,
                                      enlargeCenterPage: true,
                                    ),
                                  ),
                                ),

                          const SizedBox(
                            height: 24,
                          ),
                          ButtonWidget(
                              name: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    'Take Picture',
                                    style: getWhiteTextStyle(),
                                  ),
                                ],
                              ),
                              // function: (listTmpImg.length < 3)
                              //     ? () {
                              //         // requestCameraPermission();
                              //         // takePicture();
                              //         Navigator.pop(context);
                              //         Navigator.push(context,
                              //             MaterialPageRoute(builder: (context) {
                              //           return TestCamera();
                              //         })).then((value) {
                              //           if (value != null) {
                              //             setState(() {
                              //               // listTmpImg.add(value);
                              //               listTmpImg
                              //                   .addAll(value as List<String>);
                              //               showInputDialog('add');
                              //             });
                              //           }
                              //         });
                              //       }
                              //     : null),
                              function: () {
                                // requestCameraPermission();
                                // takePicture();
                                Navigator.pop(context);
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return TestCamera();
                                })).then((value) {
                                  if (value != null) {
                                    setState(() {
                                      // listTmpImg.add(value);
                                      listTmpImg.addAll(value as List<String>);
                                      showInputDialog('add');
                                    });
                                  }
                                });
                              }),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'Place Name',
                            style: getBlackTextStyle(),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: InputFormWidget(
                                controller: nameCtrl, hint: 'Place Name'),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'Remarks',
                            style: getBlackTextStyle(),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: InputFormWidget(
                                controller: remarksCtrl, hint: 'Remarks'),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          ButtonWidget(
                              name: Text(
                                'Save',
                                style: getWhiteTextStyle(),
                              ),
                              function: () {
                                getCurrentLocation();
                                if (listTmpImg.isEmpty) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                            'Please Take Picture First!',
                                            style: getWhiteTextStyle(),
                                          )));

                                  return;
                                }

                                if (listTmpImg.length > 3) {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          backgroundColor: Colors.red,
                                          content: Text(
                                            'Maximum 3 images. Please delete some until there are 3 images remaining.',
                                            style: getWhiteTextStyle(),
                                          )));

                                  return;
                                }

                                List<String> listImage = [];
                                DateTime now = DateTime.now();
                                String formattedDate =
                                    DateFormat('EEEE d MMMM yyyy HH:mm')
                                        .format(now);
                                listImage.addAll(listTmpImg);
                                listSiteCondition.add(SiteCondition(
                                    name: nameCtrl.text,
                                    latitude: position.latitude,
                                    longitude: position.longitude,
                                    remarks: remarksCtrl.text,
                                    date: formattedDate,
                                    image: listImage));
                                log('link gambar  masuk 1: ${listSiteCondition}');
                                // hapus form
                                nameCtrl.clear();
                                remarksCtrl.clear();
                                // hapus daftar gambar sementara
                                listTmpImg.clear();
                                log('link gambar  masuk 2: ${listSiteCondition}');

                                Navigator.pop(context);
                                setState(() {});
                              }),
                          const SizedBox(
                            height: 12,
                          ),
                          OutlinedButtonWidget(
                              name: Text(
                                'Cancel',
                                style: getBlackTextStyle(),
                              ),
                              function: () {
                                listTmpImg.clear();
                                nameCtrl.clear();
                                remarksCtrl.clear();
                                Navigator.pop(context);
                              }),
                          const SizedBox(
                            height: 24,
                          ),
                        ],
                      ),
                    )),
              );
          }
          return Container();
        });
  }

  void takePicture() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(source: ImageSource.camera, imageQuality: 50);

    // if (image != null) {
    //   showInputDialog('add', image: image.path);
    // }

    if (image != null) {
      Navigator.pop(context);
      listTmpImg.add(image.path);
      showInputDialog('add');
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    log('listgambar : $listTmpImg');
    final data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    log('dataku : $data');

    return Scaffold(
      appBar: appBarWidget('Site Condition', context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                (listSiteCondition.isEmpty)
                    ? Text(
                        'There is no data',
                        style: getBlackTextStyle(),
                      )
                    : Column(
                        children: listSiteCondition.map((condition) {
                          log('data condition : $condition');
                          final index = listSiteCondition.indexOf(condition);
                          return Column(
                            children: [
                              // Text(
                              //   '${data['siteName']}',
                              //   style: getBlackTextStyle(
                              //     fontSize: 24,
                              //   ),
                              // ),
                              Card(
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Container(
                                  // height: 260,

                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: white,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // ClipRRect(
                                      //   borderRadius: BorderRadius.circular(24),
                                      //   child: SizedBox(
                                      //     height: 200,
                                      //     width: double.infinity,
                                      //     child: Image.file(
                                      //       File(condition.image[0]),
                                      //       fit: BoxFit.cover,
                                      //     ),
                                      //   ),
                                      // ),
                                      CarouselSlider(
                                        carouselController: _carouselController,
                                        items: condition.image.map((file) {
                                          return Image.file(
                                            File(file),
                                          );
                                        }).toList(),
                                        options: CarouselOptions(
                                          aspectRatio: 3.0,
                                          height: 350,
                                          enableInfiniteScroll: false,
                                          enlargeCenterPage: true,
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Point ${index + 1}',
                                                      style: getBlackTextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 4,
                                                    ),
                                                    Text(
                                                      condition.name,
                                                      style: getBlackTextStyle(
                                                          fontWeight: w700),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 50,
                                                  width: 50,
                                                  child: ButtonWidget(
                                                      name: Icon(
                                                        Icons.edit,
                                                        size: 16,
                                                      ),
                                                      function: () {
                                                        showInputDialog('edit',
                                                            condition:
                                                                condition);
                                                      }),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 12,
                                            ),
                                            Row(
                                              children: [
                                                Icon(Icons.access_time),
                                                const SizedBox(
                                                  width: 6,
                                                ),
                                                Text(
                                                  '${condition.date}',
                                                  style: getBlackTextStyle(
                                                      fontSize: 12),
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
                                                  style: getBlackTextStyle(
                                                      fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            Divider(),
                                            Text(
                                              'Remarks',
                                              style: getBlackTextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 6,
                                            ),
                                            Text(
                                              condition.remarks,
                                              style: getBlackTextStyle(
                                                fontWeight: w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: (index != listSiteCondition.length - 1)
                                    ? 12
                                    : 0,
                              )
                            ],
                          );
                        }).toList(),
                      ),
                const SizedBox(
                  height: 24,
                ),
                ButtonWidget(
                    name: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          'Add Data',
                          style: getWhiteTextStyle(),
                        ),
                      ],
                    ),
                    function: () {
                      // takePicture();
                      showInputDialog('add');
                    }),
                const SizedBox(
                  height: 12,
                ),
                ButtonWidget(
                  name: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        'Save',
                        style: getWhiteTextStyle(),
                      ),
                    ],
                  ),
                  function: (listSiteCondition.isNotEmpty)
                      ? () async {
                          log('daftar site condition : ${listSiteCondition}');
                          final pdf = p.Document();
                          final logoCp = (await rootBundle
                                  .load('${imagePath}/cp_logo_image.png'))
                              .buffer
                              .asUint8List();
                          // pdf.addPage(p.MultiPage(build: (p.Context context) {
                          //   return [
                          //     p.Column(
                          //         children: listSiteCondition.map((e) {
                          //       return p.Column(
                          //           children: e.image.map((im) {
                          //         return p.Container(
                          //           width: double.infinity,
                          //           height: double.infinity,
                          //           child: p.Image(
                          //               fit: p.BoxFit.fill,
                          //               p.MemoryImage(
                          //                 fileToUint8List(File(im)),
                          //               )),
                          //         );
                          //       }).toList());
                          //     }).toList())
                          //   ];
                          // }));

                          // pdf.addPage(p.Page(
                          //   build: (p.Context context) {
                          //     return p.Container(
                          //       width: double.infinity,
                          //       height: double.infinity,
                          //       child: p.Image(
                          //           fit: p.BoxFit.fill,
                          //           p.MemoryImage(
                          //             fileToUint8List(
                          //                 File(listSiteCondition[0].image[0])),
                          //           )),
                          //     );
                          //   },
                          // ));

                          pdf.addPage(p.MultiPage(
                              pageFormat: PdfPageFormat.a4,
                              build: (p.Context context) {
                                return [
                                  p.Column(
                                    children: listSiteCondition.map((c) {
                                      final index =
                                          listSiteCondition.indexOf(c);
                                      return p.Column(
                                          crossAxisAlignment:
                                              p.CrossAxisAlignment.start,
                                          children: [
                                            p.SizedBox(
                                              width: 150,
                                              height: 100,
                                              child: p.Image(
                                                  p.MemoryImage(logoCp)),
                                            ),
                                            p.SizedBox(
                                              height: 24,
                                            ),
                                            // p.Text(
                                            //   '${data['siteName']}',
                                            //   style: p.TextStyle(
                                            //     fontSize: 24,
                                            //     fontWeight: p.FontWeight.bold,
                                            //   ),
                                            // ),
                                            // p.SizedBox(
                                            //   height: 24,
                                            // ),
                                            p.Text(
                                              'Location Point  ${index + 1}',
                                              style: p.TextStyle(
                                                fontSize: 24,
                                              ),
                                            ),
                                            p.Text(
                                              c.name,
                                              style: p.TextStyle(
                                                fontSize: 48,
                                                fontWeight: p.FontWeight.bold,
                                              ),
                                            ),
                                            p.SizedBox(
                                              height: 12,
                                            ),
                                            p.Wrap(
                                              spacing: 7,
                                              children:
                                                  c.image.map<p.Widget>((img) {
                                                return p.SizedBox(
                                                    height: 200,
                                                    child: p.Image(
                                                        p.MemoryImage(
                                                            fileToUint8List(
                                                                File(img)))));
                                              }).toList(),
                                            ),
                                            p.SizedBox(
                                              height: 12,
                                            ),
                                            p.Divider(),
                                            p.Row(
                                              children: [
                                                // p.Icon(Icons.access_time),
                                                p.Text(
                                                  'Time : ',
                                                  style: p.TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                p.SizedBox(
                                                  width: 6,
                                                ),
                                                p.Text(
                                                  '${c.date}',
                                                  style: p.TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                  // style: getBlackTextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            p.SizedBox(
                                              height: 12,
                                            ),
                                            p.Row(
                                              children: [
                                                // Icon(Icons.location_pin),
                                                p.Text(
                                                  'Coordinate Location : ',
                                                  style: p.TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                p.SizedBox(
                                                  width: 6,
                                                ),
                                                p.Text(
                                                  '${c.latitude}, ${c.longitude}',
                                                  style: p.TextStyle(
                                                    fontSize: 18,
                                                  ),
                                                  // style: getBlackTextStyle(fontSize: 12),
                                                ),
                                              ],
                                            ),
                                            p.Divider(),
                                            p.Text(
                                              'Remarks',
                                              style: p.TextStyle(
                                                fontSize: 18,
                                              ),
                                              // style: getBlackTextStyle(
                                              //   fontWeight: w700,
                                              // ),
                                            ),
                                            p.Text(
                                              c.remarks,
                                              style: p.TextStyle(
                                                fontSize: 18,
                                                fontWeight: p.FontWeight.bold,
                                              ),
                                            ),
                                            (index !=
                                                    listSiteCondition.length -
                                                        1)
                                                ? p.Padding(
                                                    padding:
                                                        p.EdgeInsets.symmetric(
                                                            vertical: 12.0),
                                                    child: p.Divider(),
                                                  )
                                                : p.SizedBox(
                                                    height: 0,
                                                  ),
                                          ]);
                                    }).toList(),
                                  )
                                ];
                              }));

                          final id = Uuid();
                          final outputFile =
                              await createFolderPath('${id.v4()}', 'site');
                          final filePath = await savePdf(pdf, outputFile);

                          log('save baru : $filePath');

                          if (filePath != null || filePath != '') {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                backgroundColor: green00968A,
                                content: Text(
                                  'Successfull Save Data!',
                                  style: getWhiteTextStyle(),
                                )));
                          }
                        }
                      : null,
                ),
                // ButtonWidget(
                //     name: Text('name'),
                //     function: () {
                //       Navigator.push(context,
                //           MaterialPageRoute(builder: (context) {
                //         return TestCamera();
                //       }));
                //     })
                // ButtonWidget(
                //     name: Row(
                //       mainAxisAlignment: MainAxisAlignment.center,
                //       children: [
                //         Icon(Icons.table_chart),
                //         const SizedBox(
                //           width: 12,
                //         ),
                //         Text(
                //           'Create Report',
                //           style: getWhiteTextStyle(),
                //         ),
                //       ],
                //     ),
                //     function: (listSiteCondition.isEmpty)
                //         ? null
                //         : () {
                //             Navigator.pushNamed(
                //                 context, SiteConditionPDF.routeName,
                //                 arguments: {
                //                   'listSiteCondition': listSiteCondition,
                //                   'siteName': data['siteName']
                //                 });
                //           }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
