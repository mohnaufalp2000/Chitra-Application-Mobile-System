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

// class PgdPage extends StatefulWidget {
//   static const routeName = '/pgd-page';
//   const PgdPage({super.key});

//   @override
//   State<PgdPage> createState() => _PgdPageState();
// }

// class _PgdPageState extends State<PgdPage> with WidgetsBindingObserver {
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

// import 'dart:developer';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:app_settings/app_settings.dart';
// import 'package:camos/core/blocs/outstanding_task/outstanding_task_bloc.dart';
// import 'package:camos/core/blocs/tire/tire_bloc.dart';
// import 'package:camos/core/blocs/unit/unit_bloc.dart';
// import 'package:camos/core/navigator/navigation_route.dart';
// import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
// import 'package:camos/core/services/local_database/tire_inspect_picture/tire_inspect_picture_entity.dart';
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

// class PgdPage extends StatefulWidget {
//   static const routeName = '/pgd-page';
//   const PgdPage({super.key});

//   @override
//   State<PgdPage> createState() => _PgdPageState();
// }

// class _PgdPageState extends State<PgdPage> with WidgetsBindingObserver {
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

//   FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;
//   BluetoothConnection? connection;
//   bool get isConnected => connection != null && connection!.isConnected;

//   List<BluetoothDevice> devices = [];
//   String tmpPressure = '';
//   final Box<TireInspectPictureEntity> imageBox =
//       store.box<TireInspectPictureEntity>();

//   startScanBluetooth() async {
//     bluetoothSerial.startDiscovery().listen((device) {
//       if (!devices.contains(device.device)) {
//         log('device yg tersedia ' + device.device.toString());
//         setState(() {
//           devices.add(device.device);
//         });
//       }
//     }, onDone: () {
//       setState(() {});
//     });
//   }

//   stopScanBluetooth() async {
//     bluetoothSerial.cancelDiscovery();
//   }

//   // mendapatkan nilai pressure
//   void _listenForData() {
//     connection!.input!.listen((data) {
//       String receivedData = String.fromCharCodes(data).trim();
//       log('data json : $receivedData');
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
//           connection!.close();
//           stopScanBluetooth();
//           pushReplace(context, HomePage.routeName);
//         } else {
//           connection!.close();
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
//                       if (connection != null) {
//                         connection?.close();
//                       }
//                       stopScanBluetooth();
//                       pushReplace(context, HomePage.routeName);
//                     } else {
//                       if (connection != null) {
//                         connection?.close();
//                       }
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
//                           requestBluetoothPermission();
//                           startScanBluetooth();
//                           devices.clear();
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
//                                 final fixId = id.v4();
//                                 isSaved = true;
//                                 final savedTires =
//                                     state.units[swiperController.index];

//                                 imageBox.put(TireInspectPictureEntity(
//                                     idImage: fixId, image: ''));

//                                 // Disimpan di objectbox
//                                 context
//                                     .read<OutstandingTaskBloc>()
//                                     .add(AddOutStandingTaskEvent(
//                                         task: OutstandingTask(
//                                       id: id.v4(),
//                                       idSite: idSite,
//                                       user: auth.currentUser!.email ?? '',
//                                       unit: idUnit.text,
//                                       position:
//                                           int.parse(savedTires.posisi ?? '0'),
//                                       brand: savedTires.brand ?? '',
//                                       serialNumber: savedTires.sn ?? '',
//                                       tireSize: savedTires.size ?? '',
//                                       condition: checkedCategories
//                                           .map((category) => category)
//                                           .toList(),
//                                       tireDamage: selectedTireDamage,
//                                       remarks: remarks,
//                                       rtd: rtd,
//                                       pressure: pressureCtrl.text,
//                                       lastUpdate:
//                                           DateTime.now().toIso8601String(),
//                                       isDone: false,
//                                       sn: savedTires.sn ?? '',
//                                       images:
//                                           (Platform.isAndroid) ? listImg : [],
//                                       kunciUnit: savedTires.kunciUnit ?? '',
//                                       kunciTire: savedTires.kunciTire ?? '',
//                                     )));

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

// class PgdPage extends StatefulWidget {
//   static const routeName = '/pgd-page';
//   const PgdPage({super.key});

