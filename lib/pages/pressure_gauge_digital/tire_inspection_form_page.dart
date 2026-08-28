// // new code after pi/pe implementation
// import 'dart:async';
// import 'dart:convert';
// import 'dart:developer';
// import 'dart:io';
// import 'dart:typed_data';

// import 'package:app_settings/app_settings.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
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
// import 'package:camos/core/services/model/tire_inspection_draft.dart';
// import 'package:camos/core/services/tire_inspection_draft_service.dart';
// import 'package:camos/core/utils/data/id_site.dart';
// import 'package:camos/pages/home/home_state.dart';
// import 'package:camos/pages/pressure_gauge_digital/trial/scan_device_page.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/bounding_box_painter.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/temperature_status_selector_widget.dart';
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
//   static const List<String> _siteSevenLocations = [
//     'Pitstop',
//     'Workshop',
//     'CSA 27',
//     'CSA 46',
//     'CSA 61',
//     'Hauling Road',
//     'Other',
//   ];

//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   FirebaseAuth auth = FirebaseAuth.instance;
//   final HomeState homeState = Get.find<HomeState>();
//   bool get _usesAutomaticDamageRating =>
//       homeState.userAccessCompanyId.value == '1';

//   bool _isInit = true;
//   int selectedMenu = 1;

//   final TireInspectionDraftService _draftService =
//       TireInspectionDraftService.instance;
//   Timer? _draftAutosaveTimer;
//   Timer? _draftDebounceTimer;
//   Timer? _usernamePreferenceTimer;
//   late final Future<void> _usernameReady;
//   Future<void> _formHydration = Future<void>.value();
//   TireInspectionDraftKey? _draftKey;
//   TireInspectionDraft? _loadedDraft;
//   String? _lastDraftFingerprint;
//   String? _initializedUnitNumber;
//   DateTime? _draftInspectionDate;
//   List<String?> _currentTireKeys = <String?>[];
//   bool _isRestoringDraft = false;
//   bool _isHandlingBack = false;
//   bool _usernameWasEdited = false;
//   String _latestEditedUsername = '';
//   int _pressureSubscriptionGeneration = 0;
//   final List<StreamSubscription<List<int>>> _pressureSubscriptions =
//       <StreamSubscription<List<int>>>[];

//   // Jenis periode Tire Inspection.
//   // Default menggunakan Period Inspection (PI).
//   String selectedPeriodType = 'PI';
//   bool _isLoadingPreviousPressure = false;
//   int _previousPressureRequestId = 0;
//   bool _isLoadingHiddenFieldFallbacks = false;
//   int _hiddenFieldRequestId = 0;
//   String _apiHmForHiddenFields = '';
//   String _defaultHmValue = '';

//   var map = {};
//   String idSite = '';
//   bool isSaved = false;
//   bool isLoadingSave = false;
//   Map<String, dynamic> dataUnit = {};
//   bool _isEditMode = false;
//   String _editInspectionDocumentId = '';
//   Map<String, dynamic>? _editInspectionData;
//   DateTime? _editInspectionDate;
//   String? _hmInitializedForUnit;

//   TextEditingController idUnit = TextEditingController(text: '');
//   TextEditingController hmUnit = TextEditingController(text: '');
//   TextEditingController usernameCtrl = TextEditingController(text: '');
//   TextEditingController pressureCtrl = TextEditingController(text: '');
//   TextEditingController remarksCtrl = TextEditingController(text: '');
//   TextEditingController damageCtrl = TextEditingController(text: '');
//   TextEditingController rtd1 = TextEditingController(text: '');
//   TextEditingController rtd2 = TextEditingController(text: '');
//   List<TextEditingController> remarksControllers = [];
//   List<TextEditingController> snControllers = [];
//   List<FocusNode> snFocusNodes = [];
//   List<TextEditingController> rtd1Controllers = [];
//   List<TextEditingController> rtd2Controllers = [];
//   final Set<int> _editableSnIndexes = <int>{};
//   bool _isSnConfirmationOpen = false;

//   SwiperController swiperController = SwiperController();
//   final ScrollController _formScrollController = ScrollController();
//   List<GlobalKey> _positionSectionKeys = [];
//   int _selectedScrollPosition = 0;
//   final ValueNotifier<Set<int>> _enteredPositionIndexes =
//       ValueNotifier<Set<int>>(<int>{});

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
//                     _markPositionAsEntered(tireIndex);
//                     _scheduleDraftSave();

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

//   void _configurePitOptions() {
//     pit.clear();

//     switch (idSite) {
//       case '7':
//         pit.addAll(_siteSevenLocations);
//         break;
//       case '5':
//       case '6':
//         pit.addAll(const <String>[
//           'PITSTOP AMBON',
//           'PITSTOP BANGKA',
//           'PITSTOP BUTON',
//           'PITSTOP IPD',
//           'PITSTOP MEDAN',
//           'PITSTOP OB2',
//           'PITSTOP SABANG',
//           'WSP',
//           'Other',
//         ]);
//         break;
//       case '52':
//         pit.addAll(const <String>['Utara', 'Selatan', 'RML', 'WS']);
//         break;
//       case '137':
//         pit.addAll(const <String>['Japun', 'PCE']);
//         break;
//       case '35':
//         pit.addAll(const <String>['Tabuhan', 'EBL', 'Workshop']);
//         break;
//       case '65':
//         pit.addAll(const <String>[
//           'Room B1 Selatan',
//           'TIA',
//           'Serongga',
//           'CSA Selatan',
//           'WS',
//         ]);
//         break;
//       case '166':
//         pit.addAll(const <String>[
//           'WS',
//           'Pondok Operator',
//           'CSA Bagaspati',
//           'Pit Stop Toll',
//         ]);
//         break;
//     }

//     if (idSite == '7' && (selectedPit < 0 || selectedPit >= pit.length)) {
//       selectedPit = 0;
//     } else if (selectedPit >= pit.length) {
//       selectedPit = -1;
//     }
//   }

//   DateTime? _dateFromRouteValue(dynamic value) {
//     final parsed = _dateFromRecord(value);
//     if (parsed == null) return null;
//     return DateTime(parsed.year, parsed.month, parsed.day);
//   }

//   DateTime? _dateFromRecord(dynamic value) {
//     if (value is Timestamp) return value.toDate();
//     if (value is DateTime) return value;
//     return DateTime.tryParse(value?.toString().trim() ?? '');
//   }

//   TireInspectionDraftKey? _buildDraftKey() {
//     final ownerId = auth.currentUser?.uid.trim() ?? '';
//     final unitNumber = dataUnit['unitNumber']?.toString().trim() ?? '';
//     if (ownerId.isEmpty || idSite.trim().isEmpty || unitNumber.isEmpty) {
//       return null;
//     }

//     return TireInspectionDraftKey.forDate(
//       userId: ownerId,
//       siteId: idSite,
//       unitNumber: unitNumber,
//       inspectionDate: _draftInspectionDate ?? DateTime.now(),
//     );
//   }

//   void _startDraftAutosave() {
//     if (_isEditMode) return;
//     _draftAutosaveTimer ??= Timer.periodic(
//       const Duration(seconds: 5),
//       (_) => unawaited(_persistDraftIfChanged()),
//     );
//   }

//   void _scheduleDraftSave() {
//     if (_isEditMode || _isRestoringDraft || isSaved) return;

//     _draftDebounceTimer?.cancel();
//     _draftDebounceTimer = Timer(
//       const Duration(milliseconds: 700),
//       () => unawaited(_persistDraftIfChanged()),
//     );
//   }

//   String get _accountUsername {
//     final cachedUsername = user['username']?.toString().trim() ?? '';
//     if (cachedUsername.isNotEmpty) return cachedUsername;

//     final firebaseDisplayName = auth.currentUser?.displayName?.trim() ?? '';
//     if (firebaseDisplayName.isNotEmpty) return firebaseDisplayName;

//     final email = auth.currentUser?.email?.trim() ?? '';
//     return email.isNotEmpty ? email : 'Unknown';
//   }

//   String get _effectiveUsername {
//     final inputUsername = usernameCtrl.text.trim();
//     return inputUsername.isNotEmpty ? inputUsername : _accountUsername;
//   }

//   Future<void> _initializeUsername() async {
//     try {
//       final loadedUser = await getUserPreferences();
//       final accountId = auth.currentUser?.uid.trim() ?? '';
//       final savedUsername = await getInspectionUsername(accountId: accountId);

//       if (!mounted) return;
//       user = loadedUser;

//       if (!_usernameWasEdited && usernameCtrl.text.trim().isEmpty) {
//         usernameCtrl.text =
//             savedUsername.isNotEmpty ? savedUsername : _accountUsername;
//       }
//       _scheduleDraftSave();
//       log('username : $user');
//     } catch (e, stackTrace) {
//       log(
//         'Gagal memuat username Tire Inspection: $e',
//         stackTrace: stackTrace,
//       );
//       if (mounted && !_usernameWasEdited && usernameCtrl.text.trim().isEmpty) {
//         usernameCtrl.text = _accountUsername;
//       }
//     }
//   }

//   Future<void> _persistInspectionUsername(String username) async {
//     final accountId = auth.currentUser?.uid.trim() ?? '';
//     if (accountId.isEmpty) return;

//     try {
//       await saveInspectionUsername(
//         accountId: accountId,
//         username: username.trim(),
//       );
//     } catch (e, stackTrace) {
//       log(
//         'Gagal menyimpan username Tire Inspection: $e',
//         stackTrace: stackTrace,
//       );
//     }
//   }

//   Future<void> _persistEditedUsernameIfNeeded() async {
//     if (!_usernameWasEdited) return;
//     _usernamePreferenceTimer?.cancel();
//     await _persistInspectionUsername(_latestEditedUsername);
//   }

//   void _handleUsernameChanged(String value) {
//     _usernameWasEdited = true;
//     _latestEditedUsername = value;
//     _scheduleDraftSave();

//     _usernamePreferenceTimer?.cancel();
//     final usernameToSave = value;
//     _usernamePreferenceTimer = Timer(
//       const Duration(milliseconds: 500),
//       () => unawaited(_persistInspectionUsername(usernameToSave)),
//     );
//   }

//   void _resetHmToDefault() {
//     if (_defaultHmValue.isEmpty) return;

//     hmUnit.value = TextEditingValue(
//       text: _defaultHmValue,
//       selection: TextSelection.collapsed(offset: _defaultHmValue.length),
//     );
//   }

//   TireInspectionDraft? _createDraftSnapshot() {
//     if (_isEditMode) return null;
//     final key = _draftKey ?? _buildDraftKey();
//     if (key == null || position.isEmpty) return null;
//     _draftKey = key;

//     return TireInspectionDraft.fromFormData(
//       key: key,
//       positions: position,
//       tireKeys: _currentTireKeys,
//       periodType: selectedPeriodType,
//       location:
//           selectedPit >= 0 && selectedPit < pit.length ? pit[selectedPit] : '',
//       hm: hmUnit.text,
//       unitModel: dataUnit['model']?.toString() ?? '',
//       siteName: homeState.siteName,
//       userDisplayName: _effectiveUsername,
//       formData: <String, dynamic>{
//         'selectedRoute': selectedRoute,
//         'checkAmount': checkAmount,
//       },
//       navigationData: <String, dynamic>{
//         ...dataUnit,
//         'unitNumber': key.unitNumber,
//         'idSite': key.siteId,
//         'draftInspectionDate': key.inspectionDate,
//         'idCompany': homeState.userAccessCompanyId.value,
//       },
//       createdAt: _loadedDraft?.createdAt,
//     );
//   }

//   String _draftFingerprint(TireInspectionDraft draft) {
//     final json = draft.toJson()
//       ..remove('createdAt')
//       ..remove('updatedAt');
//     return jsonEncode(json);
//   }

//   Future<void> _persistDraftIfChanged({
//     bool force = false,
//     bool rethrowOnError = false,
//   }) async {
//     if (_isEditMode || _isRestoringDraft || isSaved || position.isEmpty) {
//       return;
//     }

//     try {
//       final snapshot = _createDraftSnapshot();
//       if (snapshot == null) return;

//       final fingerprint = _draftFingerprint(snapshot);
//       if (!force && fingerprint == _lastDraftFingerprint) return;

//       _loadedDraft = await _draftService.saveDraft(snapshot);
//       _lastDraftFingerprint = fingerprint;
//     } catch (e, stackTrace) {
//       log(
//         'Tire Inspection draft save failed: $e',
//         stackTrace: stackTrace,
//       );
//       if (rethrowOnError) rethrow;
//     }
//   }

//   TireInspectionPositionDraft? _findPositionDraft(
//     TireInspectionDraft draft,
//     UnitTire unit,
//     int index,
//   ) {
//     final tireKey = unit.kunciTire?.toString().trim() ?? '';
//     if (tireKey.isNotEmpty) {
//       for (final item in draft.positions) {
//         if (item.tireKey == tireKey || item.identity == tireKey) return item;
//       }
//     }

//     final inventoryId = unit.idinventory?.toString().trim() ?? '';
//     if (inventoryId.isNotEmpty) {
//       for (final item in draft.positions) {
//         if (item.identity == inventoryId) return item;
//       }
//     }

//     final positionLabel = unit.posisi?.toString().trim().isNotEmpty == true
//         ? unit.posisi.toString().trim()
//         : '${index + 1}';
//     for (final item in draft.positions) {
//       if (item.positionLabel == positionLabel ||
//           item.positionLabel == '${index + 1}') {
//         return item;
//       }
//     }

//     return index < draft.positions.length ? draft.positions[index] : null;
//   }

//   void _syncPositionControllers() {
//     for (int index = 0; index < position.length; index++) {
//       if (index < remarksControllers.length) {
//         remarksControllers[index].text =
//             position[index]['remarks']?.toString() ?? '';
//       }
//       if (index < snControllers.length) {
//         snControllers[index].text = position[index]['sn']?.toString() ?? '';
//       }
//       if (index < rtd1Controllers.length) {
//         rtd1Controllers[index].text = position[index]['rtd1']?.toString() ?? '';
//       }
//       if (index < rtd2Controllers.length) {
//         rtd2Controllers[index].text = position[index]['rtd2']?.toString() ?? '';
//       }
//     }
//   }

//   Future<bool> _restoreDraft(TiresLoadedState state) async {
//     final key = _draftKey ?? _buildDraftKey();
//     if (key == null || state.units.isEmpty) return false;
//     _draftKey = key;

//     try {
//       final draft = await _draftService.loadDraft(key);
//       if (draft == null ||
//           !mounted ||
//           _initializedUnitNumber != key.unitNumber) {
//         return false;
//       }

//       setState(() {
//         _loadedDraft = draft;
//         if (!_usernameWasEdited && draft.userDisplayName.isNotEmpty) {
//           usernameCtrl.text = draft.userDisplayName;
//         }
//         if (draft.periodType == 'PI' || draft.periodType == 'PE') {
//           selectedPeriodType = draft.periodType;
//         }
//         hmUnit.text = draft.hm;

//         final restoredPitIndex = pit.indexWhere(
//           (item) => item.toLowerCase() == draft.location.toLowerCase(),
//         );
//         if (restoredPitIndex >= 0) selectedPit = restoredPitIndex;

//         selectedRoute = int.tryParse(
//               draft.formData['selectedRoute']?.toString() ?? '',
//             ) ??
//             selectedRoute;
//         checkAmount = int.tryParse(
//               draft.formData['checkAmount']?.toString() ?? '',
//             ) ??
//             checkAmount;

//         for (int index = 0; index < state.units.length; index++) {
//           if (index >= position.length) break;
//           final item = _findPositionDraft(draft, state.units[index], index);
//           if (item == null) continue;

//           final restored = item.toFormData();
//           for (final key in const <String>[
//             'pressure',
//             'adjusmentPressure',
//             'temperatureStatus',
//             'adjusmentTemperatureStatus',
//             'damageTire',
//             'rtd1',
//             'rtd2',
//             'remarks',
//             'sn',
//             'rating',
//             'prevRating',
//             'rimCondition',
//             'tireAccessories',
//             '_hasUserInput',
//             '_pressureFromHistory',
//           ]) {
//             if (restored.containsKey(key)) position[index][key] = restored[key];
//           }

//           final imagePaths = item.imagePaths
//               .where((path) => File(path).existsSync())
//               .map((path) => '$path|${position[index]['position']}')
//               .toList();
//           position[index]['image'] = imagePaths;

//           // Draft versi lama belum memiliki flag ini. Gunakan hanya data
//           // eksplisit yang aman agar nilai API/history tidak dianggap sebagai
//           // input baru dari user.
//           if (!restored.containsKey('_hasUserInput')) {
//             position[index]['_hasUserInput'] =
//                 _nonEmptySourceValue(restored['pressure']).isNotEmpty ||
//                     _nonEmptySourceValue(restored['adjusmentPressure'])
//                         .isNotEmpty ||
//                     imagePaths.isNotEmpty;
//           }

//           // Draft PE versi lama belum mencatat asal pressure. Perlakukan nilai
//           // tersebut sebagai data historis sampai user menginput ulang agar
//           // tidak dapat dipakai untuk memenuhi mandatory pressure pada PI.
//           if (!restored.containsKey('_pressureFromHistory')) {
//             position[index]['_pressureFromHistory'] =
//                 draft.periodType == 'PE' &&
//                     _nonEmptySourceValue(restored['pressure']).isNotEmpty;
//           }
//         }

//         _syncPositionControllers();
//       });
//       _syncEnteredPositionIndexes();

//       _lastDraftFingerprint = _draftFingerprint(draft);

//       if (mounted) {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: Colors.blue,
//             content: Text(
//               'Draft Tire Inspection unit ${key.unitNumber} berhasil dipulihkan.',
//               style: getWhiteTextStyle(),
//             ),
//           ),
//         );
//       }
//       return true;
//     } catch (e, stackTrace) {
//       log('Tire Inspection draft restore failed: $e', stackTrace: stackTrace);
//       return false;
//     }
//   }

//   Future<void> _deleteCurrentDraft() async {
//     final key = _draftKey ?? _buildDraftKey();
//     if (key == null) return;

//     try {
//       await _draftService.markCompleted(key);
//       _loadedDraft = null;
//       _lastDraftFingerprint = null;
//     } catch (e, stackTrace) {
//       log('Tire Inspection draft delete failed: $e', stackTrace: stackTrace);
//     }
//   }

//   Future<void> _deleteDraftIfUnchanged({
//     required TireInspectionDraftKey key,
//     required String fingerprint,
//   }) async {
//     try {
//       final currentDraft = await _draftService.loadDraft(key);
//       if (currentDraft == null ||
//           _draftFingerprint(currentDraft) != fingerprint) {
//         return;
//       }
//       await _draftService.markCompleted(key);
//     } catch (e, stackTrace) {
//       log(
//         'Delete synced Tire Inspection draft failed: $e',
//         stackTrace: stackTrace,
//       );
//     }
//   }

//   Future<bool> _saveDraftBeforeLeaving() async {
//     if (_isEditMode) return !isLoadingSave;
//     if (isSaved || position.isEmpty) return true;
//     if (isLoadingSave || _isHandlingBack) return false;

//     _isHandlingBack = true;
//     try {
//       _draftDebounceTimer?.cancel();
//       await _usernameReady;
//       await _formHydration;
//       if (!mounted) return false;

//       _draftDebounceTimer?.cancel();
//       await _persistEditedUsernameIfNeeded();
//       if (!mounted) return false;

//       await _persistDraftIfChanged(
//         force: true,
//         rethrowOnError: true,
//       );
//       return true;
//     } catch (_) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: Colors.red,
//             content: Text(
//               'Draft belum berhasil disimpan. Silakan tekan tombol Back kembali.',
//               style: getWhiteTextStyle(),
//             ),
//           ),
//         );
//       }
//       return false;
//     } finally {
//       _isHandlingBack = false;
//     }
//   }

//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     if (state == AppLifecycleState.inactive ||
//         state == AppLifecycleState.paused ||
//         state == AppLifecycleState.detached) {
//       unawaited(_persistEditedUsernameIfNeeded());
//       if (!_isEditMode) {
//         unawaited(_persistDraftIfChanged(force: true));
//       }
//     }
//   }

//   @override
//   void initState() {
//     super.initState();
//     requestPlacePermission();

//     context.read<BluetoothOnOffCubit>().checkBluetoothStatus();
//     final connectedCubit = context.read<ConnectedDevicesCubit>();
//     log('connected cubit : $connectedCubit');
//     connectedCubit.fetchConnectedDevices(); // HANYA MEMULAI fetch

//     // callTires();
//     WidgetsBinding.instance.addObserver(this);
//     hmUnit.addListener(_scheduleDraftSave);
//     _usernameReady = _initializeUsername();
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

//       if (!mounted) return;
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

//       if (!mounted) return;
//       setState(() {
//         loadingDamages = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _draftDebounceTimer?.cancel();
//     _draftAutosaveTimer?.cancel();
//     _usernamePreferenceTimer?.cancel();
//     unawaited(_persistEditedUsernameIfNeeded());
//     if (!isSaved && !_isEditMode) {
//       unawaited(_persistDraftIfChanged(force: true));
//     }

//     _pressureSubscriptionGeneration++;
//     for (final subscription in _pressureSubscriptions) {
//       unawaited(subscription.cancel());
//     }
//     _pressureSubscriptions.clear();

//     WidgetsBinding.instance.removeObserver(this);

//     hmUnit.removeListener(_scheduleDraftSave);
//     idUnit.dispose();
//     hmUnit.dispose();
//     usernameCtrl.dispose();
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

//     for (final focusNode in snFocusNodes) {
//       focusNode.dispose();
//     }

//     for (final controller in rtd1Controllers) {
//       controller.dispose();
//     }

//     for (final controller in rtd2Controllers) {
//       controller.dispose();
//     }

//     _formScrollController.dispose();
//     _enteredPositionIndexes.dispose();
//     swiperController.dispose();

//     super.dispose();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     if (_isInit) {
//       final args = ModalRoute.of(context)?.settings.arguments;
//       if (args is Map) {
//         dataUnit = Map<String, dynamic>.from(args);
//         _editInspectionDocumentId =
//             dataUnit['inspectionDocId']?.toString().trim() ?? '';
//         final rawEditData = dataUnit['inspectionData'];
//         if (rawEditData is Map) {
//           _editInspectionData = Map<String, dynamic>.from(rawEditData);
//         }
//         _isEditMode = dataUnit['isEdit'] == true &&
//             _editInspectionDocumentId.isNotEmpty &&
//             _editInspectionData != null;
//         final routeSiteId = dataUnit['idSite']?.toString().trim() ?? '';
//         idSite = routeSiteId.isNotEmpty ? routeSiteId : homeState.currentSiteId;
//         _draftInspectionDate =
//             _dateFromRouteValue(dataUnit['draftInspectionDate']);
//         _editInspectionDate = _dateFromRecord(
//           _editInspectionData?['tanggal'] ?? _editInspectionData?['hari'],
//         );
//         _configurePitOptions();
//         if (!_isEditMode) {
//           _draftKey = _buildDraftKey();
//         }

//         log('TireInspectionPage: dataUnit berhasil diambil -> $dataUnit');

//         unawaited(_loadDamages());
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

//     final hasNetwork = await _hasNetworkConnection();
//     if (!hasNetwork) {
//       if (!mounted) return;

//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           backgroundColor: Colors.orange,
//           content: Text(
//             'Tidak ada koneksi jaringan. Analisa AI hanya dapat digunakan saat online.',
//             style: TextStyle(color: Colors.white),
//           ),
//         ),
//       );
//       return;
//     }

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
//       final decodedWidth = decodedImage.width.toDouble();
//       final decodedHeight = decodedImage.height.toDouble();
//       decodedImage.dispose();
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
//         imageWidths[index] = decodedWidth;
//         imageHeights[index] = decodedHeight;
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

//   List<Map<String, dynamic>> _defaultRimConditions() {
//     return <Map<String, dynamic>>[
//       {
//         'title': 'RIM BASE',
//         'jobDescription': '',
//         'condition': 'Good',
//         'remark': '',
//       },
//       {
//         'title': 'FLANGE',
//         'jobDescription': '',
//         'condition': 'Good',
//         'remark': '',
//       },
//       {
//         'title': 'LOCK RING',
//         'jobDescription': '',
//         'condition': 'Good',
//         'remark': '',
//       },
//       {
//         'title': 'O-RING',
//         'jobDescription': '',
//         'condition': 'Good',
//         'remark': '',
//       },
//       {
//         'title': 'VALVE (TERPASANG/TIDAK TERPASANG)',
//         'jobDescription': '',
//         'condition': 'Good',
//         'remark': '',
//       },
//       {
//         'title': 'CORE VALVE',
//         'jobDescription': '',
//         'condition': 'Good',
//         'remark': '',
//       },
//       {
//         'title': 'VALVE CAP',
//         'jobDescription': '',
//         'condition': 'Good',
//         'remark': '',
//       },
//       {
//         'title': 'NUT DAN STUD RODA',
//         'jobDescription': '',
//         'condition': 'Good',
//         'remark': '',
//       },
//     ];
//   }

//   void _disposePositionInputs() {
//     for (final controller in remarksControllers) {
//       controller.removeListener(_scheduleDraftSave);
//       controller.dispose();
//     }
//     for (final controller in snControllers) {
//       controller.removeListener(_scheduleDraftSave);
//       controller.dispose();
//     }
//     for (final controller in rtd1Controllers) {
//       controller.removeListener(_scheduleDraftSave);
//       controller.dispose();
//     }
//     for (final controller in rtd2Controllers) {
//       controller.removeListener(_scheduleDraftSave);
//       controller.dispose();
//     }
//     for (final focusNode in snFocusNodes) {
//       focusNode.dispose();
//     }

//     remarksControllers.clear();
//     snControllers.clear();
//     rtd1Controllers.clear();
//     rtd2Controllers.clear();
//     snFocusNodes.clear();
//   }

//   void _initializePositions(TiresLoadedState state) {
//     if (state.units.isEmpty || !_stateMatchesRequestedUnit(state)) return;

//     final currentUnitNumber = state.units.first.unitNumber ?? '';
//     if (_initializedUnitNumber == currentUnitNumber &&
//         position.length == state.units.length) {
//       return;
//     }

//     _disposePositionInputs();
//     position.clear();
//     _enteredPositionIndexes.value = <int>{};
//     _editableSnIndexes.clear();
//     _currentTireKeys = state.units
//         .map((unit) => unit.kunciTire?.toString())
//         .toList(growable: false);
//     _initializedUnitNumber = currentUnitNumber;

//     final firstUnit = state.units.first;
//     _apiHmForHiddenFields = _nonEmptySourceValue(firstUnit.hm);
//     _defaultHmValue = idSite == bmbhauling.idSite ? '' : _apiHmForHiddenFields;
//     if (_hmInitializedForUnit != currentUnitNumber) {
//       hmUnit.text = _defaultHmValue;
//       _hmInitializedForUnit = currentUnitNumber;
//     }

//     dataUnit.putIfAbsent('model', () => firstUnit.model ?? '');
//     dataUnit['idSite'] = idSite;

//     for (int index = 0; index < state.units.length; index++) {
//       final unit = state.units[index];
//       final remarksController = TextEditingController();
//       final snController = TextEditingController(text: unit.sn ?? '');
//       final rtd1Controller =
//           TextEditingController(text: unit.rtd?.toString() ?? '');
//       final rtd2Controller =
//           TextEditingController(text: unit.rtd?.toString() ?? '');

//       remarksController.addListener(_scheduleDraftSave);
//       snController.addListener(_scheduleDraftSave);
//       rtd1Controller.addListener(_scheduleDraftSave);
//       rtd2Controller.addListener(_scheduleDraftSave);

//       remarksControllers.add(remarksController);
//       snControllers.add(snController);
//       snFocusNodes.add(FocusNode());
//       rtd1Controllers.add(rtd1Controller);
//       rtd2Controllers.add(rtd2Controller);

//       position.add(<String, dynamic>{
//         'position': index + 1,
//         'pressure': '',
//         '_pressureFromHistory': false,
//         'adjusmentPressure': '',
//         'temperatureStatus': 'HOT',
//         'adjusmentTemperatureStatus': 'HOT',
//         'hm': '',
//         'damageTire': <dynamic>[],
//         'rtd1': unit.rtd?.toString() ?? '',
//         'rtd2': unit.rtd?.toString() ?? '',
//         '_apiRtd': unit.rtd?.toString() ?? '',
//         '_apiRtd2': unit.rtd?.toString() ?? '',
//         '_apiSn': unit.sn?.toString() ?? '',
//         'remarks': '',
//         'sn': unit.sn,
//         'rating': '',
//         'prevRating': '',
//         'image': <String>[],
//         'idInventory': unit.idinventory,
//         'idUnit': unit.idUnit,
//         'tireSize': unit.size,
//         'kunci_tire': unit.kunciTire,
//         'rimCondition': _defaultRimConditions(),
//         'tireAccessories': <dynamic>[],
//         '_hasUserInput': false,
//       });
//     }

//     _startDraftAutosave();
//     _formHydration = _hydrateInitialFormData(state, currentUnitNumber);
//     unawaited(_formHydration);
//   }

//   bool _stateMatchesRequestedUnit(TiresLoadedState state) {
//     if (state.units.isEmpty) return false;

//     final requestedUnit = dataUnit['unitNumber']?.toString().trim() ?? '';
//     final loadedUnit = state.units.first.unitNumber?.trim() ?? '';
//     return requestedUnit.isNotEmpty && loadedUnit == requestedUnit;
//   }

//   bool _isFormInitializedFor(TiresLoadedState state) {
//     if (!_stateMatchesRequestedUnit(state)) return false;

//     final length = state.units.length;
//     return _initializedUnitNumber == state.units.first.unitNumber &&
//         position.length == length &&
//         remarksControllers.length == length &&
//         snControllers.length == length &&
//         snFocusNodes.length == length &&
//         rtd1Controllers.length == length &&
//         rtd2Controllers.length == length;
//   }

//   Map<dynamic, dynamic>? _previousPositionForUnit(
//     List<dynamic> previousPositions,
//     UnitTire unit,
//     int index,
//   ) {
//     final tireKey = unit.kunciTire?.toString().trim() ?? '';
//     if (tireKey.isNotEmpty) {
//       for (final item in previousPositions) {
//         if (item is Map &&
//             (item['kunci_tire'] ?? item['kunciTire'])?.toString() == tireKey) {
//           return item;
//         }
//       }
//     }

//     return _historyPositionAt(previousPositions, index);
//   }

//   Map<dynamic, dynamic>? _editPositionForUnit(
//     List<dynamic> storedPositions,
//     UnitTire unit,
//     int index,
//   ) {
//     final tireKey = unit.kunciTire?.toString().trim() ?? '';
//     if (tireKey.isNotEmpty) {
//       for (final item in storedPositions) {
//         if (item is Map &&
//             (item['kunci_tire'] ?? item['kunciTire'])?.toString().trim() ==
//                 tireKey) {
//           return item;
//         }
//       }
//     }

//     final inventoryId = unit.idinventory?.toString().trim() ?? '';
//     if (inventoryId.isNotEmpty) {
//       for (final item in storedPositions) {
//         if (item is Map &&
//             item['idInventory']?.toString().trim() == inventoryId) {
//           return item;
//         }
//       }
//     }

//     final unitPosition = unit.posisi?.toString().trim() ?? '';
//     for (final item in storedPositions) {
//       if (item is! Map) continue;
//       final storedPosition =
//           (item['position'] ?? item['pos'])?.toString().trim() ?? '';
//       if (storedPosition == '${index + 1}' ||
//           (unitPosition.isNotEmpty && storedPosition == unitPosition)) {
//         return item;
//       }
//     }

//     return index < storedPositions.length && storedPositions[index] is Map
//         ? storedPositions[index] as Map
//         : null;
//   }

//   List<dynamic> _copyDynamicList(dynamic value) {
//     if (value is! List) return <dynamic>[];
//     return value.map<dynamic>((item) {
//       if (item is Map) return Map<String, dynamic>.from(item);
//       return item;
//     }).toList(growable: true);
//   }

//   void _applyEditInspectionData(TiresLoadedState state) {
//     final editData = _editInspectionData;
//     if (!_isEditMode || editData == null || state.units.isEmpty) return;

//     final storedPositions = editData['posisi'];
//     if (storedPositions is! List) return;

//     final storedUsername = _nonEmptySourceValue(editData['user']);
//     if (storedUsername.isNotEmpty && !_usernameWasEdited) {
//       usernameCtrl.text = storedUsername;
//     }

//     hmUnit.text = _nonEmptySourceValue(editData['hm']);

//     final storedPeriod =
//         _nonEmptySourceValue(editData['periodType']).toUpperCase();
//     if (storedPeriod == 'PI' || storedPeriod == 'PE') {
//       selectedPeriodType = storedPeriod;
//     }

//     final storedPit = _nonEmptySourceValue(editData['pit']);
//     final storedPitIndex = pit.indexWhere(
//       (item) => item.trim().toLowerCase() == storedPit.toLowerCase(),
//     );
//     if (storedPitIndex >= 0) selectedPit = storedPitIndex;

