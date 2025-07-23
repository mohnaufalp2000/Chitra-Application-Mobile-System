import 'dart:developer';

import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/jobcard_repair.dart';
import 'package:camos/core/utils/firebase_key/firebase_key.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/jobcard_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class JobcardSelectedJobPage extends StatefulWidget {
  static const routeName = '/jobcard-selected-job-page';

  const JobcardSelectedJobPage({super.key});

  @override
  State<JobcardSelectedJobPage> createState() => _JobcardSelectedJobPageState();
}

class _JobcardSelectedJobPageState extends State<JobcardSelectedJobPage> {
  Map<String, dynamic> data = {};

  bool isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (isLoading) {
      final arguments =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      // Inisialisasi 'data' di sini
      data = arguments['data'] ?? {};
      isLoading = false;
    }
  }

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

    final Map<String, dynamic> arguments =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    print('initial jobcard : ${arguments}');

    // if (arguments['isFromJobcardList'] == true) {
    //   log('halaman sebelum A');
    //   data = arguments['data'] ?? [];
    // }

    String existingJob = '';

    String processRepairCount = '1';

    // Logika untuk existingJob harus menggunakan 'data' dari state
    if (data['jobcard$processRepairCount'] == null ||
        (data['jobcard$processRepairCount'] as List).isEmpty) {
      existingJob = 'Skiving';
    } else {
      final lastName =
          (data['jobcard$processRepairCount'] as List).last['name'];
      final jobList = JobcardRepair.jobName;
      final currentIndex = jobList.indexWhere((job) => job['name'] == lastName);
      existingJob = lastName;
      if (currentIndex != -1 && currentIndex < jobList.length - 1) {
        existingJob = jobList[currentIndex + 1]['name'];
      }
    }

    // if (data['jobcard$processRepairCount'].isEmpty) {
    //   existingJob = 'Skiving';
    // } else {
    //   final lastName = data['jobcard$processRepairCount'].last['name'];

    //   final jobList = JobcardRepair.jobName;
    //   final currentIndex = jobList.indexWhere((job) => job['name'] == lastName);

    //   existingJob = data['jobcard$processRepairCount'].last['name'];
    //   if (currentIndex != -1 && currentIndex < jobList.length - 1) {
    //     existingJob = jobList[currentIndex + 1]['name'];
    //   } else {
    //     // Kalau tidak ketemu atau sudah di akhir list, tetap pakai lastName
    //     existingJob = lastName;
    //   }
    // }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Input Jobcard Repair',
          style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF359B7B),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(
                height: 12,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.work,
                  ),
                  const SizedBox(
                    width: 6,
                  ),
                  Text(
                    'Process Repair',
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
              // Ganti seluruh Column Anda dengan ini
              Column(
                children: List.generate(JobcardRepair.jobName.length, (index) {
                  final jobName = JobcardRepair.jobName[index];

                  // Cek dulu apakah key 'jobcard...' ada dan merupakan sebuah List
                  final List<dynamic> jobcardList =
                      data['jobcard${processRepairCount}'] is List
                          ? data['jobcard${processRepairCount}']
                          : [];

                  // Cari item yang cocok dari list yang sudah aman
                  final Map<String, dynamic>? jobcardItem =
                      jobcardList.firstWhere(
                    (item) => item is Map && item['name'] == jobName['name'],
                    orElse: () =>
                        null, // Gunakan null jika tidak ada, lebih aman
                  );

                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          // Logika navigasi dan .then() Anda sudah benar, tidak perlu diubah
                          Navigator.pushNamed(
                            context,
                            JobcardFormPage.routeName,
                            arguments: {
                              'tireDetail': data,
                              'wo': arguments['wo'],
                              'woDate': arguments['woDate'],
                              'processRepairCount': processRepairCount,
                            },
                          ).then((value) async {
                            if (value == true && mounted) {
                              await Future.delayed(
                                  const Duration(milliseconds: 300));
                              final querySnapshot = await firestore
                                  .collection(
                                      FirestoreKey.tireRepairInspectionReport)
                                  .where('id', isEqualTo: data['id'])
                                  .limit(1)
                                  .get();

                              if (querySnapshot.docs.isNotEmpty) {
                                final newData = querySnapshot.docs.first.data()
                                    as Map<String, dynamic>;

                                // CUKUP UPDATE 'data'
                                setState(() {
                                  data = newData;
                                });
                              }
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: const BoxDecoration(/*...*/),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // PENGECEKAN UI YANG DIPERBAIKI
                              if (jobcardItem != null &&
                                  jobcardItem['hours'] == '0' &&
                                  jobcardItem['minutes'] == '0')
                                Text(
                                  jobName['name'],
                                  style: getBlackTextStyle().copyWith(
                                      decoration: TextDecoration.lineThrough,
                                      decorationThickness: 3.0),
                                )
                              else
                                Row(
                                  children: [
                                    // PENGECEKAN UI YANG DIPERBAIKI
                                    if (jobcardItem !=
                                        null) // Cukup cek apakah itemnya ada
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Image.asset(
                                            '${iconPath}/accept.png'),
                                      )
                                    else
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(color: black)),
                                      ),
                                    const SizedBox(width: 6),
                                    Text(
                                      jobName['name'],
                                      style: getBlackTextStyle(),
                                    )
                                  ],
                                ),
                              // Sisa kode ...
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ),
              // Column(
              //   children: List.generate(JobcardRepair.jobName.length, (index) {
              //     final jobName = JobcardRepair.jobName[index];
              //     log('jobnama : $jobName');

              //     Map<dynamic, dynamic> jobcardItem =
              //         data['jobcard${processRepairCount}'].firstWhere(
              //       (item) => item['name'] == jobName['name'],
              //       orElse: () => {},
              //     );
              //     log('jobitem : $jobcardItem');
              //     return Column(
              //       children: [
              //         InkWell(
              //           onTap: () async {
              //             Navigator.pushNamed(
              //               context,
              //               JobcardFormPage.routeName,
              //               arguments: {
              //                 'tireDetail': data,
              //                 'wo': arguments['wo'],
              //                 'woDate': arguments['woDate'],
              //                 'processRepairCount': processRepairCount
              //               },
              //             ).then((value) async {
              //               print(
              //                   'Kembali ke Halaman A, nilai yang diterima: $value');

              //               if (value == true && mounted) {
              //                 // --- TAMBAHKAN KODE DEBUG DI SINI ---
              //                 print("--- DEBUG START ---");
              //                 print(
              //                     "DATA LAMA (SEBELUM FETCH): ${data['jobcard${processRepairCount}']}");

              //                 // Tambahkan sedikit jeda untuk memberi waktu Firestore memproses data
              //                 await Future.delayed(
              //                     const Duration(milliseconds: 300));

              //                 final querySnapshot = await firestore
              //                     .collection(
              //                         FirestoreKey.tireRepairInspectionReport)
              //                     .where('id', isEqualTo: data['id'])
              //                     .limit(1)
              //                     .get();

              //                 if (querySnapshot.docs.isNotEmpty) {
              //                   final newData = querySnapshot.docs.first.data()
              //                       as Map<String, dynamic>;

              //                   // 2. CUKUP UPDATE 'data' SAJA DI DALAM SETSTATE
              //                   setState(() {
              //                     data = newData;
              //                   });
              //                 }
              //               }
              //             });
              //             // await Navigator.pushNamed(
              //             //     context, JobcardFormPage.routeName,
              //             //     arguments: {
              //             //       'tireDetail': data,
              //             //       'wo': arguments['wo'],
              //             //       'woDate': arguments['woDate'],
              //             //       'processRepairCount': processRepairCount
              //             //     });
              //             // if (context.mounted) {
              //             //   context.read<WoJobcardBloc>().add(WoJobcardEvent());
              //             // }
              //           },
              //           child: Container(
              //               padding: const EdgeInsets.symmetric(vertical: 8),
              //               decoration: const BoxDecoration(
              //                 border: Border(
              //                   bottom: BorderSide(
              //                     color: Colors.grey,
              //                     width: 1.0,
              //                   ),
              //                 ),
              //               ),
              //               child: Row(
              //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
              //                 children: [
              //                   if (jobcardItem != null &&
              //                       jobcardItem['hours'] == '0' &&
              //                       jobcardItem['minutes'] == '0')
              //                     Text(
              //                       jobName['name'],
              //                       style: getBlackTextStyle().copyWith(
              //                           decoration: TextDecoration.lineThrough,
              //                           decorationThickness: 3.0),
              //                     )
              //                   else
              //                     Row(
              //                       children: [
              //                         if (data['jobcard${processRepairCount}']
              //                             .any((item) =>
              //                                 item['name'] == jobName['name']))
              //                           SizedBox(
              //                             width: 20,
              //                             height: 20,
              //                             child: Image.asset(
              //                                 '${iconPath}/accept.png'),
              //                           )
              //                         else
              //                           Container(
              //                             width: 20,
              //                             height: 20,
              //                             decoration: BoxDecoration(
              //                                 borderRadius:
              //                                     BorderRadius.circular(6),
              //                                 border: Border.all(color: black)),
              //                           ),
              //                         const SizedBox(
              //                           width: 6,
              //                         ),
              //                         Text(
              //                           jobName['name'],
              //                           style: getBlackTextStyle(),
              //                         )
              //                       ],
              //                     ),
              //                   if (!data['jobcard$processRepairCount'].any(
              //                           (item) => item['name'] == jobName) &&
              //                       existingJob == jobName)
              //                     SizedBox(
              //                       width: 60,
              //                       height: 25,
              //                       child: TextButton(
              //                         onPressed: () {
              //                           showDialog(
              //                             context: context,
              //                             builder: (BuildContext context) {
              //                               return AlertDialog(
              //                                 title: Text(
              //                                   'Confirmation Skip (${jobName})',
              //                                   style: getBlackTextStyle(),
              //                                 ),
              //                                 content: Text(
              //                                   'Are you sure you want to skip this process (${jobName})?',
              //                                   style: getBlackTextStyle(),
              //                                 ),
              //                                 actions: [
              //                                   TextButton(
              //                                     onPressed: () => Navigator.of(
              //                                             context)
              //                                         .pop(), // Tutup dialog
              //                                     child: const Text('Cancel'),
              //                                   ),
              //                                   ElevatedButton(
              //                                     onPressed: () async {
              //                                       final oldData = await firestore
              //                                           .collection(FirestoreKey
              //                                               .tireRepairInspectionReport)
              //                                           .where('id',
              //                                               isEqualTo:
              //                                                   data['id'])
              //                                           .get();
              //                                       final jobcardData = {
              //                                         'name': jobName,
              //                                         'fulldate': DateTime.now()
              //                                             .toIso8601String(),
              //                                         'date': DateFormat(
              //                                                 'dd-MM-yyyy')
              //                                             .format(
              //                                                 DateTime.now()),
              //                                         'material': [
              //                                           {
              //                                             'id_matstock': '',
              //                                             'name': '',
              //                                             'qty': '',
              //                                           }
              //                                         ],
              //                                         'hours': '0',
              //                                         'minutes': '0',
              //                                         'bywhom': '',
              //                                         'remarks': '',
              //                                         'process_repair_count':
              //                                             oldData.docs.first[
              //                                                 'process_repair_count'],
              //                                         'id_wo': data['id'],
              //                                         'dimensi': '',
              //                                         'created_at': DateTime
              //                                                 .now()
              //                                             .toIso8601String(),
              //                                       };

              //                                       await oldData
              //                                           .docs[0].reference
              //                                           .update({
              //                                         'jobcard$processRepairCount':
              //                                             FieldValue.arrayUnion(
              //                                                 [jobcardData]),
              //                                       });

              //                                       await ApiService
              //                                           .postJobJobcardRepair(
              //                                               jobcardData);
              //                                       Navigator.of(context)
              //                                           .pop(); // Tutup dialog
              //                                     },
              //                                     child: const Text('Yes'),
              //                                   ),
              //                                 ],
              //                               );
              //                             },
              //                           );
              //                         },
              //                         style: TextButton.styleFrom(
              //                           backgroundColor:
              //                               const Color(0xFF35469B),
              //                           padding: EdgeInsets.zero,
              //                           shape: RoundedRectangleBorder(
              //                             borderRadius:
              //                                 BorderRadius.circular(12),
              //                           ),
              //                         ),
              //                         child: const FittedBox(
              //                           fit: BoxFit.scaleDown,
              //                           child: Row(
              //                             children: [
              //                               Icon(
              //                                 Icons.skip_next_outlined,
              //                                 color: Colors.white,
              //                                 size: 14,
              //                               ),
              //                               SizedBox(width: 2),
              //                               Text(
              //                                 'Skip',
              //                                 style: TextStyle(
              //                                   color: Colors.white,
              //                                   fontSize: 10,
              //                                   fontWeight: FontWeight.bold,
              //                                 ),
              //                               ),
              //                             ],
              //                           ),
              //                         ),
              //                       ),
              //                     )
              //                   else
              //                     Container()
              //                 ],
              //               )),
              //         ),
              //       ],
              //     );
              //   }),
              // ),
            ],
          ),
        ),
      )),
    );
  }
}
