import 'dart:developer';

import 'package:camos/core/services/model/outstanding_task.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/check_box_modal_widget.dart';
import 'package:camos/core/widgets/oustandingtask_tile_widget.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class TireInspectionPage extends StatefulWidget {
  static const routeName = '/tire-inspection-page';
  TireInspectionPage({super.key});

  @override
  State<TireInspectionPage> createState() => _TireInspectionPageState();
}

class _TireInspectionPageState extends State<TireInspectionPage> {
  final HomeState homeController = Get.find<HomeState>();

  List<Map<String, dynamic>> filteredItemTask = [];
  String? _selectedSite; // Menyimpan nilai yang dipilih

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  TextEditingController searchTaskController = TextEditingController();
  String searchTaskText = '';

  bool isAccessed = true;
  bool isExporting = false;
  double exportProgress = 0.0;

  List<CheckBoxModalWidget> checkBoxList = [];
  List<String> checkBoxTitleSelected = [];
  final allChecked = CheckBoxModalWidget(title: 'All');

  String formatDate(String dateStr) {
    // Parsing string ke dalam DateTime
    DateTime date = DateTime.parse(dateStr);

    // Format tanggal sesuai keinginan
    String formattedDate = DateFormat('d MMMM yyyy', 'id_ID').format(date);

    return formattedDate;
  }

  setUniqueDate(List<String> dates) {
    checkBoxList.clear();
    List<String> uniqDateList = [];
    // print('hahaha $dates');
    dates.forEach((item) {
      final splitData = item.split('T');
      uniqDateList.add(splitData[0]);
    });
    // mengurutkan dari tanggal terbaru
    final nonParsedDates = Set<String>.from(uniqDateList);
    final List<DateTime> parsedDates =
        nonParsedDates.map((dateString) => DateTime.parse(dateString)).toList();
    parsedDates.sort((a, b) => b.compareTo(a));

    final Set<String> uniqDatesSet =
        Set<String>.from(parsedDates.map((date) => date.toString()));

    print('tanggal unik : $uniqDatesSet');
    uniqDatesSet.forEach((element) {
      final date = formatDateTime(DateTime.parse(element));
      checkBoxList.add(CheckBoxModalWidget(title: date));
    });
  }

  onAllClicked(CheckBoxModalWidget ckbItem) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    checkBoxTitleSelected.clear();
    final newValue = !ckbItem.value;

    ckbItem.value = newValue;
    checkBoxList.forEach((element) {
      element.value = newValue;
    });

