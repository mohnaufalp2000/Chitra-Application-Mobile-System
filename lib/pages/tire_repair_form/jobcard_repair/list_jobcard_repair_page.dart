import 'package:camos/core/blocs/wo_jobcard/wo_jobcard_bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/jobcard_repair.dart';
import 'package:camos/core/utils/firebase_key/firebase_key.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/history_jobcard_repair_page.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/jobcard_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:intl/intl.dart';

class ListJobcardRepair extends StatefulWidget {
  static const routeName = '/list-jobcard-repair';
  const ListJobcardRepair({super.key});

  @override
  State<ListJobcardRepair> createState() => _ListJobcardRepairState();
}

class _ListJobcardRepairState extends State<ListJobcardRepair> {
  bool isChecked = false;
  final List<String> jobName =
      JobcardRepair.jobName.map((item) => item['name'] as String).toList();
  int selectedMenu = 0;
  List<Map<String, dynamic>> WOlist = [];

  List<bool> isCheckedList =
      List.generate(10, (_) => false); // Sesuaikan jumlah item

  void _onHistoryPressed() {
    // Navigator.pushNamed(context, JobcardQCPage.routeName);
    // Navigator.pushNamed(context, HistoryJobcardRepairPage.routeName);
    Navigator.pushNamed(context, HistoryJobcardRepairPage.routeName);
  }

  @override
  void initState() {
    super.initState();
    context.read<WoJobcardBloc>().add(WoJobcardEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jobcard Repair',
          style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF359B7B),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            color: Colors.white,
            tooltip: 'History',
            onPressed: _onHistoryPressed,
          ),
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: BlocConsumer<WoJobcardBloc, WoJobcardState>(
              listener: (context, state) {
                if (state is WoJobcardLoadedState) {
                  WOlist.clear();
                  WOlist.addAll(state.WOList);
                }
              },
              builder: (context, state) {
                if (state is WoJobcardLoadingState) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is WoJobcardLoadedState) {
                  final widgetOptions = [
                    WaitingWO(woList: WOlist),
                    OnProgress(woList: WOlist),
                    // const WaitingQC()
                  ];
                  return widgetOptions.elementAt(selectedMenu);
                } else if (state is WoJobcardErrorState) {
                  return const Center(
                    child: Icon(Icons.error),
                  );
                } else {
                  return Container();
                }
              },
            )),
      )),
      bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedMenu,
          onTap: (index) async {
            // FirebaseFirestore firestore = FirebaseFirestore.instance;
            // final snapshot = await firestore
            //     .collection(FirestoreKey.tireRepairInspectionReportTrial)
            //     .where('id', isEqualTo: 'v2qvvHSZF6')
            //     .get();

            // print('firebase kuy: ${snapshot.docs[0].data()}');
            setState(() {
              selectedMenu = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.tag), label: 'Waiting WO#'),
            BottomNavigationBarItem(
                icon: Icon(Icons.work_history), label: 'On Progress'),
            // BottomNavigationBarItem(
            //     icon: Icon(Icons.fact_check), label: 'Waiting QC'),
          ]),
    );
  }
}

class WaitingWO extends StatefulWidget {
  final List<Map<String, dynamic>> woList;

  const WaitingWO({super.key, required this.woList});

  @override
  State<WaitingWO> createState() => _WaitingWOState();
}

class _WaitingWOState extends State<WaitingWO> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final List<String> idWoList =
        widget.woList.map((item) => item['id_wo'] as String).toList();

    print('id wo list : ${idWoList}');

    return Column(
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
        PaginateFirestore(
            query: firestore
                .collection(FirestoreKey.tireRepairInspectionReport)
                .orderBy('created_at', descending: true),
            itemBuilderType: PaginateBuilderType.listView,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemsPerPage: 5,
            key: const Key('waiting_wo'),
            isLive: true,
            initialLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            bottomLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            itemBuilder: (context, snapshot, index) {
              final Map<String, dynamic> data =
                  snapshot[index].data() as Map<String, dynamic>;

              if (searchQuery.isNotEmpty &&
                  !data['sn']!.toLowerCase().contains(searchQuery) &&
                  !data['sn']!.toUpperCase().contains(searchQuery)) {
                return Container();
              }

              if (idWoList.contains(data['id'])) {
                return Container();
              }

              return WaitingWOCard(data: data);
            }),
      ],
    );
  }
}

class OnProgress extends StatefulWidget {
  const OnProgress({super.key, required this.woList});
  final List<Map<String, dynamic>> woList;

  @override
  State<OnProgress> createState() => _OnProgressState();
}