//     for (int index = 0; index < state.units.length; index++) {
//       if (index >= position.length) break;
//       final stored = _editPositionForUnit(
//         storedPositions,
//         state.units[index],
//         index,
//       );
//       if (stored == null) continue;

//       for (final key in const <String>[
//         'pressure',
//         'adjusmentPressure',
//         'temperatureStatus',
//         'adjusmentTemperatureStatus',
//         'rtd1',
//         'rtd2',
//         'remarks',
//         'sn',
//         'rating',
//         'idUnit',
//         'idInventory',
//         'tireSize',
//       ]) {
//         if (stored.containsKey(key)) position[index][key] = stored[key];
//       }

//       position[index]['damageTire'] = _copyDynamicList(stored['damageTire']);
//       position[index]['rimCondition'] =
//           _copyDynamicList(stored['rimCondition']);
//       position[index]['tireAccessories'] =
//           _copyDynamicList(stored['tireAccessories']);
//       position[index]['prevRating'] =
//           _nonEmptySourceValue(stored['rating']).toUpperCase();
//       position[index]['_existingImages'] = _copyDynamicList(stored['images']);
//       position[index]['_editOriginalPosition'] =
//           Map<String, dynamic>.from(stored);
//       position[index]['_pressureFromHistory'] = false;
//       position[index]['_hasUserInput'] = true;
//     }

//     _syncPositionControllers();
//     _syncEnteredPositionIndexes();
//   }

//   Future<void> _loadPreviousInspectionDetails(
//     TiresLoadedState state,
//     String unitNumber,
//   ) async {
//     try {
//       final snapshot = await firestore
//           .collection('tire_inspection')
//           .where('unit', isEqualTo: unitNumber)
//           .orderBy('tanggal', descending: true)
//           .limit(10)
//           .get();

//       if (!mounted || _initializedUnitNumber != unitNumber) return;

//       Map<String, dynamic>? previousData;
//       for (final document in snapshot.docs) {
//         final data = document.data();
//         final documentSite = data['id_site']?.toString().trim() ?? '';
//         if (documentSite.isEmpty || documentSite == idSite) {
//           previousData = data;
//           break;
//         }
//       }

//       final previousPositions = previousData?['posisi'];
//       if (previousPositions is! List) return;

//       setState(() {
//         for (int index = 0; index < state.units.length; index++) {
//           if (index >= position.length) break;
//           final previous = _previousPositionForUnit(
//             previousPositions,
//             state.units[index],
//             index,
//           );
//           if (previous == null) continue;

//           final previousRating =
//               _nonEmptySourceValue(previous['rating']).toUpperCase();
//           if (_nonEmptySourceValue(position[index]['rating']).isEmpty &&
//               previousRating.isNotEmpty) {
//             position[index]['rating'] = previousRating;
//           }
//           if (_nonEmptySourceValue(position[index]['prevRating']).isEmpty &&
//               previousRating.isNotEmpty) {
//             position[index]['prevRating'] = previousRating;
//           }

//           final previousDamage = previous['damageTire'];
//           final currentDamage = position[index]['damageTire'];
//           if (currentDamage is List &&
//               currentDamage.isEmpty &&
//               previousDamage is List &&
//               previousDamage.isNotEmpty) {
//             position[index]['damageTire'] = List<dynamic>.from(previousDamage);
//           }

//           final previousRemarks = _nonEmptySourceValue(previous['remarks']);
//           if (_nonEmptySourceValue(position[index]['remarks']).isEmpty &&
//               previousRemarks.isNotEmpty) {
//             position[index]['remarks'] = previousRemarks;
//           }
//         }
//         _syncPositionControllers();
//       });
//     } catch (e, stackTrace) {
//       log(
//         'Load previous Tire Inspection once failed: $e',
//         stackTrace: stackTrace,
//       );
//     }
//   }

//   Future<void> _hydrateInitialFormData(
//     TiresLoadedState state,
//     String unitNumber,
//   ) async {
//     // Lindungi draft lama sejak sebelum menunggu inisialisasi username.
//     // Tanpa guard ini, autosave dapat menimpa draft dengan posisi default.
//     _isRestoringDraft = true;
//     try {
//       await _usernameReady;
//       if (!mounted || _initializedUnitNumber != unitNumber) return;

//       if (_isEditMode) {
//         setState(() {
//           _applyEditInspectionData(state);
//         });
//         return;
//       }

//       await _restoreDraft(state);
//       if (!mounted || _initializedUnitNumber != unitNumber) return;

//       await _loadPreviousInspectionDetails(state, unitNumber);
//       if (!mounted || _initializedUnitNumber != unitNumber) return;

//       if (_usesCompanyOnePeriodRules && selectedPeriodType == 'PE') {
//         await _loadHiddenFieldFallbacks();
//       }
//     } finally {
//       _isRestoringDraft = false;
//     }

//     _scheduleDraftSave();
//   }

//   void callTires() async {
//     if (mounted) {
//       if (dataUnit.isNotEmpty) {
//         idUnit.text = dataUnit['unitNumber']?.toString() ?? '';
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

//   void _syncPositionSectionKeys(int itemCount) {
//     if (_positionSectionKeys.length == itemCount) return;

//     _positionSectionKeys = List<GlobalKey>.generate(
//       itemCount,
//       (index) => GlobalKey(debugLabel: 'tire-position-${index + 1}'),
//     );

//     if (_selectedScrollPosition >= itemCount) {
//       _selectedScrollPosition = 0;
//     }
//   }

//   void _markPositionAsEntered(int index) {
//     if (index < 0 || index >= position.length) return;

//     position[index]['_hasUserInput'] = true;
//     if (_enteredPositionIndexes.value.contains(index)) return;

//     _enteredPositionIndexes.value = Set<int>.unmodifiable(
//       <int>{..._enteredPositionIndexes.value, index},
//     );
//   }

//   void _syncEnteredPositionIndexes() {
//     final enteredIndexes = <int>{};
//     for (int index = 0; index < position.length; index++) {
//       if (position[index]['_hasUserInput'] == true) {
//         enteredIndexes.add(index);
//       }
//     }
//     _enteredPositionIndexes.value = Set<int>.unmodifiable(enteredIndexes);
//   }

//   Future<void> _scrollToTirePosition(int index) async {
//     if (index < 0 || index >= _positionSectionKeys.length) return;

//     FocusScope.of(context).unfocus();

//     if (_selectedScrollPosition != index) {
//       setState(() {
//         _selectedScrollPosition = index;
//       });
//     }

//     final targetContext = _positionSectionKeys[index].currentContext;
//     if (targetContext == null) return;

//     await Scrollable.ensureVisible(
//       targetContext,
//       duration: const Duration(milliseconds: 350),
//       curve: Curves.easeInOutCubic,
//       alignment: 0.04,
//     );
//   }

//   Widget _buildTirePositionIndex(int itemCount) {
//     final railHeight = (itemCount * 36.0 + 8).clamp(
//       80.0,
//       MediaQuery.of(context).size.height * 0.58,
//     );

//     return ValueListenableBuilder<Set<int>>(
//       valueListenable: _enteredPositionIndexes,
//       builder: (context, enteredIndexes, child) {
//         return Material(
//           elevation: 6,
//           color: Colors.white.withOpacity(0.96),
//           borderRadius: BorderRadius.circular(20),
//           child: Container(
//             width: 40,
//             height: railHeight,
//             padding: const EdgeInsets.symmetric(vertical: 4),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(20),
//               border: Border.all(color: Colors.orange.withOpacity(0.35)),
//             ),
//             child: ListView.builder(
//               padding: EdgeInsets.zero,
//               shrinkWrap: true,
//               itemCount: itemCount,
//               itemBuilder: (context, index) {
//                 final isSelected = _selectedScrollPosition == index;
//                 final hasUserInput = enteredIndexes.contains(index);
//                 final positionLabel = index < position.length
//                     ? position[index]['position']?.toString() ?? '${index + 1}'
//                     : '${index + 1}';

//                 return Semantics(
//                   label: hasUserInput
//                       ? 'Posisi $positionLabel, pernah diinput'
//                       : 'Posisi $positionLabel, belum pernah diinput',
//                   selected: isSelected,
//                   button: true,
//                   child: Tooltip(
//                     message: hasUserInput
//                         ? 'Posisi $positionLabel - pernah diinput'
//                         : 'Posisi $positionLabel - belum pernah diinput',
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(16),
//                       onTap: () => _scrollToTirePosition(index),
//                       child: AnimatedContainer(
//                         duration: const Duration(milliseconds: 180),
//                         height: 32,
//                         margin: const EdgeInsets.symmetric(
//                           horizontal: 4,
//                           vertical: 2,
//                         ),
//                         alignment: Alignment.center,
//                         decoration: BoxDecoration(
//                           color: isSelected
//                               ? Colors.orange
//                               : hasUserInput
//                                   ? Colors.green
//                                   : Colors.transparent,
//                           shape: BoxShape.circle,
//                           border: isSelected && hasUserInput
//                               ? Border.all(color: Colors.green, width: 2)
//                               : null,
//                         ),
//                         child: Text(
//                           positionLabel,
//                           style: TextStyle(
//                             color: isSelected || hasUserInput
//                                 ? Colors.white
//                                 : Colors.black87,
//                             fontSize: 12,
//                             fontWeight: FontWeight.w700,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         );
//       },
//     );
//   }

//   void applyPressureData(String pressureValue) {
//     if (!mounted || position.isEmpty) return;

//     if (_isUnitLocationSelectionPending(hasUnitData: dataUnit.isNotEmpty)) {
//       return;
//     }

//     int? enteredPositionIndex;
//     setState(() {
//       final firstNumber = pressureValue;

//       if (checkAmount < position.length) {
//         final route = selectedRoute >= 0 && selectedRoute < inspectRoute.length
//             ? inspectRoute[selectedRoute]
//             : const <int>[];
//         final targetIndex =
//             checkAmount < route.length ? route[checkAmount] : checkAmount;
//         if (targetIndex < 0 || targetIndex >= position.length) return;

//         log('target position : ${targetIndex}');
//         log('target pressure : ${firstNumber}');

//         // Update Map di index tersebut
//         position[targetIndex]["pressure"] = firstNumber;
//         position[targetIndex]['_pressureFromHistory'] = false;
//         enteredPositionIndex = targetIndex;

//         checkAmount++;
//       }
//     });
//     if (enteredPositionIndex != null) {
//       _markPositionAsEntered(enteredPositionIndex!);
//     }
//     _scheduleDraftSave();
//   }

//   Future<void> _subscribePressureNotifications(
//     List<BluetoothService> services,
//   ) async {
//     final generation = ++_pressureSubscriptionGeneration;
//     for (final subscription in _pressureSubscriptions) {
//       await subscription.cancel();
//     }
//     _pressureSubscriptions.clear();

//     if (!mounted || generation != _pressureSubscriptionGeneration) return;

//     for (final service in services) {
//       for (final characteristic in service.characteristics) {
//         if (!characteristic.properties.notify &&
//             !characteristic.properties.indicate) {
//           continue;
//         }

//         try {
//           await characteristic.setNotifyValue(true);
//           if (!mounted || generation != _pressureSubscriptionGeneration) {
//             return;
//           }

//           final subscription = characteristic.onValueReceived.listen((value) {
//             if (!mounted || generation != _pressureSubscriptionGeneration) {
//               return;
//             }

//             final notification = String.fromCharCodes(value).trim();
//             final rawPressure = notification.contains('|')
//                 ? notification.split('|').first.trim()
//                 : notification;
//             final parsedPressure = double.tryParse(rawPressure);
//             if (parsedPressure == null || !parsedPressure.isFinite) {
//               log('Invalid Bluetooth pressure ignored: $notification');
//               return;
//             }

//             applyPressureData(parsedPressure.floor().toString());
//           });
//           if (generation == _pressureSubscriptionGeneration) {
//             _pressureSubscriptions.add(subscription);
//           } else {
//             await subscription.cancel();
//             return;
//           }
//         } catch (e, stackTrace) {
//           log(
//             'Subscribe Bluetooth pressure failed: $e',
//             stackTrace: stackTrace,
//           );
//         }
//       }
//     }
//   }

//   String get selectedPeriodTypeLabel {
//     switch (selectedPeriodType) {
//       case 'PE':
//         return 'Period End';
//       case 'PI':
//       default:
//         return 'Period Inspection';
//     }
//   }

//   bool get _usesCompanyOnePeriodRules =>
//       homeState.userAccessCompanyId.value == '1';

//   bool get _usesSiteFiveCompanyOnePiRules =>
//       _usesCompanyOnePeriodRules && idSite == '5' && selectedPeriodType == 'PI';

//   bool get _hideHmForPeriod => _usesSiteFiveCompanyOnePiRules;

//   bool get _hideRtdForPeriod => _usesSiteFiveCompanyOnePiRules;

//   bool get _hideSnForPeriod => _usesSiteFiveCompanyOnePiRules;

//   bool get _hideTireComponentForPeriod =>
//       _usesCompanyOnePeriodRules && selectedPeriodType == 'PE';

//   bool get _usePreviousPressureFallbackForPeriod =>
//       _usesCompanyOnePeriodRules && selectedPeriodType == 'PE';

//   void _clearPreviousPressureFallbacksForPi() {
//     for (final item in position) {
//       if (item['_pressureFromHistory'] == true) {
//         item['pressure'] = '';
//         item['_pressureFromHistory'] = false;
//       }
//     }
//   }

//   String _validPressureValue(dynamic value) {
//     final text = value?.toString().trim() ?? '';
//     if (text.isEmpty || text.toLowerCase() == 'null') return '';

//     final number = double.tryParse(text);
//     if (number != null && number <= 0) return '';

//     return text;
//   }

//   String _nonEmptySourceValue(dynamic value) {
//     final text = value?.toString().trim() ?? '';
//     if (text.isEmpty || text.toLowerCase() == 'null') return '';
//     return text;
//   }

//   Map<dynamic, dynamic>? _historyPositionAt(
//     List<dynamic> positions,
//     int index,
//   ) {
//     final positionNumber =
//         position[index]['position']?.toString() ?? '${index + 1}';

//     for (final item in positions) {
//       if (item is Map &&
//           (item['position'] ?? item['pos'])?.toString() == positionNumber) {
//         return item;
//       }
//     }

//     if (index < positions.length && positions[index] is Map) {
//       return positions[index] as Map<dynamic, dynamic>;
//     }

//     return null;
//   }

//   Future<void> _loadHiddenFieldFallbacks() async {
//     if (!_usesCompanyOnePeriodRules || position.isEmpty) {
//       return;
//     }

//     final unitNumber = dataUnit['unitNumber']?.toString().trim() ?? '';
//     if (unitNumber.isEmpty) return;

//     final requestId = ++_hiddenFieldRequestId;
//     setState(() {
//       _isLoadingHiddenFieldFallbacks = true;
//     });

//     try {
//       final snapshot = await firestore
//           .collection('tire_inspection')
//           .where('unit', isEqualTo: unitNumber)
//           .orderBy('tanggal', descending: true)
//           .limit(10)
//           .get();

//       if (!mounted || requestId != _hiddenFieldRequestId) return;

//       final historyData = <Map<String, dynamic>>[];
//       for (final document in snapshot.docs) {
//         final data = document.data();
//         final documentSite = data['id_site']?.toString().trim() ?? '';
//         if (documentSite.isEmpty || documentSite == idSite) {
//           historyData.add(data);
//         }
//       }

//       String latestDocumentValue(String key) {
//         for (final data in historyData) {
//           final value = _nonEmptySourceValue(data[key]);
//           if (value.isNotEmpty) return value;
//         }
//         return '';
//       }

//       String latestPositionValue(int index, String key) {
//         for (final data in historyData) {
//           final positions = data['posisi'];
//           if (positions is! List) continue;

//           final previousPosition = _historyPositionAt(positions, index);
//           final value = _nonEmptySourceValue(previousPosition?[key]);
//           if (value.isNotEmpty) return value;
//         }
//         return '';
//       }

//       List<Map<String, dynamic>> latestRimCondition(int index) {
//         for (final data in historyData) {
//           final positions = data['posisi'];
//           if (positions is! List) continue;

//           final previousPosition = _historyPositionAt(positions, index);
//           final rimCondition = previousPosition?['rimCondition'];
//           if (rimCondition is List && rimCondition.isNotEmpty) {
//             return rimCondition
//                 .whereType<Map>()
//                 .map((item) => Map<String, dynamic>.from(item))
//                 .toList();
//           }
//         }
//         return <Map<String, dynamic>>[];
//       }

//       setState(() {
//         if (_hideHmForPeriod) {
//           final firebaseHm = latestDocumentValue('hm');
//           hmUnit.text = _apiHmForHiddenFields.isNotEmpty
//               ? _apiHmForHiddenFields
//               : firebaseHm;
//         }

//         for (int index = 0; index < position.length; index++) {
//           if (_hideRtdForPeriod) {
//             final apiRtd = _nonEmptySourceValue(position[index]['_apiRtd']);
//             final apiRtd2 = _nonEmptySourceValue(position[index]['_apiRtd2']);
//             final firebaseRtd = latestPositionValue(index, 'rtd1');
//             final firebaseRtd2 = latestPositionValue(index, 'rtd2');

//             position[index]['rtd1'] = apiRtd.isNotEmpty ? apiRtd : firebaseRtd;
//             position[index]['rtd2'] =
//                 apiRtd2.isNotEmpty ? apiRtd2 : firebaseRtd2;

//             if (index < rtd1Controllers.length) {
//               rtd1Controllers[index].text = position[index]['rtd1'].toString();
//             }
//             if (index < rtd2Controllers.length) {
//               rtd2Controllers[index].text = position[index]['rtd2'].toString();
//             }
//           }

//           if (_hideSnForPeriod) {
//             final apiSn = _nonEmptySourceValue(position[index]['_apiSn']);
//             final firebaseSn = latestPositionValue(index, 'sn');
//             position[index]['sn'] = apiSn.isNotEmpty ? apiSn : firebaseSn;

//             if (index < snControllers.length) {
//               snControllers[index].text = position[index]['sn'].toString();
//             }
//           }

//           if (_hideTireComponentForPeriod) {
//             final historicalRimCondition = latestRimCondition(index);
//             position[index]['rimCondition'] = historicalRimCondition.isNotEmpty
//                 ? historicalRimCondition
//                 : _defaultRimConditions();
//           }
//         }
//       });
//     } catch (e, stackTrace) {
//       log(
//         'Error loading hidden field fallbacks: $e',
//         stackTrace: stackTrace,
//       );
//     } finally {
//       if (mounted && requestId == _hiddenFieldRequestId) {
//         setState(() {
//           _isLoadingHiddenFieldFallbacks = false;
//         });
//       }
//     }
//   }

//   Future<void> _fillMissingPressureFromHistory() async {
//     if (!_usePreviousPressureFallbackForPeriod || position.isEmpty) return;

//     final missingIndexes = <int>[];
//     for (int index = 0; index < position.length; index++) {
//       if (_validPressureValue(position[index]['pressure']).isEmpty) {
//         missingIndexes.add(index);
//       }
//     }

//     if (missingIndexes.isEmpty) return;

//     final unitNumber = dataUnit['unitNumber']?.toString().trim() ?? '';
//     if (unitNumber.isEmpty) return;

//     final requestId = ++_previousPressureRequestId;
//     setState(() {
//       _isLoadingPreviousPressure = true;
//     });

//     try {
//       final snapshot = await firestore
//           .collection('daily_pressure')
//           .where('unit', isEqualTo: unitNumber)
//           .orderBy('tanggal', descending: true)
//           .limit(10)
//           .get();

//       if (!mounted || requestId != _previousPressureRequestId) return;

//       Map<String, dynamic>? latestData;
//       for (final document in snapshot.docs) {
//         final data = document.data();
//         final documentSite = data['idSite']?.toString().trim() ?? '';
//         if (documentSite.isEmpty || documentSite == idSite) {
//           latestData = data;
//           break;
//         }
//       }

//       final latestPositions = latestData?['posisi'];
//       if (latestPositions is! List) return;

//       setState(() {
//         for (final index in missingIndexes) {
//           if (index >= position.length ||
//               _validPressureValue(position[index]['pressure']).isNotEmpty) {
//             continue;
//           }

//           final previousPosition = _historyPositionAt(latestPositions, index);
//           if (previousPosition == null) continue;

//           final previousPressure =
//               _validPressureValue(previousPosition['pressure']);
//           final previousAdjustment =
//               _validPressureValue(previousPosition['adjusmentPressure']);

//           // Adjustment pressure adalah kondisi tekanan paling akhir. Jika
//           // tidak tersedia, gunakan hasil pressure inspeksi terakhir.
//           final effectivePreviousPressure = previousAdjustment.isNotEmpty
//               ? previousAdjustment
//               : previousPressure;

//           if (effectivePreviousPressure.isNotEmpty) {
//             position[index]['pressure'] = effectivePreviousPressure;
//             position[index]['_pressureFromHistory'] = true;
//           }
//         }
//       });
//     } catch (e, stackTrace) {
//       log(
//         'Error loading previous pressure: $e',
//         stackTrace: stackTrace,
//       );
//     } finally {
//       if (mounted && requestId == _previousPressureRequestId) {
//         setState(() {
//           _isLoadingPreviousPressure = false;
//         });
//       }
//     }
//   }

//   Widget _buildPeriodTypeSelector() {
//     Widget buildOption({
//       required String code,
//       required String label,
//       required IconData icon,
//     }) {
//       final bool isSelected = selectedPeriodType == code;

//       return Expanded(
//         child: InkWell(
//           borderRadius: BorderRadius.circular(8),
//           onTap: () async {
//             setState(() {
//               selectedPeriodType = code;

//               if (code != 'PE') {
//                 _previousPressureRequestId++;
//                 _isLoadingPreviousPressure = false;
//               }

//               if (code == 'PI') {
//                 _hiddenFieldRequestId++;
//                 _isLoadingHiddenFieldFallbacks = false;
//                 _clearPreviousPressureFallbacksForPi();
//               }
//             });
//             _scheduleDraftSave();

//             if (code == 'PE') {
//               await _loadHiddenFieldFallbacks();
//             }
//           },
//           child: AnimatedContainer(
//             duration: const Duration(milliseconds: 180),
//             padding: const EdgeInsets.symmetric(
//               horizontal: 8,
//               vertical: 12,
//             ),
//             decoration: BoxDecoration(
//               color: isSelected ? Colors.orange : greyF7F8F9,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: isSelected ? Colors.orange : Colors.grey.shade300,
//                 width: isSelected ? 1.5 : 1,
//               ),
//               boxShadow: isSelected
//                   ? [
//                       BoxShadow(
//                         color: Colors.orange.withOpacity(0.15),
//                         blurRadius: 4,
//                         offset: const Offset(0, 2),
//                       ),
//                     ]
//                   : null,
//             ),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   icon,
//                   color: isSelected ? Colors.white : Colors.black87,
//                   size: 20,
//                 ),
//                 const SizedBox(width: 6),
//                 Flexible(
//                   child: Text(
//                     label,
//                     textAlign: TextAlign.center,
//                     overflow: TextOverflow.ellipsis,
//                     style: isSelected
//                         ? getWhiteTextStyle(
//                             fontSize: 12,
//                             fontWeight: w700,
//                           )
//                         : getBlackTextStyle(
//                             fontSize: 12,
//                             fontWeight: w700,
//                           ),
//                   ),
//                 ),
//                 const SizedBox(width: 4),
//                 Text(
//                   '($code)',
//                   style: TextStyle(
//                     color: isSelected ? Colors.white70 : Colors.grey.shade600,
//                     fontSize: 10,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       );
//     }