//   @override
//   State<PgdPage> createState() => _PgdPageState();
// }

// class _PgdPageState extends State<PgdPage> with WidgetsBindingObserver {
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

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:camos/core/blocs/outstanding_task/outstanding_task_bloc.dart';
import 'package:camos/core/blocs/tire/tire_bloc.dart';
import 'package:camos/core/blocs/unit/unit_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
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
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class PgdPage extends StatefulWidget {
  static const routeName = '/pgd-page';
  const PgdPage({super.key});

  @override
  State<PgdPage> createState() => _PgdPageState();
}

class _PgdPageState extends State<PgdPage> with WidgetsBindingObserver {
  // bluetooth
  // FlutterBluePlus flutterBlue = FlutterBluePlus.
  List<ScanResult> devices = [];

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  var map = {};
  String idSite = '';
  bool isSaved = false;
  Map<String, dynamic> dataUnit = {};

  final Box<OutstandingTaskEntity> box = store.box<OutstandingTaskEntity>();

  TextEditingController idUnit = TextEditingController(text: '');
  TextEditingController hmUnit = TextEditingController(text: '');
  TextEditingController pressureCtrl = TextEditingController(text: '');
  TextEditingController remarksCtrl = TextEditingController(text: '');
  SwiperController swiperController = SwiperController();

  String selectedUnit = '';
  List<String> checkedCategories = [];
  String selectedTireDamage = '';
  String remarks = '';
  String rtd = '';
  List<String> listImg = [];
  bool isScanning = false;

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

  bool isConnected = false;

  @override
  void initState() {
    super.initState();
    requestPlacePermission();

    callTires();
    WidgetsBinding.instance.addObserver(this);
  }