class _OnProgressState extends State<OnProgress> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final List<String> idWoList =
        widget.woList.map((item) => item['id_wo'] as String).toList();

    if (idWoList.isEmpty) {
      return Center(
          child: Text(
        'No data available',
        style: getBlackTextStyle(),
      ));
    }

    return Column(
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
        PaginateFirestore(
            query: firestore
                .collection(FirestoreKey.tireRepairInspectionReport)
                // .collection('tire_repair_ins_report')
                .orderBy('created_at', descending: true)
                .where('id', whereIn: idWoList),
            itemBuilderType: PaginateBuilderType.listView,
            shrinkWrap: true,
            key: const Key('on_progress'),
            physics: NeverScrollableScrollPhysics(),
            itemsPerPage: 5,
            isLive: true,
            initialLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            bottomLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            itemBuilder: (context, snapshot, index) {
              final Map<String, dynamic> data =
                  snapshot[index].data() as Map<String, dynamic>;
              // mendapatkan nomor WO
              final WO = widget.woList.firstWhere(
                  (element) => element['id_wo'] == data['id'],
                  orElse: () => {'wo': ''})['wo'];
              // mendapatkan WO date
              final WODate = widget.woList.firstWhere(
                  (element) => element['id_wo'] == data['id'],
                  orElse: () => {'wo': ''})['wo_date'];

              if (searchQuery.isNotEmpty &&
                  !data['sn']!.toLowerCase().contains(searchQuery) &&
                  !data['sn']!.toUpperCase().contains(searchQuery)) {
                return Container();
              }

              print('WO : $WO');
              if (WO == '') {
                return Container();
              }
              return JobcardCard(
                wo: WO,
                woDate: WODate,
                data: data,
              );
            }),
      ],
    );
  }
}

class WaitingQC extends StatelessWidget {
  const WaitingQC({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [],
    );
  }
}

