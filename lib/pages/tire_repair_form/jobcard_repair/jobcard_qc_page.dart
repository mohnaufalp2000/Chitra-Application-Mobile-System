import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/jobcard_repair.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/jobcard_finish_page.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/widget/tire_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobcardQCPage extends StatefulWidget {
  static const routeName = '/jobcard-qc-page';
  const JobcardQCPage({super.key});

  @override
  State<JobcardQCPage> createState() => _JobcardQCPageState();
}

class _JobcardQCPageState extends State<JobcardQCPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tireDetail =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jobcard Repair',
          style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
        ),
        backgroundColor: green359B7B,
        iconTheme: const IconThemeData(color: Colors.white),
        bottom: TabBar(
          controller: _tabController,
          labelColor: white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: white,
          tabs: const [
            Tab(text: 'Tire Detail'),
            Tab(text: 'Process Repair (1)'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            TireDetail(
              tireDetail: tireDetail,
              wo: '',
              woDate: '',
            ),
            DetailRepair()
          ],
        ),
      ),
    );
  }
}

class DetailRepair extends StatefulWidget {
  const DetailRepair({super.key});

  @override
  State<DetailRepair> createState() => _DetailRepairState();
}

class _DetailRepairState extends State<DetailRepair> {
  String now = DateFormat('dd-MM-yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Text('Injuries',
                style: getBlackTextStyle(
                  fontSize: 18,
                  fontWeight: w700,
                )),
          ),
          const SizedBox(height: 10),
          Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                readOnly: true,
                controller: TextEditingController(text: '1 Mayor Sidewall'),
                maxLines: null,
                minLines: 5,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  contentPadding: EdgeInsets.only(left: 20, top: 40),
                ),
              )),
          const SizedBox(height: 12),
          Column(
            children: List.generate(JobcardRepair.jobName.length, (index) {
              final name = JobcardRepair.jobName[index]['name'];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: getBlackTextStyle(
                          fontSize: 16,
                          fontWeight: w700,
                        ),
                      ),
                      Text(
                        now,
                        style: getGreyTextStyle(grey8391A1),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Material (Cushion Gum)',
                    style: getBlackTextStyle(),
                  ),
                  Text(
                    'SV BLUE BONDING RUBBER',
                    style: getBlackTextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    height: 6,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'QTY',
                                  style: getBlackTextStyle(),
                                ),
                                Text(
                                  '1/2 KG',
                                  style: getBlackTextStyle(),
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 6,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hours',
                                  style: getBlackTextStyle(),
                                ),
                                Text(
                                  '1 Hour 0 Minute',
                                  style: getBlackTextStyle(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'By Whom',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              'Naufal',
                              style: getBlackTextStyle(),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                  Divider(
                    color: grey6A707C,
                  )
                ],
              );
            }),
          ),
          ButtonWidget(
              color: Colors.red,
              name: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.fast_rewind,
                    color: white,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    'Back To Repair',
                    style: getWhiteTextStyle(),
                  ),
                ],
              ),
              function: () {}),
          const SizedBox(
            height: 12,
          ),
          ButtonWidget(
              color: blue344BEF,
              name: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: white,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    'Complete',
                    style: getWhiteTextStyle(),
                  ),
                ],
              ),
              function: () {}),
        ],
      ),
    );
  }
}
