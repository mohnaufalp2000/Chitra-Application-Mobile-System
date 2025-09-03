// import 'dart:developer';

// import 'package:camos/core/styles/color.dart';
// import 'package:camos/core/styles/text_manager.dart';
// import 'package:camos/core/utils/firebase_key/firebase_key.dart';
// import 'package:camos/core/widgets/appbar_widget.dart';
// import 'package:camos/pages/home/home_page.dart';
// import 'package:camos/pages/tire_repair_form/tire_repair_inspection/detail_tire_repair_inspection_page.dart';
// import 'package:camos/pages/tire_repair_form/tire_repair_inspection/tire_repair_inspection_form_page.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';

// class TireRepairInspectionPage extends StatefulWidget {
//   static const routeName = '/tire-repair-inspection';
//   const TireRepairInspectionPage({super.key});

//   @override
//   State<TireRepairInspectionPage> createState() =>
//       _TireRepairInspectionPageState();
// }

// class _TireRepairInspectionPageState extends State<TireRepairInspectionPage>
//     with TickerProviderStateMixin {
//   late AnimationController _controller;
//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   late Stream<QuerySnapshot> customerStream;
//   String searchQuery = '';
//   String? selectedCustomer;
//   String? selectedRepairLocation;
//   int selectedIndex = 1;
//   List<String> status = ['REPAIR', 'RETREAD', 'REJECT'];
//   List<String> statusTire = ['Inspected', 'Not Inspected'];
//   String selectedStatus = 'REPAIR';

//   final double containerWidthFactor = 0.8;
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     );
//     customerStream = firestore.collection('list_customer').snapshots();
//   }

//   int repairDurationMatrix(String repairDuration) {
//     switch (repairDuration) {
//       case 'R1':
//         return 5;
//       case 'R2':
//         return 9;
//       case 'R3':
//         return 13;
//       case 'R4':
//         return 17;
//     }

//     return 0;
//   }

//   Future<List<String>> getCustomerList() async {
//     final snapshot = await firestore.collection('list_customer').get();
//     final dataList =
//         snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
//     return ['All (Select Customer)', ...dataList[0]['customer']];
//   }

//   Future<List<String>> getRepairLocationList() async {
//     final snapshot = await firestore.collection('list_repair_area').get();
//     final dataList =
//         snapshot.docs.map((doc) => doc.data()['site'] as String).toList();
//     return ['All', ...dataList];
//   }

//   Future<List<dynamic>> loadCustomerListandRepairLocationData() async {
//     return Future.wait([
//       getCustomerList(),
//       getRepairLocationList(),
//     ]);
//   }

//   Query buildFirestoreQuery() {
//     Query query = firestore.collection(FirestoreKey.tireRepairInspectionReport);

//     query = query.where('is_inspected', isEqualTo: selectedIndex);

//     if (selectedCustomer != null &&
//         selectedCustomer != 'All (Select Customer)') {
//       query = query.where('customer', isEqualTo: selectedCustomer);
//     }

//     if (selectedRepairLocation != null && selectedRepairLocation != 'All') {
//       query = query.where('repair_location', isEqualTo: selectedRepairLocation);
//     }

//     query = query.where('status', isEqualTo: selectedStatus);

//     if (searchQuery.isNotEmpty) {
//       String searchKey = searchQuery.toUpperCase();
//       query = query
//           .where('sn', isGreaterThanOrEqualTo: searchKey)
//           .where('sn', isLessThanOrEqualTo: '$searchKey\uf8ff');
//     }

//     if (searchQuery.isNotEmpty) {
//       query = query.orderBy('sn');
//     } else {
//       query = query.orderBy('created_at', descending: true);
//     }

//     return query;
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final tween =
//         Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero);
//     final animation = tween.animate(_controller);