class WaitingWOCard extends StatelessWidget {
  const WaitingWOCard({
    super.key,
    required this.data,
  });

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: white,
        elevation: 50,
        shadowColor: black,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer : ${data['customer']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Site : ${data['site']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Repair Location : ${data['repair_location']}',
              ),
              const SizedBox(
                height: 14,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'W/O #',
                    style: getGreyTextStyle(const Color(0xff969696)),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    'Waiting WO',
                    style: getBlackTextStyle(
                      fontSize: 18,
                      fontWeight: w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serial Number',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        // 'FGR3463GRE',
                        '${data['sn']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
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
                        'Tire Size',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '${data['tire_size']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class JobcardCard extends StatefulWidget {
  const JobcardCard(
      {super.key, required this.wo, required this.data, required this.woDate});

  final String wo;
  final String woDate;
  final Map<String, dynamic> data;

  @override
  State<JobcardCard> createState() => _JobcardCardState();
}

class _JobcardCardState extends State<JobcardCard> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<String> jobName =
      JobcardRepair.jobName.map((item) => item['name'] as String).toList();
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: white,
        elevation: 50,
        shadowColor: black,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer : ${widget.data['customer']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Site : ${widget.data['site']}',
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                'Repair Location : ${widget.data['repair_location']}',
              ),
              const SizedBox(
                height: 14,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'W/O #',
                    style: getGreyTextStyle(const Color(0xff969696)),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    widget.wo,
                    style: getBlackTextStyle(
                      fontSize: 18,
                      fontWeight: w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Brand',
                    style: getGreyTextStyle(const Color(0xff969696)),
                  ),
                  const SizedBox(
                    height: 4,
                  ),
                  Text(
                    '${widget.data['brand']}',
                    style: getBlackTextStyle(
                      fontSize: 18,
                      fontWeight: w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 6,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Serial Number',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        // 'FGR3463GRE',
                        '${widget.data['sn']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
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
                        'Tire Size',
                        style: getGreyTextStyle(const Color(0xff969696)),
                      ),
                      const SizedBox(
                        height: 4,
                      ),
                      Text(
                        '${widget.data['tire_size']}',
                        style: getBlackTextStyle(
                          fontSize: 18,
                          fontWeight: w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isExpanded)
                ...List.generate(
                    (widget.data['process_repair_count'] ?? 0) as int, (index) {
                  return Column(
                    children: [
                      ItemJob(
                        jobName: jobName,
                        data: widget.data,
                        cardIndex: index,
                        wo: widget.wo,
                        woDate: widget.woDate,
                      ),
                      const SizedBox(
                        height: 12,
                      ),
                      // ADD PROCESS BUTTON
                      ButtonWidget(
                          color: green359B7B,
                          name: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.add_circle,
                                color: white,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(
                                'Add Proccess',
                                style: getWhiteTextStyle(),
                              ),
                            ],
                          ),
                          function: () async {
                            final oldData = await firestore
                                .collection(
                                    FirestoreKey.tireRepairInspectionReport)
                                .where('id', isEqualTo: widget.data['id'])
                                .get();

                            final repairCount =
                                oldData.docs[0].data()['process_repair_count'];

                            await oldData.docs[0].reference.update({
                              'process_repair_count': FieldValue.increment(1),
                              'jobcard${repairCount + 1}': [],
                            });

                            setState(() {});
                          }),
                      const SizedBox(
                        height: 12,
                      ),
                    ],
                  );
                }),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(
                          (_isExpanded)
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: green35C2C1,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _isExpanded ? 'Hide' : 'Show Job Repair',
                          style: getGreenTextStyle(
                            fontWeight: w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ItemJob extends StatelessWidget {
  const ItemJob({
    super.key,
    required this.jobName,
    required this.data,
    required this.cardIndex,
    required this.wo,
    required this.woDate,
  });

  final List<String> jobName;
  final Map<String, dynamic> data;
  final int cardIndex;
  final String wo;
  final String woDate;

  bool containsAnyMatch({
    required List<String> listA,
    required List<dynamic> listB,
    required String matchKey,
  }) {
    print('sama a : ${listA}');
    print('sama b : ${listB}');
    final setA = listA.toSet();
    return listB.any((mapItem) => setA.contains(mapItem[matchKey]));
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String existingJob = '';

    String processRepairCount = '';
    int indexCount = cardIndex + 1;
    processRepairCount = '$indexCount';

    print('process : ${processRepairCount}');

    if (data['jobcard$processRepairCount'].isEmpty) {
      existingJob = 'Skiving';
    } else {
      final lastName = data['jobcard$processRepairCount'].last['name'];

      final jobList = JobcardRepair.jobName;
      final currentIndex = jobList.indexWhere((job) => job['name'] == lastName);

      existingJob = data['jobcard$processRepairCount'].last['name'];
      if (currentIndex != -1 && currentIndex < jobList.length - 1) {
        existingJob = jobList[currentIndex + 1]['name'];
      } else {
        // Kalau tidak ketemu atau sudah di akhir list, tetap pakai lastName
        existingJob = lastName;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(
              Icons.work,
            ),
            const SizedBox(
              width: 6,
            ),
            Text(
              'Process Repair (${cardIndex + 1})',
              style: getBlackTextStyle(
                fontSize: 16,
                fontWeight: w700,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 6,
        ),
        Column(
          children: List.generate(jobName.length, (index) {
            final jobcardItem = data['jobcard$processRepairCount'].firstWhere(
              (item) => item['name'] == jobName[index],
              orElse: () => null,
            );
            return Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, JobcardFormPage.routeName,
                        arguments: {
                          'tireDetail': data,
                          'wo': wo,
                          'woDate': woDate,
                          'processRepairCount': processRepairCount
                        });
                  },
                  child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey,
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (jobcardItem != null &&
                              jobcardItem['hours'] == '0' &&
                              jobcardItem['minutes'] == '0')
                            Text(
                              jobName[index],
                              style: getBlackTextStyle().copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  decorationThickness: 3.0),
                            )
                          else
                            Row(
                              children: [
                                if (data['jobcard$processRepairCount'].any(
                                    (item) => item['name'] == jobName[index]))
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child:
                                        Image.asset('${iconPath}/accept.png'),
                                  )
                                else
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: black)),
                                  ),
                                const SizedBox(
                                  width: 6,
                                ),
                                Text(
                                  jobName[index],
                                  style: getBlackTextStyle(),
                                )
                              ],
                            ),
                          if (!data['jobcard$processRepairCount'].any(
                                  (item) => item['name'] == jobName[index]) &&
                              existingJob == jobName[index])
                            SizedBox(
                              width: 60,
                              height: 25,
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          'Confirmation Skip (${jobName[index]})',
                                          style: getBlackTextStyle(),
                                        ),
                                        content: Text(
                                          'Are you sure you want to skip this process (${jobName[index]})?',
                                          style: getBlackTextStyle(),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context)
                                                    .pop(), // Tutup dialog
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              final oldData = await firestore
                                                  .collection(FirestoreKey
                                                      .tireRepairInspectionReport)
                                                  .where('id',
                                                      isEqualTo: data['id'])
                                                  .get();
                                              final jobcardData = {
                                                'name': jobName[index],
                                                'fulldate': DateTime.now()
                                                    .toIso8601String(),
                                                'date': DateFormat('dd-MM-yyyy')
                                                    .format(DateTime.now()),
                                                'material': [
                                                  {
                                                    'id_matstock': '',
                                                    'name': '',
                                                    'qty': '',
                                                  }
                                                ],
                                                'hours': '0',
                                                'minutes': '0',
                                                'bywhom': '',
                                                'remarks': '',
                                                'process_repair_count':
                                                    oldData.docs.first[
                                                        'process_repair_count'],
                                                'id_wo': data['id'],
                                                'dimensi': '',
                                                'created_at': DateTime.now()
                                                    .toIso8601String(),
                                              };

                                              await oldData.docs[0].reference
                                                  .update({
                                                'jobcard$processRepairCount':
                                                    FieldValue.arrayUnion(
                                                        [jobcardData]),
                                              });

                                              await ApiService
                                                  .postJobJobcardRepair(
                                                      jobcardData);
                                              Navigator.of(context)
                                                  .pop(); // Tutup dialog
                                            },
                                            child: const Text('Yes'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                style: TextButton.styleFrom(
                                  backgroundColor: const Color(0xFF35469B),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.skip_next_outlined,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      SizedBox(width: 2),
                                      Text(
                                        'Skip',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            Container()
                        ],
                      )),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}