//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             const Icon(
//               Icons.fact_check_outlined,
//               color: Colors.orange,
//               size: 22,
//             ),
//             const SizedBox(width: 6),
//             Text(
//               'Inspection Period',
//               style: getBlackTextStyle(
//                 fontSize: 14,
//                 fontWeight: w700,
//               ),
//             ),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Row(
//           children: [
//             buildOption(
//               code: 'PI',
//               label: 'Period Inspection',
//               icon: Icons.manage_search_outlined,
//             ),
//             const SizedBox(width: 8),
//             buildOption(
//               code: 'PE',
//               label: 'Period End',
//               icon: Icons.event_available_outlined,
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Future<bool> _hasNetworkConnection() async {
//     try {
//       final ConnectivityResult result =
//           await Connectivity().checkConnectivity();

//       return result != ConnectivityResult.none;
//     } catch (e, stackTrace) {
//       log(
//         'connectivity check error: $e',
//         stackTrace: stackTrace,
//       );

//       // Jika pengecekan koneksi gagal, gunakan jalur offline agar Save
//       // tidak berhenti menunggu timeout jaringan.
//       return false;
//     }
//   }

//   bool _isUnitLocationSelectionPending({required bool hasUnitData}) {
//     return hasUnitData &&
//         pit.isNotEmpty &&
//         (selectedPit < 0 || selectedPit >= pit.length);
//   }

//   Widget _buildUnitLocationOptions() {
//     return SizedBox(
//       width: double.infinity,
//       height: 44,
//       child: ListView.separated(
//         scrollDirection: Axis.horizontal,
//         physics: const BouncingScrollPhysics(),
//         padding: const EdgeInsets.symmetric(horizontal: 2),
//         itemCount: pit.length,
//         separatorBuilder: (context, index) => const SizedBox(width: 8),
//         itemBuilder: (context, pitIndex) {
//           final location = pit[pitIndex];

//           return ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor:
//                   selectedPit == pitIndex ? Colors.orange : greyF7F8F9,
//             ),
//             onPressed: () {
//               setState(() {
//                 selectedPit = pitIndex;
//               });
//               _scheduleDraftSave();
//             },
//             child: Text(
//               location,
//               style: selectedPit == pitIndex
//                   ? getWhiteTextStyle()
//                   : getBlackTextStyle(),
//             ),
//           );
//         },
//       ),
//     );
//   }

//   Future<void> _confirmSnChange(int index) async {
//     if (_editableSnIndexes.contains(index)) return;

//     FocusManager.instance.primaryFocus?.unfocus();

//     if (_isSnConfirmationOpen) return;
//     _isSnConfirmationOpen = true;

//     try {
//       final shouldEdit = await showDialog<bool>(
//         context: context,
//         barrierDismissible: false,
//         builder: (dialogContext) {
//           return AlertDialog(
//             title: const Text('Konfirmasi Serial Number'),
//             content: const Text(
//               'Apakah SN aktual pada ban berbeda dengan SN yang tercatat '
//               'di sistem? Mohon periksa kembali sebelum melakukan perubahan.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(dialogContext).pop(false),
//                 child: const Text('Tidak, Sudah Sesuai'),
//               ),
//               ElevatedButton(
//                 onPressed: () => Navigator.of(dialogContext).pop(true),
//                 child: const Text('Ya, Ubah SN'),
//               ),
//             ],
//           );
//         },
//       );

//       if (!mounted || index >= snFocusNodes.length) return;

//       if (shouldEdit == true) {
//         setState(() {
//           _editableSnIndexes.add(index);
//         });

//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted && index < snFocusNodes.length) {
//             snFocusNodes[index].requestFocus();
//           }
//         });
//       } else {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (mounted && index < snFocusNodes.length) {
//             snFocusNodes[index].unfocus();
//           }
//         });
//       }
//     } finally {
//       _isSnConfirmationOpen = false;
//     }
//   }

//   String _selectedPitValue() {
//     // if (!_isPitRequired()) {
//     //   return 'Default';
//     // }

//     if (selectedPit < 0 || selectedPit >= pit.length) {
//       return 'Default';
//     }

//     return pit[selectedPit];
//   }

//   String _sanitizeDocumentIdPart(dynamic value) {
//     final normalized = value?.toString().trim() ?? '';

//     return normalized
//         .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_')
//         .replaceAll(RegExp(r'_+'), '_');
//   }

//   String _buildInspectionDocumentId(DateTime date, String unitNumber) {
//     final datePart =
//         '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

//     return 'inspection_${_sanitizeDocumentIdPart(idSite)}_'
//         '${_sanitizeDocumentIdPart(unitNumber)}_$datePart';
//   }

//   String _buildDailyPressureDocumentId(DateTime date, String unitNumber) {
//     final datePart =
//         '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

//     return 'daily_${_sanitizeDocumentIdPart(idSite)}_'
//         '${_sanitizeDocumentIdPart(unitNumber)}_$datePart';
//   }

//   bool _isPositionEmpty(Map<String, dynamic> item) {
//     final damage = item['damageTire'];
//     final hasDamage = damage is List &&
//         damage.any(
//           (value) => value != null && value.toString().trim().isNotEmpty,
//         );

//     return (item['pressure']?.toString().trim().isEmpty ?? true) &&
//         !hasDamage &&
//         (item['adjusmentPressure']?.toString().trim().isEmpty ?? true) &&
//         (item['rtd1']?.toString().trim().isEmpty ?? true) &&
//         (item['rtd2']?.toString().trim().isEmpty ?? true) &&
//         (item['rating']?.toString().trim().isEmpty ?? true) &&
//         (item['sn']?.toString().trim().isEmpty ?? true) &&
//         (item['remarks']?.toString().trim().isEmpty ?? true);
//   }

//   List<int> _activePositionIndexes() {
//     if (_isEditMode) {
//       return List<int>.generate(position.length, (index) => index);
//     }

//     final indexes = <int>[];

//     for (int i = 0; i < position.length; i++) {
//       if (!_isPositionEmpty(position[i])) {
//         indexes.add(i);
//       }
//     }

//     // Pertahankan seluruh posisi jika semuanya masih kosong agar struktur
//     // posisi ban tetap konsisten dengan data unit.
//     if (indexes.isEmpty) {
//       return List<int>.generate(position.length, (index) => index);
//     }

//     return indexes;
//   }

//   String? _localImagePathAt(int positionIndex) {
//     if (positionIndex < 0 || positionIndex >= position.length) {
//       return null;
//     }

//     try {
//       final images = position[positionIndex]['image'];
//       if (images is! List || images.isEmpty) {
//         return null;
//       }

//       final raw = images.first?.toString() ?? '';
//       if (raw.trim().isEmpty) {
//         return null;
//       }

//       final path = raw.split('|').first.trim();
//       return path.isEmpty ? null : path;
//     } catch (e, stackTrace) {
//       log(
//         'parse local image error: $e',
//         stackTrace: stackTrace,
//       );
//       return null;
//     }
//   }

//   String _defaultDamageRemark() {
//     if (damageType.isNotEmpty) {
//       final remark = damageType.first['remark']?.toString().trim() ?? '';
//       if (remark.isNotEmpty) {
//         return remark;
//       }
//     }

//     return 'Good Condition';
//   }

//   List<Map<String, dynamic>> _buildInspectionPositions(
//     TiresLoadedState state,
//     List<int> activeIndexes,
//   ) {
//     final result = <Map<String, dynamic>>[];

//     for (final index in activeIndexes) {
//       if (index < 0 ||
//           index >= position.length ||
//           index >= state.units.length) {
//         continue;
//       }

//       final item = position[index];
//       final unit = state.units[index];
//       final localImagePath = _localImagePathAt(index);
//       final existingImages = _copyDynamicList(item['_existingImages']);

//       final rawDamage = item['damageTire'];
//       final damages = rawDamage is List
//           ? rawDamage
//               .where(
//                 (value) => value != null && value.toString().trim().isNotEmpty,
//               )
//               .map((value) => value.toString().trim())
//               .toList()
//           : <String>[];

//       if (damages.isEmpty) {
//         damages.add(_defaultDamageRemark());
//       }

//       final typedRemarks = item['remarks']?.toString().trim() ?? '';

//       final originalPosition = item['_editOriginalPosition'] is Map
//           ? Map<String, dynamic>.from(item['_editOriginalPosition'] as Map)
//           : <String, dynamic>{};

//       result.add({
//         ...originalPosition,
//         'position': item['position'] ?? index + 1,
//         'pressure': item['pressure']?.toString() ?? '',
//         'adjusmentPressure': item['adjusmentPressure']?.toString() ?? '',
//         'temperatureStatus': item['temperatureStatus']?.toString() ?? 'HOT',
//         'adjusmentTemperatureStatus':
//             item['adjusmentTemperatureStatus']?.toString() ?? 'HOT',
//         'rating': item['rating']?.toString().trim().isNotEmpty == true
//             ? item['rating'].toString().trim()
//             : 'A',
//         'rtd1': item['rtd1']?.toString() ?? '',
//         'rtd2': item['rtd2']?.toString() ?? '',
//         'sn': item['sn']?.toString().trim().isNotEmpty == true
//             ? item['sn'].toString().trim()
//             : unit.sn ?? '',
//         'remarks': typedRemarks.isNotEmpty ? typedRemarks : damages.first,
//         'damageTire': damages,
//         'rimCondition': item['rimCondition'] ?? [],
//         'idUnit': item['idUnit'],
//         'idInventory': item['idInventory'],
//         'tireSize': item['tireSize'],
//         'kunci_tire': unit.kunciTire,
//         'hm': hmUnit.text,
//         'images': localImagePath == null ? existingImages : <dynamic>[],
//         'imagePending': localImagePath != null,
//         'tireAccessories': item['tireAccessories'] ?? [],
//         'brand': unit.brand,
//         'pattern': unit.pattern,
//       });
//     }

//     return result;
//   }

//   List<Map<String, dynamic>> _buildDailyPressurePositions(
//     List<int> activeIndexes,
//     DateTime date,
//   ) {
//     final formattedDate = '${date.month.toString().padLeft(2, '0')}'
//         '${date.day.toString().padLeft(2, '0')}'
//         '${(date.year % 100).toString().padLeft(2, '0')}';

//     final result = <Map<String, dynamic>>[];

//     for (final index in activeIndexes) {
//       if (index < 0 || index >= position.length) {
//         continue;
//       }

//       final item = position[index];
//       final rawDamage = item['damageTire'];
//       final damages = rawDamage is List
//           ? rawDamage
//               .where(
//                 (value) => value != null && value.toString().trim().isNotEmpty,
//               )
//               .map((value) => value.toString().trim())
//               .toList()
//           : <String>[];

//       result.add({
//         'pos': '${item['position'] ?? index + 1}',
//         'pressure': item['pressure']?.toString().trim().isNotEmpty == true
//             ? item['pressure'].toString().trim()
//             : '0',
//         'rating': item['rating']?.toString().trim().isNotEmpty == true
//             ? item['rating'].toString().trim()
//             : 'A',
//         'adjusmentPressure':
//             item['adjusmentPressure']?.toString().trim().isNotEmpty == true
//                 ? item['adjusmentPressure'].toString().trim()
//                 : '0',
//         'temperatureStatus': item['temperatureStatus']?.toString() ?? 'HOT',
//         'adjusmentTemperatureStatus':
//             item['adjusmentTemperatureStatus']?.toString() ?? 'HOT',
//         'luka': damages.isEmpty ? [_defaultDamageRemark()] : damages,
//         'idUnit': item['idUnit'],
//         'idInventory': item['idInventory'],
//         'tireSize': item['tireSize'],
//         'idDaily': '${item['idUnit'] ?? ''}${index + 1}$formattedDate$idSite',
//         'tireAccessories': item['tireAccessories'] ?? [],
//         'rtd1': item['rtd1']?.toString() ?? '',
//         'rtd2': item['rtd2']?.toString() ?? '',
//       });
//     }

//     return result;
//   }

//   Map<String, dynamic> _buildInspectionData(
//     TiresLoadedState state,
//     DateTime now,
//     List<int> activeIndexes, {
//     required bool savedOffline,
//   }) {
//     final firstUnit = state.units.first;
//     final recordDate = _isEditMode ? (_editInspectionDate ?? now) : now;
//     final generatedHari =
//         '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
//     final generatedJam =
//         '${recordDate.hour.toString().padLeft(2, '0')}:${recordDate.minute.toString().padLeft(2, '0')}:${recordDate.second.toString().padLeft(2, '0')}';
//     final hari = _isEditMode
//         ? _nonEmptySourceValue(_editInspectionData?['hari']).isNotEmpty
//             ? _nonEmptySourceValue(_editInspectionData?['hari'])
//             : generatedHari
//         : generatedHari;
//     final jam = _isEditMode
//         ? _nonEmptySourceValue(_editInspectionData?['jam']).isNotEmpty
//             ? _nonEmptySourceValue(_editInspectionData?['jam'])
//             : generatedJam
//         : generatedJam;
//     final originalTimestamp =
//         _nonEmptySourceValue(_editInspectionData?['tanggal']);

//     return {
//       'id': _isEditMode &&
//               _nonEmptySourceValue(_editInspectionData?['id']).isNotEmpty
//           ? _nonEmptySourceValue(_editInspectionData?['id'])
//           : const Uuid().v4(),
//       'id_site': idSite,
//       'user': _effectiveUsername,
//       'user_email': auth.currentUser?.email ?? '',
//       'unit': dataUnit['unitNumber'] ?? firstUnit.unitNumber ?? '',
//       'kunci_unit': firstUnit.kunciUnit ?? '',
//       'hm': hmUnit.text,
//       'hari': hari,
//       'jam': jam,
//       'tanggal': _isEditMode && originalTimestamp.isNotEmpty
//           ? originalTimestamp
//           : recordDate.toIso8601String(),
//       'pit': _selectedPitValue(),
//       'periodType': selectedPeriodType,
//       'periodTypeLabel': selectedPeriodTypeLabel,
//       'posisi': _buildInspectionPositions(state, activeIndexes),
//       'brand': firstUnit.brand,
//       'pattern': firstUnit.pattern,
//       'savedOffline': savedOffline,
//       'syncStatus': savedOffline ? 'pending' : 'synced',
//       'lastLocalUpdate': now.toIso8601String(),
//       if (_isEditMode) 'editedAt': now.toIso8601String(),
//       if (_isEditMode) 'editedBy': auth.currentUser?.email ?? '',
//     };
//   }

//   Map<String, dynamic> _buildDailyPressureData(
//     DateTime now,
//     List<int> activeIndexes, {
//     required bool savedOffline,
//   }) {
//     final recordDate = _isEditMode ? (_editInspectionDate ?? now) : now;
//     final generatedHari =
//         '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
//     final generatedJam =
//         '${recordDate.hour.toString().padLeft(2, '0')}:${recordDate.minute.toString().padLeft(2, '0')}:${recordDate.second.toString().padLeft(2, '0')}';
//     final hari = _isEditMode &&
//             _nonEmptySourceValue(_editInspectionData?['hari']).isNotEmpty
//         ? _nonEmptySourceValue(_editInspectionData?['hari'])
//         : generatedHari;
//     final jam = _isEditMode &&
//             _nonEmptySourceValue(_editInspectionData?['jam']).isNotEmpty
//         ? _nonEmptySourceValue(_editInspectionData?['jam'])
//         : generatedJam;
//     final originalTimestamp =
//         _nonEmptySourceValue(_editInspectionData?['tanggal']);

//     return {
//       'idSite': idSite,
//       'user': _effectiveUsername,
//       'tanggal': _isEditMode && originalTimestamp.isNotEmpty
//           ? originalTimestamp
//           : recordDate.toIso8601String(),
//       'hari': hari,
//       'jam': jam,
//       'unit': idUnit.text,
//       'hm': hmUnit.text,
//       'posisi': _buildDailyPressurePositions(activeIndexes, recordDate),
//       'pit': _selectedPitValue(),
//       'savedOffline': savedOffline,
//       'syncStatus': savedOffline ? 'pending' : 'synced',
//       'lastLocalUpdate': now.toIso8601String(),
//       if (_isEditMode) 'editedAt': now.toIso8601String(),
//       if (_isEditMode) 'editedBy': auth.currentUser?.email ?? '',
//     };
//   }

//   void _queuePendingImages(
//     String inspectionDocumentId,
//     List<int> activeIndexes,
//   ) {
//     for (final index in activeIndexes) {
//       final localImagePath = _localImagePathAt(index);
//       if (localImagePath == null) {
//         continue;
//       }

//       try {
//         UploadQueueService.to.addPending(
//           docId: inspectionDocumentId,
//           filePath: localImagePath,
//           posisiIndex: index,
//         );
//       } catch (e, stackTrace) {
//         log(
//           'add pending image error: $e',
//           stackTrace: stackTrace,
//         );
//       }
//     }
//   }

//   void _saveInspectionOffline(TiresLoadedState state) {
//     final now = DateTime.now();
//     final firstUnit = state.units.first;
//     final unitNumber =
//         dataUnit['unitNumber']?.toString() ?? firstUnit.unitNumber ?? '';
//     final activeIndexes = _activePositionIndexes();

//     final inspectionDocumentId = _buildInspectionDocumentId(now, unitNumber);
//     final dailyDocumentId = _buildDailyPressureDocumentId(now, unitNumber);

//     final inspectionData = _buildInspectionData(
//       state,
//       now,
//       activeIndexes,
//       savedOffline: true,
//     );

//     final dailyPressureData = _buildDailyPressureData(
//       now,
//       activeIndexes,
//       savedOffline: true,
//     );

//     final inspectionWrite =
//         firestore.collection('tire_inspection').doc(inspectionDocumentId).set(
//               inspectionData,
//               SetOptions(merge: true),
//             );
//     final dailyPressureWrite =
//         firestore.collection('daily_pressure').doc(dailyDocumentId).set(
//               dailyPressureData,
//               SetOptions(merge: true),
//             );

//     // Firestore menyelesaikan Future ini setelah write offline benar-benar
//     // tersinkron. Sampai saat itu draft tetap menjadi cadangan lokal.
//     final draftKey = _draftKey;
//     final draftFingerprint = _lastDraftFingerprint;
//     unawaited(() async {
//       try {
//         await Future.wait<void>(<Future<void>>[
//           inspectionWrite,
//           dailyPressureWrite,
//         ]);
//         if (draftKey != null && draftFingerprint != null) {
//           await _deleteDraftIfUnchanged(
//             key: draftKey,
//             fingerprint: draftFingerprint,
//           );
//         }
//       } catch (error, stackTrace) {
//         log(
//           'offline Tire Inspection sync error: $error',
//           stackTrace: stackTrace,
//         );
//       }
//     }());

//     _queuePendingImages(inspectionDocumentId, activeIndexes);
//   }

//   Future<void> _updateInspectionOnline(TiresLoadedState state) async {
//     final now = DateTime.now();
//     final recordDate = _editInspectionDate ?? now;
//     final firstUnit = state.units.first;
//     final unitNumber =
//         dataUnit['unitNumber']?.toString() ?? firstUnit.unitNumber ?? '';
//     final originalHari = _nonEmptySourceValue(_editInspectionData?['hari'])
//             .isNotEmpty
//         ? _nonEmptySourceValue(_editInspectionData?['hari'])
//         : '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
//     final activeIndexes = _activePositionIndexes();

//     final dailyQuery = await firestore
//         .collection('daily_pressure')
//         .where('unit', isEqualTo: unitNumber)
//         .where('hari', isEqualTo: originalHari)
//         .limit(10)
//         .get();

//     QueryDocumentSnapshot<Map<String, dynamic>>? matchingDailyDocument;
//     for (final document in dailyQuery.docs) {
//       final documentSite = document.data()['idSite']?.toString().trim() ?? '';
//       if (documentSite.isEmpty || documentSite == idSite) {
//         matchingDailyDocument = document;
//         break;
//       }
//     }

//     final dailyDocumentId = matchingDailyDocument?.id ??
//         _buildDailyPressureDocumentId(recordDate, unitNumber);
//     final dailyPressureData = _buildDailyPressureData(
//       now,
//       activeIndexes,
//       savedOffline: false,
//     );
//     final oldDailyPositions = matchingDailyDocument?.data()['posisi'];
//     final newDailyPositions = dailyPressureData['posisi'];
//     if (oldDailyPositions is List && newDailyPositions is List) {
//       dailyPressureData['posisi'] = List<Map<String, dynamic>>.generate(
//         newDailyPositions.length,
//         (index) {
//           final oldPosition = index < oldDailyPositions.length &&
//                   oldDailyPositions[index] is Map
//               ? Map<String, dynamic>.from(oldDailyPositions[index] as Map)
//               : <String, dynamic>{};
//           final newPosition = newDailyPositions[index] is Map
//               ? Map<String, dynamic>.from(newDailyPositions[index] as Map)
//               : <String, dynamic>{};
//           return <String, dynamic>{...oldPosition, ...newPosition};
//         },
//       );
//     }

//     final batch = firestore.batch();
//     batch.set(
//       firestore.collection('tire_inspection').doc(
//             _editInspectionDocumentId,
//           ),
//       _buildInspectionData(
//         state,
//         now,
//         activeIndexes,
//         savedOffline: false,
//       ),
//       SetOptions(merge: true),
//     );
//     batch.set(
//       firestore.collection('daily_pressure').doc(dailyDocumentId),
//       dailyPressureData,
//       SetOptions(merge: true),
//     );
//     await batch.commit();

//     _queuePendingImages(_editInspectionDocumentId, activeIndexes);
//   }

//   Future<void> _saveInspectionOnline(TiresLoadedState state) async {
//     if (_isEditMode) {
//       await _updateInspectionOnline(state);
//       return;
//     }

//     final now = DateTime.now();
//     final firstUnit = state.units.first;
//     final unitNumber =
//         dataUnit['unitNumber']?.toString() ?? firstUnit.unitNumber ?? '';
//     final hari =
//         '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
//     final activeIndexes = _activePositionIndexes();

//     final inspectionQuery = await firestore
//         .collection('tire_inspection')
//         .where('hari', isEqualTo: hari)
//         .where('unit', isEqualTo: unitNumber)
//         .limit(1)
//         .get();

//     final inspectionDocumentId = inspectionQuery.docs.isNotEmpty
//         ? inspectionQuery.docs.first.id
//         : _buildInspectionDocumentId(now, unitNumber);

//     await firestore.collection('tire_inspection').doc(inspectionDocumentId).set(
//           _buildInspectionData(
//             state,
//             now,
//             activeIndexes,
//             savedOffline: false,
//           ),
//           SetOptions(merge: true),
//         );

//     _queuePendingImages(inspectionDocumentId, activeIndexes);

//     final startOfDay = DateTime(now.year, now.month, now.day);
//     final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

//     final dailyQuery = await firestore
//         .collection('daily_pressure')
//         .where('unit', isEqualTo: unitNumber)
//         .where(
//           'tanggal',
//           isGreaterThanOrEqualTo: startOfDay.toIso8601String(),
//         )
//         .where(
//           'tanggal',
//           isLessThanOrEqualTo: endOfDay.toIso8601String(),
//         )
//         .limit(1)
//         .get();

//     final dailyDocumentId = dailyQuery.docs.isNotEmpty
//         ? dailyQuery.docs.first.id
//         : _buildDailyPressureDocumentId(now, unitNumber);

//     await firestore.collection('daily_pressure').doc(dailyDocumentId).set(
//           _buildDailyPressureData(
//             now,
//             activeIndexes,
//             savedOffline: false,
//           ),
//           SetOptions(merge: true),
//         );
//   }

//   Future<void> _handleSaveTireInspection(TiresLoadedState state) async {
//     if (isLoadingSave || state.units.isEmpty) {
//       return;
//     }

//     if (_isUnitLocationSelectionPending(
//       hasUnitData: state.units.isNotEmpty,
//     )) {
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text(
//             'Please select location of unit first!',
//             style: getWhiteTextStyle(),
//           ),
//         ),
//       );
//       return;
//     }

//     if (_usesCompanyOnePeriodRules && _isLoadingHiddenFieldFallbacks) {
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.orange,
//           content: Text(
//             'Sedang melengkapi data dari API/Firebase. Silakan tunggu.',
//             style: getWhiteTextStyle(),
//           ),
//         ),
//       );
//       return;
//     }

//     if (_usePreviousPressureFallbackForPeriod && _isLoadingPreviousPressure) {
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.orange,
//           content: Text(
//             'Sedang mengambil data pressure terakhir. Silakan tunggu.',
//             style: getWhiteTextStyle(),
//           ),
//         ),
//       );
//       return;
//     }

//     if (_usesSiteFiveCompanyOnePiRules) {
//       await _loadHiddenFieldFallbacks();
//       if (!mounted) return;
//     }

//     if (_usePreviousPressureFallbackForPeriod) {
//       await _fillMissingPressureFromHistory();
//       if (!mounted) return;
//     }

//     if (selectedPeriodType == 'PI') {
//       final missingPressurePositions = <String>[];

//       for (int index = 0; index < state.units.length; index++) {
//         final usesPreviousPressure = index < position.length &&
//             position[index]['_pressureFromHistory'] == true;
//         final pressureValue = index < position.length && !usesPreviousPressure
//             ? _nonEmptySourceValue(position[index]['pressure'])
//             : '';
//         if (pressureValue.isNotEmpty) continue;

//         final formPosition = index < position.length
//             ? _nonEmptySourceValue(position[index]['position'])
//             : '';
//         final unitPosition = _nonEmptySourceValue(state.units[index].posisi);
//         final positionValue =
//             formPosition.isNotEmpty ? formPosition : unitPosition;
//         missingPressurePositions.add(
//           positionValue.isNotEmpty ? positionValue : '${index + 1}',
//         );
//       }

//       if (missingPressurePositions.isNotEmpty) {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: Colors.red,
//             duration: const Duration(seconds: 6),
//             content: Text(
//               'Pressure wajib diisi untuk seluruh posisi pada PI. '
//               'Pilih 0 Psi jika No Tire atau Block Valve. '
//               'Posisi yang belum diisi: '
//               '${missingPressurePositions.join(', ')}.',
//               style: getWhiteTextStyle(),
//             ),
//           ),
//         );
//         return;
//       }
//     }

//     if (_usesCompanyOnePeriodRules) {
//       final missingFields = <String>[];

//       if (_hideHmForPeriod && _nonEmptySourceValue(hmUnit.text).isEmpty) {
//         missingFields.add('HM');
//       }

//       for (int index = 0; index < position.length; index++) {
//         if (_hideRtdForPeriod &&
//             (_nonEmptySourceValue(position[index]['rtd1']).isEmpty ||
//                 _nonEmptySourceValue(position[index]['rtd2']).isEmpty)) {
//           missingFields.add('RTD posisi ${index + 1}');
//         }

//         if (_hideSnForPeriod &&
//             _nonEmptySourceValue(position[index]['sn']).isEmpty) {
//           missingFields.add('SN posisi ${index + 1}');
//         }

//         if (_hideTireComponentForPeriod) {
//           final rimCondition = position[index]['rimCondition'];
//           if (rimCondition is! List || rimCondition.isEmpty) {
//             missingFields.add('Tire Component posisi ${index + 1}');
//           }
//         }
//       }

//       if (missingFields.isNotEmpty) {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: Colors.red,
//             content: Text(
//               'Data API/Firebase belum tersedia: ${missingFields.join(', ')}.',
//               style: getWhiteTextStyle(),
//             ),
//           ),
//         );
//         return;
//       }
//     }

//     if (_usePreviousPressureFallbackForPeriod) {
//       final missingPressurePositions = <String>[];
//       for (int index = 0; index < position.length; index++) {
//         if (_validPressureValue(position[index]['pressure']).isEmpty) {
//           missingPressurePositions.add('${index + 1}');
//         }
//       }

//       if (missingPressurePositions.isNotEmpty) {
//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: Colors.red,
//             content: Text(
//               'Data pressure terakhir tidak ditemukan untuk posisi: '
//               '${missingPressurePositions.join(', ')}.',
//               style: getWhiteTextStyle(),
//             ),
//           ),
//         );
//         return;
//       }
//     }

//     final currentHm =
//         double.tryParse(state.units.first.hm?.toString() ?? '0') ?? 0;
//     final newHm = double.tryParse(hmUnit.text.trim()) ?? 0;

//     if (!_hideHmForPeriod && currentHm > newHm) {
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'SMU/HM tidak bisa berkurang',
//             style: getWhiteTextStyle(),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     if (!_hideHmForPeriod && (newHm - currentHm) > 1000) {
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             'Perubahan SMU/HM tidak bisa lebih dari 1000',
//             style: getWhiteTextStyle(),
//           ),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final errorsRtd = <String>[];
//     final errorsRating = <String>[];

//     const ratingScore = {
//       'A': 4,
//       'B': 3,
//       'C': 2,
//       'X': 1,
//     };

//     final validationLength = state.units.length < position.length
//         ? state.units.length
//         : position.length;

//     for (int i = 0; i < validationLength; i++) {
//       final unit = state.units[i];

//       final actualRtd = double.tryParse(unit.rtd?.toString() ?? '0') ?? 0;
//       final actualRtd2 = double.tryParse(unit.rtd?.toString() ?? '0') ?? 0;

//       final inputRtd = i < rtd1Controllers.length
//           ? double.tryParse(rtd1Controllers[i].text) ?? 0
//           : double.tryParse(position[i]['rtd1']?.toString() ?? '0') ?? 0;
//       final inputRtd2 = i < rtd2Controllers.length
//           ? double.tryParse(rtd2Controllers[i].text) ?? 0
//           : double.tryParse(position[i]['rtd2']?.toString() ?? '0') ?? 0;

//       if (!_hideRtdForPeriod && inputRtd > actualRtd) {
//         errorsRtd.add(
//           'Posisi ${unit.posisi}: RTD input ($inputRtd) melebihi RTD aktual ($actualRtd).',
//         );
//       }

//       if (!_hideRtdForPeriod && inputRtd2 > actualRtd2) {
//         errorsRtd.add(
//           'Posisi ${unit.posisi}: RTD 2 input ($inputRtd2) '
//           'melebihi RTD aktual ($actualRtd2).',
//         );
//       }

//       final actualRating =
//           position[i]['prevRating']?.toString().toUpperCase().trim() ?? '';
//       final inputRating =
//           position[i]['rating']?.toString().toUpperCase().trim() ?? '';

//       if (actualRating.isNotEmpty) {
//         final actualScore = ratingScore[actualRating] ?? 0;
//         final inputScore = ratingScore[inputRating] ?? 0;

//         if (inputScore > actualScore) {
//           errorsRating.add(
//             'Posisi ${unit.posisi}: Rating tidak boleh meningkat dari $actualRating menjadi $inputRating.',
//           );
//         }
//       }
//     }

//     if (errorsRtd.isNotEmpty) {
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 6),
//           content: Text(
//             errorsRtd.join('\n'),
//             style: getWhiteTextStyle(),
//           ),
//         ),
//       );
//       return;
//     }

//     if (errorsRating.isNotEmpty) {
//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 6),
//           content: Text(
//             errorsRating.join('\n'),
//             style: getWhiteTextStyle(),
//           ),
//         ),
//       );
//       return;
//     }

//     if (!mounted) return;

//     await _usernameReady;
//     if (!mounted) return;
//     await _persistEditedUsernameIfNeeded();
//     if (!mounted) return;

//     FocusScope.of(context).unfocus();
//     setState(() {
//       isLoadingSave = true;
//     });

//     try {
//       await _persistDraftIfChanged(force: true);
//       final hasNetwork = await _hasNetworkConnection();

//       if (!hasNetwork) {
//         if (_isEditMode) {
//           if (!mounted) return;
//           setState(() {
//             isLoadingSave = false;
//           });
//           ScaffoldMessenger.of(context).hideCurrentSnackBar();
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               backgroundColor: Colors.orange,
//               content: Text(
//                 'Edit data memerlukan koneksi internet agar dokumen lama tidak terduplikasi.',
//                 style: getWhiteTextStyle(),
//               ),
//             ),
//           );
//           return;
//         }

//         _saveInspectionOffline(state);

//         if (!mounted) return;

//         setState(() {
//           isLoadingSave = false;
//           isSaved = true;
//         });

//         ScaffoldMessenger.of(context).hideCurrentSnackBar();
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             backgroundColor: Colors.orange,
//             duration: const Duration(seconds: 5),
//             content: Text(
//               'Tidak ada jaringan. Data tersimpan di perangkat dan akan disinkronkan otomatis saat koneksi tersedia.',
//               style: getWhiteTextStyle(),
//             ),
//           ),
//         );

//         Navigator.pop(context, true);
//         return;
//       }

//       await _saveInspectionOnline(state).timeout(
//         const Duration(seconds: 15),
//       );

//       if (!mounted) return;

//       setState(() {
//         isLoadingSave = false;
//         isSaved = true;
//       });

//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             _isEditMode
//                 ? 'Data Tire Inspection berhasil diperbarui.'
//                 : 'Successful save data, please check in home page',
//             style: getWhiteTextStyle(),
//           ),
//           backgroundColor: green00968A,
//         ),
//       );

//       await _deleteCurrentDraft();
//       if (!mounted) return;
//       Navigator.pop(context, true);
//     } on TimeoutException catch (e, stackTrace) {
//       log(
//         'save timeout: $e',
//         stackTrace: stackTrace,
//       );

//       if (!mounted) return;

//       setState(() {
//         isLoadingSave = false;
//       });

//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 5),
//           content: Text(
//             'Jaringan terdeteksi tetapi proses online melebihi 15 detik. Periksa kualitas internet lalu coba kembali.',
//             style: getWhiteTextStyle(),
//           ),
//         ),
//       );
//     } catch (e, stackTrace) {
//       log(
//         'save tire inspection error: $e',
//         stackTrace: stackTrace,
//       );

//       if (!mounted) return;

//       setState(() {
//         isLoadingSave = false;
//       });

//       ScaffoldMessenger.of(context).hideCurrentSnackBar();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           backgroundColor: Colors.red,
//           content: Text(
//             'Failed to save data. Please try again.',
//             style: getWhiteTextStyle(),
//           ),
//         ),
//       );
//     } finally {
//       if (mounted && isLoadingSave) {
//         setState(() {
//           isLoadingSave = false;
//         });
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return WillPopScope(
//       onWillPop: _saveDraftBeforeLeaving,
//       child: Scaffold(
//         resizeToAvoidBottomInset: true,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           title: Padding(
//             padding: const EdgeInsets.only(top: 18.0),
//             child: Text(
//               _isEditMode ? 'Edit Tire Inspection' : 'Tire Inspection',
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
//                   onPressed: () async {
//                     final canLeave = await _saveDraftBeforeLeaving();
//                     if (canLeave && mounted) Navigator.pop(context);
//                   },
//                   icon: const Icon(
//                     Icons.arrow_back_ios,
//                     color: black,
//                     size: 24,
//                   )),
//             ),
//           ),
//         ),
//         body: SafeArea(
//             child: BlocConsumer<TireBloc, TireState>(
//           listener: (context, state) {
//             if (state is TiresLoadedState) {
//               if (state.units.isEmpty) {
//                 log('Tire Inspection: unit tidak memiliki data posisi ban.');
//                 return;
//               }
//               if (!_stateMatchesRequestedUnit(state)) {
//                 log(
//                   'Tire Inspection: mengabaikan state lama unit '
//                   '${state.units.first.unitNumber}.',
//                 );
//                 return;
//               }

//               _initializePositions(state);
//             }
//           },
//           builder: (context, state) {
//             if (state is TireLoadingState) {
//               return Center(
//                 child: CircularProgressIndicator(),
//               );
//             }
//             if (state is TiresLoadedState) {
//               final units = state.units;
//               if (!_isFormInitializedFor(state)) {
//                 return const Center(child: CircularProgressIndicator());
//               }
//               final isUnitLocationSelectionPending =
//                   _isUnitLocationSelectionPending(
//                 hasUnitData: units.isNotEmpty,
//               );
//               _syncPositionSectionKeys(units.length);

//               return Stack(
//                 children: [
//                   SingleChildScrollView(
//                     controller: _formScrollController,
//                     child: Padding(
//                       padding: EdgeInsets.fromLTRB(
//                         24,
//                         24,
//                         units.length > 1 ? 54 : 24,
//                         24,
//                       ),
//                       child: Column(
//                         children: [
//                           (pit.isNotEmpty)
//                               ? Row(
//                                   mainAxisAlignment: MainAxisAlignment.start,
//                                   children: [
//                                     Icon(
//                                       Icons.ev_station,
//                                       size: 38,
//                                     ),
//                                     const SizedBox(
//                                       width: 12,
//                                     ),
//                                     Text(
//                                       'Unit Location',
//                                       style: getBlackTextStyle(
//                                           fontSize: 18, fontWeight: w700),
//                                     ),
//                                   ],
//                                 )
//                               : Container(),
//                           SizedBox(
//                             height: (pit.isNotEmpty) ? 24 : 0,
//                           ),
//                           (pit.isNotEmpty)
//                               ? _buildUnitLocationOptions()
//                               : Container(),
//                           SizedBox(
//                             height: (pit.isNotEmpty) ? 24 : 0,
//                           ),
//                           Row(
//                             children: [
//                               const Icon(
//                                 Icons.account_circle,
//                                 color: Colors.blue,
//                                 size: 38,
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   'INSPECTOR',
//                                   style: getBlackTextStyle(
//                                     fontWeight: w700,
//                                     fontSize: 18,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(height: 12),
//                           TextFormField(
//                             controller: usernameCtrl,
//                             keyboardType: TextInputType.name,
//                             textCapitalization: TextCapitalization.words,
//                             onChanged: _handleUsernameChanged,
//                             decoration: InputDecoration(
//                               filled: true,
//                               fillColor: greyF7F8F9,
//                               border: OutlineInputBorder(
//                                 borderRadius: BorderRadius.circular(18),
//                                 borderSide: const BorderSide(color: greyDADADA),
//                               ),
//                               hintText: 'Masukkan username atau nama inspector',
//                               hintStyle: getGreyTextStyle(grey8391A1),
//                             ),
//                           ),
//                           const SizedBox(height: 24),
//                           Row(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Expanded(
//                                 child: Column(
//                                   children: [
//                                     Row(
//                                       children: [
//                                         Icon(
//                                           Icons.front_loader,
//                                           color: Colors.orange,
//                                           size: 38,
//                                         ),
//                                         const SizedBox(
//                                           width: 12,
//                                         ),
//                                         Text(
//                                           'UNIT',
//                                           style: getBlackTextStyle(
//                                               fontWeight: w700, fontSize: 18),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(
//                                       height: 12,
//                                     ),
//                                     SizedBox(
//                                       width: double.infinity,
//                                       child: InputFormWidget(
//                                           isReadOnly: true,
//                                           controller: TextEditingController(
//                                             text: units[0].unitNumber,
//                                           ),
//                                           hint: ''),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(
//                                 width: 12,
//                               ),
//                               Expanded(
//                                 child: Column(
//                                   children: [
//                                     Row(
//                                       children: [
//                                         Icon(
//                                           Icons.watch,
//                                           color: Colors.red,
//                                           size: 38,
//                                         ),
//                                         const SizedBox(
//                                           width: 12,
//                                         ),
//                                         Text(
//                                           (idSite == bmbhauling.idSite &&
//                                                   idSite == '1')
//                                               ? 'KM Unit'
//                                               : 'HM Unit',
//                                           style: getBlackTextStyle(
//                                               fontWeight: w700, fontSize: 18),
//                                         ),
//                                       ],
//                                     ),
//                                     const SizedBox(
//                                       height: 12,
//                                     ),
//                                     SizedBox(
//                                       width: double.infinity,
//                                       child: InputFormWidget(
//                                         controller: hmUnit,
//                                         isDecimalOnly: true,
//                                         type: const TextInputType
//                                             .numberWithOptions(
//                                           decimal: true,
//                                         ),
//                                         hint:
//                                             'Fill ${idSite == bmbhauling.idSite ? 'KM' : 'HM'}',
//                                       ),
//                                     ),
//                                     if (_defaultHmValue.isNotEmpty &&
//                                         !_hideHmForPeriod) ...[
//                                       const SizedBox(height: 6),
//                                       Align(
//                                         alignment: Alignment.centerRight,
//                                         child: OutlinedButton.icon(
//                                           onPressed: _resetHmToDefault,
//                                           icon: const Icon(
//                                             Icons.restart_alt,
//                                             size: 18,
//                                           ),
//                                           label: const Text('Reset HM'),
//                                           style: OutlinedButton.styleFrom(
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 10,
//                                               vertical: 7,
//                                             ),
//                                             minimumSize: const Size(0, 34),
//                                             tapTargetSize: MaterialTapTargetSize
//                                                 .shrinkWrap,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(
//                             height: 12,
//                           ),
//                           if (homeState.userAccessCompanyId.value == '1')
//                             _buildPeriodTypeSelector(),
//                           const SizedBox(
//                             height: 16,
//                           ),
//                           BlocBuilder<ConnectedDevicesCubit,
//                               ConnectedDevicesState>(
//                             builder: (context, cState) {
//                               // Asumsikan perangkat TPMS adalah yang terhubung jika statusnya Success
//                               final isConnected =
//                                   cState is ConnectedDevicesLoadedState &&
//                                       cState.connectedDevices.isNotEmpty;

//                               // Cari perangkat yang terhubung yang memiliki nama yang relevan
//                               // (Anda harus menyesuaikan logika pencarian ini sesuai nama perangkat BT Anda)
//                               final BluetoothDevice? connectedDevice =
//                                   isConnected
//                                       ? cState.connectedDevices
//                                           .firstWhereOrNull(
//                                               (d) => d.advName.isNotEmpty)
//                                       : null;

//                               final String buttonText = isConnected
//                                   ? 'Connected: ${connectedDevice?.advName ?? connectedDevice?.remoteId.str}'
//                                   : 'Scan Devices';

//                               return ButtonWidget(
//                                 // Warna tombol berdasarkan status koneksi
//                                 color: isConnected ? green00968A : Colors.blue,
//                                 name: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: [
//                                     Icon(
//                                       Icons.bluetooth,
//                                       color: white,
//                                     ),
//                                     const SizedBox(width: 6),
//                                     Text(
//                                       buttonText,
//                                       style: getWhiteTextStyle(),
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ],
//                                 ),
//                                 function: () async {},
//                               );
//                             },
//                           ),
//                           BlocListener<BluetoothOnOffCubit,
//                               BluetoothOnOffState>(
//                             listener: (context, onOffState) {
//                               if (onOffState is BluetoothOnState) {
//                                 context
//                                     .read<ConnectedDevicesCubit>()
//                                     .fetchConnectedDevices();
//                               }
//                             },
//                             child: BlocConsumer<ConnectedDevicesCubit,
//                                 ConnectedDevicesState>(
//                               listener: (context, state) {
//                                 if (state is ConnectedDevicesLoadedState &&
//                                     state.connectedDevices.isNotEmpty) {
//                                   context
//                                       .read<DiscoverServicesCubit>()
//                                       .discoverServices(
//                                           state.connectedDevices.first);
//                                 }
//                               },
//                               builder: (context, state) {
//                                 if (state is ConnectedDevicesLoadedState) {
//                                   return BlocConsumer<DiscoverServicesCubit,
//                                       DiscoverServiceState>(
//                                     listener: (context, discoverState) {
//                                       if (discoverState
//                                           is ServicesLoadedState) {
//                                         final services = discoverState.services;
//                                         log('services pgd : $services');
//                                         unawaited(
//                                           _subscribePressureNotifications(
//                                             services,
//                                           ),
//                                         );
//                                       }
//                                     },
//                                     builder: (context, discoverState) {
//                                       if (discoverState
//                                           is ErrorLoadingServiceState) {
//                                         return Center(child: Text('Error'));
//                                       }
//                                       return Container();
//                                     },
//                                   );
//                                 }
//                                 return CircularProgressIndicator();
//                               },
//                             ),
//                           ),
//                           const SizedBox(
//                             height: 12,
//                           ),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.start,
//                             children: [
//                               const Icon(
//                                 Icons.device_thermostat,
//                                 size: 38,
//                               ),
//                               const SizedBox(
//                                 width: 12,
//                               ),
//                               Text(
//                                 'Unit/Tire Temperature',
//                                 style: getBlackTextStyle(
//                                   fontSize: 18,
//                                   fontWeight: w700,
//                                 ),
//                               ),
//                             ],
//                           ),
//                           const SizedBox(
//                             height: 8,
//                           ),
//                           TemperatureStatusSelectorWidget(
//                             selectedStatus: position.isNotEmpty
//                                 ? position.first['temperatureStatus']
//                                         ?.toString() ??
//                                     'HOT'
//                                 : 'HOT',
//                             onChanged: (value) {
//                               setState(() {
//                                 for (final item in position) {
//                                   item['temperatureStatus'] = value;
//                                   item['adjusmentTemperatureStatus'] = value;
//                                 }
//                               });
//                               _scheduleDraftSave();
//                             },
//                           ),
//                           const SizedBox(
//                             height: 16,
//                           ),
//                           ListView.builder(
//                               shrinkWrap: true,
//                               physics: NeverScrollableScrollPhysics(),
//                               itemCount: units.length,
//                               itemBuilder: (context, index) {
//                                 final unit = units[index];
//                                 if (snControllers[index].text.isEmpty) {
//                                   snControllers[index].text = unit.sn ?? '';
//                                 }

//                                 return KeyedSubtree(
//                                   key: _positionSectionKeys[index],
//                                   child: Card(
//                                     elevation: 2,
//                                     child: Container(
//                                       width: MediaQuery.of(context).size.width,
//                                       padding: EdgeInsets.all(24),
//                                       child: Stack(
//                                         children: [
//                                           Opacity(
//                                             opacity: 0.1,
//                                             child: Center(
//                                               child: Text(
//                                                 unit.rating ?? '',
//                                                 style: TextStyle(
//                                                   fontSize: 100,
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.black,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                           Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             children: [
//                                               Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment
//                                                         .spaceBetween,
//                                                 children: [
//                                                   SizedBox(
//                                                     width: 35,
//                                                     height: 53,
//                                                     child: Image.asset(
//                                                       '$imagePath/em_tire_image.png',
//                                                       fit: BoxFit.cover,
//                                                     ),
//                                                   ),
//                                                   Column(
//                                                     crossAxisAlignment:
//                                                         CrossAxisAlignment.end,
//                                                     children: [
//                                                       Text(
//                                                         'Position',
//                                                         style:
//                                                             getBlackTextStyle(
//                                                                 fontSize: 14),
//                                                       ),
//                                                       const SizedBox(
//                                                         height: 6,
//                                                       ),
//                                                       Text(
//                                                         '${index + 1}',
//                                                         style:
//                                                             getBlackTextStyle(
//                                                                 fontSize: 22,
//                                                                 fontWeight:
//                                                                     w700),
//                                                       ),
//                                                     ],
//                                                   )
//                                                 ],
//                                               ),
//                                               Padding(
//                                                 padding: EdgeInsets.symmetric(
//                                                     vertical: 6),
//                                                 child: Divider(
//                                                   thickness: 1.5,
//                                                 ),
//                                               ),
//                                               Column(
//                                                 children: [
//                                                   Row(
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment
//                                                             .spaceBetween,
//                                                     children: [
//                                                       Text(
//                                                         'Unit',
//                                                         style:
//                                                             getBlackTextStyle(
//                                                                 fontWeight:
//                                                                     w700),
//                                                       ),
//                                                       Text(
//                                                         unit.unitNumber ?? '',
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   if (!_hideSnForPeriod)
//                                                     const SizedBox(
//                                                       height: 12,
//                                                     ),
//                                                   if (!_hideSnForPeriod)
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceBetween,
//                                                       children: [
//                                                         Text(
//                                                           'SN',
//                                                           style:
//                                                               getBlackTextStyle(
//                                                                   fontWeight:
//                                                                       w700),
//                                                         ),
//                                                         Text(
//                                                           unit.sn ?? '',
//                                                           style:
//                                                               getBlackTextStyle(),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   const SizedBox(
//                                                     height: 12,
//                                                   ),
//                                                   Row(
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment
//                                                             .spaceBetween,
//                                                     children: [
//                                                       Text(
//                                                         'Brand',
//                                                         style:
//                                                             getBlackTextStyle(
//                                                                 fontWeight:
//                                                                     w700),
//                                                       ),
//                                                       Text(
//                                                         unit.brand ?? '',
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   const SizedBox(
//                                                     height: 12,
//                                                   ),
//                                                   Row(
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment
//                                                             .spaceBetween,
//                                                     children: [
//                                                       Text(
//                                                         'Tire Lifetime',
//                                                         style:
//                                                             getBlackTextStyle(
//                                                                 fontWeight:
//                                                                     w700),
//                                                       ),
//                                                       Text(
//                                                         unit.lifetime ?? '',
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   const SizedBox(
//                                                     height: 12,
//                                                   ),
//                                                   Row(
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment
//                                                             .spaceBetween,
//                                                     children: [
//                                                       Text(
//                                                         'Rating',
//                                                         style:
//                                                             getBlackTextStyle(
//                                                                 fontWeight:
//                                                                     w700),
//                                                       ),
//                                                       Text(
//                                                         unit.rating ?? '',
//                                                         style:
//                                                             getBlackTextStyle(),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   if (!_hideRtdForPeriod)
//                                                     const SizedBox(
//                                                       height: 12,
//                                                     ),
//                                                   if (!_hideRtdForPeriod)
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceBetween,
//                                                       children: [
//                                                         Text(
//                                                           'RTD',
//                                                           style:
//                                                               getBlackTextStyle(
//                                                                   fontWeight:
//                                                                       w700),
//                                                         ),
//                                                         Text(
//                                                           '${unit.rtd} / ${unit.rtd}' ??
//                                                               '',
//                                                           style:
//                                                               getBlackTextStyle(),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                 ],
//                                               ),
//                                               Padding(
//                                                 padding: EdgeInsets.symmetric(
//                                                     vertical: 6),
//                                                 child: Divider(
//                                                   thickness: 1.5,
//                                                 ),
//                                               ),
//                                               Row(
//                                                 mainAxisAlignment:
//                                                     MainAxisAlignment
//                                                         .spaceBetween,
//                                                 children: [
//                                                   Expanded(
//                                                     child: SizedBox(
//                                                       width:
//                                                           MediaQuery.of(context)
//                                                               .size
//                                                               .width,
//                                                       height: 45,
//                                                       child: ElevatedButton(
//                                                         onPressed: () async {
//                                                           FocusScope.of(context)
//                                                               .unfocus();
//                                                           setState(() {
//                                                             // selectedPosIndex = posIndex;
//                                                           });
//                                                           showDialog(
//                                                             context: context,
//                                                             builder:
//                                                                 (BuildContext
//                                                                     context) {
//                                                               return Dialog(
//                                                                 child:
//                                                                     Container(
//                                                                   padding:
//                                                                       EdgeInsets
//                                                                           .all(
//                                                                               20.0),
//                                                                   child:
//                                                                       SingleChildScrollView(
//                                                                     child:
//                                                                         Column(
//                                                                       mainAxisSize:
//                                                                           MainAxisSize
//                                                                               .min,
//                                                                       children: <Widget>[
//                                                                         Text(
//                                                                           'Choose Pressure',
//                                                                           style:
//                                                                               TextStyle(
//                                                                             fontSize:
//                                                                                 24.0,
//                                                                             fontWeight:
//                                                                                 FontWeight.bold,
//                                                                           ),
//                                                                         ),
//                                                                         SizedBox(
//                                                                             height:
//                                                                                 16.0),
//                                                                         Column(),
//                                                                         Wrap(
//                                                                           children:
//                                                                               pressure.map((ps) {
//                                                                             final psIndex =
//                                                                                 pressure.indexOf(ps);
//                                                                             return Padding(
//                                                                               padding: const EdgeInsets.only(right: 16, bottom: 18),
//                                                                               child: ElevatedButton(
//                                                                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                                                                                 onPressed: () {
//                                                                                   final id = Uuid();
//                                                                                   setState(() {
//                                                                                     position[index]['pressure'] = ps;
//                                                                                     position[index]['_pressureFromHistory'] = false;
//                                                                                     Navigator.of(context).pop();
//                                                                                   });
//                                                                                   _markPositionAsEntered(index);
//                                                                                   _scheduleDraftSave();
//                                                                                 },
//                                                                                 child: Text(
//                                                                                   ps,
//                                                                                   style: getWhiteTextStyle(
//                                                                                     fontWeight: w700,
//                                                                                   ),
//                                                                                 ),
//                                                                               ),
//                                                                             );
//                                                                           }).toList(),
//                                                                         ),
//                                                                         Row(
//                                                                           children: [
//                                                                             Expanded(
//                                                                               child: SizedBox(
//                                                                                 width: double.infinity,
//                                                                                 child: InputFormWidget(controller: pressureCtrl, isDigitOnly: true, type: TextInputType.number, hint: 'Input Manual'),
//                                                                               ),
//                                                                             ),
//                                                                             const SizedBox(
//                                                                               width: 6,
//                                                                             ),
//                                                                             ElevatedButton(
//                                                                                 onPressed: () {
//                                                                                   setState(() {
//                                                                                     if (pressureCtrl.text != '') {
//                                                                                       position[index]['pressure'] = pressureCtrl.text;
//                                                                                       position[index]['_pressureFromHistory'] = false;
//                                                                                       _markPositionAsEntered(index);
//                                                                                     }
//                                                                                     pressureCtrl.clear();
//                                                                                     Navigator.of(context).pop();
//                                                                                   });
//                                                                                   _scheduleDraftSave();
//                                                                                 },
//                                                                                 child: Text('Submit'))
//                                                                           ],
//                                                                         ),
//                                                                         SizedBox(
//                                                                             height:
//                                                                                 12.0),
//                                                                         SizedBox(
//                                                                           width:
//                                                                               double.infinity,
//                                                                           child:
//                                                                               ElevatedButton(
//                                                                             onPressed:
//                                                                                 () {
//                                                                               pressureCtrl.clear();
//                                                                               Navigator.of(context).pop();
//                                                                             },
//                                                                             child:
//                                                                                 Text('Close'),
//                                                                           ),
//                                                                         ),
//                                                                       ],
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                               );
//                                                             },
//                                                           );
//                                                         },
//                                                         style: ElevatedButton
//                                                             .styleFrom(
//                                                                 backgroundColor:
//                                                                     Colors.blue,
//                                                                 shape:
//                                                                     RoundedRectangleBorder(
//                                                                   borderRadius:
//                                                                       BorderRadius
//                                                                           .circular(
//                                                                               12),
//                                                                 )),
//                                                         child: (position[index][
//                                                                         'pressure'] ==
//                                                                     '' ||
//                                                                 (position[index]
//                                                                         [
//                                                                         'pressure'] ==
//                                                                     null))
//                                                             ? Row(
//                                                                 mainAxisSize:
//                                                                     MainAxisSize
//                                                                         .min,
//                                                                 children: [
//                                                                   Icon(
//                                                                     Icons.add,
//                                                                     color:
//                                                                         white,
//                                                                   ),
//                                                                   const SizedBox(
//                                                                     width: 6,
//                                                                   ),
//                                                                   Text(
//                                                                     'Pressure',
//                                                                     style:
//                                                                         getWhiteTextStyle(),
//                                                                   )
//                                                                 ],
//                                                               )
//                                                             : Text(
//                                                                 '${position[index]['pressure']} Psi',
//                                                                 style:
//                                                                     getWhiteTextStyle(
//                                                                   fontSize: 24,
//                                                                   fontWeight:
//                                                                       w700,
//                                                                 ),
//                                                               ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   const SizedBox(
//                                                     width: 12,
//                                                   ),
//                                                   // adjusment pressure
//                                                   Expanded(
//                                                     child: SizedBox(
//                                                       width:
//                                                           MediaQuery.of(context)
//                                                               .size
//                                                               .width,
//                                                       height: 45,
//                                                       child: ElevatedButton(
//                                                         onPressed: () async {
//                                                           FocusScope.of(context)
//                                                               .unfocus();
//                                                           setState(() {
//                                                             // selectedPosIndex = posIndex;
//                                                           });
//                                                           showDialog(
//                                                             context: context,
//                                                             builder:
//                                                                 (BuildContext
//                                                                     context) {
//                                                               return Dialog(
//                                                                 child:
//                                                                     Container(
//                                                                   padding:
//                                                                       EdgeInsets
//                                                                           .all(
//                                                                               20.0),
//                                                                   child:
//                                                                       SingleChildScrollView(
//                                                                     child:
//                                                                         Column(
//                                                                       mainAxisSize:
//                                                                           MainAxisSize
//                                                                               .min,
//                                                                       children: <Widget>[
//                                                                         Text(
//                                                                           'Choose Pressure',
//                                                                           style:
//                                                                               TextStyle(
//                                                                             fontSize:
//                                                                                 24.0,
//                                                                             fontWeight:
//                                                                                 FontWeight.bold,
//                                                                           ),
//                                                                         ),
//                                                                         SizedBox(
//                                                                             height:
//                                                                                 16.0),
//                                                                         Column(),
//                                                                         Wrap(
//                                                                           children:
//                                                                               pressure.map((ps) {
//                                                                             final psIndex =
//                                                                                 pressure.indexOf(ps);
//                                                                             return Padding(
//                                                                               padding: const EdgeInsets.only(right: 16, bottom: 18),
//                                                                               child: ElevatedButton(
//                                                                                 style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                                                                                 onPressed: () {
//                                                                                   setState(() {
//                                                                                     position[index]['adjusmentPressure'] = ps;
//                                                                                     Navigator.of(context).pop();
//                                                                                   });
//                                                                                   _markPositionAsEntered(index);
//                                                                                   _scheduleDraftSave();
//                                                                                 },
//                                                                                 child: Text(
//                                                                                   ps,
//                                                                                   style: getWhiteTextStyle(
//                                                                                     fontWeight: w700,
//                                                                                   ),
//                                                                                 ),
//                                                                               ),
//                                                                             );
//                                                                           }).toList(),
//                                                                         ),
//                                                                         Row(
//                                                                           children: [
//                                                                             Expanded(
//                                                                               child: SizedBox(
//                                                                                 width: double.infinity,
//                                                                                 child: InputFormWidget(controller: pressureCtrl, isDigitOnly: true, type: TextInputType.number, hint: 'Input Manual'),
//                                                                               ),
//                                                                             ),
//                                                                             const SizedBox(
//                                                                               width: 6,
//                                                                             ),
//                                                                             ElevatedButton(
//                                                                                 onPressed: () {
//                                                                                   setState(() {
//                                                                                     if (pressureCtrl.text != '') {
//                                                                                       position[index]['adjusmentPressure'] = pressureCtrl.text;
//                                                                                       _markPositionAsEntered(index);
//                                                                                     }
//                                                                                     pressureCtrl.clear();
//                                                                                     Navigator.of(context).pop();
//                                                                                   });
//                                                                                   _scheduleDraftSave();
//                                                                                 },
//                                                                                 child: const Text('Submit'))
//                                                                           ],
//                                                                         ),
//                                                                         SizedBox(
//                                                                             height:
//                                                                                 12.0),
//                                                                         SizedBox(
//                                                                           width:
//                                                                               double.infinity,
//                                                                           child:
//                                                                               ElevatedButton(
//                                                                             onPressed:
//                                                                                 () {
//                                                                               pressureCtrl.clear();
//                                                                               Navigator.of(context).pop();
//                                                                             },
//                                                                             child:
//                                                                                 Text('Close'),
//                                                                           ),
//                                                                         ),
//                                                                       ],
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                               );
//                                                             },
//                                                           );
//                                                         },
//                                                         style: ElevatedButton
//                                                             .styleFrom(
//                                                                 backgroundColor:
//                                                                     Colors.blue,
//                                                                 shape:
//                                                                     RoundedRectangleBorder(
//                                                                   borderRadius:
//                                                                       BorderRadius
//                                                                           .circular(
//                                                                               12),
//                                                                 )),
//                                                         child: (position[index][
//                                                                     'adjusmentPressure'] ==
//                                                                 '')
//                                                             ? Text(
//                                                                 'Adj Pressure',
//                                                                 style:
//                                                                     getWhiteTextStyle(),
//                                                               )
//                                                             : Text(
//                                                                 '${position[index]['adjusmentPressure']} Psi (Adj)',
//                                                                 style:
//                                                                     getWhiteTextStyle(
//                                                                   fontSize: 16,
//                                                                   fontWeight:
//                                                                       w700,
//                                                                 ),
//                                                               ),
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),

//                                               const SizedBox(
//                                                 height: 12,
//                                               ),

//                                               SizedBox(
//                                                 width: MediaQuery.of(context)
//                                                     .size
//                                                     .width,
//                                                 height: 45,
//                                                 child: ElevatedButton(
//                                                   onPressed: () async {
//                                                     FocusScope.of(context)
//                                                         .unfocus();
//                                                     // setState(() {
//                                                     //   selectedPosIndex = posIndex;
//                                                     // });

//                                                     showDialog(
//                                                       context: context,
//                                                       builder: (BuildContext
//                                                           context) {
//                                                         return Dialog(
//                                                           child: Container(
//                                                             padding:
//                                                                 EdgeInsets.all(
//                                                                     20.0),
//                                                             child:
//                                                                 SingleChildScrollView(
//                                                               child: Column(
//                                                                 mainAxisSize:
//                                                                     MainAxisSize
//                                                                         .min,
//                                                                 children: <Widget>[
//                                                                   Text(
//                                                                     'Choose Rating',
//                                                                     style:
//                                                                         TextStyle(
//                                                                       fontSize:
//                                                                           24.0,
//                                                                       fontWeight:
//                                                                           FontWeight
//                                                                               .bold,
//                                                                     ),
//                                                                   ),
//                                                                   SizedBox(
//                                                                       height:
//                                                                           16.0),
//                                                                   Column(),
//                                                                   Wrap(
//                                                                     children:
//                                                                         rating.map(
//                                                                             (rat) {
//                                                                       final ratingIndex =
//                                                                           rating
//                                                                               .indexOf(rat);
//                                                                       return Padding(
//                                                                         padding: const EdgeInsets
//                                                                             .only(
//                                                                             right:
//                                                                                 16,
//                                                                             bottom:
//                                                                                 18),
//                                                                         child:
//                                                                             ElevatedButton(
//                                                                           style:
//                                                                               ElevatedButton.styleFrom(backgroundColor: Colors.green),
//                                                                           onPressed:
//                                                                               () {
//                                                                             setState(() {
//                                                                               position[index]['rating'] = rat;
//                                                                               Navigator.of(context).pop();
//                                                                             });
//                                                                             _markPositionAsEntered(index);
//                                                                             _scheduleDraftSave();
//                                                                           },
//                                                                           child:
//                                                                               Text(
//                                                                             rat,
//                                                                             style:
//                                                                                 getWhiteTextStyle(
//                                                                               fontWeight: w700,
//                                                                             ),
//                                                                           ),
//                                                                         ),
//                                                                       );
//                                                                     }).toList(),
//                                                                   ),
//                                                                   SizedBox(
//                                                                       height:
//                                                                           12.0),
//                                                                   SizedBox(
//                                                                     width: double
//                                                                         .infinity,
//                                                                     child:
//                                                                         ElevatedButton(
//                                                                       onPressed:
//                                                                           () {
//                                                                         pressureCtrl
//                                                                             .clear();
//                                                                         Navigator.of(context)
//                                                                             .pop();
//                                                                       },
//                                                                       child: Text(
//                                                                           'Close'),
//                                                                     ),
//                                                                   ),
//                                                                 ],
//                                                               ),
//                                                             ),
//                                                           ),
//                                                         );
//                                                       },
//                                                     );
//                                                   },
//                                                   style:
//                                                       ElevatedButton.styleFrom(
//                                                           backgroundColor:
//                                                               Colors.blue,
//                                                           shape:
//                                                               RoundedRectangleBorder(
//                                                             borderRadius:
//                                                                 BorderRadius
//                                                                     .circular(
//                                                                         12),
//                                                           )),
//                                                   child: (position[index]
//                                                               ['rating'] ==
//                                                           '')
//                                                       ? Text(
//                                                           'Rating',
//                                                           style:
//                                                               getWhiteTextStyle(),
//                                                         )
//                                                       : Text(
//                                                           'Rating ${position[index]['rating']}',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontSize: 16,
//                                                             fontWeight: w700,
//                                                           ),
//                                                         ),
//                                                 ),
//                                               ),

//                                               const SizedBox(
//                                                 height: 12,
//                                               ),

//                                               Container(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         horizontal: 8,
//                                                         vertical: 4),
//                                                 decoration: BoxDecoration(
//                                                   color: blue344BEF,
//                                                   borderRadius:
//                                                       BorderRadius.circular(8),
//                                                 ),
//                                                 child: Text(
//                                                   'Tire Damage',
//                                                   textAlign: TextAlign.start,
//                                                   style: getBlackTextStyle(
//                                                     fontSize: 12,
//                                                   ).copyWith(
//                                                       color: Colors.white),
//                                                 ),
//                                               ),

//                                               SizedBox(
//                                                 width: MediaQuery.of(context)
//                                                     .size
//                                                     .width,
//                                                 child: ElevatedButton(
//                                                   onPressed: () {
//                                                     if (index == 0)
//                                                       log('luka map : ${position[index]['damageTire']}');
//                                                     FocusScope.of(context)
//                                                         .unfocus();

//                                                     if (loadingDamages) {
//                                                       // Optional: kasih feedback kalau masih loading
//                                                       ScaffoldMessenger.of(
//                                                               context)
//                                                           .showSnackBar(
//                                                         const SnackBar(
//                                                             content: Text(
//                                                                 'Sedang memuat daftar damage...')),
//                                                       );
//                                                       return;
//                                                     }

//                                                     if (damageType.isEmpty) {
//                                                       ScaffoldMessenger.of(
//                                                               context)
//                                                           .showSnackBar(
//                                                         const SnackBar(
//                                                             content: Text(
//                                                                 'Daftar damage kosong')),
//                                                       );
//                                                       return;
//                                                     }

//                                                     final List<dynamic>
//                                                         existingDamages =
//                                                         position[index][
//                                                                 'damageTire'] ??
//                                                             [];

//                                                     List<bool>
//                                                         checkedDamageValues;

//                                                     if (existingDamages
//                                                             .isEmpty ||
//                                                         existingDamages[0] ==
//                                                             "") {
//                                                       print(
//                                                           'exisitng damage empty true');
//                                                       // otomatis centang Good Condition jika belum ada damage
//                                                       checkedDamageValues =
//                                                           damageType
//                                                               .map((damage) {
//                                                         final text =
//                                                             damage['remark']
//                                                                 .toString()
//                                                                 .toLowerCase()
//                                                                 .trim();
//                                                         return text == 'good' ||
//                                                             text ==
//                                                                 'good condition';
//                                                       }).toList();
//                                                     } else {
//                                                       print(
//                                                           'exisitng damage empty false');
//                                                       // jika sudah ada data damage
//                                                       checkedDamageValues =
//                                                           damageType
//                                                               .map((damage) {
//                                                         return existingDamages
//                                                             .contains(damage[
//                                                                 'remark']);
//                                                       }).toList();
//                                                     }

//                                                     showDialog(
//                                                       context: context,
//                                                       builder: (BuildContext
//                                                           context) {
//                                                         return Dialog(
//                                                           child: Container(
//                                                             padding:
//                                                                 const EdgeInsets
//                                                                     .all(20.0),
//                                                             child: Column(
//                                                               mainAxisSize:
//                                                                   MainAxisSize
//                                                                       .min,
//                                                               children: <Widget>[
//                                                                 const Text(
//                                                                   'Choose Damage Tire',
//                                                                   style:
//                                                                       TextStyle(
//                                                                     fontSize:
//                                                                         24.0,
//                                                                     fontWeight:
//                                                                         FontWeight
//                                                                             .bold,
//                                                                   ),
//                                                                 ),
//                                                                 const SizedBox(
//                                                                     height:
//                                                                         12.0),
//                                                                 Expanded(
//                                                                   child:
//                                                                       SingleChildScrollView(
//                                                                     child:
//                                                                         Column(
//                                                                       children:
//                                                                           damageType
//                                                                               .map((damage) {
//                                                                         final dmgIndex =
//                                                                             damageType.indexOf(damage);

//                                                                         // kalau tidak perlu skip index 0, hapus if ini
//                                                                         // if (dmgIndex == 0) return Container();

//                                                                         return StatefulBuilder(
//                                                                           builder:
//                                                                               (context, setState) {
//                                                                             return CheckboxListTile(
//                                                                               title: Text(damage['remark']),
//                                                                               value: checkedDamageValues[dmgIndex],
//                                                                               onChanged: (bool? value) {
//                                                                                 setState(() {
//                                                                                   bool newValue = value ?? false;

//                                                                                   if (dmgIndex == 0) {
//                                                                                     // GOOD CONDITION dicentang
//                                                                                     checkedDamageValues = List<bool>.filled(checkedDamageValues.length, false);
//                                                                                     checkedDamageValues[0] = newValue;
//                                                                                   } else {
//                                                                                     // Damage lain dicentang
//                                                                                     checkedDamageValues[dmgIndex] = newValue;

//                                                                                     if (newValue) {
//                                                                                       // otomatis uncheck Good Condition
//                                                                                       checkedDamageValues[0] = false;
//                                                                                     }
//                                                                                   }
//                                                                                 });
//                                                                               },
//                                                                             );
//                                                                           },
//                                                                         );
//                                                                       }).toList(),
//                                                                     ),
//                                                                   ),
//                                                                 ),
//                                                                 const SizedBox(
//                                                                     height:
//                                                                         12.0),
//                                                                 Column(
//                                                                   children: [
//                                                                     const SizedBox(
//                                                                         height:
//                                                                             12),
//                                                                     SizedBox(
//                                                                       width: double
//                                                                           .infinity,
//                                                                       child:
//                                                                           ElevatedButton(
//                                                                         onPressed:
//                                                                             () {
//                                                                           damageCtrl
//                                                                               .clear();
//                                                                           _scheduleDraftSave();
//                                                                           Navigator.pop(
//                                                                               context);
//                                                                         },
//                                                                         child: const Text(
//                                                                             'Close'),
//                                                                       ),
//                                                                     ),
//                                                                     const SizedBox(
//                                                                         height:
//                                                                             12),
//                                                                     SizedBox(
//                                                                       width: double
//                                                                           .infinity,
//                                                                       child:
//                                                                           ElevatedButton(
//                                                                         style: ElevatedButton
//                                                                             .styleFrom(
//                                                                           backgroundColor:
//                                                                               Colors.green,
//                                                                         ),
//                                                                         onPressed:
//                                                                             () {
//                                                                           selectedDamage
//                                                                               .clear();

//                                                                           Map<String, int>
//                                                                               ratingPriority =
//                                                                               {
//                                                                             '': 1,
//                                                                             'A':
//                                                                                 1,
//                                                                             'B':
//                                                                                 2,
//                                                                             'C':
//                                                                                 3,
//                                                                             'X':
//                                                                                 4,
//                                                                           };

//                                                                           final List<Map<String, dynamic>>
//                                                                               tmp =
//                                                                               [];

//                                                                           // NOTE: ini tadinya if (== '' || isNotEmpty) -> selalu true.
//                                                                           if (damageCtrl
//                                                                               .text
//                                                                               .isNotEmpty) {
//                                                                             tmp.add({
//                                                                               'remark': damageCtrl.text,
//                                                                               'rating': ''
//                                                                             });
//                                                                           }

//                                                                           for (int i = 0;
//                                                                               i < checkedDamageValues.length;
//                                                                               i++) {
//                                                                             if (checkedDamageValues[i]) {
//                                                                               tmp.add(damageType[i]);
//                                                                             }
//                                                                           }

//                                                                           final onlyRemark = tmp
//                                                                               .map<String>((item) => item['remark']?.toString() ?? '')
//                                                                               .where((remark) => remark.isNotEmpty)
//                                                                               .toList();

//                                                                           position[index]['damageTire'] =
//                                                                               onlyRemark;

//                                                                           if (tmp
//                                                                               .isNotEmpty) {
//                                                                             position[index]['damageTire'] =
//                                                                                 onlyRemark;

//                                                                             // rating based damage
//                                                                             String
//                                                                                 worstRating =
//                                                                                 '';
//                                                                             worstRating =
//                                                                                 tmp.fold(
//                                                                               '',
//                                                                               (worst, item) {
//                                                                                 final current = item['rating'] ?? '';

//                                                                                 return ratingPriority[current]! > ratingPriority[worst]! ? current : worst;
//                                                                               },
//                                                                             );

//                                                                             if (_usesAutomaticDamageRating) {
//                                                                               position[index]['rating'] = worstRating;
//                                                                             }

//                                                                             selectedDamage.addAll(onlyRemark);

//                                                                             log('hasil luka ban : $position');
//                                                                           }

//                                                                           if (tmp
//                                                                               .isNotEmpty) {
//                                                                             _markPositionAsEntered(index);
//                                                                           }
//                                                                           setState(
//                                                                               () {});
//                                                                           _scheduleDraftSave();
//                                                                           damageCtrl
//                                                                               .clear();
//                                                                           Navigator.pop(
//                                                                               context);
//                                                                         },
//                                                                         child:
//                                                                             Text(
//                                                                           'Submit',
//                                                                           style:
//                                                                               getWhiteTextStyle(
//                                                                             fontWeight:
//                                                                                 w700,
//                                                                           ),
//                                                                         ),
//                                                                       ),
//                                                                     ),
//                                                                   ],
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         );
//                                                       },
//                                                     );
//                                                   },
//                                                   style:
//                                                       ElevatedButton.styleFrom(
//                                                     backgroundColor: blue344BEF,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               12),
//                                                     ),
//                                                   ),
//                                                   child: Padding(
//                                                     padding: const EdgeInsets
//                                                         .symmetric(
//                                                         vertical: 8.0),
//                                                     child: Text(
//                                                       ((position[index][
//                                                                       'damageTire'] ==
//                                                                   null) ||
//                                                               (position[index][
//                                                                           'damageTire']
//                                                                       as List)
//                                                                   .where((e) =>
//                                                                       e !=
//                                                                           null &&
//                                                                       e
//                                                                           .toString()
//                                                                           .trim()
//                                                                           .isNotEmpty)
//                                                                   .isEmpty)
//                                                           ? 'Good Condition'
//                                                           : (position[index][
//                                                                       'damageTire']
//                                                                   as List)
//                                                               .join('\n---\n'),
//                                                       textAlign:
//                                                           TextAlign.center,
//                                                       style: getWhiteTextStyle(
//                                                           fontSize: 14),
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ),

