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
  int selectedIndex = 1;
  List<String> status = ['REPAIR', 'RETREAD', 'REJECT'];
  List<String> statusTire = ['Inspected', 'Not Inspected'];

  final double containerWidthFactor = 0.8;
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    customerStream = firestore.collection('list_customer').snapshots();
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
    final snapshot =
        await FirebaseFirestore.instance.collection('list_customer').get();
    final dataList =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    return ['All (Select Customer)', ...dataList[0]['customer']];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tween =
        Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero);
    final animation = tween.animate(_controller);

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
                future: getCustomerList(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();

                  List<String> customers = snapshot.data!;
                  selectedCustomer ??= customers[0];
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
                              print('select customer : $selectedCustomer');
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      PaginateFirestore(
                        key: ValueKey(selectedIndex),
                        query: selectedIndex == 1
                            ? firestore
                                .collection(FirestoreKey
                                    .tireRepairInspectionReportTrial)
                                .where('is_inspected', isEqualTo: selectedIndex)
                                .orderBy('date_inspect', descending: true)
                            : firestore
                                .collection(FirestoreKey
                                    .tireRepairInspectionReportTrial)
                                .where('is_inspected',
                                    isEqualTo: selectedIndex),
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
                          final Map<String, dynamic> data =
                              snapshot[index].data() as Map<String, dynamic>;
                          DateFormat date = DateFormat('dd-MM-yy');

                          // filter sn
                          if (searchQuery.isNotEmpty &&
                              !data['sn']!
                                  .toLowerCase()
                                  .contains(searchQuery) &&
                              !data['sn']!
                                  .toUpperCase()
                                  .contains(searchQuery)) {
                            return Container();
                          }

                          // filter customer
                          if (selectedCustomer != 'All (Select Customer)' &&
                              !data['customer']!.contains(selectedCustomer)) {
                            return Container();
                          }

                          switch (selectedIndex) {
                            case 0:
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pushNamed(context,
                                      TireRepairInspectionFormPage.routeName,
                                      arguments: data['id']);
                                },
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  // height: 180,
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
                                                    '${data['customer']}',
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
                                onTap: () {
                                  Navigator.pushNamed(context,
                                      DetailTireRepairInspection.routeName,
                                      arguments: data['id']);
                                },
                                child: Container(
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                  // height: 180,
                                  margin: EdgeInsets.only(
                                      bottom: 6, top: 6, right: 24, left: 24),
                                  padding: const EdgeInsets.all(5.0),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20.0),
                                      color: (data['repair_duration'] == '')
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
                                                    '${data['customer']}',
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
                                              '${data['repair_duration']}',
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
              backgroundColor: Colors.white, // Warna latar putih
              foregroundColor: Colors.green, // Warna teks dan ikon hijau
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: const BorderSide(
                    color: Colors.green, width: 6), // Border hijau
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
