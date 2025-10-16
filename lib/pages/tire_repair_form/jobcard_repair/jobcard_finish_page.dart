import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/data/jobcard_repair.dart';
import '../../../core/widgets/button_widget.dart';
import '../../../core/widgets/input_form_widget.dart';
import 'widget/tire_detail.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobcardFinishPage extends StatefulWidget {
  static const routeName = '/jobcard-finish-page';
  const JobcardFinishPage({super.key});

  @override
  State<JobcardFinishPage> createState() => _JobcardFinishPageState();
}

class _JobcardFinishPageState extends State<JobcardFinishPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          isScrollable: true,
          labelColor: white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: white,
          tabs: const [
            Tab(text: 'Tire Detail'),
            Tab(text: 'Process Repair (1)'),
            Tab(text: 'Process Repair (2)'),
            Tab(text: 'Process Repair (3)'),
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
            DetailRepair(),
            DetailRepair(),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      // JIKA PROCESS DI SKIP

                      // Column(
                      //   crossAxisAlignment: CrossAxisAlignment.end,
                      //   children: [
                      //     Text(
                      //       'By Whom',
                      //       style: getBlackTextStyle(),
                      //     ),
                      //     Text(
                      //       'Naufal',
                      //       style: getBlackTextStyle(),
                      //     ),
                      //   ],
                      // ),
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
          const SizedBox(
            height: 24,
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QC By',
                    style: getBlackTextStyle(),
                  ),
                  Text(
                    'Naufal',
                    style: getBlackTextStyle(
                      fontSize: 18,
                      fontWeight: w700,
                    ),
                  ),
                ],
              ),
              Text(
                now,
                style: getBlackTextStyle(fontSize: 18, fontWeight: w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