    if (ckbItem.value) {
      // checkBoxTitleSelected.add(ckbItem.title);
      checkBoxList.forEach((element) {
        checkBoxTitleSelected.add(element.title);
      });
    } else {
      checkBoxTitleSelected.clear();
      // checkBoxTitleSelected.removeWhere((element) {
      //   return element == ckbItem.title;
      // });
    }
    print('tercentang : $checkBoxTitleSelected');
  }

  onItemClicked(CheckBoxModalWidget ckbItem) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    final newValue = !ckbItem.value;

    ckbItem.value = newValue;

    if (!newValue) {
      allChecked.value = false;
    } else {
      final allListChecked = checkBoxList.every((element) => element.value);
      allChecked.value = allListChecked;
    }

    if (ckbItem.value) {
      checkBoxTitleSelected.add(ckbItem.title);
    } else {
      checkBoxTitleSelected.removeWhere((element) {
        return element == ckbItem.title;
      });
    }
    print('tercentang2 : $checkBoxTitleSelected');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tire Inspection Result',
                  style: getGreenTextStyle(fontWeight: w700, fontSize: 20),
                ),
                const SizedBox(
                  height: 24,
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isExporting
                        ? null
                        : () async {
                            setState(() {
                              isExporting = true;
                              exportProgress = 0.1;
                            });

                            try {
                              final id = Uuid();

                              // 1️⃣ Sorting data
                              await Future.delayed(
                                  const Duration(milliseconds: 300));
                              setState(() => exportProgress = 0.3);

                              filteredItemTask.sort((a, b) {
                                DateTime dateA =
                                    DateTime.parse(a['last_update']);
                                DateTime dateB =
                                    DateTime.parse(b['last_update']);
                                return dateB.compareTo(dateA);
                              });

                              // 2️⃣ Create folder
                              await Future.delayed(
                                  const Duration(milliseconds: 300));
                              setState(() => exportProgress = 0.45);

                              final file = await createFolderPath(
                                id.v4(),
                                'outstanding',
                                email: auth.currentUser?.email ?? '',
                                site: filteredItemTask.isNotEmpty
                                    ? filteredItemTask[0]['id_site']
                                    : 'default_site',
                              );

                              // 3️⃣ Generate Excel
                              setState(() => exportProgress = 0.65);
                              final bytes = await createExcel(
                                'outstanding',
                                task: filteredItemTask,
                              );

                              // 4️⃣ Write file
                              setState(() => exportProgress = 0.85);
                              await file.writeAsBytes(bytes, flush: true);

                              // 5️⃣ Done
                              setState(() => exportProgress = 1.0);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: green00968A,
                                  content: Text(
                                    'Successfull Save Data!',
                                    style: getWhiteTextStyle(),
                                  ),
                                ),
                              );

                              await OpenFile.open(file.path);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text('Export failed: $e'),
                                ),
                              );
                            } finally {
                              await Future.delayed(
                                  const Duration(milliseconds: 500));
                              setState(() {
                                isExporting = false;
                                exportProgress = 0.0;
                              });
                            }
                          },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isExporting) ...[
                            LinearProgressIndicator(
                              value: exportProgress,
                              minHeight: 6,
                              backgroundColor: Colors.grey.shade300,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Exporting ${(exportProgress * 100).toInt()}%',
                              style: getBlackTextStyle(),
                            ),
                          ] else ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.table_chart),
                                const SizedBox(width: 12),
                                Text(
                                  'Export to Excel',
                                  style: getBlackTextStyle(),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                TextField(
                  controller: searchTaskController,
                  onChanged: (value) {
                    setState(() {
                      searchTaskText = value;
                    });
                  },
                  decoration: InputDecoration(
                      hintText: 'Search... (Unit Number)',
                      hintStyle: getGreyTextStyle(grey8391A1),
                      prefixIcon: Icon(Icons.search)),
                ),
                const SizedBox(
                  height: 12,
                ),
                StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('task')
                        .where('id_site',
                            isEqualTo: (_selectedSite != null)
                                ? _selectedSite
                                : homeController.currentSiteId)
                        .where('is_done', isEqualTo: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      List<DocumentSnapshot> docs = snapshot.data!.docs;

                      final listTaskDate = docs.map((element) {
                        final elementMap =
                            element.data() as Map<String, dynamic>;
                        return elementMap['last_update'] as String;
                      }).toList();

                      if (isAccessed) {
                        setUniqueDate(listTaskDate);
                        onAllClicked(allChecked);
                        isAccessed = false;
                      }

                      DateFormat inputFormat =
                          DateFormat('EEEE, d MMMM y, H:m:s');

                      final formatedDates = checkBoxTitleSelected.map((date) {
                        DateTime inputDate = inputFormat.parse(date);
                        DateFormat outputFormat =
                            DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSSSSS");
                        String outputDateString =
                            outputFormat.format(inputDate);
                        List<String> splittedDate = outputDateString.split('T');
                        return splittedDate[0];
                      }).toList();

                      List<DocumentSnapshot<Object?>> filteredTask =
                          docs.where((task) {
                        List<String> splittedDate =
                            task['last_update'].split('T');
                        return formatedDates.contains(splittedDate[0]);
                      }).toList();

                      // untuk data export excel
                      filteredItemTask.clear();
                      filteredTask.forEach((item) {
                        Map<String, dynamic> cast =
                            item.data() as Map<String, dynamic>;
                        // cast['id_site'] = siteName;
                        filteredItemTask.add(cast);
                      });

                      // filter berdasarkan tanggal input data
                      filteredTask.sort((a, b) {
                        Map<String, dynamic> first =
                            a.data() as Map<String, dynamic>;
                        Map<String, dynamic> second =
                            b.data() as Map<String, dynamic>;
                        ;
                        // Ambil nilai last_update dari masing-masing DocumentSnapshot
                        DateTime timeA = DateTime.parse(first['last_update']);
                        DateTime timeB = DateTime.parse(second['last_update']);

                        // Bandingkan waktu last_update dari kedua DocumentSnapshot
                        return timeB.compareTo(
                            timeA); // Dari yang terbaru ke yang terlama
                      });

                      // pencarian data berdasarkan id unit
                      if (searchTaskText.length > 0) {
                        filteredTask = filteredTask.where((element) {
                          return element
                              .get('unit')
                              .toString()
                              .toLowerCase()
                              .contains(searchTaskText.toLowerCase());
                        }).toList();
                      }

                      // (didalam widget berisi 1 Unit menampilkan 6 tire sekaligus)
                      // Map<String, dynamic> groupedData = {};

                      // for (var doc in filteredTask) {
                      //   var item = doc.data() as Map<String, dynamic>;
                      //   String unit = item['unit'];

                      //   if (groupedData.containsKey(unit)) {
                      //     groupedData[unit]['data'].add(item);
                      //   } else {
                      //     groupedData[unit] = {
                      //       'unit': unit,
                      //       'data': [item]
                      //     };
                      //   }
                      // }

                      // hasilnya
                      // List<Map<String, dynamic>> result = groupedData
                      //     .values
                      //     .map((e) => e as Map<String, dynamic>)
                      //     .toList();

                      // final allData = snapshot.data?.docs
                      //     .map((doc) => OutstandingTask.fromFirestore(
                      //         doc.data() as Map<String, dynamic>))
                      //     .toList();

                      final allData =
                          snapshot.data?.docs.map((doc) => doc.data()).toList();

                      log('tire inspection all data : ${allData![0]}');

                      // final distinctDaily =
                      //     Set<OutstandingTask>.from(allData ?? [])
                      //         .toList();

                      // final dailyData = distinctDaily;

                      // filteredItemTask.clear();
                      // filteredItemTask.clear();

                      // dailyData.forEach((item) {
                      //   Map<String, dynamic> cast = item.toFirestore();
                      //   filteredItemTask.add(cast);
                      // });

                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              showModalBottomSheet(
                                  isScrollControlled: true,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return SingleChildScrollView(
                                        child: Padding(
                                      padding: EdgeInsets.only(
                                          bottom: MediaQuery.of(context)
                                              .viewInsets
                                              .bottom),
                                      child: StatefulBuilder(
                                        builder:
                                            (BuildContext context, setState) {
                                          return Container(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 16),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16.0),
                                                  child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                        'Filter Outstanding Task',
                                                        style:
                                                            getBlackTextStyle(),
                                                      ),
                                                      GestureDetector(
                                                          onTap: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child:
                                                              Icon(Icons.clear))
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 8,
                                                ),
                                                ListTile(
                                                  onTap: () {
                                                    Future.microtask(() {
                                                      setState(() {
                                                        onAllClicked(
                                                            allChecked);
                                                      });
                                                    });
                                                  },
                                                  leading: Checkbox(
                                                    value: allChecked.value,
                                                    onChanged: (value) {
                                                      Future.microtask(() {
                                                        setState(() {
                                                          onAllClicked(
                                                              allChecked);
                                                        });
                                                      });
                                                    },
                                                  ),
                                                  title: Text(
                                                    'All',
                                                    style: getBlackTextStyle(),
                                                  ),
                                                ),

                                                // check box list tidak muncul
                                                ...checkBoxList.map((item) {
                                                  return ListTile(
                                                    onTap: () {
                                                      Future.microtask(() {
                                                        setState(() {
                                                          onItemClicked(item);
                                                        });
                                                      });
                                                    },
                                                    leading: Checkbox(
                                                      value: item.value,
                                                      onChanged: (value) {
                                                        Future.microtask(() {
                                                          setState(() {
                                                            onItemClicked(item);
                                                          });
                                                        });
                                                      },
                                                    ),
                                                    title: Text(
                                                      item.title,
                                                      style:
                                                          getBlackTextStyle(),
                                                    ),
                                                  );
                                                }),
                                                // ButtonWidget(
                                                //     name:
                                                //         Text('Save'),
                                                //     function: () {
                                                //       setState(() {});
                                                //     })
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ));
                                  });
                            },
                            child: Container(
                              // height: 40,
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(10, 6, 7.5, 6),
                              margin: EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.all(
                                  Radius.circular(8),
                                ),
                                border: Border.all(
                                  color: const Color(0xff313131),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Builder(builder: (context) {
                                    final formated =
                                        checkBoxTitleSelected.map((title) {
                                      String inputDateString = title;
                                      DateFormat inputFormat =
                                          DateFormat('EEEE, d MMMM y, H:m:s');
                                      DateTime inputDate =
                                          inputFormat.parse(inputDateString);

                                      DateFormat outputFormat =
                                          DateFormat("EEEE, d MMMM y");
                                      return outputFormat.format(inputDate);
                                    }).toList();
                                    return Text(
                                      (allChecked.value)
                                          ? 'All'
                                          : '${formated.join('\n')}',
                                      style: getBlackTextStyle(),
                                    );
                                  }),
                                  Container(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Transform.rotate(
                                      angle: (22 / 7) / -2,
                                      child: const Icon(
                                        Icons.arrow_back_ios,
                                        color: Color(0xffC5C6C6),
                                        size: 15,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          ButtonWidget(
                            name: Text(
                              'See Inspector',
                              style: getWhiteTextStyle(),
                            ),
                            function: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  // Mengelompokkan data berdasarkan tanggal
                                  final groupedTasks = <String, List<String>>{};

                                  filteredTask.forEach((task) {
                                    final taskData =
                                        task.data() as Map<String, dynamic>;
                                    final user = taskData['user'];

                                    // Parsing last_update dan mengambil hanya tanggal
                                    final DateTime lastUpdate =
                                        DateTime.parse(taskData['last_update']);
                                    final String formattedDate = formatDate(
                                        lastUpdate.toIso8601String());

                                    if (groupedTasks
                                        .containsKey(formattedDate)) {
                                      if (!groupedTasks[formattedDate]!
                                          .contains(user)) {
                                        groupedTasks[formattedDate]!.add(user);
                                      }
                                    } else {
                                      groupedTasks[formattedDate] = [user];
                                    }
                                  });

                                  return AlertDialog(
                                    title: Text('Inspector'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children:
                                            groupedTasks.entries.map((entry) {
                                          final date = entry.key;
                                          final users = entry.value;

                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                date,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                              ...users
                                                  .map((user) => Text(user))
                                                  .toList(),
                                              SizedBox(
                                                  height:
                                                      10), // Spacer untuk jarak antar tanggal
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('OK'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            color: blue344BEF,
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          ListView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemCount: filteredTask.length,
                              // itemCount: filteredTask.length,
                              itemBuilder: (context, index) {
                                Map<String, dynamic> task = filteredTask[index]
                                    .data() as Map<String, dynamic>;

                                // return OustandingTileWidget(
                                //   task: result[index]['data'],
                                // );

                                return OustandingTileWidget(
                                    task: OutstandingTask(
                                  id: task['id'] ?? '',
                                  idSite: task['id_site'] ?? '',
                                  user: task['user'] ?? '',
                                  userEmail: task['user_email'] ?? '',
                                  unit: task['unit'] ?? '',
                                  serialNumber: task['serial_number'] ?? '',
                                  condition: (task['condition'] != null)
                                      ? List<String>.from(task['condition'].map(
                                          (condition) => condition.toString()))
                                      : [],
                                  tireSize: task['tire_size'] ?? '',
                                  hm: task['hm'] ?? '',
                                  position: task['position'] is String
                                      ? int.tryParse(task['position']) ?? 0
                                      : task['position'] ?? 0,
                                  brand: task['brand'] ?? '',
                                  tireDamage:
                                      task['tire_damage'] is List<dynamic>
                                          ? task['tire_damage'].join(', ')
                                          : task['tire_damage'],
                                  remarks: task['remarks'] ?? '',
                                  rtd: task['rtd'] ?? '',
                                  pressure: task['pressure'] ?? '',
                                  adjusmentPressure:
                                      task['adjusmentPressure'] ?? '',
                                  lastUpdate: task['last_update'] ?? '',
                                  isDone: task['is_done'] ?? '',
                                  sn: task['sn'] ?? '',
                                  kunciUnit: task['kunci_unit'] ?? '',
                                  kunciTire: task['kunci_tire'] ?? '',
                                  images: (task['images'] as List<dynamic>?)
                                          ?.whereType<String>()
                                          .toList() ??
                                      [],
                                ));
                              }),
                        ],
                      );
                    }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'tire_inspection_state.dart';

// class TireInspectionPage extends StatelessWidget {
//   final TireInspectionState controller = Get.put(TireInspectionState());
//   final TextEditingController searchController = TextEditingController();

//   TireInspectionPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Tire Inspection Report'),
//         backgroundColor: const Color(0xFF009688),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             // 🔍 Search Field
//             TextField(
//               controller: searchController,
//               onChanged: (value) {
//                 controller.searchQuery.value = value;
//                 controller.applyFilters();
//               },
//               decoration: InputDecoration(
//                 hintText: 'Search unit...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 12),

//             // 📅 Filter by Date Range
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.teal,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                     ),
//                     icon: const Icon(Icons.date_range, color: Colors.white),
//                     label: const Text(
//                       'Select Date Range',
//                       style: TextStyle(color: Colors.white),
//                     ),
//                     onPressed: () async {
//                       final picked = await showDateRangePicker(
//                         context: context,
//                         firstDate: DateTime(2024, 1, 1),
//                         lastDate: DateTime.now(),
//                       );
//                       if (picked != null) {
//                         controller.selectedDateRange.value = picked;
//                         controller.applyFilters();
//                       }
//                     },
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 IconButton(
//                   icon: const Icon(Icons.refresh),
//                   onPressed: () async {
//                     searchController.clear();
//                     controller.searchQuery.value = '';
//                     controller.selectedDateRange.value = null;
//                     await controller.fetchTasks();
//                   },
//                 ),
//               ],
//             ),

//             const SizedBox(height: 12),

//             // 📋 List of Tasks
//             Expanded(
//               child: Obx(() {
//                 if (controller.isLoading.value && controller.tasks.isEmpty) {
//                   return const Center(child: CircularProgressIndicator());
//                 }

//                 if (controller.filteredTasks.isEmpty) {
//                   return const Center(child: Text('No tasks found.'));
//                 }

//                 return RefreshIndicator(
//                     onRefresh: controller.fetchTasks,
//                     child: ListView.builder(
//                       itemCount: controller.filteredTasks.length,
//                       itemBuilder: (context, index) {
//                         final task = controller.filteredTasks[index];

//                         // 🔹 Bungkus tiap card pakai Obx supaya UI-nya reactive
//                         return Obx(() {
//                           final isExpanded =
//                               controller.expandedIndex.value == index;

//                           return Card(
//                             color: const Color(0xFF009688),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(16),
//                             ),
//                             margin: const EdgeInsets.only(bottom: 12),
//                             child: InkWell(
//                               onTap: () {
//                                 controller.expandedIndex.value =
//                                     isExpanded ? -1 : index;
//                               },
//                               child: Padding(
//                                 padding: const EdgeInsets.all(16),
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     // Title row
//                                     Row(
//                                       mainAxisAlignment:
//                                           MainAxisAlignment.spaceBetween,
//                                       children: [
//                                         Text(
//                                           task['unit'] ?? '-',
//                                           style: const TextStyle(
//                                               fontSize: 18,
//                                               fontWeight: FontWeight.bold,
//                                               color: Colors.white),
//                                         ),
//                                         Icon(
//                                           isExpanded
//                                               ? Icons.expand_less
//                                               : Icons.expand_more,
//                                           color: Colors.white,
//                                         ),
//                                       ],
//                                     ),

//                                     // Detail section muncul kalau expanded
//                                     if (isExpanded) ...[
//                                       const SizedBox(height: 8),
//                                       _detailRow("Pressure",
//                                           "${task['pressure']} Psi"),
//                                       _detailRow("RTD", "${task['rtd']}"),
//                                       _detailRow(
//                                           "Tire Size", "${task['tire_size']}"),
//                                       _detailRow("Tire Damage",
//                                           "${task['tire_damage']}"),
//                                       _detailRow(
//                                           "Remarks", "${task['remarks']}"),
//                                       _detailRow("Date", "${task['date']}"),
//                                     ],
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           );
//                         });
//                       },
//                     ));
//               }),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _detailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(top: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label,
//               style: const TextStyle(color: Colors.white70, fontSize: 14)),
//           Text(value,
//               style: const TextStyle(color: Colors.white, fontSize: 14)),
//         ],
//       ),
//     );
//   }
// }
