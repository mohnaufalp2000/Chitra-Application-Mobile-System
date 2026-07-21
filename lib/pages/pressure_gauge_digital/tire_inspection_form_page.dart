// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:app_settings/app_settings.dart';
// import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
// import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
// import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
// import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart'
//     as connectedDevicesState;
// import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart';
// import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_cubit.dart';
// import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_state.dart';
// import 'package:camos/core/services/api_service.dart';
// import 'package:camos/core/services/model/tire_damage_ai.dart';
// import 'package:camos/core/utils/bluetooth/utils/bluetooth_utils.dart';
// import 'package:camos/core/utils/data/id_site.dart';
// import 'package:camos/pages/home/home_state.dart';
// import 'package:camos/pages/pressure_gauge_digital/trial/scan_device_page.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/bounding_box_painter.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/upload_queue_service.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:get/get.dart';
// import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
// import 'package:path_provider/path_provider.dart';
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
// import 'package:carousel_slider/carousel_controller.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';

// import 'widget/ai_loading_widget.dart';

// class TireInspectionFormPage extends StatefulWidget {
//   static const routeName = '/pgd-page';
//   const TireInspectionFormPage({super.key});

//   @override
//   State<TireInspectionFormPage> createState() => _TireInspectionFormPageState();
// }

// class _TireInspectionFormPageState extends State<TireInspectionFormPage>
//     with WidgetsBindingObserver {
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth auth = FirebaseAuth.instance;
//   final HomeState homeState = Get.find<HomeState>();

//   bool _isInit = true;
//   int selectedMenu = 1;
//   var map = {};
//   String idSite = '';
//   bool isSaved = false;
//   Map<String, dynamic> dataUnit = {};
//   String? _hmInitializedForUnit;

//   TextEditingController idUnit = TextEditingController(text: '');
//   TextEditingController hmUnit = TextEditingController(text: '');
//   TextEditingController pressureCtrl = TextEditingController(text: '');
//   TextEditingController remarksCtrl = TextEditingController(text: '');
//   TextEditingController damageCtrl = TextEditingController(text: '');
//   TextEditingController rtd1 = TextEditingController(text: '');
//   TextEditingController rtd2 = TextEditingController(text: '');
//   List<TextEditingController> remarksControllers = [];
//   List<TextEditingController> snControllers = [];
//   List<TextEditingController> rtd1Controllers = [];
//   List<TextEditingController> rtd2Controllers = [];

//   SwiperController swiperController = SwiperController();

//   Map<int, TireDamageAi> aiResults = {};
//   Map<int, bool> loadingAI = {};
//   Map<int, double> imageWidths = {};
//   Map<int, double> imageHeights = {};

//   List<String>? _ratingCache;
//   List<dynamic>? _damageCache;

//   String selectedUnit = '';
//   List<String> checkedCategories = [];
//   List<Map<String, dynamic>> checkedCategoriesManual = [
//     {'name': 'Reseal Oring', 'checked': false},
//     {'name': 'Rim Condition', 'checked': false},
//     {'name': 'Inflate Tire', 'checked': false},
//     {'name': 'Lock Driver', 'checked': false},
//     {'name': 'Slide Lock', 'checked': false},
//     {'name': 'Valve Cap', 'checked': false},
//     {'name': 'Valve Protector', 'checked': false},
//     {'name': 'Stud and Nut', 'checked': false},
//   ];

//   List<bool> checkedListCategory = List<bool>.filled(8, false);
//   String selectedTireDamage = '';
//   String remarks = '';
//   String rtd = '';
//   List<String> listImg = [];
//   Map<String, dynamic> user = {};
//   bool _listenerAdded = false;
//   int checkAmount = 0;
//   int selectedRoute = 0;
//   List<List<int>> inspectRoute = [
//     [0, 1, 2, 3, 4, 5],
//     [0, 2, 3, 4, 5, 1],
//     [1, 5, 4, 3, 2, 0],
//   ];

//   List<String> pressure = [
//     '0',
//     '95',
//     '100',
//     '105',
//     '110',
//     '115',
//     '120',
//     '125',
//     '130',
//     '135',
//   ];
//   List<Map<String, dynamic>> position = [];

//   // List<String> damageType = [
//   //   'Good Condition',
//   //   'Accident',
//   //   'Bead Crack',
//   //   'Boulder',
//   //   'Bulging',
//   //   'Bead Damage',
//   //   'Chaffer Separation',
//   //   'Dog Bound',
//   //   'Foreign Object',
//   //   'Heat Separation',
//   //   'Inner Linner Separation',
//   //   'Impact',
//   //   'Repair Failure',
//   //   'Radial Crack',
//   //   'Run Flat',
//   //   'Sidewall Crack',
//   //   'Sidewall Cut',
//   //   'Sidewall Cut 2',
//   //   'Sidewall Cut 3',
//   //   'Sidewall Separation',
//   //   'Shoulder Cut',
//   //   'Shoulder Separation',
//   //   'Tread Chipping',
//   //   'Tread Chunking',
//   //   'Tread Lifting',
//   //   'Tread Cut',
//   //   'Tread Cut Separation',
//   //   'Worn Out',
//   // ];

//   List<Map<String, dynamic>> damageType = [];
//   bool loadingDamages = true;

//   List<String> selectedDamage = [];

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

//   List<String> rating = [
//     'A',
//     'B',
//     'C',
//     'X',
//   ];

//   List<String> pit = [];
//   int selectedPit = -1;

//   void showRimInspectionDialog(int tireIndex) {
//     final originalList = position[tireIndex]['rimCondition'];

//     /// 🔥 COPY DATA DULU (supaya Close tidak menyimpan)
//     List<Map<String, dynamic>> tempList =
//         originalList.map<Map<String, dynamic>>((item) {
//       return {
//         'title': item['title'],
//         'condition': item['condition'],
//         'remark': item['remark'],
//       };
//     }).toList();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, stState) {
//             return AlertDialog(
//               title: Text(
//                 'Periksa Kondisi : ',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: List.generate(tempList.length, (i) {
//                       final rimItem = tempList[i];
//                       final bool isGood = rimItem['condition'] == 'Good';
//                       final bool isPoor = rimItem['condition'] == 'Poor';

//                       return Container(
//                         margin: EdgeInsets.only(bottom: 14),
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: isGood
//                               ? Colors.green.withOpacity(0.12)
//                               : Colors.red.withOpacity(0.12),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             /// TITLE
//                             Text(
//                               rimItem['title'],
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),

//                             SizedBox(height: 10),

//                             /// GOOD / POOR
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       stState(() {
//                                         rimItem['condition'] = 'Good';
//                                       });
//                                     },
//                                     child: Container(
//                                       padding:
//                                           EdgeInsets.symmetric(vertical: 10),
//                                       decoration: BoxDecoration(
//                                         color: isGood
//                                             ? Colors.green
//                                             : Colors.grey[300],
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       alignment: Alignment.center,
//                                       child: Text(
//                                         'GOOD',
//                                         style: TextStyle(
//                                           color: isGood
//                                               ? Colors.white
//                                               : Colors.black,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: 10),
//                                 Expanded(
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       stState(() {
//                                         rimItem['condition'] = 'Poor';
//                                       });
//                                     },
//                                     child: Container(
//                                       padding:
//                                           EdgeInsets.symmetric(vertical: 10),
//                                       decoration: BoxDecoration(
//                                         color: isPoor
//                                             ? Colors.red
//                                             : Colors.grey[300],
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       alignment: Alignment.center,
//                                       child: Text(
//                                         'POOR',
//                                         style: TextStyle(
//                                           color: isPoor
//                                               ? Colors.white
//                                               : Colors.black,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             SizedBox(height: 10),

//                             // Job Description
//                             TextField(
//                               controller: TextEditingController(
//                                   text: rimItem['jobDescription'] ?? '')
//                                 ..selection = TextSelection.fromPosition(
//                                   TextPosition(
//                                       offset: (rimItem['jobDescription'] ?? '')
//                                           .length),
//                                 ),
//                               style: TextStyle(fontSize: 12),
//                               decoration: InputDecoration(
//                                 hintText: 'Job Description',
//                                 isDense: true,
//                                 contentPadding: EdgeInsets.symmetric(
//                                     horizontal: 8, vertical: 6),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 filled: true,
//                                 fillColor: Colors.white,
//                               ),
//                               maxLines: 1,
//                               onChanged: (val) {
//                                 rimItem['jobDescription'] = val;
//                               },
//                             ),

//                             SizedBox(height: 10),

//                             /// REMARK
//                             TextField(
//                               controller: TextEditingController(
//                                   text: rimItem['remark'] ?? '')
//                                 ..selection = TextSelection.fromPosition(
//                                   TextPosition(
//                                       offset: (rimItem['remark'] ?? '').length),
//                                 ),
//                               style: TextStyle(fontSize: 12), // kecilkan font
//                               decoration: InputDecoration(
//                                 hintText: 'Remark...',
//                                 isDense: true, // bikin lebih compact
//                                 contentPadding: EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 6, // lebih kecil
//                                 ),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 filled: true,
//                                 fillColor: Colors.white,
//                               ),
//                               maxLines: 2, // supaya tidak terlalu tinggi
//                               onChanged: (val) {
//                                 rimItem['remark'] = val;
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ),
//                 ),
//               ),

//               /// 🔥 ACTION BUTTONS
//               actions: [
//                 /// CLOSE (TIDAK SIMPAN)
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: Text(
//                     'Close',
//                     style: getRedTextStyle(fontWeight: w500),
//                   ),
//                 ),

//                 /// SAVE (SIMPAN KE position)
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       position[tireIndex]['rimCondition'] = tempList;
//                     });

//                     Navigator.pop(context);
//                   },
//                   child: Text(
//                     'Save',
//                     style: getWhiteTextStyle(fontWeight: w500),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   void initState() {
//     idSite = homeState.currentSiteId;
//     _loadDamages();

//     super.initState();
//     requestPlacePermission();

//     context.read<BluetoothOnOffCubit>().checkBluetoothStatus();
//     final connectedCubit = context.read<ConnectedDevicesCubit>();
//     log('connected cubit : $connectedCubit');
//     connectedCubit.fetchConnectedDevices(); // HANYA MEMULAI fetch

//     // callTires();
//     WidgetsBinding.instance.addObserver(this);
//     getUser();
//   }

//   Future<void> loadPreviousRating(
//       int index, String unit, String kunciTire) async {
//     print('load previous rating unit : $unit');
//     try {
//       final snapshot = await firestore
//           .collection('tire_inspection')
//           .where('unit', isEqualTo: unit) // ✅ FILTER UNIT
//           .orderBy('tanggal', descending: true)
//           .limit(1) // ✅ hanya dokumen terbaru unit itu
//           .get();

//       log('load previous rating : ${snapshot.docs}');

//       if (snapshot.docs.isEmpty) return;

//       final doc = snapshot.docs.first;

//       final List<dynamic> posisiList = doc['posisi'];

//       for (final pos in posisiList) {
//         if (pos['kunci_tire'] == kunciTire) {
//           final prevRating = pos['rating'];

//           if (prevRating != null) {
//             setState(() {
//               position[index]['rating'] =
//                   prevRating is String ? prevRating : [prevRating];
//               position[index]['prevRating'] =
//                   prevRating is String ? prevRating : [prevRating];
//             });

//             log('AUTO RATING FOUND: $prevRating');
//             return;
//           }
//         }
//       }
//     } catch (e) {
//       log('loadPreviousRating error: $e');
//     }
//   }

//   Future<void> loadPreviousDamage(
//       int index, String unit, String kunciTire) async {
//     print('load previous damage unit : $unit');
//     try {
//       final snapshot = await firestore
//           .collection('tire_inspection')
//           .where('unit', isEqualTo: unit) // ✅ FILTER UNIT
//           .orderBy('tanggal', descending: true)
//           .limit(1) // ✅ hanya dokumen terbaru unit itu
//           .get();

//       log('load previous damage : ${snapshot.docs}');

//       if (snapshot.docs.isEmpty) return;

//       final doc = snapshot.docs.first;

//       final List<dynamic> posisiList = doc['posisi'];

//       for (final pos in posisiList) {
//         if (pos['kunci_tire'] == kunciTire) {
//           final prevDamage = pos['damageTire'];
//           final prevRemarks = pos['remarks'];

//           if (prevDamage != null) {
//             setState(() {
//               position[index]['damageTire'] =
//                   prevDamage is List ? prevDamage : [prevDamage];
//             });

//             log('AUTO DAMAGE FOUND: $prevDamage');
//             return;
//           }

//           if (prevRemarks != null && prevRemarks != '') {
//             setState(() {
//               position[index]['remarks'] = prevRemarks;
//             });

//             log('AUTO REMARKS FOUND: $prevRemarks');
//             return;
//           }
//         }
//       }
//     } catch (e) {
//       log('loadPreviousDamage error: $e');
//     }
//   }

//   // Future<void> _loadDamages() async {
//   //   try {
//   //     final query =
//   //         await firestore.collection('list_tire_damage_inspection').get();

//   //     final docs = query.docs.where((doc) {
//   //       return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(doc.id);
//   //     }).toList();

//   //     docs.sort((a, b) => b.id.compareTo(a.id));

//   //     final latestDoc = docs.first;

//   //     final data = latestDoc.data();

//   //     log('docs luka ban : $data');

//   //     if (data != null && data['damages'] != null) {
//   //       final List<dynamic> raw = data['damages'];

//   //       List<Map<String, dynamic>> sortedList =
//   //           raw.map<Map<String, dynamic>>((e) {
//   //         return Map<String, dynamic>.from(e);
//   //       }).toList();

//   //       sortedList.sort((a, b) {
//   //         final aRemark = (a['remark'] ?? '').toString().toLowerCase();
//   //         final bRemark = (b['remark'] ?? '').toString().toLowerCase();

//   //         final aGood = aRemark.contains('good');
//   //         final bGood = bRemark.contains('good');

//   //         if (aGood && !bGood) return -1;
//   //         if (!aGood && bGood) return 1;

//   //         return aRemark.compareTo(bRemark);
//   //       });

//   //       setState(() {
//   //         damageType = sortedList;
//   //         loadingDamages = false;
//   //       });
//   //     } else {
//   //       setState(() {
//   //         loadingDamages = false;
//   //       });
//   //     }
//   //   } catch (e) {
//   //     debugPrint('Error load damages: $e');

//   //     setState(() {
//   //       loadingDamages = false;
//   //     });
//   //   }
//   // }

//   Future<void> _loadDamages() async {
//     try {
//       Map<String, dynamic>? data;
//       final sisIdSite = await getIdSiteSIS();
//       final isSisIdSite = sisIdSite.any((site) => site.idSite == idSite);

//       if (isSisIdSite) {
//         final doc = await firestore
//             .collection('list_tire_damage_inspection')
//             .doc('sis062026')
//             .get();

//         if (doc.exists) {
//           data = doc.data();
//         }
//       } else {
//         final query =
//             await firestore.collection('list_tire_damage_inspection').get();

//         final docs = query.docs.where((doc) {
//           return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(doc.id);
//         }).toList();

//         docs.sort((a, b) => b.id.compareTo(a.id));

//         if (docs.isNotEmpty) {
//           data = docs.first.data();
//         }
//       }

//       log('docs luka ban : $data');

//       if (data != null && data['damages'] != null) {
//         final List<dynamic> raw = data['damages'];

//         List<Map<String, dynamic>> sortedList =
//             raw.map<Map<String, dynamic>>((e) {
//           return Map<String, dynamic>.from(e);
//         }).toList();

//         sortedList.sort((a, b) {
//           final aRemark = (a['remark'] ?? '').toString().toLowerCase();
//           final bRemark = (b['remark'] ?? '').toString().toLowerCase();

//           final aGood = aRemark.contains('good');
//           final bGood = bRemark.contains('good');

//           if (aGood && !bGood) return -1;
//           if (!aGood && bGood) return 1;

//           return aRemark.compareTo(bRemark);
//         });

//         setState(() {
//           damageType = sortedList;
//           loadingDamages = false;
//         });
//       } else {
//         setState(() {
//           loadingDamages = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error load damages: $e');

//       setState(() {
//         loadingDamages = false;
//       });
//     }
//   }

//   getUser() async {
//     user = await getUserPreferences();
//     log('username : ${user}');
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);

//     idUnit.dispose();
//     hmUnit.dispose();
//     pressureCtrl.dispose();
//     remarksCtrl.dispose();
//     damageCtrl.dispose();
//     rtd1.dispose();
//     rtd2.dispose();

//     for (final controller in remarksControllers) {
//       controller.dispose();
//     }

//     for (final controller in snControllers) {
//       controller.dispose();
//     }

//     for (final controller in rtd1Controllers) {
//       controller.dispose();
//     }

//     for (final controller in rtd2Controllers) {
//       controller.dispose();
//     }

//     swiperController.dispose();

//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_isInit) {
//       final args = ModalRoute.of(context)?.settings.arguments;
//       if (args != null) {
//         dataUnit = args as Map<String, dynamic>;
//         log('TireInspectionPage: dataUnit berhasil diambil -> $dataUnit');

//         // Panggil callTires() setelah dataUnit pasti terisi
//         callTires();
//       } else {
//         log('TireInspectionPage: ERROR! Argumen navigasi null.');
//       }

//       _isInit = false; // Set flag agar tidak dijalankan lagi
//     }
//   }

//   List<BluetoothDevice> devices = [];
//   String tmpPressure = '';
//   final Box<TireInspectPictureEntity> imageBox =
//       store.box<TireInspectPictureEntity>();

//   insertPit() {
//     setState(() {
//       // if (idSite == '52') {
//       //   pit.add('Utara');
//       //   pit.add('Selatan');
//       //   pit.add('RML');
//       //   pit.add('WS');
//       // }
//     });
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
//     String userAccessId = homeState.userAccessId.value;
//     if (mounted) {
//       if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
//         idUnit.text = dataUnit['unitNumber'];
//         // hmUnit.text = dataUnit['hm'];
//         context.read<TireBloc>().add(GetUnitTiresEvent(
//             idSite: idSite, unitNumber: dataUnit['unitNumber']));
//       }
//     }

//     insertPit();
//   }

//   void handleDataRemarks(String remarks, int index) {
//     this.remarks = remarks;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   void handleDataRTD(String rtd, int index) {
//     this.rtd = rtd;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   void applyPressureData(String pressureValue) {
//     setState(() {
//       final firstNumber = pressureValue;

//       if (checkAmount < position.length) {
//         int targetIndex = inspectRoute[selectedRoute][checkAmount];
//         log('target position : ${targetIndex}');
//         log('target pressure : ${firstNumber}');

//         // Update Map di index tersebut
//         position[targetIndex]["pressure"] = firstNumber;

//         checkAmount++;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     pit.clear();
//     // if (idSite == '52') {
//     //   pit.add('Utara');
//     //   pit.add('Selatan');
//     //   pit.add('RML');
//     //   pit.add('WS');
//     // }
//     switch (idSite) {
//       case '52':
//         pit.add('Utara');
//         pit.add('Selatan');
//         pit.add('RML');
//         pit.add('WS');
//         break;
//       case '137':
//         pit.add('Japun');
//         pit.add('PCE');
//         break;
//       case '35':
//         pit.add('Tabuhan');
//         pit.add('EBL');
//         pit.add('Workshop');
//         break;
//       case '65':
//         pit.add('Room B1 Selatan');
//         pit.add('TIA');
//         pit.add('Serongga');
//         pit.add('CSA Selatan');
//         pit.add('WS');
//         break;
//       case '166':
//         pit.add('WS');
//         pit.add('Pondok Operator');
//         pit.add('CSA Bagaspati');
//         pit.add('Pit Stop Toll');
//         break;
//     }
//     print('dipanggil (pgd)');
//     dataUnit =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Padding(
//           padding: const EdgeInsets.only(top: 18.0),
//           child: Text(
//             'Tire Inspection',
//             textAlign: TextAlign.center,
//             style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
//           ),
//         ),
//         centerTitle: true,
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 16),
//           child: Container(
//             margin: const EdgeInsets.only(top: 14),
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             decoration: BoxDecoration(
//               color: white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: black),
//             ),
//             child: IconButton(
//                 onPressed: () {
//                   if (isSaved) {
//                     pushReplace(context, HomePage.routeName);
//                   } else {
//                     back(context);
//                   }
//                 },
//                 icon: const Icon(
//                   Icons.arrow_back_ios,
//                   color: black,
//                   size: 24,
//                 )),
//           ),
//         ),
//       ),
//       body: SafeArea(
//           child: BlocConsumer<TireBloc, TireState>(
//         listener: (context, state) {
//           if (state is TiresLoadedState) {
//             final firstUnit = state.units.first;
//             final currentUnitNumber = firstUnit.unitNumber ?? '';

//             if (_hmInitializedForUnit != currentUnitNumber) {
//               hmUnit.text = idSite == bmbhauling.idSite
//                   ? ''
//                   : firstUnit.hm?.toString() ?? '';

//               _hmInitializedForUnit = currentUnitNumber;
//             }

//             position.clear();

//             for (int i = 0; i < state.units.length; i++) {
//               final unit = state.units[i];
//               for (int i = 0; i < position.length; i++) {
//                 final unit = state.units[i];

//                 if (unit.kunciTire != null) {
//                   loadPreviousRating(
//                       i, unit.unitNumber ?? '', unit.kunciTire ?? '');
//                   loadPreviousDamage(
//                       i, unit.unitNumber ?? '', unit.kunciTire ?? '');
//                 }
//               }
//               remarksControllers.add(TextEditingController(text: ''));
//               snControllers.add(TextEditingController(text: ''));
//               rtd1Controllers.add(
//                 TextEditingController(text: unit.rtd?.toString() ?? ''),
//               );

//               rtd2Controllers.add(
//                 TextEditingController(text: unit.otd?.toString() ?? ''),
//               );
//               position.add({
//                 'position': i + 1,
//                 'pressure': '',
//                 'adjusmentPressure': '',
//                 'hm': '',
//                 'damageTire': [],
//                 'rtd1': unit.rtd?.toString() ?? '',
//                 'rtd2': unit.otd?.toString() ?? '',
//                 'remarks': '',
//                 'sn': unit.sn,
//                 'rating': '',
//                 'prevRating': '',
//                 'image': [],
//                 'idInventory': unit.idinventory,
//                 'idUnit': unit.idUnit,
//                 'tireSize': unit.size,
//                 // 'condition': [
//                 //   {'name': 'Reseal Oring', 'checked': false},
//                 //   {'name': 'Rim Condition', 'checked': false},
//                 //   {'name': 'Inflate Tire', 'checked': false},
//                 //   {'name': 'Lock Driver', 'checked': false},
//                 //   {'name': 'Slide Lock', 'checked': false},
//                 //   {'name': 'Valve Cap', 'checked': false},
//                 //   {'name': 'Valve Protector', 'checked': false},
//                 //   {'name': 'Stud and Nut', 'checked': false},
//                 // ],
//                 'rimCondition': [
//                   {
//                     'title': 'RIM BASE',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'FLANGE',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'LOCK RING',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'VALVE (TERPASANG/TIDAK TERPASANG)',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'CORE VALVE',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'NUT DAN STUD RODA',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                 ],
//                 'tireAccessories': []
//               });
//             }
//             log('message position tire inspect : ${position}');
//           }
//         },
//         builder: (context, state) {
//           if (state is TireLoadingState) {
//             return Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//           if (state is TiresLoadedState) {
//             final units = state.units;

//             return SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   children: [
//                     (pit.isNotEmpty)
//                         ? Row(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               Icon(
//                                 Icons.ev_station,
//                                 size: 38,
//                               ),
//                               const SizedBox(
//                                 width: 12,
//                               ),
//                               Text(
//                                 'Unit Location',
//                                 style: getBlackTextStyle(
//                                     fontSize: 18, fontWeight: w700),
//                               ),
//                             ],
//                           )
//                         : Container(),
//                     SizedBox(
//                       height: (pit.isNotEmpty) ? 24 : 0,
//                     ),
//                     (pit.isNotEmpty)
//                         ? Center(
//                             child: Wrap(
//                               spacing: 8.0, // Jarak horizontal antar tombol
//                               children: pit.map((e) {
//                                 final pitIndex = pit.indexOf(e);
//                                 return ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: (selectedPit == pitIndex)
//                                         ? Colors.orange
//                                         : greyF7F8F9,
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       selectedPit = pitIndex;
//                                     });
//                                   },
//                                   child: Text(
//                                     e,
//                                     style: (selectedPit == pitIndex)
//                                         ? getWhiteTextStyle()
//                                         : getBlackTextStyle(),
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                           )
//                         : Container(),
//                     SizedBox(
//                       height: (pit.isNotEmpty) ? 24 : 0,
//                     ),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.front_loader,
//                                     color: Colors.orange,
//                                     size: 38,
//                                   ),
//                                   const SizedBox(
//                                     width: 12,
//                                   ),
//                                   Text(
//                                     'UNIT',
//                                     style: getBlackTextStyle(
//                                         fontWeight: w700, fontSize: 18),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                     isReadOnly: true,
//                                     controller: TextEditingController(
//                                       text: units[0].unitNumber,
//                                     ),
//                                     hint: ''),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(
//                           width: 12,
//                         ),
//                         Expanded(
//                           child: Column(
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.watch,
//                                     color: Colors.red,
//                                     size: 38,
//                                   ),
//                                   const SizedBox(
//                                     width: 12,
//                                   ),
//                                   Text(
//                                     (idSite == bmbhauling.idSite &&
//                                             idSite == '1')
//                                         ? 'KM Unit'
//                                         : 'HM Unit',
//                                     style: getBlackTextStyle(
//                                         fontWeight: w700, fontSize: 18),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                   controller: hmUnit,
//                                   isDecimalOnly: true,
//                                   type: const TextInputType.numberWithOptions(
//                                     decimal: true,
//                                   ),
//                                   hint:
//                                       'Fill ${idSite == bmbhauling.idSite ? 'KM' : 'HM'}',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     BlocBuilder<ConnectedDevicesCubit, ConnectedDevicesState>(
//                       builder: (context, cState) {
//                         // Asumsikan perangkat TPMS adalah yang terhubung jika statusnya Success
//                         final isConnected =
//                             cState is ConnectedDevicesLoadedState &&
//                                 cState.connectedDevices.isNotEmpty;

//                         // Cari perangkat yang terhubung yang memiliki nama yang relevan
//                         // (Anda harus menyesuaikan logika pencarian ini sesuai nama perangkat BT Anda)
//                         final BluetoothDevice? connectedDevice = isConnected
//                             ? cState.connectedDevices
//                                 .firstWhereOrNull((d) => d.advName.isNotEmpty)
//                             : null;

//                         final String buttonText = isConnected
//                             ? 'Connected: ${connectedDevice?.advName ?? connectedDevice?.remoteId.str}'
//                             : 'Scan Devices';

//                         return ButtonWidget(
//                           // Warna tombol berdasarkan status koneksi
//                           color: isConnected ? green00968A : Colors.blue,
//                           name: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.bluetooth,
//                                 color: white,
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 buttonText,
//                                 style: getWhiteTextStyle(),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                           function: () async {},
//                         );
//                       },
//                     ),
//                     BlocListener<BluetoothOnOffCubit, BluetoothOnOffState>(
//                       listener: (context, onOffState) {
//                         if (onOffState is BluetoothOnState) {
//                           context
//                               .read<ConnectedDevicesCubit>()
//                               .fetchConnectedDevices();
//                         }
//                       },
//                       child: BlocConsumer<ConnectedDevicesCubit,
//                           ConnectedDevicesState>(
//                         listener: (context, state) {
//                           if (state is ConnectedDevicesLoadedState &&
//                               state.connectedDevices.isNotEmpty) {
//                             context
//                                 .read<DiscoverServicesCubit>()
//                                 .discoverServices(state.connectedDevices.first);
//                           }
//                         },
//                         builder: (context, state) {
//                           if (state is ConnectedDevicesLoadedState) {
//                             // return _buildConnectedDeviceUI(
//                             //     state.connectedDevices);
//                             if (state.connectedDevices.isNotEmpty) {
//                               BlocProvider.of<DiscoverServicesCubit>(
//                                 context,
//                               ).discoverServices(state.connectedDevices.first);
//                             }
//                             return BlocConsumer<DiscoverServicesCubit,
//                                 DiscoverServiceState>(
//                               listener: (context, discoverState) {
//                                 if (discoverState is ServicesLoadedState) {
//                                   final services = discoverState.services;
//                                   log('services pgd : $services');

//                                   if (!_listenerAdded) {
//                                     _listenerAdded = true;
//                                     for (BluetoothService service in services) {
//                                       for (BluetoothCharacteristic characteristic
//                                           in service.characteristics) {
//                                         if (characteristic.properties.notify) {
//                                           characteristic.onValueReceived
//                                               .listen((value) {
//                                             final notifInString =
//                                                 String.fromCharCodes(value);
//                                             log("angin bergejolak: $notifInString");

//                                             debugPrint(
//                                               "debugBluetoothNotification*************",
//                                             );
//                                             debugPrint(
//                                               "debugBluetoothNotification: charName: ${BluetoothUtils.getBluetoothChar(characteristic.characteristicUuid.str)}",
//                                             );

//                                             debugPrint(
//                                               "notifhohoho: stringNotif: $notifInString",
//                                             );
//                                             setState(() {
//                                               String press = '';

//                                               if (notifInString.contains('|')) {
//                                                 int floorPressure =
//                                                     double.parse(
//                                                   notifInString.split(
//                                                     '|',
//                                                   )[0],
//                                                 ).floor();

//                                                 // int floorTemperature =
//                                                 //     double.parse(
//                                                 //       notifInString.split(
//                                                 //         '|',
//                                                 //       )[1],
//                                                 //     ).floor();
//                                                 // temperature = floorTemperature
//                                                 //     .toString();
//                                                 applyPressureData(
//                                                     floorPressure.toString());
//                                               } else {
//                                                 int floorPressure =
//                                                     double.parse(
//                                                   notifInString,
//                                                 ).floor();
//                                                 press.toString();
//                                                 applyPressureData(
//                                                     floorPressure.toString());
//                                               }
//                                             });

//                                             debugPrint(
//                                               "debugBluetoothNotification*************",
//                                             );
//                                           });

//                                           characteristic
//                                               .setNotifyValue(true); // WAJIB
//                                         }
//                                       }
//                                     }
//                                   }
//                                 }
//                               },
//                               builder: (context, discoverState) {
//                                 if (discoverState is ErrorLoadingServiceState) {
//                                   return Center(child: Text('Error'));
//                                 }
//                                 return Container();
//                               },
//                             );
//                           }
//                           return CircularProgressIndicator();
//                         },
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     ListView.builder(
//                         shrinkWrap: true,
//                         physics: NeverScrollableScrollPhysics(),
//                         itemCount: units.length,
//                         itemBuilder: (context, index) {
//                           final unit = units[index];
//                           if (snControllers[index].text.isEmpty) {
//                             snControllers[index].text = unit.sn ?? '';
//                           }

//                           return Card(
//                             elevation: 2,
//                             child: Container(
//                               width: MediaQuery.of(context).size.width,
//                               padding: EdgeInsets.all(24),
//                               child: Stack(
//                                 children: [
//                                   Opacity(
//                                     opacity: 0.1,
//                                     child: Center(
//                                       child: Text(
//                                         unit.rating ?? '',
//                                         style: TextStyle(
//                                           fontSize: 100,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           SizedBox(
//                                             width: 35,
//                                             height: 53,
//                                             child: Image.asset(
//                                               '$imagePath/em_tire_image.png',
//                                               fit: BoxFit.cover,
//                                             ),
//                                           ),
//                                           Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.end,
//                                             children: [
//                                               Text(
//                                                 'Position',
//                                                 style: getBlackTextStyle(
//                                                     fontSize: 14),
//                                               ),
//                                               const SizedBox(
//                                                 height: 6,
//                                               ),
//                                               Text(
//                                                 '${index + 1}',
//                                                 style: getBlackTextStyle(
//                                                     fontSize: 22,
//                                                     fontWeight: w700),
//                                               ),
//                                             ],
//                                           )
//                                         ],
//                                       ),
//                                       Padding(
//                                         padding:
//                                             EdgeInsets.symmetric(vertical: 6),
//                                         child: Divider(
//                                           thickness: 1.5,
//                                         ),
//                                       ),
//                                       Column(
//                                         children: [
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Unit',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.unitNumber ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'SN',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.sn ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Brand',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.brand ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Tire Lifetime',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.lifetime ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Rating',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.rating ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'RTD',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 '${unit.rtd} / ${unit.otd}' ??
//                                                     '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       Padding(
//                                         padding:
//                                             EdgeInsets.symmetric(vertical: 6),
//                                         child: Divider(
//                                           thickness: 1.5,
//                                         ),
//                                       ),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Expanded(
//                                             child: SizedBox(
//                                               width: MediaQuery.of(context)
//                                                   .size
//                                                   .width,
//                                               height: 45,
//                                               child: ElevatedButton(
//                                                 onPressed: () async {
//                                                   FocusScope.of(context)
//                                                       .unfocus();
//                                                   setState(() {
//                                                     // selectedPosIndex = posIndex;
//                                                   });
//                                                   showDialog(
//                                                     context: context,
//                                                     builder:
//                                                         (BuildContext context) {
//                                                       return Dialog(
//                                                         child: Container(
//                                                           padding:
//                                                               EdgeInsets.all(
//                                                                   20.0),
//                                                           child:
//                                                               SingleChildScrollView(
//                                                             child: Column(
//                                                               mainAxisSize:
//                                                                   MainAxisSize
//                                                                       .min,
//                                                               children: <Widget>[
//                                                                 Text(
//                                                                   'Choose Pressure',
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontSize:
//                                                                         24.0,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .bold,
//                                                                   ),
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         16.0),
//                                                                 Column(),
//                                                                 Wrap(
//                                                                   children:
//                                                                       pressure.map(
//                                                                           (ps) {
//                                                                     final psIndex =
//                                                                         pressure
//                                                                             .indexOf(ps);
//                                                                     return Padding(
//                                                                       padding: const EdgeInsets
//                                                                           .only(
//                                                                           right:
//                                                                               16,
//                                                                           bottom:
//                                                                               18),
//                                                                       child:
//                                                                           ElevatedButton(
//                                                                         style: ElevatedButton.styleFrom(
//                                                                             backgroundColor:
//                                                                                 Colors.green),
//                                                                         onPressed:
//                                                                             () {
//                                                                           final id =
//                                                                               Uuid();
//                                                                           setState(
//                                                                               () {
//                                                                             position[index]['pressure'] =
//                                                                                 ps;
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child:
//                                                                             Text(
//                                                                           ps,
//                                                                           style:
//                                                                               getWhiteTextStyle(
//                                                                             fontWeight:
//                                                                                 w700,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                     );
//                                                                   }).toList(),
//                                                                 ),
//                                                                 Row(
//                                                                   children: [
//                                                                     Expanded(
//                                                                       child:
//                                                                           SizedBox(
//                                                                         width: double
//                                                                             .infinity,
//                                                                         child: InputFormWidget(
//                                                                             controller:
//                                                                                 pressureCtrl,
//                                                                             isDigitOnly:
//                                                                                 true,
//                                                                             type:
//                                                                                 TextInputType.number,
//                                                                             hint: 'Input Manual'),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       width: 6,
//                                                                     ),
//                                                                     ElevatedButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           setState(
//                                                                               () {
//                                                                             if (pressureCtrl.text !=
//                                                                                 '') {
//                                                                               position[index]['pressure'] = pressureCtrl.text;
//                                                                             }
//                                                                             pressureCtrl.clear();
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child: Text(
//                                                                             'Submit'))
//                                                                   ],
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         12.0),
//                                                                 SizedBox(
//                                                                   width: double
//                                                                       .infinity,
//                                                                   child:
//                                                                       ElevatedButton(
//                                                                     onPressed:
//                                                                         () {
//                                                                       pressureCtrl
//                                                                           .clear();
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop();
//                                                                     },
//                                                                     child: Text(
//                                                                         'Close'),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       );
//                                                     },
//                                                   );
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.blue,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               12),
//                                                     )),
//                                                 child: (position[index]
//                                                                 ['pressure'] ==
//                                                             '' ||
//                                                         (position[index]
//                                                                 ['pressure'] ==
//                                                             null))
//                                                     ? Row(
//                                                         mainAxisSize:
//                                                             MainAxisSize.min,
//                                                         children: [
//                                                           Icon(
//                                                             Icons.add,
//                                                             color: white,
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 6,
//                                                           ),
//                                                           Text(
//                                                             'Pressure',
//                                                             style:
//                                                                 getWhiteTextStyle(),
//                                                           )
//                                                         ],
//                                                       )
//                                                     : Text(
//                                                         '${position[index]['pressure']} Psi',
//                                                         style:
//                                                             getWhiteTextStyle(
//                                                           fontSize: 24,
//                                                           fontWeight: w700,
//                                                         ),
//                                                       ),
//                                               ),
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                           // adjusment pressure
//                                           Expanded(
//                                             child: SizedBox(
//                                               width: MediaQuery.of(context)
//                                                   .size
//                                                   .width,
//                                               height: 45,
//                                               child: ElevatedButton(
//                                                 onPressed: () async {
//                                                   FocusScope.of(context)
//                                                       .unfocus();
//                                                   setState(() {
//                                                     // selectedPosIndex = posIndex;
//                                                   });
//                                                   showDialog(
//                                                     context: context,
//                                                     builder:
//                                                         (BuildContext context) {
//                                                       return Dialog(
//                                                         child: Container(
//                                                           padding:
//                                                               EdgeInsets.all(
//                                                                   20.0),
//                                                           child:
//                                                               SingleChildScrollView(
//                                                             child: Column(
//                                                               mainAxisSize:
//                                                                   MainAxisSize
//                                                                       .min,
//                                                               children: <Widget>[
//                                                                 Text(
//                                                                   'Choose Pressure',
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontSize:
//                                                                         24.0,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .bold,
//                                                                   ),
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         16.0),
//                                                                 Column(),
//                                                                 Wrap(
//                                                                   children:
//                                                                       pressure.map(
//                                                                           (ps) {
//                                                                     final psIndex =
//                                                                         pressure
//                                                                             .indexOf(ps);
//                                                                     return Padding(
//                                                                       padding: const EdgeInsets
//                                                                           .only(
//                                                                           right:
//                                                                               16,
//                                                                           bottom:
//                                                                               18),
//                                                                       child:
//                                                                           ElevatedButton(
//                                                                         style: ElevatedButton.styleFrom(
//                                                                             backgroundColor:
//                                                                                 Colors.green),
//                                                                         onPressed:
//                                                                             () {
//                                                                           setState(
//                                                                               () {
//                                                                             position[index]['adjusmentPressure'] =
//                                                                                 ps;
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child:
//                                                                             Text(
//                                                                           ps,
//                                                                           style:
//                                                                               getWhiteTextStyle(
//                                                                             fontWeight:
//                                                                                 w700,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                     );
//                                                                   }).toList(),
//                                                                 ),
//                                                                 Row(
//                                                                   children: [
//                                                                     Expanded(
//                                                                       child:
//                                                                           SizedBox(
//                                                                         width: double
//                                                                             .infinity,
//                                                                         child: InputFormWidget(
//                                                                             controller:
//                                                                                 pressureCtrl,
//                                                                             isDigitOnly:
//                                                                                 true,
//                                                                             type:
//                                                                                 TextInputType.number,
//                                                                             hint: 'Input Manual'),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       width: 6,
//                                                                     ),
//                                                                     ElevatedButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           setState(
//                                                                               () {
//                                                                             if (pressureCtrl.text !=
//                                                                                 '') {
//                                                                               position[index]['adjusmentPressure'] = pressureCtrl.text;
//                                                                             }
//                                                                             pressureCtrl.clear();
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child: const Text(
//                                                                             'Submit'))
//                                                                   ],
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         12.0),
//                                                                 SizedBox(
//                                                                   width: double
//                                                                       .infinity,
//                                                                   child:
//                                                                       ElevatedButton(
//                                                                     onPressed:
//                                                                         () {
//                                                                       pressureCtrl
//                                                                           .clear();
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop();
//                                                                     },
//                                                                     child: Text(
//                                                                         'Close'),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       );
//                                                     },
//                                                   );
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.blue,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               12),
//                                                     )),
//                                                 child: (position[index][
//                                                             'adjusmentPressure'] ==
//                                                         '')
//                                                     ? Text(
//                                                         'Adj Pressure',
//                                                         style:
//                                                             getWhiteTextStyle(),
//                                                       )
//                                                     : Text(
//                                                         '${position[index]['adjusmentPressure']} Psi (Adj)',
//                                                         style:
//                                                             getWhiteTextStyle(
//                                                           fontSize: 16,
//                                                           fontWeight: w700,
//                                                         ),
//                                                       ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),

//                                       const SizedBox(
//                                         height: 12,
//                                       ),

//                                       SizedBox(
//                                         width:
//                                             MediaQuery.of(context).size.width,
//                                         height: 45,
//                                         child: ElevatedButton(
//                                           onPressed: () async {
//                                             FocusScope.of(context).unfocus();
//                                             // setState(() {
//                                             //   selectedPosIndex = posIndex;
//                                             // });

//                                             showDialog(
//                                               context: context,
//                                               builder: (BuildContext context) {
//                                                 return Dialog(
//                                                   child: Container(
//                                                     padding:
//                                                         EdgeInsets.all(20.0),
//                                                     child:
//                                                         SingleChildScrollView(
//                                                       child: Column(
//                                                         mainAxisSize:
//                                                             MainAxisSize.min,
//                                                         children: <Widget>[
//                                                           Text(
//                                                             'Choose Rating',
//                                                             style: TextStyle(
//                                                               fontSize: 24.0,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .bold,
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                               height: 16.0),
//                                                           Column(),
//                                                           Wrap(
//                                                             children: rating
//                                                                 .map((rat) {
//                                                               final ratingIndex =
//                                                                   rating
//                                                                       .indexOf(
//                                                                           rat);
//                                                               return Padding(
//                                                                 padding:
//                                                                     const EdgeInsets
//                                                                         .only(
//                                                                         right:
//                                                                             16,
//                                                                         bottom:
//                                                                             18),
//                                                                 child:
//                                                                     ElevatedButton(
//                                                                   style: ElevatedButton.styleFrom(
//                                                                       backgroundColor:
//                                                                           Colors
//                                                                               .green),
//                                                                   onPressed:
//                                                                       () {
//                                                                     setState(
//                                                                         () {
//                                                                       position[index]
//                                                                               [
//                                                                               'rating'] =
//                                                                           rat;
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop();
//                                                                     });
//                                                                   },
//                                                                   child: Text(
//                                                                     rat,
//                                                                     style:
//                                                                         getWhiteTextStyle(
//                                                                       fontWeight:
//                                                                           w700,
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                               );
//                                                             }).toList(),
//                                                           ),
//                                                           SizedBox(
//                                                               height: 12.0),
//                                                           SizedBox(
//                                                             width:
//                                                                 double.infinity,
//                                                             child:
//                                                                 ElevatedButton(
//                                                               onPressed: () {
//                                                                 pressureCtrl
//                                                                     .clear();
//                                                                 Navigator.of(
//                                                                         context)
//                                                                     .pop();
//                                                               },
//                                                               child:
//                                                                   Text('Close'),
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 );
//                                               },
//                                             );
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                               backgroundColor: Colors.blue,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               )),
//                                           child: (position[index]['rating'] ==
//                                                   '')
//                                               ? Builder(builder: (context) {
//                                                   position[index]['rating'] =
//                                                       'A';
//                                                   return Text(
//                                                     'Rating A',
//                                                     style: getWhiteTextStyle(),
//                                                   );
//                                                 })
//                                               : Text(
//                                                   'Rating ${position[index]['rating']}',
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 16,
//                                                     fontWeight: w700,
//                                                   ),
//                                                 ),
//                                         ),
//                                       ),

//                                       const SizedBox(
//                                         height: 12,
//                                       ),

//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 8, vertical: 4),
//                                         decoration: BoxDecoration(
//                                           color: blue344BEF,
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         child: Text(
//                                           'Tire Damage',
//                                           textAlign: TextAlign.start,
//                                           style: getBlackTextStyle(
//                                             fontSize: 12,
//                                           ).copyWith(color: Colors.white),
//                                         ),
//                                       ),

//                                       SizedBox(
//                                         width:
//                                             MediaQuery.of(context).size.width,
//                                         child: ElevatedButton(
//                                           onPressed: () {
//                                             if (index == 0)
//                                               log('luka map : ${position[index]['damageTire']}');
//                                             FocusScope.of(context).unfocus();

//                                             if (loadingDamages) {
//                                               // Optional: kasih feedback kalau masih loading
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 const SnackBar(
//                                                     content: Text(
//                                                         'Sedang memuat daftar damage...')),
//                                               );
//                                               return;
//                                             }

//                                             if (damageType.isEmpty) {
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 const SnackBar(
//                                                     content: Text(
//                                                         'Daftar damage kosong')),
//                                               );
//                                               return;
//                                             }

//                                             final List<dynamic>
//                                                 existingDamages =
//                                                 position[index]['damageTire'] ??
//                                                     [];

//                                             List<bool> checkedDamageValues;

//                                             if (existingDamages.isEmpty ||
//                                                 existingDamages[0] == "") {
//                                               print(
//                                                   'exisitng damage empty true');
//                                               // otomatis centang Good Condition jika belum ada damage
//                                               checkedDamageValues =
//                                                   damageType.map((damage) {
//                                                 final text = damage['remark']
//                                                     .toString()
//                                                     .toLowerCase()
//                                                     .trim();
//                                                 return text == 'good' ||
//                                                     text == 'good condition';
//                                               }).toList();
//                                             } else {
//                                               print(
//                                                   'exisitng damage empty false');
//                                               // jika sudah ada data damage
//                                               checkedDamageValues =
//                                                   damageType.map((damage) {
//                                                 return existingDamages
//                                                     .contains(damage['remark']);
//                                               }).toList();
//                                             }

//                                             showDialog(
//                                               context: context,
//                                               builder: (BuildContext context) {
//                                                 return Dialog(
//                                                   child: Container(
//                                                     padding:
//                                                         const EdgeInsets.all(
//                                                             20.0),
//                                                     child: Column(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: <Widget>[
//                                                         const Text(
//                                                           'Choose Damage Tire',
//                                                           style: TextStyle(
//                                                             fontSize: 24.0,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                             height: 12.0),
//                                                         Expanded(
//                                                           child:
//                                                               SingleChildScrollView(
//                                                             child: Column(
//                                                               children:
//                                                                   damageType.map(
//                                                                       (damage) {
//                                                                 final dmgIndex =
//                                                                     damageType
//                                                                         .indexOf(
//                                                                             damage);

//                                                                 // kalau tidak perlu skip index 0, hapus if ini
//                                                                 // if (dmgIndex == 0) return Container();

//                                                                 return StatefulBuilder(
//                                                                   builder: (context,
//                                                                       setState) {
//                                                                     return CheckboxListTile(
//                                                                       title: Text(
//                                                                           damage[
//                                                                               'remark']),
//                                                                       value: checkedDamageValues[
//                                                                           dmgIndex],
//                                                                       onChanged:
//                                                                           (bool?
//                                                                               value) {
//                                                                         setState(
//                                                                             () {
//                                                                           bool
//                                                                               newValue =
//                                                                               value ?? false;

//                                                                           if (dmgIndex ==
//                                                                               0) {
//                                                                             // GOOD CONDITION dicentang
//                                                                             checkedDamageValues =
//                                                                                 List<bool>.filled(checkedDamageValues.length, false);
//                                                                             checkedDamageValues[0] =
//                                                                                 newValue;
//                                                                           } else {
//                                                                             // Damage lain dicentang
//                                                                             checkedDamageValues[dmgIndex] =
//                                                                                 newValue;

//                                                                             if (newValue) {
//                                                                               // otomatis uncheck Good Condition
//                                                                               checkedDamageValues[0] = false;
//                                                                             }
//                                                                           }
//                                                                         });
//                                                                       },
//                                                                     );
//                                                                   },
//                                                                 );
//                                                               }).toList(),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                             height: 12.0),
//                                                         Column(
//                                                           children: [
//                                                             const SizedBox(
//                                                                 height: 12),
//                                                             SizedBox(
//                                                               width: double
//                                                                   .infinity,
//                                                               child:
//                                                                   ElevatedButton(
//                                                                 onPressed: () {
//                                                                   damageCtrl
//                                                                       .clear();
//                                                                   Navigator.pop(
//                                                                       context);
//                                                                 },
//                                                                 child:
//                                                                     const Text(
//                                                                         'Close'),
//                                                               ),
//                                                             ),
//                                                             const SizedBox(
//                                                                 height: 12),
//                                                             SizedBox(
//                                                               width: double
//                                                                   .infinity,
//                                                               child:
//                                                                   ElevatedButton(
//                                                                 style: ElevatedButton
//                                                                     .styleFrom(
//                                                                   backgroundColor:
//                                                                       Colors
//                                                                           .green,
//                                                                 ),
//                                                                 onPressed: () {
//                                                                   setState(
//                                                                       () {}); // setState parent

//                                                                   selectedDamage
//                                                                       .clear();

//                                                                   Map<String,
//                                                                           int>
//                                                                       ratingPriority =
//                                                                       {
//                                                                     '': 1,
//                                                                     'A': 1,
//                                                                     'B': 2,
//                                                                     'C': 3,
//                                                                     'X': 4,
//                                                                   };

//                                                                   final List<
//                                                                           Map<String,
//                                                                               dynamic>>
//                                                                       tmp = [];

//                                                                   // NOTE: ini tadinya if (== '' || isNotEmpty) -> selalu true.
//                                                                   if (damageCtrl
//                                                                       .text
//                                                                       .isNotEmpty) {
//                                                                     tmp.add({
//                                                                       'remark':
//                                                                           damageCtrl
//                                                                               .text,
//                                                                       'rating':
//                                                                           ''
//                                                                     });
//                                                                   }

//                                                                   for (int i =
//                                                                           0;
//                                                                       i <
//                                                                           checkedDamageValues
//                                                                               .length;
//                                                                       i++) {
//                                                                     if (checkedDamageValues[
//                                                                         i]) {
//                                                                       tmp.add(
//                                                                           damageType[
//                                                                               i]);
//                                                                     }
//                                                                   }

//                                                                   final onlyRemark = tmp
//                                                                       .map<String>((item) =>
//                                                                           item['remark']
//                                                                               ?.toString() ??
//                                                                           '')
//                                                                       .where((remark) =>
//                                                                           remark
//                                                                               .isNotEmpty)
//                                                                       .toList();

//                                                                   position[index]
//                                                                           [
//                                                                           'damageTire'] =
//                                                                       onlyRemark;

//                                                                   if (tmp
//                                                                       .isNotEmpty) {
//                                                                     position[index]
//                                                                             [
//                                                                             'damageTire'] =
//                                                                         onlyRemark;

//                                                                     // rating based damage
//                                                                     String
//                                                                         worstRating =
//                                                                         '';
//                                                                     worstRating =
//                                                                         tmp.fold(
//                                                                       '',
//                                                                       (worst,
//                                                                           item) {
//                                                                         final current =
//                                                                             item['rating'] ??
//                                                                                 '';

//                                                                         return ratingPriority[current]! >
//                                                                                 ratingPriority[worst]!
//                                                                             ? current
//                                                                             : worst;
//                                                                       },
//                                                                     );

//                                                                     position[index]
//                                                                             [
//                                                                             'rating'] =
//                                                                         worstRating;

//                                                                     selectedDamage
//                                                                         .addAll(
//                                                                             onlyRemark);

//                                                                     log('hasil luka ban : $position');
//                                                                   }

//                                                                   damageCtrl
//                                                                       .clear();
//                                                                   Navigator.pop(
//                                                                       context);
//                                                                 },
//                                                                 child: Text(
//                                                                   'Submit',
//                                                                   style:
//                                                                       getWhiteTextStyle(
//                                                                     fontWeight:
//                                                                         w700,
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 );
//                                               },
//                                             );
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: blue344BEF,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                           child: Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                                 vertical: 8.0),
//                                             child: Text(
//                                               ((position[index]['damageTire'] ==
//                                                           null) ||
//                                                       (position[index]
//                                                                   ['damageTire']
//                                                               as List)
//                                                           .where((e) =>
//                                                               e != null &&
//                                                               e
//                                                                   .toString()
//                                                                   .trim()
//                                                                   .isNotEmpty)
//                                                           .isEmpty)
//                                                   ? 'Good Condition'
//                                                   : (position[index]
//                                                               ['damageTire']
//                                                           as List)
//                                                       .join('\n---\n'),
//                                               textAlign: TextAlign.center,
//                                               style: getWhiteTextStyle(
//                                                   fontSize: 14),
//                                             ),
//                                           ),
//                                         ),
//                                       ),

//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 45,
//                                         child: ElevatedButton(
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.orange,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                           onPressed: () {
//                                             showRimInspectionDialog(index);
//                                           },
//                                           child: Text(
//                                             'Check Tire Component Condition',
//                                             style: getWhiteTextStyle(
//                                                 fontWeight: w700),
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(
//                                         height: 16,
//                                       ),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 45,
//                                         child: ElevatedButton(
//                                             style: ElevatedButton.styleFrom(
//                                                 backgroundColor: Colors.green,
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                 )),
//                                             onPressed: () async {
//                                               final ImagePicker picker =
//                                                   ImagePicker();

//                                               final ImageSource? source =
//                                                   await showDialog<ImageSource>(
//                                                 context: context,
//                                                 builder: (context) {
//                                                   return AlertDialog(
//                                                     title: Text(
//                                                         "Pilih Sumber Gambar"),
//                                                     content: Column(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: [
//                                                         ListTile(
//                                                           leading: Icon(
//                                                               Icons.camera_alt),
//                                                           title: Text("Kamera"),
//                                                           onTap: () =>
//                                                               Navigator.pop(
//                                                                   context,
//                                                                   ImageSource
//                                                                       .camera),
//                                                         ),
//                                                         ListTile(
//                                                           leading: Icon(Icons
//                                                               .photo_library),
//                                                           title:
//                                                               Text("Gallery"),
//                                                           onTap: () =>
//                                                               Navigator.pop(
//                                                                   context,
//                                                                   ImageSource
//                                                                       .gallery),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   );
//                                                 },
//                                               );

//                                               // final XFile? image =
//                                               //     await picker.pickImage(
//                                               //         imageQuality: 50,
//                                               //         source:
//                                               //             // ImageSource.camera);
//                                               //             ImageSource.gallery);

//                                               if (source == null) return;

//                                               if (source ==
//                                                   ImageSource.camera) {
//                                                 requestCameraPermission();
//                                               }

//                                               final XFile? image =
//                                                   await picker.pickImage(
//                                                 source: source,
//                                                 imageQuality: 50,
//                                               );

//                                               try {
//                                                 if (image != null) {
//                                                   Directory? directory;

//                                                   if (Platform.isAndroid) {
//                                                     // path = await getExternalStorageDirectory();
//                                                     directory =
//                                                         await DownloadsPath
//                                                             .downloadsDirectory();
//                                                   }

//                                                   if (Platform.isIOS) {
//                                                     // final directory = await getApplicationDocumentsDirectory();
//                                                     // path = directory;
//                                                     directory =
//                                                         await getApplicationDocumentsDirectory();
//                                                   }

//                                                   // Read image as a file
//                                                   File imageFile =
//                                                       File(image.path);
//                                                   // data size fotonya
//                                                   final compressedFilePath =
//                                                       '${directory?.path}/${DateTime.now().millisecondsSinceEpoch}_tireinspectionimage_compressed.jpg';

//                                                   // Compress the image if needed (optional)
//                                                   final compressedImageFile =
//                                                       await FlutterImageCompress
//                                                           .compressAndGetFile(
//                                                     imageFile.path,
//                                                     compressedFilePath,
//                                                     quality: 50,
//                                                   );
//                                                   log('gambar : ${compressedFilePath}');

//                                                   // listImg.add(
//                                                   //     '${compressedImageFile?.path}|${position[index]['position']}' ??
//                                                   //         '');
//                                                   position[index]['image'] = [
//                                                     '${compressedImageFile?.path}|${position[index]['position']}'
//                                                   ];
//                                                   log('tire inspection image = ${position[index]['image']}');

//                                                   // Convert image to base64
//                                                   final file = File(
//                                                       compressedImageFile!
//                                                           .path);
//                                                   final bytes =
//                                                       await file.readAsBytes();
//                                                   final decodedImage =
//                                                       await decodeImageFromList(
//                                                           bytes);
//                                                   imageWidths[index] =
//                                                       decodedImage.width
//                                                           .toDouble();
//                                                   imageHeights[index] =
//                                                       decodedImage.height
//                                                           .toDouble();

//                                                   final base64Image =
//                                                       base64Encode(bytes);

//                                                   Future(() async {
//                                                     setState(() {
//                                                       loadingAI[index] = true;
//                                                     });

//                                                     final result =
//                                                         await ApiService
//                                                             .postPredictImageAI(
//                                                       await ApiService
//                                                           .getValidToken(),
//                                                       base64Image,
//                                                     );
//                                                     setState(() {
//                                                       aiResults[index] =
//                                                           result!;
//                                                       loadingAI[index] = false;
//                                                     });

//                                                     log('tire damage ai : $result');
//                                                   });
//                                                 }
//                                               } catch (e) {
//                                                 log('error gambar string : $e');
//                                               }

//                                               setState(() {});
//                                             },
//                                             child: Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.center,
//                                               children: [
//                                                 Icon(
//                                                   Icons.camera_alt,
//                                                   color: white,
//                                                 ),
//                                                 const SizedBox(
//                                                   width: 12,
//                                                 ),
//                                                 Text(
//                                                   'Take Picture',
//                                                   style: getWhiteTextStyle(),
//                                                 ),
//                                               ],
//                                             )),
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       Text(
//                                         '*You can only take one picture. If you take another picture, the previous one will be deleted.',
//                                         style: getRedTextStyle(),
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       ((position[index]['image']
//                                                   as List<dynamic>)
//                                               .isNotEmpty)
//                                           ? Column(
//                                               children: [
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   height: 45,
//                                                   child: ElevatedButton(
//                                                       style: ElevatedButton
//                                                           .styleFrom(
//                                                               backgroundColor:
//                                                                   Colors
//                                                                       .deepOrange,
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             12),
//                                                               )),
//                                                       onPressed: () async {
//                                                         showDialog(
//                                                             context: context,
//                                                             builder: (context) {
//                                                               return AlertDialog(
//                                                                 content: Text(
//                                                                   'Are you sure you want to delete this image?',
//                                                                   style:
//                                                                       getBlackTextStyle(),
//                                                                 ),
//                                                                 actions: [
//                                                                   TextButton(
//                                                                       onPressed:
//                                                                           () {
//                                                                         Navigator.pop(
//                                                                             context);
//                                                                       },
//                                                                       child:
//                                                                           Text(
//                                                                         'Cancel',
//                                                                         style: getGreyTextStyle(
//                                                                             grey8391A1),
//                                                                       )),
//                                                                   TextButton(
//                                                                       onPressed:
//                                                                           () {
//                                                                         position[index]
//                                                                             [
//                                                                             'image'] = [];
//                                                                         Navigator.pop(
//                                                                             context);
//                                                                         setState(
//                                                                             () {});
//                                                                       },
//                                                                       child:
//                                                                           Text(
//                                                                         'Yes',
//                                                                         style:
//                                                                             getRedTextStyle(),
//                                                                       )),
//                                                                 ],
//                                                               );
//                                                             });

//                                                         setState(() {});
//                                                       },
//                                                       child: Row(
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .center,
//                                                         children: [
//                                                           Icon(
//                                                             Icons.delete,
//                                                             color: white,
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 12,
//                                                           ),
//                                                           Text(
//                                                             'Delete Picture',
//                                                             style:
//                                                                 getWhiteTextStyle(),
//                                                           ),
//                                                         ],
//                                                       )),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 (loadingAI[index] == true)
//                                                     ? Center(
//                                                         child:
//                                                             AiLoadingWidget(),
//                                                       )
//                                                     : Stack(
//                                                         children: [
//                                                           Container(
//                                                             width:
//                                                                 double.infinity,
//                                                             decoration:
//                                                                 BoxDecoration(
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           12),
//                                                             ),
//                                                             child: Image.file(
//                                                               File(
//                                                                 (position[index]
//                                                                             [
//                                                                             'image'][0]
//                                                                         as String)
//                                                                     .split(
//                                                                         '|')[0],
//                                                               ),
//                                                               fit: BoxFit
//                                                                   .contain,
//                                                             ),
//                                                           ),
//                                                           Positioned.fill(
//                                                             child: CustomPaint(
//                                                               painter:
//                                                                   BoundingBoxPainter(
//                                                                 detections: aiResults[
//                                                                             index]
//                                                                         ?.data
//                                                                         ?.tireDamageResult ??
//                                                                     [],
//                                                                 imageWidth:
//                                                                     imageWidths[
//                                                                             index] ??
//                                                                         1,
//                                                                 imageHeight:
//                                                                     imageHeights[
//                                                                             index] ??
//                                                                         1,
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                               ],
//                                             )
//                                           : Container(),

//                                       // Show More Images
//                                       // (listImg.isNotEmpty)
//                                       //     ? Column(
//                                       //         children: [
//                                       //           SizedBox(
//                                       //             width: double.infinity,
//                                       //             height: 45,
//                                       //             child: ElevatedButton(
//                                       //                 style: ElevatedButton
//                                       //                     .styleFrom(
//                                       //                         backgroundColor:
//                                       //                             Colors
//                                       //                                 .orange,
//                                       //                         shape:
//                                       //                             RoundedRectangleBorder(
//                                       //                           borderRadius:
//                                       //                               BorderRadius.circular(
//                                       //                                   12),
//                                       //                         )),
//                                       //                 onPressed: () async {
//                                       //                   final CarouselController
//                                       //                       _controller =
//                                       //                       CarouselController();

//                                       //                   showDialog(
//                                       //                       context:
//                                       //                           context,
//                                       //                       builder:
//                                       //                           (BuildContext
//                                       //                               context) {
//                                       //                         return AlertDialog(
//                                       //                           content:
//                                       //                               Padding(
//                                       //                             padding: const EdgeInsets
//                                       //                                 .all(
//                                       //                                 24.0),
//                                       //                             child:
//                                       //                                 Column(
//                                       //                               mainAxisSize:
//                                       //                                   MainAxisSize.min,
//                                       //                               children: [
//                                       //                                 Text(
//                                       //                                   'Show Image',
//                                       //                                   style:
//                                       //                                       getBlackTextStyle(),
//                                       //                                 ),
//                                       //                                 const SizedBox(
//                                       //                                   height:
//                                       //                                       12,
//                                       //                                 ),
//                                       //                                 Container(
//                                       //                                   width:
//                                       //                                       400,
//                                       //                                   height:
//                                       //                                       400,
//                                       //                                   child:
//                                       //                                       CarouselSlider(
//                                       //                                     carouselController: _controller,
//                                       //                                     // items: listImg.map((img) {
//                                       //                                     //   final splitImg = img.split('|');

//                                       //                                     //   if ((position[index]['position']).toString() == splitImg[1]) {
//                                       //                                     //     return Image.file(File(splitImg[0]));
//                                       //                                     //   }
//                                       //                                     //   return Container();
//                                       //                                     // }).toList(),
//                                       //                                     items: listImg
//                                       //                                         .where((img) {
//                                       //                                           final splitImg = img.split('|');
//                                       //                                           return splitImg[1] == (position[index]['position']).toString();
//                                       //                                         })
//                                       //                                         .toList()
//                                       //                                         .map((img2) {
//                                       //                                           final splitImg2 = img2.split('|');
//                                       //                                           return Image.file(File(splitImg2[0]));
//                                       //                                         })
//                                       //                                         .toList(),
//                                       //                                     options: CarouselOptions(
//                                       //                                       aspectRatio: 3.0,
//                                       //                                       height: 400,
//                                       //                                       enableInfiniteScroll: false,
//                                       //                                       enlargeCenterPage: true,
//                                       //                                     ),
//                                       //                                   ),
//                                       //                                 ),
//                                       //                               ],
//                                       //                             ),
//                                       //                           ),
//                                       //                         );
//                                       //                       });
//                                       //                   setState(() {});
//                                       //                 },
//                                       //                 child: Row(
//                                       //                   mainAxisAlignment:
//                                       //                       MainAxisAlignment
//                                       //                           .center,
//                                       //                   children: [
//                                       //                     Icon(
//                                       //                       Icons.image,
//                                       //                       color: white,
//                                       //                     ),
//                                       //                     const SizedBox(
//                                       //                       width: 12,
//                                       //                     ),
//                                       //                     Text(
//                                       //                       'Show Image',
//                                       //                       style:
//                                       //                           getWhiteTextStyle(),
//                                       //                     ),
//                                       //                   ],
//                                       //                 )),
//                                       //           ),
//                                       //           const SizedBox(
//                                       //             height: 12,
//                                       //           ),
//                                       //         ],
//                                       //       )
//                                       //     : Container(),

//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.stretch,
//                                               children: [
//                                                 Text(
//                                                   'RTD 1',
//                                                   style: getBlackTextStyle(
//                                                       fontWeight: w700),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   child: InputFormWidget(
//                                                     onChng: (value) {
//                                                       position[index]['rtd1'] =
//                                                           value;
//                                                     },
//                                                     controller:
//                                                         rtd1Controllers[index],
//                                                     hint: '',
//                                                   ),
//                                                 ),
//                                                 // Builder(builder: (context) {
//                                                 //   rtd1Controllers[index].text =
//                                                 //       unit.rtd ?? '';
//                                                 //   position[index]['rtd1'] =
//                                                 //       unit.rtd;
//                                                 //   return SizedBox(
//                                                 //     width: double.infinity,
//                                                 //     child: InputFormWidget(
//                                                 //         onChng: (value) {
//                                                 //           position[index]
//                                                 //               ['rtd1'] = value;
//                                                 //         },
//                                                 //         controller:
//                                                 //             rtd1Controllers[
//                                                 //                 index],
//                                                 //         hint: ''),
//                                                 //   );
//                                                 // }),
//                                               ],
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.stretch,
//                                               children: [
//                                                 Text(
//                                                   'RTD 2',
//                                                   style: getBlackTextStyle(
//                                                       fontWeight: w700),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   child: InputFormWidget(
//                                                     onChng: (value) {
//                                                       position[index]['rtd2'] =
//                                                           value;
//                                                     },
//                                                     controller:
//                                                         rtd2Controllers[index],
//                                                     hint: '',
//                                                   ),
//                                                 ),
//                                                 // Builder(builder: (context) {
//                                                 //   rtd2Controllers[index].text =
//                                                 //       unit.otd ?? '';
//                                                 //   position[index]['rtd2'] =
//                                                 //       unit.otd;
//                                                 //   return SizedBox(
//                                                 //     width: double.infinity,
//                                                 //     child: InputFormWidget(
//                                                 //         onChng: (value) {
//                                                 //           position[index]
//                                                 //               ['rtd2'] = value;
//                                                 //         },
//                                                 //         controller:
//                                                 //             rtd2Controllers[
//                                                 //                 index],
//                                                 //         hint: ''),
//                                                 //   );
//                                                 // }),
//                                               ],
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.stretch,
//                                         children: [
//                                           Text(
//                                             'Serial Number',
//                                             style: getBlackTextStyle(
//                                                 fontWeight: w700),
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           SizedBox(
//                                             width: double.infinity,
//                                             child: InputFormWidget(
//                                                 onChng: (value) {
//                                                   position[index]['sn'] = value;
//                                                 },
//                                                 controller:
//                                                     snControllers[index],
//                                                 hint: ''),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.stretch,
//                                         children: [
//                                           Text(
//                                             'Remarks',
//                                             style: getBlackTextStyle(
//                                                 fontWeight: w700),
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           SizedBox(
//                                             width: double.infinity,
//                                             child: InputFormWidget(
//                                                 onChng: (value) {
//                                                   position[index]['remarks'] =
//                                                       value;
//                                                 },
//                                                 controller:
//                                                     remarksControllers[index],
//                                                 hint: ''),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(
//                                         height: 24,
//                                       ),
//                                       SizedBox(height: 12),

//                                       // SizedBox(
//                                       //   // height: 160,
//                                       //   child: GridView.builder(
//                                       //       physics:
//                                       //           NeverScrollableScrollPhysics(),
//                                       //       shrinkWrap: true,
//                                       //       itemCount: position[index]
//                                       //               ['condition']
//                                       //           .length,
//                                       //       gridDelegate:
//                                       //           SliverGridDelegateWithFixedCrossAxisCount(
//                                       //               crossAxisCount: 2,
//                                       //               childAspectRatio: 3),
//                                       //       itemBuilder:
//                                       //           (context, indexBroken) {
//                                       //         final broken = position[index]
//                                       //             ['condition'][indexBroken];
//                                       //         return InkWell(
//                                       //           onTap: () {
//                                       //             setState(() {
//                                       //               // checkedListCategory[
//                                       //               //         index] =
//                                       //               //     !checkedListCategory[
//                                       //               //         index];
//                                       //               broken['checked'] =
//                                       //                   !broken['checked'];
//                                       //             });
//                                       //             // widget.onCategoryChecked(checkedListCategory);
//                                       //           },
//                                       //           child: Container(
//                                       //             padding: EdgeInsets.all(10),
//                                       //             child: Row(
//                                       //               children: [
//                                       //                 Container(
//                                       //                   width: 24,
//                                       //                   height: 24,
//                                       //                   decoration:
//                                       //                       BoxDecoration(
//                                       //                     color: broken[
//                                       //                             'checked']
//                                       //                         ? black
//                                       //                         : Colors
//                                       //                             .transparent,
//                                       //                     border: Border.all(
//                                       //                         color:
//                                       //                             Colors.black),
//                                       //                   ),
//                                       //                   child: Icon(
//                                       //                     Icons.check,
//                                       //                     color: Colors.white,
//                                       //                     size: 16,
//                                       //                   ),
//                                       //                 ),
//                                       //                 SizedBox(width: 10),
//                                       //                 LayoutBuilder(builder:
//                                       //                     (context,
//                                       //                         constraints) {
//                                       //                   double fontSize =
//                                       //                       constraints
//                                       //                               .maxHeight *
//                                       //                           0.35;
//                                       //                   // log('ukuran' + fontSize.toString());
//                                       //                   return Text(
//                                       //                     broken['name'],
//                                       //                     style:
//                                       //                         getBlackTextStyle(
//                                       //                             fontSize:
//                                       //                                 fontSize),
//                                       //                   );
//                                       //                 }),
//                                       //               ],
//                                       //             ),
//                                       //           ),
//                                       //         );
//                                       //       }),
//                                       // ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }),
//                   ],
//                 ),
//               ),
//             );
//           }
//           return Container();
//         },
//       )),
//       bottomNavigationBar: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           BlocBuilder<TireBloc, TireState>(
//             builder: (context, state) {
//               if (state is TiresLoadedState) {
//                 return Container(
//                   margin: EdgeInsets.symmetric(horizontal: 24),
//                   child: ButtonWidget(
//                       name: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.save_alt),
//                           const SizedBox(
//                             width: 6,
//                           ),
//                           Text(
//                             'Save',
//                             style: getWhiteTextStyle(),
//                           ),
//                         ],
//                       ),
//                       // function: () async {
//                       //   // jika data pressure kosong
//                       //   bool hasEmptyPressure =
//                       //       position.any((p) => p['pressure'] == '');

//                       //   if (hasEmptyPressure) {
//                       //     ScaffoldMessenger.of(context).hideCurrentSnackBar();

//                       //     ScaffoldMessenger.of(context).showSnackBar(
//                       //       SnackBar(
//                       //         backgroundColor: Colors.red,
//                       //         content: Text(
//                       //           'Please input data pressure (Choose 0 Psi if No Tire or Block Valve)',
//                       //           style: TextStyle(color: Colors.white),
//                       //         ),
//                       //       ),
//                       //     );
//                       //     return;
//                       //   }
//                       //   // jika belum memeilih pit
//                       //   if (idSite == bmbsitarum.idSite ||
//                       //       idSite == bmbhauling.idSite ||
//                       //       idSite == bmbtabuhan.idSite ||
//                       //       idSite == bibkgb.idSite ||
//                       //       idSite == bibgh.idSite) {
//                       //     if (selectedPit == -1) {
//                       //       ScaffoldMessenger.of(context).showSnackBar(
//                       //         SnackBar(
//                       //           backgroundColor: Colors.red,
//                       //           content: Text(
//                       //             'Please select location of unit first!',
//                       //             style: TextStyle(color: Colors.white),
//                       //           ),
//                       //         ),
//                       //       );
//                       //       return;
//                       //     }
//                       //   }

//                       //   // input ke tire inspection
//                       //   try {
//                       //     position.removeWhere((element) =>
//                       //         element['pressure'] == '' &&
//                       //         (element['damageTire'] as List<dynamic>)
//                       //             .isEmpty &&
//                       //         element['adjusmentPressure'] == '' &&
//                       //         element['rtd1'] == '' &&
//                       //         element['rtd2'] == '' &&
//                       //         element['rating'] == '' &&
//                       //         element['sn'] == '' &&
//                       //         element['remarks'] == '');

//                       //     for (int i = 0; i < position.length; i++) {
//                       //       final unit = state.units[i];
//                       //       final id = Uuid();

//                       //       String? localImagePath;
//                       //       try {
//                       //         final imgList =
//                       //             position[i]['image'] as List<dynamic>?;
//                       //         if (imgList != null && imgList.isNotEmpty) {
//                       //           final raw = imgList[0]
//                       //               as String; // format: "path|position"
//                       //           final parts = raw.split('|');
//                       //           if (parts.isNotEmpty) {
//                       //             localImagePath = parts[0];
//                       //           }
//                       //         }
//                       //       } catch (e) {
//                       //         log('parse image error: $e');
//                       //       }

//                       //       log('SAVE POSISI ${localImagePath}');
//                       //       log('SAVE POSISI ${position[i]['position']} '
//                       //           'IMAGE: ${position[i]['image']}');

//                       //       if (position[i]['pressure'] != '' ||
//                       //           position[i]['hm'] != '' ||
//                       //           position[i]['damageTire'] != [] ||
//                       //           position[i]['damageTire'][0] != damageType[0] ||
//                       //           position[i]['adjusmentPressure'] != '' ||
//                       //           position[i]['rtd1'] != '' ||
//                       //           position[i]['rtd2'] != '' ||
//                       //           position[i]['rating'] != '' ||
//                       //           position[i]['sn'] != '' ||
//                       //           position[i]['remarks'] != '') {
//                       //         final today = DateTime.now();
//                       //         final startOfDay =
//                       //             DateTime(today.year, today.month, today.day);
//                       //         final endOfDay = DateTime(today.year, today.month,
//                       //             today.day, 23, 59, 59);

//                       //         final querySnapshot = await firestore
//                       //             .collection('task')
//                       //             .where('kunci_unit',
//                       //                 isEqualTo: unit.kunciUnit)
//                       //             .where('kunci_tire',
//                       //                 isEqualTo: unit.kunciTire)
//                       //             .where('position',
//                       //                 isEqualTo: position[i]['position'])
//                       //             .where('last_update',
//                       //                 isGreaterThanOrEqualTo:
//                       //                     startOfDay.toIso8601String())
//                       //             .where('last_update',
//                       //                 isLessThanOrEqualTo:
//                       //                     endOfDay.toIso8601String())
//                       //             .get();

//                       //         log('adakah query : ${querySnapshot.docs.isNotEmpty}');

//                       //         final bool hasNewLocalImage =
//                       //             localImagePath != null;

//                       //         if (querySnapshot.docs.isNotEmpty) {
//                       //           // Update the existing document
//                       //           final docId = querySnapshot.docs.first.id;
//                       //           // try {
//                       //           //   log('kenapa gagal 3 ${position[i]['image'] as List<dynamic>}');
//                       //           // } catch (e) {
//                       //           //   log('kenapa gagal 4 ${e}');
//                       //           // }

//                       //           final Map<String, dynamic> updateData = {
//                       //             'id': id.v4(),
//                       //             'id_site': idSite,
//                       //             'user': user['username'] ?? 'username',
//                       //             'user_email': auth.currentUser!.email,
//                       //             'unit': unit.unitNumber,
//                       //             'serial_number': unit.sn,
//                       //             'condition': position[i]['condition']
//                       //                 .where((condition) =>
//                       //                     condition['checked'] == true)
//                       //                 .map((condition) =>
//                       //                     condition['name'].toString())
//                       //                 .toList(),
//                       //             'tire_size': unit.size,
//                       //             'hm': hmUnit.text,
//                       //             'position': position[i]['position'],
//                       //             'rating': position[i]['rating'],
//                       //             'brand': unit.brand,
//                       //             'tire_damage':
//                       //                 (position[i]['damageTire'].isEmpty)
//                       //                     ? damageType[0]
//                       //                     : position[i]['damageTire'],
//                       //             'remarks': position[i]['remarks'],
//                       //             'rtd':
//                       //                 '${position[i]['rtd1']}/${position[i]['rtd2']}',
//                       //             'pressure': position[i]['pressure'],
//                       //             'adjusmentPressure': position[i]
//                       //                 ['adjusmentPressure'],
//                       //             'last_update':
//                       //                 DateTime.now().toIso8601String(),
//                       //             'is_done': false,
//                       //             'sn': (position[i]['sn'] != null ||
//                       //                     position[i]['sn'] != '')
//                       //                 ? position[i]['sn']
//                       //                 : unit.sn,
//                       //             'kunci_unit': unit.kunciUnit,
//                       //             'kunci_tire': unit.kunciTire,
//                       //             'pit': (idSite == bmbsitarum.idSite ||
//                       //                     idSite == bmbhauling.idSite ||
//                       //                     idSite == bmbtabuhan.idSite ||
//                       //                     idSite == bibkgb.idSite)
//                       //                 ? pit[selectedPit]
//                       //                 : 'Default',
//                       //           };

//                       //           // Hanya kalau ada foto baru → kosongkan images & set pending
//                       //           if (hasNewLocalImage) {
//                       //             updateData['images'] = [];
//                       //             updateData['imagePending'] = true;
//                       //           }

//                       //           await firestore
//                       //               .collection('task')
//                       //               .doc(docId)
//                       //               .update(updateData);
//                       //           if (hasNewLocalImage) {
//                       //             UploadQueueService.to.addPending(
//                       //               docId: docId,
//                       //               filePath: localImagePath!,
//                       //             );
//                       //           }
//                       //         } else {
//                       //           final Map<String, dynamic> newData = {
//                       //             'id': id.v4(),
//                       //             'id_site': idSite,
//                       //             'user': user['username'] ?? 'username',
//                       //             'user_email': auth.currentUser!.email,
//                       //             'unit': unit.unitNumber,
//                       //             'serial_number': unit.sn,
//                       //             'condition': position[i]['condition']
//                       //                 .where((condition) =>
//                       //                     condition['checked'] == true)
//                       //                 .map((condition) =>
//                       //                     condition['name'].toString())
//                       //                 .toList(),
//                       //             'tire_size': unit.size,
//                       //             'hm': hmUnit.text,
//                       //             'position': position[i]['position'],
//                       //             'rating': position[i]['rating'],
//                       //             'brand': unit.brand,
//                       //             'tire_damage':
//                       //                 (position[i]['damageTire'].isEmpty)
//                       //                     ? damageType[0]
//                       //                     : position[i]['damageTire'],
//                       //             'remarks': position[i]['remarks'],
//                       //             'rtd':
//                       //                 '${position[i]['rtd1']}/${position[i]['rtd2']}',
//                       //             'pressure': position[i]['pressure'],
//                       //             'adjusmentPressure': position[i]
//                       //                 ['adjusmentPressure'],
//                       //             'last_update':
//                       //                 DateTime.now().toIso8601String(),
//                       //             'is_done': false,
//                       //             'sn': (position[i]['sn'] != '')
//                       //                 ? position[i]['sn']
//                       //                 : unit.sn,
//                       //             'kunci_unit': unit.kunciUnit,
//                       //             'kunci_tire': unit.kunciTire,
//                       //             'pit': (idSite == bmbsitarum.idSite ||
//                       //                     idSite == bmbhauling.idSite ||
//                       //                     idSite == bmbtabuhan.idSite ||
//                       //                     idSite == bibkgb.idSite)
//                       //                 ? pit[selectedPit]
//                       //                 : 'Default',
//                       //           };

//                       //           newData['images'] = [];
//                       //           newData['imagePending'] = hasNewLocalImage;

//                       //           final docRef = await firestore
//                       //               .collection('task')
//                       //               .add(newData);

//                       //           if (hasNewLocalImage) {
//                       //             UploadQueueService.to.addPending(
//                       //               docId: docRef.id,
//                       //               filePath: localImagePath!,
//                       //             );
//                       //           }
//                       //         }
//                       //       }
//                       //     }

//                       //     // input ke daily check pressure
//                       //     try {
//                       //       final today = DateTime.now();
//                       //       final startOfDay =
//                       //           DateTime(today.year, today.month, today.day);
//                       //       final endOfDay = DateTime(
//                       //           today.year, today.month, today.day, 23, 59, 59);
//                       //       final formattedToday =
//                       //           '${today.month.toString().padLeft(2, '0')}' // MM
//                       //           '${today.day.toString().padLeft(2, '0')}' // DD
//                       //           '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

//                       //       final querySnapshot = await FirebaseFirestore
//                       //           .instance
//                       //           .collection('daily_pressure')
//                       //           .where('unit',
//                       //               isEqualTo: dataUnit['unitNumber'])
//                       //           .where('tanggal',
//                       //               isGreaterThanOrEqualTo:
//                       //                   startOfDay.toIso8601String())
//                       //           .where('tanggal',
//                       //               isLessThanOrEqualTo:
//                       //                   endOfDay.toIso8601String())
//                       //           .get();

//                       //       print(
//                       //           'Documents found: ${querySnapshot.docs.length}');

//                       //       if (querySnapshot.docs.isNotEmpty) {
//                       //         final docId = querySnapshot.docs.first.id;

//                       //         // revisi data
//                       //         await firestore
//                       //             .collection('daily_pressure')
//                       //             .doc(docId)
//                       //             .update({
//                       //           'idSite': idSite,
//                       //           'user':
//                       //               user['username'] ?? auth.currentUser!.email,
//                       //           'tanggal': DateTime.now().toIso8601String(),
//                       //           'unit': idUnit.text,
//                       //           'hm': hmUnit.text,
//                       //           'posisi': position.map((p) {
//                       //             final pIndex = position.indexOf(p);

//                       //             log('tekanan angin : ${p['pressure']}');
//                       //             return {
//                       //               'pos': '${pIndex + 1}',
//                       //               'pressure': (p['pressure']) ?? '0',
//                       //               'rating': (p['rating']) ?? '',
//                       //               'adjusmentPressure':
//                       //                   (p['adjusmentPressure']) ?? '0',
//                       //               'luka': p['damageTire'],
//                       //               'idUnit': p['idUnit'],
//                       //               'idInventory': p['idInventory'],
//                       //               'tireSize': p['tireSize'],
//                       //               'idDaily':
//                       //                   '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                       //               'tireAccessories': []
//                       //             };
//                       //           }),
//                       //           'pit': (idSite == bmbsitarum.idSite ||
//                       //                   idSite == bmbhauling.idSite ||
//                       //                   idSite == bmbtabuhan.idSite ||
//                       //                   idSite == bibkgb.idSite)
//                       //               ? pit[selectedPit]
//                       //               : 'Default'
//                       //         });
//                       //       } else {
//                       //         // tambah data
//                       //         await firestore.collection('daily_pressure').add({
//                       //           // 'nama': (user),
//                       //           'idSite': idSite,
//                       //           'user':
//                       //               user['username'] ?? auth.currentUser!.email,
//                       //           'tanggal': DateTime.now().toIso8601String(),
//                       //           'unit': idUnit.text,
//                       //           'hm': hmUnit.text,
//                       //           'posisi': position.map((p) {
//                       //             final pIndex = position.indexOf(p);
//                       //             log('tekanan angin : ${p['pressure']}');

//                       //             return {
//                       //               'pos': '${pIndex + 1}',
//                       //               'pressure': (p['pressure']) ?? '0',
//                       //               'rating': (p['rating']) ?? '0',
//                       //               'adjusmentPressure':
//                       //                   (p['adjusmentPressure']) ?? '0',
//                       //               'luka': p['damageTire'],
//                       //               'idUnit': p['idUnit'],
//                       //               'idInventory': p['idInventory'],
//                       //               'tireSize': p['tireSize'],
//                       //               'idDaily':
//                       //                   '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                       //               'tireAccessories': []
//                       //             };
//                       //           }),
//                       //           'pit': (idSite == bmbsitarum.idSite ||
//                       //                   idSite == bmbhauling.idSite ||
//                       //                   idSite == bmbtabuhan.idSite ||
//                       //                   idSite == bibkgb.idSite)
//                       //               ? pit[selectedPit]
//                       //               : 'Default'
//                       //         });
//                       //       }
//                       //     } catch (e) {
//                       //       print('error bmb : $e');
//                       //     }
//                       //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                       //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       //       content: Text(
//                       //         'Successful save data, please check in home page',
//                       //         style: getWhiteTextStyle(),
//                       //       ),
//                       //       backgroundColor: green00968A,
//                       //     ));
//                       //     Navigator.pop(context);
//                       //   } catch (e) {
//                       //     log('kenapa gagal : $e');
//                       //   }
//                       // }
//                       function: () async {
//                         //// Validasi Tire Inspection
//                         final currentHm =
//                             double.tryParse(state.units[0].hm ?? '0') ?? 0;
//                         final newHm = double.tryParse(hmUnit.text ?? '0') ?? 0;

//                         // SMU/HM tidak boleh turun
//                         if (currentHm > newHm) {
//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                             content: Text(
//                               'SMU/HM tidak bisa berkurang',
//                               style: getWhiteTextStyle(),
//                             ),
//                             backgroundColor: Colors.red,
//                           ));
//                           return;
//                         }

//                         // SMU/HM tidak boleh nambah terlalu banyak
//                         if ((newHm - currentHm) > 1000) {
//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 'Perubahan SMU/HM tidak bisa lebih dari 1000',
//                                 style: getWhiteTextStyle(),
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }

//                         final List<String> errorsRtd = [];
//                         final List<String> errorsRating = [];

//                         for (int i = 0; i < state.units.length; i++) {
//                           final unit = state.units[i];

//                           // RTD tidak boleh naik
//                           final actualRtd =
//                               double.tryParse(unit.rtd.toString()) ?? 0;
//                           final actualOtd =
//                               double.tryParse(unit.otd.toString()) ?? 0;

//                           final inputRtd =
//                               double.tryParse(rtd1Controllers[i].text) ?? 0;
//                           final inputOtd =
//                               double.tryParse(rtd2Controllers[i].text) ?? 0;

//                           if (inputRtd > actualRtd) {
//                             errorsRtd.add(
//                               'Posisi ${unit.posisi}: RTD input ($inputRtd) melebihi RTD aktual ($actualRtd).',
//                             );
//                           }

//                           if (inputOtd > actualOtd) {
//                             errorsRtd.add(
//                               'Posisi ${unit.posisi}: OTD input ($inputOtd) melebihi OTD aktual ($actualOtd).',
//                             );
//                           }

//                           // Jika sudah rating x, tidak boleh kembali ke rating A,B,C
//                           const ratingScore = {
//                             'A': 4,
//                             'B': 3,
//                             'C': 2,
//                             'X': 1,
//                           };
//                           final actualRating = position[i]['prevRating']
//                               .toString()
//                               .toUpperCase()
//                               .trim();
//                           final inputRating = position[i]['rating']
//                               .toString()
//                               .toUpperCase()
//                               .trim();

//                           final actualScore = ratingScore[actualRating] ?? 0;
//                           final inputScore = ratingScore[inputRating] ?? 0;

//                           // Skip pengecekan jika prevRating kosong
//                           if (actualRating.isNotEmpty) {
//                             final actualScore = ratingScore[actualRating] ?? 0;
//                             final inputScore = ratingScore[inputRating] ?? 0;

//                             log('apakah rating membaik 3 : ${inputScore > actualScore}');

//                             if (inputScore > actualScore) {
//                               errorsRating.add(
//                                 'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
//                               );
//                             }
//                           }

//                           // if (inputScore > actualScore) {
//                           //   errorsRating.add(
//                           //     'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
//                           //   );
//                           // }
//                         }

//                         if (errorsRtd.isNotEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: const Duration(seconds: 6),
//                               content: Text(
//                                 errorsRtd.join('\n'),
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ),
//                           );
//                           return;
//                         }

//                         if (errorsRating.isNotEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: const Duration(seconds: 6),
//                               content: Text(
//                                 errorsRating.join('\n'),
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ),
//                           );
//                           return;
//                         }

//                         // input ke tire inspection
//                         try {
//                           position.removeWhere((element) =>
//                               element['pressure'] == '' &&
//                               (element['damageTire'] as List<dynamic>)
//                                   .isEmpty &&
//                               element['adjusmentPressure'] == '' &&
//                               element['rtd1'] == '' &&
//                               element['rtd2'] == '' &&
//                               element['rating'] == '' &&
//                               element['sn'] == '' &&
//                               element['remarks'] == '');

//                           final today = DateTime.now();
//                           final hari =
//                               '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
//                           final jam =
//                               '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}:${today.second.toString().padLeft(2, '0')}';
//                           final docId = '${hari}_${jam}';

//                           // Bangun list posisi sesuai struktur tire_inspection
//                           final List<Map<String, dynamic>> posisiList = [];
//                           log('unit tire inspection ${state.units}');
//                           final firstUnit = state.units[0];
//                           final String kunciUnit = firstUnit.kunciUnit ?? '';

//                           for (int i = 0; i < position.length; i++) {
//                             final unit = state.units[i];

//                             String? localImagePath;
//                             try {
//                               final imgList =
//                                   position[i]['image'] as List<dynamic>?;
//                               if (imgList != null && imgList.isNotEmpty) {
//                                 final raw = imgList[0] as String;
//                                 final parts = raw.split('|');
//                                 if (parts.isNotEmpty) {
//                                   localImagePath = parts[0];
//                                 }
//                               }
//                             } catch (e) {
//                               log('parse image error: $e');
//                             }

//                             final bool hasNewLocalImage =
//                                 localImagePath != null;

//                             posisiList.add({
//                               'position': position[i]['position'],
//                               'pressure': position[i]['pressure'],
//                               'adjusmentPressure': position[i]
//                                   ['adjusmentPressure'],
//                               'rating': position[i]['rating'],
//                               'rtd1': position[i]['rtd1'],
//                               'rtd2': position[i]['rtd2'],
//                               'sn': (position[i]['sn'] != null &&
//                                       position[i]['sn'] != '')
//                                   ? position[i]['sn']
//                                   : unit.sn,
//                               'remarks':
//                                   (position[i]['damageTire'] as List).isEmpty
//                                       ? damageType[0]
//                                       : position[i]['damageTire'][0],
//                               'damageTire':
//                                   (position[i]['damageTire'] as List).isEmpty
//                                       ? (damageType is List<String>)
//                                           ? damageType[0]
//                                           : damageType[0]['remark']
//                                       : position[i]['damageTire'],
//                               // 'condition': (position[i]['condition'] as List)
//                               //     .where((c) => c['checked'] == true)
//                               //     .map((c) => c['name'].toString())
//                               //     .toList(),
//                               'rimCondition': position[i]['rimCondition'],
//                               'idUnit': position[i]['idUnit'],
//                               'idInventory': position[i]['idInventory'],
//                               'tireSize': position[i]['tireSize'],
//                               'kunci_tire': unit.kunciTire,
//                               'hm': hmUnit.text,
//                               'images': [],
//                               'imagePending': hasNewLocalImage,
//                               'tireAccessories': [],
//                               'brand': firstUnit.brand,
//                               'pattern': firstUnit.pattern,
//                             });

//                             if (hasNewLocalImage) {
//                               // Pending upload akan di-handle setelah document dibuat
//                             }
//                           }

//                           // Cek apakah sudah ada dokumen tire_inspection hari ini untuk unit ini
//                           final startOfDay =
//                               DateTime(today.year, today.month, today.day);
//                           final endOfDay = DateTime(
//                               today.year, today.month, today.day, 23, 59, 59);

//                           final querySnapshot = await firestore
//                               .collection('tire_inspection')
//                               // .where('kunci_unit', isEqualTo: kunciUnit) // kunci_unit dari unit
//                               .where('hari', isEqualTo: hari)
//                               .where('unit', isEqualTo: firstUnit.unitNumber)
//                               // .where('tanggal',
//                               //     isGreaterThanOrEqualTo:
//                               //         startOfDay.toIso8601String())
//                               // .where('tanggal',
//                               //     isLessThanOrEqualTo:
//                               //         endOfDay.toIso8601String())
//                               .get();

//                           log('tire_inspection exists: ${querySnapshot.docs.isNotEmpty}');

//                           if (querySnapshot.docs.isNotEmpty) {
//                             // Update dokumen yang sudah ada
//                             final existingDocId = querySnapshot.docs.first.id;

//                             await firestore
//                                 .collection('tire_inspection')
//                                 .doc(existingDocId)
//                                 .update({
//                               'id': const Uuid().v4(),
//                               'id_site': idSite,
//                               'user': user['username'] ?? 'username',
//                               'user_email': auth.currentUser!.email,
//                               'unit': dataUnit['unitNumber'],
//                               'kunci_unit': kunciUnit,
//                               'hm': hmUnit.text,
//                               'hari': hari,
//                               'jam': jam,
//                               'tanggal': today.toIso8601String(),
//                               'pit': (idSite == bmbsitarum.idSite ||
//                                       idSite == bmbhauling.idSite ||
//                                       idSite == bmbtabuhan.idSite ||
//                                       idSite == bibkgb.idSite)
//                                   ? pit[selectedPit]
//                                   : 'Default',
//                               'posisi': posisiList,
//                               'brand': firstUnit.unitNumber,
//                               'pattern': firstUnit.pattern,
//                             });

//                             // Handle image upload per posisi
//                             for (int i = 0; i < position.length; i++) {
//                               String? localImagePath;
//                               try {
//                                 final imgList =
//                                     position[i]['image'] as List<dynamic>?;
//                                 if (imgList != null && imgList.isNotEmpty) {
//                                   final raw = imgList[0] as String;
//                                   final parts = raw.split('|');
//                                   if (parts.isNotEmpty)
//                                     localImagePath = parts[0];
//                                 }
//                               } catch (e) {
//                                 log('parse image error: $e');
//                               }
//                               if (localImagePath != null) {
//                                 UploadQueueService.to.addPending(
//                                     docId: existingDocId,
//                                     filePath: localImagePath,
//                                     posisiIndex: i);
//                               }
//                             }
//                           } else {
//                             // Buat dokumen baru dengan ID format tanggal_jam
//                             final newData = {
//                               'id': const Uuid().v4(),
//                               'id_site': idSite,
//                               'user': user['username'] ?? 'username',
//                               'user_email': auth.currentUser!.email,
//                               'unit': dataUnit['unitNumber'],
//                               'kunci_unit': kunciUnit,
//                               'hm': hmUnit.text,
//                               'hari': hari,
//                               'jam': jam,
//                               'tanggal': today.toIso8601String(),
//                               'pit': (idSite == bmbsitarum.idSite ||
//                                       idSite == bmbhauling.idSite ||
//                                       idSite == bmbtabuhan.idSite ||
//                                       idSite == bibkgb.idSite)
//                                   ? pit[selectedPit]
//                                   : 'Default',
//                               'posisi': posisiList,
//                             };

//                             final docRef = await firestore
//                                 .collection('tire_inspection')
//                                 .doc(docId)
//                                 .set(newData);

//                             // Handle image upload per posisi
//                             for (int i = 0; i < position.length; i++) {
//                               String? localImagePath;
//                               try {
//                                 final imgList =
//                                     position[i]['image'] as List<dynamic>?;
//                                 if (imgList != null && imgList.isNotEmpty) {
//                                   final raw = imgList[0] as String;
//                                   final parts = raw.split('|');
//                                   if (parts.isNotEmpty)
//                                     localImagePath = parts[0];
//                                 }
//                               } catch (e) {
//                                 log('parse image error: $e');
//                               }
//                               if (localImagePath != null) {
//                                 UploadQueueService.to.addPending(
//                                   docId: docId,
//                                   filePath: localImagePath,
//                                   posisiIndex: i,
//                                 );
//                               }
//                             }
//                           }

//                           //     // input ke daily check pressure
//                           try {
//                             final today = DateTime.now();
//                             final startOfDay =
//                                 DateTime(today.year, today.month, today.day);
//                             final endOfDay = DateTime(
//                                 today.year, today.month, today.day, 23, 59, 59);
//                             final formattedToday =
//                                 '${today.month.toString().padLeft(2, '0')}' // MM
//                                 '${today.day.toString().padLeft(2, '0')}' // DD
//                                 '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

//                             final querySnapshot = await FirebaseFirestore
//                                 .instance
//                                 .collection('daily_pressure')
//                                 .where('unit',
//                                     isEqualTo: dataUnit['unitNumber'])
//                                 .where('tanggal',
//                                     isGreaterThanOrEqualTo:
//                                         startOfDay.toIso8601String())
//                                 .where('tanggal',
//                                     isLessThanOrEqualTo:
//                                         endOfDay.toIso8601String())
//                                 .get();

//                             print(
//                                 'Documents found: ${querySnapshot.docs.length}');

//                             if (querySnapshot.docs.isNotEmpty) {
//                               final docId = querySnapshot.docs.first.id;

//                               // revisi data
//                               await firestore
//                                   .collection('daily_pressure')
//                                   .doc(docId)
//                                   .update({
//                                 'idSite': idSite,
//                                 'user':
//                                     user['username'] ?? auth.currentUser!.email,
//                                 'tanggal': DateTime.now().toIso8601String(),
//                                 'unit': idUnit.text,
//                                 'hm': hmUnit.text,
//                                 'posisi': position.map((p) {
//                                   final pIndex = position.indexOf(p);

//                                   log('tekanan angin : ${p['pressure']}');
//                                   return {
//                                     'pos': '${pIndex + 1}',
//                                     'pressure': (p['pressure']) ?? '0',
//                                     'rating': (p['rating']) ?? '',
//                                     'adjusmentPressure':
//                                         (p['adjusmentPressure']) ?? '0',
//                                     'luka': p['damageTire'],
//                                     'idUnit': p['idUnit'],
//                                     'idInventory': p['idInventory'],
//                                     'tireSize': p['tireSize'],
//                                     'idDaily':
//                                         '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                                     'tireAccessories': []
//                                   };
//                                 }),
//                                 'pit': (idSite == bmbsitarum.idSite ||
//                                         idSite == bmbhauling.idSite ||
//                                         idSite == bmbtabuhan.idSite ||
//                                         idSite == bibkgb.idSite)
//                                     ? pit[selectedPit]
//                                     : 'Default'
//                               });
//                             } else {
//                               // tambah data
//                               await firestore.collection('daily_pressure').add({
//                                 // 'nama': (user),
//                                 'idSite': idSite,
//                                 'user':
//                                     user['username'] ?? auth.currentUser!.email,
//                                 'tanggal': DateTime.now().toIso8601String(),
//                                 'unit': idUnit.text,
//                                 'hm': hmUnit.text,
//                                 'posisi': position.map((p) {
//                                   final pIndex = position.indexOf(p);
//                                   log('tekanan angin : ${p['pressure']}');

//                                   return {
//                                     'pos': '${pIndex + 1}',
//                                     'pressure': (p['pressure']) ?? '0',
//                                     'rating': (p['rating']) ?? '0',
//                                     'adjusmentPressure':
//                                         (p['adjusmentPressure']) ?? '0',
//                                     'luka': p['damageTire'],
//                                     'idUnit': p['idUnit'],
//                                     'idInventory': p['idInventory'],
//                                     'tireSize': p['tireSize'],
//                                     'idDaily':
//                                         '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                                     'tireAccessories': []
//                                   };
//                                 }),
//                                 'pit': (idSite == bmbsitarum.idSite ||
//                                         idSite == bmbhauling.idSite ||
//                                         idSite == bmbtabuhan.idSite ||
//                                         idSite == bibkgb.idSite)
//                                     ? pit[selectedPit]
//                                     : 'Default'
//                               });
//                             }
//                           } catch (e) {
//                             print('error bmb : $e');
//                           }

//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                             content: Text(
//                               'Successful save data, please check in home page',
//                               style: getWhiteTextStyle(),
//                             ),
//                             backgroundColor: green00968A,
//                           ));
//                           Navigator.pop(context);
//                         } catch (e) {
//                           log('kenapa gagal : $e');
//                         }
//                       }),
//                 );
//               }
//               return Container();
//             },
//           ),
//           const SizedBox(
//             height: 12,
//           ),
//         ],
//       ),
//     );
//   }
// }

// AI selection
// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:app_settings/app_settings.dart';
// import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
// import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
// import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
// import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart'
//     as connectedDevicesState;
// import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart';
// import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_cubit.dart';
// import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_state.dart';
// import 'package:camos/core/services/api_service.dart';
// import 'package:camos/core/services/model/tire_damage_ai.dart';
// import 'package:camos/core/utils/bluetooth/utils/bluetooth_utils.dart';
// import 'package:camos/core/utils/data/id_site.dart';
// import 'package:camos/pages/home/home_state.dart';
// import 'package:camos/pages/pressure_gauge_digital/trial/scan_device_page.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/bounding_box_painter.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/upload_queue_service.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:get/get.dart';
// import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
// import 'package:path_provider/path_provider.dart';
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
// import 'package:carousel_slider/carousel_controller.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';

// import 'widget/ai_loading_widget.dart';

// class TireInspectionFormPage extends StatefulWidget {
//   static const routeName = '/pgd-page';
//   const TireInspectionFormPage({super.key});

//   @override
//   State<TireInspectionFormPage> createState() => _TireInspectionFormPageState();
// }

// class _TireInspectionFormPageState extends State<TireInspectionFormPage>
//     with WidgetsBindingObserver {
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth auth = FirebaseAuth.instance;
//   final HomeState homeState = Get.find<HomeState>();

//   bool _isInit = true;
//   int selectedMenu = 1;
//   var map = {};
//   String idSite = '';
//   bool isSaved = false;
//   Map<String, dynamic> dataUnit = {};
//   String? _hmInitializedForUnit;

//   TextEditingController idUnit = TextEditingController(text: '');
//   TextEditingController hmUnit = TextEditingController(text: '');
//   TextEditingController pressureCtrl = TextEditingController(text: '');
//   TextEditingController remarksCtrl = TextEditingController(text: '');
//   TextEditingController damageCtrl = TextEditingController(text: '');
//   TextEditingController rtd1 = TextEditingController(text: '');
//   TextEditingController rtd2 = TextEditingController(text: '');
//   List<TextEditingController> remarksControllers = [];
//   List<TextEditingController> snControllers = [];
//   List<TextEditingController> rtd1Controllers = [];
//   List<TextEditingController> rtd2Controllers = [];

//   SwiperController swiperController = SwiperController();

//   Map<int, TireDamageAi> aiResults = {};
//   Map<int, bool> loadingAI = {};
//   Map<int, double> imageWidths = {};
//   Map<int, double> imageHeights = {};

//   List<String>? _ratingCache;
//   List<dynamic>? _damageCache;

//   String selectedUnit = '';
//   List<String> checkedCategories = [];
//   List<Map<String, dynamic>> checkedCategoriesManual = [
//     {'name': 'Reseal Oring', 'checked': false},
//     {'name': 'Rim Condition', 'checked': false},
//     {'name': 'Inflate Tire', 'checked': false},
//     {'name': 'Lock Driver', 'checked': false},
//     {'name': 'Slide Lock', 'checked': false},
//     {'name': 'Valve Cap', 'checked': false},
//     {'name': 'Valve Protector', 'checked': false},
//     {'name': 'Stud and Nut', 'checked': false},
//   ];

//   List<bool> checkedListCategory = List<bool>.filled(8, false);
//   String selectedTireDamage = '';
//   String remarks = '';
//   String rtd = '';
//   List<String> listImg = [];
//   Map<String, dynamic> user = {};
//   bool _listenerAdded = false;
//   int checkAmount = 0;
//   int selectedRoute = 0;
//   List<List<int>> inspectRoute = [
//     [0, 1, 2, 3, 4, 5],
//     [0, 2, 3, 4, 5, 1],
//     [1, 5, 4, 3, 2, 0],
//   ];

//   List<String> pressure = [
//     '0',
//     '95',
//     '100',
//     '105',
//     '110',
//     '115',
//     '120',
//     '125',
//     '130',
//     '135',
//   ];
//   List<Map<String, dynamic>> position = [];

//   // List<String> damageType = [
//   //   'Good Condition',
//   //   'Accident',
//   //   'Bead Crack',
//   //   'Boulder',
//   //   'Bulging',
//   //   'Bead Damage',
//   //   'Chaffer Separation',
//   //   'Dog Bound',
//   //   'Foreign Object',
//   //   'Heat Separation',
//   //   'Inner Linner Separation',
//   //   'Impact',
//   //   'Repair Failure',
//   //   'Radial Crack',
//   //   'Run Flat',
//   //   'Sidewall Crack',
//   //   'Sidewall Cut',
//   //   'Sidewall Cut 2',
//   //   'Sidewall Cut 3',
//   //   'Sidewall Separation',
//   //   'Shoulder Cut',
//   //   'Shoulder Separation',
//   //   'Tread Chipping',
//   //   'Tread Chunking',
//   //   'Tread Lifting',
//   //   'Tread Cut',
//   //   'Tread Cut Separation',
//   //   'Worn Out',
//   // ];

//   List<Map<String, dynamic>> damageType = [];
//   bool loadingDamages = true;

//   List<String> selectedDamage = [];

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

//   List<String> rating = [
//     'A',
//     'B',
//     'C',
//     'X',
//   ];

//   List<String> pit = [];
//   int selectedPit = -1;

//   void showRimInspectionDialog(int tireIndex) {
//     final originalList = position[tireIndex]['rimCondition'];

//     /// 🔥 COPY DATA DULU (supaya Close tidak menyimpan)
//     List<Map<String, dynamic>> tempList =
//         originalList.map<Map<String, dynamic>>((item) {
//       return {
//         'title': item['title'],
//         'condition': item['condition'],
//         'remark': item['remark'],
//       };
//     }).toList();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, stState) {
//             return AlertDialog(
//               title: Text(
//                 'Periksa Kondisi : ',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: List.generate(tempList.length, (i) {
//                       final rimItem = tempList[i];
//                       final bool isGood = rimItem['condition'] == 'Good';
//                       final bool isPoor = rimItem['condition'] == 'Poor';

//                       return Container(
//                         margin: EdgeInsets.only(bottom: 14),
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: isGood
//                               ? Colors.green.withOpacity(0.12)
//                               : Colors.red.withOpacity(0.12),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             /// TITLE
//                             Text(
//                               rimItem['title'],
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),

//                             SizedBox(height: 10),

//                             /// GOOD / POOR
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       stState(() {
//                                         rimItem['condition'] = 'Good';
//                                       });
//                                     },
//                                     child: Container(
//                                       padding:
//                                           EdgeInsets.symmetric(vertical: 10),
//                                       decoration: BoxDecoration(
//                                         color: isGood
//                                             ? Colors.green
//                                             : Colors.grey[300],
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       alignment: Alignment.center,
//                                       child: Text(
//                                         'GOOD',
//                                         style: TextStyle(
//                                           color: isGood
//                                               ? Colors.white
//                                               : Colors.black,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: 10),
//                                 Expanded(
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       stState(() {
//                                         rimItem['condition'] = 'Poor';
//                                       });
//                                     },
//                                     child: Container(
//                                       padding:
//                                           EdgeInsets.symmetric(vertical: 10),
//                                       decoration: BoxDecoration(
//                                         color: isPoor
//                                             ? Colors.red
//                                             : Colors.grey[300],
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       alignment: Alignment.center,
//                                       child: Text(
//                                         'POOR',
//                                         style: TextStyle(
//                                           color: isPoor
//                                               ? Colors.white
//                                               : Colors.black,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             SizedBox(height: 10),

//                             // Job Description
//                             TextField(
//                               controller: TextEditingController(
//                                   text: rimItem['jobDescription'] ?? '')
//                                 ..selection = TextSelection.fromPosition(
//                                   TextPosition(
//                                       offset: (rimItem['jobDescription'] ?? '')
//                                           .length),
//                                 ),
//                               style: TextStyle(fontSize: 12),
//                               decoration: InputDecoration(
//                                 hintText: 'Job Description',
//                                 isDense: true,
//                                 contentPadding: EdgeInsets.symmetric(
//                                     horizontal: 8, vertical: 6),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 filled: true,
//                                 fillColor: Colors.white,
//                               ),
//                               maxLines: 1,
//                               onChanged: (val) {
//                                 rimItem['jobDescription'] = val;
//                               },
//                             ),

//                             SizedBox(height: 10),

//                             /// REMARK
//                             TextField(
//                               controller: TextEditingController(
//                                   text: rimItem['remark'] ?? '')
//                                 ..selection = TextSelection.fromPosition(
//                                   TextPosition(
//                                       offset: (rimItem['remark'] ?? '').length),
//                                 ),
//                               style: TextStyle(fontSize: 12), // kecilkan font
//                               decoration: InputDecoration(
//                                 hintText: 'Remark...',
//                                 isDense: true, // bikin lebih compact
//                                 contentPadding: EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 6, // lebih kecil
//                                 ),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 filled: true,
//                                 fillColor: Colors.white,
//                               ),
//                               maxLines: 2, // supaya tidak terlalu tinggi
//                               onChanged: (val) {
//                                 rimItem['remark'] = val;
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ),
//                 ),
//               ),

//               /// 🔥 ACTION BUTTONS
//               actions: [
//                 /// CLOSE (TIDAK SIMPAN)
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: Text(
//                     'Close',
//                     style: getRedTextStyle(fontWeight: w500),
//                   ),
//                 ),

//                 /// SAVE (SIMPAN KE position)
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       position[tireIndex]['rimCondition'] = tempList;
//                     });

//                     Navigator.pop(context);
//                   },
//                   child: Text(
//                     'Save',
//                     style: getWhiteTextStyle(fontWeight: w500),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   void initState() {
//     idSite = homeState.currentSiteId;
//     _loadDamages();

//     super.initState();
//     requestPlacePermission();

//     context.read<BluetoothOnOffCubit>().checkBluetoothStatus();
//     final connectedCubit = context.read<ConnectedDevicesCubit>();
//     log('connected cubit : $connectedCubit');
//     connectedCubit.fetchConnectedDevices(); // HANYA MEMULAI fetch

//     // callTires();
//     WidgetsBinding.instance.addObserver(this);
//     getUser();
//   }

//   Future<void> loadPreviousRating(
//       int index, String unit, String kunciTire) async {
//     print('load previous rating unit : $unit');
//     try {
//       final snapshot = await firestore
//           .collection('tire_inspection')
//           .where('unit', isEqualTo: unit) // ✅ FILTER UNIT
//           .orderBy('tanggal', descending: true)
//           .limit(1) // ✅ hanya dokumen terbaru unit itu
//           .get();

//       log('load previous rating : ${snapshot.docs}');

//       if (snapshot.docs.isEmpty) return;

//       final doc = snapshot.docs.first;

//       final List<dynamic> posisiList = doc['posisi'];

//       for (final pos in posisiList) {
//         if (pos['kunci_tire'] == kunciTire) {
//           final prevRating = pos['rating'];

//           if (prevRating != null) {
//             setState(() {
//               position[index]['rating'] =
//                   prevRating is String ? prevRating : [prevRating];
//               position[index]['prevRating'] =
//                   prevRating is String ? prevRating : [prevRating];
//             });

//             log('AUTO RATING FOUND: $prevRating');
//             return;
//           }
//         }
//       }
//     } catch (e) {
//       log('loadPreviousRating error: $e');
//     }
//   }

//   Future<void> loadPreviousDamage(
//       int index, String unit, String kunciTire) async {
//     print('load previous damage unit : $unit');
//     try {
//       final snapshot = await firestore
//           .collection('tire_inspection')
//           .where('unit', isEqualTo: unit) // ✅ FILTER UNIT
//           .orderBy('tanggal', descending: true)
//           .limit(1) // ✅ hanya dokumen terbaru unit itu
//           .get();

//       log('load previous damage : ${snapshot.docs}');

//       if (snapshot.docs.isEmpty) return;

//       final doc = snapshot.docs.first;

//       final List<dynamic> posisiList = doc['posisi'];

//       for (final pos in posisiList) {
//         if (pos['kunci_tire'] == kunciTire) {
//           final prevDamage = pos['damageTire'];
//           final prevRemarks = pos['remarks'];

//           if (prevDamage != null) {
//             setState(() {
//               position[index]['damageTire'] =
//                   prevDamage is List ? prevDamage : [prevDamage];
//             });

//             log('AUTO DAMAGE FOUND: $prevDamage');
//             return;
//           }

//           if (prevRemarks != null && prevRemarks != '') {
//             setState(() {
//               position[index]['remarks'] = prevRemarks;
//             });

//             log('AUTO REMARKS FOUND: $prevRemarks');
//             return;
//           }
//         }
//       }
//     } catch (e) {
//       log('loadPreviousDamage error: $e');
//     }
//   }

//   // Future<void> _loadDamages() async {
//   //   try {
//   //     final query =
//   //         await firestore.collection('list_tire_damage_inspection').get();

//   //     final docs = query.docs.where((doc) {
//   //       return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(doc.id);
//   //     }).toList();

//   //     docs.sort((a, b) => b.id.compareTo(a.id));

//   //     final latestDoc = docs.first;

//   //     final data = latestDoc.data();

//   //     log('docs luka ban : $data');

//   //     if (data != null && data['damages'] != null) {
//   //       final List<dynamic> raw = data['damages'];

//   //       List<Map<String, dynamic>> sortedList =
//   //           raw.map<Map<String, dynamic>>((e) {
//   //         return Map<String, dynamic>.from(e);
//   //       }).toList();

//   //       sortedList.sort((a, b) {
//   //         final aRemark = (a['remark'] ?? '').toString().toLowerCase();
//   //         final bRemark = (b['remark'] ?? '').toString().toLowerCase();

//   //         final aGood = aRemark.contains('good');
//   //         final bGood = bRemark.contains('good');

//   //         if (aGood && !bGood) return -1;
//   //         if (!aGood && bGood) return 1;

//   //         return aRemark.compareTo(bRemark);
//   //       });

//   //       setState(() {
//   //         damageType = sortedList;
//   //         loadingDamages = false;
//   //       });
//   //     } else {
//   //       setState(() {
//   //         loadingDamages = false;
//   //       });
//   //     }
//   //   } catch (e) {
//   //     debugPrint('Error load damages: $e');

//   //     setState(() {
//   //       loadingDamages = false;
//   //     });
//   //   }
//   // }

//   Future<void> _loadDamages() async {
//     try {
//       Map<String, dynamic>? data;
//       final sisIdSite = await getIdSiteSIS();
//       final isSisIdSite = sisIdSite.any((site) => site.idSite == idSite);

//       if (isSisIdSite) {
//         final doc = await firestore
//             .collection('list_tire_damage_inspection')
//             .doc('sis062026')
//             .get();

//         if (doc.exists) {
//           data = doc.data();
//         }
//       } else {
//         final query =
//             await firestore.collection('list_tire_damage_inspection').get();

//         final docs = query.docs.where((doc) {
//           return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(doc.id);
//         }).toList();

//         docs.sort((a, b) => b.id.compareTo(a.id));

//         if (docs.isNotEmpty) {
//           data = docs.first.data();
//         }
//       }

//       log('docs luka ban : $data');

//       if (data != null && data['damages'] != null) {
//         final List<dynamic> raw = data['damages'];

//         List<Map<String, dynamic>> sortedList =
//             raw.map<Map<String, dynamic>>((e) {
//           return Map<String, dynamic>.from(e);
//         }).toList();

//         sortedList.sort((a, b) {
//           final aRemark = (a['remark'] ?? '').toString().toLowerCase();
//           final bRemark = (b['remark'] ?? '').toString().toLowerCase();

//           final aGood = aRemark.contains('good');
//           final bGood = bRemark.contains('good');

//           if (aGood && !bGood) return -1;
//           if (!aGood && bGood) return 1;

//           return aRemark.compareTo(bRemark);
//         });

//         setState(() {
//           damageType = sortedList;
//           loadingDamages = false;
//         });
//       } else {
//         setState(() {
//           loadingDamages = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error load damages: $e');

//       setState(() {
//         loadingDamages = false;
//       });
//     }
//   }

//   getUser() async {
//     user = await getUserPreferences();
//     log('username : ${user}');
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);

//     idUnit.dispose();
//     hmUnit.dispose();
//     pressureCtrl.dispose();
//     remarksCtrl.dispose();
//     damageCtrl.dispose();
//     rtd1.dispose();
//     rtd2.dispose();

//     for (final controller in remarksControllers) {
//       controller.dispose();
//     }

//     for (final controller in snControllers) {
//       controller.dispose();
//     }

//     for (final controller in rtd1Controllers) {
//       controller.dispose();
//     }

//     for (final controller in rtd2Controllers) {
//       controller.dispose();
//     }

//     swiperController.dispose();

//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_isInit) {
//       final args = ModalRoute.of(context)?.settings.arguments;
//       if (args != null) {
//         dataUnit = args as Map<String, dynamic>;
//         log('TireInspectionPage: dataUnit berhasil diambil -> $dataUnit');

//         // Panggil callTires() setelah dataUnit pasti terisi
//         callTires();
//       } else {
//         log('TireInspectionPage: ERROR! Argumen navigasi null.');
//       }

//       _isInit = false; // Set flag agar tidak dijalankan lagi
//     }
//   }

//   List<BluetoothDevice> devices = [];
//   String tmpPressure = '';
//   final Box<TireInspectPictureEntity> imageBox =
//       store.box<TireInspectPictureEntity>();

//   insertPit() {
//     setState(() {
//       // if (idSite == '52') {
//       //   pit.add('Utara');
//       //   pit.add('Selatan');
//       //   pit.add('RML');
//       //   pit.add('WS');
//       // }
//     });
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

//   Future<void> _analyzeDamageWithAI(int index) async {
//     if (loadingAI[index] == true) return;

//     final images = position[index]['image'] as List<dynamic>?;
//     if (images == null || images.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           backgroundColor: Colors.red,
//           content: Text('Please take a picture first.'),
//         ),
//       );
//       return;
//     }

//     final rawImage = images.first.toString();
//     final imagePath = rawImage.split('|').first;
//     final imageFile = File(imagePath);

//     if (!await imageFile.exists()) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           backgroundColor: Colors.red,
//           content: Text('Image file was not found. Please take a new picture.'),
//         ),
//       );
//       return;
//     }

//     setState(() {
//       loadingAI[index] = true;
//       aiResults.remove(index);
//     });

//     try {
//       final bytes = await imageFile.readAsBytes();
//       final decodedImage = await decodeImageFromList(bytes);
//       final base64Image = base64Encode(bytes);
//       final token = await ApiService.getValidToken();
//       final result = await ApiService.postPredictImageAI(
//         token,
//         base64Image,
//       );

//       if (result == null) {
//         throw Exception('AI analysis returned an empty result.');
//       }

//       if (!mounted) return;
//       setState(() {
//         imageWidths[index] = decodedImage.width.toDouble();
//         imageHeights[index] = decodedImage.height.toDouble();
//         aiResults[index] = result;
//       });

//       log('tire damage ai : $result');
//     } catch (e) {
//       log('analyze tire damage ai error : $e');

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text('Failed to analyze damage with AI: $e'),
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           loadingAI[index] = false;
//         });
//       }
//     }
//   }

//   void callTires() async {
//     String userAccessId = homeState.userAccessId.value;
//     if (mounted) {
//       if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
//         idUnit.text = dataUnit['unitNumber'];
//         // hmUnit.text = dataUnit['hm'];
//         context.read<TireBloc>().add(GetUnitTiresEvent(
//             idSite: idSite, unitNumber: dataUnit['unitNumber']));
//       }
//     }

//     insertPit();
//   }

//   void handleDataRemarks(String remarks, int index) {
//     this.remarks = remarks;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   void handleDataRTD(String rtd, int index) {
//     this.rtd = rtd;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   void applyPressureData(String pressureValue) {
//     setState(() {
//       final firstNumber = pressureValue;

//       if (checkAmount < position.length) {
//         int targetIndex = inspectRoute[selectedRoute][checkAmount];
//         log('target position : ${targetIndex}');
//         log('target pressure : ${firstNumber}');

//         // Update Map di index tersebut
//         position[targetIndex]["pressure"] = firstNumber;

//         checkAmount++;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     pit.clear();
//     // if (idSite == '52') {
//     //   pit.add('Utara');
//     //   pit.add('Selatan');
//     //   pit.add('RML');
//     //   pit.add('WS');
//     // }
//     switch (idSite) {
//       case '52':
//         pit.add('Utara');
//         pit.add('Selatan');
//         pit.add('RML');
//         pit.add('WS');
//         break;
//       case '137':
//         pit.add('Japun');
//         pit.add('PCE');
//         break;
//       case '35':
//         pit.add('Tabuhan');
//         pit.add('EBL');
//         pit.add('Workshop');
//         break;
//       case '65':
//         pit.add('Room B1 Selatan');
//         pit.add('TIA');
//         pit.add('Serongga');
//         pit.add('CSA Selatan');
//         pit.add('WS');
//         break;
//       case '166':
//         pit.add('WS');
//         pit.add('Pondok Operator');
//         pit.add('CSA Bagaspati');
//         pit.add('Pit Stop Toll');
//         break;
//     }
//     print('dipanggil (pgd)');
//     dataUnit =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Padding(
//           padding: const EdgeInsets.only(top: 18.0),
//           child: Text(
//             'Tire Inspection',
//             textAlign: TextAlign.center,
//             style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
//           ),
//         ),
//         centerTitle: true,
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 16),
//           child: Container(
//             margin: const EdgeInsets.only(top: 14),
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             decoration: BoxDecoration(
//               color: white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: black),
//             ),
//             child: IconButton(
//                 onPressed: () {
//                   if (isSaved) {
//                     pushReplace(context, HomePage.routeName);
//                   } else {
//                     back(context);
//                   }
//                 },
//                 icon: const Icon(
//                   Icons.arrow_back_ios,
//                   color: black,
//                   size: 24,
//                 )),
//           ),
//         ),
//       ),
//       body: SafeArea(
//           child: BlocConsumer<TireBloc, TireState>(
//         listener: (context, state) {
//           if (state is TiresLoadedState) {
//             final firstUnit = state.units.first;
//             final currentUnitNumber = firstUnit.unitNumber ?? '';

//             if (_hmInitializedForUnit != currentUnitNumber) {
//               hmUnit.text = idSite == bmbhauling.idSite
//                   ? ''
//                   : firstUnit.hm?.toString() ?? '';

//               _hmInitializedForUnit = currentUnitNumber;
//             }

//             position.clear();

//             for (int i = 0; i < state.units.length; i++) {
//               final unit = state.units[i];
//               for (int i = 0; i < position.length; i++) {
//                 final unit = state.units[i];

//                 if (unit.kunciTire != null) {
//                   loadPreviousRating(
//                       i, unit.unitNumber ?? '', unit.kunciTire ?? '');
//                   loadPreviousDamage(
//                       i, unit.unitNumber ?? '', unit.kunciTire ?? '');
//                 }
//               }
//               remarksControllers.add(TextEditingController(text: ''));
//               snControllers.add(TextEditingController(text: ''));
//               rtd1Controllers.add(
//                 TextEditingController(text: unit.rtd?.toString() ?? ''),
//               );

//               rtd2Controllers.add(
//                 TextEditingController(text: unit.otd?.toString() ?? ''),
//               );
//               position.add({
//                 'position': i + 1,
//                 'pressure': '',
//                 'adjusmentPressure': '',
//                 'hm': '',
//                 'damageTire': [],
//                 'rtd1': unit.rtd?.toString() ?? '',
//                 'rtd2': unit.otd?.toString() ?? '',
//                 'remarks': '',
//                 'sn': unit.sn,
//                 'rating': '',
//                 'prevRating': '',
//                 'image': [],
//                 'idInventory': unit.idinventory,
//                 'idUnit': unit.idUnit,
//                 'tireSize': unit.size,
//                 // 'condition': [
//                 //   {'name': 'Reseal Oring', 'checked': false},
//                 //   {'name': 'Rim Condition', 'checked': false},
//                 //   {'name': 'Inflate Tire', 'checked': false},
//                 //   {'name': 'Lock Driver', 'checked': false},
//                 //   {'name': 'Slide Lock', 'checked': false},
//                 //   {'name': 'Valve Cap', 'checked': false},
//                 //   {'name': 'Valve Protector', 'checked': false},
//                 //   {'name': 'Stud and Nut', 'checked': false},
//                 // ],
//                 'rimCondition': [
//                   {
//                     'title': 'RIM BASE',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'FLANGE',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'LOCK RING',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'VALVE (TERPASANG/TIDAK TERPASANG)',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'CORE VALVE',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'NUT DAN STUD RODA',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                 ],
//                 'tireAccessories': []
//               });
//             }
//             log('message position tire inspect : ${position}');
//           }
//         },
//         builder: (context, state) {
//           if (state is TireLoadingState) {
//             return Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//           if (state is TiresLoadedState) {
//             final units = state.units;

//             return SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   children: [
//                     (pit.isNotEmpty)
//                         ? Row(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               Icon(
//                                 Icons.ev_station,
//                                 size: 38,
//                               ),
//                               const SizedBox(
//                                 width: 12,
//                               ),
//                               Text(
//                                 'Unit Location',
//                                 style: getBlackTextStyle(
//                                     fontSize: 18, fontWeight: w700),
//                               ),
//                             ],
//                           )
//                         : Container(),
//                     SizedBox(
//                       height: (pit.isNotEmpty) ? 24 : 0,
//                     ),
//                     (pit.isNotEmpty)
//                         ? Center(
//                             child: Wrap(
//                               spacing: 8.0, // Jarak horizontal antar tombol
//                               children: pit.map((e) {
//                                 final pitIndex = pit.indexOf(e);
//                                 return ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: (selectedPit == pitIndex)
//                                         ? Colors.orange
//                                         : greyF7F8F9,
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       selectedPit = pitIndex;
//                                     });
//                                   },
//                                   child: Text(
//                                     e,
//                                     style: (selectedPit == pitIndex)
//                                         ? getWhiteTextStyle()
//                                         : getBlackTextStyle(),
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                           )
//                         : Container(),
//                     SizedBox(
//                       height: (pit.isNotEmpty) ? 24 : 0,
//                     ),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.front_loader,
//                                     color: Colors.orange,
//                                     size: 38,
//                                   ),
//                                   const SizedBox(
//                                     width: 12,
//                                   ),
//                                   Text(
//                                     'UNIT',
//                                     style: getBlackTextStyle(
//                                         fontWeight: w700, fontSize: 18),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                     isReadOnly: true,
//                                     controller: TextEditingController(
//                                       text: units[0].unitNumber,
//                                     ),
//                                     hint: ''),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(
//                           width: 12,
//                         ),
//                         Expanded(
//                           child: Column(
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.watch,
//                                     color: Colors.red,
//                                     size: 38,
//                                   ),
//                                   const SizedBox(
//                                     width: 12,
//                                   ),
//                                   Text(
//                                     (idSite == bmbhauling.idSite &&
//                                             idSite == '1')
//                                         ? 'KM Unit'
//                                         : 'HM Unit',
//                                     style: getBlackTextStyle(
//                                         fontWeight: w700, fontSize: 18),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                   controller: hmUnit,
//                                   isDecimalOnly: true,
//                                   type: const TextInputType.numberWithOptions(
//                                     decimal: true,
//                                   ),
//                                   hint:
//                                       'Fill ${idSite == bmbhauling.idSite ? 'KM' : 'HM'}',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     BlocBuilder<ConnectedDevicesCubit, ConnectedDevicesState>(
//                       builder: (context, cState) {
//                         // Asumsikan perangkat TPMS adalah yang terhubung jika statusnya Success
//                         final isConnected =
//                             cState is ConnectedDevicesLoadedState &&
//                                 cState.connectedDevices.isNotEmpty;

//                         // Cari perangkat yang terhubung yang memiliki nama yang relevan
//                         // (Anda harus menyesuaikan logika pencarian ini sesuai nama perangkat BT Anda)
//                         final BluetoothDevice? connectedDevice = isConnected
//                             ? cState.connectedDevices
//                                 .firstWhereOrNull((d) => d.advName.isNotEmpty)
//                             : null;

//                         final String buttonText = isConnected
//                             ? 'Connected: ${connectedDevice?.advName ?? connectedDevice?.remoteId.str}'
//                             : 'Scan Devices';

//                         return ButtonWidget(
//                           // Warna tombol berdasarkan status koneksi
//                           color: isConnected ? green00968A : Colors.blue,
//                           name: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.bluetooth,
//                                 color: white,
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 buttonText,
//                                 style: getWhiteTextStyle(),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                           function: () async {},
//                         );
//                       },
//                     ),
//                     BlocListener<BluetoothOnOffCubit, BluetoothOnOffState>(
//                       listener: (context, onOffState) {
//                         if (onOffState is BluetoothOnState) {
//                           context
//                               .read<ConnectedDevicesCubit>()
//                               .fetchConnectedDevices();
//                         }
//                       },
//                       child: BlocConsumer<ConnectedDevicesCubit,
//                           ConnectedDevicesState>(
//                         listener: (context, state) {
//                           if (state is ConnectedDevicesLoadedState &&
//                               state.connectedDevices.isNotEmpty) {
//                             context
//                                 .read<DiscoverServicesCubit>()
//                                 .discoverServices(state.connectedDevices.first);
//                           }
//                         },
//                         builder: (context, state) {
//                           if (state is ConnectedDevicesLoadedState) {
//                             // return _buildConnectedDeviceUI(
//                             //     state.connectedDevices);
//                             if (state.connectedDevices.isNotEmpty) {
//                               BlocProvider.of<DiscoverServicesCubit>(
//                                 context,
//                               ).discoverServices(state.connectedDevices.first);
//                             }
//                             return BlocConsumer<DiscoverServicesCubit,
//                                 DiscoverServiceState>(
//                               listener: (context, discoverState) {
//                                 if (discoverState is ServicesLoadedState) {
//                                   final services = discoverState.services;
//                                   log('services pgd : $services');

//                                   if (!_listenerAdded) {
//                                     _listenerAdded = true;
//                                     for (BluetoothService service in services) {
//                                       for (BluetoothCharacteristic characteristic
//                                           in service.characteristics) {
//                                         if (characteristic.properties.notify) {
//                                           characteristic.onValueReceived
//                                               .listen((value) {
//                                             final notifInString =
//                                                 String.fromCharCodes(value);
//                                             log("angin bergejolak: $notifInString");

//                                             debugPrint(
//                                               "debugBluetoothNotification*************",
//                                             );
//                                             debugPrint(
//                                               "debugBluetoothNotification: charName: ${BluetoothUtils.getBluetoothChar(characteristic.characteristicUuid.str)}",
//                                             );

//                                             debugPrint(
//                                               "notifhohoho: stringNotif: $notifInString",
//                                             );
//                                             setState(() {
//                                               String press = '';

//                                               if (notifInString.contains('|')) {
//                                                 int floorPressure =
//                                                     double.parse(
//                                                   notifInString.split(
//                                                     '|',
//                                                   )[0],
//                                                 ).floor();

//                                                 // int floorTemperature =
//                                                 //     double.parse(
//                                                 //       notifInString.split(
//                                                 //         '|',
//                                                 //       )[1],
//                                                 //     ).floor();
//                                                 // temperature = floorTemperature
//                                                 //     .toString();
//                                                 applyPressureData(
//                                                     floorPressure.toString());
//                                               } else {
//                                                 int floorPressure =
//                                                     double.parse(
//                                                   notifInString,
//                                                 ).floor();
//                                                 press.toString();
//                                                 applyPressureData(
//                                                     floorPressure.toString());
//                                               }
//                                             });

//                                             debugPrint(
//                                               "debugBluetoothNotification*************",
//                                             );
//                                           });

//                                           characteristic
//                                               .setNotifyValue(true); // WAJIB
//                                         }
//                                       }
//                                     }
//                                   }
//                                 }
//                               },
//                               builder: (context, discoverState) {
//                                 if (discoverState is ErrorLoadingServiceState) {
//                                   return Center(child: Text('Error'));
//                                 }
//                                 return Container();
//                               },
//                             );
//                           }
//                           return CircularProgressIndicator();
//                         },
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     ListView.builder(
//                         shrinkWrap: true,
//                         physics: NeverScrollableScrollPhysics(),
//                         itemCount: units.length,
//                         itemBuilder: (context, index) {
//                           final unit = units[index];
//                           if (snControllers[index].text.isEmpty) {
//                             snControllers[index].text = unit.sn ?? '';
//                           }

//                           return Card(
//                             elevation: 2,
//                             child: Container(
//                               width: MediaQuery.of(context).size.width,
//                               padding: EdgeInsets.all(24),
//                               child: Stack(
//                                 children: [
//                                   Opacity(
//                                     opacity: 0.1,
//                                     child: Center(
//                                       child: Text(
//                                         unit.rating ?? '',
//                                         style: TextStyle(
//                                           fontSize: 100,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           SizedBox(
//                                             width: 35,
//                                             height: 53,
//                                             child: Image.asset(
//                                               '$imagePath/em_tire_image.png',
//                                               fit: BoxFit.cover,
//                                             ),
//                                           ),
//                                           Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.end,
//                                             children: [
//                                               Text(
//                                                 'Position',
//                                                 style: getBlackTextStyle(
//                                                     fontSize: 14),
//                                               ),
//                                               const SizedBox(
//                                                 height: 6,
//                                               ),
//                                               Text(
//                                                 '${index + 1}',
//                                                 style: getBlackTextStyle(
//                                                     fontSize: 22,
//                                                     fontWeight: w700),
//                                               ),
//                                             ],
//                                           )
//                                         ],
//                                       ),
//                                       Padding(
//                                         padding:
//                                             EdgeInsets.symmetric(vertical: 6),
//                                         child: Divider(
//                                           thickness: 1.5,
//                                         ),
//                                       ),
//                                       Column(
//                                         children: [
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Unit',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.unitNumber ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'SN',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.sn ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Brand',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.brand ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Tire Lifetime',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.lifetime ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Rating',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.rating ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'RTD',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 '${unit.rtd} / ${unit.otd}' ??
//                                                     '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       Padding(
//                                         padding:
//                                             EdgeInsets.symmetric(vertical: 6),
//                                         child: Divider(
//                                           thickness: 1.5,
//                                         ),
//                                       ),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Expanded(
//                                             child: SizedBox(
//                                               width: MediaQuery.of(context)
//                                                   .size
//                                                   .width,
//                                               height: 45,
//                                               child: ElevatedButton(
//                                                 onPressed: () async {
//                                                   FocusScope.of(context)
//                                                       .unfocus();
//                                                   setState(() {
//                                                     // selectedPosIndex = posIndex;
//                                                   });
//                                                   showDialog(
//                                                     context: context,
//                                                     builder:
//                                                         (BuildContext context) {
//                                                       return Dialog(
//                                                         child: Container(
//                                                           padding:
//                                                               EdgeInsets.all(
//                                                                   20.0),
//                                                           child:
//                                                               SingleChildScrollView(
//                                                             child: Column(
//                                                               mainAxisSize:
//                                                                   MainAxisSize
//                                                                       .min,
//                                                               children: <Widget>[
//                                                                 Text(
//                                                                   'Choose Pressure',
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontSize:
//                                                                         24.0,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .bold,
//                                                                   ),
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         16.0),
//                                                                 Column(),
//                                                                 Wrap(
//                                                                   children:
//                                                                       pressure.map(
//                                                                           (ps) {
//                                                                     final psIndex =
//                                                                         pressure
//                                                                             .indexOf(ps);
//                                                                     return Padding(
//                                                                       padding: const EdgeInsets
//                                                                           .only(
//                                                                           right:
//                                                                               16,
//                                                                           bottom:
//                                                                               18),
//                                                                       child:
//                                                                           ElevatedButton(
//                                                                         style: ElevatedButton.styleFrom(
//                                                                             backgroundColor:
//                                                                                 Colors.green),
//                                                                         onPressed:
//                                                                             () {
//                                                                           final id =
//                                                                               Uuid();
//                                                                           setState(
//                                                                               () {
//                                                                             position[index]['pressure'] =
//                                                                                 ps;
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child:
//                                                                             Text(
//                                                                           ps,
//                                                                           style:
//                                                                               getWhiteTextStyle(
//                                                                             fontWeight:
//                                                                                 w700,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                     );
//                                                                   }).toList(),
//                                                                 ),
//                                                                 Row(
//                                                                   children: [
//                                                                     Expanded(
//                                                                       child:
//                                                                           SizedBox(
//                                                                         width: double
//                                                                             .infinity,
//                                                                         child: InputFormWidget(
//                                                                             controller:
//                                                                                 pressureCtrl,
//                                                                             isDigitOnly:
//                                                                                 true,
//                                                                             type:
//                                                                                 TextInputType.number,
//                                                                             hint: 'Input Manual'),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       width: 6,
//                                                                     ),
//                                                                     ElevatedButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           setState(
//                                                                               () {
//                                                                             if (pressureCtrl.text !=
//                                                                                 '') {
//                                                                               position[index]['pressure'] = pressureCtrl.text;
//                                                                             }
//                                                                             pressureCtrl.clear();
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child: Text(
//                                                                             'Submit'))
//                                                                   ],
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         12.0),
//                                                                 SizedBox(
//                                                                   width: double
//                                                                       .infinity,
//                                                                   child:
//                                                                       ElevatedButton(
//                                                                     onPressed:
//                                                                         () {
//                                                                       pressureCtrl
//                                                                           .clear();
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop();
//                                                                     },
//                                                                     child: Text(
//                                                                         'Close'),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       );
//                                                     },
//                                                   );
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.blue,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               12),
//                                                     )),
//                                                 child: (position[index]
//                                                                 ['pressure'] ==
//                                                             '' ||
//                                                         (position[index]
//                                                                 ['pressure'] ==
//                                                             null))
//                                                     ? Row(
//                                                         mainAxisSize:
//                                                             MainAxisSize.min,
//                                                         children: [
//                                                           Icon(
//                                                             Icons.add,
//                                                             color: white,
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 6,
//                                                           ),
//                                                           Text(
//                                                             'Pressure',
//                                                             style:
//                                                                 getWhiteTextStyle(),
//                                                           )
//                                                         ],
//                                                       )
//                                                     : Text(
//                                                         '${position[index]['pressure']} Psi',
//                                                         style:
//                                                             getWhiteTextStyle(
//                                                           fontSize: 24,
//                                                           fontWeight: w700,
//                                                         ),
//                                                       ),
//                                               ),
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                           // adjusment pressure
//                                           Expanded(
//                                             child: SizedBox(
//                                               width: MediaQuery.of(context)
//                                                   .size
//                                                   .width,
//                                               height: 45,
//                                               child: ElevatedButton(
//                                                 onPressed: () async {
//                                                   FocusScope.of(context)
//                                                       .unfocus();
//                                                   setState(() {
//                                                     // selectedPosIndex = posIndex;
//                                                   });
//                                                   showDialog(
//                                                     context: context,
//                                                     builder:
//                                                         (BuildContext context) {
//                                                       return Dialog(
//                                                         child: Container(
//                                                           padding:
//                                                               EdgeInsets.all(
//                                                                   20.0),
//                                                           child:
//                                                               SingleChildScrollView(
//                                                             child: Column(
//                                                               mainAxisSize:
//                                                                   MainAxisSize
//                                                                       .min,
//                                                               children: <Widget>[
//                                                                 Text(
//                                                                   'Choose Pressure',
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontSize:
//                                                                         24.0,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .bold,
//                                                                   ),
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         16.0),
//                                                                 Column(),
//                                                                 Wrap(
//                                                                   children:
//                                                                       pressure.map(
//                                                                           (ps) {
//                                                                     final psIndex =
//                                                                         pressure
//                                                                             .indexOf(ps);
//                                                                     return Padding(
//                                                                       padding: const EdgeInsets
//                                                                           .only(
//                                                                           right:
//                                                                               16,
//                                                                           bottom:
//                                                                               18),
//                                                                       child:
//                                                                           ElevatedButton(
//                                                                         style: ElevatedButton.styleFrom(
//                                                                             backgroundColor:
//                                                                                 Colors.green),
//                                                                         onPressed:
//                                                                             () {
//                                                                           setState(
//                                                                               () {
//                                                                             position[index]['adjusmentPressure'] =
//                                                                                 ps;
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child:
//                                                                             Text(
//                                                                           ps,
//                                                                           style:
//                                                                               getWhiteTextStyle(
//                                                                             fontWeight:
//                                                                                 w700,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                     );
//                                                                   }).toList(),
//                                                                 ),
//                                                                 Row(
//                                                                   children: [
//                                                                     Expanded(
//                                                                       child:
//                                                                           SizedBox(
//                                                                         width: double
//                                                                             .infinity,
//                                                                         child: InputFormWidget(
//                                                                             controller:
//                                                                                 pressureCtrl,
//                                                                             isDigitOnly:
//                                                                                 true,
//                                                                             type:
//                                                                                 TextInputType.number,
//                                                                             hint: 'Input Manual'),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       width: 6,
//                                                                     ),
//                                                                     ElevatedButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           setState(
//                                                                               () {
//                                                                             if (pressureCtrl.text !=
//                                                                                 '') {
//                                                                               position[index]['adjusmentPressure'] = pressureCtrl.text;
//                                                                             }
//                                                                             pressureCtrl.clear();
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child: const Text(
//                                                                             'Submit'))
//                                                                   ],
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         12.0),
//                                                                 SizedBox(
//                                                                   width: double
//                                                                       .infinity,
//                                                                   child:
//                                                                       ElevatedButton(
//                                                                     onPressed:
//                                                                         () {
//                                                                       pressureCtrl
//                                                                           .clear();
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop();
//                                                                     },
//                                                                     child: Text(
//                                                                         'Close'),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       );
//                                                     },
//                                                   );
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.blue,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               12),
//                                                     )),
//                                                 child: (position[index][
//                                                             'adjusmentPressure'] ==
//                                                         '')
//                                                     ? Text(
//                                                         'Adj Pressure',
//                                                         style:
//                                                             getWhiteTextStyle(),
//                                                       )
//                                                     : Text(
//                                                         '${position[index]['adjusmentPressure']} Psi (Adj)',
//                                                         style:
//                                                             getWhiteTextStyle(
//                                                           fontSize: 16,
//                                                           fontWeight: w700,
//                                                         ),
//                                                       ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),

//                                       const SizedBox(
//                                         height: 12,
//                                       ),

//                                       SizedBox(
//                                         width:
//                                             MediaQuery.of(context).size.width,
//                                         height: 45,
//                                         child: ElevatedButton(
//                                           onPressed: () async {
//                                             FocusScope.of(context).unfocus();
//                                             // setState(() {
//                                             //   selectedPosIndex = posIndex;
//                                             // });

//                                             showDialog(
//                                               context: context,
//                                               builder: (BuildContext context) {
//                                                 return Dialog(
//                                                   child: Container(
//                                                     padding:
//                                                         EdgeInsets.all(20.0),
//                                                     child:
//                                                         SingleChildScrollView(
//                                                       child: Column(
//                                                         mainAxisSize:
//                                                             MainAxisSize.min,
//                                                         children: <Widget>[
//                                                           Text(
//                                                             'Choose Rating',
//                                                             style: TextStyle(
//                                                               fontSize: 24.0,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .bold,
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                               height: 16.0),
//                                                           Column(),
//                                                           Wrap(
//                                                             children: rating
//                                                                 .map((rat) {
//                                                               final ratingIndex =
//                                                                   rating
//                                                                       .indexOf(
//                                                                           rat);
//                                                               return Padding(
//                                                                 padding:
//                                                                     const EdgeInsets
//                                                                         .only(
//                                                                         right:
//                                                                             16,
//                                                                         bottom:
//                                                                             18),
//                                                                 child:
//                                                                     ElevatedButton(
//                                                                   style: ElevatedButton.styleFrom(
//                                                                       backgroundColor:
//                                                                           Colors
//                                                                               .green),
//                                                                   onPressed:
//                                                                       () {
//                                                                     setState(
//                                                                         () {
//                                                                       position[index]
//                                                                               [
//                                                                               'rating'] =
//                                                                           rat;
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop();
//                                                                     });
//                                                                   },
//                                                                   child: Text(
//                                                                     rat,
//                                                                     style:
//                                                                         getWhiteTextStyle(
//                                                                       fontWeight:
//                                                                           w700,
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                               );
//                                                             }).toList(),
//                                                           ),
//                                                           SizedBox(
//                                                               height: 12.0),
//                                                           SizedBox(
//                                                             width:
//                                                                 double.infinity,
//                                                             child:
//                                                                 ElevatedButton(
//                                                               onPressed: () {
//                                                                 pressureCtrl
//                                                                     .clear();
//                                                                 Navigator.of(
//                                                                         context)
//                                                                     .pop();
//                                                               },
//                                                               child:
//                                                                   Text('Close'),
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 );
//                                               },
//                                             );
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                               backgroundColor: Colors.blue,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               )),
//                                           child: (position[index]['rating'] ==
//                                                   '')
//                                               ? Builder(builder: (context) {
//                                                   position[index]['rating'] =
//                                                       'A';
//                                                   return Text(
//                                                     'Rating A',
//                                                     style: getWhiteTextStyle(),
//                                                   );
//                                                 })
//                                               : Text(
//                                                   'Rating ${position[index]['rating']}',
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 16,
//                                                     fontWeight: w700,
//                                                   ),
//                                                 ),
//                                         ),
//                                       ),

//                                       const SizedBox(
//                                         height: 12,
//                                       ),

//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 8, vertical: 4),
//                                         decoration: BoxDecoration(
//                                           color: blue344BEF,
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         child: Text(
//                                           'Tire Damage',
//                                           textAlign: TextAlign.start,
//                                           style: getBlackTextStyle(
//                                             fontSize: 12,
//                                           ).copyWith(color: Colors.white),
//                                         ),
//                                       ),

//                                       SizedBox(
//                                         width:
//                                             MediaQuery.of(context).size.width,
//                                         child: ElevatedButton(
//                                           onPressed: () {
//                                             if (index == 0)
//                                               log('luka map : ${position[index]['damageTire']}');
//                                             FocusScope.of(context).unfocus();

//                                             if (loadingDamages) {
//                                               // Optional: kasih feedback kalau masih loading
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 const SnackBar(
//                                                     content: Text(
//                                                         'Sedang memuat daftar damage...')),
//                                               );
//                                               return;
//                                             }

//                                             if (damageType.isEmpty) {
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 const SnackBar(
//                                                     content: Text(
//                                                         'Daftar damage kosong')),
//                                               );
//                                               return;
//                                             }

//                                             final List<dynamic>
//                                                 existingDamages =
//                                                 position[index]['damageTire'] ??
//                                                     [];

//                                             List<bool> checkedDamageValues;

//                                             if (existingDamages.isEmpty ||
//                                                 existingDamages[0] == "") {
//                                               print(
//                                                   'exisitng damage empty true');
//                                               // otomatis centang Good Condition jika belum ada damage
//                                               checkedDamageValues =
//                                                   damageType.map((damage) {
//                                                 final text = damage['remark']
//                                                     .toString()
//                                                     .toLowerCase()
//                                                     .trim();
//                                                 return text == 'good' ||
//                                                     text == 'good condition';
//                                               }).toList();
//                                             } else {
//                                               print(
//                                                   'exisitng damage empty false');
//                                               // jika sudah ada data damage
//                                               checkedDamageValues =
//                                                   damageType.map((damage) {
//                                                 return existingDamages
//                                                     .contains(damage['remark']);
//                                               }).toList();
//                                             }

//                                             showDialog(
//                                               context: context,
//                                               builder: (BuildContext context) {
//                                                 return Dialog(
//                                                   child: Container(
//                                                     padding:
//                                                         const EdgeInsets.all(
//                                                             20.0),
//                                                     child: Column(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: <Widget>[
//                                                         const Text(
//                                                           'Choose Damage Tire',
//                                                           style: TextStyle(
//                                                             fontSize: 24.0,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                             height: 12.0),
//                                                         Expanded(
//                                                           child:
//                                                               SingleChildScrollView(
//                                                             child: Column(
//                                                               children:
//                                                                   damageType.map(
//                                                                       (damage) {
//                                                                 final dmgIndex =
//                                                                     damageType
//                                                                         .indexOf(
//                                                                             damage);

//                                                                 // kalau tidak perlu skip index 0, hapus if ini
//                                                                 // if (dmgIndex == 0) return Container();

//                                                                 return StatefulBuilder(
//                                                                   builder: (context,
//                                                                       setState) {
//                                                                     return CheckboxListTile(
//                                                                       title: Text(
//                                                                           damage[
//                                                                               'remark']),
//                                                                       value: checkedDamageValues[
//                                                                           dmgIndex],
//                                                                       onChanged:
//                                                                           (bool?
//                                                                               value) {
//                                                                         setState(
//                                                                             () {
//                                                                           bool
//                                                                               newValue =
//                                                                               value ?? false;

//                                                                           if (dmgIndex ==
//                                                                               0) {
//                                                                             // GOOD CONDITION dicentang
//                                                                             checkedDamageValues =
//                                                                                 List<bool>.filled(checkedDamageValues.length, false);
//                                                                             checkedDamageValues[0] =
//                                                                                 newValue;
//                                                                           } else {
//                                                                             // Damage lain dicentang
//                                                                             checkedDamageValues[dmgIndex] =
//                                                                                 newValue;

//                                                                             if (newValue) {
//                                                                               // otomatis uncheck Good Condition
//                                                                               checkedDamageValues[0] = false;
//                                                                             }
//                                                                           }
//                                                                         });
//                                                                       },
//                                                                     );
//                                                                   },
//                                                                 );
//                                                               }).toList(),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                             height: 12.0),
//                                                         Column(
//                                                           children: [
//                                                             const SizedBox(
//                                                                 height: 12),
//                                                             SizedBox(
//                                                               width: double
//                                                                   .infinity,
//                                                               child:
//                                                                   ElevatedButton(
//                                                                 onPressed: () {
//                                                                   damageCtrl
//                                                                       .clear();
//                                                                   Navigator.pop(
//                                                                       context);
//                                                                 },
//                                                                 child:
//                                                                     const Text(
//                                                                         'Close'),
//                                                               ),
//                                                             ),
//                                                             const SizedBox(
//                                                                 height: 12),
//                                                             SizedBox(
//                                                               width: double
//                                                                   .infinity,
//                                                               child:
//                                                                   ElevatedButton(
//                                                                 style: ElevatedButton
//                                                                     .styleFrom(
//                                                                   backgroundColor:
//                                                                       Colors
//                                                                           .green,
//                                                                 ),
//                                                                 onPressed: () {
//                                                                   setState(
//                                                                       () {}); // setState parent

//                                                                   selectedDamage
//                                                                       .clear();

//                                                                   Map<String,
//                                                                           int>
//                                                                       ratingPriority =
//                                                                       {
//                                                                     '': 1,
//                                                                     'A': 1,
//                                                                     'B': 2,
//                                                                     'C': 3,
//                                                                     'X': 4,
//                                                                   };

//                                                                   final List<
//                                                                           Map<String,
//                                                                               dynamic>>
//                                                                       tmp = [];

//                                                                   // NOTE: ini tadinya if (== '' || isNotEmpty) -> selalu true.
//                                                                   if (damageCtrl
//                                                                       .text
//                                                                       .isNotEmpty) {
//                                                                     tmp.add({
//                                                                       'remark':
//                                                                           damageCtrl
//                                                                               .text,
//                                                                       'rating':
//                                                                           ''
//                                                                     });
//                                                                   }

//                                                                   for (int i =
//                                                                           0;
//                                                                       i <
//                                                                           checkedDamageValues
//                                                                               .length;
//                                                                       i++) {
//                                                                     if (checkedDamageValues[
//                                                                         i]) {
//                                                                       tmp.add(
//                                                                           damageType[
//                                                                               i]);
//                                                                     }
//                                                                   }

//                                                                   final onlyRemark = tmp
//                                                                       .map<String>((item) =>
//                                                                           item['remark']
//                                                                               ?.toString() ??
//                                                                           '')
//                                                                       .where((remark) =>
//                                                                           remark
//                                                                               .isNotEmpty)
//                                                                       .toList();

//                                                                   position[index]
//                                                                           [
//                                                                           'damageTire'] =
//                                                                       onlyRemark;

//                                                                   if (tmp
//                                                                       .isNotEmpty) {
//                                                                     position[index]
//                                                                             [
//                                                                             'damageTire'] =
//                                                                         onlyRemark;

//                                                                     // rating based damage
//                                                                     String
//                                                                         worstRating =
//                                                                         '';
//                                                                     worstRating =
//                                                                         tmp.fold(
//                                                                       '',
//                                                                       (worst,
//                                                                           item) {
//                                                                         final current =
//                                                                             item['rating'] ??
//                                                                                 '';

//                                                                         return ratingPriority[current]! >
//                                                                                 ratingPriority[worst]!
//                                                                             ? current
//                                                                             : worst;
//                                                                       },
//                                                                     );

//                                                                     position[index]
//                                                                             [
//                                                                             'rating'] =
//                                                                         worstRating;

//                                                                     selectedDamage
//                                                                         .addAll(
//                                                                             onlyRemark);

//                                                                     log('hasil luka ban : $position');
//                                                                   }

//                                                                   damageCtrl
//                                                                       .clear();
//                                                                   Navigator.pop(
//                                                                       context);
//                                                                 },
//                                                                 child: Text(
//                                                                   'Submit',
//                                                                   style:
//                                                                       getWhiteTextStyle(
//                                                                     fontWeight:
//                                                                         w700,
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 );
//                                               },
//                                             );
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: blue344BEF,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                           child: Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                                 vertical: 8.0),
//                                             child: Text(
//                                               ((position[index]['damageTire'] ==
//                                                           null) ||
//                                                       (position[index]
//                                                                   ['damageTire']
//                                                               as List)
//                                                           .where((e) =>
//                                                               e != null &&
//                                                               e
//                                                                   .toString()
//                                                                   .trim()
//                                                                   .isNotEmpty)
//                                                           .isEmpty)
//                                                   ? 'Good Condition'
//                                                   : (position[index]
//                                                               ['damageTire']
//                                                           as List)
//                                                       .join('\n---\n'),
//                                               textAlign: TextAlign.center,
//                                               style: getWhiteTextStyle(
//                                                   fontSize: 14),
//                                             ),
//                                           ),
//                                         ),
//                                       ),

//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 45,
//                                         child: ElevatedButton(
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.orange,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                           onPressed: () {
//                                             showRimInspectionDialog(index);
//                                           },
//                                           child: Text(
//                                             'Check Tire Component Condition',
//                                             style: getWhiteTextStyle(
//                                                 fontWeight: w700),
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(
//                                         height: 16,
//                                       ),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 45,
//                                         child: ElevatedButton(
//                                             style: ElevatedButton.styleFrom(
//                                                 backgroundColor: Colors.green,
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                 )),
//                                             onPressed: () async {
//                                               final ImagePicker picker =
//                                                   ImagePicker();

//                                               final ImageSource? source =
//                                                   await showDialog<ImageSource>(
//                                                 context: context,
//                                                 builder: (context) {
//                                                   return AlertDialog(
//                                                     title: Text(
//                                                         "Pilih Sumber Gambar"),
//                                                     content: Column(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: [
//                                                         ListTile(
//                                                           leading: Icon(
//                                                               Icons.camera_alt),
//                                                           title: Text("Kamera"),
//                                                           onTap: () =>
//                                                               Navigator.pop(
//                                                                   context,
//                                                                   ImageSource
//                                                                       .camera),
//                                                         ),
//                                                         ListTile(
//                                                           leading: Icon(Icons
//                                                               .photo_library),
//                                                           title:
//                                                               Text("Gallery"),
//                                                           onTap: () =>
//                                                               Navigator.pop(
//                                                                   context,
//                                                                   ImageSource
//                                                                       .gallery),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   );
//                                                 },
//                                               );

//                                               // final XFile? image =
//                                               //     await picker.pickImage(
//                                               //         imageQuality: 50,
//                                               //         source:
//                                               //             // ImageSource.camera);
//                                               //             ImageSource.gallery);

//                                               if (source == null) return;

//                                               if (source ==
//                                                   ImageSource.camera) {
//                                                 requestCameraPermission();
//                                               }

//                                               final XFile? image =
//                                                   await picker.pickImage(
//                                                 source: source,
//                                                 imageQuality: 50,
//                                               );

//                                               try {
//                                                 if (image != null) {
//                                                   Directory? directory;

//                                                   if (Platform.isAndroid) {
//                                                     // path = await getExternalStorageDirectory();
//                                                     directory =
//                                                         await DownloadsPath
//                                                             .downloadsDirectory();
//                                                   }

//                                                   if (Platform.isIOS) {
//                                                     // final directory = await getApplicationDocumentsDirectory();
//                                                     // path = directory;
//                                                     directory =
//                                                         await getApplicationDocumentsDirectory();
//                                                   }

//                                                   // Read image as a file
//                                                   File imageFile =
//                                                       File(image.path);
//                                                   // data size fotonya
//                                                   final compressedFilePath =
//                                                       '${directory?.path}/${DateTime.now().millisecondsSinceEpoch}_tireinspectionimage_compressed.jpg';

//                                                   // Compress the image if needed (optional)
//                                                   final compressedImageFile =
//                                                       await FlutterImageCompress
//                                                           .compressAndGetFile(
//                                                     imageFile.path,
//                                                     compressedFilePath,
//                                                     quality: 50,
//                                                   );
//                                                   log('gambar : ${compressedFilePath}');

//                                                   if (compressedImageFile ==
//                                                       null) {
//                                                     throw Exception(
//                                                       'Failed to compress image.',
//                                                     );
//                                                   }

//                                                   // Simpan foto saja. Analisa AI dijalankan manual
//                                                   // melalui tombol Analyze Damage with AI.
//                                                   setState(() {
//                                                     position[index]['image'] = [
//                                                       '${compressedImageFile.path}|${position[index]['position']}'
//                                                     ];

//                                                     // Hapus hasil AI dari foto sebelumnya.
//                                                     aiResults.remove(index);
//                                                     imageWidths.remove(index);
//                                                     imageHeights.remove(index);
//                                                     loadingAI[index] = false;
//                                                   });

//                                                   log('tire inspection image = ${position[index]['image']}');
//                                                 }
//                                               } catch (e) {
//                                                 log('error gambar string : $e');
//                                               }

//                                               setState(() {});
//                                             },
//                                             child: Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.center,
//                                               children: [
//                                                 Icon(
//                                                   Icons.camera_alt,
//                                                   color: white,
//                                                 ),
//                                                 const SizedBox(
//                                                   width: 12,
//                                                 ),
//                                                 Text(
//                                                   'Take Picture',
//                                                   style: getWhiteTextStyle(),
//                                                 ),
//                                               ],
//                                             )),
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       Text(
//                                         '*You can only take one picture. If you take another picture, the previous one will be deleted.',
//                                         style: getRedTextStyle(),
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       ((position[index]['image']
//                                                   as List<dynamic>)
//                                               .isNotEmpty)
//                                           ? Column(
//                                               children: [
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   height: 45,
//                                                   child: ElevatedButton(
//                                                       style: ElevatedButton
//                                                           .styleFrom(
//                                                               backgroundColor:
//                                                                   Colors
//                                                                       .deepOrange,
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             12),
//                                                               )),
//                                                       onPressed: () async {
//                                                         showDialog(
//                                                             context: context,
//                                                             builder: (context) {
//                                                               return AlertDialog(
//                                                                 content: Text(
//                                                                   'Are you sure you want to delete this image?',
//                                                                   style:
//                                                                       getBlackTextStyle(),
//                                                                 ),
//                                                                 actions: [
//                                                                   TextButton(
//                                                                       onPressed:
//                                                                           () {
//                                                                         Navigator.pop(
//                                                                             context);
//                                                                       },
//                                                                       child:
//                                                                           Text(
//                                                                         'Cancel',
//                                                                         style: getGreyTextStyle(
//                                                                             grey8391A1),
//                                                                       )),
//                                                                   TextButton(
//                                                                       onPressed:
//                                                                           () {
//                                                                         setState(
//                                                                             () {
//                                                                           position[index]['image'] =
//                                                                               [];
//                                                                           aiResults
//                                                                               .remove(index);
//                                                                           loadingAI
//                                                                               .remove(index);
//                                                                           imageWidths
//                                                                               .remove(index);
//                                                                           imageHeights
//                                                                               .remove(index);
//                                                                         });
//                                                                         Navigator.pop(
//                                                                             context);
//                                                                       },
//                                                                       child:
//                                                                           Text(
//                                                                         'Yes',
//                                                                         style:
//                                                                             getRedTextStyle(),
//                                                                       )),
//                                                                 ],
//                                                               );
//                                                             });

//                                                         setState(() {});
//                                                       },
//                                                       child: Row(
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .center,
//                                                         children: [
//                                                           Icon(
//                                                             Icons.delete,
//                                                             color: white,
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 12,
//                                                           ),
//                                                           Text(
//                                                             'Delete Picture',
//                                                             style:
//                                                                 getWhiteTextStyle(),
//                                                           ),
//                                                         ],
//                                                       )),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 (loadingAI[index] == true)
//                                                     ? Center(
//                                                         child:
//                                                             AiLoadingWidget(),
//                                                       )
//                                                     : Stack(
//                                                         children: [
//                                                           Container(
//                                                             width:
//                                                                 double.infinity,
//                                                             decoration:
//                                                                 BoxDecoration(
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           12),
//                                                             ),
//                                                             child: Image.file(
//                                                               File(
//                                                                 (position[index]
//                                                                             [
//                                                                             'image'][0]
//                                                                         as String)
//                                                                     .split(
//                                                                         '|')[0],
//                                                               ),
//                                                               fit: BoxFit
//                                                                   .contain,
//                                                             ),
//                                                           ),
//                                                           if (aiResults[
//                                                                   index] !=
//                                                               null)
//                                                             Positioned.fill(
//                                                               child:
//                                                                   CustomPaint(
//                                                                 painter:
//                                                                     BoundingBoxPainter(
//                                                                   detections: aiResults[
//                                                                               index]
//                                                                           ?.data
//                                                                           ?.tireDamageResult ??
//                                                                       [],
//                                                                   imageWidth:
//                                                                       imageWidths[
//                                                                               index] ??
//                                                                           1,
//                                                                   imageHeight:
//                                                                       imageHeights[
//                                                                               index] ??
//                                                                           1,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                         ],
//                                                       ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   height: 45,
//                                                   child: ElevatedButton(
//                                                     style: ElevatedButton
//                                                         .styleFrom(
//                                                       backgroundColor:
//                                                           Colors.purple,
//                                                       shape:
//                                                           RoundedRectangleBorder(
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(12),
//                                                       ),
//                                                     ),
//                                                     onPressed:
//                                                         loadingAI[index] == true
//                                                             ? null
//                                                             : () async {
//                                                                 await _analyzeDamageWithAI(
//                                                                   index,
//                                                                 );
//                                                               },
//                                                     child: Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .center,
//                                                       children: [
//                                                         const Icon(
//                                                           Icons.auto_awesome,
//                                                           color: white,
//                                                         ),
//                                                         const SizedBox(
//                                                           width: 12,
//                                                         ),
//                                                         Text(
//                                                           aiResults[index] ==
//                                                                   null
//                                                               ? 'Analyze Damage with AI'
//                                                               : 'Analyze Again with AI',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontWeight: w700,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                               ],
//                                             )
//                                           : Container(),

//                                       // Show More Images
//                                       // (listImg.isNotEmpty)
//                                       //     ? Column(
//                                       //         children: [
//                                       //           SizedBox(
//                                       //             width: double.infinity,
//                                       //             height: 45,
//                                       //             child: ElevatedButton(
//                                       //                 style: ElevatedButton
//                                       //                     .styleFrom(
//                                       //                         backgroundColor:
//                                       //                             Colors
//                                       //                                 .orange,
//                                       //                         shape:
//                                       //                             RoundedRectangleBorder(
//                                       //                           borderRadius:
//                                       //                               BorderRadius.circular(
//                                       //                                   12),
//                                       //                         )),
//                                       //                 onPressed: () async {
//                                       //                   final CarouselController
//                                       //                       _controller =
//                                       //                       CarouselController();

//                                       //                   showDialog(
//                                       //                       context:
//                                       //                           context,
//                                       //                       builder:
//                                       //                           (BuildContext
//                                       //                               context) {
//                                       //                         return AlertDialog(
//                                       //                           content:
//                                       //                               Padding(
//                                       //                             padding: const EdgeInsets
//                                       //                                 .all(
//                                       //                                 24.0),
//                                       //                             child:
//                                       //                                 Column(
//                                       //                               mainAxisSize:
//                                       //                                   MainAxisSize.min,
//                                       //                               children: [
//                                       //                                 Text(
//                                       //                                   'Show Image',
//                                       //                                   style:
//                                       //                                       getBlackTextStyle(),
//                                       //                                 ),
//                                       //                                 const SizedBox(
//                                       //                                   height:
//                                       //                                       12,
//                                       //                                 ),
//                                       //                                 Container(
//                                       //                                   width:
//                                       //                                       400,
//                                       //                                   height:
//                                       //                                       400,
//                                       //                                   child:
//                                       //                                       CarouselSlider(
//                                       //                                     carouselController: _controller,
//                                       //                                     // items: listImg.map((img) {
//                                       //                                     //   final splitImg = img.split('|');

//                                       //                                     //   if ((position[index]['position']).toString() == splitImg[1]) {
//                                       //                                     //     return Image.file(File(splitImg[0]));
//                                       //                                     //   }
//                                       //                                     //   return Container();
//                                       //                                     // }).toList(),
//                                       //                                     items: listImg
//                                       //                                         .where((img) {
//                                       //                                           final splitImg = img.split('|');
//                                       //                                           return splitImg[1] == (position[index]['position']).toString();
//                                       //                                         })
//                                       //                                         .toList()
//                                       //                                         .map((img2) {
//                                       //                                           final splitImg2 = img2.split('|');
//                                       //                                           return Image.file(File(splitImg2[0]));
//                                       //                                         })
//                                       //                                         .toList(),
//                                       //                                     options: CarouselOptions(
//                                       //                                       aspectRatio: 3.0,
//                                       //                                       height: 400,
//                                       //                                       enableInfiniteScroll: false,
//                                       //                                       enlargeCenterPage: true,
//                                       //                                     ),
//                                       //                                   ),
//                                       //                                 ),
//                                       //                               ],
//                                       //                             ),
//                                       //                           ),
//                                       //                         );
//                                       //                       });
//                                       //                   setState(() {});
//                                       //                 },
//                                       //                 child: Row(
//                                       //                   mainAxisAlignment:
//                                       //                       MainAxisAlignment
//                                       //                           .center,
//                                       //                   children: [
//                                       //                     Icon(
//                                       //                       Icons.image,
//                                       //                       color: white,
//                                       //                     ),
//                                       //                     const SizedBox(
//                                       //                       width: 12,
//                                       //                     ),
//                                       //                     Text(
//                                       //                       'Show Image',
//                                       //                       style:
//                                       //                           getWhiteTextStyle(),
//                                       //                     ),
//                                       //                   ],
//                                       //                 )),
//                                       //           ),
//                                       //           const SizedBox(
//                                       //             height: 12,
//                                       //           ),
//                                       //         ],
//                                       //       )
//                                       //     : Container(),

//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.stretch,
//                                               children: [
//                                                 Text(
//                                                   'RTD 1',
//                                                   style: getBlackTextStyle(
//                                                       fontWeight: w700),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   child: InputFormWidget(
//                                                     onChng: (value) {
//                                                       position[index]['rtd1'] =
//                                                           value;
//                                                     },
//                                                     controller:
//                                                         rtd1Controllers[index],
//                                                     hint: '',
//                                                   ),
//                                                 ),
//                                                 // Builder(builder: (context) {
//                                                 //   rtd1Controllers[index].text =
//                                                 //       unit.rtd ?? '';
//                                                 //   position[index]['rtd1'] =
//                                                 //       unit.rtd;
//                                                 //   return SizedBox(
//                                                 //     width: double.infinity,
//                                                 //     child: InputFormWidget(
//                                                 //         onChng: (value) {
//                                                 //           position[index]
//                                                 //               ['rtd1'] = value;
//                                                 //         },
//                                                 //         controller:
//                                                 //             rtd1Controllers[
//                                                 //                 index],
//                                                 //         hint: ''),
//                                                 //   );
//                                                 // }),
//                                               ],
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.stretch,
//                                               children: [
//                                                 Text(
//                                                   'RTD 2',
//                                                   style: getBlackTextStyle(
//                                                       fontWeight: w700),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   child: InputFormWidget(
//                                                     onChng: (value) {
//                                                       position[index]['rtd2'] =
//                                                           value;
//                                                     },
//                                                     controller:
//                                                         rtd2Controllers[index],
//                                                     hint: '',
//                                                   ),
//                                                 ),
//                                                 // Builder(builder: (context) {
//                                                 //   rtd2Controllers[index].text =
//                                                 //       unit.otd ?? '';
//                                                 //   position[index]['rtd2'] =
//                                                 //       unit.otd;
//                                                 //   return SizedBox(
//                                                 //     width: double.infinity,
//                                                 //     child: InputFormWidget(
//                                                 //         onChng: (value) {
//                                                 //           position[index]
//                                                 //               ['rtd2'] = value;
//                                                 //         },
//                                                 //         controller:
//                                                 //             rtd2Controllers[
//                                                 //                 index],
//                                                 //         hint: ''),
//                                                 //   );
//                                                 // }),
//                                               ],
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.stretch,
//                                         children: [
//                                           Text(
//                                             'Serial Number',
//                                             style: getBlackTextStyle(
//                                                 fontWeight: w700),
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           SizedBox(
//                                             width: double.infinity,
//                                             child: InputFormWidget(
//                                                 onChng: (value) {
//                                                   position[index]['sn'] = value;
//                                                 },
//                                                 controller:
//                                                     snControllers[index],
//                                                 hint: ''),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.stretch,
//                                         children: [
//                                           Text(
//                                             'Remarks',
//                                             style: getBlackTextStyle(
//                                                 fontWeight: w700),
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           SizedBox(
//                                             width: double.infinity,
//                                             child: InputFormWidget(
//                                                 onChng: (value) {
//                                                   position[index]['remarks'] =
//                                                       value;
//                                                 },
//                                                 controller:
//                                                     remarksControllers[index],
//                                                 hint: ''),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(
//                                         height: 24,
//                                       ),
//                                       SizedBox(height: 12),

//                                       // SizedBox(
//                                       //   // height: 160,
//                                       //   child: GridView.builder(
//                                       //       physics:
//                                       //           NeverScrollableScrollPhysics(),
//                                       //       shrinkWrap: true,
//                                       //       itemCount: position[index]
//                                       //               ['condition']
//                                       //           .length,
//                                       //       gridDelegate:
//                                       //           SliverGridDelegateWithFixedCrossAxisCount(
//                                       //               crossAxisCount: 2,
//                                       //               childAspectRatio: 3),
//                                       //       itemBuilder:
//                                       //           (context, indexBroken) {
//                                       //         final broken = position[index]
//                                       //             ['condition'][indexBroken];
//                                       //         return InkWell(
//                                       //           onTap: () {
//                                       //             setState(() {
//                                       //               // checkedListCategory[
//                                       //               //         index] =
//                                       //               //     !checkedListCategory[
//                                       //               //         index];
//                                       //               broken['checked'] =
//                                       //                   !broken['checked'];
//                                       //             });
//                                       //             // widget.onCategoryChecked(checkedListCategory);
//                                       //           },
//                                       //           child: Container(
//                                       //             padding: EdgeInsets.all(10),
//                                       //             child: Row(
//                                       //               children: [
//                                       //                 Container(
//                                       //                   width: 24,
//                                       //                   height: 24,
//                                       //                   decoration:
//                                       //                       BoxDecoration(
//                                       //                     color: broken[
//                                       //                             'checked']
//                                       //                         ? black
//                                       //                         : Colors
//                                       //                             .transparent,
//                                       //                     border: Border.all(
//                                       //                         color:
//                                       //                             Colors.black),
//                                       //                   ),
//                                       //                   child: Icon(
//                                       //                     Icons.check,
//                                       //                     color: Colors.white,
//                                       //                     size: 16,
//                                       //                   ),
//                                       //                 ),
//                                       //                 SizedBox(width: 10),
//                                       //                 LayoutBuilder(builder:
//                                       //                     (context,
//                                       //                         constraints) {
//                                       //                   double fontSize =
//                                       //                       constraints
//                                       //                               .maxHeight *
//                                       //                           0.35;
//                                       //                   // log('ukuran' + fontSize.toString());
//                                       //                   return Text(
//                                       //                     broken['name'],
//                                       //                     style:
//                                       //                         getBlackTextStyle(
//                                       //                             fontSize:
//                                       //                                 fontSize),
//                                       //                   );
//                                       //                 }),
//                                       //               ],
//                                       //             ),
//                                       //           ),
//                                       //         );
//                                       //       }),
//                                       // ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }),
//                   ],
//                 ),
//               ),
//             );
//           }
//           return Container();
//         },
//       )),
//       bottomNavigationBar: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           BlocBuilder<TireBloc, TireState>(
//             builder: (context, state) {
//               if (state is TiresLoadedState) {
//                 return Container(
//                   margin: EdgeInsets.symmetric(horizontal: 24),
//                   child: ButtonWidget(
//                       name: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           Icon(Icons.save_alt),
//                           const SizedBox(
//                             width: 6,
//                           ),
//                           Text(
//                             'Save',
//                             style: getWhiteTextStyle(),
//                           ),
//                         ],
//                       ),
//                       // function: () async {
//                       //   // jika data pressure kosong
//                       //   bool hasEmptyPressure =
//                       //       position.any((p) => p['pressure'] == '');

//                       //   if (hasEmptyPressure) {
//                       //     ScaffoldMessenger.of(context).hideCurrentSnackBar();

//                       //     ScaffoldMessenger.of(context).showSnackBar(
//                       //       SnackBar(
//                       //         backgroundColor: Colors.red,
//                       //         content: Text(
//                       //           'Please input data pressure (Choose 0 Psi if No Tire or Block Valve)',
//                       //           style: TextStyle(color: Colors.white),
//                       //         ),
//                       //       ),
//                       //     );
//                       //     return;
//                       //   }
//                       //   // jika belum memeilih pit
//                       //   if (idSite == bmbsitarum.idSite ||
//                       //       idSite == bmbhauling.idSite ||
//                       //       idSite == bmbtabuhan.idSite ||
//                       //       idSite == bibkgb.idSite ||
//                       //       idSite == bibgh.idSite) {
//                       //     if (selectedPit == -1) {
//                       //       ScaffoldMessenger.of(context).showSnackBar(
//                       //         SnackBar(
//                       //           backgroundColor: Colors.red,
//                       //           content: Text(
//                       //             'Please select location of unit first!',
//                       //             style: TextStyle(color: Colors.white),
//                       //           ),
//                       //         ),
//                       //       );
//                       //       return;
//                       //     }
//                       //   }

//                       //   // input ke tire inspection
//                       //   try {
//                       //     position.removeWhere((element) =>
//                       //         element['pressure'] == '' &&
//                       //         (element['damageTire'] as List<dynamic>)
//                       //             .isEmpty &&
//                       //         element['adjusmentPressure'] == '' &&
//                       //         element['rtd1'] == '' &&
//                       //         element['rtd2'] == '' &&
//                       //         element['rating'] == '' &&
//                       //         element['sn'] == '' &&
//                       //         element['remarks'] == '');

//                       //     for (int i = 0; i < position.length; i++) {
//                       //       final unit = state.units[i];
//                       //       final id = Uuid();

//                       //       String? localImagePath;
//                       //       try {
//                       //         final imgList =
//                       //             position[i]['image'] as List<dynamic>?;
//                       //         if (imgList != null && imgList.isNotEmpty) {
//                       //           final raw = imgList[0]
//                       //               as String; // format: "path|position"
//                       //           final parts = raw.split('|');
//                       //           if (parts.isNotEmpty) {
//                       //             localImagePath = parts[0];
//                       //           }
//                       //         }
//                       //       } catch (e) {
//                       //         log('parse image error: $e');
//                       //       }

//                       //       log('SAVE POSISI ${localImagePath}');
//                       //       log('SAVE POSISI ${position[i]['position']} '
//                       //           'IMAGE: ${position[i]['image']}');

//                       //       if (position[i]['pressure'] != '' ||
//                       //           position[i]['hm'] != '' ||
//                       //           position[i]['damageTire'] != [] ||
//                       //           position[i]['damageTire'][0] != damageType[0] ||
//                       //           position[i]['adjusmentPressure'] != '' ||
//                       //           position[i]['rtd1'] != '' ||
//                       //           position[i]['rtd2'] != '' ||
//                       //           position[i]['rating'] != '' ||
//                       //           position[i]['sn'] != '' ||
//                       //           position[i]['remarks'] != '') {
//                       //         final today = DateTime.now();
//                       //         final startOfDay =
//                       //             DateTime(today.year, today.month, today.day);
//                       //         final endOfDay = DateTime(today.year, today.month,
//                       //             today.day, 23, 59, 59);

//                       //         final querySnapshot = await firestore
//                       //             .collection('task')
//                       //             .where('kunci_unit',
//                       //                 isEqualTo: unit.kunciUnit)
//                       //             .where('kunci_tire',
//                       //                 isEqualTo: unit.kunciTire)
//                       //             .where('position',
//                       //                 isEqualTo: position[i]['position'])
//                       //             .where('last_update',
//                       //                 isGreaterThanOrEqualTo:
//                       //                     startOfDay.toIso8601String())
//                       //             .where('last_update',
//                       //                 isLessThanOrEqualTo:
//                       //                     endOfDay.toIso8601String())
//                       //             .get();

//                       //         log('adakah query : ${querySnapshot.docs.isNotEmpty}');

//                       //         final bool hasNewLocalImage =
//                       //             localImagePath != null;

//                       //         if (querySnapshot.docs.isNotEmpty) {
//                       //           // Update the existing document
//                       //           final docId = querySnapshot.docs.first.id;
//                       //           // try {
//                       //           //   log('kenapa gagal 3 ${position[i]['image'] as List<dynamic>}');
//                       //           // } catch (e) {
//                       //           //   log('kenapa gagal 4 ${e}');
//                       //           // }

//                       //           final Map<String, dynamic> updateData = {
//                       //             'id': id.v4(),
//                       //             'id_site': idSite,
//                       //             'user': user['username'] ?? 'username',
//                       //             'user_email': auth.currentUser!.email,
//                       //             'unit': unit.unitNumber,
//                       //             'serial_number': unit.sn,
//                       //             'condition': position[i]['condition']
//                       //                 .where((condition) =>
//                       //                     condition['checked'] == true)
//                       //                 .map((condition) =>
//                       //                     condition['name'].toString())
//                       //                 .toList(),
//                       //             'tire_size': unit.size,
//                       //             'hm': hmUnit.text,
//                       //             'position': position[i]['position'],
//                       //             'rating': position[i]['rating'],
//                       //             'brand': unit.brand,
//                       //             'tire_damage':
//                       //                 (position[i]['damageTire'].isEmpty)
//                       //                     ? damageType[0]
//                       //                     : position[i]['damageTire'],
//                       //             'remarks': position[i]['remarks'],
//                       //             'rtd':
//                       //                 '${position[i]['rtd1']}/${position[i]['rtd2']}',
//                       //             'pressure': position[i]['pressure'],
//                       //             'adjusmentPressure': position[i]
//                       //                 ['adjusmentPressure'],
//                       //             'last_update':
//                       //                 DateTime.now().toIso8601String(),
//                       //             'is_done': false,
//                       //             'sn': (position[i]['sn'] != null ||
//                       //                     position[i]['sn'] != '')
//                       //                 ? position[i]['sn']
//                       //                 : unit.sn,
//                       //             'kunci_unit': unit.kunciUnit,
//                       //             'kunci_tire': unit.kunciTire,
//                       //             'pit': (idSite == bmbsitarum.idSite ||
//                       //                     idSite == bmbhauling.idSite ||
//                       //                     idSite == bmbtabuhan.idSite ||
//                       //                     idSite == bibkgb.idSite)
//                       //                 ? pit[selectedPit]
//                       //                 : 'Default',
//                       //           };

//                       //           // Hanya kalau ada foto baru → kosongkan images & set pending
//                       //           if (hasNewLocalImage) {
//                       //             updateData['images'] = [];
//                       //             updateData['imagePending'] = true;
//                       //           }

//                       //           await firestore
//                       //               .collection('task')
//                       //               .doc(docId)
//                       //               .update(updateData);
//                       //           if (hasNewLocalImage) {
//                       //             UploadQueueService.to.addPending(
//                       //               docId: docId,
//                       //               filePath: localImagePath!,
//                       //             );
//                       //           }
//                       //         } else {
//                       //           final Map<String, dynamic> newData = {
//                       //             'id': id.v4(),
//                       //             'id_site': idSite,
//                       //             'user': user['username'] ?? 'username',
//                       //             'user_email': auth.currentUser!.email,
//                       //             'unit': unit.unitNumber,
//                       //             'serial_number': unit.sn,
//                       //             'condition': position[i]['condition']
//                       //                 .where((condition) =>
//                       //                     condition['checked'] == true)
//                       //                 .map((condition) =>
//                       //                     condition['name'].toString())
//                       //                 .toList(),
//                       //             'tire_size': unit.size,
//                       //             'hm': hmUnit.text,
//                       //             'position': position[i]['position'],
//                       //             'rating': position[i]['rating'],
//                       //             'brand': unit.brand,
//                       //             'tire_damage':
//                       //                 (position[i]['damageTire'].isEmpty)
//                       //                     ? damageType[0]
//                       //                     : position[i]['damageTire'],
//                       //             'remarks': position[i]['remarks'],
//                       //             'rtd':
//                       //                 '${position[i]['rtd1']}/${position[i]['rtd2']}',
//                       //             'pressure': position[i]['pressure'],
//                       //             'adjusmentPressure': position[i]
//                       //                 ['adjusmentPressure'],
//                       //             'last_update':
//                       //                 DateTime.now().toIso8601String(),
//                       //             'is_done': false,
//                       //             'sn': (position[i]['sn'] != '')
//                       //                 ? position[i]['sn']
//                       //                 : unit.sn,
//                       //             'kunci_unit': unit.kunciUnit,
//                       //             'kunci_tire': unit.kunciTire,
//                       //             'pit': (idSite == bmbsitarum.idSite ||
//                       //                     idSite == bmbhauling.idSite ||
//                       //                     idSite == bmbtabuhan.idSite ||
//                       //                     idSite == bibkgb.idSite)
//                       //                 ? pit[selectedPit]
//                       //                 : 'Default',
//                       //           };

//                       //           newData['images'] = [];
//                       //           newData['imagePending'] = hasNewLocalImage;

//                       //           final docRef = await firestore
//                       //               .collection('task')
//                       //               .add(newData);

//                       //           if (hasNewLocalImage) {
//                       //             UploadQueueService.to.addPending(
//                       //               docId: docRef.id,
//                       //               filePath: localImagePath!,
//                       //             );
//                       //           }
//                       //         }
//                       //       }
//                       //     }

//                       //     // input ke daily check pressure
//                       //     try {
//                       //       final today = DateTime.now();
//                       //       final startOfDay =
//                       //           DateTime(today.year, today.month, today.day);
//                       //       final endOfDay = DateTime(
//                       //           today.year, today.month, today.day, 23, 59, 59);
//                       //       final formattedToday =
//                       //           '${today.month.toString().padLeft(2, '0')}' // MM
//                       //           '${today.day.toString().padLeft(2, '0')}' // DD
//                       //           '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

//                       //       final querySnapshot = await FirebaseFirestore
//                       //           .instance
//                       //           .collection('daily_pressure')
//                       //           .where('unit',
//                       //               isEqualTo: dataUnit['unitNumber'])
//                       //           .where('tanggal',
//                       //               isGreaterThanOrEqualTo:
//                       //                   startOfDay.toIso8601String())
//                       //           .where('tanggal',
//                       //               isLessThanOrEqualTo:
//                       //                   endOfDay.toIso8601String())
//                       //           .get();

//                       //       print(
//                       //           'Documents found: ${querySnapshot.docs.length}');

//                       //       if (querySnapshot.docs.isNotEmpty) {
//                       //         final docId = querySnapshot.docs.first.id;

//                       //         // revisi data
//                       //         await firestore
//                       //             .collection('daily_pressure')
//                       //             .doc(docId)
//                       //             .update({
//                       //           'idSite': idSite,
//                       //           'user':
//                       //               user['username'] ?? auth.currentUser!.email,
//                       //           'tanggal': DateTime.now().toIso8601String(),
//                       //           'unit': idUnit.text,
//                       //           'hm': hmUnit.text,
//                       //           'posisi': position.map((p) {
//                       //             final pIndex = position.indexOf(p);

//                       //             log('tekanan angin : ${p['pressure']}');
//                       //             return {
//                       //               'pos': '${pIndex + 1}',
//                       //               'pressure': (p['pressure']) ?? '0',
//                       //               'rating': (p['rating']) ?? '',
//                       //               'adjusmentPressure':
//                       //                   (p['adjusmentPressure']) ?? '0',
//                       //               'luka': p['damageTire'],
//                       //               'idUnit': p['idUnit'],
//                       //               'idInventory': p['idInventory'],
//                       //               'tireSize': p['tireSize'],
//                       //               'idDaily':
//                       //                   '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                       //               'tireAccessories': []
//                       //             };
//                       //           }),
//                       //           'pit': (idSite == bmbsitarum.idSite ||
//                       //                   idSite == bmbhauling.idSite ||
//                       //                   idSite == bmbtabuhan.idSite ||
//                       //                   idSite == bibkgb.idSite)
//                       //               ? pit[selectedPit]
//                       //               : 'Default'
//                       //         });
//                       //       } else {
//                       //         // tambah data
//                       //         await firestore.collection('daily_pressure').add({
//                       //           // 'nama': (user),
//                       //           'idSite': idSite,
//                       //           'user':
//                       //               user['username'] ?? auth.currentUser!.email,
//                       //           'tanggal': DateTime.now().toIso8601String(),
//                       //           'unit': idUnit.text,
//                       //           'hm': hmUnit.text,
//                       //           'posisi': position.map((p) {
//                       //             final pIndex = position.indexOf(p);
//                       //             log('tekanan angin : ${p['pressure']}');

//                       //             return {
//                       //               'pos': '${pIndex + 1}',
//                       //               'pressure': (p['pressure']) ?? '0',
//                       //               'rating': (p['rating']) ?? '0',
//                       //               'adjusmentPressure':
//                       //                   (p['adjusmentPressure']) ?? '0',
//                       //               'luka': p['damageTire'],
//                       //               'idUnit': p['idUnit'],
//                       //               'idInventory': p['idInventory'],
//                       //               'tireSize': p['tireSize'],
//                       //               'idDaily':
//                       //                   '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                       //               'tireAccessories': []
//                       //             };
//                       //           }),
//                       //           'pit': (idSite == bmbsitarum.idSite ||
//                       //                   idSite == bmbhauling.idSite ||
//                       //                   idSite == bmbtabuhan.idSite ||
//                       //                   idSite == bibkgb.idSite)
//                       //               ? pit[selectedPit]
//                       //               : 'Default'
//                       //         });
//                       //       }
//                       //     } catch (e) {
//                       //       print('error bmb : $e');
//                       //     }
//                       //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                       //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                       //       content: Text(
//                       //         'Successful save data, please check in home page',
//                       //         style: getWhiteTextStyle(),
//                       //       ),
//                       //       backgroundColor: green00968A,
//                       //     ));
//                       //     Navigator.pop(context);
//                       //   } catch (e) {
//                       //     log('kenapa gagal : $e');
//                       //   }
//                       // }
//                       function: () async {
//                         //// Validasi Tire Inspection
//                         final currentHm =
//                             double.tryParse(state.units[0].hm ?? '0') ?? 0;
//                         final newHm = double.tryParse(hmUnit.text ?? '0') ?? 0;

//                         // SMU/HM tidak boleh turun
//                         if (currentHm > newHm) {
//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                             content: Text(
//                               'SMU/HM tidak bisa berkurang',
//                               style: getWhiteTextStyle(),
//                             ),
//                             backgroundColor: Colors.red,
//                           ));
//                           return;
//                         }

//                         // SMU/HM tidak boleh nambah terlalu banyak
//                         if ((newHm - currentHm) > 1000) {
//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 'Perubahan SMU/HM tidak bisa lebih dari 1000',
//                                 style: getWhiteTextStyle(),
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }

//                         final List<String> errorsRtd = [];
//                         final List<String> errorsRating = [];

//                         for (int i = 0; i < state.units.length; i++) {
//                           final unit = state.units[i];

//                           // RTD tidak boleh naik
//                           final actualRtd =
//                               double.tryParse(unit.rtd.toString()) ?? 0;
//                           final actualOtd =
//                               double.tryParse(unit.otd.toString()) ?? 0;

//                           final inputRtd =
//                               double.tryParse(rtd1Controllers[i].text) ?? 0;
//                           final inputOtd =
//                               double.tryParse(rtd2Controllers[i].text) ?? 0;

//                           if (inputRtd > actualRtd) {
//                             errorsRtd.add(
//                               'Posisi ${unit.posisi}: RTD input ($inputRtd) melebihi RTD aktual ($actualRtd).',
//                             );
//                           }

//                           if (inputOtd > actualOtd) {
//                             errorsRtd.add(
//                               'Posisi ${unit.posisi}: OTD input ($inputOtd) melebihi OTD aktual ($actualOtd).',
//                             );
//                           }

//                           // Jika sudah rating x, tidak boleh kembali ke rating A,B,C
//                           const ratingScore = {
//                             'A': 4,
//                             'B': 3,
//                             'C': 2,
//                             'X': 1,
//                           };
//                           final actualRating = position[i]['prevRating']
//                               .toString()
//                               .toUpperCase()
//                               .trim();
//                           final inputRating = position[i]['rating']
//                               .toString()
//                               .toUpperCase()
//                               .trim();

//                           final actualScore = ratingScore[actualRating] ?? 0;
//                           final inputScore = ratingScore[inputRating] ?? 0;

//                           // Skip pengecekan jika prevRating kosong
//                           if (actualRating.isNotEmpty) {
//                             final actualScore = ratingScore[actualRating] ?? 0;
//                             final inputScore = ratingScore[inputRating] ?? 0;

//                             log('apakah rating membaik 3 : ${inputScore > actualScore}');

//                             if (inputScore > actualScore) {
//                               errorsRating.add(
//                                 'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
//                               );
//                             }
//                           }

//                           // if (inputScore > actualScore) {
//                           //   errorsRating.add(
//                           //     'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
//                           //   );
//                           // }
//                         }

//                         if (errorsRtd.isNotEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: const Duration(seconds: 6),
//                               content: Text(
//                                 errorsRtd.join('\n'),
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ),
//                           );
//                           return;
//                         }

//                         if (errorsRating.isNotEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: const Duration(seconds: 6),
//                               content: Text(
//                                 errorsRating.join('\n'),
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ),
//                           );
//                           return;
//                         }

//                         // input ke tire inspection
//                         try {
//                           position.removeWhere((element) =>
//                               element['pressure'] == '' &&
//                               (element['damageTire'] as List<dynamic>)
//                                   .isEmpty &&
//                               element['adjusmentPressure'] == '' &&
//                               element['rtd1'] == '' &&
//                               element['rtd2'] == '' &&
//                               element['rating'] == '' &&
//                               element['sn'] == '' &&
//                               element['remarks'] == '');

//                           final today = DateTime.now();
//                           final hari =
//                               '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
//                           final jam =
//                               '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}:${today.second.toString().padLeft(2, '0')}';
//                           final docId = '${hari}_${jam}';

//                           // Bangun list posisi sesuai struktur tire_inspection
//                           final List<Map<String, dynamic>> posisiList = [];
//                           log('unit tire inspection ${state.units}');
//                           final firstUnit = state.units[0];
//                           final String kunciUnit = firstUnit.kunciUnit ?? '';

//                           for (int i = 0; i < position.length; i++) {
//                             final unit = state.units[i];

//                             String? localImagePath;
//                             try {
//                               final imgList =
//                                   position[i]['image'] as List<dynamic>?;
//                               if (imgList != null && imgList.isNotEmpty) {
//                                 final raw = imgList[0] as String;
//                                 final parts = raw.split('|');
//                                 if (parts.isNotEmpty) {
//                                   localImagePath = parts[0];
//                                 }
//                               }
//                             } catch (e) {
//                               log('parse image error: $e');
//                             }

//                             final bool hasNewLocalImage =
//                                 localImagePath != null;

//                             posisiList.add({
//                               'position': position[i]['position'],
//                               'pressure': position[i]['pressure'],
//                               'adjusmentPressure': position[i]
//                                   ['adjusmentPressure'],
//                               'rating': position[i]['rating'],
//                               'rtd1': position[i]['rtd1'],
//                               'rtd2': position[i]['rtd2'],
//                               'sn': (position[i]['sn'] != null &&
//                                       position[i]['sn'] != '')
//                                   ? position[i]['sn']
//                                   : unit.sn,
//                               'remarks':
//                                   (position[i]['damageTire'] as List).isEmpty
//                                       ? damageType[0]
//                                       : position[i]['damageTire'][0],
//                               'damageTire':
//                                   (position[i]['damageTire'] as List).isEmpty
//                                       ? (damageType is List<String>)
//                                           ? damageType[0]
//                                           : damageType[0]['remark']
//                                       : position[i]['damageTire'],
//                               // 'condition': (position[i]['condition'] as List)
//                               //     .where((c) => c['checked'] == true)
//                               //     .map((c) => c['name'].toString())
//                               //     .toList(),
//                               'rimCondition': position[i]['rimCondition'],
//                               'idUnit': position[i]['idUnit'],
//                               'idInventory': position[i]['idInventory'],
//                               'tireSize': position[i]['tireSize'],
//                               'kunci_tire': unit.kunciTire,
//                               'hm': hmUnit.text,
//                               'images': [],
//                               'imagePending': hasNewLocalImage,
//                               'tireAccessories': [],
//                               'brand': firstUnit.brand,
//                               'pattern': firstUnit.pattern,
//                             });

//                             if (hasNewLocalImage) {
//                               // Pending upload akan di-handle setelah document dibuat
//                             }
//                           }

//                           // Cek apakah sudah ada dokumen tire_inspection hari ini untuk unit ini
//                           final startOfDay =
//                               DateTime(today.year, today.month, today.day);
//                           final endOfDay = DateTime(
//                               today.year, today.month, today.day, 23, 59, 59);

//                           final querySnapshot = await firestore
//                               .collection('tire_inspection')
//                               // .where('kunci_unit', isEqualTo: kunciUnit) // kunci_unit dari unit
//                               .where('hari', isEqualTo: hari)
//                               .where('unit', isEqualTo: firstUnit.unitNumber)
//                               // .where('tanggal',
//                               //     isGreaterThanOrEqualTo:
//                               //         startOfDay.toIso8601String())
//                               // .where('tanggal',
//                               //     isLessThanOrEqualTo:
//                               //         endOfDay.toIso8601String())
//                               .get();

//                           log('tire_inspection exists: ${querySnapshot.docs.isNotEmpty}');

//                           if (querySnapshot.docs.isNotEmpty) {
//                             // Update dokumen yang sudah ada
//                             final existingDocId = querySnapshot.docs.first.id;

//                             await firestore
//                                 .collection('tire_inspection')
//                                 .doc(existingDocId)
//                                 .update({
//                               'id': const Uuid().v4(),
//                               'id_site': idSite,
//                               'user': user['username'] ?? 'username',
//                               'user_email': auth.currentUser!.email,
//                               'unit': dataUnit['unitNumber'],
//                               'kunci_unit': kunciUnit,
//                               'hm': hmUnit.text,
//                               'hari': hari,
//                               'jam': jam,
//                               'tanggal': today.toIso8601String(),
//                               'pit': (idSite == bmbsitarum.idSite ||
//                                       idSite == bmbhauling.idSite ||
//                                       idSite == bmbtabuhan.idSite ||
//                                       idSite == bibkgb.idSite)
//                                   ? pit[selectedPit]
//                                   : 'Default',
//                               'posisi': posisiList,
//                               'brand': firstUnit.unitNumber,
//                               'pattern': firstUnit.pattern,
//                             });

//                             // Handle image upload per posisi
//                             for (int i = 0; i < position.length; i++) {
//                               String? localImagePath;
//                               try {
//                                 final imgList =
//                                     position[i]['image'] as List<dynamic>?;
//                                 if (imgList != null && imgList.isNotEmpty) {
//                                   final raw = imgList[0] as String;
//                                   final parts = raw.split('|');
//                                   if (parts.isNotEmpty)
//                                     localImagePath = parts[0];
//                                 }
//                               } catch (e) {
//                                 log('parse image error: $e');
//                               }
//                               if (localImagePath != null) {
//                                 UploadQueueService.to.addPending(
//                                     docId: existingDocId,
//                                     filePath: localImagePath,
//                                     posisiIndex: i);
//                               }
//                             }
//                           } else {
//                             // Buat dokumen baru dengan ID format tanggal_jam
//                             final newData = {
//                               'id': const Uuid().v4(),
//                               'id_site': idSite,
//                               'user': user['username'] ?? 'username',
//                               'user_email': auth.currentUser!.email,
//                               'unit': dataUnit['unitNumber'],
//                               'kunci_unit': kunciUnit,
//                               'hm': hmUnit.text,
//                               'hari': hari,
//                               'jam': jam,
//                               'tanggal': today.toIso8601String(),
//                               'pit': (idSite == bmbsitarum.idSite ||
//                                       idSite == bmbhauling.idSite ||
//                                       idSite == bmbtabuhan.idSite ||
//                                       idSite == bibkgb.idSite)
//                                   ? pit[selectedPit]
//                                   : 'Default',
//                               'posisi': posisiList,
//                             };

//                             final docRef = await firestore
//                                 .collection('tire_inspection')
//                                 .doc(docId)
//                                 .set(newData);

//                             // Handle image upload per posisi
//                             for (int i = 0; i < position.length; i++) {
//                               String? localImagePath;
//                               try {
//                                 final imgList =
//                                     position[i]['image'] as List<dynamic>?;
//                                 if (imgList != null && imgList.isNotEmpty) {
//                                   final raw = imgList[0] as String;
//                                   final parts = raw.split('|');
//                                   if (parts.isNotEmpty)
//                                     localImagePath = parts[0];
//                                 }
//                               } catch (e) {
//                                 log('parse image error: $e');
//                               }
//                               if (localImagePath != null) {
//                                 UploadQueueService.to.addPending(
//                                   docId: docId,
//                                   filePath: localImagePath,
//                                   posisiIndex: i,
//                                 );
//                               }
//                             }
//                           }

//                           //     // input ke daily check pressure
//                           try {
//                             final today = DateTime.now();
//                             final startOfDay =
//                                 DateTime(today.year, today.month, today.day);
//                             final endOfDay = DateTime(
//                                 today.year, today.month, today.day, 23, 59, 59);
//                             final formattedToday =
//                                 '${today.month.toString().padLeft(2, '0')}' // MM
//                                 '${today.day.toString().padLeft(2, '0')}' // DD
//                                 '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

//                             final querySnapshot = await FirebaseFirestore
//                                 .instance
//                                 .collection('daily_pressure')
//                                 .where('unit',
//                                     isEqualTo: dataUnit['unitNumber'])
//                                 .where('tanggal',
//                                     isGreaterThanOrEqualTo:
//                                         startOfDay.toIso8601String())
//                                 .where('tanggal',
//                                     isLessThanOrEqualTo:
//                                         endOfDay.toIso8601String())
//                                 .get();

//                             print(
//                                 'Documents found: ${querySnapshot.docs.length}');

//                             if (querySnapshot.docs.isNotEmpty) {
//                               final docId = querySnapshot.docs.first.id;

//                               // revisi data
//                               await firestore
//                                   .collection('daily_pressure')
//                                   .doc(docId)
//                                   .update({
//                                 'idSite': idSite,
//                                 'user':
//                                     user['username'] ?? auth.currentUser!.email,
//                                 'tanggal': DateTime.now().toIso8601String(),
//                                 'unit': idUnit.text,
//                                 'hm': hmUnit.text,
//                                 'posisi': position.map((p) {
//                                   final pIndex = position.indexOf(p);

//                                   log('tekanan angin : ${p['pressure']}');
//                                   return {
//                                     'pos': '${pIndex + 1}',
//                                     'pressure': (p['pressure']) ?? '0',
//                                     'rating': (p['rating']) ?? '',
//                                     'adjusmentPressure':
//                                         (p['adjusmentPressure']) ?? '0',
//                                     'luka': p['damageTire'],
//                                     'idUnit': p['idUnit'],
//                                     'idInventory': p['idInventory'],
//                                     'tireSize': p['tireSize'],
//                                     'idDaily':
//                                         '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                                     'tireAccessories': []
//                                   };
//                                 }),
//                                 'pit': (idSite == bmbsitarum.idSite ||
//                                         idSite == bmbhauling.idSite ||
//                                         idSite == bmbtabuhan.idSite ||
//                                         idSite == bibkgb.idSite)
//                                     ? pit[selectedPit]
//                                     : 'Default'
//                               });
//                             } else {
//                               // tambah data
//                               await firestore.collection('daily_pressure').add({
//                                 // 'nama': (user),
//                                 'idSite': idSite,
//                                 'user':
//                                     user['username'] ?? auth.currentUser!.email,
//                                 'tanggal': DateTime.now().toIso8601String(),
//                                 'unit': idUnit.text,
//                                 'hm': hmUnit.text,
//                                 'posisi': position.map((p) {
//                                   final pIndex = position.indexOf(p);
//                                   log('tekanan angin : ${p['pressure']}');

//                                   return {
//                                     'pos': '${pIndex + 1}',
//                                     'pressure': (p['pressure']) ?? '0',
//                                     'rating': (p['rating']) ?? '0',
//                                     'adjusmentPressure':
//                                         (p['adjusmentPressure']) ?? '0',
//                                     'luka': p['damageTire'],
//                                     'idUnit': p['idUnit'],
//                                     'idInventory': p['idInventory'],
//                                     'tireSize': p['tireSize'],
//                                     'idDaily':
//                                         '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                                     'tireAccessories': []
//                                   };
//                                 }),
//                                 'pit': (idSite == bmbsitarum.idSite ||
//                                         idSite == bmbhauling.idSite ||
//                                         idSite == bmbtabuhan.idSite ||
//                                         idSite == bibkgb.idSite)
//                                     ? pit[selectedPit]
//                                     : 'Default'
//                               });
//                             }
//                           } catch (e) {
//                             print('error bmb : $e');
//                           }

//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                             content: Text(
//                               'Successful save data, please check in home page',
//                               style: getWhiteTextStyle(),
//                             ),
//                             backgroundColor: green00968A,
//                           ));
//                           Navigator.pop(context);
//                         } catch (e) {
//                           log('kenapa gagal : $e');
//                         }
//                       }),
//                 );
//               }
//               return Container();
//             },
//           ),
//           const SizedBox(
//             height: 12,
//           ),
//         ],
//       ),
//     );
//   }
// }

// Loading State
// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:app_settings/app_settings.dart';
// import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
// import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
// import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
// import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart'
//     as connectedDevicesState;
// import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart';
// import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_cubit.dart';
// import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_state.dart';
// import 'package:camos/core/services/api_service.dart';
// import 'package:camos/core/services/model/tire_damage_ai.dart';
// import 'package:camos/core/utils/bluetooth/utils/bluetooth_utils.dart';
// import 'package:camos/core/utils/data/id_site.dart';
// import 'package:camos/pages/home/home_state.dart';
// import 'package:camos/pages/pressure_gauge_digital/trial/scan_device_page.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/bounding_box_painter.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/upload_queue_service.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:get/get.dart';
// import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
// import 'package:path_provider/path_provider.dart';
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
// import 'package:carousel_slider/carousel_controller.dart';
// import 'package:carousel_slider/carousel_slider.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_storage/firebase_storage.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:uuid/uuid.dart';

// import 'widget/ai_loading_widget.dart';

// class TireInspectionFormPage extends StatefulWidget {
//   static const routeName = '/pgd-page';
//   const TireInspectionFormPage({super.key});

//   @override
//   State<TireInspectionFormPage> createState() => _TireInspectionFormPageState();
// }

// class _TireInspectionFormPageState extends State<TireInspectionFormPage>
//     with WidgetsBindingObserver {
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth auth = FirebaseAuth.instance;
//   final HomeState homeState = Get.find<HomeState>();

//   bool _isInit = true;
//   int selectedMenu = 1;
//   var map = {};
//   String idSite = '';
//   bool isSaved = false;
//   bool isLoadingSave = false;
//   Map<String, dynamic> dataUnit = {};
//   String? _hmInitializedForUnit;

//   TextEditingController idUnit = TextEditingController(text: '');
//   TextEditingController hmUnit = TextEditingController(text: '');
//   TextEditingController pressureCtrl = TextEditingController(text: '');
//   TextEditingController remarksCtrl = TextEditingController(text: '');
//   TextEditingController damageCtrl = TextEditingController(text: '');
//   TextEditingController rtd1 = TextEditingController(text: '');
//   TextEditingController rtd2 = TextEditingController(text: '');
//   List<TextEditingController> remarksControllers = [];
//   List<TextEditingController> snControllers = [];
//   List<TextEditingController> rtd1Controllers = [];
//   List<TextEditingController> rtd2Controllers = [];

//   SwiperController swiperController = SwiperController();

//   Map<int, TireDamageAi> aiResults = {};
//   Map<int, bool> loadingAI = {};
//   Map<int, double> imageWidths = {};
//   Map<int, double> imageHeights = {};

//   List<String>? _ratingCache;
//   List<dynamic>? _damageCache;

//   String selectedUnit = '';
//   List<String> checkedCategories = [];
//   List<Map<String, dynamic>> checkedCategoriesManual = [
//     {'name': 'Reseal Oring', 'checked': false},
//     {'name': 'Rim Condition', 'checked': false},
//     {'name': 'Inflate Tire', 'checked': false},
//     {'name': 'Lock Driver', 'checked': false},
//     {'name': 'Slide Lock', 'checked': false},
//     {'name': 'Valve Cap', 'checked': false},
//     {'name': 'Valve Protector', 'checked': false},
//     {'name': 'Stud and Nut', 'checked': false},
//   ];

//   List<bool> checkedListCategory = List<bool>.filled(8, false);
//   String selectedTireDamage = '';
//   String remarks = '';
//   String rtd = '';
//   List<String> listImg = [];
//   Map<String, dynamic> user = {};
//   bool _listenerAdded = false;
//   int checkAmount = 0;
//   int selectedRoute = 0;
//   List<List<int>> inspectRoute = [
//     [0, 1, 2, 3, 4, 5],
//     [0, 2, 3, 4, 5, 1],
//     [1, 5, 4, 3, 2, 0],
//   ];

//   List<String> pressure = [
//     '0',
//     '95',
//     '100',
//     '105',
//     '110',
//     '115',
//     '120',
//     '125',
//     '130',
//     '135',
//   ];
//   List<Map<String, dynamic>> position = [];

//   // List<String> damageType = [
//   //   'Good Condition',
//   //   'Accident',
//   //   'Bead Crack',
//   //   'Boulder',
//   //   'Bulging',
//   //   'Bead Damage',
//   //   'Chaffer Separation',
//   //   'Dog Bound',
//   //   'Foreign Object',
//   //   'Heat Separation',
//   //   'Inner Linner Separation',
//   //   'Impact',
//   //   'Repair Failure',
//   //   'Radial Crack',
//   //   'Run Flat',
//   //   'Sidewall Crack',
//   //   'Sidewall Cut',
//   //   'Sidewall Cut 2',
//   //   'Sidewall Cut 3',
//   //   'Sidewall Separation',
//   //   'Shoulder Cut',
//   //   'Shoulder Separation',
//   //   'Tread Chipping',
//   //   'Tread Chunking',
//   //   'Tread Lifting',
//   //   'Tread Cut',
//   //   'Tread Cut Separation',
//   //   'Worn Out',
//   // ];

//   List<Map<String, dynamic>> damageType = [];
//   bool loadingDamages = true;

//   List<String> selectedDamage = [];

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

//   List<String> rating = [
//     'A',
//     'B',
//     'C',
//     'X',
//   ];

//   List<String> pit = [];
//   int selectedPit = -1;

//   void showRimInspectionDialog(int tireIndex) {
//     final originalList = position[tireIndex]['rimCondition'];

//     /// 🔥 COPY DATA DULU (supaya Close tidak menyimpan)
//     List<Map<String, dynamic>> tempList =
//         originalList.map<Map<String, dynamic>>((item) {
//       return {
//         'title': item['title'],
//         'condition': item['condition'],
//         'remark': item['remark'],
//       };
//     }).toList();

//     showDialog(
//       context: context,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, stState) {
//             return AlertDialog(
//               title: Text(
//                 'Periksa Kondisi : ',
//                 style: TextStyle(fontWeight: FontWeight.bold),
//               ),
//               content: SizedBox(
//                 width: double.maxFinite,
//                 child: SingleChildScrollView(
//                   child: Column(
//                     children: List.generate(tempList.length, (i) {
//                       final rimItem = tempList[i];
//                       final bool isGood = rimItem['condition'] == 'Good';
//                       final bool isPoor = rimItem['condition'] == 'Poor';

//                       return Container(
//                         margin: EdgeInsets.only(bottom: 14),
//                         padding: EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: isGood
//                               ? Colors.green.withOpacity(0.12)
//                               : Colors.red.withOpacity(0.12),
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             /// TITLE
//                             Text(
//                               rimItem['title'],
//                               style: TextStyle(fontWeight: FontWeight.bold),
//                             ),

//                             SizedBox(height: 10),

//                             /// GOOD / POOR
//                             Row(
//                               children: [
//                                 Expanded(
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       stState(() {
//                                         rimItem['condition'] = 'Good';
//                                       });
//                                     },
//                                     child: Container(
//                                       padding:
//                                           EdgeInsets.symmetric(vertical: 10),
//                                       decoration: BoxDecoration(
//                                         color: isGood
//                                             ? Colors.green
//                                             : Colors.grey[300],
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       alignment: Alignment.center,
//                                       child: Text(
//                                         'GOOD',
//                                         style: TextStyle(
//                                           color: isGood
//                                               ? Colors.white
//                                               : Colors.black,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                                 SizedBox(width: 10),
//                                 Expanded(
//                                   child: GestureDetector(
//                                     onTap: () {
//                                       stState(() {
//                                         rimItem['condition'] = 'Poor';
//                                       });
//                                     },
//                                     child: Container(
//                                       padding:
//                                           EdgeInsets.symmetric(vertical: 10),
//                                       decoration: BoxDecoration(
//                                         color: isPoor
//                                             ? Colors.red
//                                             : Colors.grey[300],
//                                         borderRadius: BorderRadius.circular(8),
//                                       ),
//                                       alignment: Alignment.center,
//                                       child: Text(
//                                         'POOR',
//                                         style: TextStyle(
//                                           color: isPoor
//                                               ? Colors.white
//                                               : Colors.black,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),

//                             SizedBox(height: 10),

//                             // Job Description
//                             TextField(
//                               controller: TextEditingController(
//                                   text: rimItem['jobDescription'] ?? '')
//                                 ..selection = TextSelection.fromPosition(
//                                   TextPosition(
//                                       offset: (rimItem['jobDescription'] ?? '')
//                                           .length),
//                                 ),
//                               style: TextStyle(fontSize: 12),
//                               decoration: InputDecoration(
//                                 hintText: 'Job Description',
//                                 isDense: true,
//                                 contentPadding: EdgeInsets.symmetric(
//                                     horizontal: 8, vertical: 6),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 filled: true,
//                                 fillColor: Colors.white,
//                               ),
//                               maxLines: 1,
//                               onChanged: (val) {
//                                 rimItem['jobDescription'] = val;
//                               },
//                             ),

//                             SizedBox(height: 10),

//                             /// REMARK
//                             TextField(
//                               controller: TextEditingController(
//                                   text: rimItem['remark'] ?? '')
//                                 ..selection = TextSelection.fromPosition(
//                                   TextPosition(
//                                       offset: (rimItem['remark'] ?? '').length),
//                                 ),
//                               style: TextStyle(fontSize: 12), // kecilkan font
//                               decoration: InputDecoration(
//                                 hintText: 'Remark...',
//                                 isDense: true, // bikin lebih compact
//                                 contentPadding: EdgeInsets.symmetric(
//                                   horizontal: 8,
//                                   vertical: 6, // lebih kecil
//                                 ),
//                                 border: OutlineInputBorder(
//                                   borderRadius: BorderRadius.circular(8),
//                                 ),
//                                 filled: true,
//                                 fillColor: Colors.white,
//                               ),
//                               maxLines: 2, // supaya tidak terlalu tinggi
//                               onChanged: (val) {
//                                 rimItem['remark'] = val;
//                               },
//                             ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ),
//                 ),
//               ),

//               /// 🔥 ACTION BUTTONS
//               actions: [
//                 /// CLOSE (TIDAK SIMPAN)
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                   },
//                   child: Text(
//                     'Close',
//                     style: getRedTextStyle(fontWeight: w500),
//                   ),
//                 ),

//                 /// SAVE (SIMPAN KE position)
//                 ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue,
//                   ),
//                   onPressed: () {
//                     setState(() {
//                       position[tireIndex]['rimCondition'] = tempList;
//                     });

//                     Navigator.pop(context);
//                   },
//                   child: Text(
//                     'Save',
//                     style: getWhiteTextStyle(fontWeight: w500),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }

//   @override
//   void initState() {
//     idSite = homeState.currentSiteId;
//     _loadDamages();

//     super.initState();
//     requestPlacePermission();

//     context.read<BluetoothOnOffCubit>().checkBluetoothStatus();
//     final connectedCubit = context.read<ConnectedDevicesCubit>();
//     log('connected cubit : $connectedCubit');
//     connectedCubit.fetchConnectedDevices(); // HANYA MEMULAI fetch

//     // callTires();
//     WidgetsBinding.instance.addObserver(this);
//     getUser();
//   }

//   Future<void> loadPreviousRating(
//       int index, String unit, String kunciTire) async {
//     print('load previous rating unit : $unit');
//     try {
//       final snapshot = await firestore
//           .collection('tire_inspection')
//           .where('unit', isEqualTo: unit) // ✅ FILTER UNIT
//           .orderBy('tanggal', descending: true)
//           .limit(1) // ✅ hanya dokumen terbaru unit itu
//           .get();

//       log('load previous rating : ${snapshot.docs}');

//       if (snapshot.docs.isEmpty) return;

//       final doc = snapshot.docs.first;

//       final List<dynamic> posisiList = doc['posisi'];

//       for (final pos in posisiList) {
//         if (pos['kunci_tire'] == kunciTire) {
//           final prevRating = pos['rating'];

//           if (prevRating != null) {
//             setState(() {
//               position[index]['rating'] =
//                   prevRating is String ? prevRating : [prevRating];
//               position[index]['prevRating'] =
//                   prevRating is String ? prevRating : [prevRating];
//             });

//             log('AUTO RATING FOUND: $prevRating');
//             return;
//           }
//         }
//       }
//     } catch (e) {
//       log('loadPreviousRating error: $e');
//     }
//   }

//   Future<void> loadPreviousDamage(
//       int index, String unit, String kunciTire) async {
//     print('load previous damage unit : $unit');
//     try {
//       final snapshot = await firestore
//           .collection('tire_inspection')
//           .where('unit', isEqualTo: unit) // ✅ FILTER UNIT
//           .orderBy('tanggal', descending: true)
//           .limit(1) // ✅ hanya dokumen terbaru unit itu
//           .get();

//       log('load previous damage : ${snapshot.docs}');

//       if (snapshot.docs.isEmpty) return;

//       final doc = snapshot.docs.first;

//       final List<dynamic> posisiList = doc['posisi'];

//       for (final pos in posisiList) {
//         if (pos['kunci_tire'] == kunciTire) {
//           final prevDamage = pos['damageTire'];
//           final prevRemarks = pos['remarks'];

//           if (prevDamage != null) {
//             setState(() {
//               position[index]['damageTire'] =
//                   prevDamage is List ? prevDamage : [prevDamage];
//             });

//             log('AUTO DAMAGE FOUND: $prevDamage');
//             return;
//           }

//           if (prevRemarks != null && prevRemarks != '') {
//             setState(() {
//               position[index]['remarks'] = prevRemarks;
//             });

//             log('AUTO REMARKS FOUND: $prevRemarks');
//             return;
//           }
//         }
//       }
//     } catch (e) {
//       log('loadPreviousDamage error: $e');
//     }
//   }

//   // Future<void> _loadDamages() async {
//   //   try {
//   //     final query =
//   //         await firestore.collection('list_tire_damage_inspection').get();

//   //     final docs = query.docs.where((doc) {
//   //       return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(doc.id);
//   //     }).toList();

//   //     docs.sort((a, b) => b.id.compareTo(a.id));

//   //     final latestDoc = docs.first;

//   //     final data = latestDoc.data();

//   //     log('docs luka ban : $data');

//   //     if (data != null && data['damages'] != null) {
//   //       final List<dynamic> raw = data['damages'];

//   //       List<Map<String, dynamic>> sortedList =
//   //           raw.map<Map<String, dynamic>>((e) {
//   //         return Map<String, dynamic>.from(e);
//   //       }).toList();

//   //       sortedList.sort((a, b) {
//   //         final aRemark = (a['remark'] ?? '').toString().toLowerCase();
//   //         final bRemark = (b['remark'] ?? '').toString().toLowerCase();

//   //         final aGood = aRemark.contains('good');
//   //         final bGood = bRemark.contains('good');

//   //         if (aGood && !bGood) return -1;
//   //         if (!aGood && bGood) return 1;

//   //         return aRemark.compareTo(bRemark);
//   //       });

//   //       setState(() {
//   //         damageType = sortedList;
//   //         loadingDamages = false;
//   //       });
//   //     } else {
//   //       setState(() {
//   //         loadingDamages = false;
//   //       });
//   //     }
//   //   } catch (e) {
//   //     debugPrint('Error load damages: $e');

//   //     setState(() {
//   //       loadingDamages = false;
//   //     });
//   //   }
//   // }

//   Future<void> _loadDamages() async {
//     try {
//       Map<String, dynamic>? data;
//       final sisIdSite = await getIdSiteSIS();
//       final isSisIdSite = sisIdSite.any((site) => site.idSite == idSite);

//       if (isSisIdSite) {
//         final doc = await firestore
//             .collection('list_tire_damage_inspection')
//             .doc('sis062026')
//             .get();

//         if (doc.exists) {
//           data = doc.data();
//         }
//       } else {
//         final query =
//             await firestore.collection('list_tire_damage_inspection').get();

//         final docs = query.docs.where((doc) {
//           return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(doc.id);
//         }).toList();

//         docs.sort((a, b) => b.id.compareTo(a.id));

//         if (docs.isNotEmpty) {
//           data = docs.first.data();
//         }
//       }

//       log('docs luka ban : $data');

//       if (data != null && data['damages'] != null) {
//         final List<dynamic> raw = data['damages'];

//         List<Map<String, dynamic>> sortedList =
//             raw.map<Map<String, dynamic>>((e) {
//           return Map<String, dynamic>.from(e);
//         }).toList();

//         sortedList.sort((a, b) {
//           final aRemark = (a['remark'] ?? '').toString().toLowerCase();
//           final bRemark = (b['remark'] ?? '').toString().toLowerCase();

//           final aGood = aRemark.contains('good');
//           final bGood = bRemark.contains('good');

//           if (aGood && !bGood) return -1;
//           if (!aGood && bGood) return 1;

//           return aRemark.compareTo(bRemark);
//         });

//         setState(() {
//           damageType = sortedList;
//           loadingDamages = false;
//         });
//       } else {
//         setState(() {
//           loadingDamages = false;
//         });
//       }
//     } catch (e) {
//       debugPrint('Error load damages: $e');

//       setState(() {
//         loadingDamages = false;
//       });
//     }
//   }

//   getUser() async {
//     user = await getUserPreferences();
//     log('username : ${user}');
//   }

//   @override
//   void dispose() {
//     WidgetsBinding.instance.removeObserver(this);

//     idUnit.dispose();
//     hmUnit.dispose();
//     pressureCtrl.dispose();
//     remarksCtrl.dispose();
//     damageCtrl.dispose();
//     rtd1.dispose();
//     rtd2.dispose();

//     for (final controller in remarksControllers) {
//       controller.dispose();
//     }

//     for (final controller in snControllers) {
//       controller.dispose();
//     }

//     for (final controller in rtd1Controllers) {
//       controller.dispose();
//     }

//     for (final controller in rtd2Controllers) {
//       controller.dispose();
//     }

//     swiperController.dispose();

//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_isInit) {
//       final args = ModalRoute.of(context)?.settings.arguments;
//       if (args != null) {
//         dataUnit = args as Map<String, dynamic>;
//         log('TireInspectionPage: dataUnit berhasil diambil -> $dataUnit');

//         // Panggil callTires() setelah dataUnit pasti terisi
//         callTires();
//       } else {
//         log('TireInspectionPage: ERROR! Argumen navigasi null.');
//       }

//       _isInit = false; // Set flag agar tidak dijalankan lagi
//     }
//   }

//   List<BluetoothDevice> devices = [];
//   String tmpPressure = '';
//   final Box<TireInspectPictureEntity> imageBox =
//       store.box<TireInspectPictureEntity>();

//   insertPit() {
//     setState(() {
//       // if (idSite == '52') {
//       //   pit.add('Utara');
//       //   pit.add('Selatan');
//       //   pit.add('RML');
//       //   pit.add('WS');
//       // }
//     });
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

//   Future<void> _analyzeDamageWithAI(int index) async {
//     if (loadingAI[index] == true) return;

//     final images = position[index]['image'] as List<dynamic>?;
//     if (images == null || images.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           backgroundColor: Colors.red,
//           content: Text('Please take a picture first.'),
//         ),
//       );
//       return;
//     }

//     final rawImage = images.first.toString();
//     final imagePath = rawImage.split('|').first;
//     final imageFile = File(imagePath);

//     if (!await imageFile.exists()) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           backgroundColor: Colors.red,
//           content: Text('Image file was not found. Please take a new picture.'),
//         ),
//       );
//       return;
//     }

//     setState(() {
//       loadingAI[index] = true;
//       aiResults.remove(index);
//     });

//     try {
//       final bytes = await imageFile.readAsBytes();
//       final decodedImage = await decodeImageFromList(bytes);
//       final base64Image = base64Encode(bytes);
//       final token = await ApiService.getValidToken();
//       final result = await ApiService.postPredictImageAI(
//         token,
//         base64Image,
//       );

//       if (result == null) {
//         throw Exception('AI analysis returned an empty result.');
//       }

//       if (!mounted) return;
//       setState(() {
//         imageWidths[index] = decodedImage.width.toDouble();
//         imageHeights[index] = decodedImage.height.toDouble();
//         aiResults[index] = result;
//       });

//       log('tire damage ai : $result');
//     } catch (e) {
//       log('analyze tire damage ai error : $e');

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text('Failed to analyze damage with AI: $e'),
//         ),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           loadingAI[index] = false;
//         });
//       }
//     }
//   }

//   void callTires() async {
//     String userAccessId = homeState.userAccessId.value;
//     if (mounted) {
//       if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
//         idUnit.text = dataUnit['unitNumber'];
//         // hmUnit.text = dataUnit['hm'];
//         context.read<TireBloc>().add(GetUnitTiresEvent(
//             idSite: idSite, unitNumber: dataUnit['unitNumber']));
//       }
//     }

//     insertPit();
//   }

//   void handleDataRemarks(String remarks, int index) {
//     this.remarks = remarks;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   void handleDataRTD(String rtd, int index) {
//     this.rtd = rtd;
//     print('remarks (pgd) : ${this.remarks}');
//   }

//   void applyPressureData(String pressureValue) {
//     setState(() {
//       final firstNumber = pressureValue;

//       if (checkAmount < position.length) {
//         int targetIndex = inspectRoute[selectedRoute][checkAmount];
//         log('target position : ${targetIndex}');
//         log('target pressure : ${firstNumber}');

//         // Update Map di index tersebut
//         position[targetIndex]["pressure"] = firstNumber;

//         checkAmount++;
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     pit.clear();
//     // if (idSite == '52') {
//     //   pit.add('Utara');
//     //   pit.add('Selatan');
//     //   pit.add('RML');
//     //   pit.add('WS');
//     // }
//     switch (idSite) {
//       case '52':
//         pit.add('Utara');
//         pit.add('Selatan');
//         pit.add('RML');
//         pit.add('WS');
//         break;
//       case '137':
//         pit.add('Japun');
//         pit.add('PCE');
//         break;
//       case '35':
//         pit.add('Tabuhan');
//         pit.add('EBL');
//         pit.add('Workshop');
//         break;
//       case '65':
//         pit.add('Room B1 Selatan');
//         pit.add('TIA');
//         pit.add('Serongga');
//         pit.add('CSA Selatan');
//         pit.add('WS');
//         break;
//       case '166':
//         pit.add('WS');
//         pit.add('Pondok Operator');
//         pit.add('CSA Bagaspati');
//         pit.add('Pit Stop Toll');
//         break;
//     }
//     print('dipanggil (pgd)');
//     dataUnit =
//         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       appBar: AppBar(
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         title: Padding(
//           padding: const EdgeInsets.only(top: 18.0),
//           child: Text(
//             'Tire Inspection',
//             textAlign: TextAlign.center,
//             style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
//           ),
//         ),
//         centerTitle: true,
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 16),
//           child: Container(
//             margin: const EdgeInsets.only(top: 14),
//             padding: const EdgeInsets.symmetric(horizontal: 4),
//             decoration: BoxDecoration(
//               color: white,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: black),
//             ),
//             child: IconButton(
//                 onPressed: () {
//                   if (isSaved) {
//                     pushReplace(context, HomePage.routeName);
//                   } else {
//                     back(context);
//                   }
//                 },
//                 icon: const Icon(
//                   Icons.arrow_back_ios,
//                   color: black,
//                   size: 24,
//                 )),
//           ),
//         ),
//       ),
//       body: SafeArea(
//           child: BlocConsumer<TireBloc, TireState>(
//         listener: (context, state) {
//           if (state is TiresLoadedState) {
//             final firstUnit = state.units.first;
//             final currentUnitNumber = firstUnit.unitNumber ?? '';

//             if (_hmInitializedForUnit != currentUnitNumber) {
//               hmUnit.text = idSite == bmbhauling.idSite
//                   ? ''
//                   : firstUnit.hm?.toString() ?? '';

//               _hmInitializedForUnit = currentUnitNumber;
//             }

//             position.clear();

//             for (int i = 0; i < state.units.length; i++) {
//               final unit = state.units[i];
//               for (int i = 0; i < position.length; i++) {
//                 final unit = state.units[i];

//                 if (unit.kunciTire != null) {
//                   loadPreviousRating(
//                       i, unit.unitNumber ?? '', unit.kunciTire ?? '');
//                   loadPreviousDamage(
//                       i, unit.unitNumber ?? '', unit.kunciTire ?? '');
//                 }
//               }
//               remarksControllers.add(TextEditingController(text: ''));
//               snControllers.add(TextEditingController(text: ''));
//               rtd1Controllers.add(
//                 TextEditingController(text: unit.rtd?.toString() ?? ''),
//               );

//               rtd2Controllers.add(
//                 TextEditingController(text: unit.otd?.toString() ?? ''),
//               );
//               position.add({
//                 'position': i + 1,
//                 'pressure': '',
//                 'adjusmentPressure': '',
//                 'hm': '',
//                 'damageTire': [],
//                 'rtd1': unit.rtd?.toString() ?? '',
//                 'rtd2': unit.otd?.toString() ?? '',
//                 'remarks': '',
//                 'sn': unit.sn,
//                 'rating': '',
//                 'prevRating': '',
//                 'image': [],
//                 'idInventory': unit.idinventory,
//                 'idUnit': unit.idUnit,
//                 'tireSize': unit.size,
//                 // 'condition': [
//                 //   {'name': 'Reseal Oring', 'checked': false},
//                 //   {'name': 'Rim Condition', 'checked': false},
//                 //   {'name': 'Inflate Tire', 'checked': false},
//                 //   {'name': 'Lock Driver', 'checked': false},
//                 //   {'name': 'Slide Lock', 'checked': false},
//                 //   {'name': 'Valve Cap', 'checked': false},
//                 //   {'name': 'Valve Protector', 'checked': false},
//                 //   {'name': 'Stud and Nut', 'checked': false},
//                 // ],
//                 'rimCondition': [
//                   {
//                     'title': 'RIM BASE',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'FLANGE',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'LOCK RING',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'VALVE (TERPASANG/TIDAK TERPASANG)',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'CORE VALVE',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                   {
//                     'title': 'NUT DAN STUD RODA',
//                     'jobDescription': '',
//                     'condition': 'Good',
//                     'remark': ''
//                   },
//                 ],
//                 'tireAccessories': []
//               });
//             }
//             log('message position tire inspect : ${position}');
//           }
//         },
//         builder: (context, state) {
//           if (state is TireLoadingState) {
//             return Center(
//               child: CircularProgressIndicator(),
//             );
//           }
//           if (state is TiresLoadedState) {
//             final units = state.units;

//             return SingleChildScrollView(
//               child: Padding(
//                 padding: const EdgeInsets.all(24.0),
//                 child: Column(
//                   children: [
//                     (pit.isNotEmpty)
//                         ? Row(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               Icon(
//                                 Icons.ev_station,
//                                 size: 38,
//                               ),
//                               const SizedBox(
//                                 width: 12,
//                               ),
//                               Text(
//                                 'Unit Location',
//                                 style: getBlackTextStyle(
//                                     fontSize: 18, fontWeight: w700),
//                               ),
//                             ],
//                           )
//                         : Container(),
//                     SizedBox(
//                       height: (pit.isNotEmpty) ? 24 : 0,
//                     ),
//                     (pit.isNotEmpty)
//                         ? Center(
//                             child: Wrap(
//                               spacing: 8.0, // Jarak horizontal antar tombol
//                               children: pit.map((e) {
//                                 final pitIndex = pit.indexOf(e);
//                                 return ElevatedButton(
//                                   style: ElevatedButton.styleFrom(
//                                     backgroundColor: (selectedPit == pitIndex)
//                                         ? Colors.orange
//                                         : greyF7F8F9,
//                                   ),
//                                   onPressed: () {
//                                     setState(() {
//                                       selectedPit = pitIndex;
//                                     });
//                                   },
//                                   child: Text(
//                                     e,
//                                     style: (selectedPit == pitIndex)
//                                         ? getWhiteTextStyle()
//                                         : getBlackTextStyle(),
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                           )
//                         : Container(),
//                     SizedBox(
//                       height: (pit.isNotEmpty) ? 24 : 0,
//                     ),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Column(
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.front_loader,
//                                     color: Colors.orange,
//                                     size: 38,
//                                   ),
//                                   const SizedBox(
//                                     width: 12,
//                                   ),
//                                   Text(
//                                     'UNIT',
//                                     style: getBlackTextStyle(
//                                         fontWeight: w700, fontSize: 18),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                     isReadOnly: true,
//                                     controller: TextEditingController(
//                                       text: units[0].unitNumber,
//                                     ),
//                                     hint: ''),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(
//                           width: 12,
//                         ),
//                         Expanded(
//                           child: Column(
//                             children: [
//                               Row(
//                                 children: [
//                                   Icon(
//                                     Icons.watch,
//                                     color: Colors.red,
//                                     size: 38,
//                                   ),
//                                   const SizedBox(
//                                     width: 12,
//                                   ),
//                                   Text(
//                                     (idSite == bmbhauling.idSite &&
//                                             idSite == '1')
//                                         ? 'KM Unit'
//                                         : 'HM Unit',
//                                     style: getBlackTextStyle(
//                                         fontWeight: w700, fontSize: 18),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(
//                                 height: 12,
//                               ),
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: InputFormWidget(
//                                   controller: hmUnit,
//                                   isDecimalOnly: true,
//                                   type: const TextInputType.numberWithOptions(
//                                     decimal: true,
//                                   ),
//                                   hint:
//                                       'Fill ${idSite == bmbhauling.idSite ? 'KM' : 'HM'}',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     BlocBuilder<ConnectedDevicesCubit, ConnectedDevicesState>(
//                       builder: (context, cState) {
//                         // Asumsikan perangkat TPMS adalah yang terhubung jika statusnya Success
//                         final isConnected =
//                             cState is ConnectedDevicesLoadedState &&
//                                 cState.connectedDevices.isNotEmpty;

//                         // Cari perangkat yang terhubung yang memiliki nama yang relevan
//                         // (Anda harus menyesuaikan logika pencarian ini sesuai nama perangkat BT Anda)
//                         final BluetoothDevice? connectedDevice = isConnected
//                             ? cState.connectedDevices
//                                 .firstWhereOrNull((d) => d.advName.isNotEmpty)
//                             : null;

//                         final String buttonText = isConnected
//                             ? 'Connected: ${connectedDevice?.advName ?? connectedDevice?.remoteId.str}'
//                             : 'Scan Devices';

//                         return ButtonWidget(
//                           // Warna tombol berdasarkan status koneksi
//                           color: isConnected ? green00968A : Colors.blue,
//                           name: Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Icon(
//                                 Icons.bluetooth,
//                                 color: white,
//                               ),
//                               const SizedBox(width: 6),
//                               Text(
//                                 buttonText,
//                                 style: getWhiteTextStyle(),
//                                 overflow: TextOverflow.ellipsis,
//                               ),
//                             ],
//                           ),
//                           function: () async {},
//                         );
//                       },
//                     ),
//                     BlocListener<BluetoothOnOffCubit, BluetoothOnOffState>(
//                       listener: (context, onOffState) {
//                         if (onOffState is BluetoothOnState) {
//                           context
//                               .read<ConnectedDevicesCubit>()
//                               .fetchConnectedDevices();
//                         }
//                       },
//                       child: BlocConsumer<ConnectedDevicesCubit,
//                           ConnectedDevicesState>(
//                         listener: (context, state) {
//                           if (state is ConnectedDevicesLoadedState &&
//                               state.connectedDevices.isNotEmpty) {
//                             context
//                                 .read<DiscoverServicesCubit>()
//                                 .discoverServices(state.connectedDevices.first);
//                           }
//                         },
//                         builder: (context, state) {
//                           if (state is ConnectedDevicesLoadedState) {
//                             // return _buildConnectedDeviceUI(
//                             //     state.connectedDevices);
//                             if (state.connectedDevices.isNotEmpty) {
//                               BlocProvider.of<DiscoverServicesCubit>(
//                                 context,
//                               ).discoverServices(state.connectedDevices.first);
//                             }
//                             return BlocConsumer<DiscoverServicesCubit,
//                                 DiscoverServiceState>(
//                               listener: (context, discoverState) {
//                                 if (discoverState is ServicesLoadedState) {
//                                   final services = discoverState.services;
//                                   log('services pgd : $services');

//                                   if (!_listenerAdded) {
//                                     _listenerAdded = true;
//                                     for (BluetoothService service in services) {
//                                       for (BluetoothCharacteristic characteristic
//                                           in service.characteristics) {
//                                         if (characteristic.properties.notify) {
//                                           characteristic.onValueReceived
//                                               .listen((value) {
//                                             final notifInString =
//                                                 String.fromCharCodes(value);
//                                             log("angin bergejolak: $notifInString");

//                                             debugPrint(
//                                               "debugBluetoothNotification*************",
//                                             );
//                                             debugPrint(
//                                               "debugBluetoothNotification: charName: ${BluetoothUtils.getBluetoothChar(characteristic.characteristicUuid.str)}",
//                                             );

//                                             debugPrint(
//                                               "notifhohoho: stringNotif: $notifInString",
//                                             );
//                                             setState(() {
//                                               String press = '';

//                                               if (notifInString.contains('|')) {
//                                                 int floorPressure =
//                                                     double.parse(
//                                                   notifInString.split(
//                                                     '|',
//                                                   )[0],
//                                                 ).floor();

//                                                 // int floorTemperature =
//                                                 //     double.parse(
//                                                 //       notifInString.split(
//                                                 //         '|',
//                                                 //       )[1],
//                                                 //     ).floor();
//                                                 // temperature = floorTemperature
//                                                 //     .toString();
//                                                 applyPressureData(
//                                                     floorPressure.toString());
//                                               } else {
//                                                 int floorPressure =
//                                                     double.parse(
//                                                   notifInString,
//                                                 ).floor();
//                                                 press.toString();
//                                                 applyPressureData(
//                                                     floorPressure.toString());
//                                               }
//                                             });

//                                             debugPrint(
//                                               "debugBluetoothNotification*************",
//                                             );
//                                           });

//                                           characteristic
//                                               .setNotifyValue(true); // WAJIB
//                                         }
//                                       }
//                                     }
//                                   }
//                                 }
//                               },
//                               builder: (context, discoverState) {
//                                 if (discoverState is ErrorLoadingServiceState) {
//                                   return Center(child: Text('Error'));
//                                 }
//                                 return Container();
//                               },
//                             );
//                           }
//                           return CircularProgressIndicator();
//                         },
//                       ),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     ListView.builder(
//                         shrinkWrap: true,
//                         physics: NeverScrollableScrollPhysics(),
//                         itemCount: units.length,
//                         itemBuilder: (context, index) {
//                           final unit = units[index];
//                           if (snControllers[index].text.isEmpty) {
//                             snControllers[index].text = unit.sn ?? '';
//                           }

//                           return Card(
//                             elevation: 2,
//                             child: Container(
//                               width: MediaQuery.of(context).size.width,
//                               padding: EdgeInsets.all(24),
//                               child: Stack(
//                                 children: [
//                                   Opacity(
//                                     opacity: 0.1,
//                                     child: Center(
//                                       child: Text(
//                                         unit.rating ?? '',
//                                         style: TextStyle(
//                                           fontSize: 100,
//                                           fontWeight: FontWeight.bold,
//                                           color: Colors.black,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           SizedBox(
//                                             width: 35,
//                                             height: 53,
//                                             child: Image.asset(
//                                               '$imagePath/em_tire_image.png',
//                                               fit: BoxFit.cover,
//                                             ),
//                                           ),
//                                           Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.end,
//                                             children: [
//                                               Text(
//                                                 'Position',
//                                                 style: getBlackTextStyle(
//                                                     fontSize: 14),
//                                               ),
//                                               const SizedBox(
//                                                 height: 6,
//                                               ),
//                                               Text(
//                                                 '${index + 1}',
//                                                 style: getBlackTextStyle(
//                                                     fontSize: 22,
//                                                     fontWeight: w700),
//                                               ),
//                                             ],
//                                           )
//                                         ],
//                                       ),
//                                       Padding(
//                                         padding:
//                                             EdgeInsets.symmetric(vertical: 6),
//                                         child: Divider(
//                                           thickness: 1.5,
//                                         ),
//                                       ),
//                                       Column(
//                                         children: [
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Unit',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.unitNumber ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'SN',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.sn ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Brand',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.brand ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Tire Lifetime',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.lifetime ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'Rating',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 unit.rating ?? '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           Row(
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.spaceBetween,
//                                             children: [
//                                               Text(
//                                                 'RTD',
//                                                 style: getBlackTextStyle(
//                                                     fontWeight: w700),
//                                               ),
//                                               Text(
//                                                 '${unit.rtd} / ${unit.otd}' ??
//                                                     '',
//                                                 style: getBlackTextStyle(),
//                                               ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       Padding(
//                                         padding:
//                                             EdgeInsets.symmetric(vertical: 6),
//                                         child: Divider(
//                                           thickness: 1.5,
//                                         ),
//                                       ),
//                                       Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceBetween,
//                                         children: [
//                                           Expanded(
//                                             child: SizedBox(
//                                               width: MediaQuery.of(context)
//                                                   .size
//                                                   .width,
//                                               height: 45,
//                                               child: ElevatedButton(
//                                                 onPressed: () async {
//                                                   FocusScope.of(context)
//                                                       .unfocus();
//                                                   setState(() {
//                                                     // selectedPosIndex = posIndex;
//                                                   });
//                                                   showDialog(
//                                                     context: context,
//                                                     builder:
//                                                         (BuildContext context) {
//                                                       return Dialog(
//                                                         child: Container(
//                                                           padding:
//                                                               EdgeInsets.all(
//                                                                   20.0),
//                                                           child:
//                                                               SingleChildScrollView(
//                                                             child: Column(
//                                                               mainAxisSize:
//                                                                   MainAxisSize
//                                                                       .min,
//                                                               children: <Widget>[
//                                                                 Text(
//                                                                   'Choose Pressure',
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontSize:
//                                                                         24.0,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .bold,
//                                                                   ),
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         16.0),
//                                                                 Column(),
//                                                                 Wrap(
//                                                                   children:
//                                                                       pressure.map(
//                                                                           (ps) {
//                                                                     final psIndex =
//                                                                         pressure
//                                                                             .indexOf(ps);
//                                                                     return Padding(
//                                                                       padding: const EdgeInsets
//                                                                           .only(
//                                                                           right:
//                                                                               16,
//                                                                           bottom:
//                                                                               18),
//                                                                       child:
//                                                                           ElevatedButton(
//                                                                         style: ElevatedButton.styleFrom(
//                                                                             backgroundColor:
//                                                                                 Colors.green),
//                                                                         onPressed:
//                                                                             () {
//                                                                           final id =
//                                                                               Uuid();
//                                                                           setState(
//                                                                               () {
//                                                                             position[index]['pressure'] =
//                                                                                 ps;
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child:
//                                                                             Text(
//                                                                           ps,
//                                                                           style:
//                                                                               getWhiteTextStyle(
//                                                                             fontWeight:
//                                                                                 w700,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                     );
//                                                                   }).toList(),
//                                                                 ),
//                                                                 Row(
//                                                                   children: [
//                                                                     Expanded(
//                                                                       child:
//                                                                           SizedBox(
//                                                                         width: double
//                                                                             .infinity,
//                                                                         child: InputFormWidget(
//                                                                             controller:
//                                                                                 pressureCtrl,
//                                                                             isDigitOnly:
//                                                                                 true,
//                                                                             type:
//                                                                                 TextInputType.number,
//                                                                             hint: 'Input Manual'),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       width: 6,
//                                                                     ),
//                                                                     ElevatedButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           setState(
//                                                                               () {
//                                                                             if (pressureCtrl.text !=
//                                                                                 '') {
//                                                                               position[index]['pressure'] = pressureCtrl.text;
//                                                                             }
//                                                                             pressureCtrl.clear();
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child: Text(
//                                                                             'Submit'))
//                                                                   ],
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         12.0),
//                                                                 SizedBox(
//                                                                   width: double
//                                                                       .infinity,
//                                                                   child:
//                                                                       ElevatedButton(
//                                                                     onPressed:
//                                                                         () {
//                                                                       pressureCtrl
//                                                                           .clear();
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop();
//                                                                     },
//                                                                     child: Text(
//                                                                         'Close'),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       );
//                                                     },
//                                                   );
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.blue,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               12),
//                                                     )),
//                                                 child: (position[index]
//                                                                 ['pressure'] ==
//                                                             '' ||
//                                                         (position[index]
//                                                                 ['pressure'] ==
//                                                             null))
//                                                     ? Row(
//                                                         mainAxisSize:
//                                                             MainAxisSize.min,
//                                                         children: [
//                                                           Icon(
//                                                             Icons.add,
//                                                             color: white,
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 6,
//                                                           ),
//                                                           Text(
//                                                             'Pressure',
//                                                             style:
//                                                                 getWhiteTextStyle(),
//                                                           )
//                                                         ],
//                                                       )
//                                                     : Text(
//                                                         '${position[index]['pressure']} Psi',
//                                                         style:
//                                                             getWhiteTextStyle(
//                                                           fontSize: 24,
//                                                           fontWeight: w700,
//                                                         ),
//                                                       ),
//                                               ),
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                           // adjusment pressure
//                                           Expanded(
//                                             child: SizedBox(
//                                               width: MediaQuery.of(context)
//                                                   .size
//                                                   .width,
//                                               height: 45,
//                                               child: ElevatedButton(
//                                                 onPressed: () async {
//                                                   FocusScope.of(context)
//                                                       .unfocus();
//                                                   setState(() {
//                                                     // selectedPosIndex = posIndex;
//                                                   });
//                                                   showDialog(
//                                                     context: context,
//                                                     builder:
//                                                         (BuildContext context) {
//                                                       return Dialog(
//                                                         child: Container(
//                                                           padding:
//                                                               EdgeInsets.all(
//                                                                   20.0),
//                                                           child:
//                                                               SingleChildScrollView(
//                                                             child: Column(
//                                                               mainAxisSize:
//                                                                   MainAxisSize
//                                                                       .min,
//                                                               children: <Widget>[
//                                                                 Text(
//                                                                   'Choose Pressure',
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontSize:
//                                                                         24.0,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .bold,
//                                                                   ),
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         16.0),
//                                                                 Column(),
//                                                                 Wrap(
//                                                                   children:
//                                                                       pressure.map(
//                                                                           (ps) {
//                                                                     final psIndex =
//                                                                         pressure
//                                                                             .indexOf(ps);
//                                                                     return Padding(
//                                                                       padding: const EdgeInsets
//                                                                           .only(
//                                                                           right:
//                                                                               16,
//                                                                           bottom:
//                                                                               18),
//                                                                       child:
//                                                                           ElevatedButton(
//                                                                         style: ElevatedButton.styleFrom(
//                                                                             backgroundColor:
//                                                                                 Colors.green),
//                                                                         onPressed:
//                                                                             () {
//                                                                           setState(
//                                                                               () {
//                                                                             position[index]['adjusmentPressure'] =
//                                                                                 ps;
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child:
//                                                                             Text(
//                                                                           ps,
//                                                                           style:
//                                                                               getWhiteTextStyle(
//                                                                             fontWeight:
//                                                                                 w700,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                     );
//                                                                   }).toList(),
//                                                                 ),
//                                                                 Row(
//                                                                   children: [
//                                                                     Expanded(
//                                                                       child:
//                                                                           SizedBox(
//                                                                         width: double
//                                                                             .infinity,
//                                                                         child: InputFormWidget(
//                                                                             controller:
//                                                                                 pressureCtrl,
//                                                                             isDigitOnly:
//                                                                                 true,
//                                                                             type:
//                                                                                 TextInputType.number,
//                                                                             hint: 'Input Manual'),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                       width: 6,
//                                                                     ),
//                                                                     ElevatedButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           setState(
//                                                                               () {
//                                                                             if (pressureCtrl.text !=
//                                                                                 '') {
//                                                                               position[index]['adjusmentPressure'] = pressureCtrl.text;
//                                                                             }
//                                                                             pressureCtrl.clear();
//                                                                             Navigator.of(context).pop();
//                                                                           });
//                                                                         },
//                                                                         child: const Text(
//                                                                             'Submit'))
//                                                                   ],
//                                                                 ),
//                                                                 SizedBox(
//                                                                     height:
//                                                                         12.0),
//                                                                 SizedBox(
//                                                                   width: double
//                                                                       .infinity,
//                                                                   child:
//                                                                       ElevatedButton(
//                                                                     onPressed:
//                                                                         () {
//                                                                       pressureCtrl
//                                                                           .clear();
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop();
//                                                                     },
//                                                                     child: Text(
//                                                                         'Close'),
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       );
//                                                     },
//                                                   );
//                                                 },
//                                                 style: ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.blue,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               12),
//                                                     )),
//                                                 child: (position[index][
//                                                             'adjusmentPressure'] ==
//                                                         '')
//                                                     ? Text(
//                                                         'Adj Pressure',
//                                                         style:
//                                                             getWhiteTextStyle(),
//                                                       )
//                                                     : Text(
//                                                         '${position[index]['adjusmentPressure']} Psi (Adj)',
//                                                         style:
//                                                             getWhiteTextStyle(
//                                                           fontSize: 16,
//                                                           fontWeight: w700,
//                                                         ),
//                                                       ),
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),

//                                       const SizedBox(
//                                         height: 12,
//                                       ),

//                                       SizedBox(
//                                         width:
//                                             MediaQuery.of(context).size.width,
//                                         height: 45,
//                                         child: ElevatedButton(
//                                           onPressed: () async {
//                                             FocusScope.of(context).unfocus();
//                                             // setState(() {
//                                             //   selectedPosIndex = posIndex;
//                                             // });

//                                             showDialog(
//                                               context: context,
//                                               builder: (BuildContext context) {
//                                                 return Dialog(
//                                                   child: Container(
//                                                     padding:
//                                                         EdgeInsets.all(20.0),
//                                                     child:
//                                                         SingleChildScrollView(
//                                                       child: Column(
//                                                         mainAxisSize:
//                                                             MainAxisSize.min,
//                                                         children: <Widget>[
//                                                           Text(
//                                                             'Choose Rating',
//                                                             style: TextStyle(
//                                                               fontSize: 24.0,
//                                                               fontWeight:
//                                                                   FontWeight
//                                                                       .bold,
//                                                             ),
//                                                           ),
//                                                           SizedBox(
//                                                               height: 16.0),
//                                                           Column(),
//                                                           Wrap(
//                                                             children: rating
//                                                                 .map((rat) {
//                                                               final ratingIndex =
//                                                                   rating
//                                                                       .indexOf(
//                                                                           rat);
//                                                               return Padding(
//                                                                 padding:
//                                                                     const EdgeInsets
//                                                                         .only(
//                                                                         right:
//                                                                             16,
//                                                                         bottom:
//                                                                             18),
//                                                                 child:
//                                                                     ElevatedButton(
//                                                                   style: ElevatedButton.styleFrom(
//                                                                       backgroundColor:
//                                                                           Colors
//                                                                               .green),
//                                                                   onPressed:
//                                                                       () {
//                                                                     setState(
//                                                                         () {
//                                                                       position[index]
//                                                                               [
//                                                                               'rating'] =
//                                                                           rat;
//                                                                       Navigator.of(
//                                                                               context)
//                                                                           .pop();
//                                                                     });
//                                                                   },
//                                                                   child: Text(
//                                                                     rat,
//                                                                     style:
//                                                                         getWhiteTextStyle(
//                                                                       fontWeight:
//                                                                           w700,
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                               );
//                                                             }).toList(),
//                                                           ),
//                                                           SizedBox(
//                                                               height: 12.0),
//                                                           SizedBox(
//                                                             width:
//                                                                 double.infinity,
//                                                             child:
//                                                                 ElevatedButton(
//                                                               onPressed: () {
//                                                                 pressureCtrl
//                                                                     .clear();
//                                                                 Navigator.of(
//                                                                         context)
//                                                                     .pop();
//                                                               },
//                                                               child:
//                                                                   Text('Close'),
//                                                             ),
//                                                           ),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 );
//                                               },
//                                             );
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                               backgroundColor: Colors.blue,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               )),
//                                           child: (position[index]['rating'] ==
//                                                   '')
//                                               ? Builder(builder: (context) {
//                                                   position[index]['rating'] =
//                                                       'A';
//                                                   return Text(
//                                                     'Rating A',
//                                                     style: getWhiteTextStyle(),
//                                                   );
//                                                 })
//                                               : Text(
//                                                   'Rating ${position[index]['rating']}',
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 16,
//                                                     fontWeight: w700,
//                                                   ),
//                                                 ),
//                                         ),
//                                       ),

//                                       const SizedBox(
//                                         height: 12,
//                                       ),

//                                       Container(
//                                         padding: const EdgeInsets.symmetric(
//                                             horizontal: 8, vertical: 4),
//                                         decoration: BoxDecoration(
//                                           color: blue344BEF,
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                         child: Text(
//                                           'Tire Damage',
//                                           textAlign: TextAlign.start,
//                                           style: getBlackTextStyle(
//                                             fontSize: 12,
//                                           ).copyWith(color: Colors.white),
//                                         ),
//                                       ),

//                                       SizedBox(
//                                         width:
//                                             MediaQuery.of(context).size.width,
//                                         child: ElevatedButton(
//                                           onPressed: () {
//                                             if (index == 0)
//                                               log('luka map : ${position[index]['damageTire']}');
//                                             FocusScope.of(context).unfocus();

//                                             if (loadingDamages) {
//                                               // Optional: kasih feedback kalau masih loading
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 const SnackBar(
//                                                     content: Text(
//                                                         'Sedang memuat daftar damage...')),
//                                               );
//                                               return;
//                                             }

//                                             if (damageType.isEmpty) {
//                                               ScaffoldMessenger.of(context)
//                                                   .showSnackBar(
//                                                 const SnackBar(
//                                                     content: Text(
//                                                         'Daftar damage kosong')),
//                                               );
//                                               return;
//                                             }

//                                             final List<dynamic>
//                                                 existingDamages =
//                                                 position[index]['damageTire'] ??
//                                                     [];

//                                             List<bool> checkedDamageValues;

//                                             if (existingDamages.isEmpty ||
//                                                 existingDamages[0] == "") {
//                                               print(
//                                                   'exisitng damage empty true');
//                                               // otomatis centang Good Condition jika belum ada damage
//                                               checkedDamageValues =
//                                                   damageType.map((damage) {
//                                                 final text = damage['remark']
//                                                     .toString()
//                                                     .toLowerCase()
//                                                     .trim();
//                                                 return text == 'good' ||
//                                                     text == 'good condition';
//                                               }).toList();
//                                             } else {
//                                               print(
//                                                   'exisitng damage empty false');
//                                               // jika sudah ada data damage
//                                               checkedDamageValues =
//                                                   damageType.map((damage) {
//                                                 return existingDamages
//                                                     .contains(damage['remark']);
//                                               }).toList();
//                                             }

//                                             showDialog(
//                                               context: context,
//                                               builder: (BuildContext context) {
//                                                 return Dialog(
//                                                   child: Container(
//                                                     padding:
//                                                         const EdgeInsets.all(
//                                                             20.0),
//                                                     child: Column(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: <Widget>[
//                                                         const Text(
//                                                           'Choose Damage Tire',
//                                                           style: TextStyle(
//                                                             fontSize: 24.0,
//                                                             fontWeight:
//                                                                 FontWeight.bold,
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                             height: 12.0),
//                                                         Expanded(
//                                                           child:
//                                                               SingleChildScrollView(
//                                                             child: Column(
//                                                               children:
//                                                                   damageType.map(
//                                                                       (damage) {
//                                                                 final dmgIndex =
//                                                                     damageType
//                                                                         .indexOf(
//                                                                             damage);

//                                                                 // kalau tidak perlu skip index 0, hapus if ini
//                                                                 // if (dmgIndex == 0) return Container();

//                                                                 return StatefulBuilder(
//                                                                   builder: (context,
//                                                                       setState) {
//                                                                     return CheckboxListTile(
//                                                                       title: Text(
//                                                                           damage[
//                                                                               'remark']),
//                                                                       value: checkedDamageValues[
//                                                                           dmgIndex],
//                                                                       onChanged:
//                                                                           (bool?
//                                                                               value) {
//                                                                         setState(
//                                                                             () {
//                                                                           bool
//                                                                               newValue =
//                                                                               value ?? false;

//                                                                           if (dmgIndex ==
//                                                                               0) {
//                                                                             // GOOD CONDITION dicentang
//                                                                             checkedDamageValues =
//                                                                                 List<bool>.filled(checkedDamageValues.length, false);
//                                                                             checkedDamageValues[0] =
//                                                                                 newValue;
//                                                                           } else {
//                                                                             // Damage lain dicentang
//                                                                             checkedDamageValues[dmgIndex] =
//                                                                                 newValue;

//                                                                             if (newValue) {
//                                                                               // otomatis uncheck Good Condition
//                                                                               checkedDamageValues[0] = false;
//                                                                             }
//                                                                           }
//                                                                         });
//                                                                       },
//                                                                     );
//                                                                   },
//                                                                 );
//                                                               }).toList(),
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                             height: 12.0),
//                                                         Column(
//                                                           children: [
//                                                             const SizedBox(
//                                                                 height: 12),
//                                                             SizedBox(
//                                                               width: double
//                                                                   .infinity,
//                                                               child:
//                                                                   ElevatedButton(
//                                                                 onPressed: () {
//                                                                   damageCtrl
//                                                                       .clear();
//                                                                   Navigator.pop(
//                                                                       context);
//                                                                 },
//                                                                 child:
//                                                                     const Text(
//                                                                         'Close'),
//                                                               ),
//                                                             ),
//                                                             const SizedBox(
//                                                                 height: 12),
//                                                             SizedBox(
//                                                               width: double
//                                                                   .infinity,
//                                                               child:
//                                                                   ElevatedButton(
//                                                                 style: ElevatedButton
//                                                                     .styleFrom(
//                                                                   backgroundColor:
//                                                                       Colors
//                                                                           .green,
//                                                                 ),
//                                                                 onPressed: () {
//                                                                   setState(
//                                                                       () {}); // setState parent

//                                                                   selectedDamage
//                                                                       .clear();

//                                                                   Map<String,
//                                                                           int>
//                                                                       ratingPriority =
//                                                                       {
//                                                                     '': 1,
//                                                                     'A': 1,
//                                                                     'B': 2,
//                                                                     'C': 3,
//                                                                     'X': 4,
//                                                                   };

//                                                                   final List<
//                                                                           Map<String,
//                                                                               dynamic>>
//                                                                       tmp = [];

//                                                                   // NOTE: ini tadinya if (== '' || isNotEmpty) -> selalu true.
//                                                                   if (damageCtrl
//                                                                       .text
//                                                                       .isNotEmpty) {
//                                                                     tmp.add({
//                                                                       'remark':
//                                                                           damageCtrl
//                                                                               .text,
//                                                                       'rating':
//                                                                           ''
//                                                                     });
//                                                                   }

//                                                                   for (int i =
//                                                                           0;
//                                                                       i <
//                                                                           checkedDamageValues
//                                                                               .length;
//                                                                       i++) {
//                                                                     if (checkedDamageValues[
//                                                                         i]) {
//                                                                       tmp.add(
//                                                                           damageType[
//                                                                               i]);
//                                                                     }
//                                                                   }

//                                                                   final onlyRemark = tmp
//                                                                       .map<String>((item) =>
//                                                                           item['remark']
//                                                                               ?.toString() ??
//                                                                           '')
//                                                                       .where((remark) =>
//                                                                           remark
//                                                                               .isNotEmpty)
//                                                                       .toList();

//                                                                   position[index]
//                                                                           [
//                                                                           'damageTire'] =
//                                                                       onlyRemark;

//                                                                   if (tmp
//                                                                       .isNotEmpty) {
//                                                                     position[index]
//                                                                             [
//                                                                             'damageTire'] =
//                                                                         onlyRemark;

//                                                                     // rating based damage
//                                                                     String
//                                                                         worstRating =
//                                                                         '';
//                                                                     worstRating =
//                                                                         tmp.fold(
//                                                                       '',
//                                                                       (worst,
//                                                                           item) {
//                                                                         final current =
//                                                                             item['rating'] ??
//                                                                                 '';

//                                                                         return ratingPriority[current]! >
//                                                                                 ratingPriority[worst]!
//                                                                             ? current
//                                                                             : worst;
//                                                                       },
//                                                                     );

//                                                                     position[index]
//                                                                             [
//                                                                             'rating'] =
//                                                                         worstRating;

//                                                                     selectedDamage
//                                                                         .addAll(
//                                                                             onlyRemark);

//                                                                     log('hasil luka ban : $position');
//                                                                   }

//                                                                   damageCtrl
//                                                                       .clear();
//                                                                   Navigator.pop(
//                                                                       context);
//                                                                 },
//                                                                 child: Text(
//                                                                   'Submit',
//                                                                   style:
//                                                                       getWhiteTextStyle(
//                                                                     fontWeight:
//                                                                         w700,
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                           ],
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 );
//                                               },
//                                             );
//                                           },
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: blue344BEF,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                           child: Padding(
//                                             padding: const EdgeInsets.symmetric(
//                                                 vertical: 8.0),
//                                             child: Text(
//                                               ((position[index]['damageTire'] ==
//                                                           null) ||
//                                                       (position[index]
//                                                                   ['damageTire']
//                                                               as List)
//                                                           .where((e) =>
//                                                               e != null &&
//                                                               e
//                                                                   .toString()
//                                                                   .trim()
//                                                                   .isNotEmpty)
//                                                           .isEmpty)
//                                                   ? 'Good Condition'
//                                                   : (position[index]
//                                                               ['damageTire']
//                                                           as List)
//                                                       .join('\n---\n'),
//                                               textAlign: TextAlign.center,
//                                               style: getWhiteTextStyle(
//                                                   fontSize: 14),
//                                             ),
//                                           ),
//                                         ),
//                                       ),

//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 45,
//                                         child: ElevatedButton(
//                                           style: ElevatedButton.styleFrom(
//                                             backgroundColor: Colors.orange,
//                                             shape: RoundedRectangleBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                           ),
//                                           onPressed: () {
//                                             showRimInspectionDialog(index);
//                                           },
//                                           child: Text(
//                                             'Check Tire Component Condition',
//                                             style: getWhiteTextStyle(
//                                                 fontWeight: w700),
//                                           ),
//                                         ),
//                                       ),
//                                       const SizedBox(
//                                         height: 16,
//                                       ),
//                                       SizedBox(
//                                         width: double.infinity,
//                                         height: 45,
//                                         child: ElevatedButton(
//                                             style: ElevatedButton.styleFrom(
//                                                 backgroundColor: Colors.green,
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                 )),
//                                             onPressed: () async {
//                                               final ImagePicker picker =
//                                                   ImagePicker();

//                                               final ImageSource? source =
//                                                   await showDialog<ImageSource>(
//                                                 context: context,
//                                                 builder: (context) {
//                                                   return AlertDialog(
//                                                     title: Text(
//                                                         "Pilih Sumber Gambar"),
//                                                     content: Column(
//                                                       mainAxisSize:
//                                                           MainAxisSize.min,
//                                                       children: [
//                                                         ListTile(
//                                                           leading: Icon(
//                                                               Icons.camera_alt),
//                                                           title: Text("Kamera"),
//                                                           onTap: () =>
//                                                               Navigator.pop(
//                                                                   context,
//                                                                   ImageSource
//                                                                       .camera),
//                                                         ),
//                                                         ListTile(
//                                                           leading: Icon(Icons
//                                                               .photo_library),
//                                                           title:
//                                                               Text("Gallery"),
//                                                           onTap: () =>
//                                                               Navigator.pop(
//                                                                   context,
//                                                                   ImageSource
//                                                                       .gallery),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   );
//                                                 },
//                                               );

//                                               // final XFile? image =
//                                               //     await picker.pickImage(
//                                               //         imageQuality: 50,
//                                               //         source:
//                                               //             // ImageSource.camera);
//                                               //             ImageSource.gallery);

//                                               if (source == null) return;

//                                               if (source ==
//                                                   ImageSource.camera) {
//                                                 requestCameraPermission();
//                                               }

//                                               final XFile? image =
//                                                   await picker.pickImage(
//                                                 source: source,
//                                                 imageQuality: 50,
//                                               );

//                                               try {
//                                                 if (image != null) {
//                                                   Directory? directory;

//                                                   if (Platform.isAndroid) {
//                                                     // path = await getExternalStorageDirectory();
//                                                     directory =
//                                                         await DownloadsPath
//                                                             .downloadsDirectory();
//                                                   }

//                                                   if (Platform.isIOS) {
//                                                     // final directory = await getApplicationDocumentsDirectory();
//                                                     // path = directory;
//                                                     directory =
//                                                         await getApplicationDocumentsDirectory();
//                                                   }

//                                                   // Read image as a file
//                                                   File imageFile =
//                                                       File(image.path);
//                                                   // data size fotonya
//                                                   final compressedFilePath =
//                                                       '${directory?.path}/${DateTime.now().millisecondsSinceEpoch}_tireinspectionimage_compressed.jpg';

//                                                   // Compress the image if needed (optional)
//                                                   final compressedImageFile =
//                                                       await FlutterImageCompress
//                                                           .compressAndGetFile(
//                                                     imageFile.path,
//                                                     compressedFilePath,
//                                                     quality: 50,
//                                                   );
//                                                   log('gambar : ${compressedFilePath}');

//                                                   if (compressedImageFile ==
//                                                       null) {
//                                                     throw Exception(
//                                                       'Failed to compress image.',
//                                                     );
//                                                   }

//                                                   // Simpan foto saja. Analisa AI dijalankan manual
//                                                   // melalui tombol Analyze Damage with AI.
//                                                   setState(() {
//                                                     position[index]['image'] = [
//                                                       '${compressedImageFile.path}|${position[index]['position']}'
//                                                     ];

//                                                     // Hapus hasil AI dari foto sebelumnya.
//                                                     aiResults.remove(index);
//                                                     imageWidths.remove(index);
//                                                     imageHeights.remove(index);
//                                                     loadingAI[index] = false;
//                                                   });

//                                                   log('tire inspection image = ${position[index]['image']}');
//                                                 }
//                                               } catch (e) {
//                                                 log('error gambar string : $e');
//                                               }

//                                               setState(() {});
//                                             },
//                                             child: Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment.center,
//                                               children: [
//                                                 Icon(
//                                                   Icons.camera_alt,
//                                                   color: white,
//                                                 ),
//                                                 const SizedBox(
//                                                   width: 12,
//                                                 ),
//                                                 Text(
//                                                   'Take Picture',
//                                                   style: getWhiteTextStyle(),
//                                                 ),
//                                               ],
//                                             )),
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       Text(
//                                         '*You can only take one picture. If you take another picture, the previous one will be deleted.',
//                                         style: getRedTextStyle(),
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       ((position[index]['image']
//                                                   as List<dynamic>)
//                                               .isNotEmpty)
//                                           ? Column(
//                                               children: [
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   height: 45,
//                                                   child: ElevatedButton(
//                                                       style: ElevatedButton
//                                                           .styleFrom(
//                                                               backgroundColor:
//                                                                   Colors
//                                                                       .deepOrange,
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             12),
//                                                               )),
//                                                       onPressed: () async {
//                                                         showDialog(
//                                                             context: context,
//                                                             builder: (context) {
//                                                               return AlertDialog(
//                                                                 content: Text(
//                                                                   'Are you sure you want to delete this image?',
//                                                                   style:
//                                                                       getBlackTextStyle(),
//                                                                 ),
//                                                                 actions: [
//                                                                   TextButton(
//                                                                       onPressed:
//                                                                           () {
//                                                                         Navigator.pop(
//                                                                             context);
//                                                                       },
//                                                                       child:
//                                                                           Text(
//                                                                         'Cancel',
//                                                                         style: getGreyTextStyle(
//                                                                             grey8391A1),
//                                                                       )),
//                                                                   TextButton(
//                                                                       onPressed:
//                                                                           () {
//                                                                         setState(
//                                                                             () {
//                                                                           position[index]['image'] =
//                                                                               [];
//                                                                           aiResults
//                                                                               .remove(index);
//                                                                           loadingAI
//                                                                               .remove(index);
//                                                                           imageWidths
//                                                                               .remove(index);
//                                                                           imageHeights
//                                                                               .remove(index);
//                                                                         });
//                                                                         Navigator.pop(
//                                                                             context);
//                                                                       },
//                                                                       child:
//                                                                           Text(
//                                                                         'Yes',
//                                                                         style:
//                                                                             getRedTextStyle(),
//                                                                       )),
//                                                                 ],
//                                                               );
//                                                             });

//                                                         setState(() {});
//                                                       },
//                                                       child: Row(
//                                                         mainAxisAlignment:
//                                                             MainAxisAlignment
//                                                                 .center,
//                                                         children: [
//                                                           Icon(
//                                                             Icons.delete,
//                                                             color: white,
//                                                           ),
//                                                           const SizedBox(
//                                                             width: 12,
//                                                           ),
//                                                           Text(
//                                                             'Delete Picture',
//                                                             style:
//                                                                 getWhiteTextStyle(),
//                                                           ),
//                                                         ],
//                                                       )),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 (loadingAI[index] == true)
//                                                     ? Center(
//                                                         child:
//                                                             AiLoadingWidget(),
//                                                       )
//                                                     : Stack(
//                                                         children: [
//                                                           Container(
//                                                             width:
//                                                                 double.infinity,
//                                                             decoration:
//                                                                 BoxDecoration(
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           12),
//                                                             ),
//                                                             child: Image.file(
//                                                               File(
//                                                                 (position[index]
//                                                                             [
//                                                                             'image'][0]
//                                                                         as String)
//                                                                     .split(
//                                                                         '|')[0],
//                                                               ),
//                                                               fit: BoxFit
//                                                                   .contain,
//                                                             ),
//                                                           ),
//                                                           if (aiResults[
//                                                                   index] !=
//                                                               null)
//                                                             Positioned.fill(
//                                                               child:
//                                                                   CustomPaint(
//                                                                 painter:
//                                                                     BoundingBoxPainter(
//                                                                   detections: aiResults[
//                                                                               index]
//                                                                           ?.data
//                                                                           ?.tireDamageResult ??
//                                                                       [],
//                                                                   imageWidth:
//                                                                       imageWidths[
//                                                                               index] ??
//                                                                           1,
//                                                                   imageHeight:
//                                                                       imageHeights[
//                                                                               index] ??
//                                                                           1,
//                                                                 ),
//                                                               ),
//                                                             ),
//                                                         ],
//                                                       ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   height: 45,
//                                                   child: ElevatedButton(
//                                                     style: ElevatedButton
//                                                         .styleFrom(
//                                                       backgroundColor:
//                                                           Colors.purple,
//                                                       shape:
//                                                           RoundedRectangleBorder(
//                                                         borderRadius:
//                                                             BorderRadius
//                                                                 .circular(12),
//                                                       ),
//                                                     ),
//                                                     onPressed:
//                                                         loadingAI[index] == true
//                                                             ? null
//                                                             : () async {
//                                                                 await _analyzeDamageWithAI(
//                                                                   index,
//                                                                 );
//                                                               },
//                                                     child: Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .center,
//                                                       children: [
//                                                         const Icon(
//                                                           Icons.auto_awesome,
//                                                           color: white,
//                                                         ),
//                                                         const SizedBox(
//                                                           width: 12,
//                                                         ),
//                                                         Text(
//                                                           aiResults[index] ==
//                                                                   null
//                                                               ? 'Analyze Damage with AI'
//                                                               : 'Analyze Again with AI',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontWeight: w700,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                               ],
//                                             )
//                                           : Container(),

//                                       // Show More Images
//                                       // (listImg.isNotEmpty)
//                                       //     ? Column(
//                                       //         children: [
//                                       //           SizedBox(
//                                       //             width: double.infinity,
//                                       //             height: 45,
//                                       //             child: ElevatedButton(
//                                       //                 style: ElevatedButton
//                                       //                     .styleFrom(
//                                       //                         backgroundColor:
//                                       //                             Colors
//                                       //                                 .orange,
//                                       //                         shape:
//                                       //                             RoundedRectangleBorder(
//                                       //                           borderRadius:
//                                       //                               BorderRadius.circular(
//                                       //                                   12),
//                                       //                         )),
//                                       //                 onPressed: () async {
//                                       //                   final CarouselController
//                                       //                       _controller =
//                                       //                       CarouselController();

//                                       //                   showDialog(
//                                       //                       context:
//                                       //                           context,
//                                       //                       builder:
//                                       //                           (BuildContext
//                                       //                               context) {
//                                       //                         return AlertDialog(
//                                       //                           content:
//                                       //                               Padding(
//                                       //                             padding: const EdgeInsets
//                                       //                                 .all(
//                                       //                                 24.0),
//                                       //                             child:
//                                       //                                 Column(
//                                       //                               mainAxisSize:
//                                       //                                   MainAxisSize.min,
//                                       //                               children: [
//                                       //                                 Text(
//                                       //                                   'Show Image',
//                                       //                                   style:
//                                       //                                       getBlackTextStyle(),
//                                       //                                 ),
//                                       //                                 const SizedBox(
//                                       //                                   height:
//                                       //                                       12,
//                                       //                                 ),
//                                       //                                 Container(
//                                       //                                   width:
//                                       //                                       400,
//                                       //                                   height:
//                                       //                                       400,
//                                       //                                   child:
//                                       //                                       CarouselSlider(
//                                       //                                     carouselController: _controller,
//                                       //                                     // items: listImg.map((img) {
//                                       //                                     //   final splitImg = img.split('|');

//                                       //                                     //   if ((position[index]['position']).toString() == splitImg[1]) {
//                                       //                                     //     return Image.file(File(splitImg[0]));
//                                       //                                     //   }
//                                       //                                     //   return Container();
//                                       //                                     // }).toList(),
//                                       //                                     items: listImg
//                                       //                                         .where((img) {
//                                       //                                           final splitImg = img.split('|');
//                                       //                                           return splitImg[1] == (position[index]['position']).toString();
//                                       //                                         })
//                                       //                                         .toList()
//                                       //                                         .map((img2) {
//                                       //                                           final splitImg2 = img2.split('|');
//                                       //                                           return Image.file(File(splitImg2[0]));
//                                       //                                         })
//                                       //                                         .toList(),
//                                       //                                     options: CarouselOptions(
//                                       //                                       aspectRatio: 3.0,
//                                       //                                       height: 400,
//                                       //                                       enableInfiniteScroll: false,
//                                       //                                       enlargeCenterPage: true,
//                                       //                                     ),
//                                       //                                   ),
//                                       //                                 ),
//                                       //                               ],
//                                       //                             ),
//                                       //                           ),
//                                       //                         );
//                                       //                       });
//                                       //                   setState(() {});
//                                       //                 },
//                                       //                 child: Row(
//                                       //                   mainAxisAlignment:
//                                       //                       MainAxisAlignment
//                                       //                           .center,
//                                       //                   children: [
//                                       //                     Icon(
//                                       //                       Icons.image,
//                                       //                       color: white,
//                                       //                     ),
//                                       //                     const SizedBox(
//                                       //                       width: 12,
//                                       //                     ),
//                                       //                     Text(
//                                       //                       'Show Image',
//                                       //                       style:
//                                       //                           getWhiteTextStyle(),
//                                       //                     ),
//                                       //                   ],
//                                       //                 )),
//                                       //           ),
//                                       //           const SizedBox(
//                                       //             height: 12,
//                                       //           ),
//                                       //         ],
//                                       //       )
//                                       //     : Container(),

//                                       Row(
//                                         children: [
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.stretch,
//                                               children: [
//                                                 Text(
//                                                   'RTD 1',
//                                                   style: getBlackTextStyle(
//                                                       fontWeight: w700),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   child: InputFormWidget(
//                                                     onChng: (value) {
//                                                       position[index]['rtd1'] =
//                                                           value;
//                                                     },
//                                                     controller:
//                                                         rtd1Controllers[index],
//                                                     hint: '',
//                                                   ),
//                                                 ),
//                                                 // Builder(builder: (context) {
//                                                 //   rtd1Controllers[index].text =
//                                                 //       unit.rtd ?? '';
//                                                 //   position[index]['rtd1'] =
//                                                 //       unit.rtd;
//                                                 //   return SizedBox(
//                                                 //     width: double.infinity,
//                                                 //     child: InputFormWidget(
//                                                 //         onChng: (value) {
//                                                 //           position[index]
//                                                 //               ['rtd1'] = value;
//                                                 //         },
//                                                 //         controller:
//                                                 //             rtd1Controllers[
//                                                 //                 index],
//                                                 //         hint: ''),
//                                                 //   );
//                                                 // }),
//                                               ],
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                           Expanded(
//                                             child: Column(
//                                               crossAxisAlignment:
//                                                   CrossAxisAlignment.stretch,
//                                               children: [
//                                                 Text(
//                                                   'RTD 2',
//                                                   style: getBlackTextStyle(
//                                                       fontWeight: w700),
//                                                 ),
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   child: InputFormWidget(
//                                                     onChng: (value) {
//                                                       position[index]['rtd2'] =
//                                                           value;
//                                                     },
//                                                     controller:
//                                                         rtd2Controllers[index],
//                                                     hint: '',
//                                                   ),
//                                                 ),
//                                                 // Builder(builder: (context) {
//                                                 //   rtd2Controllers[index].text =
//                                                 //       unit.otd ?? '';
//                                                 //   position[index]['rtd2'] =
//                                                 //       unit.otd;
//                                                 //   return SizedBox(
//                                                 //     width: double.infinity,
//                                                 //     child: InputFormWidget(
//                                                 //         onChng: (value) {
//                                                 //           position[index]
//                                                 //               ['rtd2'] = value;
//                                                 //         },
//                                                 //         controller:
//                                                 //             rtd2Controllers[
//                                                 //                 index],
//                                                 //         hint: ''),
//                                                 //   );
//                                                 // }),
//                                               ],
//                                             ),
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.stretch,
//                                         children: [
//                                           Text(
//                                             'Serial Number',
//                                             style: getBlackTextStyle(
//                                                 fontWeight: w700),
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           SizedBox(
//                                             width: double.infinity,
//                                             child: InputFormWidget(
//                                                 onChng: (value) {
//                                                   position[index]['sn'] = value;
//                                                 },
//                                                 controller:
//                                                     snControllers[index],
//                                                 hint: ''),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(
//                                         height: 12,
//                                       ),
//                                       Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.stretch,
//                                         children: [
//                                           Text(
//                                             'Remarks',
//                                             style: getBlackTextStyle(
//                                                 fontWeight: w700),
//                                           ),
//                                           const SizedBox(
//                                             height: 12,
//                                           ),
//                                           SizedBox(
//                                             width: double.infinity,
//                                             child: InputFormWidget(
//                                                 onChng: (value) {
//                                                   position[index]['remarks'] =
//                                                       value;
//                                                 },
//                                                 controller:
//                                                     remarksControllers[index],
//                                                 hint: ''),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(
//                                         height: 24,
//                                       ),
//                                       SizedBox(height: 12),

//                                       // SizedBox(
//                                       //   // height: 160,
//                                       //   child: GridView.builder(
//                                       //       physics:
//                                       //           NeverScrollableScrollPhysics(),
//                                       //       shrinkWrap: true,
//                                       //       itemCount: position[index]
//                                       //               ['condition']
//                                       //           .length,
//                                       //       gridDelegate:
//                                       //           SliverGridDelegateWithFixedCrossAxisCount(
//                                       //               crossAxisCount: 2,
//                                       //               childAspectRatio: 3),
//                                       //       itemBuilder:
//                                       //           (context, indexBroken) {
//                                       //         final broken = position[index]
//                                       //             ['condition'][indexBroken];
//                                       //         return InkWell(
//                                       //           onTap: () {
//                                       //             setState(() {
//                                       //               // checkedListCategory[
//                                       //               //         index] =
//                                       //               //     !checkedListCategory[
//                                       //               //         index];
//                                       //               broken['checked'] =
//                                       //                   !broken['checked'];
//                                       //             });
//                                       //             // widget.onCategoryChecked(checkedListCategory);
//                                       //           },
//                                       //           child: Container(
//                                       //             padding: EdgeInsets.all(10),
//                                       //             child: Row(
//                                       //               children: [
//                                       //                 Container(
//                                       //                   width: 24,
//                                       //                   height: 24,
//                                       //                   decoration:
//                                       //                       BoxDecoration(
//                                       //                     color: broken[
//                                       //                             'checked']
//                                       //                         ? black
//                                       //                         : Colors
//                                       //                             .transparent,
//                                       //                     border: Border.all(
//                                       //                         color:
//                                       //                             Colors.black),
//                                       //                   ),
//                                       //                   child: Icon(
//                                       //                     Icons.check,
//                                       //                     color: Colors.white,
//                                       //                     size: 16,
//                                       //                   ),
//                                       //                 ),
//                                       //                 SizedBox(width: 10),
//                                       //                 LayoutBuilder(builder:
//                                       //                     (context,
//                                       //                         constraints) {
//                                       //                   double fontSize =
//                                       //                       constraints
//                                       //                               .maxHeight *
//                                       //                           0.35;
//                                       //                   // log('ukuran' + fontSize.toString());
//                                       //                   return Text(
//                                       //                     broken['name'],
//                                       //                     style:
//                                       //                         getBlackTextStyle(
//                                       //                             fontSize:
//                                       //                                 fontSize),
//                                       //                   );
//                                       //                 }),
//                                       //               ],
//                                       //             ),
//                                       //           ),
//                                       //         );
//                                       //       }),
//                                       // ),
//                                     ],
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         }),
//                   ],
//                 ),
//               ),
//             );
//           }
//           return Container();
//         },
//       )),
//       bottomNavigationBar: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           BlocBuilder<TireBloc, TireState>(
//             builder: (context, state) {
//               if (state is TiresLoadedState) {
//                 return Container(
//                   margin: EdgeInsets.symmetric(horizontal: 24),
//                   child: ButtonWidget(
//                       name: isLoadingSave
//                           ? Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const SizedBox(
//                                   width: 22,
//                                   height: 22,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2.5,
//                                     valueColor: AlwaysStoppedAnimation<Color>(
//                                       Colors.white,
//                                     ),
//                                   ),
//                                 ),
//                                 const SizedBox(width: 10),
//                                 Text(
//                                   'Saving...',
//                                   style: getWhiteTextStyle(
//                                     fontWeight: w700,
//                                   ),
//                                 ),
//                               ],
//                             )
//                           : Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 const Icon(
//                                   Icons.save_alt,
//                                   color: Colors.white,
//                                 ),
//                                 const SizedBox(width: 6),
//                                 Text(
//                                   'Save',
//                                   style: getWhiteTextStyle(),
//                                 ),
//                               ],
//                             ),
//                       function: () async {
//                         if (isLoadingSave) return;

//                         //// Validasi Tire Inspection
//                         final currentHm =
//                             double.tryParse(state.units[0].hm ?? '0') ?? 0;
//                         final newHm = double.tryParse(hmUnit.text ?? '0') ?? 0;

//                         // SMU/HM tidak boleh turun
//                         if (currentHm > newHm) {
//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                             content: Text(
//                               'SMU/HM tidak bisa berkurang',
//                               style: getWhiteTextStyle(),
//                             ),
//                             backgroundColor: Colors.red,
//                           ));
//                           return;
//                         }

//                         // SMU/HM tidak boleh nambah terlalu banyak
//                         if ((newHm - currentHm) > 1000) {
//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 'Perubahan SMU/HM tidak bisa lebih dari 1000',
//                                 style: getWhiteTextStyle(),
//                               ),
//                               backgroundColor: Colors.red,
//                             ),
//                           );
//                           return;
//                         }

//                         final List<String> errorsRtd = [];
//                         final List<String> errorsRating = [];

//                         for (int i = 0; i < state.units.length; i++) {
//                           final unit = state.units[i];

//                           // RTD tidak boleh naik
//                           final actualRtd =
//                               double.tryParse(unit.rtd.toString()) ?? 0;
//                           final actualOtd =
//                               double.tryParse(unit.otd.toString()) ?? 0;

//                           final inputRtd =
//                               double.tryParse(rtd1Controllers[i].text) ?? 0;
//                           final inputOtd =
//                               double.tryParse(rtd2Controllers[i].text) ?? 0;

//                           if (inputRtd > actualRtd) {
//                             errorsRtd.add(
//                               'Posisi ${unit.posisi}: RTD input ($inputRtd) melebihi RTD aktual ($actualRtd).',
//                             );
//                           }

//                           if (inputOtd > actualOtd) {
//                             errorsRtd.add(
//                               'Posisi ${unit.posisi}: OTD input ($inputOtd) melebihi OTD aktual ($actualOtd).',
//                             );
//                           }

//                           // Jika sudah rating x, tidak boleh kembali ke rating A,B,C
//                           const ratingScore = {
//                             'A': 4,
//                             'B': 3,
//                             'C': 2,
//                             'X': 1,
//                           };
//                           final actualRating = position[i]['prevRating']
//                               .toString()
//                               .toUpperCase()
//                               .trim();
//                           final inputRating = position[i]['rating']
//                               .toString()
//                               .toUpperCase()
//                               .trim();

//                           final actualScore = ratingScore[actualRating] ?? 0;
//                           final inputScore = ratingScore[inputRating] ?? 0;

//                           // Skip pengecekan jika prevRating kosong
//                           if (actualRating.isNotEmpty) {
//                             final actualScore = ratingScore[actualRating] ?? 0;
//                             final inputScore = ratingScore[inputRating] ?? 0;

//                             log('apakah rating membaik 3 : ${inputScore > actualScore}');

//                             if (inputScore > actualScore) {
//                               errorsRating.add(
//                                 'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
//                               );
//                             }
//                           }

//                           // if (inputScore > actualScore) {
//                           //   errorsRating.add(
//                           //     'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
//                           //   );
//                           // }
//                         }

//                         if (errorsRtd.isNotEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: const Duration(seconds: 6),
//                               content: Text(
//                                 errorsRtd.join('\n'),
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ),
//                           );
//                           return;
//                         }

//                         if (errorsRating.isNotEmpty) {
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: const Duration(seconds: 6),
//                               content: Text(
//                                 errorsRating.join('\n'),
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ),
//                           );
//                           return;
//                         }

//                         if (!mounted) return;

//                         FocusScope.of(context).unfocus();
//                         setState(() {
//                           isLoadingSave = true;
//                         });

//                         // input ke tire inspection
//                         try {
//                           await (() async {
//                             position.removeWhere((element) =>
//                                 element['pressure'] == '' &&
//                                 (element['damageTire'] as List<dynamic>)
//                                     .isEmpty &&
//                                 element['adjusmentPressure'] == '' &&
//                                 element['rtd1'] == '' &&
//                                 element['rtd2'] == '' &&
//                                 element['rating'] == '' &&
//                                 element['sn'] == '' &&
//                                 element['remarks'] == '');

//                             final today = DateTime.now();
//                             final hari =
//                                 '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
//                             final jam =
//                                 '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}:${today.second.toString().padLeft(2, '0')}';
//                             final docId = '${hari}_${jam}';

//                             // Bangun list posisi sesuai struktur tire_inspection
//                             final List<Map<String, dynamic>> posisiList = [];
//                             log('unit tire inspection ${state.units}');
//                             final firstUnit = state.units[0];
//                             final String kunciUnit = firstUnit.kunciUnit ?? '';

//                             for (int i = 0; i < position.length; i++) {
//                               final unit = state.units[i];

//                               String? localImagePath;
//                               try {
//                                 final imgList =
//                                     position[i]['image'] as List<dynamic>?;
//                                 if (imgList != null && imgList.isNotEmpty) {
//                                   final raw = imgList[0] as String;
//                                   final parts = raw.split('|');
//                                   if (parts.isNotEmpty) {
//                                     localImagePath = parts[0];
//                                   }
//                                 }
//                               } catch (e) {
//                                 log('parse image error: $e');
//                               }

//                               final bool hasNewLocalImage =
//                                   localImagePath != null;

//                               posisiList.add({
//                                 'position': position[i]['position'],
//                                 'pressure': position[i]['pressure'],
//                                 'adjusmentPressure': position[i]
//                                     ['adjusmentPressure'],
//                                 'rating': position[i]['rating'],
//                                 'rtd1': position[i]['rtd1'],
//                                 'rtd2': position[i]['rtd2'],
//                                 'sn': (position[i]['sn'] != null &&
//                                         position[i]['sn'] != '')
//                                     ? position[i]['sn']
//                                     : unit.sn,
//                                 'remarks':
//                                     (position[i]['damageTire'] as List).isEmpty
//                                         ? damageType[0]
//                                         : position[i]['damageTire'][0],
//                                 'damageTire':
//                                     (position[i]['damageTire'] as List).isEmpty
//                                         ? (damageType is List<String>)
//                                             ? damageType[0]
//                                             : damageType[0]['remark']
//                                         : position[i]['damageTire'],
//                                 // 'condition': (position[i]['condition'] as List)
//                                 //     .where((c) => c['checked'] == true)
//                                 //     .map((c) => c['name'].toString())
//                                 //     .toList(),
//                                 'rimCondition': position[i]['rimCondition'],
//                                 'idUnit': position[i]['idUnit'],
//                                 'idInventory': position[i]['idInventory'],
//                                 'tireSize': position[i]['tireSize'],
//                                 'kunci_tire': unit.kunciTire,
//                                 'hm': hmUnit.text,
//                                 'images': [],
//                                 'imagePending': hasNewLocalImage,
//                                 'tireAccessories': [],
//                                 'brand': firstUnit.brand,
//                                 'pattern': firstUnit.pattern,
//                               });

//                               if (hasNewLocalImage) {
//                                 // Pending upload akan di-handle setelah document dibuat
//                               }
//                             }

//                             // Cek apakah sudah ada dokumen tire_inspection hari ini untuk unit ini
//                             final startOfDay =
//                                 DateTime(today.year, today.month, today.day);
//                             final endOfDay = DateTime(
//                                 today.year, today.month, today.day, 23, 59, 59);

//                             final querySnapshot = await firestore
//                                 .collection('tire_inspection')
//                                 // .where('kunci_unit', isEqualTo: kunciUnit) // kunci_unit dari unit
//                                 .where('hari', isEqualTo: hari)
//                                 .where('unit', isEqualTo: firstUnit.unitNumber)
//                                 // .where('tanggal',
//                                 //     isGreaterThanOrEqualTo:
//                                 //         startOfDay.toIso8601String())
//                                 // .where('tanggal',
//                                 //     isLessThanOrEqualTo:
//                                 //         endOfDay.toIso8601String())
//                                 .get();

//                             log('tire_inspection exists: ${querySnapshot.docs.isNotEmpty}');

//                             if (querySnapshot.docs.isNotEmpty) {
//                               // Update dokumen yang sudah ada
//                               final existingDocId = querySnapshot.docs.first.id;

//                               await firestore
//                                   .collection('tire_inspection')
//                                   .doc(existingDocId)
//                                   .update({
//                                 'id': const Uuid().v4(),
//                                 'id_site': idSite,
//                                 'user': user['username'] ?? 'username',
//                                 'user_email': auth.currentUser!.email,
//                                 'unit': dataUnit['unitNumber'],
//                                 'kunci_unit': kunciUnit,
//                                 'hm': hmUnit.text,
//                                 'hari': hari,
//                                 'jam': jam,
//                                 'tanggal': today.toIso8601String(),
//                                 'pit': (idSite == bmbsitarum.idSite ||
//                                         idSite == bmbhauling.idSite ||
//                                         idSite == bmbtabuhan.idSite ||
//                                         idSite == bibkgb.idSite)
//                                     ? pit[selectedPit]
//                                     : 'Default',
//                                 'posisi': posisiList,
//                                 'brand': firstUnit.unitNumber,
//                                 'pattern': firstUnit.pattern,
//                               });

//                               // Handle image upload per posisi
//                               for (int i = 0; i < position.length; i++) {
//                                 String? localImagePath;
//                                 try {
//                                   final imgList =
//                                       position[i]['image'] as List<dynamic>?;
//                                   if (imgList != null && imgList.isNotEmpty) {
//                                     final raw = imgList[0] as String;
//                                     final parts = raw.split('|');
//                                     if (parts.isNotEmpty)
//                                       localImagePath = parts[0];
//                                   }
//                                 } catch (e) {
//                                   log('parse image error: $e');
//                                 }
//                                 if (localImagePath != null) {
//                                   UploadQueueService.to.addPending(
//                                       docId: existingDocId,
//                                       filePath: localImagePath,
//                                       posisiIndex: i);
//                                 }
//                               }
//                             } else {
//                               // Buat dokumen baru dengan ID format tanggal_jam
//                               final newData = {
//                                 'id': const Uuid().v4(),
//                                 'id_site': idSite,
//                                 'user': user['username'] ?? 'username',
//                                 'user_email': auth.currentUser!.email,
//                                 'unit': dataUnit['unitNumber'],
//                                 'kunci_unit': kunciUnit,
//                                 'hm': hmUnit.text,
//                                 'hari': hari,
//                                 'jam': jam,
//                                 'tanggal': today.toIso8601String(),
//                                 'pit': (idSite == bmbsitarum.idSite ||
//                                         idSite == bmbhauling.idSite ||
//                                         idSite == bmbtabuhan.idSite ||
//                                         idSite == bibkgb.idSite)
//                                     ? pit[selectedPit]
//                                     : 'Default',
//                                 'posisi': posisiList,
//                               };

//                               final docRef = await firestore
//                                   .collection('tire_inspection')
//                                   .doc(docId)
//                                   .set(newData);

//                               // Handle image upload per posisi
//                               for (int i = 0; i < position.length; i++) {
//                                 String? localImagePath;
//                                 try {
//                                   final imgList =
//                                       position[i]['image'] as List<dynamic>?;
//                                   if (imgList != null && imgList.isNotEmpty) {
//                                     final raw = imgList[0] as String;
//                                     final parts = raw.split('|');
//                                     if (parts.isNotEmpty)
//                                       localImagePath = parts[0];
//                                   }
//                                 } catch (e) {
//                                   log('parse image error: $e');
//                                 }
//                                 if (localImagePath != null) {
//                                   UploadQueueService.to.addPending(
//                                     docId: docId,
//                                     filePath: localImagePath,
//                                     posisiIndex: i,
//                                   );
//                                 }
//                               }
//                             }

//                             //     // input ke daily check pressure
//                             try {
//                               final today = DateTime.now();
//                               final startOfDay =
//                                   DateTime(today.year, today.month, today.day);
//                               final endOfDay = DateTime(today.year, today.month,
//                                   today.day, 23, 59, 59);
//                               final formattedToday =
//                                   '${today.month.toString().padLeft(2, '0')}' // MM
//                                   '${today.day.toString().padLeft(2, '0')}' // DD
//                                   '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

//                               final querySnapshot = await FirebaseFirestore
//                                   .instance
//                                   .collection('daily_pressure')
//                                   .where('unit',
//                                       isEqualTo: dataUnit['unitNumber'])
//                                   .where('tanggal',
//                                       isGreaterThanOrEqualTo:
//                                           startOfDay.toIso8601String())
//                                   .where('tanggal',
//                                       isLessThanOrEqualTo:
//                                           endOfDay.toIso8601String())
//                                   .get();

//                               print(
//                                   'Documents found: ${querySnapshot.docs.length}');

//                               if (querySnapshot.docs.isNotEmpty) {
//                                 final docId = querySnapshot.docs.first.id;

//                                 // revisi data
//                                 await firestore
//                                     .collection('daily_pressure')
//                                     .doc(docId)
//                                     .update({
//                                   'idSite': idSite,
//                                   'user': user['username'] ??
//                                       auth.currentUser!.email,
//                                   'tanggal': DateTime.now().toIso8601String(),
//                                   'unit': idUnit.text,
//                                   'hm': hmUnit.text,
//                                   'posisi': position.map((p) {
//                                     final pIndex = position.indexOf(p);

//                                     log('tekanan angin : ${p['pressure']}');
//                                     return {
//                                       'pos': '${pIndex + 1}',
//                                       'pressure': (p['pressure']) ?? '0',
//                                       'rating': (p['rating']) ?? '',
//                                       'adjusmentPressure':
//                                           (p['adjusmentPressure']) ?? '0',
//                                       'luka': p['damageTire'],
//                                       'idUnit': p['idUnit'],
//                                       'idInventory': p['idInventory'],
//                                       'tireSize': p['tireSize'],
//                                       'idDaily':
//                                           '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                                       'tireAccessories': []
//                                     };
//                                   }),
//                                   'pit': (idSite == bmbsitarum.idSite ||
//                                           idSite == bmbhauling.idSite ||
//                                           idSite == bmbtabuhan.idSite ||
//                                           idSite == bibkgb.idSite ||
//                                           idSite == bibgh.idSite)
//                                       ? pit[selectedPit]
//                                       : 'Default'
//                                 });
//                               } else {
//                                 // tambah data
//                                 await firestore
//                                     .collection('daily_pressure')
//                                     .add({
//                                   // 'nama': (user),
//                                   'idSite': idSite,
//                                   'user': user['username'] ??
//                                       auth.currentUser!.email,
//                                   'tanggal': DateTime.now().toIso8601String(),
//                                   'unit': idUnit.text,
//                                   'hm': hmUnit.text,
//                                   'posisi': position.map((p) {
//                                     final pIndex = position.indexOf(p);
//                                     log('tekanan angin : ${p['pressure']}');

//                                     return {
//                                       'pos': '${pIndex + 1}',
//                                       'pressure': (p['pressure']) ?? '0',
//                                       'rating': (p['rating']) ?? '0',
//                                       'adjusmentPressure':
//                                           (p['adjusmentPressure']) ?? '0',
//                                       'luka': p['damageTire'],
//                                       'idUnit': p['idUnit'],
//                                       'idInventory': p['idInventory'],
//                                       'tireSize': p['tireSize'],
//                                       'idDaily':
//                                           '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                                       'tireAccessories': []
//                                     };
//                                   }),
//                                   'pit': (idSite == bmbsitarum.idSite ||
//                                           idSite == bmbhauling.idSite ||
//                                           idSite == bmbtabuhan.idSite ||
//                                           idSite == bibkgb.idSite)
//                                       ? pit[selectedPit]
//                                       : 'Default'
//                                 });
//                               }
//                             } catch (e, stackTrace) {
//                               log(
//                                 'error save daily pressure : $e',
//                                 stackTrace: stackTrace,
//                               );
//                               rethrow;
//                             }
//                           })()
//                               .timeout(
//                             const Duration(seconds: 15),
//                           );

//                           if (!mounted) return;

//                           setState(() {
//                             isLoadingSave = false;
//                           });

//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               content: Text(
//                                 'Successful save data, please check in home page',
//                                 style: getWhiteTextStyle(),
//                               ),
//                               backgroundColor: green00968A,
//                             ),
//                           );

//                           Navigator.pop(context);
//                         } on TimeoutException catch (e, stackTrace) {
//                           log(
//                             'save timeout : $e',
//                             stackTrace: stackTrace,
//                           );

//                           if (!mounted) return;

//                           setState(() {
//                             isLoadingSave = false;
//                           });

//                           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             SnackBar(
//                               backgroundColor: Colors.red,
//                               duration: const Duration(seconds: 5),
//                               content: Text(
//                                 'Gagal menyimpan data karena proses melebihi 15 detik. Periksa koneksi internet lalu coba kembali.',
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ),
//                           );
//                         } catch (e, stackTrace) {
//                           log(
//                             'kenapa gagal : $e',
//                             stackTrace: stackTrace,
//                           );

//                           if (mounted) {
//                             ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 backgroundColor: Colors.red,
//                                 content: Text(
//                                   'Failed to save data. Please try again.',
//                                   style: getWhiteTextStyle(),
//                                 ),
//                               ),
//                             );
//                           }
//                         } finally {
//                           if (mounted && isLoadingSave) {
//                             setState(() {
//                               isLoadingSave = false;
//                             });
//                           }
//                         }
//                       }),
//                   // child: ButtonWidget(
//                   //     name: isLoadingSave
//                   //         ? Row(
//                   //             mainAxisAlignment: MainAxisAlignment.center,
//                   //             children: [
//                   //               const SizedBox(
//                   //                 width: 22,
//                   //                 height: 22,
//                   //                 child: CircularProgressIndicator(
//                   //                   strokeWidth: 2.5,
//                   //                   valueColor: AlwaysStoppedAnimation<Color>(
//                   //                     Colors.white,
//                   //                   ),
//                   //                 ),
//                   //               ),
//                   //               const SizedBox(width: 10),
//                   //               Text(
//                   //                 'Saving...',
//                   //                 style: getWhiteTextStyle(
//                   //                   fontWeight: w700,
//                   //                 ),
//                   //               ),
//                   //             ],
//                   //           )
//                   //         : Row(
//                   //             mainAxisAlignment: MainAxisAlignment.center,
//                   //             children: [
//                   //               const Icon(
//                   //                 Icons.save_alt,
//                   //                 color: Colors.white,
//                   //               ),
//                   //               const SizedBox(width: 6),
//                   //               Text(
//                   //                 'Save',
//                   //                 style: getWhiteTextStyle(),
//                   //               ),
//                   //             ],
//                   //           ),
//                   //     // function: () async {
//                   //     //   // jika data pressure kosong
//                   //     //   bool hasEmptyPressure =
//                   //     //       position.any((p) => p['pressure'] == '');

//                   //     //   if (hasEmptyPressure) {
//                   //     //     ScaffoldMessenger.of(context).hideCurrentSnackBar();

//                   //     //     ScaffoldMessenger.of(context).showSnackBar(
//                   //     //       SnackBar(
//                   //     //         backgroundColor: Colors.red,
//                   //     //         content: Text(
//                   //     //           'Please input data pressure (Choose 0 Psi if No Tire or Block Valve)',
//                   //     //           style: TextStyle(color: Colors.white),
//                   //     //         ),
//                   //     //       ),
//                   //     //     );
//                   //     //     return;
//                   //     //   }
//                   //     //   // jika belum memeilih pit
//                   //     //   if (idSite == bmbsitarum.idSite ||
//                   //     //       idSite == bmbhauling.idSite ||
//                   //     //       idSite == bmbtabuhan.idSite ||
//                   //     //       idSite == bibkgb.idSite ||
//                   //     //       idSite == bibgh.idSite) {
//                   //     //     if (selectedPit == -1) {
//                   //     //       ScaffoldMessenger.of(context).showSnackBar(
//                   //     //         SnackBar(
//                   //     //           backgroundColor: Colors.red,
//                   //     //           content: Text(
//                   //     //             'Please select location of unit first!',
//                   //     //             style: TextStyle(color: Colors.white),
//                   //     //           ),
//                   //     //         ),
//                   //     //       );
//                   //     //       return;
//                   //     //     }
//                   //     //   }

//                   //     //   // input ke tire inspection
//                   //     //   try {
//                   //     //     position.removeWhere((element) =>
//                   //     //         element['pressure'] == '' &&
//                   //     //         (element['damageTire'] as List<dynamic>)
//                   //     //             .isEmpty &&
//                   //     //         element['adjusmentPressure'] == '' &&
//                   //     //         element['rtd1'] == '' &&
//                   //     //         element['rtd2'] == '' &&
//                   //     //         element['rating'] == '' &&
//                   //     //         element['sn'] == '' &&
//                   //     //         element['remarks'] == '');

//                   //     //     for (int i = 0; i < position.length; i++) {
//                   //     //       final unit = state.units[i];
//                   //     //       final id = Uuid();

//                   //     //       String? localImagePath;
//                   //     //       try {
//                   //     //         final imgList =
//                   //     //             position[i]['image'] as List<dynamic>?;
//                   //     //         if (imgList != null && imgList.isNotEmpty) {
//                   //     //           final raw = imgList[0]
//                   //     //               as String; // format: "path|position"
//                   //     //           final parts = raw.split('|');
//                   //     //           if (parts.isNotEmpty) {
//                   //     //             localImagePath = parts[0];
//                   //     //           }
//                   //     //         }
//                   //     //       } catch (e) {
//                   //     //         log('parse image error: $e');
//                   //     //       }

//                   //     //       log('SAVE POSISI ${localImagePath}');
//                   //     //       log('SAVE POSISI ${position[i]['position']} '
//                   //     //           'IMAGE: ${position[i]['image']}');

//                   //     //       if (position[i]['pressure'] != '' ||
//                   //     //           position[i]['hm'] != '' ||
//                   //     //           position[i]['damageTire'] != [] ||
//                   //     //           position[i]['damageTire'][0] != damageType[0] ||
//                   //     //           position[i]['adjusmentPressure'] != '' ||
//                   //     //           position[i]['rtd1'] != '' ||
//                   //     //           position[i]['rtd2'] != '' ||
//                   //     //           position[i]['rating'] != '' ||
//                   //     //           position[i]['sn'] != '' ||
//                   //     //           position[i]['remarks'] != '') {
//                   //     //         final today = DateTime.now();
//                   //     //         final startOfDay =
//                   //     //             DateTime(today.year, today.month, today.day);
//                   //     //         final endOfDay = DateTime(today.year, today.month,
//                   //     //             today.day, 23, 59, 59);

//                   //     //         final querySnapshot = await firestore
//                   //     //             .collection('task')
//                   //     //             .where('kunci_unit',
//                   //     //                 isEqualTo: unit.kunciUnit)
//                   //     //             .where('kunci_tire',
//                   //     //                 isEqualTo: unit.kunciTire)
//                   //     //             .where('position',
//                   //     //                 isEqualTo: position[i]['position'])
//                   //     //             .where('last_update',
//                   //     //                 isGreaterThanOrEqualTo:
//                   //     //                     startOfDay.toIso8601String())
//                   //     //             .where('last_update',
//                   //     //                 isLessThanOrEqualTo:
//                   //     //                     endOfDay.toIso8601String())
//                   //     //             .get();

//                   //     //         log('adakah query : ${querySnapshot.docs.isNotEmpty}');

//                   //     //         final bool hasNewLocalImage =
//                   //     //             localImagePath != null;

//                   //     //         if (querySnapshot.docs.isNotEmpty) {
//                   //     //           // Update the existing document
//                   //     //           final docId = querySnapshot.docs.first.id;
//                   //     //           // try {
//                   //     //           //   log('kenapa gagal 3 ${position[i]['image'] as List<dynamic>}');
//                   //     //           // } catch (e) {
//                   //     //           //   log('kenapa gagal 4 ${e}');
//                   //     //           // }

//                   //     //           final Map<String, dynamic> updateData = {
//                   //     //             'id': id.v4(),
//                   //     //             'id_site': idSite,
//                   //     //             'user': user['username'] ?? 'username',
//                   //     //             'user_email': auth.currentUser!.email,
//                   //     //             'unit': unit.unitNumber,
//                   //     //             'serial_number': unit.sn,
//                   //     //             'condition': position[i]['condition']
//                   //     //                 .where((condition) =>
//                   //     //                     condition['checked'] == true)
//                   //     //                 .map((condition) =>
//                   //     //                     condition['name'].toString())
//                   //     //                 .toList(),
//                   //     //             'tire_size': unit.size,
//                   //     //             'hm': hmUnit.text,
//                   //     //             'position': position[i]['position'],
//                   //     //             'rating': position[i]['rating'],
//                   //     //             'brand': unit.brand,
//                   //     //             'tire_damage':
//                   //     //                 (position[i]['damageTire'].isEmpty)
//                   //     //                     ? damageType[0]
//                   //     //                     : position[i]['damageTire'],
//                   //     //             'remarks': position[i]['remarks'],
//                   //     //             'rtd':
//                   //     //                 '${position[i]['rtd1']}/${position[i]['rtd2']}',
//                   //     //             'pressure': position[i]['pressure'],
//                   //     //             'adjusmentPressure': position[i]
//                   //     //                 ['adjusmentPressure'],
//                   //     //             'last_update':
//                   //     //                 DateTime.now().toIso8601String(),
//                   //     //             'is_done': false,
//                   //     //             'sn': (position[i]['sn'] != null ||
//                   //     //                     position[i]['sn'] != '')
//                   //     //                 ? position[i]['sn']
//                   //     //                 : unit.sn,
//                   //     //             'kunci_unit': unit.kunciUnit,
//                   //     //             'kunci_tire': unit.kunciTire,
//                   //     //             'pit': (idSite == bmbsitarum.idSite ||
//                   //     //                     idSite == bmbhauling.idSite ||
//                   //     //                     idSite == bmbtabuhan.idSite ||
//                   //     //                     idSite == bibkgb.idSite)
//                   //     //                 ? pit[selectedPit]
//                   //     //                 : 'Default',
//                   //     //           };

//                   //     //           // Hanya kalau ada foto baru → kosongkan images & set pending
//                   //     //           if (hasNewLocalImage) {
//                   //     //             updateData['images'] = [];
//                   //     //             updateData['imagePending'] = true;
//                   //     //           }

//                   //     //           await firestore
//                   //     //               .collection('task')
//                   //     //               .doc(docId)
//                   //     //               .update(updateData);
//                   //     //           if (hasNewLocalImage) {
//                   //     //             UploadQueueService.to.addPending(
//                   //     //               docId: docId,
//                   //     //               filePath: localImagePath!,
//                   //     //             );
//                   //     //           }
//                   //     //         } else {
//                   //     //           final Map<String, dynamic> newData = {
//                   //     //             'id': id.v4(),
//                   //     //             'id_site': idSite,
//                   //     //             'user': user['username'] ?? 'username',
//                   //     //             'user_email': auth.currentUser!.email,
//                   //     //             'unit': unit.unitNumber,
//                   //     //             'serial_number': unit.sn,
//                   //     //             'condition': position[i]['condition']
//                   //     //                 .where((condition) =>
//                   //     //                     condition['checked'] == true)
//                   //     //                 .map((condition) =>
//                   //     //                     condition['name'].toString())
//                   //     //                 .toList(),
//                   //     //             'tire_size': unit.size,
//                   //     //             'hm': hmUnit.text,
//                   //     //             'position': position[i]['position'],
//                   //     //             'rating': position[i]['rating'],
//                   //     //             'brand': unit.brand,
//                   //     //             'tire_damage':
//                   //     //                 (position[i]['damageTire'].isEmpty)
//                   //     //                     ? damageType[0]
//                   //     //                     : position[i]['damageTire'],
//                   //     //             'remarks': position[i]['remarks'],
//                   //     //             'rtd':
//                   //     //                 '${position[i]['rtd1']}/${position[i]['rtd2']}',
//                   //     //             'pressure': position[i]['pressure'],
//                   //     //             'adjusmentPressure': position[i]
//                   //     //                 ['adjusmentPressure'],
//                   //     //             'last_update':
//                   //     //                 DateTime.now().toIso8601String(),
//                   //     //             'is_done': false,
//                   //     //             'sn': (position[i]['sn'] != '')
//                   //     //                 ? position[i]['sn']
//                   //     //                 : unit.sn,
//                   //     //             'kunci_unit': unit.kunciUnit,
//                   //     //             'kunci_tire': unit.kunciTire,
//                   //     //             'pit': (idSite == bmbsitarum.idSite ||
//                   //     //                     idSite == bmbhauling.idSite ||
//                   //     //                     idSite == bmbtabuhan.idSite ||
//                   //     //                     idSite == bibkgb.idSite)
//                   //     //                 ? pit[selectedPit]
//                   //     //                 : 'Default',
//                   //     //           };

//                   //     //           newData['images'] = [];
//                   //     //           newData['imagePending'] = hasNewLocalImage;

//                   //     //           final docRef = await firestore
//                   //     //               .collection('task')
//                   //     //               .add(newData);

//                   //     //           if (hasNewLocalImage) {
//                   //     //             UploadQueueService.to.addPending(
//                   //     //               docId: docRef.id,
//                   //     //               filePath: localImagePath!,
//                   //     //             );
//                   //     //           }
//                   //     //         }
//                   //     //       }
//                   //     //     }

//                   //     //     // input ke daily check pressure
//                   //     //     try {
//                   //     //       final today = DateTime.now();
//                   //     //       final startOfDay =
//                   //     //           DateTime(today.year, today.month, today.day);
//                   //     //       final endOfDay = DateTime(
//                   //     //           today.year, today.month, today.day, 23, 59, 59);
//                   //     //       final formattedToday =
//                   //     //           '${today.month.toString().padLeft(2, '0')}' // MM
//                   //     //           '${today.day.toString().padLeft(2, '0')}' // DD
//                   //     //           '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

//                   //     //       final querySnapshot = await FirebaseFirestore
//                   //     //           .instance
//                   //     //           .collection('daily_pressure')
//                   //     //           .where('unit',
//                   //     //               isEqualTo: dataUnit['unitNumber'])
//                   //     //           .where('tanggal',
//                   //     //               isGreaterThanOrEqualTo:
//                   //     //                   startOfDay.toIso8601String())
//                   //     //           .where('tanggal',
//                   //     //               isLessThanOrEqualTo:
//                   //     //                   endOfDay.toIso8601String())
//                   //     //           .get();

//                   //     //       print(
//                   //     //           'Documents found: ${querySnapshot.docs.length}');

//                   //     //       if (querySnapshot.docs.isNotEmpty) {
//                   //     //         final docId = querySnapshot.docs.first.id;

//                   //     //         // revisi data
//                   //     //         await firestore
//                   //     //             .collection('daily_pressure')
//                   //     //             .doc(docId)
//                   //     //             .update({
//                   //     //           'idSite': idSite,
//                   //     //           'user':
//                   //     //               user['username'] ?? auth.currentUser!.email,
//                   //     //           'tanggal': DateTime.now().toIso8601String(),
//                   //     //           'unit': idUnit.text,
//                   //     //           'hm': hmUnit.text,
//                   //     //           'posisi': position.map((p) {
//                   //     //             final pIndex = position.indexOf(p);

//                   //     //             log('tekanan angin : ${p['pressure']}');
//                   //     //             return {
//                   //     //               'pos': '${pIndex + 1}',
//                   //     //               'pressure': (p['pressure']) ?? '0',
//                   //     //               'rating': (p['rating']) ?? '',
//                   //     //               'adjusmentPressure':
//                   //     //                   (p['adjusmentPressure']) ?? '0',
//                   //     //               'luka': p['damageTire'],
//                   //     //               'idUnit': p['idUnit'],
//                   //     //               'idInventory': p['idInventory'],
//                   //     //               'tireSize': p['tireSize'],
//                   //     //               'idDaily':
//                   //     //                   '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                   //     //               'tireAccessories': []
//                   //     //             };
//                   //     //           }),
//                   //     //           'pit': (idSite == bmbsitarum.idSite ||
//                   //     //                   idSite == bmbhauling.idSite ||
//                   //     //                   idSite == bmbtabuhan.idSite ||
//                   //     //                   idSite == bibkgb.idSite)
//                   //     //               ? pit[selectedPit]
//                   //     //               : 'Default'
//                   //     //         });
//                   //     //       } else {
//                   //     //         // tambah data
//                   //     //         await firestore.collection('daily_pressure').add({
//                   //     //           // 'nama': (user),
//                   //     //           'idSite': idSite,
//                   //     //           'user':
//                   //     //               user['username'] ?? auth.currentUser!.email,
//                   //     //           'tanggal': DateTime.now().toIso8601String(),
//                   //     //           'unit': idUnit.text,
//                   //     //           'hm': hmUnit.text,
//                   //     //           'posisi': position.map((p) {
//                   //     //             final pIndex = position.indexOf(p);
//                   //     //             log('tekanan angin : ${p['pressure']}');

//                   //     //             return {
//                   //     //               'pos': '${pIndex + 1}',
//                   //     //               'pressure': (p['pressure']) ?? '0',
//                   //     //               'rating': (p['rating']) ?? '0',
//                   //     //               'adjusmentPressure':
//                   //     //                   (p['adjusmentPressure']) ?? '0',
//                   //     //               'luka': p['damageTire'],
//                   //     //               'idUnit': p['idUnit'],
//                   //     //               'idInventory': p['idInventory'],
//                   //     //               'tireSize': p['tireSize'],
//                   //     //               'idDaily':
//                   //     //                   '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                   //     //               'tireAccessories': []
//                   //     //             };
//                   //     //           }),
//                   //     //           'pit': (idSite == bmbsitarum.idSite ||
//                   //     //                   idSite == bmbhauling.idSite ||
//                   //     //                   idSite == bmbtabuhan.idSite ||
//                   //     //                   idSite == bibkgb.idSite)
//                   //     //               ? pit[selectedPit]
//                   //     //               : 'Default'
//                   //     //         });
//                   //     //       }
//                   //     //     } catch (e) {
//                   //     //       print('error bmb : $e');
//                   //     //     }
//                   //     //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                   //     //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                   //     //       content: Text(
//                   //     //         'Successful save data, please check in home page',
//                   //     //         style: getWhiteTextStyle(),
//                   //     //       ),
//                   //     //       backgroundColor: green00968A,
//                   //     //     ));
//                   //     //     Navigator.pop(context);
//                   //     //   } catch (e) {
//                   //     //     log('kenapa gagal : $e');
//                   //     //   }
//                   //     // }
//                   //     function: () async {
//                   //       if (isLoadingSave) return;

//                   //       //// Validasi Tire Inspection
//                   //       final currentHm =
//                   //           double.tryParse(state.units[0].hm ?? '0') ?? 0;
//                   //       final newHm = double.tryParse(hmUnit.text ?? '0') ?? 0;

//                   //       // SMU/HM tidak boleh turun
//                   //       if (currentHm > newHm) {
//                   //         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                   //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                   //           content: Text(
//                   //             'SMU/HM tidak bisa berkurang',
//                   //             style: getWhiteTextStyle(),
//                   //           ),
//                   //           backgroundColor: Colors.red,
//                   //         ));
//                   //         return;
//                   //       }

//                   //       // SMU/HM tidak boleh nambah terlalu banyak
//                   //       if ((newHm - currentHm) > 1000) {
//                   //         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                   //         ScaffoldMessenger.of(context).showSnackBar(
//                   //           SnackBar(
//                   //             content: Text(
//                   //               'Perubahan SMU/HM tidak bisa lebih dari 1000',
//                   //               style: getWhiteTextStyle(),
//                   //             ),
//                   //             backgroundColor: Colors.red,
//                   //           ),
//                   //         );
//                   //         return;
//                   //       }

//                   //       final List<String> errorsRtd = [];
//                   //       final List<String> errorsRating = [];

//                   //       for (int i = 0; i < state.units.length; i++) {
//                   //         final unit = state.units[i];

//                   //         // RTD tidak boleh naik
//                   //         final actualRtd =
//                   //             double.tryParse(unit.rtd.toString()) ?? 0;
//                   //         final actualOtd =
//                   //             double.tryParse(unit.otd.toString()) ?? 0;

//                   //         final inputRtd =
//                   //             double.tryParse(rtd1Controllers[i].text) ?? 0;
//                   //         final inputOtd =
//                   //             double.tryParse(rtd2Controllers[i].text) ?? 0;

//                   //         if (inputRtd > actualRtd) {
//                   //           errorsRtd.add(
//                   //             'Posisi ${unit.posisi}: RTD input ($inputRtd) melebihi RTD aktual ($actualRtd).',
//                   //           );
//                   //         }

//                   //         if (inputOtd > actualOtd) {
//                   //           errorsRtd.add(
//                   //             'Posisi ${unit.posisi}: OTD input ($inputOtd) melebihi OTD aktual ($actualOtd).',
//                   //           );
//                   //         }

//                   //         // Jika sudah rating x, tidak boleh kembali ke rating A,B,C
//                   //         const ratingScore = {
//                   //           'A': 4,
//                   //           'B': 3,
//                   //           'C': 2,
//                   //           'X': 1,
//                   //         };
//                   //         final actualRating = position[i]['prevRating']
//                   //             .toString()
//                   //             .toUpperCase()
//                   //             .trim();
//                   //         final inputRating = position[i]['rating']
//                   //             .toString()
//                   //             .toUpperCase()
//                   //             .trim();

//                   //         final actualScore = ratingScore[actualRating] ?? 0;
//                   //         final inputScore = ratingScore[inputRating] ?? 0;

//                   //         // Skip pengecekan jika prevRating kosong
//                   //         if (actualRating.isNotEmpty) {
//                   //           final actualScore = ratingScore[actualRating] ?? 0;
//                   //           final inputScore = ratingScore[inputRating] ?? 0;

//                   //           log('apakah rating membaik 3 : ${inputScore > actualScore}');

//                   //           if (inputScore > actualScore) {
//                   //             errorsRating.add(
//                   //               'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
//                   //             );
//                   //           }
//                   //         }

//                   //         // if (inputScore > actualScore) {
//                   //         //   errorsRating.add(
//                   //         //     'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
//                   //         //   );
//                   //         // }
//                   //       }

//                   //       if (errorsRtd.isNotEmpty) {
//                   //         ScaffoldMessenger.of(context).showSnackBar(
//                   //           SnackBar(
//                   //             backgroundColor: Colors.red,
//                   //             duration: const Duration(seconds: 6),
//                   //             content: Text(
//                   //               errorsRtd.join('\n'),
//                   //               style: getWhiteTextStyle(),
//                   //             ),
//                   //           ),
//                   //         );
//                   //         return;
//                   //       }

//                   //       if (errorsRating.isNotEmpty) {
//                   //         ScaffoldMessenger.of(context).showSnackBar(
//                   //           SnackBar(
//                   //             backgroundColor: Colors.red,
//                   //             duration: const Duration(seconds: 6),
//                   //             content: Text(
//                   //               errorsRating.join('\n'),
//                   //               style: getWhiteTextStyle(),
//                   //             ),
//                   //           ),
//                   //         );
//                   //         return;
//                   //       }

//                   //       if (!mounted) return;

//                   //       FocusScope.of(context).unfocus();
//                   //       setState(() {
//                   //         isLoadingSave = true;
//                   //       });

//                   //       // input ke tire inspection
//                   //       try {
//                   //         position.removeWhere((element) =>
//                   //             element['pressure'] == '' &&
//                   //             (element['damageTire'] as List<dynamic>)
//                   //                 .isEmpty &&
//                   //             element['adjusmentPressure'] == '' &&
//                   //             element['rtd1'] == '' &&
//                   //             element['rtd2'] == '' &&
//                   //             element['rating'] == '' &&
//                   //             element['sn'] == '' &&
//                   //             element['remarks'] == '');

//                   //         final today = DateTime.now();
//                   //         final hari =
//                   //             '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
//                   //         final jam =
//                   //             '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}:${today.second.toString().padLeft(2, '0')}';
//                   //         final docId = '${hari}_${jam}';

//                   //         // Bangun list posisi sesuai struktur tire_inspection
//                   //         final List<Map<String, dynamic>> posisiList = [];
//                   //         log('unit tire inspection ${state.units}');
//                   //         final firstUnit = state.units[0];
//                   //         final String kunciUnit = firstUnit.kunciUnit ?? '';

//                   //         for (int i = 0; i < position.length; i++) {
//                   //           final unit = state.units[i];

//                   //           String? localImagePath;
//                   //           try {
//                   //             final imgList =
//                   //                 position[i]['image'] as List<dynamic>?;
//                   //             if (imgList != null && imgList.isNotEmpty) {
//                   //               final raw = imgList[0] as String;
//                   //               final parts = raw.split('|');
//                   //               if (parts.isNotEmpty) {
//                   //                 localImagePath = parts[0];
//                   //               }
//                   //             }
//                   //           } catch (e) {
//                   //             log('parse image error: $e');
//                   //           }

//                   //           final bool hasNewLocalImage =
//                   //               localImagePath != null;

//                   //           posisiList.add({
//                   //             'position': position[i]['position'],
//                   //             'pressure': position[i]['pressure'],
//                   //             'adjusmentPressure': position[i]
//                   //                 ['adjusmentPressure'],
//                   //             'rating': position[i]['rating'],
//                   //             'rtd1': position[i]['rtd1'],
//                   //             'rtd2': position[i]['rtd2'],
//                   //             'sn': (position[i]['sn'] != null &&
//                   //                     position[i]['sn'] != '')
//                   //                 ? position[i]['sn']
//                   //                 : unit.sn,
//                   //             'remarks':
//                   //                 (position[i]['damageTire'] as List).isEmpty
//                   //                     ? damageType[0]
//                   //                     : position[i]['damageTire'][0],
//                   //             'damageTire':
//                   //                 (position[i]['damageTire'] as List).isEmpty
//                   //                     ? (damageType is List<String>)
//                   //                         ? damageType[0]
//                   //                         : damageType[0]['remark']
//                   //                     : position[i]['damageTire'],
//                   //             // 'condition': (position[i]['condition'] as List)
//                   //             //     .where((c) => c['checked'] == true)
//                   //             //     .map((c) => c['name'].toString())
//                   //             //     .toList(),
//                   //             'rimCondition': position[i]['rimCondition'],
//                   //             'idUnit': position[i]['idUnit'],
//                   //             'idInventory': position[i]['idInventory'],
//                   //             'tireSize': position[i]['tireSize'],
//                   //             'kunci_tire': unit.kunciTire,
//                   //             'hm': hmUnit.text,
//                   //             'images': [],
//                   //             'imagePending': hasNewLocalImage,
//                   //             'tireAccessories': [],
//                   //             'brand': firstUnit.brand,
//                   //             'pattern': firstUnit.pattern,
//                   //           });

//                   //           if (hasNewLocalImage) {
//                   //             // Pending upload akan di-handle setelah document dibuat
//                   //           }
//                   //         }

//                   //         // Cek apakah sudah ada dokumen tire_inspection hari ini untuk unit ini
//                   //         final startOfDay =
//                   //             DateTime(today.year, today.month, today.day);
//                   //         final endOfDay = DateTime(
//                   //             today.year, today.month, today.day, 23, 59, 59);

//                   //         final querySnapshot = await firestore
//                   //             .collection('tire_inspection')
//                   //             // .where('kunci_unit', isEqualTo: kunciUnit) // kunci_unit dari unit
//                   //             .where('hari', isEqualTo: hari)
//                   //             .where('unit', isEqualTo: firstUnit.unitNumber)
//                   //             // .where('tanggal',
//                   //             //     isGreaterThanOrEqualTo:
//                   //             //         startOfDay.toIso8601String())
//                   //             // .where('tanggal',
//                   //             //     isLessThanOrEqualTo:
//                   //             //         endOfDay.toIso8601String())
//                   //             .get();

//                   //         log('tire_inspection exists: ${querySnapshot.docs.isNotEmpty}');

//                   //         if (querySnapshot.docs.isNotEmpty) {
//                   //           // Update dokumen yang sudah ada
//                   //           final existingDocId = querySnapshot.docs.first.id;

//                   //           await firestore
//                   //               .collection('tire_inspection')
//                   //               .doc(existingDocId)
//                   //               .update({
//                   //             'id': const Uuid().v4(),
//                   //             'id_site': idSite,
//                   //             'user': user['username'] ?? 'username',
//                   //             'user_email': auth.currentUser!.email,
//                   //             'unit': dataUnit['unitNumber'],
//                   //             'kunci_unit': kunciUnit,
//                   //             'hm': hmUnit.text,
//                   //             'hari': hari,
//                   //             'jam': jam,
//                   //             'tanggal': today.toIso8601String(),
//                   //             'pit': (idSite == bmbsitarum.idSite ||
//                   //                     idSite == bmbhauling.idSite ||
//                   //                     idSite == bmbtabuhan.idSite ||
//                   //                     idSite == bibkgb.idSite)
//                   //                 ? pit[selectedPit]
//                   //                 : 'Default',
//                   //             'posisi': posisiList,
//                   //             'brand': firstUnit.unitNumber,
//                   //             'pattern': firstUnit.pattern,
//                   //           });

//                   //           // Handle image upload per posisi
//                   //           for (int i = 0; i < position.length; i++) {
//                   //             String? localImagePath;
//                   //             try {
//                   //               final imgList =
//                   //                   position[i]['image'] as List<dynamic>?;
//                   //               if (imgList != null && imgList.isNotEmpty) {
//                   //                 final raw = imgList[0] as String;
//                   //                 final parts = raw.split('|');
//                   //                 if (parts.isNotEmpty)
//                   //                   localImagePath = parts[0];
//                   //               }
//                   //             } catch (e) {
//                   //               log('parse image error: $e');
//                   //             }
//                   //             if (localImagePath != null) {
//                   //               UploadQueueService.to.addPending(
//                   //                   docId: existingDocId,
//                   //                   filePath: localImagePath,
//                   //                   posisiIndex: i);
//                   //             }
//                   //           }
//                   //         } else {
//                   //           // Buat dokumen baru dengan ID format tanggal_jam
//                   //           final newData = {
//                   //             'id': const Uuid().v4(),
//                   //             'id_site': idSite,
//                   //             'user': user['username'] ?? 'username',
//                   //             'user_email': auth.currentUser!.email,
//                   //             'unit': dataUnit['unitNumber'],
//                   //             'kunci_unit': kunciUnit,
//                   //             'hm': hmUnit.text,
//                   //             'hari': hari,
//                   //             'jam': jam,
//                   //             'tanggal': today.toIso8601String(),
//                   //             'pit': (idSite == bmbsitarum.idSite ||
//                   //                     idSite == bmbhauling.idSite ||
//                   //                     idSite == bmbtabuhan.idSite ||
//                   //                     idSite == bibkgb.idSite)
//                   //                 ? pit[selectedPit]
//                   //                 : 'Default',
//                   //             'posisi': posisiList,
//                   //           };

//                   //           final docRef = await firestore
//                   //               .collection('tire_inspection')
//                   //               .doc(docId)
//                   //               .set(newData);

//                   //           // Handle image upload per posisi
//                   //           for (int i = 0; i < position.length; i++) {
//                   //             String? localImagePath;
//                   //             try {
//                   //               final imgList =
//                   //                   position[i]['image'] as List<dynamic>?;
//                   //               if (imgList != null && imgList.isNotEmpty) {
//                   //                 final raw = imgList[0] as String;
//                   //                 final parts = raw.split('|');
//                   //                 if (parts.isNotEmpty)
//                   //                   localImagePath = parts[0];
//                   //               }
//                   //             } catch (e) {
//                   //               log('parse image error: $e');
//                   //             }
//                   //             if (localImagePath != null) {
//                   //               UploadQueueService.to.addPending(
//                   //                 docId: docId,
//                   //                 filePath: localImagePath,
//                   //                 posisiIndex: i,
//                   //               );
//                   //             }
//                   //           }
//                   //         }

//                   //         //     // input ke daily check pressure
//                   //         try {
//                   //           final today = DateTime.now();
//                   //           final startOfDay =
//                   //               DateTime(today.year, today.month, today.day);
//                   //           final endOfDay = DateTime(
//                   //               today.year, today.month, today.day, 23, 59, 59);
//                   //           final formattedToday =
//                   //               '${today.month.toString().padLeft(2, '0')}' // MM
//                   //               '${today.day.toString().padLeft(2, '0')}' // DD
//                   //               '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

//                   //           final querySnapshot = await FirebaseFirestore
//                   //               .instance
//                   //               .collection('daily_pressure')
//                   //               .where('unit',
//                   //                   isEqualTo: dataUnit['unitNumber'])
//                   //               .where('tanggal',
//                   //                   isGreaterThanOrEqualTo:
//                   //                       startOfDay.toIso8601String())
//                   //               .where('tanggal',
//                   //                   isLessThanOrEqualTo:
//                   //                       endOfDay.toIso8601String())
//                   //               .get();

//                   //           print(
//                   //               'Documents found: ${querySnapshot.docs.length}');

//                   //           if (querySnapshot.docs.isNotEmpty) {
//                   //             final docId = querySnapshot.docs.first.id;

//                   //             // revisi data
//                   //             await firestore
//                   //                 .collection('daily_pressure')
//                   //                 .doc(docId)
//                   //                 .update({
//                   //               'idSite': idSite,
//                   //               'user':
//                   //                   user['username'] ?? auth.currentUser!.email,
//                   //               'tanggal': DateTime.now().toIso8601String(),
//                   //               'unit': idUnit.text,
//                   //               'hm': hmUnit.text,
//                   //               'posisi': position.map((p) {
//                   //                 final pIndex = position.indexOf(p);

//                   //                 log('tekanan angin : ${p['pressure']}');
//                   //                 return {
//                   //                   'pos': '${pIndex + 1}',
//                   //                   'pressure': (p['pressure']) ?? '0',
//                   //                   'rating': (p['rating']) ?? '',
//                   //                   'adjusmentPressure':
//                   //                       (p['adjusmentPressure']) ?? '0',
//                   //                   'luka': p['damageTire'],
//                   //                   'idUnit': p['idUnit'],
//                   //                   'idInventory': p['idInventory'],
//                   //                   'tireSize': p['tireSize'],
//                   //                   'idDaily':
//                   //                       '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                   //                   'tireAccessories': []
//                   //                 };
//                   //               }),
//                   //               'pit': (idSite == bmbsitarum.idSite ||
//                   //                       idSite == bmbhauling.idSite ||
//                   //                       idSite == bmbtabuhan.idSite ||
//                   //                       idSite == bibkgb.idSite ||
//                   //                       idSite == bibgh.idSite)
//                   //                   ? pit[selectedPit]
//                   //                   : 'Default'
//                   //             });
//                   //           } else {
//                   //             // tambah data
//                   //             await firestore.collection('daily_pressure').add({
//                   //               // 'nama': (user),
//                   //               'idSite': idSite,
//                   //               'user':
//                   //                   user['username'] ?? auth.currentUser!.email,
//                   //               'tanggal': DateTime.now().toIso8601String(),
//                   //               'unit': idUnit.text,
//                   //               'hm': hmUnit.text,
//                   //               'posisi': position.map((p) {
//                   //                 final pIndex = position.indexOf(p);
//                   //                 log('tekanan angin : ${p['pressure']}');

//                   //                 return {
//                   //                   'pos': '${pIndex + 1}',
//                   //                   'pressure': (p['pressure']) ?? '0',
//                   //                   'rating': (p['rating']) ?? '0',
//                   //                   'adjusmentPressure':
//                   //                       (p['adjusmentPressure']) ?? '0',
//                   //                   'luka': p['damageTire'],
//                   //                   'idUnit': p['idUnit'],
//                   //                   'idInventory': p['idInventory'],
//                   //                   'tireSize': p['tireSize'],
//                   //                   'idDaily':
//                   //                       '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
//                   //                   'tireAccessories': []
//                   //                 };
//                   //               }),
//                   //               'pit': (idSite == bmbsitarum.idSite ||
//                   //                       idSite == bmbhauling.idSite ||
//                   //                       idSite == bmbtabuhan.idSite ||
//                   //                       idSite == bibkgb.idSite)
//                   //                   ? pit[selectedPit]
//                   //                   : 'Default'
//                   //             });
//                   //           }
//                   //         } catch (e) {
//                   //           print('error bmb : $e');
//                   //         }

//                   //         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                   //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                   //           content: Text(
//                   //             'Successful save data, please check in home page',
//                   //             style: getWhiteTextStyle(),
//                   //           ),
//                   //           backgroundColor: green00968A,
//                   //         ));
//                   //         Navigator.pop(context);
//                   //       } catch (e, stackTrace) {
//                   //         log(
//                   //           'kenapa gagal : $e',
//                   //           stackTrace: stackTrace,
//                   //         );

//                   //         if (mounted) {
//                   //           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//                   //           ScaffoldMessenger.of(context).showSnackBar(
//                   //             SnackBar(
//                   //               backgroundColor: Colors.red,
//                   //               content: Text(
//                   //                 'Failed to save data. Please try again.',
//                   //                 style: getWhiteTextStyle(),
//                   //               ),
//                   //             ),
//                   //           );
//                   //         }
//                   //       } finally {
//                   //         if (mounted && isLoadingSave) {
//                   //           setState(() {
//                   //             isLoadingSave = false;
//                   //           });
//                   //         }
//                   //       }
//                   //     }),
//                 );
//               }
//               return Container();
//             },
//           ),
//           const SizedBox(
//             height: 12,
//           ),
//         ],
//       ),
//     );
//   }
// }

// new code after check connection implementation sis admo mining
import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_settings/app_settings.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart'
    as connectedDevicesState;
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart';
import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_cubit.dart';
import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_state.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/tire_damage_ai.dart';
import 'package:camos/core/utils/bluetooth/utils/bluetooth_utils.dart';
import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/scan_device_page.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/bounding_box_painter.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/upload_queue_service.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:path_provider/path_provider.dart';
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
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

import 'widget/ai_loading_widget.dart';

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
  final HomeState homeState = Get.find<HomeState>();

  bool _isInit = true;
  int selectedMenu = 1;
  var map = {};
  String idSite = '';
  bool isSaved = false;
  bool isLoadingSave = false;
  Map<String, dynamic> dataUnit = {};
  String? _hmInitializedForUnit;

  TextEditingController idUnit = TextEditingController(text: '');
  TextEditingController hmUnit = TextEditingController(text: '');
  TextEditingController pressureCtrl = TextEditingController(text: '');
  TextEditingController remarksCtrl = TextEditingController(text: '');
  TextEditingController damageCtrl = TextEditingController(text: '');
  TextEditingController rtd1 = TextEditingController(text: '');
  TextEditingController rtd2 = TextEditingController(text: '');
  List<TextEditingController> remarksControllers = [];
  List<TextEditingController> snControllers = [];
  List<TextEditingController> rtd1Controllers = [];
  List<TextEditingController> rtd2Controllers = [];

  SwiperController swiperController = SwiperController();

  Map<int, TireDamageAi> aiResults = {};
  Map<int, bool> loadingAI = {};
  Map<int, double> imageWidths = {};
  Map<int, double> imageHeights = {};

  List<String>? _ratingCache;
  List<dynamic>? _damageCache;

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
  bool _listenerAdded = false;
  int checkAmount = 0;
  int selectedRoute = 0;
  List<List<int>> inspectRoute = [
    [0, 1, 2, 3, 4, 5],
    [0, 2, 3, 4, 5, 1],
    [1, 5, 4, 3, 2, 0],
  ];

  List<String> pressure = [
    '0',
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

  // List<String> damageType = [
  //   'Good Condition',
  //   'Accident',
  //   'Bead Crack',
  //   'Boulder',
  //   'Bulging',
  //   'Bead Damage',
  //   'Chaffer Separation',
  //   'Dog Bound',
  //   'Foreign Object',
  //   'Heat Separation',
  //   'Inner Linner Separation',
  //   'Impact',
  //   'Repair Failure',
  //   'Radial Crack',
  //   'Run Flat',
  //   'Sidewall Crack',
  //   'Sidewall Cut',
  //   'Sidewall Cut 2',
  //   'Sidewall Cut 3',
  //   'Sidewall Separation',
  //   'Shoulder Cut',
  //   'Shoulder Separation',
  //   'Tread Chipping',
  //   'Tread Chunking',
  //   'Tread Lifting',
  //   'Tread Cut',
  //   'Tread Cut Separation',
  //   'Worn Out',
  // ];

  List<Map<String, dynamic>> damageType = [];
  bool loadingDamages = true;

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

  List<String> rating = [
    'A',
    'B',
    'C',
    'X',
  ];

  List<String> pit = [];
  int selectedPit = -1;

  void showRimInspectionDialog(int tireIndex) {
    final originalList = position[tireIndex]['rimCondition'];

    /// 🔥 COPY DATA DULU (supaya Close tidak menyimpan)
    List<Map<String, dynamic>> tempList =
        originalList.map<Map<String, dynamic>>((item) {
      return {
        'title': item['title'],
        'condition': item['condition'],
        'remark': item['remark'],
      };
    }).toList();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, stState) {
            return AlertDialog(
              title: Text(
                'Periksa Kondisi : ',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    children: List.generate(tempList.length, (i) {
                      final rimItem = tempList[i];
                      final bool isGood = rimItem['condition'] == 'Good';
                      final bool isPoor = rimItem['condition'] == 'Poor';

                      return Container(
                        margin: EdgeInsets.only(bottom: 14),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isGood
                              ? Colors.green.withOpacity(0.12)
                              : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// TITLE
                            Text(
                              rimItem['title'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),

                            SizedBox(height: 10),

                            /// GOOD / POOR
                            Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      stState(() {
                                        rimItem['condition'] = 'Good';
                                      });
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isGood
                                            ? Colors.green
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'GOOD',
                                        style: TextStyle(
                                          color: isGood
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      stState(() {
                                        rimItem['condition'] = 'Poor';
                                      });
                                    },
                                    child: Container(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isPoor
                                            ? Colors.red
                                            : Colors.grey[300],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        'POOR',
                                        style: TextStyle(
                                          color: isPoor
                                              ? Colors.white
                                              : Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 10),

                            // Job Description
                            TextField(
                              controller: TextEditingController(
                                  text: rimItem['jobDescription'] ?? '')
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(
                                      offset: (rimItem['jobDescription'] ?? '')
                                          .length),
                                ),
                              style: TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                hintText: 'Job Description',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 1,
                              onChanged: (val) {
                                rimItem['jobDescription'] = val;
                              },
                            ),

                            SizedBox(height: 10),

                            /// REMARK
                            TextField(
                              controller: TextEditingController(
                                  text: rimItem['remark'] ?? '')
                                ..selection = TextSelection.fromPosition(
                                  TextPosition(
                                      offset: (rimItem['remark'] ?? '').length),
                                ),
                              style: TextStyle(fontSize: 12), // kecilkan font
                              decoration: InputDecoration(
                                hintText: 'Remark...',
                                isDense: true, // bikin lebih compact
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6, // lebih kecil
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              maxLines: 2, // supaya tidak terlalu tinggi
                              onChanged: (val) {
                                rimItem['remark'] = val;
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),

              /// 🔥 ACTION BUTTONS
              actions: [
                /// CLOSE (TIDAK SIMPAN)
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Close',
                    style: getRedTextStyle(fontWeight: w500),
                  ),
                ),

                /// SAVE (SIMPAN KE position)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      position[tireIndex]['rimCondition'] = tempList;
                    });

                    Navigator.pop(context);
                  },
                  child: Text(
                    'Save',
                    style: getWhiteTextStyle(fontWeight: w500),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    idSite = homeState.currentSiteId;
    _loadDamages();

    super.initState();
    requestPlacePermission();

    context.read<BluetoothOnOffCubit>().checkBluetoothStatus();
    final connectedCubit = context.read<ConnectedDevicesCubit>();
    log('connected cubit : $connectedCubit');
    connectedCubit.fetchConnectedDevices(); // HANYA MEMULAI fetch

    // callTires();
    WidgetsBinding.instance.addObserver(this);
    getUser();
  }

  Future<void> loadPreviousRating(
      int index, String unit, String kunciTire) async {
    print('load previous rating unit : $unit');
    try {
      final snapshot = await firestore
          .collection('tire_inspection')
          .where('unit', isEqualTo: unit) // ✅ FILTER UNIT
          .orderBy('tanggal', descending: true)
          .limit(1) // ✅ hanya dokumen terbaru unit itu
          .get();

      log('load previous rating : ${snapshot.docs}');

      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;

      final List<dynamic> posisiList = doc['posisi'];

      for (final pos in posisiList) {
        if (pos['kunci_tire'] == kunciTire) {
          final prevRating = pos['rating'];

          if (prevRating != null) {
            setState(() {
              position[index]['rating'] =
                  prevRating is String ? prevRating : [prevRating];
              position[index]['prevRating'] =
                  prevRating is String ? prevRating : [prevRating];
            });

            log('AUTO RATING FOUND: $prevRating');
            return;
          }
        }
      }
    } catch (e) {
      log('loadPreviousRating error: $e');
    }
  }

  Future<void> loadPreviousDamage(
      int index, String unit, String kunciTire) async {
    print('load previous damage unit : $unit');
    try {
      final snapshot = await firestore
          .collection('tire_inspection')
          .where('unit', isEqualTo: unit) // ✅ FILTER UNIT
          .orderBy('tanggal', descending: true)
          .limit(1) // ✅ hanya dokumen terbaru unit itu
          .get();

      log('load previous damage : ${snapshot.docs}');

      if (snapshot.docs.isEmpty) return;

      final doc = snapshot.docs.first;

      final List<dynamic> posisiList = doc['posisi'];

      for (final pos in posisiList) {
        if (pos['kunci_tire'] == kunciTire) {
          final prevDamage = pos['damageTire'];
          final prevRemarks = pos['remarks'];

          if (prevDamage != null) {
            setState(() {
              position[index]['damageTire'] =
                  prevDamage is List ? prevDamage : [prevDamage];
            });

            log('AUTO DAMAGE FOUND: $prevDamage');
            return;
          }

          if (prevRemarks != null && prevRemarks != '') {
            setState(() {
              position[index]['remarks'] = prevRemarks;
            });

            log('AUTO REMARKS FOUND: $prevRemarks');
            return;
          }
        }
      }
    } catch (e) {
      log('loadPreviousDamage error: $e');
    }
  }

  // Future<void> _loadDamages() async {
  //   try {
  //     final query =
  //         await firestore.collection('list_tire_damage_inspection').get();

  //     final docs = query.docs.where((doc) {
  //       return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(doc.id);
  //     }).toList();

  //     docs.sort((a, b) => b.id.compareTo(a.id));

  //     final latestDoc = docs.first;

  //     final data = latestDoc.data();

  //     log('docs luka ban : $data');

  //     if (data != null && data['damages'] != null) {
  //       final List<dynamic> raw = data['damages'];

  //       List<Map<String, dynamic>> sortedList =
  //           raw.map<Map<String, dynamic>>((e) {
  //         return Map<String, dynamic>.from(e);
  //       }).toList();

  //       sortedList.sort((a, b) {
  //         final aRemark = (a['remark'] ?? '').toString().toLowerCase();
  //         final bRemark = (b['remark'] ?? '').toString().toLowerCase();

  //         final aGood = aRemark.contains('good');
  //         final bGood = bRemark.contains('good');

  //         if (aGood && !bGood) return -1;
  //         if (!aGood && bGood) return 1;

  //         return aRemark.compareTo(bRemark);
  //       });

  //       setState(() {
  //         damageType = sortedList;
  //         loadingDamages = false;
  //       });
  //     } else {
  //       setState(() {
  //         loadingDamages = false;
  //       });
  //     }
  //   } catch (e) {
  //     debugPrint('Error load damages: $e');

  //     setState(() {
  //       loadingDamages = false;
  //     });
  //   }
  // }

  Future<void> _loadDamages() async {
    try {
      Map<String, dynamic>? data;
      final sisIdSite = await getIdSiteSIS();
      final isSisIdSite = sisIdSite.any((site) => site.idSite == idSite);

      if (isSisIdSite) {
        final doc = await firestore
            .collection('list_tire_damage_inspection')
            .doc('sis062026')
            .get();

        if (doc.exists) {
          data = doc.data();
        }
      } else {
        final query =
            await firestore.collection('list_tire_damage_inspection').get();

        final docs = query.docs.where((doc) {
          return RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(doc.id);
        }).toList();

        docs.sort((a, b) => b.id.compareTo(a.id));

        if (docs.isNotEmpty) {
          data = docs.first.data();
        }
      }

      log('docs luka ban : $data');

      if (data != null && data['damages'] != null) {
        final List<dynamic> raw = data['damages'];

        List<Map<String, dynamic>> sortedList =
            raw.map<Map<String, dynamic>>((e) {
          return Map<String, dynamic>.from(e);
        }).toList();

        sortedList.sort((a, b) {
          final aRemark = (a['remark'] ?? '').toString().toLowerCase();
          final bRemark = (b['remark'] ?? '').toString().toLowerCase();

          final aGood = aRemark.contains('good');
          final bGood = bRemark.contains('good');

          if (aGood && !bGood) return -1;
          if (!aGood && bGood) return 1;

          return aRemark.compareTo(bRemark);
        });

        setState(() {
          damageType = sortedList;
          loadingDamages = false;
        });
      } else {
        setState(() {
          loadingDamages = false;
        });
      }
    } catch (e) {
      debugPrint('Error load damages: $e');

      setState(() {
        loadingDamages = false;
      });
    }
  }

  getUser() async {
    user = await getUserPreferences();
    log('username : ${user}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    idUnit.dispose();
    hmUnit.dispose();
    pressureCtrl.dispose();
    remarksCtrl.dispose();
    damageCtrl.dispose();
    rtd1.dispose();
    rtd2.dispose();

    for (final controller in remarksControllers) {
      controller.dispose();
    }

    for (final controller in snControllers) {
      controller.dispose();
    }

    for (final controller in rtd1Controllers) {
      controller.dispose();
    }

    for (final controller in rtd2Controllers) {
      controller.dispose();
    }

    swiperController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        dataUnit = args as Map<String, dynamic>;
        log('TireInspectionPage: dataUnit berhasil diambil -> $dataUnit');

        // Panggil callTires() setelah dataUnit pasti terisi
        callTires();
      } else {
        log('TireInspectionPage: ERROR! Argumen navigasi null.');
      }

      _isInit = false; // Set flag agar tidak dijalankan lagi
    }
  }

  List<BluetoothDevice> devices = [];
  String tmpPressure = '';
  final Box<TireInspectPictureEntity> imageBox =
      store.box<TireInspectPictureEntity>();

  insertPit() {
    setState(() {
      // if (idSite == '52') {
      //   pit.add('Utara');
      //   pit.add('Selatan');
      //   pit.add('RML');
      //   pit.add('WS');
      // }
    });
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

  Future<void> _analyzeDamageWithAI(int index) async {
    if (loadingAI[index] == true) return;

    final hasNetwork = await _hasNetworkConnection();
    if (!hasNetwork) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Tidak ada koneksi jaringan. Analisa AI hanya dapat digunakan saat online.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    final images = position[index]['image'] as List<dynamic>?;
    if (images == null || images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please take a picture first.'),
        ),
      );
      return;
    }

    final rawImage = images.first.toString();
    final imagePath = rawImage.split('|').first;
    final imageFile = File(imagePath);

    if (!await imageFile.exists()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Image file was not found. Please take a new picture.'),
        ),
      );
      return;
    }

    setState(() {
      loadingAI[index] = true;
      aiResults.remove(index);
    });

    try {
      final bytes = await imageFile.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);
      final base64Image = base64Encode(bytes);
      final token = await ApiService.getValidToken();
      final result = await ApiService.postPredictImageAI(
        token,
        base64Image,
      );

      if (result == null) {
        throw Exception('AI analysis returned an empty result.');
      }

      if (!mounted) return;
      setState(() {
        imageWidths[index] = decodedImage.width.toDouble();
        imageHeights[index] = decodedImage.height.toDouble();
        aiResults[index] = result;
      });

      log('tire damage ai : $result');
    } catch (e) {
      log('analyze tire damage ai error : $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text('Failed to analyze damage with AI: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          loadingAI[index] = false;
        });
      }
    }
  }

  void callTires() async {
    String userAccessId = homeState.userAccessId.value;
    if (mounted) {
      if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
        idUnit.text = dataUnit['unitNumber'];
        // hmUnit.text = dataUnit['hm'];
        context.read<TireBloc>().add(GetUnitTiresEvent(
            idSite: idSite, unitNumber: dataUnit['unitNumber']));
      }
    }

    insertPit();
  }

  void handleDataRemarks(String remarks, int index) {
    this.remarks = remarks;
    print('remarks (pgd) : ${this.remarks}');
  }

  void handleDataRTD(String rtd, int index) {
    this.rtd = rtd;
    print('remarks (pgd) : ${this.remarks}');
  }

  void applyPressureData(String pressureValue) {
    setState(() {
      final firstNumber = pressureValue;

      if (checkAmount < position.length) {
        int targetIndex = inspectRoute[selectedRoute][checkAmount];
        log('target position : ${targetIndex}');
        log('target pressure : ${firstNumber}');

        // Update Map di index tersebut
        position[targetIndex]["pressure"] = firstNumber;

        checkAmount++;
      }
    });
  }

  Future<bool> _hasNetworkConnection() async {
    try {
      final ConnectivityResult result =
          await Connectivity().checkConnectivity();

      return result != ConnectivityResult.none;
    } catch (e, stackTrace) {
      log(
        'connectivity check error: $e',
        stackTrace: stackTrace,
      );

      // Jika pengecekan koneksi gagal, gunakan jalur offline agar Save
      // tidak berhenti menunggu timeout jaringan.
      return false;
    }
  }

  bool _isPitRequired() {
    return idSite == bmbsitarum.idSite ||
        idSite == bmbhauling.idSite ||
        idSite == bmbtabuhan.idSite ||
        idSite == bibkgb.idSite ||
        idSite == bibgh.idSite;
  }

  String _selectedPitValue() {
    if (!_isPitRequired()) {
      return 'Default';
    }

    if (selectedPit < 0 || selectedPit >= pit.length) {
      return 'Default';
    }

    return pit[selectedPit];
  }

  String _sanitizeDocumentIdPart(dynamic value) {
    final normalized = value?.toString().trim() ?? '';

    return normalized
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
  }

  String _buildInspectionDocumentId(DateTime date, String unitNumber) {
    final datePart =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    return 'inspection_${_sanitizeDocumentIdPart(idSite)}_'
        '${_sanitizeDocumentIdPart(unitNumber)}_$datePart';
  }

  String _buildDailyPressureDocumentId(DateTime date, String unitNumber) {
    final datePart =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

    return 'daily_${_sanitizeDocumentIdPart(idSite)}_'
        '${_sanitizeDocumentIdPart(unitNumber)}_$datePart';
  }

  bool _isPositionEmpty(Map<String, dynamic> item) {
    final damage = item['damageTire'];
    final hasDamage = damage is List &&
        damage.any(
          (value) => value != null && value.toString().trim().isNotEmpty,
        );

    return (item['pressure']?.toString().trim().isEmpty ?? true) &&
        !hasDamage &&
        (item['adjusmentPressure']?.toString().trim().isEmpty ?? true) &&
        (item['rtd1']?.toString().trim().isEmpty ?? true) &&
        (item['rtd2']?.toString().trim().isEmpty ?? true) &&
        (item['rating']?.toString().trim().isEmpty ?? true) &&
        (item['sn']?.toString().trim().isEmpty ?? true) &&
        (item['remarks']?.toString().trim().isEmpty ?? true);
  }

  List<int> _activePositionIndexes() {
    final indexes = <int>[];

    for (int i = 0; i < position.length; i++) {
      if (!_isPositionEmpty(position[i])) {
        indexes.add(i);
      }
    }

    // Pertahankan seluruh posisi jika semuanya masih kosong agar struktur
    // posisi ban tetap konsisten dengan data unit.
    if (indexes.isEmpty) {
      return List<int>.generate(position.length, (index) => index);
    }

    return indexes;
  }

  String? _localImagePathAt(int positionIndex) {
    if (positionIndex < 0 || positionIndex >= position.length) {
      return null;
    }

    try {
      final images = position[positionIndex]['image'];
      if (images is! List || images.isEmpty) {
        return null;
      }

      final raw = images.first?.toString() ?? '';
      if (raw.trim().isEmpty) {
        return null;
      }

      final path = raw.split('|').first.trim();
      return path.isEmpty ? null : path;
    } catch (e, stackTrace) {
      log(
        'parse local image error: $e',
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  String _defaultDamageRemark() {
    if (damageType.isNotEmpty) {
      final remark = damageType.first['remark']?.toString().trim() ?? '';
      if (remark.isNotEmpty) {
        return remark;
      }
    }

    return 'Good Condition';
  }

  List<Map<String, dynamic>> _buildInspectionPositions(
    TiresLoadedState state,
    List<int> activeIndexes,
  ) {
    final result = <Map<String, dynamic>>[];

    for (final index in activeIndexes) {
      if (index < 0 ||
          index >= position.length ||
          index >= state.units.length) {
        continue;
      }

      final item = position[index];
      final unit = state.units[index];
      final localImagePath = _localImagePathAt(index);

      final rawDamage = item['damageTire'];
      final damages = rawDamage is List
          ? rawDamage
              .where(
                (value) => value != null && value.toString().trim().isNotEmpty,
              )
              .map((value) => value.toString().trim())
              .toList()
          : <String>[];

      if (damages.isEmpty) {
        damages.add(_defaultDamageRemark());
      }

      final typedRemarks = item['remarks']?.toString().trim() ?? '';

      result.add({
        'position': item['position'] ?? index + 1,
        'pressure': item['pressure']?.toString() ?? '',
        'adjusmentPressure': item['adjusmentPressure']?.toString() ?? '',
        'rating': item['rating']?.toString().trim().isNotEmpty == true
            ? item['rating'].toString().trim()
            : 'A',
        'rtd1': item['rtd1']?.toString() ?? '',
        'rtd2': item['rtd2']?.toString() ?? '',
        'sn': item['sn']?.toString().trim().isNotEmpty == true
            ? item['sn'].toString().trim()
            : unit.sn ?? '',
        'remarks': typedRemarks.isNotEmpty ? typedRemarks : damages.first,
        'damageTire': damages,
        'rimCondition': item['rimCondition'] ?? [],
        'idUnit': item['idUnit'],
        'idInventory': item['idInventory'],
        'tireSize': item['tireSize'],
        'kunci_tire': unit.kunciTire,
        'hm': hmUnit.text,
        'images': [],
        'imagePending': localImagePath != null,
        'tireAccessories': item['tireAccessories'] ?? [],
        'brand': unit.brand,
        'pattern': unit.pattern,
      });
    }

    return result;
  }

  List<Map<String, dynamic>> _buildDailyPressurePositions(
    List<int> activeIndexes,
    DateTime date,
  ) {
    final formattedDate = '${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}'
        '${(date.year % 100).toString().padLeft(2, '0')}';

    final result = <Map<String, dynamic>>[];

    for (final index in activeIndexes) {
      if (index < 0 || index >= position.length) {
        continue;
      }

      final item = position[index];
      final rawDamage = item['damageTire'];
      final damages = rawDamage is List
          ? rawDamage
              .where(
                (value) => value != null && value.toString().trim().isNotEmpty,
              )
              .map((value) => value.toString().trim())
              .toList()
          : <String>[];

      result.add({
        'pos': '${item['position'] ?? index + 1}',
        'pressure': item['pressure']?.toString().trim().isNotEmpty == true
            ? item['pressure'].toString().trim()
            : '0',
        'rating': item['rating']?.toString().trim().isNotEmpty == true
            ? item['rating'].toString().trim()
            : 'A',
        'adjusmentPressure':
            item['adjusmentPressure']?.toString().trim().isNotEmpty == true
                ? item['adjusmentPressure'].toString().trim()
                : '0',
        'luka': damages.isEmpty ? [_defaultDamageRemark()] : damages,
        'idUnit': item['idUnit'],
        'idInventory': item['idInventory'],
        'tireSize': item['tireSize'],
        'idDaily': '${item['idUnit'] ?? ''}${index + 1}$formattedDate$idSite',
        'tireAccessories': item['tireAccessories'] ?? [],
        'rtd1': item['rtd1']?.toString() ?? '',
        'rtd2': item['rtd2']?.toString() ?? '',
      });
    }

    return result;
  }

  Map<String, dynamic> _buildInspectionData(
    TiresLoadedState state,
    DateTime now,
    List<int> activeIndexes, {
    required bool savedOffline,
  }) {
    final firstUnit = state.units.first;
    final hari =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final jam =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return {
      'id': const Uuid().v4(),
      'id_site': idSite,
      'user': user['username'] ?? 'username',
      'user_email': auth.currentUser?.email ?? '',
      'unit': dataUnit['unitNumber'] ?? firstUnit.unitNumber ?? '',
      'kunci_unit': firstUnit.kunciUnit ?? '',
      'hm': hmUnit.text,
      'hari': hari,
      'jam': jam,
      'tanggal': now.toIso8601String(),
      'pit': _selectedPitValue(),
      'posisi': _buildInspectionPositions(state, activeIndexes),
      'brand': firstUnit.brand,
      'pattern': firstUnit.pattern,
      'savedOffline': savedOffline,
      'syncStatus': savedOffline ? 'pending' : 'synced',
      'lastLocalUpdate': now.toIso8601String(),
    };
  }

  Map<String, dynamic> _buildDailyPressureData(
    DateTime now,
    List<int> activeIndexes, {
    required bool savedOffline,
  }) {
    final hari =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final jam =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    return {
      'idSite': idSite,
      'user': user['username'] ?? auth.currentUser?.email ?? 'username',
      'tanggal': now.toIso8601String(),
      'hari': hari,
      'jam': jam,
      'unit': idUnit.text,
      'hm': hmUnit.text,
      'posisi': _buildDailyPressurePositions(activeIndexes, now),
      'pit': _selectedPitValue(),
      'savedOffline': savedOffline,
      'syncStatus': savedOffline ? 'pending' : 'synced',
      'lastLocalUpdate': now.toIso8601String(),
    };
  }

  void _queuePendingImages(
    String inspectionDocumentId,
    List<int> activeIndexes,
  ) {
    for (final index in activeIndexes) {
      final localImagePath = _localImagePathAt(index);
      if (localImagePath == null) {
        continue;
      }

      try {
        UploadQueueService.to.addPending(
          docId: inspectionDocumentId,
          filePath: localImagePath,
          posisiIndex: index,
        );
      } catch (e, stackTrace) {
        log(
          'add pending image error: $e',
          stackTrace: stackTrace,
        );
      }
    }
  }

  void _saveInspectionOffline(TiresLoadedState state) {
    final now = DateTime.now();
    final firstUnit = state.units.first;
    final unitNumber =
        dataUnit['unitNumber']?.toString() ?? firstUnit.unitNumber ?? '';
    final activeIndexes = _activePositionIndexes();

    final inspectionDocumentId = _buildInspectionDocumentId(now, unitNumber);
    final dailyDocumentId = _buildDailyPressureDocumentId(now, unitNumber);

    final inspectionData = _buildInspectionData(
      state,
      now,
      activeIndexes,
      savedOffline: true,
    );

    final dailyPressureData = _buildDailyPressureData(
      now,
      activeIndexes,
      savedOffline: true,
    );

    // Jangan await write Firestore saat offline. Perubahan langsung masuk
    // antrean lokal dan akan dikirim ketika koneksi tersedia kembali.
    unawaited(
      firestore
          .collection('tire_inspection')
          .doc(inspectionDocumentId)
          .set(
            inspectionData,
            SetOptions(merge: true),
          )
          .catchError((Object error, StackTrace stackTrace) {
        log(
          'offline tire inspection write error: $error',
          stackTrace: stackTrace,
        );
      }),
    );

    unawaited(
      firestore
          .collection('daily_pressure')
          .doc(dailyDocumentId)
          .set(
            dailyPressureData,
            SetOptions(merge: true),
          )
          .catchError((Object error, StackTrace stackTrace) {
        log(
          'offline daily pressure write error: $error',
          stackTrace: stackTrace,
        );
      }),
    );

    _queuePendingImages(inspectionDocumentId, activeIndexes);
  }

  Future<void> _saveInspectionOnline(TiresLoadedState state) async {
    final now = DateTime.now();
    final firstUnit = state.units.first;
    final unitNumber =
        dataUnit['unitNumber']?.toString() ?? firstUnit.unitNumber ?? '';
    final hari =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final activeIndexes = _activePositionIndexes();

    final inspectionQuery = await firestore
        .collection('tire_inspection')
        .where('hari', isEqualTo: hari)
        .where('unit', isEqualTo: unitNumber)
        .limit(1)
        .get();

    final inspectionDocumentId = inspectionQuery.docs.isNotEmpty
        ? inspectionQuery.docs.first.id
        : _buildInspectionDocumentId(now, unitNumber);

    await firestore.collection('tire_inspection').doc(inspectionDocumentId).set(
          _buildInspectionData(
            state,
            now,
            activeIndexes,
            savedOffline: false,
          ),
          SetOptions(merge: true),
        );

    _queuePendingImages(inspectionDocumentId, activeIndexes);

    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final dailyQuery = await firestore
        .collection('daily_pressure')
        .where('unit', isEqualTo: unitNumber)
        .where(
          'tanggal',
          isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
        )
        .where(
          'tanggal',
          isLessThanOrEqualTo: endOfDay.toIso8601String(),
        )
        .limit(1)
        .get();

    final dailyDocumentId = dailyQuery.docs.isNotEmpty
        ? dailyQuery.docs.first.id
        : _buildDailyPressureDocumentId(now, unitNumber);

    await firestore.collection('daily_pressure').doc(dailyDocumentId).set(
          _buildDailyPressureData(
            now,
            activeIndexes,
            savedOffline: false,
          ),
          SetOptions(merge: true),
        );
  }

  Future<void> _handleSaveTireInspection(TiresLoadedState state) async {
    if (isLoadingSave || state.units.isEmpty) {
      return;
    }

    final currentHm =
        double.tryParse(state.units.first.hm?.toString() ?? '0') ?? 0;
    final newHm = double.tryParse(hmUnit.text.trim()) ?? 0;

    if (currentHm > newHm) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SMU/HM tidak bisa berkurang',
            style: getWhiteTextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if ((newHm - currentHm) > 1000) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Perubahan SMU/HM tidak bisa lebih dari 1000',
            style: getWhiteTextStyle(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isPitRequired() && (selectedPit < 0 || selectedPit >= pit.length)) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Please select location of unit first!',
            style: getWhiteTextStyle(),
          ),
        ),
      );
      return;
    }

    final errorsRtd = <String>[];
    final errorsRating = <String>[];

    const ratingScore = {
      'A': 4,
      'B': 3,
      'C': 2,
      'X': 1,
    };

    final validationLength = state.units.length < position.length
        ? state.units.length
        : position.length;

    for (int i = 0; i < validationLength; i++) {
      final unit = state.units[i];

      final actualRtd = double.tryParse(unit.rtd?.toString() ?? '0') ?? 0;
      final actualOtd = double.tryParse(unit.otd?.toString() ?? '0') ?? 0;

      final inputRtd = i < rtd1Controllers.length
          ? double.tryParse(rtd1Controllers[i].text) ?? 0
          : double.tryParse(position[i]['rtd1']?.toString() ?? '0') ?? 0;
      final inputOtd = i < rtd2Controllers.length
          ? double.tryParse(rtd2Controllers[i].text) ?? 0
          : double.tryParse(position[i]['rtd2']?.toString() ?? '0') ?? 0;

      if (inputRtd > actualRtd) {
        errorsRtd.add(
          'Posisi ${unit.posisi}: RTD input ($inputRtd) melebihi RTD aktual ($actualRtd).',
        );
      }

      if (inputOtd > actualOtd) {
        errorsRtd.add(
          'Posisi ${unit.posisi}: OTD input ($inputOtd) melebihi OTD aktual ($actualOtd).',
        );
      }

      final actualRating =
          position[i]['prevRating']?.toString().toUpperCase().trim() ?? '';
      final inputRating =
          position[i]['rating']?.toString().toUpperCase().trim() ?? '';

      if (actualRating.isNotEmpty) {
        final actualScore = ratingScore[actualRating] ?? 0;
        final inputScore = ratingScore[inputRating] ?? 0;

        if (inputScore > actualScore) {
          errorsRating.add(
            'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
          );
        }
      }
    }

    if (errorsRtd.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          content: Text(
            errorsRtd.join('\n'),
            style: getWhiteTextStyle(),
          ),
        ),
      );
      return;
    }

    if (errorsRating.isNotEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 6),
          content: Text(
            errorsRating.join('\n'),
            style: getWhiteTextStyle(),
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() {
      isLoadingSave = true;
    });

    try {
      final hasNetwork = await _hasNetworkConnection();

      if (!hasNetwork) {
        _saveInspectionOffline(state);

        if (!mounted) return;

        setState(() {
          isLoadingSave = false;
          isSaved = true;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            content: Text(
              'Tidak ada jaringan. Data tersimpan di perangkat dan akan disinkronkan otomatis saat koneksi tersedia.',
              style: getWhiteTextStyle(),
            ),
          ),
        );

        Navigator.pop(context, true);
        return;
      }

      await _saveInspectionOnline(state).timeout(
        const Duration(seconds: 15),
      );

      if (!mounted) return;

      setState(() {
        isLoadingSave = false;
        isSaved = true;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successful save data, please check in home page',
            style: getWhiteTextStyle(),
          ),
          backgroundColor: green00968A,
        ),
      );

      Navigator.pop(context, true);
    } on TimeoutException catch (e, stackTrace) {
      log(
        'save timeout: $e',
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        isLoadingSave = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
          content: Text(
            'Jaringan terdeteksi tetapi proses online melebihi 15 detik. Periksa kualitas internet lalu coba kembali.',
            style: getWhiteTextStyle(),
          ),
        ),
      );
    } catch (e, stackTrace) {
      log(
        'save tire inspection error: $e',
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        isLoadingSave = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Failed to save data. Please try again.',
            style: getWhiteTextStyle(),
          ),
        ),
      );
    } finally {
      if (mounted && isLoadingSave) {
        setState(() {
          isLoadingSave = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    pit.clear();
    // if (idSite == '52') {
    //   pit.add('Utara');
    //   pit.add('Selatan');
    //   pit.add('RML');
    //   pit.add('WS');
    // }
    switch (idSite) {
      case '52':
        pit.add('Utara');
        pit.add('Selatan');
        pit.add('RML');
        pit.add('WS');
        break;
      case '137':
        pit.add('Japun');
        pit.add('PCE');
        break;
      case '35':
        pit.add('Tabuhan');
        pit.add('EBL');
        pit.add('Workshop');
        break;
      case '65':
        pit.add('Room B1 Selatan');
        pit.add('TIA');
        pit.add('Serongga');
        pit.add('CSA Selatan');
        pit.add('WS');
        break;
      case '166':
        pit.add('WS');
        pit.add('Pondok Operator');
        pit.add('CSA Bagaspati');
        pit.add('Pit Stop Toll');
        break;
    }
    print('dipanggil (pgd)');
    dataUnit =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Text(
            'Tire Inspection',
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
                    pushReplace(context, HomePage.routeName);
                  } else {
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
            final firstUnit = state.units.first;
            final currentUnitNumber = firstUnit.unitNumber ?? '';

            if (_hmInitializedForUnit != currentUnitNumber) {
              hmUnit.text = idSite == bmbhauling.idSite
                  ? ''
                  : firstUnit.hm?.toString() ?? '';

              _hmInitializedForUnit = currentUnitNumber;
            }

            position.clear();

            for (int i = 0; i < state.units.length; i++) {
              final unit = state.units[i];
              for (int i = 0; i < position.length; i++) {
                final unit = state.units[i];

                if (unit.kunciTire != null) {
                  loadPreviousRating(
                      i, unit.unitNumber ?? '', unit.kunciTire ?? '');
                  loadPreviousDamage(
                      i, unit.unitNumber ?? '', unit.kunciTire ?? '');
                }
              }
              remarksControllers.add(TextEditingController(text: ''));
              snControllers.add(TextEditingController(text: ''));
              rtd1Controllers.add(
                TextEditingController(text: unit.rtd?.toString() ?? ''),
              );

              rtd2Controllers.add(
                TextEditingController(text: unit.otd?.toString() ?? ''),
              );
              position.add({
                'position': i + 1,
                'pressure': '',
                'adjusmentPressure': '',
                'hm': '',
                'damageTire': [],
                'rtd1': unit.rtd?.toString() ?? '',
                'rtd2': unit.otd?.toString() ?? '',
                'remarks': '',
                'sn': unit.sn,
                'rating': '',
                'prevRating': '',
                'image': [],
                'idInventory': unit.idinventory,
                'idUnit': unit.idUnit,
                'tireSize': unit.size,
                // 'condition': [
                //   {'name': 'Reseal Oring', 'checked': false},
                //   {'name': 'Rim Condition', 'checked': false},
                //   {'name': 'Inflate Tire', 'checked': false},
                //   {'name': 'Lock Driver', 'checked': false},
                //   {'name': 'Slide Lock', 'checked': false},
                //   {'name': 'Valve Cap', 'checked': false},
                //   {'name': 'Valve Protector', 'checked': false},
                //   {'name': 'Stud and Nut', 'checked': false},
                // ],
                'rimCondition': [
                  {
                    'title': 'RIM BASE',
                    'jobDescription': '',
                    'condition': 'Good',
                    'remark': ''
                  },
                  {
                    'title': 'FLANGE',
                    'jobDescription': '',
                    'condition': 'Good',
                    'remark': ''
                  },
                  {
                    'title': 'LOCK RING',
                    'jobDescription': '',
                    'condition': 'Good',
                    'remark': ''
                  },
                  {
                    'title': 'VALVE (TERPASANG/TIDAK TERPASANG)',
                    'jobDescription': '',
                    'condition': 'Good',
                    'remark': ''
                  },
                  {
                    'title': 'CORE VALVE',
                    'jobDescription': '',
                    'condition': 'Good',
                    'remark': ''
                  },
                  {
                    'title': 'NUT DAN STUD RODA',
                    'jobDescription': '',
                    'condition': 'Good',
                    'remark': ''
                  },
                ],
                'tireAccessories': []
              });
            }
            log('message position tire inspect : ${position}');
          }
        },
        builder: (context, state) {
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
                    (pit.isNotEmpty)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.ev_station,
                                size: 38,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(
                                'Unit Location',
                                style: getBlackTextStyle(
                                    fontSize: 18, fontWeight: w700),
                              ),
                            ],
                          )
                        : Container(),
                    SizedBox(
                      height: (pit.isNotEmpty) ? 24 : 0,
                    ),
                    (pit.isNotEmpty)
                        ? Center(
                            child: Wrap(
                              spacing: 8.0, // Jarak horizontal antar tombol
                              children: pit.map((e) {
                                final pitIndex = pit.indexOf(e);
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (selectedPit == pitIndex)
                                        ? Colors.orange
                                        : greyF7F8F9,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      selectedPit = pitIndex;
                                    });
                                  },
                                  child: Text(
                                    e,
                                    style: (selectedPit == pitIndex)
                                        ? getWhiteTextStyle()
                                        : getBlackTextStyle(),
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        : Container(),
                    SizedBox(
                      height: (pit.isNotEmpty) ? 24 : 0,
                    ),
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
                                    (idSite == bmbhauling.idSite &&
                                            idSite == '1')
                                        ? 'KM Unit'
                                        : 'HM Unit',
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
                                  controller: hmUnit,
                                  isDecimalOnly: true,
                                  type: const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                  hint:
                                      'Fill ${idSite == bmbhauling.idSite ? 'KM' : 'HM'}',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    BlocBuilder<ConnectedDevicesCubit, ConnectedDevicesState>(
                      builder: (context, cState) {
                        // Asumsikan perangkat TPMS adalah yang terhubung jika statusnya Success
                        final isConnected =
                            cState is ConnectedDevicesLoadedState &&
                                cState.connectedDevices.isNotEmpty;

                        // Cari perangkat yang terhubung yang memiliki nama yang relevan
                        // (Anda harus menyesuaikan logika pencarian ini sesuai nama perangkat BT Anda)
                        final BluetoothDevice? connectedDevice = isConnected
                            ? cState.connectedDevices
                                .firstWhereOrNull((d) => d.advName.isNotEmpty)
                            : null;

                        final String buttonText = isConnected
                            ? 'Connected: ${connectedDevice?.advName ?? connectedDevice?.remoteId.str}'
                            : 'Scan Devices';

                        return ButtonWidget(
                          // Warna tombol berdasarkan status koneksi
                          color: isConnected ? green00968A : Colors.blue,
                          name: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth,
                                color: white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                buttonText,
                                style: getWhiteTextStyle(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          function: () async {},
                        );
                      },
                    ),
                    BlocListener<BluetoothOnOffCubit, BluetoothOnOffState>(
                      listener: (context, onOffState) {
                        if (onOffState is BluetoothOnState) {
                          context
                              .read<ConnectedDevicesCubit>()
                              .fetchConnectedDevices();
                        }
                      },
                      child: BlocConsumer<ConnectedDevicesCubit,
                          ConnectedDevicesState>(
                        listener: (context, state) {
                          if (state is ConnectedDevicesLoadedState &&
                              state.connectedDevices.isNotEmpty) {
                            context
                                .read<DiscoverServicesCubit>()
                                .discoverServices(state.connectedDevices.first);
                          }
                        },
                        builder: (context, state) {
                          if (state is ConnectedDevicesLoadedState) {
                            // return _buildConnectedDeviceUI(
                            //     state.connectedDevices);
                            if (state.connectedDevices.isNotEmpty) {
                              BlocProvider.of<DiscoverServicesCubit>(
                                context,
                              ).discoverServices(state.connectedDevices.first);
                            }
                            return BlocConsumer<DiscoverServicesCubit,
                                DiscoverServiceState>(
                              listener: (context, discoverState) {
                                if (discoverState is ServicesLoadedState) {
                                  final services = discoverState.services;
                                  log('services pgd : $services');

                                  if (!_listenerAdded) {
                                    _listenerAdded = true;
                                    for (BluetoothService service in services) {
                                      for (BluetoothCharacteristic characteristic
                                          in service.characteristics) {
                                        if (characteristic.properties.notify) {
                                          characteristic.onValueReceived
                                              .listen((value) {
                                            final notifInString =
                                                String.fromCharCodes(value);
                                            log("angin bergejolak: $notifInString");

                                            debugPrint(
                                              "debugBluetoothNotification*************",
                                            );
                                            debugPrint(
                                              "debugBluetoothNotification: charName: ${BluetoothUtils.getBluetoothChar(characteristic.characteristicUuid.str)}",
                                            );

                                            debugPrint(
                                              "notifhohoho: stringNotif: $notifInString",
                                            );
                                            setState(() {
                                              String press = '';

                                              if (notifInString.contains('|')) {
                                                int floorPressure =
                                                    double.parse(
                                                  notifInString.split(
                                                    '|',
                                                  )[0],
                                                ).floor();

                                                // int floorTemperature =
                                                //     double.parse(
                                                //       notifInString.split(
                                                //         '|',
                                                //       )[1],
                                                //     ).floor();
                                                // temperature = floorTemperature
                                                //     .toString();
                                                applyPressureData(
                                                    floorPressure.toString());
                                              } else {
                                                int floorPressure =
                                                    double.parse(
                                                  notifInString,
                                                ).floor();
                                                press.toString();
                                                applyPressureData(
                                                    floorPressure.toString());
                                              }
                                            });

                                            debugPrint(
                                              "debugBluetoothNotification*************",
                                            );
                                          });

                                          characteristic
                                              .setNotifyValue(true); // WAJIB
                                        }
                                      }
                                    }
                                  }
                                }
                              },
                              builder: (context, discoverState) {
                                if (discoverState is ErrorLoadingServiceState) {
                                  return Center(child: Text('Error'));
                                }
                                return Container();
                              },
                            );
                          }
                          return CircularProgressIndicator();
                        },
                      ),
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
                          if (snControllers[index].text.isEmpty) {
                            snControllers[index].text = unit.sn ?? '';
                          }

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6),
                                        child: Divider(
                                          thickness: 1.5,
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
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
                                                MainAxisAlignment.spaceBetween,
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
                                                MainAxisAlignment.spaceBetween,
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
                                                MainAxisAlignment.spaceBetween,
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
                                                MainAxisAlignment.spaceBetween,
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
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'RTD',
                                                style: getBlackTextStyle(
                                                    fontWeight: w700),
                                              ),
                                              Text(
                                                '${unit.rtd} / ${unit.otd}' ??
                                                    '',
                                                style: getBlackTextStyle(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6),
                                        child: Divider(
                                          thickness: 1.5,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: SizedBox(
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
                                                          padding:
                                                              EdgeInsets.all(
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
                                                                    height:
                                                                        16.0),
                                                                Column(),
                                                                Wrap(
                                                                  children:
                                                                      pressure.map(
                                                                          (ps) {
                                                                    final psIndex =
                                                                        pressure
                                                                            .indexOf(ps);
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
                                                                            Navigator.of(context).pop();
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
                                                                            type:
                                                                                TextInputType.number,
                                                                            hint: 'Input Manual'),
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
                                                                              position[index]['pressure'] = pressureCtrl.text;
                                                                            }
                                                                            pressureCtrl.clear();
                                                                            Navigator.of(context).pop();
                                                                          });
                                                                        },
                                                                        child: Text(
                                                                            'Submit'))
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        12.0),
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
                                                    backgroundColor:
                                                        Colors.blue,
                                                    shape:
                                                        RoundedRectangleBorder(
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
                                                        style:
                                                            getWhiteTextStyle(
                                                          fontSize: 24,
                                                          fontWeight: w700,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                          // adjusment pressure
                                          Expanded(
                                            child: SizedBox(
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
                                                          padding:
                                                              EdgeInsets.all(
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
                                                                    height:
                                                                        16.0),
                                                                Column(),
                                                                Wrap(
                                                                  children:
                                                                      pressure.map(
                                                                          (ps) {
                                                                    final psIndex =
                                                                        pressure
                                                                            .indexOf(ps);
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
                                                                            Navigator.of(context).pop();
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
                                                                            type:
                                                                                TextInputType.number,
                                                                            hint: 'Input Manual'),
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
                                                                              position[index]['adjusmentPressure'] = pressureCtrl.text;
                                                                            }
                                                                            pressureCtrl.clear();
                                                                            Navigator.of(context).pop();
                                                                          });
                                                                        },
                                                                        child: const Text(
                                                                            'Submit'))
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        12.0),
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
                                                    backgroundColor:
                                                        Colors.blue,
                                                    shape:
                                                        RoundedRectangleBorder(
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
                                                        style:
                                                            getWhiteTextStyle(
                                                          fontSize: 16,
                                                          fontWeight: w700,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 12,
                                      ),

                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 45,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            FocusScope.of(context).unfocus();
                                            // setState(() {
                                            //   selectedPosIndex = posIndex;
                                            // });

                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.all(20.0),
                                                    child:
                                                        SingleChildScrollView(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          Text(
                                                            'Choose Rating',
                                                            style: TextStyle(
                                                              fontSize: 24.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height: 16.0),
                                                          Column(),
                                                          Wrap(
                                                            children: rating
                                                                .map((rat) {
                                                              final ratingIndex =
                                                                  rating
                                                                      .indexOf(
                                                                          rat);
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            16,
                                                                        bottom:
                                                                            18),
                                                                child:
                                                                    ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .green),
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      position[index]
                                                                              [
                                                                              'rating'] =
                                                                          rat;
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    });
                                                                  },
                                                                  child: Text(
                                                                    rat,
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
                                                          SizedBox(
                                                              height: 12.0),
                                                          SizedBox(
                                                            width:
                                                                double.infinity,
                                                            child:
                                                                ElevatedButton(
                                                              onPressed: () {
                                                                pressureCtrl
                                                                    .clear();
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child:
                                                                  Text('Close'),
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
                                                    BorderRadius.circular(12),
                                              )),
                                          child: (position[index]['rating'] ==
                                                  '')
                                              ? Builder(builder: (context) {
                                                  position[index]['rating'] =
                                                      'A';
                                                  return Text(
                                                    'Rating A',
                                                    style: getWhiteTextStyle(),
                                                  );
                                                })
                                              : Text(
                                                  'Rating ${position[index]['rating']}',
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

                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: blue344BEF,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'Tire Damage',
                                          textAlign: TextAlign.start,
                                          style: getBlackTextStyle(
                                            fontSize: 12,
                                          ).copyWith(color: Colors.white),
                                        ),
                                      ),

                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (index == 0)
                                              log('luka map : ${position[index]['damageTire']}');
                                            FocusScope.of(context).unfocus();

                                            if (loadingDamages) {
                                              // Optional: kasih feedback kalau masih loading
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Sedang memuat daftar damage...')),
                                              );
                                              return;
                                            }

                                            if (damageType.isEmpty) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                    content: Text(
                                                        'Daftar damage kosong')),
                                              );
                                              return;
                                            }

                                            final List<dynamic>
                                                existingDamages =
                                                position[index]['damageTire'] ??
                                                    [];

                                            List<bool> checkedDamageValues;

                                            if (existingDamages.isEmpty ||
                                                existingDamages[0] == "") {
                                              print(
                                                  'exisitng damage empty true');
                                              // otomatis centang Good Condition jika belum ada damage
                                              checkedDamageValues =
                                                  damageType.map((damage) {
                                                final text = damage['remark']
                                                    .toString()
                                                    .toLowerCase()
                                                    .trim();
                                                return text == 'good' ||
                                                    text == 'good condition';
                                              }).toList();
                                            } else {
                                              print(
                                                  'exisitng damage empty false');
                                              // jika sudah ada data damage
                                              checkedDamageValues =
                                                  damageType.map((damage) {
                                                return existingDamages
                                                    .contains(damage['remark']);
                                              }).toList();
                                            }

                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            20.0),
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        const Text(
                                                          'Choose Damage Tire',
                                                          style: TextStyle(
                                                            fontSize: 24.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 12.0),
                                                        Expanded(
                                                          child:
                                                              SingleChildScrollView(
                                                            child: Column(
                                                              children:
                                                                  damageType.map(
                                                                      (damage) {
                                                                final dmgIndex =
                                                                    damageType
                                                                        .indexOf(
                                                                            damage);

                                                                // kalau tidak perlu skip index 0, hapus if ini
                                                                // if (dmgIndex == 0) return Container();

                                                                return StatefulBuilder(
                                                                  builder: (context,
                                                                      setState) {
                                                                    return CheckboxListTile(
                                                                      title: Text(
                                                                          damage[
                                                                              'remark']),
                                                                      value: checkedDamageValues[
                                                                          dmgIndex],
                                                                      onChanged:
                                                                          (bool?
                                                                              value) {
                                                                        setState(
                                                                            () {
                                                                          bool
                                                                              newValue =
                                                                              value ?? false;

                                                                          if (dmgIndex ==
                                                                              0) {
                                                                            // GOOD CONDITION dicentang
                                                                            checkedDamageValues =
                                                                                List<bool>.filled(checkedDamageValues.length, false);
                                                                            checkedDamageValues[0] =
                                                                                newValue;
                                                                          } else {
                                                                            // Damage lain dicentang
                                                                            checkedDamageValues[dmgIndex] =
                                                                                newValue;

                                                                            if (newValue) {
                                                                              // otomatis uncheck Good Condition
                                                                              checkedDamageValues[0] = false;
                                                                            }
                                                                          }
                                                                        });
                                                                      },
                                                                    );
                                                                  },
                                                                );
                                                              }).toList(),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 12.0),
                                                        Column(
                                                          children: [
                                                            const SizedBox(
                                                                height: 12),
                                                            SizedBox(
                                                              width: double
                                                                  .infinity,
                                                              child:
                                                                  ElevatedButton(
                                                                onPressed: () {
                                                                  damageCtrl
                                                                      .clear();
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child:
                                                                    const Text(
                                                                        'Close'),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 12),
                                                            SizedBox(
                                                              width: double
                                                                  .infinity,
                                                              child:
                                                                  ElevatedButton(
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green,
                                                                ),
                                                                onPressed: () {
                                                                  setState(
                                                                      () {}); // setState parent

                                                                  selectedDamage
                                                                      .clear();

                                                                  Map<String,
                                                                          int>
                                                                      ratingPriority =
                                                                      {
                                                                    '': 1,
                                                                    'A': 1,
                                                                    'B': 2,
                                                                    'C': 3,
                                                                    'X': 4,
                                                                  };

                                                                  final List<
                                                                          Map<String,
                                                                              dynamic>>
                                                                      tmp = [];

                                                                  // NOTE: ini tadinya if (== '' || isNotEmpty) -> selalu true.
                                                                  if (damageCtrl
                                                                      .text
                                                                      .isNotEmpty) {
                                                                    tmp.add({
                                                                      'remark':
                                                                          damageCtrl
                                                                              .text,
                                                                      'rating':
                                                                          ''
                                                                    });
                                                                  }

                                                                  for (int i =
                                                                          0;
                                                                      i <
                                                                          checkedDamageValues
                                                                              .length;
                                                                      i++) {
                                                                    if (checkedDamageValues[
                                                                        i]) {
                                                                      tmp.add(
                                                                          damageType[
                                                                              i]);
                                                                    }
                                                                  }

                                                                  final onlyRemark = tmp
                                                                      .map<String>((item) =>
                                                                          item['remark']
                                                                              ?.toString() ??
                                                                          '')
                                                                      .where((remark) =>
                                                                          remark
                                                                              .isNotEmpty)
                                                                      .toList();

                                                                  position[index]
                                                                          [
                                                                          'damageTire'] =
                                                                      onlyRemark;

                                                                  if (tmp
                                                                      .isNotEmpty) {
                                                                    position[index]
                                                                            [
                                                                            'damageTire'] =
                                                                        onlyRemark;

                                                                    // rating based damage
                                                                    String
                                                                        worstRating =
                                                                        '';
                                                                    worstRating =
                                                                        tmp.fold(
                                                                      '',
                                                                      (worst,
                                                                          item) {
                                                                        final current =
                                                                            item['rating'] ??
                                                                                '';

                                                                        return ratingPriority[current]! >
                                                                                ratingPriority[worst]!
                                                                            ? current
                                                                            : worst;
                                                                      },
                                                                    );

                                                                    position[index]
                                                                            [
                                                                            'rating'] =
                                                                        worstRating;

                                                                    selectedDamage
                                                                        .addAll(
                                                                            onlyRemark);

                                                                    log('hasil luka ban : $position');
                                                                  }

                                                                  damageCtrl
                                                                      .clear();
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child: Text(
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
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8.0),
                                            child: Text(
                                              ((position[index]['damageTire'] ==
                                                          null) ||
                                                      (position[index]
                                                                  ['damageTire']
                                                              as List)
                                                          .where((e) =>
                                                              e != null &&
                                                              e
                                                                  .toString()
                                                                  .trim()
                                                                  .isNotEmpty)
                                                          .isEmpty)
                                                  ? 'Good Condition'
                                                  : (position[index]
                                                              ['damageTire']
                                                          as List)
                                                      .join('\n---\n'),
                                              textAlign: TextAlign.center,
                                              style: getWhiteTextStyle(
                                                  fontSize: 14),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 12,
                                      ),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 45,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () {
                                            showRimInspectionDialog(index);
                                          },
                                          child: Text(
                                            'Check Tire Component Condition',
                                            style: getWhiteTextStyle(
                                                fontWeight: w700),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 16,
                                      ),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 45,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                )),
                                            onPressed: () async {
                                              final ImagePicker picker =
                                                  ImagePicker();

                                              final ImageSource? source =
                                                  await showDialog<ImageSource>(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                        "Pilih Sumber Gambar"),
                                                    content: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        ListTile(
                                                          leading: Icon(
                                                              Icons.camera_alt),
                                                          title: Text("Kamera"),
                                                          onTap: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  ImageSource
                                                                      .camera),
                                                        ),
                                                        ListTile(
                                                          leading: Icon(Icons
                                                              .photo_library),
                                                          title:
                                                              Text("Gallery"),
                                                          onTap: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  ImageSource
                                                                      .gallery),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                },
                                              );

                                              // final XFile? image =
                                              //     await picker.pickImage(
                                              //         imageQuality: 50,
                                              //         source:
                                              //             // ImageSource.camera);
                                              //             ImageSource.gallery);

                                              if (source == null) return;

                                              if (source ==
                                                  ImageSource.camera) {
                                                requestCameraPermission();
                                              }

                                              final XFile? image =
                                                  await picker.pickImage(
                                                source: source,
                                                imageQuality: 50,
                                              );

                                              try {
                                                if (image != null) {
                                                  Directory? directory;

                                                  if (Platform.isAndroid) {
                                                    // path = await getExternalStorageDirectory();
                                                    directory =
                                                        await DownloadsPath
                                                            .downloadsDirectory();
                                                  }

                                                  if (Platform.isIOS) {
                                                    // final directory = await getApplicationDocumentsDirectory();
                                                    // path = directory;
                                                    directory =
                                                        await getApplicationDocumentsDirectory();
                                                  }

                                                  // Read image as a file
                                                  File imageFile =
                                                      File(image.path);
                                                  // data size fotonya
                                                  final compressedFilePath =
                                                      '${directory?.path}/${DateTime.now().millisecondsSinceEpoch}_tireinspectionimage_compressed.jpg';

                                                  // Compress the image if needed (optional)
                                                  final compressedImageFile =
                                                      await FlutterImageCompress
                                                          .compressAndGetFile(
                                                    imageFile.path,
                                                    compressedFilePath,
                                                    quality: 50,
                                                  );
                                                  log('gambar : ${compressedFilePath}');

                                                  if (compressedImageFile ==
                                                      null) {
                                                    throw Exception(
                                                      'Failed to compress image.',
                                                    );
                                                  }

                                                  // Simpan foto saja. Analisa AI dijalankan manual
                                                  // melalui tombol Analyze Damage with AI.
                                                  setState(() {
                                                    position[index]['image'] = [
                                                      '${compressedImageFile.path}|${position[index]['position']}'
                                                    ];

                                                    // Hapus hasil AI dari foto sebelumnya.
                                                    aiResults.remove(index);
                                                    imageWidths.remove(index);
                                                    imageHeights.remove(index);
                                                    loadingAI[index] = false;
                                                  });

                                                  log('tire inspection image = ${position[index]['image']}');
                                                }
                                              } catch (e) {
                                                log('error gambar string : $e');
                                              }

                                              setState(() {});
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.camera_alt,
                                                  color: white,
                                                ),
                                                const SizedBox(
                                                  width: 12,
                                                ),
                                                Text(
                                                  'Take Picture',
                                                  style: getWhiteTextStyle(),
                                                ),
                                              ],
                                            )),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Text(
                                        '*You can only take one picture. If you take another picture, the previous one will be deleted.',
                                        style: getRedTextStyle(),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      ((position[index]['image']
                                                  as List<dynamic>)
                                              .isNotEmpty)
                                          ? Column(
                                              children: [
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 45,
                                                  child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .deepOrange,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              )),
                                                      onPressed: () async {
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                content: Text(
                                                                  'Are you sure you want to delete this image?',
                                                                  style:
                                                                      getBlackTextStyle(),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        'Cancel',
                                                                        style: getGreyTextStyle(
                                                                            grey8391A1),
                                                                      )),
                                                                  TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        setState(
                                                                            () {
                                                                          position[index]['image'] =
                                                                              [];
                                                                          aiResults
                                                                              .remove(index);
                                                                          loadingAI
                                                                              .remove(index);
                                                                          imageWidths
                                                                              .remove(index);
                                                                          imageHeights
                                                                              .remove(index);
                                                                        });
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        'Yes',
                                                                        style:
                                                                            getRedTextStyle(),
                                                                      )),
                                                                ],
                                                              );
                                                            });

                                                        setState(() {});
                                                      },
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.delete,
                                                            color: white,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Text(
                                                            'Delete Picture',
                                                            style:
                                                                getWhiteTextStyle(),
                                                          ),
                                                        ],
                                                      )),
                                                ),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                (loadingAI[index] == true)
                                                    ? Center(
                                                        child:
                                                            AiLoadingWidget(),
                                                      )
                                                    : Stack(
                                                        children: [
                                                          Container(
                                                            width:
                                                                double.infinity,
                                                            decoration:
                                                                BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            ),
                                                            child: Image.file(
                                                              File(
                                                                (position[index]
                                                                            [
                                                                            'image'][0]
                                                                        as String)
                                                                    .split(
                                                                        '|')[0],
                                                              ),
                                                              fit: BoxFit
                                                                  .contain,
                                                            ),
                                                          ),
                                                          if (aiResults[
                                                                  index] !=
                                                              null)
                                                            Positioned.fill(
                                                              child:
                                                                  CustomPaint(
                                                                painter:
                                                                    BoundingBoxPainter(
                                                                  detections: aiResults[
                                                                              index]
                                                                          ?.data
                                                                          ?.tireDamageResult ??
                                                                      [],
                                                                  imageWidth:
                                                                      imageWidths[
                                                                              index] ??
                                                                          1,
                                                                  imageHeight:
                                                                      imageHeights[
                                                                              index] ??
                                                                          1,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 45,
                                                  child: ElevatedButton(
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.purple,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                      ),
                                                    ),
                                                    onPressed:
                                                        loadingAI[index] == true
                                                            ? null
                                                            : () async {
                                                                await _analyzeDamageWithAI(
                                                                  index,
                                                                );
                                                              },
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Icon(
                                                          Icons.auto_awesome,
                                                          color: white,
                                                        ),
                                                        const SizedBox(
                                                          width: 12,
                                                        ),
                                                        Text(
                                                          aiResults[index] ==
                                                                  null
                                                              ? 'Analyze Damage with AI'
                                                              : 'Analyze Again with AI',
                                                          style:
                                                              getWhiteTextStyle(
                                                            fontWeight: w700,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                              ],
                                            )
                                          : Container(),

                                      // Show More Images
                                      // (listImg.isNotEmpty)
                                      //     ? Column(
                                      //         children: [
                                      //           SizedBox(
                                      //             width: double.infinity,
                                      //             height: 45,
                                      //             child: ElevatedButton(
                                      //                 style: ElevatedButton
                                      //                     .styleFrom(
                                      //                         backgroundColor:
                                      //                             Colors
                                      //                                 .orange,
                                      //                         shape:
                                      //                             RoundedRectangleBorder(
                                      //                           borderRadius:
                                      //                               BorderRadius.circular(
                                      //                                   12),
                                      //                         )),
                                      //                 onPressed: () async {
                                      //                   final CarouselController
                                      //                       _controller =
                                      //                       CarouselController();

                                      //                   showDialog(
                                      //                       context:
                                      //                           context,
                                      //                       builder:
                                      //                           (BuildContext
                                      //                               context) {
                                      //                         return AlertDialog(
                                      //                           content:
                                      //                               Padding(
                                      //                             padding: const EdgeInsets
                                      //                                 .all(
                                      //                                 24.0),
                                      //                             child:
                                      //                                 Column(
                                      //                               mainAxisSize:
                                      //                                   MainAxisSize.min,
                                      //                               children: [
                                      //                                 Text(
                                      //                                   'Show Image',
                                      //                                   style:
                                      //                                       getBlackTextStyle(),
                                      //                                 ),
                                      //                                 const SizedBox(
                                      //                                   height:
                                      //                                       12,
                                      //                                 ),
                                      //                                 Container(
                                      //                                   width:
                                      //                                       400,
                                      //                                   height:
                                      //                                       400,
                                      //                                   child:
                                      //                                       CarouselSlider(
                                      //                                     carouselController: _controller,
                                      //                                     // items: listImg.map((img) {
                                      //                                     //   final splitImg = img.split('|');

                                      //                                     //   if ((position[index]['position']).toString() == splitImg[1]) {
                                      //                                     //     return Image.file(File(splitImg[0]));
                                      //                                     //   }
                                      //                                     //   return Container();
                                      //                                     // }).toList(),
                                      //                                     items: listImg
                                      //                                         .where((img) {
                                      //                                           final splitImg = img.split('|');
                                      //                                           return splitImg[1] == (position[index]['position']).toString();
                                      //                                         })
                                      //                                         .toList()
                                      //                                         .map((img2) {
                                      //                                           final splitImg2 = img2.split('|');
                                      //                                           return Image.file(File(splitImg2[0]));
                                      //                                         })
                                      //                                         .toList(),
                                      //                                     options: CarouselOptions(
                                      //                                       aspectRatio: 3.0,
                                      //                                       height: 400,
                                      //                                       enableInfiniteScroll: false,
                                      //                                       enlargeCenterPage: true,
                                      //                                     ),
                                      //                                   ),
                                      //                                 ),
                                      //                               ],
                                      //                             ),
                                      //                           ),
                                      //                         );
                                      //                       });
                                      //                   setState(() {});
                                      //                 },
                                      //                 child: Row(
                                      //                   mainAxisAlignment:
                                      //                       MainAxisAlignment
                                      //                           .center,
                                      //                   children: [
                                      //                     Icon(
                                      //                       Icons.image,
                                      //                       color: white,
                                      //                     ),
                                      //                     const SizedBox(
                                      //                       width: 12,
                                      //                     ),
                                      //                     Text(
                                      //                       'Show Image',
                                      //                       style:
                                      //                           getWhiteTextStyle(),
                                      //                     ),
                                      //                   ],
                                      //                 )),
                                      //           ),
                                      //           const SizedBox(
                                      //             height: 12,
                                      //           ),
                                      //         ],
                                      //       )
                                      //     : Container(),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
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
                                                      position[index]['rtd1'] =
                                                          value;
                                                    },
                                                    controller:
                                                        rtd1Controllers[index],
                                                    hint: '',
                                                  ),
                                                ),
                                                // Builder(builder: (context) {
                                                //   rtd1Controllers[index].text =
                                                //       unit.rtd ?? '';
                                                //   position[index]['rtd1'] =
                                                //       unit.rtd;
                                                //   return SizedBox(
                                                //     width: double.infinity,
                                                //     child: InputFormWidget(
                                                //         onChng: (value) {
                                                //           position[index]
                                                //               ['rtd1'] = value;
                                                //         },
                                                //         controller:
                                                //             rtd1Controllers[
                                                //                 index],
                                                //         hint: ''),
                                                //   );
                                                // }),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
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
                                                      position[index]['rtd2'] =
                                                          value;
                                                    },
                                                    controller:
                                                        rtd2Controllers[index],
                                                    hint: '',
                                                  ),
                                                ),
                                                // Builder(builder: (context) {
                                                //   rtd2Controllers[index].text =
                                                //       unit.otd ?? '';
                                                //   position[index]['rtd2'] =
                                                //       unit.otd;
                                                //   return SizedBox(
                                                //     width: double.infinity,
                                                //     child: InputFormWidget(
                                                //         onChng: (value) {
                                                //           position[index]
                                                //               ['rtd2'] = value;
                                                //         },
                                                //         controller:
                                                //             rtd2Controllers[
                                                //                 index],
                                                //         hint: ''),
                                                //   );
                                                // }),
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
                                            'Serial Number',
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
                                                  position[index]['sn'] = value;
                                                },
                                                controller:
                                                    snControllers[index],
                                                hint: ''),
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
                                                  position[index]['remarks'] =
                                                      value;
                                                },
                                                controller:
                                                    remarksControllers[index],
                                                hint: ''),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 24,
                                      ),
                                      SizedBox(height: 12),

                                      // SizedBox(
                                      //   // height: 160,
                                      //   child: GridView.builder(
                                      //       physics:
                                      //           NeverScrollableScrollPhysics(),
                                      //       shrinkWrap: true,
                                      //       itemCount: position[index]
                                      //               ['condition']
                                      //           .length,
                                      //       gridDelegate:
                                      //           SliverGridDelegateWithFixedCrossAxisCount(
                                      //               crossAxisCount: 2,
                                      //               childAspectRatio: 3),
                                      //       itemBuilder:
                                      //           (context, indexBroken) {
                                      //         final broken = position[index]
                                      //             ['condition'][indexBroken];
                                      //         return InkWell(
                                      //           onTap: () {
                                      //             setState(() {
                                      //               // checkedListCategory[
                                      //               //         index] =
                                      //               //     !checkedListCategory[
                                      //               //         index];
                                      //               broken['checked'] =
                                      //                   !broken['checked'];
                                      //             });
                                      //             // widget.onCategoryChecked(checkedListCategory);
                                      //           },
                                      //           child: Container(
                                      //             padding: EdgeInsets.all(10),
                                      //             child: Row(
                                      //               children: [
                                      //                 Container(
                                      //                   width: 24,
                                      //                   height: 24,
                                      //                   decoration:
                                      //                       BoxDecoration(
                                      //                     color: broken[
                                      //                             'checked']
                                      //                         ? black
                                      //                         : Colors
                                      //                             .transparent,
                                      //                     border: Border.all(
                                      //                         color:
                                      //                             Colors.black),
                                      //                   ),
                                      //                   child: Icon(
                                      //                     Icons.check,
                                      //                     color: Colors.white,
                                      //                     size: 16,
                                      //                   ),
                                      //                 ),
                                      //                 SizedBox(width: 10),
                                      //                 LayoutBuilder(builder:
                                      //                     (context,
                                      //                         constraints) {
                                      //                   double fontSize =
                                      //                       constraints
                                      //                               .maxHeight *
                                      //                           0.35;
                                      //                   // log('ukuran' + fontSize.toString());
                                      //                   return Text(
                                      //                     broken['name'],
                                      //                     style:
                                      //                         getBlackTextStyle(
                                      //                             fontSize:
                                      //                                 fontSize),
                                      //                   );
                                      //                 }),
                                      //               ],
                                      //             ),
                                      //           ),
                                      //         );
                                      //       }),
                                      // ),
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
                      name: isLoadingSave
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Saving...',
                                  style: getWhiteTextStyle(
                                    fontWeight: w700,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.save_alt,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Save',
                                  style: getWhiteTextStyle(),
                                ),
                              ],
                            ),
                      function: () async {
                        await _handleSaveTireInspection(state);
                      }),
                  // child: ButtonWidget(
                  //     name: isLoadingSave
                  //         ? Row(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               const SizedBox(
                  //                 width: 22,
                  //                 height: 22,
                  //                 child: CircularProgressIndicator(
                  //                   strokeWidth: 2.5,
                  //                   valueColor: AlwaysStoppedAnimation<Color>(
                  //                     Colors.white,
                  //                   ),
                  //                 ),
                  //               ),
                  //               const SizedBox(width: 10),
                  //               Text(
                  //                 'Saving...',
                  //                 style: getWhiteTextStyle(
                  //                   fontWeight: w700,
                  //                 ),
                  //               ),
                  //             ],
                  //           )
                  //         : Row(
                  //             mainAxisAlignment: MainAxisAlignment.center,
                  //             children: [
                  //               const Icon(
                  //                 Icons.save_alt,
                  //                 color: Colors.white,
                  //               ),
                  //               const SizedBox(width: 6),
                  //               Text(
                  //                 'Save',
                  //                 style: getWhiteTextStyle(),
                  //               ),
                  //             ],
                  //           ),
                  //     // function: () async {
                  //     //   // jika data pressure kosong
                  //     //   bool hasEmptyPressure =
                  //     //       position.any((p) => p['pressure'] == '');

                  //     //   if (hasEmptyPressure) {
                  //     //     ScaffoldMessenger.of(context).hideCurrentSnackBar();

                  //     //     ScaffoldMessenger.of(context).showSnackBar(
                  //     //       SnackBar(
                  //     //         backgroundColor: Colors.red,
                  //     //         content: Text(
                  //     //           'Please input data pressure (Choose 0 Psi if No Tire or Block Valve)',
                  //     //           style: TextStyle(color: Colors.white),
                  //     //         ),
                  //     //       ),
                  //     //     );
                  //     //     return;
                  //     //   }
                  //     //   // jika belum memeilih pit
                  //     //   if (idSite == bmbsitarum.idSite ||
                  //     //       idSite == bmbhauling.idSite ||
                  //     //       idSite == bmbtabuhan.idSite ||
                  //     //       idSite == bibkgb.idSite ||
                  //     //       idSite == bibgh.idSite) {
                  //     //     if (selectedPit == -1) {
                  //     //       ScaffoldMessenger.of(context).showSnackBar(
                  //     //         SnackBar(
                  //     //           backgroundColor: Colors.red,
                  //     //           content: Text(
                  //     //             'Please select location of unit first!',
                  //     //             style: TextStyle(color: Colors.white),
                  //     //           ),
                  //     //         ),
                  //     //       );
                  //     //       return;
                  //     //     }
                  //     //   }

                  //     //   // input ke tire inspection
                  //     //   try {
                  //     //     position.removeWhere((element) =>
                  //     //         element['pressure'] == '' &&
                  //     //         (element['damageTire'] as List<dynamic>)
                  //     //             .isEmpty &&
                  //     //         element['adjusmentPressure'] == '' &&
                  //     //         element['rtd1'] == '' &&
                  //     //         element['rtd2'] == '' &&
                  //     //         element['rating'] == '' &&
                  //     //         element['sn'] == '' &&
                  //     //         element['remarks'] == '');

                  //     //     for (int i = 0; i < position.length; i++) {
                  //     //       final unit = state.units[i];
                  //     //       final id = Uuid();

                  //     //       String? localImagePath;
                  //     //       try {
                  //     //         final imgList =
                  //     //             position[i]['image'] as List<dynamic>?;
                  //     //         if (imgList != null && imgList.isNotEmpty) {
                  //     //           final raw = imgList[0]
                  //     //               as String; // format: "path|position"
                  //     //           final parts = raw.split('|');
                  //     //           if (parts.isNotEmpty) {
                  //     //             localImagePath = parts[0];
                  //     //           }
                  //     //         }
                  //     //       } catch (e) {
                  //     //         log('parse image error: $e');
                  //     //       }

                  //     //       log('SAVE POSISI ${localImagePath}');
                  //     //       log('SAVE POSISI ${position[i]['position']} '
                  //     //           'IMAGE: ${position[i]['image']}');

                  //     //       if (position[i]['pressure'] != '' ||
                  //     //           position[i]['hm'] != '' ||
                  //     //           position[i]['damageTire'] != [] ||
                  //     //           position[i]['damageTire'][0] != damageType[0] ||
                  //     //           position[i]['adjusmentPressure'] != '' ||
                  //     //           position[i]['rtd1'] != '' ||
                  //     //           position[i]['rtd2'] != '' ||
                  //     //           position[i]['rating'] != '' ||
                  //     //           position[i]['sn'] != '' ||
                  //     //           position[i]['remarks'] != '') {
                  //     //         final today = DateTime.now();
                  //     //         final startOfDay =
                  //     //             DateTime(today.year, today.month, today.day);
                  //     //         final endOfDay = DateTime(today.year, today.month,
                  //     //             today.day, 23, 59, 59);

                  //     //         final querySnapshot = await firestore
                  //     //             .collection('task')
                  //     //             .where('kunci_unit',
                  //     //                 isEqualTo: unit.kunciUnit)
                  //     //             .where('kunci_tire',
                  //     //                 isEqualTo: unit.kunciTire)
                  //     //             .where('position',
                  //     //                 isEqualTo: position[i]['position'])
                  //     //             .where('last_update',
                  //     //                 isGreaterThanOrEqualTo:
                  //     //                     startOfDay.toIso8601String())
                  //     //             .where('last_update',
                  //     //                 isLessThanOrEqualTo:
                  //     //                     endOfDay.toIso8601String())
                  //     //             .get();

                  //     //         log('adakah query : ${querySnapshot.docs.isNotEmpty}');

                  //     //         final bool hasNewLocalImage =
                  //     //             localImagePath != null;

                  //     //         if (querySnapshot.docs.isNotEmpty) {
                  //     //           // Update the existing document
                  //     //           final docId = querySnapshot.docs.first.id;
                  //     //           // try {
                  //     //           //   log('kenapa gagal 3 ${position[i]['image'] as List<dynamic>}');
                  //     //           // } catch (e) {
                  //     //           //   log('kenapa gagal 4 ${e}');
                  //     //           // }

                  //     //           final Map<String, dynamic> updateData = {
                  //     //             'id': id.v4(),
                  //     //             'id_site': idSite,
                  //     //             'user': user['username'] ?? 'username',
                  //     //             'user_email': auth.currentUser!.email,
                  //     //             'unit': unit.unitNumber,
                  //     //             'serial_number': unit.sn,
                  //     //             'condition': position[i]['condition']
                  //     //                 .where((condition) =>
                  //     //                     condition['checked'] == true)
                  //     //                 .map((condition) =>
                  //     //                     condition['name'].toString())
                  //     //                 .toList(),
                  //     //             'tire_size': unit.size,
                  //     //             'hm': hmUnit.text,
                  //     //             'position': position[i]['position'],
                  //     //             'rating': position[i]['rating'],
                  //     //             'brand': unit.brand,
                  //     //             'tire_damage':
                  //     //                 (position[i]['damageTire'].isEmpty)
                  //     //                     ? damageType[0]
                  //     //                     : position[i]['damageTire'],
                  //     //             'remarks': position[i]['remarks'],
                  //     //             'rtd':
                  //     //                 '${position[i]['rtd1']}/${position[i]['rtd2']}',
                  //     //             'pressure': position[i]['pressure'],
                  //     //             'adjusmentPressure': position[i]
                  //     //                 ['adjusmentPressure'],
                  //     //             'last_update':
                  //     //                 DateTime.now().toIso8601String(),
                  //     //             'is_done': false,
                  //     //             'sn': (position[i]['sn'] != null ||
                  //     //                     position[i]['sn'] != '')
                  //     //                 ? position[i]['sn']
                  //     //                 : unit.sn,
                  //     //             'kunci_unit': unit.kunciUnit,
                  //     //             'kunci_tire': unit.kunciTire,
                  //     //             'pit': (idSite == bmbsitarum.idSite ||
                  //     //                     idSite == bmbhauling.idSite ||
                  //     //                     idSite == bmbtabuhan.idSite ||
                  //     //                     idSite == bibkgb.idSite)
                  //     //                 ? pit[selectedPit]
                  //     //                 : 'Default',
                  //     //           };

                  //     //           // Hanya kalau ada foto baru → kosongkan images & set pending
                  //     //           if (hasNewLocalImage) {
                  //     //             updateData['images'] = [];
                  //     //             updateData['imagePending'] = true;
                  //     //           }

                  //     //           await firestore
                  //     //               .collection('task')
                  //     //               .doc(docId)
                  //     //               .update(updateData);
                  //     //           if (hasNewLocalImage) {
                  //     //             UploadQueueService.to.addPending(
                  //     //               docId: docId,
                  //     //               filePath: localImagePath!,
                  //     //             );
                  //     //           }
                  //     //         } else {
                  //     //           final Map<String, dynamic> newData = {
                  //     //             'id': id.v4(),
                  //     //             'id_site': idSite,
                  //     //             'user': user['username'] ?? 'username',
                  //     //             'user_email': auth.currentUser!.email,
                  //     //             'unit': unit.unitNumber,
                  //     //             'serial_number': unit.sn,
                  //     //             'condition': position[i]['condition']
                  //     //                 .where((condition) =>
                  //     //                     condition['checked'] == true)
                  //     //                 .map((condition) =>
                  //     //                     condition['name'].toString())
                  //     //                 .toList(),
                  //     //             'tire_size': unit.size,
                  //     //             'hm': hmUnit.text,
                  //     //             'position': position[i]['position'],
                  //     //             'rating': position[i]['rating'],
                  //     //             'brand': unit.brand,
                  //     //             'tire_damage':
                  //     //                 (position[i]['damageTire'].isEmpty)
                  //     //                     ? damageType[0]
                  //     //                     : position[i]['damageTire'],
                  //     //             'remarks': position[i]['remarks'],
                  //     //             'rtd':
                  //     //                 '${position[i]['rtd1']}/${position[i]['rtd2']}',
                  //     //             'pressure': position[i]['pressure'],
                  //     //             'adjusmentPressure': position[i]
                  //     //                 ['adjusmentPressure'],
                  //     //             'last_update':
                  //     //                 DateTime.now().toIso8601String(),
                  //     //             'is_done': false,
                  //     //             'sn': (position[i]['sn'] != '')
                  //     //                 ? position[i]['sn']
                  //     //                 : unit.sn,
                  //     //             'kunci_unit': unit.kunciUnit,
                  //     //             'kunci_tire': unit.kunciTire,
                  //     //             'pit': (idSite == bmbsitarum.idSite ||
                  //     //                     idSite == bmbhauling.idSite ||
                  //     //                     idSite == bmbtabuhan.idSite ||
                  //     //                     idSite == bibkgb.idSite)
                  //     //                 ? pit[selectedPit]
                  //     //                 : 'Default',
                  //     //           };

                  //     //           newData['images'] = [];
                  //     //           newData['imagePending'] = hasNewLocalImage;

                  //     //           final docRef = await firestore
                  //     //               .collection('task')
                  //     //               .add(newData);

                  //     //           if (hasNewLocalImage) {
                  //     //             UploadQueueService.to.addPending(
                  //     //               docId: docRef.id,
                  //     //               filePath: localImagePath!,
                  //     //             );
                  //     //           }
                  //     //         }
                  //     //       }
                  //     //     }

                  //     //     // input ke daily check pressure
                  //     //     try {
                  //     //       final today = DateTime.now();
                  //     //       final startOfDay =
                  //     //           DateTime(today.year, today.month, today.day);
                  //     //       final endOfDay = DateTime(
                  //     //           today.year, today.month, today.day, 23, 59, 59);
                  //     //       final formattedToday =
                  //     //           '${today.month.toString().padLeft(2, '0')}' // MM
                  //     //           '${today.day.toString().padLeft(2, '0')}' // DD
                  //     //           '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

                  //     //       final querySnapshot = await FirebaseFirestore
                  //     //           .instance
                  //     //           .collection('daily_pressure')
                  //     //           .where('unit',
                  //     //               isEqualTo: dataUnit['unitNumber'])
                  //     //           .where('tanggal',
                  //     //               isGreaterThanOrEqualTo:
                  //     //                   startOfDay.toIso8601String())
                  //     //           .where('tanggal',
                  //     //               isLessThanOrEqualTo:
                  //     //                   endOfDay.toIso8601String())
                  //     //           .get();

                  //     //       print(
                  //     //           'Documents found: ${querySnapshot.docs.length}');

                  //     //       if (querySnapshot.docs.isNotEmpty) {
                  //     //         final docId = querySnapshot.docs.first.id;

                  //     //         // revisi data
                  //     //         await firestore
                  //     //             .collection('daily_pressure')
                  //     //             .doc(docId)
                  //     //             .update({
                  //     //           'idSite': idSite,
                  //     //           'user':
                  //     //               user['username'] ?? auth.currentUser!.email,
                  //     //           'tanggal': DateTime.now().toIso8601String(),
                  //     //           'unit': idUnit.text,
                  //     //           'hm': hmUnit.text,
                  //     //           'posisi': position.map((p) {
                  //     //             final pIndex = position.indexOf(p);

                  //     //             log('tekanan angin : ${p['pressure']}');
                  //     //             return {
                  //     //               'pos': '${pIndex + 1}',
                  //     //               'pressure': (p['pressure']) ?? '0',
                  //     //               'rating': (p['rating']) ?? '',
                  //     //               'adjusmentPressure':
                  //     //                   (p['adjusmentPressure']) ?? '0',
                  //     //               'luka': p['damageTire'],
                  //     //               'idUnit': p['idUnit'],
                  //     //               'idInventory': p['idInventory'],
                  //     //               'tireSize': p['tireSize'],
                  //     //               'idDaily':
                  //     //                   '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
                  //     //               'tireAccessories': []
                  //     //             };
                  //     //           }),
                  //     //           'pit': (idSite == bmbsitarum.idSite ||
                  //     //                   idSite == bmbhauling.idSite ||
                  //     //                   idSite == bmbtabuhan.idSite ||
                  //     //                   idSite == bibkgb.idSite)
                  //     //               ? pit[selectedPit]
                  //     //               : 'Default'
                  //     //         });
                  //     //       } else {
                  //     //         // tambah data
                  //     //         await firestore.collection('daily_pressure').add({
                  //     //           // 'nama': (user),
                  //     //           'idSite': idSite,
                  //     //           'user':
                  //     //               user['username'] ?? auth.currentUser!.email,
                  //     //           'tanggal': DateTime.now().toIso8601String(),
                  //     //           'unit': idUnit.text,
                  //     //           'hm': hmUnit.text,
                  //     //           'posisi': position.map((p) {
                  //     //             final pIndex = position.indexOf(p);
                  //     //             log('tekanan angin : ${p['pressure']}');

                  //     //             return {
                  //     //               'pos': '${pIndex + 1}',
                  //     //               'pressure': (p['pressure']) ?? '0',
                  //     //               'rating': (p['rating']) ?? '0',
                  //     //               'adjusmentPressure':
                  //     //                   (p['adjusmentPressure']) ?? '0',
                  //     //               'luka': p['damageTire'],
                  //     //               'idUnit': p['idUnit'],
                  //     //               'idInventory': p['idInventory'],
                  //     //               'tireSize': p['tireSize'],
                  //     //               'idDaily':
                  //     //                   '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
                  //     //               'tireAccessories': []
                  //     //             };
                  //     //           }),
                  //     //           'pit': (idSite == bmbsitarum.idSite ||
                  //     //                   idSite == bmbhauling.idSite ||
                  //     //                   idSite == bmbtabuhan.idSite ||
                  //     //                   idSite == bibkgb.idSite)
                  //     //               ? pit[selectedPit]
                  //     //               : 'Default'
                  //     //         });
                  //     //       }
                  //     //     } catch (e) {
                  //     //       print('error bmb : $e');
                  //     //     }
                  //     //     ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  //     //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //     //       content: Text(
                  //     //         'Successful save data, please check in home page',
                  //     //         style: getWhiteTextStyle(),
                  //     //       ),
                  //     //       backgroundColor: green00968A,
                  //     //     ));
                  //     //     Navigator.pop(context);
                  //     //   } catch (e) {
                  //     //     log('kenapa gagal : $e');
                  //     //   }
                  //     // }
                  //     function: () async {
                  //       if (isLoadingSave) return;

                  //       //// Validasi Tire Inspection
                  //       final currentHm =
                  //           double.tryParse(state.units[0].hm ?? '0') ?? 0;
                  //       final newHm = double.tryParse(hmUnit.text ?? '0') ?? 0;

                  //       // SMU/HM tidak boleh turun
                  //       if (currentHm > newHm) {
                  //         ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //           content: Text(
                  //             'SMU/HM tidak bisa berkurang',
                  //             style: getWhiteTextStyle(),
                  //           ),
                  //           backgroundColor: Colors.red,
                  //         ));
                  //         return;
                  //       }

                  //       // SMU/HM tidak boleh nambah terlalu banyak
                  //       if ((newHm - currentHm) > 1000) {
                  //         ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(
                  //             content: Text(
                  //               'Perubahan SMU/HM tidak bisa lebih dari 1000',
                  //               style: getWhiteTextStyle(),
                  //             ),
                  //             backgroundColor: Colors.red,
                  //           ),
                  //         );
                  //         return;
                  //       }

                  //       final List<String> errorsRtd = [];
                  //       final List<String> errorsRating = [];

                  //       for (int i = 0; i < state.units.length; i++) {
                  //         final unit = state.units[i];

                  //         // RTD tidak boleh naik
                  //         final actualRtd =
                  //             double.tryParse(unit.rtd.toString()) ?? 0;
                  //         final actualOtd =
                  //             double.tryParse(unit.otd.toString()) ?? 0;

                  //         final inputRtd =
                  //             double.tryParse(rtd1Controllers[i].text) ?? 0;
                  //         final inputOtd =
                  //             double.tryParse(rtd2Controllers[i].text) ?? 0;

                  //         if (inputRtd > actualRtd) {
                  //           errorsRtd.add(
                  //             'Posisi ${unit.posisi}: RTD input ($inputRtd) melebihi RTD aktual ($actualRtd).',
                  //           );
                  //         }

                  //         if (inputOtd > actualOtd) {
                  //           errorsRtd.add(
                  //             'Posisi ${unit.posisi}: OTD input ($inputOtd) melebihi OTD aktual ($actualOtd).',
                  //           );
                  //         }

                  //         // Jika sudah rating x, tidak boleh kembali ke rating A,B,C
                  //         const ratingScore = {
                  //           'A': 4,
                  //           'B': 3,
                  //           'C': 2,
                  //           'X': 1,
                  //         };
                  //         final actualRating = position[i]['prevRating']
                  //             .toString()
                  //             .toUpperCase()
                  //             .trim();
                  //         final inputRating = position[i]['rating']
                  //             .toString()
                  //             .toUpperCase()
                  //             .trim();

                  //         final actualScore = ratingScore[actualRating] ?? 0;
                  //         final inputScore = ratingScore[inputRating] ?? 0;

                  //         // Skip pengecekan jika prevRating kosong
                  //         if (actualRating.isNotEmpty) {
                  //           final actualScore = ratingScore[actualRating] ?? 0;
                  //           final inputScore = ratingScore[inputRating] ?? 0;

                  //           log('apakah rating membaik 3 : ${inputScore > actualScore}');

                  //           if (inputScore > actualScore) {
                  //             errorsRating.add(
                  //               'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
                  //             );
                  //           }
                  //         }

                  //         // if (inputScore > actualScore) {
                  //         //   errorsRating.add(
                  //         //     'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
                  //         //   );
                  //         // }
                  //       }

                  //       if (errorsRtd.isNotEmpty) {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(
                  //             backgroundColor: Colors.red,
                  //             duration: const Duration(seconds: 6),
                  //             content: Text(
                  //               errorsRtd.join('\n'),
                  //               style: getWhiteTextStyle(),
                  //             ),
                  //           ),
                  //         );
                  //         return;
                  //       }

                  //       if (errorsRating.isNotEmpty) {
                  //         ScaffoldMessenger.of(context).showSnackBar(
                  //           SnackBar(
                  //             backgroundColor: Colors.red,
                  //             duration: const Duration(seconds: 6),
                  //             content: Text(
                  //               errorsRating.join('\n'),
                  //               style: getWhiteTextStyle(),
                  //             ),
                  //           ),
                  //         );
                  //         return;
                  //       }

                  //       if (!mounted) return;

                  //       FocusScope.of(context).unfocus();
                  //       setState(() {
                  //         isLoadingSave = true;
                  //       });

                  //       // input ke tire inspection
                  //       try {
                  //         position.removeWhere((element) =>
                  //             element['pressure'] == '' &&
                  //             (element['damageTire'] as List<dynamic>)
                  //                 .isEmpty &&
                  //             element['adjusmentPressure'] == '' &&
                  //             element['rtd1'] == '' &&
                  //             element['rtd2'] == '' &&
                  //             element['rating'] == '' &&
                  //             element['sn'] == '' &&
                  //             element['remarks'] == '');

                  //         final today = DateTime.now();
                  //         final hari =
                  //             '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                  //         final jam =
                  //             '${today.hour.toString().padLeft(2, '0')}:${today.minute.toString().padLeft(2, '0')}:${today.second.toString().padLeft(2, '0')}';
                  //         final docId = '${hari}_${jam}';

                  //         // Bangun list posisi sesuai struktur tire_inspection
                  //         final List<Map<String, dynamic>> posisiList = [];
                  //         log('unit tire inspection ${state.units}');
                  //         final firstUnit = state.units[0];
                  //         final String kunciUnit = firstUnit.kunciUnit ?? '';

                  //         for (int i = 0; i < position.length; i++) {
                  //           final unit = state.units[i];

                  //           String? localImagePath;
                  //           try {
                  //             final imgList =
                  //                 position[i]['image'] as List<dynamic>?;
                  //             if (imgList != null && imgList.isNotEmpty) {
                  //               final raw = imgList[0] as String;
                  //               final parts = raw.split('|');
                  //               if (parts.isNotEmpty) {
                  //                 localImagePath = parts[0];
                  //               }
                  //             }
                  //           } catch (e) {
                  //             log('parse image error: $e');
                  //           }

                  //           final bool hasNewLocalImage =
                  //               localImagePath != null;

                  //           posisiList.add({
                  //             'position': position[i]['position'],
                  //             'pressure': position[i]['pressure'],
                  //             'adjusmentPressure': position[i]
                  //                 ['adjusmentPressure'],
                  //             'rating': position[i]['rating'],
                  //             'rtd1': position[i]['rtd1'],
                  //             'rtd2': position[i]['rtd2'],
                  //             'sn': (position[i]['sn'] != null &&
                  //                     position[i]['sn'] != '')
                  //                 ? position[i]['sn']
                  //                 : unit.sn,
                  //             'remarks':
                  //                 (position[i]['damageTire'] as List).isEmpty
                  //                     ? damageType[0]
                  //                     : position[i]['damageTire'][0],
                  //             'damageTire':
                  //                 (position[i]['damageTire'] as List).isEmpty
                  //                     ? (damageType is List<String>)
                  //                         ? damageType[0]
                  //                         : damageType[0]['remark']
                  //                     : position[i]['damageTire'],
                  //             // 'condition': (position[i]['condition'] as List)
                  //             //     .where((c) => c['checked'] == true)
                  //             //     .map((c) => c['name'].toString())
                  //             //     .toList(),
                  //             'rimCondition': position[i]['rimCondition'],
                  //             'idUnit': position[i]['idUnit'],
                  //             'idInventory': position[i]['idInventory'],
                  //             'tireSize': position[i]['tireSize'],
                  //             'kunci_tire': unit.kunciTire,
                  //             'hm': hmUnit.text,
                  //             'images': [],
                  //             'imagePending': hasNewLocalImage,
                  //             'tireAccessories': [],
                  //             'brand': firstUnit.brand,
                  //             'pattern': firstUnit.pattern,
                  //           });

                  //           if (hasNewLocalImage) {
                  //             // Pending upload akan di-handle setelah document dibuat
                  //           }
                  //         }

                  //         // Cek apakah sudah ada dokumen tire_inspection hari ini untuk unit ini
                  //         final startOfDay =
                  //             DateTime(today.year, today.month, today.day);
                  //         final endOfDay = DateTime(
                  //             today.year, today.month, today.day, 23, 59, 59);

                  //         final querySnapshot = await firestore
                  //             .collection('tire_inspection')
                  //             // .where('kunci_unit', isEqualTo: kunciUnit) // kunci_unit dari unit
                  //             .where('hari', isEqualTo: hari)
                  //             .where('unit', isEqualTo: firstUnit.unitNumber)
                  //             // .where('tanggal',
                  //             //     isGreaterThanOrEqualTo:
                  //             //         startOfDay.toIso8601String())
                  //             // .where('tanggal',
                  //             //     isLessThanOrEqualTo:
                  //             //         endOfDay.toIso8601String())
                  //             .get();

                  //         log('tire_inspection exists: ${querySnapshot.docs.isNotEmpty}');

                  //         if (querySnapshot.docs.isNotEmpty) {
                  //           // Update dokumen yang sudah ada
                  //           final existingDocId = querySnapshot.docs.first.id;

                  //           await firestore
                  //               .collection('tire_inspection')
                  //               .doc(existingDocId)
                  //               .update({
                  //             'id': const Uuid().v4(),
                  //             'id_site': idSite,
                  //             'user': user['username'] ?? 'username',
                  //             'user_email': auth.currentUser!.email,
                  //             'unit': dataUnit['unitNumber'],
                  //             'kunci_unit': kunciUnit,
                  //             'hm': hmUnit.text,
                  //             'hari': hari,
                  //             'jam': jam,
                  //             'tanggal': today.toIso8601String(),
                  //             'pit': (idSite == bmbsitarum.idSite ||
                  //                     idSite == bmbhauling.idSite ||
                  //                     idSite == bmbtabuhan.idSite ||
                  //                     idSite == bibkgb.idSite)
                  //                 ? pit[selectedPit]
                  //                 : 'Default',
                  //             'posisi': posisiList,
                  //             'brand': firstUnit.unitNumber,
                  //             'pattern': firstUnit.pattern,
                  //           });

                  //           // Handle image upload per posisi
                  //           for (int i = 0; i < position.length; i++) {
                  //             String? localImagePath;
                  //             try {
                  //               final imgList =
                  //                   position[i]['image'] as List<dynamic>?;
                  //               if (imgList != null && imgList.isNotEmpty) {
                  //                 final raw = imgList[0] as String;
                  //                 final parts = raw.split('|');
                  //                 if (parts.isNotEmpty)
                  //                   localImagePath = parts[0];
                  //               }
                  //             } catch (e) {
                  //               log('parse image error: $e');
                  //             }
                  //             if (localImagePath != null) {
                  //               UploadQueueService.to.addPending(
                  //                   docId: existingDocId,
                  //                   filePath: localImagePath,
                  //                   posisiIndex: i);
                  //             }
                  //           }
                  //         } else {
                  //           // Buat dokumen baru dengan ID format tanggal_jam
                  //           final newData = {
                  //             'id': const Uuid().v4(),
                  //             'id_site': idSite,
                  //             'user': user['username'] ?? 'username',
                  //             'user_email': auth.currentUser!.email,
                  //             'unit': dataUnit['unitNumber'],
                  //             'kunci_unit': kunciUnit,
                  //             'hm': hmUnit.text,
                  //             'hari': hari,
                  //             'jam': jam,
                  //             'tanggal': today.toIso8601String(),
                  //             'pit': (idSite == bmbsitarum.idSite ||
                  //                     idSite == bmbhauling.idSite ||
                  //                     idSite == bmbtabuhan.idSite ||
                  //                     idSite == bibkgb.idSite)
                  //                 ? pit[selectedPit]
                  //                 : 'Default',
                  //             'posisi': posisiList,
                  //           };

                  //           final docRef = await firestore
                  //               .collection('tire_inspection')
                  //               .doc(docId)
                  //               .set(newData);

                  //           // Handle image upload per posisi
                  //           for (int i = 0; i < position.length; i++) {
                  //             String? localImagePath;
                  //             try {
                  //               final imgList =
                  //                   position[i]['image'] as List<dynamic>?;
                  //               if (imgList != null && imgList.isNotEmpty) {
                  //                 final raw = imgList[0] as String;
                  //                 final parts = raw.split('|');
                  //                 if (parts.isNotEmpty)
                  //                   localImagePath = parts[0];
                  //               }
                  //             } catch (e) {
                  //               log('parse image error: $e');
                  //             }
                  //             if (localImagePath != null) {
                  //               UploadQueueService.to.addPending(
                  //                 docId: docId,
                  //                 filePath: localImagePath,
                  //                 posisiIndex: i,
                  //               );
                  //             }
                  //           }
                  //         }

                  //         //     // input ke daily check pressure
                  //         try {
                  //           final today = DateTime.now();
                  //           final startOfDay =
                  //               DateTime(today.year, today.month, today.day);
                  //           final endOfDay = DateTime(
                  //               today.year, today.month, today.day, 23, 59, 59);
                  //           final formattedToday =
                  //               '${today.month.toString().padLeft(2, '0')}' // MM
                  //               '${today.day.toString().padLeft(2, '0')}' // DD
                  //               '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

                  //           final querySnapshot = await FirebaseFirestore
                  //               .instance
                  //               .collection('daily_pressure')
                  //               .where('unit',
                  //                   isEqualTo: dataUnit['unitNumber'])
                  //               .where('tanggal',
                  //                   isGreaterThanOrEqualTo:
                  //                       startOfDay.toIso8601String())
                  //               .where('tanggal',
                  //                   isLessThanOrEqualTo:
                  //                       endOfDay.toIso8601String())
                  //               .get();

                  //           print(
                  //               'Documents found: ${querySnapshot.docs.length}');

                  //           if (querySnapshot.docs.isNotEmpty) {
                  //             final docId = querySnapshot.docs.first.id;

                  //             // revisi data
                  //             await firestore
                  //                 .collection('daily_pressure')
                  //                 .doc(docId)
                  //                 .update({
                  //               'idSite': idSite,
                  //               'user':
                  //                   user['username'] ?? auth.currentUser!.email,
                  //               'tanggal': DateTime.now().toIso8601String(),
                  //               'unit': idUnit.text,
                  //               'hm': hmUnit.text,
                  //               'posisi': position.map((p) {
                  //                 final pIndex = position.indexOf(p);

                  //                 log('tekanan angin : ${p['pressure']}');
                  //                 return {
                  //                   'pos': '${pIndex + 1}',
                  //                   'pressure': (p['pressure']) ?? '0',
                  //                   'rating': (p['rating']) ?? '',
                  //                   'adjusmentPressure':
                  //                       (p['adjusmentPressure']) ?? '0',
                  //                   'luka': p['damageTire'],
                  //                   'idUnit': p['idUnit'],
                  //                   'idInventory': p['idInventory'],
                  //                   'tireSize': p['tireSize'],
                  //                   'idDaily':
                  //                       '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
                  //                   'tireAccessories': []
                  //                 };
                  //               }),
                  //               'pit': (idSite == bmbsitarum.idSite ||
                  //                       idSite == bmbhauling.idSite ||
                  //                       idSite == bmbtabuhan.idSite ||
                  //                       idSite == bibkgb.idSite ||
                  //                       idSite == bibgh.idSite)
                  //                   ? pit[selectedPit]
                  //                   : 'Default'
                  //             });
                  //           } else {
                  //             // tambah data
                  //             await firestore.collection('daily_pressure').add({
                  //               // 'nama': (user),
                  //               'idSite': idSite,
                  //               'user':
                  //                   user['username'] ?? auth.currentUser!.email,
                  //               'tanggal': DateTime.now().toIso8601String(),
                  //               'unit': idUnit.text,
                  //               'hm': hmUnit.text,
                  //               'posisi': position.map((p) {
                  //                 final pIndex = position.indexOf(p);
                  //                 log('tekanan angin : ${p['pressure']}');

                  //                 return {
                  //                   'pos': '${pIndex + 1}',
                  //                   'pressure': (p['pressure']) ?? '0',
                  //                   'rating': (p['rating']) ?? '0',
                  //                   'adjusmentPressure':
                  //                       (p['adjusmentPressure']) ?? '0',
                  //                   'luka': p['damageTire'],
                  //                   'idUnit': p['idUnit'],
                  //                   'idInventory': p['idInventory'],
                  //                   'tireSize': p['tireSize'],
                  //                   'idDaily':
                  //                       '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
                  //                   'tireAccessories': []
                  //                 };
                  //               }),
                  //               'pit': (idSite == bmbsitarum.idSite ||
                  //                       idSite == bmbhauling.idSite ||
                  //                       idSite == bmbtabuhan.idSite ||
                  //                       idSite == bibkgb.idSite)
                  //                   ? pit[selectedPit]
                  //                   : 'Default'
                  //             });
                  //           }
                  //         } catch (e) {
                  //           print('error bmb : $e');
                  //         }

                  //         ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  //           content: Text(
                  //             'Successful save data, please check in home page',
                  //             style: getWhiteTextStyle(),
                  //           ),
                  //           backgroundColor: green00968A,
                  //         ));
                  //         Navigator.pop(context);
                  //       } catch (e, stackTrace) {
                  //         log(
                  //           'kenapa gagal : $e',
                  //           stackTrace: stackTrace,
                  //         );

                  //         if (mounted) {
                  //           ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  //           ScaffoldMessenger.of(context).showSnackBar(
                  //             SnackBar(
                  //               backgroundColor: Colors.red,
                  //               content: Text(
                  //                 'Failed to save data. Please try again.',
                  //                 style: getWhiteTextStyle(),
                  //               ),
                  //             ),
                  //           );
                  //         }
                  //       } finally {
                  //         if (mounted && isLoadingSave) {
                  //           setState(() {
                  //             isLoadingSave = false;
                  //           });
                  //         }
                  //       }
                  //     }),
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
    );
  }
}
