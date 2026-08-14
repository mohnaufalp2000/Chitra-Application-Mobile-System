// import 'dart:developer';

// import 'package:camos/core/utils/data/id_site.dart';
// import 'package:camos/main.dart';
// import 'package:camos/objectbox.g.dart';
// import 'package:camos/pages/home/home_state.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/upload_queue_service.dart';
// import 'package:get/get.dart';

// import '../../core/blocs/unit/unit_bloc.dart';
// import '../../core/services/shared_preferences/shared_preferences.dart';
// import '../../core/styles/color.dart';
// import '../../core/styles/text_manager.dart';
// import '../../core/widgets/appbar_widget.dart';
// import 'daily_check_form_page.dart';
// import 'daily_pressure_list.dart';
// import 'tire_inspection_form_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class SelectUnitPage extends StatefulWidget {
//   static const routeName = '/select-unit-page';
//   SelectUnitPage({super.key});

//   @override
//   State<SelectUnitPage> createState() => _SelectUnitPageState();
// }

// class _SelectUnitPageState extends State<SelectUnitPage> with RouteAware {
//   String searchQuery = '';
//   bool isOnline = false;
//   final HomeState homeState = Get.find<HomeState>();

//   @override
//   void initState() {
//     super.initState();
//     callUnits();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // subscribe ke routeObserver global
//     final modal = ModalRoute.of(context);
//     if (modal != null) {
//       routeObserver.subscribe(this, modal);
//     }
//   }

//   @override
//   void dispose() {
//     // unsubscribe sebelum dispose
//     routeObserver.unsubscribe(this);
//     super.dispose();
//   }

//   // Dipanggil ketika suatu route DIPUSH di atas route ini (halaman ini 'ditinggalkan')
//   @override
//   void didPushNext() {
//     super.didPushNext();
//     // halaman ditumpuk oleh route lain -> panggil retryPending()
//     _triggerRetryPending();
//   }

//   // (opsional) kalau ingin saat kembali ke page
//   @override
//   void didPopNext() {
//     super.didPopNext();
//     // route di atas di-pop, kita kembali visible
//     // bisa panggil retryPending di sini juga jika mau
//   }

//   Future<void> _triggerRetryPending() async {
//     try {
//       // cek dulu koneksi optional atau langsung panggil
//       // await InternetConnectionChecker().hasConnection
//       // jika kamu tidak mau cek, langsung panggil:
//       await UploadQueueService.to.retryPending();
//       // atau kalau tidak pake singleton, panggil instance mu
//       log('triggerRetryPending from SelectUnitPage.didPushNext');
//     } catch (e, st) {
//       log('retryPending error: $e\n$st');
//     }
//   }

//   Future<void> callUnits() async {
//     String currentSiteId = homeState.currentSiteId;
//     String userAccessId = homeState.userAccessId.value;

//     bool isSis = homeState.userAccessCompanyId.value == '1';

//     log('test call units 1 : $currentSiteId');
//     log('test call units 2 : $userAccessId');
//     context.read<UnitBloc>().add(GetUnitsEvent(
//         idSite: currentSiteId,
//         isOnline:
//             // (userAccessId == '1' || userAccessId == '2') ? true : isOnline));
//             (userAccessId == '1' && !isSis) ? true : isOnline));
//   }

//   Future<String> getActualIdSite() async {
//     final actIdSite = await getIdSitePreferences();

//     return actIdSite;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final inspectionType = ModalRoute.of(context)?.settings.arguments as String;