//                                               const SizedBox(
//                                                 height: 12,
//                                               ),
//                                               SizedBox(
//                                                 width: double.infinity,
//                                                 height: 45,
//                                                 child: ElevatedButton(
//                                                   style:
//                                                       ElevatedButton.styleFrom(
//                                                     backgroundColor:
//                                                         Colors.orange,
//                                                     shape:
//                                                         RoundedRectangleBorder(
//                                                       borderRadius:
//                                                           BorderRadius.circular(
//                                                               12),
//                                                     ),
//                                                   ),
//                                                   onPressed: () {
//                                                     showRimInspectionDialog(
//                                                         index);
//                                                   },
//                                                   child: Text(
//                                                     'Check Tire Component Condition',
//                                                     style: getWhiteTextStyle(
//                                                         fontWeight: w700),
//                                                   ),
//                                                 ),
//                                               ),
//                                               const SizedBox(
//                                                 height: 16,
//                                               ),
//                                               SizedBox(
//                                                 width: double.infinity,
//                                                 height: 45,
//                                                 child: ElevatedButton(
//                                                     style: ElevatedButton
//                                                         .styleFrom(
//                                                             backgroundColor:
//                                                                 Colors.green,
//                                                             shape:
//                                                                 RoundedRectangleBorder(
//                                                               borderRadius:
//                                                                   BorderRadius
//                                                                       .circular(
//                                                                           12),
//                                                             )),
//                                                     onPressed: () async {
//                                                       final ImagePicker picker =
//                                                           ImagePicker();