//     return Scaffold(
//       resizeToAvoidBottomInset: false,
//       backgroundColor: const Color(0xFFF1F1F1),
//       appBar: appBarWidget('Tire Repair Inspection Report', context),
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 24.0),
//               child: TextField(
//                 onChanged: (value) {
//                   setState(() {
//                     searchQuery = value;
//                   });
//                 },
//                 decoration: InputDecoration(
//                     hintText: 'Search... (SN)',
//                     hintStyle: getGreyTextStyle(grey8391A1),
//                     prefixIcon: Icon(Icons.search)),
//               ),
//             ),
//             const SizedBox(
//               height: 12,
//             ),
//             FutureBuilder(
//                 future: loadCustomerListandRepairLocationData(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) return CircularProgressIndicator();

//                   final List<String> customers = snapshot.data![0];
//                   final List<String> repairLocationList = snapshot.data![1];

//                   selectedCustomer ??= customers[0];
//                   selectedRepairLocation ??= repairLocationList[0];
//                   return Column(
//                     children: [
//                       Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 24.0),
//                         child: DropdownButton<String>(
//                           value: selectedCustomer,
//                           isExpanded: true,
//                           items: customers.map((customer) {
//                             return DropdownMenuItem<String>(
//                               value: customer,
//                               child: Text(customer),
//                             );
//                           }).toList(),
//                           onChanged: (newValue) {
//                             setState(() {
//                               selectedCustomer = newValue!;
//                               print('select customer : $selectedCustomer');
//                             });
//                           },
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: Padding(
//                               padding:
//                                   const EdgeInsets.only(left: 24.0, right: 12),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Select Status',
//                                     style: getBlackTextStyle(
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                   DropdownButton<String>(
//                                     value: selectedStatus,
//                                     isExpanded: true,
//                                     items: status.map((stat) {
//                                       return DropdownMenuItem<String>(
//                                         value: stat,
//                                         child: Text(stat),
//                                       );
//                                     }).toList(),
//                                     onChanged: (newValue) {
//                                       setState(() {
//                                         selectedStatus = newValue!;
//                                         print(
//                                             'select status : $selectedStatus');
//                                       });
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           Expanded(
//                             child: Padding(
//                               padding:
//                                   const EdgeInsets.only(right: 24.0, left: 12),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     'Select Repair Location',
//                                     style: getBlackTextStyle(
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                   DropdownButton<String>(
//                                     value: selectedRepairLocation,
//                                     isExpanded: true,
//                                     items: repairLocationList.map((loc) {
//                                       return DropdownMenuItem<String>(
//                                         value: loc,
//                                         child: Text(loc),
//                                       );
//                                     }).toList(),
//                                     onChanged: (newValue) {
//                                       setState(() {
//                                         selectedRepairLocation = newValue!;
//                                         print(
//                                             'select repair location : $selectedRepairLocation');
//                                       });
//                                     },
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                       const SizedBox(height: 12),
//                       PaginateFirestore(
//                         // key: ValueKey(selectedIndex),
//                         key: ValueKey(
//                             '$selectedIndex-$selectedCustomer-$selectedStatus-$searchQuery-$selectedRepairLocation'),
//                         // query: selectedIndex == 1
//                         //     ? firestore
//                         //         .collection(
//                         //             FirestoreKey.tireRepairInspectionReport)
//                         //         .where('is_inspected', isEqualTo: selectedIndex)
//                         //         .orderBy('created_at', descending: true)
//                         //     : firestore
//                         //         .collection(
//                         //             FirestoreKey.tireRepairInspectionReport)
//                         //         .where('is_inspected',
//                         //             isEqualTo: selectedIndex),
//                         query: buildFirestoreQuery(),
//                         itemBuilderType: PaginateBuilderType.listView,
//                         shrinkWrap: true,
//                         physics: NeverScrollableScrollPhysics(),
//                         itemsPerPage: 5,
//                         isLive: true,
//                         initialLoader: const Center(
//                             child: CircularProgressIndicator.adaptive()),
//                         bottomLoader: const Center(
//                             child: CircularProgressIndicator.adaptive()),
//                         itemBuilder: (context, snapshot, index) {
//                           final Map<String, dynamic> data =
//                               snapshot[index].data() as Map<String, dynamic>;
//                           DateFormat date = DateFormat('dd-MM-yy');

//                           // // filter sn
//                           // if (searchQuery.isNotEmpty &&
//                           //     !data['sn']!
//                           //         .toLowerCase()
//                           //         .contains(searchQuery) &&
//                           //     !data['sn']!
//                           //         .toUpperCase()
//                           //         .contains(searchQuery)) {
//                           //   return Container();
//                           // }

//                           // // filter status tire
//                           // if (!data['status'].contains(selectedStatus)) {
//                           //   return Container();
//                           // }

//                           // // filter customer
//                           // if (selectedCustomer != 'All (Select Customer)' &&
//                           //     !data['customer']!.contains(selectedCustomer)) {
//                           //   return Container();
//                           // }

//                           switch (selectedIndex) {
//                             case 0:
//                               return GestureDetector(
//                                 onTap: () {
//                                   Navigator.pushNamed(context,
//                                       TireRepairInspectionFormPage.routeName,
//                                       arguments: data['id']);
//                                 },
//                                 child: Container(
//                                   width:
//                                       MediaQuery.of(context).size.width * 0.9,
//                                   // height: 180,
//                                   margin: EdgeInsets.only(
//                                       bottom: 6, top: 6, right: 24, left: 24),
//                                   padding: const EdgeInsets.all(5.0),
//                                   decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(20.0),
//                                       border: Border.all(color: Colors.black),
//                                       color: Colors.transparent),
//                                   child: Stack(
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Image.asset(
//                                             'assets/images/ban.png',
//                                             width: 100.0,
//                                             height: 120.0,
//                                           ),
//                                           Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Text(
//                                                 data['sn'],
//                                                 style: getBlackTextStyle(
//                                                     fontSize: 24,
//                                                     fontWeight:
//                                                         FontWeight.w700),
//                                               ),
//                                               const SizedBox(height: 4.0),
//                                               Container(
//                                                 width: 170,
//                                                 child: Text(
//                                                     '${data['customer']} site : ${data['site']}',
//                                                     style: getBlackTextStyle(
//                                                         fontSize: 16,
//                                                         fontWeight:
//                                                             FontWeight.w700)),
//                                               ),
//                                               const SizedBox(height: 4.0),
//                                               Container(
//                                                 width: 120.0,
//                                                 height: 2.0,
//                                                 color: Colors.black,
//                                               ),
//                                               const SizedBox(height: 4.0),
//                                               Text(
//                                                   '${data['brand']} / ${data['tire_size']}',
//                                                   style: getBlackTextStyle(
//                                                       fontSize: 16,
//                                                       fontWeight:
//                                                           FontWeight.w700)),
//                                               const SizedBox(height: 4.0),
//                                               Text('Need to be inspect!',
//                                                   style: getBlackTextStyle(
//                                                       fontSize: 16,
//                                                       fontWeight:
//                                                           FontWeight.w700)),
//                                               const SizedBox(height: 4.0),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             case 1:
//                               return GestureDetector(
//                                 onTap: () {
//                                   Navigator.pushNamed(context,
//                                       DetailTireRepairInspection.routeName,
//                                       arguments: data['id']);
//                                 },
//                                 child: Container(
//                                   width:
//                                       MediaQuery.of(context).size.width * 0.9,
//                                   // height: 180,
//                                   margin: EdgeInsets.only(
//                                       bottom: 6, top: 6, right: 24, left: 24),
//                                   padding: const EdgeInsets.all(5.0),
//                                   decoration: BoxDecoration(
//                                       borderRadius: BorderRadius.circular(20.0),
//                                       color: (data['repair_duration'] == '' ||
//                                               data['repair_duration'] == null)
//                                           ? black
//                                           : (data['repair_duration'] == 'R1')
//                                               ? green00968A
//                                               : (data['repair_duration'] ==
//                                                       'R2')
//                                                   ? Colors.yellow[800]
//                                                   : (data['repair_duration'] ==
//                                                           'R3')
//                                                       ? blue344BEF
//                                                       : Colors.red),

//                                   child: Stack(
//                                     children: [
//                                       Row(
//                                         children: [
//                                           Image.asset(
//                                             'assets/images/ban.png',
//                                             width: 100.0,
//                                             height: 120.0,
//                                           ),
//                                           Column(
//                                             crossAxisAlignment:
//                                                 CrossAxisAlignment.start,
//                                             mainAxisAlignment:
//                                                 MainAxisAlignment.center,
//                                             children: [
//                                               Text(
//                                                 data['sn'],
//                                                 style: getWhiteTextStyle(
//                                                     fontSize: 24,
//                                                     fontWeight:
//                                                         FontWeight.w700),
//                                               ),
//                                               const SizedBox(height: 4.0),
//                                               Container(
//                                                 width: 170,
//                                                 child: Text(
//                                                     '${data['customer']} site : ${data['site']}',
//                                                     style: getWhiteTextStyle(
//                                                         fontSize: 16,
//                                                         fontWeight:
//                                                             FontWeight.w700)),
//                                               ),
//                                               const SizedBox(height: 4.0),
//                                               Container(
//                                                 width: 120.0,
//                                                 height: 2.0,
//                                                 color: Colors.white,
//                                               ),
//                                               const SizedBox(height: 4.0),
//                                               Text(
//                                                   '${data['brand']} / ${data['tire_size']}',
//                                                   style: getWhiteTextStyle(
//                                                       fontSize: 16,
//                                                       fontWeight:
//                                                           FontWeight.w700)),
//                                               const SizedBox(height: 4.0),
//                                               Text(
//                                                   'Inspected : ${date.format(DateTime.parse('${data['date_inspect']}'))}',
//                                                   style: getWhiteTextStyle(
//                                                       fontSize: 16,
//                                                       fontWeight:
//                                                           FontWeight.w700)),
//                                               const SizedBox(height: 4.0),
//                                               Text(
//                                                   'Repair Completed : ${date.format(DateTime.parse('${data['date_inspect']}').add(Duration(days: repairDurationMatrix('${data['repair_duration']}'))))}',
//                                                   style: getWhiteTextStyle(
//                                                       fontSize: 16,
//                                                       fontWeight:
//                                                           FontWeight.w700)),
//                                               const SizedBox(height: 4.0),
//                                             ],
//                                           ),
//                                         ],
//                                       ),
//                                       Align(
//                                         alignment: Alignment.topRight,
//                                         child: Padding(
//                                           padding: const EdgeInsets.all(8.0),
//                                           child: Text(
//                                               (data['repair_duration'] == null)
//                                                   ? ''
//                                                   : '${data['repair_duration']}',
//                                               style: getWhiteTextStyle(
//                                                   fontSize: 20,
//                                                   fontWeight: FontWeight.w700)),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               );
//                           }
//                           return Container();
//                         },
//                       ),
//                       const SizedBox(
//                         height: 84,
//                       )
//                     ],
//                   );
//                 }),
//           ],
//         ),
//       ),
//       floatingActionButton: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6),
//         child: SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: ElevatedButton(
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.white, // Warna latar putih
//               foregroundColor: Colors.green, // Warna teks dan ikon hijau
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(30),
//                 side: const BorderSide(
//                     color: Colors.green, width: 6), // Border hijau
//               ),
//             ),
//             onPressed: () {
//               _controller.forward();
//               Navigator.push(
//                 context,
//                 PageRouteBuilder(
//                     transitionDuration: const Duration(milliseconds: 500),
//                     transitionsBuilder:
//                         (context, animation, secondaryAnimation, child) {
//                       const Offset begin = Offset(1.0, 0.0);
//                       const Offset end = Offset.zero;
//                       const Curve curve = Curves.easeInOut;

//                       var tween = Tween<Offset>(begin: begin, end: end);
//                       var offsetAnimation = animation
//                           .drive(tween.chain(CurveTween(curve: curve)));

//                       return SlideTransition(
//                           position: offsetAnimation, child: child);
//                     },
//                     pageBuilder: (context, animation, secondaryAnimation) =>
//                         TireRepairInspectionFormPage()),
//               );
//             },
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(
//                   Icons.add,
//                   color: black,
//                 ),
//                 const SizedBox(
//                   width: 12,
//                 ),
//                 Text("Add Tire", style: getBlackTextStyle(fontSize: 16)),
//               ],
//             ),
//           ),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//       bottomNavigationBar: BottomNavigationBar(
//         items: const [
//           BottomNavigationBarItem(
//               icon: Icon(Icons.pending), label: 'Not Inspect'),
//           BottomNavigationBarItem(icon: Icon(Icons.done), label: 'Inspected'),
//         ],
//         currentIndex: selectedIndex,
//         onTap: (index) {
//           setState(() {
//             selectedIndex = index;
//             log('selectedindex = ${selectedIndex}');
//           });
//         },
//       ),
//     );
//   }
// }

import 'dart:developer';

import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/firebase_key/firebase_key.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection/detail_tire_repair_inspection_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection/tire_repair_inspection_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';

class TireRepairInspectionPage extends StatefulWidget {
  static const routeName = '/tire-repair-inspection';
  const TireRepairInspectionPage({super.key});

  @override
  State<TireRepairInspectionPage> createState() =>
      _TireRepairInspectionPageState();
}

class _TireRepairInspectionPageState extends State<TireRepairInspectionPage>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late Stream<QuerySnapshot> customerStream;
  String searchQuery = '';
  String? selectedCustomer;
  String? selectedRepairLocation;
  int selectedIndex = 1;
  List<String> status = ['REPAIR', 'RETREAD', 'REJECT'];
  List<String> statusTire = ['Inspected', 'Not Inspected'];
  String selectedStatus = 'REPAIR';

  // BARU: State untuk filter bulan dan tahun
  int? selectedYear;
  int? selectedMonth;

  final double containerWidthFactor = 0.8;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    customerStream = firestore.collection('list_customer').snapshots();

    // BARU: Set nilai default filter ke bulan dan tahun saat ini
    final now = DateTime.now();
    selectedYear = now.year;
    selectedMonth = now.month;
  }

  int repairDurationMatrix(String repairDuration) {
    switch (repairDuration) {
      case 'R1':
        return 5;
      case 'R2':
        return 9;
      case 'R3':
        return 13;
      case 'R4':
        return 17;
    }

    return 0;
  }

  Future<List<String>> getCustomerList() async {
    final snapshot = await firestore.collection('list_customer').get();
    final dataList =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    return ['All (Select Customer)', ...dataList[0]['customer']];
  }

  Future<List<String>> getRepairLocationList() async {
    final snapshot = await firestore.collection('list_repair_area').get();
    final dataList =
        snapshot.docs.map((doc) => doc.data()['site'] as String).toList();
    return ['All', ...dataList];
  }

  Future<List<dynamic>> loadCustomerListandRepairLocationData() async {
    return Future.wait([
      getCustomerList(),
      getRepairLocationList(),
    ]);
  }

  Query buildFirestoreQuery() {
    Query query = firestore.collection(FirestoreKey.tireRepairInspectionReport);

    query = query.where('is_inspected', isEqualTo: selectedIndex);

    if (selectedCustomer != null &&
        selectedCustomer != 'All (Select Customer)') {
      query = query.where('customer', isEqualTo: selectedCustomer);
    }

    if (selectedRepairLocation != null && selectedRepairLocation != 'All') {
      query = query.where('repair_location', isEqualTo: selectedRepairLocation);
    }

    query = query.where('status', isEqualTo: selectedStatus);

    if (searchQuery.isNotEmpty) {
      String searchKey = searchQuery.toUpperCase();
      query = query
          .where('sn', isGreaterThanOrEqualTo: searchKey)
          .where('sn', isLessThanOrEqualTo: '$searchKey\uf8ff');
      query = query.orderBy('sn');
    } else {
      if (selectedYear != null && selectedMonth != null) {
        final DateTime startOfMonth = DateTime(selectedYear!, selectedMonth!);
        final DateTime endOfMonth = (selectedMonth == 12)
            ? DateTime(selectedYear! + 1, 1)
            : DateTime(selectedYear!, selectedMonth! + 1);

        query = query.where('created_at',
            isGreaterThanOrEqualTo: startOfMonth.toIso8601String());
        query =
            query.where('created_at', isLessThan: endOfMonth.toIso8601String());
      }
      query = query.orderBy('created_at', descending: true);
    }

    return query;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // BARU: Helper list untuk dropdown bulan dan tahun
    final List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final int currentYear = DateTime.now().year;
    // Membuat list 5 tahun ke belakang dari tahun sekarang
    final List<int> years = List.generate(5, (index) => currentYear - index);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: appBarWidget('Tire Repair Inspection Report', context),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                    hintText: 'Search... (SN)',
                    hintStyle: getGreyTextStyle(grey8391A1),
                    prefixIcon: Icon(Icons.search)),
              ),
            ),
            const SizedBox(
              height: 12,
            ),
            FutureBuilder(
                future: loadCustomerListandRepairLocationData(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  final List<String> customers = snapshot.data![0];
                  final List<String> repairLocationList = snapshot.data![1];

                  selectedCustomer ??= customers[0];
                  selectedRepairLocation ??= repairLocationList[0];
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: DropdownButton<String>(
                          value: selectedCustomer,
                          isExpanded: true,
                          items: customers.map((customer) {
                            return DropdownMenuItem<String>(
                              value: customer,
                              child: Text(customer),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedCustomer = newValue!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(left: 24.0, right: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Status',
                                    style: getBlackTextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: selectedStatus,
                                    isExpanded: true,
                                    items: status.map((stat) {
                                      return DropdownMenuItem<String>(
                                        value: stat,
                                        child: Text(stat),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedStatus = newValue!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(right: 24.0, left: 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Select Repair Location',
                                    style: getBlackTextStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  DropdownButton<String>(
                                    value: selectedRepairLocation,
                                    isExpanded: true,
                                    items: repairLocationList.map((loc) {
                                      return DropdownMenuItem<String>(
                                        value: loc,
                                        child: Text(loc),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedRepairLocation = newValue!;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // BARU: UI untuk filter bulan dan tahun
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Month',
                                        style: getBlackTextStyle(fontSize: 12)),
                                    DropdownButton<int>(
                                      value: selectedMonth,
                                      isExpanded: true,
                                      items: List.generate(12, (index) {
                                        return DropdownMenuItem<int>(
                                          value: index + 1,
                                          child: Text(months[index]),
                                        );
                                      }),
                                      onChanged: (newValue) {
                                        setState(() {
                                          selectedMonth = newValue!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Year',
                                        style: getBlackTextStyle(fontSize: 12)),
                                    DropdownButton<int>(
                                      value: selectedYear,
                                      isExpanded: true,
                                      items: years.map((year) {
                                        return DropdownMenuItem<int>(
                                          value: year,
                                          child: Text(year.toString()),
                                        );
                                      }).toList(),
                                      onChanged: (newValue) {
                                        setState(() {
                                          selectedYear = newValue!;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      PaginateFirestore(
                        // DIUBAH: ValueKey diperbarui dengan filter tanggal
                        key: ValueKey(
                            '$selectedIndex-$selectedCustomer-$selectedStatus-$searchQuery-$selectedRepairLocation-$selectedYear-$selectedMonth'),
                        query: buildFirestoreQuery(),
                        itemBuilderType: PaginateBuilderType.listView,
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemsPerPage: 5,
                        isLive: true,
                        initialLoader: const Center(
                            child: CircularProgressIndicator.adaptive()),
                        bottomLoader: const Center(
                            child: CircularProgressIndicator.adaptive()),
                        itemBuilder: (context, snapshot, index) {
                          // ... sisa dari itemBuilder Anda (tidak ada perubahan)
                          final Map<String, dynamic> data =
                              snapshot[index].data() as Map<String, dynamic>;
                          DateFormat date = DateFormat('dd-MM-yy');

                          switch (selectedIndex) {
                            case 0:
                              return GestureDetector(
                                // ... Card untuk 'Not Inspected'
                                onTap: () {
                                  Navigator.pushNamed(context,
                                      TireRepairInspectionFormPage.routeName,
                                      arguments: data['id']);
                                },
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  margin: EdgeInsets.only(
                                      bottom: 6, top: 6, right: 24, left: 24),
                                  padding: const EdgeInsets.all(5.0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      border: Border.all(color: Colors.black),
                                      color: Colors.transparent),
                                  child: Stack(
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/ban.png',
                                            width: 100.0,
                                            height: 120.0,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                data['sn'],
                                                style: getBlackTextStyle(
                                                    fontSize: 24,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                              const SizedBox(height: 4.0),
                                              Container(
                                                width: 170,
                                                child: Text(
                                                    '${data['customer']} site : ${data['site']}',
                                                    style: getBlackTextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ),
                                              const SizedBox(height: 4.0),
                                              Container(
                                                width: 120.0,
                                                height: 2.0,
                                                color: Colors.black,
                                              ),
                                              const SizedBox(height: 4.0),
                                              Text(
                                                  '${data['brand']} / ${data['tire_size']}',
                                                  style: getBlackTextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const SizedBox(height: 4.0),
                                              Text('Need to be inspect!',
                                                  style: getBlackTextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const SizedBox(height: 4.0),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            case 1:
                              return GestureDetector(
                                // ... Card untuk 'Inspected'
                                onTap: () {
                                  Navigator.pushNamed(context,
                                      DetailTireRepairInspection.routeName,
                                      arguments: data['id']);
                                },
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  margin: EdgeInsets.only(
                                      bottom: 6, top: 6, right: 24, left: 24),
                                  padding: const EdgeInsets.all(5.0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: (data['repair_duration'] == '' ||
                                              data['repair_duration'] == null)
                                          ? black
                                          : (data['repair_duration'] == 'R1')
                                              ? green00968A
                                              : (data['repair_duration'] ==
                                                      'R2')
                                                  ? Colors.yellow[800]
                                                  : (data['repair_duration'] ==
                                                          'R3')
                                                      ? blue344BEF
                                                      : Colors.red),
                                  child: Stack(
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            'assets/images/ban.png',
                                            width: 100.0,
                                            height: 120.0,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                data['sn'],
                                                style: getWhiteTextStyle(
                                                    fontSize: 24,
                                                    fontWeight:
                                                        FontWeight.w700),
                                              ),
                                              const SizedBox(height: 4.0),
                                              Container(
                                                width: 170,
                                                child: Text(
                                                    '${data['customer']} site : ${data['site']}',
                                                    style: getWhiteTextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w700)),
                                              ),
                                              const SizedBox(height: 4.0),
                                              Container(
                                                width: 120.0,
                                                height: 2.0,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(height: 4.0),
                                              Text(
                                                  '${data['brand']} / ${data['tire_size']}',
                                                  style: getWhiteTextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const SizedBox(height: 4.0),
                                              Text(
                                                  'Inspected : ${date.format(DateTime.parse('${data['date_inspect']}'))}',
                                                  style: getWhiteTextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const SizedBox(height: 4.0),
                                              Text(
                                                  'Repair Completed : ${date.format(DateTime.parse('${data['date_inspect']}').add(Duration(days: repairDurationMatrix('${data['repair_duration']}'))))}',
                                                  style: getWhiteTextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const SizedBox(height: 4.0),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Align(
                                        alignment: Alignment.topRight,
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                              (data['repair_duration'] == null)
                                                  ? ''
                                                  : '${data['repair_duration']}',
                                              style: getWhiteTextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                          }
                          return Container();
                        },
                      ),
                      const SizedBox(
                        height: 84,
                      )
                    ],
                  );
                }),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 6),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(color: Colors.green, width: 6),
              ),
            ),
            onPressed: () {
              _controller.forward();
              Navigator.push(
                context,
                PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 500),
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const Offset begin = Offset(1.0, 0.0);
                      const Offset end = Offset.zero;
                      const Curve curve = Curves.easeInOut;

                      var tween = Tween<Offset>(begin: begin, end: end);
                      var offsetAnimation = animation
                          .drive(tween.chain(CurveTween(curve: curve)));

                      return SlideTransition(
                          position: offsetAnimation, child: child);
                    },
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        TireRepairInspectionFormPage()),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add,
                  color: black,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text("Add Tire", style: getBlackTextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.pending), label: 'Not Inspect'),
          BottomNavigationBarItem(icon: Icon(Icons.done), label: 'Inspected'),
        ],
        currentIndex: selectedIndex,
        onTap: (index) {
          setState(() {
            selectedIndex = index;
            log('selectedindex = ${selectedIndex}');
          });
        },
      ),
    );
  }
}
