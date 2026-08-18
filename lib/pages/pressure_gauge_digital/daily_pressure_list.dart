import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/not_update_warning_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/temperature_status_badge_widget.dart';
import 'package:get/get.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/blocs/daily_check_post/daily_check_post_bloc.dart';
import '../../core/services/api_service.dart';
import '../../core/services/model/daily_press.dart';
import '../../core/services/model/recc_press.dart';
import '../../core/services/model/unit_tire.dart';
import '../../core/services/shared_preferences/shared_preferences.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/utils/data/daily_check_firebase.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/button_widget.dart';
import '../home/home_state.dart';
import 'daily_check_form_page.dart';
import 'daily_pressure_history_page.dart';
import 'widget/enum_export_type.dart';
import 'widget/export_excel_button.dart';
import 'widget/select_pit_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/unit/unit_bloc.dart';
import 'package:collection/collection.dart';

class DailyPressureListPage extends StatefulWidget {
  static const routeName = '/daily-pressure-list-page';
  const DailyPressureListPage({super.key});

  @override
  State<DailyPressureListPage> createState() => _DailyPressureListPageState();
}

class _DailyPressureListPageState extends State<DailyPressureListPage> {
  // FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeState homeState = Get.isRegistered<HomeState>()
      ? Get.find<HomeState>()
      : Get.put(HomeState());

  Future<QuerySnapshot<Map<String, dynamic>>>? checkedFuture;
  Future<QuerySnapshot<Map<String, dynamic>>>? notCheckedFuture;

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String currentIdSite = '';
  String userAccessId = '';
  List<String> pit = [];
  int selectedNotCheckedPit = 0;
  int selectedPit = 0;
  int selectedMenu = 2;
  String searchQuery = '';
  Map<String, dynamic> user = {};
  List<Map<String, dynamic>> filteredItemTask = [];
  List<UnitTire> units = [];
  List<UnitTire> allUnit = [];
  Map<String, dynamic> allTireSize = {};

  int countAllTire = 0;
  bool isOnline = false;
  bool isLoading = false;
  bool isEmpty = false;

  DateTime now = DateTime.now();

  // ────────────────────────────────
  // INIT STATE
  // ────────────────────────────────
  @override
  void initState() {
    super.initState();

    log('init page terpanggil : ${homeState.currentSiteId}');
    unawaited(initializePage());
  }

  Future<void> setInitialUnitSource() async {
    final firstApiLoadToday = await shouldLoadUnitListFromApiToday(
      idSite: currentIdSite,
    );

    isOnline = firstApiLoadToday;

    log(
      'Daily Check initial unit source: '
      '${isOnline ? 'API' : 'cache'} '
      '(firstSharedLoadToday=$firstApiLoadToday)',
    );
  }

  Future<void> initializePage() async {
    log('initialize page terpanggil');
    await getUser();
    await setupSite();
    await setInitialUnitSource();
    if (!mounted) return;

    await getUnits();
    setupPit();
    await getCount();

    checkedFuture = getCheckedTodayFuture();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getCheckedTodayFuture() {
    final now = DateTime.now();

    final startOfDay = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final startOfNextDay = startOfDay.add(
      const Duration(days: 1),
    );

    final startDate = startOfDay.toIso8601String();
    final endDate = startOfNextDay.toIso8601String();

    log('====================================');
    log('LOAD CHECKED UNIT');
    log('Site          : $currentIdSite');
    log('Selected Pit  : $selectedPit');
    log('Start Date    : $startDate');
    log('End Date      : $endDate');
    log('====================================');

    Query<Map<String, dynamic>> query = firestore
        .collection('daily_pressure')
        .where(
          'tanggal',
          isGreaterThanOrEqualTo: startDate,
        )
        .where(
          'tanggal',
          isLessThan: endDate,
        )
        .where(
          'idSite',
          isEqualTo: currentIdSite,
        );

    if (selectedPit != 0 && pit.isNotEmpty && selectedPit < pit.length) {
      query = query.where(
        'pit',
        isEqualTo: pit[selectedPit],
      );
    }

    return query.get();
  }

  // Future<QuerySnapshot<Map<String, dynamic>>> getCheckedTodayFuture() {
  //   final todayString = DateTime.now().toIso8601String().substring(0, 10);
  //   print('hari ini : $todayString');
  //   print('id site hari ini : $currentIdSite');

  //   if (selectedPit == 0) {
  //     return firestore
  //         .collection('daily_pressure')
  //         .where('hari', isEqualTo: todayString)
  //         .where('idSite', isEqualTo: currentIdSite)
  //         .get();
  //   }

  //   return firestore
  //       .collection('daily_pressure')
  //       .where('hari', isEqualTo: todayString)
  //       .where('idSite', isEqualTo: currentIdSite)
  //       .where('pit', isEqualTo: pit[selectedPit])
  //       .get();
  // }

  void refreshCheckedData() {
    setState(() {
      checkedFuture = getCheckedTodayFuture();
    });
  }

  void setupPit() {
    pit.clear();

    switch (currentIdSite) {
      case '5':
        pit.addAll([
          'All',
          'PITSTOP AMBON',
          'PITSTOP BANGKA',
          'PITSTOP BUTON',
          'PITSTOP IPD',
          'PITSTOP MEDAN',
          'PITSTOP OB2',
          'PITSTOP SABANG',
          'WSP',
          'Other'
        ]);
        break;
      case '52':
        pit.addAll(['All', 'Utara', 'Selatan', 'RML', 'WS']);
        break;
      case '137':
        pit.addAll(['All', 'Japun', 'PCE']);
        break;
      case '35':
        pit.addAll(['All', 'Tabuhan', 'EBL', 'Workshop']);
        break;
      case '65':
        pit.addAll([
          'All',
          'Room B1 Selatan',
          'TIA',
          'Serongga',
          'CSA Selatan',
          'WS',
        ]);
        break;
      case '166':
        pit.addAll(
            ['All', 'WS', 'CSA Bagaspati', 'Pondok Operator', 'Pit Stop Toll']);
        break;
      default:
        pit.add('All');
    }
  }

  // ────────────────────────────────
  // USER DATA
  // ────────────────────────────────
  Future<void> getUser() async {
    user = await getUserPreferences();
    log('👤 User data: $user');
  }

  // ────────────────────────────────
  // SITE SETUP
  // ────────────────────────────────
  Future<void> setupSite() async {
    // ambil current dan actual site dari HomeState
    currentIdSite = homeState.currentSiteId;
    userAccessId = homeState.userAccessId.value;

    log('🏗️ Current Site: $currentIdSite | Actual Site: $userAccessId');
  }

  // ────────────────────────────────
  // GET UNITS
  // ────────────────────────────────
  Future<void> getUnits() async {
    log('🔄 getUnits() dipanggil untuk site: $currentIdSite (online=$isOnline)');
    final isSis = homeState.userAccessCompanyId.value == '1';
    // jika user bukan office site (bukan 1 atau 2)
    // if (userAccessId != '1' && userAccessId != '2') {
    if (userAccessId != '1' || isSis) {
      if (!isOnline) {
        // Offline Mode
        log('📴 Load data dari cache untuk site $currentIdSite');
        context.read<UnitBloc>().add(
              GetUnitsEvent(
                idSite: currentIdSite,
                isOnline: false,
                requestSource: dailyCheckUnitList,
              ),
            );
      } else {
        // Cek koneksi dulu
        final connectivityResult = await Connectivity().checkConnectivity();

        if (connectivityResult == ConnectivityResult.none) {
          setState(() {
            isOnline = false;
          });
          _showNoConnectionDialog();
          return;
        }

        // Online Mode
        log('🌐 Load data dari CTS untuk site $currentIdSite');
        context.read<UnitBloc>().add(
              GetUnitsEvent(
                idSite: currentIdSite,
                isOnline: true,
                requestSource: dailyCheckUnitList,
              ),
            );
      }
    } else {
      // Untuk user office — selalu online
      log('🏢 Office user — ambil data online untuk site $currentIdSite');
      context.read<UnitBloc>().add(
            GetUnitsEvent(
              idSite: currentIdSite,
              isOnline: true,
              requestSource: dailyCheckUnitList,
            ),
          );
    }
  }

  // ────────────────────────────────
  // COUNT DATA
  // ────────────────────────────────
  Future<void> getCount() async {
    final snapshot = await firestore
        .collection('daily_pressure')
        .where('idSite', isEqualTo: currentIdSite)
        .count()
        .get();

    final count = snapshot.count;
    log('📊 Jumlah data daily_pressure ($currentIdSite): $count');
  }

  // ────────────────────────────────
  // HELPER
  // ────────────────────────────────
  void _showNoConnectionDialog() {
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
              child: Text('Okay'),
            )
          ],
        );
      },
    );
  }

  Future<String> getActualIdSite() async {
    return currentIdSite;
  }

  @override
  Widget build(BuildContext context) {
    log('tanggal sekarang : ${DateTime(now.year, now.month, now.day).toIso8601String()}');
    // getCount();
    // pit.clear();
    setupPit();

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
                    bool isSis = homeState.userAccessCompanyId.value == '1';

                    // if (userAccessId != '1' &&
                    //     userAccessId != '2' &&
                    //     userAccessId != '3') {
                    if (userAccessId != '1' || isSis) {
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
                  return Column(
                    children: [
                      ExportExcelButton(
                        user: user,
                        pit: pit,
                        selectedPit: selectedPit,
                        filteredItemTask: filteredItemTask,
                        idSite: currentIdSite,
                        date:
                            "${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().year}",
                        type: ExportType.oneDay,
                      ),
                      const SizedBox(
                        height: 16,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            bool? confirmSend = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Row(
                                  children: [
                                    Icon(
                                      Icons.warning,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      "Warning",
                                      style: getRedTextStyle(fontSize: 24)
                                          .copyWith(
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                content: Text(
                                  "Are you sure? Please Check Before Send Data!",
                                  style: getBlackTextStyle(),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text("No"),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text("Yes"),
                                  ),
                                ],
                              ),
                            );

                            if (confirmSend == true) {
                              context.read<DailyCheckPostBloc>().add(
                                    DailyCheckPostEvent(
                                      dailyCheck: filteredItemTask,
                                      countAllTire: countAllTire,
                                      allUnit: allUnit,
                                      allTireSize: allTireSize,
                                      typeSend: 'single',
                                    ),
                                  );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: green00968A,
                                  content: Text(
                                    'Successful Save Data!',
                                    style: getWhiteTextStyle(),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: green00968A),
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, color: Colors.white),
                                SizedBox(width: 12),
                                Text('Send Data to CTS',
                                    style: getWhiteTextStyle()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Container();
              }),
              if (selectedMenu == 0)
                const SizedBox(
                  height: 12,
                )
              else
                Container(),
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
                if (state is UnitLoadedState) {
                  setState(() {
                    // Tambahkan setState agar UI diperbarui
                    allUnit = state.units;
                    countAllTire = state.countAllTire;
                    allTireSize = state.allTireSize;
                  });
                  // log('ban daily : ${state.units}');
                }
              }, builder: (context, state) {
                if (state is UnitLoadingState) {
                  return Center(child: CircularProgressIndicator());
                }

                if (state is UnitLoadedState) {
                  switch (selectedMenu) {
                    // Checked Unit
                    case 0:
                      checkedFuture ??= getCheckedTodayFuture();

                      return Column(
                        children: [
                          const SizedBox(height: 12),
                          SelectPitButton(
                            pit: pit,
                            selectedPit: selectedPit,
                            onSelectedPitChanged: (index) {
                              setState(() {
                                selectedPit = index;
                                checkedFuture = getCheckedTodayFuture();
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: refreshCheckedData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                              ),
                              child: Text(
                                'Refresh Checked Data',
                                style: getWhiteTextStyle(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            future: checkedFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Text(
                                  'Error load checked data: ${snapshot.error}',
                                  style: getBlackTextStyle(fontSize: 14),
                                );
                              }

                              final docs = snapshot.data?.docs ?? [];

                              log('docs list daily : $docs');

                              // Ambil semua data dari Firestore
                              final rawData = docs.map((doc) {
                                return doc.data();
                              }).toList();

// Sort dulu dari tanggal terbaru ke terlama
                              rawData.sort((a, b) {
                                final aTanggal = a['tanggal']?.toString() ?? '';
                                final bTanggal = b['tanggal']?.toString() ?? '';
                                return bTanggal.compareTo(aTanggal);
                              });

// DISTINCT BY UNIT
// Kalau ada unit duplikat, yang dipakai adalah data paling terbaru
// karena rawData sudah di-sort descending berdasarkan tanggal.
                              final distinctMap =
                                  <String, Map<String, dynamic>>{};

                              for (final item in rawData) {
                                final unit = item['unit']?.toString() ?? '';

                                if (unit.isEmpty) {
                                  continue;
                                }

                                if (!distinctMap.containsKey(unit)) {
                                  distinctMap[unit] =
                                      Map<String, dynamic>.from(item);
                                }
                              }

                              final distinctDaily = distinctMap.values.toList();

                              log('distinct list daily : $distinctDaily');

                              final keyword = searchQuery.toLowerCase();

                              final filteredData = distinctDaily.where((data) {
                                final unit =
                                    data['unit']?.toString().toLowerCase() ??
                                        '';
                                final model =
                                    data['model']?.toString().toLowerCase() ??
                                        '';

                                if (keyword.isEmpty) return true;

                                return unit.contains(keyword) ||
                                    model.contains(keyword);
                              }).toList();

                              filteredItemTask.clear();

                              for (final item in filteredData) {
                                filteredItemTask
                                    .add(Map<String, dynamic>.from(item));
                              }

                              DateTime? lastUpdate;

                              if (distinctDaily.isNotEmpty) {
                                final tanggal =
                                    distinctDaily.first['tanggal']?.toString();

                                if (tanggal != null && tanggal.isNotEmpty) {
                                  lastUpdate = DateTime.tryParse(tanggal);
                                }
                              }

                              return Column(
                                children: [
                                  Text(
                                    'Total Unit : ${filteredData.length}',
                                    style: getBlackTextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(height: 12),
                                  if (lastUpdate != null)
                                    Column(
                                      children: [
                                        Text(
                                          'Last Update : ${DateFormat('HH:mm:ss dd-MM-yyyy').format(lastUpdate)}',
                                          textAlign: TextAlign.center,
                                          style:
                                              getBlackTextStyle(fontSize: 14),
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),
                                  filteredData.isEmpty
                                      ? Text(
                                          'Empty!',
                                          textAlign: TextAlign.center,
                                          style:
                                              getBlackTextStyle(fontSize: 18),
                                        )
                                      : ListView.builder(
                                          itemCount: filteredData.length,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            final dailyMap =
                                                filteredData[index];
                                            final positionList =
                                                dailyMap['posisi']
                                                        as List<dynamic>? ??
                                                    [];

                                            return Card(
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              color: green00968A,
                                              child: Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 24,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: green00968A,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: ExpansionTile(
                                                  tilePadding: EdgeInsets.zero,
                                                  childrenPadding:
                                                      EdgeInsets.zero,
                                                  title: Row(
                                                    children: [
                                                      Icon(
                                                        Icons.task,
                                                        color: white,
                                                        size: 36,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          '${dailyMap['unit'] ?? ''}${((dailyMap['pit'] != 'Default') ? '\n${dailyMap['pit']}' : '')}',
                                                          style:
                                                              getWhiteTextStyle(
                                                            fontWeight: w700,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  trailing: const SizedBox(
                                                    width: 90,
                                                    child: Icon(
                                                        Icons.arrow_drop_down),
                                                  ),
                                                  children: [
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Name',
                                                          style:
                                                              getWhiteTextStyle(
                                                                  fontSize: 18),
                                                        ),
                                                        SizedBox(
                                                          width: 250,
                                                          child: Text(
                                                            dailyMap['user'] ??
                                                                'No Name',
                                                            textAlign:
                                                                TextAlign.end,
                                                            style:
                                                                getWhiteTextStyle(
                                                              fontWeight: w700,
                                                              fontSize: 18,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Tanggal',
                                                          style:
                                                              getWhiteTextStyle(
                                                                  fontSize: 18),
                                                        ),
                                                        Text(
                                                          dailyMap['tanggal']
                                                                  ?.toString()
                                                                  .split('T')
                                                                  .first ??
                                                              '',
                                                          style:
                                                              getWhiteTextStyle(
                                                            fontWeight: w700,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Waktu',
                                                          style:
                                                              getWhiteTextStyle(
                                                                  fontSize: 18),
                                                        ),
                                                        Text(
                                                          dailyMap['tanggal'] !=
                                                                  null
                                                              ? dailyMap[
                                                                      'tanggal']
                                                                  .toString()
                                                                  .split('T')[1]
                                                                  .substring(
                                                                      0, 5)
                                                              : '',
                                                          style:
                                                              getWhiteTextStyle(
                                                            fontWeight: w700,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          (currentIdSite ==
                                                                      bmbhauling
                                                                          .idSite ||
                                                                  currentIdSite ==
                                                                      '1')
                                                              ? 'KM Unit'
                                                              : 'HM Unit',
                                                          style:
                                                              getWhiteTextStyle(
                                                                  fontSize: 18),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              (dailyMap['hm'] ==
                                                                      '')
                                                                  ? '0'
                                                                  : dailyMap[
                                                                      'hm'],
                                                              style:
                                                                  getWhiteTextStyle(
                                                                fontWeight:
                                                                    w700,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                            (dailyMap['hmNote'] !=
                                                                    null)
                                                                ? Column(
                                                                    crossAxisAlignment:
                                                                        CrossAxisAlignment
                                                                            .end,
                                                                    children: [
                                                                      const SizedBox(
                                                                        height:
                                                                            6,
                                                                      ),
                                                                      Text(
                                                                          'Note : ' + dailyMap['hmNote'] ??
                                                                              '',
                                                                          style:
                                                                              getWhiteTextStyle(fontSize: 18)),
                                                                    ],
                                                                  )
                                                                : Container()
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
                                                      children: [
                                                        Text(
                                                          'Pit',
                                                          style:
                                                              getWhiteTextStyle(
                                                                  fontSize: 18),
                                                        ),
                                                        Text(
                                                          dailyMap['pit'] ?? '',
                                                          style:
                                                              getWhiteTextStyle(
                                                            fontWeight: w700,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 12),
                                                    ListView.builder(
                                                      itemCount:
                                                          positionList.length,
                                                      shrinkWrap: true,
                                                      physics:
                                                          const NeverScrollableScrollPhysics(),
                                                      itemBuilder:
                                                          (context, posIndex) {
                                                        final pl = positionList[
                                                            posIndex];
                                                        List<dynamic> luka = [];

                                                        if (pl['luka'] !=
                                                                null &&
                                                            pl['luka']
                                                                is! String) {
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
                                                                    fontSize:
                                                                        18,
                                                                  ),
                                                                ),
                                                                Column(
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .end,
                                                                  children: [
                                                                    Row(
                                                                      children: [
                                                                        Text(
                                                                          '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
                                                                          style:
                                                                              getWhiteTextStyle(
                                                                            fontWeight:
                                                                                w700,
                                                                            fontSize:
                                                                                18,
                                                                          ),
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                6),
                                                                        (pl['temperatureStatus'] !=
                                                                                null)
                                                                            ? TemperatureStatusBadgeWidget(
                                                                                status: pl['temperatureStatus'],
                                                                              )
                                                                            : Container(),
                                                                      ],
                                                                    ),
                                                                    if (pl['adjusmentPressure'] != null &&
                                                                        pl['adjusmentPressure'] !=
                                                                            '0' &&
                                                                        pl['adjusmentPressure'] !=
                                                                            '')
                                                                      Text(
                                                                        '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
                                                                        style:
                                                                            getWhiteTextStyle(
                                                                          fontWeight:
                                                                              w700,
                                                                          fontSize:
                                                                              18,
                                                                        ),
                                                                      ),
                                                                    if (luka
                                                                        .isNotEmpty)
                                                                      Text(
                                                                        luka.join(
                                                                            '\n'),
                                                                        textAlign:
                                                                            TextAlign.end,
                                                                        style:
                                                                            getWhiteTextStyle(
                                                                          fontWeight:
                                                                              w700,
                                                                          fontSize:
                                                                              18,
                                                                        ),
                                                                      ),
                                                                    Text(
                                                                      '${(pl['rating'] == '' || pl['rating'] == null) ? '' : 'Rating ${pl['rating']}'}',
                                                                      style:
                                                                          getWhiteTextStyle(
                                                                        fontWeight:
                                                                            w700,
                                                                        fontSize:
                                                                            18,
                                                                      ),
                                                                    ),
                                                                    (userAccessId ==
                                                                            '1')
                                                                        ? Column(
                                                                            children: [
                                                                              SizedBox(height: 12),
                                                                              Text(
                                                                                'RTD ${pl['rtd1'] ?? '-'}/${pl['rtd2'] ?? '-'}',
                                                                                style: getWhiteTextStyle(
                                                                                  fontWeight: w700,
                                                                                  fontSize: 18,
                                                                                ),
                                                                              ),
                                                                            ],
                                                                          )
                                                                        : Container(),
                                                                    const SizedBox(
                                                                        height:
                                                                            12),
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
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              );
                            },
                          ),
                        ],
                      );
                    // return Column(
                    //   children: [
                    //     const SizedBox(
                    //       height: 12,
                    //     ),
                    //     SelectPitButton(
                    //         pit: pit,
                    //         selectedPit: selectedPit,
                    //         onSelectedPitChanged: (index) {
                    //           setState(() {
                    //             selectedPit = index;
                    //           });
                    //         }),
                    //     const SizedBox(
                    //       height: 12,
                    //     ),
                    //     StreamBuilder(
                    //         stream: firestore
                    //             .collection('daily_pressure')
                    //             .where('tanggal',
                    //                 isGreaterThanOrEqualTo:
                    //                     DateTime(now.year, now.month, now.day)
                    //                         .toIso8601String())
                    //             .where('tanggal',
                    //                 isLessThanOrEqualTo: DateTime(now.year,
                    //                         now.month, now.day, 23, 59, 59)
                    //                     .toIso8601String())
                    //             .where('idSite', isEqualTo: currentIdSite)
                    //             .snapshots(),
                    //         builder: (context, snapshot) {
                    //           if (snapshot.connectionState ==
                    //               ConnectionState.waiting) {
                    //             return CircularProgressIndicator.adaptive();
                    //           }
                    //           if (snapshot.connectionState ==
                    //               ConnectionState.active) {
                    //             final allData = snapshot.data?.docs
                    //                 .map((doc) => DailyPress.fromFirestore(
                    //                     doc.data() as Map<String, dynamic>))
                    //                 .toList();

                    //             final distinctDaily =
                    //                 Set<DailyPress>.from(allData ?? [])
                    //                     .toList();

                    //             final tmpDailyData =
                    //                 snapshot.data?.docs ?? [];

                    //             final dailyData = distinctDaily.where((doc) {
                    //               // pilih all pit
                    //               if (pit.isNotEmpty) {
                    //                 if (pit[selectedPit] == 'All') {
                    //                   return doc.idSite == currentIdSite;
                    //                 }

                    //                 // ada pit
                    //                 if (doc.pit != 'Default') {
                    //                   return doc.idSite == currentIdSite &&
                    //                       doc.pit == pit[selectedPit];
                    //                 }
                    //               }

                    //               // tidak ada pit
                    //               return doc.idSite == currentIdSite;
                    //             }).toList();

                    //             // untuk data export excel
                    //             filteredItemTask.clear();
                    //             filteredItemTask.clear();

                    //             dailyData.forEach((item) {
                    //               Map<String, dynamic> cast =
                    //                   item.toFirestore();
                    //               filteredItemTask.add(cast);
                    //             });

                    //             return Column(
                    //               children: [
                    //                 Text(
                    //                   'Total Unit : ${distinctDaily.length ?? 0}',
                    //                   style: getBlackTextStyle(
                    //                     fontSize: 20,
                    //                   ),
                    //                 ),
                    //                 const SizedBox(
                    //                   height: 12,
                    //                 ),
                    //                 (snapshot.data?.size != 0)
                    //                     ? Column(
                    //                         children: [
                    //                           Builder(builder: (context) {
                    //                             // Parsing string to DateTime object
                    //                             DateTime parsedDate =
                    //                                 DateTime.parse(snapshot
                    //                                     .data
                    //                                     ?.docs[snapshot
                    //                                             .data!.size -
                    //                                         1]
                    //                                     .data()['tanggal']);

                    //                             // Formatting DateTime to the desired format
                    //                             String formattedDate = DateFormat(
                    //                                     'HH:mm:ss dd-MM-yyyy')
                    //                                 .format(parsedDate);
                    //                             return Text(
                    //                               'Last Update : ${formattedDate}',
                    //                               textAlign: TextAlign.center,
                    //                               style: getBlackTextStyle(
                    //                                 fontSize: 14,
                    //                               ),
                    //                             );
                    //                           }),
                    //                           const SizedBox(
                    //                             height: 12,
                    //                           ),
                    //                         ],
                    //                       )
                    //                     : Container(),
                    //               ],
                    //             );
                    //           }

                    //           return Container();
                    //         }),
                    //     PaginateFirestore(
                    //         query: selectedPit == 0
                    //             ? firestore
                    //                 .collection('daily_pressure')
                    //                 .where('tanggal',
                    //                     isGreaterThanOrEqualTo:
                    //                         DateTime(now.year, now.month, now.day)
                    //                             .toIso8601String())
                    //                 .where('tanggal',
                    //                     isLessThanOrEqualTo:
                    //                         DateTime(now.year, now.month, now.day, 23, 59, 59)
                    //                             .toIso8601String())
                    //                 .where('idSite', isEqualTo: currentIdSite)
                    //                 .orderBy('tanggal', descending: true)
                    //             : firestore
                    //                 .collection('daily_pressure')
                    //                 .where('tanggal',
                    //                     isGreaterThanOrEqualTo:
                    //                         DateTime(now.year, now.month, now.day)
                    //                             .toIso8601String())
                    //                 .where('tanggal',
                    //                     isLessThanOrEqualTo:
                    //                         DateTime(now.year, now.month, now.day, 23, 59, 59)
                    //                             .toIso8601String())
                    //                 .where('idSite', isEqualTo: currentIdSite)
                    //                 .where('pit', isEqualTo: pit[selectedPit])
                    //                 .orderBy('tanggal', descending: true),
                    //         itemBuilderType: PaginateBuilderType.listView,
                    //         shrinkWrap: true,
                    //         physics: NeverScrollableScrollPhysics(),
                    //         itemsPerPage: 10,
                    //         // isLive: true,
                    //         isLive: false,
                    //         initialLoader: const Center(child: CircularProgressIndicator.adaptive()),
                    //         bottomLoader: const Center(child: CircularProgressIndicator.adaptive()),
                    //         itemBuilder: (context, snapshot, firebaseIndex) {
                    //           final Map<String, dynamic> dailyMap =
                    //               snapshot[firebaseIndex].data()
                    //                   as Map<String, dynamic>;
                    //           final positionList =
                    //               dailyMap['posisi'] as List<dynamic>;

                    //           if (selectedPit != 0) {
                    //             if (dailyMap['pit'] != pit[selectedPit]) {
                    //               return Container();
                    //             }
                    //           }

                    //           if (searchQuery.isNotEmpty &&
                    //               !dailyMap['unit']!
                    //                   .toLowerCase()
                    //                   .contains(searchQuery)) {
                    //             return Container();
                    //           }

                    //           return Card(
                    //               elevation: 2,
                    //               shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(12),
                    //               ),
                    //               color: green00968A,
                    //               child: Container(
                    //                 width: double.infinity,
                    //                 padding: EdgeInsets.symmetric(
                    //                     horizontal: 12, vertical: 24),
                    //                 decoration: BoxDecoration(
                    //                   color: green00968A,
                    //                   borderRadius: BorderRadius.circular(12),
                    //                 ),
                    //                 child: ExpansionTile(
                    //                   tilePadding: EdgeInsets.zero,
                    //                   childrenPadding: EdgeInsets.all(0),
                    //                   title: Row(
                    //                     children: [
                    //                       Icon(
                    //                         Icons.task,
                    //                         color: white,
                    //                         size: 36,
                    //                       ),
                    //                       const SizedBox(
                    //                         width: 12,
                    //                       ),
                    //                       Text(
                    //                         dailyMap['unit'] +
                    //                             '${((dailyMap['pit'] != 'Default') ? '\n' + dailyMap['pit'] : '')}',
                    //                         style: getWhiteTextStyle(
                    //                             fontWeight: w700,
                    //                             fontSize: 18),
                    //                       )
                    //                     ],
                    //                   ),
                    //                   trailing: SizedBox(
                    //                     width: 90,
                    //                     child: Icon(Icons.arrow_drop_down),
                    //                   ),
                    //                   children: [
                    //                     const SizedBox(
                    //                       height: 12,
                    //                     ),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           'Name',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         Container(
                    //                           width: 250,
                    //                           child: Text(
                    //                             dailyMap['user'] ?? 'No Name',
                    //                             textAlign: TextAlign.end,
                    //                             style: getWhiteTextStyle(
                    //                                 fontWeight: w700,
                    //                                 fontSize: 18),
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(
                    //                       height: 12,
                    //                     ),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           'Tanggal',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         Text(
                    //                           dailyMap['tanggal']
                    //                                   .split('T')[0] ??
                    //                               '',
                    //                           style: getWhiteTextStyle(
                    //                               fontWeight: w700,
                    //                               fontSize: 18),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(
                    //                       height: 12,
                    //                     ),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           'Waktu',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         Text(
                    //                           dailyMap['tanggal']
                    //                               .split('T')[1]
                    //                               .substring(0, 5),
                    //                           style: getWhiteTextStyle(
                    //                               fontWeight: w700,
                    //                               fontSize: 18),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(
                    //                       height: 12,
                    //                     ),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           (currentIdSite ==
                    //                                   bmbhauling.idSite)
                    //                               ? 'KM Unit'
                    //                               : 'HM Unit',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         Text(
                    //                           dailyMap['hm'] ?? '',
                    //                           style: getWhiteTextStyle(
                    //                               fontWeight: w700,
                    //                               fontSize: 18),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(
                    //                       height: 12,
                    //                     ),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           'Pit',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         Text(
                    //                           dailyMap['pit'],
                    //                           style: getWhiteTextStyle(
                    //                               fontWeight: w700,
                    //                               fontSize: 18),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(
                    //                       height: 12,
                    //                     ),
                    //                     Column(
                    //                       children: positionList.map((pl) {
                    //                         final plIndex =
                    //                             positionList.indexOf(pl);
                    //                         List<dynamic> luka = [];

                    //                         if (pl['luka'] != null &&
                    //                             pl['luka'] is! String) {
                    //                           luka =
                    //                               pl['luka'] as List<dynamic>;
                    //                         }

                    //                         return Column(
                    //                           children: [
                    //                             Row(
                    //                               mainAxisAlignment:
                    //                                   MainAxisAlignment
                    //                                       .spaceBetween,
                    //                               crossAxisAlignment:
                    //                                   CrossAxisAlignment
                    //                                       .center,
                    //                               children: [
                    //                                 Text(
                    //                                   'Pos. ${pl['pos']}',
                    //                                   style:
                    //                                       getWhiteTextStyle(
                    //                                           fontSize: 18),
                    //                                 ),
                    //                                 Column(
                    //                                   crossAxisAlignment:
                    //                                       CrossAxisAlignment
                    //                                           .end,
                    //                                   mainAxisAlignment:
                    //                                       MainAxisAlignment
                    //                                           .center,
                    //                                   children: [
                    //                                     Column(
                    //                                       crossAxisAlignment:
                    //                                           CrossAxisAlignment
                    //                                               .end,
                    //                                       children: [
                    //                                         Row(
                    //                                           children: [
                    //                                             Text(
                    //                                               '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
                    //                                               style: getWhiteTextStyle(
                    //                                                   fontWeight:
                    //                                                       w700,
                    //                                                   fontSize:
                    //                                                       18),
                    //                                             ),
                    //                                             const SizedBox(
                    //                                               width: 6,
                    //                                             ),
                    //                                             (pl['temperatureStatus'] !=
                    //                                                     null)
                    //                                                 ? TemperatureStatusBadgeWidget(
                    //                                                     status:
                    //                                                         pl['temperatureStatus'])
                    //                                                 : Container()
                    //                                             // Text(
                    //                                             //   // '${(pl['temperatureStatus'] == '' || pl['temperatureStatus'] == null) ? 'HOT' : pl['temperatureStatus']}',
                    //                                             //   '${(pl['temperatureStatus'])}',
                    //                                             //   style: getWhiteTextStyle(
                    //                                             //       fontWeight:
                    //                                             //           w700,
                    //                                             //       fontSize:
                    //                                             //           18),
                    //                                             // ),
                    //                                           ],
                    //                                         ),
                    //                                         (pl['adjusmentPressure'] != null &&
                    //                                                 pl['adjusmentPressure'] !=
                    //                                                     '0' &&
                    //                                                 pl['adjusmentPressure'] !=
                    //                                                     '')
                    //                                             ? Text(
                    //                                                 '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
                    //                                                 style: getWhiteTextStyle(
                    //                                                     fontWeight:
                    //                                                         w700,
                    //                                                     fontSize:
                    //                                                         18),
                    //                                               )
                    //                                             : Container(),
                    //                                       ],
                    //                                     ),
                    //                                     (luka.isEmpty ||
                    //                                             luka == null)
                    //                                         ? Container()
                    //                                         : Text(
                    //                                             pl['luka']
                    //                                                 .join(
                    //                                                     '\n'),
                    //                                             textAlign:
                    //                                                 TextAlign
                    //                                                     .end,
                    //                                             style: getWhiteTextStyle(
                    //                                                 fontWeight:
                    //                                                     w700,
                    //                                                 fontSize:
                    //                                                     18),
                    //                                           ),
                    //                                     Text(
                    //                                         '${(pl['rating'] == '' || pl['rating'] == null) ? '' : 'Rating ${pl['rating']}'}',
                    //                                         style:
                    //                                             getWhiteTextStyle(
                    //                                                 fontWeight:
                    //                                                     w700,
                    //                                                 fontSize:
                    //                                                     18)),
                    //                                     // Jangan lupa tambahkan IDSite 33
                    //                                     if (pl['tireAccessories'] !=
                    //                                             null &&
                    //                                         pl['tireAccessories']
                    //                                             .isNotEmpty &&
                    //                                         currentIdSite ==
                    //                                             '33')
                    //                                       Column(
                    //                                         crossAxisAlignment:
                    //                                             CrossAxisAlignment
                    //                                                 .end,
                    //                                         children: [
                    //                                           Text(
                    //                                               'Tire Accessories',
                    //                                               style: getWhiteTextStyle(
                    //                                                   fontWeight:
                    //                                                       w700,
                    //                                                   fontSize:
                    //                                                       14)),
                    //                                           const SizedBox(
                    //                                             height: 6,
                    //                                           ),
                    //                                           Column(
                    //                                             crossAxisAlignment:
                    //                                                 CrossAxisAlignment
                    //                                                     .end,
                    //                                             children: pl[
                    //                                                     'tireAccessories']
                    //                                                 .map<Widget>(
                    //                                                     (acc) {
                    //                                               return Column(
                    //                                                 crossAxisAlignment:
                    //                                                     CrossAxisAlignment
                    //                                                         .end,
                    //                                                 children: [
                    //                                                   Row(
                    //                                                     children: [
                    //                                                       Text(acc['name'] + ' (' + acc['condition'] + '${(acc['remark'] != '') ? ': ${acc['remark']}' : ''})',
                    //                                                           textAlign: TextAlign.right,
                    //                                                           style: getWhiteTextStyle(fontWeight: w500, fontSize: 14)),
                    //                                                     ],
                    //                                                   ),
                    //                                                   const SizedBox(
                    //                                                     height:
                    //                                                         6,
                    //                                                   ),
                    //                                                   if (acc['image'].isNotEmpty &&
                    //                                                       acc['image'] !=
                    //                                                           'image.png' &&
                    //                                                       acc['image'] !=
                    //                                                           '')
                    //                                                     InkWell(
                    //                                                       onTap:
                    //                                                           () async {
                    //                                                         await showDialog(
                    //                                                           context: context,
                    //                                                           barrierDismissible: true,
                    //                                                           builder: (_) {
                    //                                                             return Dialog(
                    //                                                               backgroundColor: Colors.transparent,
                    //                                                               elevation: 0,
                    //                                                               child: Center(
                    //                                                                 child: Column(
                    //                                                                   mainAxisSize: MainAxisSize.min,
                    //                                                                   children: [
                    //                                                                     // === GAMBAR + TOMBOL CLOSE ===
                    //                                                                     Stack(
                    //                                                                       children: [
                    //                                                                         Container(
                    //                                                                           width: MediaQuery.of(context).size.width * 0.6,
                    //                                                                           height: MediaQuery.of(context).size.height * 0.6,
                    //                                                                           decoration: BoxDecoration(
                    //                                                                             borderRadius: BorderRadius.circular(12),
                    //                                                                           ),
                    //                                                                           clipBehavior: Clip.antiAlias,
                    //                                                                           child: Image.network(
                    //                                                                             acc['image'],
                    //                                                                             fit: BoxFit.contain,
                    //                                                                           ),
                    //                                                                         ),
                    //                                                                         Positioned(
                    //                                                                           right: 8,
                    //                                                                           top: 8,
                    //                                                                           child: InkWell(
                    //                                                                             onTap: () => Navigator.of(context).pop(),
                    //                                                                             borderRadius: BorderRadius.circular(20),
                    //                                                                             child: Container(
                    //                                                                               padding: const EdgeInsets.all(6),
                    //                                                                               decoration: BoxDecoration(
                    //                                                                                 color: Colors.black45,
                    //                                                                                 shape: BoxShape.circle,
                    //                                                                               ),
                    //                                                                               child: const Icon(
                    //                                                                                 LucideIcons.x,
                    //                                                                                 color: Colors.white,
                    //                                                                                 size: 20,
                    //                                                                               ),
                    //                                                                             ),
                    //                                                                           ),
                    //                                                                         ),
                    //                                                                       ],
                    //                                                                     ),

                    //                                                                     const SizedBox(height: 12),

                    //                                                                     // === TEKS KETERANGAN ===
                    //                                                                     Container(
                    //                                                                       padding: const EdgeInsets.all(8),
                    //                                                                       decoration: BoxDecoration(
                    //                                                                         color: Colors.white,
                    //                                                                         borderRadius: BorderRadius.circular(16),
                    //                                                                       ),
                    //                                                                       child: Text(
                    //                                                                         '#${dailyMap['unit']} Pos. ${pl['pos']} | ${acc['name']} ${acc['condition']} ${(acc['remark'] != '') ? ': ${acc['remark']}' : ''}',
                    //                                                                         style: getBlackTextStyle(
                    //                                                                           fontWeight: w700,
                    //                                                                         ),
                    //                                                                         textAlign: TextAlign.center,
                    //                                                                       ),
                    //                                                                     ),
                    //                                                                   ],
                    //                                                                 ),
                    //                                                               ),
                    //                                                             );
                    //                                                           },
                    //                                                         );
                    //                                                       },
                    //                                                       child:
                    //                                                           SizedBox(
                    //                                                         width: 150,
                    //                                                         height: 100,
                    //                                                         child: Image.network(
                    //                                                           acc['image'],
                    //                                                           fit: BoxFit.cover,
                    //                                                         ),
                    //                                                       ),
                    //                                                     )
                    //                                                 ],
                    //                                               );
                    //                                             }).toList(),
                    //                                           ),
                    //                                         ],
                    //                                       ),
                    //                                     const SizedBox(
                    //                                       height: 12,
                    //                                     ),
                    //                                   ],
                    //                                 ),
                    //                               ],
                    //                             ),
                    //                             Divider(
                    //                               color: white,
                    //                               thickness: 1.5,
                    //                             ),
                    //                           ],
                    //                         );
                    //                       }).toList(),
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ));

                    //           ;
                    //         }),
                    //   ],
                    // );

                    // Unit Low Pressure
                    case 1:
                      checkedFuture ??= getCheckedTodayFuture();

                      if (homeState.userAccessCompanyId.value == '1' &&
                          homeState.userAccessId.value == '1') {
                        // ============================================================
                        // USER COMPANY 1 + ACCESS ID 1
                        // MENAMPILKAN UNIT YANG MEMILIKI PRESSURE 0 PSI
                        // ============================================================

                        bool isZeroPressure(dynamic pressureValue) {
                          final rawValue = pressureValue
                              ?.toString()
                              .trim()
                              .replaceAll(',', '.');

                          // Nilai null atau kosong pada tampilan lama juga ditulis 0 Psi,
                          // sehingga pada filter dianggap sebagai pressure 0 Psi.
                          if (rawValue == null || rawValue.isEmpty) {
                            return true;
                          }

                          final pressure = double.tryParse(rawValue);

                          return pressure != null && pressure == 0;
                        }

                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            SelectPitButton(
                              pit: pit,
                              selectedPit: selectedPit,
                              onSelectedPitChanged: (index) {
                                setState(() {
                                  selectedPit = index;
                                  checkedFuture = getCheckedTodayFuture();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: refreshCheckedData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                ),
                                child: Text(
                                  'Refresh Data Incomplete Check',
                                  style: getWhiteTextStyle(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              future: checkedFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator.adaptive(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Text(
                                    'Error load data pressure 0 Psi: ${snapshot.error}',
                                    style: getBlackTextStyle(fontSize: 14),
                                  );
                                }

                                final docs = snapshot.data?.docs ?? [];

                                final allData = docs.map((doc) {
                                  final data = doc.data();

                                  return DailyPress.fromFirestore(data);
                                }).toList();

                                // Urutkan berdasarkan tanggal terbaru
                                allData.sort((a, b) {
                                  return b.tanggal.compareTo(a.tanggal);
                                });

                                final keyword =
                                    searchQuery.trim().toLowerCase();

                                // Ambil unit yang memiliki minimal satu posisi 0 Psi
                                final zeroPressureData = allData.where((data) {
                                  if (keyword.isNotEmpty) {
                                    final unit = data.unit.toLowerCase();

                                    if (!unit.contains(keyword)) {
                                      return false;
                                    }
                                  }

                                  return data.posisi.any((position) {
                                    return isZeroPressure(position.pressure);
                                  });
                                }).toList();

                                if (zeroPressureData.isEmpty) {
                                  return Text(
                                    'Tidak ada data pressure 0 Psi!',
                                    style: getBlackTextStyle(),
                                  );
                                }

                                return Column(
                                  children: [
                                    Text(
                                      'Total Unit : ${zeroPressureData.length}',
                                      textAlign: TextAlign.center,
                                      style: getBlackTextStyle(
                                        fontSize: 20,
                                        fontWeight: w700,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ListView.builder(
                                      itemCount: zeroPressureData.length,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemBuilder: (context, index) {
                                        final data = zeroPressureData[index];

                                        // Hanya mengambil posisi yang memiliki 0 Psi
                                        final zeroPressurePositions =
                                            data.posisi.where((position) {
                                          return isZeroPressure(
                                              position.pressure);
                                        }).toList();

                                        return Card(
                                          elevation: 2,
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 24,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: ExpansionTile(
                                              tilePadding: EdgeInsets.zero,
                                              childrenPadding: EdgeInsets.zero,
                                              iconColor: white,
                                              collapsedIconColor: white,
                                              title: Row(
                                                children: [
                                                  Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: white,
                                                    size: 36,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          data.unit +
                                                              '${data.pit != 'Default' ? '\n${data.pit}' : ''}',
                                                          style:
                                                              getWhiteTextStyle(
                                                            fontWeight: w700,
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                        Text(
                                                          '${zeroPressurePositions.length} posisi terdeteksi',
                                                          style:
                                                              getWhiteTextStyle(
                                                            fontSize: 14,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              trailing: const SizedBox(
                                                width: 90,
                                                child: Icon(
                                                  Icons.arrow_drop_down,
                                                ),
                                              ),
                                              children: [
                                                const SizedBox(height: 12),

                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Name',
                                                      style: getWhiteTextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      width: 250,
                                                      child: Text(
                                                        data.user.isEmpty
                                                            ? 'No Name'
                                                            : data.user,
                                                        textAlign:
                                                            TextAlign.end,
                                                        style:
                                                            getWhiteTextStyle(
                                                          fontWeight: w700,
                                                          fontSize: 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 12),

                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Tanggal',
                                                      style: getWhiteTextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    Text(
                                                      data.tanggal
                                                          .split('T')[0],
                                                      style: getWhiteTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 12),

                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Waktu',
                                                      style: getWhiteTextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    Text(
                                                      data.tanggal
                                                          .split('T')[1]
                                                          .substring(0, 5),
                                                      style: getWhiteTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 12),

                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'HM Unit',
                                                      style: getWhiteTextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    Text(
                                                      data.hm,
                                                      style: getWhiteTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 12),

                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Text(
                                                      'Pit',
                                                      style: getWhiteTextStyle(
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    Text(
                                                      data.pit,
                                                      style: getWhiteTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                const SizedBox(height: 12),

                                                // Hanya menampilkan posisi pressure 0 Psi
                                                ListView.builder(
                                                  itemCount:
                                                      zeroPressurePositions
                                                          .length,
                                                  shrinkWrap: true,
                                                  physics:
                                                      const NeverScrollableScrollPhysics(),
                                                  itemBuilder:
                                                      (context, posIndex) {
                                                    final pl =
                                                        zeroPressurePositions[
                                                            posIndex];

                                                    List<dynamic> luka = [];

                                                    if (pl.luka != null &&
                                                        pl.luka is! String) {
                                                      luka = pl.luka
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
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                Icon(
                                                                  Icons
                                                                      .error_outline,
                                                                  color: white,
                                                                  size: 24,
                                                                ),
                                                                const SizedBox(
                                                                    width: 8),
                                                                Text(
                                                                  'Pos. ${pl.pos}',
                                                                  style:
                                                                      getWhiteTextStyle(
                                                                    fontWeight:
                                                                        w700,
                                                                    fontSize:
                                                                        18,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .end,
                                                              children: [
                                                                Text(
                                                                  '0 Psi',
                                                                  style:
                                                                      getWhiteTextStyle(
                                                                    fontWeight:
                                                                        w700,
                                                                    fontSize:
                                                                        22,
                                                                  ),
                                                                ),
                                                                Text(
                                                                  'Pressure belum diinput',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .end,
                                                                  style:
                                                                      getWhiteTextStyle(
                                                                    fontWeight:
                                                                        w700,
                                                                    fontSize:
                                                                        14,
                                                                  ),
                                                                ),
                                                                if (pl.size !=
                                                                        null &&
                                                                    pl.size!
                                                                        .isNotEmpty)
                                                                  Text(
                                                                    'Size: ${pl.size}',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                    style:
                                                                        getWhiteTextStyle(
                                                                      fontSize:
                                                                          14,
                                                                    ),
                                                                  ),
                                                                if (pl.adjusmentPressure !=
                                                                        null &&
                                                                    pl.adjusmentPressure !=
                                                                        '0' &&
                                                                    pl.adjusmentPressure !=
                                                                        '')
                                                                  Text(
                                                                    '${pl.adjusmentPressure} Psi '
                                                                    '(Adj. Pressure)',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                    style:
                                                                        getWhiteTextStyle(
                                                                      fontWeight:
                                                                          w700,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                  ),
                                                                if (luka
                                                                    .isNotEmpty)
                                                                  SizedBox(
                                                                    width: 200,
                                                                    child: Text(
                                                                      luka.join(
                                                                          '\n'),
                                                                      textAlign:
                                                                          TextAlign
                                                                              .end,
                                                                      style:
                                                                          getWhiteTextStyle(
                                                                        fontWeight:
                                                                            w700,
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                if (pl.rating !=
                                                                        null &&
                                                                    pl.rating!
                                                                        .isNotEmpty)
                                                                  Text(
                                                                    'Rating ${pl.rating}',
                                                                    textAlign:
                                                                        TextAlign
                                                                            .end,
                                                                    style:
                                                                        getWhiteTextStyle(
                                                                      fontWeight:
                                                                          w700,
                                                                      fontSize:
                                                                          16,
                                                                    ),
                                                                  ),
                                                                Container(
                                                                  width: 120,
                                                                  height: 60,
                                                                  margin:
                                                                      const EdgeInsets
                                                                          .only(
                                                                    top: 12,
                                                                    bottom: 12,
                                                                  ),
                                                                  child:
                                                                      ButtonWidget(
                                                                    name: Text(
                                                                      'Edit',
                                                                      textAlign:
                                                                          TextAlign
                                                                              .center,
                                                                      style:
                                                                          getWhiteTextStyle(),
                                                                    ),
                                                                    color:
                                                                        green00968A,
                                                                    function:
                                                                        () {
                                                                      final List<
                                                                              Position>
                                                                          position =
                                                                          [];

                                                                      for (int i =
                                                                              0;
                                                                          i < data.posisi.length;
                                                                          i++) {
                                                                        final p =
                                                                            data.posisi[i];

                                                                        position
                                                                            .add(
                                                                          Position(
                                                                            pos:
                                                                                p.pos,
                                                                            pressure:
                                                                                p.pressure,
                                                                            temperatureStatus:
                                                                                p.temperatureStatus,
                                                                            rating:
                                                                                p.rating,
                                                                            adjusmentPressure:
                                                                                p.adjusmentPressure,
                                                                            adjustmentTemperatureStatus:
                                                                                p.adjustmentTemperatureStatus,
                                                                            luka:
                                                                                p.luka,
                                                                            image:
                                                                                p.image,
                                                                            size:
                                                                                p.size,
                                                                            idInventory:
                                                                                p.idInventory,
                                                                            idUnit:
                                                                                p.idUnit,
                                                                            idDaily:
                                                                                p.idDaily,
                                                                            kondisi:
                                                                                p.kondisi,
                                                                          ),
                                                                        );
                                                                      }

                                                                      final dataUnit =
                                                                          {
                                                                        'unitNumber':
                                                                            data.unit,
                                                                        'hm': data
                                                                            .hm,
                                                                        'pit': data
                                                                            .pit,
                                                                        'position':
                                                                            position,
                                                                        'reccPress':
                                                                            state.reccPress,
                                                                      };

                                                                      Navigator
                                                                          .pushNamed(
                                                                        context,
                                                                        DailyCheckFormPage
                                                                            .routeName,
                                                                        arguments:
                                                                            dataUnit,
                                                                      );
                                                                    },
                                                                  ),
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
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      } else {
                        // ============================================================
                        // USER LAIN
                        // TETAP MENGGUNAKAN LOGIKA LOW PRESSURE LAMA
                        // ============================================================

                        final reccPressMap = <String, int>{};

                        for (final item in state.reccPress) {
                          item.forEach((key, value) {
                            reccPressMap[key.toString()] =
                                int.tryParse(value.toString()) ?? 0;
                          });
                        }

                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            SelectPitButton(
                              pit: pit,
                              selectedPit: selectedPit,
                              onSelectedPitChanged: (index) {
                                setState(() {
                                  selectedPit = index;
                                  checkedFuture = getCheckedTodayFuture();
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            if (homeState.selectedSite?.idCompany == '2')
                              Text(
                                'Target Low Pressure : ${(state.countAllTire * 0.01).ceil()} Tire',
                                style: getBlackTextStyle(fontSize: 14),
                              )
                            else
                              Container(),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: refreshCheckedData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                ),
                                child: Text(
                                  'Refresh Low Pressure Data',
                                  style: getWhiteTextStyle(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              future: checkedFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator.adaptive(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Text(
                                    'Error load low pressure data: ${snapshot.error}',
                                    style: getBlackTextStyle(fontSize: 14),
                                  );
                                }

                                final docs = snapshot.data?.docs ?? [];

                                final allData = docs.map((doc) {
                                  final data = doc.data();

                                  return DailyPress.fromFirestore(data);
                                }).toList();

                                allData.sort((a, b) {
                                  return b.tanggal.compareTo(a.tanggal);
                                });

                                final keyword = searchQuery.toLowerCase();

                                final lowPressureData = allData.where((data) {
                                  if (keyword.isNotEmpty) {
                                    final unit = data.unit.toLowerCase();

                                    if (!unit.contains(keyword)) {
                                      return false;
                                    }
                                  }

                                  return data.posisi.any((position) {
                                    final tireSize = position.size;

                                    if (tireSize == null || tireSize.isEmpty) {
                                      return false;
                                    }

                                    final pressure = int.tryParse(
                                            position.pressure ?? '0') ??
                                        0;

                                    if (pressure == 0) {
                                      return false;
                                    }

                                    final adjustedPressure =
                                        position.adjusmentPressure;

                                    if (adjustedPressure.isNotEmpty &&
                                        adjustedPressure != '0') {
                                      return false;
                                    }

                                    final recommendedPressure =
                                        reccPressMap[tireSize] ?? 0;

                                    if (recommendedPressure == 0) {
                                      return false;
                                    }

                                    return pressure < recommendedPressure;
                                  });
                                }).toList();

                                if (lowPressureData.isEmpty) {
                                  return Text(
                                    'There is no low pressure data!',
                                    style: getBlackTextStyle(),
                                  );
                                }

                                return ListView.builder(
                                  itemCount: lowPressureData.length,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (context, index) {
                                    final data = lowPressureData[index];

                                    return Card(
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 24,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: ExpansionTile(
                                          tilePadding: EdgeInsets.zero,
                                          childrenPadding: EdgeInsets.zero,
                                          title: Row(
                                            children: [
                                              Icon(
                                                Icons.task,
                                                color: white,
                                                size: 36,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      data.unit +
                                                          '${data.pit != 'Default' ? '\n${data.pit}' : ''}',
                                                      style: getWhiteTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                    Text(
                                                      'LOW PRESSURE!',
                                                      style: getWhiteTextStyle(
                                                        fontWeight: w700,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          trailing: const SizedBox(
                                            width: 90,
                                            child: Icon(
                                              Icons.arrow_drop_down,
                                            ),
                                          ),
                                          children: [
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Name',
                                                  style: getWhiteTextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 250,
                                                  child: Text(
                                                    data.user == ''
                                                        ? 'No Name'
                                                        : data.user,
                                                    textAlign: TextAlign.end,
                                                    style: getWhiteTextStyle(
                                                      fontWeight: w700,
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Tanggal',
                                                  style: getWhiteTextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                Text(
                                                  data.tanggal.split('T')[0],
                                                  style: getWhiteTextStyle(
                                                    fontWeight: w700,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Waktu',
                                                  style: getWhiteTextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                Text(
                                                  data.tanggal
                                                      .split('T')[1]
                                                      .substring(0, 5),
                                                  style: getWhiteTextStyle(
                                                    fontWeight: w700,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'HM Unit',
                                                  style: getWhiteTextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                Text(
                                                  data.hm,
                                                  style: getWhiteTextStyle(
                                                    fontWeight: w700,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  'Pit',
                                                  style: getWhiteTextStyle(
                                                    fontSize: 18,
                                                  ),
                                                ),
                                                Text(
                                                  data.pit,
                                                  style: getWhiteTextStyle(
                                                    fontWeight: w700,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            ListView.builder(
                                              itemCount: data.posisi.length,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemBuilder: (context, posIndex) {
                                                final pl =
                                                    data.posisi[posIndex];

                                                List<dynamic> luka = [];

                                                if (pl.luka != null &&
                                                    pl.luka is! String) {
                                                  luka =
                                                      pl.luka as List<dynamic>;
                                                }

                                                final tireSize = pl.size;

                                                final pressure = int.tryParse(
                                                        pl.pressure ?? '0') ??
                                                    0;

                                                final recommendedPressure =
                                                    reccPressMap[tireSize] ?? 0;

                                                final adjustedPressure =
                                                    pl.adjusmentPressure;

                                                final isThisPositionLow =
                                                    tireSize != null &&
                                                        tireSize.isNotEmpty &&
                                                        pressure > 0 &&
                                                        recommendedPressure >
                                                            0 &&
                                                        pressure <
                                                            recommendedPressure &&
                                                        (adjustedPressure
                                                                .isEmpty ||
                                                            adjustedPressure ==
                                                                '0');

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
                                                          'Pos. ${pl.pos}',
                                                          style:
                                                              getWhiteTextStyle(
                                                            fontSize: 18,
                                                          ),
                                                        ),
                                                        Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .end,
                                                          children: [
                                                            Text(
                                                              '${pl.pressure == '' || pl.pressure == null ? 0 : pl.pressure} Psi',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                fontWeight:
                                                                    w700,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                            if (isThisPositionLow)
                                                              Text(
                                                                'Recc: $recommendedPressure Psi',
                                                                style:
                                                                    getWhiteTextStyle(
                                                                  fontWeight:
                                                                      w700,
                                                                  fontSize: 14,
                                                                ),
                                                              ),
                                                            if (isThisPositionLow)
                                                              Container(
                                                                width: 120,
                                                                height: 60,
                                                                margin:
                                                                    const EdgeInsets
                                                                        .only(
                                                                  top: 12,
                                                                  bottom: 12,
                                                                ),
                                                                child:
                                                                    ButtonWidget(
                                                                  name: Text(
                                                                    'Adjust',
                                                                    style:
                                                                        getWhiteTextStyle(),
                                                                  ),
                                                                  color:
                                                                      green00968A,
                                                                  function: () {
                                                                    final List<
                                                                            Position>
                                                                        position =
                                                                        [];

                                                                    for (int i =
                                                                            0;
                                                                        i < data.posisi.length;
                                                                        i++) {
                                                                      final p =
                                                                          data.posisi[
                                                                              i];

                                                                      position
                                                                          .add(
                                                                        Position(
                                                                          pos: p
                                                                              .pos,
                                                                          pressure:
                                                                              p.pressure,
                                                                          temperatureStatus:
                                                                              p.temperatureStatus,
                                                                          rating:
                                                                              p.rating,
                                                                          adjusmentPressure:
                                                                              p.adjusmentPressure,
                                                                          adjustmentTemperatureStatus:
                                                                              p.adjustmentTemperatureStatus,
                                                                          luka:
                                                                              p.luka,
                                                                          image:
                                                                              p.image,
                                                                          size:
                                                                              p.size,
                                                                          idInventory:
                                                                              p.idInventory,
                                                                          idUnit:
                                                                              p.idUnit,
                                                                          idDaily:
                                                                              p.idDaily,
                                                                          kondisi:
                                                                              p.kondisi,
                                                                        ),
                                                                      );
                                                                    }

                                                                    final dataUnit =
                                                                        {
                                                                      'unitNumber':
                                                                          data.unit,
                                                                      'hm': data
                                                                          .hm,
                                                                      'pit': data
                                                                          .pit,
                                                                      'position':
                                                                          position,
                                                                      'reccPress':
                                                                          state
                                                                              .reccPress,
                                                                    };

                                                                    Navigator
                                                                        .pushNamed(
                                                                      context,
                                                                      DailyCheckFormPage
                                                                          .routeName,
                                                                      arguments:
                                                                          dataUnit,
                                                                    );
                                                                  },
                                                                ),
                                                              ),
                                                            if (pl.adjusmentPressure !=
                                                                    null &&
                                                                pl.adjusmentPressure !=
                                                                    '0' &&
                                                                pl.adjusmentPressure !=
                                                                    '')
                                                              Text(
                                                                '${pl.adjusmentPressure} Psi (Adj. Pressure)',
                                                                style:
                                                                    getWhiteTextStyle(
                                                                  fontWeight:
                                                                      w700,
                                                                  fontSize: 18,
                                                                ),
                                                              ),
                                                            if (luka.isNotEmpty)
                                                              SizedBox(
                                                                width: 200,
                                                                child: Text(
                                                                  luka.join(
                                                                      '\n'),
                                                                  textAlign:
                                                                      TextAlign
                                                                          .end,
                                                                  style:
                                                                      getWhiteTextStyle(
                                                                    fontWeight:
                                                                        w700,
                                                                    fontSize:
                                                                        18,
                                                                  ),
                                                                ),
                                                              ),
                                                            Text(
                                                              '${pl.rating == '' || pl.rating == null ? '' : 'Rating ${pl.rating}'}',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                fontWeight:
                                                                    w700,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 12),
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
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        );
                      }
                    // case 1:
                    // checkedFuture ??= getCheckedTodayFuture();

                    // final reccPressMap = <String, int>{};

                    // for (final item in state.reccPress) {
                    //   item.forEach((key, value) {
                    //     reccPressMap[key.toString()] =
                    //         int.tryParse(value.toString()) ?? 0;
                    //   });
                    // }

                    // return Column(
                    //   children: [
                    //     const SizedBox(height: 12),
                    //     SelectPitButton(
                    //       pit: pit,
                    //       selectedPit: selectedPit,
                    //       onSelectedPitChanged: (index) {
                    //         setState(() {
                    //           selectedPit = index;
                    //           checkedFuture = getCheckedTodayFuture();
                    //         });
                    //       },
                    //     ),
                    //     const SizedBox(height: 12),
                    //     if (homeState.selectedSite?.idCompany == '2')
                    //       Text(
                    //         'Target Low Pressure : ${(state.countAllTire * 0.01).ceil()} Tire',
                    //         style: getBlackTextStyle(fontSize: 14),
                    //       )
                    //     else
                    //       Container(),
                    //     const SizedBox(height: 12),
                    //     SizedBox(
                    //       width: double.infinity,
                    //       child: ElevatedButton(
                    //         onPressed: refreshCheckedData,
                    //         style: ElevatedButton.styleFrom(
                    //           backgroundColor: Colors.blueGrey,
                    //         ),
                    //         child: Text(
                    //           'Refresh Low Pressure Data',
                    //           style: getWhiteTextStyle(),
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(height: 12),
                    //     FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    //       future: checkedFuture,
                    //       builder: (context, snapshot) {
                    //         if (snapshot.connectionState ==
                    //             ConnectionState.waiting) {
                    //           return const Center(
                    //             child: CircularProgressIndicator.adaptive(),
                    //           );
                    //         }

                    //         if (snapshot.hasError) {
                    //           return Text(
                    //             'Error load low pressure data: ${snapshot.error}',
                    //             style: getBlackTextStyle(fontSize: 14),
                    //           );
                    //         }

                    //         final docs = snapshot.data?.docs ?? [];

                    //         final allData = docs.map((doc) {
                    //           final data = doc.data();
                    //           return DailyPress.fromFirestore(data);
                    //         }).toList();

                    //         allData.sort((a, b) {
                    //           return b.tanggal.compareTo(a.tanggal);
                    //         });

                    //         final keyword = searchQuery.toLowerCase();

                    //         final lowPressureData = allData.where((data) {
                    //           if (keyword.isNotEmpty) {
                    //             final unit = data.unit.toLowerCase();

                    //             if (!unit.contains(keyword)) {
                    //               return false;
                    //             }
                    //           }

                    //           return data.posisi.any((position) {
                    //             final tireSize = position.size;

                    //             if (tireSize == null || tireSize.isEmpty) {
                    //               return false;
                    //             }

                    //             final pressure =
                    //                 int.tryParse(position.pressure ?? '0') ??
                    //                     0;

                    //             if (pressure == 0) {
                    //               return false;
                    //             }

                    //             final adjustedPressure =
                    //                 position.adjusmentPressure;

                    //             if (adjustedPressure.isNotEmpty &&
                    //                 adjustedPressure != '0') {
                    //               return false;
                    //             }

                    //             final recommendedPressure =
                    //                 reccPressMap[tireSize] ?? 0;

                    //             if (recommendedPressure == 0) {
                    //               return false;
                    //             }

                    //             return pressure < recommendedPressure;
                    //           });
                    //         }).toList();

                    //         if (lowPressureData.isEmpty) {
                    //           return Text(
                    //             'There is no low pressure data!',
                    //             style: getBlackTextStyle(),
                    //           );
                    //         }

                    //         return ListView.builder(
                    //           itemCount: lowPressureData.length,
                    //           shrinkWrap: true,
                    //           physics: const NeverScrollableScrollPhysics(),
                    //           itemBuilder: (context, index) {
                    //             final data = lowPressureData[index];

                    //             return Card(
                    //               elevation: 2,
                    //               shape: RoundedRectangleBorder(
                    //                 borderRadius: BorderRadius.circular(12),
                    //               ),
                    //               child: Container(
                    //                 width: double.infinity,
                    //                 padding: const EdgeInsets.symmetric(
                    //                   horizontal: 12,
                    //                   vertical: 24,
                    //                 ),
                    //                 decoration: BoxDecoration(
                    //                   color: Colors.red,
                    //                   borderRadius: BorderRadius.circular(12),
                    //                 ),
                    //                 child: ExpansionTile(
                    //                   tilePadding: EdgeInsets.zero,
                    //                   childrenPadding: EdgeInsets.zero,
                    //                   title: Row(
                    //                     children: [
                    //                       Icon(
                    //                         Icons.task,
                    //                         color: white,
                    //                         size: 36,
                    //                       ),
                    //                       const SizedBox(width: 12),
                    //                       Expanded(
                    //                         child: Column(
                    //                           crossAxisAlignment:
                    //                               CrossAxisAlignment.start,
                    //                           children: [
                    //                             Text(
                    //                               data.unit +
                    //                                   '${((data.pit != 'Default') ? '\n${data.pit}' : '')}',
                    //                               style: getWhiteTextStyle(
                    //                                 fontWeight: w700,
                    //                                 fontSize: 18,
                    //                               ),
                    //                             ),
                    //                             Text(
                    //                               'LOW PRESSURE!',
                    //                               style: getWhiteTextStyle(
                    //                                 fontWeight: w700,
                    //                                 fontSize: 18,
                    //                               ),
                    //                             ),
                    //                           ],
                    //                         ),
                    //                       ),
                    //                     ],
                    //                   ),
                    //                   trailing: const SizedBox(
                    //                     width: 90,
                    //                     child: Icon(Icons.arrow_drop_down),
                    //                   ),
                    //                   children: [
                    //                     const SizedBox(height: 12),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           'Name',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         SizedBox(
                    //                           width: 250,
                    //                           child: Text(
                    //                             data.user == ''
                    //                                 ? 'No Name'
                    //                                 : data.user,
                    //                             textAlign: TextAlign.end,
                    //                             style: getWhiteTextStyle(
                    //                               fontWeight: w700,
                    //                               fontSize: 18,
                    //                             ),
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           'Tanggal',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         Text(
                    //                           data.tanggal.split('T')[0],
                    //                           style: getWhiteTextStyle(
                    //                             fontWeight: w700,
                    //                             fontSize: 18,
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           'Waktu',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         Text(
                    //                           data.tanggal
                    //                               .split('T')[1]
                    //                               .substring(0, 5),
                    //                           style: getWhiteTextStyle(
                    //                             fontWeight: w700,
                    //                             fontSize: 18,
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           'HM Unit',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         Text(
                    //                           data.hm,
                    //                           style: getWhiteTextStyle(
                    //                             fontWeight: w700,
                    //                             fontSize: 18,
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     Row(
                    //                       mainAxisAlignment:
                    //                           MainAxisAlignment.spaceBetween,
                    //                       children: [
                    //                         Text(
                    //                           'Pit',
                    //                           style: getWhiteTextStyle(
                    //                               fontSize: 18),
                    //                         ),
                    //                         Text(
                    //                           data.pit,
                    //                           style: getWhiteTextStyle(
                    //                             fontWeight: w700,
                    //                             fontSize: 18,
                    //                           ),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     const SizedBox(height: 12),
                    //                     ListView.builder(
                    //                       itemCount: data.posisi.length,
                    //                       shrinkWrap: true,
                    //                       physics:
                    //                           const NeverScrollableScrollPhysics(),
                    //                       itemBuilder: (context, posIndex) {
                    //                         final pl = data.posisi[posIndex];

                    //                         List<dynamic> luka = [];

                    //                         if (pl.luka != null &&
                    //                             pl.luka is! String) {
                    //                           luka = pl.luka as List<dynamic>;
                    //                         }

                    //                         final tireSize = pl.size;
                    //                         final pressure = int.tryParse(
                    //                                 pl.pressure ?? '0') ??
                    //                             0;
                    //                         final recommendedPressure =
                    //                             reccPressMap[tireSize] ?? 0;

                    //                         final adjustedPressure =
                    //                             pl.adjusmentPressure;

                    //                         final isThisPositionLow =
                    //                             tireSize != null &&
                    //                                 tireSize.isNotEmpty &&
                    //                                 pressure > 0 &&
                    //                                 recommendedPressure > 0 &&
                    //                                 pressure <
                    //                                     recommendedPressure &&
                    //                                 (adjustedPressure
                    //                                         .isEmpty ||
                    //                                     adjustedPressure ==
                    //                                         '0');

                    //                         return Column(
                    //                           children: [
                    //                             Row(
                    //                               mainAxisAlignment:
                    //                                   MainAxisAlignment
                    //                                       .spaceBetween,
                    //                               crossAxisAlignment:
                    //                                   CrossAxisAlignment
                    //                                       .center,
                    //                               children: [
                    //                                 Text(
                    //                                   'Pos. ${pl.pos}',
                    //                                   style:
                    //                                       getWhiteTextStyle(
                    //                                           fontSize: 18),
                    //                                 ),
                    //                                 Column(
                    //                                   crossAxisAlignment:
                    //                                       CrossAxisAlignment
                    //                                           .end,
                    //                                   children: [
                    //                                     Text(
                    //                                       '${(pl.pressure == '' || pl.pressure == null) ? 0 : pl.pressure} Psi',
                    //                                       style:
                    //                                           getWhiteTextStyle(
                    //                                         fontWeight: w700,
                    //                                         fontSize: 18,
                    //                                       ),
                    //                                     ),
                    //                                     if (isThisPositionLow)
                    //                                       Text(
                    //                                         'Recc: $recommendedPressure Psi',
                    //                                         style:
                    //                                             getWhiteTextStyle(
                    //                                           fontWeight:
                    //                                               w700,
                    //                                           fontSize: 14,
                    //                                         ),
                    //                                       ),
                    //                                     if (isThisPositionLow)
                    //                                       Container(
                    //                                         width: 120,
                    //                                         height: 60,
                    //                                         margin:
                    //                                             const EdgeInsets
                    //                                                 .only(
                    //                                           top: 12,
                    //                                           bottom: 12,
                    //                                         ),
                    //                                         child:
                    //                                             ButtonWidget(
                    //                                           name: Text(
                    //                                             'Adjust',
                    //                                             style:
                    //                                                 getWhiteTextStyle(),
                    //                                           ),
                    //                                           color:
                    //                                               green00968A,
                    //                                           function: () {
                    //                                             List<Position>
                    //                                                 position =
                    //                                                 [];

                    //                                             for (int i =
                    //                                                     0;
                    //                                                 i <
                    //                                                     data.posisi
                    //                                                         .length;
                    //                                                 i++) {
                    //                                               final p =
                    //                                                   data.posisi[
                    //                                                       i];

                    //                                               position
                    //                                                   .add(
                    //                                                 Position(
                    //                                                   pos: p
                    //                                                       .pos,
                    //                                                   pressure:
                    //                                                       p.pressure,
                    //                                                   temperatureStatus:
                    //                                                       p.temperatureStatus,
                    //                                                   rating:
                    //                                                       p.rating,
                    //                                                   adjusmentPressure:
                    //                                                       p.adjusmentPressure,
                    //                                                   adjustmentTemperatureStatus:
                    //                                                       p.adjustmentTemperatureStatus,
                    //                                                   luka: p
                    //                                                       .luka,
                    //                                                   image: p
                    //                                                       .image,
                    //                                                   size: p
                    //                                                       .size,
                    //                                                   idInventory:
                    //                                                       p.idInventory,
                    //                                                   idUnit:
                    //                                                       p.idUnit,
                    //                                                   idDaily:
                    //                                                       p.idDaily,
                    //                                                   kondisi:
                    //                                                       p.kondisi,
                    //                                                 ),
                    //                                               );
                    //                                             }

                    //                                             final dataUnit =
                    //                                                 {
                    //                                               'unitNumber':
                    //                                                   data.unit,
                    //                                               'hm':
                    //                                                   data.hm,
                    //                                               'pit': data
                    //                                                   .pit,
                    //                                               'position':
                    //                                                   position,
                    //                                               'reccPress':
                    //                                                   state
                    //                                                       .reccPress,
                    //                                             };

                    //                                             Navigator
                    //                                                 .pushNamed(
                    //                                               context,
                    //                                               DailyCheckFormPage
                    //                                                   .routeName,
                    //                                               arguments:
                    //                                                   dataUnit,
                    //                                             );
                    //                                           },
                    //                                         ),
                    //                                       ),
                    //                                     if (pl.adjusmentPressure !=
                    //                                             null &&
                    //                                         pl.adjusmentPressure !=
                    //                                             '0' &&
                    //                                         pl.adjusmentPressure !=
                    //                                             '')
                    //                                       Text(
                    //                                         '${pl.adjusmentPressure} Psi (Adj. Pressure)',
                    //                                         style:
                    //                                             getWhiteTextStyle(
                    //                                           fontWeight:
                    //                                               w700,
                    //                                           fontSize: 18,
                    //                                         ),
                    //                                       ),
                    //                                     if (luka.isNotEmpty)
                    //                                       SizedBox(
                    //                                         width: 200,
                    //                                         child: Text(
                    //                                           luka.join('\n'),
                    //                                           textAlign:
                    //                                               TextAlign
                    //                                                   .end,
                    //                                           style:
                    //                                               getWhiteTextStyle(
                    //                                             fontWeight:
                    //                                                 w700,
                    //                                             fontSize: 18,
                    //                                           ),
                    //                                         ),
                    //                                       ),
                    //                                     Text(
                    //                                       '${(pl.rating == '' || pl.rating == null) ? '' : 'Rating ${pl.rating}'}',
                    //                                       style:
                    //                                           getWhiteTextStyle(
                    //                                         fontWeight: w700,
                    //                                         fontSize: 18,
                    //                                       ),
                    //                                     ),
                    //                                     const SizedBox(
                    //                                         height: 12),
                    //                                   ],
                    //                                 ),
                    //                               ],
                    //                             ),
                    //                             Divider(
                    //                               color: white,
                    //                               thickness: 1.5,
                    //                             ),
                    //                           ],
                    //                         );
                    //                       },
                    //                     ),
                    //                   ],
                    //                 ),
                    //               ),
                    //             );
                    //           },
                    //         );
                    //       },
                    //     ),
                    //   ],
                    // );
                    // old code case 1
                    // case 1:
                    //   return Column(
                    //     children: [
                    //       const SizedBox(
                    //         height: 12,
                    //       ),
                    //       SelectPitButton(
                    //           pit: pit,
                    //           selectedPit: selectedPit,
                    //           onSelectedPitChanged: (index) {
                    //             setState(() {
                    //               selectedPit = index;
                    //             });
                    //           }),
                    //       const SizedBox(
                    //         height: 12,
                    //       ),
                    //       if (homeState.selectedSite?.idCompany == '2')
                    //         Text(
                    //           // 'Total Unit : ${dailyData.length ?? 0}',
                    //           'Target Low Pressure : ${(state.countAllTire * 0.01).ceil()} Tire',

                    //           style: getBlackTextStyle(
                    //             fontSize: 14,
                    //           ),
                    //         )
                    //       else
                    //         Container(),
                    //       const SizedBox(
                    //         height: 12,
                    //       ),
                    //       PaginateFirestore(
                    //           query: selectedPit == 0
                    //               ? firestore
                    //                   .collection('daily_pressure')
                    //                   .where('tanggal',
                    //                       isGreaterThanOrEqualTo:
                    //                           DateTime(now.year, now.month, now.day)
                    //                               .toIso8601String())
                    //                   .where('tanggal',
                    //                       isLessThanOrEqualTo:
                    //                           DateTime(now.year, now.month, now.day, 23, 59, 59)
                    //                               .toIso8601String())
                    //                   .where('idSite', isEqualTo: currentIdSite)
                    //                   .orderBy('tanggal', descending: true)
                    //               : firestore
                    //                   .collection('daily_pressure')
                    //                   .where('tanggal',
                    //                       isGreaterThanOrEqualTo:
                    //                           DateTime(now.year, now.month, now.day)
                    //                               .toIso8601String())
                    //                   .where('tanggal',
                    //                       isLessThanOrEqualTo:
                    //                           DateTime(now.year, now.month, now.day, 23, 59, 59)
                    //                               .toIso8601String())
                    //                   .where('idSite', isEqualTo: currentIdSite)
                    //                   .where('pit', isEqualTo: pit[selectedPit])
                    //                   .orderBy('tanggal', descending: true),
                    //           itemBuilderType: PaginateBuilderType.listView,
                    //           shrinkWrap: true,
                    //           physics: NeverScrollableScrollPhysics(),
                    //           itemsPerPage: 10,
                    //           // isLive: true,
                    //           isLive: false,
                    //           onEmpty: Text(
                    //             'There is no low pressure data!',
                    //             style: getBlackTextStyle(),
                    //           ),
                    //           initialLoader: const Center(child: CircularProgressIndicator.adaptive()),
                    //           bottomLoader: const Center(child: CircularProgressIndicator.adaptive()),
                    //           itemBuilder: (context, snapshot, firebaseIndex) {
                    //             // log('snapshot : $snapshot');
                    //             final allData = snapshot
                    //                 .map((doc) => DailyPress.fromFirestore(
                    //                     doc.data() as Map<String, dynamic>))
                    //                 .toList();

                    //             final distinctDaily =
                    //                 Set<DailyPress>.from(allData).toList();

                    //             return ListView.builder(
                    //                 itemCount: distinctDaily.length,
                    //                 physics: NeverScrollableScrollPhysics(),
                    //                 shrinkWrap: true,
                    //                 itemBuilder: (context, index) {
                    //                   if (firebaseIndex +
                    //                           (distinctDaily.length) >
                    //                       distinctDaily.length) {
                    //                     return Container();
                    //                   }
                    //                   final data = distinctDaily[index];

                    //                   if (searchQuery.isNotEmpty &&
                    //                       !data.unit!
                    //                           .toLowerCase()
                    //                           .contains(searchQuery)) {
                    //                     return Container();
                    //                   }

                    //                   if (selectedPit != 0) {
                    //                     if (data.pit != pit[selectedPit]) {
                    //                       return Container();
                    //                     }
                    //                   }

                    //                   bool isLowPressure =
                    //                       data.posisi.any((position) {
                    //                     final tireSize = position.size;

                    //                     final pressure = int.tryParse(
                    //                             position.pressure ?? '0') ??
                    //                         0;

                    //                     if (tireSize == null ||
                    //                         tireSize.isEmpty) return false;

                    //                     // Cari data reccPress berdasarkan ukuran ban (tireSize)
                    //                     final recommended =
                    //                         state.reccPress.firstWhere(
                    //                       (rec) => rec.containsKey(tireSize),
                    //                       orElse: () => {},
                    //                     );

                    //                     if (recommended != {} &&
                    //                         recommended[tireSize] != null) {
                    //                       final recommendedPressure =
                    //                           int.parse(recommended[tireSize]);

                    //                       final adjustedPressure =
                    //                           position.adjusmentPressure;

                    //                       if (pressure == 0) return false;
                    //                       if (adjustedPressure != '') {
                    //                         return false;
                    //                       }

                    //                       return pressure < recommendedPressure;
                    //                     }
                    //                     return false;
                    //                   });

                    //                   if (!isLowPressure) {
                    //                     return Container();
                    //                   }

                    //                   return Card(
                    //                       elevation: 2,
                    //                       shape: RoundedRectangleBorder(
                    //                         borderRadius:
                    //                             BorderRadius.circular(12),
                    //                       ),
                    //                       child: Container(
                    //                         width: double.infinity,
                    //                         padding: EdgeInsets.symmetric(
                    //                             horizontal: 12, vertical: 24),
                    //                         decoration: BoxDecoration(
                    //                           color: (isLowPressure
                    //                               ? Colors.red
                    //                               : green00968A),
                    //                           // color: green00968A,
                    //                           borderRadius:
                    //                               BorderRadius.circular(12),
                    //                         ),
                    //                         child: ExpansionTile(
                    //                           tilePadding: EdgeInsets.zero,
                    //                           childrenPadding:
                    //                               EdgeInsets.all(0),
                    //                           title: Column(
                    //                             crossAxisAlignment:
                    //                                 CrossAxisAlignment.start,
                    //                             children: [
                    //                               Row(
                    //                                 children: [
                    //                                   Icon(
                    //                                     Icons.task,
                    //                                     color: white,
                    //                                     size: 36,
                    //                                   ),
                    //                                   const SizedBox(
                    //                                     width: 12,
                    //                                   ),
                    //                                   Column(
                    //                                     crossAxisAlignment:
                    //                                         CrossAxisAlignment
                    //                                             .start,
                    //                                     children: [
                    //                                       Text(
                    //                                         // dailyMap['unit'] +
                    //                                         //     '${((dailyMap['pit'] != 'Default') ? '\n' + dailyMap['pit'] : '')}',
                    //                                         data.unit +
                    //                                             '${((data.pit != 'Default') ? '\n' + data.pit : '')}',
                    //                                         style:
                    //                                             getWhiteTextStyle(
                    //                                                 fontWeight:
                    //                                                     w700,
                    //                                                 fontSize:
                    //                                                     18),
                    //                                       ),
                    //                                       (isLowPressure)
                    //                                           ? Text(
                    //                                               // dailyMap['unit'] +
                    //                                               //     '${((dailyMap['pit'] != 'Default') ? '\n' + dailyMap['pit'] : '')}',
                    //                                               'LOW PRESSURE!',
                    //                                               style: getWhiteTextStyle(
                    //                                                   fontWeight:
                    //                                                       w700,
                    //                                                   fontSize:
                    //                                                       18),
                    //                                             )
                    //                                           : Container()
                    //                                     ],
                    //                                   ),
                    //                                 ],
                    //                               ),
                    //                             ],
                    //                           ),
                    //                           trailing: SizedBox(
                    //                             width: 90,
                    //                             child:
                    //                                 Icon(Icons.arrow_drop_down),
                    //                           ),
                    //                           children: [
                    //                             const SizedBox(
                    //                               height: 12,
                    //                             ),
                    //                             Row(
                    //                               mainAxisAlignment:
                    //                                   MainAxisAlignment
                    //                                       .spaceBetween,
                    //                               children: [
                    //                                 Text(
                    //                                   'Name',
                    //                                   style: getWhiteTextStyle(
                    //                                       fontSize: 18),
                    //                                 ),
                    //                                 Container(
                    //                                   width: 250,
                    //                                   child: Text(
                    //                                     // dailyMap['user'] ??
                    //                                     //     'No Name',
                    //                                     data.user == ''
                    //                                         ? 'No Name'
                    //                                         : data.user,
                    //                                     textAlign:
                    //                                         TextAlign.end,
                    //                                     style:
                    //                                         getWhiteTextStyle(
                    //                                             fontWeight:
                    //                                                 w700,
                    //                                             fontSize: 18),
                    //                                   ),
                    //                                 ),
                    //                               ],
                    //                             ),
                    //                             const SizedBox(
                    //                               height: 12,
                    //                             ),
                    //                             Row(
                    //                               mainAxisAlignment:
                    //                                   MainAxisAlignment
                    //                                       .spaceBetween,
                    //                               children: [
                    //                                 Text(
                    //                                   'Tanggal',
                    //                                   style: getWhiteTextStyle(
                    //                                       fontSize: 18),
                    //                                 ),
                    //                                 Text(
                    //                                   // dailyMap['tanggal']
                    //                                   //     .split('T')[0],
                    //                                   data.tanggal
                    //                                       .split('T')[0],
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
                    //                                   MainAxisAlignment
                    //                                       .spaceBetween,
                    //                               children: [
                    //                                 Text(
                    //                                   'Waktu',
                    //                                   style: getWhiteTextStyle(
                    //                                       fontSize: 18),
                    //                                 ),
                    //                                 Text(
                    //                                   // dailyMap['tanggal']
                    //                                   //     .split('T')[1]
                    //                                   data.tanggal
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
                    //                                   MainAxisAlignment
                    //                                       .spaceBetween,
                    //                               children: [
                    //                                 Text(
                    //                                   'HM Unit',
                    //                                   style: getWhiteTextStyle(
                    //                                       fontSize: 18),
                    //                                 ),
                    //                                 Text(
                    //                                   // dailyMap['hm'],
                    //                                   data.hm,
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
                    //                                   MainAxisAlignment
                    //                                       .spaceBetween,
                    //                               children: [
                    //                                 Text(
                    //                                   'Pit',
                    //                                   style: getWhiteTextStyle(
                    //                                       fontSize: 18),
                    //                                 ),
                    //                                 Text(
                    //                                   // dailyMap['pit'],
                    //                                   data.pit,
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
                    //                               children:
                    //                                   // positionList.map((pl) {
                    //                                   data.posisi.map((pl) {
                    //                                 // final plIndex = positionList
                    //                                 //     .indexOf(pl);
                    //                                 List<dynamic> luka = [];

                    //                                 // if (pl['luka'] != null &&
                    //                                 //     pl['luka'] is! String) {
                    //                                 //   luka = pl['luka']
                    //                                 //       as List<dynamic>;
                    //                                 // }
                    //                                 if (pl.luka != null &&
                    //                                     pl.luka is! String) {
                    //                                   luka = pl.luka
                    //                                       as List<dynamic>;
                    //                                 }

                    //                                 return Column(
                    //                                   children: [
                    //                                     Row(
                    //                                       mainAxisAlignment:
                    //                                           MainAxisAlignment
                    //                                               .spaceBetween,
                    //                                       crossAxisAlignment:
                    //                                           CrossAxisAlignment
                    //                                               .center,
                    //                                       children: [
                    //                                         Text(
                    //                                           // 'Pos. ${pl['pos']}',
                    //                                           'Pos. ${pl.pos}',
                    //                                           style:
                    //                                               getWhiteTextStyle(
                    //                                                   fontSize:
                    //                                                       18),
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
                    //                                                 Column(
                    //                                                   crossAxisAlignment:
                    //                                                       CrossAxisAlignment
                    //                                                           .end,
                    //                                                   children: [
                    //                                                     Builder(builder:
                    //                                                         (context) {
                    //                                                       return Text(
                    //                                                         // '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
                    //                                                         '${(pl.pressure == '' || pl.pressure == null) ? 0 : pl.pressure} Psi',
                    //                                                         style:
                    //                                                             getWhiteTextStyle(fontWeight: w700, fontSize: 18),
                    //                                                       );
                    //                                                     }),
                    //                                                     Builder(
                    //                                                       builder:
                    //                                                           (context) {
                    //                                                         // Cek jika pl.size null atau kosong
                    //                                                         if (pl.size == null ||
                    //                                                             pl.size.isEmpty)
                    //                                                           return Container();

                    //                                                         // Ambil data recommended pressure
                    //                                                         final recommendedMap =
                    //                                                             state.reccPress.firstWhere(
                    //                                                           (map) => map.containsKey(pl.size),
                    //                                                           orElse: () => {},
                    //                                                         );

                    //                                                         // Cek apakah recommendedMap valid dan pl.size ada di dalamnya
                    //                                                         final recommendedPressure = recommendedMap.isNotEmpty && recommendedMap[pl.size] != null
                    //                                                             ? int.tryParse(recommendedMap[pl.size]) ?? 0
                    //                                                             : 0;

                    //                                                         // Cek jika pl.pressure null atau bukan angka
                    //                                                         final pressure =
                    //                                                             int.tryParse(pl.pressure ?? '0') ?? 0;

                    //                                                         // Jika tekanan = 0, tidak ditampilkan
                    //                                                         if (pressure ==
                    //                                                             0)
                    //                                                           return Container();

                    //                                                         // Jika low pressure dan belum di-adjust, tidak ditampilkan
                    //                                                         if (recommendedPressure < pressure ||
                    //                                                             pl.adjusmentPressure.isNotEmpty) {
                    //                                                           return Container();
                    //                                                         }

                    //                                                         return Container(
                    //                                                           width: 120,
                    //                                                           height: 60,
                    //                                                           margin: EdgeInsets.only(top: 12, bottom: 12),
                    //                                                           child: ButtonWidget(
                    //                                                             name: Text(
                    //                                                               'Adjust',
                    //                                                               style: getWhiteTextStyle(),
                    //                                                             ),
                    //                                                             color: green00968A,
                    //                                                             function: () {
                    //                                                               List<Position> position = [];
                    //                                                               for (int i = 0; i < data.posisi.length; i++) {
                    //                                                                 final p = data.posisi[i];
                    //                                                                 // ADD COT HOLD PRESSURE
                    //                                                                 position.add(Position(pos: p.pos, pressure: p.pressure, temperatureStatus: p.temperatureStatus, rating: p.rating, adjusmentPressure: p.adjusmentPressure, adjustmentTemperatureStatus: p.adjustmentTemperatureStatus, luka: p.luka, image: p.image, size: p.size, idInventory: p.idInventory, idUnit: p.idUnit, idDaily: p.idDaily, kondisi: p.kondisi));
                    //                                                               }

                    //                                                               final dataUnit = {
                    //                                                                 'unitNumber': data.unit,
                    //                                                                 'hm': data.hm,
                    //                                                                 'pit': data.pit,
                    //                                                                 'position': position,
                    //                                                                 'reccPress': state.reccPress,
                    //                                                               };

                    //                                                               Navigator.pushNamed(context, DailyCheckFormPage.routeName, arguments: dataUnit);
                    //                                                             },
                    //                                                           ),
                    //                                                         );
                    //                                                       },
                    //                                                     ),
                    //                                                   ],
                    //                                                 ),
                    //                                                 // (pl['adjusmentPressure'] != null &&
                    //                                                 //         pl['adjusmentPressure'] !=
                    //                                                 //             '0' &&
                    //                                                 //         pl['adjusmentPressure'] !=
                    //                                                 //             '')
                    //                                                 (pl.adjusmentPressure != null &&
                    //                                                         pl.adjusmentPressure !=
                    //                                                             '0' &&
                    //                                                         pl.adjusmentPressure !=
                    //                                                             '')
                    //                                                     ? Text(
                    //                                                         // '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
                    //                                                         '${pl.adjusmentPressure} Psi (Adj. Pressure)',
                    //                                                         style:
                    //                                                             getWhiteTextStyle(fontWeight: w700, fontSize: 18),
                    //                                                       )
                    //                                                     : Container(),
                    //                                               ],
                    //                                             ),
                    //                                             (luka.isEmpty ||
                    //                                                     luka ==
                    //                                                         null)
                    //                                                 ? Container()
                    //                                                 : Container(
                    //                                                     width:
                    //                                                         200,
                    //                                                     child:
                    //                                                         Text(
                    //                                                       // pl['luka']
                    //                                                       pl.luka
                    //                                                           .join('\n'),
                    //                                                       textAlign:
                    //                                                           TextAlign.end,
                    //                                                       style: getWhiteTextStyle(
                    //                                                           fontWeight: w700,
                    //                                                           fontSize: 18),
                    //                                                     ),
                    //                                                   ),
                    //                                             Text(
                    //                                                 // '${(pl['rating'] == '' || pl['rating'] == null) ? '' : 'Rating ${pl['rating']}'}',
                    //                                                 '${(pl.rating == '' || pl.rating == null) ? '' : 'Rating ${pl.rating}'}',
                    //                                                 style: getWhiteTextStyle(
                    //                                                     fontWeight:
                    //                                                         w700,
                    //                                                     fontSize:
                    //                                                         18)),
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
                    //                       ));
                    //                 });

                    //             ;
                    //           }),
                    //     ],
                    //   );

                    // All Unit
                    case 2:
                      final keyword = searchQuery.toLowerCase();

                      final filteredUnits = state.units.where((unit) {
                        if (keyword.isEmpty) return true;

                        final unitNumber = unit.unitNumber?.toLowerCase() ?? '';
                        final model = unit.model?.toLowerCase() ?? '';

                        return unitNumber.contains(keyword) ||
                            model.contains(keyword);
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'Total Unit : ${filteredUnits.length}',
                            style: getBlackTextStyle(fontSize: 20),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          if (state.units.isEmpty)
                            Text(
                              'Empty!',
                              textAlign: TextAlign.center,
                              style: getBlackTextStyle(fontSize: 18),
                            )
                          else
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.62,
                              child: ListView.builder(
                                itemCount: filteredUnits.length,
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemBuilder: (context, index) {
                                  final unit = filteredUnits[index];

                                  return InkWell(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        DailyCheckFormPage.routeName,
                                        arguments: {
                                          'unitNumber': unit.unitNumber,
                                          'reccPress': state.reccPress,
                                        },
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            spreadRadius: 2,
                                            blurRadius: 5,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ListTile(
                                        leading: const Icon(
                                          Icons.front_loader,
                                          color: Colors.orange,
                                        ),
                                        title: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4.0),
                                          child: Text(
                                            unit.unitNumber ?? '',
                                            style: getBlackTextStyle(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        subtitle: Text(
                                          unit.model ?? '',
                                          style: getGreyTextStyle(grey6A707C),
                                        ),
                                        trailing:
                                            const Icon(Icons.arrow_forward_ios),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      );
                    // case 2:
                    //   // log('kendaraanku: ${state.units.map((unit) => 'unitNumber: ${unit.unitNumber}, sn: ${unit.sn}').toList()}');
                    //   final filteredUnits = state.units.where((unit) {
                    //     final keyword = searchQuery.toLowerCase();

                    //     if (keyword.isEmpty) return true;

                    //     final unitNumber = unit.unitNumber?.toLowerCase() ?? '';
                    //     final model = unit.model?.toLowerCase() ?? '';

                    //     return unitNumber.contains(keyword) ||
                    //         model.contains(keyword);
                    //   }).toList();

                    //   return Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       const SizedBox(
                    //         height: 12,
                    //       ),
                    //       Text(
                    //         'Total Unit : ${state.units.length.toString()}',
                    //         style: getBlackTextStyle(fontSize: 20),
                    //       ),
                    //       const SizedBox(
                    //         height: 6,
                    //       ),
                    //       // Builder(builder: (context) {
                    //       //   if (state.totalActualUnits?.length == null) {
                    //       //     return Container();
                    //       //   }

                    //       //   if (state.totalActualUnits?.length !=
                    //       //       state.units.length) {
                    //       //     return Column(
                    //       //       children: [
                    //       //         NotUpdateWarningWidget(
                    //       //             totalActual:
                    //       //                 state.totalActualUnits?.length ?? 0),
                    //       //         SizedBox(
                    //       //           height: 12,
                    //       //         ),
                    //       //       ],
                    //       //     );
                    //       //   } else {
                    //       //     Container();
                    //       //   }
                    //       //   return Container();
                    //       // }),
                    //       (state.units == null || state.units.isEmpty)
                    //           ? Text(
                    //               'Empty!',
                    //               textAlign: TextAlign.center,
                    //               style: getBlackTextStyle(fontSize: 18),
                    //             )
                    //           : ListView.builder(
                    //               shrinkWrap: true,
                    //               physics: const NeverScrollableScrollPhysics(),
                    //               itemCount: filteredUnits.length,
                    //               itemBuilder: (context, index) {
                    //                 final unit = filteredUnits[index];

                    //                 return InkWell(
                    //                   onTap: () {
                    //                     Navigator.pushNamed(
                    //                       context,
                    //                       DailyCheckFormPage.routeName,
                    //                       arguments: {
                    //                         'unitNumber': unit.unitNumber,
                    //                         'reccPress': state.reccPress,
                    //                       },
                    //                     );
                    //                   },
                    //                   child: Container(
                    //                     margin: const EdgeInsets.symmetric(
                    //                         vertical: 8.0),
                    //                     padding: const EdgeInsets.symmetric(
                    //                         vertical: 6),
                    //                     decoration: BoxDecoration(
                    //                       color: Colors.white,
                    //                       borderRadius:
                    //                           BorderRadius.circular(12),
                    //                       boxShadow: [
                    //                         BoxShadow(
                    //                           color:
                    //                               Colors.black.withOpacity(0.1),
                    //                           spreadRadius: 2,
                    //                           blurRadius: 5,
                    //                           offset: const Offset(0, 2),
                    //                         ),
                    //                       ],
                    //                     ),
                    //                     child: ListTile(
                    //                       leading: const Icon(
                    //                         Icons.front_loader,
                    //                         color: Colors.orange,
                    //                       ),
                    //                       title: Padding(
                    //                         padding: const EdgeInsets.only(
                    //                             bottom: 4.0),
                    //                         child: Text(
                    //                           unit.unitNumber ?? '',
                    //                           style: getBlackTextStyle(
                    //                               fontWeight: FontWeight.w700),
                    //                         ),
                    //                       ),
                    //                       subtitle: Text(
                    //                         unit.model ?? '',
                    //                         style: getGreyTextStyle(grey6A707C),
                    //                       ),
                    //                       trailing: const Icon(
                    //                           Icons.arrow_forward_ios),
                    //                     ),
                    //                   ),
                    //                 );
                    //               },
                    //             ),
                    //       // : Column(
                    //       //     children: state.units.map((unit) {
                    //       //       if (searchQuery.isNotEmpty &&
                    //       //           !unit.unitNumber!
                    //       //               .toLowerCase()
                    //       //               .contains(searchQuery) &&
                    //       //           !unit.model!
                    //       //               .toLowerCase()
                    //       //               .contains(searchQuery)) {
                    //       //         return Container();
                    //       //       }
                    //       //       return InkWell(
                    //       //         // onTap: (userAccessId == '1' ||
                    //       //         //         userAccessId == '2' ||
                    //       //         //         userAccessId == '3')
                    //       //         onTap: () {
                    //       //           Navigator.pushNamed(context,
                    //       //               DailyCheckFormPage.routeName,
                    //       //               arguments: {
                    //       //                 'unitNumber': unit.unitNumber,
                    //       //                 'reccPress': state.reccPress,
                    //       //               });
                    //       //         },
                    //       //         child: Container(
                    //       //           margin:
                    //       //               EdgeInsets.symmetric(vertical: 8.0),
                    //       //           padding:
                    //       //               EdgeInsets.symmetric(vertical: 6),
                    //       //           decoration: BoxDecoration(
                    //       //             color: Colors.white,
                    //       //             borderRadius:
                    //       //                 BorderRadius.circular(12),
                    //       //             boxShadow: [
                    //       //               BoxShadow(
                    //       //                 color:
                    //       //                     Colors.black.withOpacity(0.1),
                    //       //                 spreadRadius: 2,
                    //       //                 blurRadius: 5,
                    //       //                 offset: Offset(0, 2),
                    //       //               ),
                    //       //             ],
                    //       //           ),
                    //       //           child: ListTile(
                    //       //             leading: Icon(
                    //       //               Icons.front_loader,
                    //       //               color: Colors.orange,
                    //       //             ),
                    //       //             title: Padding(
                    //       //               padding: const EdgeInsets.only(
                    //       //                   bottom: 4.0),
                    //       //               child: Text(
                    //       //                 '${unit.unitNumber}',
                    //       //                 style: getBlackTextStyle(
                    //       //                     fontWeight: FontWeight.w700),
                    //       //               ),
                    //       //             ),
                    //       //             subtitle: Text(
                    //       //               '${unit.model}',
                    //       //               style: getGreyTextStyle(grey6A707C),
                    //       //             ),
                    //       //             trailing:
                    //       //                 Icon(Icons.arrow_forward_ios),
                    //       //           ),
                    //       //         ),
                    //       //       );
                    //       //     }).toList(),
                    //       //   ),
                    //     ],
                    //   );

                    // Not Checked Unit
                    case 3:
                      final today = DateTime.now();
                      final todayString =
                          today.toIso8601String().substring(0, 10);

                      final bool showNotCheckedPit =
                          homeState.userAccessCompanyId.value == '1' &&
                              homeState.userAccessId.value == '5';

                      // Daftar PIT/area diambil langsung dari target_area
                      // yang sudah tersedia pada UnitLoadedState.
                      final List<String> targetAreaNames = state.targetArea.keys
                          .map((area) => area.trim())
                          .where((area) => area.isNotEmpty)
                          .toSet()
                          .toList()
                        ..sort(
                          (a, b) => a.toLowerCase().compareTo(
                                b.toLowerCase(),
                              ),
                        );

                      final List<String> notCheckedPit = [
                        'All',
                        ...targetAreaNames,
                      ];

                      final int safeSelectedNotCheckedPit =
                          selectedNotCheckedPit >= 0 &&
                                  selectedNotCheckedPit < notCheckedPit.length
                              ? selectedNotCheckedPit
                              : 0;

                      final String selectedNotCheckedArea =
                          notCheckedPit[safeSelectedNotCheckedPit];

                      checkedFuture ??= getCheckedTodayFuture();

                      return Column(
                        children: [
                          const SizedBox(
                            height: 12,
                          ),

                          if (showNotCheckedPit &&
                              notCheckedPit.length > 1) ...[
                            SelectPitButton(
                              pit: notCheckedPit,
                              selectedPit: safeSelectedNotCheckedPit,
                              onSelectedPitChanged: (index) {
                                if (index < 0 ||
                                    index >= notCheckedPit.length) {
                                  return;
                                }

                                setState(() {
                                  selectedNotCheckedPit = index;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Tombol Get SPM Unit Tire Pressure
                          (userAccessId != '1' &&
                                  homeState.userAccessCompanyId.value == '')
                              ? SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      showDialog<bool>(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text("Konfirmasi"),
                                            content: const Text(
                                                "Apakah Anda yakin?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.of(context)
                                                        .pop(false),
                                                child: const Text("No"),
                                              ),
                                              ElevatedButton(
                                                onPressed: () async {
                                                  showDialog(
                                                    context: context,
                                                    barrierDismissible: false,
                                                    builder: (context) {
                                                      return const AlertDialog(
                                                        content: Row(
                                                          children: [
                                                            CircularProgressIndicator(),
                                                            SizedBox(width: 20),
                                                            Text(
                                                                "Submitting data, please wait..."),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                  );

                                                  try {
                                                    final dataSPMJam7 =
                                                        await ApiService
                                                            .getJam7SPM(
                                                                currentIdSite);

                                                    final List<UnitTire>
                                                        dataTireCondition =
                                                        await ApiService
                                                            .getTireCondition(
                                                      currentIdSite,
                                                    );

                                                    final ratingMap =
                                                        <String, String>{};
                                                    final tireSizeMap =
                                                        <String, String>{};
                                                    final hmMap =
                                                        <String, String>{};
                                                    final idInventoryMap =
                                                        <String, String>{};
                                                    final idUnitMap =
                                                        <String, String>{};
                                                    final idDailyMap =
                                                        <String, String>{};

                                                    final today =
                                                        DateTime.now();

                                                    final formattedToday =
                                                        '${today.month.toString().padLeft(2, '0')}'
                                                        '${today.day.toString().padLeft(2, '0')}'
                                                        '${(today.year % 100).toString().padLeft(2, '0')}';

                                                    for (final unit
                                                        in dataTireCondition) {
                                                      final unitNumber =
                                                          unit.unitNumber ?? '';
                                                      final posisi =
                                                          unit.posisi ?? '';

                                                      if (unitNumber
                                                              .isNotEmpty &&
                                                          posisi.isNotEmpty) {
                                                        final key =
                                                            '$unitNumber-$posisi';

                                                        ratingMap[key] =
                                                            unit.rating ?? '';
                                                        tireSizeMap[key] =
                                                            unit.size ?? '';
                                                        hmMap[key] =
                                                            unit.hm ?? '';
                                                        idInventoryMap[key] =
                                                            unit.idinventory ??
                                                                '';
                                                        idUnitMap[key] =
                                                            unit.idUnit ?? '';
                                                        idDailyMap[key] =
                                                            '$unitNumber$posisi$formattedToday$currentIdSite';
                                                      }
                                                    }

                                                    final batch =
                                                        firestore.batch();
                                                    final collection =
                                                        firestore.collection(
                                                            'daily_pressure');

                                                    // Ambil semua data checked hari ini sekali saja,
                                                    // supaya tidak query Firebase di dalam loop.
                                                    final todaySnapshot =
                                                        await collection
                                                            .where('hari',
                                                                isEqualTo:
                                                                    todayString)
                                                            .where('idSite',
                                                                isEqualTo:
                                                                    currentIdSite)
                                                            .get();

                                                    final existingDocMap =
                                                        <String, String>{};

                                                    for (final doc
                                                        in todaySnapshot.docs) {
                                                      final data = doc.data();
                                                      final unit = data['unit']
                                                              ?.toString() ??
                                                          '';

                                                      if (unit.isNotEmpty) {
                                                        existingDocMap[unit] =
                                                            doc.id;
                                                      }
                                                    }

                                                    for (final dataUnit
                                                        in dataSPMJam7) {
                                                      final jsonData =
                                                          dataUnit.toJson();
                                                      final unitNumber =
                                                          dataUnit.devicename ??
                                                              '';

                                                      if (unitNumber.isEmpty) {
                                                        continue;
                                                      }

                                                      final tireCount = jsonData
                                                          .keys
                                                          .where((k) =>
                                                              k.startsWith(
                                                                  'max_p'))
                                                          .length;

                                                      bool hasZeroPressure =
                                                          false;

                                                      for (int pos = 1;
                                                          pos <= tireCount;
                                                          pos++) {
                                                        final pressure =
                                                            double.tryParse(
                                                                  jsonData[
                                                                          'avg_p$pos']
                                                                      .toString(),
                                                                ) ??
                                                                0;

                                                        if (pressure == 0) {
                                                          hasZeroPressure =
                                                              true;
                                                          break;
                                                        }
                                                      }

                                                      if (hasZeroPressure) {
                                                        continue;
                                                      }

                                                      final existingDocId =
                                                          existingDocMap[
                                                              unitNumber];

                                                      final docRef =
                                                          existingDocId != null
                                                              ? collection.doc(
                                                                  existingDocId)
                                                              : collection
                                                                  .doc();

                                                      batch.set(docRef, {
                                                        'idSite': currentIdSite,
                                                        'user':
                                                            user['username'] ??
                                                                'Username',
                                                        'tanggal': DateTime
                                                                .now()
                                                            .toIso8601String(),
                                                        'hari': todayString,
                                                        'jam': DateTime.now()
                                                            .toIso8601String()
                                                            .substring(11, 19),
                                                        'unit': unitNumber,
                                                        'hm': hmMap[
                                                                '$unitNumber-1'] ??
                                                            '',
                                                        'posisi': List.generate(
                                                          tireCount,
                                                          (pIndex) {
                                                            final pos =
                                                                pIndex + 1;
                                                            final key =
                                                                '$unitNumber-$pos';

                                                            return {
                                                              'pos': '$pos',
                                                              'pressure': (double
                                                                          .tryParse(
                                                                        jsonData['avg_p$pos']
                                                                            .toString(),
                                                                      ) ??
                                                                      0)
                                                                  .toStringAsFixed(
                                                                      0),
                                                              'rating':
                                                                  ratingMap[
                                                                          key] ??
                                                                      '',
                                                              'adjusmentPressure':
                                                                  '0',
                                                              'luka': '',
                                                              'image': '',
                                                              'tireSize':
                                                                  tireSizeMap[
                                                                          key] ??
                                                                      '',
                                                              'idInventory':
                                                                  idInventoryMap[
                                                                          key] ??
                                                                      '',
                                                              'idUnit':
                                                                  idUnitMap[
                                                                          key] ??
                                                                      '',
                                                              'idDaily':
                                                                  idDailyMap[
                                                                          key] ??
                                                                      '',
                                                              'kondisi': '',
                                                              'min_press': (double
                                                                          .tryParse(
                                                                        jsonData['min_p$pos']
                                                                            .toString(),
                                                                      ) ??
                                                                      0)
                                                                  .toStringAsFixed(
                                                                      0),
                                                              'max_press': (double
                                                                          .tryParse(
                                                                        jsonData['max_p$pos']
                                                                            .toString(),
                                                                      ) ??
                                                                      0)
                                                                  .toStringAsFixed(
                                                                      0),
                                                              'avg_press': (double
                                                                          .tryParse(
                                                                        jsonData['avg_p$pos']
                                                                            .toString(),
                                                                      ) ??
                                                                      0)
                                                                  .toStringAsFixed(
                                                                      0),
                                                              'temp': double
                                                                      .tryParse(
                                                                    jsonData[
                                                                            'avg_t$pos']
                                                                        .toString(),
                                                                  ) ??
                                                                  0,
                                                            };
                                                          },
                                                        ),
                                                        'pit': 'Default',
                                                        'timeLowPressureSPM':
                                                            '',
                                                      });
                                                    }

                                                    await batch.commit();

                                                    Navigator.pop(
                                                        context); // close loading
                                                    Navigator.pop(
                                                        context); // close confirmation

                                                    // Setelah submit, refresh data FutureBuilder.
                                                    setState(() {
                                                      checkedFuture =
                                                          getCheckedTodayFuture();
                                                    });

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          "Success! Please open menu 'Checked'",
                                                        ),
                                                        backgroundColor:
                                                            Colors.green,
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    Navigator.pop(
                                                        context); // close loading
                                                    Navigator.pop(
                                                        context); // close confirmation

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          "Error (Data Null) : Please Try Again\n$e",
                                                        ),
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                    );
                                                  }
                                                },
                                                child: const Text("Yes"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.send,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                          Text(
                                            'Get SPM Unit Tire Pressure',
                                            style: getWhiteTextStyle(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                              : Container(),

                          const SizedBox(
                            height: 12,
                          ),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: refreshCheckedData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueGrey,
                              ),
                              child: Text(
                                'Refresh Not Checked Data',
                                style: getWhiteTextStyle(),
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 12,
                          ),
                          FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            future: checkedFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator.adaptive(),
                                );
                              }

                              if (snapshot.hasError) {
                                return Text(
                                  'Error load data: ${snapshot.error}',
                                  style: getBlackTextStyle(fontSize: 14),
                                );
                              }

                              final dailyData = snapshot.data?.docs ?? [];

                              final checkedUnitSet = dailyData
                                  .map((doc) {
                                    final data = doc.data();
                                    return data['unit']?.toString() ?? '';
                                  })
                                  .where((unit) => unit.isNotEmpty)
                                  .toSet();

                              final notChecked = state.units.where((unit) {
                                final unitNumber = unit.unitNumber ?? '';

                                return !checkedUnitSet.contains(unitNumber);
                              }).toList();

                              // Filter area hanya berlaku untuk user:
                              // company ID 1 dan access ID 5.
                              final areaFilteredNotChecked =
                                  notChecked.where((unit) {
                                if (!showNotCheckedPit ||
                                    selectedNotCheckedArea == 'All') {
                                  return true;
                                }

                                final String unitArea =
                                    (unit.area ?? '').trim().toLowerCase();

                                return unitArea ==
                                    selectedNotCheckedArea.trim().toLowerCase();
                              }).toList();

                              final keyword = searchQuery.trim().toLowerCase();

                              final filteredNotChecked =
                                  areaFilteredNotChecked.where((unit) {
                                if (keyword.isEmpty) {
                                  return true;
                                }

                                final unitNumber =
                                    unit.unitNumber?.toLowerCase() ?? '';

                                final model = unit.model?.toLowerCase() ?? '';

                                return unitNumber.contains(keyword) ||
                                    model.contains(keyword);
                              }).toList();

                              DateTime? lastUpdate;

                              if (dailyData.isNotEmpty) {
                                final sortedDocs = [...dailyData];

                                sortedDocs.sort((a, b) {
                                  final aData = a.data();
                                  final bData = b.data();

                                  final aTanggal =
                                      aData['tanggal']?.toString() ?? '';
                                  final bTanggal =
                                      bData['tanggal']?.toString() ?? '';

                                  return bTanggal.compareTo(aTanggal);
                                });

                                final latestData = sortedDocs.first.data();
                                final tanggal =
                                    latestData['tanggal']?.toString();

                                if (tanggal != null && tanggal.isNotEmpty) {
                                  lastUpdate = DateTime.tryParse(tanggal);
                                }
                              }

                              return Column(
                                children: [
                                  Text(
                                    'Total Unit : ${filteredNotChecked.length}',
                                    style: getBlackTextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: filteredNotChecked.isEmpty
                                          ? null
                                          : () async {
                                              try {
                                                final StringBuffer txt =
                                                    StringBuffer();

                                                final String tanggal = DateFormat(
                                                        'dd-MM-yyyy HH:mm:ss')
                                                    .format(DateTime.now());

                                                txt.writeln(
                                                    'LIST UNIT NOT CHECKED');
                                                txt.writeln(
                                                    '==============================');
                                                txt.writeln(
                                                    'Site       : $currentIdSite');

                                                if (showNotCheckedPit) {
                                                  txt.writeln(
                                                    'PIT / Area : $selectedNotCheckedArea',
                                                  );
                                                }

                                                txt.writeln(
                                                    'Tanggal    : $tanggal');
                                                txt.writeln(
                                                  'Total Unit : ${filteredNotChecked.length}',
                                                );
                                                txt.writeln(
                                                    '==============================');
                                                txt.writeln();

                                                for (int index = 0;
                                                    index <
                                                        filteredNotChecked
                                                            .length;
                                                    index++) {
                                                  final unit =
                                                      filteredNotChecked[index];

                                                  final String unitNumber =
                                                      unit.unitNumber?.trim() ??
                                                          '';

                                                  final String model =
                                                      unit.model?.trim() ?? '';

                                                  txt.writeln(
                                                    '${index + 1}. ${unitNumber.isEmpty ? '-' : unitNumber}',
                                                  );

                                                  txt.writeln(
                                                    '   Model : ${model.isEmpty ? '-' : model}',
                                                  );

                                                  final String unitArea =
                                                      (unit.area ?? '').trim();

                                                  if (unitArea.isNotEmpty) {
                                                    txt.writeln(
                                                      '   Area  : $unitArea',
                                                    );
                                                  }

                                                  txt.writeln(
                                                    '------------------------------',
                                                  );
                                                }

                                                final Directory?
                                                    downloadDirectory =
                                                    await DownloadsPath
                                                        .downloadsDirectory();

                                                if (downloadDirectory == null) {
                                                  throw Exception(
                                                    'Folder Download tidak ditemukan',
                                                  );
                                                }

                                                final String fileDate =
                                                    DateFormat(
                                                            'yyyyMMdd_HHmmss')
                                                        .format(DateTime.now());

                                                final String fileName =
                                                    'not_checked_unit_${currentIdSite}_$fileDate.txt';

                                                final File file = File(
                                                  '${downloadDirectory.path}/$fileName',
                                                );

                                                await file.writeAsString(
                                                  txt.toString(),
                                                  flush: true,
                                                );

                                                debugPrint(
                                                  'File berhasil disimpan: ${file.path}',
                                                );

                                                if (!context.mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    backgroundColor:
                                                        Colors.green,
                                                    duration: const Duration(
                                                        seconds: 5),
                                                    content: Text(
                                                      'Berhasil export '
                                                      '${filteredNotChecked.length} unit\n'
                                                      'Download/$fileName',
                                                    ),
                                                  ),
                                                );
                                              } catch (e) {
                                                debugPrint(
                                                  'Gagal export Not Checked: $e',
                                                );

                                                if (!context.mounted) return;

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    backgroundColor: Colors.red,
                                                    content: Text(
                                                      'Gagal export data: $e',
                                                    ),
                                                  ),
                                                );
                                              }
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        disabledBackgroundColor: Colors.grey,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.file_download_outlined,
                                        color: Colors.white,
                                      ),
                                      label: Text(
                                        'Export Not Checked (${filteredNotChecked.length})',
                                        style: getWhiteTextStyle(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 12,
                                  ),
                                  if (lastUpdate != null)
                                    Column(
                                      children: [
                                        Text(
                                          'Last Update : ${DateFormat('HH:mm:ss dd-MM-yyyy').format(lastUpdate)}',
                                          textAlign: TextAlign.center,
                                          style: getBlackTextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                      ],
                                    ),
                                  filteredNotChecked.isEmpty
                                      ? Text(
                                          'Empty!',
                                          textAlign: TextAlign.center,
                                          style:
                                              getBlackTextStyle(fontSize: 18),
                                        )
                                      : ListView.builder(
                                          itemCount: filteredNotChecked.length,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            final unit =
                                                filteredNotChecked[index];

                                            return InkWell(
                                              onTap: (userAccessId != '1' ||
                                                      homeState
                                                              .userAccessCompanyId
                                                              .value ==
                                                          '1')
                                                  ? () {
                                                      // Khusus company 1 +
                                                      // access ID 5, user wajib
                                                      // memilih area terlebih dahulu.
                                                      if (showNotCheckedPit &&
                                                          notCheckedPit.length >
                                                              1 &&
                                                          safeSelectedNotCheckedPit ==
                                                              0) {
                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .hideCurrentSnackBar();

                                                        ScaffoldMessenger.of(
                                                                context)
                                                            .showSnackBar(
                                                          const SnackBar(
                                                            backgroundColor:
                                                                Colors.red,
                                                            content: Text(
                                                              'Please select PIT before checking the unit!',
                                                              style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                            ),
                                                          ),
                                                        );

                                                        return;
                                                      }

                                                      final Map<String, dynamic>
                                                          arguments = {
                                                        'unitNumber':
                                                            unit.unitNumber,
                                                        'reccPress':
                                                            state.reccPress,
                                                      };

                                                      if (showNotCheckedPit &&
                                                          selectedNotCheckedArea !=
                                                              'All') {
                                                        arguments['pit'] =
                                                            selectedNotCheckedArea;
                                                      }

                                                      Navigator.pushNamed(
                                                        context,
                                                        DailyCheckFormPage
                                                            .routeName,
                                                        arguments: arguments,
                                                      );
                                                    }
                                                  : null,
                                              child: Container(
                                                margin:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.1),
                                                      spreadRadius: 2,
                                                      blurRadius: 5,
                                                      offset:
                                                          const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                child: ListTile(
                                                  leading: const Icon(
                                                    Icons.front_loader,
                                                    color: Colors.orange,
                                                  ),
                                                  title: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            bottom: 4.0),
                                                    child: Text(
                                                      unit.unitNumber ?? '',
                                                      style: getBlackTextStyle(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  subtitle: Text(
                                                    [
                                                      unit.model ?? '',
                                                      if (homeState
                                                                  .currentSiteId ==
                                                              '5' &&
                                                          (unit.area ?? '')
                                                              .trim()
                                                              .isNotEmpty)
                                                        'Area: ${unit.area}',
                                                    ].where((value) {
                                                      return value
                                                          .trim()
                                                          .isNotEmpty;
                                                    }).join('\n'),
                                                    style: getGreyTextStyle(
                                                        grey6A707C),
                                                  ),
                                                  // subtitle: Text(
                                                  //   [
                                                  //     unit.model ?? '',
                                                  //     if ((unit.area ?? '')
                                                  //         .trim()
                                                  //         .isNotEmpty)
                                                  //       'Area: ${unit.area}',
                                                  //   ].where((value) {
                                                  //     return value
                                                  //         .trim()
                                                  //         .isNotEmpty;
                                                  //   }).join('\n'),
                                                  //   style: getGreyTextStyle(
                                                  //       grey6A707C),
                                                  // ),
                                                  trailing: const Icon(
                                                      Icons.arrow_forward_ios),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(
                            height: 12,
                          ),
                        ],
                      );
                  }
                  //   case 3:
                  //     final today = DateTime.now();
                  //     final todayString =
                  //         today.toIso8601String().substring(0, 10);

                  //     return Column(
                  //       children: [
                  //         const SizedBox(
                  //           height: 12,
                  //         ),

                  //         // Tombol Get SPM Unit Tire Pressure
                  //         (userAccessId != '1' &&
                  //                 homeState.userAccessCompanyId.value == '')
                  //             ? SizedBox(
                  //                 width: double.infinity,
                  //                 child: ElevatedButton(
                  //                   onPressed: () async {
                  //                     showDialog<bool>(
                  //                       context: context,
                  //                       barrierDismissible: false,
                  //                       builder: (context) {
                  //                         return AlertDialog(
                  //                           title: const Text("Konfirmasi"),
                  //                           content: const Text(
                  //                               "Apakah Anda yakin?"),
                  //                           actions: [
                  //                             TextButton(
                  //                               onPressed: () =>
                  //                                   Navigator.of(context)
                  //                                       .pop(false),
                  //                               child: const Text("No"),
                  //                             ),
                  //                             ElevatedButton(
                  //                               onPressed: () async {
                  //                                 showDialog(
                  //                                   context: context,
                  //                                   barrierDismissible: false,
                  //                                   builder: (context) {
                  //                                     return const AlertDialog(
                  //                                       content: Row(
                  //                                         children: [
                  //                                           CircularProgressIndicator(),
                  //                                           SizedBox(width: 20),
                  //                                           Text(
                  //                                               "Submitting data, please wait..."),
                  //                                         ],
                  //                                       ),
                  //                                     );
                  //                                   },
                  //                                 );

                  //                                 try {
                  //                                   final dataSPMJam7 =
                  //                                       await ApiService
                  //                                           .getJam7SPM(
                  //                                               currentIdSite);

                  //                                   final List<UnitTire>
                  //                                       dataTireCondition =
                  //                                       await ApiService
                  //                                           .getTireCondition(
                  //                                     currentIdSite,
                  //                                   );

                  //                                   final ratingMap =
                  //                                       <String, String>{};
                  //                                   final tireSizeMap =
                  //                                       <String, String>{};
                  //                                   final hmMap =
                  //                                       <String, String>{};
                  //                                   final idInventoryMap =
                  //                                       <String, String>{};
                  //                                   final idUnitMap =
                  //                                       <String, String>{};
                  //                                   final idDailyMap =
                  //                                       <String, String>{};

                  //                                   final today =
                  //                                       DateTime.now();

                  //                                   final formattedToday =
                  //                                       '${today.month.toString().padLeft(2, '0')}'
                  //                                       '${today.day.toString().padLeft(2, '0')}'
                  //                                       '${(today.year % 100).toString().padLeft(2, '0')}';

                  //                                   for (final unit
                  //                                       in dataTireCondition) {
                  //                                     final unitNumber =
                  //                                         unit.unitNumber ?? '';
                  //                                     final posisi =
                  //                                         unit.posisi ?? '';

                  //                                     if (unitNumber
                  //                                             .isNotEmpty &&
                  //                                         posisi.isNotEmpty) {
                  //                                       final key =
                  //                                           '$unitNumber-$posisi';

                  //                                       ratingMap[key] =
                  //                                           unit.rating ?? '';
                  //                                       tireSizeMap[key] =
                  //                                           unit.size ?? '';
                  //                                       hmMap[key] =
                  //                                           unit.hm ?? '';
                  //                                       idInventoryMap[key] =
                  //                                           unit.idinventory ??
                  //                                               '';
                  //                                       idUnitMap[key] =
                  //                                           unit.idUnit ?? '';
                  //                                       idDailyMap[key] =
                  //                                           '$unitNumber$posisi$formattedToday$currentIdSite';
                  //                                     }
                  //                                   }

                  //                                   final batch =
                  //                                       firestore.batch();
                  //                                   final collection =
                  //                                       firestore.collection(
                  //                                           'daily_pressure');

                  //                                   // Ambil semua data checked hari ini sekali saja,
                  //                                   // supaya tidak query Firebase di dalam loop.
                  //                                   final todaySnapshot =
                  //                                       await collection
                  //                                           .where('hari',
                  //                                               isEqualTo:
                  //                                                   todayString)
                  //                                           .where('idSite',
                  //                                               isEqualTo:
                  //                                                   currentIdSite)
                  //                                           .get();

                  //                                   final existingDocMap =
                  //                                       <String, String>{};

                  //                                   for (final doc
                  //                                       in todaySnapshot.docs) {
                  //                                     final data = doc.data();
                  //                                     final unit = data['unit']
                  //                                             ?.toString() ??
                  //                                         '';

                  //                                     if (unit.isNotEmpty) {
                  //                                       existingDocMap[unit] =
                  //                                           doc.id;
                  //                                     }
                  //                                   }

                  //                                   for (final dataUnit
                  //                                       in dataSPMJam7) {
                  //                                     final jsonData =
                  //                                         dataUnit.toJson();
                  //                                     final unitNumber =
                  //                                         dataUnit.devicename ??
                  //                                             '';

                  //                                     if (unitNumber.isEmpty) {
                  //                                       continue;
                  //                                     }

                  //                                     final tireCount = jsonData
                  //                                         .keys
                  //                                         .where((k) =>
                  //                                             k.startsWith(
                  //                                                 'max_p'))
                  //                                         .length;

                  //                                     bool hasZeroPressure =
                  //                                         false;

                  //                                     for (int pos = 1;
                  //                                         pos <= tireCount;
                  //                                         pos++) {
                  //                                       final pressure =
                  //                                           double.tryParse(
                  //                                                 jsonData[
                  //                                                         'avg_p$pos']
                  //                                                     .toString(),
                  //                                               ) ??
                  //                                               0;

                  //                                       if (pressure == 0) {
                  //                                         hasZeroPressure =
                  //                                             true;
                  //                                         break;
                  //                                       }
                  //                                     }

                  //                                     if (hasZeroPressure) {
                  //                                       continue;
                  //                                     }

                  //                                     final existingDocId =
                  //                                         existingDocMap[
                  //                                             unitNumber];

                  //                                     final docRef =
                  //                                         existingDocId != null
                  //                                             ? collection.doc(
                  //                                                 existingDocId)
                  //                                             : collection
                  //                                                 .doc();

                  //                                     batch.set(docRef, {
                  //                                       'idSite': currentIdSite,
                  //                                       'user':
                  //                                           user['username'] ??
                  //                                               'Username',
                  //                                       'tanggal': DateTime
                  //                                               .now()
                  //                                           .toIso8601String(),
                  //                                       'hari': todayString,
                  //                                       'jam': DateTime.now()
                  //                                           .toIso8601String()
                  //                                           .substring(11, 19),
                  //                                       'unit': unitNumber,
                  //                                       'hm': hmMap[
                  //                                               '$unitNumber-1'] ??
                  //                                           '',
                  //                                       'posisi': List.generate(
                  //                                           tireCount,
                  //                                           (pIndex) {
                  //                                         final pos =
                  //                                             pIndex + 1;
                  //                                         final key =
                  //                                             '$unitNumber-$pos';

                  //                                         return {
                  //                                           'pos': '$pos',
                  //                                           'pressure': (double
                  //                                                       .tryParse(
                  //                                                     jsonData[
                  //                                                             'avg_p$pos']
                  //                                                         .toString(),
                  //                                                   ) ??
                  //                                                   0)
                  //                                               .toStringAsFixed(
                  //                                                   0),
                  //                                           'rating': ratingMap[
                  //                                                   key] ??
                  //                                               '',
                  //                                           'adjusmentPressure':
                  //                                               '0',
                  //                                           'luka': '',
                  //                                           'image': '',
                  //                                           'tireSize':
                  //                                               tireSizeMap[
                  //                                                       key] ??
                  //                                                   '',
                  //                                           'idInventory':
                  //                                               idInventoryMap[
                  //                                                       key] ??
                  //                                                   '',
                  //                                           'idUnit': idUnitMap[
                  //                                                   key] ??
                  //                                               '',
                  //                                           'idDaily':
                  //                                               idDailyMap[
                  //                                                       key] ??
                  //                                                   '',
                  //                                           'kondisi': '',
                  //                                           'min_press': (double
                  //                                                       .tryParse(
                  //                                                     jsonData[
                  //                                                             'min_p$pos']
                  //                                                         .toString(),
                  //                                                   ) ??
                  //                                                   0)
                  //                                               .toStringAsFixed(
                  //                                                   0),
                  //                                           'max_press': (double
                  //                                                       .tryParse(
                  //                                                     jsonData[
                  //                                                             'max_p$pos']
                  //                                                         .toString(),
                  //                                                   ) ??
                  //                                                   0)
                  //                                               .toStringAsFixed(
                  //                                                   0),
                  //                                           'avg_press': (double
                  //                                                       .tryParse(
                  //                                                     jsonData[
                  //                                                             'avg_p$pos']
                  //                                                         .toString(),
                  //                                                   ) ??
                  //                                                   0)
                  //                                               .toStringAsFixed(
                  //                                                   0),
                  //                                           'temp':
                  //                                               double.tryParse(
                  //                                                     jsonData[
                  //                                                             'avg_t$pos']
                  //                                                         .toString(),
                  //                                                   ) ??
                  //                                                   0,
                  //                                         };
                  //                                       }),
                  //                                       'pit': 'Default',
                  //                                       'timeLowPressureSPM':
                  //                                           '',
                  //                                     });
                  //                                   }

                  //                                   await batch.commit();

                  //                                   Navigator.pop(
                  //                                       context); // close loading
                  //                                   Navigator.pop(
                  //                                       context); // close confirmation

                  //                                   ScaffoldMessenger.of(
                  //                                           context)
                  //                                       .showSnackBar(
                  //                                     const SnackBar(
                  //                                       content: Text(
                  //                                         "Success! Please open menu 'Checked'",
                  //                                       ),
                  //                                       backgroundColor:
                  //                                           Colors.green,
                  //                                     ),
                  //                                   );
                  //                                 } catch (e) {
                  //                                   Navigator.pop(
                  //                                       context); // close loading
                  //                                   Navigator.pop(
                  //                                       context); // close confirmation

                  //                                   ScaffoldMessenger.of(
                  //                                           context)
                  //                                       .showSnackBar(
                  //                                     SnackBar(
                  //                                       content: Text(
                  //                                         "Error (Data Null) : Please Try Again\n$e",
                  //                                       ),
                  //                                       backgroundColor:
                  //                                           Colors.red,
                  //                                     ),
                  //                                   );
                  //                                 }
                  //                               },
                  //                               child: const Text("Yes"),
                  //                             ),
                  //                           ],
                  //                         );
                  //                       },
                  //                     );
                  //                   },
                  //                   style: ElevatedButton.styleFrom(
                  //                     backgroundColor: Colors.red,
                  //                   ),
                  //                   child: Container(
                  //                     padding: const EdgeInsets.symmetric(
                  //                         vertical: 12),
                  //                     child: Row(
                  //                       mainAxisAlignment:
                  //                           MainAxisAlignment.center,
                  //                       children: [
                  //                         const Icon(
                  //                           Icons.send,
                  //                           color: Colors.white,
                  //                         ),
                  //                         const SizedBox(
                  //                           width: 12,
                  //                         ),
                  //                         Text(
                  //                           'Get SPM Unit Tire Pressure',
                  //                           style: getWhiteTextStyle(),
                  //                         ),
                  //                       ],
                  //                     ),
                  //                   ),
                  //                 ),
                  //               )
                  //             : Container(),

                  //         const SizedBox(
                  //           height: 12,
                  //         ),

                  //         StreamBuilder<QuerySnapshot>(
                  //           stream: firestore
                  //               .collection('daily_pressure')
                  //               .where('hari', isEqualTo: todayString)
                  //               .where('idSite', isEqualTo: currentIdSite)
                  //               .snapshots(),
                  //           builder: (context, snapshot) {
                  //             if (snapshot.connectionState ==
                  //                 ConnectionState.waiting) {
                  //               return const Center(
                  //                 child: CircularProgressIndicator.adaptive(),
                  //               );
                  //             }

                  //             if (snapshot.hasError) {
                  //               return Text(
                  //                 'Error load data: ${snapshot.error}',
                  //                 style: getBlackTextStyle(fontSize: 14),
                  //               );
                  //             }

                  //             final dailyData = snapshot.data?.docs ?? [];

                  //             final checkedUnitSet = dailyData
                  //                 .map((doc) {
                  //                   final data =
                  //                       doc.data() as Map<String, dynamic>;
                  //                   return data['unit']?.toString() ?? '';
                  //                 })
                  //                 .where((unit) => unit.isNotEmpty)
                  //                 .toSet();

                  //             final notChecked = state.units.where((unit) {
                  //               final unitNumber = unit.unitNumber ?? '';
                  //               return !checkedUnitSet.contains(unitNumber);
                  //             }).toList();

                  //             final keyword = searchQuery.toLowerCase();

                  //             final filteredNotChecked =
                  //                 notChecked.where((unit) {
                  //               if (keyword.isEmpty) return true;

                  //               final unitNumber =
                  //                   unit.unitNumber?.toLowerCase() ?? '';
                  //               final model = unit.model?.toLowerCase() ?? '';

                  //               return unitNumber.contains(keyword) ||
                  //                   model.contains(keyword);
                  //             }).toList();

                  //             DateTime? lastUpdate;

                  //             if (dailyData.isNotEmpty) {
                  //               final sortedDocs = [...dailyData];

                  //               sortedDocs.sort((a, b) {
                  //                 final aData =
                  //                     a.data() as Map<String, dynamic>;
                  //                 final bData =
                  //                     b.data() as Map<String, dynamic>;

                  //                 final aTanggal =
                  //                     aData['tanggal']?.toString() ?? '';
                  //                 final bTanggal =
                  //                     bData['tanggal']?.toString() ?? '';

                  //                 return bTanggal.compareTo(aTanggal);
                  //               });

                  //               final latestData = sortedDocs.first.data()
                  //                   as Map<String, dynamic>;

                  //               final tanggal =
                  //                   latestData['tanggal']?.toString();

                  //               if (tanggal != null && tanggal.isNotEmpty) {
                  //                 lastUpdate = DateTime.tryParse(tanggal);
                  //               }
                  //             }

                  //             return Column(
                  //               children: [
                  //                 Text(
                  //                   'Total Unit : ${filteredNotChecked.length}',
                  //                   style: getBlackTextStyle(
                  //                     fontSize: 20,
                  //                   ),
                  //                 ),
                  //                 const SizedBox(
                  //                   height: 12,
                  //                 ),
                  //                 if (lastUpdate != null)
                  //                   Column(
                  //                     children: [
                  //                       Text(
                  //                         'Last Update : ${DateFormat('HH:mm:ss dd-MM-yyyy').format(lastUpdate)}',
                  //                         textAlign: TextAlign.center,
                  //                         style: getBlackTextStyle(
                  //                           fontSize: 14,
                  //                         ),
                  //                       ),
                  //                       const SizedBox(
                  //                         height: 12,
                  //                       ),
                  //                     ],
                  //                   ),
                  //                 filteredNotChecked.isEmpty
                  //                     ? Text(
                  //                         'Empty!',
                  //                         textAlign: TextAlign.center,
                  //                         style:
                  //                             getBlackTextStyle(fontSize: 18),
                  //                       )
                  //                     : ListView.builder(
                  //                         itemCount: filteredNotChecked.length,
                  //                         shrinkWrap: true,
                  //                         physics:
                  //                             const NeverScrollableScrollPhysics(),
                  //                         itemBuilder: (context, index) {
                  //                           final unit =
                  //                               filteredNotChecked[index];

                  //                           return InkWell(
                  //                             onTap: (userAccessId != '1' ||
                  //                                     homeState
                  //                                             .userAccessCompanyId
                  //                                             .value ==
                  //                                         '1')
                  //                                 ? () {
                  //                                     Navigator.pushNamed(
                  //                                       context,
                  //                                       DailyCheckFormPage
                  //                                           .routeName,
                  //                                       arguments: {
                  //                                         'unitNumber':
                  //                                             unit.unitNumber,
                  //                                         'reccPress':
                  //                                             state.reccPress,
                  //                                       },
                  //                                     );
                  //                                   }
                  //                                 : null,
                  //                             child: Container(
                  //                               margin:
                  //                                   const EdgeInsets.symmetric(
                  //                                       vertical: 8.0),
                  //                               padding:
                  //                                   const EdgeInsets.symmetric(
                  //                                       vertical: 6),
                  //                               decoration: BoxDecoration(
                  //                                 color: Colors.white,
                  //                                 borderRadius:
                  //                                     BorderRadius.circular(12),
                  //                                 boxShadow: [
                  //                                   BoxShadow(
                  //                                     color: Colors.black
                  //                                         .withOpacity(0.1),
                  //                                     spreadRadius: 2,
                  //                                     blurRadius: 5,
                  //                                     offset:
                  //                                         const Offset(0, 2),
                  //                                   ),
                  //                                 ],
                  //                               ),
                  //                               child: ListTile(
                  //                                 leading: const Icon(
                  //                                   Icons.front_loader,
                  //                                   color: Colors.orange,
                  //                                 ),
                  //                                 title: Padding(
                  //                                   padding:
                  //                                       const EdgeInsets.only(
                  //                                           bottom: 4.0),
                  //                                   child: Text(
                  //                                     unit.unitNumber ?? '',
                  //                                     style: getBlackTextStyle(
                  //                                       fontWeight:
                  //                                           FontWeight.w700,
                  //                                     ),
                  //                                   ),
                  //                                 ),
                  //                                 subtitle: Text(
                  //                                   unit.model ?? '',
                  //                                   style: getGreyTextStyle(
                  //                                       grey6A707C),
                  //                                 ),
                  //                                 trailing: const Icon(
                  //                                     Icons.arrow_forward_ios),
                  //                               ),
                  //                             ),
                  //                           );
                  //                         },
                  //                       ),
                  //               ],
                  //             );
                  //           },
                  //         ),

                  //         const SizedBox(
                  //           height: 12,
                  //         ),
                  //       ],
                  //     );
                  // }

                  // KODE LAMA YANG BIKIN LEMOT
                  //   case 3:
                  //     final notChecked = [];
                  //     notChecked.clear();
                  //     notChecked.addAll(state.units);
                  //     return Column(
                  //       children: [
                  //         const SizedBox(
                  //           height: 12,
                  //         ),
                  //         // (userAccessId == '1' || userAccessId == '2')
                  //         (userAccessId != '1' &&
                  //                 homeState.userAccessCompanyId.value == '')
                  //             ? SizedBox(
                  //                 width: double.infinity,
                  //                 child: ElevatedButton(
                  //                     onPressed: () async {
                  //                       showDialog<bool>(
                  //                           context: context,
                  //                           barrierDismissible: false,
                  //                           builder: (context) {
                  //                             return AlertDialog(
                  //                               title: const Text("Konfirmasi"),
                  //                               content: const Text(
                  //                                   "Apakah Anda yakin?"),
                  //                               actions: [
                  //                                 TextButton(
                  //                                   onPressed: () => Navigator
                  //                                           .of(context)
                  //                                       .pop(false), // pilih No
                  //                                   child: const Text("No"),
                  //                                 ),
                  //                                 ElevatedButton(
                  //                                   onPressed: () async {
                  //                                     showDialog(
                  //                                       context: context,
                  //                                       barrierDismissible:
                  //                                           false,
                  //                                       builder: (context) {
                  //                                         return const AlertDialog(
                  //                                           content: Row(
                  //                                             children: [
                  //                                               CircularProgressIndicator(),
                  //                                               SizedBox(
                  //                                                   width: 20),
                  //                                               Text(
                  //                                                   "Submitting data, please wait..."),
                  //                                             ],
                  //                                           ),
                  //                                         );
                  //                                       },
                  //                                     );
                  //                                     try {
                  //                                       final dataSPMJam7 =
                  //                                           await ApiService
                  //                                               .getJam7SPM(
                  //                                                   currentIdSite);

                  //                                       final List<UnitTire>
                  //                                           dataTireCondition =
                  //                                           await ApiService
                  //                                               .getTireCondition(
                  //                                                   currentIdSite);

                  //                                       final ratingMap =
                  //                                           <String, String>{};
                  //                                       final tireSizeMap =
                  //                                           <String, String>{};
                  //                                       final hmMap =
                  //                                           <String, String>{};
                  //                                       final idInventoryMap =
                  //                                           <String, String>{};
                  //                                       final idUnitMap =
                  //                                           <String, String>{};
                  //                                       final idDailyMap =
                  //                                           <String, String>{};
                  //                                       final today =
                  //                                           DateTime.now();
                  //                                       final startOfDay =
                  //                                           DateTime(
                  //                                               today.year,
                  //                                               today.month,
                  //                                               today.day);
                  //                                       final endOfDay =
                  //                                           DateTime(
                  //                                               today.year,
                  //                                               today.month,
                  //                                               today.day,
                  //                                               23,
                  //                                               59,
                  //                                               59);
                  //                                       final formattedToday =
                  //                                           '${today.month.toString().padLeft(2, '0')}' // MM
                  //                                           '${today.day.toString().padLeft(2, '0')}' // DD
                  //                                           '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

                  //                                       for (final unit
                  //                                           in dataTireCondition) {
                  //                                         if (unit.unitNumber!
                  //                                                 .isNotEmpty &&
                  //                                             unit.posisi!
                  //                                                 .isNotEmpty) {
                  //                                           final key =
                  //                                               '${unit.unitNumber}-${unit.posisi}';
                  //                                           ratingMap[key] =
                  //                                               unit.rating ??
                  //                                                   '';
                  //                                           tireSizeMap[key] =
                  //                                               unit.size ?? '';
                  //                                           hmMap[key] =
                  //                                               unit.hm ?? '';
                  //                                           idInventoryMap[
                  //                                                   key] =
                  //                                               unit.idinventory ??
                  //                                                   '';
                  //                                           idUnitMap[key] =
                  //                                               unit.idUnit ??
                  //                                                   '';
                  //                                           idDailyMap[key] =
                  //                                               '${unit.unitNumber}${unit.posisi}$formattedToday$currentIdSite';
                  //                                         }
                  //                                       }

                  //                                       final batch =
                  //                                           firestore.batch();
                  //                                       final collection =
                  //                                           firestore.collection(
                  //                                               'daily_pressure');

                  //                                       for (int i = 0;
                  //                                           i <
                  //                                               dataSPMJam7
                  //                                                   .length;
                  //                                           i++) {
                  //                                         final dataUnit =
                  //                                             dataSPMJam7[i];

                  //                                         // tire count
                  //                                         final tireCount = dataUnit
                  //                                             .toJson()
                  //                                             .keys
                  //                                             .where((k) =>
                  //                                                 k.startsWith(
                  //                                                     'max_p'))
                  //                                             .length;

                  //                                         bool hasZeroPressure =
                  //                                             false;
                  //                                         for (int pos = 1;
                  //                                             pos <= tireCount;
                  //                                             pos++) {
                  //                                           final pressure =
                  //                                               double.tryParse(
                  //                                                     dataUnit
                  //                                                         .toJson()[
                  //                                                             'avg_p$pos']
                  //                                                         .toString(),
                  //                                                   ) ??
                  //                                                   0;
                  //                                           if (pressure == 0) {
                  //                                             hasZeroPressure =
                  //                                                 true;
                  //                                             break; // stop pengecekan
                  //                                           }
                  //                                         }

                  //                                         if (hasZeroPressure) {
                  //                                           continue;
                  //                                         }

                  //                                         final snapshot = await collection
                  //                                             .where('unit',
                  //                                                 isEqualTo:
                  //                                                     dataUnit
                  //                                                         .devicename)
                  //                                             .where('tanggal',
                  //                                                 isGreaterThanOrEqualTo:
                  //                                                     startOfDay
                  //                                                         .toIso8601String())
                  //                                             .where('tanggal',
                  //                                                 isLessThanOrEqualTo:
                  //                                                     endOfDay
                  //                                                         .toIso8601String())
                  //                                             .get();

                  //                                         // Kalau ada snapshot → pakai doc lama, kalau tidak → bikin baru
                  //                                         final docRef = snapshot
                  //                                                 .docs
                  //                                                 .isNotEmpty
                  //                                             ? collection.doc(
                  //                                                 snapshot
                  //                                                     .docs
                  //                                                     .first
                  //                                                     .id) // overwrite dok lama
                  //                                             : collection
                  //                                                 .doc(); // bikin dok baru

                  //                                         batch.set(docRef, {
                  //                                           'idSite':
                  //                                               currentIdSite ??
                  //                                                   '',
                  //                                           'user': user[
                  //                                                   'username'] ??
                  //                                               'Username',
                  //                                           'tanggal': DateTime
                  //                                                       .now()
                  //                                                   .toIso8601String() ??
                  //                                               '',
                  //                                           'hari': DateTime
                  //                                                       .now()
                  //                                                   .toIso8601String()
                  //                                                   .substring(
                  //                                                       0,
                  //                                                       10) ??
                  //                                               '',
                  //                                           'jam': DateTime
                  //                                                       .now()
                  //                                                   .toIso8601String()
                  //                                                   .substring(
                  //                                                       11,
                  //                                                       19) ??
                  //                                               '',
                  //                                           'unit': dataUnit
                  //                                                   .devicename ??
                  //                                               '',
                  //                                           'hm': hmMap[
                  //                                                   '${dataUnit.devicename}-${i + 1}'] ??
                  //                                               '',
                  //                                           'posisi':
                  //                                               List.generate(
                  //                                                   tireCount,
                  //                                                   (pIndex) {
                  //                                             final pos =
                  //                                                 pIndex + 1;
                  //                                             return {
                  //                                               'pos': '$pos',
                  //                                               // 'pressure': dataUnit
                  //                                               //         .toJson()['avg_p$pos'] ??
                  //                                               //     '0',
                  //                                               'pressure': (double.tryParse(dataUnit
                  //                                                           .toJson()[
                  //                                                               'avg_p$pos']
                  //                                                           .toString()) ??
                  //                                                       0)
                  //                                                   .toStringAsFixed(
                  //                                                       0),
                  //                                               'rating': ratingMap[
                  //                                                   '${dataUnit.devicename}-$pos'],
                  //                                               'adjusmentPressure':
                  //                                                   '0',
                  //                                               'luka': '',
                  //                                               'image': '',
                  //                                               'tireSize':
                  //                                                   tireSizeMap[
                  //                                                       '${dataUnit.devicename}-$pos'],
                  //                                               'idInventory':
                  //                                                   idInventoryMap[
                  //                                                       '${dataUnit.devicename}-$pos'],
                  //                                               'idUnit': idUnitMap[
                  //                                                   '${dataUnit.devicename}-$pos'],
                  //                                               'idDaily':
                  //                                                   idDailyMap[
                  //                                                       '${dataUnit.devicename}-$pos'],
                  //                                               'kondisi': '',
                  //                                               'min_press': (double.tryParse(dataUnit
                  //                                                           .toJson()[
                  //                                                               'min_p$pos']
                  //                                                           .toString()) ??
                  //                                                       0)
                  //                                                   .toStringAsFixed(
                  //                                                       0),
                  //                                               'max_press': (double.tryParse(dataUnit
                  //                                                           .toJson()[
                  //                                                               'max_p$pos']
                  //                                                           .toString()) ??
                  //                                                       0)
                  //                                                   .toStringAsFixed(
                  //                                                       0),
                  //                                               'avg_press': (double.tryParse(dataUnit
                  //                                                           .toJson()[
                  //                                                               'avg_p$pos']
                  //                                                           .toString()) ??
                  //                                                       0)
                  //                                                   .toStringAsFixed(
                  //                                                       0),
                  //                                               'temp': (double.tryParse(dataUnit
                  //                                                       .toJson()[
                  //                                                           'avg_t$pos']
                  //                                                       .toString()) ??
                  //                                                   0),
                  //                                             };
                  //                                           }),
                  //                                           'pit': 'Default',
                  //                                           'timeLowPressureSPM':
                  //                                               '',
                  //                                         });
                  //                                       }

                  //                                       await batch.commit();

                  //                                       Navigator.pop(context);
                  //                                       Navigator.pop(context);
                  //                                       ScaffoldMessenger.of(
                  //                                               context)
                  //                                           .showSnackBar(
                  //                                               const SnackBar(
                  //                                         content: Text(
                  //                                             "Success! Please open menu 'Checked'"),
                  //                                         backgroundColor:
                  //                                             Colors.green,
                  //                                       ));
                  //                                     } catch (e) {
                  //                                       // Tutup semua dialog
                  //                                       Navigator.pop(
                  //                                           context); // close submitting
                  //                                       Navigator.pop(
                  //                                           context); // close konfirmasi

                  //                                       ScaffoldMessenger.of(
                  //                                               context)
                  //                                           .showSnackBar(
                  //                                         SnackBar(
                  //                                           content: Text(
                  //                                               "Error (Data Null) : Please Try Again"),
                  //                                           backgroundColor:
                  //                                               Colors.red,
                  //                                         ),
                  //                                       );
                  //                                     }
                  //                                   },
                  //                                   child: const Text("Yes"),
                  //                                 ),
                  //                               ],
                  //                             );
                  //                           });
                  //                     },
                  //                     style: ElevatedButton.styleFrom(
                  //                         backgroundColor: Colors.red),
                  //                     child: Container(
                  //                       padding:
                  //                           EdgeInsets.symmetric(vertical: 12),
                  //                       child: Row(
                  //                         mainAxisAlignment:
                  //                             MainAxisAlignment.center,
                  //                         children: [
                  //                           const Icon(
                  //                             Icons.send,
                  //                             color: Colors.white,
                  //                           ),
                  //                           const SizedBox(
                  //                             width: 12,
                  //                           ),
                  //                           Text(
                  //                             'Get SPM Unit Tire Pressure',
                  //                             style: getWhiteTextStyle(),
                  //                           ),
                  //                         ],
                  //                       ),
                  //                     )))
                  //             : Container(),

                  //         const SizedBox(
                  //           height: 12,
                  //         ),
                  //         StreamBuilder(
                  //             stream: firestore
                  //                 .collection('daily_pressure')
                  //                 .where('tanggal',
                  //                     isGreaterThanOrEqualTo:
                  //                         DateTime(now.year, now.month, now.day)
                  //                             .toIso8601String())
                  //                 .where('tanggal',
                  //                     isLessThanOrEqualTo: DateTime(now.year,
                  //                             now.month, now.day, 23, 59, 59)
                  //                         .toIso8601String())
                  //                 .where('idSite', isEqualTo: currentIdSite)
                  //                 .snapshots(),
                  //             builder: (context, snapshot) {
                  //               if (snapshot.connectionState ==
                  //                   ConnectionState.waiting) {
                  //                 return CircularProgressIndicator.adaptive();
                  //               }
                  //               if (snapshot.connectionState ==
                  //                   ConnectionState.active) {
                  //                 final dailyData = snapshot.data?.docs ?? [];

                  //                 // Mendapatkan field 'unit' dari setiap dokumen
                  //                 final unitList = dailyData
                  //                     .map((doc) => doc['unit'])
                  //                     .toList();

                  //                 // Mengecek apakah 'unitList' kosong, jika tidak kosong lanjutkan removeWhere
                  //                 unitList.isNotEmpty
                  //                     ? notChecked.removeWhere((element) =>
                  //                         unitList.contains(element.unitNumber))
                  //                     : [];

                  //                 log('not checked unit : ${notChecked}');

                  //                 return Column(
                  //                   children: [
                  //                     Text(
                  //                       'Total Unit : ${notChecked.length ?? 0}',
                  //                       style: getBlackTextStyle(
                  //                         fontSize: 20,
                  //                       ),
                  //                     ),
                  //                     const SizedBox(
                  //                       height: 12,
                  //                     ),
                  //                     (snapshot.data?.size != 0)
                  //                         ? Column(
                  //                             children: [
                  //                               Builder(builder: (context) {
                  //                                 // Parsing string to DateTime object
                  //                                 DateTime parsedDate =
                  //                                     DateTime.parse(snapshot
                  //                                         .data
                  //                                         ?.docs[snapshot
                  //                                                 .data!.size -
                  //                                             1]
                  //                                         .data()['tanggal']);

                  //                                 // Formatting DateTime to the desired format
                  //                                 String formattedDate = DateFormat(
                  //                                         'HH:mm:ss dd-MM-yyyy')
                  //                                     .format(parsedDate);
                  //                                 return Text(
                  //                                   'Last Update : ${formattedDate}',
                  //                                   textAlign: TextAlign.center,
                  //                                   style: getBlackTextStyle(
                  //                                     fontSize: 14,
                  //                                   ),
                  //                                 );
                  //                               }),
                  //                               const SizedBox(
                  //                                 height: 12,
                  //                               ),
                  //                             ],
                  //                           )
                  //                         : Container(),
                  //                     (notChecked == null || notChecked.isEmpty)
                  //                         ? Text(
                  //                             'Empty!',
                  //                             textAlign: TextAlign.center,
                  //                             style: getBlackTextStyle(
                  //                                 fontSize: 18),
                  //                           )
                  //                         : Column(
                  //                             children:
                  //                                 (notChecked).map((unit) {
                  //                               if (searchQuery.isNotEmpty &&
                  //                                   !unit.unitNumber!
                  //                                       .toLowerCase()
                  //                                       .contains(
                  //                                           searchQuery) &&
                  //                                   !unit.model!
                  //                                       .toLowerCase()
                  //                                       .contains(
                  //                                           searchQuery)) {
                  //                                 return Container();
                  //                               }
                  //                               return InkWell(
                  //                                 // onTap: (userAccessId == '1' ||
                  //                                 //         userAccessId == '2' ||
                  //                                 //         userAccessId == '3')
                  //                                 onTap: (userAccessId != '1' ||
                  //                                         homeState
                  //                                                 .userAccessCompanyId
                  //                                                 .value ==
                  //                                             '1')
                  //                                     ? () {
                  //                                         Navigator.pushNamed(
                  //                                             context,
                  //                                             DailyCheckFormPage
                  //                                                 .routeName,
                  //                                             arguments: {
                  //                                               'unitNumber': unit
                  //                                                   .unitNumber,
                  //                                               'reccPress': state
                  //                                                   .reccPress,
                  //                                             });
                  //                                       }
                  //                                     : () {},
                  //                                 child: Container(
                  //                                   margin:
                  //                                       EdgeInsets.symmetric(
                  //                                           vertical: 8.0),
                  //                                   padding:
                  //                                       EdgeInsets.symmetric(
                  //                                           vertical: 6),
                  //                                   decoration: BoxDecoration(
                  //                                     color: Colors.white,
                  //                                     borderRadius:
                  //                                         BorderRadius.circular(
                  //                                             12),
                  //                                     boxShadow: [
                  //                                       BoxShadow(
                  //                                         color: Colors.black
                  //                                             .withOpacity(0.1),
                  //                                         spreadRadius: 2,
                  //                                         blurRadius: 5,
                  //                                         offset: Offset(0, 2),
                  //                                       ),
                  //                                     ],
                  //                                   ),
                  //                                   child: ListTile(
                  //                                     leading: Icon(
                  //                                       Icons.front_loader,
                  //                                       color: Colors.orange,
                  //                                     ),
                  //                                     title: Padding(
                  //                                       padding:
                  //                                           const EdgeInsets
                  //                                               .only(
                  //                                               bottom: 4.0),
                  //                                       child: Text(
                  //                                         '${unit.unitNumber}',
                  //                                         style:
                  //                                             getBlackTextStyle(
                  //                                                 fontWeight:
                  //                                                     FontWeight
                  //                                                         .w700),
                  //                                       ),
                  //                                     ),
                  //                                     subtitle: Text(
                  //                                       '${unit.model}',
                  //                                       style: getGreyTextStyle(
                  //                                           grey6A707C),
                  //                                     ),
                  //                                     trailing: Icon(Icons
                  //                                         .arrow_forward_ios),
                  //                                   ),
                  //                                 ),
                  //                               );
                  //                             }).toList(),
                  //                           ),
                  //                   ],
                  //                 );
                  //               }

                  //               return Container();
                  //             }),
                  //         const SizedBox(
                  //           height: 12,
                  //         ),
                  //       ],
                  //     );
                  // }
                }
                return Container();
              }),
            ],
          ),
        ),
      )),
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: green00968A,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.done_outline_rounded),
              label: homeState.userAccessCompanyId.value == '1' &&
                      homeState.userAccessId.value == '1'
                  ? 'Complete'
                  : 'Checked (All)'),
          BottomNavigationBarItem(
              icon: Icon(Icons.error),
              label: homeState.userAccessCompanyId.value == '1' &&
                      homeState.userAccessId.value == '1'
                  ? 'Incomplete Check'
                  : 'Checked (Low)'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All Unit'),
          BottomNavigationBarItem(
              icon: Icon(Icons.close), label: 'Not Checked'),
        ],
        currentIndex: selectedMenu,
        // onTap: (index) {
        //   setState(() {
        //     selectedMenu = index;
        //   });
        // },
        onTap: (index) {
          setState(() {
            selectedMenu = index;

            if (index == 0 || index == 1 || index == 3) {
              checkedFuture = getCheckedTodayFuture();
            }
          });
        },
      ),
    );
  }
}

// import 'dart:developer';
// import 'dart:io';

// import 'package:camos/core/utils/data/id_site.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/not_update_warning_widget.dart';
// import 'package:camos/pages/pressure_gauge_digital/widget/temperature_status_badge_widget.dart';
// import 'package:get/get.dart';
// import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
// import 'package:lucide_icons/lucide_icons.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';

// import '../../core/blocs/daily_check_post/daily_check_post_bloc.dart';
// import '../../core/services/api_service.dart';
// import '../../core/services/model/daily_press.dart';
// import '../../core/services/model/recc_press.dart';
// import '../../core/services/model/unit_tire.dart';
// import '../../core/services/shared_preferences/shared_preferences.dart';
// import '../../core/styles/color.dart';
// import '../../core/styles/text_manager.dart';
// import '../../core/utils/data/daily_check_firebase.dart';
// import '../../core/utils/functions/functions.dart';
// import '../../core/widgets/appbar_widget.dart';
// import '../../core/widgets/button_widget.dart';
// import '../home/home_state.dart';
// import 'daily_check_form_page.dart';
// import 'daily_pressure_history_page.dart';
// import 'widget/enum_export_type.dart';
// import 'widget/export_excel_button.dart';
// import 'widget/select_pit_button.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
// import 'package:http/http.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import '../../core/blocs/unit/unit_bloc.dart';
// import 'package:collection/collection.dart';

// class DailyPressureListPage extends StatefulWidget {
//   static const routeName = '/daily-pressure-list-page';
//   const DailyPressureListPage({super.key});

//   @override
//   State<DailyPressureListPage> createState() => _DailyPressureListPageState();
// }

// class _DailyPressureListPageState extends State<DailyPressureListPage> {
//   // FirebaseFirestore firestore = FirebaseFirestore.instance;
//   final HomeState homeState = Get.isRegistered<HomeState>()
//       ? Get.find<HomeState>()
//       : Get.put(HomeState());

//   Future<QuerySnapshot<Map<String, dynamic>>>? checkedFuture;
//   Future<QuerySnapshot<Map<String, dynamic>>>? notCheckedFuture;

//   FirebaseFirestore firestore = FirebaseFirestore.instance;
//   String currentIdSite = '';
//   String userAccessId = '';
//   List<String> pit = [];
//   final List<String> notCheckedPit = [
//     'All',
//     'Central',
//     'Northwest',
//   ];

//   int selectedNotCheckedPit = 0;
//   int selectedPit = 0;
//   int selectedMenu = 2;
//   String searchQuery = '';
//   Map<String, dynamic> user = {};
//   List<Map<String, dynamic>> filteredItemTask = [];
//   List<UnitTire> units = [];
//   List<UnitTire> allUnit = [];
//   Map<String, dynamic> allTireSize = {};

//   int countAllTire = 0;
//   bool isOnline = false;
//   bool isLoading = false;
//   bool isEmpty = false;

//   DateTime now = DateTime.now();

//   // ────────────────────────────────
//   // INIT STATE
//   // ────────────────────────────────
//   @override
//   void initState() {
//     log('init page terpanggil : ${homeState.currentSiteId}');
//     initializePage();
//     getUnitBefore7AM();

//     super.initState();
//   }

//   getUnitBefore7AM() {
//     if (DateTime.now().hour < 7) {
//       print('buka halaman sebelum jam 7');
//       setState(() {
//         isOnline = !isOnline;

//         getUnits();
//       });
//     }
//   }

//   Future<void> initializePage() async {
//     log('initialize page terpanggil');
//     await getUser();
//     await setupSite();
//     setupPit();
//     await getCount();

//     checkedFuture = getCheckedTodayFuture();
//   }

//   Future<QuerySnapshot<Map<String, dynamic>>> getCheckedTodayFuture() {
//     final now = DateTime.now();

//     final startOfDay = DateTime(
//       now.year,
//       now.month,
//       now.day,
//     );

//     final startOfNextDay = startOfDay.add(
//       const Duration(days: 1),
//     );

//     final startDate = startOfDay.toIso8601String();
//     final endDate = startOfNextDay.toIso8601String();

//     log('====================================');
//     log('LOAD CHECKED UNIT');
//     log('Site          : $currentIdSite');
//     log('Selected Pit  : $selectedPit');
//     log('Start Date    : $startDate');
//     log('End Date      : $endDate');
//     log('====================================');

//     Query<Map<String, dynamic>> query = firestore
//         .collection('daily_pressure')
//         .where(
//           'tanggal',
//           isGreaterThanOrEqualTo: startDate,
//         )
//         .where(
//           'tanggal',
//           isLessThan: endDate,
//         )
//         .where(
//           'idSite',
//           isEqualTo: currentIdSite,
//         );

//     if (selectedPit != 0 && pit.isNotEmpty && selectedPit < pit.length) {
//       query = query.where(
//         'pit',
//         isEqualTo: pit[selectedPit],
//       );
//     }

//     return query.get();
//   }

//   // Future<QuerySnapshot<Map<String, dynamic>>> getCheckedTodayFuture() {
//   //   final todayString = DateTime.now().toIso8601String().substring(0, 10);
//   //   print('hari ini : $todayString');
//   //   print('id site hari ini : $currentIdSite');

//   //   if (selectedPit == 0) {
//   //     return firestore
//   //         .collection('daily_pressure')
//   //         .where('hari', isEqualTo: todayString)
//   //         .where('idSite', isEqualTo: currentIdSite)
//   //         .get();
//   //   }

//   //   return firestore
//   //       .collection('daily_pressure')
//   //       .where('hari', isEqualTo: todayString)
//   //       .where('idSite', isEqualTo: currentIdSite)
//   //       .where('pit', isEqualTo: pit[selectedPit])
//   //       .get();
//   // }

//   void refreshCheckedData() {
//     setState(() {
//       checkedFuture = getCheckedTodayFuture();
//     });
//   }

//   void setupPit() {
//     pit.clear();

//     switch (currentIdSite) {
//       case '5':
//         pit.addAll([
//           'All',
//           'PITSTOP AMBON',
//           'PITSTOP BANGKA',
//           'PITSTOP BUTON',
//           'PITSTOP IPD',
//           'PITSTOP MEDAN',
//           'PITSTOP OB2',
//           'PITSTOP SABANG',
//           'WSP',
//           'Other'
//         ]);
//         break;
//       case '52':
//         pit.addAll(['All', 'Utara', 'Selatan', 'RML', 'WS']);
//         break;
//       case '137':
//         pit.addAll(['All', 'Japun', 'PCE']);
//         break;
//       case '35':
//         pit.addAll(['All', 'Tabuhan', 'EBL', 'Workshop']);
//         break;
//       case '65':
//         pit.addAll([
//           'All',
//           'Room B1 Selatan',
//           'TIA',
//           'Serongga',
//           'CSA Selatan',
//           'WS',
//         ]);
//         break;
//       case '166':
//         pit.addAll(
//             ['All', 'WS', 'CSA Bagaspati', 'Pondok Operator', 'Pit Stop Toll']);
//         break;
//       default:
//         pit.add('All');
//     }
//   }

//   // ────────────────────────────────
//   // USER DATA
//   // ────────────────────────────────
//   Future<void> getUser() async {
//     user = await getUserPreferences();
//     log('👤 User data: $user');
//   }

//   // ────────────────────────────────
//   // SITE SETUP
//   // ────────────────────────────────
//   Future<void> setupSite() async {
//     // ambil current dan actual site dari HomeState
//     currentIdSite = homeState.currentSiteId;
//     userAccessId = homeState.userAccessId.value;

//     log('🏗️ Current Site: $currentIdSite | Actual Site: $userAccessId');

//     await getUnits();
//   }

//   // ────────────────────────────────
//   // GET UNITS
//   // ────────────────────────────────
//   Future<void> getUnits() async {
//     log('🔄 getUnits() dipanggil untuk site: $currentIdSite (online=$isOnline)');
//     final isSis = homeState.userAccessCompanyId.value == '1';
//     // jika user bukan office site (bukan 1 atau 2)
//     // if (userAccessId != '1' && userAccessId != '2') {
//     if (userAccessId != '1' || isSis) {
//       if (!isOnline) {
//         // Offline Mode
//         log('📴 Load data dari cache untuk site $currentIdSite');
//         context.read<UnitBloc>().add(
//               GetUnitsEvent(idSite: currentIdSite, isOnline: false),
//             );
//       } else {
//         // Cek koneksi dulu
//         final connectivityResult = await Connectivity().checkConnectivity();

//         if (connectivityResult == ConnectivityResult.none) {
//           setState(() {
//             isOnline = false;
//           });
//           _showNoConnectionDialog();
//           return;
//         }

//         // Online Mode
//         log('🌐 Load data dari CTS untuk site $currentIdSite');
//         context.read<UnitBloc>().add(
//               GetUnitsEvent(idSite: currentIdSite, isOnline: true),
//             );
//       }
//     } else {
//       // Untuk user office — selalu online
//       log('🏢 Office user — ambil data online untuk site $currentIdSite');
//       context.read<UnitBloc>().add(
//             GetUnitsEvent(idSite: currentIdSite, isOnline: true),
//           );
//     }
//   }

//   // ────────────────────────────────
//   // COUNT DATA
//   // ────────────────────────────────
//   Future<void> getCount() async {
//     final snapshot = await firestore
//         .collection('daily_pressure')
//         .where('idSite', isEqualTo: currentIdSite)
//         .count()
//         .get();

//     final count = snapshot.count;
//     log('📊 Jumlah data daily_pressure ($currentIdSite): $count');
//   }

//   // ────────────────────────────────
//   // HELPER
//   // ────────────────────────────────
//   void _showNoConnectionDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(
//             'Please check your internet connection!',
//             style: getBlackTextStyle(),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.pop(context);
//                 Navigator.pop(context);
//               },
//               child: Text('Okay'),
//             )
//           ],
//         );
//       },
//     );
//   }

//   Future<String> getActualIdSite() async {
//     return currentIdSite;
//   }

//   @override
//   Widget build(BuildContext context) {
//     log('tanggal sekarang : ${DateTime(now.year, now.month, now.day).toIso8601String()}');
//     // getCount();
//     // pit.clear();
//     setupPit();

//     return Scaffold(
//       appBar: appBarWidget('Daily Pressure List', context),
//       body: SafeArea(
//           child: SingleChildScrollView(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             children: [
//               FutureBuilder(
//                   future: getActualIdSite(),
//                   builder: (context, snapshot) {
//                     if (snapshot.connectionState == ConnectionState.waiting) {
//                       return Container();
//                     }

//                     final data = snapshot.data;
//                     log('id site future builder : $data');
//                     bool isSis = homeState.userAccessCompanyId.value == '1';

//                     // if (userAccessId != '1' &&
//                     //     userAccessId != '2' &&
//                     //     userAccessId != '3') {
//                     if (userAccessId != '1' || isSis) {
//                       return Column(
//                         children: [
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: () {
//                                 setState(() {
//                                   isOnline = !isOnline; // Toggle the status
//                                   getUnits();
//                                 });
//                               },
//                               style: ElevatedButton.styleFrom(
//                                 primary: Colors.green,
//                               ),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   Icon(
//                                     Icons.fire_truck,
//                                     color: white,
//                                   ),
//                                   const SizedBox(
//                                     width: 12,
//                                   ),
//                                   Text(
//                                     'Update Unit',
//                                     style: getWhiteTextStyle(),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(
//                             height: 6,
//                           ),
//                           Text(
//                             'Press this if list unit not showing!',
//                             style: getGreyTextStyle(grey8391A1, fontSize: 12),
//                           ),
//                         ],
//                       );
//                     }
//                     return Container();
//                   }),
//               const SizedBox(
//                 height: 12,
//               ),
//               TextField(
//                 onChanged: (value) {
//                   setState(() {
//                     searchQuery = value;
//                   });
//                 },
//                 decoration: InputDecoration(
//                     hintText: 'Search... (Unit Number or Model)',
//                     hintStyle: getGreyTextStyle(grey8391A1),
//                     prefixIcon: Icon(Icons.search)),
//               ),
//               const SizedBox(
//                 height: 12,
//               ),
//               const SizedBox(
//                 height: 12,
//               ),
//               Builder(builder: (context) {
//                 if (selectedMenu == 0) {
//                   return Column(
//                     children: [
//                       ExportExcelButton(
//                         user: user,
//                         pit: pit,
//                         selectedPit: selectedPit,
//                         filteredItemTask: filteredItemTask,
//                         date:
//                             "${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().year}",
//                         type: ExportType.oneDay,
//                       ),
//                       const SizedBox(
//                         height: 16,
//                       ),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           onPressed: () async {
//                             bool? confirmSend = await showDialog(
//                               context: context,
//                               builder: (context) => AlertDialog(
//                                 title: Row(
//                                   children: [
//                                     Icon(
//                                       Icons.warning,
//                                       color: Colors.orange,
//                                     ),
//                                     const SizedBox(
//                                       width: 12,
//                                     ),
//                                     Text(
//                                       "Warning",
//                                       style: getRedTextStyle(fontSize: 24)
//                                           .copyWith(
//                                         color: Colors.orange,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 content: Text(
//                                   "Are you sure? Please Check Before Send Data!",
//                                   style: getBlackTextStyle(),
//                                 ),
//                                 actions: [
//                                   TextButton(
//                                     onPressed: () =>
//                                         Navigator.pop(context, false),
//                                     child: Text("No"),
//                                   ),
//                                   TextButton(
//                                     onPressed: () =>
//                                         Navigator.pop(context, true),
//                                     child: Text("Yes"),
//                                   ),
//                                 ],
//                               ),
//                             );

//                             if (confirmSend == true) {
//                               context.read<DailyCheckPostBloc>().add(
//                                     DailyCheckPostEvent(
//                                       dailyCheck: filteredItemTask,
//                                       countAllTire: countAllTire,
//                                       allUnit: allUnit,
//                                       allTireSize: allTireSize,
//                                       typeSend: 'single',
//                                     ),
//                                   );

//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   backgroundColor: green00968A,
//                                   content: Text(
//                                     'Successful Save Data!',
//                                     style: getWhiteTextStyle(),
//                                   ),
//                                 ),
//                               );
//                             }
//                           },
//                           style: ElevatedButton.styleFrom(
//                               backgroundColor: green00968A),
//                           child: Container(
//                             padding: EdgeInsets.symmetric(vertical: 12),
//                             child: Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.send, color: Colors.white),
//                                 SizedBox(width: 12),
//                                 Text('Send Data to CTS',
//                                     style: getWhiteTextStyle()),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   );
//                 }
//                 return Container();
//               }),
//               if (selectedMenu == 0)
//                 const SizedBox(
//                   height: 12,
//                 )
//               else
//                 Container(),
//               SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                       onPressed: () {
//                         Navigator.pushNamed(
//                             context, DailyPressureHistoryPage.routeName);
//                       },
//                       style: ElevatedButton.styleFrom(
//                           backgroundColor: Colors.orange),
//                       child: Container(
//                         padding: EdgeInsets.symmetric(vertical: 12),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.history,
//                               color: Colors.white,
//                             ),
//                             const SizedBox(
//                               width: 12,
//                             ),
//                             Text(
//                               'History',
//                               style: getWhiteTextStyle(),
//                             ),
//                           ],
//                         ),
//                       ))),
//               // tester 1
//               BlocConsumer<UnitBloc, UnitState>(listener: (context, state) {
//                 if (state is UnitLoadedState) {
//                   setState(() {
//                     // Tambahkan setState agar UI diperbarui
//                     allUnit = state.units;
//                     countAllTire = state.countAllTire;
//                     allTireSize = state.allTireSize;
//                   });
//                   // log('ban daily : ${state.units}');
//                 }
//               }, builder: (context, state) {
//                 if (state is UnitLoadingState) {
//                   return Center(child: CircularProgressIndicator());
//                 }

//                 if (state is UnitLoadedState) {
//                   switch (selectedMenu) {
//                     // Checked Unit
//                     case 0:
//                       checkedFuture ??= getCheckedTodayFuture();

//                       return Column(
//                         children: [
//                           const SizedBox(height: 12),
//                           SelectPitButton(
//                             pit: pit,
//                             selectedPit: selectedPit,
//                             onSelectedPitChanged: (index) {
//                               setState(() {
//                                 selectedPit = index;
//                                 checkedFuture = getCheckedTodayFuture();
//                               });
//                             },
//                           ),
//                           const SizedBox(height: 12),
//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: refreshCheckedData,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.blueGrey,
//                               ),
//                               child: Text(
//                                 'Refresh Checked Data',
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                           FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                             future: checkedFuture,
//                             builder: (context, snapshot) {
//                               if (snapshot.connectionState ==
//                                   ConnectionState.waiting) {
//                                 return const Center(
//                                   child: CircularProgressIndicator.adaptive(),
//                                 );
//                               }

//                               if (snapshot.hasError) {
//                                 return Text(
//                                   'Error load checked data: ${snapshot.error}',
//                                   style: getBlackTextStyle(fontSize: 14),
//                                 );
//                               }

//                               final docs = snapshot.data?.docs ?? [];

//                               log('docs list daily : $docs');

//                               // Ambil semua data dari Firestore
//                               final rawData = docs.map((doc) {
//                                 return doc.data();
//                               }).toList();

// // Sort dulu dari tanggal terbaru ke terlama
//                               rawData.sort((a, b) {
//                                 final aTanggal = a['tanggal']?.toString() ?? '';
//                                 final bTanggal = b['tanggal']?.toString() ?? '';
//                                 return bTanggal.compareTo(aTanggal);
//                               });

// // DISTINCT BY UNIT
// // Kalau ada unit duplikat, yang dipakai adalah data paling terbaru
// // karena rawData sudah di-sort descending berdasarkan tanggal.
//                               final distinctMap =
//                                   <String, Map<String, dynamic>>{};

//                               for (final item in rawData) {
//                                 final unit = item['unit']?.toString() ?? '';

//                                 if (unit.isEmpty) {
//                                   continue;
//                                 }

//                                 if (!distinctMap.containsKey(unit)) {
//                                   distinctMap[unit] =
//                                       Map<String, dynamic>.from(item);
//                                 }
//                               }

//                               final distinctDaily = distinctMap.values.toList();

//                               log('distinct list daily : $distinctDaily');

//                               final keyword = searchQuery.toLowerCase();

//                               final filteredData = distinctDaily.where((data) {
//                                 final unit =
//                                     data['unit']?.toString().toLowerCase() ??
//                                         '';
//                                 final model =
//                                     data['model']?.toString().toLowerCase() ??
//                                         '';

//                                 if (keyword.isEmpty) return true;

//                                 return unit.contains(keyword) ||
//                                     model.contains(keyword);
//                               }).toList();

//                               filteredItemTask.clear();

//                               for (final item in filteredData) {
//                                 filteredItemTask
//                                     .add(Map<String, dynamic>.from(item));
//                               }

//                               DateTime? lastUpdate;

//                               if (distinctDaily.isNotEmpty) {
//                                 final tanggal =
//                                     distinctDaily.first['tanggal']?.toString();

//                                 if (tanggal != null && tanggal.isNotEmpty) {
//                                   lastUpdate = DateTime.tryParse(tanggal);
//                                 }
//                               }

//                               return Column(
//                                 children: [
//                                   Text(
//                                     'Total Unit : ${filteredData.length}',
//                                     style: getBlackTextStyle(fontSize: 20),
//                                   ),
//                                   const SizedBox(height: 12),
//                                   if (lastUpdate != null)
//                                     Column(
//                                       children: [
//                                         Text(
//                                           'Last Update : ${DateFormat('HH:mm:ss dd-MM-yyyy').format(lastUpdate)}',
//                                           textAlign: TextAlign.center,
//                                           style:
//                                               getBlackTextStyle(fontSize: 14),
//                                         ),
//                                         const SizedBox(height: 12),
//                                       ],
//                                     ),
//                                   filteredData.isEmpty
//                                       ? Text(
//                                           'Empty!',
//                                           textAlign: TextAlign.center,
//                                           style:
//                                               getBlackTextStyle(fontSize: 18),
//                                         )
//                                       : ListView.builder(
//                                           itemCount: filteredData.length,
//                                           shrinkWrap: true,
//                                           physics:
//                                               const NeverScrollableScrollPhysics(),
//                                           itemBuilder: (context, index) {
//                                             final dailyMap =
//                                                 filteredData[index];
//                                             final positionList =
//                                                 dailyMap['posisi']
//                                                         as List<dynamic>? ??
//                                                     [];

//                                             return Card(
//                                               elevation: 2,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius:
//                                                     BorderRadius.circular(12),
//                                               ),
//                                               color: green00968A,
//                                               child: Container(
//                                                 width: double.infinity,
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                   horizontal: 12,
//                                                   vertical: 24,
//                                                 ),
//                                                 decoration: BoxDecoration(
//                                                   color: green00968A,
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                 ),
//                                                 child: ExpansionTile(
//                                                   tilePadding: EdgeInsets.zero,
//                                                   childrenPadding:
//                                                       EdgeInsets.zero,
//                                                   title: Row(
//                                                     children: [
//                                                       Icon(
//                                                         Icons.task,
//                                                         color: white,
//                                                         size: 36,
//                                                       ),
//                                                       const SizedBox(width: 12),
//                                                       Expanded(
//                                                         child: Text(
//                                                           '${dailyMap['unit'] ?? ''}${((dailyMap['pit'] != 'Default') ? '\n${dailyMap['pit']}' : '')}',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontWeight: w700,
//                                                             fontSize: 18,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   trailing: const SizedBox(
//                                                     width: 90,
//                                                     child: Icon(
//                                                         Icons.arrow_drop_down),
//                                                   ),
//                                                   children: [
//                                                     const SizedBox(height: 12),
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceBetween,
//                                                       children: [
//                                                         Text(
//                                                           'Name',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                                   fontSize: 18),
//                                                         ),
//                                                         SizedBox(
//                                                           width: 250,
//                                                           child: Text(
//                                                             dailyMap['user'] ??
//                                                                 'No Name',
//                                                             textAlign:
//                                                                 TextAlign.end,
//                                                             style:
//                                                                 getWhiteTextStyle(
//                                                               fontWeight: w700,
//                                                               fontSize: 18,
//                                                             ),
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     const SizedBox(height: 12),
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceBetween,
//                                                       children: [
//                                                         Text(
//                                                           'Tanggal',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                                   fontSize: 18),
//                                                         ),
//                                                         Text(
//                                                           dailyMap['tanggal']
//                                                                   ?.toString()
//                                                                   .split('T')
//                                                                   .first ??
//                                                               '',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontWeight: w700,
//                                                             fontSize: 18,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     const SizedBox(height: 12),
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceBetween,
//                                                       children: [
//                                                         Text(
//                                                           'Waktu',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                                   fontSize: 18),
//                                                         ),
//                                                         Text(
//                                                           dailyMap['tanggal'] !=
//                                                                   null
//                                                               ? dailyMap[
//                                                                       'tanggal']
//                                                                   .toString()
//                                                                   .split('T')[1]
//                                                                   .substring(
//                                                                       0, 5)
//                                                               : '',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontWeight: w700,
//                                                             fontSize: 18,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     const SizedBox(height: 12),
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceBetween,
//                                                       children: [
//                                                         Text(
//                                                           (currentIdSite ==
//                                                                       bmbhauling
//                                                                           .idSite ||
//                                                                   currentIdSite ==
//                                                                       '1')
//                                                               ? 'KM Unit'
//                                                               : 'HM Unit',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                                   fontSize: 18),
//                                                         ),
//                                                         Column(
//                                                           crossAxisAlignment:
//                                                               CrossAxisAlignment
//                                                                   .end,
//                                                           children: [
//                                                             Text(
//                                                               (dailyMap['hm'] ==
//                                                                       '')
//                                                                   ? '0'
//                                                                   : dailyMap[
//                                                                       'hm'],
//                                                               style:
//                                                                   getWhiteTextStyle(
//                                                                 fontWeight:
//                                                                     w700,
//                                                                 fontSize: 18,
//                                                               ),
//                                                             ),
//                                                             (dailyMap['hmNote'] !=
//                                                                     null)
//                                                                 ? Column(
//                                                                     crossAxisAlignment:
//                                                                         CrossAxisAlignment
//                                                                             .end,
//                                                                     children: [
//                                                                       const SizedBox(
//                                                                         height:
//                                                                             6,
//                                                                       ),
//                                                                       Text(
//                                                                           'Note : ' + dailyMap['hmNote'] ??
//                                                                               '',
//                                                                           style:
//                                                                               getWhiteTextStyle(fontSize: 18)),
//                                                                     ],
//                                                                   )
//                                                                 : Container()
//                                                           ],
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     const SizedBox(height: 12),
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceBetween,
//                                                       children: [
//                                                         Text(
//                                                           'Pit',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                                   fontSize: 18),
//                                                         ),
//                                                         Text(
//                                                           dailyMap['pit'] ?? '',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontWeight: w700,
//                                                             fontSize: 18,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     const SizedBox(height: 12),
//                                                     ListView.builder(
//                                                       itemCount:
//                                                           positionList.length,
//                                                       shrinkWrap: true,
//                                                       physics:
//                                                           const NeverScrollableScrollPhysics(),
//                                                       itemBuilder:
//                                                           (context, posIndex) {
//                                                         final pl = positionList[
//                                                             posIndex];
//                                                         List<dynamic> luka = [];

//                                                         if (pl['luka'] !=
//                                                                 null &&
//                                                             pl['luka']
//                                                                 is! String) {
//                                                           luka = pl['luka']
//                                                               as List<dynamic>;
//                                                         }

//                                                         return Column(
//                                                           children: [
//                                                             Row(
//                                                               mainAxisAlignment:
//                                                                   MainAxisAlignment
//                                                                       .spaceBetween,
//                                                               crossAxisAlignment:
//                                                                   CrossAxisAlignment
//                                                                       .center,
//                                                               children: [
//                                                                 Text(
//                                                                   'Pos. ${pl['pos']}',
//                                                                   style:
//                                                                       getWhiteTextStyle(
//                                                                     fontSize:
//                                                                         18,
//                                                                   ),
//                                                                 ),
//                                                                 Column(
//                                                                   crossAxisAlignment:
//                                                                       CrossAxisAlignment
//                                                                           .end,
//                                                                   children: [
//                                                                     Row(
//                                                                       children: [
//                                                                         Text(
//                                                                           '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
//                                                                           style:
//                                                                               getWhiteTextStyle(
//                                                                             fontWeight:
//                                                                                 w700,
//                                                                             fontSize:
//                                                                                 18,
//                                                                           ),
//                                                                         ),
//                                                                         const SizedBox(
//                                                                             width:
//                                                                                 6),
//                                                                         (pl['temperatureStatus'] !=
//                                                                                 null)
//                                                                             ? TemperatureStatusBadgeWidget(
//                                                                                 status: pl['temperatureStatus'],
//                                                                               )
//                                                                             : Container(),
//                                                                       ],
//                                                                     ),
//                                                                     if (pl['adjusmentPressure'] != null &&
//                                                                         pl['adjusmentPressure'] !=
//                                                                             '0' &&
//                                                                         pl['adjusmentPressure'] !=
//                                                                             '')
//                                                                       Text(
//                                                                         '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
//                                                                         style:
//                                                                             getWhiteTextStyle(
//                                                                           fontWeight:
//                                                                               w700,
//                                                                           fontSize:
//                                                                               18,
//                                                                         ),
//                                                                       ),
//                                                                     if (luka
//                                                                         .isNotEmpty)
//                                                                       Text(
//                                                                         luka.join(
//                                                                             '\n'),
//                                                                         textAlign:
//                                                                             TextAlign.end,
//                                                                         style:
//                                                                             getWhiteTextStyle(
//                                                                           fontWeight:
//                                                                               w700,
//                                                                           fontSize:
//                                                                               18,
//                                                                         ),
//                                                                       ),
//                                                                     Text(
//                                                                       '${(pl['rating'] == '' || pl['rating'] == null) ? '' : 'Rating ${pl['rating']}'}',
//                                                                       style:
//                                                                           getWhiteTextStyle(
//                                                                         fontWeight:
//                                                                             w700,
//                                                                         fontSize:
//                                                                             18,
//                                                                       ),
//                                                                     ),
//                                                                     (userAccessId ==
//                                                                             '1')
//                                                                         ? Column(
//                                                                             children: [
//                                                                               SizedBox(height: 12),
//                                                                               Text(
//                                                                                 'RTD ${pl['rtd1'] ?? '-'}/${pl['rtd2'] ?? '-'}',
//                                                                                 style: getWhiteTextStyle(
//                                                                                   fontWeight: w700,
//                                                                                   fontSize: 18,
//                                                                                 ),
//                                                                               ),
//                                                                             ],
//                                                                           )
//                                                                         : Container(),
//                                                                     const SizedBox(
//                                                                         height:
//                                                                             12),
//                                                                   ],
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                             Divider(
//                                                               color: white,
//                                                               thickness: 1.5,
//                                                             ),
//                                                           ],
//                                                         );
//                                                       },
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                 ],
//                               );
//                             },
//                           ),
//                         ],
//                       );
//                     // return Column(
//                     //   children: [
//                     //     const SizedBox(
//                     //       height: 12,
//                     //     ),
//                     //     SelectPitButton(
//                     //         pit: pit,
//                     //         selectedPit: selectedPit,
//                     //         onSelectedPitChanged: (index) {
//                     //           setState(() {
//                     //             selectedPit = index;
//                     //           });
//                     //         }),
//                     //     const SizedBox(
//                     //       height: 12,
//                     //     ),
//                     //     StreamBuilder(
//                     //         stream: firestore
//                     //             .collection('daily_pressure')
//                     //             .where('tanggal',
//                     //                 isGreaterThanOrEqualTo:
//                     //                     DateTime(now.year, now.month, now.day)
//                     //                         .toIso8601String())
//                     //             .where('tanggal',
//                     //                 isLessThanOrEqualTo: DateTime(now.year,
//                     //                         now.month, now.day, 23, 59, 59)
//                     //                     .toIso8601String())
//                     //             .where('idSite', isEqualTo: currentIdSite)
//                     //             .snapshots(),
//                     //         builder: (context, snapshot) {
//                     //           if (snapshot.connectionState ==
//                     //               ConnectionState.waiting) {
//                     //             return CircularProgressIndicator.adaptive();
//                     //           }
//                     //           if (snapshot.connectionState ==
//                     //               ConnectionState.active) {
//                     //             final allData = snapshot.data?.docs
//                     //                 .map((doc) => DailyPress.fromFirestore(
//                     //                     doc.data() as Map<String, dynamic>))
//                     //                 .toList();

//                     //             final distinctDaily =
//                     //                 Set<DailyPress>.from(allData ?? [])
//                     //                     .toList();

//                     //             final tmpDailyData =
//                     //                 snapshot.data?.docs ?? [];

//                     //             final dailyData = distinctDaily.where((doc) {
//                     //               // pilih all pit
//                     //               if (pit.isNotEmpty) {
//                     //                 if (pit[selectedPit] == 'All') {
//                     //                   return doc.idSite == currentIdSite;
//                     //                 }

//                     //                 // ada pit
//                     //                 if (doc.pit != 'Default') {
//                     //                   return doc.idSite == currentIdSite &&
//                     //                       doc.pit == pit[selectedPit];
//                     //                 }
//                     //               }

//                     //               // tidak ada pit
//                     //               return doc.idSite == currentIdSite;
//                     //             }).toList();

//                     //             // untuk data export excel
//                     //             filteredItemTask.clear();
//                     //             filteredItemTask.clear();

//                     //             dailyData.forEach((item) {
//                     //               Map<String, dynamic> cast =
//                     //                   item.toFirestore();
//                     //               filteredItemTask.add(cast);
//                     //             });

//                     //             return Column(
//                     //               children: [
//                     //                 Text(
//                     //                   'Total Unit : ${distinctDaily.length ?? 0}',
//                     //                   style: getBlackTextStyle(
//                     //                     fontSize: 20,
//                     //                   ),
//                     //                 ),
//                     //                 const SizedBox(
//                     //                   height: 12,
//                     //                 ),
//                     //                 (snapshot.data?.size != 0)
//                     //                     ? Column(
//                     //                         children: [
//                     //                           Builder(builder: (context) {
//                     //                             // Parsing string to DateTime object
//                     //                             DateTime parsedDate =
//                     //                                 DateTime.parse(snapshot
//                     //                                     .data
//                     //                                     ?.docs[snapshot
//                     //                                             .data!.size -
//                     //                                         1]
//                     //                                     .data()['tanggal']);

//                     //                             // Formatting DateTime to the desired format
//                     //                             String formattedDate = DateFormat(
//                     //                                     'HH:mm:ss dd-MM-yyyy')
//                     //                                 .format(parsedDate);
//                     //                             return Text(
//                     //                               'Last Update : ${formattedDate}',
//                     //                               textAlign: TextAlign.center,
//                     //                               style: getBlackTextStyle(
//                     //                                 fontSize: 14,
//                     //                               ),
//                     //                             );
//                     //                           }),
//                     //                           const SizedBox(
//                     //                             height: 12,
//                     //                           ),
//                     //                         ],
//                     //                       )
//                     //                     : Container(),
//                     //               ],
//                     //             );
//                     //           }

//                     //           return Container();
//                     //         }),
//                     //     PaginateFirestore(
//                     //         query: selectedPit == 0
//                     //             ? firestore
//                     //                 .collection('daily_pressure')
//                     //                 .where('tanggal',
//                     //                     isGreaterThanOrEqualTo:
//                     //                         DateTime(now.year, now.month, now.day)
//                     //                             .toIso8601String())
//                     //                 .where('tanggal',
//                     //                     isLessThanOrEqualTo:
//                     //                         DateTime(now.year, now.month, now.day, 23, 59, 59)
//                     //                             .toIso8601String())
//                     //                 .where('idSite', isEqualTo: currentIdSite)
//                     //                 .orderBy('tanggal', descending: true)
//                     //             : firestore
//                     //                 .collection('daily_pressure')
//                     //                 .where('tanggal',
//                     //                     isGreaterThanOrEqualTo:
//                     //                         DateTime(now.year, now.month, now.day)
//                     //                             .toIso8601String())
//                     //                 .where('tanggal',
//                     //                     isLessThanOrEqualTo:
//                     //                         DateTime(now.year, now.month, now.day, 23, 59, 59)
//                     //                             .toIso8601String())
//                     //                 .where('idSite', isEqualTo: currentIdSite)
//                     //                 .where('pit', isEqualTo: pit[selectedPit])
//                     //                 .orderBy('tanggal', descending: true),
//                     //         itemBuilderType: PaginateBuilderType.listView,
//                     //         shrinkWrap: true,
//                     //         physics: NeverScrollableScrollPhysics(),
//                     //         itemsPerPage: 10,
//                     //         // isLive: true,
//                     //         isLive: false,
//                     //         initialLoader: const Center(child: CircularProgressIndicator.adaptive()),
//                     //         bottomLoader: const Center(child: CircularProgressIndicator.adaptive()),
//                     //         itemBuilder: (context, snapshot, firebaseIndex) {
//                     //           final Map<String, dynamic> dailyMap =
//                     //               snapshot[firebaseIndex].data()
//                     //                   as Map<String, dynamic>;
//                     //           final positionList =
//                     //               dailyMap['posisi'] as List<dynamic>;

//                     //           if (selectedPit != 0) {
//                     //             if (dailyMap['pit'] != pit[selectedPit]) {
//                     //               return Container();
//                     //             }
//                     //           }

//                     //           if (searchQuery.isNotEmpty &&
//                     //               !dailyMap['unit']!
//                     //                   .toLowerCase()
//                     //                   .contains(searchQuery)) {
//                     //             return Container();
//                     //           }

//                     //           return Card(
//                     //               elevation: 2,
//                     //               shape: RoundedRectangleBorder(
//                     //                 borderRadius: BorderRadius.circular(12),
//                     //               ),
//                     //               color: green00968A,
//                     //               child: Container(
//                     //                 width: double.infinity,
//                     //                 padding: EdgeInsets.symmetric(
//                     //                     horizontal: 12, vertical: 24),
//                     //                 decoration: BoxDecoration(
//                     //                   color: green00968A,
//                     //                   borderRadius: BorderRadius.circular(12),
//                     //                 ),
//                     //                 child: ExpansionTile(
//                     //                   tilePadding: EdgeInsets.zero,
//                     //                   childrenPadding: EdgeInsets.all(0),
//                     //                   title: Row(
//                     //                     children: [
//                     //                       Icon(
//                     //                         Icons.task,
//                     //                         color: white,
//                     //                         size: 36,
//                     //                       ),
//                     //                       const SizedBox(
//                     //                         width: 12,
//                     //                       ),
//                     //                       Text(
//                     //                         dailyMap['unit'] +
//                     //                             '${((dailyMap['pit'] != 'Default') ? '\n' + dailyMap['pit'] : '')}',
//                     //                         style: getWhiteTextStyle(
//                     //                             fontWeight: w700,
//                     //                             fontSize: 18),
//                     //                       )
//                     //                     ],
//                     //                   ),
//                     //                   trailing: SizedBox(
//                     //                     width: 90,
//                     //                     child: Icon(Icons.arrow_drop_down),
//                     //                   ),
//                     //                   children: [
//                     //                     const SizedBox(
//                     //                       height: 12,
//                     //                     ),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           'Name',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         Container(
//                     //                           width: 250,
//                     //                           child: Text(
//                     //                             dailyMap['user'] ?? 'No Name',
//                     //                             textAlign: TextAlign.end,
//                     //                             style: getWhiteTextStyle(
//                     //                                 fontWeight: w700,
//                     //                                 fontSize: 18),
//                     //                           ),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(
//                     //                       height: 12,
//                     //                     ),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           'Tanggal',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         Text(
//                     //                           dailyMap['tanggal']
//                     //                                   .split('T')[0] ??
//                     //                               '',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontWeight: w700,
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(
//                     //                       height: 12,
//                     //                     ),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           'Waktu',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         Text(
//                     //                           dailyMap['tanggal']
//                     //                               .split('T')[1]
//                     //                               .substring(0, 5),
//                     //                           style: getWhiteTextStyle(
//                     //                               fontWeight: w700,
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(
//                     //                       height: 12,
//                     //                     ),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           (currentIdSite ==
//                     //                                   bmbhauling.idSite)
//                     //                               ? 'KM Unit'
//                     //                               : 'HM Unit',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         Text(
//                     //                           dailyMap['hm'] ?? '',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontWeight: w700,
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(
//                     //                       height: 12,
//                     //                     ),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           'Pit',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         Text(
//                     //                           dailyMap['pit'],
//                     //                           style: getWhiteTextStyle(
//                     //                               fontWeight: w700,
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(
//                     //                       height: 12,
//                     //                     ),
//                     //                     Column(
//                     //                       children: positionList.map((pl) {
//                     //                         final plIndex =
//                     //                             positionList.indexOf(pl);
//                     //                         List<dynamic> luka = [];

//                     //                         if (pl['luka'] != null &&
//                     //                             pl['luka'] is! String) {
//                     //                           luka =
//                     //                               pl['luka'] as List<dynamic>;
//                     //                         }

//                     //                         return Column(
//                     //                           children: [
//                     //                             Row(
//                     //                               mainAxisAlignment:
//                     //                                   MainAxisAlignment
//                     //                                       .spaceBetween,
//                     //                               crossAxisAlignment:
//                     //                                   CrossAxisAlignment
//                     //                                       .center,
//                     //                               children: [
//                     //                                 Text(
//                     //                                   'Pos. ${pl['pos']}',
//                     //                                   style:
//                     //                                       getWhiteTextStyle(
//                     //                                           fontSize: 18),
//                     //                                 ),
//                     //                                 Column(
//                     //                                   crossAxisAlignment:
//                     //                                       CrossAxisAlignment
//                     //                                           .end,
//                     //                                   mainAxisAlignment:
//                     //                                       MainAxisAlignment
//                     //                                           .center,
//                     //                                   children: [
//                     //                                     Column(
//                     //                                       crossAxisAlignment:
//                     //                                           CrossAxisAlignment
//                     //                                               .end,
//                     //                                       children: [
//                     //                                         Row(
//                     //                                           children: [
//                     //                                             Text(
//                     //                                               '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
//                     //                                               style: getWhiteTextStyle(
//                     //                                                   fontWeight:
//                     //                                                       w700,
//                     //                                                   fontSize:
//                     //                                                       18),
//                     //                                             ),
//                     //                                             const SizedBox(
//                     //                                               width: 6,
//                     //                                             ),
//                     //                                             (pl['temperatureStatus'] !=
//                     //                                                     null)
//                     //                                                 ? TemperatureStatusBadgeWidget(
//                     //                                                     status:
//                     //                                                         pl['temperatureStatus'])
//                     //                                                 : Container()
//                     //                                             // Text(
//                     //                                             //   // '${(pl['temperatureStatus'] == '' || pl['temperatureStatus'] == null) ? 'HOT' : pl['temperatureStatus']}',
//                     //                                             //   '${(pl['temperatureStatus'])}',
//                     //                                             //   style: getWhiteTextStyle(
//                     //                                             //       fontWeight:
//                     //                                             //           w700,
//                     //                                             //       fontSize:
//                     //                                             //           18),
//                     //                                             // ),
//                     //                                           ],
//                     //                                         ),
//                     //                                         (pl['adjusmentPressure'] != null &&
//                     //                                                 pl['adjusmentPressure'] !=
//                     //                                                     '0' &&
//                     //                                                 pl['adjusmentPressure'] !=
//                     //                                                     '')
//                     //                                             ? Text(
//                     //                                                 '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
//                     //                                                 style: getWhiteTextStyle(
//                     //                                                     fontWeight:
//                     //                                                         w700,
//                     //                                                     fontSize:
//                     //                                                         18),
//                     //                                               )
//                     //                                             : Container(),
//                     //                                       ],
//                     //                                     ),
//                     //                                     (luka.isEmpty ||
//                     //                                             luka == null)
//                     //                                         ? Container()
//                     //                                         : Text(
//                     //                                             pl['luka']
//                     //                                                 .join(
//                     //                                                     '\n'),
//                     //                                             textAlign:
//                     //                                                 TextAlign
//                     //                                                     .end,
//                     //                                             style: getWhiteTextStyle(
//                     //                                                 fontWeight:
//                     //                                                     w700,
//                     //                                                 fontSize:
//                     //                                                     18),
//                     //                                           ),
//                     //                                     Text(
//                     //                                         '${(pl['rating'] == '' || pl['rating'] == null) ? '' : 'Rating ${pl['rating']}'}',
//                     //                                         style:
//                     //                                             getWhiteTextStyle(
//                     //                                                 fontWeight:
//                     //                                                     w700,
//                     //                                                 fontSize:
//                     //                                                     18)),
//                     //                                     // Jangan lupa tambahkan IDSite 33
//                     //                                     if (pl['tireAccessories'] !=
//                     //                                             null &&
//                     //                                         pl['tireAccessories']
//                     //                                             .isNotEmpty &&
//                     //                                         currentIdSite ==
//                     //                                             '33')
//                     //                                       Column(
//                     //                                         crossAxisAlignment:
//                     //                                             CrossAxisAlignment
//                     //                                                 .end,
//                     //                                         children: [
//                     //                                           Text(
//                     //                                               'Tire Accessories',
//                     //                                               style: getWhiteTextStyle(
//                     //                                                   fontWeight:
//                     //                                                       w700,
//                     //                                                   fontSize:
//                     //                                                       14)),
//                     //                                           const SizedBox(
//                     //                                             height: 6,
//                     //                                           ),
//                     //                                           Column(
//                     //                                             crossAxisAlignment:
//                     //                                                 CrossAxisAlignment
//                     //                                                     .end,
//                     //                                             children: pl[
//                     //                                                     'tireAccessories']
//                     //                                                 .map<Widget>(
//                     //                                                     (acc) {
//                     //                                               return Column(
//                     //                                                 crossAxisAlignment:
//                     //                                                     CrossAxisAlignment
//                     //                                                         .end,
//                     //                                                 children: [
//                     //                                                   Row(
//                     //                                                     children: [
//                     //                                                       Text(acc['name'] + ' (' + acc['condition'] + '${(acc['remark'] != '') ? ': ${acc['remark']}' : ''})',
//                     //                                                           textAlign: TextAlign.right,
//                     //                                                           style: getWhiteTextStyle(fontWeight: w500, fontSize: 14)),
//                     //                                                     ],
//                     //                                                   ),
//                     //                                                   const SizedBox(
//                     //                                                     height:
//                     //                                                         6,
//                     //                                                   ),
//                     //                                                   if (acc['image'].isNotEmpty &&
//                     //                                                       acc['image'] !=
//                     //                                                           'image.png' &&
//                     //                                                       acc['image'] !=
//                     //                                                           '')
//                     //                                                     InkWell(
//                     //                                                       onTap:
//                     //                                                           () async {
//                     //                                                         await showDialog(
//                     //                                                           context: context,
//                     //                                                           barrierDismissible: true,
//                     //                                                           builder: (_) {
//                     //                                                             return Dialog(
//                     //                                                               backgroundColor: Colors.transparent,
//                     //                                                               elevation: 0,
//                     //                                                               child: Center(
//                     //                                                                 child: Column(
//                     //                                                                   mainAxisSize: MainAxisSize.min,
//                     //                                                                   children: [
//                     //                                                                     // === GAMBAR + TOMBOL CLOSE ===
//                     //                                                                     Stack(
//                     //                                                                       children: [
//                     //                                                                         Container(
//                     //                                                                           width: MediaQuery.of(context).size.width * 0.6,
//                     //                                                                           height: MediaQuery.of(context).size.height * 0.6,
//                     //                                                                           decoration: BoxDecoration(
//                     //                                                                             borderRadius: BorderRadius.circular(12),
//                     //                                                                           ),
//                     //                                                                           clipBehavior: Clip.antiAlias,
//                     //                                                                           child: Image.network(
//                     //                                                                             acc['image'],
//                     //                                                                             fit: BoxFit.contain,
//                     //                                                                           ),
//                     //                                                                         ),
//                     //                                                                         Positioned(
//                     //                                                                           right: 8,
//                     //                                                                           top: 8,
//                     //                                                                           child: InkWell(
//                     //                                                                             onTap: () => Navigator.of(context).pop(),
//                     //                                                                             borderRadius: BorderRadius.circular(20),
//                     //                                                                             child: Container(
//                     //                                                                               padding: const EdgeInsets.all(6),
//                     //                                                                               decoration: BoxDecoration(
//                     //                                                                                 color: Colors.black45,
//                     //                                                                                 shape: BoxShape.circle,
//                     //                                                                               ),
//                     //                                                                               child: const Icon(
//                     //                                                                                 LucideIcons.x,
//                     //                                                                                 color: Colors.white,
//                     //                                                                                 size: 20,
//                     //                                                                               ),
//                     //                                                                             ),
//                     //                                                                           ),
//                     //                                                                         ),
//                     //                                                                       ],
//                     //                                                                     ),

//                     //                                                                     const SizedBox(height: 12),

//                     //                                                                     // === TEKS KETERANGAN ===
//                     //                                                                     Container(
//                     //                                                                       padding: const EdgeInsets.all(8),
//                     //                                                                       decoration: BoxDecoration(
//                     //                                                                         color: Colors.white,
//                     //                                                                         borderRadius: BorderRadius.circular(16),
//                     //                                                                       ),
//                     //                                                                       child: Text(
//                     //                                                                         '#${dailyMap['unit']} Pos. ${pl['pos']} | ${acc['name']} ${acc['condition']} ${(acc['remark'] != '') ? ': ${acc['remark']}' : ''}',
//                     //                                                                         style: getBlackTextStyle(
//                     //                                                                           fontWeight: w700,
//                     //                                                                         ),
//                     //                                                                         textAlign: TextAlign.center,
//                     //                                                                       ),
//                     //                                                                     ),
//                     //                                                                   ],
//                     //                                                                 ),
//                     //                                                               ),
//                     //                                                             );
//                     //                                                           },
//                     //                                                         );
//                     //                                                       },
//                     //                                                       child:
//                     //                                                           SizedBox(
//                     //                                                         width: 150,
//                     //                                                         height: 100,
//                     //                                                         child: Image.network(
//                     //                                                           acc['image'],
//                     //                                                           fit: BoxFit.cover,
//                     //                                                         ),
//                     //                                                       ),
//                     //                                                     )
//                     //                                                 ],
//                     //                                               );
//                     //                                             }).toList(),
//                     //                                           ),
//                     //                                         ],
//                     //                                       ),
//                     //                                     const SizedBox(
//                     //                                       height: 12,
//                     //                                     ),
//                     //                                   ],
//                     //                                 ),
//                     //                               ],
//                     //                             ),
//                     //                             Divider(
//                     //                               color: white,
//                     //                               thickness: 1.5,
//                     //                             ),
//                     //                           ],
//                     //                         );
//                     //                       }).toList(),
//                     //                     ),
//                     //                   ],
//                     //                 ),
//                     //               ));

//                     //           ;
//                     //         }),
//                     //   ],
//                     // );

//                     // Unit Low Pressure
//                     case 1:
//                       checkedFuture ??= getCheckedTodayFuture();

//                       if (homeState.userAccessCompanyId.value == '1' &&
//                           homeState.userAccessId.value == '1') {
//                         // ============================================================
//                         // USER COMPANY 1 + ACCESS ID 1
//                         // MENAMPILKAN UNIT YANG MEMILIKI PRESSURE 0 PSI
//                         // ============================================================

//                         bool isZeroPressure(dynamic pressureValue) {
//                           final rawValue = pressureValue
//                               ?.toString()
//                               .trim()
//                               .replaceAll(',', '.');

//                           // Nilai null atau kosong pada tampilan lama juga ditulis 0 Psi,
//                           // sehingga pada filter dianggap sebagai pressure 0 Psi.
//                           if (rawValue == null || rawValue.isEmpty) {
//                             return true;
//                           }

//                           final pressure = double.tryParse(rawValue);

//                           return pressure != null && pressure == 0;
//                         }

//                         return Column(
//                           children: [
//                             const SizedBox(height: 12),
//                             SelectPitButton(
//                               pit: pit,
//                               selectedPit: selectedPit,
//                               onSelectedPitChanged: (index) {
//                                 setState(() {
//                                   selectedPit = index;
//                                   checkedFuture = getCheckedTodayFuture();
//                                 });
//                               },
//                             ),
//                             const SizedBox(height: 12),
//                             SizedBox(
//                               width: double.infinity,
//                               child: ElevatedButton(
//                                 onPressed: refreshCheckedData,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blueGrey,
//                                 ),
//                                 child: Text(
//                                   'Refresh Data Incomplete Check',
//                                   style: getWhiteTextStyle(),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                               future: checkedFuture,
//                               builder: (context, snapshot) {
//                                 if (snapshot.connectionState ==
//                                     ConnectionState.waiting) {
//                                   return const Center(
//                                     child: CircularProgressIndicator.adaptive(),
//                                   );
//                                 }

//                                 if (snapshot.hasError) {
//                                   return Text(
//                                     'Error load data pressure 0 Psi: ${snapshot.error}',
//                                     style: getBlackTextStyle(fontSize: 14),
//                                   );
//                                 }

//                                 final docs = snapshot.data?.docs ?? [];

//                                 final allData = docs.map((doc) {
//                                   final data = doc.data();

//                                   return DailyPress.fromFirestore(data);
//                                 }).toList();

//                                 // Urutkan berdasarkan tanggal terbaru
//                                 allData.sort((a, b) {
//                                   return b.tanggal.compareTo(a.tanggal);
//                                 });

//                                 final keyword =
//                                     searchQuery.trim().toLowerCase();

//                                 // Ambil unit yang memiliki minimal satu posisi 0 Psi
//                                 final zeroPressureData = allData.where((data) {
//                                   if (keyword.isNotEmpty) {
//                                     final unit = data.unit.toLowerCase();

//                                     if (!unit.contains(keyword)) {
//                                       return false;
//                                     }
//                                   }

//                                   return data.posisi.any((position) {
//                                     return isZeroPressure(position.pressure);
//                                   });
//                                 }).toList();

//                                 if (zeroPressureData.isEmpty) {
//                                   return Text(
//                                     'Tidak ada data pressure 0 Psi!',
//                                     style: getBlackTextStyle(),
//                                   );
//                                 }

//                                 return Column(
//                                   children: [
//                                     Text(
//                                       'Total Unit : ${zeroPressureData.length}',
//                                       textAlign: TextAlign.center,
//                                       style: getBlackTextStyle(
//                                         fontSize: 20,
//                                         fontWeight: w700,
//                                       ),
//                                     ),
//                                     const SizedBox(height: 16),
//                                     ListView.builder(
//                                       itemCount: zeroPressureData.length,
//                                       shrinkWrap: true,
//                                       physics:
//                                           const NeverScrollableScrollPhysics(),
//                                       itemBuilder: (context, index) {
//                                         final data = zeroPressureData[index];

//                                         // Hanya mengambil posisi yang memiliki 0 Psi
//                                         final zeroPressurePositions =
//                                             data.posisi.where((position) {
//                                           return isZeroPressure(
//                                               position.pressure);
//                                         }).toList();

//                                         return Card(
//                                           elevation: 2,
//                                           shape: RoundedRectangleBorder(
//                                             borderRadius:
//                                                 BorderRadius.circular(12),
//                                           ),
//                                           child: Container(
//                                             width: double.infinity,
//                                             padding: const EdgeInsets.symmetric(
//                                               horizontal: 12,
//                                               vertical: 24,
//                                             ),
//                                             decoration: BoxDecoration(
//                                               color: Colors.red,
//                                               borderRadius:
//                                                   BorderRadius.circular(12),
//                                             ),
//                                             child: ExpansionTile(
//                                               tilePadding: EdgeInsets.zero,
//                                               childrenPadding: EdgeInsets.zero,
//                                               iconColor: white,
//                                               collapsedIconColor: white,
//                                               title: Row(
//                                                 children: [
//                                                   Icon(
//                                                     Icons.warning_amber_rounded,
//                                                     color: white,
//                                                     size: 36,
//                                                   ),
//                                                   const SizedBox(width: 12),
//                                                   Expanded(
//                                                     child: Column(
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .start,
//                                                       children: [
//                                                         Text(
//                                                           data.unit +
//                                                               '${data.pit != 'Default' ? '\n${data.pit}' : ''}',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontWeight: w700,
//                                                             fontSize: 18,
//                                                           ),
//                                                         ),
//                                                         Text(
//                                                           '${zeroPressurePositions.length} posisi terdeteksi',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontSize: 14,
//                                                           ),
//                                                         ),
//                                                       ],
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                               trailing: const SizedBox(
//                                                 width: 90,
//                                                 child: Icon(
//                                                   Icons.arrow_drop_down,
//                                                 ),
//                                               ),
//                                               children: [
//                                                 const SizedBox(height: 12),

//                                                 Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceBetween,
//                                                   children: [
//                                                     Text(
//                                                       'Name',
//                                                       style: getWhiteTextStyle(
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                     SizedBox(
//                                                       width: 250,
//                                                       child: Text(
//                                                         data.user.isEmpty
//                                                             ? 'No Name'
//                                                             : data.user,
//                                                         textAlign:
//                                                             TextAlign.end,
//                                                         style:
//                                                             getWhiteTextStyle(
//                                                           fontWeight: w700,
//                                                           fontSize: 18,
//                                                         ),
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),

//                                                 const SizedBox(height: 12),

//                                                 Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceBetween,
//                                                   children: [
//                                                     Text(
//                                                       'Tanggal',
//                                                       style: getWhiteTextStyle(
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                     Text(
//                                                       data.tanggal
//                                                           .split('T')[0],
//                                                       style: getWhiteTextStyle(
//                                                         fontWeight: w700,
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),

//                                                 const SizedBox(height: 12),

//                                                 Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceBetween,
//                                                   children: [
//                                                     Text(
//                                                       'Waktu',
//                                                       style: getWhiteTextStyle(
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                     Text(
//                                                       data.tanggal
//                                                           .split('T')[1]
//                                                           .substring(0, 5),
//                                                       style: getWhiteTextStyle(
//                                                         fontWeight: w700,
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),

//                                                 const SizedBox(height: 12),

//                                                 Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceBetween,
//                                                   children: [
//                                                     Text(
//                                                       'HM Unit',
//                                                       style: getWhiteTextStyle(
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                     Text(
//                                                       data.hm,
//                                                       style: getWhiteTextStyle(
//                                                         fontWeight: w700,
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),

//                                                 const SizedBox(height: 12),

//                                                 Row(
//                                                   mainAxisAlignment:
//                                                       MainAxisAlignment
//                                                           .spaceBetween,
//                                                   children: [
//                                                     Text(
//                                                       'Pit',
//                                                       style: getWhiteTextStyle(
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                     Text(
//                                                       data.pit,
//                                                       style: getWhiteTextStyle(
//                                                         fontWeight: w700,
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),

//                                                 const SizedBox(height: 12),

//                                                 // Hanya menampilkan posisi pressure 0 Psi
//                                                 ListView.builder(
//                                                   itemCount:
//                                                       zeroPressurePositions
//                                                           .length,
//                                                   shrinkWrap: true,
//                                                   physics:
//                                                       const NeverScrollableScrollPhysics(),
//                                                   itemBuilder:
//                                                       (context, posIndex) {
//                                                     final pl =
//                                                         zeroPressurePositions[
//                                                             posIndex];

//                                                     List<dynamic> luka = [];

//                                                     if (pl.luka != null &&
//                                                         pl.luka is! String) {
//                                                       luka = pl.luka
//                                                           as List<dynamic>;
//                                                     }

//                                                     return Column(
//                                                       children: [
//                                                         Row(
//                                                           mainAxisAlignment:
//                                                               MainAxisAlignment
//                                                                   .spaceBetween,
//                                                           crossAxisAlignment:
//                                                               CrossAxisAlignment
//                                                                   .start,
//                                                           children: [
//                                                             Row(
//                                                               children: [
//                                                                 Icon(
//                                                                   Icons
//                                                                       .error_outline,
//                                                                   color: white,
//                                                                   size: 24,
//                                                                 ),
//                                                                 const SizedBox(
//                                                                     width: 8),
//                                                                 Text(
//                                                                   'Pos. ${pl.pos}',
//                                                                   style:
//                                                                       getWhiteTextStyle(
//                                                                     fontWeight:
//                                                                         w700,
//                                                                     fontSize:
//                                                                         18,
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                             Column(
//                                                               crossAxisAlignment:
//                                                                   CrossAxisAlignment
//                                                                       .end,
//                                                               children: [
//                                                                 Text(
//                                                                   '0 Psi',
//                                                                   style:
//                                                                       getWhiteTextStyle(
//                                                                     fontWeight:
//                                                                         w700,
//                                                                     fontSize:
//                                                                         22,
//                                                                   ),
//                                                                 ),
//                                                                 Text(
//                                                                   'Pressure belum diinput',
//                                                                   textAlign:
//                                                                       TextAlign
//                                                                           .end,
//                                                                   style:
//                                                                       getWhiteTextStyle(
//                                                                     fontWeight:
//                                                                         w700,
//                                                                     fontSize:
//                                                                         14,
//                                                                   ),
//                                                                 ),
//                                                                 if (pl.size !=
//                                                                         null &&
//                                                                     pl.size!
//                                                                         .isNotEmpty)
//                                                                   Text(
//                                                                     'Size: ${pl.size}',
//                                                                     textAlign:
//                                                                         TextAlign
//                                                                             .end,
//                                                                     style:
//                                                                         getWhiteTextStyle(
//                                                                       fontSize:
//                                                                           14,
//                                                                     ),
//                                                                   ),
//                                                                 if (pl.adjusmentPressure !=
//                                                                         null &&
//                                                                     pl.adjusmentPressure !=
//                                                                         '0' &&
//                                                                     pl.adjusmentPressure !=
//                                                                         '')
//                                                                   Text(
//                                                                     '${pl.adjusmentPressure} Psi '
//                                                                     '(Adj. Pressure)',
//                                                                     textAlign:
//                                                                         TextAlign
//                                                                             .end,
//                                                                     style:
//                                                                         getWhiteTextStyle(
//                                                                       fontWeight:
//                                                                           w700,
//                                                                       fontSize:
//                                                                           16,
//                                                                     ),
//                                                                   ),
//                                                                 if (luka
//                                                                     .isNotEmpty)
//                                                                   SizedBox(
//                                                                     width: 200,
//                                                                     child: Text(
//                                                                       luka.join(
//                                                                           '\n'),
//                                                                       textAlign:
//                                                                           TextAlign
//                                                                               .end,
//                                                                       style:
//                                                                           getWhiteTextStyle(
//                                                                         fontWeight:
//                                                                             w700,
//                                                                         fontSize:
//                                                                             16,
//                                                                       ),
//                                                                     ),
//                                                                   ),
//                                                                 if (pl.rating !=
//                                                                         null &&
//                                                                     pl.rating!
//                                                                         .isNotEmpty)
//                                                                   Text(
//                                                                     'Rating ${pl.rating}',
//                                                                     textAlign:
//                                                                         TextAlign
//                                                                             .end,
//                                                                     style:
//                                                                         getWhiteTextStyle(
//                                                                       fontWeight:
//                                                                           w700,
//                                                                       fontSize:
//                                                                           16,
//                                                                     ),
//                                                                   ),
//                                                                 Container(
//                                                                   width: 120,
//                                                                   height: 60,
//                                                                   margin:
//                                                                       const EdgeInsets
//                                                                           .only(
//                                                                     top: 12,
//                                                                     bottom: 12,
//                                                                   ),
//                                                                   child:
//                                                                       ButtonWidget(
//                                                                     name: Text(
//                                                                       'Edit',
//                                                                       textAlign:
//                                                                           TextAlign
//                                                                               .center,
//                                                                       style:
//                                                                           getWhiteTextStyle(),
//                                                                     ),
//                                                                     color:
//                                                                         green00968A,
//                                                                     function:
//                                                                         () {
//                                                                       final List<
//                                                                               Position>
//                                                                           position =
//                                                                           [];

//                                                                       for (int i =
//                                                                               0;
//                                                                           i < data.posisi.length;
//                                                                           i++) {
//                                                                         final p =
//                                                                             data.posisi[i];

//                                                                         position
//                                                                             .add(
//                                                                           Position(
//                                                                             pos:
//                                                                                 p.pos,
//                                                                             pressure:
//                                                                                 p.pressure,
//                                                                             temperatureStatus:
//                                                                                 p.temperatureStatus,
//                                                                             rating:
//                                                                                 p.rating,
//                                                                             adjusmentPressure:
//                                                                                 p.adjusmentPressure,
//                                                                             adjustmentTemperatureStatus:
//                                                                                 p.adjustmentTemperatureStatus,
//                                                                             luka:
//                                                                                 p.luka,
//                                                                             image:
//                                                                                 p.image,
//                                                                             size:
//                                                                                 p.size,
//                                                                             idInventory:
//                                                                                 p.idInventory,
//                                                                             idUnit:
//                                                                                 p.idUnit,
//                                                                             idDaily:
//                                                                                 p.idDaily,
//                                                                             kondisi:
//                                                                                 p.kondisi,
//                                                                           ),
//                                                                         );
//                                                                       }

//                                                                       final dataUnit =
//                                                                           {
//                                                                         'unitNumber':
//                                                                             data.unit,
//                                                                         'hm': data
//                                                                             .hm,
//                                                                         'pit': data
//                                                                             .pit,
//                                                                         'position':
//                                                                             position,
//                                                                         'reccPress':
//                                                                             state.reccPress,
//                                                                       };

//                                                                       Navigator
//                                                                           .pushNamed(
//                                                                         context,
//                                                                         DailyCheckFormPage
//                                                                             .routeName,
//                                                                         arguments:
//                                                                             dataUnit,
//                                                                       );
//                                                                     },
//                                                                   ),
//                                                                 ),
//                                                               ],
//                                                             ),
//                                                           ],
//                                                         ),
//                                                         Divider(
//                                                           color: white,
//                                                           thickness: 1.5,
//                                                         ),
//                                                       ],
//                                                     );
//                                                   },
//                                                 ),
//                                               ],
//                                             ),
//                                           ),
//                                         );
//                                       },
//                                     ),
//                                   ],
//                                 );
//                               },
//                             ),
//                           ],
//                         );
//                       } else {
//                         // ============================================================
//                         // USER LAIN
//                         // TETAP MENGGUNAKAN LOGIKA LOW PRESSURE LAMA
//                         // ============================================================

//                         final reccPressMap = <String, int>{};

//                         for (final item in state.reccPress) {
//                           item.forEach((key, value) {
//                             reccPressMap[key.toString()] =
//                                 int.tryParse(value.toString()) ?? 0;
//                           });
//                         }

//                         return Column(
//                           children: [
//                             const SizedBox(height: 12),
//                             SelectPitButton(
//                               pit: pit,
//                               selectedPit: selectedPit,
//                               onSelectedPitChanged: (index) {
//                                 setState(() {
//                                   selectedPit = index;
//                                   checkedFuture = getCheckedTodayFuture();
//                                 });
//                               },
//                             ),
//                             const SizedBox(height: 12),
//                             if (homeState.selectedSite?.idCompany == '2')
//                               Text(
//                                 'Target Low Pressure : ${(state.countAllTire * 0.01).ceil()} Tire',
//                                 style: getBlackTextStyle(fontSize: 14),
//                               )
//                             else
//                               Container(),
//                             const SizedBox(height: 12),
//                             SizedBox(
//                               width: double.infinity,
//                               child: ElevatedButton(
//                                 onPressed: refreshCheckedData,
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: Colors.blueGrey,
//                                 ),
//                                 child: Text(
//                                   'Refresh Low Pressure Data',
//                                   style: getWhiteTextStyle(),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(height: 12),
//                             FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                               future: checkedFuture,
//                               builder: (context, snapshot) {
//                                 if (snapshot.connectionState ==
//                                     ConnectionState.waiting) {
//                                   return const Center(
//                                     child: CircularProgressIndicator.adaptive(),
//                                   );
//                                 }

//                                 if (snapshot.hasError) {
//                                   return Text(
//                                     'Error load low pressure data: ${snapshot.error}',
//                                     style: getBlackTextStyle(fontSize: 14),
//                                   );
//                                 }

//                                 final docs = snapshot.data?.docs ?? [];

//                                 final allData = docs.map((doc) {
//                                   final data = doc.data();

//                                   return DailyPress.fromFirestore(data);
//                                 }).toList();

//                                 allData.sort((a, b) {
//                                   return b.tanggal.compareTo(a.tanggal);
//                                 });

//                                 final keyword = searchQuery.toLowerCase();

//                                 final lowPressureData = allData.where((data) {
//                                   if (keyword.isNotEmpty) {
//                                     final unit = data.unit.toLowerCase();

//                                     if (!unit.contains(keyword)) {
//                                       return false;
//                                     }
//                                   }

//                                   return data.posisi.any((position) {
//                                     final tireSize = position.size;

//                                     if (tireSize == null || tireSize.isEmpty) {
//                                       return false;
//                                     }

//                                     final pressure = int.tryParse(
//                                             position.pressure ?? '0') ??
//                                         0;

//                                     if (pressure == 0) {
//                                       return false;
//                                     }

//                                     final adjustedPressure =
//                                         position.adjusmentPressure;

//                                     if (adjustedPressure.isNotEmpty &&
//                                         adjustedPressure != '0') {
//                                       return false;
//                                     }

//                                     final recommendedPressure =
//                                         reccPressMap[tireSize] ?? 0;

//                                     if (recommendedPressure == 0) {
//                                       return false;
//                                     }

//                                     return pressure < recommendedPressure;
//                                   });
//                                 }).toList();

//                                 if (lowPressureData.isEmpty) {
//                                   return Text(
//                                     'There is no low pressure data!',
//                                     style: getBlackTextStyle(),
//                                   );
//                                 }

//                                 return ListView.builder(
//                                   itemCount: lowPressureData.length,
//                                   shrinkWrap: true,
//                                   physics: const NeverScrollableScrollPhysics(),
//                                   itemBuilder: (context, index) {
//                                     final data = lowPressureData[index];

//                                     return Card(
//                                       elevation: 2,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(12),
//                                       ),
//                                       child: Container(
//                                         width: double.infinity,
//                                         padding: const EdgeInsets.symmetric(
//                                           horizontal: 12,
//                                           vertical: 24,
//                                         ),
//                                         decoration: BoxDecoration(
//                                           color: Colors.red,
//                                           borderRadius:
//                                               BorderRadius.circular(12),
//                                         ),
//                                         child: ExpansionTile(
//                                           tilePadding: EdgeInsets.zero,
//                                           childrenPadding: EdgeInsets.zero,
//                                           title: Row(
//                                             children: [
//                                               Icon(
//                                                 Icons.task,
//                                                 color: white,
//                                                 size: 36,
//                                               ),
//                                               const SizedBox(width: 12),
//                                               Expanded(
//                                                 child: Column(
//                                                   crossAxisAlignment:
//                                                       CrossAxisAlignment.start,
//                                                   children: [
//                                                     Text(
//                                                       data.unit +
//                                                           '${data.pit != 'Default' ? '\n${data.pit}' : ''}',
//                                                       style: getWhiteTextStyle(
//                                                         fontWeight: w700,
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                     Text(
//                                                       'LOW PRESSURE!',
//                                                       style: getWhiteTextStyle(
//                                                         fontWeight: w700,
//                                                         fontSize: 18,
//                                                       ),
//                                                     ),
//                                                   ],
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           trailing: const SizedBox(
//                                             width: 90,
//                                             child: Icon(
//                                               Icons.arrow_drop_down,
//                                             ),
//                                           ),
//                                           children: [
//                                             const SizedBox(height: 12),
//                                             Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment
//                                                       .spaceBetween,
//                                               children: [
//                                                 Text(
//                                                   'Name',
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                                 SizedBox(
//                                                   width: 250,
//                                                   child: Text(
//                                                     data.user == ''
//                                                         ? 'No Name'
//                                                         : data.user,
//                                                     textAlign: TextAlign.end,
//                                                     style: getWhiteTextStyle(
//                                                       fontWeight: w700,
//                                                       fontSize: 18,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             const SizedBox(height: 12),
//                                             Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment
//                                                       .spaceBetween,
//                                               children: [
//                                                 Text(
//                                                   'Tanggal',
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                                 Text(
//                                                   data.tanggal.split('T')[0],
//                                                   style: getWhiteTextStyle(
//                                                     fontWeight: w700,
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             const SizedBox(height: 12),
//                                             Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment
//                                                       .spaceBetween,
//                                               children: [
//                                                 Text(
//                                                   'Waktu',
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                                 Text(
//                                                   data.tanggal
//                                                       .split('T')[1]
//                                                       .substring(0, 5),
//                                                   style: getWhiteTextStyle(
//                                                     fontWeight: w700,
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             const SizedBox(height: 12),
//                                             Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment
//                                                       .spaceBetween,
//                                               children: [
//                                                 Text(
//                                                   'HM Unit',
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                                 Text(
//                                                   data.hm,
//                                                   style: getWhiteTextStyle(
//                                                     fontWeight: w700,
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             const SizedBox(height: 12),
//                                             Row(
//                                               mainAxisAlignment:
//                                                   MainAxisAlignment
//                                                       .spaceBetween,
//                                               children: [
//                                                 Text(
//                                                   'Pit',
//                                                   style: getWhiteTextStyle(
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                                 Text(
//                                                   data.pit,
//                                                   style: getWhiteTextStyle(
//                                                     fontWeight: w700,
//                                                     fontSize: 18,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                             const SizedBox(height: 12),
//                                             ListView.builder(
//                                               itemCount: data.posisi.length,
//                                               shrinkWrap: true,
//                                               physics:
//                                                   const NeverScrollableScrollPhysics(),
//                                               itemBuilder: (context, posIndex) {
//                                                 final pl =
//                                                     data.posisi[posIndex];

//                                                 List<dynamic> luka = [];

//                                                 if (pl.luka != null &&
//                                                     pl.luka is! String) {
//                                                   luka =
//                                                       pl.luka as List<dynamic>;
//                                                 }

//                                                 final tireSize = pl.size;

//                                                 final pressure = int.tryParse(
//                                                         pl.pressure ?? '0') ??
//                                                     0;

//                                                 final recommendedPressure =
//                                                     reccPressMap[tireSize] ?? 0;

//                                                 final adjustedPressure =
//                                                     pl.adjusmentPressure;

//                                                 final isThisPositionLow =
//                                                     tireSize != null &&
//                                                         tireSize.isNotEmpty &&
//                                                         pressure > 0 &&
//                                                         recommendedPressure >
//                                                             0 &&
//                                                         pressure <
//                                                             recommendedPressure &&
//                                                         (adjustedPressure
//                                                                 .isEmpty ||
//                                                             adjustedPressure ==
//                                                                 '0');

//                                                 return Column(
//                                                   children: [
//                                                     Row(
//                                                       mainAxisAlignment:
//                                                           MainAxisAlignment
//                                                               .spaceBetween,
//                                                       crossAxisAlignment:
//                                                           CrossAxisAlignment
//                                                               .center,
//                                                       children: [
//                                                         Text(
//                                                           'Pos. ${pl.pos}',
//                                                           style:
//                                                               getWhiteTextStyle(
//                                                             fontSize: 18,
//                                                           ),
//                                                         ),
//                                                         Column(
//                                                           crossAxisAlignment:
//                                                               CrossAxisAlignment
//                                                                   .end,
//                                                           children: [
//                                                             Text(
//                                                               '${pl.pressure == '' || pl.pressure == null ? 0 : pl.pressure} Psi',
//                                                               style:
//                                                                   getWhiteTextStyle(
//                                                                 fontWeight:
//                                                                     w700,
//                                                                 fontSize: 18,
//                                                               ),
//                                                             ),
//                                                             if (isThisPositionLow)
//                                                               Text(
//                                                                 'Recc: $recommendedPressure Psi',
//                                                                 style:
//                                                                     getWhiteTextStyle(
//                                                                   fontWeight:
//                                                                       w700,
//                                                                   fontSize: 14,
//                                                                 ),
//                                                               ),
//                                                             if (isThisPositionLow)
//                                                               Container(
//                                                                 width: 120,
//                                                                 height: 60,
//                                                                 margin:
//                                                                     const EdgeInsets
//                                                                         .only(
//                                                                   top: 12,
//                                                                   bottom: 12,
//                                                                 ),
//                                                                 child:
//                                                                     ButtonWidget(
//                                                                   name: Text(
//                                                                     'Adjust',
//                                                                     style:
//                                                                         getWhiteTextStyle(),
//                                                                   ),
//                                                                   color:
//                                                                       green00968A,
//                                                                   function: () {
//                                                                     final List<
//                                                                             Position>
//                                                                         position =
//                                                                         [];

//                                                                     for (int i =
//                                                                             0;
//                                                                         i < data.posisi.length;
//                                                                         i++) {
//                                                                       final p =
//                                                                           data.posisi[
//                                                                               i];

//                                                                       position
//                                                                           .add(
//                                                                         Position(
//                                                                           pos: p
//                                                                               .pos,
//                                                                           pressure:
//                                                                               p.pressure,
//                                                                           temperatureStatus:
//                                                                               p.temperatureStatus,
//                                                                           rating:
//                                                                               p.rating,
//                                                                           adjusmentPressure:
//                                                                               p.adjusmentPressure,
//                                                                           adjustmentTemperatureStatus:
//                                                                               p.adjustmentTemperatureStatus,
//                                                                           luka:
//                                                                               p.luka,
//                                                                           image:
//                                                                               p.image,
//                                                                           size:
//                                                                               p.size,
//                                                                           idInventory:
//                                                                               p.idInventory,
//                                                                           idUnit:
//                                                                               p.idUnit,
//                                                                           idDaily:
//                                                                               p.idDaily,
//                                                                           kondisi:
//                                                                               p.kondisi,
//                                                                         ),
//                                                                       );
//                                                                     }

//                                                                     final dataUnit =
//                                                                         {
//                                                                       'unitNumber':
//                                                                           data.unit,
//                                                                       'hm': data
//                                                                           .hm,
//                                                                       'pit': data
//                                                                           .pit,
//                                                                       'position':
//                                                                           position,
//                                                                       'reccPress':
//                                                                           state
//                                                                               .reccPress,
//                                                                     };

//                                                                     Navigator
//                                                                         .pushNamed(
//                                                                       context,
//                                                                       DailyCheckFormPage
//                                                                           .routeName,
//                                                                       arguments:
//                                                                           dataUnit,
//                                                                     );
//                                                                   },
//                                                                 ),
//                                                               ),
//                                                             if (pl.adjusmentPressure !=
//                                                                     null &&
//                                                                 pl.adjusmentPressure !=
//                                                                     '0' &&
//                                                                 pl.adjusmentPressure !=
//                                                                     '')
//                                                               Text(
//                                                                 '${pl.adjusmentPressure} Psi (Adj. Pressure)',
//                                                                 style:
//                                                                     getWhiteTextStyle(
//                                                                   fontWeight:
//                                                                       w700,
//                                                                   fontSize: 18,
//                                                                 ),
//                                                               ),
//                                                             if (luka.isNotEmpty)
//                                                               SizedBox(
//                                                                 width: 200,
//                                                                 child: Text(
//                                                                   luka.join(
//                                                                       '\n'),
//                                                                   textAlign:
//                                                                       TextAlign
//                                                                           .end,
//                                                                   style:
//                                                                       getWhiteTextStyle(
//                                                                     fontWeight:
//                                                                         w700,
//                                                                     fontSize:
//                                                                         18,
//                                                                   ),
//                                                                 ),
//                                                               ),
//                                                             Text(
//                                                               '${pl.rating == '' || pl.rating == null ? '' : 'Rating ${pl.rating}'}',
//                                                               style:
//                                                                   getWhiteTextStyle(
//                                                                 fontWeight:
//                                                                     w700,
//                                                                 fontSize: 18,
//                                                               ),
//                                                             ),
//                                                             const SizedBox(
//                                                                 height: 12),
//                                                           ],
//                                                         ),
//                                                       ],
//                                                     ),
//                                                     Divider(
//                                                       color: white,
//                                                       thickness: 1.5,
//                                                     ),
//                                                   ],
//                                                 );
//                                               },
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 );
//                               },
//                             ),
//                           ],
//                         );
//                       }
//                     // case 1:
//                     // checkedFuture ??= getCheckedTodayFuture();

//                     // final reccPressMap = <String, int>{};

//                     // for (final item in state.reccPress) {
//                     //   item.forEach((key, value) {
//                     //     reccPressMap[key.toString()] =
//                     //         int.tryParse(value.toString()) ?? 0;
//                     //   });
//                     // }

//                     // return Column(
//                     //   children: [
//                     //     const SizedBox(height: 12),
//                     //     SelectPitButton(
//                     //       pit: pit,
//                     //       selectedPit: selectedPit,
//                     //       onSelectedPitChanged: (index) {
//                     //         setState(() {
//                     //           selectedPit = index;
//                     //           checkedFuture = getCheckedTodayFuture();
//                     //         });
//                     //       },
//                     //     ),
//                     //     const SizedBox(height: 12),
//                     //     if (homeState.selectedSite?.idCompany == '2')
//                     //       Text(
//                     //         'Target Low Pressure : ${(state.countAllTire * 0.01).ceil()} Tire',
//                     //         style: getBlackTextStyle(fontSize: 14),
//                     //       )
//                     //     else
//                     //       Container(),
//                     //     const SizedBox(height: 12),
//                     //     SizedBox(
//                     //       width: double.infinity,
//                     //       child: ElevatedButton(
//                     //         onPressed: refreshCheckedData,
//                     //         style: ElevatedButton.styleFrom(
//                     //           backgroundColor: Colors.blueGrey,
//                     //         ),
//                     //         child: Text(
//                     //           'Refresh Low Pressure Data',
//                     //           style: getWhiteTextStyle(),
//                     //         ),
//                     //       ),
//                     //     ),
//                     //     const SizedBox(height: 12),
//                     //     FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                     //       future: checkedFuture,
//                     //       builder: (context, snapshot) {
//                     //         if (snapshot.connectionState ==
//                     //             ConnectionState.waiting) {
//                     //           return const Center(
//                     //             child: CircularProgressIndicator.adaptive(),
//                     //           );
//                     //         }

//                     //         if (snapshot.hasError) {
//                     //           return Text(
//                     //             'Error load low pressure data: ${snapshot.error}',
//                     //             style: getBlackTextStyle(fontSize: 14),
//                     //           );
//                     //         }

//                     //         final docs = snapshot.data?.docs ?? [];

//                     //         final allData = docs.map((doc) {
//                     //           final data = doc.data();
//                     //           return DailyPress.fromFirestore(data);
//                     //         }).toList();

//                     //         allData.sort((a, b) {
//                     //           return b.tanggal.compareTo(a.tanggal);
//                     //         });

//                     //         final keyword = searchQuery.toLowerCase();

//                     //         final lowPressureData = allData.where((data) {
//                     //           if (keyword.isNotEmpty) {
//                     //             final unit = data.unit.toLowerCase();

//                     //             if (!unit.contains(keyword)) {
//                     //               return false;
//                     //             }
//                     //           }

//                     //           return data.posisi.any((position) {
//                     //             final tireSize = position.size;

//                     //             if (tireSize == null || tireSize.isEmpty) {
//                     //               return false;
//                     //             }

//                     //             final pressure =
//                     //                 int.tryParse(position.pressure ?? '0') ??
//                     //                     0;

//                     //             if (pressure == 0) {
//                     //               return false;
//                     //             }

//                     //             final adjustedPressure =
//                     //                 position.adjusmentPressure;

//                     //             if (adjustedPressure.isNotEmpty &&
//                     //                 adjustedPressure != '0') {
//                     //               return false;
//                     //             }

//                     //             final recommendedPressure =
//                     //                 reccPressMap[tireSize] ?? 0;

//                     //             if (recommendedPressure == 0) {
//                     //               return false;
//                     //             }

//                     //             return pressure < recommendedPressure;
//                     //           });
//                     //         }).toList();

//                     //         if (lowPressureData.isEmpty) {
//                     //           return Text(
//                     //             'There is no low pressure data!',
//                     //             style: getBlackTextStyle(),
//                     //           );
//                     //         }

//                     //         return ListView.builder(
//                     //           itemCount: lowPressureData.length,
//                     //           shrinkWrap: true,
//                     //           physics: const NeverScrollableScrollPhysics(),
//                     //           itemBuilder: (context, index) {
//                     //             final data = lowPressureData[index];

//                     //             return Card(
//                     //               elevation: 2,
//                     //               shape: RoundedRectangleBorder(
//                     //                 borderRadius: BorderRadius.circular(12),
//                     //               ),
//                     //               child: Container(
//                     //                 width: double.infinity,
//                     //                 padding: const EdgeInsets.symmetric(
//                     //                   horizontal: 12,
//                     //                   vertical: 24,
//                     //                 ),
//                     //                 decoration: BoxDecoration(
//                     //                   color: Colors.red,
//                     //                   borderRadius: BorderRadius.circular(12),
//                     //                 ),
//                     //                 child: ExpansionTile(
//                     //                   tilePadding: EdgeInsets.zero,
//                     //                   childrenPadding: EdgeInsets.zero,
//                     //                   title: Row(
//                     //                     children: [
//                     //                       Icon(
//                     //                         Icons.task,
//                     //                         color: white,
//                     //                         size: 36,
//                     //                       ),
//                     //                       const SizedBox(width: 12),
//                     //                       Expanded(
//                     //                         child: Column(
//                     //                           crossAxisAlignment:
//                     //                               CrossAxisAlignment.start,
//                     //                           children: [
//                     //                             Text(
//                     //                               data.unit +
//                     //                                   '${((data.pit != 'Default') ? '\n${data.pit}' : '')}',
//                     //                               style: getWhiteTextStyle(
//                     //                                 fontWeight: w700,
//                     //                                 fontSize: 18,
//                     //                               ),
//                     //                             ),
//                     //                             Text(
//                     //                               'LOW PRESSURE!',
//                     //                               style: getWhiteTextStyle(
//                     //                                 fontWeight: w700,
//                     //                                 fontSize: 18,
//                     //                               ),
//                     //                             ),
//                     //                           ],
//                     //                         ),
//                     //                       ),
//                     //                     ],
//                     //                   ),
//                     //                   trailing: const SizedBox(
//                     //                     width: 90,
//                     //                     child: Icon(Icons.arrow_drop_down),
//                     //                   ),
//                     //                   children: [
//                     //                     const SizedBox(height: 12),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           'Name',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         SizedBox(
//                     //                           width: 250,
//                     //                           child: Text(
//                     //                             data.user == ''
//                     //                                 ? 'No Name'
//                     //                                 : data.user,
//                     //                             textAlign: TextAlign.end,
//                     //                             style: getWhiteTextStyle(
//                     //                               fontWeight: w700,
//                     //                               fontSize: 18,
//                     //                             ),
//                     //                           ),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(height: 12),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           'Tanggal',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         Text(
//                     //                           data.tanggal.split('T')[0],
//                     //                           style: getWhiteTextStyle(
//                     //                             fontWeight: w700,
//                     //                             fontSize: 18,
//                     //                           ),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(height: 12),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           'Waktu',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         Text(
//                     //                           data.tanggal
//                     //                               .split('T')[1]
//                     //                               .substring(0, 5),
//                     //                           style: getWhiteTextStyle(
//                     //                             fontWeight: w700,
//                     //                             fontSize: 18,
//                     //                           ),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(height: 12),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           'HM Unit',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         Text(
//                     //                           data.hm,
//                     //                           style: getWhiteTextStyle(
//                     //                             fontWeight: w700,
//                     //                             fontSize: 18,
//                     //                           ),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(height: 12),
//                     //                     Row(
//                     //                       mainAxisAlignment:
//                     //                           MainAxisAlignment.spaceBetween,
//                     //                       children: [
//                     //                         Text(
//                     //                           'Pit',
//                     //                           style: getWhiteTextStyle(
//                     //                               fontSize: 18),
//                     //                         ),
//                     //                         Text(
//                     //                           data.pit,
//                     //                           style: getWhiteTextStyle(
//                     //                             fontWeight: w700,
//                     //                             fontSize: 18,
//                     //                           ),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     const SizedBox(height: 12),
//                     //                     ListView.builder(
//                     //                       itemCount: data.posisi.length,
//                     //                       shrinkWrap: true,
//                     //                       physics:
//                     //                           const NeverScrollableScrollPhysics(),
//                     //                       itemBuilder: (context, posIndex) {
//                     //                         final pl = data.posisi[posIndex];

//                     //                         List<dynamic> luka = [];

//                     //                         if (pl.luka != null &&
//                     //                             pl.luka is! String) {
//                     //                           luka = pl.luka as List<dynamic>;
//                     //                         }

//                     //                         final tireSize = pl.size;
//                     //                         final pressure = int.tryParse(
//                     //                                 pl.pressure ?? '0') ??
//                     //                             0;
//                     //                         final recommendedPressure =
//                     //                             reccPressMap[tireSize] ?? 0;

//                     //                         final adjustedPressure =
//                     //                             pl.adjusmentPressure;

//                     //                         final isThisPositionLow =
//                     //                             tireSize != null &&
//                     //                                 tireSize.isNotEmpty &&
//                     //                                 pressure > 0 &&
//                     //                                 recommendedPressure > 0 &&
//                     //                                 pressure <
//                     //                                     recommendedPressure &&
//                     //                                 (adjustedPressure
//                     //                                         .isEmpty ||
//                     //                                     adjustedPressure ==
//                     //                                         '0');

//                     //                         return Column(
//                     //                           children: [
//                     //                             Row(
//                     //                               mainAxisAlignment:
//                     //                                   MainAxisAlignment
//                     //                                       .spaceBetween,
//                     //                               crossAxisAlignment:
//                     //                                   CrossAxisAlignment
//                     //                                       .center,
//                     //                               children: [
//                     //                                 Text(
//                     //                                   'Pos. ${pl.pos}',
//                     //                                   style:
//                     //                                       getWhiteTextStyle(
//                     //                                           fontSize: 18),
//                     //                                 ),
//                     //                                 Column(
//                     //                                   crossAxisAlignment:
//                     //                                       CrossAxisAlignment
//                     //                                           .end,
//                     //                                   children: [
//                     //                                     Text(
//                     //                                       '${(pl.pressure == '' || pl.pressure == null) ? 0 : pl.pressure} Psi',
//                     //                                       style:
//                     //                                           getWhiteTextStyle(
//                     //                                         fontWeight: w700,
//                     //                                         fontSize: 18,
//                     //                                       ),
//                     //                                     ),
//                     //                                     if (isThisPositionLow)
//                     //                                       Text(
//                     //                                         'Recc: $recommendedPressure Psi',
//                     //                                         style:
//                     //                                             getWhiteTextStyle(
//                     //                                           fontWeight:
//                     //                                               w700,
//                     //                                           fontSize: 14,
//                     //                                         ),
//                     //                                       ),
//                     //                                     if (isThisPositionLow)
//                     //                                       Container(
//                     //                                         width: 120,
//                     //                                         height: 60,
//                     //                                         margin:
//                     //                                             const EdgeInsets
//                     //                                                 .only(
//                     //                                           top: 12,
//                     //                                           bottom: 12,
//                     //                                         ),
//                     //                                         child:
//                     //                                             ButtonWidget(
//                     //                                           name: Text(
//                     //                                             'Adjust',
//                     //                                             style:
//                     //                                                 getWhiteTextStyle(),
//                     //                                           ),
//                     //                                           color:
//                     //                                               green00968A,
//                     //                                           function: () {
//                     //                                             List<Position>
//                     //                                                 position =
//                     //                                                 [];

//                     //                                             for (int i =
//                     //                                                     0;
//                     //                                                 i <
//                     //                                                     data.posisi
//                     //                                                         .length;
//                     //                                                 i++) {
//                     //                                               final p =
//                     //                                                   data.posisi[
//                     //                                                       i];

//                     //                                               position
//                     //                                                   .add(
//                     //                                                 Position(
//                     //                                                   pos: p
//                     //                                                       .pos,
//                     //                                                   pressure:
//                     //                                                       p.pressure,
//                     //                                                   temperatureStatus:
//                     //                                                       p.temperatureStatus,
//                     //                                                   rating:
//                     //                                                       p.rating,
//                     //                                                   adjusmentPressure:
//                     //                                                       p.adjusmentPressure,
//                     //                                                   adjustmentTemperatureStatus:
//                     //                                                       p.adjustmentTemperatureStatus,
//                     //                                                   luka: p
//                     //                                                       .luka,
//                     //                                                   image: p
//                     //                                                       .image,
//                     //                                                   size: p
//                     //                                                       .size,
//                     //                                                   idInventory:
//                     //                                                       p.idInventory,
//                     //                                                   idUnit:
//                     //                                                       p.idUnit,
//                     //                                                   idDaily:
//                     //                                                       p.idDaily,
//                     //                                                   kondisi:
//                     //                                                       p.kondisi,
//                     //                                                 ),
//                     //                                               );
//                     //                                             }

//                     //                                             final dataUnit =
//                     //                                                 {
//                     //                                               'unitNumber':
//                     //                                                   data.unit,
//                     //                                               'hm':
//                     //                                                   data.hm,
//                     //                                               'pit': data
//                     //                                                   .pit,
//                     //                                               'position':
//                     //                                                   position,
//                     //                                               'reccPress':
//                     //                                                   state
//                     //                                                       .reccPress,
//                     //                                             };

//                     //                                             Navigator
//                     //                                                 .pushNamed(
//                     //                                               context,
//                     //                                               DailyCheckFormPage
//                     //                                                   .routeName,
//                     //                                               arguments:
//                     //                                                   dataUnit,
//                     //                                             );
//                     //                                           },
//                     //                                         ),
//                     //                                       ),
//                     //                                     if (pl.adjusmentPressure !=
//                     //                                             null &&
//                     //                                         pl.adjusmentPressure !=
//                     //                                             '0' &&
//                     //                                         pl.adjusmentPressure !=
//                     //                                             '')
//                     //                                       Text(
//                     //                                         '${pl.adjusmentPressure} Psi (Adj. Pressure)',
//                     //                                         style:
//                     //                                             getWhiteTextStyle(
//                     //                                           fontWeight:
//                     //                                               w700,
//                     //                                           fontSize: 18,
//                     //                                         ),
//                     //                                       ),
//                     //                                     if (luka.isNotEmpty)
//                     //                                       SizedBox(
//                     //                                         width: 200,
//                     //                                         child: Text(
//                     //                                           luka.join('\n'),
//                     //                                           textAlign:
//                     //                                               TextAlign
//                     //                                                   .end,
//                     //                                           style:
//                     //                                               getWhiteTextStyle(
//                     //                                             fontWeight:
//                     //                                                 w700,
//                     //                                             fontSize: 18,
//                     //                                           ),
//                     //                                         ),
//                     //                                       ),
//                     //                                     Text(
//                     //                                       '${(pl.rating == '' || pl.rating == null) ? '' : 'Rating ${pl.rating}'}',
//                     //                                       style:
//                     //                                           getWhiteTextStyle(
//                     //                                         fontWeight: w700,
//                     //                                         fontSize: 18,
//                     //                                       ),
//                     //                                     ),
//                     //                                     const SizedBox(
//                     //                                         height: 12),
//                     //                                   ],
//                     //                                 ),
//                     //                               ],
//                     //                             ),
//                     //                             Divider(
//                     //                               color: white,
//                     //                               thickness: 1.5,
//                     //                             ),
//                     //                           ],
//                     //                         );
//                     //                       },
//                     //                     ),
//                     //                   ],
//                     //                 ),
//                     //               ),
//                     //             );
//                     //           },
//                     //         );
//                     //       },
//                     //     ),
//                     //   ],
//                     // );
//                     // old code case 1
//                     // case 1:
//                     //   return Column(
//                     //     children: [
//                     //       const SizedBox(
//                     //         height: 12,
//                     //       ),
//                     //       SelectPitButton(
//                     //           pit: pit,
//                     //           selectedPit: selectedPit,
//                     //           onSelectedPitChanged: (index) {
//                     //             setState(() {
//                     //               selectedPit = index;
//                     //             });
//                     //           }),
//                     //       const SizedBox(
//                     //         height: 12,
//                     //       ),
//                     //       if (homeState.selectedSite?.idCompany == '2')
//                     //         Text(
//                     //           // 'Total Unit : ${dailyData.length ?? 0}',
//                     //           'Target Low Pressure : ${(state.countAllTire * 0.01).ceil()} Tire',

//                     //           style: getBlackTextStyle(
//                     //             fontSize: 14,
//                     //           ),
//                     //         )
//                     //       else
//                     //         Container(),
//                     //       const SizedBox(
//                     //         height: 12,
//                     //       ),
//                     //       PaginateFirestore(
//                     //           query: selectedPit == 0
//                     //               ? firestore
//                     //                   .collection('daily_pressure')
//                     //                   .where('tanggal',
//                     //                       isGreaterThanOrEqualTo:
//                     //                           DateTime(now.year, now.month, now.day)
//                     //                               .toIso8601String())
//                     //                   .where('tanggal',
//                     //                       isLessThanOrEqualTo:
//                     //                           DateTime(now.year, now.month, now.day, 23, 59, 59)
//                     //                               .toIso8601String())
//                     //                   .where('idSite', isEqualTo: currentIdSite)
//                     //                   .orderBy('tanggal', descending: true)
//                     //               : firestore
//                     //                   .collection('daily_pressure')
//                     //                   .where('tanggal',
//                     //                       isGreaterThanOrEqualTo:
//                     //                           DateTime(now.year, now.month, now.day)
//                     //                               .toIso8601String())
//                     //                   .where('tanggal',
//                     //                       isLessThanOrEqualTo:
//                     //                           DateTime(now.year, now.month, now.day, 23, 59, 59)
//                     //                               .toIso8601String())
//                     //                   .where('idSite', isEqualTo: currentIdSite)
//                     //                   .where('pit', isEqualTo: pit[selectedPit])
//                     //                   .orderBy('tanggal', descending: true),
//                     //           itemBuilderType: PaginateBuilderType.listView,
//                     //           shrinkWrap: true,
//                     //           physics: NeverScrollableScrollPhysics(),
//                     //           itemsPerPage: 10,
//                     //           // isLive: true,
//                     //           isLive: false,
//                     //           onEmpty: Text(
//                     //             'There is no low pressure data!',
//                     //             style: getBlackTextStyle(),
//                     //           ),
//                     //           initialLoader: const Center(child: CircularProgressIndicator.adaptive()),
//                     //           bottomLoader: const Center(child: CircularProgressIndicator.adaptive()),
//                     //           itemBuilder: (context, snapshot, firebaseIndex) {
//                     //             // log('snapshot : $snapshot');
//                     //             final allData = snapshot
//                     //                 .map((doc) => DailyPress.fromFirestore(
//                     //                     doc.data() as Map<String, dynamic>))
//                     //                 .toList();

//                     //             final distinctDaily =
//                     //                 Set<DailyPress>.from(allData).toList();

//                     //             return ListView.builder(
//                     //                 itemCount: distinctDaily.length,
//                     //                 physics: NeverScrollableScrollPhysics(),
//                     //                 shrinkWrap: true,
//                     //                 itemBuilder: (context, index) {
//                     //                   if (firebaseIndex +
//                     //                           (distinctDaily.length) >
//                     //                       distinctDaily.length) {
//                     //                     return Container();
//                     //                   }
//                     //                   final data = distinctDaily[index];

//                     //                   if (searchQuery.isNotEmpty &&
//                     //                       !data.unit!
//                     //                           .toLowerCase()
//                     //                           .contains(searchQuery)) {
//                     //                     return Container();
//                     //                   }

//                     //                   if (selectedPit != 0) {
//                     //                     if (data.pit != pit[selectedPit]) {
//                     //                       return Container();
//                     //                     }
//                     //                   }

//                     //                   bool isLowPressure =
//                     //                       data.posisi.any((position) {
//                     //                     final tireSize = position.size;

//                     //                     final pressure = int.tryParse(
//                     //                             position.pressure ?? '0') ??
//                     //                         0;

//                     //                     if (tireSize == null ||
//                     //                         tireSize.isEmpty) return false;

//                     //                     // Cari data reccPress berdasarkan ukuran ban (tireSize)
//                     //                     final recommended =
//                     //                         state.reccPress.firstWhere(
//                     //                       (rec) => rec.containsKey(tireSize),
//                     //                       orElse: () => {},
//                     //                     );

//                     //                     if (recommended != {} &&
//                     //                         recommended[tireSize] != null) {
//                     //                       final recommendedPressure =
//                     //                           int.parse(recommended[tireSize]);

//                     //                       final adjustedPressure =
//                     //                           position.adjusmentPressure;

//                     //                       if (pressure == 0) return false;
//                     //                       if (adjustedPressure != '') {
//                     //                         return false;
//                     //                       }

//                     //                       return pressure < recommendedPressure;
//                     //                     }
//                     //                     return false;
//                     //                   });

//                     //                   if (!isLowPressure) {
//                     //                     return Container();
//                     //                   }

//                     //                   return Card(
//                     //                       elevation: 2,
//                     //                       shape: RoundedRectangleBorder(
//                     //                         borderRadius:
//                     //                             BorderRadius.circular(12),
//                     //                       ),
//                     //                       child: Container(
//                     //                         width: double.infinity,
//                     //                         padding: EdgeInsets.symmetric(
//                     //                             horizontal: 12, vertical: 24),
//                     //                         decoration: BoxDecoration(
//                     //                           color: (isLowPressure
//                     //                               ? Colors.red
//                     //                               : green00968A),
//                     //                           // color: green00968A,
//                     //                           borderRadius:
//                     //                               BorderRadius.circular(12),
//                     //                         ),
//                     //                         child: ExpansionTile(
//                     //                           tilePadding: EdgeInsets.zero,
//                     //                           childrenPadding:
//                     //                               EdgeInsets.all(0),
//                     //                           title: Column(
//                     //                             crossAxisAlignment:
//                     //                                 CrossAxisAlignment.start,
//                     //                             children: [
//                     //                               Row(
//                     //                                 children: [
//                     //                                   Icon(
//                     //                                     Icons.task,
//                     //                                     color: white,
//                     //                                     size: 36,
//                     //                                   ),
//                     //                                   const SizedBox(
//                     //                                     width: 12,
//                     //                                   ),
//                     //                                   Column(
//                     //                                     crossAxisAlignment:
//                     //                                         CrossAxisAlignment
//                     //                                             .start,
//                     //                                     children: [
//                     //                                       Text(
//                     //                                         // dailyMap['unit'] +
//                     //                                         //     '${((dailyMap['pit'] != 'Default') ? '\n' + dailyMap['pit'] : '')}',
//                     //                                         data.unit +
//                     //                                             '${((data.pit != 'Default') ? '\n' + data.pit : '')}',
//                     //                                         style:
//                     //                                             getWhiteTextStyle(
//                     //                                                 fontWeight:
//                     //                                                     w700,
//                     //                                                 fontSize:
//                     //                                                     18),
//                     //                                       ),
//                     //                                       (isLowPressure)
//                     //                                           ? Text(
//                     //                                               // dailyMap['unit'] +
//                     //                                               //     '${((dailyMap['pit'] != 'Default') ? '\n' + dailyMap['pit'] : '')}',
//                     //                                               'LOW PRESSURE!',
//                     //                                               style: getWhiteTextStyle(
//                     //                                                   fontWeight:
//                     //                                                       w700,
//                     //                                                   fontSize:
//                     //                                                       18),
//                     //                                             )
//                     //                                           : Container()
//                     //                                     ],
//                     //                                   ),
//                     //                                 ],
//                     //                               ),
//                     //                             ],
//                     //                           ),
//                     //                           trailing: SizedBox(
//                     //                             width: 90,
//                     //                             child:
//                     //                                 Icon(Icons.arrow_drop_down),
//                     //                           ),
//                     //                           children: [
//                     //                             const SizedBox(
//                     //                               height: 12,
//                     //                             ),
//                     //                             Row(
//                     //                               mainAxisAlignment:
//                     //                                   MainAxisAlignment
//                     //                                       .spaceBetween,
//                     //                               children: [
//                     //                                 Text(
//                     //                                   'Name',
//                     //                                   style: getWhiteTextStyle(
//                     //                                       fontSize: 18),
//                     //                                 ),
//                     //                                 Container(
//                     //                                   width: 250,
//                     //                                   child: Text(
//                     //                                     // dailyMap['user'] ??
//                     //                                     //     'No Name',
//                     //                                     data.user == ''
//                     //                                         ? 'No Name'
//                     //                                         : data.user,
//                     //                                     textAlign:
//                     //                                         TextAlign.end,
//                     //                                     style:
//                     //                                         getWhiteTextStyle(
//                     //                                             fontWeight:
//                     //                                                 w700,
//                     //                                             fontSize: 18),
//                     //                                   ),
//                     //                                 ),
//                     //                               ],
//                     //                             ),
//                     //                             const SizedBox(
//                     //                               height: 12,
//                     //                             ),
//                     //                             Row(
//                     //                               mainAxisAlignment:
//                     //                                   MainAxisAlignment
//                     //                                       .spaceBetween,
//                     //                               children: [
//                     //                                 Text(
//                     //                                   'Tanggal',
//                     //                                   style: getWhiteTextStyle(
//                     //                                       fontSize: 18),
//                     //                                 ),
//                     //                                 Text(
//                     //                                   // dailyMap['tanggal']
//                     //                                   //     .split('T')[0],
//                     //                                   data.tanggal
//                     //                                       .split('T')[0],
//                     //                                   style: getWhiteTextStyle(
//                     //                                       fontWeight: w700,
//                     //                                       fontSize: 18),
//                     //                                 ),
//                     //                               ],
//                     //                             ),
//                     //                             const SizedBox(
//                     //                               height: 12,
//                     //                             ),
//                     //                             Row(
//                     //                               mainAxisAlignment:
//                     //                                   MainAxisAlignment
//                     //                                       .spaceBetween,
//                     //                               children: [
//                     //                                 Text(
//                     //                                   'Waktu',
//                     //                                   style: getWhiteTextStyle(
//                     //                                       fontSize: 18),
//                     //                                 ),
//                     //                                 Text(
//                     //                                   // dailyMap['tanggal']
//                     //                                   //     .split('T')[1]
//                     //                                   data.tanggal
//                     //                                       .split('T')[1]
//                     //                                       .substring(0, 5),
//                     //                                   style: getWhiteTextStyle(
//                     //                                       fontWeight: w700,
//                     //                                       fontSize: 18),
//                     //                                 ),
//                     //                               ],
//                     //                             ),
//                     //                             const SizedBox(
//                     //                               height: 12,
//                     //                             ),
//                     //                             Row(
//                     //                               mainAxisAlignment:
//                     //                                   MainAxisAlignment
//                     //                                       .spaceBetween,
//                     //                               children: [
//                     //                                 Text(
//                     //                                   'HM Unit',
//                     //                                   style: getWhiteTextStyle(
//                     //                                       fontSize: 18),
//                     //                                 ),
//                     //                                 Text(
//                     //                                   // dailyMap['hm'],
//                     //                                   data.hm,
//                     //                                   style: getWhiteTextStyle(
//                     //                                       fontWeight: w700,
//                     //                                       fontSize: 18),
//                     //                                 ),
//                     //                               ],
//                     //                             ),
//                     //                             const SizedBox(
//                     //                               height: 12,
//                     //                             ),
//                     //                             Row(
//                     //                               mainAxisAlignment:
//                     //                                   MainAxisAlignment
//                     //                                       .spaceBetween,
//                     //                               children: [
//                     //                                 Text(
//                     //                                   'Pit',
//                     //                                   style: getWhiteTextStyle(
//                     //                                       fontSize: 18),
//                     //                                 ),
//                     //                                 Text(
//                     //                                   // dailyMap['pit'],
//                     //                                   data.pit,
//                     //                                   style: getWhiteTextStyle(
//                     //                                       fontWeight: w700,
//                     //                                       fontSize: 18),
//                     //                                 ),
//                     //                               ],
//                     //                             ),
//                     //                             const SizedBox(
//                     //                               height: 12,
//                     //                             ),
//                     //                             Column(
//                     //                               children:
//                     //                                   // positionList.map((pl) {
//                     //                                   data.posisi.map((pl) {
//                     //                                 // final plIndex = positionList
//                     //                                 //     .indexOf(pl);
//                     //                                 List<dynamic> luka = [];

//                     //                                 // if (pl['luka'] != null &&
//                     //                                 //     pl['luka'] is! String) {
//                     //                                 //   luka = pl['luka']
//                     //                                 //       as List<dynamic>;
//                     //                                 // }
//                     //                                 if (pl.luka != null &&
//                     //                                     pl.luka is! String) {
//                     //                                   luka = pl.luka
//                     //                                       as List<dynamic>;
//                     //                                 }

//                     //                                 return Column(
//                     //                                   children: [
//                     //                                     Row(
//                     //                                       mainAxisAlignment:
//                     //                                           MainAxisAlignment
//                     //                                               .spaceBetween,
//                     //                                       crossAxisAlignment:
//                     //                                           CrossAxisAlignment
//                     //                                               .center,
//                     //                                       children: [
//                     //                                         Text(
//                     //                                           // 'Pos. ${pl['pos']}',
//                     //                                           'Pos. ${pl.pos}',
//                     //                                           style:
//                     //                                               getWhiteTextStyle(
//                     //                                                   fontSize:
//                     //                                                       18),
//                     //                                         ),
//                     //                                         Column(
//                     //                                           crossAxisAlignment:
//                     //                                               CrossAxisAlignment
//                     //                                                   .end,
//                     //                                           mainAxisAlignment:
//                     //                                               MainAxisAlignment
//                     //                                                   .center,
//                     //                                           children: [
//                     //                                             Column(
//                     //                                               crossAxisAlignment:
//                     //                                                   CrossAxisAlignment
//                     //                                                       .end,
//                     //                                               children: [
//                     //                                                 Column(
//                     //                                                   crossAxisAlignment:
//                     //                                                       CrossAxisAlignment
//                     //                                                           .end,
//                     //                                                   children: [
//                     //                                                     Builder(builder:
//                     //                                                         (context) {
//                     //                                                       return Text(
//                     //                                                         // '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
//                     //                                                         '${(pl.pressure == '' || pl.pressure == null) ? 0 : pl.pressure} Psi',
//                     //                                                         style:
//                     //                                                             getWhiteTextStyle(fontWeight: w700, fontSize: 18),
//                     //                                                       );
//                     //                                                     }),
//                     //                                                     Builder(
//                     //                                                       builder:
//                     //                                                           (context) {
//                     //                                                         // Cek jika pl.size null atau kosong
//                     //                                                         if (pl.size == null ||
//                     //                                                             pl.size.isEmpty)
//                     //                                                           return Container();

//                     //                                                         // Ambil data recommended pressure
//                     //                                                         final recommendedMap =
//                     //                                                             state.reccPress.firstWhere(
//                     //                                                           (map) => map.containsKey(pl.size),
//                     //                                                           orElse: () => {},
//                     //                                                         );

//                     //                                                         // Cek apakah recommendedMap valid dan pl.size ada di dalamnya
//                     //                                                         final recommendedPressure = recommendedMap.isNotEmpty && recommendedMap[pl.size] != null
//                     //                                                             ? int.tryParse(recommendedMap[pl.size]) ?? 0
//                     //                                                             : 0;

//                     //                                                         // Cek jika pl.pressure null atau bukan angka
//                     //                                                         final pressure =
//                     //                                                             int.tryParse(pl.pressure ?? '0') ?? 0;

//                     //                                                         // Jika tekanan = 0, tidak ditampilkan
//                     //                                                         if (pressure ==
//                     //                                                             0)
//                     //                                                           return Container();

//                     //                                                         // Jika low pressure dan belum di-adjust, tidak ditampilkan
//                     //                                                         if (recommendedPressure < pressure ||
//                     //                                                             pl.adjusmentPressure.isNotEmpty) {
//                     //                                                           return Container();
//                     //                                                         }

//                     //                                                         return Container(
//                     //                                                           width: 120,
//                     //                                                           height: 60,
//                     //                                                           margin: EdgeInsets.only(top: 12, bottom: 12),
//                     //                                                           child: ButtonWidget(
//                     //                                                             name: Text(
//                     //                                                               'Adjust',
//                     //                                                               style: getWhiteTextStyle(),
//                     //                                                             ),
//                     //                                                             color: green00968A,
//                     //                                                             function: () {
//                     //                                                               List<Position> position = [];
//                     //                                                               for (int i = 0; i < data.posisi.length; i++) {
//                     //                                                                 final p = data.posisi[i];
//                     //                                                                 // ADD COT HOLD PRESSURE
//                     //                                                                 position.add(Position(pos: p.pos, pressure: p.pressure, temperatureStatus: p.temperatureStatus, rating: p.rating, adjusmentPressure: p.adjusmentPressure, adjustmentTemperatureStatus: p.adjustmentTemperatureStatus, luka: p.luka, image: p.image, size: p.size, idInventory: p.idInventory, idUnit: p.idUnit, idDaily: p.idDaily, kondisi: p.kondisi));
//                     //                                                               }

//                     //                                                               final dataUnit = {
//                     //                                                                 'unitNumber': data.unit,
//                     //                                                                 'hm': data.hm,
//                     //                                                                 'pit': data.pit,
//                     //                                                                 'position': position,
//                     //                                                                 'reccPress': state.reccPress,
//                     //                                                               };

//                     //                                                               Navigator.pushNamed(context, DailyCheckFormPage.routeName, arguments: dataUnit);
//                     //                                                             },
//                     //                                                           ),
//                     //                                                         );
//                     //                                                       },
//                     //                                                     ),
//                     //                                                   ],
//                     //                                                 ),
//                     //                                                 // (pl['adjusmentPressure'] != null &&
//                     //                                                 //         pl['adjusmentPressure'] !=
//                     //                                                 //             '0' &&
//                     //                                                 //         pl['adjusmentPressure'] !=
//                     //                                                 //             '')
//                     //                                                 (pl.adjusmentPressure != null &&
//                     //                                                         pl.adjusmentPressure !=
//                     //                                                             '0' &&
//                     //                                                         pl.adjusmentPressure !=
//                     //                                                             '')
//                     //                                                     ? Text(
//                     //                                                         // '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
//                     //                                                         '${pl.adjusmentPressure} Psi (Adj. Pressure)',
//                     //                                                         style:
//                     //                                                             getWhiteTextStyle(fontWeight: w700, fontSize: 18),
//                     //                                                       )
//                     //                                                     : Container(),
//                     //                                               ],
//                     //                                             ),
//                     //                                             (luka.isEmpty ||
//                     //                                                     luka ==
//                     //                                                         null)
//                     //                                                 ? Container()
//                     //                                                 : Container(
//                     //                                                     width:
//                     //                                                         200,
//                     //                                                     child:
//                     //                                                         Text(
//                     //                                                       // pl['luka']
//                     //                                                       pl.luka
//                     //                                                           .join('\n'),
//                     //                                                       textAlign:
//                     //                                                           TextAlign.end,
//                     //                                                       style: getWhiteTextStyle(
//                     //                                                           fontWeight: w700,
//                     //                                                           fontSize: 18),
//                     //                                                     ),
//                     //                                                   ),
//                     //                                             Text(
//                     //                                                 // '${(pl['rating'] == '' || pl['rating'] == null) ? '' : 'Rating ${pl['rating']}'}',
//                     //                                                 '${(pl.rating == '' || pl.rating == null) ? '' : 'Rating ${pl.rating}'}',
//                     //                                                 style: getWhiteTextStyle(
//                     //                                                     fontWeight:
//                     //                                                         w700,
//                     //                                                     fontSize:
//                     //                                                         18)),
//                     //                                             const SizedBox(
//                     //                                               height: 12,
//                     //                                             ),
//                     //                                           ],
//                     //                                         ),
//                     //                                       ],
//                     //                                     ),
//                     //                                     Divider(
//                     //                                       color: white,
//                     //                                       thickness: 1.5,
//                     //                                     ),
//                     //                                   ],
//                     //                                 );
//                     //                               }).toList(),
//                     //                             ),
//                     //                           ],
//                     //                         ),
//                     //                       ));
//                     //                 });

//                     //             ;
//                     //           }),
//                     //     ],
//                     //   );

//                     // All Unit
//                     case 2:
//                       final keyword = searchQuery.toLowerCase();

//                       final filteredUnits = state.units.where((unit) {
//                         if (keyword.isEmpty) return true;

//                         final unitNumber = unit.unitNumber?.toLowerCase() ?? '';
//                         final model = unit.model?.toLowerCase() ?? '';

//                         return unitNumber.contains(keyword) ||
//                             model.contains(keyword);
//                       }).toList();

//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const SizedBox(
//                             height: 12,
//                           ),
//                           Text(
//                             'Total Unit : ${filteredUnits.length}',
//                             style: getBlackTextStyle(fontSize: 20),
//                           ),
//                           const SizedBox(
//                             height: 6,
//                           ),
//                           if (state.units.isEmpty)
//                             Text(
//                               'Empty!',
//                               textAlign: TextAlign.center,
//                               style: getBlackTextStyle(fontSize: 18),
//                             )
//                           else
//                             SizedBox(
//                               height: MediaQuery.of(context).size.height * 0.62,
//                               child: ListView.builder(
//                                 itemCount: filteredUnits.length,
//                                 keyboardDismissBehavior:
//                                     ScrollViewKeyboardDismissBehavior.onDrag,
//                                 itemBuilder: (context, index) {
//                                   final unit = filteredUnits[index];

//                                   return InkWell(
//                                     onTap: () {
//                                       Navigator.pushNamed(
//                                         context,
//                                         DailyCheckFormPage.routeName,
//                                         arguments: {
//                                           'unitNumber': unit.unitNumber,
//                                           'reccPress': state.reccPress,
//                                         },
//                                       );
//                                     },
//                                     child: Container(
//                                       margin: const EdgeInsets.symmetric(
//                                           vertical: 8.0),
//                                       padding: const EdgeInsets.symmetric(
//                                           vertical: 6),
//                                       decoration: BoxDecoration(
//                                         color: Colors.white,
//                                         borderRadius: BorderRadius.circular(12),
//                                         boxShadow: [
//                                           BoxShadow(
//                                             color:
//                                                 Colors.black.withOpacity(0.1),
//                                             spreadRadius: 2,
//                                             blurRadius: 5,
//                                             offset: const Offset(0, 2),
//                                           ),
//                                         ],
//                                       ),
//                                       child: ListTile(
//                                         leading: const Icon(
//                                           Icons.front_loader,
//                                           color: Colors.orange,
//                                         ),
//                                         title: Padding(
//                                           padding: const EdgeInsets.only(
//                                               bottom: 4.0),
//                                           child: Text(
//                                             unit.unitNumber ?? '',
//                                             style: getBlackTextStyle(
//                                               fontWeight: FontWeight.w700,
//                                             ),
//                                           ),
//                                         ),
//                                         subtitle: Text(
//                                           unit.model ?? '',
//                                           style: getGreyTextStyle(grey6A707C),
//                                         ),
//                                         trailing:
//                                             const Icon(Icons.arrow_forward_ios),
//                                       ),
//                                     ),
//                                   );
//                                 },
//                               ),
//                             ),
//                         ],
//                       );
//                     // case 2:
//                     //   // log('kendaraanku: ${state.units.map((unit) => 'unitNumber: ${unit.unitNumber}, sn: ${unit.sn}').toList()}');
//                     //   final filteredUnits = state.units.where((unit) {
//                     //     final keyword = searchQuery.toLowerCase();

//                     //     if (keyword.isEmpty) return true;

//                     //     final unitNumber = unit.unitNumber?.toLowerCase() ?? '';
//                     //     final model = unit.model?.toLowerCase() ?? '';

//                     //     return unitNumber.contains(keyword) ||
//                     //         model.contains(keyword);
//                     //   }).toList();

//                     //   return Column(
//                     //     crossAxisAlignment: CrossAxisAlignment.start,
//                     //     children: [
//                     //       const SizedBox(
//                     //         height: 12,
//                     //       ),
//                     //       Text(
//                     //         'Total Unit : ${state.units.length.toString()}',
//                     //         style: getBlackTextStyle(fontSize: 20),
//                     //       ),
//                     //       const SizedBox(
//                     //         height: 6,
//                     //       ),
//                     //       // Builder(builder: (context) {
//                     //       //   if (state.totalActualUnits?.length == null) {
//                     //       //     return Container();
//                     //       //   }

//                     //       //   if (state.totalActualUnits?.length !=
//                     //       //       state.units.length) {
//                     //       //     return Column(
//                     //       //       children: [
//                     //       //         NotUpdateWarningWidget(
//                     //       //             totalActual:
//                     //       //                 state.totalActualUnits?.length ?? 0),
//                     //       //         SizedBox(
//                     //       //           height: 12,
//                     //       //         ),
//                     //       //       ],
//                     //       //     );
//                     //       //   } else {
//                     //       //     Container();
//                     //       //   }
//                     //       //   return Container();
//                     //       // }),
//                     //       (state.units == null || state.units.isEmpty)
//                     //           ? Text(
//                     //               'Empty!',
//                     //               textAlign: TextAlign.center,
//                     //               style: getBlackTextStyle(fontSize: 18),
//                     //             )
//                     //           : ListView.builder(
//                     //               shrinkWrap: true,
//                     //               physics: const NeverScrollableScrollPhysics(),
//                     //               itemCount: filteredUnits.length,
//                     //               itemBuilder: (context, index) {
//                     //                 final unit = filteredUnits[index];

//                     //                 return InkWell(
//                     //                   onTap: () {
//                     //                     Navigator.pushNamed(
//                     //                       context,
//                     //                       DailyCheckFormPage.routeName,
//                     //                       arguments: {
//                     //                         'unitNumber': unit.unitNumber,
//                     //                         'reccPress': state.reccPress,
//                     //                       },
//                     //                     );
//                     //                   },
//                     //                   child: Container(
//                     //                     margin: const EdgeInsets.symmetric(
//                     //                         vertical: 8.0),
//                     //                     padding: const EdgeInsets.symmetric(
//                     //                         vertical: 6),
//                     //                     decoration: BoxDecoration(
//                     //                       color: Colors.white,
//                     //                       borderRadius:
//                     //                           BorderRadius.circular(12),
//                     //                       boxShadow: [
//                     //                         BoxShadow(
//                     //                           color:
//                     //                               Colors.black.withOpacity(0.1),
//                     //                           spreadRadius: 2,
//                     //                           blurRadius: 5,
//                     //                           offset: const Offset(0, 2),
//                     //                         ),
//                     //                       ],
//                     //                     ),
//                     //                     child: ListTile(
//                     //                       leading: const Icon(
//                     //                         Icons.front_loader,
//                     //                         color: Colors.orange,
//                     //                       ),
//                     //                       title: Padding(
//                     //                         padding: const EdgeInsets.only(
//                     //                             bottom: 4.0),
//                     //                         child: Text(
//                     //                           unit.unitNumber ?? '',
//                     //                           style: getBlackTextStyle(
//                     //                               fontWeight: FontWeight.w700),
//                     //                         ),
//                     //                       ),
//                     //                       subtitle: Text(
//                     //                         unit.model ?? '',
//                     //                         style: getGreyTextStyle(grey6A707C),
//                     //                       ),
//                     //                       trailing: const Icon(
//                     //                           Icons.arrow_forward_ios),
//                     //                     ),
//                     //                   ),
//                     //                 );
//                     //               },
//                     //             ),
//                     //       // : Column(
//                     //       //     children: state.units.map((unit) {
//                     //       //       if (searchQuery.isNotEmpty &&
//                     //       //           !unit.unitNumber!
//                     //       //               .toLowerCase()
//                     //       //               .contains(searchQuery) &&
//                     //       //           !unit.model!
//                     //       //               .toLowerCase()
//                     //       //               .contains(searchQuery)) {
//                     //       //         return Container();
//                     //       //       }
//                     //       //       return InkWell(
//                     //       //         // onTap: (userAccessId == '1' ||
//                     //       //         //         userAccessId == '2' ||
//                     //       //         //         userAccessId == '3')
//                     //       //         onTap: () {
//                     //       //           Navigator.pushNamed(context,
//                     //       //               DailyCheckFormPage.routeName,
//                     //       //               arguments: {
//                     //       //                 'unitNumber': unit.unitNumber,
//                     //       //                 'reccPress': state.reccPress,
//                     //       //               });
//                     //       //         },
//                     //       //         child: Container(
//                     //       //           margin:
//                     //       //               EdgeInsets.symmetric(vertical: 8.0),
//                     //       //           padding:
//                     //       //               EdgeInsets.symmetric(vertical: 6),
//                     //       //           decoration: BoxDecoration(
//                     //       //             color: Colors.white,
//                     //       //             borderRadius:
//                     //       //                 BorderRadius.circular(12),
//                     //       //             boxShadow: [
//                     //       //               BoxShadow(
//                     //       //                 color:
//                     //       //                     Colors.black.withOpacity(0.1),
//                     //       //                 spreadRadius: 2,
//                     //       //                 blurRadius: 5,
//                     //       //                 offset: Offset(0, 2),
//                     //       //               ),
//                     //       //             ],
//                     //       //           ),
//                     //       //           child: ListTile(
//                     //       //             leading: Icon(
//                     //       //               Icons.front_loader,
//                     //       //               color: Colors.orange,
//                     //       //             ),
//                     //       //             title: Padding(
//                     //       //               padding: const EdgeInsets.only(
//                     //       //                   bottom: 4.0),
//                     //       //               child: Text(
//                     //       //                 '${unit.unitNumber}',
//                     //       //                 style: getBlackTextStyle(
//                     //       //                     fontWeight: FontWeight.w700),
//                     //       //               ),
//                     //       //             ),
//                     //       //             subtitle: Text(
//                     //       //               '${unit.model}',
//                     //       //               style: getGreyTextStyle(grey6A707C),
//                     //       //             ),
//                     //       //             trailing:
//                     //       //                 Icon(Icons.arrow_forward_ios),
//                     //       //           ),
//                     //       //         ),
//                     //       //       );
//                     //       //     }).toList(),
//                     //       //   ),
//                     //     ],
//                     //   );

//                     // Not Checked Unit
//                     case 3:
//                       final today = DateTime.now();
//                       final todayString =
//                           today.toIso8601String().substring(0, 10);

//                       checkedFuture ??= getCheckedTodayFuture();

//                       return Column(
//                         children: [
//                           const SizedBox(
//                             height: 12,
//                           ),

//                           if (homeState.userAccessCompanyId.value == '1' &&
//                               homeState.userAccessId.value == '5') ...[
//                             SelectPitButton(
//                               pit: notCheckedPit,
//                               selectedPit: selectedNotCheckedPit,
//                               onSelectedPitChanged: (index) {
//                                 setState(() {
//                                   selectedNotCheckedPit = index;
//                                 });
//                               },
//                             ),
//                             if (selectedNotCheckedPit != 0)
//                               const SizedBox(height: 12),
//                           ],

//                           // Tombol Get SPM Unit Tire Pressure
//                           (userAccessId != '1' &&
//                                   homeState.userAccessCompanyId.value == '')
//                               ? SizedBox(
//                                   width: double.infinity,
//                                   child: ElevatedButton(
//                                     onPressed: () async {
//                                       showDialog<bool>(
//                                         context: context,
//                                         barrierDismissible: false,
//                                         builder: (context) {
//                                           return AlertDialog(
//                                             title: const Text("Konfirmasi"),
//                                             content: const Text(
//                                                 "Apakah Anda yakin?"),
//                                             actions: [
//                                               TextButton(
//                                                 onPressed: () =>
//                                                     Navigator.of(context)
//                                                         .pop(false),
//                                                 child: const Text("No"),
//                                               ),
//                                               ElevatedButton(
//                                                 onPressed: () async {
//                                                   showDialog(
//                                                     context: context,
//                                                     barrierDismissible: false,
//                                                     builder: (context) {
//                                                       return const AlertDialog(
//                                                         content: Row(
//                                                           children: [
//                                                             CircularProgressIndicator(),
//                                                             SizedBox(width: 20),
//                                                             Text(
//                                                                 "Submitting data, please wait..."),
//                                                           ],
//                                                         ),
//                                                       );
//                                                     },
//                                                   );

//                                                   try {
//                                                     final dataSPMJam7 =
//                                                         await ApiService
//                                                             .getJam7SPM(
//                                                                 currentIdSite);

//                                                     final List<UnitTire>
//                                                         dataTireCondition =
//                                                         await ApiService
//                                                             .getTireCondition(
//                                                       currentIdSite,
//                                                     );

//                                                     final ratingMap =
//                                                         <String, String>{};
//                                                     final tireSizeMap =
//                                                         <String, String>{};
//                                                     final hmMap =
//                                                         <String, String>{};
//                                                     final idInventoryMap =
//                                                         <String, String>{};
//                                                     final idUnitMap =
//                                                         <String, String>{};
//                                                     final idDailyMap =
//                                                         <String, String>{};

//                                                     final today =
//                                                         DateTime.now();

//                                                     final formattedToday =
//                                                         '${today.month.toString().padLeft(2, '0')}'
//                                                         '${today.day.toString().padLeft(2, '0')}'
//                                                         '${(today.year % 100).toString().padLeft(2, '0')}';

//                                                     for (final unit
//                                                         in dataTireCondition) {
//                                                       final unitNumber =
//                                                           unit.unitNumber ?? '';
//                                                       final posisi =
//                                                           unit.posisi ?? '';

//                                                       if (unitNumber
//                                                               .isNotEmpty &&
//                                                           posisi.isNotEmpty) {
//                                                         final key =
//                                                             '$unitNumber-$posisi';

//                                                         ratingMap[key] =
//                                                             unit.rating ?? '';
//                                                         tireSizeMap[key] =
//                                                             unit.size ?? '';
//                                                         hmMap[key] =
//                                                             unit.hm ?? '';
//                                                         idInventoryMap[key] =
//                                                             unit.idinventory ??
//                                                                 '';
//                                                         idUnitMap[key] =
//                                                             unit.idUnit ?? '';
//                                                         idDailyMap[key] =
//                                                             '$unitNumber$posisi$formattedToday$currentIdSite';
//                                                       }
//                                                     }

//                                                     final batch =
//                                                         firestore.batch();
//                                                     final collection =
//                                                         firestore.collection(
//                                                             'daily_pressure');

//                                                     // Ambil semua data checked hari ini sekali saja,
//                                                     // supaya tidak query Firebase di dalam loop.
//                                                     final todaySnapshot =
//                                                         await collection
//                                                             .where('hari',
//                                                                 isEqualTo:
//                                                                     todayString)
//                                                             .where('idSite',
//                                                                 isEqualTo:
//                                                                     currentIdSite)
//                                                             .get();

//                                                     final existingDocMap =
//                                                         <String, String>{};

//                                                     for (final doc
//                                                         in todaySnapshot.docs) {
//                                                       final data = doc.data();
//                                                       final unit = data['unit']
//                                                               ?.toString() ??
//                                                           '';

//                                                       if (unit.isNotEmpty) {
//                                                         existingDocMap[unit] =
//                                                             doc.id;
//                                                       }
//                                                     }

//                                                     for (final dataUnit
//                                                         in dataSPMJam7) {
//                                                       final jsonData =
//                                                           dataUnit.toJson();
//                                                       final unitNumber =
//                                                           dataUnit.devicename ??
//                                                               '';

//                                                       if (unitNumber.isEmpty) {
//                                                         continue;
//                                                       }

//                                                       final tireCount = jsonData
//                                                           .keys
//                                                           .where((k) =>
//                                                               k.startsWith(
//                                                                   'max_p'))
//                                                           .length;

//                                                       bool hasZeroPressure =
//                                                           false;

//                                                       for (int pos = 1;
//                                                           pos <= tireCount;
//                                                           pos++) {
//                                                         final pressure =
//                                                             double.tryParse(
//                                                                   jsonData[
//                                                                           'avg_p$pos']
//                                                                       .toString(),
//                                                                 ) ??
//                                                                 0;

//                                                         if (pressure == 0) {
//                                                           hasZeroPressure =
//                                                               true;
//                                                           break;
//                                                         }
//                                                       }

//                                                       if (hasZeroPressure) {
//                                                         continue;
//                                                       }

//                                                       final existingDocId =
//                                                           existingDocMap[
//                                                               unitNumber];

//                                                       final docRef =
//                                                           existingDocId != null
//                                                               ? collection.doc(
//                                                                   existingDocId)
//                                                               : collection
//                                                                   .doc();

//                                                       batch.set(docRef, {
//                                                         'idSite': currentIdSite,
//                                                         'user':
//                                                             user['username'] ??
//                                                                 'Username',
//                                                         'tanggal': DateTime
//                                                                 .now()
//                                                             .toIso8601String(),
//                                                         'hari': todayString,
//                                                         'jam': DateTime.now()
//                                                             .toIso8601String()
//                                                             .substring(11, 19),
//                                                         'unit': unitNumber,
//                                                         'hm': hmMap[
//                                                                 '$unitNumber-1'] ??
//                                                             '',
//                                                         'posisi': List.generate(
//                                                           tireCount,
//                                                           (pIndex) {
//                                                             final pos =
//                                                                 pIndex + 1;
//                                                             final key =
//                                                                 '$unitNumber-$pos';

//                                                             return {
//                                                               'pos': '$pos',
//                                                               'pressure': (double
//                                                                           .tryParse(
//                                                                         jsonData['avg_p$pos']
//                                                                             .toString(),
//                                                                       ) ??
//                                                                       0)
//                                                                   .toStringAsFixed(
//                                                                       0),
//                                                               'rating':
//                                                                   ratingMap[
//                                                                           key] ??
//                                                                       '',
//                                                               'adjusmentPressure':
//                                                                   '0',
//                                                               'luka': '',
//                                                               'image': '',
//                                                               'tireSize':
//                                                                   tireSizeMap[
//                                                                           key] ??
//                                                                       '',
//                                                               'idInventory':
//                                                                   idInventoryMap[
//                                                                           key] ??
//                                                                       '',
//                                                               'idUnit':
//                                                                   idUnitMap[
//                                                                           key] ??
//                                                                       '',
//                                                               'idDaily':
//                                                                   idDailyMap[
//                                                                           key] ??
//                                                                       '',
//                                                               'kondisi': '',
//                                                               'min_press': (double
//                                                                           .tryParse(
//                                                                         jsonData['min_p$pos']
//                                                                             .toString(),
//                                                                       ) ??
//                                                                       0)
//                                                                   .toStringAsFixed(
//                                                                       0),
//                                                               'max_press': (double
//                                                                           .tryParse(
//                                                                         jsonData['max_p$pos']
//                                                                             .toString(),
//                                                                       ) ??
//                                                                       0)
//                                                                   .toStringAsFixed(
//                                                                       0),
//                                                               'avg_press': (double
//                                                                           .tryParse(
//                                                                         jsonData['avg_p$pos']
//                                                                             .toString(),
//                                                                       ) ??
//                                                                       0)
//                                                                   .toStringAsFixed(
//                                                                       0),
//                                                               'temp': double
//                                                                       .tryParse(
//                                                                     jsonData[
//                                                                             'avg_t$pos']
//                                                                         .toString(),
//                                                                   ) ??
//                                                                   0,
//                                                             };
//                                                           },
//                                                         ),
//                                                         'pit': 'Default',
//                                                         'timeLowPressureSPM':
//                                                             '',
//                                                       });
//                                                     }

//                                                     await batch.commit();

//                                                     Navigator.pop(
//                                                         context); // close loading
//                                                     Navigator.pop(
//                                                         context); // close confirmation

//                                                     // Setelah submit, refresh data FutureBuilder.
//                                                     setState(() {
//                                                       checkedFuture =
//                                                           getCheckedTodayFuture();
//                                                     });

//                                                     ScaffoldMessenger.of(
//                                                             context)
//                                                         .showSnackBar(
//                                                       const SnackBar(
//                                                         content: Text(
//                                                           "Success! Please open menu 'Checked'",
//                                                         ),
//                                                         backgroundColor:
//                                                             Colors.green,
//                                                       ),
//                                                     );
//                                                   } catch (e) {
//                                                     Navigator.pop(
//                                                         context); // close loading
//                                                     Navigator.pop(
//                                                         context); // close confirmation

//                                                     ScaffoldMessenger.of(
//                                                             context)
//                                                         .showSnackBar(
//                                                       SnackBar(
//                                                         content: Text(
//                                                           "Error (Data Null) : Please Try Again\n$e",
//                                                         ),
//                                                         backgroundColor:
//                                                             Colors.red,
//                                                       ),
//                                                     );
//                                                   }
//                                                 },
//                                                 child: const Text("Yes"),
//                                               ),
//                                             ],
//                                           );
//                                         },
//                                       );
//                                     },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.red,
//                                     ),
//                                     child: Container(
//                                       padding: const EdgeInsets.symmetric(
//                                           vertical: 12),
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           const Icon(
//                                             Icons.send,
//                                             color: Colors.white,
//                                           ),
//                                           const SizedBox(
//                                             width: 12,
//                                           ),
//                                           Text(
//                                             'Get SPM Unit Tire Pressure',
//                                             style: getWhiteTextStyle(),
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                 )
//                               : Container(),

//                           const SizedBox(
//                             height: 12,
//                           ),

//                           SizedBox(
//                             width: double.infinity,
//                             child: ElevatedButton(
//                               onPressed: refreshCheckedData,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.blueGrey,
//                               ),
//                               child: Text(
//                                 'Refresh Not Checked Data',
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ),
//                           ),

//                           const SizedBox(
//                             height: 12,
//                           ),
//                           FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
//                             future: checkedFuture,
//                             builder: (context, snapshot) {
//                               if (snapshot.connectionState ==
//                                   ConnectionState.waiting) {
//                                 return const Center(
//                                   child: CircularProgressIndicator.adaptive(),
//                                 );
//                               }

//                               if (snapshot.hasError) {
//                                 return Text(
//                                   'Error load data: ${snapshot.error}',
//                                   style: getBlackTextStyle(fontSize: 14),
//                                 );
//                               }

//                               final dailyData = snapshot.data?.docs ?? [];

//                               final checkedUnitSet = dailyData
//                                   .map((doc) {
//                                     final data = doc.data();
//                                     return data['unit']?.toString() ?? '';
//                                   })
//                                   .where((unit) => unit.isNotEmpty)
//                                   .toSet();

//                               final notChecked = state.units.where((unit) {
//                                 final unitNumber = unit.unitNumber ?? '';
//                                 return !checkedUnitSet.contains(unitNumber);
//                               }).toList();

//                               final keyword = searchQuery.toLowerCase();

//                               final filteredNotChecked =
//                                   notChecked.where((unit) {
//                                 if (keyword.isEmpty) return true;

//                                 final unitNumber =
//                                     unit.unitNumber?.toLowerCase() ?? '';
//                                 final model = unit.model?.toLowerCase() ?? '';

//                                 return unitNumber.contains(keyword) ||
//                                     model.contains(keyword);
//                               }).toList();

//                               DateTime? lastUpdate;

//                               if (dailyData.isNotEmpty) {
//                                 final sortedDocs = [...dailyData];

//                                 sortedDocs.sort((a, b) {
//                                   final aData = a.data();
//                                   final bData = b.data();

//                                   final aTanggal =
//                                       aData['tanggal']?.toString() ?? '';
//                                   final bTanggal =
//                                       bData['tanggal']?.toString() ?? '';

//                                   return bTanggal.compareTo(aTanggal);
//                                 });

//                                 final latestData = sortedDocs.first.data();
//                                 final tanggal =
//                                     latestData['tanggal']?.toString();

//                                 if (tanggal != null && tanggal.isNotEmpty) {
//                                   lastUpdate = DateTime.tryParse(tanggal);
//                                 }
//                               }

//                               return Column(
//                                 children: [
//                                   Text(
//                                     'Total Unit : ${filteredNotChecked.length}',
//                                     style: getBlackTextStyle(
//                                       fontSize: 20,
//                                     ),
//                                   ),
//                                   const SizedBox(
//                                     height: 12,
//                                   ),
//                                   SizedBox(
//                                     width: double.infinity,
//                                     child: ElevatedButton.icon(
//                                       onPressed: filteredNotChecked.isEmpty
//                                           ? null
//                                           : () async {
//                                               try {
//                                                 final StringBuffer txt =
//                                                     StringBuffer();

//                                                 final String tanggal = DateFormat(
//                                                         'dd-MM-yyyy HH:mm:ss')
//                                                     .format(DateTime.now());

//                                                 txt.writeln(
//                                                     'LIST UNIT NOT CHECKED');
//                                                 txt.writeln(
//                                                     '==============================');
//                                                 txt.writeln(
//                                                     'Site       : $currentIdSite');
//                                                 txt.writeln(
//                                                     'Tanggal    : $tanggal');
//                                                 txt.writeln(
//                                                   'Total Unit : ${filteredNotChecked.length}',
//                                                 );
//                                                 txt.writeln(
//                                                     '==============================');
//                                                 txt.writeln();

//                                                 for (int index = 0;
//                                                     index <
//                                                         filteredNotChecked
//                                                             .length;
//                                                     index++) {
//                                                   final unit =
//                                                       filteredNotChecked[index];

//                                                   final String unitNumber =
//                                                       unit.unitNumber?.trim() ??
//                                                           '';

//                                                   final String model =
//                                                       unit.model?.trim() ?? '';

//                                                   txt.writeln(
//                                                     '${index + 1}. ${unitNumber.isEmpty ? '-' : unitNumber}',
//                                                   );

//                                                   txt.writeln(
//                                                     '   Model : ${model.isEmpty ? '-' : model}',
//                                                   );

//                                                   txt.writeln(
//                                                     '------------------------------',
//                                                   );
//                                                 }

//                                                 final Directory?
//                                                     downloadDirectory =
//                                                     await DownloadsPath
//                                                         .downloadsDirectory();

//                                                 if (downloadDirectory == null) {
//                                                   throw Exception(
//                                                     'Folder Download tidak ditemukan',
//                                                   );
//                                                 }

//                                                 final String fileDate =
//                                                     DateFormat(
//                                                             'yyyyMMdd_HHmmss')
//                                                         .format(DateTime.now());

//                                                 final String fileName =
//                                                     'not_checked_unit_${currentIdSite}_$fileDate.txt';

//                                                 final File file = File(
//                                                   '${downloadDirectory.path}/$fileName',
//                                                 );

//                                                 await file.writeAsString(
//                                                   txt.toString(),
//                                                   flush: true,
//                                                 );

//                                                 debugPrint(
//                                                   'File berhasil disimpan: ${file.path}',
//                                                 );

//                                                 if (!context.mounted) return;

//                                                 ScaffoldMessenger.of(context)
//                                                     .showSnackBar(
//                                                   SnackBar(
//                                                     backgroundColor:
//                                                         Colors.green,
//                                                     duration: const Duration(
//                                                         seconds: 5),
//                                                     content: Text(
//                                                       'Berhasil export '
//                                                       '${filteredNotChecked.length} unit\n'
//                                                       'Download/$fileName',
//                                                     ),
//                                                   ),
//                                                 );
//                                               } catch (e) {
//                                                 debugPrint(
//                                                   'Gagal export Not Checked: $e',
//                                                 );

//                                                 if (!context.mounted) return;

//                                                 ScaffoldMessenger.of(context)
//                                                     .showSnackBar(
//                                                   SnackBar(
//                                                     backgroundColor: Colors.red,
//                                                     content: Text(
//                                                       'Gagal export data: $e',
//                                                     ),
//                                                   ),
//                                                 );
//                                               }
//                                             },
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: Colors.blue,
//                                         disabledBackgroundColor: Colors.grey,
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 12,
//                                         ),
//                                       ),
//                                       icon: const Icon(
//                                         Icons.file_download_outlined,
//                                         color: Colors.white,
//                                       ),
//                                       label: Text(
//                                         'Export Not Checked (${filteredNotChecked.length})',
//                                         style: getWhiteTextStyle(),
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(
//                                     height: 12,
//                                   ),
//                                   if (lastUpdate != null)
//                                     Column(
//                                       children: [
//                                         Text(
//                                           'Last Update : ${DateFormat('HH:mm:ss dd-MM-yyyy').format(lastUpdate)}',
//                                           textAlign: TextAlign.center,
//                                           style: getBlackTextStyle(
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                         const SizedBox(
//                                           height: 12,
//                                         ),
//                                       ],
//                                     ),
//                                   filteredNotChecked.isEmpty
//                                       ? Text(
//                                           'Empty!',
//                                           textAlign: TextAlign.center,
//                                           style:
//                                               getBlackTextStyle(fontSize: 18),
//                                         )
//                                       : ListView.builder(
//                                           itemCount: filteredNotChecked.length,
//                                           shrinkWrap: true,
//                                           physics:
//                                               const NeverScrollableScrollPhysics(),
//                                           itemBuilder: (context, index) {
//                                             final unit =
//                                                 filteredNotChecked[index];

//                                             return InkWell(
//                                               onTap: (userAccessId != '1' ||
//                                                       homeState
//                                                               .userAccessCompanyId
//                                                               .value ==
//                                                           '1')
//                                                   ? () {
//                                                       Navigator.pushNamed(
//                                                         context,
//                                                         DailyCheckFormPage
//                                                             .routeName,
//                                                         arguments: {
//                                                           'unitNumber':
//                                                               unit.unitNumber,
//                                                           'reccPress':
//                                                               state.reccPress,
//                                                         },
//                                                       );
//                                                     }
//                                                   : null,
//                                               child: Container(
//                                                 margin:
//                                                     const EdgeInsets.symmetric(
//                                                         vertical: 8.0),
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         vertical: 6),
//                                                 decoration: BoxDecoration(
//                                                   color: Colors.white,
//                                                   borderRadius:
//                                                       BorderRadius.circular(12),
//                                                   boxShadow: [
//                                                     BoxShadow(
//                                                       color: Colors.black
//                                                           .withOpacity(0.1),
//                                                       spreadRadius: 2,
//                                                       blurRadius: 5,
//                                                       offset:
//                                                           const Offset(0, 2),
//                                                     ),
//                                                   ],
//                                                 ),
//                                                 child: ListTile(
//                                                   leading: const Icon(
//                                                     Icons.front_loader,
//                                                     color: Colors.orange,
//                                                   ),
//                                                   title: Padding(
//                                                     padding:
//                                                         const EdgeInsets.only(
//                                                             bottom: 4.0),
//                                                     child: Text(
//                                                       unit.unitNumber ?? '',
//                                                       style: getBlackTextStyle(
//                                                         fontWeight:
//                                                             FontWeight.w700,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                   subtitle: Text(
//                                                     unit.model ?? '',
//                                                     style: getGreyTextStyle(
//                                                         grey6A707C),
//                                                   ),
//                                                   trailing: const Icon(
//                                                       Icons.arrow_forward_ios),
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                 ],
//                               );
//                             },
//                           ),

//                           const SizedBox(
//                             height: 12,
//                           ),
//                         ],
//                       );
//                   }
//                   //   case 3:
//                   //     final today = DateTime.now();
//                   //     final todayString =
//                   //         today.toIso8601String().substring(0, 10);

//                   //     return Column(
//                   //       children: [
//                   //         const SizedBox(
//                   //           height: 12,
//                   //         ),

//                   //         // Tombol Get SPM Unit Tire Pressure
//                   //         (userAccessId != '1' &&
//                   //                 homeState.userAccessCompanyId.value == '')
//                   //             ? SizedBox(
//                   //                 width: double.infinity,
//                   //                 child: ElevatedButton(
//                   //                   onPressed: () async {
//                   //                     showDialog<bool>(
//                   //                       context: context,
//                   //                       barrierDismissible: false,
//                   //                       builder: (context) {
//                   //                         return AlertDialog(
//                   //                           title: const Text("Konfirmasi"),
//                   //                           content: const Text(
//                   //                               "Apakah Anda yakin?"),
//                   //                           actions: [
//                   //                             TextButton(
//                   //                               onPressed: () =>
//                   //                                   Navigator.of(context)
//                   //                                       .pop(false),
//                   //                               child: const Text("No"),
//                   //                             ),
//                   //                             ElevatedButton(
//                   //                               onPressed: () async {
//                   //                                 showDialog(
//                   //                                   context: context,
//                   //                                   barrierDismissible: false,
//                   //                                   builder: (context) {
//                   //                                     return const AlertDialog(
//                   //                                       content: Row(
//                   //                                         children: [
//                   //                                           CircularProgressIndicator(),
//                   //                                           SizedBox(width: 20),
//                   //                                           Text(
//                   //                                               "Submitting data, please wait..."),
//                   //                                         ],
//                   //                                       ),
//                   //                                     );
//                   //                                   },
//                   //                                 );

//                   //                                 try {
//                   //                                   final dataSPMJam7 =
//                   //                                       await ApiService
//                   //                                           .getJam7SPM(
//                   //                                               currentIdSite);

//                   //                                   final List<UnitTire>
//                   //                                       dataTireCondition =
//                   //                                       await ApiService
//                   //                                           .getTireCondition(
//                   //                                     currentIdSite,
//                   //                                   );

//                   //                                   final ratingMap =
//                   //                                       <String, String>{};
//                   //                                   final tireSizeMap =
//                   //                                       <String, String>{};
//                   //                                   final hmMap =
//                   //                                       <String, String>{};
//                   //                                   final idInventoryMap =
//                   //                                       <String, String>{};
//                   //                                   final idUnitMap =
//                   //                                       <String, String>{};
//                   //                                   final idDailyMap =
//                   //                                       <String, String>{};

//                   //                                   final today =
//                   //                                       DateTime.now();

//                   //                                   final formattedToday =
//                   //                                       '${today.month.toString().padLeft(2, '0')}'
//                   //                                       '${today.day.toString().padLeft(2, '0')}'
//                   //                                       '${(today.year % 100).toString().padLeft(2, '0')}';

//                   //                                   for (final unit
//                   //                                       in dataTireCondition) {
//                   //                                     final unitNumber =
//                   //                                         unit.unitNumber ?? '';
//                   //                                     final posisi =
//                   //                                         unit.posisi ?? '';

//                   //                                     if (unitNumber
//                   //                                             .isNotEmpty &&
//                   //                                         posisi.isNotEmpty) {
//                   //                                       final key =
//                   //                                           '$unitNumber-$posisi';

//                   //                                       ratingMap[key] =
//                   //                                           unit.rating ?? '';
//                   //                                       tireSizeMap[key] =
//                   //                                           unit.size ?? '';
//                   //                                       hmMap[key] =
//                   //                                           unit.hm ?? '';
//                   //                                       idInventoryMap[key] =
//                   //                                           unit.idinventory ??
//                   //                                               '';
//                   //                                       idUnitMap[key] =
//                   //                                           unit.idUnit ?? '';
//                   //                                       idDailyMap[key] =
//                   //                                           '$unitNumber$posisi$formattedToday$currentIdSite';
//                   //                                     }
//                   //                                   }

//                   //                                   final batch =
//                   //                                       firestore.batch();
//                   //                                   final collection =
//                   //                                       firestore.collection(
//                   //                                           'daily_pressure');

//                   //                                   // Ambil semua data checked hari ini sekali saja,
//                   //                                   // supaya tidak query Firebase di dalam loop.
//                   //                                   final todaySnapshot =
//                   //                                       await collection
//                   //                                           .where('hari',
//                   //                                               isEqualTo:
//                   //                                                   todayString)
//                   //                                           .where('idSite',
//                   //                                               isEqualTo:
//                   //                                                   currentIdSite)
//                   //                                           .get();

//                   //                                   final existingDocMap =
//                   //                                       <String, String>{};

//                   //                                   for (final doc
//                   //                                       in todaySnapshot.docs) {
//                   //                                     final data = doc.data();
//                   //                                     final unit = data['unit']
//                   //                                             ?.toString() ??
//                   //                                         '';

//                   //                                     if (unit.isNotEmpty) {
//                   //                                       existingDocMap[unit] =
//                   //                                           doc.id;
//                   //                                     }
//                   //                                   }

//                   //                                   for (final dataUnit
//                   //                                       in dataSPMJam7) {
//                   //                                     final jsonData =
//                   //                                         dataUnit.toJson();
//                   //                                     final unitNumber =
//                   //                                         dataUnit.devicename ??
//                   //                                             '';

//                   //                                     if (unitNumber.isEmpty) {
//                   //                                       continue;
//                   //                                     }

//                   //                                     final tireCount = jsonData
//                   //                                         .keys
//                   //                                         .where((k) =>
//                   //                                             k.startsWith(
//                   //                                                 'max_p'))
//                   //                                         .length;

//                   //                                     bool hasZeroPressure =
//                   //                                         false;

//                   //                                     for (int pos = 1;
//                   //                                         pos <= tireCount;
//                   //                                         pos++) {
//                   //                                       final pressure =
//                   //                                           double.tryParse(
//                   //                                                 jsonData[
//                   //                                                         'avg_p$pos']
//                   //                                                     .toString(),
//                   //                                               ) ??
//                   //                                               0;

//                   //                                       if (pressure == 0) {
//                   //                                         hasZeroPressure =
//                   //                                             true;
//                   //                                         break;
//                   //                                       }
//                   //                                     }

//                   //                                     if (hasZeroPressure) {
//                   //                                       continue;
//                   //                                     }

//                   //                                     final existingDocId =
//                   //                                         existingDocMap[
//                   //                                             unitNumber];

//                   //                                     final docRef =
//                   //                                         existingDocId != null
//                   //                                             ? collection.doc(
//                   //                                                 existingDocId)
//                   //                                             : collection
//                   //                                                 .doc();

//                   //                                     batch.set(docRef, {
//                   //                                       'idSite': currentIdSite,
//                   //                                       'user':
//                   //                                           user['username'] ??
//                   //                                               'Username',
//                   //                                       'tanggal': DateTime
//                   //                                               .now()
//                   //                                           .toIso8601String(),
//                   //                                       'hari': todayString,
//                   //                                       'jam': DateTime.now()
//                   //                                           .toIso8601String()
//                   //                                           .substring(11, 19),
//                   //                                       'unit': unitNumber,
//                   //                                       'hm': hmMap[
//                   //                                               '$unitNumber-1'] ??
//                   //                                           '',
//                   //                                       'posisi': List.generate(
//                   //                                           tireCount,
//                   //                                           (pIndex) {
//                   //                                         final pos =
//                   //                                             pIndex + 1;
//                   //                                         final key =
//                   //                                             '$unitNumber-$pos';

//                   //                                         return {
//                   //                                           'pos': '$pos',
//                   //                                           'pressure': (double
//                   //                                                       .tryParse(
//                   //                                                     jsonData[
//                   //                                                             'avg_p$pos']
//                   //                                                         .toString(),
//                   //                                                   ) ??
//                   //                                                   0)
//                   //                                               .toStringAsFixed(
//                   //                                                   0),
//                   //                                           'rating': ratingMap[
//                   //                                                   key] ??
//                   //                                               '',
//                   //                                           'adjusmentPressure':
//                   //                                               '0',
//                   //                                           'luka': '',
//                   //                                           'image': '',
//                   //                                           'tireSize':
//                   //                                               tireSizeMap[
//                   //                                                       key] ??
//                   //                                                   '',
//                   //                                           'idInventory':
//                   //                                               idInventoryMap[
//                   //                                                       key] ??
//                   //                                                   '',
//                   //                                           'idUnit': idUnitMap[
//                   //                                                   key] ??
//                   //                                               '',
//                   //                                           'idDaily':
//                   //                                               idDailyMap[
//                   //                                                       key] ??
//                   //                                                   '',
//                   //                                           'kondisi': '',
//                   //                                           'min_press': (double
//                   //                                                       .tryParse(
//                   //                                                     jsonData[
//                   //                                                             'min_p$pos']
//                   //                                                         .toString(),
//                   //                                                   ) ??
//                   //                                                   0)
//                   //                                               .toStringAsFixed(
//                   //                                                   0),
//                   //                                           'max_press': (double
//                   //                                                       .tryParse(
//                   //                                                     jsonData[
//                   //                                                             'max_p$pos']
//                   //                                                         .toString(),
//                   //                                                   ) ??
//                   //                                                   0)
//                   //                                               .toStringAsFixed(
//                   //                                                   0),
//                   //                                           'avg_press': (double
//                   //                                                       .tryParse(
//                   //                                                     jsonData[
//                   //                                                             'avg_p$pos']
//                   //                                                         .toString(),
//                   //                                                   ) ??
//                   //                                                   0)
//                   //                                               .toStringAsFixed(
//                   //                                                   0),
//                   //                                           'temp':
//                   //                                               double.tryParse(
//                   //                                                     jsonData[
//                   //                                                             'avg_t$pos']
//                   //                                                         .toString(),
//                   //                                                   ) ??
//                   //                                                   0,
//                   //                                         };
//                   //                                       }),
//                   //                                       'pit': 'Default',
//                   //                                       'timeLowPressureSPM':
//                   //                                           '',
//                   //                                     });
//                   //                                   }

//                   //                                   await batch.commit();

//                   //                                   Navigator.pop(
//                   //                                       context); // close loading
//                   //                                   Navigator.pop(
//                   //                                       context); // close confirmation

//                   //                                   ScaffoldMessenger.of(
//                   //                                           context)
//                   //                                       .showSnackBar(
//                   //                                     const SnackBar(
//                   //                                       content: Text(
//                   //                                         "Success! Please open menu 'Checked'",
//                   //                                       ),
//                   //                                       backgroundColor:
//                   //                                           Colors.green,
//                   //                                     ),
//                   //                                   );
//                   //                                 } catch (e) {
//                   //                                   Navigator.pop(
//                   //                                       context); // close loading
//                   //                                   Navigator.pop(
//                   //                                       context); // close confirmation

//                   //                                   ScaffoldMessenger.of(
//                   //                                           context)
//                   //                                       .showSnackBar(
//                   //                                     SnackBar(
//                   //                                       content: Text(
//                   //                                         "Error (Data Null) : Please Try Again\n$e",
//                   //                                       ),
//                   //                                       backgroundColor:
//                   //                                           Colors.red,
//                   //                                     ),
//                   //                                   );
//                   //                                 }
//                   //                               },
//                   //                               child: const Text("Yes"),
//                   //                             ),
//                   //                           ],
//                   //                         );
//                   //                       },
//                   //                     );
//                   //                   },
//                   //                   style: ElevatedButton.styleFrom(
//                   //                     backgroundColor: Colors.red,
//                   //                   ),
//                   //                   child: Container(
//                   //                     padding: const EdgeInsets.symmetric(
//                   //                         vertical: 12),
//                   //                     child: Row(
//                   //                       mainAxisAlignment:
//                   //                           MainAxisAlignment.center,
//                   //                       children: [
//                   //                         const Icon(
//                   //                           Icons.send,
//                   //                           color: Colors.white,
//                   //                         ),
//                   //                         const SizedBox(
//                   //                           width: 12,
//                   //                         ),
//                   //                         Text(
//                   //                           'Get SPM Unit Tire Pressure',
//                   //                           style: getWhiteTextStyle(),
//                   //                         ),
//                   //                       ],
//                   //                     ),
//                   //                   ),
//                   //                 ),
//                   //               )
//                   //             : Container(),

//                   //         const SizedBox(
//                   //           height: 12,
//                   //         ),

//                   //         StreamBuilder<QuerySnapshot>(
//                   //           stream: firestore
//                   //               .collection('daily_pressure')
//                   //               .where('hari', isEqualTo: todayString)
//                   //               .where('idSite', isEqualTo: currentIdSite)
//                   //               .snapshots(),
//                   //           builder: (context, snapshot) {
//                   //             if (snapshot.connectionState ==
//                   //                 ConnectionState.waiting) {
//                   //               return const Center(
//                   //                 child: CircularProgressIndicator.adaptive(),
//                   //               );
//                   //             }

//                   //             if (snapshot.hasError) {
//                   //               return Text(
//                   //                 'Error load data: ${snapshot.error}',
//                   //                 style: getBlackTextStyle(fontSize: 14),
//                   //               );
//                   //             }

//                   //             final dailyData = snapshot.data?.docs ?? [];

//                   //             final checkedUnitSet = dailyData
//                   //                 .map((doc) {
//                   //                   final data =
//                   //                       doc.data() as Map<String, dynamic>;
//                   //                   return data['unit']?.toString() ?? '';
//                   //                 })
//                   //                 .where((unit) => unit.isNotEmpty)
//                   //                 .toSet();

//                   //             final notChecked = state.units.where((unit) {
//                   //               final unitNumber = unit.unitNumber ?? '';
//                   //               return !checkedUnitSet.contains(unitNumber);
//                   //             }).toList();

//                   //             final keyword = searchQuery.toLowerCase();

//                   //             final filteredNotChecked =
//                   //                 notChecked.where((unit) {
//                   //               if (keyword.isEmpty) return true;

//                   //               final unitNumber =
//                   //                   unit.unitNumber?.toLowerCase() ?? '';
//                   //               final model = unit.model?.toLowerCase() ?? '';

//                   //               return unitNumber.contains(keyword) ||
//                   //                   model.contains(keyword);
//                   //             }).toList();

//                   //             DateTime? lastUpdate;

//                   //             if (dailyData.isNotEmpty) {
//                   //               final sortedDocs = [...dailyData];

//                   //               sortedDocs.sort((a, b) {
//                   //                 final aData =
//                   //                     a.data() as Map<String, dynamic>;
//                   //                 final bData =
//                   //                     b.data() as Map<String, dynamic>;

//                   //                 final aTanggal =
//                   //                     aData['tanggal']?.toString() ?? '';
//                   //                 final bTanggal =
//                   //                     bData['tanggal']?.toString() ?? '';

//                   //                 return bTanggal.compareTo(aTanggal);
//                   //               });

//                   //               final latestData = sortedDocs.first.data()
//                   //                   as Map<String, dynamic>;

//                   //               final tanggal =
//                   //                   latestData['tanggal']?.toString();

//                   //               if (tanggal != null && tanggal.isNotEmpty) {
//                   //                 lastUpdate = DateTime.tryParse(tanggal);
//                   //               }
//                   //             }

//                   //             return Column(
//                   //               children: [
//                   //                 Text(
//                   //                   'Total Unit : ${filteredNotChecked.length}',
//                   //                   style: getBlackTextStyle(
//                   //                     fontSize: 20,
//                   //                   ),
//                   //                 ),
//                   //                 const SizedBox(
//                   //                   height: 12,
//                   //                 ),
//                   //                 if (lastUpdate != null)
//                   //                   Column(
//                   //                     children: [
//                   //                       Text(
//                   //                         'Last Update : ${DateFormat('HH:mm:ss dd-MM-yyyy').format(lastUpdate)}',
//                   //                         textAlign: TextAlign.center,
//                   //                         style: getBlackTextStyle(
//                   //                           fontSize: 14,
//                   //                         ),
//                   //                       ),
//                   //                       const SizedBox(
//                   //                         height: 12,
//                   //                       ),
//                   //                     ],
//                   //                   ),
//                   //                 filteredNotChecked.isEmpty
//                   //                     ? Text(
//                   //                         'Empty!',
//                   //                         textAlign: TextAlign.center,
//                   //                         style:
//                   //                             getBlackTextStyle(fontSize: 18),
//                   //                       )
//                   //                     : ListView.builder(
//                   //                         itemCount: filteredNotChecked.length,
//                   //                         shrinkWrap: true,
//                   //                         physics:
//                   //                             const NeverScrollableScrollPhysics(),
//                   //                         itemBuilder: (context, index) {
//                   //                           final unit =
//                   //                               filteredNotChecked[index];

//                   //                           return InkWell(
//                   //                             onTap: (userAccessId != '1' ||
//                   //                                     homeState
//                   //                                             .userAccessCompanyId
//                   //                                             .value ==
//                   //                                         '1')
//                   //                                 ? () {
//                   //                                     Navigator.pushNamed(
//                   //                                       context,
//                   //                                       DailyCheckFormPage
//                   //                                           .routeName,
//                   //                                       arguments: {
//                   //                                         'unitNumber':
//                   //                                             unit.unitNumber,
//                   //                                         'reccPress':
//                   //                                             state.reccPress,
//                   //                                       },
//                   //                                     );
//                   //                                   }
//                   //                                 : null,
//                   //                             child: Container(
//                   //                               margin:
//                   //                                   const EdgeInsets.symmetric(
//                   //                                       vertical: 8.0),
//                   //                               padding:
//                   //                                   const EdgeInsets.symmetric(
//                   //                                       vertical: 6),
//                   //                               decoration: BoxDecoration(
//                   //                                 color: Colors.white,
//                   //                                 borderRadius:
//                   //                                     BorderRadius.circular(12),
//                   //                                 boxShadow: [
//                   //                                   BoxShadow(
//                   //                                     color: Colors.black
//                   //                                         .withOpacity(0.1),
//                   //                                     spreadRadius: 2,
//                   //                                     blurRadius: 5,
//                   //                                     offset:
//                   //                                         const Offset(0, 2),
//                   //                                   ),
//                   //                                 ],
//                   //                               ),
//                   //                               child: ListTile(
//                   //                                 leading: const Icon(
//                   //                                   Icons.front_loader,
//                   //                                   color: Colors.orange,
//                   //                                 ),
//                   //                                 title: Padding(
//                   //                                   padding:
//                   //                                       const EdgeInsets.only(
//                   //                                           bottom: 4.0),
//                   //                                   child: Text(
//                   //                                     unit.unitNumber ?? '',
//                   //                                     style: getBlackTextStyle(
//                   //                                       fontWeight:
//                   //                                           FontWeight.w700,
//                   //                                     ),
//                   //                                   ),
//                   //                                 ),
//                   //                                 subtitle: Text(
//                   //                                   unit.model ?? '',
//                   //                                   style: getGreyTextStyle(
//                   //                                       grey6A707C),
//                   //                                 ),
//                   //                                 trailing: const Icon(
//                   //                                     Icons.arrow_forward_ios),
//                   //                               ),
//                   //                             ),
//                   //                           );
//                   //                         },
//                   //                       ),
//                   //               ],
//                   //             );
//                   //           },
//                   //         ),

//                   //         const SizedBox(
//                   //           height: 12,
//                   //         ),
//                   //       ],
//                   //     );
//                   // }

//                   // KODE LAMA YANG BIKIN LEMOT
//                   //   case 3:
//                   //     final notChecked = [];
//                   //     notChecked.clear();
//                   //     notChecked.addAll(state.units);
//                   //     return Column(
//                   //       children: [
//                   //         const SizedBox(
//                   //           height: 12,
//                   //         ),
//                   //         // (userAccessId == '1' || userAccessId == '2')
//                   //         (userAccessId != '1' &&
//                   //                 homeState.userAccessCompanyId.value == '')
//                   //             ? SizedBox(
//                   //                 width: double.infinity,
//                   //                 child: ElevatedButton(
//                   //                     onPressed: () async {
//                   //                       showDialog<bool>(
//                   //                           context: context,
//                   //                           barrierDismissible: false,
//                   //                           builder: (context) {
//                   //                             return AlertDialog(
//                   //                               title: const Text("Konfirmasi"),
//                   //                               content: const Text(
//                   //                                   "Apakah Anda yakin?"),
//                   //                               actions: [
//                   //                                 TextButton(
//                   //                                   onPressed: () => Navigator
//                   //                                           .of(context)
//                   //                                       .pop(false), // pilih No
//                   //                                   child: const Text("No"),
//                   //                                 ),
//                   //                                 ElevatedButton(
//                   //                                   onPressed: () async {
//                   //                                     showDialog(
//                   //                                       context: context,
//                   //                                       barrierDismissible:
//                   //                                           false,
//                   //                                       builder: (context) {
//                   //                                         return const AlertDialog(
//                   //                                           content: Row(
//                   //                                             children: [
//                   //                                               CircularProgressIndicator(),
//                   //                                               SizedBox(
//                   //                                                   width: 20),
//                   //                                               Text(
//                   //                                                   "Submitting data, please wait..."),
//                   //                                             ],
//                   //                                           ),
//                   //                                         );
//                   //                                       },
//                   //                                     );
//                   //                                     try {
//                   //                                       final dataSPMJam7 =
//                   //                                           await ApiService
//                   //                                               .getJam7SPM(
//                   //                                                   currentIdSite);

//                   //                                       final List<UnitTire>
//                   //                                           dataTireCondition =
//                   //                                           await ApiService
//                   //                                               .getTireCondition(
//                   //                                                   currentIdSite);

//                   //                                       final ratingMap =
//                   //                                           <String, String>{};
//                   //                                       final tireSizeMap =
//                   //                                           <String, String>{};
//                   //                                       final hmMap =
//                   //                                           <String, String>{};
//                   //                                       final idInventoryMap =
//                   //                                           <String, String>{};
//                   //                                       final idUnitMap =
//                   //                                           <String, String>{};
//                   //                                       final idDailyMap =
//                   //                                           <String, String>{};
//                   //                                       final today =
//                   //                                           DateTime.now();
//                   //                                       final startOfDay =
//                   //                                           DateTime(
//                   //                                               today.year,
//                   //                                               today.month,
//                   //                                               today.day);
//                   //                                       final endOfDay =
//                   //                                           DateTime(
//                   //                                               today.year,
//                   //                                               today.month,
//                   //                                               today.day,
//                   //                                               23,
//                   //                                               59,
//                   //                                               59);
//                   //                                       final formattedToday =
//                   //                                           '${today.month.toString().padLeft(2, '0')}' // MM
//                   //                                           '${today.day.toString().padLeft(2, '0')}' // DD
//                   //                                           '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

//                   //                                       for (final unit
//                   //                                           in dataTireCondition) {
//                   //                                         if (unit.unitNumber!
//                   //                                                 .isNotEmpty &&
//                   //                                             unit.posisi!
//                   //                                                 .isNotEmpty) {
//                   //                                           final key =
//                   //                                               '${unit.unitNumber}-${unit.posisi}';
//                   //                                           ratingMap[key] =
//                   //                                               unit.rating ??
//                   //                                                   '';
//                   //                                           tireSizeMap[key] =
//                   //                                               unit.size ?? '';
//                   //                                           hmMap[key] =
//                   //                                               unit.hm ?? '';
//                   //                                           idInventoryMap[
//                   //                                                   key] =
//                   //                                               unit.idinventory ??
//                   //                                                   '';
//                   //                                           idUnitMap[key] =
//                   //                                               unit.idUnit ??
//                   //                                                   '';
//                   //                                           idDailyMap[key] =
//                   //                                               '${unit.unitNumber}${unit.posisi}$formattedToday$currentIdSite';
//                   //                                         }
//                   //                                       }

//                   //                                       final batch =
//                   //                                           firestore.batch();
//                   //                                       final collection =
//                   //                                           firestore.collection(
//                   //                                               'daily_pressure');

//                   //                                       for (int i = 0;
//                   //                                           i <
//                   //                                               dataSPMJam7
//                   //                                                   .length;
//                   //                                           i++) {
//                   //                                         final dataUnit =
//                   //                                             dataSPMJam7[i];

//                   //                                         // tire count
//                   //                                         final tireCount = dataUnit
//                   //                                             .toJson()
//                   //                                             .keys
//                   //                                             .where((k) =>
//                   //                                                 k.startsWith(
//                   //                                                     'max_p'))
//                   //                                             .length;

//                   //                                         bool hasZeroPressure =
//                   //                                             false;
//                   //                                         for (int pos = 1;
//                   //                                             pos <= tireCount;
//                   //                                             pos++) {
//                   //                                           final pressure =
//                   //                                               double.tryParse(
//                   //                                                     dataUnit
//                   //                                                         .toJson()[
//                   //                                                             'avg_p$pos']
//                   //                                                         .toString(),
//                   //                                                   ) ??
//                   //                                                   0;
//                   //                                           if (pressure == 0) {
//                   //                                             hasZeroPressure =
//                   //                                                 true;
//                   //                                             break; // stop pengecekan
//                   //                                           }
//                   //                                         }

//                   //                                         if (hasZeroPressure) {
//                   //                                           continue;
//                   //                                         }

//                   //                                         final snapshot = await collection
//                   //                                             .where('unit',
//                   //                                                 isEqualTo:
//                   //                                                     dataUnit
//                   //                                                         .devicename)
//                   //                                             .where('tanggal',
//                   //                                                 isGreaterThanOrEqualTo:
//                   //                                                     startOfDay
//                   //                                                         .toIso8601String())
//                   //                                             .where('tanggal',
//                   //                                                 isLessThanOrEqualTo:
//                   //                                                     endOfDay
//                   //                                                         .toIso8601String())
//                   //                                             .get();

//                   //                                         // Kalau ada snapshot → pakai doc lama, kalau tidak → bikin baru
//                   //                                         final docRef = snapshot
//                   //                                                 .docs
//                   //                                                 .isNotEmpty
//                   //                                             ? collection.doc(
//                   //                                                 snapshot
//                   //                                                     .docs
//                   //                                                     .first
//                   //                                                     .id) // overwrite dok lama
//                   //                                             : collection
//                   //                                                 .doc(); // bikin dok baru

//                   //                                         batch.set(docRef, {
//                   //                                           'idSite':
//                   //                                               currentIdSite ??
//                   //                                                   '',
//                   //                                           'user': user[
//                   //                                                   'username'] ??
//                   //                                               'Username',
//                   //                                           'tanggal': DateTime
//                   //                                                       .now()
//                   //                                                   .toIso8601String() ??
//                   //                                               '',
//                   //                                           'hari': DateTime
//                   //                                                       .now()
//                   //                                                   .toIso8601String()
//                   //                                                   .substring(
//                   //                                                       0,
//                   //                                                       10) ??
//                   //                                               '',
//                   //                                           'jam': DateTime
//                   //                                                       .now()
//                   //                                                   .toIso8601String()
//                   //                                                   .substring(
//                   //                                                       11,
//                   //                                                       19) ??
//                   //                                               '',
//                   //                                           'unit': dataUnit
//                   //                                                   .devicename ??
//                   //                                               '',
//                   //                                           'hm': hmMap[
//                   //                                                   '${dataUnit.devicename}-${i + 1}'] ??
//                   //                                               '',
//                   //                                           'posisi':
//                   //                                               List.generate(
//                   //                                                   tireCount,
//                   //                                                   (pIndex) {
//                   //                                             final pos =
//                   //                                                 pIndex + 1;
//                   //                                             return {
//                   //                                               'pos': '$pos',
//                   //                                               // 'pressure': dataUnit
//                   //                                               //         .toJson()['avg_p$pos'] ??
//                   //                                               //     '0',
//                   //                                               'pressure': (double.tryParse(dataUnit
//                   //                                                           .toJson()[
//                   //                                                               'avg_p$pos']
//                   //                                                           .toString()) ??
//                   //                                                       0)
//                   //                                                   .toStringAsFixed(
//                   //                                                       0),
//                   //                                               'rating': ratingMap[
//                   //                                                   '${dataUnit.devicename}-$pos'],
//                   //                                               'adjusmentPressure':
//                   //                                                   '0',
//                   //                                               'luka': '',
//                   //                                               'image': '',
//                   //                                               'tireSize':
//                   //                                                   tireSizeMap[
//                   //                                                       '${dataUnit.devicename}-$pos'],
//                   //                                               'idInventory':
//                   //                                                   idInventoryMap[
//                   //                                                       '${dataUnit.devicename}-$pos'],
//                   //                                               'idUnit': idUnitMap[
//                   //                                                   '${dataUnit.devicename}-$pos'],
//                   //                                               'idDaily':
//                   //                                                   idDailyMap[
//                   //                                                       '${dataUnit.devicename}-$pos'],
//                   //                                               'kondisi': '',
//                   //                                               'min_press': (double.tryParse(dataUnit
//                   //                                                           .toJson()[
//                   //                                                               'min_p$pos']
//                   //                                                           .toString()) ??
//                   //                                                       0)
//                   //                                                   .toStringAsFixed(
//                   //                                                       0),
//                   //                                               'max_press': (double.tryParse(dataUnit
//                   //                                                           .toJson()[
//                   //                                                               'max_p$pos']
//                   //                                                           .toString()) ??
//                   //                                                       0)
//                   //                                                   .toStringAsFixed(
//                   //                                                       0),
//                   //                                               'avg_press': (double.tryParse(dataUnit
//                   //                                                           .toJson()[
//                   //                                                               'avg_p$pos']
//                   //                                                           .toString()) ??
//                   //                                                       0)
//                   //                                                   .toStringAsFixed(
//                   //                                                       0),
//                   //                                               'temp': (double.tryParse(dataUnit
//                   //                                                       .toJson()[
//                   //                                                           'avg_t$pos']
//                   //                                                       .toString()) ??
//                   //                                                   0),
//                   //                                             };
//                   //                                           }),
//                   //                                           'pit': 'Default',
//                   //                                           'timeLowPressureSPM':
//                   //                                               '',
//                   //                                         });
//                   //                                       }

//                   //                                       await batch.commit();

//                   //                                       Navigator.pop(context);
//                   //                                       Navigator.pop(context);
//                   //                                       ScaffoldMessenger.of(
//                   //                                               context)
//                   //                                           .showSnackBar(
//                   //                                               const SnackBar(
//                   //                                         content: Text(
//                   //                                             "Success! Please open menu 'Checked'"),
//                   //                                         backgroundColor:
//                   //                                             Colors.green,
//                   //                                       ));
//                   //                                     } catch (e) {
//                   //                                       // Tutup semua dialog
//                   //                                       Navigator.pop(
//                   //                                           context); // close submitting
//                   //                                       Navigator.pop(
//                   //                                           context); // close konfirmasi

//                   //                                       ScaffoldMessenger.of(
//                   //                                               context)
//                   //                                           .showSnackBar(
//                   //                                         SnackBar(
//                   //                                           content: Text(
//                   //                                               "Error (Data Null) : Please Try Again"),
//                   //                                           backgroundColor:
//                   //                                               Colors.red,
//                   //                                         ),
//                   //                                       );
//                   //                                     }
//                   //                                   },
//                   //                                   child: const Text("Yes"),
//                   //                                 ),
//                   //                               ],
//                   //                             );
//                   //                           });
//                   //                     },
//                   //                     style: ElevatedButton.styleFrom(
//                   //                         backgroundColor: Colors.red),
//                   //                     child: Container(
//                   //                       padding:
//                   //                           EdgeInsets.symmetric(vertical: 12),
//                   //                       child: Row(
//                   //                         mainAxisAlignment:
//                   //                             MainAxisAlignment.center,
//                   //                         children: [
//                   //                           const Icon(
//                   //                             Icons.send,
//                   //                             color: Colors.white,
//                   //                           ),
//                   //                           const SizedBox(
//                   //                             width: 12,
//                   //                           ),
//                   //                           Text(
//                   //                             'Get SPM Unit Tire Pressure',
//                   //                             style: getWhiteTextStyle(),
//                   //                           ),
//                   //                         ],
//                   //                       ),
//                   //                     )))
//                   //             : Container(),

//                   //         const SizedBox(
//                   //           height: 12,
//                   //         ),
//                   //         StreamBuilder(
//                   //             stream: firestore
//                   //                 .collection('daily_pressure')
//                   //                 .where('tanggal',
//                   //                     isGreaterThanOrEqualTo:
//                   //                         DateTime(now.year, now.month, now.day)
//                   //                             .toIso8601String())
//                   //                 .where('tanggal',
//                   //                     isLessThanOrEqualTo: DateTime(now.year,
//                   //                             now.month, now.day, 23, 59, 59)
//                   //                         .toIso8601String())
//                   //                 .where('idSite', isEqualTo: currentIdSite)
//                   //                 .snapshots(),
//                   //             builder: (context, snapshot) {
//                   //               if (snapshot.connectionState ==
//                   //                   ConnectionState.waiting) {
//                   //                 return CircularProgressIndicator.adaptive();
//                   //               }
//                   //               if (snapshot.connectionState ==
//                   //                   ConnectionState.active) {
//                   //                 final dailyData = snapshot.data?.docs ?? [];

//                   //                 // Mendapatkan field 'unit' dari setiap dokumen
//                   //                 final unitList = dailyData
//                   //                     .map((doc) => doc['unit'])
//                   //                     .toList();

//                   //                 // Mengecek apakah 'unitList' kosong, jika tidak kosong lanjutkan removeWhere
//                   //                 unitList.isNotEmpty
//                   //                     ? notChecked.removeWhere((element) =>
//                   //                         unitList.contains(element.unitNumber))
//                   //                     : [];

//                   //                 log('not checked unit : ${notChecked}');

//                   //                 return Column(
//                   //                   children: [
//                   //                     Text(
//                   //                       'Total Unit : ${notChecked.length ?? 0}',
//                   //                       style: getBlackTextStyle(
//                   //                         fontSize: 20,
//                   //                       ),
//                   //                     ),
//                   //                     const SizedBox(
//                   //                       height: 12,
//                   //                     ),
//                   //                     (snapshot.data?.size != 0)
//                   //                         ? Column(
//                   //                             children: [
//                   //                               Builder(builder: (context) {
//                   //                                 // Parsing string to DateTime object
//                   //                                 DateTime parsedDate =
//                   //                                     DateTime.parse(snapshot
//                   //                                         .data
//                   //                                         ?.docs[snapshot
//                   //                                                 .data!.size -
//                   //                                             1]
//                   //                                         .data()['tanggal']);

//                   //                                 // Formatting DateTime to the desired format
//                   //                                 String formattedDate = DateFormat(
//                   //                                         'HH:mm:ss dd-MM-yyyy')
//                   //                                     .format(parsedDate);
//                   //                                 return Text(
//                   //                                   'Last Update : ${formattedDate}',
//                   //                                   textAlign: TextAlign.center,
//                   //                                   style: getBlackTextStyle(
//                   //                                     fontSize: 14,
//                   //                                   ),
//                   //                                 );
//                   //                               }),
//                   //                               const SizedBox(
//                   //                                 height: 12,
//                   //                               ),
//                   //                             ],
//                   //                           )
//                   //                         : Container(),
//                   //                     (notChecked == null || notChecked.isEmpty)
//                   //                         ? Text(
//                   //                             'Empty!',
//                   //                             textAlign: TextAlign.center,
//                   //                             style: getBlackTextStyle(
//                   //                                 fontSize: 18),
//                   //                           )
//                   //                         : Column(
//                   //                             children:
//                   //                                 (notChecked).map((unit) {
//                   //                               if (searchQuery.isNotEmpty &&
//                   //                                   !unit.unitNumber!
//                   //                                       .toLowerCase()
//                   //                                       .contains(
//                   //                                           searchQuery) &&
//                   //                                   !unit.model!
//                   //                                       .toLowerCase()
//                   //                                       .contains(
//                   //                                           searchQuery)) {
//                   //                                 return Container();
//                   //                               }
//                   //                               return InkWell(
//                   //                                 // onTap: (userAccessId == '1' ||
//                   //                                 //         userAccessId == '2' ||
//                   //                                 //         userAccessId == '3')
//                   //                                 onTap: (userAccessId != '1' ||
//                   //                                         homeState
//                   //                                                 .userAccessCompanyId
//                   //                                                 .value ==
//                   //                                             '1')
//                   //                                     ? () {
//                   //                                         Navigator.pushNamed(
//                   //                                             context,
//                   //                                             DailyCheckFormPage
//                   //                                                 .routeName,
//                   //                                             arguments: {
//                   //                                               'unitNumber': unit
//                   //                                                   .unitNumber,
//                   //                                               'reccPress': state
//                   //                                                   .reccPress,
//                   //                                             });
//                   //                                       }
//                   //                                     : () {},
//                   //                                 child: Container(
//                   //                                   margin:
//                   //                                       EdgeInsets.symmetric(
//                   //                                           vertical: 8.0),
//                   //                                   padding:
//                   //                                       EdgeInsets.symmetric(
//                   //                                           vertical: 6),
//                   //                                   decoration: BoxDecoration(
//                   //                                     color: Colors.white,
//                   //                                     borderRadius:
//                   //                                         BorderRadius.circular(
//                   //                                             12),
//                   //                                     boxShadow: [
//                   //                                       BoxShadow(
//                   //                                         color: Colors.black
//                   //                                             .withOpacity(0.1),
//                   //                                         spreadRadius: 2,
//                   //                                         blurRadius: 5,
//                   //                                         offset: Offset(0, 2),
//                   //                                       ),
//                   //                                     ],
//                   //                                   ),
//                   //                                   child: ListTile(
//                   //                                     leading: Icon(
//                   //                                       Icons.front_loader,
//                   //                                       color: Colors.orange,
//                   //                                     ),
//                   //                                     title: Padding(
//                   //                                       padding:
//                   //                                           const EdgeInsets
//                   //                                               .only(
//                   //                                               bottom: 4.0),
//                   //                                       child: Text(
//                   //                                         '${unit.unitNumber}',
//                   //                                         style:
//                   //                                             getBlackTextStyle(
//                   //                                                 fontWeight:
//                   //                                                     FontWeight
//                   //                                                         .w700),
//                   //                                       ),
//                   //                                     ),
//                   //                                     subtitle: Text(
//                   //                                       '${unit.model}',
//                   //                                       style: getGreyTextStyle(
//                   //                                           grey6A707C),
//                   //                                     ),
//                   //                                     trailing: Icon(Icons
//                   //                                         .arrow_forward_ios),
//                   //                                   ),
//                   //                                 ),
//                   //                               );
//                   //                             }).toList(),
//                   //                           ),
//                   //                   ],
//                   //                 );
//                   //               }

//                   //               return Container();
//                   //             }),
//                   //         const SizedBox(
//                   //           height: 12,
//                   //         ),
//                   //       ],
//                   //     );
//                   // }
//                 }
//                 return Container();
//               }),
//             ],
//           ),
//         ),
//       )),
//       bottomNavigationBar: BottomNavigationBar(
//         selectedItemColor: green00968A,
//         type: BottomNavigationBarType.fixed,
//         items: [
//           BottomNavigationBarItem(
//               icon: Icon(Icons.done_outline_rounded),
//               label: homeState.userAccessCompanyId.value == '1' &&
//                       homeState.userAccessId.value == '1'
//                   ? 'Complete'
//                   : 'Checked (All)'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.error),
//               label: homeState.userAccessCompanyId.value == '1' &&
//                       homeState.userAccessId.value == '1'
//                   ? 'Incomplete Check'
//                   : 'Checked (Low)'),
//           BottomNavigationBarItem(icon: Icon(Icons.list), label: 'All Unit'),
//           BottomNavigationBarItem(
//               icon: Icon(Icons.close), label: 'Not Checked'),
//         ],
//         currentIndex: selectedMenu,
//         // onTap: (index) {
//         //   setState(() {
//         //     selectedMenu = index;
//         //   });
//         // },
//         onTap: (index) {
//           setState(() {
//             selectedMenu = index;

//             if (index == 0 || index == 1 || index == 3) {
//               checkedFuture = getCheckedTodayFuture();
//             }
//           });
//         },
//       ),
//     );
//   }
// }