  checkBluetooth() {
    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
      if (state == BluetoothAdapterState.on) {
        startBluetoothScan();
      } else {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Please Turn ON Bluetooth',
            style: getWhiteTextStyle(),
          ),
          backgroundColor: Colors.red,
        ));
      }
    });
  }

  stopBluetoothScan() {
    FlutterBluePlus.stopScan();
  }

  startBluetoothScan() async {
    if (mounted)
      setState(() {
        isScanning = true;
      });
    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: 5),
    );
    await Future.delayed(Duration(seconds: 5));
    setState(() {
      isScanning = false;
    });

    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        devices.clear();
        ScanResult r = results.last; // the most recently found device
        log('hp terdaftar : ${r.device}');
        log('${r.device.remoteId}: "${r.advertisementData.advName}" found!');
        devices.addAll(results);
        // setState(() {});
      },
      onError: (e) => print(e),
    );
  }

  void connectToDevice(BluetoothDevice device) async {
    try {
      devices.removeWhere((e) => e.device != device);
      await device.connect();
      List<BluetoothService> services = await device.discoverServices();
      services.forEach((service) {
        print("service level is ${service.uuid.toString()} %");
        if (service.uuid.toString() == service.uuid.toString()) {
          log('karakteristik');
          List<BluetoothCharacteristic> characteristics =
              service.characteristics;
          characteristics.forEach((characteristic) async {
            List<int> value = await characteristic.read();
            log('karakteristiknya $value');

// Ubah List<int> menjadi String menggunakan UTF-8 encoding
            String jsonString = utf8.decode(value);
            log('string json $jsonString');

// // Parse JSON string menjadi Map
            // try {
            //   Map<String, dynamic> data = json.decode(jsonString);
            //   log('data json $data');
            // } catch (e) {
            //   log('error karakteristik : $e');
            // }

// // Akses nilai tekanan
//             int pressure = data['pressure'];
//             print('pressurenya adalah $pressure');
            // if (characteristic.uuid.toString() ==
            //     "4fafc201-1fb5-459e-8fcc-c5c9c331914b") {
            //   characteristic.read().then((value) {
            //     int batteryLevel = value[0];
            //     print("Battery level is $batteryLevel %");
            //   });
            // }
          });
        } else {
          log('bukan karakteristik');
        }
      });
      setState(() {});
      print('Connected to ${device.name}');
    } catch (e) {
      print('Error while connecting to device: $e');
    }
  }

  void disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
      devices.clear();
      setState(() {});
      print('Disconnected from ${device.name}');
    } catch (e) {
      print('Error while disconnecting from device: $e');
    }
  }

  //  void discoverServices(BluetoothDevice device) async {
  //   List<BluetoothService> services = await device.discoverServices();
  //   services.forEach((service) {
  //     print('Service found: ${service.uuid}');
  //     service.characteristics.forEach((characteristic) {
  //       print('Characteristic found: ${characteristic.uuid}');
  //       // Periksa apakah UUID sesuai dengan karakteristik perangkat IoT Anda, jika iya, lakukan langganan
  //       if (characteristic.uuid == Guid('KarakteristikUUIDPerangkatIoT')) {
  //         characteristic.setNotifyValue(true);
  //         characteristic.value.listen((value) {
  //           // Lakukan sesuatu dengan data yang diterima dari perangkat IoT
  //           String receivedData = String.fromCharCodes(value);
  //           print('Received data: $receivedData');
  //           // Di sini Anda dapat melakukan apa pun dengan data yang diterima, misalnya memperbarui UI, dll.
  //         });
  //       }
  //     });
  //   });
  // }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String tmpPressure = '';

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
        hmUnit.text = dataUnit['hm'];
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
          devices.clear();
          stopBluetoothScan();
          pushReplace(context, HomePage.routeName);
        } else {
          devices.clear();
          stopBluetoothScan();
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
              'Pressure Gauge Digital',
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
                      devices.forEach((e) {
                        disconnectDevice(e.device);
                      });
                      devices.clear();

                      stopBluetoothScan();
                      pushReplace(context, HomePage.routeName);
                    } else {
                      devices.forEach((e) {
                        disconnectDevice(e.device);
                      });
                      devices.clear();
                      stopBluetoothScan();
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
        body: SafeArea(child: BlocBuilder<TireBloc, TireState>(
          builder: (context, state) {
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
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
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
                                    isReadOnly: true,
                                    controller: hmUnit,
                                    hint: 'Insert HM Unit'),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        // SizedBox(
                        //   height: 200,
                        //   width: 100,
                        //   child: ButtonWidget(
                        //       name: Row(
                        //         mainAxisAlignment: MainAxisAlignment.center,
                        //         children: [
                        //           Icon(Icons.restore),
                        //           const SizedBox(
                        //             width: 6,
                        //           ),
                        //           Text(
                        //             'Reset',
                        //             style: getWhiteTextStyle(),
                        //           ),
                        //         ],
                        //       ),
                        //       function: () {
                        //         idUnit.clear();
                        //         hmUnit.clear();
                        //         setState(() {});
                        //       }),
                        // ),
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
                        name: (!isScanning)
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bluetooth),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  (isScanning)
                                      ? Text(
                                          'Scan Devices',
                                          style: getWhiteTextStyle(),
                                        )
                                      : Text(
                                          'Scan Devices',
                                          style: getWhiteTextStyle(),
                                        )
                                ],
                              )
                            : CircularProgressIndicator(),
                        function: () async {
                          setState(() {});
                          devices.clear();
                          requestBluetoothPermission();
                          checkBluetooth();
                          // AppSettings.openBluetoothSettings();
                        }),
                    const SizedBox(
                      height: 12,
                    ),
                    Column(
                      children: devices.map((device) {
                        if (device.device.name == '') {
                          return Container();
                        }
                        return ListTile(
                          title: Text(
                            device.device.name,
                            style: getBlackTextStyle(),
                          ),
                          // subtitle: Text(
                          //   device.address,
                          //   style: getGreyTextStyle(grey6A707C),
                          // ),
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
                                      isConnected = false;
                                      disconnectDevice(device.device);
                                      setState(() {});
                                    } else {
                                      isConnected = true;
                                      connectToDevice(device.device);
                                      setState(() {});
                                    }
                                  })),
                        );
                      }).toList(),
                    ),
                    const SizedBox(
                      height: 12,
                    ),

                    (tmpPressure == '')
                        ? Container()
                        : Column(
                            children: [
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.25,
                                child: InputFormWidget(
                                  isReadOnly: true,
                                  controller:
                                      TextEditingController(text: tmpPressure),
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
                          return LayoutBuilder(builder: (context, constraints) {
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
                          width: MediaQuery.of(context).size.width,
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

                    BlocBuilder<TireBloc, TireState>(
                      builder: (context, state) {
                        if (state is TireLoadingState) {}

                        if (state is TiresLoadedState) {
                          return Row(
                            children: [
                              Expanded(
                                child: ButtonWidget(
                                  name: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                    pressureCtrl.clear();
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
                                    mainAxisAlignment: MainAxisAlignment.center,
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
                                    pressureCtrl.clear();
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
                    BlocBuilder<TireBloc, TireState>(
                      builder: (context, state) {
                        if (state is TiresLoadedState) {
                          final tire = state.units;
                          return ButtonWidget(
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
                              function: () {
                                final id = Uuid();
                                isSaved = true;
                                final savedTires =
                                    state.units[swiperController.index];

                                // Disimpan di objectbox
                                context.read<OutstandingTaskBloc>().add(
                                    AddOutStandingTaskEvent(
                                        task: OutstandingTask(
                                            id: id.v4(),
                                            idSite: idSite,
                                            user: auth.currentUser!.email ?? '',
                                            unit: idUnit.text,
                                            position: int.parse(
                                                savedTires.posisi ?? '0'),
                                            brand: savedTires.brand ?? '',
                                            serialNumber:
                                                savedTires.unitNumber ?? '',
                                            tireSize: savedTires.size ?? '',
                                            condition: checkedCategories
                                                .map((category) => category)
                                                .toList(),
                                            tireDamage: selectedTireDamage,
                                            remarks: remarks,
                                            rtd: rtd,
                                            pressure: pressureCtrl.text,
                                            lastUpdate: DateTime.now()
                                                .toIso8601String(),
                                            isDone: false,
                                            sn: savedTires.sn ?? '',
                                            kunciUnit:
                                                savedTires.kunciTire ?? '',
                                            kunciTire:
                                                savedTires.kunciTire ?? '',
                                            images: listImg)));

                                // for (var outStandingTask in box.getAll()) {
                                //   log(box.getAll().length.toString());
                                //   log('data outstanding (object box) ${outStandingTask.id}');
                                // }

                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                        backgroundColor: green00968A,
                                        content: Text(
                                          'Succesful Save Data',
                                          style: getWhiteTextStyle(),
                                        )));
                              });
                        }
                        return Container();
                      },
                    ),
                    // const SizedBox(
                    //   height: 12,
                    // ),
                    // ButtonWidget(
                    //     name: Row(
                    //       mainAxisAlignment: MainAxisAlignment.center,
                    //       children: [
                    //         Icon(Icons.send),
                    //         const SizedBox(
                    //           width: 6,
                    //         ),
                    //         Text(
                    //           'Send',
                    //           style: getWhiteTextStyle(),
                    //         ),
                    //       ],
                    //     ),
                    //     function: () async {
                    //       // await _notificationHelper
                    //       //     .showNotification(flutterLocalNotificationsPlugin);
                    //     }),
                    const SizedBox(
                      height: 12,
                    ),

                    // Row(
                    //   children: [
                    //     Expanded(
                    //       child: ButtonWidget(
                    //           name: Row(
                    //             mainAxisAlignment: MainAxisAlignment.center,
                    //             children: [
                    //               Icon(Icons.arrow_left),
                    //               Text(
                    //                 'Previous',
                    //                 style: getWhiteTextStyle(),
                    //               ),
                    //             ],
                    //           ),
                    //           function: () {
                    //             setState(() {
                    //               if (tireIndex > 1) {
                    //                 tireIndex--;
                    //               }
                    //             });
                    //           }),
                    //     ),
                    //     const SizedBox(
                    //       width: 12,
                    //     ),
                    //     Expanded(
                    //       child: ButtonWidget(
                    //           name: Row(
                    //             mainAxisAlignment: MainAxisAlignment.center,
                    //             children: [
                    //               Text(
                    //                 'Next',
                    //                 style: getWhiteTextStyle(),
                    //               ),
                    //               Icon(Icons.arrow_right),
                    //             ],
                    //           ),
                    //           function: () {
                    //             setState(() {
                    //               tireIndex++;
                    //             });
                    //           }),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            );
          },
        )),
      ),
    );
  }
}
