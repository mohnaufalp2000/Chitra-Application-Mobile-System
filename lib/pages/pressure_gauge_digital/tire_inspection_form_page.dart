// import 'dart:developer';
// import 'dart:io';

// import 'package:app_settings/app_settings.dart';
// import 'package:camos/core/blocs/outstanding_task/outstanding_task_bloc.dart';
// import 'package:camos/core/blocs/tire/tire_bloc.dart';
// import 'package:camos/core/blocs/unit/unit_bloc.dart';
// import 'package:camos/core/navigator/navigation_route.dart';
// import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
// import 'package:camos/core/services/model/outstanding_task.dart';
// import 'package:camos/core/services/model/unit_tire.dart';
// import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
// import 'package:camos/core/styles/asset_path.dart';
// import 'package:camos/core/styles/color.dart';
// import 'package:camos/core/styles/text_manager.dart';
// import 'package:camos/core/utils/data/oustanding_task.dart';
// import 'package:camos/core/utils/data/pgd.dart';
// import 'package:camos/core/utils/functions/functions.dart';
// import 'package:camos/core/widgets/appbar_widget.dart';
// import 'package:camos/core/widgets/button_widget.dart';
// import 'package:camos/core/widgets/input_form_widget.dart';
// import 'package:camos/core/widgets/pgd_tire_card_widget.dart';
// import 'package:camos/main.dart';
// import 'package:camos/objectbox.g.dart';
// import 'package:camos/pages/home/home_page.dart';
// import 'package:card_swiper/card_swiper.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';

// class TireInspectionFormPage extends StatefulWidget {
//   static const routeName = '/pgd-page';
//   const TireInspectionFormPage({super.key});

//   @override
//   State<TireInspectionFormPage> createState() => _TireInspectionFormPageState();
// }

// class _TireInspectionFormPageState extends State<TireInspectionFormPage> with WidgetsBindingObserver {
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth auth = FirebaseAuth.instance;

//   var map = {};
//   String idSite = '';
//   bool isSaved = false;
//   Map<String, dynamic> dataUnit = {};

//   final Box<OutstandingTaskEntity> box = store.box<OutstandingTaskEntity>();

//   TextEditingController idUnit = TextEditingController(text: '');
//   TextEditingController hmUnit = TextEditingController(text: '');
//   TextEditingController pressureCtrl = TextEditingController(text: '');
//   TextEditingController remarksCtrl = TextEditingController(text: '');
//   SwiperController swiperController = SwiperController();

//   String selectedUnit = '';
//   List<String> checkedCategories = [];
//   String selectedTireDamage = '';
//   String remarks = '';
//   String rtd = '';
//   List<File> listImg = [];

//   List<String> categories = [
//     'Reseal Oring',
//     'Rim Condition',
//     'Inflate Tire',
//     'Lock Driver',
//     'Slide Lock',
//     'Valve Cap',
//     'Valve Protector',
//     'Stud and Nut',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     requestPlacePermission();

//     callTires();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   BluetoothConnection? connection;
//   bool get isConnected => connection != null && connection!.isConnected;

//   List<BluetoothDevice> devices = [];
//   bool isDiscovering = false;
//   String tmpPressure = '';

//   void _listenForData() {
//     connection!.input!.listen((data) {
//       String receivedData = String.fromCharCodes(data).trim();
//       String onlyNumber =
//           '${double.parse(receivedData.replaceAll(RegExp(r'[^\d.-]+'), ''))}';
//       print(
//           'Received data: ${double.parse(receivedData.replaceAll(RegExp(r'[^\d.-]+'), ''))}');

//       setState(() {
//         pressureCtrl.text = onlyNumber;
//         print('tekananangin : ${pressureCtrl.text}');
//       });
//     });
//   }

//   void connectedDevice(BluetoothDevice device) async {
//     if (isConnected) {
//       await connection!.close();
//     }

//     try {
//       connection = await BluetoothConnection.toAddress(device.address);
//       print('Connected to the device');
//       _listenForData();
//       // pressureGaugeLooping();
//       setState(() {});
//     } catch (e) {
//       print('Cannot connect to the device: $e');
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     super.didChangeAppLifecycleState(state);
//     if (state == AppLifecycleState.resumed) {
//       // Perbarui daftar perangkat terhubung
//       updateConnectedDevices();
//     }
//   }

//   void updateConnectedDevices() async {
//     // Ambil daftar perangkat terhubung dan perbarui state
//     await FlutterBluetoothSerial.instance.getBondedDevices();
//     setState(() {});
//   }

//   Stream<List<BluetoothDevice>> getConnectedDevices() {
//     return FlutterBluetoothSerial.instance.getBondedDevices().asStream();
//   }

//   void handleDataChecked(List<bool> checkedList, int index) {
//     checkedCategories.clear();

//     for (int i = 0; i < checkedList.length; i++) {
//       if (checkedList[i] == true) {
//         // setState(() {
//         checkedCategories.add(categories[i]);
//         // });
//       }
//     }

//     // Cetak hasil untuk tujuan pengujian
//   }

//   void handleDataSelected(String tireDamage, int index) {
//     // Perbarui data tire damage
//     selectedTireDamage = tireDamage;
//   }

//   void handleImageTire(List<File> images) {
//     listImg.clear();
//     listImg.addAll(images);
//   }

//   void callTires() async {
//     idSite = await getIdSitePreferences();
//     if (idSite == '1') {
//       idSite = await getSelectedIdSitePreferences();
//     }
//     if (mounted) {
//       if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
//         idUnit.text = dataUnit['unitNumber'];
//         hmUnit.text = dataUnit['hm'];
//         context.read<TireBloc>().add(GetUnitTiresEvent(
//             idSite: idSite, unitNumber: dataUnit['unitNumber']));
//       }
//     }
//   }

//   void handleDataRemarks(String remarks, int index) {
//     this.remarks = remarks;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   void handleDataRTD(String rtd, int index) {
//     this.rtd = rtd;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   @override
//   Widget build(BuildContext context) {
//     print('dipanggil (pgd)');
//     dataUnit =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

