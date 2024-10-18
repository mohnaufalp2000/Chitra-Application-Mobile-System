import 'dart:developer';

import 'package:camos/core/blocs/unit/unit_bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/export_excel_button.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/select_pit_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class DailyPressureHistoryPage extends StatefulWidget {
  static const routeName = '/daily-pressure-history-page';
  const DailyPressureHistoryPage({super.key});

  @override
  State<DailyPressureHistoryPage> createState() =>
      _DailyPressureHistoryPageState();
}

class _DailyPressureHistoryPageState extends State<DailyPressureHistoryPage> {
  DateTime selectedDate = DateTime.now().subtract(Duration(days: 1));
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String searchQuery = '';
  String idSite = '';
  List<String> pit = [];
  int selectedPit = 0;
  List<Map<String, dynamic>> filteredItemTask = [];
  Map<String, dynamic> user = {};
  List<UnitTire> units = [];
  int selectedMenu = 1;
  bool isOnline = false;

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

  // Future<void> getUnits() async {
  //   // belum ganti bulan
  //   if (await getSavedMonthYear() ==
  //       "${DateTime.now().year}-${DateTime.now().month}") {
  //     units = await ApiService.getCachedUnits();
  //   } else {
  //     // sudah ganti bulan
  //     units = await ApiService.getUnits(idSite);
  //   }
  // }

  Future<String> getActualIdSite() async {
    final actIdSite = await getIdSitePreferences();

    return actIdSite;
  }

  Future<void> getUnits() async {
    // jika user site ambil dari cache
    if (await getIdSitePreferences() != '1' &&
        await getIdSitePreferences() != '2') {
      //       // belum ganti bulan
      if (!isOnline) {
        units = await ApiService.getCachedUnits(
            idSite: await getIdSitePreferences());
      } else {
        units = await ApiService.getUnits(idSite);
      }
    } else {
      // jika user office tidak perlu ambil dari cache
      units = await ApiService.getUnits(idSite);
    }
  }

  getUser() async {
    user = await getUserPreferences();
    log('username : ${user}');
  }