//                                                       final ImageSource?
//                                                           source =
//                                                           await showDialog<
//                                                               ImageSource>(
//                                                         context: context,
//                                                         builder: (context) {
//                                                           return AlertDialog(
//                                                             title: Text(
//                                                                 "Pilih Sumber Gambar"),
//                                                             content: Column(
//                                                               mainAxisSize:
//                                                                   MainAxisSize
//                                                                       .min,
//                                                               children: [
//                                                                 ListTile(
//                                                                   leading: Icon(
//                                                                       Icons
//                                                                           .camera_alt),
//                                                                   title: Text(
//                                                                       "Kamera"),
//                                                                   onTap: () => Navigator.pop(
//                                                                       context,
//                                                                       ImageSource
//                                                                           .camera),
//                                                                 ),
//                                                                 ListTile(
//                                                                   leading: Icon(
//                                                                       Icons
//                                                                           .photo_library),
//                                                                   title: Text(
//                                                                       "Gallery"),
//                                                                   onTap: () => Navigator.pop(
//                                                                       context,
//                                                                       ImageSource
//                                                                           .gallery),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           );
//                                                         },
//                                                       );

//                                                       // final XFile? image =
//                                                       //     await picker.pickImage(
//                                                       //         imageQuality: 50,
//                                                       //         source:
//                                                       //             // ImageSource.camera);
//                                                       //             ImageSource.gallery);

//                                                       if (source == null)
//                                                         return;

//                                                       if (source ==
//                                                           ImageSource.camera) {
//                                                         requestCameraPermission();
//                                                       }

//                                                       final XFile? image =
//                                                           await picker
//                                                               .pickImage(
//                                                         source: source,
//                                                         imageQuality: 70,
//                                                         maxWidth: 1920,
//                                                         maxHeight: 1920,
//                                                       );

//                                                       try {
//                                                         if (image != null) {
//                                                           Directory? directory;

//                                                           if (Platform
//                                                               .isAndroid) {
//                                                             // path = await getExternalStorageDirectory();
//                                                             directory =
//                                                                 await DownloadsPath
//                                                                     .downloadsDirectory();
//                                                           }

//                                                           if (Platform.isIOS) {
//                                                             // final directory = await getApplicationDocumentsDirectory();
//                                                             // path = directory;
//                                                             directory =
//                                                                 await getApplicationDocumentsDirectory();
//                                                           }

//                                                           // Read image as a file
//                                                           File imageFile =
//                                                               File(image.path);
//                                                           // data size fotonya
//                                                           final compressedFilePath =
//                                                               '${directory?.path}/${DateTime.now().millisecondsSinceEpoch}_tireinspectionimage_compressed.jpg';

//                                                           // Compress the image if needed (optional)
//                                                           final compressedImageFile =
//                                                               await FlutterImageCompress
//                                                                   .compressAndGetFile(
//                                                             imageFile.path,
//                                                             compressedFilePath,
//                                                             quality: 70,
//                                                             minWidth: 1280,
//                                                             minHeight: 1280,
//                                                           );
//                                                           log('gambar : ${compressedFilePath}');

//                                                           if (compressedImageFile ==
//                                                               null) {
//                                                             throw Exception(
//                                                               'Failed to compress image.',
//                                                             );
//                                                           }

//                                                           // Simpan foto saja. Analisa AI dijalankan manual
//                                                           // melalui tombol Analyze Damage with AI.
//                                                           setState(() {
//                                                             position[index]
//                                                                 ['image'] = [
//                                                               '${compressedImageFile.path}|${position[index]['position']}'
//                                                             ];

//                                                             // Hapus hasil AI dari foto sebelumnya.
//                                                             aiResults
//                                                                 .remove(index);
//                                                             imageWidths
//                                                                 .remove(index);
//                                                             imageHeights
//                                                                 .remove(index);
//                                                             loadingAI[index] =
//                                                                 false;
//                                                           });
//                                                           _markPositionAsEntered(
//                                                               index);
//                                                           _scheduleDraftSave();

//                                                           log('tire inspection image = ${position[index]['image']}');
//                                                         }
//                                                       } catch (e) {
//                                                         log('error gambar string : $e');
//                                                       }

//                                                       setState(() {});
//                                                     },
//                                                     child: Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .center,
//                                                       children: [
//                                                         Icon(
//                                                           Icons.camera_alt,
//                                                           color: white,
//                                                         ),
//                                                         const SizedBox(
//                                                           width: 12,
//                                                         ),
//                                                         Text(
//                                                           'Take Picture',
//                                                           style:
//                                                               getWhiteTextStyle(),
//                                                         ),
//                                                       ],
//                                                     )),
//                                               ),
//                                               const SizedBox(
//                                                 height: 12,
//                                               ),
//                                               Text(
//                                                 '*You can only take one picture. If you take another picture, the previous one will be deleted.',
//                                                 style: getRedTextStyle(),
//                                               ),
//                                               const SizedBox(
//                                                 height: 12,
//                                               ),
//                                               ((position[index]['image']
//                                                           as List<dynamic>)
//                                                       .isNotEmpty)
//                                                   ? Column(
//                                                       children: [
//                                                         SizedBox(
//                                                           width:
//                                                               double.infinity,
//                                                           height: 45,
//                                                           child: ElevatedButton(
//                                                               style: ElevatedButton
//                                                                   .styleFrom(
//                                                                       backgroundColor:
//                                                                           Colors
//                                                                               .deepOrange,
//                                                                       shape:
//                                                                           RoundedRectangleBorder(
//                                                                         borderRadius:
//                                                                             BorderRadius.circular(12),
//                                                                       )),
//                                                               onPressed:
//                                                                   () async {
//                                                                 showDialog(
//                                                                     context:
//                                                                         context,
//                                                                     builder:
//                                                                         (context) {
//                                                                       return AlertDialog(
//                                                                         content:
//                                                                             Text(
//                                                                           'Are you sure you want to delete this image?',
//                                                                           style:
//                                                                               getBlackTextStyle(),
//                                                                         ),
//                                                                         actions: [
//                                                                           TextButton(
//                                                                               onPressed: () {
//                                                                                 Navigator.pop(context);
//                                                                               },
//                                                                               child: Text(
//                                                                                 'Cancel',
//                                                                                 style: getGreyTextStyle(grey8391A1),
//                                                                               )),
//                                                                           TextButton(
//                                                                               onPressed: () {
//                                                                                 setState(() {
//                                                                                   position[index]['image'] = [];
//                                                                                   aiResults.remove(index);
//                                                                                   loadingAI.remove(index);
//                                                                                   imageWidths.remove(index);
//                                                                                   imageHeights.remove(index);
//                                                                                 });
//                                                                                 _scheduleDraftSave();
//                                                                                 Navigator.pop(context);
//                                                                               },
//                                                                               child: Text(
//                                                                                 'Yes',
//                                                                                 style: getRedTextStyle(),
//                                                                               )),
//                                                                         ],
//                                                                       );
//                                                                     });

//                                                                 setState(() {});
//                                                               },
//                                                               child: Row(
//                                                                 mainAxisAlignment:
//                                                                     MainAxisAlignment
//                                                                         .center,
//                                                                 children: [
//                                                                   Icon(
//                                                                     Icons
//                                                                         .delete,
//                                                                     color:
//                                                                         white,
//                                                                   ),
//                                                                   const SizedBox(
//                                                                     width: 12,
//                                                                   ),
//                                                                   Text(
//                                                                     'Delete Picture',
//                                                                     style:
//                                                                         getWhiteTextStyle(),
//                                                                   ),
//                                                                 ],
//                                                               )),
//                                                         ),
//                                                         const SizedBox(
//                                                           height: 12,
//                                                         ),
//                                                         (loadingAI[index] ==
//                                                                 true)
//                                                             ? Center(
//                                                                 child:
//                                                                     AiLoadingWidget(),
//                                                               )
//                                                             : Stack(
//                                                                 children: [
//                                                                   Container(
//                                                                     width: double
//                                                                         .infinity,
//                                                                     decoration:
//                                                                         BoxDecoration(
//                                                                       borderRadius:
//                                                                           BorderRadius.circular(
//                                                                               12),
//                                                                     ),
//                                                                     child: Image
//                                                                         .file(
//                                                                       File(
//                                                                         (position[index]['image'][0]
//                                                                                 as String)
//                                                                             .split('|')[0],
//                                                                       ),
//                                                                       cacheWidth:
//                                                                           1080,
//                                                                       fit: BoxFit
//                                                                           .contain,
//                                                                     ),
//                                                                   ),
//                                                                   if (aiResults[
//                                                                           index] !=
//                                                                       null)
//                                                                     Positioned
//                                                                         .fill(
//                                                                       child:
//                                                                           CustomPaint(
//                                                                         painter:
//                                                                             BoundingBoxPainter(
//                                                                           detections:
//                                                                               aiResults[index]?.data?.tireDamageResult ?? [],
//                                                                           imageWidth:
//                                                                               imageWidths[index] ?? 1,
//                                                                           imageHeight:
//                                                                               imageHeights[index] ?? 1,
//                                                                         ),
//                                                                       ),
//                                                                     ),
//                                                                 ],
//                                                               ),
//                                                         const SizedBox(
//                                                           height: 12,
//                                                         ),
//                                                         SizedBox(
//                                                           width:
//                                                               double.infinity,
//                                                           height: 45,
//                                                           child: ElevatedButton(
//                                                             style:
//                                                                 ElevatedButton
//                                                                     .styleFrom(
//                                                               backgroundColor:
//                                                                   Colors.purple,
//                                                               shape:
//                                                                   RoundedRectangleBorder(
//                                                                 borderRadius:
//                                                                     BorderRadius
//                                                                         .circular(
//                                                                             12),
//                                                               ),
//                                                             ),
//                                                             onPressed: loadingAI[
//                                                                         index] ==
//                                                                     true
//                                                                 ? null
//                                                                 : () async {
//                                                                     await _analyzeDamageWithAI(
//                                                                       index,
//                                                                     );
//                                                                   },
//                                                             child: Row(
//                                                               mainAxisAlignment:
//                                                                   MainAxisAlignment
//                                                                       .center,
//                                                               children: [
//                                                                 const Icon(
//                                                                   Icons
//                                                                       .auto_awesome,
//                                                                   color: white,
//                                                                 ),
//                                                                 const SizedBox(
//                                                                   width: 12,
//                                                                 ),
//                                                                 Text(
//                                                                   aiResults[index] ==
//                                                                           null
//                                                                       ? 'Analyze Damage with AI'
//                                                                       : 'Analyze Again with AI',
//                                                                   style:
//                                                                       getWhiteTextStyle(
//                                                                     fontWeight:
//                                                                         w700,
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ),
//                                                         ),
//                                                         const SizedBox(
//                                                           height: 12,
//                                                         ),
//                                                       ],
//                                                     )
//                                                   : Container(),

//                                               // Show More Images
//                                               // (listImg.isNotEmpty)
//                                               //     ? Column(
//                                               //         children: [
//                                               //           SizedBox(
//                                               //             width: double.infinity,
//                                               //             height: 45,
//                                               //             child: ElevatedButton(
//                                               //                 style: ElevatedButton
//                                               //                     .styleFrom(
//                                               //                         backgroundColor:
//                                               //                             Colors
//                                               //                                 .orange,
//                                               //                         shape:
//                                               //                             RoundedRectangleBorder(
//                                               //                           borderRadius:
//                                               //                               BorderRadius.circular(
//                                               //                                   12),
//                                               //                         )),
//                                               //                 onPressed: () async {
//                                               //                   final CarouselController
//                                               //                       _controller =
//                                               //                       CarouselController();

//                                               //                   showDialog(
//                                               //                       context:
//                                               //                           context,
//                                               //                       builder:
//                                               //                           (BuildContext
//                                               //                               context) {
//                                               //                         return AlertDialog(
//                                               //                           content:
//                                               //                               Padding(
//                                               //                             padding: const EdgeInsets
//                                               //                                 .all(
//                                               //                                 24.0),
//                                               //                             child:
//                                               //                                 Column(
//                                               //                               mainAxisSize:
//                                               //                                   MainAxisSize.min,
//                                               //                               children: [
//                                               //                                 Text(
//                                               //                                   'Show Image',
//                                               //                                   style:
//                                               //                                       getBlackTextStyle(),
//                                               //                                 ),
//                                               //                                 const SizedBox(
//                                               //                                   height:
//                                               //                                       12,
//                                               //                                 ),
//                                               //                                 Container(
//                                               //                                   width:
//                                               //                                       400,
//                                               //                                   height:
//                                               //                                       400,
//                                               //                                   child:
//                                               //                                       CarouselSlider(
//                                               //                                     carouselController: _controller,
//                                               //                                     // items: listImg.map((img) {
//                                               //                                     //   final splitImg = img.split('|');

//                                               //                                     //   if ((position[index]['position']).toString() == splitImg[1]) {
//                                               //                                     //     return Image.file(File(splitImg[0]));
//                                               //                                     //   }
//                                               //                                     //   return Container();
//                                               //                                     // }).toList(),
//                                               //                                     items: listImg
//                                               //                                         .where((img) {
//                                               //                                           final splitImg = img.split('|');
//                                               //                                           return splitImg[1] == (position[index]['position']).toString();
//                                               //                                         })
//                                               //                                         .toList()
//                                               //                                         .map((img2) {
//                                               //                                           final splitImg2 = img2.split('|');
//                                               //                                           return Image.file(File(splitImg2[0]));
//                                               //                                         })
//                                               //                                         .toList(),
//                                               //                                     options: CarouselOptions(
//                                               //                                       aspectRatio: 3.0,
//                                               //                                       height: 400,
//                                               //                                       enableInfiniteScroll: false,
//                                               //                                       enlargeCenterPage: true,
//                                               //                                     ),
//                                               //                                   ),
//                                               //                                 ),
//                                               //                               ],
//                                               //                             ),
//                                               //                           ),
//                                               //                         );
//                                               //                       });
//                                               //                   setState(() {});
//                                               //                 },
//                                               //                 child: Row(
//                                               //                   mainAxisAlignment:
//                                               //                       MainAxisAlignment
//                                               //                           .center,
//                                               //                   children: [
//                                               //                     Icon(
//                                               //                       Icons.image,
//                                               //                       color: white,
//                                               //                     ),
//                                               //                     const SizedBox(
//                                               //                       width: 12,
//                                               //                     ),
//                                               //                     Text(
//                                               //                       'Show Image',
//                                               //                       style:
//                                               //                           getWhiteTextStyle(),
//                                               //                     ),
//                                               //                   ],
//                                               //                 )),
//                                               //           ),
//                                               //           const SizedBox(
//                                               //             height: 12,
//                                               //           ),
//                                               //         ],
//                                               //       )
//                                               //     : Container(),

//                                               if (!_hideRtdForPeriod)
//                                                 Row(
//                                                   children: [
//                                                     Expanded(
//                                                       child: Column(
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .stretch,
//                                                         children: [
//                                                           Text(
//                                                             'RTD 1',
//                                                             style:
//                                                                 getBlackTextStyle(
//                                                                     fontWeight:
//                                                                         w700),
//                                                           ),
//                                                           const SizedBox(
//                                                             height: 12,
//                                                           ),
//                                                           SizedBox(
//                                                             width:
//                                                                 double.infinity,
//                                                             child:
//                                                                 InputFormWidget(
//                                                               onChng: (value) {
//                                                                 position[index][
//                                                                         'rtd1'] =
//                                                                     value;
//                                                                 _markPositionAsEntered(
//                                                                     index);
//                                                               },
//                                                               controller:
//                                                                   rtd1Controllers[
//                                                                       index],
//                                                               hint: '',
//                                                             ),
//                                                           ),
//                                                           // Builder(builder: (context) {
//                                                           //   rtd1Controllers[index].text =
//                                                           //       unit.rtd ?? '';
//                                                           //   position[index]['rtd1'] =
//                                                           //       unit.rtd;
//                                                           //   return SizedBox(
//                                                           //     width: double.infinity,
//                                                           //     child: InputFormWidget(
//                                                           //         onChng: (value) {
//                                                           //           position[index]
//                                                           //               ['rtd1'] = value;
//                                                           //         },
//                                                           //         controller:
//                                                           //             rtd1Controllers[
//                                                           //                 index],
//                                                           //         hint: ''),
//                                                           //   );
//                                                           // }),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     const SizedBox(
//                                                       width: 12,
//                                                     ),
//                                                     Expanded(
//                                                       child: Column(
//                                                         crossAxisAlignment:
//                                                             CrossAxisAlignment
//                                                                 .stretch,
//                                                         children: [
//                                                           Text(
//                                                             'RTD 2',
//                                                             style:
//                                                                 getBlackTextStyle(
//                                                                     fontWeight:
//                                                                         w700),
//                                                           ),
//                                                           const SizedBox(
//                                                             height: 12,
//                                                           ),
//                                                           SizedBox(
//                                                             width:
//                                                                 double.infinity,
//                                                             child:
//                                                                 InputFormWidget(
//                                                               onChng: (value) {
//                                                                 position[index][
//                                                                         'rtd2'] =
//                                                                     value;
//                                                                 _markPositionAsEntered(
//                                                                     index);
//                                                               },
//                                                               controller:
//                                                                   rtd2Controllers[
//                                                                       index],
//                                                               hint: '',
//                                                             ),
//                                                           ),
//                                                           // Builder(builder: (context) {
//                                                           //   rtd2Controllers[index].text =
//                                                           //       unit.rtd ?? '';
//                                                           //   position[index]['rtd2'] =
//                                                           //       unit.rtd;
//                                                           //   return SizedBox(
//                                                           //     width: double.infinity,
//                                                           //     child: InputFormWidget(
//                                                           //         onChng: (value) {
//                                                           //           position[index]
//                                                           //               ['rtd2'] = value;
//                                                           //         },
//                                                           //         controller:
//                                                           //             rtd2Controllers[
//                                                           //                 index],
//                                                           //         hint: ''),
//                                                           //   );
//                                                           // }),
//                                                         ],
//                                                       ),
//                                                     ),
//                                                     const SizedBox(
//                                                       width: 12,
//                                                     ),
//                                                   ],
//                                                 ),
//                                               if (!_hideRtdForPeriod)
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                               if (!_hideSnForPeriod)
//                                                 Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment
//                                                           .stretch,
//                                                   children: [
//                                                     Text(
//                                                       'Serial Number',
//                                                       style: getBlackTextStyle(
//                                                           fontWeight: w700),
//                                                     ),
//                                                     const SizedBox(
//                                                       height: 12,
//                                                     ),
//                                                     SizedBox(
//                                                       width: double.infinity,
//                                                       child: InputFormWidget(
//                                                           isReadOnly:
//                                                               !_editableSnIndexes
//                                                                   .contains(
//                                                                       index),
//                                                           focusNode:
//                                                               snFocusNodes[
//                                                                   index],
//                                                           onTap: () {
//                                                             unawaited(
//                                                               _confirmSnChange(
//                                                                 index,
//                                                               ),
//                                                             );
//                                                           },
//                                                           onChng: (value) {
//                                                             position[index]
//                                                                 ['sn'] = value;
//                                                             _markPositionAsEntered(
//                                                                 index);
//                                                           },
//                                                           controller:
//                                                               snControllers[
//                                                                   index],
//                                                           hint: ''),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               if (!_hideSnForPeriod)
//                                                 const SizedBox(
//                                                   height: 12,
//                                                 ),
//                                               Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.stretch,
//                                                 children: [
//                                                   Text(
//                                                     'Remarks',
//                                                     style: getBlackTextStyle(
//                                                         fontWeight: w700),
//                                                   ),
//                                                   const SizedBox(
//                                                     height: 12,
//                                                   ),
//                                                   SizedBox(
//                                                     width: double.infinity,
//                                                     child: InputFormWidget(
//                                                         onChng: (value) {
//                                                           position[index]
//                                                                   ['remarks'] =
//                                                               value;
//                                                           _markPositionAsEntered(
//                                                               index);
//                                                         },
//                                                         controller:
//                                                             remarksControllers[
//                                                                 index],
//                                                         hint: ''),
//                                                   ),
//                                                 ],
//                                               ),
//                                               const SizedBox(
//                                                 height: 24,
//                                               ),
//                                               SizedBox(height: 12),

//                                               // SizedBox(
//                                               //   // height: 160,
//                                               //   child: GridView.builder(
//                                               //       physics:
//                                               //           NeverScrollableScrollPhysics(),
//                                               //       shrinkWrap: true,
//                                               //       itemCount: position[index]
//                                               //               ['condition']
//                                               //           .length,
//                                               //       gridDelegate:
//                                               //           SliverGridDelegateWithFixedCrossAxisCount(
//                                               //               crossAxisCount: 2,
//                                               //               childAspectRatio: 3),
//                                               //       itemBuilder:
//                                               //           (context, indexBroken) {
//                                               //         final broken = position[index]
//                                               //             ['condition'][indexBroken];
//                                               //         return InkWell(
//                                               //           onTap: () {
//                                               //             setState(() {
//                                               //               // checkedListCategory[
//                                               //               //         index] =
//                                               //               //     !checkedListCategory[
//                                               //               //         index];
//                                               //               broken['checked'] =
//                                               //                   !broken['checked'];
//                                               //             });
//                                               //             // widget.onCategoryChecked(checkedListCategory);
//                                               //           },
//                                               //           child: Container(
//                                               //             padding: EdgeInsets.all(10),
//                                               //             child: Row(
//                                               //               children: [
//                                               //                 Container(
//                                               //                   width: 24,
//                                               //                   height: 24,
//                                               //                   decoration:
//                                               //                       BoxDecoration(
//                                               //                     color: broken[
//                                               //                             'checked']
//                                               //                         ? black
//                                               //                         : Colors
//                                               //                             .transparent,
//                                               //                     border: Border.all(
//                                               //                         color:
//                                               //                             Colors.black),
//                                               //                   ),
//                                               //                   child: Icon(
//                                               //                     Icons.check,
//                                               //                     color: Colors.white,
//                                               //                     size: 16,
//                                               //                   ),
//                                               //                 ),
//                                               //                 SizedBox(width: 10),
//                                               //                 LayoutBuilder(builder:
//                                               //                     (context,
//                                               //                         constraints) {
//                                               //                   double fontSize =
//                                               //                       constraints
//                                               //                               .maxHeight *
//                                               //                           0.35;
//                                               //                   // log('ukuran' + fontSize.toString());
//                                               //                   return Text(
//                                               //                     broken['name'],
//                                               //                     style:
//                                               //                         getBlackTextStyle(
//                                               //                             fontSize:
//                                               //                                 fontSize),
//                                               //                   );
//                                               //                 }),
//                                               //               ],
//                                               //             ),
//                                               //           ),
//                                               //         );
//                                               //       }),
//                                               // ),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 );
//                               }),
//                         ],
//                       ),
//                     ),
//                   ),
//                   if (units.length > 1)
//                     Positioned(
//                       top: 24,
//                       right: 6,
//                       bottom: 24,
//                       child: Center(
//                         child: _buildTirePositionIndex(units.length),
//                       ),
//                     ),
//                   if (isUnitLocationSelectionPending)
//                     Positioned.fill(
//                       child: Stack(
//                         children: [
//                           const ModalBarrier(
//                             dismissible: false,
//                             color: Color(0x33000000),
//                           ),
//                           Align(
//                             alignment: Alignment.topCenter,
//                             child: Padding(
//                               padding: EdgeInsets.fromLTRB(
//                                 24,
//                                 24,
//                                 units.length > 1 ? 54 : 24,
//                                 24,
//                               ),
//                               child: Material(
//                                 elevation: 8,
//                                 borderRadius: BorderRadius.circular(12),
//                                 child: Padding(
//                                   padding: const EdgeInsets.all(16),
//                                   child: Column(
//                                     mainAxisSize: MainAxisSize.min,
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.stretch,
//                                     children: [
//                                       Row(
//                                         children: [
//                                           const Icon(
//                                             Icons.ev_station,
//                                             size: 32,
//                                             color: Colors.orange,
//                                           ),
//                                           const SizedBox(width: 10),
//                                           Expanded(
//                                             child: Text(
//                                               'Pilih Unit Location',
//                                               style: getBlackTextStyle(
//                                                 fontSize: 18,
//                                                 fontWeight: w700,
//                                               ),
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                                       const SizedBox(height: 8),
//                                       Text(
//                                         'Location wajib dipilih sebelum data '
//                                         'inspeksi dapat diinput.',
//                                         style: getBlackTextStyle(),
//                                       ),
//                                       const SizedBox(height: 12),
//                                       _buildUnitLocationOptions(),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                 ],
//               );
//             }
//             return Container();
//           },
//         )),
//         bottomNavigationBar: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             BlocBuilder<TireBloc, TireState>(
//               builder: (context, state) {
//                 if (state is TiresLoadedState && _isFormInitializedFor(state)) {
//                   final isUnitLocationSelectionPending =
//                       _isUnitLocationSelectionPending(
//                     hasUnitData: state.units.isNotEmpty,
//                   );

