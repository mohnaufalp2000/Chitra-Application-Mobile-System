import 'dart:developer';

import 'package:camos/core/blocs/wo_jobcard/wo_jobcard_bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/jobcard_repair.dart';
import 'package:camos/core/utils/firebase_key/firebase_key.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/tire_repair_form/jobcard_repair/jobcard_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

    String existingJob = '';
    String lastJob = '';

    String processRepairCount = '1';

    if (data['jobcard$processRepairCount'] is List &&
        data['jobcard$processRepairCount'].isNotEmpty) {
      // Jika value adalah List DAN tidak kosong, baru ambil item terakhir
      lastJob = data['jobcard$processRepairCount'].last['name'];
    }

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

    print('last job : $lastJob');

    String formatDataDimensi(String rawData) {
      // 1. Pisahkan setiap grup data berdasarkan spasi.
      // Hasil: ["L25,W33,P22,T55", "L54,W66,P32,T75"]
      List<String> groups = rawData.split(' ');

      // 2. Proses setiap grup menggunakan .map()
      var formattedDimensiLuka = groups.map((group) {
        // 3. Pisahkan setiap pasangan key-value berdasarkan koma.
        // Hasil: ["L25", "W33", "P22", "T55"]
        List<String> pairs = group.split(',');

        // 4. Proses setiap pasangan untuk menambahkan " : ".
        var formattedPairs = pairs.map((pair) {
          if (pair.isNotEmpty) {
            // Ambil huruf pertama sebagai key, sisanya sebagai value.
            String key = pair.substring(0, 1);
            String value = pair.substring(1);
            return '$key : $value'; // Hasil: "L : 25"
          }
          return '';
        });

        // 5. Gabungkan kembali pasangan yang sudah diformat dengan spasi.
        // Hasil: "L : 25 W : 33 P : 22 T : 55"
        return formattedPairs.join(' ');
      });

      // 6. Gabungkan semua grup yang sudah diformat dengan baris baru (\n).
      return formattedDimensiLuka.join('\n');
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
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input Jobcard Repair',
              style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
            ),
            const SizedBox(
              height: 12,
            ),
            Text(
              'SN : ${data['sn']}',
              style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
            ),
          ],
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

                  final List<dynamic> jobcardList =
                      data['jobcard${processRepairCount}'] is List
                          ? data['jobcard${processRepairCount}']
                          : [];

                  final Map<String, dynamic>? jobcardItem =
                      jobcardList.firstWhere(
                    (item) => item is Map && item['name'] == jobName['name'],
                    orElse: () => null,
                  );

                  return Column(
                    children: [
                      InkWell(
                        onTap: (lastJob == 'Painting')
                            ? null
                            : () {
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
                                        .collection(FirestoreKey
                                            .tireRepairInspectionReport)
                                        .where('id', isEqualTo: data['id'])
                                        .limit(1)
                                        .get();

                                    if (querySnapshot.docs.isNotEmpty) {
                                      final newData = querySnapshot.docs.first
                                          .data() as Map<String, dynamic>;

                                      // CUKUP UPDATE 'data'
                                      setState(() {
                                        data = newData;
                                      });
                                    }
                                  }
                                });
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (jobcardItem != null &&
                                  jobcardItem['hours'] == '0' &&
                                  jobcardItem['minutes'] == '0')
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ),
                                        Text(
                                          jobName['name'],
                                          style: getBlackTextStyle().copyWith(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              decorationThickness: 1.5),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(
                                      height: 6,
                                    ),
                                    Text(
                                      'Skipped at : ${jobcardItem['date']}',
                                      style: getBlackTextStyle()
                                          .copyWith(decorationThickness: 3.0),
                                    ),
                                  ],
                                )
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    //
                                    Row(
                                      children: [
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
                                              border: Border.all(
                                                  color: Colors.black),
                                            ),
                                          ),
                                        const SizedBox(width: 6),
                                        // Gunakan Expanded di sini agar teks tidak overflow jika panjang
                                        Expanded(
                                          child: Text(
                                            jobName['name'],
                                            style: getBlackTextStyle(
                                                fontWeight: w700),
                                          ),
                                        ),
                                        if (!jobcardList.any((item) =>
                                                item['name'] ==
                                                jobName['name']) &&
                                            existingJob == jobName['name'])
                                          SizedBox(
                                              width: 60,
                                              height: 25,
                                              child: TextButton(
                                                onPressed: () async {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title: Text(
                                                          'Confirmation Skip (${jobName['name']})',
                                                          style:
                                                              getBlackTextStyle(),
                                                        ),
                                                        content: Text(
                                                          'Are you sure you want to skip this process (${jobName['name']})?',
                                                          style:
                                                              getBlackTextStyle(),
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed: () =>
                                                                Navigator.of(
                                                                        context)
                                                                    .pop(), // Tutup dialog
                                                            child: const Text(
                                                                'Cancel'),
                                                          ),
                                                          ElevatedButton(
                                                            onPressed:
                                                                () async {
                                                              final oldData = await firestore
                                                                  .collection(
                                                                      FirestoreKey
                                                                          .tireRepairInspectionReport)
                                                                  .where('id',
                                                                      isEqualTo:
                                                                          data[
                                                                              'id'])
                                                                  .get();
                                                              final jobcardData =
                                                                  {
                                                                'name': jobName[
                                                                    'name'],
                                                                'fulldate': DateTime
                                                                        .now()
                                                                    .toIso8601String(),
                                                                'date': DateFormat(
                                                                        'dd-MM-yyyy')
                                                                    .format(DateTime
                                                                        .now()),
                                                                'material': [
                                                                  {
                                                                    'id_matstock':
                                                                        '',
                                                                    'name': '',
                                                                    'qty': '',
                                                                    'smu': '',
                                                                  }
                                                                ],
                                                                'hours': '0',
                                                                'minutes': '0',
                                                                'bywhom': '',
                                                                'remarks': '',
                                                                'process_repair_count':
                                                                    1,
                                                                'id_wo':
                                                                    data['id'],
                                                                'dimensi': '',
                                                                'created_at':
                                                                    DateTime.now()
                                                                        .toIso8601String(),
                                                              };

                                                              await oldData
                                                                  .docs[0]
                                                                  .reference
                                                                  .update({
                                                                'jobcard1':
                                                                    FieldValue
                                                                        .arrayUnion([
                                                                  jobcardData
                                                                ]),
                                                              });

                                                              await ApiService
                                                                  .postJobJobcardRepair(
                                                                      jobcardData);

                                                              if (context
                                                                  .mounted)
                                                                Navigator.pop(
                                                                    context);

                                                              final querySnapshot = await firestore
                                                                  .collection(
                                                                      FirestoreKey
                                                                          .tireRepairInspectionReport)
                                                                  .where('id',
                                                                      isEqualTo:
                                                                          data[
                                                                              'id'])
                                                                  .limit(1)
                                                                  .get();
                                                              if (querySnapshot
                                                                      .docs
                                                                      .isNotEmpty &&
                                                                  mounted) {
                                                                final newData =
                                                                    querySnapshot
                                                                        .docs
                                                                        .first
                                                                        .data();

                                                                setState(() {
                                                                  data =
                                                                      newData;
                                                                });
                                                              }
                                                            },
                                                            child: const Text(
                                                                'Yes'),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }, // Disingkat
                                                style: TextButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFF35469B),
                                                  padding: EdgeInsets.zero,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: const FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                          Icons
                                                              .skip_next_outlined,
                                                          color: Colors.white,
                                                          size: 14),
                                                      SizedBox(width: 2),
                                                      Text('Skip',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 10,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ],
                                                  ),
                                                ),
                                              )),
                                      ],
                                    ),
                                    if (jobcardItem != null)
                                      Padding(
                                        // Beri sedikit jarak dari header di atas
                                        padding:
                                            const EdgeInsets.only(top: 12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(children: [
                                              const Icon(Icons
                                                  .account_circle_outlined),
                                              const SizedBox(width: 6),
                                              Text(
                                                  'Repairman : ${jobcardItem['bywhom']}',
                                                  style: getBlackTextStyle()),
                                            ]),
                                            const SizedBox(height: 14),
                                            Row(
                                              children: [
                                                const Icon(Icons.date_range),
                                                const SizedBox(
                                                  width: 6,
                                                ),
                                                Text(
                                                  'Date : ' +
                                                      jobcardList[index]
                                                          ['date'],
                                                  style: getBlackTextStyle(),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 14,
                                            ),
                                            Row(
                                              children: [
                                                const Icon(Icons.timer),
                                                const SizedBox(
                                                  width: 6,
                                                ),
                                                Text(
                                                  'Duration : ' +
                                                      '${(jobcardList[index]['hours'] == null || jobcardList[index]['hours'].isEmpty) ? '0' : jobcardList[index]['hours']} Hours  ${(jobcardList[index]['minutes'] == null || jobcardList[index]['minutes'].isEmpty) ? '0' : jobcardList[index]['minutes']} Minutes',
                                                  style: getBlackTextStyle(),
                                                ),
                                              ],
                                            ),
                                            if (jobcardList[index]['name'] ==
                                                'Dimensi Luka')
                                              Column(
                                                children: [
                                                  const SizedBox(
                                                    height: 14,
                                                  ),
                                                  Text(
                                                    '${formatDataDimensi(jobcardList[index]['dimensi'])}',
                                                    style: getBlackTextStyle(),
                                                  ),
                                                  const SizedBox(
                                                    height: 14,
                                                  ),
                                                ],
                                              )
                                            else
                                              Column(
                                                children: [
                                                  const SizedBox(
                                                    height: 14,
                                                  ),
                                                  Container(),
                                                ],
                                              ),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // 1. Cek dulu apakah list 'material' ada dan tidak kosong.
                                                // Pengecekan ini lebih aman daripada hanya memeriksa item pertama.
                                                if (jobcardList[index]
                                                            ['material'] !=
                                                        null &&
                                                    (jobcardList[index]
                                                                ['material']
                                                            as List)
                                                        .isNotEmpty &&
                                                    jobcardList[index]
                                                                ['material'][0]
                                                            ['name'] !=
                                                        '')

                                                  // 2. Gunakan spread operator `...` untuk memasukkan beberapa widget sekaligus jika kondisi true.
                                                  ...[
                                                  // Widget Judul "Material"
                                                  Row(
                                                    children: [
                                                      const Icon(
                                                          Icons.settings),
                                                      const SizedBox(width: 6),
                                                      Text('Material',
                                                          style:
                                                              getBlackTextStyle()),
                                                    ],
                                                  ),

                                                  // 3. Gunakan .asMap().entries.map() untuk membuat list material dengan index.
                                                  ...(jobcardList[index]
                                                          ['material'] as List)
                                                      .asMap()
                                                      .entries
                                                      .map((entry) {
                                                    final int itemIndex = entry
                                                        .key; // <- Ini adalah index dari item (0, 1, 2, ...)
                                                    final dynamic item =
                                                        entry.value;

                                                    return Padding(
                                                      padding: const EdgeInsets
                                                          .fromLTRB(8, 8, 8,
                                                          0), // Atur padding sesuai kebutuhan
                                                      child: Text(
                                                        // Gunakan itemIndex di sini, bukan index dari ListView.builder
                                                        '${itemIndex + 1}. ${item['name'] ?? ''} (Qty: ${item['qty'] ?? ''} ${item['smu'] ?? ''})',
                                                        style:
                                                            getBlackTextStyle(),
                                                      ),
                                                    );
                                                  }).toList(),
                                                ] else
                                                  // 4. Blok `else` jika material kosong.
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Text(
                                                      'No Material.',
                                                      style: getBlackTextStyle()
                                                          .copyWith(
                                                              fontStyle:
                                                                  FontStyle
                                                                      .italic),
                                                    ),
                                                  ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                        // child: Container(
                        //   padding: const EdgeInsets.symmetric(vertical: 8),
                        //   decoration: const BoxDecoration(/*...*/),
                        //   child: Row(
                        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        //     children: [
                        //       // PENGECEKAN UI YANG DIPERBAIKI
                        //       if (jobcardItem != null &&
                        //           jobcardItem['hours'] == '0' &&
                        //           jobcardItem['minutes'] == '0')
                        //         Text(
                        //           jobName['name'],
                        //           style: getBlackTextStyle().copyWith(
                        //               decoration: TextDecoration.lineThrough,
                        //               decorationThickness: 3.0),
                        //         )
                        //       else
                        //         Column(
                        //           crossAxisAlignment:
                        //               CrossAxisAlignment.start,
                        //           children: [
                        //             Row(
                        //               mainAxisAlignment:
                        //                   MainAxisAlignment.spaceBetween,
                        //               children: [
                        //                 Row(
                        //                   children: [
                        //                     // PENGECEKAN UI YANG DIPERBAIKI
                        //                     if (jobcardItem !=
                        //                         null) // Cukup cek apakah itemnya ada
                        //                       SizedBox(
                        //                         width: 20,
                        //                         height: 20,
                        //                         child: Image.asset(
                        //                             '${iconPath}/accept.png'),
                        //                       )
                        //                     else
                        //                       Container(
                        //                         width: 20,
                        //                         height: 20,
                        //                         decoration: BoxDecoration(
                        //                             borderRadius:
                        //                                 BorderRadius.circular(
                        //                                     6),
                        //                             border: Border.all(
                        //                                 color: black)),
                        //                       ),
                        //                     const SizedBox(width: 6),
                        //                     Text(
                        //                       jobName['name'],
                        //                       style: getBlackTextStyle(
                        //                         fontWeight: w700,
                        //                       ),
                        //                     ),
                        //                   ],
                        //                 ),
                        //                 if (!data['jobcard1'].any((item) =>
                        //                         item['name'] == jobName) &&
                        //                     existingJob == jobName['name'])
                        //                   SizedBox(
                        //                     width: 60,
                        //                     height: 25,
                        //                     child: TextButton(
                        //                       onPressed: () {
                        //                         showDialog(
                        //                           context: context,
                        //                           builder:
                        //                               (BuildContext context) {
                        //                             return AlertDialog(
                        //                               title: Text(
                        //                                 'Confirmation Skip (${jobName['name']})',
                        //                                 style:
                        //                                     getBlackTextStyle(),
                        //                               ),
                        //                               content: Text(
                        //                                 'Are you sure you want to skip this process (${jobName['name']})?',
                        //                                 style:
                        //                                     getBlackTextStyle(),
                        //                               ),
                        //                               actions: [
                        //                                 TextButton(
                        //                                   onPressed: () =>
                        //                                       Navigator.of(
                        //                                               context)
                        //                                           .pop(), // Tutup dialog
                        //                                   child: const Text(
                        //                                       'Cancel'),
                        //                                 ),
                        //                                 ElevatedButton(
                        //                                   onPressed:
                        //                                       () async {
                        //                                     final oldData = await firestore
                        //                                         .collection(
                        //                                             FirestoreKey
                        //                                                 .tireRepairInspectionReport)
                        //                                         .where('id',
                        //                                             isEqualTo:
                        //                                                 data[
                        //                                                     'id'])
                        //                                         .get();
                        //                                     final jobcardData =
                        //                                         {
                        //                                       'name': jobName[
                        //                                           'name'],
                        //                                       'fulldate': DateTime
                        //                                               .now()
                        //                                           .toIso8601String(),
                        //                                       'date': DateFormat(
                        //                                               'dd-MM-yyyy')
                        //                                           .format(DateTime
                        //                                               .now()),
                        //                                       'material': [
                        //                                         {
                        //                                           'id_matstock':
                        //                                               '',
                        //                                           'name': '',
                        //                                           'qty': '',
                        //                                           'smu': '',
                        //                                         }
                        //                                       ],
                        //                                       'hours': '0',
                        //                                       'minutes': '0',
                        //                                       'bywhom': '',
                        //                                       'remarks': '',
                        //                                       'process_repair_count':
                        //                                           1,
                        //                                       'id_wo':
                        //                                           data['id'],
                        //                                       'dimensi': '',
                        //                                       'created_at':
                        //                                           DateTime.now()
                        //                                               .toIso8601String(),
                        //                                     };

                        //                                     await oldData
                        //                                         .docs[0]
                        //                                         .reference
                        //                                         .update({
                        //                                       'jobcard1':
                        //                                           FieldValue
                        //                                               .arrayUnion([
                        //                                         jobcardData
                        //                                       ]),
                        //                                     });

                        //                                     await ApiService
                        //                                         .postJobJobcardRepair(
                        //                                             jobcardData);
                        //                                     Navigator.of(
                        //                                             context)
                        //                                         .pop(); // Tutup dialog
                        //                                   },
                        //                                   child: const Text(
                        //                                       'Yes'),
                        //                                 ),
                        //                               ],
                        //                             );
                        //                           },
                        //                         );
                        //                       },
                        //                       style: TextButton.styleFrom(
                        //                         backgroundColor:
                        //                             const Color(0xFF35469B),
                        //                         padding: EdgeInsets.zero,
                        //                         shape: RoundedRectangleBorder(
                        //                           borderRadius:
                        //                               BorderRadius.circular(
                        //                                   12),
                        //                         ),
                        //                       ),
                        //                       child: const FittedBox(
                        //                         fit: BoxFit.scaleDown,
                        //                         child: Row(
                        //                           children: [
                        //                             Icon(
                        //                               Icons
                        //                                   .skip_next_outlined,
                        //                               color: Colors.white,
                        //                               size: 14,
                        //                             ),
                        //                             SizedBox(width: 2),
                        //                             Text(
                        //                               'Skip',
                        //                               style: TextStyle(
                        //                                 color: Colors.white,
                        //                                 fontSize: 10,
                        //                                 fontWeight:
                        //                                     FontWeight.bold,
                        //                               ),
                        //                             ),
                        //                           ],
                        //                         ),
                        //                       ),
                        //                     ),
                        //                   )
                        //               ],
                        //             ),
                        //             const SizedBox(
                        //               height: 12,
                        //             ),
                        //             (index < jobcardList.length)
                        //                 ? Column(
                        //                     crossAxisAlignment:
                        //                         CrossAxisAlignment.start,
                        //                     children: [
                        //                       Row(
                        //                         children: [
                        //                           const Icon(Icons
                        //                               .account_circle_outlined),
                        //                           const SizedBox(
                        //                             width: 6,
                        //                           ),
                        //                           Text(
                        //                             'Repairman : ' +
                        //                                 jobcardList[index]
                        //                                     ['bywhom'],
                        //                             style:
                        //                                 getBlackTextStyle(),
                        //                           ),
                        //                         ],
                        //                       ),
                        //                       const SizedBox(
                        //                         height: 14,
                        //                       ),
                        //                       Row(
                        //                         children: [
                        //                           const Icon(
                        //                               Icons.date_range),
                        //                           const SizedBox(
                        //                             width: 6,
                        //                           ),
                        //                           Text(
                        //                             'Date : ' +
                        //                                 jobcardList[index]
                        //                                     ['date'],
                        //                             style:
                        //                                 getBlackTextStyle(),
                        //                           ),
                        //                         ],
                        //                       ),
                        //                       const SizedBox(
                        //                         height: 14,
                        //                       ),
                        //                       Row(
                        //                         children: [
                        //                           const Icon(Icons.timer),
                        //                           const SizedBox(
                        //                             width: 6,
                        //                           ),
                        //                           Text(
                        //                             'Duration : ' +
                        //                                 '${(jobcardList[index]['hours'] == null || jobcardList[index]['hours'].isEmpty) ? '0' : jobcardList[index]['hours']} Hours  ${(jobcardList[index]['minutes'] == null || jobcardList[index]['minutes'].isEmpty) ? '0' : jobcardList[index]['minutes']} Minutes',
                        //                             style:
                        //                                 getBlackTextStyle(),
                        //                           ),
                        //                         ],
                        //                       ),
                        //                       if (jobcardList[index]
                        //                               ['name'] ==
                        //                           'Dimensi Luka')
                        //                         Column(
                        //                           children: [
                        //                             const SizedBox(
                        //                               height: 14,
                        //                             ),
                        //                             Text(
                        //                               '${formatDataDimensi(jobcardList[index]['dimensi'])}',
                        //                               style:
                        //                                   getBlackTextStyle(),
                        //                             ),
                        //                             const SizedBox(
                        //                               height: 14,
                        //                             ),
                        //                           ],
                        //                         )
                        //                       else
                        //                         Column(
                        //                           children: [
                        //                             const SizedBox(
                        //                               height: 14,
                        //                             ),
                        //                             Container(),
                        //                           ],
                        //                         ),
                        //                       Column(
                        //                         crossAxisAlignment:
                        //                             CrossAxisAlignment.start,
                        //                         children: [
                        //                           // 1. Cek dulu apakah list 'material' ada dan tidak kosong.
                        //                           // Pengecekan ini lebih aman daripada hanya memeriksa item pertama.
                        //                           if (jobcardList[index]
                        //                                       ['material'] !=
                        //                                   null &&
                        //                               (jobcardList[index]
                        //                                           ['material']
                        //                                       as List)
                        //                                   .isNotEmpty &&
                        //                               jobcardList[index]
                        //                                           ['material']
                        //                                       [0]['name'] !=
                        //                                   '')

                        //                             // 2. Gunakan spread operator `...` untuk memasukkan beberapa widget sekaligus jika kondisi true.
                        //                             ...[
                        //                             // Widget Judul "Material"
                        //                             Row(
                        //                               children: [
                        //                                 const Icon(
                        //                                     Icons.settings),
                        //                                 const SizedBox(
                        //                                     width: 6),
                        //                                 Text('Material',
                        //                                     style:
                        //                                         getBlackTextStyle()),
                        //                               ],
                        //                             ),

                        //                             // 3. Gunakan .asMap().entries.map() untuk membuat list material dengan index.
                        //                             ...(jobcardList[index]
                        //                                         ['material']
                        //                                     as List)
                        //                                 .asMap()
                        //                                 .entries
                        //                                 .map((entry) {
                        //                               final int itemIndex = entry
                        //                                   .key; // <- Ini adalah index dari item (0, 1, 2, ...)
                        //                               final dynamic item =
                        //                                   entry.value;

                        //                               return Padding(
                        //                                 padding: const EdgeInsets
                        //                                     .fromLTRB(8, 8, 8,
                        //                                     0), // Atur padding sesuai kebutuhan
                        //                                 child: Text(
                        //                                   // Gunakan itemIndex di sini, bukan index dari ListView.builder
                        //                                   '${itemIndex + 1}. ${item['name'] ?? ''} (Qty: ${item['qty'] ?? ''} ${item['smu'] ?? ''})',
                        //                                   style:
                        //                                       getBlackTextStyle(),
                        //                                 ),
                        //                               );
                        //                             }).toList(),
                        //                           ] else
                        //                             // 4. Blok `else` jika material kosong.
                        //                             Padding(
                        //                               padding:
                        //                                   const EdgeInsets
                        //                                       .all(8.0),
                        //                               child: Text(
                        //                                 'No Material.',
                        //                                 style: getBlackTextStyle()
                        //                                     .copyWith(
                        //                                         fontStyle:
                        //                                             FontStyle
                        //                                                 .italic),
                        //                               ),
                        //                             ),
                        //                         ],
                        //                       )
                        //                     ],
                        //                   )
                        //                 : Container(),
                        //           ],
                        //         ),
                        //     ],
                        //   ),
                        // ),
                      ),
                      const Divider(
                        thickness: 1.5,
                      )
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(12),
        color: (lastJob == 'Painting') ? grey6A707C : white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ButtonWidget(
                  color: (lastJob == 'Painting')
                      ? Colors.grey
                      : const Color(0xFF359B7B),
                  name: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                          (lastJob == 'Painting')
                              ? Icons.done_all
                              : Icons.add_circle,
                          color: Colors.white),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        (lastJob == 'Painting')
                            ? 'Repair Finished'
                            : 'Input Jobcard',
                        style: getWhiteTextStyle(fontWeight: w700),
                      ),
                    ],
                  ),
                  function: (lastJob == 'Painting')
                      ? null
                      : () async {
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
                        }),
            ),
          ],
        ),
      ),
    );
  }
}