//     return Scaffold(
//       appBar: (inspectionType == 'daily_check')
//           ? AppBar(
//               centerTitle: true,
//               title: Text(
//                 'Daily Check Pressure',
//                 style: getBlackTextStyle(),
//               ),
//               actions: [
//                 InkWell(
//                   onTap: () {
//                     Navigator.pushNamed(
//                         context, DailyPressureListPage.routeName);
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.only(
//                       right: 8.0,
//                       top: 8.0,
//                     ),
//                     child: Icon(
//                       Icons.list,
//                       size: 32,
//                     ),
//                   ),
//                 )
//               ],
//             )
//           : appBarWidget('Select Unit First', context),
//       body: SafeArea(
//           child: SingleChildScrollView(
//         child: Container(
//           margin: EdgeInsets.only(top: 12),
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: BlocConsumer<UnitBloc, UnitState>(
//             listener: (context, state) {
//               if (state is UnitErrorState) {
//                 setState(() {
//                   isOnline = !isOnline;
//                 });
//                 showDialog(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return AlertDialog(
//                         title: Text(
//                           'Please check your internet connection!',
//                           style: getBlackTextStyle(),
//                         ),
//                         actions: [
//                           TextButton(
//                               onPressed: () {
//                                 Navigator.pop(context);
//                                 Navigator.pop(context);
//                               },
//                               child: Text('Okay'))
//                         ],
//                       );
//                     });
//               }
//             },
//             builder: (context, state) {
//               if (state is UnitLoadingState) {
//                 return Center(child: CircularProgressIndicator());
//               }

//               if (state is UnitLoadedState) {
//                 log('kondisi state : ${state.units.length}');

//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     TextField(
//                       onChanged: (value) {
//                         setState(() {
//                           searchQuery = value;
//                         });
//                       },
//                       decoration: InputDecoration(
//                           hintText: 'Search... (Unit Number or Model)',
//                           hintStyle: getGreyTextStyle(grey8391A1),
//                           prefixIcon: Icon(Icons.search)),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Text(
//                       'Total Unit : ${state.units.length.toString()}',
//                       style: getGreyTextStyle(grey8391A1),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     FutureBuilder(
//                         future: getActualIdSite(),
//                         builder: (context, snapshot) {
//                           if (snapshot.connectionState ==
//                               ConnectionState.waiting) {
//                             return Container();
//                           }

//                           final data = snapshot.data;
//                           log('id site future builder : $data');

//                           final isSis =
//                               homeState.userAccessCompanyId.value == '1';

//                           if (data != '1' ||
//                               isSis && data != '2' && data != '3') {
//                             return FutureBuilder(
//                                 future: getActualIdSite(),
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return Container();
//                                   }

//                                   final data = snapshot.data;
//                                   log('id site future builder : $data');

//                                   if (data != '1' ||
//                                       isSis && data != '2' && data != '3') {
//                                     return SizedBox(
//                                       width: double.infinity,
//                                       child: ElevatedButton(
//                                         onPressed: () {
//                                           setState(() {
//                                             isOnline =
//                                                 !isOnline; // Toggle the status
//                                             callUnits();
//                                           });
//                                         },
//                                         style: ElevatedButton.styleFrom(
//                                           primary: Colors.green,
//                                         ),
//                                         child: Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             Icon(
//                                               Icons.fire_truck,
//                                               color: white,
//                                             ),
//                                             const SizedBox(
//                                               width: 12,
//                                             ),
//                                             Text(
//                                               'Update Unit',
//                                               style: getWhiteTextStyle(),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                   return Container();
//                                 });
//                           }
//                           return Container();
//                         }),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     (state.units == null || state.units.isEmpty)
//                         ? Text(
//                             'No Data, please press Get Unit to get data!',
//                             textAlign: TextAlign.center,
//                             style: getBlackTextStyle(fontSize: 18),
//                           )
//                         : Column(
//                             children: state.units.map((unit) {
//                               if (searchQuery.isNotEmpty &&
//                                   !unit.unitNumber!
//                                       .toLowerCase()
//                                       .contains(searchQuery) &&
//                                   !unit.model!
//                                       .toLowerCase()
//                                       .contains(searchQuery)) {
//                                 return Container();
//                               }
//                               return InkWell(
//                                 onTap: () {
//                                   switch (inspectionType) {
//                                     case 'daily_check':
//                                       Navigator.pushNamed(
//                                           context, DailyCheckFormPage.routeName,
//                                           arguments: {
//                                             'unitNumber': unit.unitNumber,
//                                           });
//                                       break;
//                                     case 'tire_inspection':
//                                       Navigator.pushNamed(context,
//                                           TireInspectionFormPage.routeName,
//                                           arguments: {
//                                             'unitNumber': unit.unitNumber,
//                                             'hm': unit.hm,
//                                           });
//                                       break;
//                                   }
//                                 },
//                                 child: Container(
//                                   margin: EdgeInsets.symmetric(vertical: 8.0),
//                                   padding: EdgeInsets.symmetric(vertical: 6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(12),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.black.withOpacity(0.1),
//                                         spreadRadius: 2,
//                                         blurRadius: 5,
//                                         offset: Offset(0, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: ListTile(
//                                     leading: Icon(
//                                       Icons.front_loader,
//                                       color: Colors.orange,
//                                     ),
//                                     title: Padding(
//                                       padding:
//                                           const EdgeInsets.only(bottom: 4.0),
//                                       child: Text(
//                                         '${unit.unitNumber}',
//                                         style: getBlackTextStyle(
//                                             fontWeight: FontWeight.w700),
//                                       ),
//                                     ),
//                                     subtitle: Text(
//                                       '${unit.model}',
//                                       style: getGreyTextStyle(grey6A707C),
//                                     ),
//                                     trailing: Icon(Icons.arrow_forward_ios),
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                   ],
//                 );
//               }

//               return Container();
//             },
//           ),
//         ),
//       )),
//     );
//   }
// }

// import 'dart:developer';

// import 'package:camos/core/utils/data/id_site.dart';
// import 'package:camos/main.dart';
// import 'package:camos/objectbox.g.dart';
// import 'package:camos/pages/home/home_state.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/upload_queue_service.dart';
// import 'package:get/get.dart';

// import '../../core/blocs/unit/unit_bloc.dart';
// import '../../core/services/shared_preferences/shared_preferences.dart';
// import '../../core/styles/color.dart';
// import '../../core/styles/text_manager.dart';
// import '../../core/widgets/appbar_widget.dart';
// import 'daily_check_form_page.dart';
// import 'daily_pressure_list.dart';
// import 'tire_inspection_form_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// class SelectUnitPage extends StatefulWidget {
//   static const routeName = '/select-unit-page';
//   SelectUnitPage({super.key});

//   @override
//   State<SelectUnitPage> createState() => _SelectUnitPageState();
// }

// class _SelectUnitPageState extends State<SelectUnitPage> with RouteAware {
//   String searchQuery = '';
//   bool isOnline = false;
//   final HomeState homeState = Get.find<HomeState>();

//   @override
//   void initState() {
//     super.initState();
//     callUnits();
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // subscribe ke routeObserver global
//     final modal = ModalRoute.of(context);
//     if (modal != null) {
//       routeObserver.subscribe(this, modal);
//     }
//   }

//   @override
//   void dispose() {
//     // unsubscribe sebelum dispose
//     routeObserver.unsubscribe(this);
//     super.dispose();
//   }

//   // Dipanggil ketika suatu route DIPUSH di atas route ini (halaman ini 'ditinggalkan')
//   @override
//   void didPushNext() {
//     super.didPushNext();
//     // halaman ditumpuk oleh route lain -> panggil retryPending()
//     _triggerRetryPending();
//   }

//   // (opsional) kalau ingin saat kembali ke page
//   @override
//   void didPopNext() {
//     super.didPopNext();
//     // route di atas di-pop, kita kembali visible
//     // bisa panggil retryPending di sini juga jika mau
//   }

//   Future<void> _triggerRetryPending() async {
//     try {
//       // cek dulu koneksi optional atau langsung panggil
//       // await InternetConnectionChecker().hasConnection
//       // jika kamu tidak mau cek, langsung panggil:
//       await UploadQueueService.to.retryPending();
//       // atau kalau tidak pake singleton, panggil instance mu
//       log('triggerRetryPending from SelectUnitPage.didPushNext');
//     } catch (e, st) {
//       log('retryPending error: $e\n$st');
//     }
//   }

//   Future<void> callUnits() async {
//     String currentSiteId = homeState.currentSiteId;
//     String userAccessId = homeState.userAccessId.value;

//     bool isSis = homeState.userAccessCompanyId.value == '1';

//     log('test call units 1 : $currentSiteId');
//     log('test call units 2 : $userAccessId');
//     context.read<UnitBloc>().add(GetUnitsEvent(
//         idSite: currentSiteId,
//         isOnline:
//             // (userAccessId == '1' || userAccessId == '2') ? true : isOnline));
//             (userAccessId == '1' && !isSis) ? true : isOnline));
//   }

//   Future<String> getActualIdSite() async {
//     final actIdSite = await getIdSitePreferences();

//     return actIdSite;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final inspectionType = ModalRoute.of(context)?.settings.arguments as String;

//     return Scaffold(
//       appBar: (inspectionType == 'daily_check')
//           ? AppBar(
//               centerTitle: true,
//               title: Text(
//                 'Daily Check Pressure',
//                 style: getBlackTextStyle(),
//               ),
//               actions: [
//                 InkWell(
//                   onTap: () {
//                     Navigator.pushNamed(
//                         context, DailyPressureListPage.routeName);
//                   },
//                   child: Padding(
//                     padding: const EdgeInsets.only(
//                       right: 8.0,
//                       top: 8.0,
//                     ),
//                     child: Icon(
//                       Icons.list,
//                       size: 32,
//                     ),
//                   ),
//                 )
//               ],
//             )
//           : appBarWidget('Select Unit First', context),
//       body: SafeArea(
//           child: SingleChildScrollView(
//         child: Container(
//           margin: EdgeInsets.only(top: 12),
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: BlocConsumer<UnitBloc, UnitState>(
//             listener: (context, state) {
//               if (state is UnitErrorState) {
//                 setState(() {
//                   isOnline = !isOnline;
//                 });
//                 showDialog(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return AlertDialog(
//                         title: Text(
//                           'Please check your internet connection!',
//                           style: getBlackTextStyle(),
//                         ),
//                         actions: [
//                           TextButton(
//                               onPressed: () {
//                                 Navigator.pop(context);
//                                 Navigator.pop(context);
//                               },
//                               child: Text('Okay'))
//                         ],
//                       );
//                     });
//               }
//             },
//             builder: (context, state) {
//               if (state is UnitLoadingState) {
//                 return Center(child: CircularProgressIndicator());
//               }

//               if (state is UnitLoadedState) {
//                 log('kondisi state : ${state.units.length}');

//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     TextField(
//                       onChanged: (value) {
//                         setState(() {
//                           searchQuery = value;
//                         });
//                       },
//                       decoration: InputDecoration(
//                           hintText: 'Search... (Unit Number or Model)',
//                           hintStyle: getGreyTextStyle(grey8391A1),
//                           prefixIcon: Icon(Icons.search)),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     Text(
//                       'Total Unit : ${state.units.length.toString()}',
//                       style: getGreyTextStyle(grey8391A1),
//                     ),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     FutureBuilder(
//                         future: getActualIdSite(),
//                         builder: (context, snapshot) {
//                           if (snapshot.connectionState ==
//                               ConnectionState.waiting) {
//                             return Container();
//                           }

//                           final data = snapshot.data;
//                           log('id site future builder : $data');

//                           final isSis =
//                               homeState.userAccessCompanyId.value == '1';

//                           if (data != '1' ||
//                               isSis && data != '2' && data != '3') {
//                             return FutureBuilder(
//                                 future: getActualIdSite(),
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return Container();
//                                   }

//                                   final data = snapshot.data;
//                                   log('id site future builder : $data');

//                                   if (data != '1' ||
//                                       isSis && data != '2' && data != '3') {
//                                     return SizedBox(
//                                       width: double.infinity,
//                                       child: ElevatedButton(
//                                         onPressed: () {
//                                           setState(() {
//                                             isOnline =
//                                                 !isOnline; // Toggle the status
//                                             callUnits();
//                                           });
//                                         },
//                                         style: ElevatedButton.styleFrom(
//                                           primary: Colors.green,
//                                         ),
//                                         child: Row(
//                                           mainAxisAlignment:
//                                               MainAxisAlignment.center,
//                                           children: [
//                                             Icon(
//                                               Icons.fire_truck,
//                                               color: white,
//                                             ),
//                                             const SizedBox(
//                                               width: 12,
//                                             ),
//                                             Text(
//                                               'Update Unit',
//                                               style: getWhiteTextStyle(),
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   }
//                                   return Container();
//                                 });
//                           }
//                           return Container();
//                         }),
//                     const SizedBox(
//                       height: 12,
//                     ),
//                     (state.units == null || state.units.isEmpty)
//                         ? Text(
//                             'No Data, please press Get Unit to get data!',
//                             textAlign: TextAlign.center,
//                             style: getBlackTextStyle(fontSize: 18),
//                           )
//                         : Column(
//                             children: state.units.map((unit) {
//                               if (searchQuery.isNotEmpty &&
//                                   !unit.unitNumber!
//                                       .toLowerCase()
//                                       .contains(searchQuery) &&
//                                   !unit.model!
//                                       .toLowerCase()
//                                       .contains(searchQuery)) {
//                                 return Container();
//                               }
//                               return InkWell(
//                                 onTap: () {
//                                   switch (inspectionType) {
//                                     case 'daily_check':
//                                       Navigator.pushNamed(
//                                           context, DailyCheckFormPage.routeName,
//                                           arguments: {
//                                             'unitNumber': unit.unitNumber,
//                                           });
//                                       break;
//                                     case 'tire_inspection':
//                                       Navigator.pushNamed(context,
//                                           TireInspectionFormPage.routeName,
//                                           arguments: {
//                                             'unitNumber': unit.unitNumber,
//                                             'hm': unit.hm,
//                                           });
//                                       break;
//                                   }
//                                 },
//                                 child: Container(
//                                   margin: EdgeInsets.symmetric(vertical: 8.0),
//                                   padding: EdgeInsets.symmetric(vertical: 6),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius: BorderRadius.circular(12),
//                                     boxShadow: [
//                                       BoxShadow(
//                                         color: Colors.black.withOpacity(0.1),
//                                         spreadRadius: 2,
//                                         blurRadius: 5,
//                                         offset: Offset(0, 2),
//                                       ),
//                                     ],
//                                   ),
//                                   child: ListTile(
//                                     leading: Icon(
//                                       Icons.front_loader,
//                                       color: Colors.orange,
//                                     ),
//                                     title: Padding(
//                                       padding:
//                                           const EdgeInsets.only(bottom: 4.0),
//                                       child: Text(
//                                         '${unit.unitNumber}',
//                                         style: getBlackTextStyle(
//                                             fontWeight: FontWeight.w700),
//                                       ),
//                                     ),
//                                     subtitle: Text(
//                                       '${unit.model}',
//                                       style: getGreyTextStyle(grey6A707C),
//                                     ),
//                                     trailing: Icon(Icons.arrow_forward_ios),
//                                   ),
//                                 ),
//                               );
//                             }).toList(),
//                           ),
//                   ],
//                 );
//               }

//               return Container();
//             },
//           ),
//         ),
//       )),
//     );
//   }
// }

import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/select_pit_button.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/upload_queue_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import '../../core/blocs/unit/unit_bloc.dart';
import '../../core/services/model/unit_tire.dart';
import '../../core/services/shared_preferences/shared_preferences.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import 'daily_check_form_page.dart';
import 'daily_pressure_list.dart';
import 'tire_inspection_form_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectUnitPage extends StatefulWidget {
  static const routeName = '/select-unit-page';

  const SelectUnitPage({super.key});

  @override
  State<SelectUnitPage> createState() => _SelectUnitPageState();
}