//                   return Container(
//                     margin: EdgeInsets.symmetric(horizontal: 24),
//                     child: ButtonWidget(
//                         color: isUnitLocationSelectionPending
//                             ? Colors.grey
//                             : black,
//                         name: isLoadingSave
//                             ? Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const SizedBox(
//                                     width: 22,
//                                     height: 22,
//                                     child: CircularProgressIndicator(
//                                       strokeWidth: 2.5,
//                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                         Colors.white,
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Text(
//                                     'Saving...',
//                                     style: getWhiteTextStyle(
//                                       fontWeight: w700,
//                                     ),
//                                   ),
//                                 ],
//                               )
//                             : Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const Icon(
//                                     Icons.save_alt,
//                                     color: Colors.white,
//                                   ),
//                                   const SizedBox(width: 6),
//                                   Text(
//                                     _isEditMode ? 'Update' : 'Save',
//                                     style: getWhiteTextStyle(),
//                                   ),
//                                 ],
//                               ),
//                         function: isUnitLocationSelectionPending
//                             ? null
//                             : () async {
//                                 await _handleSaveTireInspection(state);
//                               }),
//                   );
//                 }
//                 return Container();
//               },
//             ),
//             const SizedBox(
//               height: 12,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// new code after pi/pe implementation
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
import 'package:camos/core/services/model/tire_inspection_draft.dart';
import 'package:camos/core/services/tire_inspection_draft_service.dart';
import 'package:camos/core/services/tire_inspection_offline_edit_service.dart';
import 'package:camos/core/utils/functions/inspection_photo_helpers.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/pending_inspection_photo_preview.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/cached_inspection_photo_preview.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/existing_inspection_photo_preview.dart';
import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/scan_device_page.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/bounding_box_painter.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/temperature_status_selector_widget.dart';
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
  static const List<String> _siteSevenLocations = [
    'Pitstop',
    'Workshop',
    'CSA 27',
    'CSA 46',
    'CSA 61',
    'Hauling Road',
    'Other',
  ];
  static const List<String> _siteEightCompanyOneLocations = [
    'Pit Stop',
    'Workshop',
    'Moving',
    'Refueling',
  ];

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  final HomeState homeState = Get.find<HomeState>();
  bool get _usesAutomaticDamageRating =>
      homeState.userAccessCompanyId.value == '1';

  bool _isInit = true;
  int selectedMenu = 1;

  final TireInspectionDraftService _draftService =
      TireInspectionDraftService.instance;
  Timer? _draftAutosaveTimer;
  Timer? _draftDebounceTimer;
  Timer? _usernamePreferenceTimer;
  late final Future<void> _usernameReady;
  Future<void> _formHydration = Future<void>.value();
  TireInspectionDraftKey? _draftKey;
  TireInspectionDraft? _loadedDraft;
  String? _lastDraftFingerprint;
  String? _initializedUnitNumber;
  DateTime? _draftInspectionDate;
  List<String?> _currentTireKeys = <String?>[];
  bool _isRestoringDraft = false;
  bool _isHandlingBack = false;
  bool _usernameWasEdited = false;
  String _latestEditedUsername = '';
  int _pressureSubscriptionGeneration = 0;
  final List<StreamSubscription<List<int>>> _pressureSubscriptions =
      <StreamSubscription<List<int>>>[];

  // Jenis periode Tire Inspection.
  // Default menggunakan Period Inspection (PI).
  String selectedPeriodType = 'PI';
  bool _isLoadingPreviousPressure = false;
  int _previousPressureRequestId = 0;
  bool _isLoadingHiddenFieldFallbacks = false;
  int _hiddenFieldRequestId = 0;
  String _apiHmForHiddenFields = '';
  String _defaultHmValue = '';

  var map = {};
  String idSite = '';
  bool isSaved = false;
  bool isLoadingSave = false;
  Map<String, dynamic> dataUnit = {};
  bool _isEditMode = false;
  String _editInspectionDocumentId = '';
  Map<String, dynamic>? _editInspectionData;
  DateTime? _editInspectionDate;
  String? _hmInitializedForUnit;

  TextEditingController idUnit = TextEditingController(text: '');
  TextEditingController hmUnit = TextEditingController(text: '');
  TextEditingController usernameCtrl = TextEditingController(text: '');
  TextEditingController pressureCtrl = TextEditingController(text: '');
  TextEditingController remarksCtrl = TextEditingController(text: '');
  TextEditingController damageCtrl = TextEditingController(text: '');
  TextEditingController rtd1 = TextEditingController(text: '');
  TextEditingController rtd2 = TextEditingController(text: '');
  List<TextEditingController> remarksControllers = [];
  List<TextEditingController> snControllers = [];
  List<FocusNode> snFocusNodes = [];
  List<TextEditingController> rtd1Controllers = [];
  List<TextEditingController> rtd2Controllers = [];
  final Set<int> _editableSnIndexes = <int>{};
  bool _isSnConfirmationOpen = false;

  SwiperController swiperController = SwiperController();
  final ScrollController _formScrollController = ScrollController();
  List<GlobalKey> _positionSectionKeys = [];
  int _selectedScrollPosition = 0;
  final ValueNotifier<Set<int>> _enteredPositionIndexes =
      ValueNotifier<Set<int>>(<int>{});

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
                    _markPositionAsEntered(tireIndex);
                    _scheduleDraftSave();

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

  void _configurePitOptions() {
    pit.clear();

    switch (idSite) {
      case '7':
        pit.addAll(_siteSevenLocations);
        break;
      case '8':
        if (homeState.userAccessCompanyId.value == '1') {
          pit.addAll(_siteEightCompanyOneLocations);
        }
        break;
      case '5':
      case '6':
        pit.addAll(const <String>[
          'PITSTOP AMBON',
          'PITSTOP BANGKA',
          'PITSTOP BUTON',
          'PITSTOP IPD',
          'PITSTOP MEDAN',
          'PITSTOP OB2',
          'PITSTOP SABANG',
          'WSP',
          'Other',
        ]);
        break;
      case '52':
        pit.addAll(const <String>['Utara', 'Selatan', 'RML', 'WS']);
        break;
      case '137':
        pit.addAll(const <String>['Japun', 'PCE']);
        break;
      case '35':
        pit.addAll(const <String>['Tabuhan', 'EBL', 'Workshop']);
        break;
      case '65':
        pit.addAll(const <String>[
          'Room B1 Selatan',
          'TIA',
          'Serongga',
          'CSA Selatan',
          'CSA Pelaihari',
          'WS',
        ]);
        break;
      case '166':
        pit.addAll(const <String>[
          'WS',
          'Pondok Operator',
          'CSA Bagaspati',
          'Pit Stop Toll',
        ]);
        break;
    }

    if (idSite == '7' && (selectedPit < 0 || selectedPit >= pit.length)) {
      selectedPit = 0;
    } else if (selectedPit >= pit.length) {
      selectedPit = -1;
    }
  }

  DateTime? _dateFromRouteValue(dynamic value) {
    final parsed = _dateFromRecord(value);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  DateTime? _dateFromRecord(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString().trim() ?? '');
  }

  TireInspectionDraftKey? _buildDraftKey() {
    final ownerId = auth.currentUser?.uid.trim() ?? '';
    final unitNumber = dataUnit['unitNumber']?.toString().trim() ?? '';
    if (ownerId.isEmpty || idSite.trim().isEmpty || unitNumber.isEmpty) {
      return null;
    }

    return TireInspectionDraftKey.forDate(
      userId: ownerId,
      siteId: idSite,
      unitNumber: unitNumber,
      inspectionDate: _draftInspectionDate ?? DateTime.now(),
    );
  }

  void _startDraftAutosave() {
    if (_isEditMode) return;
    _draftAutosaveTimer ??= Timer.periodic(
      const Duration(seconds: 5),
      (_) => unawaited(_persistDraftIfChanged()),
    );
  }

  void _scheduleDraftSave() {
    if (_isEditMode || _isRestoringDraft || isSaved) return;

    _draftDebounceTimer?.cancel();
    _draftDebounceTimer = Timer(
      const Duration(milliseconds: 700),
      () => unawaited(_persistDraftIfChanged()),
    );
  }

  String get _accountUsername {
    final cachedUsername = user['username']?.toString().trim() ?? '';
    if (cachedUsername.isNotEmpty) return cachedUsername;

    final firebaseDisplayName = auth.currentUser?.displayName?.trim() ?? '';
    if (firebaseDisplayName.isNotEmpty) return firebaseDisplayName;

    final email = auth.currentUser?.email?.trim() ?? '';
    return email.isNotEmpty ? email : 'Unknown';
  }

  String get _effectiveUsername {
    final inputUsername = usernameCtrl.text.trim();
    return inputUsername.isNotEmpty ? inputUsername : _accountUsername;
  }

  Future<void> _initializeUsername() async {
    try {
      final loadedUser = await getUserPreferences();
      final accountId = auth.currentUser?.uid.trim() ?? '';
      final savedUsername = await getInspectionUsername(accountId: accountId);

      if (!mounted) return;
      user = loadedUser;

      if (!_usernameWasEdited && usernameCtrl.text.trim().isEmpty) {
        usernameCtrl.text =
            savedUsername.isNotEmpty ? savedUsername : _accountUsername;
      }
      _scheduleDraftSave();
      log('username : $user');
    } catch (e, stackTrace) {
      log(
        'Gagal memuat username Tire Inspection: $e',
        stackTrace: stackTrace,
      );
      if (mounted && !_usernameWasEdited && usernameCtrl.text.trim().isEmpty) {
        usernameCtrl.text = _accountUsername;
      }
    }
  }

  Future<void> _persistInspectionUsername(String username) async {
    final accountId = auth.currentUser?.uid.trim() ?? '';
    if (accountId.isEmpty) return;

    try {
      await saveInspectionUsername(
        accountId: accountId,
        username: username.trim(),
      );
    } catch (e, stackTrace) {
      log(
        'Gagal menyimpan username Tire Inspection: $e',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistEditedUsernameIfNeeded() async {
    if (!_usernameWasEdited) return;
    _usernamePreferenceTimer?.cancel();
    await _persistInspectionUsername(_latestEditedUsername);
  }

  void _handleUsernameChanged(String value) {
    _usernameWasEdited = true;
    _latestEditedUsername = value;
    _scheduleDraftSave();

    _usernamePreferenceTimer?.cancel();
    final usernameToSave = value;
    _usernamePreferenceTimer = Timer(
      const Duration(milliseconds: 500),
      () => unawaited(_persistInspectionUsername(usernameToSave)),
    );
  }

  void _resetHmToDefault() {
    if (_defaultHmValue.isEmpty) return;

    hmUnit.value = TextEditingValue(
      text: _defaultHmValue,
      selection: TextSelection.collapsed(offset: _defaultHmValue.length),
    );
  }

  TireInspectionDraft? _createDraftSnapshot() {
    if (_isEditMode) return null;
    final key = _draftKey ?? _buildDraftKey();
    if (key == null || position.isEmpty) return null;
    _draftKey = key;

    return TireInspectionDraft.fromFormData(
      key: key,
      positions: position,
      tireKeys: _currentTireKeys,
      periodType: selectedPeriodType,
      location:
          selectedPit >= 0 && selectedPit < pit.length ? pit[selectedPit] : '',
      hm: hmUnit.text,
      unitModel: dataUnit['model']?.toString() ?? '',
      siteName: homeState.siteName,
      userDisplayName: _effectiveUsername,
      formData: <String, dynamic>{
        'selectedRoute': selectedRoute,
        'checkAmount': checkAmount,
      },
      navigationData: <String, dynamic>{
        ...dataUnit,
        'unitNumber': key.unitNumber,
        'idSite': key.siteId,
        'draftInspectionDate': key.inspectionDate,
        'idCompany': homeState.userAccessCompanyId.value,
      },
      createdAt: _loadedDraft?.createdAt,
    );
  }

  String _draftFingerprint(TireInspectionDraft draft) {
    final json = draft.toJson()
      ..remove('createdAt')
      ..remove('updatedAt');
    return jsonEncode(json);
  }

  Future<void> _persistDraftIfChanged({
    bool force = false,
    bool rethrowOnError = false,
  }) async {
    if (_isEditMode || _isRestoringDraft || isSaved || position.isEmpty) {
      return;
    }

    try {
      final snapshot = _createDraftSnapshot();
      if (snapshot == null) return;

      final fingerprint = _draftFingerprint(snapshot);
      if (!force && fingerprint == _lastDraftFingerprint) return;

      _loadedDraft = await _draftService.saveDraft(snapshot);
      _lastDraftFingerprint = fingerprint;
    } catch (e, stackTrace) {
      log(
        'Tire Inspection draft save failed: $e',
        stackTrace: stackTrace,
      );
      if (rethrowOnError) rethrow;
    }
  }

  TireInspectionPositionDraft? _findPositionDraft(
    TireInspectionDraft draft,
    UnitTire unit,
    int index,
  ) {
    final tireKey = unit.kunciTire?.toString().trim() ?? '';
    if (tireKey.isNotEmpty) {
      for (final item in draft.positions) {
        if (item.tireKey == tireKey || item.identity == tireKey) return item;
      }
    }

    final inventoryId = unit.idinventory?.toString().trim() ?? '';
    if (inventoryId.isNotEmpty) {
      for (final item in draft.positions) {
        if (item.identity == inventoryId) return item;
      }
    }

    final positionLabel = unit.posisi?.toString().trim().isNotEmpty == true
        ? unit.posisi.toString().trim()
        : '${index + 1}';
    for (final item in draft.positions) {
      if (item.positionLabel == positionLabel ||
          item.positionLabel == '${index + 1}') {
        return item;
      }
    }

    return index < draft.positions.length ? draft.positions[index] : null;
  }

  void _syncPositionControllers() {
    for (int index = 0; index < position.length; index++) {
      if (index < remarksControllers.length) {
        remarksControllers[index].text =
            position[index]['remarks']?.toString() ?? '';
      }
      if (index < snControllers.length) {
        snControllers[index].text = position[index]['sn']?.toString() ?? '';
      }
      if (index < rtd1Controllers.length) {
        rtd1Controllers[index].text = position[index]['rtd1']?.toString() ?? '';
      }
      if (index < rtd2Controllers.length) {
        rtd2Controllers[index].text = position[index]['rtd2']?.toString() ?? '';
      }
    }
  }

  Future<bool> _restoreDraft(TiresLoadedState state) async {
    final key = _draftKey ?? _buildDraftKey();
    if (key == null || state.units.isEmpty) return false;
    _draftKey = key;

    try {
      final draft = await _draftService.loadDraft(key);
      if (draft == null ||
          !mounted ||
          _initializedUnitNumber != key.unitNumber) {
        return false;
      }

      setState(() {
        _loadedDraft = draft;
        if (!_usernameWasEdited && draft.userDisplayName.isNotEmpty) {
          usernameCtrl.text = draft.userDisplayName;
        }
        if (draft.periodType == 'PI' || draft.periodType == 'PE') {
          selectedPeriodType = draft.periodType;
        }
        final draftHm = _nonEmptySourceValue(draft.hm);

        if (draftHm.isNotEmpty) {
          // Kalau draft memang punya HM, gunakan HM dari draft.
          hmUnit.text = draftHm;
        } else if (hmUnit.text.trim().isEmpty) {
          // Kalau HM draft kosong, jangan menimpa HM dari API/default.
          hmUnit.text = _defaultHmValue.isNotEmpty
              ? _defaultHmValue
              : _apiHmForHiddenFields;
        }

        final restoredPitIndex = pit.indexWhere(
          (item) => item.toLowerCase() == draft.location.toLowerCase(),
        );
        if (restoredPitIndex >= 0) selectedPit = restoredPitIndex;

        selectedRoute = int.tryParse(
              draft.formData['selectedRoute']?.toString() ?? '',
            ) ??
            selectedRoute;
        checkAmount = int.tryParse(
              draft.formData['checkAmount']?.toString() ?? '',
            ) ??
            checkAmount;

        for (int index = 0; index < state.units.length; index++) {
          if (index >= position.length) break;
          final item = _findPositionDraft(draft, state.units[index], index);
          if (item == null) continue;

          final restored = item.toFormData();
          for (final key in const <String>[
            'pressure',
            'adjusmentPressure',
            'temperatureStatus',
            'adjusmentTemperatureStatus',
            'damageTire',
            'rtd1',
            'rtd2',
            'remarks',
            'sn',
            'rating',
            'prevRating',
            'rimCondition',
            'tireAccessories',
            '_hasUserInput',
            '_pressureFromHistory',
          ]) {
            if (restored.containsKey(key)) position[index][key] = restored[key];
          }

          final imagePaths = item.imagePaths
              .where((path) => File(path).existsSync())
              .map((path) => '$path|${position[index]['position']}')
              .toList();
          position[index]['image'] = imagePaths;

          // Draft versi lama belum memiliki flag ini. Gunakan hanya data
          // eksplisit yang aman agar nilai API/history tidak dianggap sebagai
          // input baru dari user.
          if (!restored.containsKey('_hasUserInput')) {
            position[index]['_hasUserInput'] =
                _nonEmptySourceValue(restored['pressure']).isNotEmpty ||
                    _nonEmptySourceValue(restored['adjusmentPressure'])
                        .isNotEmpty ||
                    imagePaths.isNotEmpty;
          }

          // Draft PE versi lama belum mencatat asal pressure. Perlakukan nilai
          // tersebut sebagai data historis sampai user menginput ulang agar
          // tidak dapat dipakai untuk memenuhi mandatory pressure pada PI.
          if (!restored.containsKey('_pressureFromHistory')) {
            position[index]['_pressureFromHistory'] =
                draft.periodType == 'PE' &&
                    _nonEmptySourceValue(restored['pressure']).isNotEmpty;
          }
        }

        _syncPositionControllers();
      });
      _syncEnteredPositionIndexes();

      _lastDraftFingerprint = _draftFingerprint(draft);

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.blue,
            content: Text(
              'Draft Tire Inspection unit ${key.unitNumber} berhasil dipulihkan.',
              style: getWhiteTextStyle(),
            ),
          ),
        );
      }
      return true;
    } catch (e, stackTrace) {
      log('Tire Inspection draft restore failed: $e', stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _deleteCurrentDraft() async {
    final key = _draftKey ?? _buildDraftKey();
    if (key == null) return;

    try {
      await _draftService.markCompleted(key);
      _loadedDraft = null;
      _lastDraftFingerprint = null;
    } catch (e, stackTrace) {
      log('Tire Inspection draft delete failed: $e', stackTrace: stackTrace);
    }
  }

  Future<void> _deleteDraftIfUnchanged({
    required TireInspectionDraftKey key,
    required String fingerprint,
  }) async {
    try {
      final currentDraft = await _draftService.loadDraft(key);
      if (currentDraft == null ||
          _draftFingerprint(currentDraft) != fingerprint) {
        return;
      }
      await _draftService.markCompleted(key);
    } catch (e, stackTrace) {
      log(
        'Delete synced Tire Inspection draft failed: $e',
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> _saveDraftBeforeLeaving() async {
    if (_isEditMode) return !isLoadingSave;
    if (isSaved || position.isEmpty) return true;
    if (isLoadingSave || _isHandlingBack) return false;

    _isHandlingBack = true;

    try {
      _draftDebounceTimer?.cancel();

      await _persistEditedUsernameIfNeeded();
      if (!mounted) return false;

      // Jangan pakai force:true
      // Kalau draft tidak berubah, langsung return.
      await _persistDraftIfChanged(
        rethrowOnError: true,
      );

      return true;
    } catch (e, stackTrace) {
      log(
        'Save draft before leaving failed: $e',
        stackTrace: stackTrace,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Draft belum berhasil disimpan. Silakan tekan tombol Back kembali.',
              style: getWhiteTextStyle(),
            ),
          ),
        );
      }

      return false;
    } finally {
      _isHandlingBack = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_persistEditedUsernameIfNeeded());
      if (!_isEditMode) {
        unawaited(_persistDraftIfChanged(force: true));
      }
    }
  }

  @override
  void initState() {
    super.initState();
    requestPlacePermission();

    context.read<BluetoothOnOffCubit>().checkBluetoothStatus();
    final connectedCubit = context.read<ConnectedDevicesCubit>();
    log('connected cubit : $connectedCubit');
    connectedCubit.fetchConnectedDevices(); // HANYA MEMULAI fetch

    // callTires();
    WidgetsBinding.instance.addObserver(this);
    hmUnit.addListener(_scheduleDraftSave);
    _usernameReady = _initializeUsername();
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

      if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        loadingDamages = false;
      });
    }
  }

  @override
  void dispose() {
    _draftDebounceTimer?.cancel();
    _draftAutosaveTimer?.cancel();
    _usernamePreferenceTimer?.cancel();
    unawaited(_persistEditedUsernameIfNeeded());
    if (!isSaved && !_isEditMode) {
      // unawaited(_persistDraftIfChanged(force: true));
      unawaited(_persistDraftIfChanged());
    }

    _pressureSubscriptionGeneration++;
    for (final subscription in _pressureSubscriptions) {
      unawaited(subscription.cancel());
    }
    _pressureSubscriptions.clear();

    WidgetsBinding.instance.removeObserver(this);

    hmUnit.removeListener(_scheduleDraftSave);
    idUnit.dispose();
    hmUnit.dispose();
    usernameCtrl.dispose();
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

    for (final focusNode in snFocusNodes) {
      focusNode.dispose();
    }

    for (final controller in rtd1Controllers) {
      controller.dispose();
    }

    for (final controller in rtd2Controllers) {
      controller.dispose();
    }

    _formScrollController.dispose();
    _enteredPositionIndexes.dispose();
    swiperController.dispose();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        dataUnit = Map<String, dynamic>.from(args);
        _editInspectionDocumentId =
            dataUnit['inspectionDocId']?.toString().trim() ?? '';
        final rawEditData = dataUnit['inspectionData'];
        if (rawEditData is Map) {
          _editInspectionData = Map<String, dynamic>.from(rawEditData);
        }
        _isEditMode = dataUnit['isEdit'] == true &&
            _editInspectionDocumentId.isNotEmpty &&
            _editInspectionData != null;
        final routeSiteId = dataUnit['idSite']?.toString().trim() ?? '';
        idSite = routeSiteId.isNotEmpty ? routeSiteId : homeState.currentSiteId;
        _draftInspectionDate =
            _dateFromRouteValue(dataUnit['draftInspectionDate']);
        _editInspectionDate = _dateFromRecord(
          _editInspectionData?['tanggal'] ?? _editInspectionData?['hari'],
        );
        _configurePitOptions();
        if (!_isEditMode) {
          _draftKey = _buildDraftKey();
        }

        log('TireInspectionPage: dataUnit berhasil diambil -> $dataUnit');

        unawaited(_loadDamages());
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
      final decodedWidth = decodedImage.width.toDouble();
      final decodedHeight = decodedImage.height.toDouble();
      decodedImage.dispose();
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
        imageWidths[index] = decodedWidth;
        imageHeights[index] = decodedHeight;
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

  List<Map<String, dynamic>> _defaultRimConditions() {
    return <Map<String, dynamic>>[
      {
        'title': 'RIM BASE',
        'jobDescription': '',
        'condition': 'Good',
        'remark': '',
      },
      {
        'title': 'FLANGE',
        'jobDescription': '',
        'condition': 'Good',
        'remark': '',
      },
      {
        'title': 'LOCK RING',
        'jobDescription': '',
        'condition': 'Good',
        'remark': '',
      },
      {
        'title': 'O-RING',
        'jobDescription': '',
        'condition': 'Good',
        'remark': '',
      },
      {
        'title': 'VALVE (TERPASANG/TIDAK TERPASANG)',
        'jobDescription': '',
        'condition': 'Good',
        'remark': '',
      },
      {
        'title': 'CORE VALVE',
        'jobDescription': '',
        'condition': 'Good',
        'remark': '',
      },
      {
        'title': 'VALVE CAP',
        'jobDescription': '',
        'condition': 'Good',
        'remark': '',
      },
      {
        'title': 'NUT DAN STUD RODA',
        'jobDescription': '',
        'condition': 'Good',
        'remark': '',
      },
    ];
  }

  void _disposePositionInputs() {
    for (final controller in remarksControllers) {
      controller.removeListener(_scheduleDraftSave);
      controller.dispose();
    }
    for (final controller in snControllers) {
      controller.removeListener(_scheduleDraftSave);
      controller.dispose();
    }
    for (final controller in rtd1Controllers) {
      controller.removeListener(_scheduleDraftSave);
      controller.dispose();
    }
    for (final controller in rtd2Controllers) {
      controller.removeListener(_scheduleDraftSave);
      controller.dispose();
    }
    for (final focusNode in snFocusNodes) {
      focusNode.dispose();
    }

    remarksControllers.clear();
    snControllers.clear();
    rtd1Controllers.clear();
    rtd2Controllers.clear();
    snFocusNodes.clear();
  }

  void _initializePositions(TiresLoadedState state) {
    if (state.units.isEmpty || !_stateMatchesRequestedUnit(state)) return;

    final currentUnitNumber = state.units.first.unitNumber ?? '';
    if (_initializedUnitNumber == currentUnitNumber &&
        position.length == state.units.length) {
      return;
    }

    _disposePositionInputs();
    position.clear();
    _enteredPositionIndexes.value = <int>{};
    _editableSnIndexes.clear();
    _currentTireKeys = state.units
        .map((unit) => unit.kunciTire?.toString())
        .toList(growable: false);
    _initializedUnitNumber = currentUnitNumber;

    final firstUnit = state.units.first;
    _apiHmForHiddenFields = _nonEmptySourceValue(firstUnit.hm);
    _defaultHmValue = idSite == bmbhauling.idSite ? '' : _apiHmForHiddenFields;
    if (_hmInitializedForUnit != currentUnitNumber) {
      hmUnit.text = _defaultHmValue;
      _hmInitializedForUnit = currentUnitNumber;
    }

    dataUnit.putIfAbsent('model', () => firstUnit.model ?? '');
    dataUnit['idSite'] = idSite;

    for (int index = 0; index < state.units.length; index++) {
      final unit = state.units[index];
      final remarksController = TextEditingController();
      final snController = TextEditingController(text: unit.sn ?? '');
      final rtd1Controller =
          TextEditingController(text: unit.rtd?.toString() ?? '');
      final rtd2Controller =
          TextEditingController(text: unit.rtd?.toString() ?? '');

      remarksController.addListener(_scheduleDraftSave);
      snController.addListener(_scheduleDraftSave);
      rtd1Controller.addListener(_scheduleDraftSave);
      rtd2Controller.addListener(_scheduleDraftSave);

      remarksControllers.add(remarksController);
      snControllers.add(snController);
      snFocusNodes.add(FocusNode());
      rtd1Controllers.add(rtd1Controller);
      rtd2Controllers.add(rtd2Controller);

      position.add(<String, dynamic>{
        'position': index + 1,
        'pressure': '',
        '_pressureFromHistory': false,
        'adjusmentPressure': '',
        'temperatureStatus': 'HOT',
        'adjusmentTemperatureStatus': 'HOT',
        'hm': '',
        'damageTire': <dynamic>[],
        'rtd1': unit.rtd?.toString() ?? '',
        'rtd2': unit.rtd?.toString() ?? '',
        '_apiRtd': unit.rtd?.toString() ?? '',
        '_apiRtd2': unit.rtd?.toString() ?? '',
        '_apiSn': unit.sn?.toString() ?? '',
        'remarks': '',
        'sn': unit.sn,
        'rating': '',
        'prevRating': '',
        'image': <String>[],
        'idInventory': unit.idinventory,
        'idUnit': unit.idUnit,
        'tireSize': unit.size,
        'kunci_tire': unit.kunciTire,
        'rimCondition': _defaultRimConditions(),
        'tireAccessories': <dynamic>[],
        '_hasUserInput': false,
      });
    }

    _startDraftAutosave();
    _formHydration = _hydrateInitialFormData(state, currentUnitNumber);
    unawaited(_formHydration);
  }

  bool _stateMatchesRequestedUnit(TiresLoadedState state) {
    if (state.units.isEmpty) return false;

    final requestedUnit = dataUnit['unitNumber']?.toString().trim() ?? '';
    final loadedUnit = state.units.first.unitNumber?.trim() ?? '';
    return requestedUnit.isNotEmpty && loadedUnit == requestedUnit;
  }

  bool _isFormInitializedFor(TiresLoadedState state) {
    if (!_stateMatchesRequestedUnit(state)) return false;

    final length = state.units.length;
    return _initializedUnitNumber == state.units.first.unitNumber &&
        position.length == length &&
        remarksControllers.length == length &&
        snControllers.length == length &&
        snFocusNodes.length == length &&
        rtd1Controllers.length == length &&
        rtd2Controllers.length == length;
  }

  Map<dynamic, dynamic>? _previousPositionForUnit(
    List<dynamic> previousPositions,
    UnitTire unit,
    int index,
  ) {
    final tireKey = unit.kunciTire?.toString().trim() ?? '';
    if (tireKey.isNotEmpty) {
      for (final item in previousPositions) {
        if (item is Map &&
            (item['kunci_tire'] ?? item['kunciTire'])?.toString() == tireKey) {
          return item;
        }
      }
    }

    return _historyPositionAt(previousPositions, index);
  }

  Map<dynamic, dynamic>? _editPositionForUnit(
    List<dynamic> storedPositions,
    UnitTire unit,
    int index,
  ) {
    final tireKey = unit.kunciTire?.toString().trim() ?? '';
    if (tireKey.isNotEmpty) {
      for (final item in storedPositions) {
        if (item is Map &&
            (item['kunci_tire'] ?? item['kunciTire'])?.toString().trim() ==
                tireKey) {
          return item;
        }
      }
    }

    final inventoryId = unit.idinventory?.toString().trim() ?? '';
    if (inventoryId.isNotEmpty) {
      for (final item in storedPositions) {
        if (item is Map &&
            item['idInventory']?.toString().trim() == inventoryId) {
          return item;
        }
      }
    }

    final unitPosition = unit.posisi?.toString().trim() ?? '';
    for (final item in storedPositions) {
      if (item is! Map) continue;
      final storedPosition =
          (item['position'] ?? item['pos'])?.toString().trim() ?? '';
      if (storedPosition == '${index + 1}' ||
          (unitPosition.isNotEmpty && storedPosition == unitPosition)) {
        return item;
      }
    }

    return index < storedPositions.length && storedPositions[index] is Map
        ? storedPositions[index] as Map
        : null;
  }

  List<dynamic> _copyDynamicList(dynamic value) {
    if (value is! List) return <dynamic>[];
    return value.map<dynamic>((item) {
      if (item is Map) return Map<String, dynamic>.from(item);
      return item;
    }).toList(growable: true);
  }

  void _applyEditInspectionData(TiresLoadedState state) {
    final editData = _editInspectionData;
    if (!_isEditMode || editData == null || state.units.isEmpty) return;

    final storedPositions = editData['posisi'];
    if (storedPositions is! List) return;

    final pendingPhotos = Get.isRegistered<UploadQueueService>()
        ? UploadQueueService.to.photosForDocument(
            _editInspectionDocumentId,
            storedPositions: storedPositions,
          )
        : <Map<String, dynamic>>[];

    final storedUsername = _nonEmptySourceValue(editData['user']);
    if (storedUsername.isNotEmpty && !_usernameWasEdited) {
      usernameCtrl.text = storedUsername;
    }

    hmUnit.text = _nonEmptySourceValue(editData['hm']);

    final storedPeriod =
        _nonEmptySourceValue(editData['periodType']).toUpperCase();
    if (storedPeriod == 'PI' || storedPeriod == 'PE') {
      selectedPeriodType = storedPeriod;
    }

    final storedPit = _nonEmptySourceValue(editData['pit']);
    final storedPitIndex = pit.indexWhere(
      (item) => item.trim().toLowerCase() == storedPit.toLowerCase(),
    );
    if (storedPitIndex >= 0) selectedPit = storedPitIndex;

    for (int index = 0; index < state.units.length; index++) {
      if (index >= position.length) break;
      final stored = _editPositionForUnit(
        storedPositions,
        state.units[index],
        index,
      );
      if (stored == null) continue;

      for (final key in const <String>[
        'pressure',
        'adjusmentPressure',
        'temperatureStatus',
        'adjusmentTemperatureStatus',
        'rtd1',
        'rtd2',
        'remarks',
        'sn',
        'rating',
        'idUnit',
        'idInventory',
        'tireSize',
      ]) {
        if (stored.containsKey(key)) position[index][key] = stored[key];
      }

      position[index]['damageTire'] = _copyDynamicList(stored['damageTire']);
      position[index]['rimCondition'] =
          _copyDynamicList(stored['rimCondition']);
      position[index]['tireAccessories'] =
          _copyDynamicList(stored['tireAccessories']);
      position[index]['prevRating'] =
          _nonEmptySourceValue(stored['rating']).toUpperCase();
      position[index]['_existingImages'] = _copyDynamicList(stored['images']);
      position[index]['_cachedLocalImagePath'] =
          _nonEmptySourceValue(stored['_cachedLocalImagePath']);
      final pendingPhotoPath = pendingInspectionPhotoPath(
        pendingPhotos,
        storedIndex: storedPositions.indexOf(stored),
        tirePosition: (stored['position'] ?? stored['pos'])?.toString() ?? '',
      );
      // Preview tersimpan terpisah dari 'image' (foto baru). Save tanpa
      // mengganti foto tidak boleh mengantrekan file yang sama sekali lagi.
      position[index]['_pendingLocalImagePath'] = pendingPhotoPath;
      position[index]['_existingImagePending'] =
          stored['imagePending'] == true || pendingPhotoPath != null;
      position[index]['_editOriginalPosition'] =
          Map<String, dynamic>.from(stored);
      position[index]['_pressureFromHistory'] = false;
      position[index]['_hasUserInput'] = true;
    }

    _syncPositionControllers();
    _syncEnteredPositionIndexes();
  }

  Future<void> _loadPreviousInspectionDetails(
    TiresLoadedState state,
    String unitNumber,
  ) async {
    try {
      final snapshot = await firestore
          .collection('tire_inspection')
          .where('unit', isEqualTo: unitNumber)
          .orderBy('tanggal', descending: true)
          .limit(10)
          .get();

      if (!mounted || _initializedUnitNumber != unitNumber) return;

      Map<String, dynamic>? previousData;
      for (final document in snapshot.docs) {
        final data = document.data();
        final documentSite = data['id_site']?.toString().trim() ?? '';
        if (documentSite.isEmpty || documentSite == idSite) {
          previousData = data;
          break;
        }
      }

      final previousPositions = previousData?['posisi'];
      if (previousPositions is! List) return;

      setState(() {
        for (int index = 0; index < state.units.length; index++) {
          if (index >= position.length) break;
          final previous = _previousPositionForUnit(
            previousPositions,
            state.units[index],
            index,
          );
          if (previous == null) continue;

          final previousRating =
              _nonEmptySourceValue(previous['rating']).toUpperCase();
          if (_nonEmptySourceValue(position[index]['rating']).isEmpty &&
              previousRating.isNotEmpty) {
            position[index]['rating'] = previousRating;
          }
          if (_nonEmptySourceValue(position[index]['prevRating']).isEmpty &&
              previousRating.isNotEmpty) {
            position[index]['prevRating'] = previousRating;
          }

          final previousDamage = previous['damageTire'];
          final currentDamage = position[index]['damageTire'];
          if (currentDamage is List &&
              currentDamage.isEmpty &&
              previousDamage is List &&
              previousDamage.isNotEmpty) {
            position[index]['damageTire'] = List<dynamic>.from(previousDamage);
          }

          final previousRemarks = _nonEmptySourceValue(previous['remarks']);
          if (_nonEmptySourceValue(position[index]['remarks']).isEmpty &&
              previousRemarks.isNotEmpty) {
            position[index]['remarks'] = previousRemarks;
          }
        }
        _syncPositionControllers();
      });
    } catch (e, stackTrace) {
      log(
        'Load previous Tire Inspection once failed: $e',
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _hydrateInitialFormData(
    TiresLoadedState state,
    String unitNumber,
  ) async {
    // Lindungi draft lama sejak sebelum menunggu inisialisasi username.
    // Tanpa guard ini, autosave dapat menimpa draft dengan posisi default.
    _isRestoringDraft = true;
    try {
      await _usernameReady;
      if (!mounted || _initializedUnitNumber != unitNumber) return;

      if (_isEditMode) {
        setState(() {
          _applyEditInspectionData(state);
        });
        return;
      }

      await _restoreDraft(state);
      if (!mounted || _initializedUnitNumber != unitNumber) return;

      await _loadPreviousInspectionDetails(state, unitNumber);
      if (!mounted || _initializedUnitNumber != unitNumber) return;

      if (_usesCompanyOnePeriodRules && selectedPeriodType == 'PE') {
        await _loadHiddenFieldFallbacks();
      }
    } finally {
      _isRestoringDraft = false;
    }

    _scheduleDraftSave();
  }

  void callTires() async {
    if (mounted) {
      if (dataUnit.isNotEmpty) {
        idUnit.text = dataUnit['unitNumber']?.toString() ?? '';
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

  void _syncPositionSectionKeys(int itemCount) {
    if (_positionSectionKeys.length == itemCount) return;

    _positionSectionKeys = List<GlobalKey>.generate(
      itemCount,
      (index) => GlobalKey(debugLabel: 'tire-position-${index + 1}'),
    );

    if (_selectedScrollPosition >= itemCount) {
      _selectedScrollPosition = 0;
    }
  }

  void _markPositionAsEntered(int index) {
    if (index < 0 || index >= position.length) return;

    position[index]['_hasUserInput'] = true;
    if (_enteredPositionIndexes.value.contains(index)) return;

    _enteredPositionIndexes.value = Set<int>.unmodifiable(
      <int>{..._enteredPositionIndexes.value, index},
    );
  }

  void _syncEnteredPositionIndexes() {
    final enteredIndexes = <int>{};
    for (int index = 0; index < position.length; index++) {
      if (position[index]['_hasUserInput'] == true) {
        enteredIndexes.add(index);
      }
    }
    _enteredPositionIndexes.value = Set<int>.unmodifiable(enteredIndexes);
  }

  Future<void> _scrollToTirePosition(int index) async {
    if (index < 0 || index >= _positionSectionKeys.length) return;

    FocusScope.of(context).unfocus();

    if (_selectedScrollPosition != index) {
      setState(() {
        _selectedScrollPosition = index;
      });
    }

    final targetContext = _positionSectionKeys[index].currentContext;
    if (targetContext == null) return;

    await Scrollable.ensureVisible(
      targetContext,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
      alignment: 0.04,
    );
  }

  Widget _buildTirePositionIndex(int itemCount) {
    final railHeight = (itemCount * 36.0 + 8).clamp(
      80.0,
      MediaQuery.of(context).size.height * 0.58,
    );

    return ValueListenableBuilder<Set<int>>(
      valueListenable: _enteredPositionIndexes,
      builder: (context, enteredIndexes, child) {
        return Material(
          elevation: 6,
          color: Colors.white.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: railHeight,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.withOpacity(0.35)),
            ),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: itemCount,
              itemBuilder: (context, index) {
                final isSelected = _selectedScrollPosition == index;
                final hasUserInput = enteredIndexes.contains(index);
                final positionLabel = index < position.length
                    ? position[index]['position']?.toString() ?? '${index + 1}'
                    : '${index + 1}';

                return Semantics(
                  label: hasUserInput
                      ? 'Posisi $positionLabel, pernah diinput'
                      : 'Posisi $positionLabel, belum pernah diinput',
                  selected: isSelected,
                  button: true,
                  child: Tooltip(
                    message: hasUserInput
                        ? 'Posisi $positionLabel - pernah diinput'
                        : 'Posisi $positionLabel - belum pernah diinput',
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _scrollToTirePosition(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 32,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.orange
                              : hasUserInput
                                  ? Colors.green
                                  : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isSelected && hasUserInput
                              ? Border.all(color: Colors.green, width: 2)
                              : null,
                        ),
                        child: Text(
                          positionLabel,
                          style: TextStyle(
                            color: isSelected || hasUserInput
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  void applyPressureData(String pressureValue) {
    if (!mounted || position.isEmpty) return;

    if (_isUnitLocationSelectionPending(hasUnitData: dataUnit.isNotEmpty)) {
      return;
    }

    int? enteredPositionIndex;
    setState(() {
      final firstNumber = pressureValue;

      if (checkAmount < position.length) {
        final route = selectedRoute >= 0 && selectedRoute < inspectRoute.length
            ? inspectRoute[selectedRoute]
            : const <int>[];
        final targetIndex =
            checkAmount < route.length ? route[checkAmount] : checkAmount;
        if (targetIndex < 0 || targetIndex >= position.length) return;

        log('target position : ${targetIndex}');
        log('target pressure : ${firstNumber}');

        // Update Map di index tersebut
        position[targetIndex]["pressure"] = firstNumber;
        position[targetIndex]['_pressureFromHistory'] = false;
        enteredPositionIndex = targetIndex;

        checkAmount++;
      }
    });
    if (enteredPositionIndex != null) {
      _markPositionAsEntered(enteredPositionIndex!);
    }
    _scheduleDraftSave();
  }

  Future<void> _subscribePressureNotifications(
    List<BluetoothService> services,
  ) async {
    final generation = ++_pressureSubscriptionGeneration;
    for (final subscription in _pressureSubscriptions) {
      await subscription.cancel();
    }
    _pressureSubscriptions.clear();

    if (!mounted || generation != _pressureSubscriptionGeneration) return;

    for (final service in services) {
      for (final characteristic in service.characteristics) {
        if (!characteristic.properties.notify &&
            !characteristic.properties.indicate) {
          continue;
        }

        try {
          await characteristic.setNotifyValue(true);
          if (!mounted || generation != _pressureSubscriptionGeneration) {
            return;
          }

          final subscription = characteristic.onValueReceived.listen((value) {
            if (!mounted || generation != _pressureSubscriptionGeneration) {
              return;
            }

            final notification = String.fromCharCodes(value).trim();
            final rawPressure = notification.contains('|')
                ? notification.split('|').first.trim()
                : notification;
            final parsedPressure = double.tryParse(rawPressure);
            if (parsedPressure == null || !parsedPressure.isFinite) {
              log('Invalid Bluetooth pressure ignored: $notification');
              return;
            }

            applyPressureData(parsedPressure.floor().toString());
          });
          if (generation == _pressureSubscriptionGeneration) {
            _pressureSubscriptions.add(subscription);
          } else {
            await subscription.cancel();
            return;
          }
        } catch (e, stackTrace) {
          log(
            'Subscribe Bluetooth pressure failed: $e',
            stackTrace: stackTrace,
          );
        }
      }
    }
  }

  String get selectedPeriodTypeLabel {
    switch (selectedPeriodType) {
      case 'PE':
        return 'Period End';
      case 'PI':
      default:
        return 'Period Inspection';
    }
  }

  bool get _usesCompanyOnePeriodRules =>
      homeState.userAccessCompanyId.value == '1';

  bool get _usesSiteFiveCompanyOnePiRules =>
      _usesCompanyOnePeriodRules && idSite == '5' && selectedPeriodType == 'PI';

  bool get _hideHmForPeriod => _usesSiteFiveCompanyOnePiRules;

  bool get _hideRtdForPeriod => _usesSiteFiveCompanyOnePiRules;

  bool get _hideSnForPeriod => _usesSiteFiveCompanyOnePiRules;

  bool get _hideTireComponentForPeriod =>
      _usesCompanyOnePeriodRules && selectedPeriodType == 'PE';

  bool get _usePreviousPressureFallbackForPeriod =>
      _usesCompanyOnePeriodRules && selectedPeriodType == 'PE';

  void _clearPreviousPressureFallbacksForPi() {
    for (final item in position) {
      if (item['_pressureFromHistory'] == true) {
        item['pressure'] = '';
        item['_pressureFromHistory'] = false;
      }
    }
  }

  String _validPressureValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return '';

    final number = double.tryParse(text);
    if (number != null && number < 0) return '';
    // if (number != null && number <= 0) return '';

    return text;
  }

  String _nonEmptySourceValue(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text.toLowerCase() == 'null') return '';
    return text;
  }

  Map<dynamic, dynamic>? _historyPositionAt(
    List<dynamic> positions,
    int index,
  ) {
    final positionNumber =
        position[index]['position']?.toString() ?? '${index + 1}';

    for (final item in positions) {
      if (item is Map &&
          (item['position'] ?? item['pos'])?.toString() == positionNumber) {
        return item;
      }
    }

    if (index < positions.length && positions[index] is Map) {
      return positions[index] as Map<dynamic, dynamic>;
    }

    return null;
  }

  Future<void> _loadHiddenFieldFallbacks() async {
    if (!_usesCompanyOnePeriodRules || position.isEmpty) {
      return;
    }

    final unitNumber = dataUnit['unitNumber']?.toString().trim() ?? '';
    if (unitNumber.isEmpty) return;

    final requestId = ++_hiddenFieldRequestId;
    setState(() {
      _isLoadingHiddenFieldFallbacks = true;
    });

    try {
      final snapshot = await firestore
          .collection('tire_inspection')
          .where('unit', isEqualTo: unitNumber)
          .orderBy('tanggal', descending: true)
          .limit(10)
          .get();

      if (!mounted || requestId != _hiddenFieldRequestId) return;

      final historyData = <Map<String, dynamic>>[];
      for (final document in snapshot.docs) {
        final data = document.data();
        final documentSite = data['id_site']?.toString().trim() ?? '';
        if (documentSite.isEmpty || documentSite == idSite) {
          historyData.add(data);
        }
      }

      String latestDocumentValue(String key) {
        for (final data in historyData) {
          final value = _nonEmptySourceValue(data[key]);
          if (value.isNotEmpty) return value;
        }
        return '';
      }

      String latestPositionValue(int index, String key) {
        for (final data in historyData) {
          final positions = data['posisi'];
          if (positions is! List) continue;

          final previousPosition = _historyPositionAt(positions, index);
          final value = _nonEmptySourceValue(previousPosition?[key]);
          if (value.isNotEmpty) return value;
        }
        return '';
      }

      List<Map<String, dynamic>> latestRimCondition(int index) {
        for (final data in historyData) {
          final positions = data['posisi'];
          if (positions is! List) continue;

          final previousPosition = _historyPositionAt(positions, index);
          final rimCondition = previousPosition?['rimCondition'];
          if (rimCondition is List && rimCondition.isNotEmpty) {
            return rimCondition
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          }
        }
        return <Map<String, dynamic>>[];
      }

      setState(() {
        if (_hideHmForPeriod) {
          final firebaseHm = latestDocumentValue('hm');
          hmUnit.text = _apiHmForHiddenFields.isNotEmpty
              ? _apiHmForHiddenFields
              : firebaseHm;
        }

        for (int index = 0; index < position.length; index++) {
          if (_hideRtdForPeriod) {
            final apiRtd = _nonEmptySourceValue(position[index]['_apiRtd']);
            final apiRtd2 = _nonEmptySourceValue(position[index]['_apiRtd2']);
            final firebaseRtd = latestPositionValue(index, 'rtd1');
            final firebaseRtd2 = latestPositionValue(index, 'rtd2');

            position[index]['rtd1'] = apiRtd.isNotEmpty ? apiRtd : firebaseRtd;
            position[index]['rtd2'] =
                apiRtd2.isNotEmpty ? apiRtd2 : firebaseRtd2;

            if (index < rtd1Controllers.length) {
              rtd1Controllers[index].text = position[index]['rtd1'].toString();
            }
            if (index < rtd2Controllers.length) {
              rtd2Controllers[index].text = position[index]['rtd2'].toString();
            }
          }

          if (_hideSnForPeriod) {
            final apiSn = _nonEmptySourceValue(position[index]['_apiSn']);
            final firebaseSn = latestPositionValue(index, 'sn');
            position[index]['sn'] = apiSn.isNotEmpty ? apiSn : firebaseSn;

            if (index < snControllers.length) {
              snControllers[index].text = position[index]['sn'].toString();
            }
          }

          if (_hideTireComponentForPeriod) {
            final historicalRimCondition = latestRimCondition(index);
            position[index]['rimCondition'] = historicalRimCondition.isNotEmpty
                ? historicalRimCondition
                : _defaultRimConditions();
          }
        }
      });
    } catch (e, stackTrace) {
      log(
        'Error loading hidden field fallbacks: $e',
        stackTrace: stackTrace,
      );
    } finally {
      if (mounted && requestId == _hiddenFieldRequestId) {
        setState(() {
          _isLoadingHiddenFieldFallbacks = false;
        });
      }
    }
  }

  Future<void> _fillMissingPressureFromHistory() async {
    if (!_usePreviousPressureFallbackForPeriod || position.isEmpty) return;

    final missingIndexes = <int>[];

    for (int index = 0; index < position.length; index++) {
      final pressureValue =
          position[index]['pressure']?.toString().trim() ?? '';

      if (pressureValue.isEmpty || pressureValue == 'null') {
        missingIndexes.add(index);
      }
    }

    if (missingIndexes.isEmpty) return;

    final unitNumber = dataUnit['unitNumber']?.toString().trim() ?? '';
    if (unitNumber.isEmpty) return;

    final requestId = ++_previousPressureRequestId;

    setState(() {
      _isLoadingPreviousPressure = true;
    });

    try {
      final snapshot = await firestore
          .collection('daily_pressure')
          .where('unit', isEqualTo: unitNumber)
          .orderBy('tanggal', descending: true)
          .limit(10)
          .get();

      if (!mounted || requestId != _previousPressureRequestId) return;

      // Filter history berdasarkan site
      final historyData = <Map<String, dynamic>>[];

      for (final document in snapshot.docs) {
        final data = document.data();

        final documentSite = data['idSite']?.toString().trim() ?? '';

        if (documentSite.isEmpty || documentSite == idSite) {
          historyData.add(data);
        }
      }

      setState(() {
        for (final index in missingIndexes) {
          if (index >= position.length) continue;

          String previousPressure = '';

          // Cari pressure terakhir untuk posisi ini
          // Tidak hanya dari 1 document terbaru.
          for (final history in historyData) {
            final historyPositions = history['posisi'];

            if (historyPositions is! List) continue;

            final previousPosition =
                _historyPositionAt(historyPositions, index);

            if (previousPosition == null) continue;

            final pressure =
                previousPosition['pressure']?.toString().trim() ?? '';

            final adjustment =
                previousPosition['adjusmentPressure']?.toString().trim() ?? '';

            // Adjustment adalah kondisi pressure paling akhir.
            if (adjustment.isNotEmpty && adjustment != 'null') {
              previousPressure = adjustment;
              break;
            }

            if (pressure.isNotEmpty && pressure != 'null') {
              previousPressure = pressure;
              break;
            }
          }

          if (previousPressure.isNotEmpty) {
            // Ada history
            position[index]['pressure'] = previousPressure;
            position[index]['_pressureFromHistory'] = true;
          } else {
            // Tidak pernah ada history pressure
            // PE tetap dapat disimpan dengan pressure 0.
            position[index]['pressure'] = '0';
            position[index]['_pressureFromHistory'] = false;
          }
        }
      });

      _scheduleDraftSave();
    } catch (e, stackTrace) {
      log(
        'Error loading previous pressure: $e',
        stackTrace: stackTrace,
      );

      // Kalau query Firebase error/tidak ada data,
      // PE tetap diberi fallback 0.
      if (mounted && requestId == _previousPressureRequestId) {
        setState(() {
          for (final index in missingIndexes) {
            if (index < position.length) {
              final value =
                  position[index]['pressure']?.toString().trim() ?? '';

              if (value.isEmpty || value == 'null') {
                position[index]['pressure'] = '0';
                position[index]['_pressureFromHistory'] = false;
              }
            }
          }
        });
      }
    } finally {
      if (mounted && requestId == _previousPressureRequestId) {
        setState(() {
          _isLoadingPreviousPressure = false;
        });
      }
    }
  }

  Widget _buildPeriodTypeSelector() {
    Widget buildOption({
      required String code,
      required String label,
      required IconData icon,
    }) {
      final bool isSelected = selectedPeriodType == code;

      return Expanded(
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            setState(() {
              selectedPeriodType = code;

              if (code != 'PE') {
                _previousPressureRequestId++;
                _isLoadingPreviousPressure = false;
              }

              if (code == 'PI') {
                _hiddenFieldRequestId++;
                _isLoadingHiddenFieldFallbacks = false;
                _clearPreviousPressureFallbacksForPi();
              }
            });
            _scheduleDraftSave();

            if (code == 'PE') {
              await _loadHiddenFieldFallbacks();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected ? Colors.orange : greyF7F8F9,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.black87,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: isSelected
                        ? getWhiteTextStyle(
                            fontSize: 12,
                            fontWeight: w700,
                          )
                        : getBlackTextStyle(
                            fontSize: 12,
                            fontWeight: w700,
                          ),
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '($code)',
                  style: TextStyle(
                    color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.fact_check_outlined,
              color: Colors.orange,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              'Inspection Period',
              style: getBlackTextStyle(
                fontSize: 14,
                fontWeight: w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            buildOption(
              code: 'PI',
              label: 'Period Inspection',
              icon: Icons.manage_search_outlined,
            ),
            const SizedBox(width: 8),
            buildOption(
              code: 'PE',
              label: 'Period End',
              icon: Icons.event_available_outlined,
            ),
          ],
        ),
      ],
    );
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

  bool _isUnitLocationSelectionPending({required bool hasUnitData}) {
    return hasUnitData &&
        pit.isNotEmpty &&
        (selectedPit < 0 || selectedPit >= pit.length);
  }

  Widget _buildUnitLocationOptions() {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 2),
        itemCount: pit.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, pitIndex) {
          final location = pit[pitIndex];

          return ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  selectedPit == pitIndex ? Colors.orange : greyF7F8F9,
            ),
            onPressed: () {
              setState(() {
                selectedPit = pitIndex;
              });
              _scheduleDraftSave();
            },
            child: Text(
              location,
              style: selectedPit == pitIndex
                  ? getWhiteTextStyle()
                  : getBlackTextStyle(),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmSnChange(int index) async {
    if (_editableSnIndexes.contains(index)) return;

    FocusManager.instance.primaryFocus?.unfocus();

    if (_isSnConfirmationOpen) return;
    _isSnConfirmationOpen = true;

    try {
      final shouldEdit = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Konfirmasi Serial Number'),
            content: const Text(
              'Apakah SN aktual pada ban berbeda dengan SN yang tercatat '
              'di sistem? Mohon periksa kembali sebelum melakukan perubahan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Tidak, Sudah Sesuai'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Ya, Ubah SN'),
              ),
            ],
          );
        },
      );

      if (!mounted || index >= snFocusNodes.length) return;

      if (shouldEdit == true) {
        setState(() {
          _editableSnIndexes.add(index);
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index < snFocusNodes.length) {
            snFocusNodes[index].requestFocus();
          }
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && index < snFocusNodes.length) {
            snFocusNodes[index].unfocus();
          }
        });
      }
    } finally {
      _isSnConfirmationOpen = false;
    }
  }

  String _selectedPitValue() {
    // if (!_isPitRequired()) {
    //   return 'Default';
    // }

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
    if (_isEditMode) {
      return List<int>.generate(position.length, (index) => index);
    }

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

  String? _existingImageUrlAt(int positionIndex) {
    if (positionIndex < 0 || positionIndex >= position.length) {
      return null;
    }

    final images = position[positionIndex]['_existingImages'];
    if (images is! List) return null;

    for (final image in images) {
      String? candidate;
      if (image is String) {
        candidate = image.trim();
      } else if (image is Map) {
        candidate =
            (image['url'] ?? image['image'] ?? image['src'])?.toString().trim();
      }

      if (candidate == null || candidate.isEmpty) continue;
      final uri = Uri.tryParse(candidate);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return candidate;
      }
    }

    return null;
  }

  String? _cachedLocalImagePathAt(int positionIndex) {
    if (positionIndex < 0 || positionIndex >= position.length) return null;
    final path =
        position[positionIndex]['_cachedLocalImagePath']?.toString().trim() ??
            '';
    if (path.isEmpty) return null;
    final file = File(path);
    return file.existsSync() ? path : null;
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
    final latestPositions = _isEditMode
        ? TireInspectionOfflineEditService.instance
            .loadByDocumentId(_editInspectionDocumentId)
            ?.data['posisi']
        : null;

    for (final index in activeIndexes) {
      if (index < 0 ||
          index >= position.length ||
          index >= state.units.length) {
        continue;
      }

      final item = position[index];
      final unit = state.units[index];
      final localImagePath = _localImagePathAt(index);
      var existingImages = _copyDynamicList(item['_existingImages']);
      var existingPending = item['_existingImagePending'] == true;
      if (localImagePath == null && latestPositions is List) {
        final latestPosition =
            _editPositionForUnit(latestPositions, unit, index);
        final uploadedImages = _copyDynamicList(latestPosition?['images']);
        if (uploadedImages.isNotEmpty &&
            latestPosition?['imagePending'] != true) {
          // Upload bisa selesai setelah form dibuka. Pertahankan URL hasilnya
          // ketika user hanya mengedit isian, bukan mengganti foto.
          existingImages = uploadedImages;
          existingPending = false;
        }
      }

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

      final originalPosition = item['_editOriginalPosition'] is Map
          ? Map<String, dynamic>.from(item['_editOriginalPosition'] as Map)
          : <String, dynamic>{};

      result.add({
        ...originalPosition,
        'position': item['position'] ?? index + 1,
        'pressure': item['pressure']?.toString() ?? '',
        'adjusmentPressure': item['adjusmentPressure']?.toString() ?? '',
        'temperatureStatus': item['temperatureStatus']?.toString() ?? 'HOT',
        'adjusmentTemperatureStatus':
            item['adjusmentTemperatureStatus']?.toString() ?? 'HOT',
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
        ...inspectionPhotoFields(
          existingImages: existingImages,
          existingPending: existingPending,
          newLocalImagePath: localImagePath,
        ),
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
        'temperatureStatus': item['temperatureStatus']?.toString() ?? 'HOT',
        'adjusmentTemperatureStatus':
            item['adjusmentTemperatureStatus']?.toString() ?? 'HOT',
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
    final recordDate = _isEditMode ? (_editInspectionDate ?? now) : now;
    final generatedHari =
        '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
    final generatedJam =
        '${recordDate.hour.toString().padLeft(2, '0')}:${recordDate.minute.toString().padLeft(2, '0')}:${recordDate.second.toString().padLeft(2, '0')}';
    final hari = _isEditMode
        ? _nonEmptySourceValue(_editInspectionData?['hari']).isNotEmpty
            ? _nonEmptySourceValue(_editInspectionData?['hari'])
            : generatedHari
        : generatedHari;
    final jam = _isEditMode
        ? _nonEmptySourceValue(_editInspectionData?['jam']).isNotEmpty
            ? _nonEmptySourceValue(_editInspectionData?['jam'])
            : generatedJam
        : generatedJam;
    final originalTimestamp =
        _nonEmptySourceValue(_editInspectionData?['tanggal']);

    return {
      'id': _isEditMode &&
              _nonEmptySourceValue(_editInspectionData?['id']).isNotEmpty
          ? _nonEmptySourceValue(_editInspectionData?['id'])
          : const Uuid().v4(),
      'id_site': idSite,
      'user': _effectiveUsername,
      'user_email': auth.currentUser?.email ?? '',
      'unit': dataUnit['unitNumber'] ?? firstUnit.unitNumber ?? '',
      'kunci_unit': firstUnit.kunciUnit ?? '',
      'hm': hmUnit.text,
      'hari': hari,
      'jam': jam,
      'tanggal': _isEditMode && originalTimestamp.isNotEmpty
          ? originalTimestamp
          : recordDate.toIso8601String(),
      'pit': _selectedPitValue(),
      'periodType': selectedPeriodType,
      'periodTypeLabel': selectedPeriodTypeLabel,
      'posisi': _buildInspectionPositions(state, activeIndexes),
      'brand': firstUnit.brand,
      'pattern': firstUnit.pattern,
      'savedOffline': savedOffline,
      'syncStatus': savedOffline ? 'pending' : 'synced',
      'lastLocalUpdate': now.toIso8601String(),
      if (_isEditMode) 'editedAt': now.toIso8601String(),
      if (_isEditMode) 'editedBy': auth.currentUser?.email ?? '',
    };
  }

  Map<String, dynamic> _buildDailyPressureData(
    DateTime now,
    List<int> activeIndexes, {
    required bool savedOffline,
  }) {
    final recordDate = _isEditMode ? (_editInspectionDate ?? now) : now;
    final generatedHari =
        '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
    final generatedJam =
        '${recordDate.hour.toString().padLeft(2, '0')}:${recordDate.minute.toString().padLeft(2, '0')}:${recordDate.second.toString().padLeft(2, '0')}';
    final hari = _isEditMode &&
            _nonEmptySourceValue(_editInspectionData?['hari']).isNotEmpty
        ? _nonEmptySourceValue(_editInspectionData?['hari'])
        : generatedHari;
    final jam = _isEditMode &&
            _nonEmptySourceValue(_editInspectionData?['jam']).isNotEmpty
        ? _nonEmptySourceValue(_editInspectionData?['jam'])
        : generatedJam;
    final originalTimestamp =
        _nonEmptySourceValue(_editInspectionData?['tanggal']);

    return {
      'idSite': idSite,
      'user': _effectiveUsername,
      'tanggal': _isEditMode && originalTimestamp.isNotEmpty
          ? originalTimestamp
          : recordDate.toIso8601String(),
      'hari': hari,
      'jam': jam,
      'unit': idUnit.text,
      'hm': hmUnit.text,
      'posisi': _buildDailyPressurePositions(activeIndexes, recordDate),
      'pit': _selectedPitValue(),
      'savedOffline': savedOffline,
      'syncStatus': savedOffline ? 'pending' : 'synced',
      'lastLocalUpdate': now.toIso8601String(),
      if (_isEditMode) 'editedAt': now.toIso8601String(),
      if (_isEditMode) 'editedBy': auth.currentUser?.email ?? '',
    };
  }

  void _queuePendingImages(
    String inspectionDocumentId,
    List<int> activeIndexes,
  ) {
    for (final entry in activeIndexes.asMap().entries) {
      final index = entry.value;
      final localImagePath = _localImagePathAt(index);
      if (localImagePath == null) {
        continue;
      }

      try {
        UploadQueueService.to.addPending(
          docId: inspectionDocumentId,
          filePath: localImagePath,
          posisiIndex: entry.key,
          tirePosition:
              position[index]['position']?.toString() ?? '${index + 1}',
        );
        TireInspectionOfflineEditService.instance.cacheLocalPhotoPath(
          inspectionDocumentId: inspectionDocumentId,
          tirePosition:
              position[index]['position']?.toString() ?? '${index + 1}',
          filePath: localImagePath,
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

    // Data baru yang dibuat tanpa jaringan belum tentu langsung dapat dibaca
    // ulang dari cache Firestore. Simpan snapshot lokal lebih dulu supaya
    // foto lokal yang masih berada pada antrean upload tetap dapat ditemukan
    // saat pengguna membuka form edit kembali.
    TireInspectionOfflineEditService.instance.cacheInspection(
      documentId: inspectionDocumentId,
      data: inspectionData,
    );

    final inspectionWrite =
        firestore.collection('tire_inspection').doc(inspectionDocumentId).set(
              inspectionData,
              SetOptions(merge: true),
            );
    final dailyPressureWrite =
        firestore.collection('daily_pressure').doc(dailyDocumentId).set(
              dailyPressureData,
              SetOptions(merge: true),
            );

    // Firestore menyelesaikan Future ini setelah write offline benar-benar
    // tersinkron. Sampai saat itu draft tetap menjadi cadangan lokal.
    final draftKey = _draftKey;
    final draftFingerprint = _lastDraftFingerprint;
    unawaited(() async {
      try {
        await Future.wait<void>(<Future<void>>[
          inspectionWrite,
          dailyPressureWrite,
        ]);
        if (draftKey != null && draftFingerprint != null) {
          await _deleteDraftIfUnchanged(
            key: draftKey,
            fingerprint: draftFingerprint,
          );
        }
      } catch (error, stackTrace) {
        log(
          'offline Tire Inspection sync error: $error',
          stackTrace: stackTrace,
        );
      }
    }());

    _queuePendingImages(inspectionDocumentId, activeIndexes);
  }

  Future<void> _updateInspectionOffline(TiresLoadedState state) async {
    if (_editInspectionDocumentId.trim().isEmpty) {
      throw StateError('ID dokumen Tire Inspection lama tidak tersedia.');
    }

    final now = DateTime.now();
    final recordDate = _editInspectionDate ?? now;
    final firstUnit = state.units.first;
    final unitNumber =
        dataUnit['unitNumber']?.toString() ?? firstUnit.unitNumber ?? '';
    final originalHari = _nonEmptySourceValue(_editInspectionData?['hari'])
            .isNotEmpty
        ? _nonEmptySourceValue(_editInspectionData?['hari'])
        : '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
    final activeIndexes = _activePositionIndexes();

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

    await TireInspectionOfflineEditService.instance.enqueueEdit(
      inspectionDocumentId: _editInspectionDocumentId,
      siteId: idSite,
      unitNumber: unitNumber,
      originalHari: originalHari,
      inspectionData: inspectionData,
      dailyPressureData: dailyPressureData,
    );

    _editInspectionData = Map<String, dynamic>.from(inspectionData);
    _queuePendingImages(_editInspectionDocumentId, activeIndexes);
  }

  Future<void> _updateInspectionOnline(TiresLoadedState state) async {
    final now = DateTime.now();
    final recordDate = _editInspectionDate ?? now;
    final firstUnit = state.units.first;
    final unitNumber =
        dataUnit['unitNumber']?.toString() ?? firstUnit.unitNumber ?? '';
    final originalHari = _nonEmptySourceValue(_editInspectionData?['hari'])
            .isNotEmpty
        ? _nonEmptySourceValue(_editInspectionData?['hari'])
        : '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
    final activeIndexes = _activePositionIndexes();

    final dailyQuery = await firestore
        .collection('daily_pressure')
        .where('unit', isEqualTo: unitNumber)
        .where('hari', isEqualTo: originalHari)
        .limit(10)
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? matchingDailyDocument;
    for (final document in dailyQuery.docs) {
      final documentSite = document.data()['idSite']?.toString().trim() ?? '';
      if (documentSite.isEmpty || documentSite == idSite) {
        matchingDailyDocument = document;
        break;
      }
    }

    final dailyDocumentId = matchingDailyDocument?.id ??
        _buildDailyPressureDocumentId(recordDate, unitNumber);
    final dailyPressureData = _buildDailyPressureData(
      now,
      activeIndexes,
      savedOffline: false,
    );
    final oldDailyPositions = matchingDailyDocument?.data()['posisi'];
    final newDailyPositions = dailyPressureData['posisi'];
    if (oldDailyPositions is List && newDailyPositions is List) {
      dailyPressureData['posisi'] = List<Map<String, dynamic>>.generate(
        newDailyPositions.length,
        (index) {
          final oldPosition = index < oldDailyPositions.length &&
                  oldDailyPositions[index] is Map
              ? Map<String, dynamic>.from(oldDailyPositions[index] as Map)
              : <String, dynamic>{};
          final newPosition = newDailyPositions[index] is Map
              ? Map<String, dynamic>.from(newDailyPositions[index] as Map)
              : <String, dynamic>{};
          return <String, dynamic>{...oldPosition, ...newPosition};
        },
      );
    }

    final updatedInspectionData = _buildInspectionData(
      state,
      now,
      activeIndexes,
      savedOffline: false,
    );

    final batch = firestore.batch();
    batch.set(
      firestore.collection('tire_inspection').doc(
            _editInspectionDocumentId,
          ),
      updatedInspectionData,
      SetOptions(merge: true),
    );
    batch.set(
      firestore.collection('daily_pressure').doc(dailyDocumentId),
      dailyPressureData,
      SetOptions(merge: true),
    );
    await batch.commit();

    TireInspectionOfflineEditService.instance.markSynced(
      inspectionDocumentId: _editInspectionDocumentId,
      inspectionData: updatedInspectionData,
    );

    _queuePendingImages(_editInspectionDocumentId, activeIndexes);
  }

  Future<void> _saveInspectionOnline(TiresLoadedState state) async {
    if (_isEditMode) {
      await _updateInspectionOnline(state);
      return;
    }

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

    final inspectionData = _buildInspectionData(
      state,
      now,
      activeIndexes,
      savedOffline: false,
    );
    await firestore.collection('tire_inspection').doc(inspectionDocumentId).set(
          inspectionData,
          SetOptions(merge: true),
        );

    // Jaga snapshot lokal tetap sama dengan data yang baru disimpan. Ini
    // memastikan preview foto pending tidak hilang bila form dibuka sebelum
    // worker upload berhasil mengirim gambar ke Storage.
    TireInspectionOfflineEditService.instance.cacheInspection(
      documentId: inspectionDocumentId,
      data: inspectionData,
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

    if (_isUnitLocationSelectionPending(
      hasUnitData: state.units.isNotEmpty,
    )) {
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

    if (_usesCompanyOnePeriodRules && _isLoadingHiddenFieldFallbacks) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Sedang melengkapi data dari API/Firebase. Silakan tunggu.',
            style: getWhiteTextStyle(),
          ),
        ),
      );
      return;
    }

    if (_usePreviousPressureFallbackForPeriod && _isLoadingPreviousPressure) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Sedang mengambil data pressure terakhir. Silakan tunggu.',
            style: getWhiteTextStyle(),
          ),
        ),
      );
      return;
    }

    if (_usesSiteFiveCompanyOnePiRules) {
      await _loadHiddenFieldFallbacks();
      if (!mounted) return;
    }

    if (_usePreviousPressureFallbackForPeriod) {
      await _fillMissingPressureFromHistory();
      if (!mounted) return;
    }

    if (selectedPeriodType == 'PI') {
      final missingPressurePositions = <String>[];

      for (int index = 0; index < state.units.length; index++) {
        final usesPreviousPressure = index < position.length &&
            position[index]['_pressureFromHistory'] == true;
        final pressureValue = index < position.length && !usesPreviousPressure
            ? _nonEmptySourceValue(position[index]['pressure'])
            : '';
        if (pressureValue.isNotEmpty) continue;

        final formPosition = index < position.length
            ? _nonEmptySourceValue(position[index]['position'])
            : '';
        final unitPosition = _nonEmptySourceValue(state.units[index].posisi);
        final positionValue =
            formPosition.isNotEmpty ? formPosition : unitPosition;
        missingPressurePositions.add(
          positionValue.isNotEmpty ? positionValue : '${index + 1}',
        );
      }

      if (missingPressurePositions.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 6),
            content: Text(
              'Pressure wajib diisi untuk seluruh posisi pada PI. '
              'Pilih 0 Psi jika No Tire atau Block Valve. '
              'Posisi yang belum diisi: '
              '${missingPressurePositions.join(', ')}.',
              style: getWhiteTextStyle(),
            ),
          ),
        );
        return;
      }
    }

    if (_usesCompanyOnePeriodRules) {
      final missingFields = <String>[];

      if (_hideHmForPeriod && _nonEmptySourceValue(hmUnit.text).isEmpty) {
        missingFields.add('HM');
      }

      for (int index = 0; index < position.length; index++) {
        if (_hideRtdForPeriod &&
            (_nonEmptySourceValue(position[index]['rtd1']).isEmpty ||
                _nonEmptySourceValue(position[index]['rtd2']).isEmpty)) {
          missingFields.add('RTD posisi ${index + 1}');
        }

        if (_hideSnForPeriod &&
            _nonEmptySourceValue(position[index]['sn']).isEmpty) {
          missingFields.add('SN posisi ${index + 1}');
        }

        if (_hideTireComponentForPeriod) {
          final rimCondition = position[index]['rimCondition'];
          if (rimCondition is! List || rimCondition.isEmpty) {
            missingFields.add('Tire Component posisi ${index + 1}');
          }
        }
      }

      if (missingFields.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Data API/Firebase belum tersedia: ${missingFields.join(', ')}.',
              style: getWhiteTextStyle(),
            ),
          ),
        );
        return;
      }
    }

    if (_usePreviousPressureFallbackForPeriod) {
      final missingPressurePositions = <String>[];
      for (int index = 0; index < position.length; index++) {
        if (_validPressureValue(position[index]['pressure']).isEmpty) {
          missingPressurePositions.add('${index + 1}');
        }
      }

      if (missingPressurePositions.isNotEmpty) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              'Data pressure terakhir tidak ditemukan untuk posisi: '
              '${missingPressurePositions.join(', ')}.',
              style: getWhiteTextStyle(),
            ),
          ),
        );
        return;
      }
    }

    final currentHm =
        double.tryParse(state.units.first.hm?.toString() ?? '0') ?? 0;
    final newHm = double.tryParse(hmUnit.text.trim()) ?? 0;

    if (!_hideHmForPeriod && currentHm > newHm) {
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

    if (!_hideHmForPeriod && (newHm - currentHm) > 1000) {
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
      final actualRtd2 = double.tryParse(unit.rtd?.toString() ?? '0') ?? 0;

      final inputRtd = i < rtd1Controllers.length
          ? double.tryParse(rtd1Controllers[i].text) ?? 0
          : double.tryParse(position[i]['rtd1']?.toString() ?? '0') ?? 0;
      final inputRtd2 = i < rtd2Controllers.length
          ? double.tryParse(rtd2Controllers[i].text) ?? 0
          : double.tryParse(position[i]['rtd2']?.toString() ?? '0') ?? 0;

      if (!_hideRtdForPeriod && inputRtd > actualRtd) {
        errorsRtd.add(
          'Posisi ${unit.posisi}: RTD input ($inputRtd) melebihi RTD aktual ($actualRtd).',
        );
      }

      if (!_hideRtdForPeriod && inputRtd2 > actualRtd2) {
        errorsRtd.add(
          'Posisi ${unit.posisi}: RTD 2 input ($inputRtd2) '
          'melebihi RTD aktual ($actualRtd2).',
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

    await _usernameReady;
    if (!mounted) return;
    await _persistEditedUsernameIfNeeded();
    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() {
      isLoadingSave = true;
    });

    try {
      await _persistDraftIfChanged(force: true);
      final hasNetwork = await _hasNetworkConnection();

      if (!hasNetwork) {
        if (_isEditMode) {
          await _updateInspectionOffline(state);
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
                'Tidak ada jaringan. Perubahan edit disimpan di perangkat dan akan disinkronkan ke dokumen lama saat koneksi tersedia.',
                style: getWhiteTextStyle(),
              ),
            ),
          );

          Navigator.pop(context, true);
          return;
        }

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
            _isEditMode
                ? 'Data Tire Inspection berhasil diperbarui.'
                : 'Successful save data, please check in home page',
            style: getWhiteTextStyle(),
          ),
          backgroundColor: green00968A,
        ),
      );

      await _deleteCurrentDraft();
      if (!mounted) return;
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
    return WillPopScope(
      onWillPop: _saveDraftBeforeLeaving,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Padding(
            padding: const EdgeInsets.only(top: 18.0),
            child: Text(
              _isEditMode ? 'Edit Tire Inspection' : 'Tire Inspection',
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
                  onPressed: () async {
                    final canLeave = await _saveDraftBeforeLeaving();
                    if (canLeave && mounted) Navigator.pop(context);
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
              if (state.units.isEmpty) {
                log('Tire Inspection: unit tidak memiliki data posisi ban.');
                return;
              }
              if (!_stateMatchesRequestedUnit(state)) {
                log(
                  'Tire Inspection: mengabaikan state lama unit '
                  '${state.units.first.unitNumber}.',
                );
                return;
              }

              _initializePositions(state);
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
              if (!_isFormInitializedFor(state)) {
                return const Center(child: CircularProgressIndicator());
              }
              final isUnitLocationSelectionPending =
                  _isUnitLocationSelectionPending(
                hasUnitData: units.isNotEmpty,
              );
              _syncPositionSectionKeys(units.length);

              return Stack(
                children: [
                  SingleChildScrollView(
                    controller: _formScrollController,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        units.length > 1 ? 54 : 24,
                        24,
                      ),
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
                              ? _buildUnitLocationOptions()
                              : Container(),
                          SizedBox(
                            height: (pit.isNotEmpty) ? 24 : 0,
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.account_circle,
                                color: Colors.blue,
                                size: 38,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'INSPECTOR',
                                  style: getBlackTextStyle(
                                    fontWeight: w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: usernameCtrl,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            onChanged: _handleUsernameChanged,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: greyF7F8F9,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(18),
                                borderSide: const BorderSide(color: greyDADADA),
                              ),
                              hintText: 'Masukkan username atau nama inspector',
                              hintStyle: getGreyTextStyle(grey8391A1),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
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
                                        type: const TextInputType
                                            .numberWithOptions(
                                          decimal: true,
                                        ),
                                        hint:
                                            'Fill ${idSite == bmbhauling.idSite ? 'KM' : 'HM'}',
                                      ),
                                    ),
                                    if (_defaultHmValue.isNotEmpty) ...[
                                      const SizedBox(height: 6),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: OutlinedButton.icon(
                                          onPressed: _resetHmToDefault,
                                          icon: const Icon(
                                            Icons.restart_alt,
                                            size: 18,
                                          ),
                                          label: const Text('Reset HM'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 7,
                                            ),
                                            minimumSize: const Size(0, 34),
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          if (homeState.userAccessCompanyId.value == '1')
                            _buildPeriodTypeSelector(),
                          const SizedBox(
                            height: 16,
                          ),
                          BlocBuilder<ConnectedDevicesCubit,
                              ConnectedDevicesState>(
                            builder: (context, cState) {
                              // Asumsikan perangkat TPMS adalah yang terhubung jika statusnya Success
                              final isConnected =
                                  cState is ConnectedDevicesLoadedState &&
                                      cState.connectedDevices.isNotEmpty;

                              // Cari perangkat yang terhubung yang memiliki nama yang relevan
                              // (Anda harus menyesuaikan logika pencarian ini sesuai nama perangkat BT Anda)
                              final BluetoothDevice? connectedDevice =
                                  isConnected
                                      ? cState.connectedDevices
                                          .firstWhereOrNull(
                                              (d) => d.advName.isNotEmpty)
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
                          BlocListener<BluetoothOnOffCubit,
                              BluetoothOnOffState>(
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
                                      .discoverServices(
                                          state.connectedDevices.first);
                                }
                              },
                              builder: (context, state) {
                                if (state is ConnectedDevicesLoadedState) {
                                  return BlocConsumer<DiscoverServicesCubit,
                                      DiscoverServiceState>(
                                    listener: (context, discoverState) {
                                      if (discoverState
                                          is ServicesLoadedState) {
                                        final services = discoverState.services;
                                        log('services pgd : $services');
                                        unawaited(
                                          _subscribePressureNotifications(
                                            services,
                                          ),
                                        );
                                      }
                                    },
                                    builder: (context, discoverState) {
                                      if (discoverState
                                          is ErrorLoadingServiceState) {
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.device_thermostat,
                                size: 38,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(
                                'Unit/Tire Temperature',
                                style: getBlackTextStyle(
                                  fontSize: 18,
                                  fontWeight: w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          TemperatureStatusSelectorWidget(
                            selectedStatus: position.isNotEmpty
                                ? position.first['temperatureStatus']
                                        ?.toString() ??
                                    'HOT'
                                : 'HOT',
                            onChanged: (value) {
                              setState(() {
                                for (final item in position) {
                                  item['temperatureStatus'] = value;
                                  item['adjusmentTemperatureStatus'] = value;
                                }
                              });
                              _scheduleDraftSave();
                            },
                          ),
                          const SizedBox(
                            height: 16,
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

                                return KeyedSubtree(
                                  key: _positionSectionKeys[index],
                                  child: Card(
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
                                                    MainAxisAlignment
                                                        .spaceBetween,
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
                                                        style:
                                                            getBlackTextStyle(
                                                                fontSize: 14),
                                                      ),
                                                      const SizedBox(
                                                        height: 6,
                                                      ),
                                                      Text(
                                                        '${index + 1}',
                                                        style:
                                                            getBlackTextStyle(
                                                                fontSize: 22,
                                                                fontWeight:
                                                                    w700),
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
                                                        style:
                                                            getBlackTextStyle(
                                                                fontWeight:
                                                                    w700),
                                                      ),
                                                      Text(
                                                        unit.unitNumber ?? '',
                                                        style:
                                                            getBlackTextStyle(),
                                                      ),
                                                    ],
                                                  ),
                                                  if (!_hideSnForPeriod)
                                                    const SizedBox(
                                                      height: 12,
                                                    ),
                                                  if (!_hideSnForPeriod)
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'SN',
                                                          style:
                                                              getBlackTextStyle(
                                                                  fontWeight:
                                                                      w700),
                                                        ),
                                                        Text(
                                                          unit.sn ?? '',
                                                          style:
                                                              getBlackTextStyle(),
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
                                                        style:
                                                            getBlackTextStyle(
                                                                fontWeight:
                                                                    w700),
                                                      ),
                                                      Text(
                                                        unit.brand ?? '',
                                                        style:
                                                            getBlackTextStyle(),
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
                                                        style:
                                                            getBlackTextStyle(
                                                                fontWeight:
                                                                    w700),
                                                      ),
                                                      Text(
                                                        unit.lifetime ?? '',
                                                        style:
                                                            getBlackTextStyle(),
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
                                                        style:
                                                            getBlackTextStyle(
                                                                fontWeight:
                                                                    w700),
                                                      ),
                                                      Text(
                                                        unit.rating ?? '',
                                                        style:
                                                            getBlackTextStyle(),
                                                      ),
                                                    ],
                                                  ),
                                                  if (!_hideRtdForPeriod)
                                                    const SizedBox(
                                                      height: 12,
                                                    ),
                                                  if (!_hideRtdForPeriod)
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'RTD',
                                                          style:
                                                              getBlackTextStyle(
                                                                  fontWeight:
                                                                      w700),
                                                        ),
                                                        Text(
                                                          '${unit.rtd} / ${unit.rtd}' ??
                                                              '',
                                                          style:
                                                              getBlackTextStyle(),
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
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: SizedBox(
                                                      width:
                                                          MediaQuery.of(context)
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
                                                                (BuildContext
                                                                    context) {
                                                              return Dialog(
                                                                child:
                                                                    Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              20.0),
                                                                  child:
                                                                      SingleChildScrollView(
                                                                    child:
                                                                        Column(
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
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                            height:
                                                                                16.0),
                                                                        Column(),
                                                                        Wrap(
                                                                          children:
                                                                              pressure.map((ps) {
                                                                            final psIndex =
                                                                                pressure.indexOf(ps);
                                                                            return Padding(
                                                                              padding: const EdgeInsets.only(right: 16, bottom: 18),
                                                                              child: ElevatedButton(
                                                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                                                onPressed: () {
                                                                                  final id = Uuid();
                                                                                  setState(() {
                                                                                    position[index]['pressure'] = ps;
                                                                                    position[index]['_pressureFromHistory'] = false;
                                                                                    Navigator.of(context).pop();
                                                                                  });
                                                                                  _markPositionAsEntered(index);
                                                                                  _scheduleDraftSave();
                                                                                },
                                                                                child: Text(
                                                                                  ps,
                                                                                  style: getWhiteTextStyle(
                                                                                    fontWeight: w700,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }).toList(),
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: SizedBox(
                                                                                width: double.infinity,
                                                                                child: InputFormWidget(controller: pressureCtrl, isDigitOnly: true, type: TextInputType.number, hint: 'Input Manual'),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 6,
                                                                            ),
                                                                            ElevatedButton(
                                                                                onPressed: () {
                                                                                  setState(() {
                                                                                    if (pressureCtrl.text != '') {
                                                                                      position[index]['pressure'] = pressureCtrl.text;
                                                                                      position[index]['_pressureFromHistory'] = false;
                                                                                      _markPositionAsEntered(index);
                                                                                    }
                                                                                    pressureCtrl.clear();
                                                                                    Navigator.of(context).pop();
                                                                                  });
                                                                                  _scheduleDraftSave();
                                                                                },
                                                                                child: Text('Submit'))
                                                                          ],
                                                                        ),
                                                                        SizedBox(
                                                                            height:
                                                                                12.0),
                                                                        SizedBox(
                                                                          width:
                                                                              double.infinity,
                                                                          child:
                                                                              ElevatedButton(
                                                                            onPressed:
                                                                                () {
                                                                              pressureCtrl.clear();
                                                                              Navigator.of(context).pop();
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
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                                backgroundColor:
                                                                    Colors.blue,
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              12),
                                                                )),
                                                        child: (position[index][
                                                                        'pressure'] ==
                                                                    '' ||
                                                                (position[index]
                                                                        [
                                                                        'pressure'] ==
                                                                    null))
                                                            ? Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: [
                                                                  Icon(
                                                                    Icons.add,
                                                                    color:
                                                                        white,
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
                                                                  fontWeight:
                                                                      w700,
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
                                                      width:
                                                          MediaQuery.of(context)
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
                                                                (BuildContext
                                                                    context) {
                                                              return Dialog(
                                                                child:
                                                                    Container(
                                                                  padding:
                                                                      EdgeInsets
                                                                          .all(
                                                                              20.0),
                                                                  child:
                                                                      SingleChildScrollView(
                                                                    child:
                                                                        Column(
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
                                                                                FontWeight.bold,
                                                                          ),
                                                                        ),
                                                                        SizedBox(
                                                                            height:
                                                                                16.0),
                                                                        Column(),
                                                                        Wrap(
                                                                          children:
                                                                              pressure.map((ps) {
                                                                            final psIndex =
                                                                                pressure.indexOf(ps);
                                                                            return Padding(
                                                                              padding: const EdgeInsets.only(right: 16, bottom: 18),
                                                                              child: ElevatedButton(
                                                                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                                                onPressed: () {
                                                                                  setState(() {
                                                                                    position[index]['adjusmentPressure'] = ps;
                                                                                    Navigator.of(context).pop();
                                                                                  });
                                                                                  _markPositionAsEntered(index);
                                                                                  _scheduleDraftSave();
                                                                                },
                                                                                child: Text(
                                                                                  ps,
                                                                                  style: getWhiteTextStyle(
                                                                                    fontWeight: w700,
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            );
                                                                          }).toList(),
                                                                        ),
                                                                        Row(
                                                                          children: [
                                                                            Expanded(
                                                                              child: SizedBox(
                                                                                width: double.infinity,
                                                                                child: InputFormWidget(controller: pressureCtrl, isDigitOnly: true, type: TextInputType.number, hint: 'Input Manual'),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(
                                                                              width: 6,
                                                                            ),
                                                                            ElevatedButton(
                                                                                onPressed: () {
                                                                                  setState(() {
                                                                                    if (pressureCtrl.text != '') {
                                                                                      position[index]['adjusmentPressure'] = pressureCtrl.text;
                                                                                      _markPositionAsEntered(index);
                                                                                    }
                                                                                    pressureCtrl.clear();
                                                                                    Navigator.of(context).pop();
                                                                                  });
                                                                                  _scheduleDraftSave();
                                                                                },
                                                                                child: const Text('Submit'))
                                                                          ],
                                                                        ),
                                                                        SizedBox(
                                                                            height:
                                                                                12.0),
                                                                        SizedBox(
                                                                          width:
                                                                              double.infinity,
                                                                          child:
                                                                              ElevatedButton(
                                                                            onPressed:
                                                                                () {
                                                                              pressureCtrl.clear();
                                                                              Navigator.of(context).pop();
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
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                                backgroundColor:
                                                                    Colors.blue,
                                                                shape:
                                                                    RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
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
                                                                  fontWeight:
                                                                      w700,
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
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                height: 45,
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    // setState(() {
                                                    //   selectedPosIndex = posIndex;
                                                    // });

                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
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
                                                                    'Choose Rating',
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
                                                                        rating.map(
                                                                            (rat) {
                                                                      final ratingIndex =
                                                                          rating
                                                                              .indexOf(rat);
                                                                      return Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            right:
                                                                                16,
                                                                            bottom:
                                                                                18),
                                                                        child:
                                                                            ElevatedButton(
                                                                          style:
                                                                              ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              position[index]['rating'] = rat;
                                                                              Navigator.of(context).pop();
                                                                            });
                                                                            _markPositionAsEntered(index);
                                                                            _scheduleDraftSave();
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            rat,
                                                                            style:
                                                                                getWhiteTextStyle(
                                                                              fontWeight: w700,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }).toList(),
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
                                                                        Navigator.of(context)
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          )),
                                                  child: (position[index]
                                                              ['rating'] ==
                                                          '')
                                                      ? Text(
                                                          'Rating',
                                                          style:
                                                              getWhiteTextStyle(),
                                                        )
                                                      : Text(
                                                          'Rating ${position[index]['rating']}',
                                                          style:
                                                              getWhiteTextStyle(
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
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
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
                                                  ).copyWith(
                                                      color: Colors.white),
                                                ),
                                              ),

                                              SizedBox(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    if (index == 0)
                                                      log('luka map : ${position[index]['damageTire']}');
                                                    FocusScope.of(context)
                                                        .unfocus();

                                                    if (loadingDamages) {
                                                      // Optional: kasih feedback kalau masih loading
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Sedang memuat daftar damage...')),
                                                      );
                                                      return;
                                                    }

                                                    if (damageType.isEmpty) {
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                        const SnackBar(
                                                            content: Text(
                                                                'Daftar damage kosong')),
                                                      );
                                                      return;
                                                    }

                                                    final List<dynamic>
                                                        existingDamages =
                                                        position[index][
                                                                'damageTire'] ??
                                                            [];

                                                    List<bool>
                                                        checkedDamageValues;

                                                    if (existingDamages
                                                            .isEmpty ||
                                                        existingDamages[0] ==
                                                            "") {
                                                      print(
                                                          'exisitng damage empty true');
                                                      // otomatis centang Good Condition jika belum ada damage
                                                      checkedDamageValues =
                                                          damageType
                                                              .map((damage) {
                                                        final text =
                                                            damage['remark']
                                                                .toString()
                                                                .toLowerCase()
                                                                .trim();
                                                        return text == 'good' ||
                                                            text ==
                                                                'good condition';
                                                      }).toList();
                                                    } else {
                                                      print(
                                                          'exisitng damage empty false');
                                                      // jika sudah ada data damage
                                                      checkedDamageValues =
                                                          damageType
                                                              .map((damage) {
                                                        return existingDamages
                                                            .contains(damage[
                                                                'remark']);
                                                      }).toList();
                                                    }

                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
                                                        return Dialog(
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(20.0),
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <Widget>[
                                                                const Text(
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
                                                                const SizedBox(
                                                                    height:
                                                                        12.0),
                                                                Expanded(
                                                                  child:
                                                                      SingleChildScrollView(
                                                                    child:
                                                                        Column(
                                                                      children:
                                                                          damageType
                                                                              .map((damage) {
                                                                        final dmgIndex =
                                                                            damageType.indexOf(damage);

                                                                        // kalau tidak perlu skip index 0, hapus if ini
                                                                        // if (dmgIndex == 0) return Container();

                                                                        return StatefulBuilder(
                                                                          builder:
                                                                              (context, setState) {
                                                                            return CheckboxListTile(
                                                                              title: Text(damage['remark']),
                                                                              value: checkedDamageValues[dmgIndex],
                                                                              onChanged: (bool? value) {
                                                                                setState(() {
                                                                                  bool newValue = value ?? false;

                                                                                  if (dmgIndex == 0) {
                                                                                    // GOOD CONDITION dicentang
                                                                                    checkedDamageValues = List<bool>.filled(checkedDamageValues.length, false);
                                                                                    checkedDamageValues[0] = newValue;
                                                                                  } else {
                                                                                    // Damage lain dicentang
                                                                                    checkedDamageValues[dmgIndex] = newValue;

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
                                                                    height:
                                                                        12.0),
                                                                Column(
                                                                  children: [
                                                                    const SizedBox(
                                                                        height:
                                                                            12),
                                                                    SizedBox(
                                                                      width: double
                                                                          .infinity,
                                                                      child:
                                                                          ElevatedButton(
                                                                        onPressed:
                                                                            () {
                                                                          damageCtrl
                                                                              .clear();
                                                                          _scheduleDraftSave();
                                                                          Navigator.pop(
                                                                              context);
                                                                        },
                                                                        child: const Text(
                                                                            'Close'),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                        height:
                                                                            12),
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
                                                                          selectedDamage
                                                                              .clear();

                                                                          Map<String, int>
                                                                              ratingPriority =
                                                                              {
                                                                            '': 1,
                                                                            'A':
                                                                                1,
                                                                            'B':
                                                                                2,
                                                                            'C':
                                                                                3,
                                                                            'X':
                                                                                4,
                                                                          };

                                                                          final List<Map<String, dynamic>>
                                                                              tmp =
                                                                              [];

                                                                          // NOTE: ini tadinya if (== '' || isNotEmpty) -> selalu true.
                                                                          if (damageCtrl
                                                                              .text
                                                                              .isNotEmpty) {
                                                                            tmp.add({
                                                                              'remark': damageCtrl.text,
                                                                              'rating': ''
                                                                            });
                                                                          }

                                                                          for (int i = 0;
                                                                              i < checkedDamageValues.length;
                                                                              i++) {
                                                                            if (checkedDamageValues[i]) {
                                                                              tmp.add(damageType[i]);
                                                                            }
                                                                          }

                                                                          final onlyRemark = tmp
                                                                              .map<String>((item) => item['remark']?.toString() ?? '')
                                                                              .where((remark) => remark.isNotEmpty)
                                                                              .toList();

                                                                          position[index]['damageTire'] =
                                                                              onlyRemark;

                                                                          if (tmp
                                                                              .isNotEmpty) {
                                                                            position[index]['damageTire'] =
                                                                                onlyRemark;

                                                                            // rating based damage
                                                                            String
                                                                                worstRating =
                                                                                '';
                                                                            worstRating =
                                                                                tmp.fold(
                                                                              '',
                                                                              (worst, item) {
                                                                                final current = item['rating'] ?? '';

                                                                                return ratingPriority[current]! > ratingPriority[worst]! ? current : worst;
                                                                              },
                                                                            );

                                                                            if (_usesAutomaticDamageRating) {
                                                                              position[index]['rating'] = worstRating;
                                                                            }

                                                                            selectedDamage.addAll(onlyRemark);

                                                                            log('hasil luka ban : $position');
                                                                          }

                                                                          if (tmp
                                                                              .isNotEmpty) {
                                                                            _markPositionAsEntered(index);
                                                                          }
                                                                          setState(
                                                                              () {});
                                                                          _scheduleDraftSave();
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor: blue344BEF,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 8.0),
                                                    child: Text(
                                                      ((position[index][
                                                                      'damageTire'] ==
                                                                  null) ||
                                                              (position[index][
                                                                          'damageTire']
                                                                      as List)
                                                                  .where((e) =>
                                                                      e !=
                                                                          null &&
                                                                      e
                                                                          .toString()
                                                                          .trim()
                                                                          .isNotEmpty)
                                                                  .isEmpty)
                                                          ? 'Good Condition'
                                                          : (position[index][
                                                                      'damageTire']
                                                                  as List)
                                                              .join('\n---\n'),
                                                      textAlign:
                                                          TextAlign.center,
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.orange,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    showRimInspectionDialog(
                                                        index);
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
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                Colors.green,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            )),
                                                    onPressed: () async {
                                                      final ImagePicker picker =
                                                          ImagePicker();

                                                      final ImageSource?
                                                          source =
                                                          await showDialog<
                                                              ImageSource>(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: Text(
                                                                "Pilih Sumber Gambar"),
                                                            content: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                ListTile(
                                                                  leading: Icon(
                                                                      Icons
                                                                          .camera_alt),
                                                                  title: Text(
                                                                      "Kamera"),
                                                                  onTap: () => Navigator.pop(
                                                                      context,
                                                                      ImageSource
                                                                          .camera),
                                                                ),
                                                                ListTile(
                                                                  leading: Icon(
                                                                      Icons
                                                                          .photo_library),
                                                                  title: Text(
                                                                      "Gallery"),
                                                                  onTap: () => Navigator.pop(
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

                                                      if (source == null)
                                                        return;

                                                      if (source ==
                                                          ImageSource.camera) {
                                                        requestCameraPermission();
                                                      }

                                                      final XFile? image =
                                                          await picker
                                                              .pickImage(
                                                        source: source,
                                                        imageQuality: 70,
                                                        maxWidth: 1920,
                                                        maxHeight: 1920,
                                                      );

                                                      try {
                                                        if (image != null) {
                                                          Directory? directory;

                                                          if (Platform
                                                              .isAndroid) {
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
                                                            quality: 70,
                                                            minWidth: 1280,
                                                            minHeight: 1280,
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
                                                            position[index]
                                                                ['image'] = [
                                                              '${compressedImageFile.path}|${position[index]['position']}'
                                                            ];

                                                            // Hapus hasil AI dari foto sebelumnya.
                                                            aiResults
                                                                .remove(index);
                                                            imageWidths
                                                                .remove(index);
                                                            imageHeights
                                                                .remove(index);
                                                            loadingAI[index] =
                                                                false;
                                                          });
                                                          _markPositionAsEntered(
                                                              index);
                                                          _scheduleDraftSave();

                                                          log('tire inspection image = ${position[index]['image']}');
                                                        }
                                                      } catch (e) {
                                                        log('error gambar string : $e');
                                                      }

                                                      setState(() {});
                                                    },
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
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
                                                          style:
                                                              getWhiteTextStyle(),
                                                        ),
                                                      ],
                                                    )),
                                              ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                              if ((position[index]['image']
                                                          as List)
                                                      .isEmpty &&
                                                  position[index][
                                                          '_pendingLocalImagePath']
                                                      is String)
                                                PendingInspectionPhotoPreview(
                                                  filePath: position[index][
                                                          '_pendingLocalImagePath']
                                                      as String,
                                                ),
                                              if ((position[index]['image']
                                                          as List)
                                                      .isEmpty &&
                                                  position[index][
                                                          '_pendingLocalImagePath']
                                                      is! String &&
                                                  _cachedLocalImagePathAt(
                                                          index) !=
                                                      null)
                                                CachedInspectionPhotoPreview(
                                                  filePath:
                                                      _cachedLocalImagePathAt(
                                                          index)!,
                                                ),
                                              if ((position[index]['image']
                                                          as List)
                                                      .isEmpty &&
                                                  position[index][
                                                          '_pendingLocalImagePath']
                                                      is! String &&
                                                  _cachedLocalImagePathAt(
                                                          index) ==
                                                      null &&
                                                  _existingImageUrlAt(index) !=
                                                      null)
                                                ExistingInspectionPhotoPreview(
                                                  imageUrl: _existingImageUrlAt(
                                                      index)!,
                                                ),
                                              ((position[index]['image']
                                                          as List<dynamic>)
                                                      .isNotEmpty)
                                                  ? Column(
                                                      children: [
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
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
                                                                            BorderRadius.circular(12),
                                                                      )),
                                                              onPressed:
                                                                  () async {
                                                                showDialog(
                                                                    context:
                                                                        context,
                                                                    builder:
                                                                        (context) {
                                                                      return AlertDialog(
                                                                        content:
                                                                            Text(
                                                                          'Are you sure you want to delete this image?',
                                                                          style:
                                                                              getBlackTextStyle(),
                                                                        ),
                                                                        actions: [
                                                                          TextButton(
                                                                              onPressed: () {
                                                                                Navigator.pop(context);
                                                                              },
                                                                              child: Text(
                                                                                'Cancel',
                                                                                style: getGreyTextStyle(grey8391A1),
                                                                              )),
                                                                          TextButton(
                                                                              onPressed: () {
                                                                                setState(() {
                                                                                  position[index]['image'] = [];
                                                                                  aiResults.remove(index);
                                                                                  loadingAI.remove(index);
                                                                                  imageWidths.remove(index);
                                                                                  imageHeights.remove(index);
                                                                                });
                                                                                _scheduleDraftSave();
                                                                                Navigator.pop(context);
                                                                              },
                                                                              child: Text(
                                                                                'Yes',
                                                                                style: getRedTextStyle(),
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
                                                                    Icons
                                                                        .delete,
                                                                    color:
                                                                        white,
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
                                                        (loadingAI[index] ==
                                                                true)
                                                            ? Center(
                                                                child:
                                                                    AiLoadingWidget(),
                                                              )
                                                            : Stack(
                                                                children: [
                                                                  Container(
                                                                    width: double
                                                                        .infinity,
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                    ),
                                                                    child: Image
                                                                        .file(
                                                                      File(
                                                                        (position[index]['image'][0]
                                                                                as String)
                                                                            .split('|')[0],
                                                                      ),
                                                                      cacheWidth:
                                                                          1080,
                                                                      fit: BoxFit
                                                                          .contain,
                                                                    ),
                                                                  ),
                                                                  if (aiResults[
                                                                          index] !=
                                                                      null)
                                                                    Positioned
                                                                        .fill(
                                                                      child:
                                                                          CustomPaint(
                                                                        painter:
                                                                            BoundingBoxPainter(
                                                                          detections:
                                                                              aiResults[index]?.data?.tireDamageResult ?? [],
                                                                          imageWidth:
                                                                              imageWidths[index] ?? 1,
                                                                          imageHeight:
                                                                              imageHeights[index] ?? 1,
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
                                                              double.infinity,
                                                          height: 45,
                                                          child: ElevatedButton(
                                                            style:
                                                                ElevatedButton
                                                                    .styleFrom(
                                                              backgroundColor:
                                                                  Colors.purple,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                            ),
                                                            onPressed: loadingAI[
                                                                        index] ==
                                                                    true
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
                                                                  Icons
                                                                      .auto_awesome,
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
                                                                    fontWeight:
                                                                        w700,
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

                                              if (!_hideRtdForPeriod)
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
                                                            style:
                                                                getBlackTextStyle(
                                                                    fontWeight:
                                                                        w700),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                double.infinity,
                                                            child:
                                                                InputFormWidget(
                                                              onChng: (value) {
                                                                position[index][
                                                                        'rtd1'] =
                                                                    value;
                                                                _markPositionAsEntered(
                                                                    index);
                                                              },
                                                              controller:
                                                                  rtd1Controllers[
                                                                      index],
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
                                                            CrossAxisAlignment
                                                                .stretch,
                                                        children: [
                                                          Text(
                                                            'RTD 2',
                                                            style:
                                                                getBlackTextStyle(
                                                                    fontWeight:
                                                                        w700),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          SizedBox(
                                                            width:
                                                                double.infinity,
                                                            child:
                                                                InputFormWidget(
                                                              onChng: (value) {
                                                                position[index][
                                                                        'rtd2'] =
                                                                    value;
                                                                _markPositionAsEntered(
                                                                    index);
                                                              },
                                                              controller:
                                                                  rtd2Controllers[
                                                                      index],
                                                              hint: '',
                                                            ),
                                                          ),
                                                          // Builder(builder: (context) {
                                                          //   rtd2Controllers[index].text =
                                                          //       unit.rtd ?? '';
                                                          //   position[index]['rtd2'] =
                                                          //       unit.rtd;
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
                                              if (!_hideRtdForPeriod)
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                              if (!_hideSnForPeriod)
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .stretch,
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
                                                          isReadOnly:
                                                              !_editableSnIndexes
                                                                  .contains(
                                                                      index),
                                                          focusNode:
                                                              snFocusNodes[
                                                                  index],
                                                          onTap: () {
                                                            unawaited(
                                                              _confirmSnChange(
                                                                index,
                                                              ),
                                                            );
                                                          },
                                                          onChng: (value) {
                                                            position[index]
                                                                ['sn'] = value;
                                                            _markPositionAsEntered(
                                                                index);
                                                          },
                                                          controller:
                                                              snControllers[
                                                                  index],
                                                          hint: ''),
                                                    ),
                                                  ],
                                                ),
                                              if (!_hideSnForPeriod)
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
                                                                  ['remarks'] =
                                                              value;
                                                          _markPositionAsEntered(
                                                              index);
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
                                  ),
                                );
                              }),
                        ],
                      ),
                    ),
                  ),
                  if (units.length > 1)
                    Positioned(
                      top: 24,
                      right: 6,
                      bottom: 24,
                      child: Center(
                        child: _buildTirePositionIndex(units.length),
                      ),
                    ),
                  if (isUnitLocationSelectionPending)
                    Positioned.fill(
                      child: Stack(
                        children: [
                          const ModalBarrier(
                            dismissible: false,
                            color: Color(0x33000000),
                          ),
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                24,
                                24,
                                units.length > 1 ? 54 : 24,
                                24,
                              ),
                              child: Material(
                                elevation: 8,
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.ev_station,
                                            size: 32,
                                            color: Colors.orange,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Pilih Unit Location',
                                              style: getBlackTextStyle(
                                                fontSize: 18,
                                                fontWeight: w700,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Location wajib dipilih sebelum data '
                                        'inspeksi dapat diinput.',
                                        style: getBlackTextStyle(),
                                      ),
                                      const SizedBox(height: 12),
                                      _buildUnitLocationOptions(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
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
                if (state is TiresLoadedState && _isFormInitializedFor(state)) {
                  final isUnitLocationSelectionPending =
                      _isUnitLocationSelectionPending(
                    hasUnitData: state.units.isNotEmpty,
                  );

                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    child: ButtonWidget(
                        color: isUnitLocationSelectionPending
                            ? Colors.grey
                            : black,
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
                                    _isEditMode ? 'Update' : 'Save',
                                    style: getWhiteTextStyle(),
                                  ),
                                ],
                              ),
                        function: isUnitLocationSelectionPending
                            ? null
                            : () async {
                                await _handleSaveTireInspection(state);
                              }),
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
  }
}
