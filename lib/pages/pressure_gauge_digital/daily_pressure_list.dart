import 'dart:developer';

import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/recc_press.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/daily_check_firebase.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_check_form_page.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_history_page.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/enum_export_type.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/export_excel_button.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/select_pit_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_firestore/firebase_ui_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camos/core/blocs/unit/unit_bloc.dart';

class DailyPressureListPage extends StatefulWidget {
  static const routeName = '/daily-pressure-list-page';
  const DailyPressureListPage({super.key});

  @override
  State<DailyPressureListPage> createState() => _DailyPressureListPageState();
}

class _DailyPressureListPageState extends State<DailyPressureListPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // untuk user office, id site menyimpan id site yang dipilih
  String idSite = '';
  // untuk user office, actual id site menyimpan id site office
  String actualIdSite = '';
  List<String> pit = [];
  int selectedPit = 0;
  int selectedMenu = 1;
  String searchQuery = '';
  Map<String, dynamic> user = {};
  List<Map<String, dynamic>> filteredItemTask = [];
  List<UnitTire> units = [];
  bool isOnline = false;
  DateTime now = DateTime.now();
  bool isLoading = false;
  List<ReccPress> reccPress = [];

  // List<UnitTire> filteredUnits = [];

  @override
  void initState() {
    super.initState();

    insertPit();
    getUser();
  }

  getCount() async {
    final snapshot = await firestore
        .collection('daily_pressure')
        .where('idSite', isEqualTo: idSite)
        .count()
        .get();
    final count = snapshot.count;
    log('jumlah : $count');
  }

  // coba buat variable offline dan online, jika tekan tombol online ambil dari cts, jika tekan tombol offline ambil dari local tapi kalau belum ambil dari cts, ambil dari cts dulu
  Future<void> getUnits() async {
    log('get units terpanggil');
    // jika user site ambil dari cache
    if (await getIdSitePreferences() != '1' &&
        await getIdSitePreferences() != '2') {
      //       // belum ganti bulan
      if (!isOnline) {
        log('apakah offline');
        // units = await ApiService.getCachedUnits(
        //     idSite: await getIdSitePreferences());
        context.read<UnitBloc>().add(GetUnitsEvent(
            idSite: await getIdSitePreferences(), isOnline: isOnline));
      } else {
        final connectivityResult = await Connectivity().checkConnectivity();

        if (connectivityResult == ConnectivityResult.none) {
          setState(() {
            isOnline = !isOnline;
          });
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(
                    'Please check your internet connection!',
                    style: getBlackTextStyle(),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        child: Text('Okay'))
                  ],
                );
              });
        } else {
          // units = await ApiService.getUnits(idSite);
          context.read<UnitBloc>().add(GetUnitsEvent(
              idSite: await getIdSitePreferences(), isOnline: isOnline));
        }
      }
    } else {
      // jika user office tidak perlu ambil dari cache
      context
          .read<UnitBloc>()
          .add(GetUnitsEvent(idSite: idSite, isOnline: true));
    }
  }

  getUser() async {
    user = await getUserPreferences();
    log('username : ${user}');
  }

  insertPit() async {
    idSite = await getIdSitePreferences();
    actualIdSite = await getIdSitePreferences();
    if (idSite == '1' || idSite == '2') {
      idSite = await getSelectedIdSitePreferences();
    }
    log('id site : $idSite');

    await getUnits();

    // int count = await getTodayDocumentCount();
    log('jumlah unit dicek : $count');
  }

  Future<String> getActualIdSite() async {
    final actIdSite = await getIdSitePreferences();

    return actIdSite;
  }

  // Future<int> getTodayDocumentCount() async {
  //   try {
  //     // Mendapatkan waktu awal dan akhir untuk hari ini
  //     DateTime now = DateTime.now();
  //     DateTime startOfDay = DateTime(now.year, now.month, now.day);
  //     DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

  //     // Query untuk menghitung dokumen yang `timestamp`-nya berada di antara startOfDay dan endOfDay
  //     final query = FirebaseFirestore.instance
  //         .collection('daily_pressure')
  //         .where('idSite', isEqualTo: idSite)
  //         .where('tanggal',
  //             isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
  //         .where('tanggal', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));

  //     // Menggunakan aggregation query 'count()'
  //     final snapshot = await query.count().get();

  //     // Mendapatkan jumlah dokumen yang sesuai dengan query
  //     return snapshot.count;
  //   } catch (e) {
  //     log('error count firebase : $e');
  //   }

  //   return 0;
  // }

  @override
  Widget build(BuildContext context) {
    log('tanggal sekarang : ${DateTime(now.year, now.month, now.day).toIso8601String()}');
    getCount();
    pit.clear();

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
      case '65':
        pit.add('All');
        pit.add('Room B1 Selatan');
        pit.add('Utara');
        pit.add('Serongga');
        pit.add('WS');
        break;
    }
    return Scaffold(
      appBar: appBarWidget('Daily Pressure List', context),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              FutureBuilder(
                  future: getActualIdSite(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container();
                    }

                    final data = snapshot.data;
                    log('id site future builder : $data');

                    if (data != '1' && data != '2' && data != '3') {
                      return Column(
                        children: [
                          SizedBox(
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
                                    'Update Unit',
                                    style: getWhiteTextStyle(),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          Text(
                            'Press this if list unit not showing!',
                            style: getGreyTextStyle(grey8391A1, fontSize: 12),
                          ),
                        ],
                      );
                    }
                    return Container();
                  }),
              const SizedBox(
                height: 12,
              ),
              TextField(
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
              const SizedBox(
                height: 12,
              ),
              const SizedBox(
                height: 12,
              ),
              Builder(builder: (context) {
                if (selectedMenu == 0) {
                  return ExportExcelButton(
                    user: user,
                    pit: pit,
                    selectedPit: selectedPit,
                    filteredItemTask: filteredItemTask,
                    date:
                        "${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().year}",
                    type: ExportType.oneDay,
                  );
                }
                return Container();
              }),

              const SizedBox(
                height: 12,
              ),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                            context, DailyPressureHistoryPage.routeName);
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              color: Colors.white,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              'History',
                              style: getWhiteTextStyle(),
                            ),
                          ],
                        ),
                      ))),
              // tester 1
              BlocConsumer<UnitBloc, UnitState>(listener: (context, state) {
                // if(state is UnitLoadedState){
                //   reccPress = {
                //     state.reccPress[]
                //   };
                // }
              }, builder: (context, state) {
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
                          SelectPitButton(
                              pit: pit,
                              selectedPit: selectedPit,
                              onSelectedPitChanged: (index) {
                                setState(() {
                                  selectedPit = index;
                                });
                              }),
                          const SizedBox(
                            height: 12,
                          ),
                          StreamBuilder(
                              stream: firestore
                                  .collection('daily_pressure')
                                  .where('tanggal',
                                      isGreaterThanOrEqualTo:
                                          DateTime(now.year, now.month, now.day)
                                              .toIso8601String())
                                  .where('tanggal',
                                      isLessThanOrEqualTo: DateTime(now.year,
                                              now.month, now.day, 23, 59, 59)
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
                                                                  .data!.size -
                                                              1]
                                                          .data()['tanggal']);

                                                  // Formatting DateTime to the desired format
                                                  String formattedDate = DateFormat(
                                                          'HH:mm:ss dd-MM-yyyy')
                                                      .format(parsedDate);
                                                  return Text(
                                                    'Last Update : ${formattedDate}',
                                                    textAlign: TextAlign.center,
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
                                          isGreaterThanOrEqualTo:
                                              DateTime(now.year, now.month, now.day)
                                                  .toIso8601String())
                                      .where('tanggal',
                                          isLessThanOrEqualTo:
                                              DateTime(now.year, now.month, now.day, 23, 59, 59)
                                                  .toIso8601String())
                                      .where('idSite', isEqualTo: idSite)
                                      .orderBy('tanggal', descending: true)
                                  : firestore
                                      .collection('daily_pressure')
                                      .where('tanggal',
                                          isGreaterThanOrEqualTo:
                                              DateTime(now.year, now.month, now.day)
                                                  .toIso8601String())
                                      .where('tanggal',
                                          isLessThanOrEqualTo:
                                              DateTime(now.year, now.month, now.day, 23, 59, 59)
                                                  .toIso8601String())
                                      .where('idSite', isEqualTo: idSite)
                                      .where('pit', isEqualTo: pit[selectedPit])
                                      .orderBy('tanggal', descending: true),
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
                                    child: Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 24),
                                      decoration: BoxDecoration(
                                        // color: (positionList.any((position) =>
                                        //         int.parse(
                                        //             position['pressure']) <
                                        //         115)
                                        //     ? Colors.red
                                        //     : green00968A),
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
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Name',
                                                style: getWhiteTextStyle(
                                                    fontSize: 18),
                                              ),
                                              Container(
                                                width: 250,
                                                child: Text(
                                                  dailyMap['user'] ?? 'No Name',
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
                                                MainAxisAlignment.spaceBetween,
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
                                                MainAxisAlignment.spaceBetween,
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
                                                MainAxisAlignment.spaceBetween,
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
                                                MainAxisAlignment.spaceBetween,
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
                                                luka =
                                                    pl['luka'] as List<dynamic>;
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
                                                                  luka == null)
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
                                                          Text(
                                                              '${(pl['rating'] == '' || pl['rating'] == null) ? '' : 'Rating ${pl['rating']}'}',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                      fontWeight:
                                                                          w700,
                                                                      fontSize:
                                                                          18)),
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

                                ;
                              }),
                        ],
                      );

                    // Al Unit
                    case 1:
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'Total Unit : ${state.units.length.toString()}',
                            style: getBlackTextStyle(fontSize: 20),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          (state.units == null || state.units.isEmpty)
                              ? Text(
                                  'Empty!',
                                  textAlign: TextAlign.center,
                                  style: getBlackTextStyle(fontSize: 18),
                                )
                              : Column(
                                  children: state.units.map((unit) {
                                    if (searchQuery.isNotEmpty &&
                                        !unit.unitNumber!
                                            .toLowerCase()
                                            .contains(searchQuery) &&
                                        !unit.model!
                                            .toLowerCase()
                                            .contains(searchQuery)) {
                                      return Container();
                                    }
                                    return InkWell(
                                      onTap: (actualIdSite == '1' ||
                                              actualIdSite == '2' ||
                                              actualIdSite == '3')
                                          ? () {}
                                          : () {
                                              Navigator.pushNamed(context,
                                                  DailyCheckFormPage.routeName,
                                                  arguments: {
                                                    'unitNumber':
                                                        unit.unitNumber,
                                                  });
                                            },
                                      child: Container(
                                        margin:
                                            EdgeInsets.symmetric(vertical: 8.0),
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.black.withOpacity(0.1),
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
                                            padding: const EdgeInsets.only(
                                                bottom: 4.0),
                                            child: Text(
                                              '${unit.unitNumber}',
                                              style: getBlackTextStyle(
                                                  fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${unit.model}',
                                            style: getGreyTextStyle(grey6A707C),
                                          ),
                                          trailing:
                                              Icon(Icons.arrow_forward_ios),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ],
                      );

                    // Not Checked Unit
                    case 2:
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
                                      isGreaterThanOrEqualTo:
                                          DateTime(now.year, now.month, now.day)
                                              .toIso8601String())
                                  .where('tanggal',
                                      isLessThanOrEqualTo: DateTime(now.year,
                                              now.month, now.day, 23, 59, 59)
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
                                          unitList.contains(element.unitNumber))
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
                                                                  .data!.size -
                                                              1]
                                                          .data()['tanggal']);

                                                  // Formatting DateTime to the desired format
                                                  String formattedDate = DateFormat(
                                                          'HH:mm:ss dd-MM-yyyy')
                                                      .format(parsedDate);
                                                  return Text(
                                                    'Last Update : ${formattedDate}',
                                                    textAlign: TextAlign.center,
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
                                      (notChecked == null || notChecked.isEmpty)
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
                                                return InkWell(
                                                  onTap: (actualIdSite == '1' ||
                                                          actualIdSite == '2' ||
                                                          actualIdSite == '3')
                                                      ? () {}
                                                      : () {
                                                          Navigator.pushNamed(
                                                              context,
                                                              DailyCheckFormPage
                                                                  .routeName,
                                                              arguments: {
                                                                'unitNumber': unit
                                                                    .unitNumber,
                                                              });
                                                        },
                                                  child: Container(
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

              // tester 2
              // BlocConsumer<UnitBloc, UnitState>(builder: (context, state) {
              //   if (state is UnitLoadingState) {
              //     return Center(child: CircularProgressIndicator());
              //   }

              //   if (state is UnitLoadedState) {
              //     log('kondisi state : ${state.units.length}');

              //     // List<UnitTire> filteredUnits = state.units.where((unit) {
              //     //   // Cek apakah unit sudah dicek (berada di filteredItemTask)
              //     //   return !filteredItemTask
              //     //       .any((task) => task['unit'] == unit.unitNumber);
              //     // }).toList();

              //     // log('kondisi unit : ${filteredUnits.length}');

              //     return Builder(builder: (context) {
              //       if (selectedMenu == 1) {
              //         return Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             const SizedBox(
              //               height: 12,
              //             ),
              //             Text(
              //               'Total Unit : ${state.units.length.toString()}',
              //               style: getBlackTextStyle(fontSize: 20),
              //             ),
              //             const SizedBox(
              //               height: 12,
              //             ),
              //             (state.units == null || state.units.isEmpty)
              //                 ? Text(
              //                     'No Data, please press Get Unit to get data!',
              //                     textAlign: TextAlign.center,
              //                     style: getBlackTextStyle(fontSize: 18),
              //                   )
              //                 : Column(
              //                     children: state.units.map((unit) {
              //                       if (searchQuery.isNotEmpty &&
              //                           !unit.unitNumber!
              //                               .toLowerCase()
              //                               .contains(searchQuery) &&
              //                           !unit.model!
              //                               .toLowerCase()
              //                               .contains(searchQuery)) {
              //                         return Container();
              //                       }
              //                       return InkWell(
              //                         onTap: (actualIdSite == '1' ||
              //                                 actualIdSite == '2' ||
              //                                 actualIdSite == '3')
              //                             ? () {}
              //                             : () {
              //                                 Navigator.pushNamed(context,
              //                                     DailyCheckFormPage.routeName,
              //                                     arguments: {
              //                                       'unitNumber':
              //                                           unit.unitNumber,
              //                                     });
              //                               },
              //                         child: Container(
              //                           margin:
              //                               EdgeInsets.symmetric(vertical: 8.0),
              //                           padding:
              //                               EdgeInsets.symmetric(vertical: 6),
              //                           decoration: BoxDecoration(
              //                             color: Colors.white,
              //                             borderRadius:
              //                                 BorderRadius.circular(12),
              //                             boxShadow: [
              //                               BoxShadow(
              //                                 color:
              //                                     Colors.black.withOpacity(0.1),
              //                                 spreadRadius: 2,
              //                                 blurRadius: 5,
              //                                 offset: Offset(0, 2),
              //                               ),
              //                             ],
              //                           ),
              //                           child: ListTile(
              //                             leading: Icon(
              //                               Icons.front_loader,
              //                               color: Colors.orange,
              //                             ),
              //                             title: Padding(
              //                               padding: const EdgeInsets.only(
              //                                   bottom: 4.0),
              //                               child: Text(
              //                                 '${unit.unitNumber}',
              //                                 style: getBlackTextStyle(
              //                                     fontWeight: FontWeight.w700),
              //                               ),
              //                             ),
              //                             subtitle: Text(
              //                               '${unit.model}',
              //                               style: getGreyTextStyle(grey6A707C),
              //                             ),
              //                             trailing:
              //                                 Icon(Icons.arrow_forward_ios),
              //                           ),
              //                         ),
              //                       );
              //                     }).toList(),
              //                   ),
              //           ],
              //         );
              //       } else {
              //         return // Unit telah di cek
              //             Column(
              //           children: [
              //             const SizedBox(
              //               height: 12,
              //             ),

              //             PaginateFirestore(
              //               query: firestore
              //                   .collection('daily_pressure')
              //                   .where('idSite', isEqualTo: idSite),
              //               itemsPerPage: 2,
              //               isLive: true,
              //               initialLoader: Center(
              //                 child: CircularProgressIndicator.adaptive(),
              //               ),
              //               bottomLoader: Center(
              //                 child: CircularProgressIndicator.adaptive(),
              //               ),
              //               itemBuilderType: PaginateBuilderType.listView,
              //               itemBuilder: (context, snapshot, index) {
              //                 final filteredDocument = snapshot.where((doc) {
              //                   final Map<String, dynamic> data =
              //                       doc.data() as Map<String, dynamic>;

              //                   final dateString = data['tanggal'] as String;
              //                   final dateTime = DateTime.parse(dateString);
              //                   final now = DateTime.now();

              //                   // pilih all pit
              //                   if (pit.isNotEmpty) {
              //                     if (pit[selectedPit] == 'All') {
              //                       return dateTime.year == now.year &&
              //                           dateTime.month == now.month &&
              //                           dateTime.day == now.day &&
              //                           data['idSite'] == idSite;
              //                     }

              //                     // ada pit
              //                     if (data['pit'] != 'Default') {
              //                       return dateTime.year == now.year &&
              //                           dateTime.month == now.month &&
              //                           dateTime.day == now.day &&
              //                           data['idSite'] == idSite &&
              //                           data['pit'] == pit[selectedPit];
              //                     }
              //                   }

              //                   // tidak ada pit
              //                   return dateTime.year == now.year &&
              //                       dateTime.month == now.month &&
              //                       dateTime.day == now.day &&
              //                       data['idSite'] == idSite;
              //                 }).toList();

              //                 filteredDocument.sort((a, b) {
              //                   Map<String, dynamic> first =
              //                       a.data() as Map<String, dynamic>;
              //                   Map<String, dynamic> second =
              //                       b.data() as Map<String, dynamic>;
              //                   ;
              //                   // Ambil nilai last_update dari masing-masing DocumentSnapshot
              //                   DateTime timeA =
              //                       DateTime.parse(first['tanggal']);
              //                   DateTime timeB =
              //                       DateTime.parse(second['tanggal']);

              //                   // Bandingkan waktu last_update dari kedua DocumentSnapshot
              //                   return timeB.compareTo(
              //                       timeA); // Dari yang terbaru ke yang terlama
              //                 });

              //                 // untuk data export excel
              //                 filteredItemTask.clear();
              //                 filteredDocument.forEach((item) {
              //                   Map<String, dynamic> cast =
              //                       item.data() as Map<String, dynamic>;

              //                   units.removeWhere((element) =>
              //                       element.unitNumber == cast['unit']);
              //                   filteredItemTask.add(cast);
              //                 });

              //                 switch (selectedMenu) {
              //                   case 0:
              //                     return Column(
              //                       children: [
              //                         const SizedBox(
              //                           height: 12,
              //                         ),
              //                         SelectPitButton(
              //                             pit: pit,
              //                             selectedPit: selectedPit,
              //                             onSelectedPitChanged: (index) {
              //                               setState(() {
              //                                 selectedPit = index;
              //                               });
              //                             }),
              //                         const SizedBox(
              //                           height: 12,
              //                         ),
              //                         Padding(
              //                           padding: const EdgeInsets.symmetric(
              //                               horizontal: 12.0),
              //                           child: Column(
              //                             children: [
              //                               Text(
              //                                 'Total Unit : ${filteredDocument.length}',
              //                                 style: getBlackTextStyle(
              //                                     fontSize: 20),
              //                               ),
              //                               const SizedBox(
              //                                 height: 6,
              //                               ),
              //                               Builder(builder: (context) {
              //                                 Map<String, dynamic> mapData =
              //                                     filteredDocument.isNotEmpty
              //                                         ? filteredDocument[0]
              //                                                 .data()
              //                                             as Map<String,
              //                                                 dynamic>
              //                                         : {};
              //                                 String originalDate =
              //                                     mapData.isNotEmpty
              //                                         ? mapData['tanggal']
              //                                         : '';
              //                                 DateTime parsedDate = originalDate
              //                                         .isNotEmpty
              //                                     ? DateTime.parse(originalDate)
              //                                     : DateTime
              //                                         .now(); // atau default date jika tidak ada tanggal

              //                                 String formattedDate = originalDate
              //                                         .isNotEmpty
              //                                     ? DateFormat(
              //                                             'HH:mm || dd-MM-yyyy')
              //                                         .format(parsedDate)
              //                                     : 'No Date Available';

              //                                 return Text(
              //                                   'Last Update : ${formattedDate}',
              //                                   style: getBlackTextStyle(
              //                                       fontSize: 14),
              //                                 );
              //                               }),
              //                             ],
              //                           ),
              //                         ),
              //                         const SizedBox(
              //                           height: 12,
              //                         ),
              //                         ListView.builder(
              //                           shrinkWrap: true,
              //                           physics: NeverScrollableScrollPhysics(),
              //                           itemCount: filteredDocument.length,
              //                           itemBuilder: (context, index) {
              //                             final Map<String, dynamic> dailyMap =
              //                                 filteredDocument[index].data()
              //                                     as Map<String, dynamic>;
              //                             final positionList =
              //                                 dailyMap['posisi']
              //                                     as List<dynamic>;

              //                             log('subsub : $positionList');

              //                             return Card(
              //                                 elevation: 2,
              //                                 shape: RoundedRectangleBorder(
              //                                   borderRadius:
              //                                       BorderRadius.circular(12),
              //                                 ),
              //                                 color: green00968A,
              //                                 child: Container(
              //                                   width: double.infinity,
              //                                   padding: EdgeInsets.symmetric(
              //                                       horizontal: 12,
              //                                       vertical: 24),
              //                                   decoration: BoxDecoration(
              //                                     color: green00968A,
              //                                     borderRadius:
              //                                         BorderRadius.circular(12),
              //                                   ),
              //                                   child: ExpansionTile(
              //                                     tilePadding: EdgeInsets.zero,
              //                                     childrenPadding:
              //                                         EdgeInsets.all(0),
              //                                     title: Row(
              //                                       children: [
              //                                         Icon(
              //                                           Icons.task,
              //                                           color: white,
              //                                           size: 36,
              //                                         ),
              //                                         const SizedBox(
              //                                           width: 12,
              //                                         ),
              //                                         Text(
              //                                           dailyMap['unit'] +
              //                                               '${((dailyMap['pit'] != 'Default') ? ' - ' + dailyMap['pit'] : '')}',
              //                                           style:
              //                                               getWhiteTextStyle(
              //                                                   fontWeight:
              //                                                       w700,
              //                                                   fontSize: 18),
              //                                         )
              //                                       ],
              //                                     ),
              //                                     trailing: SizedBox(
              //                                       width: 90,
              //                                       child: Icon(
              //                                           Icons.arrow_drop_down),
              //                                     ),
              //                                     children: [
              //                                       const SizedBox(
              //                                         height: 12,
              //                                       ),
              //                                       Row(
              //                                         mainAxisAlignment:
              //                                             MainAxisAlignment
              //                                                 .spaceBetween,
              //                                         children: [
              //                                           Text(
              //                                             'Name',
              //                                             style:
              //                                                 getWhiteTextStyle(
              //                                                     fontSize: 18),
              //                                           ),
              //                                           Container(
              //                                             width: 250,
              //                                             child: Text(
              //                                               dailyMap['user'] ??
              //                                                   'No Name',
              //                                               textAlign:
              //                                                   TextAlign.end,
              //                                               style:
              //                                                   getWhiteTextStyle(
              //                                                       fontWeight:
              //                                                           w700,
              //                                                       fontSize:
              //                                                           18),
              //                                             ),
              //                                           ),
              //                                         ],
              //                                       ),
              //                                       const SizedBox(
              //                                         height: 12,
              //                                       ),
              //                                       Row(
              //                                         mainAxisAlignment:
              //                                             MainAxisAlignment
              //                                                 .spaceBetween,
              //                                         children: [
              //                                           Text(
              //                                             'Tanggal',
              //                                             style:
              //                                                 getWhiteTextStyle(
              //                                                     fontSize: 18),
              //                                           ),
              //                                           Text(
              //                                             dailyMap['tanggal']
              //                                                 .split('T')[0],
              //                                             style:
              //                                                 getWhiteTextStyle(
              //                                                     fontWeight:
              //                                                         w700,
              //                                                     fontSize: 18),
              //                                           ),
              //                                         ],
              //                                       ),
              //                                       const SizedBox(
              //                                         height: 12,
              //                                       ),
              //                                       Row(
              //                                         mainAxisAlignment:
              //                                             MainAxisAlignment
              //                                                 .spaceBetween,
              //                                         children: [
              //                                           Text(
              //                                             'Waktu',
              //                                             style:
              //                                                 getWhiteTextStyle(
              //                                                     fontSize: 18),
              //                                           ),
              //                                           Text(
              //                                             dailyMap['tanggal']
              //                                                 .split('T')[1]
              //                                                 .substring(0, 5),
              //                                             style:
              //                                                 getWhiteTextStyle(
              //                                                     fontWeight:
              //                                                         w700,
              //                                                     fontSize: 18),
              //                                           ),
              //                                         ],
              //                                       ),
              //                                       const SizedBox(
              //                                         height: 12,
              //                                       ),
              //                                       Row(
              //                                         mainAxisAlignment:
              //                                             MainAxisAlignment
              //                                                 .spaceBetween,
              //                                         children: [
              //                                           Text(
              //                                             'HM Unit',
              //                                             style:
              //                                                 getWhiteTextStyle(
              //                                                     fontSize: 18),
              //                                           ),
              //                                           Text(
              //                                             dailyMap['hm'],
              //                                             style:
              //                                                 getWhiteTextStyle(
              //                                                     fontWeight:
              //                                                         w700,
              //                                                     fontSize: 18),
              //                                           ),
              //                                         ],
              //                                       ),
              //                                       const SizedBox(
              //                                         height: 12,
              //                                       ),
              //                                       Row(
              //                                         mainAxisAlignment:
              //                                             MainAxisAlignment
              //                                                 .spaceBetween,
              //                                         children: [
              //                                           Text(
              //                                             'Pit',
              //                                             style:
              //                                                 getWhiteTextStyle(
              //                                                     fontSize: 18),
              //                                           ),
              //                                           Text(
              //                                             dailyMap['pit'],
              //                                             style:
              //                                                 getWhiteTextStyle(
              //                                                     fontWeight:
              //                                                         w700,
              //                                                     fontSize: 18),
              //                                           ),
              //                                         ],
              //                                       ),
              //                                       const SizedBox(
              //                                         height: 12,
              //                                       ),
              //                                       Column(
              //                                         children: positionList
              //                                             .map((pl) {
              //                                           final plIndex =
              //                                               positionList
              //                                                   .indexOf(pl);
              //                                           List<dynamic> luka = [];

              //                                           if (pl['luka'] !=
              //                                                   null &&
              //                                               pl['luka']
              //                                                   is! String) {
              //                                             luka = pl['luka']
              //                                                 as List<dynamic>;
              //                                           }

              //                                           return Column(
              //                                             children: [
              //                                               Row(
              //                                                 mainAxisAlignment:
              //                                                     MainAxisAlignment
              //                                                         .spaceBetween,
              //                                                 crossAxisAlignment:
              //                                                     CrossAxisAlignment
              //                                                         .center,
              //                                                 children: [
              //                                                   Text(
              //                                                     'Pos. ${pl['pos']}',
              //                                                     style: getWhiteTextStyle(
              //                                                         fontSize:
              //                                                             18),
              //                                                   ),
              //                                                   Column(
              //                                                     crossAxisAlignment:
              //                                                         CrossAxisAlignment
              //                                                             .end,
              //                                                     mainAxisAlignment:
              //                                                         MainAxisAlignment
              //                                                             .center,
              //                                                     children: [
              //                                                       Column(
              //                                                         crossAxisAlignment:
              //                                                             CrossAxisAlignment
              //                                                                 .end,
              //                                                         children: [
              //                                                           Text(
              //                                                             '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
              //                                                             style: getWhiteTextStyle(
              //                                                                 fontWeight: w700,
              //                                                                 fontSize: 18),
              //                                                           ),
              //                                                           (pl['adjusmentPressure'] != null &&
              //                                                                   pl['adjusmentPressure'] != '0' &&
              //                                                                   pl['adjusmentPressure'] != '')
              //                                                               ? Text(
              //                                                                   '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
              //                                                                   style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
              //                                                                 )
              //                                                               : Container(),
              //                                                         ],
              //                                                       ),
              //                                                       (luka.isEmpty ||
              //                                                               luka ==
              //                                                                   null)
              //                                                           ? Container()
              //                                                           : Text(
              //                                                               pl['luka'].join('\n'),
              //                                                               textAlign:
              //                                                                   TextAlign.end,
              //                                                               style:
              //                                                                   getWhiteTextStyle(fontWeight: w700, fontSize: 18),
              //                                                             ),
              //                                                       const SizedBox(
              //                                                         height:
              //                                                             12,
              //                                                       ),
              //                                                     ],
              //                                                   ),
              //                                                 ],
              //                                               ),
              //                                               Divider(
              //                                                 color: white,
              //                                                 thickness: 1.5,
              //                                               ),
              //                                             ],
              //                                           );
              //                                         }).toList(),
              //                                       ),
              //                                     ],
              //                                   ),
              //                                 ));
              //                           },
              //                         ),
              //                       ],
              //                     );

              //                   case 2:
              //                     Map<String, dynamic> mapData =
              //                         filteredDocument.isNotEmpty
              //                             ? filteredDocument[0].data()
              //                                 as Map<String, dynamic>
              //                             : {};
              //                     String originalDate = mapData.isNotEmpty
              //                         ? mapData['tanggal']
              //                         : '';
              //                     DateTime parsedDate = originalDate.isNotEmpty
              //                         ? DateTime.parse(originalDate)
              //                         : DateTime
              //                             .now(); // atau default date jika tidak ada tanggal

              //                     String formattedDate = originalDate.isNotEmpty
              //                         ? DateFormat('HH:mm || dd-MM-yyyy')
              //                             .format(parsedDate)
              //                         : 'No Date Available';
              //                     return Column(
              //                       crossAxisAlignment:
              //                           CrossAxisAlignment.start,
              //                       children: [
              //                         Text(
              //                           'Total Unit : ${units.length.toString()}',
              //                           style: getBlackTextStyle(fontSize: 20),
              //                         ),
              //                         const SizedBox(
              //                           height: 12,
              //                         ),
              //                         Text(
              //                           'Last Update : ${formattedDate}',
              //                           style: getBlackTextStyle(fontSize: 14),
              //                         ),
              //                         const SizedBox(
              //                           height: 12,
              //                         ),
              //                         (units == null || units.isEmpty)
              //                             ? Text(
              //                                 'No Data, please press Get Unit to get data!',
              //                                 textAlign: TextAlign.center,
              //                                 style: getBlackTextStyle(
              //                                     fontSize: 18),
              //                               )
              //                             : Column(
              //                                 children: units.map((unit) {
              //                                   if (searchQuery.isNotEmpty &&
              //                                       !unit.unitNumber!
              //                                           .toLowerCase()
              //                                           .contains(
              //                                               searchQuery) &&
              //                                       !unit.model!
              //                                           .toLowerCase()
              //                                           .contains(
              //                                               searchQuery)) {
              //                                     return Container();
              //                                   }
              //                                   return InkWell(
              //                                     onTap: (actualIdSite == '1' ||
              //                                             actualIdSite == '2' ||
              //                                             actualIdSite == '3')
              //                                         ? () {}
              //                                         : () {
              //                                             Navigator.pushNamed(
              //                                                 context,
              //                                                 DailyCheckFormPage
              //                                                     .routeName,
              //                                                 arguments: {
              //                                                   'unitNumber': unit
              //                                                       .unitNumber,
              //                                                 });
              //                                           },
              //                                     child: Container(
              //                                       margin:
              //                                           EdgeInsets.symmetric(
              //                                               vertical: 8.0),
              //                                       padding:
              //                                           EdgeInsets.symmetric(
              //                                               vertical: 6),
              //                                       decoration: BoxDecoration(
              //                                         color: Colors.white,
              //                                         borderRadius:
              //                                             BorderRadius.circular(
              //                                                 12),
              //                                         boxShadow: [
              //                                           BoxShadow(
              //                                             color: Colors.black
              //                                                 .withOpacity(0.1),
              //                                             spreadRadius: 2,
              //                                             blurRadius: 5,
              //                                             offset: Offset(0, 2),
              //                                           ),
              //                                         ],
              //                                       ),
              //                                       child: ListTile(
              //                                         leading: Icon(
              //                                           Icons.front_loader,
              //                                           color: Colors.orange,
              //                                         ),
              //                                         title: Padding(
              //                                           padding:
              //                                               const EdgeInsets
              //                                                   .only(
              //                                                   bottom: 4.0),
              //                                           child: Text(
              //                                             '${unit.unitNumber}',
              //                                             style:
              //                                                 getBlackTextStyle(
              //                                                     fontWeight:
              //                                                         FontWeight
              //                                                             .w700),
              //                                           ),
              //                                         ),
              //                                         subtitle: Text(
              //                                           '${unit.model}',
              //                                           style: getGreyTextStyle(
              //                                               grey6A707C),
              //                                         ),
              //                                         trailing: Icon(Icons
              //                                             .arrow_forward_ios),
              //                                       ),
              //                                     ),
              //                                   );
              //                                 }).toList(),
              //                               ),
              //                       ],
              //                     );
              //                 }
              //                 return Container();
              //               },
              //             ),

              //             // StreamBuilder(
              //             //     stream: firestore
              //             //         .collection('daily_pressure')
              //             //         .where('idSite', isEqualTo: idSite)
              //             //         .snapshots(),
              //             //     builder: (context, snapshot) {
              //             //       if (snapshot.connectionState ==
              //             //           ConnectionState.waiting) {
              //             //         return CircularProgressIndicator();
              //             //       }

              //             //       List<DocumentSnapshot> documents =
              //             //           snapshot.data!.docs;

              //             //       // final filteredDocument = documents.where((doc) {
              //             //       //   final Map<String, dynamic> data =
              //             //       //       doc.data() as Map<String, dynamic>;

              //             //       //   final dateString = data['tanggal'] as String;
              //             //       //   final dateTime = DateTime.parse(dateString);
              //             //       //   final now = DateTime.now();

              //             //       //   return dateTime.year == now.year &&
              //             //       //       dateTime.month == now.month &&
              //             //       //       dateTime.day == now.day;
              //             //       // });

              //             //       final filteredDocument = documents.where((doc) {
              //             //         final Map<String, dynamic> data =
              //             //             doc.data() as Map<String, dynamic>;

              //             //         final dateString = data['tanggal'] as String;
              //             //         final dateTime = DateTime.parse(dateString);
              //             //         final now = DateTime.now();

              //             //         // pilih all pit
              //             //         if (pit.isNotEmpty) {
              //             //           if (pit[selectedPit] == 'All') {
              //             //             return dateTime.year == now.year &&
              //             //                 dateTime.month == now.month &&
              //             //                 dateTime.day == now.day &&
              //             //                 data['idSite'] == idSite;
              //             //           }

              //             //           // ada pit
              //             //           if (data['pit'] != 'Default') {
              //             //             return dateTime.year == now.year &&
              //             //                 dateTime.month == now.month &&
              //             //                 dateTime.day == now.day &&
              //             //                 data['idSite'] == idSite &&
              //             //                 data['pit'] == pit[selectedPit];
              //             //           }
              //             //         }

              //             //         // tidak ada pit
              //             //         return dateTime.year == now.year &&
              //             //             dateTime.month == now.month &&
              //             //             dateTime.day == now.day &&
              //             //             data['idSite'] == idSite;
              //             //       }).toList();

              //             //       filteredDocument.sort((a, b) {
              //             //         Map<String, dynamic> first =
              //             //             a.data() as Map<String, dynamic>;
              //             //         Map<String, dynamic> second =
              //             //             b.data() as Map<String, dynamic>;
              //             //         ;
              //             //         // Ambil nilai last_update dari masing-masing DocumentSnapshot
              //             //         DateTime timeA =
              //             //             DateTime.parse(first['tanggal']);
              //             //         DateTime timeB =
              //             //             DateTime.parse(second['tanggal']);

              //             //         // Bandingkan waktu last_update dari kedua DocumentSnapshot
              //             //         return timeB.compareTo(
              //             //             timeA); // Dari yang terbaru ke yang terlama
              //             //       });

              //             //       // untuk data export excel
              //             //       filteredItemTask.clear();
              //             //       filteredDocument.forEach((item) {
              //             //         Map<String, dynamic> cast =
              //             //             item.data() as Map<String, dynamic>;

              //             //         units.removeWhere((element) =>
              //             //             element.unitNumber == cast['unit']);
              //             //         filteredItemTask.add(cast);
              //             //       });

              //             //       log('jumlah unit yang di cek hari ini : ${filteredDocument.length}');

              //             //       switch (selectedMenu) {
              //             //         case 0:
              //             //           return Column(
              //             //             children: [
              //             //               const SizedBox(
              //             //                 height: 12,
              //             //               ),
              //             //               SelectPitButton(
              //             //                   pit: pit,
              //             //                   selectedPit: selectedPit,
              //             //                   onSelectedPitChanged: (index) {
              //             //                     setState(() {
              //             //                       selectedPit = index;
              //             //                     });
              //             //                   }),
              //             //               const SizedBox(
              //             //                 height: 12,
              //             //               ),
              //             //               Padding(
              //             //                 padding: const EdgeInsets.symmetric(
              //             //                     horizontal: 12.0),
              //             //                 child: Column(
              //             //                   children: [
              //             //                     Text(
              //             //                       'Total Unit : ${filteredDocument.length}',
              //             //                       style: getBlackTextStyle(
              //             //                           fontSize: 20),
              //             //                     ),
              //             //                     const SizedBox(
              //             //                       height: 6,
              //             //                     ),
              //             //                     Builder(builder: (context) {
              //             //                       Map<String, dynamic> mapData =
              //             //                           filteredDocument.isNotEmpty
              //             //                               ? filteredDocument[0]
              //             //                                       .data()
              //             //                                   as Map<String,
              //             //                                       dynamic>
              //             //                               : {};
              //             //                       String originalDate =
              //             //                           mapData.isNotEmpty
              //             //                               ? mapData['tanggal']
              //             //                               : '';
              //             //                       DateTime parsedDate = originalDate
              //             //                               .isNotEmpty
              //             //                           ? DateTime.parse(
              //             //                               originalDate)
              //             //                           : DateTime
              //             //                               .now(); // atau default date jika tidak ada tanggal

              //             //                       String formattedDate = originalDate
              //             //                               .isNotEmpty
              //             //                           ? DateFormat(
              //             //                                   'HH:mm || dd-MM-yyyy')
              //             //                               .format(parsedDate)
              //             //                           : 'No Date Available';

              //             //                       return Text(
              //             //                         'Last Update : ${formattedDate}',
              //             //                         style: getBlackTextStyle(
              //             //                             fontSize: 14),
              //             //                       );
              //             //                     }),
              //             //                   ],
              //             //                 ),
              //             //               ),
              //             //               const SizedBox(
              //             //                 height: 12,
              //             //               ),
              //             //               ListView.builder(
              //             //                 shrinkWrap: true,
              //             //                 physics:
              //             //                     NeverScrollableScrollPhysics(),
              //             //                 itemCount: filteredDocument.length,
              //             //                 itemBuilder: (context, index) {
              //             //                   final Map<String, dynamic>
              //             //                       dailyMap =
              //             //                       filteredDocument[index].data()
              //             //                           as Map<String, dynamic>;
              //             //                   final positionList =
              //             //                       dailyMap['posisi']
              //             //                           as List<dynamic>;

              //             //                   log('subsub : $positionList');

              //             //                   return Card(
              //             //                       elevation: 2,
              //             //                       shape: RoundedRectangleBorder(
              //             //                         borderRadius:
              //             //                             BorderRadius.circular(12),
              //             //                       ),
              //             //                       color: green00968A,
              //             //                       child: Container(
              //             //                         width: double.infinity,
              //             //                         padding: EdgeInsets.symmetric(
              //             //                             horizontal: 12,
              //             //                             vertical: 24),
              //             //                         decoration: BoxDecoration(
              //             //                           color: green00968A,
              //             //                           borderRadius:
              //             //                               BorderRadius.circular(
              //             //                                   12),
              //             //                         ),
              //             //                         child: ExpansionTile(
              //             //                           tilePadding:
              //             //                               EdgeInsets.zero,
              //             //                           childrenPadding:
              //             //                               EdgeInsets.all(0),
              //             //                           title: Row(
              //             //                             children: [
              //             //                               Icon(
              //             //                                 Icons.task,
              //             //                                 color: white,
              //             //                                 size: 36,
              //             //                               ),
              //             //                               const SizedBox(
              //             //                                 width: 12,
              //             //                               ),
              //             //                               Text(
              //             //                                 dailyMap['unit'] +
              //             //                                     '${((dailyMap['pit'] != 'Default') ? ' - ' + dailyMap['pit'] : '')}',
              //             //                                 style:
              //             //                                     getWhiteTextStyle(
              //             //                                         fontWeight:
              //             //                                             w700,
              //             //                                         fontSize: 18),
              //             //                               )
              //             //                             ],
              //             //                           ),
              //             //                           trailing: SizedBox(
              //             //                             width: 90,
              //             //                             child: Icon(Icons
              //             //                                 .arrow_drop_down),
              //             //                           ),
              //             //                           children: [
              //             //                             const SizedBox(
              //             //                               height: 12,
              //             //                             ),
              //             //                             Row(
              //             //                               mainAxisAlignment:
              //             //                                   MainAxisAlignment
              //             //                                       .spaceBetween,
              //             //                               children: [
              //             //                                 Text(
              //             //                                   'Name',
              //             //                                   style:
              //             //                                       getWhiteTextStyle(
              //             //                                           fontSize:
              //             //                                               18),
              //             //                                 ),
              //             //                                 Container(
              //             //                                   width: 250,
              //             //                                   child: Text(
              //             //                                     dailyMap[
              //             //                                             'user'] ??
              //             //                                         'No Name',
              //             //                                     textAlign:
              //             //                                         TextAlign.end,
              //             //                                     style:
              //             //                                         getWhiteTextStyle(
              //             //                                             fontWeight:
              //             //                                                 w700,
              //             //                                             fontSize:
              //             //                                                 18),
              //             //                                   ),
              //             //                                 ),
              //             //                               ],
              //             //                             ),
              //             //                             const SizedBox(
              //             //                               height: 12,
              //             //                             ),
              //             //                             Row(
              //             //                               mainAxisAlignment:
              //             //                                   MainAxisAlignment
              //             //                                       .spaceBetween,
              //             //                               children: [
              //             //                                 Text(
              //             //                                   'Tanggal',
              //             //                                   style:
              //             //                                       getWhiteTextStyle(
              //             //                                           fontSize:
              //             //                                               18),
              //             //                                 ),
              //             //                                 Text(
              //             //                                   dailyMap['tanggal']
              //             //                                       .split('T')[0],
              //             //                                   style:
              //             //                                       getWhiteTextStyle(
              //             //                                           fontWeight:
              //             //                                               w700,
              //             //                                           fontSize:
              //             //                                               18),
              //             //                                 ),
              //             //                               ],
              //             //                             ),
              //             //                             const SizedBox(
              //             //                               height: 12,
              //             //                             ),
              //             //                             Row(
              //             //                               mainAxisAlignment:
              //             //                                   MainAxisAlignment
              //             //                                       .spaceBetween,
              //             //                               children: [
              //             //                                 Text(
              //             //                                   'Waktu',
              //             //                                   style:
              //             //                                       getWhiteTextStyle(
              //             //                                           fontSize:
              //             //                                               18),
              //             //                                 ),
              //             //                                 Text(
              //             //                                   dailyMap['tanggal']
              //             //                                       .split('T')[1]
              //             //                                       .substring(
              //             //                                           0, 5),
              //             //                                   style:
              //             //                                       getWhiteTextStyle(
              //             //                                           fontWeight:
              //             //                                               w700,
              //             //                                           fontSize:
              //             //                                               18),
              //             //                                 ),
              //             //                               ],
              //             //                             ),
              //             //                             const SizedBox(
              //             //                               height: 12,
              //             //                             ),
              //             //                             Row(
              //             //                               mainAxisAlignment:
              //             //                                   MainAxisAlignment
              //             //                                       .spaceBetween,
              //             //                               children: [
              //             //                                 Text(
              //             //                                   'HM Unit',
              //             //                                   style:
              //             //                                       getWhiteTextStyle(
              //             //                                           fontSize:
              //             //                                               18),
              //             //                                 ),
              //             //                                 Text(
              //             //                                   dailyMap['hm'],
              //             //                                   style:
              //             //                                       getWhiteTextStyle(
              //             //                                           fontWeight:
              //             //                                               w700,
              //             //                                           fontSize:
              //             //                                               18),
              //             //                                 ),
              //             //                               ],
              //             //                             ),
              //             //                             const SizedBox(
              //             //                               height: 12,
              //             //                             ),
              //             //                             Row(
              //             //                               mainAxisAlignment:
              //             //                                   MainAxisAlignment
              //             //                                       .spaceBetween,
              //             //                               children: [
              //             //                                 Text(
              //             //                                   'Pit',
              //             //                                   style:
              //             //                                       getWhiteTextStyle(
              //             //                                           fontSize:
              //             //                                               18),
              //             //                                 ),
              //             //                                 Text(
              //             //                                   dailyMap['pit'],
              //             //                                   style:
              //             //                                       getWhiteTextStyle(
              //             //                                           fontWeight:
              //             //                                               w700,
              //             //                                           fontSize:
              //             //                                               18),
              //             //                                 ),
              //             //                               ],
              //             //                             ),
              //             //                             const SizedBox(
              //             //                               height: 12,
              //             //                             ),
              //             //                             Column(
              //             //                               children: positionList
              //             //                                   .map((pl) {
              //             //                                 final plIndex =
              //             //                                     positionList
              //             //                                         .indexOf(pl);
              //             //                                 List<dynamic> luka =
              //             //                                     [];

              //             //                                 if (pl['luka'] !=
              //             //                                         null &&
              //             //                                     pl['luka']
              //             //                                         is! String) {
              //             //                                   luka = pl['luka']
              //             //                                       as List<
              //             //                                           dynamic>;
              //             //                                 }

              //             //                                 return Column(
              //             //                                   children: [
              //             //                                     Row(
              //             //                                       mainAxisAlignment:
              //             //                                           MainAxisAlignment
              //             //                                               .spaceBetween,
              //             //                                       crossAxisAlignment:
              //             //                                           CrossAxisAlignment
              //             //                                               .center,
              //             //                                       children: [
              //             //                                         Text(
              //             //                                           'Pos. ${pl['pos']}',
              //             //                                           style: getWhiteTextStyle(
              //             //                                               fontSize:
              //             //                                                   18),
              //             //                                         ),
              //             //                                         Column(
              //             //                                           crossAxisAlignment:
              //             //                                               CrossAxisAlignment
              //             //                                                   .end,
              //             //                                           mainAxisAlignment:
              //             //                                               MainAxisAlignment
              //             //                                                   .center,
              //             //                                           children: [
              //             //                                             Column(
              //             //                                               crossAxisAlignment:
              //             //                                                   CrossAxisAlignment.end,
              //             //                                               children: [
              //             //                                                 Text(
              //             //                                                   '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
              //             //                                                   style:
              //             //                                                       getWhiteTextStyle(fontWeight: w700, fontSize: 18),
              //             //                                                 ),
              //             //                                                 (pl['adjusmentPressure'] != null && pl['adjusmentPressure'] != '0' && pl['adjusmentPressure'] != '')
              //             //                                                     ? Text(
              //             //                                                         '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
              //             //                                                         style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
              //             //                                                       )
              //             //                                                     : Container(),
              //             //                                               ],
              //             //                                             ),
              //             //                                             (luka.isEmpty ||
              //             //                                                     luka == null)
              //             //                                                 ? Container()
              //             //                                                 : Text(
              //             //                                                     pl['luka'].join('\n'),
              //             //                                                     textAlign: TextAlign.end,
              //             //                                                     style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
              //             //                                                   ),
              //             //                                             const SizedBox(
              //             //                                               height:
              //             //                                                   12,
              //             //                                             ),
              //             //                                           ],
              //             //                                         ),
              //             //                                       ],
              //             //                                     ),
              //             //                                     Divider(
              //             //                                       color: white,
              //             //                                       thickness: 1.5,
              //             //                                     ),
              //             //                                   ],
              //             //                                 );
              //             //                               }).toList(),
              //             //                             ),
              //             //                           ],
              //             //                         ),
              //             //                       ));
              //             //                 },
              //             //               ),
              //             //             ],
              //             //           );

              //             //         case 2:
              //             //           Map<String, dynamic> mapData =
              //             //               filteredDocument.isNotEmpty
              //             //                   ? filteredDocument[0].data()
              //             //                       as Map<String, dynamic>
              //             //                   : {};
              //             //           String originalDate = mapData.isNotEmpty
              //             //               ? mapData['tanggal']
              //             //               : '';
              //             //           DateTime parsedDate = originalDate
              //             //                   .isNotEmpty
              //             //               ? DateTime.parse(originalDate)
              //             //               : DateTime
              //             //                   .now(); // atau default date jika tidak ada tanggal

              //             //           String formattedDate =
              //             //               originalDate.isNotEmpty
              //             //                   ? DateFormat('HH:mm || dd-MM-yyyy')
              //             //                       .format(parsedDate)
              //             //                   : 'No Date Available';
              //             //           return Column(
              //             //             crossAxisAlignment:
              //             //                 CrossAxisAlignment.start,
              //             //             children: [
              //             //               Text(
              //             //                 'Total Unit : ${units.length.toString()}',
              //             //                 style:
              //             //                     getBlackTextStyle(fontSize: 20),
              //             //               ),
              //             //               const SizedBox(
              //             //                 height: 12,
              //             //               ),
              //             //               Text(
              //             //                 'Last Update : ${formattedDate}',
              //             //                 style:
              //             //                     getBlackTextStyle(fontSize: 14),
              //             //               ),
              //             //               const SizedBox(
              //             //                 height: 12,
              //             //               ),
              //             //               (units == null || units.isEmpty)
              //             //                   ? Text(
              //             //                       'No Data, please press Get Unit to get data!',
              //             //                       textAlign: TextAlign.center,
              //             //                       style: getBlackTextStyle(
              //             //                           fontSize: 18),
              //             //                     )
              //             //                   : Column(
              //             //                       children: units.map((unit) {
              //             //                         if (searchQuery.isNotEmpty &&
              //             //                             !unit.unitNumber!
              //             //                                 .toLowerCase()
              //             //                                 .contains(
              //             //                                     searchQuery) &&
              //             //                             !unit.model!
              //             //                                 .toLowerCase()
              //             //                                 .contains(
              //             //                                     searchQuery)) {
              //             //                           return Container();
              //             //                         }
              //             //                         return InkWell(
              //             //                           onTap:
              //             //                               (actualIdSite == '1' ||
              //             //                                       actualIdSite ==
              //             //                                           '2' ||
              //             //                                       actualIdSite ==
              //             //                                           '3')
              //             //                                   ? () {}
              //             //                                   : () {
              //             //                                       Navigator.pushNamed(
              //             //                                           context,
              //             //                                           DailyCheckFormPage
              //             //                                               .routeName,
              //             //                                           arguments: {
              //             //                                             'unitNumber':
              //             //                                                 unit.unitNumber,
              //             //                                           });
              //             //                                     },
              //             //                           child: Container(
              //             //                             margin:
              //             //                                 EdgeInsets.symmetric(
              //             //                                     vertical: 8.0),
              //             //                             padding:
              //             //                                 EdgeInsets.symmetric(
              //             //                                     vertical: 6),
              //             //                             decoration: BoxDecoration(
              //             //                               color: Colors.white,
              //             //                               borderRadius:
              //             //                                   BorderRadius
              //             //                                       .circular(12),
              //             //                               boxShadow: [
              //             //                                 BoxShadow(
              //             //                                   color: Colors.black
              //             //                                       .withOpacity(
              //             //                                           0.1),
              //             //                                   spreadRadius: 2,
              //             //                                   blurRadius: 5,
              //             //                                   offset:
              //             //                                       Offset(0, 2),
              //             //                                 ),
              //             //                               ],
              //             //                             ),
              //             //                             child: ListTile(
              //             //                               leading: Icon(
              //             //                                 Icons.front_loader,
              //             //                                 color: Colors.orange,
              //             //                               ),
              //             //                               title: Padding(
              //             //                                 padding:
              //             //                                     const EdgeInsets
              //             //                                         .only(
              //             //                                         bottom: 4.0),
              //             //                                 child: Text(
              //             //                                   '${unit.unitNumber}',
              //             //                                   style: getBlackTextStyle(
              //             //                                       fontWeight:
              //             //                                           FontWeight
              //             //                                               .w700),
              //             //                                 ),
              //             //                               ),
              //             //                               subtitle: Text(
              //             //                                 '${unit.model}',
              //             //                                 style:
              //             //                                     getGreyTextStyle(
              //             //                                         grey6A707C),
              //             //                               ),
              //             //                               trailing: Icon(Icons
              //             //                                   .arrow_forward_ios),
              //             //                             ),
              //             //                           ),
              //             //                         );
              //             //                       }).toList(),
              //             //                     ),
              //             //             ],
              //             //           );
              //             //       }
              //             //       return Container();
              //             //     }),
              //           ],
              //         );
              //       }
              //     });
              //   }

              //   return Container();
              // }, listener: (context, state) {
              //   if (state is UnitErrorState) {
              //     setState(() {
              //       isOnline = !isOnline;
              //     });
              //     showDialog(
              //         context: context,
              //         builder: (BuildContext context) {
              //           return AlertDialog(
              //             title: Text(
              //               'Please check your internet connection!',
              //               style: getBlackTextStyle(),
              //             ),
              //             actions: [
              //               TextButton(
              //                   onPressed: () {
              //                     Navigator.pop(context);
              //                     Navigator.pop(context);
              //                   },
              //                   child: const Text('Okay'))
              //             ],
              //           );
              //         });
              //   }

              //   if (state is UnitLoadedState) {
              //     units.clear();
              //     units.addAll(state.units);
              //   }
              // }),
            ],
          ),
        ),
      )),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: green00968A,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.done_outline_rounded), label: 'Checked'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All Unit'),
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
