import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:camos/pages/tire_repair_form/detail_tire_repair_inspection_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  final double containerWidthFactor = 0.8;
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
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
        child: StreamBuilder(
            stream: firestore.collection('tire_repair_ins_report').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              List<Map<String, dynamic>> dataList = [];
              List<DocumentSnapshot> docs = snapshot.data!.docs;

              for (var doc in docs) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                dataList.add(data);
              }
              if (dataList.isEmpty) {
                return Center(
                  child: Text(
                    'Empty',
                    style: getBlackTextStyle(
                      fontSize: 24,
                    ),
                  ),
                );
              }

              return Column(
                children: dataList.map((data) {
                  DateFormat date = DateFormat('dd-MM-yy');
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            // Navigator.push(
                            //   context,
                            //   MaterialPageRoute(
                            //     builder: (context) =>
                            //         DetailTireRepairInspection(),
                            //   ),
                            // );
                            Navigator.pushNamed(
                                context, DetailTireRepairInspection.routeName,
                                arguments: data['id']);
                          },
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.9,
                            height: 150,
                            padding: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20.0),
                                color: (data['repair_duration'] == 'R1')
                                    ? green00968A
                                    : (data['repair_duration'] == 'R2')
                                        ? Colors.yellow[800]
                                        : (data['repair_duration'] == 'R3')
                                            ? blue344BEF
                                            : Colors.red
                                // gradient: LinearGradient(
                                //   colors: [
                                //     const Color(0xFF67ADFF),
                                //     const Color(0xFF4778B2),
                                //   ],
                                //   begin: Alignment.topCenter,
                                //   end: Alignment.bottomCenter,
                                // ),
                                ),
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
                                              fontWeight: FontWeight.w700),
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
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4.0),
                                        Text(
                                            'Inspected : ${date.format(DateTime.parse('${data['date_inspect']}'))}',
                                            style: getWhiteTextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4.0),
                                        Text(
                                            'Repair Completed : ${date.format(DateTime.parse('${data['date_inspect']}').add(Duration(days: repairDurationMatrix('${data['repair_duration']}'))))}',
                                            style: getWhiteTextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w700)),
                                        const SizedBox(height: 4.0),
                                      ],
                                    ),
                                  ],
                                ),
                                Align(
                                  alignment: Alignment.topRight,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('${data['repair_duration']}',
                                        style: getWhiteTextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            }),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFA3FF94), const Color(0xFF5A6AFB)],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
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
                    var offsetAnimation =
                        animation.drive(tween.chain(CurveTween(curve: curve)));

                    return SlideTransition(
                        position: offsetAnimation, child: child);
                  },
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      TireRepairInspectionFormPage()),
            );
          },
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 36.0,
          ),
          backgroundColor: Colors.transparent,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
