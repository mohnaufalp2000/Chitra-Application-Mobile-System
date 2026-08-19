import 'dart:developer';
import 'dart:io';

import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:get/get.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/blocs/daily_check_post/daily_check_post_bloc.dart';
import '../../core/blocs/unit/unit_bloc.dart';
import '../../core/services/api_service.dart';
import '../../core/services/model/daily_press.dart';
import '../../core/services/model/unit_tire.dart';
import '../../core/services/shared_preferences/shared_preferences.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/widgets/appbar_widget.dart';
import 'widget/enum_export_type.dart';
import 'widget/export_excel_button.dart';
import 'widget/select_pit_button.dart';
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
  HomeState homeState = Get.find<HomeState>();
  String searchQuery = '';
  String idSite = '';
  List<String> pit = [];
  int selectedPit = 0;
  List<Map<String, dynamic>> filteredItemTask = [];
  Map<String, dynamic> user = {};
  List<UnitTire> units = [];
  int selectedMenu = 1;
  bool isOnline = false;
  DateTime now = DateTime.now();
  bool _isLoadingSendData = false;
  Future<QuerySnapshot<Map<String, dynamic>>>? historyCheckedFuture;

  @override
  void initState() {
    super.initState();

    final yesterday = DateTime.now().subtract(Duration(days: 1));
    String formattedDate =
        "${yesterday.year}-${(yesterday.month).toString().padLeft(2, '0')}-${(yesterday.day).toString().padLeft(2, '0')}";
    log('tanggal kemarin : $formattedDate');
    getIdSite();
    getUser();
    getUnits();

    switch (idSite) {
      case '5':
        pit.add('All');
        pit.add('PITSTOP AMBON');
        pit.add('PITSTOP BANGKA');
        pit.add('PITSTOP BUTON');
        pit.add('PITSTOP IPD');
        pit.add('PITSTOP MEDAN');
        pit.add('PITSTOP OB2');
        pit.add('PITSTOP SABANG');
        pit.add('WSP');
        pit.add('Other');
        break;
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
        pit.add('TIA');
        pit.add('Serongga');
        pit.add('CSA Selatan');
        pit.add('WS');
        break;
      case '166':
        pit.add('All');
        pit.add('WS');
        pit.add('CSA Bagaspati');
        pit.add('Pondok Operator');
        pit.add('Pit Stop Toll');
        break;
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> getHistoryCheckedFuture() {
    final startDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    final endDate = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      23,
      59,
      59,
    );

    if (selectedPit == 0) {
      return firestore
          .collection('daily_pressure')
          .where(
            'tanggal',
            isGreaterThanOrEqualTo: startDate.toIso8601String(),
          )
          .where(
            'tanggal',
            isLessThanOrEqualTo: endDate.toIso8601String(),
          )
          .where('idSite', isEqualTo: idSite)
          .get();
    }

    return firestore
        .collection('daily_pressure')
        .where(
          'tanggal',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        )
        .where(
          'tanggal',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        )
        .where('idSite', isEqualTo: idSite)
        .where('pit', isEqualTo: pit[selectedPit])
        .get();
  }

  void refreshHistoryCheckedData() {
    setState(() {
      historyCheckedFuture = getHistoryCheckedFuture();
    });
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

  void _showDateRangePicker(
      BuildContext context, Function(List<DateTime>) onDatesSelected) async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1, 1, 1),
      lastDate: DateTime(now.year, 12, 31),
      helpText: 'Select Date Range',
    );

    if (pickedRange != null) {
      List<DateTime> selectedDates = [];
      for (var date = pickedRange.start;
          date.isBefore(pickedRange.end.add(Duration(days: 1)));
          date = date.add(Duration(days: 1))) {
        selectedDates.add(date);
      }
      onDatesSelected(selectedDates);
    }
  }

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
    // idSite = await getIdSitePreferences();
    // if (idSite == '1') {
    //   idSite = await getSelectedIdSitePreferences();
    // }
    idSite = homeState.currentSiteId;

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
    // getUnits();
    // log('count unit : ${units.length}');
    // pit.clear();
    // if (idSite == '52') {
    //   pit.add('All');
    //   pit.add('Utara');
    //   pit.add('Selatan');
    //   pit.add('RML');
    //   pit.add('WS');
    // }

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
                DateTime.now().subtract(Duration(days: 60)),
                height: 100,
                width: 80,
                daysCount: 60,
                locale: 'id_ID',
                initialSelectedDate: DateTime.now().subtract(Duration(days: 1)),
                selectionColor: green00968A,
                selectedTextColor: white,
                // onDateChange: (date) {
                //   log('tanggal terpilih : $date');
                //   setState(() {
                //     selectedDate = date;
                //   });
                // },
                onDateChange: (date) {
                  log('tanggal terpilih : $date');

                  setState(() {
                    selectedDate = date;
                    historyCheckedFuture = getHistoryCheckedFuture();
                  });
                },
                dateTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: grey6A707C,
                ),
              ),
            ),
            Builder(builder: (context) {
              if (selectedMenu == 0) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: ExportExcelButton(
                        user: user,
                        pit: pit,
                        selectedPit: selectedPit,
                        filteredItemTask: filteredItemTask,
                        idSite: idSite,
                        date:
                            "${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.year}",
                        type: ExportType.multipleDay,
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () async {
                                List<Map<String, dynamic>> itemTask = [];
                                _showDateRangePicker(context,
                                    (selectedMonths) async {
                                  setState(() {
                                    _isLoadingSendData =
                                        true; // Tampilkan loading
                                  });
                                  try {
                                    final firstPicked = selectedMonths[0];
                                    final lastPicked = selectedMonths[
                                        selectedMonths.length - 1];

                                    // Cek apakah bulan berbeda
                                    if (firstPicked.month != lastPicked.month ||
                                        firstPicked.year != lastPicked.year) {
                                      // Tampilkan modal dialog jika bulan berbeda
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text("Invalid Selection!",
                                              style: getRedTextStyle(
                                                  fontSize: 24)),
                                          content: Text(
                                              "Please select a date within the same month!",
                                              style: getBlackTextStyle()),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(
                                                    context); // Tutup modal
                                              },
                                              child: Text("OK",
                                                  style: getBlackTextStyle()),
                                            ),
                                          ],
                                        ),
                                      );
                                      return;
                                    }

                                    final snapshot = await firestore
                                        .collection('daily_pressure')
                                        .where('idSite',
                                            isEqualTo: filteredItemTask[0]
                                                ['idSite'])
                                        .where('tanggal',
                                            isGreaterThanOrEqualTo: DateTime(
                                                    firstPicked.year,
                                                    firstPicked.month,
                                                    firstPicked.day)
                                                .toIso8601String())
                                        .where('tanggal',
                                            isLessThanOrEqualTo: DateTime(
                                                    lastPicked.year,
                                                    lastPicked.month,
                                                    lastPicked.day,
                                                    23,
                                                    59,
                                                    59)
                                                .toIso8601String())
                                        .get();

                                    snapshot.docs.forEach((data) {
                                      final dataDaily =
                                          data.data() as Map<String, dynamic>;
                                      itemTask.add(dataDaily);
                                    });

                                    final countAllTire =
                                        await ApiService.getCachedCountAllTire(
                                            idSite: idSite);
                                    final allUnit =
                                        await ApiService.getCachedUnits(
                                            idSite: idSite);

                                    final allTireSize =
                                        await ApiService.getCachedTireSize(
                                            idSite: idSite);

                                    context.read<DailyCheckPostBloc>().add(
                                        DailyCheckPostEvent(
                                            dailyCheck: itemTask,
                                            countAllTire: countAllTire,
                                            allUnit: allUnit,
                                            allTireSize: allTireSize,
                                            typeSend: 'multiple'));

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      backgroundColor: green00968A,
                                      content: Text(
                                        'Successful Save Data!',
                                        style: getWhiteTextStyle(),
                                      ),
                                    ));
                                  } catch (e) {
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text('Error: $e'),
                                    ));
                                  } finally {
                                    setState(() {
                                      _isLoadingSendData =
                                          false; // Sembunyikan loading
                                    });
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: green00968A),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    _isLoadingSendData
                                        ? CircularProgressIndicator(
                                            color: Colors.white,
                                          )
                                        : Text(
                                            'Send Data to CTS (Selected Date)',
                                            style: getWhiteTextStyle(),
                                          ),
                                  ],
                                ),
                              ))),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                  ],
                );
              }
              return Container();
            }),
            FutureBuilder(
                future: getActualIdSite(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }

                  final data = snapshot.data;
                  log('id site future builder : $data');

                  if (data != '1' && data != '2' && data != '3') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: SizedBox(
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
              height: 12,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Builder(builder: (context) {
                if (selectedMenu == 0) {
                  return Column(
                    children: [
                      ExportExcelButton(
                        user: user,
                        pit: pit,
                        selectedPit: selectedPit,
                        filteredItemTask: filteredItemTask,
                        idSite: idSite,
                        date:
                            "${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}-${selectedDate.year}",
                        type: ExportType.oneDay,
                      ),
                      const SizedBox(
                        height: 12,
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
                                  final countAllTire =
                                      await ApiService.getCachedCountAllTire(
                                          idSite: idSite);
                                  final allUnit =
                                      await ApiService.getCachedUnits(
                                          idSite: idSite);
                                  final allTireSize =
                                      await ApiService.getCachedTireSize(
                                          idSite: idSite);

                                  context.read<DailyCheckPostBloc>().add(
                                      DailyCheckPostEvent(
                                          dailyCheck: filteredItemTask,
                                          countAllTire: countAllTire,
                                          allUnit: allUnit,
                                          allTireSize: allTireSize,
                                          typeSend: 'single'));
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    backgroundColor: green00968A,
                                    content: Text(
                                      'Successful Save Data!',
                                      style: getWhiteTextStyle(),
                                    ),
                                  ));
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: green00968A),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      'Send Data to CTS (One Day)',
                                      style: getWhiteTextStyle(),
                                    ),
                                  ],
                                ),
                              ))),
                    ],
                  );
                }
                return Container();
              }),
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
                        historyCheckedFuture ??= getHistoryCheckedFuture();

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
                                    historyCheckedFuture =
                                        getHistoryCheckedFuture();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: refreshHistoryCheckedData,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueGrey,
                                  ),
                                  child: Text(
                                    'Refresh History Data',
                                    style: getWhiteTextStyle(),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                              future: historyCheckedFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator.adaptive(),
                                  );
                                }

                                if (snapshot.hasError) {
                                  return Text(
                                    'Error load history data: ${snapshot.error}',
                                    style: getBlackTextStyle(fontSize: 14),
                                  );
                                }

                                final docs = snapshot.data?.docs ?? [];

                                final rawData = docs.map((doc) {
                                  return doc.data();
                                }).toList();

                                rawData.sort((a, b) {
                                  final aTanggal =
                                      a['tanggal']?.toString() ?? '';
                                  final bTanggal =
                                      b['tanggal']?.toString() ?? '';
                                  return bTanggal.compareTo(aTanggal);
                                });

                                // DISTINCT BY UNIT
                                // Jika ada unit duplikat dalam 1 hari,
                                // yang dipakai adalah data terbaru berdasarkan tanggal.
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

                                final distinctDaily =
                                    distinctMap.values.toList();

                                final keyword = searchQuery.toLowerCase();

                                final filteredData =
                                    distinctDaily.where((data) {
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
                                  final tanggal = distinctDaily.first['tanggal']
                                      ?.toString();

                                  if (tanggal != null && tanggal.isNotEmpty) {
                                    lastUpdate = DateTime.tryParse(tanggal);
                                  }
                                }

                                return Column(
                                  children: [
                                    Text(
                                      'Total Unit : ${filteredData.length}',
                                      style: getBlackTextStyle(
                                        fontSize: 20,
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
                                    filteredData.isEmpty
                                        ? Text(
                                            'Empty!',
                                            textAlign: TextAlign.center,
                                            style:
                                                getBlackTextStyle(fontSize: 18),
                                          )
                                        : Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12.0),
                                            child: ListView.builder(
                                              itemCount: filteredData.length,
                                              shrinkWrap: true,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              itemBuilder: (context, index) {
                                                final dailyMap =
                                                    filteredData[index];

                                                final String unit =
                                                    dailyMap['unit']
                                                            ?.toString() ??
                                                        'No Unit';
                                                final String pitText =
                                                    dailyMap['pit']
                                                            ?.toString() ??
                                                        'Default';
                                                final String userText =
                                                    dailyMap['user']
                                                            ?.toString() ??
                                                        'No Name';
                                                final String tanggal =
                                                    dailyMap['tanggal']
                                                            ?.toString() ??
                                                        '';
                                                final String hm = dailyMap['hm']
                                                        ?.toString() ??
                                                    '0';

                                                final positionList =
                                                    dailyMap['posisi']
                                                            as List<dynamic>? ??
                                                        [];

                                                return Card(
                                                  elevation: 2,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                  color: green00968A,
                                                  child: Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 12,
                                                      vertical: 24,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: green00968A,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: ExpansionTile(
                                                      tilePadding:
                                                          EdgeInsets.zero,
                                                      childrenPadding:
                                                          EdgeInsets.zero,
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
                                                          Expanded(
                                                            child: Text(
                                                              unit +
                                                                  '${((pitText != 'Default') ? '\n$pitText' : '')}',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                fontWeight:
                                                                    w700,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      trailing: const SizedBox(
                                                        width: 90,
                                                        child: Icon(Icons
                                                            .arrow_drop_down),
                                                      ),
                                                      children: [
                                                        const SizedBox(
                                                            height: 12),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Name',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                      fontSize:
                                                                          18),
                                                            ),
                                                            SizedBox(
                                                              width: 250,
                                                              child: Text(
                                                                userText,
                                                                textAlign:
                                                                    TextAlign
                                                                        .end,
                                                                style:
                                                                    getWhiteTextStyle(
                                                                  fontWeight:
                                                                      w700,
                                                                  fontSize: 18,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Tanggal',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                      fontSize:
                                                                          18),
                                                            ),
                                                            Text(
                                                              tanggal.isNotEmpty
                                                                  ? tanggal
                                                                      .split(
                                                                          'T')[0]
                                                                  : 'No Date',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                fontWeight:
                                                                    w700,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Waktu',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                      fontSize:
                                                                          18),
                                                            ),
                                                            Text(
                                                              (tanggal.isNotEmpty &&
                                                                      tanggal.contains(
                                                                          'T'))
                                                                  ? tanggal
                                                                      .split('T')[
                                                                          1]
                                                                      .substring(
                                                                          0, 5)
                                                                  : 'No Time',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                fontWeight:
                                                                    w700,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              (idSite ==
                                                                      bmbhauling
                                                                          .idSite)
                                                                  ? 'KM Unit'
                                                                  : 'HM Unit',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                      fontSize:
                                                                          18),
                                                            ),
                                                            Text(
                                                              hm,
                                                              style:
                                                                  getWhiteTextStyle(
                                                                fontWeight:
                                                                    w700,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              'Pit',
                                                              style:
                                                                  getWhiteTextStyle(
                                                                      fontSize:
                                                                          18),
                                                            ),
                                                            Text(
                                                              pitText,
                                                              style:
                                                                  getWhiteTextStyle(
                                                                fontWeight:
                                                                    w700,
                                                                fontSize: 18,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(
                                                            height: 12),
                                                        Column(
                                                          children: positionList
                                                              .map((pl) {
                                                            final Map<String,
                                                                    dynamic>
                                                                posData = Map<
                                                                    String,
                                                                    dynamic>.from(
                                                              pl as Map,
                                                            );

                                                            List<dynamic> luka =
                                                                [];
                                                            final dynamic
                                                                rawLuka =
                                                                posData['luka'];

                                                            if (rawLuka
                                                                is List) {
                                                              luka = rawLuka;
                                                            } else if (rawLuka
                                                                    is String &&
                                                                rawLuka
                                                                    .isNotEmpty) {
                                                              luka.add(rawLuka);
                                                            }

                                                            final String pos =
                                                                posData['pos']
                                                                        ?.toString() ??
                                                                    '-';

                                                            final String
                                                                pressure =
                                                                posData['pressure']
                                                                        ?.toString() ??
                                                                    '0';

                                                            final String
                                                                adjPressure =
                                                                posData['adjusmentPressure']
                                                                        ?.toString() ??
                                                                    '';

                                                            final String
                                                                rating =
                                                                posData['rating']
                                                                        ?.toString() ??
                                                                    '';

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
                                                                      'Pos. $pos',
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
                                                                      mainAxisAlignment:
                                                                          MainAxisAlignment
                                                                              .center,
                                                                      children: [
                                                                        Text(
                                                                          '$pressure Psi',
                                                                          style:
                                                                              getWhiteTextStyle(
                                                                            fontWeight:
                                                                                w700,
                                                                            fontSize:
                                                                                18,
                                                                          ),
                                                                        ),
                                                                        if (adjPressure.isNotEmpty &&
                                                                            adjPressure !=
                                                                                '0')
                                                                          Text(
                                                                            '$adjPressure Psi (Adj. Pressure)',
                                                                            style:
                                                                                getWhiteTextStyle(
                                                                              fontWeight: w700,
                                                                              fontSize: 18,
                                                                            ),
                                                                          ),
                                                                        if (luka
                                                                            .isNotEmpty)
                                                                          Text(
                                                                            luka.join('\n'),
                                                                            textAlign:
                                                                                TextAlign.end,
                                                                            style:
                                                                                getWhiteTextStyle(
                                                                              fontWeight: w700,
                                                                              fontSize: 18,
                                                                            ),
                                                                          ),
                                                                        if (rating
                                                                            .isNotEmpty)
                                                                          Text(
                                                                            'Rating $rating',
                                                                            style:
                                                                                getWhiteTextStyle(
                                                                              fontWeight: w700,
                                                                              fontSize: 18,
                                                                            ),
                                                                          ),
                                                                        if (idSite ==
                                                                                '33' &&
                                                                            posData['tireAccessories'] !=
                                                                                null)
                                                                          Column(
                                                                            crossAxisAlignment:
                                                                                CrossAxisAlignment.end,
                                                                            children: [
                                                                              Text(
                                                                                'Tire Accessories',
                                                                                style: getWhiteTextStyle(
                                                                                  fontWeight: w700,
                                                                                  fontSize: 14,
                                                                                ),
                                                                              ),
                                                                              const SizedBox(
                                                                                height: 6,
                                                                              ),
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                                                children: posData['tireAccessories'].map<Widget>((acc) {
                                                                                  return Column(
                                                                                    crossAxisAlignment: CrossAxisAlignment.end,
                                                                                    children: [
                                                                                      Row(
                                                                                        children: [
                                                                                          Text(
                                                                                            acc['name'] + ' (' + acc['condition'] + '${(acc['remark'] != '') ? ': ${acc['remark']}' : ''})',
                                                                                            textAlign: TextAlign.right,
                                                                                            style: getWhiteTextStyle(
                                                                                              fontWeight: w500,
                                                                                              fontSize: 14,
                                                                                            ),
                                                                                          ),
                                                                                        ],
                                                                                      ),
                                                                                      const SizedBox(
                                                                                        height: 6,
                                                                                      ),
                                                                                      if (acc['image'].isNotEmpty && acc['image'] != 'image.png' && acc['image'] != '')
                                                                                        InkWell(
                                                                                          onTap: () async {
                                                                                            await showDialog(
                                                                                              context: context,
                                                                                              barrierDismissible: true,
                                                                                              builder: (_) {
                                                                                                return Dialog(
                                                                                                  backgroundColor: Colors.transparent,
                                                                                                  elevation: 0,
                                                                                                  child: Center(
                                                                                                    child: Column(
                                                                                                      mainAxisSize: MainAxisSize.min,
                                                                                                      children: [
                                                                                                        Stack(
                                                                                                          children: [
                                                                                                            Container(
                                                                                                              width: MediaQuery.of(context).size.width * 0.6,
                                                                                                              height: MediaQuery.of(context).size.height * 0.6,
                                                                                                              decoration: BoxDecoration(
                                                                                                                borderRadius: BorderRadius.circular(12),
                                                                                                              ),
                                                                                                              clipBehavior: Clip.antiAlias,
                                                                                                              child: Image.network(
                                                                                                                acc['image'],
                                                                                                                fit: BoxFit.contain,
                                                                                                              ),
                                                                                                            ),
                                                                                                            Positioned(
                                                                                                              right: 8,
                                                                                                              top: 8,
                                                                                                              child: InkWell(
                                                                                                                onTap: () => Navigator.of(context).pop(),
                                                                                                                borderRadius: BorderRadius.circular(20),
                                                                                                                child: Container(
                                                                                                                  padding: const EdgeInsets.all(6),
                                                                                                                  decoration: const BoxDecoration(
                                                                                                                    color: Colors.black45,
                                                                                                                    shape: BoxShape.circle,
                                                                                                                  ),
                                                                                                                  child: const Icon(
                                                                                                                    LucideIcons.x,
                                                                                                                    color: Colors.white,
                                                                                                                    size: 20,
                                                                                                                  ),
                                                                                                                ),
                                                                                                              ),
                                                                                                            ),
                                                                                                          ],
                                                                                                        ),
                                                                                                        const SizedBox(height: 12),
                                                                                                        Container(
                                                                                                          padding: const EdgeInsets.all(8),
                                                                                                          decoration: BoxDecoration(
                                                                                                            color: Colors.white,
                                                                                                            borderRadius: BorderRadius.circular(16),
                                                                                                          ),
                                                                                                          child: Text(
                                                                                                            '#$unit Pos. $pos | ${acc['name']} ${acc['condition']} ${(acc['remark'] != '') ? ': ${acc['remark']}' : ''}',
                                                                                                            style: getBlackTextStyle(
                                                                                                              fontWeight: w700,
                                                                                                            ),
                                                                                                            textAlign: TextAlign.center,
                                                                                                          ),
                                                                                                        ),
                                                                                                      ],
                                                                                                    ),
                                                                                                  ),
                                                                                                );
                                                                                              },
                                                                                            );
                                                                                          },
                                                                                          child: SizedBox(
                                                                                            width: 150,
                                                                                            height: 100,
                                                                                            child: Image.network(
                                                                                              acc['image'],
                                                                                              fit: BoxFit.cover,
                                                                                            ),
                                                                                          ),
                                                                                        ),
                                                                                    ],
                                                                                  );
                                                                                }).toList(),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                      ],
                                                                    ),
                                                                  ],
                                                                ),
                                                                const SizedBox(
                                                                    height: 12),
                                                                Divider(
                                                                  color: white,
                                                                  thickness:
                                                                      1.5,
                                                                ),
                                                              ],
                                                            );
                                                          }).toList(),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                  ],
                                );
                              },
                            ),
                          ],
                        );
                      // case 0:
                      //   return Column(
                      //     children: [
                      //       const SizedBox(
                      //         height: 12,
                      //       ),
                      //       Padding(
                      //         padding:
                      //             const EdgeInsets.symmetric(horizontal: 12.0),
                      //         child: SelectPitButton(
                      //             pit: pit,
                      //             selectedPit: selectedPit,
                      //             onSelectedPitChanged: (index) {
                      //               setState(() {
                      //                 selectedPit = index;
                      //               });
                      //             }),
                      //       ),
                      //       const SizedBox(
                      //         height: 12,
                      //       ),
                      //       StreamBuilder(
                      //           stream: firestore
                      //               .collection('daily_pressure')
                      //               .where('tanggal',
                      //                   isGreaterThanOrEqualTo: DateTime(
                      //                           selectedDate.year,
                      //                           selectedDate.month,
                      //                           selectedDate.day)
                      //                       .toIso8601String())
                      //               .where('tanggal',
                      //                   isLessThanOrEqualTo: DateTime(
                      //                           selectedDate.year,
                      //                           selectedDate.month,
                      //                           selectedDate.day,
                      //                           23,
                      //                           59,
                      //                           59)
                      //                       .toIso8601String())
                      //               .where('idSite', isEqualTo: idSite)
                      //               .orderBy('tanggal', descending: true)
                      //               .snapshots(),
                      //           builder: (context, snapshot) {
                      //             if (snapshot.connectionState ==
                      //                 ConnectionState.waiting) {
                      //               return CircularProgressIndicator.adaptive();
                      //             }
                      //             if (snapshot.connectionState ==
                      //                 ConnectionState.active) {
                      //               // final allData = snapshot.data?.docs
                      //               //     .map((doc) => DailyPress.fromFirestore(
                      //               //         doc.data() as Map<String, dynamic>))
                      //               //     .toList();

                      //               // final distinctDaily =
                      //               //     Set<DailyPress>.from(allData ?? [])
                      //               //         .toList();

                      //               // ---------------------------------------- //
                      //               final allData = snapshot.data?.docs
                      //                       .map((doc) =>
                      //                           DailyPress.fromFirestore(doc
                      //                                   .data()
                      //                               as Map<String, dynamic>))
                      //                       .toList() ??
                      //                   [];

                      //               // Buat map sementara untuk menyimpan data terbaru per unit
                      //               final Map<String, DailyPress>
                      //                   latestDataByUnit = {};

                      //               for (var item in allData) {
                      //                 final existing =
                      //                     latestDataByUnit[item.unit];
                      //                 if (existing == null ||
                      //                     DateTime.parse(item.tanggal).isAfter(
                      //                         DateTime.parse(
                      //                             existing.tanggal))) {
                      //                   latestDataByUnit[item.unit] = item;
                      //                 }
                      //               }

                      //               // Ambil hasil akhir (data unik dengan jam terbaru)
                      //               final distinctDaily =
                      //                   latestDataByUnit.values.toList();

                      //               final tmpDailyData =
                      //                   snapshot.data?.docs ?? [];

                      //               final dailyData =
                      //                   distinctDaily.where((doc) {
                      //                 // pilih all pit
                      //                 if (pit.isNotEmpty) {
                      //                   if (pit[selectedPit] == 'All') {
                      //                     return doc.idSite == idSite;
                      //                   }

                      //                   // ada pit
                      //                   if (doc.pit != 'Default') {
                      //                     return doc.idSite == idSite &&
                      //                         doc.pit == pit[selectedPit];
                      //                   }
                      //                 }

                      //                 // tidak ada pit
                      //                 return doc.idSite == idSite;
                      //               }).toList();

                      //               // untuk data export excel
                      //               filteredItemTask.clear();
                      //               filteredItemTask.clear();
                      //               dailyData.forEach((item) {
                      //                 log('perulangan item: $item');
                      //                 Map<String, dynamic> cast =
                      //                     item.toFirestore();
                      //                 if (cast['unit'] == 'CO2386') {
                      //                   log('co2386: $cast');
                      //                 }

                      //                 filteredItemTask.add(cast);
                      //               });

                      //               log('list selected 1 = ${tmpDailyData.length}');
                      //               log('list selected 2 = ${filteredItemTask}');

                      //               return Column(
                      //                 children: [
                      //                   Text(
                      //                     'Total Unit : ${dailyData.length ?? 0}',
                      //                     style: getBlackTextStyle(
                      //                       fontSize: 20,
                      //                     ),
                      //                   ),
                      //                   const SizedBox(
                      //                     height: 12,
                      //                   ),
                      //                   (snapshot.data?.size != 0)
                      //                       ? Column(
                      //                           children: [
                      //                             Builder(builder: (context) {
                      //                               // Parsing string to DateTime object
                      //                               DateTime parsedDate =
                      //                                   DateTime.parse(snapshot
                      //                                       .data
                      //                                       ?.docs[snapshot
                      //                                               .data!
                      //                                               .size -
                      //                                           1]
                      //                                       .data()['tanggal']);

                      //                               // Formatting DateTime to the desired format
                      //                               String formattedDate =
                      //                                   DateFormat(
                      //                                           'HH:mm:ss dd-MM-yyyy')
                      //                                       .format(parsedDate);
                      //                               return Text(
                      //                                 'Last Update : ${formattedDate}',
                      //                                 textAlign:
                      //                                     TextAlign.center,
                      //                                 style: getBlackTextStyle(
                      //                                   fontSize: 14,
                      //                                 ),
                      //                               );
                      //                             }),
                      //                             const SizedBox(
                      //                               height: 12,
                      //                             ),
                      //                           ],
                      //                         )
                      //                       : Container(),
                      //                 ],
                      //               );
                      //             }

                      //             return Container();
                      //           }),
                      //       Padding(
                      //         padding:
                      //             const EdgeInsets.symmetric(horizontal: 12.0),
                      //         child: PaginateFirestore(
                      //           query: selectedPit == 0
                      //               ? firestore
                      //                   .collection('daily_pressure')
                      //                   .where('tanggal',
                      //                       isGreaterThanOrEqualTo:
                      //                           DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
                      //                               .toIso8601String())
                      //                   .where('tanggal',
                      //                       isLessThanOrEqualTo: DateTime(
                      //                               selectedDate.year,
                      //                               selectedDate.month,
                      //                               selectedDate.day,
                      //                               23,
                      //                               59,
                      //                               59)
                      //                           .toIso8601String())
                      //                   .where('idSite', isEqualTo: idSite)
                      //                   .orderBy('tanggal', descending: true)
                      //               : firestore
                      //                   .collection('daily_pressure')
                      //                   .where('tanggal',
                      //                       isGreaterThanOrEqualTo:
                      //                           DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
                      //                               .toIso8601String())
                      //                   .where('tanggal',
                      //                       isLessThanOrEqualTo:
                      //                           DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59)
                      //                               .toIso8601String())
                      //                   .where('idSite', isEqualTo: idSite)
                      //                   .where('pit', isEqualTo: pit[selectedPit])
                      //                   .orderBy('tanggal', descending: true),
                      //           key: ValueKey(selectedDate),
                      //           itemBuilderType: PaginateBuilderType.listView,
                      //           shrinkWrap: true,
                      //           physics: NeverScrollableScrollPhysics(),
                      //           itemsPerPage: 10,
                      //           isLive: true,
                      //           initialLoader: const Center(
                      //               child:
                      //                   CircularProgressIndicator.adaptive()),
                      //           bottomLoader: const Center(
                      //               child:
                      //                   CircularProgressIndicator.adaptive()),
                      //           itemBuilder:
                      //               (context, snapshot, firebaseIndex) {
                      //             final Map<String, dynamic> dailyMap =
                      //                 snapshot[firebaseIndex].data()
                      //                     as Map<String, dynamic>;

                      //             final String unit =
                      //                 dailyMap['unit'] ?? 'No Unit';
                      //             final String pit =
                      //                 dailyMap['pit'] ?? 'Default';
                      //             final String user =
                      //                 dailyMap['user'] ?? 'No Name';
                      //             final String tanggal =
                      //                 dailyMap['tanggal'] ?? '';
                      //             final String hm = dailyMap['hm'] ?? '0';
                      //             final positionList =
                      //                 dailyMap['posisi'] as List<dynamic>? ??
                      //                     [];

                      //             if (selectedPit != 0) {
                      //               if (pit != this.pit[selectedPit]) {
                      //                 return Container();
                      //               }
                      //             }

                      //             if (searchQuery.isNotEmpty &&
                      //                 !unit.toLowerCase().contains(
                      //                     searchQuery.toLowerCase())) {
                      //               return Container();
                      //             }

                      //             return Card(
                      //                 elevation: 2,
                      //                 shape: RoundedRectangleBorder(
                      //                   borderRadius: BorderRadius.circular(12),
                      //                 ),
                      //                 color: green00968A,
                      //                 child: Container(
                      //                   width: double.infinity,
                      //                   padding: EdgeInsets.symmetric(
                      //                       horizontal: 12, vertical: 24),
                      //                   decoration: BoxDecoration(
                      //                     color: green00968A,
                      //                     borderRadius:
                      //                         BorderRadius.circular(12),
                      //                   ),
                      //                   child: ExpansionTile(
                      //                     tilePadding: EdgeInsets.zero,
                      //                     childrenPadding: EdgeInsets.all(0),
                      //                     title: Row(
                      //                       children: [
                      //                         Icon(
                      //                           Icons.task,
                      //                           color: white,
                      //                           size: 36,
                      //                         ),
                      //                         const SizedBox(
                      //                           width: 12,
                      //                         ),
                      //                         Text(
                      //                           unit +
                      //                               '${((pit != 'Default') ? '\n' + pit : '')}',
                      //                           style: getWhiteTextStyle(
                      //                               fontWeight: w700,
                      //                               fontSize: 18),
                      //                         )
                      //                       ],
                      //                     ),
                      //                     trailing: SizedBox(
                      //                       width: 90,
                      //                       child: Icon(Icons.arrow_drop_down),
                      //                     ),
                      //                     children: [
                      //                       const SizedBox(height: 12),
                      //                       Row(
                      //                         mainAxisAlignment:
                      //                             MainAxisAlignment
                      //                                 .spaceBetween,
                      //                         children: [
                      //                           Text('Name',
                      //                               style: getWhiteTextStyle(
                      //                                   fontSize: 18)),
                      //                           Container(
                      //                             width: 250,
                      //                             child: Text(user,
                      //                                 textAlign: TextAlign.end,
                      //                                 style: getWhiteTextStyle(
                      //                                     fontWeight: w700,
                      //                                     fontSize: 18)),
                      //                           ),
                      //                         ],
                      //                       ),
                      //                       const SizedBox(height: 12),
                      //                       Row(
                      //                         mainAxisAlignment:
                      //                             MainAxisAlignment
                      //                                 .spaceBetween,
                      //                         children: [
                      //                           Text('Tanggal',
                      //                               style: getWhiteTextStyle(
                      //                                   fontSize: 18)),
                      //                           Text(
                      //                               tanggal.isNotEmpty
                      //                                   ? tanggal.split('T')[0]
                      //                                   : 'No Date',
                      //                               style: getWhiteTextStyle(
                      //                                   fontWeight: w700,
                      //                                   fontSize: 18)),
                      //                         ],
                      //                       ),
                      //                       const SizedBox(height: 12),
                      //                       Row(
                      //                         mainAxisAlignment:
                      //                             MainAxisAlignment
                      //                                 .spaceBetween,
                      //                         children: [
                      //                           Text('Waktu',
                      //                               style: getWhiteTextStyle(
                      //                                   fontSize: 18)),
                      //                           Text(
                      //                               (tanggal.isNotEmpty &&
                      //                                       tanggal
                      //                                           .contains('T'))
                      //                                   ? tanggal
                      //                                       .split('T')[1]
                      //                                       .substring(0, 5)
                      //                                   : 'No Time',
                      //                               style: getWhiteTextStyle(
                      //                                   fontWeight: w700,
                      //                                   fontSize: 18)),
                      //                         ],
                      //                       ),
                      //                       const SizedBox(height: 12),
                      //                       Row(
                      //                         mainAxisAlignment:
                      //                             MainAxisAlignment
                      //                                 .spaceBetween,
                      //                         children: [
                      //                           Text(
                      //                             (idSite == bmbhauling.idSite)
                      //                                 ? 'KM Unit'
                      //                                 : 'HM Unit',
                      //                             style: getWhiteTextStyle(
                      //                                 fontSize: 18),
                      //                           ),
                      //                           Text(hm,
                      //                               style: getWhiteTextStyle(
                      //                                   fontWeight: w700,
                      //                                   fontSize: 18)),
                      //                         ],
                      //                       ),
                      //                       const SizedBox(height: 12),
                      //                       Row(
                      //                         mainAxisAlignment:
                      //                             MainAxisAlignment
                      //                                 .spaceBetween,
                      //                         children: [
                      //                           Text('Pit',
                      //                               style: getWhiteTextStyle(
                      //                                   fontSize: 18)),
                      //                           Text(pit,
                      //                               style: getWhiteTextStyle(
                      //                                   fontWeight: w700,
                      //                                   fontSize: 18)),
                      //                         ],
                      //                       ),
                      //                       const SizedBox(height: 12),
                      //                       Column(
                      //                         children: positionList.map((pl) {
                      //                           final Map<String, dynamic>
                      //                               posData =
                      //                               pl as Map<String, dynamic>;

                      //                           List<dynamic> luka = [];
                      //                           final dynamic rawLuka =
                      //                               posData['luka'];

                      //                           if (rawLuka is List) {
                      //                             luka = rawLuka;
                      //                           } else if (rawLuka is String) {
                      //                             luka.add(rawLuka);
                      //                           }

                      //                           final String pos =
                      //                               posData['pos']
                      //                                       ?.toString() ??
                      //                                   '-';
                      //                           final String pressure =
                      //                               posData['pressure']
                      //                                       ?.toString() ??
                      //                                   '0';
                      //                           final String adjPressure =
                      //                               posData['adjusmentPressure']
                      //                                       ?.toString() ??
                      //                                   '';
                      //                           final String rating =
                      //                               posData['rating']
                      //                                       ?.toString() ??
                      //                                   '';

                      //                           return Column(
                      //                             children: [
                      //                               Row(
                      //                                 mainAxisAlignment:
                      //                                     MainAxisAlignment
                      //                                         .spaceBetween,
                      //                                 crossAxisAlignment:
                      //                                     CrossAxisAlignment
                      //                                         .center,
                      //                                 children: [
                      //                                   Text(
                      //                                     'Pos. $pos',
                      //                                     style:
                      //                                         getWhiteTextStyle(
                      //                                             fontSize: 18),
                      //                                   ),
                      //                                   Column(
                      //                                     crossAxisAlignment:
                      //                                         CrossAxisAlignment
                      //                                             .end,
                      //                                     mainAxisAlignment:
                      //                                         MainAxisAlignment
                      //                                             .center,
                      //                                     children: [
                      //                                       Text(
                      //                                         '$pressure Psi',
                      //                                         style:
                      //                                             getWhiteTextStyle(
                      //                                                 fontWeight:
                      //                                                     w700,
                      //                                                 fontSize:
                      //                                                     18),
                      //                                       ),
                      //                                       if (adjPressure
                      //                                               .isNotEmpty &&
                      //                                           adjPressure !=
                      //                                               '0')
                      //                                         Text(
                      //                                           '$adjPressure Psi (Adj. Pressure)',
                      //                                           style: getWhiteTextStyle(
                      //                                               fontWeight:
                      //                                                   w700,
                      //                                               fontSize:
                      //                                                   18),
                      //                                         ),
                      //                                       if (luka.isNotEmpty)
                      //                                         Text(
                      //                                           luka.join('\n'),
                      //                                           textAlign:
                      //                                               TextAlign
                      //                                                   .end,
                      //                                           style: getWhiteTextStyle(
                      //                                               fontWeight:
                      //                                                   w700,
                      //                                               fontSize:
                      //                                                   18),
                      //                                         ),
                      //                                       if (rating
                      //                                           .isNotEmpty)
                      //                                         Text(
                      //                                             'Rating $rating',
                      //                                             style: getWhiteTextStyle(
                      //                                                 fontWeight:
                      //                                                     w700,
                      //                                                 fontSize:
                      //                                                     18)),
                      //                                       // Jangan lupa tambahkan IDSite 33
                      //                                       if (idSite ==
                      //                                               '33' &&
                      //                                           pl['tireAccessories'] !=
                      //                                               null)
                      //                                         Column(
                      //                                           crossAxisAlignment:
                      //                                               CrossAxisAlignment
                      //                                                   .end,
                      //                                           children: [
                      //                                             Text(
                      //                                                 'Tire Accessories',
                      //                                                 style: getWhiteTextStyle(
                      //                                                     fontWeight:
                      //                                                         w700,
                      //                                                     fontSize:
                      //                                                         14)),
                      //                                             const SizedBox(
                      //                                               height: 6,
                      //                                             ),
                      //                                             Column(
                      //                                               crossAxisAlignment:
                      //                                                   CrossAxisAlignment
                      //                                                       .end,
                      //                                               children: pl[
                      //                                                       'tireAccessories']
                      //                                                   .map<Widget>(
                      //                                                       (acc) {
                      //                                                 return Column(
                      //                                                   crossAxisAlignment:
                      //                                                       CrossAxisAlignment.end,
                      //                                                   children: [
                      //                                                     Row(
                      //                                                       children: [
                      //                                                         Text(acc['name'] + ' (' + acc['condition'] + '${(acc['remark'] != '') ? ': ${acc['remark']}' : ''})', textAlign: TextAlign.right, style: getWhiteTextStyle(fontWeight: w500, fontSize: 14)),
                      //                                                       ],
                      //                                                     ),
                      //                                                     const SizedBox(
                      //                                                       height:
                      //                                                           6,
                      //                                                     ),
                      //                                                     if (acc['image'].isNotEmpty &&
                      //                                                         acc['image'] != 'image.png' &&
                      //                                                         acc['image'] != '')
                      //                                                       InkWell(
                      //                                                         onTap: () async {
                      //                                                           await showDialog(
                      //                                                             context: context,
                      //                                                             barrierDismissible: true,
                      //                                                             builder: (_) {
                      //                                                               return Dialog(
                      //                                                                 backgroundColor: Colors.transparent,
                      //                                                                 elevation: 0,
                      //                                                                 child: Center(
                      //                                                                   child: Column(
                      //                                                                     mainAxisSize: MainAxisSize.min,
                      //                                                                     children: [
                      //                                                                       // === GAMBAR + TOMBOL CLOSE ===
                      //                                                                       Stack(
                      //                                                                         children: [
                      //                                                                           Container(
                      //                                                                             width: MediaQuery.of(context).size.width * 0.6,
                      //                                                                             height: MediaQuery.of(context).size.height * 0.6,
                      //                                                                             decoration: BoxDecoration(
                      //                                                                               borderRadius: BorderRadius.circular(12),
                      //                                                                             ),
                      //                                                                             clipBehavior: Clip.antiAlias,
                      //                                                                             child: Image.network(
                      //                                                                               acc['image'],
                      //                                                                               fit: BoxFit.contain,
                      //                                                                             ),
                      //                                                                           ),
                      //                                                                           Positioned(
                      //                                                                             right: 8,
                      //                                                                             top: 8,
                      //                                                                             child: InkWell(
                      //                                                                               onTap: () => Navigator.of(context).pop(),
                      //                                                                               borderRadius: BorderRadius.circular(20),
                      //                                                                               child: Container(
                      //                                                                                 padding: const EdgeInsets.all(6),
                      //                                                                                 decoration: BoxDecoration(
                      //                                                                                   color: Colors.black45,
                      //                                                                                   shape: BoxShape.circle,
                      //                                                                                 ),
                      //                                                                                 child: const Icon(
                      //                                                                                   LucideIcons.x,
                      //                                                                                   color: Colors.white,
                      //                                                                                   size: 20,
                      //                                                                                 ),
                      //                                                                               ),
                      //                                                                             ),
                      //                                                                           ),
                      //                                                                         ],
                      //                                                                       ),

                      //                                                                       const SizedBox(height: 12),

                      //                                                                       // === TEKS KETERANGAN ===
                      //                                                                       Container(
                      //                                                                         padding: const EdgeInsets.all(8),
                      //                                                                         decoration: BoxDecoration(
                      //                                                                           color: Colors.white,
                      //                                                                           borderRadius: BorderRadius.circular(16),
                      //                                                                         ),
                      //                                                                         child: Text(
                      //                                                                           '#$unit Pos. $pos | ${acc['name']} ${acc['condition']} ${(acc['remark'] != '') ? ': ${acc['remark']}' : ''}',
                      //                                                                           style: getBlackTextStyle(
                      //                                                                             fontWeight: w700,
                      //                                                                           ),
                      //                                                                           textAlign: TextAlign.center,
                      //                                                                         ),
                      //                                                                       ),
                      //                                                                     ],
                      //                                                                   ),
                      //                                                                 ),
                      //                                                               );
                      //                                                             },
                      //                                                           );
                      //                                                         },
                      //                                                         child: SizedBox(
                      //                                                           width: 150,
                      //                                                           height: 100,
                      //                                                           child: Image.network(
                      //                                                             acc['image'],
                      //                                                             fit: BoxFit.cover,
                      //                                                           ),
                      //                                                         ),
                      //                                                       )
                      //                                                   ],
                      //                                                 );
                      //                                               }).toList(),
                      //                                             ),
                      //                                           ],
                      //                                         ),
                      //                                     ],
                      //                                   ),
                      //                                 ],
                      //                               ),
                      //                               const SizedBox(height: 12),
                      //                               Divider(
                      //                                 color: white,
                      //                                 thickness: 1.5,
                      //                               ),
                      //                             ],
                      //                           );
                      //                         }).toList(),
                      //                       ),
                      //                     ],
                      //                   ),
                      //                 ));
                      //           },
                      //         ),
                      //       ),
                      //     ],
                      //   );
                      // Not Checked Unit
                      // Not Checked Unit
                      case 1:
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 12),
                              StreamBuilder<
                                  QuerySnapshot<Map<String, dynamic>>>(
                                stream: firestore
                                    .collection('daily_pressure')
                                    .where(
                                      'tanggal',
                                      isGreaterThanOrEqualTo: DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                      ).toIso8601String(),
                                    )
                                    .where(
                                      'tanggal',
                                      isLessThanOrEqualTo: DateTime(
                                        selectedDate.year,
                                        selectedDate.month,
                                        selectedDate.day,
                                        23,
                                        59,
                                        59,
                                      ).toIso8601String(),
                                    )
                                    .where(
                                      'idSite',
                                      isEqualTo: idSite,
                                    )
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                      child:
                                          CircularProgressIndicator.adaptive(),
                                    );
                                  }

                                  if (snapshot.hasError) {
                                    return Text(
                                      'Error load Not Checked data: ${snapshot.error}',
                                      style: getBlackTextStyle(fontSize: 14),
                                    );
                                  }

                                  final dailyData = snapshot.data?.docs ?? [];

                                  // Daftar unit yang sudah diperiksa pada tanggal terpilih.
                                  final Set<String> checkedUnitSet = dailyData
                                      .map((doc) {
                                        final data = doc.data();

                                        return data['unit']
                                                ?.toString()
                                                .trim()
                                                .toLowerCase() ??
                                            '';
                                      })
                                      .where((unit) => unit.isNotEmpty)
                                      .toSet();

                                  // Ambil unit yang belum diperiksa.
                                  final List<UnitTire> notChecked =
                                      state.units.where((unit) {
                                    final unitNumber =
                                        unit.unitNumber?.trim().toLowerCase() ??
                                            '';

                                    if (unitNumber.isEmpty) {
                                      return false;
                                    }

                                    return !checkedUnitSet.contains(unitNumber);
                                  }).toList();

                                  // Filter berdasarkan search.
                                  final String keyword =
                                      searchQuery.trim().toLowerCase();

                                  final List<UnitTire> filteredNotChecked =
                                      notChecked.where((unit) {
                                    if (keyword.isEmpty) {
                                      return true;
                                    }

                                    final unitNumber =
                                        unit.unitNumber?.toLowerCase() ?? '';

                                    final model =
                                        unit.model?.toLowerCase() ?? '';

                                    return unitNumber.contains(keyword) ||
                                        model.contains(keyword);
                                  }).toList();

                                  // Urutkan berdasarkan nomor unit.
                                  filteredNotChecked.sort((a, b) {
                                    final unitA = a.unitNumber ?? '';
                                    final unitB = b.unitNumber ?? '';

                                    return unitA.compareTo(unitB);
                                  });

                                  DateTime? lastUpdate;

                                  if (dailyData.isNotEmpty) {
                                    final sortedDocs = [...dailyData];

                                    sortedDocs.sort((a, b) {
                                      final aTanggal =
                                          a.data()['tanggal']?.toString() ?? '';

                                      final bTanggal =
                                          b.data()['tanggal']?.toString() ?? '';

                                      return bTanggal.compareTo(aTanggal);
                                    });

                                    final tanggal = sortedDocs.first
                                        .data()['tanggal']
                                        ?.toString();

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

                                      const SizedBox(height: 12),

                                      // ==========================================
                                      // TOMBOL EXPORT TXT
                                      // ==========================================
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          onPressed: filteredNotChecked.isEmpty
                                              ? null
                                              : () async {
                                                  try {
                                                    final StringBuffer txt =
                                                        StringBuffer();

                                                    final String
                                                        selectedDateText =
                                                        DateFormat('dd-MM-yyyy')
                                                            .format(
                                                                selectedDate);

                                                    final String exportTime =
                                                        DateFormat(
                                                      'dd-MM-yyyy HH:mm:ss',
                                                    ).format(DateTime.now());

                                                    txt.writeln(
                                                      'LIST UNIT NOT CHECKED',
                                                    );

                                                    txt.writeln(
                                                      '================================',
                                                    );

                                                    txt.writeln(
                                                      'Site          : $idSite',
                                                    );

                                                    txt.writeln(
                                                      'Tanggal Data  : $selectedDateText',
                                                    );

                                                    txt.writeln(
                                                      'Waktu Export  : $exportTime',
                                                    );

                                                    txt.writeln(
                                                      'Total Unit    : '
                                                      '${filteredNotChecked.length}',
                                                    );

                                                    if (keyword.isNotEmpty) {
                                                      txt.writeln(
                                                        'Pencarian     : $searchQuery',
                                                      );
                                                    }

                                                    txt.writeln(
                                                      '================================',
                                                    );

                                                    txt.writeln();

                                                    for (int index = 0;
                                                        index <
                                                            filteredNotChecked
                                                                .length;
                                                        index++) {
                                                      final unit =
                                                          filteredNotChecked[
                                                              index];

                                                      final String unitNumber =
                                                          unit.unitNumber
                                                                  ?.toString()
                                                                  .trim() ??
                                                              '';

                                                      final String model = unit
                                                              .model
                                                              ?.toString()
                                                              .trim() ??
                                                          '';

                                                      txt.writeln(
                                                        '${index + 1}. '
                                                        '${unitNumber.isEmpty ? '-' : unitNumber}',
                                                      );

                                                      txt.writeln(
                                                        '   Model : '
                                                        '${model.isEmpty ? '-' : model}',
                                                      );

                                                      txt.writeln(
                                                        '--------------------------------',
                                                      );
                                                    }

                                                    final Directory?
                                                        downloadDirectory =
                                                        await DownloadsPath
                                                            .downloadsDirectory();

                                                    if (downloadDirectory ==
                                                        null) {
                                                      throw Exception(
                                                        'Folder Download tidak ditemukan',
                                                      );
                                                    }

                                                    final String fileDate =
                                                        DateFormat('yyyyMMdd')
                                                            .format(
                                                                selectedDate);

                                                    final String fileTime =
                                                        DateFormat('HHmmss')
                                                            .format(
                                                                DateTime.now());

                                                    final String fileName =
                                                        'not_checked_'
                                                        '${idSite}_'
                                                        '${fileDate}_'
                                                        '$fileTime.txt';

                                                    final File file = File(
                                                      '${downloadDirectory.path}/'
                                                      '$fileName',
                                                    );

                                                    await file.writeAsString(
                                                      txt.toString(),
                                                      flush: true,
                                                    );

                                                    debugPrint(
                                                      'File TXT tersimpan: '
                                                      '${file.path}',
                                                    );

                                                    if (!mounted) return;

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .hideCurrentSnackBar();

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        backgroundColor:
                                                            Colors.green,
                                                        duration:
                                                            const Duration(
                                                          seconds: 5,
                                                        ),
                                                        content: Text(
                                                          'Berhasil export '
                                                          '${filteredNotChecked.length} '
                                                          'unit Not Checked\n'
                                                          'Download/$fileName',
                                                        ),
                                                      ),
                                                    );
                                                  } catch (e) {
                                                    debugPrint(
                                                      'Gagal export TXT: $e',
                                                    );

                                                    if (!mounted) return;

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .hideCurrentSnackBar();

                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        backgroundColor:
                                                            Colors.red,
                                                        content: Text(
                                                          'Gagal export TXT: $e',
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            disabledBackgroundColor:
                                                Colors.grey,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                            ),
                                          ),
                                          icon: const Icon(
                                            Icons.file_download_outlined,
                                            color: Colors.white,
                                          ),
                                          label: Text(
                                            'Export Not Checked '
                                            '(${filteredNotChecked.length})',
                                            style: getWhiteTextStyle(),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 12),

                                      if (lastUpdate != null)
                                        Column(
                                          children: [
                                            Text(
                                              'Last Update : '
                                              '${DateFormat('HH:mm:ss dd-MM-yyyy').format(lastUpdate)}',
                                              textAlign: TextAlign.center,
                                              style: getBlackTextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                          ],
                                        ),

                                      if (filteredNotChecked.isEmpty)
                                        Text(
                                          keyword.isEmpty
                                              ? 'Empty!'
                                              : 'Unit tidak ditemukan!',
                                          textAlign: TextAlign.center,
                                          style: getBlackTextStyle(
                                            fontSize: 18,
                                          ),
                                        )
                                      else
                                        ListView.builder(
                                          itemCount: filteredNotChecked.length,
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            final UnitTire unit =
                                                filteredNotChecked[index];

                                            return Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                vertical: 8.0,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                vertical: 6,
                                              ),
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
                                                  padding:
                                                      const EdgeInsets.only(
                                                    bottom: 4.0,
                                                  ),
                                                  child: Text(
                                                    unit.unitNumber ?? '-',
                                                    style: getBlackTextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  unit.model ?? '-',
                                                  style: getGreyTextStyle(
                                                    grey6A707C,
                                                  ),
                                                ),
                                                trailing: const Icon(
                                                  Icons.arrow_forward_ios,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                            ],
                          ),
                        );
                      // case 1:
                      // final notChecked = [];
                      // notChecked.clear();
                      // notChecked.addAll(state.units);
                      // return Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      //   child: Column(
                      //     children: [
                      //       const SizedBox(
                      //         height: 12,
                      //       ),
                      //       StreamBuilder(
                      //           stream: firestore
                      //               .collection('daily_pressure')
                      //               .where('tanggal',
                      //                   isGreaterThanOrEqualTo: DateTime(
                      //                           selectedDate.year,
                      //                           selectedDate.month,
                      //                           selectedDate.day)
                      //                       .toIso8601String())
                      //               .where('tanggal',
                      //                   isLessThanOrEqualTo: DateTime(
                      //                           selectedDate.year,
                      //                           selectedDate.month,
                      //                           selectedDate.day,
                      //                           23,
                      //                           59,
                      //                           59)
                      //                       .toIso8601String())
                      //               .where('idSite', isEqualTo: idSite)
                      //               .snapshots(),
                      //           builder: (context, snapshot) {
                      //             if (snapshot.connectionState ==
                      //                 ConnectionState.waiting) {
                      //               return CircularProgressIndicator
                      //                   .adaptive();
                      //             }
                      //             if (snapshot.connectionState ==
                      //                 ConnectionState.active) {
                      //               final dailyData =
                      //                   snapshot.data?.docs ?? [];

                      //               // Mendapatkan field 'unit' dari setiap dokumen
                      //               final unitList = dailyData
                      //                   .map((doc) => doc['unit'])
                      //                   .toList();

                      //               // Mengecek apakah 'unitList' kosong, jika tidak kosong lanjutkan removeWhere
                      //               unitList.isNotEmpty
                      //                   ? notChecked.removeWhere((element) =>
                      //                       unitList
                      //                           .contains(element.unitNumber))
                      //                   : [];

                      //               return Column(
                      //                 children: [
                      //                   Text(
                      //                     'Total Unit : ${notChecked.length ?? 0}',
                      //                     style: getBlackTextStyle(
                      //                       fontSize: 20,
                      //                     ),
                      //                   ),
                      //                   const SizedBox(
                      //                     height: 12,
                      //                   ),
                      //                   (snapshot.data?.size != 0)
                      //                       ? Column(
                      //                           children: [
                      //                             Builder(builder: (context) {
                      //                               // Parsing string to DateTime object
                      //                               DateTime parsedDate =
                      //                                   DateTime.parse(snapshot
                      //                                       .data
                      //                                       ?.docs[snapshot
                      //                                               .data!
                      //                                               .size -
                      //                                           1]
                      //                                       .data()['tanggal']);

                      //                               // Formatting DateTime to the desired format
                      //                               String formattedDate =
                      //                                   DateFormat(
                      //                                           'HH:mm:ss dd-MM-yyyy')
                      //                                       .format(
                      //                                           parsedDate);
                      //                               return Text(
                      //                                 'Last Update : ${formattedDate}',
                      //                                 textAlign:
                      //                                     TextAlign.center,
                      //                                 style:
                      //                                     getBlackTextStyle(
                      //                                   fontSize: 14,
                      //                                 ),
                      //                               );
                      //                             }),
                      //                             const SizedBox(
                      //                               height: 12,
                      //                             ),
                      //                           ],
                      //                         )
                      //                       : Container(),
                      //                   (notChecked == null ||
                      //                           notChecked.isEmpty)
                      //                       ? Text(
                      //                           'Empty!',
                      //                           textAlign: TextAlign.center,
                      //                           style: getBlackTextStyle(
                      //                               fontSize: 18),
                      //                         )
                      //                       : Column(
                      //                           children:
                      //                               (notChecked).map((unit) {
                      //                             if (searchQuery
                      //                                     .isNotEmpty &&
                      //                                 !unit.unitNumber!
                      //                                     .toLowerCase()
                      //                                     .contains(
                      //                                         searchQuery) &&
                      //                                 !unit.model!
                      //                                     .toLowerCase()
                      //                                     .contains(
                      //                                         searchQuery)) {
                      //                               return Container();
                      //                             }
                      //                             return Container(
                      //                               margin:
                      //                                   EdgeInsets.symmetric(
                      //                                       vertical: 8.0),
                      //                               padding:
                      //                                   EdgeInsets.symmetric(
                      //                                       vertical: 6),
                      //                               decoration: BoxDecoration(
                      //                                 color: Colors.white,
                      //                                 borderRadius:
                      //                                     BorderRadius
                      //                                         .circular(12),
                      //                                 boxShadow: [
                      //                                   BoxShadow(
                      //                                     color: Colors.black
                      //                                         .withOpacity(
                      //                                             0.1),
                      //                                     spreadRadius: 2,
                      //                                     blurRadius: 5,
                      //                                     offset:
                      //                                         Offset(0, 2),
                      //                                   ),
                      //                                 ],
                      //                               ),
                      //                               child: ListTile(
                      //                                 leading: Icon(
                      //                                   Icons.front_loader,
                      //                                   color: Colors.orange,
                      //                                 ),
                      //                                 title: Padding(
                      //                                   padding:
                      //                                       const EdgeInsets
                      //                                           .only(
                      //                                           bottom: 4.0),
                      //                                   child: Text(
                      //                                     '${unit.unitNumber}',
                      //                                     style: getBlackTextStyle(
                      //                                         fontWeight:
                      //                                             FontWeight
                      //                                                 .w700),
                      //                                   ),
                      //                                 ),
                      //                                 subtitle: Text(
                      //                                   '${unit.model}',
                      //                                   style:
                      //                                       getGreyTextStyle(
                      //                                           grey6A707C),
                      //                                 ),
                      //                                 trailing: Icon(Icons
                      //                                     .arrow_forward_ios),
                      //                               ),
                      //                             );
                      //                           }).toList(),
                      //                         ),
                      //                 ],
                      //               );
                      //             }

                      //             return Container();
                      //           }),
                      //       const SizedBox(
                      //         height: 12,
                      //       ),
                      //     ],
                      //   ),
                      // );
                    }
                  }
                  return Container();
                }),
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

            if (index == 0) {
              historyCheckedFuture ??= getHistoryCheckedFuture();
            }
          });
        },
        // onTap: (index) {
        //   setState(() {
        //     selectedMenu = index;
        //   });
        // },
      ),
    );
  }
}
