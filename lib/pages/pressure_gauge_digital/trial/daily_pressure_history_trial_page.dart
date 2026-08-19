import 'dart:developer';

import '../../../core/services/api_service.dart';
import '../../../core/services/model/unit_tire.dart';
import '../../../core/services/shared_preferences/shared_preferences.dart';
import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/functions/functions.dart';
import '../../../core/widgets/appbar_widget.dart';
import '../widget/enum_export_type.dart';
import '../widget/export_excel_button.dart';
import '../widget/select_pit_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class DailyPressureHistoryTrialPage extends StatefulWidget {
  static const routeName = '/daily-pressure-history-trial-page';
  const DailyPressureHistoryTrialPage({super.key});

  @override
  State<DailyPressureHistoryTrialPage> createState() =>
      _DailyPressureHistoryTrialPageState();
}

class _DailyPressureHistoryTrialPageState
    extends State<DailyPressureHistoryTrialPage> {
  DateTime selectedDate = DateTime.now().subtract(Duration(days: 1));
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String searchQuery = '';
  String idSite = '';
  List<String> pit = [];
  int selectedPit = 0;
  List<Map<String, dynamic>> filteredItemTask = [];
  Map<String, dynamic> user = {};
  List<UnitTire> units = [];

  @override
  void initState() {
    super.initState();

    final yesterday = DateTime.now().subtract(Duration(days: 1));
    String formattedDate =
        "${yesterday.year}-${(yesterday.month).toString().padLeft(2, '0')}-${(yesterday.day).toString().padLeft(2, '0')}";
    log('tanggal kemarin : $formattedDate');
    getIdSite();
    getUser();
  }

  Future<void> getUnits() async {
    // belum ganti bulan
    if (await getSavedMonthYear() ==
        "${DateTime.now().year}-${DateTime.now().month}") {
      units = await ApiService.getCachedUnits();
    } else {
      // sudah ganti bulan
      units = await ApiService.getUnits(idSite);
    }
  }

  getUser() async {
    user = await getUserPreferences();
    log('username : ${user}');
  }

  getIdSite() async {
    idSite = await getIdSitePreferences();
    log('id site history pama : $idSite');
    if (idSite == '1') {
      idSite = await getSelectedIdSitePreferences();
    }

    setState(() {
      // BMB COYYY
      // if (idSite == '52') {
      //   pit.add('All');
      //   pit.add('Utara');
      //   pit.add('Selatan');
      //   pit.add('RML');
      //   pit.add('WS');
      // }
    });
  }

  @override
  Widget build(BuildContext context) {
    getUnits();
    log('count unit : ${units.length}');
    pit.clear();
    if (idSite == '52') {
      pit.add('All');
      pit.add('Utara');
      pit.add('Selatan');
      pit.add('RML');
      pit.add('WS');
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          setState(() {
            selectedDate = DateTime.now().subtract(Duration(days: 1));
          });
        },
        icon: Icon(
          Icons.refresh,
          color: Colors.white,
        ),
        backgroundColor: Colors.red,
        label: Text(
          'Refresh',
          style: getWhiteTextStyle(),
        ),
      ),
      appBar: appBarWidget('History', context),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 12,
              ),
              child: DatePicker(
                DateTime.now().subtract(Duration(days: 31)),
                height: 100,
                width: 80,
                daysCount: 31,
                locale: 'id_ID',
                initialSelectedDate: DateTime.now().subtract(Duration(days: 1)),
                selectionColor: green00968A,
                selectedTextColor: white,
                onDateChange: (date) {
                  log('tanggal terpilih : $date');
                  setState(() {
                    selectedDate = date;
                  });
                },
                dateTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: grey6A707C,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                    hintText: 'Search... (Unit Number or Model)',
                    hintStyle: getGreyTextStyle(grey8391A1),
                    prefixIcon: Icon(Icons.search)),
              ),
            ),
            const SizedBox(
              height: 24,
            ),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: ExportExcelButton(
                    user: user,
                    pit: pit,
                    selectedPit: selectedPit,
                    filteredItemTask: filteredItemTask,
                    idSite: idSite,
                    type: ExportType.oneDay,
                    date:
                        "${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.year}")),

            const SizedBox(
              height: 12,
            ),
            StreamBuilder(
                stream: firestore
                    .collection('daily_pressure')
                    .where('tanggal',
                        isGreaterThanOrEqualTo: DateTime(selectedDate.year,
                                selectedDate.month, selectedDate.day)
                            .toIso8601String())
                    .where('tanggal',
                        isLessThanOrEqualTo: DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                23,
                                59,
                                59)
                            .toIso8601String())
                    .where('idSite', isEqualTo: idSite)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator.adaptive();
                  }
                  if (snapshot.connectionState == ConnectionState.active) {
                    final dailyData = snapshot.data?.docs ?? [];

                    // untuk data export excel
                    filteredItemTask.clear();
                    filteredItemTask.clear();
                    dailyData.forEach((item) {
                      Map<String, dynamic> cast =
                          item.data() as Map<String, dynamic>;

                      filteredItemTask.add(cast);
                    });

                    log('list selected 2 = ${dailyData.length}');

                    return Column(
                      children: [
                        Text(
                          'Total Unit : ${dailyData.length ?? 0}',
                          style: getBlackTextStyle(
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                      ],
                    );
                  }

                  return Container();
                }),
            const SizedBox(
              height: 12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: PaginateFirestore(
                  key: ValueKey(selectedDate),
                  query: firestore
                      .collection('daily_pressure')
                      .where('tanggal',
                          isGreaterThanOrEqualTo: DateTime(selectedDate.year,
                                  selectedDate.month, selectedDate.day)
                              .toIso8601String())
                      .where('tanggal',
                          isLessThanOrEqualTo: DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  23,
                                  59,
                                  59)
                              .toIso8601String())
                      .where('idSite', isEqualTo: idSite)
                      .orderBy('tanggal', descending: true),
                  itemBuilderType: PaginateBuilderType.listView,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemsPerPage: 10,
                  isLive: true,
                  initialLoader:
                      const Center(child: CircularProgressIndicator.adaptive()),
                  bottomLoader:
                      const Center(child: CircularProgressIndicator.adaptive()),
                  itemBuilder: (context, snapshot, index) {
                    log('hahaha');
                    log('pama pressure list : ${snapshot.length}');

                    final Map<String, dynamic> dailyMap =
                        snapshot[index].data() as Map<String, dynamic>;
                    final positionList = dailyMap['posisi'] as List<dynamic>;

                    if (searchQuery.isNotEmpty &&
                        !dailyMap['unit']!
                            .toLowerCase()
                            .contains(searchQuery)) {
                      return Container();
                    }

                    return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: green00968A,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 24),
                          decoration: BoxDecoration(
                            color: green00968A,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ExpansionTile(
                            tilePadding: EdgeInsets.zero,
                            childrenPadding: EdgeInsets.all(0),
                            title: Row(
                              children: [
                                Icon(
                                  Icons.task,
                                  color: white,
                                  size: 36,
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  dailyMap['unit'] +
                                      '${((dailyMap['pit'] != 'Default') ? '\n' + dailyMap['pit'] : '')}',
                                  style: getWhiteTextStyle(
                                      fontWeight: w700, fontSize: 18),
                                )
                              ],
                            ),
                            trailing: SizedBox(
                              width: 90,
                              child: Icon(Icons.arrow_drop_down),
                            ),
                            children: [
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Name',
                                    style: getWhiteTextStyle(fontSize: 18),
                                  ),
                                  Container(
                                    width: 250,
                                    child: Text(
                                      dailyMap['user'] ?? 'No Name',
                                      textAlign: TextAlign.end,
                                      style: getWhiteTextStyle(
                                          fontWeight: w700, fontSize: 18),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Tanggal',
                                    style: getWhiteTextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    dailyMap['tanggal'].split('T')[0],
                                    style: getWhiteTextStyle(
                                        fontWeight: w700, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Waktu',
                                    style: getWhiteTextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    dailyMap['tanggal']
                                        .split('T')[1]
                                        .substring(0, 5),
                                    style: getWhiteTextStyle(
                                        fontWeight: w700, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'HM Unit',
                                    style: getWhiteTextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    dailyMap['hm'],
                                    style: getWhiteTextStyle(
                                        fontWeight: w700, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Pit',
                                    style: getWhiteTextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    dailyMap['pit'],
                                    style: getWhiteTextStyle(
                                        fontWeight: w700, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Column(
                                children: positionList.map((pl) {
                                  final plIndex = positionList.indexOf(pl);
                                  List<dynamic> luka = [];

                                  if (pl['luka'] != null &&
                                      pl['luka'] is! String) {
                                    luka = pl['luka'] as List<dynamic>;
                                  }

                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Pos. ${pl['pos']}',
                                            style:
                                                getWhiteTextStyle(fontSize: 18),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                children: [
                                                  Text(
                                                    '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
                                                    style: getWhiteTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: 18),
                                                  ),
                                                  (pl['adjusmentPressure'] !=
                                                              null &&
                                                          pl['adjusmentPressure'] !=
                                                              '0' &&
                                                          pl['adjusmentPressure'] !=
                                                              '')
                                                      ? Text(
                                                          '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
                                                          style:
                                                              getWhiteTextStyle(
                                                                  fontWeight:
                                                                      w700,
                                                                  fontSize: 18),
                                                        )
                                                      : Container(),
                                                ],
                                              ),
                                              (luka.isEmpty || luka == null)
                                                  ? Container()
                                                  : Text(
                                                      pl['luka'].join('\n'),
                                                      textAlign: TextAlign.end,
                                                      style: getWhiteTextStyle(
                                                          fontWeight: w700,
                                                          fontSize: 18),
                                                    ),
                                              const SizedBox(
                                                height: 12,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Divider(
                                        color: white,
                                        thickness: 1.5,
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ));
                  }),
            ),
            const SizedBox(
              height: 24,
            ),

            // StreamBuilder(
            //     stream: firestore.collection('daily_pressure').snapshots(),
            //     builder: (context, snapshot) {
            //       if (snapshot.connectionState == ConnectionState.waiting) {
            //         return CircularProgressIndicator();
            //       }

            //       List<DocumentSnapshot> documents = snapshot.data!.docs;

            //       if (searchQuery.length > 0) {
            //         documents = documents.where((element) {
            //           return element
            //               .get('unit')
            //               .toString()
            //               .toLowerCase()
            //               .contains(searchQuery.toLowerCase());
            //         }).toList();
            //       }

            //       final filteredDocument = documents.where((doc) {
            //         final Map<String, dynamic> data =
            //             doc.data() as Map<String, dynamic>;

            //         final dateString = data['tanggal'] as String;
            //         final dateTime = DateTime.parse(dateString);

            //         // Get date part from DateTime object
            //         DateTime dateOnly =
            //             DateTime(dateTime.year, dateTime.month, dateTime.day);

            //         // Format date as desired
            //         String formattedDate =
            //             "${dateOnly.year}-${(dateOnly.month).toString().padLeft(2, '0')}-${(dateOnly.day).toString().padLeft(2, '0')}";
            //         final formattedDateTime = DateTime.parse(formattedDate);

            //         // pilih all pit
            //         if (pit.isNotEmpty) {
            //           if (pit[selectedPit] == 'All') {
            //             return dateTime.year == selectedDate.year &&
            //                 dateTime.month == selectedDate.month &&
            //                 dateTime.day == selectedDate.day &&
            //                 data['idSite'] == idSite;
            //           }

            //           // ada pit
            //           if (data['pit'] != 'Default') {
            //             return dateTime.year == selectedDate.year &&
            //                 dateTime.month == selectedDate.month &&
            //                 dateTime.day == selectedDate.day &&
            //                 data['idSite'] == idSite &&
            //                 data['pit'] == pit[selectedPit];
            //           }
            //         }

            //         // tidak ada pit
            //         return formattedDateTime.year == selectedDate.year &&
            //             formattedDateTime.month == selectedDate.month &&
            //             data['idSite'] == idSite &&
            //             formattedDateTime.day == selectedDate.day;
            //       }).toList();

            //       filteredDocument.sort((a, b) {
            //         Map<String, dynamic> first =
            //             a.data() as Map<String, dynamic>;
            //         Map<String, dynamic> second =
            //             b.data() as Map<String, dynamic>;
            //         ;
            //         // Ambil nilai last_update dari masing-masing DocumentSnapshot
            //         DateTime timeA = DateTime.parse(first['tanggal']);
            //         DateTime timeB = DateTime.parse(second['tanggal']);

            //         // Bandingkan waktu last_update dari kedua DocumentSnapshot
            //         return timeB
            //             .compareTo(timeA); // Dari yang terbaru ke yang terlama
            //       });

            //       // untuk data export excel
            //       filteredItemTask.clear();
            //       filteredDocument.forEach((item) {
            //         Map<String, dynamic> cast =
            //             item.data() as Map<String, dynamic>;

            //         units.removeWhere(
            //             (element) => element.unitNumber == cast['unit']);
            //         filteredItemTask.add(cast);
            //       });
            //       log('dailyexcel: $filteredItemTask');
            //       log('jumlah kendaraan : ${units.length}');

            //       return Column(
            //         children: [
            //           Padding(
            //             padding: const EdgeInsets.symmetric(horizontal: 12.0),
            //             child: Text(
            //               'Total Unit : ${filteredDocument.length}',
            //               style: getBlackTextStyle(
            //                 fontSize: 20,
            //               ),
            //             ),
            //           ),
            //           const SizedBox(
            //             height: 12,
            //           ),
            //           ListView.builder(
            //             shrinkWrap: true,
            //             physics: NeverScrollableScrollPhysics(),
            //             itemCount: filteredDocument.length,
            //             itemBuilder: (context, index) {
            //               final Map<String, dynamic> dailyMap =
            //                   filteredDocument[index].data()
            //                       as Map<String, dynamic>;
            //               final positionList =
            //                   dailyMap['posisi'] as List<dynamic>;

            //               log('subsub : $positionList');

            //               return Padding(
            //                 padding:
            //                     const EdgeInsets.symmetric(horizontal: 8.0),
            //                 child: Card(
            //                     elevation: 2,
            //                     shape: RoundedRectangleBorder(
            //                       borderRadius: BorderRadius.circular(12),
            //                     ),
            //                     color: green00968A,
            //                     child: Container(
            //                       width: double.infinity,
            //                       padding: EdgeInsets.symmetric(
            //                           horizontal: 12, vertical: 24),
            //                       decoration: BoxDecoration(
            //                         color: green00968A,
            //                         borderRadius: BorderRadius.circular(12),
            //                       ),
            //                       child: ExpansionTile(
            //                         tilePadding: EdgeInsets.zero,
            //                         childrenPadding: EdgeInsets.all(0),
            //                         title: Row(
            //                           children: [
            //                             Icon(
            //                               Icons.task,
            //                               color: white,
            //                               size: 36,
            //                             ),
            //                             const SizedBox(
            //                               width: 12,
            //                             ),
            //                             Text(
            //                               dailyMap['unit'] +
            //                                   '${((dailyMap['pit'] != 'Default') ? ' - ' + dailyMap['pit'] : '')}',
            //                               style: getWhiteTextStyle(
            //                                   fontWeight: w700, fontSize: 18),
            //                             )
            //                           ],
            //                         ),
            //                         trailing: SizedBox(
            //                           width: 90,
            //                           child: Icon(Icons.arrow_drop_down),
            //                         ),
            //                         children: [
            //                           const SizedBox(
            //                             height: 12,
            //                           ),
            //                           Row(
            //                             mainAxisAlignment:
            //                                 MainAxisAlignment.spaceBetween,
            //                             children: [
            //                               Text(
            //                                 'Name',
            //                                 style:
            //                                     getWhiteTextStyle(fontSize: 18),
            //                               ),
            //                               Container(
            //                                 width: 250,
            //                                 child: Text(
            //                                   dailyMap['user'] ?? 'No Name',
            //                                   textAlign: TextAlign.end,
            //                                   style: getWhiteTextStyle(
            //                                       fontWeight: w700,
            //                                       fontSize: 18),
            //                                 ),
            //                               ),
            //                             ],
            //                           ),
            //                           const SizedBox(
            //                             height: 12,
            //                           ),
            //                           Row(
            //                             mainAxisAlignment:
            //                                 MainAxisAlignment.spaceBetween,
            //                             children: [
            //                               Text(
            //                                 'Tanggal',
            //                                 style:
            //                                     getWhiteTextStyle(fontSize: 18),
            //                               ),
            //                               Text(
            //                                 dailyMap['tanggal'].split('T')[0],
            //                                 style: getWhiteTextStyle(
            //                                     fontWeight: w700, fontSize: 18),
            //                               ),
            //                             ],
            //                           ),
            //                           const SizedBox(
            //                             height: 12,
            //                           ),
            //                           Row(
            //                             mainAxisAlignment:
            //                                 MainAxisAlignment.spaceBetween,
            //                             children: [
            //                               Text(
            //                                 'Waktu',
            //                                 style:
            //                                     getWhiteTextStyle(fontSize: 18),
            //                               ),
            //                               Text(
            //                                 dailyMap['tanggal']
            //                                     .split('T')[1]
            //                                     .substring(0, 5),
            //                                 style: getWhiteTextStyle(
            //                                     fontWeight: w700, fontSize: 18),
            //                               ),
            //                             ],
            //                           ),
            //                           const SizedBox(
            //                             height: 12,
            //                           ),
            //                           Row(
            //                             mainAxisAlignment:
            //                                 MainAxisAlignment.spaceBetween,
            //                             children: [
            //                               Text(
            //                                 'HM Unit',
            //                                 style:
            //                                     getWhiteTextStyle(fontSize: 18),
            //                               ),
            //                               Text(
            //                                 dailyMap['hm'],
            //                                 style: getWhiteTextStyle(
            //                                     fontWeight: w700, fontSize: 18),
            //                               ),
            //                             ],
            //                           ),
            //                           const SizedBox(
            //                             height: 12,
            //                           ),
            //                           Row(
            //                             mainAxisAlignment:
            //                                 MainAxisAlignment.spaceBetween,
            //                             children: [
            //                               Text(
            //                                 'Pit',
            //                                 style:
            //                                     getWhiteTextStyle(fontSize: 18),
            //                               ),
            //                               Text(
            //                                 dailyMap['pit'],
            //                                 style: getWhiteTextStyle(
            //                                     fontWeight: w700, fontSize: 18),
            //                               ),
            //                             ],
            //                           ),
            //                           const SizedBox(
            //                             height: 12,
            //                           ),
            //                           Column(
            //                             children: positionList.map((pl) {
            //                               final plIndex =
            //                                   positionList.indexOf(pl);
            //                               List<dynamic> luka = [];

            //                               if (pl['luka'] != null &&
            //                                   pl['luka'] is! String) {
            //                                 luka = pl['luka'] as List<dynamic>;
            //                               }

            //                               return Column(
            //                                 children: [
            //                                   Row(
            //                                     mainAxisAlignment:
            //                                         MainAxisAlignment
            //                                             .spaceBetween,
            //                                     crossAxisAlignment:
            //                                         CrossAxisAlignment.center,
            //                                     children: [
            //                                       Text(
            //                                         'Pos. ${pl['pos']}',
            //                                         style: getWhiteTextStyle(
            //                                             fontSize: 18),
            //                                       ),
            //                                       Column(
            //                                         crossAxisAlignment:
            //                                             CrossAxisAlignment.end,
            //                                         mainAxisAlignment:
            //                                             MainAxisAlignment
            //                                                 .center,
            //                                         children: [
            //                                           Column(
            //                                             crossAxisAlignment:
            //                                                 CrossAxisAlignment
            //                                                     .end,
            //                                             children: [
            //                                               Text(
            //                                                 '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
            //                                                 style:
            //                                                     getWhiteTextStyle(
            //                                                         fontWeight:
            //                                                             w700,
            //                                                         fontSize:
            //                                                             18),
            //                                               ),
            //                                               (pl['adjusmentPressure'] !=
            //                                                           null &&
            //                                                       pl['adjusmentPressure'] !=
            //                                                           '0' &&
            //                                                       pl['adjusmentPressure'] !=
            //                                                           '')
            //                                                   ? Text(
            //                                                       '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
            //                                                       style: getWhiteTextStyle(
            //                                                           fontWeight:
            //                                                               w700,
            //                                                           fontSize:
            //                                                               18),
            //                                                     )
            //                                                   : Container(),
            //                                             ],
            //                                           ),
            //                                           (luka.isEmpty ||
            //                                                   luka == null)
            //                                               ? Container()
            //                                               : Text(
            //                                                   pl['luka']
            //                                                       .join('\n'),
            //                                                   textAlign:
            //                                                       TextAlign.end,
            //                                                   style:
            //                                                       getWhiteTextStyle(
            //                                                           fontWeight:
            //                                                               w700,
            //                                                           fontSize:
            //                                                               18),
            //                                                 ),
            //                                           const SizedBox(
            //                                             height: 12,
            //                                           ),
            //                                         ],
            //                                       ),
            //                                     ],
            //                                   ),
            //                                   Divider(
            //                                     color: white,
            //                                     thickness: 1.5,
            //                                   ),
            //                                 ],
            //                               );
            //                             }).toList(),
            //                           ),
            //                         ],
            //                       ),
            //                     )),
            //               );
            //             },
            //           ),
            //         ],
            //       );
            //     })
          ],
        ),
      )),
    );
  }
}