  getIdSite() async {
    idSite = await getIdSitePreferences();
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
    // if (idSite == '52') {
    //   pit.add('All');
    //   pit.add('Utara');
    //   pit.add('Selatan');
    //   pit.add('RML');
    //   pit.add('WS');
    // }
    switch (idSite) {
      case '52':
        pit.add('All');
        pit.add('Utara');
        pit.add('Selatan');
        pit.add('RML');
        pit.add('WS');
        break;
      case '137':
        pit.add('All');
        pit.add('Japun');
        pit.add('PCE');
        break;
      case '35':
        pit.add('All');
        pit.add('Tabuhan');
        pit.add('EBL');
        pit.add('Workshop');
        break;
    }

    return Scaffold(
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
            const SizedBox(
              height: 12,
            ),
            FutureBuilder(
                future: getActualIdSite(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }

                  final data = snapshot.data;
                  log('id site future builder : $data');

                  if (data != '1' && data != '2' && data != '3') {
                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            isOnline = !isOnline; // Toggle the status
                            getUnits();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.fire_truck,
                              color: white,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              'Get Unit',
                              style: getWhiteTextStyle(),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Container();
                }),
            const SizedBox(
              height: 12,
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
              child: Builder(builder: (context) {
                if (selectedMenu == 0) {
                  return ExportExcelButton(
                    user: user,
                    pit: pit,
                    selectedPit: selectedPit,
                    filteredItemTask: filteredItemTask,
                    date:
                        "${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().year}",
                  );
                }
                return Container();
              }),
            ),
            const SizedBox(
              height: 12,
            ),
            BlocConsumer<UnitBloc, UnitState>(
                listener: (context, state) {},
                builder: (context, state) {
                  if (state is UnitLoadingState) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (state is UnitLoadedState) {
                    switch (selectedMenu) {
                      // Checked Unit
                      case 0:
                        return Column(
                          children: [
                            const SizedBox(
                              height: 12,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: SelectPitButton(
                                  pit: pit,
                                  selectedPit: selectedPit,
                                  onSelectedPitChanged: (index) {
                                    setState(() {
                                      selectedPit = index;
                                    });
                                  }),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            StreamBuilder(
                                stream: firestore
                                    .collection('daily_pressure')
                                    .where('tanggal',
                                        isGreaterThanOrEqualTo: DateTime(
                                                selectedDate.year,
                                                selectedDate.month,
                                                selectedDate.day)
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
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator.adaptive();
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.active) {
                                    final tmpDailyData =
                                        snapshot.data?.docs ?? [];

                                    final dailyData = tmpDailyData.where((doc) {
                                      final Map<String, dynamic> data =
                                          doc.data() as Map<String, dynamic>;

                                      // pilih all pit
                                      if (pit.isNotEmpty) {
                                        if (pit[selectedPit] == 'All') {
                                          return data['idSite'] == idSite;
                                        }

                                        // ada pit
                                        if (data['pit'] != 'Default') {
                                          return data['idSite'] == idSite &&
                                              data['pit'] == pit[selectedPit];
                                        }
                                      }

                                      // tidak ada pit
                                      return data['idSite'] == idSite;
                                    }).toList();

                                    // untuk data export excel
                                    filteredItemTask.clear();
                                    filteredItemTask.clear();
                                    dailyData.forEach((item) {
                                      Map<String, dynamic> cast =
                                          item.data() as Map<String, dynamic>;

                                      filteredItemTask.add(cast);
                                    });

                                    log('list selected 1 = ${tmpDailyData.length}');
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
                                        (snapshot.data?.size != 0)
                                            ? Column(
                                                children: [
                                                  Builder(builder: (context) {
                                                    // Parsing string to DateTime object
                                                    DateTime parsedDate =
                                                        DateTime.parse(snapshot
                                                            .data
                                                            ?.docs[snapshot
                                                                    .data!
                                                                    .size -
                                                                1]
                                                            .data()['tanggal']);

                                                    // Formatting DateTime to the desired format
                                                    String formattedDate =
                                                        DateFormat(
                                                                'HH:mm:ss dd-MM-yyyy')
                                                            .format(parsedDate);
                                                    return Text(
                                                      'Last Update : ${formattedDate}',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: getBlackTextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    );
                                                  }),
                                                  const SizedBox(
                                                    height: 12,
                                                  ),
                                                ],
                                              )
                                            : Container(),
                                      ],
                                    );
                                  }

                                  return Container();
                                }),
                            PaginateFirestore(
                                query: selectedPit == 0
                                    ? firestore
                                        .collection('daily_pressure')
                                        .where('tanggal',
                                            isGreaterThanOrEqualTo: DateTime(
                                                    selectedDate.year,
                                                    selectedDate.month,
                                                    selectedDate.day)
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
                                        .orderBy('tanggal', descending: true)
                                    : firestore
                                        .collection('daily_pressure')
                                        .where('tanggal',
                                            isGreaterThanOrEqualTo:
                                                DateTime(selectedDate.year, selectedDate.month, selectedDate.day).toIso8601String())
                                        .where('tanggal', isLessThanOrEqualTo: DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59).toIso8601String())
                                        .where('idSite', isEqualTo: idSite)
                                        .where('pit', isEqualTo: pit[selectedPit])
                                        .orderBy('tanggal', descending: true),
                                key: ValueKey(selectedDate),
                                itemBuilderType: PaginateBuilderType.listView,
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemsPerPage: 10,
                                isLive: true,
                                initialLoader: const Center(child: CircularProgressIndicator.adaptive()),
                                bottomLoader: const Center(child: CircularProgressIndicator.adaptive()),
                                itemBuilder: (context, snapshot, index) {
                                  final Map<String, dynamic> dailyMap =
                                      snapshot[index].data()
                                          as Map<String, dynamic>;
                                  final positionList =
                                      dailyMap['posisi'] as List<dynamic>;

                                  if (selectedPit != 0) {
                                    if (dailyMap['pit'] != pit[selectedPit]) {
                                      return Container();
                                    }
                                  }

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
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                                                    '${((dailyMap['pit'] != 'Default') ? ' - ' + dailyMap['pit'] : '')}',
                                                style: getWhiteTextStyle(
                                                    fontWeight: w700,
                                                    fontSize: 18),
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Name',
                                                  style: getWhiteTextStyle(
                                                      fontSize: 18),
                                                ),
                                                Container(
                                                  width: 250,
                                                  child: Text(
                                                    dailyMap['user'] ??
                                                        'No Name',
                                                    textAlign: TextAlign.end,
                                                    style: getWhiteTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: 18),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 12,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Tanggal',
                                                  style: getWhiteTextStyle(
                                                      fontSize: 18),
                                                ),
                                                Text(
                                                  dailyMap['tanggal']
                                                      .split('T')[0],
                                                  style: getWhiteTextStyle(
                                                      fontWeight: w700,
                                                      fontSize: 18),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 12,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Waktu',
                                                  style: getWhiteTextStyle(
                                                      fontSize: 18),
                                                ),
                                                Text(
                                                  dailyMap['tanggal']
                                                      .split('T')[1]
                                                      .substring(0, 5),
                                                  style: getWhiteTextStyle(
                                                      fontWeight: w700,
                                                      fontSize: 18),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 12,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'HM Unit',
                                                  style: getWhiteTextStyle(
                                                      fontSize: 18),
                                                ),
                                                Text(
                                                  dailyMap['hm'],
                                                  style: getWhiteTextStyle(
                                                      fontWeight: w700,
                                                      fontSize: 18),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 12,
                                            ),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Pit',
                                                  style: getWhiteTextStyle(
                                                      fontSize: 18),
                                                ),
                                                Text(
                                                  dailyMap['pit'],
                                                  style: getWhiteTextStyle(
                                                      fontWeight: w700,
                                                      fontSize: 18),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              height: 12,
                                            ),
                                            Column(
                                              children: positionList.map((pl) {
                                                final plIndex =
                                                    positionList.indexOf(pl);
                                                List<dynamic> luka = [];

                                                if (pl['luka'] != null &&
                                                    pl['luka'] is! String) {
                                                  luka = pl['luka']
                                                      as List<dynamic>;
                                                }

                                                return Column(
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        Text(
                                                          'Pos. ${pl['pos']}',
                                                          style:
                                                              getWhiteTextStyle(
                                                                  fontSize: 18),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .end,
                                                              children: [
                                                                Text(
                                                                  '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
                                                                  style: getWhiteTextStyle(
                                                                      fontWeight:
                                                                          w700,
                                                                      fontSize:
                                                                          18),
                                                                ),
                                                                (pl['adjusmentPressure'] != null &&
                                                                        pl['adjusmentPressure'] !=
                                                                            '0' &&
                                                                        pl['adjusmentPressure'] !=
                                                                            '')
                                                                    ? Text(
                                                                        '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
                                                                        style: getWhiteTextStyle(
                                                                            fontWeight:
                                                                                w700,
                                                                            fontSize:
                                                                                18),
                                                                      )
                                                                    : Container(),
                                                              ],
                                                            ),
                                                            (luka.isEmpty ||
                                                                    luka ==
                                                                        null)
                                                                ? Container()
                                                                : Text(
                                                                    pl['luka']
                                                                        .join(
                                                                            '\n'),
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                    style: getWhiteTextStyle(
                                                                        fontWeight:
                                                                            w700,
                                                                        fontSize:
                                                                            18),
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
                          ],
                        );
                      // Not Checked Unit
                      case 1:
                        final notChecked = [];
                        notChecked.clear();
                        notChecked.addAll(state.units);
                        return Column(
                          children: [
                            const SizedBox(
                              height: 12,
                            ),
                            StreamBuilder(
                                stream: firestore
                                    .collection('daily_pressure')
                                    .where('tanggal',
                                        isGreaterThanOrEqualTo: DateTime(
                                                selectedDate.year,
                                                selectedDate.month,
                                                selectedDate.day)
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
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator.adaptive();
                                  }
                                  if (snapshot.connectionState ==
                                      ConnectionState.active) {
                                    final dailyData = snapshot.data?.docs ?? [];

                                    // Mendapatkan field 'unit' dari setiap dokumen
                                    final unitList = dailyData
                                        .map((doc) => doc['unit'])
                                        .toList();

                                    // Mengecek apakah 'unitList' kosong, jika tidak kosong lanjutkan removeWhere
                                    unitList.isNotEmpty
                                        ? notChecked.removeWhere((element) =>
                                            unitList
                                                .contains(element.unitNumber))
                                        : [];

                                    return Column(
                                      children: [
                                        Text(
                                          'Total Unit : ${notChecked.length ?? 0}',
                                          style: getBlackTextStyle(
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        (snapshot.data?.size != 0)
                                            ? Column(
                                                children: [
                                                  Builder(builder: (context) {
                                                    // Parsing string to DateTime object
                                                    DateTime parsedDate =
                                                        DateTime.parse(snapshot
                                                            .data
                                                            ?.docs[snapshot
                                                                    .data!
                                                                    .size -
                                                                1]
                                                            .data()['tanggal']);

                                                    // Formatting DateTime to the desired format
                                                    String formattedDate =
                                                        DateFormat(
                                                                'HH:mm:ss dd-MM-yyyy')
                                                            .format(parsedDate);
                                                    return Text(
                                                      'Last Update : ${formattedDate}',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: getBlackTextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    );
                                                  }),
                                                  const SizedBox(
                                                    height: 12,
                                                  ),
                                                ],
                                              )
                                            : Container(),
                                        (notChecked == null ||
                                                notChecked.isEmpty)
                                            ? Text(
                                                'Empty!',
                                                textAlign: TextAlign.center,
                                                style: getBlackTextStyle(
                                                    fontSize: 18),
                                              )
                                            : Column(
                                                children:
                                                    (notChecked).map((unit) {
                                                  if (searchQuery.isNotEmpty &&
                                                      !unit.unitNumber!
                                                          .toLowerCase()
                                                          .contains(
                                                              searchQuery) &&
                                                      !unit.model!
                                                          .toLowerCase()
                                                          .contains(
                                                              searchQuery)) {
                                                    return Container();
                                                  }
                                                  return Container(
                                                    margin:
                                                        EdgeInsets.symmetric(
                                                            vertical: 8.0),
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withOpacity(0.1),
                                                          spreadRadius: 2,
                                                          blurRadius: 5,
                                                          offset: Offset(0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: ListTile(
                                                      leading: Icon(
                                                        Icons.front_loader,
                                                        color: Colors.orange,
                                                      ),
                                                      title: Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                bottom: 4.0),
                                                        child: Text(
                                                          '${unit.unitNumber}',
                                                          style:
                                                              getBlackTextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w700),
                                                        ),
                                                      ),
                                                      subtitle: Text(
                                                        '${unit.model}',
                                                        style: getGreyTextStyle(
                                                            grey6A707C),
                                                      ),
                                                      trailing: Icon(Icons
                                                          .arrow_forward_ios),
                                                    ),
                                                  );
                                                }).toList(),
                                              ),
                                      ],
                                    );
                                  }

                                  return Container();
                                }),
                            const SizedBox(
                              height: 12,
                            ),
                          ],
                        );
                    }
                  }
                  return Container();
                }),

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
            //               (selectedMenu == 0)
            //                   ? 'Total Unit : ${filteredDocument.length}'
            //                   : 'Total Unit : ${units.length}',
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
            //             itemCount: (selectedMenu == 0)
            //                 ? filteredDocument.length
            //                 : units.length,
            //             itemBuilder: (context, index) {
            //               if (selectedMenu == 0) {
            //                 final Map<String, dynamic> dailyMap =
            //                     filteredDocument[index].data()
            //                         as Map<String, dynamic>;
            //                 final positionList =
            //                     dailyMap['posisi'] as List<dynamic>;

            //                 log('subsub : $positionList');

            //                 return Padding(
            //                   padding:
            //                       const EdgeInsets.symmetric(horizontal: 8.0),
            //                   child: Card(
            //                       elevation: 2,
            //                       shape: RoundedRectangleBorder(
            //                         borderRadius: BorderRadius.circular(12),
            //                       ),
            //                       color: green00968A,
            //                       child: Container(
            //                         width: double.infinity,
            //                         padding: EdgeInsets.symmetric(
            //                             horizontal: 12, vertical: 24),
            //                         decoration: BoxDecoration(
            //                           color: green00968A,
            //                           borderRadius: BorderRadius.circular(12),
            //                         ),
            //                         child: ExpansionTile(
            //                           tilePadding: EdgeInsets.zero,
            //                           childrenPadding: EdgeInsets.all(0),
            //                           title: Row(
            //                             children: [
            //                               Icon(
            //                                 Icons.task,
            //                                 color: white,
            //                                 size: 36,
            //                               ),
            //                               const SizedBox(
            //                                 width: 12,
            //                               ),
            //                               Text(
            //                                 dailyMap['unit'] +
            //                                     '${((dailyMap['pit'] != 'Default') ? ' - ' + dailyMap['pit'] : '')}',
            //                                 style: getWhiteTextStyle(
            //                                     fontWeight: w700, fontSize: 18),
            //                               )
            //                             ],
            //                           ),
            //                           trailing: SizedBox(
            //                             width: 90,
            //                             child: Icon(Icons.arrow_drop_down),
            //                           ),
            //                           children: [
            //                             const SizedBox(
            //                               height: 12,
            //                             ),
            //                             Row(
            //                               mainAxisAlignment:
            //                                   MainAxisAlignment.spaceBetween,
            //                               children: [
            //                                 Text(
            //                                   'Name',
            //                                   style: getWhiteTextStyle(
            //                                       fontSize: 18),
            //                                 ),
            //                                 Container(
            //                                   width: 250,
            //                                   child: Text(
            //                                     dailyMap['user'] ?? 'No Name',
            //                                     textAlign: TextAlign.end,
            //                                     style: getWhiteTextStyle(
            //                                         fontWeight: w700,
            //                                         fontSize: 18),
            //                                   ),
            //                                 ),
            //                               ],
            //                             ),
            //                             const SizedBox(
            //                               height: 12,
            //                             ),
            //                             Row(
            //                               mainAxisAlignment:
            //                                   MainAxisAlignment.spaceBetween,
            //                               children: [
            //                                 Text(
            //                                   'Tanggal',
            //                                   style: getWhiteTextStyle(
            //                                       fontSize: 18),
            //                                 ),
            //                                 Text(
            //                                   dailyMap['tanggal'].split('T')[0],
            //                                   style: getWhiteTextStyle(
            //                                       fontWeight: w700,
            //                                       fontSize: 18),
            //                                 ),
            //                               ],
            //                             ),
            //                             const SizedBox(
            //                               height: 12,
            //                             ),
            //                             Row(
            //                               mainAxisAlignment:
            //                                   MainAxisAlignment.spaceBetween,
            //                               children: [
            //                                 Text(
            //                                   'Waktu',
            //                                   style: getWhiteTextStyle(
            //                                       fontSize: 18),
            //                                 ),
            //                                 Text(
            //                                   dailyMap['tanggal']
            //                                       .split('T')[1]
            //                                       .substring(0, 5),
            //                                   style: getWhiteTextStyle(
            //                                       fontWeight: w700,
            //                                       fontSize: 18),
            //                                 ),
            //                               ],
            //                             ),
            //                             const SizedBox(
            //                               height: 12,
            //                             ),
            //                             Row(
            //                               mainAxisAlignment:
            //                                   MainAxisAlignment.spaceBetween,
            //                               children: [
            //                                 Text(
            //                                   'HM Unit',
            //                                   style: getWhiteTextStyle(
            //                                       fontSize: 18),
            //                                 ),
            //                                 Text(
            //                                   dailyMap['hm'],
            //                                   style: getWhiteTextStyle(
            //                                       fontWeight: w700,
            //                                       fontSize: 18),
            //                                 ),
            //                               ],
            //                             ),
            //                             const SizedBox(
            //                               height: 12,
            //                             ),
            //                             Row(
            //                               mainAxisAlignment:
            //                                   MainAxisAlignment.spaceBetween,
            //                               children: [
            //                                 Text(
            //                                   'Pit',
            //                                   style: getWhiteTextStyle(
            //                                       fontSize: 18),
            //                                 ),
            //                                 Text(
            //                                   dailyMap['pit'],
            //                                   style: getWhiteTextStyle(
            //                                       fontWeight: w700,
            //                                       fontSize: 18),
            //                                 ),
            //                               ],
            //                             ),
            //                             const SizedBox(
            //                               height: 12,
            //                             ),
            //                             Column(
            //                               children: positionList.map((pl) {
            //                                 final plIndex =
            //                                     positionList.indexOf(pl);
            //                                 List<dynamic> luka = [];

            //                                 if (pl['luka'] != null &&
            //                                     pl['luka'] is! String) {
            //                                   luka =
            //                                       pl['luka'] as List<dynamic>;
            //                                 }

            //                                 return Column(
            //                                   children: [
            //                                     Row(
            //                                       mainAxisAlignment:
            //                                           MainAxisAlignment
            //                                               .spaceBetween,
            //                                       crossAxisAlignment:
            //                                           CrossAxisAlignment.center,
            //                                       children: [
            //                                         Text(
            //                                           'Pos. ${pl['pos']}',
            //                                           style: getWhiteTextStyle(
            //                                               fontSize: 18),
            //                                         ),
            //                                         Column(
            //                                           crossAxisAlignment:
            //                                               CrossAxisAlignment
            //                                                   .end,
            //                                           mainAxisAlignment:
            //                                               MainAxisAlignment
            //                                                   .center,
            //                                           children: [
            //                                             Column(
            //                                               crossAxisAlignment:
            //                                                   CrossAxisAlignment
            //                                                       .end,
            //                                               children: [
            //                                                 Text(
            //                                                   '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
            //                                                   style:
            //                                                       getWhiteTextStyle(
            //                                                           fontWeight:
            //                                                               w700,
            //                                                           fontSize:
            //                                                               18),
            //                                                 ),
            //                                                 (pl['adjusmentPressure'] !=
            //                                                             null &&
            //                                                         pl['adjusmentPressure'] !=
            //                                                             '0' &&
            //                                                         pl['adjusmentPressure'] !=
            //                                                             '')
            //                                                     ? Text(
            //                                                         '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
            //                                                         style: getWhiteTextStyle(
            //                                                             fontWeight:
            //                                                                 w700,
            //                                                             fontSize:
            //                                                                 18),
            //                                                       )
            //                                                     : Container(),
            //                                               ],
            //                                             ),
            //                                             (luka.isEmpty ||
            //                                                     luka == null)
            //                                                 ? Container()
            //                                                 : Text(
            //                                                     pl['luka']
            //                                                         .join('\n'),
            //                                                     textAlign:
            //                                                         TextAlign
            //                                                             .end,
            //                                                     style: getWhiteTextStyle(
            //                                                         fontWeight:
            //                                                             w700,
            //                                                         fontSize:
            //                                                             18),
            //                                                   ),
            //                                             const SizedBox(
            //                                               height: 12,
            //                                             ),
            //                                           ],
            //                                         ),
            //                                       ],
            //                                     ),
            //                                     Divider(
            //                                       color: white,
            //                                       thickness: 1.5,
            //                                     ),
            //                                   ],
            //                                 );
            //                               }).toList(),
            //                             ),
            //                           ],
            //                         ),
            //                       )),
            //                 );
            //               } else {
            //                 log('kendaraan di bmb ${units.length}');
            //                 final item = units[index];
            //                 if (searchQuery.isNotEmpty &&
            //                     !item.unitNumber!
            //                         .toLowerCase()
            //                         .contains(searchQuery) &&
            //                     !item.model!
            //                         .toLowerCase()
            //                         .contains(searchQuery)) {
            //                   return Container();
            //                 }
            //                 return Container(
            //                   margin: EdgeInsets.symmetric(
            //                       vertical: 8.0, horizontal: 12),
            //                   padding: EdgeInsets.symmetric(vertical: 6),
            //                   decoration: BoxDecoration(
            //                     color: Colors.white,
            //                     borderRadius: BorderRadius.circular(12),
            //                     boxShadow: [
            //                       BoxShadow(
            //                         color: Colors.black.withOpacity(0.1),
            //                         spreadRadius: 2,
            //                         blurRadius: 5,
            //                         offset: Offset(0, 2),
            //                       ),
            //                     ],
            //                   ),
            //                   child: ListTile(
            //                     leading: Icon(
            //                       Icons.front_loader,
            //                       color: Colors.orange,
            //                     ),
            //                     title: Padding(
            //                       padding: const EdgeInsets.only(bottom: 4.0),
            //                       child: Text(
            //                         '${item.unitNumber}',
            //                         style: getBlackTextStyle(
            //                             fontWeight: FontWeight.w700),
            //                       ),
            //                     ),
            //                   ),
            //                 );
            //               }
            //               return Container();
            //             },
            //           ),
            //         ],
            //       );
            //     })
          ],
        ),
      )),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: green00968A,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.done_outline_rounded), label: 'Checked'),
          BottomNavigationBarItem(
              icon: Icon(Icons.close), label: 'Not Checked'),
        ],
        currentIndex: selectedMenu,
        onTap: (index) {
          setState(() {
            selectedMenu = index;
          });
        },
      ),
    );
  }
}