//     return WillPopScope(
//       onWillPop: () async {
//         if (isSaved) {
//           pushReplace(context, HomePage.routeName);
//         } else {
//           back(context);
//         }
//         return false;
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           title: Padding(
//             padding: const EdgeInsets.only(top: 18.0),
//             child: Text(
//               'Pressure Gauge Digital',
//               textAlign: TextAlign.center,
//               style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
//             ),
//           ),
//           centerTitle: true,
//           leading: Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Container(
//               margin: const EdgeInsets.only(top: 14),
//               padding: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 color: white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: black),
//               ),
//               child: IconButton(
//                   onPressed: () {
//                     if (isSaved) {
//                       pushReplace(context, HomePage.routeName);
//                     } else {
//                       back(context);
//                     }
//                   },
//                   icon: const Icon(
//                     Icons.arrow_back_ios,
//                     color: black,
//                     size: 24,
//                   )),
//             ),
//           ),
//         ),
//         body: SafeArea(child: BlocBuilder<TireBloc, TireState>(
//           builder: (context, state) {
//             return SingleChildScrollView(
//               primary: false,
//               physics: BouncingScrollPhysics(),
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               Text(
//                                 'Unit Number',
//                                 style: getBlackTextStyle(fontWeight: w700),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                     isReadOnly: true,
//                                     controller: idUnit,
//                                     hint: ''),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               Text(
//                                 'HM Unit',
//                                 style: getBlackTextStyle(fontWeight: w700),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                     isReadOnly: true,
//                                     controller: hmUnit,
//                                     hint: 'Insert HM Unit'),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(
//                           width: 12,
//                         ),
//                         // SizedBox(
//                         //   height: 200,
//                         //   width: 100,
//                         //   child: ButtonWidget(
//                         //       name: Row(
//                         //         mainAxisAlignment: MainAxisAlignment.center,
//                         //         children: [
//                         //           Icon(Icons.restore),
//                         //           const SizedBox(
//                         //             width: 6,
//                         //           ),
//                         //           Text(
//                         //             'Reset',
//                         //             style: getWhiteTextStyle(),
//                         //           ),
//                         //         ],
//                         //       ),
//                         //       function: () {
//                         //         idUnit.clear();
//                         //         hmUnit.clear();
//                         //         setState(() {});
//                         //       }),
//                         // ),
//                       ],
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 12.0),
//                       child: Divider(
//                         thickness: 1.2,
//                       ),
//                     ),
//                     Text(
//                       'Bluetooth Connection',
//                       style: getBlackTextStyle(
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     ButtonWidget(
//                         name: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.bluetooth),
//                             const SizedBox(
//                               width: 6,
//                             ),
//                             Text(
//                               'Scan Devices',
//                               style: getWhiteTextStyle(),
//                             ),
//                           ],
//                         ),
//                         function: () async {
//                           requestBluetoothPermission();
//                           devices.clear();
//                           isDiscovering = true;
//                           FlutterBluetoothSerial.instance
//                               .startDiscovery()
//                               .listen((device) {
//                             if (!devices.contains(device.device)) {
//                               log(device.device.toString());
//                               setState(() {
//                                 devices.add(device.device);
//                               });
//                             }
//                           }, onDone: () {
//                             isDiscovering = false;
//                             setState(() {});
//                           });
//                           // AppSettings.openBluetoothSettings();
//                         }),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Column(
//                       children: devices.map((device) {
//                         return ListTile(
//                           title: Text(
//                             device.name ?? 'Uknown Device',
//                             style: getBlackTextStyle(),
//                           ),
//                           subtitle: Text(
//                             device.address,
//                             style: getGreyTextStyle(grey6A707C),
//                           ),
//                           trailing: SizedBox(
//                               width: 110,
//                               height: 50,
//                               child: ButtonWidget(
//                                   name: Text(
//                                     (isConnected) ? 'Disconnect' : 'Connect',
//                                     style: getWhiteTextStyle(),
//                                   ),
//                                   function: () async {
//                                     if (isConnected) {
//                                       await connection!.close();
//                                       devices.clear();
//                                       setState(() {});
//                                     } else {
//                                       try {
//                                         connection =
//                                             await BluetoothConnection.toAddress(
//                                                 device.address);
//                                         print('Connected to the device');
//                                         _listenForData();
//                                         devices.clear();
//                                         devices.add(device);
//                                         setState(() {});
//                                       } catch (e) {
//                                         print(
//                                             'Cannot connect to the device: $e');
//                                       }
//                                     }
//                                   })),
//                         );
//                       }).toList(),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Text(
//                       'Pressure',
//                       style: getBlackTextStyle(),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Column(
//                       children: [
//                         SizedBox(
//                           width: MediaQuery.of(context).size.width * 0.25,
//                           child: InputFormWidget(
//                             isDecimalOnly: true,
//                             type: const TextInputType.numberWithOptions(
//                                 decimal: true),
//                             controller: pressureCtrl,
//                             hint: '',
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 12,
//                         ),
//                       ],
//                     ),
//                     // (tmpPressure == '')
//                     //     ? Container()
//                     //     : Column(
//                     //         children: [
//                     //           SizedBox(
//                     //             width: MediaQuery.of(context).size.width * 0.25,
//                     //             child: InputFormWidget(
//                     //               isReadOnly: true,
//                     //               controller:
//                     //                   TextEditingController(text: tmpPressure),
//                     //               hint: '',
//                     //             ),
//                     //           ),
//                     //           const SizedBox(
//                     //             height: 12,
//                     //           ),
//                     //         ],
//                     //       ),
//                     // TIRE
//                     BlocBuilder<TireBloc, TireState>(
//                       builder: (context, state) {
//                         if (state is TireLoadingState) {
//                           return CircularProgressIndicator();
//                         }

//                         if (state is TiresLoadedState) {
//                           return LayoutBuilder(builder: (context, constraints) {
//                             return Container(
//                               height: constraints.maxWidth * 3.4,
//                               child: Swiper(
//                                 controller: swiperController,
//                                 loop: false,
//                                 physics: NeverScrollableScrollPhysics(),
//                                 scrollDirection: Axis.horizontal,
//                                 itemCount: state.units.length,
//                                 itemBuilder: (context, index) {
//                                   return PgdTireCardWidget(
//                                     dataTire: state.units[index],
//                                     onCategoryChecked: (checkedList) {
//                                       handleDataChecked(checkedList, index);
//                                     },
//                                     onSelectedTireDamage: (tireDamage) {
//                                       handleDataSelected(tireDamage, index);
//                                     },
//                                     onStringRemarks: (remarks) {
//                                       handleDataRemarks(remarks, index);
//                                     },
//                                     onStringRTD: (rtd) {
//                                       handleDataRTD(rtd, index);
//                                     },
//                                     onImageTire: (images) {
//                                       handleImageTire(images);
//                                     },
//                                   );
//                                 },
//                               ),
//                             );
//                           });
//                         }
//                         return Container();
//                       },
//                     ),

//                     const SizedBox(
//                       height: 12,
//                     ),

//                     BlocBuilder<TireBloc, TireState>(
//                       builder: (context, state) {
//                         if (state is TireLoadingState) {}

//                         if (state is TiresLoadedState) {
//                           return Row(
//                             children: [
//                               Expanded(
//                                 child: ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.arrow_left),
//                                       const SizedBox(width: 6),
//                                       Text(
//                                         'Previous',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                     ],
//                                   ),
//                                   function: () {
//                                     if (swiperController.index > 0) {
//                                       swiperController.index--;
//                                       swiperController.previous();
//                                     }
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         'Next',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Icon(Icons.arrow_right),
//                                     ],
//                                   ),
//                                   function: () {
//                                     if (swiperController.index <
//                                         state.units.length - 1) {
//                                       swiperController.index++;
//                                       swiperController.next();
//                                     }
//                                   },
//                                 ),
//                               ),
//                             ],
//                           );
//                         }

//                         return Container();
//                       },
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     BlocBuilder<TireBloc, TireState>(
//                       builder: (context, state) {
//                         if (state is TiresLoadedState) {
//                           final tire = state.units;
//                           return ButtonWidget(
//                               name: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.save_alt),
//                                   const SizedBox(
//                                     width: 6,
//                                   ),
//                                   Text(
//                                     'Save',
//                                     style: getWhiteTextStyle(),
//                                   ),
//                                 ],
//                               ),
//                               function: () {
//                                 final id = Uuid();
//                                 isSaved = true;
//                                 final savedTires =
//                                     state.units[swiperController.index];

//                                 // Disimpan di objectbox
//                                 context.read<OutstandingTaskBloc>().add(
//                                     AddOutStandingTaskEvent(
//                                         task: OutstandingTask(
//                                             id: id.v4(),
//                                             idSite: idSite,
//                                             user: auth.currentUser!.email ?? '',
//                                             unit: idUnit.text,
//                                             position: int.parse(
//                                                 savedTires.posisi ?? '0'),
//                                             brand: savedTires.brand ?? '',
//                                             serialNumber:
//                                                 savedTires.unitNumber ?? '',
//                                             tireSize: savedTires.size ?? '',
//                                             condition: checkedCategories
//                                                 .map((category) => category)
//                                                 .toList(),
//                                             tireDamage: selectedTireDamage,
//                                             remarks: remarks,
//                                             rtd: rtd,
//                                             pressure: pressureCtrl.text,
//                                             lastUpdate: DateTime.now()
//                                                 .toIso8601String(),
//                                             isDone: false,
//                                             sn: savedTires.sn ?? '',
//                                             images: listImg)));

//                                 // for (var outStandingTask in box.getAll()) {
//                                 //   log(box.getAll().length.toString());
//                                 //   log('data outstanding (object box) ${outStandingTask.id}');
//                                 // }

//                                 ScaffoldMessenger.of(context)
//                                     .showSnackBar(SnackBar(
//                                         backgroundColor: green00968A,
//                                         content: Text(
//                                           'Succesful Save Data',
//                                           style: getWhiteTextStyle(),
//                                         )));
//                               });
//                         }
//                         return Container();
//                       },
//                     ),
//                     // const SizedBox(
//                     //   height: 12,
//                     // ),
//                     // ButtonWidget(
//                     //     name: Row(
//                     //       mainAxisAlignment: MainAxisAlignment.center,
//                     //       children: [
//                     //         Icon(Icons.send),
//                     //         const SizedBox(
//                     //           width: 6,
//                     //         ),
//                     //         Text(
//                     //           'Send',
//                     //           style: getWhiteTextStyle(),
//                     //         ),
//                     //       ],
//                     //     ),
//                     //     function: () async {
//                     //       // await _notificationHelper
//                     //       //     .showNotification(flutterLocalNotificationsPlugin);
//                     //     }),
//                     const SizedBox(
//                       height: 12,
//                     ),

//                     // Row(
//                     //   children: [
//                     //     Expanded(
//                     //       child: ButtonWidget(
//                     //           name: Row(
//                     //             mainAxisAlignment: MainAxisAlignment.center,
//                     //             children: [
//                     //               Icon(Icons.arrow_left),
//                     //               Text(
//                     //                 'Previous',
//                     //                 style: getWhiteTextStyle(),
//                     //               ),
//                     //             ],
//                     //           ),
//                     //           function: () {
//                     //             setState(() {
//                     //               if (tireIndex > 1) {
//                     //                 tireIndex--;
//                     //               }
//                     //             });
//                     //           }),
//                     //     ),
//                     //     const SizedBox(
//                     //       width: 12,
//                     //     ),
//                     //     Expanded(
//                     //       child: ButtonWidget(
//                     //           name: Row(
//                     //             mainAxisAlignment: MainAxisAlignment.center,
//                     //             children: [
//                     //               Text(
//                     //                 'Next',
//                     //                 style: getWhiteTextStyle(),
//                     //               ),
//                     //               Icon(Icons.arrow_right),
//                     //             ],
//                     //           ),
//                     //           function: () {
//                     //             setState(() {
//                     //               tireIndex++;
//                     //             });
//                     //           }),
//                     //     ),
//                     //   ],
//                     // ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         )),
//       ),
//     );
//   }
// }

////// FLUTTER SERIAL BLUETOOTH 1 (YG DIPAKE)

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_settings/app_settings.dart';
import 'package:camos/core/blocs/outstanding_task/outstanding_task_bloc.dart';
import 'package:camos/core/blocs/tire/tire_bloc.dart';
import 'package:camos/core/blocs/unit/unit_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
import 'package:camos/core/services/local_database/tire_inspect_picture/tire_inspect_picture_entity.dart';
import 'package:camos/core/services/model/outstanding_task.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/oustanding_task.dart';
import 'package:camos/core/utils/data/pgd.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/core/widgets/pgd_tire_card_widget.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class TireInspectionFormPage extends StatefulWidget {
  static const routeName = '/pgd-page';
  const TireInspectionFormPage({super.key});

  @override
  State<TireInspectionFormPage> createState() => _TireInspectionFormPageState();
}

class _TireInspectionFormPageState extends State<TireInspectionFormPage>
    with WidgetsBindingObserver {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  int selectedMenu = 1;
  var map = {};
  String idSite = '';
  bool isSaved = false;
  Map<String, dynamic> dataUnit = {};

  final Box<OutstandingTaskEntity> box = store.box<OutstandingTaskEntity>();

  TextEditingController idUnit = TextEditingController(text: '');
  TextEditingController hmUnit = TextEditingController(text: '');
  TextEditingController pressureCtrl = TextEditingController(text: '');
  TextEditingController remarksCtrl = TextEditingController(text: '');
  TextEditingController damageCtrl = TextEditingController(text: '');
  TextEditingController rtd1 = TextEditingController(text: '');
  TextEditingController rtd2 = TextEditingController(text: '');
  List<TextEditingController> remarksControllers = [];
  List<TextEditingController> rtd1Controllers = [];
  List<TextEditingController> rtd2Controllers = [];

  SwiperController swiperController = SwiperController();

  String selectedUnit = '';
  List<String> checkedCategories = [];
  List<Map<String, dynamic>> checkedCategoriesManual = [
    {'name': 'Reseal Oring', 'checked': false},
    {'name': 'Rim Condition', 'checked': false},
    {'name': 'Inflate Tire', 'checked': false},
    {'name': 'Lock Driver', 'checked': false},
    {'name': 'Slide Lock', 'checked': false},
    {'name': 'Valve Cap', 'checked': false},
    {'name': 'Valve Protector', 'checked': false},
    {'name': 'Stud and Nut', 'checked': false},
  ];

  List<bool> checkedListCategory = List<bool>.filled(8, false);
  String selectedTireDamage = '';
  String remarks = '';
  String rtd = '';
  List<String> listImg = [];
  Map<String, dynamic> user = {};

  List<String> pressure = [
    '95',
    '100',
    '105',
    '110',
    '115',
    '120',
    '125',
    '130',
    '135',
  ];
  List<Map<String, dynamic>> position = [];

  List<String> damageType = [
    'Good Condition (Keep Monitoring)',
    'Accident',
    'Bead Crack',
    'Boulder',
    'Bulging',
    'Bead Damage',
    'Chaffer Separation',
    'Dog Bound',
    'Foreign Object',
    'Heat Separation',
    'Inner Linner Separation',
    'Impact',
    'Repair Failure',
    'Radial Crack',
    'Run Flat',
    'Sidewall Crack',
    'Sidewall Cut',
    'Sidewall Cut 2',
    'Sidewall Cut 3',
    'Sidewall Separation',
    'Shoulder Cut',
    'Shoulder Separation',
    'Tread Chipping',
    'Tread Chungking',
    'Tread Lifting',
    'Tread Cut',
    'Tread Cut Separation',
    'Worn Out',
  ];

  List<String> selectedDamage = [];

  List<String> categories = [
    'Reseal Oring',
    'Rim Condition',
    'Inflate Tire',
    'Lock Driver',
    'Slide Lock',
    'Valve Cap',
    'Valve Protector',
    'Stud and Nut',
  ];

  @override
  void initState() {
    super.initState();
    requestPlacePermission();

    callTires();
    WidgetsBinding.instance.addObserver(this);
    getUser();
  }

  getUser() async {
    user = await getUserPreferences();
    log('username : ${user}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  bool get isConnected => connection != null && connection!.isConnected;

  List<BluetoothDevice> devices = [];
  String tmpPressure = '';
  final Box<TireInspectPictureEntity> imageBox =
      store.box<TireInspectPictureEntity>();

  startScanBluetooth() async {
    bluetoothSerial.startDiscovery().listen((device) {
      if (!devices.contains(device.device)) {
        log('device yg tersedia ' + device.device.toString());
        setState(() {
          devices.add(device.device);
        });
      }
    }, onDone: () {
      setState(() {});
    });
  }

  stopScanBluetooth() async {
    bluetoothSerial.cancelDiscovery();
  }

  // mendapatkan nilai pressure
  void _listenForData() {
    connection!.input!.listen((data) {
      String receivedData = String.fromCharCodes(data).trim();
      log('data json : $receivedData');
      String onlyNumber =
          '${double.parse(receivedData.replaceAll(RegExp(r'[^\d.-]+'), ''))}';
      print(
          'Received data: ${double.parse(receivedData.replaceAll(RegExp(r'[^\d.-]+'), ''))}');

      setState(() {
        pressureCtrl.text = onlyNumber;
        print('tekananangin : ${pressureCtrl.text}');
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Perbarui daftar perangkat terhubung
      updateConnectedDevices();
    }
  }

  void updateConnectedDevices() async {
    // Ambil daftar perangkat terhubung dan perbarui state
    await FlutterBluetoothSerial.instance.getBondedDevices();
    setState(() {});
  }

  Stream<List<BluetoothDevice>> getConnectedDevices() {
    return FlutterBluetoothSerial.instance.getBondedDevices().asStream();
  }

  void handleDataChecked(List<bool> checkedList, int index) {
    checkedCategories.clear();

    for (int i = 0; i < checkedList.length; i++) {
      if (checkedList[i] == true) {
        // setState(() {
        checkedCategories.add(categories[i]);
        // });
      }
    }

    // Cetak hasil untuk tujuan pengujian
  }

  void handleDataSelected(String tireDamage, int index) {
    // Perbarui data tire damage
    selectedTireDamage = tireDamage;
  }

  void handleImageTire(List<String> images) {
    listImg.clear();
    listImg.addAll(images);
  }

  void callTires() async {
    idSite = await getIdSitePreferences();
    if (idSite == '1') {
      idSite = await getSelectedIdSitePreferences();
    }
    if (mounted) {
      if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
        idUnit.text = dataUnit['unitNumber'];
        // hmUnit.text = dataUnit['hm'];
        context.read<TireBloc>().add(GetUnitTiresEvent(
            idSite: idSite, unitNumber: dataUnit['unitNumber']));
      }
    }
  }

  void handleDataRemarks(String remarks, int index) {
    this.remarks = remarks;
    print('remarks (pgd) : ${this.remarks}');
  }

  void handleDataRTD(String rtd, int index) {
    this.rtd = rtd;
    print('remarks (pgd) : ${this.remarks}');
  }

  @override
  Widget build(BuildContext context) {
    print('dipanggil (pgd)');
    dataUnit =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    return WillPopScope(
      onWillPop: () async {
        if (isSaved) {
          connection!.close();
          stopScanBluetooth();
          pushReplace(context, HomePage.routeName);
        } else {
          connection!.close();
          stopScanBluetooth();
          back(context);
        }
        return false;
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Text(
              (selectedMenu == 0)
                  ? 'PG Digital Tire Inspection'
                  : 'Tire Inspection',
              textAlign: TextAlign.center,
              style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
            ),
          ),
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Container(
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: black),
              ),
              child: IconButton(
                  onPressed: () {
                    if (isSaved) {
                      if (connection != null) {
                        connection?.close();
                      }
                      stopScanBluetooth();
                      pushReplace(context, HomePage.routeName);
                    } else {
                      if (connection != null) {
                        connection?.close();
                      }
                      stopScanBluetooth();
                      back(context);
                    }
                  },
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: black,
                    size: 24,
                  )),
            ),
          ),
        ),
        body: SafeArea(
            child: BlocConsumer<TireBloc, TireState>(
          listener: (context, state) {
            if (state is TiresLoadedState) {
              position.clear();

              for (int i = 0; i < state.units.length; i++) {
                remarksControllers.add(TextEditingController(text: ''));
                rtd1Controllers.add(TextEditingController(text: ''));
                rtd2Controllers.add(TextEditingController(text: ''));
                position.add({
                  'position': i + 1,
                  'pressure': '',
                  'adjusmentPressure': '',
                  'hm': hmUnit.text,
                  'damageTire': [],
                  'rtd1': '',
                  'rtd2': '',
                  'remarks': '',
                  'condition': [
                    {'name': 'Reseal Oring', 'checked': false},
                    {'name': 'Rim Condition', 'checked': false},
                    {'name': 'Inflate Tire', 'checked': false},
                    {'name': 'Lock Driver', 'checked': false},
                    {'name': 'Slide Lock', 'checked': false},
                    {'name': 'Valve Cap', 'checked': false},
                    {'name': 'Valve Protector', 'checked': false},
                    {'name': 'Stud and Nut', 'checked': false},
                  ],
                });
              }
              log('message position tire inspect : ${position}');
            }
          },
          builder: (context, state) {
            if (selectedMenu == 0) {
              return SingleChildScrollView(
                primary: false,
                physics: BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Unit Number',
                                  style: getBlackTextStyle(fontWeight: w700),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: InputFormWidget(
                                      isReadOnly: true,
                                      controller: idUnit,
                                      hint: ''),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Text(
                                  'HM Unit',
                                  style: getBlackTextStyle(fontWeight: w700),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                SizedBox(
                                  width: double.infinity,
                                  child: InputFormWidget(
                                      controller: hmUnit,
                                      hint: 'Insert HM Unit'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Divider(
                          thickness: 1.2,
                        ),
                      ),
                      Text(
                        'Bluetooth Connection',
                        style: getBlackTextStyle(
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      ButtonWidget(
                          name: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.bluetooth),
                              const SizedBox(
                                width: 6,
                              ),
                              Text(
                                'Scan Devices',
                                style: getWhiteTextStyle(),
                              ),
                            ],
                          ),
                          function: () async {
                            requestBluetoothPermission();
                            startScanBluetooth();
                            devices.clear();
                            // AppSettings.openBluetoothSettings();
                          }),
                      const SizedBox(
                        height: 12,
                      ),
                      Column(
                        children: devices.map((device) {
                          return ListTile(
                            title: Text(
                              device.name ?? 'Uknown Device',
                              style: getBlackTextStyle(),
                            ),
                            subtitle: Text(
                              device.address,
                              style: getGreyTextStyle(grey6A707C),
                            ),
                            trailing: SizedBox(
                                width: 110,
                                height: 50,
                                child: ButtonWidget(
                                    name: Text(
                                      (isConnected) ? 'Disconnect' : 'Connect',
                                      style: getWhiteTextStyle(),
                                    ),
                                    function: () async {
                                      if (isConnected) {
                                        await connection!.close();
                                        devices.clear();
                                        setState(() {});
                                      } else {
                                        try {
                                          connection = await BluetoothConnection
                                              .toAddress(device.address);
                                          print('Connected to the device');
                                          _listenForData();
                                          devices.clear();
                                          devices.add(device);
                                          setState(() {});
                                        } catch (e) {
                                          print(
                                              'Cannot connect to the device: $e');
                                        }
                                      }
                                    })),
                          );
                        }).toList(),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Text(
                        'Pressure',
                        style: getBlackTextStyle(),
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      Column(
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.25,
                            child: InputFormWidget(
                              isDecimalOnly: true,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              controller: pressureCtrl,
                              hint: '',
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                        ],
                      ),
                      // TIRE
                      BlocBuilder<TireBloc, TireState>(
                        builder: (context, state) {
                          if (state is TireLoadingState) {
                            return CircularProgressIndicator();
                          }

                          if (state is TiresLoadedState) {
                            return LayoutBuilder(
                                builder: (context, constraints) {
                              return Container(
                                height: constraints.maxWidth * 3.4,
                                child: Swiper(
                                  controller: swiperController,
                                  loop: false,
                                  physics: NeverScrollableScrollPhysics(),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: state.units.length,
                                  itemBuilder: (context, index) {
                                    return PgdTireCardWidget(
                                      dataTire: state.units[index],
                                      onCategoryChecked: (checkedList) {
                                        handleDataChecked(checkedList, index);
                                      },
                                      onSelectedTireDamage: (tireDamage) {
                                        handleDataSelected(tireDamage, index);
                                      },
                                      onStringRemarks: (remarks) {
                                        handleDataRemarks(remarks, index);
                                      },
                                      onStringRTD: (rtd) {
                                        handleDataRTD(rtd, index);
                                      },
                                      onImageTire: (images) {
                                        handleImageTire(images);
                                      },
                                    );
                                  },
                                ),
                              );
                            });
                          }
                          return Container();
                        },
                      ),

                      const SizedBox(
                        height: 12,
                      ),

                      BlocBuilder<TireBloc, TireState>(
                        builder: (context, state) {
                          if (state is TireLoadingState) {}

                          if (state is TiresLoadedState) {
                            return Row(
                              children: [
                                Expanded(
                                  child: ButtonWidget(
                                    name: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.arrow_left),
                                        const SizedBox(width: 6),
                                        Text(
                                          'Previous',
                                          style: getWhiteTextStyle(),
                                        ),
                                      ],
                                    ),
                                    function: () {
                                      if (swiperController.index > 0) {
                                        swiperController.index--;
                                        swiperController.previous();
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ButtonWidget(
                                    name: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Next',
                                          style: getWhiteTextStyle(),
                                        ),
                                        const SizedBox(width: 6),
                                        Icon(Icons.arrow_right),
                                      ],
                                    ),
                                    function: () {
                                      if (swiperController.index <
                                          state.units.length - 1) {
                                        swiperController.index++;
                                        swiperController.next();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            );
                          }

                          return Container();
                        },
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  ),
                ),
              );
            } else {
              if (state is TireLoadingState) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              if (state is TiresLoadedState) {
                final units = state.units;

                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.front_loader,
                                        color: Colors.orange,
                                        size: 38,
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Text(
                                        'UNIT',
                                        style: getBlackTextStyle(
                                            fontWeight: w700, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: InputFormWidget(
                                        isReadOnly: true,
                                        controller: TextEditingController(
                                          text: units[0].unitNumber,
                                        ),
                                        hint: ''),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.watch,
                                        color: Colors.red,
                                        size: 38,
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Text(
                                        'HM UNIT',
                                        style: getBlackTextStyle(
                                            fontWeight: w700, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: InputFormWidget(
                                        // isReadOnly: true,
                                        // controller: hmCtrl,
                                        controller: hmUnit,
                                        isDecimalOnly: true,
                                        type: TextInputType.number,
                                        hint: 'Fill HM'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: units.length,
                            itemBuilder: (context, index) {
                              final unit = units[index];

                              return Card(
                                elevation: 2,
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  padding: EdgeInsets.all(24),
                                  child: Stack(
                                    children: [
                                      Opacity(
                                        opacity: 0.1,
                                        child: Center(
                                          child: Text(
                                            unit.rating ?? '',
                                            style: TextStyle(
                                              fontSize: 100,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              SizedBox(
                                                width: 35,
                                                height: 53,
                                                child: Image.asset(
                                                  '$imagePath/em_tire_image.png',
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    'Position',
                                                    style: getBlackTextStyle(
                                                        fontSize: 14),
                                                  ),
                                                  const SizedBox(
                                                    height: 6,
                                                  ),
                                                  Text(
                                                    '${index + 1}',
                                                    style: getBlackTextStyle(
                                                        fontSize: 22,
                                                        fontWeight: w700),
                                                  ),
                                                ],
                                              )
                                            ],
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Divider(
                                              thickness: 1.5,
                                            ),
                                          ),
                                          Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Unit',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700),
                                                  ),
                                                  Text(
                                                    unit.unitNumber ?? '',
                                                    style: getBlackTextStyle(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'SN',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700),
                                                  ),
                                                  Text(
                                                    unit.sn ?? '',
                                                    style: getBlackTextStyle(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Brand',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700),
                                                  ),
                                                  Text(
                                                    unit.brand ?? '',
                                                    style: getBlackTextStyle(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Tire Lifetime',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700),
                                                  ),
                                                  Text(
                                                    unit.lifetime ?? '',
                                                    style: getBlackTextStyle(),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Rating',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700),
                                                  ),
                                                  Text(
                                                    unit.rating ?? '',
                                                    style: getBlackTextStyle(),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Divider(
                                              thickness: 1.5,
                                            ),
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: 45,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                setState(() {
                                                  // selectedPosIndex = posIndex;
                                                });
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Dialog(
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                            20.0),
                                                        child:
                                                            SingleChildScrollView(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: <Widget>[
                                                              Text(
                                                                'Choose Pressure',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      24.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 16.0),
                                                              Column(),
                                                              Wrap(
                                                                children:
                                                                    pressure.map(
                                                                        (ps) {
                                                                  final psIndex =
                                                                      pressure
                                                                          .indexOf(
                                                                              ps);
                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            16,
                                                                        bottom:
                                                                            18),
                                                                    child:
                                                                        ElevatedButton(
                                                                      style: ElevatedButton.styleFrom(
                                                                          backgroundColor:
                                                                              Colors.green),
                                                                      onPressed:
                                                                          () {
                                                                        final id =
                                                                            Uuid();
                                                                        setState(
                                                                            () {
                                                                          position[index]['pressure'] =
                                                                              ps;
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        });
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        ps,
                                                                        style:
                                                                            getWhiteTextStyle(
                                                                          fontWeight:
                                                                              w700,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        SizedBox(
                                                                      width: double
                                                                          .infinity,
                                                                      child: InputFormWidget(
                                                                          controller:
                                                                              pressureCtrl,
                                                                          isDigitOnly:
                                                                              true,
                                                                          type: TextInputType
                                                                              .number,
                                                                          hint:
                                                                              'Input Manual'),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          if (pressureCtrl.text !=
                                                                              '') {
                                                                            position[index]['pressure'] =
                                                                                pressureCtrl.text;
                                                                          }
                                                                          pressureCtrl
                                                                              .clear();
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        });
                                                                      },
                                                                      child: Text(
                                                                          'Submit'))
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                  height: 12.0),
                                                              SizedBox(
                                                                width: double
                                                                    .infinity,
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed:
                                                                      () {
                                                                    pressureCtrl
                                                                        .clear();
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                  child: Text(
                                                                      'Close'),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  )),
                                              child: (position[index]
                                                              ['pressure'] ==
                                                          '' ||
                                                      (position[index]
                                                              ['pressure'] ==
                                                          null))
                                                  ? Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Icon(
                                                          Icons.add,
                                                          color: white,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          'Pressure',
                                                          style:
                                                              getWhiteTextStyle(),
                                                        )
                                                      ],
                                                    )
                                                  : Text(
                                                      '${position[index]['pressure']} Psi',
                                                      style: getWhiteTextStyle(
                                                        fontSize: 24,
                                                        fontWeight: w700,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          // adjusment pressure
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            height: 45,
                                            child: ElevatedButton(
                                              onPressed: () async {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                setState(() {
                                                  // selectedPosIndex = posIndex;
                                                });
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Dialog(
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                            20.0),
                                                        child:
                                                            SingleChildScrollView(
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: <Widget>[
                                                              Text(
                                                                'Choose Pressure',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      24.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 16.0),
                                                              Column(),
                                                              Wrap(
                                                                children:
                                                                    pressure.map(
                                                                        (ps) {
                                                                  final psIndex =
                                                                      pressure
                                                                          .indexOf(
                                                                              ps);
                                                                  return Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            16,
                                                                        bottom:
                                                                            18),
                                                                    child:
                                                                        ElevatedButton(
                                                                      style: ElevatedButton.styleFrom(
                                                                          backgroundColor:
                                                                              Colors.green),
                                                                      onPressed:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          position[index]['adjusmentPressure'] =
                                                                              ps;
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        });
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        ps,
                                                                        style:
                                                                            getWhiteTextStyle(
                                                                          fontWeight:
                                                                              w700,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  );
                                                                }).toList(),
                                                              ),
                                                              Row(
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        SizedBox(
                                                                      width: double
                                                                          .infinity,
                                                                      child: InputFormWidget(
                                                                          controller:
                                                                              pressureCtrl,
                                                                          isDigitOnly:
                                                                              true,
                                                                          type: TextInputType
                                                                              .number,
                                                                          hint:
                                                                              'Input Manual'),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    width: 6,
                                                                  ),
                                                                  ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          if (pressureCtrl.text !=
                                                                              '') {
                                                                            position[index]['adjusmentPressure'] =
                                                                                pressureCtrl.text;
                                                                          }
                                                                          pressureCtrl
                                                                              .clear();
                                                                          Navigator.of(context)
                                                                              .pop();
                                                                        });
                                                                      },
                                                                      child: Text(
                                                                          'Submit'))
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                  height: 12.0),
                                                              SizedBox(
                                                                width: double
                                                                    .infinity,
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed:
                                                                      () {
                                                                    pressureCtrl
                                                                        .clear();
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  },
                                                                  child: Text(
                                                                      'Close'),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.blue,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  )),
                                              child: (position[index][
                                                          'adjusmentPressure'] ==
                                                      '')
                                                  ? Text(
                                                      'Adj Pressure',
                                                      style:
                                                          getWhiteTextStyle(),
                                                    )
                                                  : Text(
                                                      '${position[index]['adjusmentPressure']} Psi (Adj)',
                                                      style: getWhiteTextStyle(
                                                        fontSize: 16,
                                                        fontWeight: w700,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          SizedBox(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            // height: 65,
                                            child: ElevatedButton(
                                                onPressed: () {
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                  List<bool>
                                                      checkedDamageValues =
                                                      List<bool>.filled(
                                                          damageType.length,
                                                          false);

                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return Dialog(
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  20.0),
                                                          child: Column(
                                                            mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                            children: <Widget>[
                                                              Text(
                                                                'Choose Damage Tire',
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      24.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 12.0),
                                                              Expanded(
                                                                child:
                                                                    SingleChildScrollView(
                                                                  child: Column(
                                                                    children:
                                                                        damageType
                                                                            .map((damage) {
                                                                      final dmgIndex =
                                                                          damageType
                                                                              .indexOf(damage);

                                                                      if (dmgIndex >
                                                                          0) {
                                                                        return StatefulBuilder(builder:
                                                                            (context,
                                                                                setState) {
                                                                          return CheckboxListTile(
                                                                            title:
                                                                                Text(damage),
                                                                            value:
                                                                                checkedDamageValues[dmgIndex],
                                                                            onChanged:
                                                                                (bool? value) {
                                                                              setState(() {
                                                                                checkedDamageValues[dmgIndex] = value ?? false;
                                                                              });
                                                                            },
                                                                          );
                                                                        });
                                                                      }
                                                                      return Container();
                                                                    }).toList(),
                                                                  ),
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height:
                                                                      12.0), // Tambahkan sedikit jarak antara daftar checkbox dan tombol "Close"
                                                              Column(
                                                                children: [
                                                                  SizedBox(
                                                                    height: 42,
                                                                    width: double
                                                                        .infinity,
                                                                    child: InputFormWidget(
                                                                        controller:
                                                                            damageCtrl,
                                                                        hint:
                                                                            'Input Manual Here....'),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 12,
                                                                  ),
                                                                  SizedBox(
                                                                    width: double
                                                                        .infinity,
                                                                    child:
                                                                        ElevatedButton(
                                                                      onPressed:
                                                                          () {
                                                                        damageCtrl
                                                                            .clear();
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child: Text(
                                                                          'Close'),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                    height: 12,
                                                                  ),
                                                                  SizedBox(
                                                                    width: double
                                                                        .infinity,
                                                                    child:
                                                                        ElevatedButton(
                                                                      style: ElevatedButton
                                                                          .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.green,
                                                                      ),
                                                                      onPressed:
                                                                          () {
                                                                        setState(
                                                                            () {});

                                                                        selectedDamage
                                                                            .clear();
                                                                        final List<String>
                                                                            tmp =
                                                                            [];
                                                                        if (damageCtrl.text ==
                                                                                '' ||
                                                                            damageCtrl.text.isNotEmpty) {
                                                                          tmp.add(
                                                                              damageCtrl.text);
                                                                        }
                                                                        for (int i =
                                                                                0;
                                                                            i < checkedDamageValues.length;
                                                                            i++) {
                                                                          if (checkedDamageValues[
                                                                              i]) {
                                                                            tmp.add(damageType[i]);
                                                                          }
                                                                        }
                                                                        position[index]['damageTire'] =
                                                                            tmp;
                                                                        if (tmp
                                                                            .isNotEmpty) {
                                                                          position[index]['damageTire'] =
                                                                              tmp;
                                                                          selectedDamage
                                                                              .addAll(tmp);
                                                                          log('hasil luka ban : ${position}');
                                                                        }
                                                                        damageCtrl
                                                                            .clear();

                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        'Submit',
                                                                        style:
                                                                            getWhiteTextStyle(
                                                                          fontWeight:
                                                                              w700,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor: blue344BEF,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    )),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: Text(
                                                    (position[index][
                                                                    'damageTire'] ==
                                                                null ||
                                                            position[index][
                                                                    'damageTire'] ==
                                                                [] ||
                                                            (position[index][
                                                                        'damageTire']
                                                                    as List<
                                                                        dynamic>)
                                                                .isEmpty)
                                                        ? 'Damage Tire (None)'
                                                        : position[index]
                                                                ['damageTire']
                                                            .join('\n---\n'),
                                                    textAlign: TextAlign.center,
                                                    style: getWhiteTextStyle(
                                                        fontSize: 14),
                                                  ),
                                                )),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Text(
                                                      'RTD 1',
                                                      style: getBlackTextStyle(
                                                          fontWeight: w700),
                                                    ),
                                                    const SizedBox(
                                                      height: 12,
                                                    ),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: InputFormWidget(
                                                          onChng: (value) {
                                                            position[index]
                                                                    ['rtd1'] =
                                                                value;
                                                          },
                                                          controller:
                                                              rtd1Controllers[
                                                                  index],
                                                          hint: ''),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 12,
                                              ),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
                                                  children: [
                                                    Text(
                                                      'RTD 2',
                                                      style: getBlackTextStyle(
                                                          fontWeight: w700),
                                                    ),
                                                    const SizedBox(
                                                      height: 12,
                                                    ),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: InputFormWidget(
                                                          onChng: (value) {
                                                            position[index]
                                                                    ['rtd2'] =
                                                                value;
                                                          },
                                                          controller:
                                                              rtd2Controllers[
                                                                  index],
                                                          hint: ''),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(
                                                width: 12,
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text(
                                                'Remarks',
                                                style: getBlackTextStyle(
                                                    fontWeight: w700),
                                              ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              SizedBox(
                                                width: double.infinity,
                                                child: InputFormWidget(
                                                    onChng: (value) {
                                                      position[index]
                                                          ['remarks'] = value;
                                                    },
                                                    controller:
                                                        remarksControllers[
                                                            index],
                                                    hint: ''),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 24,
                                          ),
                                          Text(
                                            'Broken Component (Optional)',
                                            style: getBlackTextStyle(
                                                fontWeight: w700),
                                          ),
                                          SizedBox(
                                            // height: 160,
                                            child: GridView.builder(
                                                physics:
                                                    NeverScrollableScrollPhysics(),
                                                shrinkWrap: true,
                                                itemCount: position[index]
                                                        ['condition']
                                                    .length,
                                                gridDelegate:
                                                    SliverGridDelegateWithFixedCrossAxisCount(
                                                        crossAxisCount: 2,
                                                        childAspectRatio: 3),
                                                itemBuilder:
                                                    (context, indexBroken) {
                                                  final broken = position[index]
                                                          ['condition']
                                                      [indexBroken];
                                                  return InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        // checkedListCategory[
                                                        //         index] =
                                                        //     !checkedListCategory[
                                                        //         index];
                                                        broken['checked'] =
                                                            !broken['checked'];
                                                      });
                                                      // widget.onCategoryChecked(checkedListCategory);
                                                    },
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(10),
                                                      child: Row(
                                                        children: [
                                                          Container(
                                                            width: 24,
                                                            height: 24,
                                                            decoration:
                                                                BoxDecoration(
                                                              color: broken[
                                                                      'checked']
                                                                  ? black
                                                                  : Colors
                                                                      .transparent,
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .black),
                                                            ),
                                                            child: Icon(
                                                              Icons.check,
                                                              color:
                                                                  Colors.white,
                                                              size: 16,
                                                            ),
                                                          ),
                                                          SizedBox(width: 10),
                                                          LayoutBuilder(builder:
                                                              (context,
                                                                  constraints) {
                                                            double fontSize =
                                                                constraints
                                                                        .maxHeight *
                                                                    0.35;
                                                            // log('ukuran' + fontSize.toString());
                                                            return Text(
                                                              broken['name'],
                                                              style: getBlackTextStyle(
                                                                  fontSize:
                                                                      fontSize),
                                                            );
                                                          }),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                      ],
                    ),
                  ),
                );
              }
              return Container();
            }
          },
        )),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            BlocBuilder<TireBloc, TireState>(
              builder: (context, state) {
                if (state is TiresLoadedState) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    child: ButtonWidget(
                        name: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.save_alt),
                            const SizedBox(
                              width: 6,
                            ),
                            Text(
                              'Save',
                              style: getWhiteTextStyle(),
                            ),
                          ],
                        ),
                        function: (selectedMenu == 0)
                            ? () {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                    'Successful save data, please check in home page',
                                    style: getWhiteTextStyle(),
                                  ),
                                  backgroundColor: green00968A,
                                ));
                                final id = Uuid();
                                final fixId = id.v4();
                                isSaved = true;
                                final savedTires =
                                    state.units[swiperController.index];

                                imageBox.put(TireInspectPictureEntity(
                                    idImage: fixId, image: ''));

                                // Disimpan di objectbox
                                context
                                    .read<OutstandingTaskBloc>()
                                    .add(AddOutStandingTaskEvent(
                                        task: OutstandingTask(
                                      id: id.v4(),
                                      idSite: idSite,
                                      user: auth.currentUser!.email ?? '',
                                      unit: idUnit.text,
                                      position:
                                          int.parse(savedTires.posisi ?? '0'),
                                      brand: savedTires.brand ?? '',
                                      serialNumber: savedTires.sn ?? '',
                                      tireSize: savedTires.size ?? '',
                                      hm: hmUnit.text,
                                      condition: checkedCategories
                                          .map((category) => category)
                                          .toList(),
                                      tireDamage: selectedTireDamage,
                                      remarks: remarks,
                                      rtd: rtd,
                                      pressure: pressureCtrl.text,
                                      adjusmentPressure: pressureCtrl.text,
                                      lastUpdate:
                                          DateTime.now().toIso8601String(),
                                      isDone: false,
                                      sn: savedTires.sn ?? '',
                                      images:
                                          (Platform.isAndroid) ? listImg : [],
                                      kunciUnit: savedTires.kunciUnit ?? '',
                                      kunciTire: savedTires.kunciTire ?? '',
                                    )));

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        backgroundColor: green00968A,
                                        content: Text(
                                          'Succesful Save Data',
                                          style: getWhiteTextStyle(),
                                        )));
                              }
                            : () async {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                    'Successful save data, please check in home page',
                                    style: getWhiteTextStyle(),
                                  ),
                                  backgroundColor: green00968A,
                                ));

                                // input ke tire inspection
                                try {
                                  log('apakah pressure tire kosong : ${(position[0]['damageTire'] as List<dynamic>) == null}');

                                  position.removeWhere((element) =>
                                      element['pressure'] == '' &&
                                      (element['damageTire'] as List<dynamic>)
                                          .isEmpty &&
                                      element['adjusmentPressure'] == '' &&
                                      element['rtd1'] == '' &&
                                      element['rtd2'] == '' &&
                                      element['remarks'] == '');
                                  log('tire tire : ${position}');

                                  for (int i = 0; i < position.length; i++) {
                                    final unit = state.units[i];
                                    final id = Uuid();

                                    if (position[i]['pressure'] != '' ||
                                        position[i]['damageTire'] != [] ||
                                        position[i]['damageTire'][0] !=
                                            damageType[0] ||
                                        position[i]['adjusmentPressure'] !=
                                            '' ||
                                        position[i]['rtd1'] != '' ||
                                        position[i]['rtd2'] != '' ||
                                        position[i]['remarks'] != '') {
                                      final querySnapshot = await firestore
                                          .collection('task')
                                          .where('kunci_unit',
                                              isEqualTo: unit.kunciUnit)
                                          .where('kunci_tire',
                                              isEqualTo: unit.kunciTire)
                                          .where('position',
                                              isEqualTo: position[i]
                                                  ['position'])
                                          .get();

                                      log('adakah query : ${querySnapshot.docs.isNotEmpty}');

                                      if (querySnapshot.docs.isNotEmpty) {
                                        // Update the existing document
                                        final docId =
                                            querySnapshot.docs.first.id;
                                        await firestore
                                            .collection('task')
                                            .doc(docId)
                                            .update({
                                          'id': id.v4(),
                                          'id_site': idSite,
                                          'user': user['username'] ??
                                              auth.currentUser!.email,
                                          'unit': unit.unitNumber,
                                          'serial_number': unit.sn,
                                          'condition': position[i]['condition']
                                              .where((condition) =>
                                                  condition['checked'] == true)
                                              .map((condition) =>
                                                  condition['name'].toString())
                                              .toList(),
                                          'tire_size': unit.size,
                                          'hm': hmUnit.text,
                                          'position': position[i]['position'],
                                          'brand': unit.brand,
                                          'tire_damage': (position[i]
                                                      ['damageTire']
                                                  .isEmpty)
                                              ? damageType[0]
                                              : position[i]['damageTire'],
                                          'remarks': position[i]['remarks'],
                                          'rtd':
                                              '${position[i]['rtd1']}/${position[i]['rtd2']}',
                                          'pressure': position[i]['pressure'],
                                          'adjusmentPressure': position[i]
                                              ['adjusmentPressure'],
                                          'last_update':
                                              DateTime.now().toIso8601String(),
                                          'is_done': false,
                                          'images': [],
                                          'sn': unit.sn,
                                          'kunci_unit': unit.kunciUnit,
                                          'kunci_tire': unit.kunciTire,
                                        });
                                      } else {
                                        await firestore.collection('task').add({
                                          'id': id.v4(),
                                          'id_site': idSite,
                                          'user': user['username'] ??
                                              auth.currentUser!.email,
                                          'unit': unit.unitNumber,
                                          'serial_number': unit.sn,
                                          'condition': position[i]['condition']
                                              .where((condition) =>
                                                  condition['checked'] == true)
                                              .map((condition) =>
                                                  condition['name'].toString())
                                              .toList(),
                                          'tire_size': unit.size,
                                          'hm': hmUnit.text,
                                          'position': position[i]['position'],
                                          'brand': unit.brand,
                                          'tire_damage': (position[i]
                                                      ['damageTire']
                                                  .isEmpty)
                                              ? damageType[0]
                                              : position[i]['damageTire'],
                                          'remarks': position[i]['remarks'],
                                          'rtd':
                                              '${position[i]['rtd1']}/${position[i]['rtd2']}',
                                          'pressure': position[i]['pressure'],
                                          'adjusmentPressure': position[i]
                                              ['adjusmentPressure'],
                                          'last_update':
                                              DateTime.now().toIso8601String(),
                                          'is_done': false,
                                          'images': [],
                                          'sn': unit.sn,
                                          'kunci_unit': unit.kunciUnit,
                                          'kunci_tire': unit.kunciTire,
                                        });
                                      }
                                    }
                                  }

                                  // input ke daily check pressure
                                  try {
                                    final today = DateTime.now();
                                    final startOfDay = DateTime(
                                        today.year, today.month, today.day);
                                    final endOfDay = DateTime(today.year,
                                        today.month, today.day, 23, 59, 59);

                                    final querySnapshot = await firestore
                                        .collection('daily_pressure')
                                        .where('unit', isEqualTo: idUnit.text)
                                        .where('tanggal',
                                            isGreaterThanOrEqualTo: startOfDay)
                                        .where('tanggal',
                                            isLessThanOrEqualTo: endOfDay)
                                        .get();

                                    print(
                                        'Documents found: ${querySnapshot.docs.length}');

                                    if (querySnapshot.docs.isNotEmpty) {
                                      final docId = querySnapshot.docs.first.id;

                                      // revisi data
                                      await firestore
                                          .collection('daily_pressure')
                                          .doc(docId)
                                          .update({
                                        'idSite': idSite,
                                        'user': user['username'] ??
                                            auth.currentUser!.email,
                                        'tanggal':
                                            DateTime.now().toIso8601String(),
                                        'unit': idUnit.text,
                                        'hm': hmUnit.text,
                                        'posisi': position.map((p) {
                                          final pIndex = position.indexOf(p);

                                          log('tekanan angin : ${p['pressure']}');
                                          return {
                                            'pos': '${pIndex + 1}',
                                            'pressure': (p['pressure']) ?? '0',
                                            'adjusmentPressure':
                                                (p['adjusmentPressure']) ?? '0',
                                            'luka': p['damageTire']
                                          };
                                        }),
                                        'pit': 'Default',
                                      });
                                    } else {
                                      // tambah data
                                      await firestore
                                          .collection('daily_pressure')
                                          .add({
                                        // 'nama': (user),
                                        'idSite': idSite,
                                        'user': user['username'] ??
                                            auth.currentUser!.email,
                                        'tanggal':
                                            DateTime.now().toIso8601String(),
                                        'unit': idUnit.text,
                                        'hm': hmUnit.text,
                                        'posisi': position.map((p) {
                                          final pIndex = position.indexOf(p);
                                          log('tekanan angin : ${p['pressure']}');

                                          return {
                                            'pos': '${pIndex + 1}',
                                            'pressure': (p['pressure']) ?? '0',
                                            'adjusmentPressure':
                                                (p['adjusmentPressure']) ?? '0',
                                            'luka': p['damageTire']
                                          };
                                        }),
                                        'pit': 'Default',
                                      });
                                    }
                                  } catch (e) {
                                    print('error bmb : $e');
                                  }
                                } catch (e) {
                                  log('kenapa gagal : $e');
                                }
                              }),
                  );
                }
                return Container();
              },
            ),
            const SizedBox(
              height: 12,
            ),
            BottomNavigationBar(
              selectedItemColor: green00968A,
              items: [
                BottomNavigationBarItem(
                    icon: Icon(Icons.tire_repair), label: 'PG Digital'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.edit_square), label: 'Manual'),
              ],
              currentIndex: selectedMenu,
              onTap: (index) {
                setState(() {
                  selectedMenu = index;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

////// FLUTTER SERIAL BLUETOOTH 2

// import 'dart:async';
// import 'dart:developer';
// import 'dart:io';

// import 'package:app_settings/app_settings.dart';
// import 'package:camos/core/blocs/outstanding_task/outstanding_task_bloc.dart';
// import 'package:camos/core/blocs/tire/tire_bloc.dart';
// import 'package:camos/core/blocs/unit/unit_bloc.dart';
// import 'package:camos/core/navigator/navigation_route.dart';
// import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
// import 'package:camos/core/services/model/outstanding_task.dart';
// import 'package:camos/core/services/model/unit_tire.dart';
// import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
// import 'package:camos/core/styles/asset_path.dart';
// import 'package:camos/core/styles/color.dart';
// import 'package:camos/core/styles/text_manager.dart';
// import 'package:camos/core/utils/data/oustanding_task.dart';
// import 'package:camos/core/utils/data/pgd.dart';
// import 'package:camos/core/utils/functions/functions.dart';
// import 'package:camos/core/widgets/appbar_widget.dart';
// import 'package:camos/core/widgets/button_widget.dart';
// import 'package:camos/core/widgets/input_form_widget.dart';
// import 'package:camos/core/widgets/pgd_tire_card_widget.dart';
// import 'package:camos/main.dart';
// import 'package:camos/objectbox.g.dart';
// import 'package:camos/pages/home/home_page.dart';
// import 'package:card_swiper/card_swiper.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';

// class TireInspectionFormPage extends StatefulWidget {
//   static const routeName = '/pgd-page';
//   const TireInspectionFormPage({super.key});

//   @override
//   State<TireInspectionFormPage> createState() => _TireInspectionFormPageState();
// }

// class _TireInspectionFormPageState extends State<TireInspectionFormPage> with WidgetsBindingObserver {
//   // bluetooth

//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth auth = FirebaseAuth.instance;

//   var map = {};
//   String idSite = '';
//   bool isSaved = false;
//   Map<String, dynamic> dataUnit = {};

//   final Box<OutstandingTaskEntity> box = store.box<OutstandingTaskEntity>();

//   TextEditingController idUnit = TextEditingController(text: '');
//   TextEditingController hmUnit = TextEditingController(text: '');
//   TextEditingController pressureCtrl = TextEditingController(text: '');
//   TextEditingController remarksCtrl = TextEditingController(text: '');
//   SwiperController swiperController = SwiperController();

//   String selectedUnit = '';
//   List<String> checkedCategories = [];
//   String selectedTireDamage = '';
//   String remarks = '';
//   String rtd = '';
//   List<File> listImg = [];

//   List<String> categories = [
//     'Reseal Oring',
//     'Rim Condition',
//     'Inflate Tire',
//     'Lock Driver',
//     'Slide Lock',
//     'Valve Cap',
//     'Valve Protector',
//     'Stud and Nut',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     requestPlacePermission();

//     callTires();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   late StreamSubscription<List<ScanResult>> subscription;
//   List<ScanResult> deviceBluetooth = [];

//   turnBluetooth() async {
//     if (await FlutterBluePlus.isSupported == false) {
//       print("Bluetooth not supported by this device");
//       return;
//     }

//     FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
//       print(state);
//       if (state == BluetoothAdapterState.on) {
//         startScanBluetooth();
//       } else {}
//     });

//     if (Platform.isAndroid) {
//       await FlutterBluePlus.turnOn();
//     }
//   }

//   startScanBluetooth() async {
//     await FlutterBluePlus.startScan();

//     subscription = FlutterBluePlus.onScanResults.listen(
//       (results) async {
//         if (results.isNotEmpty) {
//           ScanResult r = results.last; // the most recently found device
//           setState(() {
//             deviceBluetooth.add(r);
//           });
//           print(
//               '${r.device.remoteId}: "${r.advertisementData.advName}" found!');
//         }

//         await FlutterBluePlus.adapterState
//             .where((val) => val == BluetoothAdapterState.on)
//             .first;
//       },
//     );
//   }

//   stopScanBluetooth() async {
//     print('BLUETOOTH BERHENTI!');
//     await FlutterBluePlus.stopScan();
//     subscription.cancel();
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   String tmpPressure = '';

//   void handleDataChecked(List<bool> checkedList, int index) {
//     checkedCategories.clear();

//     for (int i = 0; i < checkedList.length; i++) {
//       if (checkedList[i] == true) {
//         // setState(() {
//         checkedCategories.add(categories[i]);
//         // });
//       }
//     }

//     // Cetak hasil untuk tujuan pengujian
//   }

//   void handleDataSelected(String tireDamage, int index) {
//     // Perbarui data tire damage
//     selectedTireDamage = tireDamage;
//   }

//   void handleImageTire(List<File> images) {
//     listImg.clear();
//     listImg.addAll(images);
//   }

//   void callTires() async {
//     idSite = await getIdSitePreferences();
//     if (idSite == '1') {
//       idSite = await getSelectedIdSitePreferences();
//     }
//     if (mounted) {
//       if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
//         idUnit.text = dataUnit['unitNumber'];
//         hmUnit.text = dataUnit['hm'];
//         context.read<TireBloc>().add(GetUnitTiresEvent(
//             idSite: idSite, unitNumber: dataUnit['unitNumber']));
//       }
//     }
//   }

//   void handleDataRemarks(String remarks, int index) {
//     this.remarks = remarks;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   void handleDataRTD(String rtd, int index) {
//     this.rtd = rtd;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   @override
//   Widget build(BuildContext context) {
//     print('dipanggil (pgd)');
//     dataUnit =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

//     return WillPopScope(
//       onWillPop: () async {
//         if (isSaved) {
//           stopScanBluetooth();
//           pushReplace(context, HomePage.routeName);
//         } else {
//           stopScanBluetooth();
//           back(context);
//         }
//         return false;
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           title: Padding(
//             padding: const EdgeInsets.only(top: 18.0),
//             child: Text(
//               'Pressure Gauge Digital',
//               textAlign: TextAlign.center,
//               style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
//             ),
//           ),
//           centerTitle: true,
//           leading: Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Container(
//               margin: const EdgeInsets.only(top: 14),
//               padding: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 color: white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: black),
//               ),
//               child: IconButton(
//                   onPressed: () {
//                     if (isSaved) {
//                       stopScanBluetooth();
//                       pushReplace(context, HomePage.routeName);
//                     } else {
//                       stopScanBluetooth();
//                       back(context);
//                     }
//                   },
//                   icon: const Icon(
//                     Icons.arrow_back_ios,
//                     color: black,
//                     size: 24,
//                   )),
//             ),
//           ),
//         ),
//         body: SafeArea(child: BlocBuilder<TireBloc, TireState>(
//           builder: (context, state) {
//             return SingleChildScrollView(
//               primary: false,
//               physics: BouncingScrollPhysics(),
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               Text(
//                                 'Unit Number',
//                                 style: getBlackTextStyle(fontWeight: w700),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                     isReadOnly: true,
//                                     controller: idUnit,
//                                     hint: ''),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               Text(
//                                 'HM Unit',
//                                 style: getBlackTextStyle(fontWeight: w700),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                     isReadOnly: true,
//                                     controller: hmUnit,
//                                     hint: 'Insert HM Unit'),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(
//                           width: 12,
//                         ),
//                         // SizedBox(
//                         //   height: 200,
//                         //   width: 100,
//                         //   child: ButtonWidget(
//                         //       name: Row(
//                         //         mainAxisAlignment: MainAxisAlignment.center,
//                         //         children: [
//                         //           Icon(Icons.restore),
//                         //           const SizedBox(
//                         //             width: 6,
//                         //           ),
//                         //           Text(
//                         //             'Reset',
//                         //             style: getWhiteTextStyle(),
//                         //           ),
//                         //         ],
//                         //       ),
//                         //       function: () {
//                         //         idUnit.clear();
//                         //         hmUnit.clear();
//                         //         setState(() {});
//                         //       }),
//                         // ),
//                       ],
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 12.0),
//                       child: Divider(
//                         thickness: 1.2,
//                       ),
//                     ),
//                     Text(
//                       'Bluetooth Connection',
//                       style: getBlackTextStyle(
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     ButtonWidget(
//                         name: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(Icons.bluetooth),
//                             const SizedBox(
//                               width: 6,
//                             ),
//                             Text(
//                               'Scan Devices',
//                               style: getWhiteTextStyle(),
//                             ),
//                           ],
//                         ),
//                         function: () async {
//                           deviceBluetooth.clear();

//                           requestBluetoothPermission();
//                           turnBluetooth();
//                           // AppSettings.openBluetoothSettings();
//                         }),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Column(
//                       children: deviceBluetooth.map((device) {
//                         if (device.advertisementData.advName == '') {
//                           return Container();
//                         }
//                         return ListTile(
//                           title: Text(
//                             device.advertisementData.advName,
//                             style: getBlackTextStyle(),
//                           ),
//                           // subtitle: Text(
//                           //   device.address,
//                           //   style: getGreyTextStyle(grey6A707C),
//                           // ),
//                           // trailing: SizedBox(
//                           //     width: 110,
//                           //     height: 50,
//                           //     child: ButtonWidget(
//                           //         name: Text(
//                           //           (isConnected) ? 'Disconnect' : 'Connect',
//                           //           style: getWhiteTextStyle(),
//                           //         ),
//                           //         function: () async {
//                           //           if (isConnected) {
//                           //             await connection!.close();
//                           //             devices.clear();
//                           //             setState(() {});
//                           //           } else {
//                           //             try {
//                           //               connection =
//                           //                   await BluetoothConnection.toAddress(
//                           //                       device.address);
//                           //               print('Connected to the device');
//                           //               _listenForData();
//                           //               devices.clear();
//                           //               devices.add(device);
//                           //               setState(() {});
//                           //             } catch (e) {
//                           //               print(
//                           //                   'Cannot connect to the device: $e');
//                           //             }
//                           //           }
//                           //         })),
//                         );
//                       }).toList(),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Text(
//                       'Pressure',
//                       style: getBlackTextStyle(),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Column(
//                       children: [
//                         SizedBox(
//                           width: MediaQuery.of(context).size.width * 0.25,
//                           child: InputFormWidget(
//                             isDecimalOnly: true,
//                             type: const TextInputType.numberWithOptions(
//                                 decimal: true),
//                             controller: pressureCtrl,
//                             hint: '',
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 12,
//                         ),
//                       ],
//                     ),
//                     // (tmpPressure == '')
//                     //     ? Container()
//                     //     : Column(
//                     //         children: [
//                     //           SizedBox(
//                     //             width: MediaQuery.of(context).size.width * 0.25,
//                     //             child: InputFormWidget(
//                     //               isReadOnly: true,
//                     //               controller:
//                     //                   TextEditingController(text: tmpPressure),
//                     //               hint: '',
//                     //             ),
//                     //           ),
//                     //           const SizedBox(
//                     //             height: 12,
//                     //           ),
//                     //         ],
//                     //       ),
//                     // TIRE
//                     BlocBuilder<TireBloc, TireState>(
//                       builder: (context, state) {
//                         if (state is TireLoadingState) {
//                           return CircularProgressIndicator();
//                         }

//                         if (state is TiresLoadedState) {
//                           return LayoutBuilder(builder: (context, constraints) {
//                             return Container(
//                               height: constraints.maxWidth * 3.4,
//                               child: Swiper(
//                                 controller: swiperController,
//                                 loop: false,
//                                 physics: NeverScrollableScrollPhysics(),
//                                 scrollDirection: Axis.horizontal,
//                                 itemCount: state.units.length,
//                                 itemBuilder: (context, index) {
//                                   return PgdTireCardWidget(
//                                     dataTire: state.units[index],
//                                     onCategoryChecked: (checkedList) {
//                                       handleDataChecked(checkedList, index);
//                                     },
//                                     onSelectedTireDamage: (tireDamage) {
//                                       handleDataSelected(tireDamage, index);
//                                     },
//                                     onStringRemarks: (remarks) {
//                                       handleDataRemarks(remarks, index);
//                                     },
//                                     onStringRTD: (rtd) {
//                                       handleDataRTD(rtd, index);
//                                     },
//                                     onImageTire: (images) {
//                                       handleImageTire(images);
//                                     },
//                                   );
//                                 },
//                               ),
//                             );
//                           });
//                         }
//                         return Container();
//                       },
//                     ),

//                     const SizedBox(
//                       height: 12,
//                     ),

//                     BlocBuilder<TireBloc, TireState>(
//                       builder: (context, state) {
//                         if (state is TireLoadingState) {}

//                         if (state is TiresLoadedState) {
//                           return Row(
//                             children: [
//                               Expanded(
//                                 child: ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.arrow_left),
//                                       const SizedBox(width: 6),
//                                       Text(
//                                         'Previous',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                     ],
//                                   ),
//                                   function: () {
//                                     if (swiperController.index > 0) {
//                                       swiperController.index--;
//                                       swiperController.previous();
//                                     }
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         'Next',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Icon(Icons.arrow_right),
//                                     ],
//                                   ),
//                                   function: () {
//                                     if (swiperController.index <
//                                         state.units.length - 1) {
//                                       swiperController.index++;
//                                       swiperController.next();
//                                     }
//                                   },
//                                 ),
//                               ),
//                             ],
//                           );
//                         }

//                         return Container();
//                       },
//                     ),

//                     const SizedBox(
//                       height: 12,
//                     ),
//                     BlocBuilder<TireBloc, TireState>(
//                       builder: (context, state) {
//                         if (state is TiresLoadedState) {
//                           final tire = state.units;
//                           return ButtonWidget(
//                               name: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.save_alt),
//                                   const SizedBox(
//                                     width: 6,
//                                   ),
//                                   Text(
//                                     'Save',
//                                     style: getWhiteTextStyle(),
//                                   ),
//                                 ],
//                               ),
//                               function: () {
//                                 final id = Uuid();
//                                 isSaved = true;
//                                 final savedTires =
//                                     state.units[swiperController.index];

//                                 // Disimpan di objectbox
//                                 context.read<OutstandingTaskBloc>().add(
//                                     AddOutStandingTaskEvent(
//                                         task: OutstandingTask(
//                                             id: id.v4(),
//                                             idSite: idSite,
//                                             user: auth.currentUser!.email ?? '',
//                                             unit: idUnit.text,
//                                             position: int.parse(
//                                                 savedTires.posisi ?? '0'),
//                                             brand: savedTires.brand ?? '',
//                                             serialNumber:
//                                                 savedTires.unitNumber ?? '',
//                                             tireSize: savedTires.size ?? '',
//                                             condition: checkedCategories
//                                                 .map((category) => category)
//                                                 .toList(),
//                                             tireDamage: selectedTireDamage,
//                                             remarks: remarks,
//                                             rtd: rtd,
//                                             pressure: pressureCtrl.text,
//                                             lastUpdate: DateTime.now()
//                                                 .toIso8601String(),
//                                             isDone: false,
//                                             sn: savedTires.sn ?? '',
//                                             images: listImg)));

//                                 // for (var outStandingTask in box.getAll()) {
//                                 //   log(box.getAll().length.toString());
//                                 //   log('data outstanding (object box) ${outStandingTask.id}');
//                                 // }

//                                 ScaffoldMessenger.of(context)
//                                     .showSnackBar(SnackBar(
//                                         backgroundColor: green00968A,
//                                         content: Text(
//                                           'Succesful Save Data',
//                                           style: getWhiteTextStyle(),
//                                         )));
//                               });
//                         }
//                         return Container();
//                       },
//                     ),
//                     // const SizedBox(
//                     //   height: 12,
//                     // ),
//                     // ButtonWidget(
//                     //     name: Row(
//                     //       mainAxisAlignment: MainAxisAlignment.center,
//                     //       children: [
//                     //         Icon(Icons.send),
//                     //         const SizedBox(
//                     //           width: 6,
//                     //         ),
//                     //         Text(
//                     //           'Send',
//                     //           style: getWhiteTextStyle(),
//                     //         ),
//                     //       ],
//                     //     ),
//                     //     function: () async {
//                     //       // await _notificationHelper
//                     //       //     .showNotification(flutterLocalNotificationsPlugin);
//                     //     }),
//                     const SizedBox(
//                       height: 12,
//                     ),

//                     // Row(
//                     //   children: [
//                     //     Expanded(
//                     //       child: ButtonWidget(
//                     //           name: Row(
//                     //             mainAxisAlignment: MainAxisAlignment.center,
//                     //             children: [
//                     //               Icon(Icons.arrow_left),
//                     //               Text(
//                     //                 'Previous',
//                     //                 style: getWhiteTextStyle(),
//                     //               ),
//                     //             ],
//                     //           ),
//                     //           function: () {
//                     //             setState(() {
//                     //               if (tireIndex > 1) {
//                     //                 tireIndex--;
//                     //               }
//                     //             });
//                     //           }),
//                     //     ),
//                     //     const SizedBox(
//                     //       width: 12,
//                     //     ),
//                     //     Expanded(
//                     //       child: ButtonWidget(
//                     //           name: Row(
//                     //             mainAxisAlignment: MainAxisAlignment.center,
//                     //             children: [
//                     //               Text(
//                     //                 'Next',
//                     //                 style: getWhiteTextStyle(),
//                     //               ),
//                     //               Icon(Icons.arrow_right),
//                     //             ],
//                     //           ),
//                     //           function: () {
//                     //             setState(() {
//                     //               tireIndex++;
//                     //             });
//                     //           }),
//                     //     ),
//                     //   ],
//                     // ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         )),
//       ),
//     );
//   }
// }

// FLUTTER BLUE PLUS

// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';

// import 'package:app_settings/app_settings.dart';
// import 'package:camos/core/blocs/outstanding_task/outstanding_task_bloc.dart';
// import 'package:camos/core/blocs/tire/tire_bloc.dart';
// import 'package:camos/core/blocs/unit/unit_bloc.dart';
// import 'package:camos/core/navigator/navigation_route.dart';
// import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
// import 'package:camos/core/services/model/outstanding_task.dart';
// import 'package:camos/core/services/model/unit_tire.dart';
// import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
// import 'package:camos/core/styles/asset_path.dart';
// import 'package:camos/core/styles/color.dart';
// import 'package:camos/core/styles/text_manager.dart';
// import 'package:camos/core/utils/data/oustanding_task.dart';
// import 'package:camos/core/utils/data/pgd.dart';
// import 'package:camos/core/utils/functions/functions.dart';
// import 'package:camos/core/widgets/appbar_widget.dart';
// import 'package:camos/core/widgets/button_widget.dart';
// import 'package:camos/core/widgets/input_form_widget.dart';
// import 'package:camos/core/widgets/pgd_tire_card_widget.dart';
// import 'package:camos/main.dart';
// import 'package:camos/objectbox.g.dart';
// import 'package:camos/pages/home/home_page.dart';
// import 'package:card_swiper/card_swiper.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';

// class TireInspectionFormPage extends StatefulWidget {
//   static const routeName = '/pgd-page';
//   const TireInspectionFormPage({super.key});

//   @override
//   State<TireInspectionFormPage> createState() => _TireInspectionFormPageState();
// }

// class _TireInspectionFormPageState extends State<TireInspectionFormPage> with WidgetsBindingObserver {
//   // bluetooth
//   // FlutterBluePlus flutterBlue = FlutterBluePlus.
//   List<ScanResult> devices = [];

//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth auth = FirebaseAuth.instance;

//   var map = {};
//   String idSite = '';
//   bool isSaved = false;
//   Map<String, dynamic> dataUnit = {};

//   final Box<OutstandingTaskEntity> box = store.box<OutstandingTaskEntity>();

//   TextEditingController idUnit = TextEditingController(text: '');
//   TextEditingController hmUnit = TextEditingController(text: '');
//   TextEditingController pressureCtrl = TextEditingController(text: '');
//   TextEditingController remarksCtrl = TextEditingController(text: '');
//   SwiperController swiperController = SwiperController();

//   String selectedUnit = '';
//   List<String> checkedCategories = [];
//   String selectedTireDamage = '';
//   String remarks = '';
//   String rtd = '';
//   List<String> listImg = [];
//   bool isScanning = false;

//   List<String> categories = [
//     'Reseal Oring',
//     'Rim Condition',
//     'Inflate Tire',
//     'Lock Driver',
//     'Slide Lock',
//     'Valve Cap',
//     'Valve Protector',
//     'Stud and Nut',
//   ];

//   bool isConnected = false;

//   @override
//   void initState() {
//     super.initState();
//     requestPlacePermission();

//     callTires();
//     WidgetsBinding.instance.addObserver(this);
//   }

//   checkBluetooth() {
//     var subscription =
//         FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
//       print(state);
//       if (state == BluetoothAdapterState.on) {
//         startBluetoothScan();
//       } else {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//           content: Text(
//             'Please Turn ON Bluetooth',
//             style: getWhiteTextStyle(),
//           ),
//           backgroundColor: Colors.red,
//         ));
//       }
//     });
//   }

//   stopBluetoothScan() {
//     FlutterBluePlus.stopScan();
//   }

//   startBluetoothScan() async {
//     if (mounted)
//       setState(() {
//         isScanning = true;
//       });
//     await FlutterBluePlus.startScan(
//       timeout: Duration(seconds: 5),
//     );
//     await Future.delayed(Duration(seconds: 5));
//     setState(() {
//       isScanning = false;
//     });

//     var subscription = FlutterBluePlus.onScanResults.listen(
//       (results) {
//         devices.clear();
//         ScanResult r = results.last; // the most recently found device
//         log('hp terdaftar : ${r.device}');
//         log('${r.device.remoteId}: "${r.advertisementData.advName}" found!');
//         devices.addAll(results);
//         // setState(() {});
//       },
//       onError: (e) => print(e),
//     );
//   }

//   void connectToDevice(BluetoothDevice device) async {
//     try {
//       devices.removeWhere((e) => e.device != device);
//       await device.connect();
//       List<BluetoothService> services = await device.discoverServices();
//       services.forEach((service) {
//         print("service level is ${service.uuid.toString()} %");
//         if (service.uuid.toString() == service.uuid.toString()) {
//           log('karakteristik');
//           List<BluetoothCharacteristic> characteristics =
//               service.characteristics;
//           characteristics.forEach((characteristic) async {
//             List<int> value = await characteristic.read();
//             log('karakteristiknya $value');

// // Ubah List<int> menjadi String menggunakan UTF-8 encoding
//             String jsonString = utf8.decode(value);
//             log('string json $jsonString');

// // // Parse JSON string menjadi Map
//             // try {
//             //   Map<String, dynamic> data = json.decode(jsonString);
//             //   log('data json $data');
//             // } catch (e) {
//             //   log('error karakteristik : $e');
//             // }

// // // Akses nilai tekanan
// //             int pressure = data['pressure'];
// //             print('pressurenya adalah $pressure');
//             // if (characteristic.uuid.toString() ==
//             //     "4fafc201-1fb5-459e-8fcc-c5c9c331914b") {
//             //   characteristic.read().then((value) {
//             //     int batteryLevel = value[0];
//             //     print("Battery level is $batteryLevel %");
//             //   });
//             // }
//           });
//         } else {
//           log('bukan karakteristik');
//         }
//       });
//       setState(() {});
//       print('Connected to ${device.name}');
//     } catch (e) {
//       print('Error while connecting to device: $e');
//     }
//   }

//   void disconnectDevice(BluetoothDevice device) async {
//     try {
//       await device.disconnect();
//       devices.clear();
//       setState(() {});
//       print('Disconnected from ${device.name}');
//     } catch (e) {
//       print('Error while disconnecting from device: $e');
//     }
//   }

//   //  void discoverServices(BluetoothDevice device) async {
//   //   List<BluetoothService> services = await device.discoverServices();
//   //   services.forEach((service) {
//   //     print('Service found: ${service.uuid}');
//   //     service.characteristics.forEach((characteristic) {
//   //       print('Characteristic found: ${characteristic.uuid}');
//   //       // Periksa apakah UUID sesuai dengan karakteristik perangkat IoT Anda, jika iya, lakukan langganan
//   //       if (characteristic.uuid == Guid('KarakteristikUUIDPerangkatIoT')) {
//   //         characteristic.setNotifyValue(true);
//   //         characteristic.value.listen((value) {
//   //           // Lakukan sesuatu dengan data yang diterima dari perangkat IoT
//   //           String receivedData = String.fromCharCodes(value);
//   //           print('Received data: $receivedData');
//   //           // Di sini Anda dapat melakukan apa pun dengan data yang diterima, misalnya memperbarui UI, dll.
//   //         });
//   //       }
//   //     });
//   //   });
//   // }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);
//     super.dispose();
//   }

//   String tmpPressure = '';

//   void handleDataChecked(List<bool> checkedList, int index) {
//     checkedCategories.clear();

//     for (int i = 0; i < checkedList.length; i++) {
//       if (checkedList[i] == true) {
//         // setState(() {
//         checkedCategories.add(categories[i]);
//         // });
//       }
//     }

//     // Cetak hasil untuk tujuan pengujian
//   }

//   void handleDataSelected(String tireDamage, int index) {
//     // Perbarui data tire damage
//     selectedTireDamage = tireDamage;
//   }

//   void handleImageTire(List<String> images) {
//     listImg.clear();
//     listImg.addAll(images);
//   }

//   void callTires() async {
//     idSite = await getIdSitePreferences();
//     if (idSite == '1') {
//       idSite = await getSelectedIdSitePreferences();
//     }
//     if (mounted) {
//       if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
//         idUnit.text = dataUnit['unitNumber'];
//         hmUnit.text = dataUnit['hm'];
//         context.read<TireBloc>().add(GetUnitTiresEvent(
//             idSite: idSite, unitNumber: dataUnit['unitNumber']));
//       }
//     }
//   }

//   void handleDataRemarks(String remarks, int index) {
//     this.remarks = remarks;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   void handleDataRTD(String rtd, int index) {
//     this.rtd = rtd;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   @override
//   Widget build(BuildContext context) {
//     print('dipanggil (pgd)');
//     dataUnit =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

//     return WillPopScope(
//       onWillPop: () async {
//         if (isSaved) {
//           devices.clear();
//           stopBluetoothScan();
//           pushReplace(context, HomePage.routeName);
//         } else {
//           devices.clear();
//           stopBluetoothScan();
//           back(context);
//         }
//         return false;
//       },
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           title: Padding(
//             padding: const EdgeInsets.only(top: 18.0),
//             child: Text(
//               'Tire Inspection',
//               textAlign: TextAlign.center,
//               style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
//             ),
//           ),
//           centerTitle: true,
//           leading: Padding(
//             padding: const EdgeInsets.only(left: 16),
//             child: Container(
//               margin: const EdgeInsets.only(top: 14),
//               padding: const EdgeInsets.symmetric(horizontal: 4),
//               decoration: BoxDecoration(
//                 color: white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: black),
//               ),
//               child: IconButton(
//                   onPressed: () {
//                     if (isSaved) {
//                       devices.forEach((e) {
//                         disconnectDevice(e.device);
//                       });
//                       devices.clear();

//                       stopBluetoothScan();
//                       pushReplace(context, HomePage.routeName);
//                     } else {
//                       devices.forEach((e) {
//                         disconnectDevice(e.device);
//                       });
//                       devices.clear();
//                       stopBluetoothScan();
//                       back(context);
//                     }
//                   },
//                   icon: const Icon(
//                     Icons.arrow_back_ios,
//                     color: black,
//                     size: 24,
//                   )),
//             ),
//           ),
//         ),
//         body: SafeArea(child: BlocBuilder<TireBloc, TireState>(
//           builder: (context, state) {
//             return SingleChildScrollView(
//               primary: false,
//               physics: BouncingScrollPhysics(),
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               Text(
//                                 'Unit Number',
//                                 style: getBlackTextStyle(fontWeight: w700),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                     isReadOnly: true,
//                                     controller: idUnit,
//                                     hint: ''),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(
//                           width: 12,
//                         ),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.stretch,
//                             children: [
//                               Text(
//                                 'HM Unit',
//                                 style: getBlackTextStyle(fontWeight: w700),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                     isReadOnly: true,
//                                     controller: hmUnit,
//                                     hint: 'Insert HM Unit'),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(
//                           width: 12,
//                         ),
//                         // SizedBox(
//                         //   height: 200,
//                         //   width: 100,
//                         //   child: ButtonWidget(
//                         //       name: Row(
//                         //         mainAxisAlignment: MainAxisAlignment.center,
//                         //         children: [
//                         //           Icon(Icons.restore),
//                         //           const SizedBox(
//                         //             width: 6,
//                         //           ),
//                         //           Text(
//                         //             'Reset',
//                         //             style: getWhiteTextStyle(),
//                         //           ),
//                         //         ],
//                         //       ),
//                         //       function: () {
//                         //         idUnit.clear();
//                         //         hmUnit.clear();
//                         //         setState(() {});
//                         //       }),
//                         // ),
//                       ],
//                     ),
//                     Padding(
//                       padding: const EdgeInsets.symmetric(vertical: 12.0),
//                       child: Divider(
//                         thickness: 1.2,
//                       ),
//                     ),
//                     Text(
//                       'Bluetooth Connection',
//                       style: getBlackTextStyle(
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     ButtonWidget(
//                         name: (!isScanning)
//                             ? Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.bluetooth),
//                                   const SizedBox(
//                                     width: 6,
//                                   ),
//                                   (isScanning)
//                                       ? Text(
//                                           'Scan Devices',
//                                           style: getWhiteTextStyle(),
//                                         )
//                                       : Text(
//                                           'Scan Devices',
//                                           style: getWhiteTextStyle(),
//                                         )
//                                 ],
//                               )
//                             : CircularProgressIndicator(),
//                         function: () async {
//                           setState(() {});
//                           devices.clear();
//                           requestBluetoothPermission();
//                           checkBluetooth();
//                           // AppSettings.openBluetoothSettings();
//                         }),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Column(
//                       children: devices.map((device) {
//                         if (device.device.name == '') {
//                           return Container();
//                         }
//                         return ListTile(
//                           title: Text(
//                             device.device.name,
//                             style: getBlackTextStyle(),
//                           ),
//                           // subtitle: Text(
//                           //   device.address,
//                           //   style: getGreyTextStyle(grey6A707C),
//                           // ),
//                           trailing: SizedBox(
//                               width: 110,
//                               height: 50,
//                               child: ButtonWidget(
//                                   name: Text(
//                                     (isConnected) ? 'Disconnect' : 'Connect',
//                                     style: getWhiteTextStyle(),
//                                   ),
//                                   function: () async {
//                                     if (isConnected) {
//                                       isConnected = false;
//                                       disconnectDevice(device.device);
//                                       setState(() {});
//                                     } else {
//                                       isConnected = true;
//                                       connectToDevice(device.device);
//                                       setState(() {});
//                                     }
//                                   })),
//                         );
//                       }).toList(),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),

//                     (tmpPressure == '')
//                         ? Container()
//                         : Column(
//                             children: [
//                               SizedBox(
//                                 width: MediaQuery.of(context).size.width * 0.25,
//                                 child: InputFormWidget(
//                                   isReadOnly: true,
//                                   controller:
//                                       TextEditingController(text: tmpPressure),
//                                   hint: '',
//                                 ),
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                             ],
//                           ),
//                     // TIRE
//                     BlocBuilder<TireBloc, TireState>(
//                       builder: (context, state) {
//                         if (state is TireLoadingState) {
//                           return CircularProgressIndicator();
//                         }

//                         if (state is TiresLoadedState) {
//                           return LayoutBuilder(builder: (context, constraints) {
//                             return Container(
//                               height: constraints.maxWidth * 3.4,
//                               child: Swiper(
//                                 controller: swiperController,
//                                 loop: false,
//                                 physics: NeverScrollableScrollPhysics(),
//                                 scrollDirection: Axis.horizontal,
//                                 itemCount: state.units.length,
//                                 itemBuilder: (context, index) {
//                                   return PgdTireCardWidget(
//                                     dataTire: state.units[index],
//                                     onCategoryChecked: (checkedList) {
//                                       handleDataChecked(checkedList, index);
//                                     },
//                                     onSelectedTireDamage: (tireDamage) {
//                                       handleDataSelected(tireDamage, index);
//                                     },
//                                     onStringRemarks: (remarks) {
//                                       handleDataRemarks(remarks, index);
//                                     },
//                                     onStringRTD: (rtd) {
//                                       handleDataRTD(rtd, index);
//                                     },
//                                     onImageTire: (images) {
//                                       handleImageTire(images);
//                                     },
//                                   );
//                                 },
//                               ),
//                             );
//                           });
//                         }
//                         return Container();
//                       },
//                     ),

//                     const SizedBox(
//                       height: 12,
//                     ),

//                     Text(
//                       'Pressure',
//                       style: getBlackTextStyle(),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Column(
//                       children: [
//                         SizedBox(
//                           width: MediaQuery.of(context).size.width,
//                           child: InputFormWidget(
//                             isDecimalOnly: true,
//                             type: const TextInputType.numberWithOptions(
//                                 decimal: true),
//                             controller: pressureCtrl,
//                             hint: '',
//                           ),
//                         ),
//                         const SizedBox(
//                           height: 12,
//                         ),
//                       ],
//                     ),

//                     BlocBuilder<TireBloc, TireState>(
//                       builder: (context, state) {
//                         if (state is TireLoadingState) {}

//                         if (state is TiresLoadedState) {
//                           return Row(
//                             children: [
//                               Expanded(
//                                 child: ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(Icons.arrow_left),
//                                       const SizedBox(width: 6),
//                                       Text(
//                                         'Previous',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                     ],
//                                   ),
//                                   function: () {
//                                     pressureCtrl.clear();
//                                     if (swiperController.index > 0) {
//                                       swiperController.index--;
//                                       swiperController.previous();
//                                     }
//                                   },
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: ButtonWidget(
//                                   name: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Text(
//                                         'Next',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                       const SizedBox(width: 6),
//                                       Icon(Icons.arrow_right),
//                                     ],
//                                   ),
//                                   function: () {
//                                     pressureCtrl.clear();
//                                     if (swiperController.index <
//                                         state.units.length - 1) {
//                                       swiperController.index++;
//                                       swiperController.next();
//                                     }
//                                   },
//                                 ),
//                               ),
//                             ],
//                           );
//                         }

//                         return Container();
//                       },
//                     ),

//                     const SizedBox(
//                       height: 12,
//                     ),
//                     BlocBuilder<TireBloc, TireState>(
//                       builder: (context, state) {
//                         if (state is TiresLoadedState) {
//                           final tire = state.units;
//                           return ButtonWidget(
//                               name: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(Icons.save_alt),
//                                   const SizedBox(
//                                     width: 6,
//                                   ),
//                                   Text(
//                                     'Save',
//                                     style: getWhiteTextStyle(),
//                                   ),
//                                 ],
//                               ),
//                               function: () {
//                                 final id = Uuid();
//                                 isSaved = true;
//                                 final savedTires =
//                                     state.units[swiperController.index];

//                                 // Disimpan di objectbox
//                                 context.read<OutstandingTaskBloc>().add(
//                                     AddOutStandingTaskEvent(
//                                         task: OutstandingTask(
//                                             id: id.v4(),
//                                             idSite: idSite,
//                                             user: auth.currentUser!.email ?? '',
//                                             unit: idUnit.text,
//                                             position: int.parse(
//                                                 savedTires.posisi ?? '0'),
//                                             brand: savedTires.brand ?? '',
//                                             serialNumber:
//                                                 savedTires.unitNumber ?? '',
//                                             tireSize: savedTires.size ?? '',
//                                             condition: checkedCategories
//                                                 .map((category) => category)
//                                                 .toList(),
//                                             tireDamage: selectedTireDamage,
//                                             remarks: remarks,
//                                             rtd: rtd,
//                                             pressure: pressureCtrl.text,
//                                             lastUpdate: DateTime.now()
//                                                 .toIso8601String(),
//                                             isDone: false,
//                                             sn: savedTires.sn ?? '',
//                                             kunciUnit:
//                                                 savedTires.kunciTire ?? '',
//                                             kunciTire:
//                                                 savedTires.kunciTire ?? '',
//                                             images: listImg)));

//                                 // for (var outStandingTask in box.getAll()) {
//                                 //   log(box.getAll().length.toString());
//                                 //   log('data outstanding (object box) ${outStandingTask.id}');
//                                 // }

//                                 ScaffoldMessenger.of(context)
//                                     .showSnackBar(SnackBar(
//                                         backgroundColor: green00968A,
//                                         content: Text(
//                                           'Succesful Save Data',
//                                           style: getWhiteTextStyle(),
//                                         )));
//                               });
//                         }
//                         return Container();
//                       },
//                     ),
//                     // const SizedBox(
//                     //   height: 12,
//                     // ),
//                     // ButtonWidget(
//                     //     name: Row(
//                     //       mainAxisAlignment: MainAxisAlignment.center,
//                     //       children: [
//                     //         Icon(Icons.send),
//                     //         const SizedBox(
//                     //           width: 6,
//                     //         ),
//                     //         Text(
//                     //           'Send',
//                     //           style: getWhiteTextStyle(),
//                     //         ),
//                     //       ],
//                     //     ),
//                     //     function: () async {
//                     //       // await _notificationHelper
//                     //       //     .showNotification(flutterLocalNotificationsPlugin);
//                     //     }),
//                     const SizedBox(
//                       height: 12,
//                     ),

//                     // Row(
//                     //   children: [
//                     //     Expanded(
//                     //       child: ButtonWidget(
//                     //           name: Row(
//                     //             mainAxisAlignment: MainAxisAlignment.center,
//                     //             children: [
//                     //               Icon(Icons.arrow_left),
//                     //               Text(
//                     //                 'Previous',
//                     //                 style: getWhiteTextStyle(),
//                     //               ),
//                     //             ],
//                     //           ),
//                     //           function: () {
//                     //             setState(() {
//                     //               if (tireIndex > 1) {
//                     //                 tireIndex--;
//                     //               }
//                     //             });
//                     //           }),
//                     //     ),
//                     //     const SizedBox(
//                     //       width: 12,
//                     //     ),
//                     //     Expanded(
//                     //       child: ButtonWidget(
//                     //           name: Row(
//                     //             mainAxisAlignment: MainAxisAlignment.center,
//                     //             children: [
//                     //               Text(
//                     //                 'Next',
//                     //                 style: getWhiteTextStyle(),
//                     //               ),
//                     //               Icon(Icons.arrow_right),
//                     //             ],
//                     //           ),
//                     //           function: () {
//                     //             setState(() {
//                     //               tireIndex++;
//                     //             });
//                     //           }),
//                     //     ),
//                     //   ],
//                     // ),
//                   ],
//                 ),
//               ),
//             );
//           },
//         )),
//       ),
//     );
//   }
// }
