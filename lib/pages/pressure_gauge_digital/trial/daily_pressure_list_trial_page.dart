import 'dart:developer';

import '../../../core/blocs/daily_check_post/daily_check_post_bloc.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/model/unit_tire.dart';
import '../../../core/services/shared_preferences/shared_preferences.dart';
import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/functions/functions.dart';
import '../../../core/widgets/appbar_widget.dart';
import '../daily_pressure_history_page.dart';
import 'daily_pressure_history_trial_page.dart';
import '../widget/enum_export_type.dart';
import '../widget/export_excel_button.dart';
import '../widget/select_pit_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/blocs/unit/unit_bloc.dart';

class DailyPressureListTrialPage extends StatefulWidget {
  static const routeName = '/daily-pressure-list-trial-page';
  const DailyPressureListTrialPage({super.key});

  @override
  State<DailyPressureListTrialPage> createState() =>
      _DailyPressureListTrialPageState();
}

class _DailyPressureListTrialPageState
    extends State<DailyPressureListTrialPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  // untuk user office, id site menyimpan id site yang dipilih
  String idSite = '';
  // untuk user office, actual id site menyimpan id site office
  String actualIdSite = '';
  List<String> pit = [];
  int selectedPit = 0;
  String searchQuery = '';
  Map<String, dynamic> user = {};
  List<Map<String, dynamic>> filteredItemTask = [];
  List<UnitTire> units = [];
  DateTime now = DateTime.now();
  bool _isPreparingCtsData = false;

  @override
  void initState() {
    super.initState();

    insertPit();
    // getUser();
  }

  Future<void> getUnits() async {
    // jika user site ambil dari cache
    if (await getIdSitePreferences() != '1' &&
        await getIdSitePreferences() != '2') {
      // belum ganti bulan

      if (await getSavedMonthYear() ==
          "${DateTime.now().year}-${DateTime.now().month}") {
        units = await ApiService.getCachedUnits();
      } else {
        // sudah ganti bulan
        units = await ApiService.getUnits(idSite);
      }
    } else {
      // jika user office tidak perlu ambil dari cache
      units = await ApiService.getUnits(idSite);
    }
  }

  // getUser() async {
  //   user = await getUserPreferences();
  //   log('username : ${user}');
  // }

  Future<String> getActualIdSite() async {
    final actIdSite = await getIdSitePreferences();

    return actIdSite;
  }

  insertPit() async {
    idSite = await getIdSitePreferences();
    actualIdSite = await getIdSitePreferences();
    if (idSite == '1' || idSite == '2') {
      idSite = await getSelectedIdSitePreferences();
    }
    log('id site : $idSite');

    // await getUnits();

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

  bool _hasCompleteCtsMetadata(
    List<UnitTire> allUnit,
    int countAllTire,
    Map<String, dynamic> allTireSize,
  ) {
    final sizes = allTireSize['sizes'];
    final sizeCount = allTireSize['sizeCount'];

    return allUnit.isNotEmpty &&
        countAllTire > 0 &&
        sizes is List &&
        sizes.isNotEmpty &&
        sizeCount is Map &&
        sizeCount.isNotEmpty;
  }

  Future<Map<String, dynamic>> _loadCtsMetadata() async {
    List<UnitTire> allUnit = [];
    int countAllTire = 0;
    Map<String, dynamic> allTireSize = {};

    try {
      allUnit = await ApiService.getCachedUnits(idSite: idSite);
    } catch (e, stackTrace) {
      log(
        'Cache unit CTS tidak tersedia, menggunakan list kosong: $e',
        stackTrace: stackTrace,
      );
    }

    try {
      countAllTire = await ApiService.getCachedCountAllTire(idSite: idSite);
    } catch (e, stackTrace) {
      log(
        'Cache total tire CTS tidak tersedia, menggunakan 0: $e',
        stackTrace: stackTrace,
      );
    }

    try {
      allTireSize = await ApiService.getCachedTireSize(idSite: idSite);
    } catch (e, stackTrace) {
      log(
        'Cache tire size CTS tidak tersedia, menggunakan map kosong: $e',
        stackTrace: stackTrace,
      );
    }

    if (!_hasCompleteCtsMetadata(
      allUnit,
      countAllTire,
      allTireSize,
    )) {
      try {
        allUnit = await ApiService.getUnits(idSite);
        countAllTire = await ApiService.getCachedCountAllTire(idSite: idSite);
        allTireSize = await ApiService.getCachedTireSize(idSite: idSite);
      } catch (e, stackTrace) {
        log(
          'Metadata CTS tidak lengkap dan gagal diperbarui. '
          'Pengiriman dilanjutkan dengan data yang tersedia: $e',
          stackTrace: stackTrace,
        );
      }
    }

    final rawSizes = allTireSize['sizes'];
    final normalizedSizes = rawSizes is List
        ? rawSizes.map((size) => size?.toString() ?? '').toList()
        : <String>[];
    final rawSizeCount = allTireSize['sizeCount'];
    final normalizedSizeCount = <String, dynamic>{};

    for (final size in normalizedSizes) {
      normalizedSizeCount[size] =
          rawSizeCount is Map ? (rawSizeCount[size] ?? '') : '';
    }

    allTireSize = {
      'sizes': normalizedSizes,
      'sizeCount': normalizedSizeCount,
    };

    if (!_hasCompleteCtsMetadata(allUnit, countAllTire, allTireSize)) {
      log(
        'Metadata CTS belum lengkap. Menggunakan fallback: '
        'allUnit=${allUnit.length}, countAllTire=$countAllTire, '
        'sizes=${normalizedSizes.length}.',
      );
    }

    return {
      'allUnit': allUnit,
      'countAllTire': countAllTire > 0 ? countAllTire : 0,
      'allTireSize': allTireSize,
    };
  }

  Future<void> _sendDataToCts() async {
    if (_isPreparingCtsData) return;

    final dailyData = filteredItemTask
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (dailyData.isEmpty) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange,
          content: Text(
            'Tidak ada data Daily Pressure hari ini untuk dikirim.',
            style: getWhiteTextStyle(),
          ),
        ),
      );
      return;
    }

    final confirmSend = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.warning,
              color: Colors.orange,
            ),
            const SizedBox(width: 12),
            Text(
              'Warning',
              style: getRedTextStyle(fontSize: 24).copyWith(
                color: Colors.orange,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure? Please Check Before Send Data!',
          style: getBlackTextStyle(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmSend != true || !mounted) return;

    if (idSite.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Site belum tersedia. Silakan buka ulang halaman.',
            style: getWhiteTextStyle(),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isPreparingCtsData = true;
    });

    try {
      final metadata = await _loadCtsMetadata();

      if (!mounted) return;

      context.read<DailyCheckPostBloc>().add(
            DailyCheckPostEvent(
              dailyCheck: dailyData,
              countAllTire: metadata['countAllTire'] as int,
              allUnit: metadata['allUnit'] as List<UnitTire>,
              allTireSize: metadata['allTireSize'] as Map<String, dynamic>,
              typeSend: 'single',
            ),
          );
    } catch (e, stackTrace) {
      log(
        'Gagal menyiapkan data CTS: $e',
        stackTrace: stackTrace,
      );

      if (!mounted) return;

      setState(() {
        _isPreparingCtsData = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text(
            'Gagal menyiapkan data CTS: $e',
            style: getWhiteTextStyle(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    pit.clear();
    if (idSite == '52') {
      pit.add('All');
      pit.add('Utara');
      pit.add('Selatan');
      pit.add('RML');
      pit.add('WS');
    }
    return Scaffold(
      appBar: appBarWidget('Daily Pressure List', context),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
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
                BlocConsumer<DailyCheckPostBloc, DailyCheckPostState>(
                  listener: (context, state) {
                    if (state is DailyCheckPostSuccessState) {
                      if (_isPreparingCtsData) {
                        setState(() {
                          _isPreparingCtsData = false;
                        });
                      }

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: green00968A,
                          content: Text(
                            state.message,
                            style: getWhiteTextStyle(),
                          ),
                        ),
                      );
                    }

                    if (state is DailyCheckPostErrorState) {
                      if (_isPreparingCtsData) {
                        setState(() {
                          _isPreparingCtsData = false;
                        });
                      }

                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.red,
                          content: Text(
                            'Gagal mengirim data ke CTS: ${state.error}',
                            style: getWhiteTextStyle(),
                          ),
                        ),
                      );
                    }
                  },
                  builder: (context, state) {
                    final isSending = _isPreparingCtsData ||
                        state is DailyCheckPostLoadingState;

                    return SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSending ? null : _sendDataToCts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: green00968A,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: isSending
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      state is DailyCheckPostLoadingState
                                          ? 'Sending to CTS...'
                                          : 'Preparing Data...',
                                      style: getWhiteTextStyle(),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.send,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Send Data to CTS',
                                      style: getWhiteTextStyle(),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(
                  height: 12,
                ),
                ExportExcelButton(
                  user: user,
                  pit: pit,
                  selectedPit: selectedPit,
                  filteredItemTask: filteredItemTask,
                  date:
                      "${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().year}",
                  type: ExportType.oneDay,
                ),
                const SizedBox(
                  height: 12,
                ),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(
                              context, DailyPressureHistoryTrialPage.routeName);
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
                            isLessThanOrEqualTo: DateTime(
                                    now.year, now.month, now.day, 23, 59, 59)
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
                            (snapshot.data?.size != 0)
                                ? Column(
                                    children: [
                                      Builder(builder: (context) {
                                        // Parsing string to DateTime object
                                        DateTime parsedDate = DateTime.parse(
                                            snapshot.data
                                                ?.docs[snapshot.data!.size - 1]
                                                .data()['tanggal']);

                                        // Formatting DateTime to the desired format
                                        String formattedDate =
                                            DateFormat('HH:mm:ss dd-MM-yyyy')
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
                      return PaginateFirestore(
                          query: firestore
                              .collection('daily_pressure')
                              .where('tanggal',
                                  isGreaterThanOrEqualTo:
                                      DateTime(now.year, now.month, now.day)
                                          .toIso8601String())
                              .where('tanggal',
                                  isLessThanOrEqualTo: DateTime(now.year,
                                          now.month, now.day, 23, 59, 59)
                                      .toIso8601String())
                              .where('idSite', isEqualTo: data)
                              .orderBy('tanggal', descending: true),
                          itemBuilderType: PaginateBuilderType.listView,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemsPerPage: 10,
                          isLive: true,
                          initialLoader: const Center(
                              child: CircularProgressIndicator.adaptive()),
                          bottomLoader: const Center(
                              child: CircularProgressIndicator.adaptive()),
                          itemBuilder: (context, snapshot, index) {
                            log('hahaha');
                            log('pama pressure list : ${snapshot.length}');

                            final Map<String, dynamic> dailyMap =
                                snapshot[index].data() as Map<String, dynamic>;
                            final positionList =
                                dailyMap['posisi'] as List<dynamic>;

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
                                            style:
                                                getWhiteTextStyle(fontSize: 18),
                                          ),
                                          Container(
                                            width: 300,
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
                                            style:
                                                getWhiteTextStyle(fontSize: 18),
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
                                            style:
                                                getWhiteTextStyle(fontSize: 18),
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
                                            style:
                                                getWhiteTextStyle(fontSize: 18),
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
                                            'Condition',
                                            style:
                                                getWhiteTextStyle(fontSize: 18),
                                          ),
                                          Text(
                                            dailyMap['unit_condition'] ?? '',
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
                                            style:
                                                getWhiteTextStyle(fontSize: 18),
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
                                          final plIndex =
                                              positionList.indexOf(pl);
                                          List<dynamic> luka = [];

                                          if (pl['luka'] != null &&
                                              pl['luka'] is! String) {
                                            luka = pl['luka'] as List<dynamic>;
                                          }

                                          return Column(
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    'Pos. ${pl['pos']}',
                                                    style: getWhiteTextStyle(
                                                        fontSize: 18),
                                                  ),
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.end,
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
                                                            style:
                                                                getWhiteTextStyle(
                                                                    fontWeight:
                                                                        w700,
                                                                    fontSize:
                                                                        18),
                                                          ),
                                                          (pl['adjusmentPressure'] !=
                                                                      null &&
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
                                                                  .join('\n'),
                                                              textAlign:
                                                                  TextAlign.end,
                                                              style:
                                                                  getWhiteTextStyle(
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
                          });
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
                //         final now = DateTime.now();

                //         // pilih all pit
                //         if (pit.isNotEmpty) {
                //           if (pit[selectedPit] == 'All') {
                //             return dateTime.year == now.year &&
                //                 dateTime.month == now.month &&
                //                 dateTime.day == now.day &&
                //                 data['idSite'] == idSite;
                //           }

                //           // ada pit
                //           if (data['pit'] != 'Default') {
                //             return dateTime.year == now.year &&
                //                 dateTime.month == now.month &&
                //                 dateTime.day == now.day &&
                //                 data['idSite'] == idSite &&
                //                 data['pit'] == pit[selectedPit];
                //           }
                //         }

                //         // tidak ada pit
                //         return dateTime.year == now.year &&
                //             dateTime.month == now.month &&
                //             dateTime.day == now.day &&
                //             data['idSite'] == idSite;
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
                //         return timeB.compareTo(
                //             timeA); // Dari yang terbaru ke yang terlama
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
                //           const SizedBox(
                //             height: 12,
                //           ),
                //           Padding(
                //             padding:
                //                 const EdgeInsets.symmetric(horizontal: 12.0),
                //             child: Text(
                //               'Total Unit : ${filteredDocument.length}',
                //               style: getBlackTextStyle(fontSize: 20),
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

                //               return Card(
                //                   elevation: 2,
                //                   shape: RoundedRectangleBorder(
                //                     borderRadius: BorderRadius.circular(12),
                //                   ),
                //                   color: green00968A,
                //                   child: Container(
                //                     width: double.infinity,
                //                     padding: EdgeInsets.symmetric(
                //                         horizontal: 12, vertical: 24),
                //                     decoration: BoxDecoration(
                //                       color: green00968A,
                //                       borderRadius: BorderRadius.circular(12),
                //                     ),
                //                     child: ExpansionTile(
                //                       tilePadding: EdgeInsets.zero,
                //                       childrenPadding: EdgeInsets.all(0),
                //                       title: Row(
                //                         children: [
                //                           Icon(
                //                             Icons.task,
                //                             color: white,
                //                             size: 36,
                //                           ),
                //                           const SizedBox(
                //                             width: 12,
                //                           ),
                //                           Text(
                //                             dailyMap['unit'] +
                //                                 '${((dailyMap['pit'] != 'Default') ? ' - ' + dailyMap['pit'] : '')}',
                //                             style: getWhiteTextStyle(
                //                                 fontWeight: w700, fontSize: 18),
                //                           )
                //                         ],
                //                       ),
                //                       trailing: SizedBox(
                //                         width: 90,
                //                         child: Icon(Icons.arrow_drop_down),
                //                       ),
                //                       children: [
                //                         const SizedBox(
                //                           height: 12,
                //                         ),
                //                         Row(
                //                           mainAxisAlignment:
                //                               MainAxisAlignment.spaceBetween,
                //                           children: [
                //                             Text(
                //                               'Name',
                //                               style: getWhiteTextStyle(
                //                                   fontSize: 18),
                //                             ),
                //                             Container(
                //                               width: 250,
                //                               child: Text(
                //                                 dailyMap['user'] ?? 'No Name',
                //                                 textAlign: TextAlign.end,
                //                                 style: getWhiteTextStyle(
                //                                     fontWeight: w700,
                //                                     fontSize: 18),
                //                               ),
                //                             ),
                //                           ],
                //                         ),
                //                         const SizedBox(
                //                           height: 12,
                //                         ),
                //                         Row(
                //                           mainAxisAlignment:
                //                               MainAxisAlignment.spaceBetween,
                //                           children: [
                //                             Text(
                //                               'Tanggal',
                //                               style: getWhiteTextStyle(
                //                                   fontSize: 18),
                //                             ),
                //                             Text(
                //                               dailyMap['tanggal'].split('T')[0],
                //                               style: getWhiteTextStyle(
                //                                   fontWeight: w700,
                //                                   fontSize: 18),
                //                             ),
                //                           ],
                //                         ),
                //                         const SizedBox(
                //                           height: 12,
                //                         ),
                //                         Row(
                //                           mainAxisAlignment:
                //                               MainAxisAlignment.spaceBetween,
                //                           children: [
                //                             Text(
                //                               'Waktu',
                //                               style: getWhiteTextStyle(
                //                                   fontSize: 18),
                //                             ),
                //                             Text(
                //                               dailyMap['tanggal']
                //                                   .split('T')[1]
                //                                   .substring(0, 5),
                //                               style: getWhiteTextStyle(
                //                                   fontWeight: w700,
                //                                   fontSize: 18),
                //                             ),
                //                           ],
                //                         ),
                //                         const SizedBox(
                //                           height: 12,
                //                         ),
                //                         Row(
                //                           mainAxisAlignment:
                //                               MainAxisAlignment.spaceBetween,
                //                           children: [
                //                             Text(
                //                               'HM Unit',
                //                               style: getWhiteTextStyle(
                //                                   fontSize: 18),
                //                             ),
                //                             Text(
                //                               dailyMap['hm'],
                //                               style: getWhiteTextStyle(
                //                                   fontWeight: w700,
                //                                   fontSize: 18),
                //                             ),
                //                           ],
                //                         ),
                //                         const SizedBox(
                //                           height: 12,
                //                         ),
                //                         Row(
                //                           mainAxisAlignment:
                //                               MainAxisAlignment.spaceBetween,
                //                           children: [
                //                             Text(
                //                               'Pit',
                //                               style: getWhiteTextStyle(
                //                                   fontSize: 18),
                //                             ),
                //                             Text(
                //                               dailyMap['pit'],
                //                               style: getWhiteTextStyle(
                //                                   fontWeight: w700,
                //                                   fontSize: 18),
                //                             ),
                //                           ],
                //                         ),
                //                         const SizedBox(
                //                           height: 12,
                //                         ),
                //                         Column(
                //                           children: positionList.map((pl) {
                //                             final plIndex =
                //                                 positionList.indexOf(pl);
                //                             List<dynamic> luka = [];

                //                             if (pl['luka'] != null &&
                //                                 pl['luka'] is! String) {
                //                               luka =
                //                                   pl['luka'] as List<dynamic>;
                //                             }

                //                             return Column(
                //                               children: [
                //                                 Row(
                //                                   mainAxisAlignment:
                //                                       MainAxisAlignment
                //                                           .spaceBetween,
                //                                   crossAxisAlignment:
                //                                       CrossAxisAlignment.center,
                //                                   children: [
                //                                     Text(
                //                                       'Pos. ${pl['pos']}',
                //                                       style: getWhiteTextStyle(
                //                                           fontSize: 18),
                //                                     ),
                //                                     Column(
                //                                       crossAxisAlignment:
                //                                           CrossAxisAlignment
                //                                               .end,
                //                                       mainAxisAlignment:
                //                                           MainAxisAlignment
                //                                               .center,
                //                                       children: [
                //                                         Column(
                //                                           crossAxisAlignment:
                //                                               CrossAxisAlignment
                //                                                   .end,
                //                                           children: [
                //                                             Text(
                //                                               '${(pl['pressure'] == '' || pl['pressure'] == null) ? 0 : pl['pressure']} Psi',
                //                                               style:
                //                                                   getWhiteTextStyle(
                //                                                       fontWeight:
                //                                                           w700,
                //                                                       fontSize:
                //                                                           18),
                //                                             ),
                //                                             (pl['adjusmentPressure'] !=
                //                                                         null &&
                //                                                     pl['adjusmentPressure'] !=
                //                                                         '0' &&
                //                                                     pl['adjusmentPressure'] !=
                //                                                         '')
                //                                                 ? Text(
                //                                                     '${pl['adjusmentPressure']} Psi (Adj. Pressure)',
                //                                                     style: getWhiteTextStyle(
                //                                                         fontWeight:
                //                                                             w700,
                //                                                         fontSize:
                //                                                             18),
                //                                                   )
                //                                                 : Container(),
                //                                           ],
                //                                         ),
                //                                         (luka.isEmpty ||
                //                                                 luka == null)
                //                                             ? Container()
                //                                             : Text(
                //                                                 pl['luka']
                //                                                     .join('\n'),
                //                                                 textAlign:
                //                                                     TextAlign
                //                                                         .end,
                //                                                 style: getWhiteTextStyle(
                //                                                     fontWeight:
                //                                                         w700,
                //                                                     fontSize:
                //                                                         18),
                //                                               ),
                //                                         const SizedBox(
                //                                           height: 12,
                //                                         ),
                //                                       ],
                //                                     ),
                //                                   ],
                //                                 ),
                //                                 Divider(
                //                                   color: white,
                //                                   thickness: 1.5,
                //                                 ),
                //                               ],
                //                             );
                //                           }).toList(),
                //                         ),
                //                       ],
                //                     ),
                //                   ));
                //             },
                //           ),
                //         ],
                //       );
                //     })
              ],
            ),
          ),
        ),
      ),
    );
  }
}