class _SelectUnitPageState extends State<SelectUnitPage> with RouteAware {
  String selectedTargetArea = 'All';
  final Set<String> selectedTargetAreaKeys = <String>{};
  final HomeState homeState = Get.find<HomeState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  String searchQuery = '';
  bool isOnline = false;

  /// Key:
  /// Nomor unit yang sudah dinormalisasi.
  ///
  /// Value:
  /// Tanggal Tire Inspection unit tersebut.
  Map<String, DateTime> checkedUnitDates = <String, DateTime>{};

  /// Loading khusus pengambilan status Checked.
  bool isLoadingCheckedUnits = false;

  /// Menjaga agar hasil request site lama tidak menimpa site yang baru.
  int checkedUnitsRequestId = 0;

  /// Listener perubahan site.
  Worker? siteWorker;

  /// Menjaga agar pemuatan awal hanya dijalankan sekali setelah argument
  /// route tersedia.
  bool hasInitializedPage = false;

  String activeInspectionType = '';
  int initialUnitLoadRequestId = 0;

  @override
  void initState() {
    super.initState();

    /// Muat ulang data ketika site aktif berubah.
    siteWorker = ever<String>(
      homeState.currentSiteIdRx,
      (String siteId) {
        if (siteId.trim().isEmpty || !hasInitializedPage) {
          return;
        }

        if (mounted) {
          setState(() {
            selectedTargetArea = 'All';
            selectedTargetAreaKeys.clear();
          });
        }

        unawaited(_loadUnitsForCurrentSite());
      },
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final modalRoute = ModalRoute.of(context);

    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);

      if (!hasInitializedPage) {
        hasInitializedPage = true;

        activeInspectionType = modalRoute.settings.arguments as String? ?? '';
        unawaited(_loadUnitsForCurrentSite());
      }
    }
  }

  Future<void> _loadUnitsForCurrentSite() async {
    final requestId = ++initialUnitLoadRequestId;
    final siteId = homeState.currentSiteId.trim();
    final shouldUseApi = await getUnitBefore7AM(
      activeInspectionType,
      siteId,
    );

    if (!mounted ||
        requestId != initialUnitLoadRequestId ||
        siteId != homeState.currentSiteId.trim()) {
      return;
    }

    isOnline = shouldUseApi;
    await callUnits();
    await fetchCheckedUnits();
  }

  /// Tire Inspection memakai API sebelum pukul 07.00 atau ketika ini adalah
  /// pembukaan pertama pada tanggal lokal hari ini.
  Future<bool> getUnitBefore7AM(
    String inspectionType,
    String siteId,
  ) async {
    if (inspectionType != 'tire_inspection') return false;

    final now = DateTime.now();
    final firstApiLoadToday = await shouldLoadUnitListFromApiToday(
      listType: tireInspectionUnitList,
      idSite: siteId,
    );
    final shouldUseApi = now.hour < 7 || firstApiLoadToday;

    log(
      'Tire Inspection initial unit source: '
      '${shouldUseApi ? 'API' : 'cache'} '
      '(before7=${now.hour < 7}, firstToday=$firstApiLoadToday)',
    );

    return shouldUseApi;
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    siteWorker?.dispose();
    super.dispose();
  }

  /// Dipanggil ketika halaman lain dibuka di atas halaman ini.
  @override
  void didPushNext() {
    super.didPushNext();
    _triggerRetryPending();
  }

  /// Dipanggil ketika kembali dari halaman Tire Inspection.
  ///
  /// Data Checked diambil ulang agar unit yang baru selesai
  /// diperiksa langsung berubah menjadi Checked dan pindah ke atas.
  @override
  void didPopNext() {
    super.didPopNext();
    fetchCheckedUnits();
  }

  Future<void> _triggerRetryPending() async {
    try {
      await UploadQueueService.to.retryPending();

      log(
        'triggerRetryPending from SelectUnitPage.didPushNext',
      );
    } catch (e, st) {
      log('retryPending error: $e\n$st');
    }
  }

  Future<void> callUnits() async {
    final String currentSiteId = homeState.currentSiteId;
    final String userAccessId = homeState.userAccessId.value;

    final bool isSis = homeState.userAccessCompanyId.value == '1';

    log('test call units 1 : $currentSiteId');
    log('test call units 2 : $userAccessId');

    context.read<UnitBloc>().add(
          GetUnitsEvent(
            idSite: currentSiteId,
            isOnline: (userAccessId == '1' && !isSis) ? true : isOnline,
            requestSource: activeInspectionType,
          ),
        );
  }

  /// Mengambil unit yang sudah diperiksa dari koleksi:
  ///
  /// tire_inspection
  ///
  /// Unit dianggap Checked jika:
  /// 1. id_site sama dengan site aktif.
  /// 2. Tanggal inspeksi sama dengan hari ini.
  Future<void> fetchCheckedUnits() async {
    final int requestId = ++checkedUnitsRequestId;
    final String currentSiteId = homeState.currentSiteId.trim();

    if (currentSiteId.isEmpty) {
      if (!mounted) return;

      setState(() {
        checkedUnitDates.clear();
        isLoadingCheckedUnits = false;
      });

      return;
    }

    if (mounted) {
      setState(() {
        isLoadingCheckedUnits = true;
      });
    }

    try {
      log('===================================');
      log('FETCH CHECKED TIRE INSPECTION');
      log('Current site ID: $currentSiteId');

      final DateTime now = DateTime.now();
      final String today = DateFormat('yyyy-MM-dd').format(now);
      final Map<String, DateTime> result = <String, DateTime>{};

      // Status Checked hanya membutuhkan data hari ini. Memindai seluruh
      // riwayat per halaman tetap membuat CPU dan GC bekerja terus-menerus.
      final querySnapshot = await firestore
          .collection('tire_inspection')
          .where(
            'id_site',
            isEqualTo: currentSiteId,
          )
          .where(
            'hari',
            isEqualTo: today,
          )
          .get();

      if (requestId != checkedUnitsRequestId ||
          currentSiteId != homeState.currentSiteId.trim()) {
        return;
      }

      for (final document in querySnapshot.docs) {
        final Map<String, dynamic> data = document.data();

        final String unitNumber = normalizeUnitNumber(
          data['unit']?.toString(),
        );

        if (unitNumber.isEmpty) {
          continue;
        }

        final dynamic dateValue = data['hari'] ?? data['tanggal'];
        final DateTime? inspectionDate = parseInspectionDate(dateValue);

        if (inspectionDate == null || !isSameDate(inspectionDate, now)) {
          continue;
        }

        final DateTime? previousDate = result[unitNumber];

        /// Jika terdapat lebih dari satu dokumen pada unit
        /// yang sama, gunakan tanggal/waktu terbaru.
        if (previousDate == null || inspectionDate.isAfter(previousDate)) {
          result[unitNumber] = inspectionDate;
        }
      }

      log('Total checked today: ${result.length}');
      log('Checked unit list: ${result.keys.toList()}');

      if (!mounted) return;

      setState(() {
        checkedUnitDates = result;
      });
    } catch (e, st) {
      log('Error fetching checked units: $e');
      log('$st');
    } finally {
      if (mounted && requestId == checkedUnitsRequestId) {
        setState(() {
          isLoadingCheckedUnits = false;
        });
      }
    }
  }

  /// Normalisasi nomor unit agar pencocokan lebih aman.
  ///
  /// Contoh:
  /// " dt090-0666 " menjadi "DT090-0666".
  String normalizeUnitNumber(String? unitNumber) {
    return (unitNumber ?? '').trim().toUpperCase();
  }

  /// Mendukung tipe tanggal:
  /// - Firestore Timestamp
  /// - DateTime
  /// - ISO String
  /// - yyyy-MM-dd
  /// - dd-MM-yyyy
  /// - dd/MM/yyyy
  DateTime? parseInspectionDate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is Timestamp) {
      return value.toDate();
    }

    if (value is DateTime) {
      return value;
    }

    final String text = value.toString().trim();

    if (text.isEmpty) {
      return null;
    }

    /// Mencoba format ISO.
    ///
    /// Contoh:
    /// 2026-07-21
    /// 2026-07-21T10:30:00.000
    final DateTime? isoDate = DateTime.tryParse(text);

    if (isoDate != null) {
      return isoDate;
    }

    /// Mendukung:
    /// dd-MM-yyyy
    /// dd/MM/yyyy
    /// yyyy-MM-dd
    /// yyyy/MM/dd
    final List<String> dateParts = text.split(RegExp(r'[-/]'));

    if (dateParts.length != 3) {
      return null;
    }

    final int? first = int.tryParse(dateParts[0]);

    final int? second = int.tryParse(dateParts[1]);

    final int? third = int.tryParse(dateParts[2]);

    if (first == null || second == null || third == null) {
      return null;
    }

    try {
      /// Format yyyy-MM-dd atau yyyy/MM/dd.
      if (dateParts[0].length == 4) {
        return DateTime(
          first,
          second,
          third,
        );
      }

      /// Format dd-MM-yyyy atau dd/MM/yyyy.
      return DateTime(
        third,
        second,
        first,
      );
    } catch (_) {
      return null;
    }
  }

  bool isSameDate(
    DateTime firstDate,
    DateTime secondDate,
  ) {
    return firstDate.year == secondDate.year &&
        firstDate.month == secondDate.month &&
        firstDate.day == secondDate.day;
  }

  bool isUnitChecked(String? unitNumber) {
    final String normalized = normalizeUnitNumber(unitNumber);

    return checkedUnitDates.containsKey(normalized);
  }

  DateTime? getUnitCheckedDate(
    String? unitNumber,
  ) {
    final String normalized = normalizeUnitNumber(unitNumber);

    return checkedUnitDates[normalized];
  }

  String formatCheckedDate(DateTime? date) {
    if (date == null) {
      return '-';
    }

    final String day = date.day.toString().padLeft(2, '0');

    final String month = date.month.toString().padLeft(2, '0');

    final String year = date.year.toString();

    return '$day-$month-$year';
  }

  Future<String> getActualIdSite() async {
    final actIdSite = await getIdSitePreferences();

    return actIdSite;
  }

  Future<void> exportUnitsToTxt({
    required List<UnitTire> units,
    required String inspectionType,
    required String selectedArea,
    required String exportType,
  }) async {
    if (units.isEmpty) {
      String emptyMessage = 'Tidak ada data unit untuk diexport.';

      if (exportType == 'checked') {
        emptyMessage = 'Tidak ada unit Checked untuk diexport.';
      } else if (exportType == 'not_checked') {
        emptyMessage = 'Tidak ada unit Not Checked untuk diexport.';
      }

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            emptyMessage,
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
      return;
    }

    try {
      final Directory? downloadDirectory =
          await DownloadsPath.downloadsDirectory();

      if (downloadDirectory == null) {
        throw Exception('Folder Download tidak ditemukan');
      }

      final DateTime exportTime = DateTime.now();
      final String formattedDate =
          DateFormat('dd-MM-yyyy HH:mm:ss').format(exportTime);
      final String fileDate = DateFormat('yyyyMMdd_HHmmss').format(exportTime);

      String pageTitle;
      String filePrefix;

      switch (exportType) {
        case 'checked':
          pageTitle = 'LIST UNIT TIRE INSPECTION - CHECKED';
          filePrefix = 'tire_inspection_checked';
          break;

        case 'not_checked':
          pageTitle = 'LIST UNIT TIRE INSPECTION - NOT CHECKED';
          filePrefix = 'tire_inspection_not_checked';
          break;

        default:
          pageTitle = inspectionType == 'tire_inspection'
              ? 'LIST UNIT TIRE INSPECTION'
              : 'LIST UNIT DAILY CHECK PRESSURE';

          filePrefix = inspectionType == 'tire_inspection'
              ? 'tire_inspection_units'
              : 'daily_check_units';
          break;
      }

      final selectedAreaLabels = selectedArea
          .split(',')
          .map((area) => area.trim())
          .where((area) => area.isNotEmpty)
          .toList();
      final String safeArea = selectedAreaLabels.length > 1
          ? 'multi_area_${selectedAreaLabels.length}'
          : (selectedAreaLabels.isEmpty ? 'All' : selectedAreaLabels.first)
              .replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');

      final StringBuffer txt = StringBuffer();

      txt.writeln(pageTitle);
      txt.writeln('========================================');
      txt.writeln('Site       : ${homeState.currentSiteId}');
      txt.writeln('Area / PIT : $selectedArea');
      txt.writeln('Tanggal    : $formattedDate');
      txt.writeln('Total Unit : ${units.length}');
      txt.writeln('========================================');
      txt.writeln();

      for (int index = 0; index < units.length; index++) {
        final UnitTire unit = units[index];

        final String unitNumber = (unit.unitNumber ?? '').trim().isEmpty
            ? '-'
            : (unit.unitNumber ?? '').trim();

        final String model =
            (unit.model ?? '').trim().isEmpty ? '-' : (unit.model ?? '').trim();

        final String area =
            (unit.area ?? '').trim().isEmpty ? '-' : (unit.area ?? '').trim();

        final String hm =
            (unit.hm ?? '').trim().isEmpty ? '-' : (unit.hm ?? '').trim();

        txt.writeln('${index + 1}. $unitNumber');
        txt.writeln('   Model  : $model');
        txt.writeln('   Area   : $area');
        txt.writeln('   HM     : $hm');

        if (inspectionType == 'tire_inspection') {
          final bool checked = isUnitChecked(unit.unitNumber);
          final DateTime? checkedDate = getUnitCheckedDate(unit.unitNumber);

          txt.writeln(
            '   Status : ${checked ? 'Checked' : 'Not Checked'}',
          );

          if (checkedDate != null) {
            txt.writeln(
              '   Checked Date : '
              '${DateFormat('dd-MM-yyyy HH:mm:ss').format(checkedDate)}',
            );
          }
        }

        txt.writeln('----------------------------------------');
      }

      final String fileName =
          '${filePrefix}_${homeState.currentSiteId}_${safeArea}_$fileDate.txt';

      final File file = File(
        '${downloadDirectory.path}/$fileName',
      );

      await file.writeAsString(
        txt.toString(),
        flush: true,
      );

      log('File export berhasil disimpan: ${file.path}');

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          content: Text(
            'Berhasil export ${units.length} unit\n'
            'Download/$fileName',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e, st) {
      log('Gagal export TXT: $e');
      log('$st');

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Gagal export data: $e',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    }
  }

  String formatInspectionPercentage({
    required int current,
    required int target,
  }) {
    if (target <= 0) {
      return '0%';
    }

    final double percentage = (current / target) * 100;

    if (percentage == percentage.roundToDouble()) {
      return '${percentage.toStringAsFixed(0)}%';
    }

    return '${percentage.toStringAsFixed(1)}%';
  }

  Widget buildTargetAreaSummary({
    required Map<String, int> targetArea,
    required List<UnitTire> units,
  }) {
    final List<MapEntry<String, int>> entries = targetArea.entries
        .where(
          (entry) => entry.key.trim().isNotEmpty,
        )
        .toList()
      ..sort(
        (a, b) => a.key.toLowerCase().compareTo(
              b.key.toLowerCase(),
            ),
      );

    if (entries.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFD9DDE3),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Target area belum tersedia.',
                style: getGreyTextStyle(
                  grey8391A1,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final Map<String, Set<String>> checkedUnitByArea = <String, Set<String>>{};

    for (final UnitTire unit in units) {
      final String unitNumber = normalizeUnitNumber(
        unit.unitNumber,
      );

      if (unitNumber.isEmpty || !isUnitChecked(unitNumber)) {
        continue;
      }

      final String area = (unit.area ?? '').trim();

      if (area.isEmpty) {
        continue;
      }

      final String areaKey = area.toLowerCase();

      checkedUnitByArea.putIfAbsent(
        areaKey,
        () => <String>{},
      );

      checkedUnitByArea[areaKey]!.add(unitNumber);
    }

    final int totalTarget = entries.fold<int>(
      0,
      (total, entry) => total + entry.value,
    );

    final int totalCurrent = entries.fold<int>(
      0,
      (total, entry) {
        final String areaKey = entry.key.trim().toLowerCase();

        return total + (checkedUnitByArea[areaKey]?.length ?? 0);
      },
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB8D5FF),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.track_changes,
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Target Area',
                  style: getBlackTextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$totalCurrent / $totalTarget',
                  style: getWhiteTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Area',
                  style: getGreyTextStyle(
                    grey8391A1,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Target',
                  textAlign: TextAlign.center,
                  style: getGreyTextStyle(
                    grey8391A1,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Current',
                  textAlign: TextAlign.center,
                  style: getGreyTextStyle(
                    grey8391A1,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Progress',
                  textAlign: TextAlign.center,
                  style: getGreyTextStyle(
                    grey8391A1,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Divider(height: 1),
          const SizedBox(height: 6),
          ...entries.map(
            (entry) {
              final String areaKey = entry.key.trim().toLowerCase();

              final int target = entry.value;
              final int current = checkedUnitByArea[areaKey]?.length ?? 0;

              final bool targetReached = target > 0 && current >= target;

              return Container(
                margin: const EdgeInsets.only(
                  bottom: 8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: targetReached
                        ? const Color(0xFFB8E5C6)
                        : const Color(0xFFD9DDE3),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Icon(
                            targetReached
                                ? Icons.check_circle
                                : Icons.location_on_outlined,
                            size: 18,
                            color: targetReached
                                ? const Color(0xFF00A849)
                                : Colors.blueGrey,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: getBlackTextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$target',
                        textAlign: TextAlign.center,
                        style: getBlackTextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '$current',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: targetReached
                              ? const Color(0xFF00A849)
                              : Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        formatInspectionPercentage(
                          current: current,
                          target: target,
                        ),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: targetReached
                              ? const Color(0xFF00A849)
                              : Colors.blue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  'Total',
                  style: getBlackTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$totalTarget',
                  textAlign: TextAlign.center,
                  style: getBlackTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '$totalCurrent',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatInspectionPercentage(
                    current: totalCurrent,
                    target: totalTarget,
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildCheckedBadge(
    DateTime? checkedDate,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F8EE),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFB8E5C6),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle,
            color: Color(0xFF00B14F),
            size: 18,
          ),
          const SizedBox(width: 6),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Checked',
                style: TextStyle(
                  color: Color(0xFF00A849),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                formatCheckedDate(checkedDate),
                style: const TextStyle(
                  color: Color(0xFF559B6E),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String inspectionType =
        ModalRoute.of(context)?.settings.arguments as String;

    return Scaffold(
      appBar: inspectionType == 'daily_check'
          ? AppBar(
              centerTitle: true,
              title: Text(
                'Daily Check Pressure',
                style: getBlackTextStyle(),
              ),
              actions: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      DailyPressureListPage.routeName,
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.only(
                      right: 8,
                      top: 8,
                    ),
                    child: Icon(
                      Icons.list,
                      size: 32,
                    ),
                  ),
                ),
              ],
            )
          : appBarWidget(
              'Select Unit First',
              context,
            ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.only(
              top: 12,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: BlocConsumer<UnitBloc, UnitState>(
              listener: (context, state) {
                if (state is UnitLoadedState &&
                    state.loadedFromApi &&
                    state.requestSource == tireInspectionUnitList &&
                    activeInspectionType == 'tire_inspection') {
                  unawaited(
                    saveUnitListApiLoadedToday(
                      listType: tireInspectionUnitList,
                      idSite: state.idSite,
                    ),
                  );
                }

                if (state is UnitErrorState) {
                  setState(() {
                    isOnline = !isOnline;
                  });

                  showDialog(
                    context: context,
                    builder: (
                      BuildContext context,
                    ) {
                      return AlertDialog(
                        title: Text(
                          'Please check your internet connection!',
                          style: getBlackTextStyle(),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            child: const Text('Okay'),
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              builder: (context, state) {
                if (state is UnitLoadingState) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (state is UnitLoadedState) {
                  log(
                    'kondisi state : '
                    '${state.units.length}',
                  );

                  // Ambil nama area dari targetArea.
// Contoh:
// {
//   'Central': 6,
//   'North West': 6,
// }
                  final Map<String, String> targetAreaLabelsByKey =
                      <String, String>{};
                  for (final rawArea in state.targetArea.keys) {
                    final area = rawArea.trim();
                    if (area.isEmpty) continue;

                    targetAreaLabelsByKey.putIfAbsent(
                      area.toLowerCase(),
                      () => area,
                    );
                  }

                  final List<String> targetAreaNames =
                      targetAreaLabelsByKey.values.toList()
                        ..sort(
                          (a, b) => a.toLowerCase().compareTo(
                                b.toLowerCase(),
                              ),
                        );
                  print('target area names: $targetAreaNames');

// Tambahkan pilihan All di urutan pertama.
                  final List<String> targetAreaOptions = [
                    'All',
                    ...targetAreaNames,
                  ];

// Pastikan pilihan lama masih tersedia ketika data/site berubah.
                  final bool selectedAreaExists = targetAreaOptions.any(
                    (area) =>
                        area.toLowerCase() == selectedTargetArea.toLowerCase(),
                  );

                  final String activeTargetArea =
                      selectedAreaExists ? selectedTargetArea : 'All';

                  final int selectedTargetAreaIndex =
                      targetAreaOptions.indexWhere(
                    (area) =>
                        area.toLowerCase() == activeTargetArea.toLowerCase(),
                  );

                  // Multi-area hanya berlaku untuk Tire Inspection. Pilihan
                  // yang sudah tidak tersedia setelah refresh/site berubah
                  // diabaikan; set kosong berarti menampilkan semua area.
                  final Set<String> activeTargetAreaKeys =
                      selectedTargetAreaKeys
                          .where(targetAreaLabelsByKey.containsKey)
                          .toSet();
                  final List<String> activeTargetAreaLabels = targetAreaNames
                      .where(
                        (area) => activeTargetAreaKeys.contains(
                          area.toLowerCase(),
                        ),
                      )
                      .toList();
                  final bool isAllTargetAreas = activeTargetAreaKeys.isEmpty;
                  final Set<int> selectedTargetAreaIndexes = <int>{
                    for (int index = 1;
                        index < targetAreaOptions.length;
                        index++)
                      if (activeTargetAreaKeys.contains(
                        targetAreaOptions[index].toLowerCase(),
                      ))
                        index,
                  };
                  if (selectedTargetAreaIndexes.isEmpty) {
                    selectedTargetAreaIndexes.add(0);
                  }

                  final String activeTargetAreaLabel =
                      inspectionType == 'tire_inspection'
                          ? (isAllTargetAreas
                              ? 'All'
                              : activeTargetAreaLabels.join(', '))
                          : activeTargetArea;

                  final String query = searchQuery.trim().toLowerCase();

// Filter pertama berdasarkan target area/PIT.
                  final areaFilteredUnits = state.units.where((unit) {
                    final String unitArea =
                        (unit.area ?? '').trim().toLowerCase();

                    if (inspectionType == 'tire_inspection') {
                      return isAllTargetAreas ||
                          activeTargetAreaKeys.contains(unitArea);
                    }

                    return activeTargetArea == 'All' ||
                        unitArea == activeTargetArea.trim().toLowerCase();
                  }).toList();

// Filter kedua berdasarkan pencarian.
                  final filteredUnits = areaFilteredUnits.where((unit) {
                    final String unitNumber =
                        (unit.unitNumber ?? '').trim().toLowerCase();

                    final String model =
                        (unit.model ?? '').trim().toLowerCase();

                    if (query.isEmpty) {
                      return true;
                    }

                    return unitNumber.contains(query) || model.contains(query);
                  }).toList();

                  /// Filter berdasarkan nomor unit
                  /// atau model unit.
                  // final filteredUnits = state.units.where((unit) {
                  //   final String unitNumber =
                  //       (unit.unitNumber ?? '').toString().toLowerCase();

                  //   final String model =
                  //       (unit.model ?? '').toString().toLowerCase();

                  //   if (query.isEmpty) {
                  //     return true;
                  //   }

                  //   return unitNumber.contains(query) || model.contains(query);
                  // }).toList();

                  /// Pisahkan unit Checked.
                  final checkedUnits = filteredUnits.where((unit) {
                    return isUnitChecked(
                      unit.unitNumber,
                    );
                  }).toList();

                  /// Urutkan Checked berdasarkan
                  /// tanggal terbaru.
                  checkedUnits.sort((a, b) {
                    final DateTime? dateA = getUnitCheckedDate(
                      a.unitNumber,
                    );

                    final DateTime? dateB = getUnitCheckedDate(
                      b.unitNumber,
                    );

                    if (dateA == null && dateB == null) {
                      return 0;
                    }

                    if (dateA == null) {
                      return 1;
                    }

                    if (dateB == null) {
                      return -1;
                    }

                    return dateB.compareTo(dateA);
                  });

                  /// Unit yang belum Checked.
                  final uncheckedUnits = filteredUnits.where((unit) {
                    return !isUnitChecked(
                      unit.unitNumber,
                    );
                  }).toList();

                  /// Pada Tire Inspection:
                  /// Checked berada paling atas.
                  ///
                  /// Pada Daily Check:
                  /// Urutan tidak diubah.
                  final displayedUnits = inspectionType == 'tire_inspection'
                      ? [
                          ...checkedUnits,
                          ...uncheckedUnits,
                        ]
                      : filteredUnits;

                  final String totalUnitLabel;
                  if (inspectionType == 'tire_inspection') {
                    if (isAllTargetAreas) {
                      totalUnitLabel = 'Total Unit : ${filteredUnits.length}';
                    } else if (activeTargetAreaLabels.length == 1) {
                      totalUnitLabel =
                          'Total Unit ${activeTargetAreaLabels.first} : '
                          '${filteredUnits.length}';
                    } else {
                      totalUnitLabel =
                          'Total Unit (${activeTargetAreaLabels.length} area) : '
                          '${filteredUnits.length}';
                    }
                  } else {
                    totalUnitLabel = activeTargetArea == 'All'
                        ? 'Total Unit : ${filteredUnits.length}'
                        : 'Total Unit $activeTargetArea : '
                            '${filteredUnits.length}';
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (targetAreaOptions.length > 1) ...[
                        Text(
                          'Select Area / PIT',
                          style: getBlackTextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (inspectionType == 'tire_inspection')
                          MultiSelectPitButton(
                            pit: targetAreaOptions,
                            selectedPits: selectedTargetAreaIndexes,
                            onSelectedPitsChanged: (indexes) {
                              final newAreaKeys = <String>{};
                              for (final index in indexes) {
                                if (index <= 0 ||
                                    index >= targetAreaOptions.length) {
                                  continue;
                                }
                                newAreaKeys.add(
                                  targetAreaOptions[index].toLowerCase(),
                                );
                              }

                              setState(() {
                                selectedTargetAreaKeys
                                  ..clear()
                                  ..addAll(newAreaKeys);
                              });
                            },
                          )
                        else
                          SelectPitButton(
                            pit: targetAreaOptions,
                            selectedPit: selectedTargetAreaIndex < 0
                                ? 0
                                : selectedTargetAreaIndex,
                            onSelectedPitChanged: (index) {
                              if (index < 0 ||
                                  index >= targetAreaOptions.length) {
                                return;
                              }

                              setState(() {
                                selectedTargetArea = targetAreaOptions[index];
                              });
                            },
                          ),
                        const SizedBox(height: 12),
                      ],
                      buildTargetAreaSummary(
                        targetArea: state.targetArea,
                        units: state.units,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search... (Unit Number or Model)',
                          hintStyle: getGreyTextStyle(
                            grey8391A1,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              totalUnitLabel,
                              style: getGreyTextStyle(
                                grey8391A1,
                              ),
                            ),
                          ),
                          if (inspectionType == 'tire_inspection' &&
                              isLoadingCheckedUnits) ...[
                            const SizedBox(width: 10),
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (inspectionType == 'tire_inspection') ...[
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: checkedUnits.isEmpty
                                    ? null
                                    : () {
                                        exportUnitsToTxt(
                                          units: List<UnitTire>.from(
                                            checkedUnits,
                                          ),
                                          inspectionType: inspectionType,
                                          selectedArea: activeTargetAreaLabel,
                                          exportType: 'checked',
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  disabledBackgroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'TXT Checked (${checkedUnits.length})',
                                  textAlign: TextAlign.center,
                                  style: getWhiteTextStyle(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: uncheckedUnits.isEmpty
                                    ? null
                                    : () {
                                        exportUnitsToTxt(
                                          units: List<UnitTire>.from(
                                            uncheckedUnits,
                                          ),
                                          inspectionType: inspectionType,
                                          selectedArea: activeTargetAreaLabel,
                                          exportType: 'not_checked',
                                        );
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  disabledBackgroundColor: Colors.grey,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                                icon: const Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  'TXT Not Checked (${uncheckedUnits.length})',
                                  textAlign: TextAlign.center,
                                  style: getWhiteTextStyle(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: filteredUnits.isEmpty
                                ? null
                                : () {
                                    exportUnitsToTxt(
                                      units: List<UnitTire>.from(
                                        filteredUnits,
                                      ),
                                      inspectionType: inspectionType,
                                      selectedArea: activeTargetAreaLabel,
                                      exportType: 'all',
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              disabledBackgroundColor: Colors.grey,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                            ),
                            icon: const Icon(
                              Icons.file_download_outlined,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Export TXT (${filteredUnits.length})',
                              style: getWhiteTextStyle(),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      FutureBuilder<String>(
                        future: getActualIdSite(),
                        builder: (
                          context,
                          snapshot,
                        ) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const SizedBox();
                          }

                          final String? data = snapshot.data;

                          log(
                            'id site future builder : '
                            '$data',
                          );

                          final bool isSis =
                              homeState.userAccessCompanyId.value == '1';

                          if (data != '1' ||
                              isSis && data != '2' && data != '3') {
                            return SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    isOnline = !isOnline;
                                  });

                                  callUnits();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.fire_truck,
                                      color: white,
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      'Update Unit',
                                      style: getWhiteTextStyle(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return const SizedBox();
                        },
                      ),
                      const SizedBox(height: 12),
                      state.units.isEmpty
                          ? Text(
                              'No Data, please press Get Unit to get data!',
                              textAlign: TextAlign.center,
                              style: getBlackTextStyle(
                                fontSize: 18,
                              ),
                            )
                          : Column(
                              children: displayedUnits.map(
                                (unit) {
                                  final bool checked =
                                      inspectionType == 'tire_inspection' &&
                                          isUnitChecked(
                                            unit.unitNumber,
                                          );

                                  final DateTime? checkedDate = checked
                                      ? getUnitCheckedDate(
                                          unit.unitNumber,
                                        )
                                      : null;
                                  final String unitArea =
                                      (unit.area ?? '').trim();
                                  final bool shouldShowUnitArea =
                                      inspectionType == 'tire_inspection' &&
                                          unitArea.isNotEmpty &&
                                          unitArea.toLowerCase() !=
                                              'noschedule';

                                  return InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      switch (inspectionType) {
                                        case 'daily_check':
                                          Navigator.pushNamed(
                                            context,
                                            DailyCheckFormPage.routeName,
                                            arguments: {
                                              'unitNumber': unit.unitNumber,

                                              // Area unit ikut dikirim sebagai PIT.
                                              if (unitArea.isNotEmpty)
                                                'pit': unitArea,
                                            },
                                          );
                                          break;

                                        case 'tire_inspection':
                                          Navigator.pushNamed(
                                            context,
                                            TireInspectionFormPage.routeName,
                                            arguments: {
                                              'unitNumber': unit.unitNumber,
                                              'hm': unit.hm,
                                              'idSite': homeState.currentSiteId,

                                              // Area unit ikut dikirim ke form.
                                              if (unitArea.isNotEmpty)
                                                'area': unitArea,
                                            },
                                          );
                                          break;
                                      }
                                    },
                                    // onTap: () {
                                    //   switch (inspectionType) {
                                    //     case 'daily_check':
                                    //       Navigator.pushNamed(
                                    //         context,
                                    //         DailyCheckFormPage.routeName,
                                    //         arguments: {
                                    //           'unitNumber': unit.unitNumber,
                                    //         },
                                    //       );
                                    //       break;

                                    //     case 'tire_inspection':
                                    //       Navigator.pushNamed(
                                    //         context,
                                    //         TireInspectionFormPage.routeName,
                                    //         arguments: {
                                    //           'unitNumber': unit.unitNumber,
                                    //           'hm': unit.hm,
                                    //         },
                                    //       );
                                    //       break;
                                    //   }
                                    // },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.1,
                                            ),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(
                                              0,
                                              2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.front_loader,
                                          color: Colors.orange,
                                        ),
                                        title: Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                          child: Text(
                                            '${unit.unitNumber}',
                                            style: getBlackTextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        subtitle: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${unit.model}',
                                              style: getGreyTextStyle(
                                                grey6A707C,
                                              ),
                                            ),
                                            if (shouldShowUnitArea) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.location_on_outlined,
                                                    size: 14,
                                                    color: Colors.orange,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Area: $unitArea',
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: getGreyTextStyle(
                                                        grey6A707C,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ],
                                        ),
                                        trailing: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (checked) ...[
                                              buildCheckedBadge(
                                                checkedDate,
                                              ),
                                              const SizedBox(
                                                width: 8,
                                              ),
                                            ],
                                            const Icon(
                                              Icons.arrow_forward_ios,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),
                    ],
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
  }
}
