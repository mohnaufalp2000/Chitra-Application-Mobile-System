import 'dart:developer';

import 'package:camos/objectbox.g.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:get/get.dart';

import '../../core/blocs/authentication/authentication_bloc.dart';
import '../../core/blocs/spm/spm_bloc.dart';
import '../../core/navigator/navigation_route.dart';
import '../../core/services/api_service.dart';
import '../../core/services/model/daily_press.dart';
import '../../core/services/shared_preferences/shared_preferences.dart';
import '../../core/styles/asset_path.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/utils/data/spm.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/button_widget.dart';
import '../../core/widgets/text_button_widget.dart';
import '../../core/widgets/tire_widget.dart';
import '../authentication/login_page.dart';
import '../pressure_gauge_digital/daily_check_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';

class TpmsPage extends StatefulWidget {
  static const routeName = '/tpmsPage';
  const TpmsPage({super.key});

  @override
  State<TpmsPage> createState() => _TpmsPageState();
}

class _TpmsPageState extends State<TpmsPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  WebViewController? webViewController;
  List<String> pressureData = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
  ];
  String idSite = '';
  String searchQuery = '';
  List<Map<String, dynamic>> pressures = [];
  List<Map<String, dynamic>> pressureStatus = [];
  List<Map<String, dynamic>> temperatures = [];
  List<List<List<Map<String, dynamic>>>> allUnits = [];
  String siteName = '';
  // List<bool> isShowMore = [];

  // @override
  // void initState() {
  //   super.initState();
  //   context.read<SpmBloc>().add(GetListSpmEvent());
  // }

  void _loadAndFindSite(String idSite) async {
    // 1. Ambil semua data dari cache (cukup sekali saat widget pertama kali dibuat)
    final allSites = await ApiService.getCachedAllSites();

    // 2. Lakukan filtering untuk menemukan site yang cocok
    // Gunakan try-catch untuk menangani kasus jika idSite tidak ditemukan
    try {
      final selectedSite = allSites.firstWhere(
        (site) => site.idSite == idSite,
      );

      // 3. Update state dengan nama site yang ditemukan
      if (mounted) {
        // Pastikan widget masih ada di tree
        setState(() {
          siteName = selectedSite.site ?? '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          siteName = '';
        });
      }
    }
  }

  logoutConfirmation() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Logout Confirmation',
                  style: getBlackTextStyle(
                    fontSize: 16,
                    fontWeight: w600,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'Are you sure you want to logout?',
                  style: getBlackTextStyle(),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    back(context);
                  },
                  child: Text(
                    'No',
                    style: getGreyTextStyle(grey8391A1),
                  )),
              TextButton(
                  onPressed: () async {
                    // removeTireConditionPreferences();
                    // removeTireSpecPreferences();
                    // removeIdSitePreferences();
                    // removeUserPreferences();
                    context
                        .read<AuthenticationBloc>()
                        .add(AuthenticationEventLogout());
                    pushRemoveUntil(context, LoginPage.routeName);
                  },
                  child: Text('Yes')),
            ],
          );
        });
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();

    // final data =
    //     ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    // if (data != null) {
    //   // Pastikan data tidak null
    //   final idSite = data['idSite'];
    //   _loadAndFindSite(idSite);

    //   if (data['isCTS'] != true && data['isCTS'] != null) {
    //     final userDocs = await firestore
    //         .collection('users')
    //         .where('email', isEqualTo: auth.currentUser!.email)
    //         .get();
    //     final mapUser = userDocs.docs[0].data();
    //     saveUserPreferences(mapUser);
    //   }
    //   log('id site spm : $idSite');

    // Pastikan data tidak null
    idSite = (Get.isRegistered<HomeState>())
        ? Get.find<HomeState>().currentSiteId
        : await getIdSitePreferences();
    final user = await getUserPreferences();
    _loadAndFindSite(idSite);

    if (user['isCTS'] != true && user['isCTS'] != null) {
      final userDocs = await firestore
          .collection('users')
          .where('email', isEqualTo: auth.currentUser!.email)
          .get();
      final mapUser = userDocs.docs[0].data();
      saveUserPreferences(mapUser);
    }
    log('id site spm : $idSite');
    context.read<SpmBloc>().add(GetListSpmEvent(idSite: idSite));
  }

  void showWeeklyAdjustmentDialog(
      BuildContext context, String idSite, dynamic unit) {
    // 1. Hitung tanggal 7 hari yang lalu dan ubah ke format ISO String
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final now = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Riwayat Adjustment ${unit.devicename}'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.7,
            child: StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection('adjusment_spm')
                  .where('idSite', isEqualTo: idSite)
                  .where('unit', isEqualTo: unit.devicename)
                  .orderBy('tanggal',
                      descending:
                          true) // Mengurutkan berdasarkan tanggal terbaru
                  .limit(14)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child:
                          Text('Tidak ada data adjustment 7 hari terakhir.'));
                }

                // Semua dokumen 7 hari terakhir
                final allDocs = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: allDocs.length,
                  itemBuilder: (context, index) {
                    final doc = allDocs[index];
                    final Map<String, dynamic> adjustMap =
                        doc.data() as Map<String, dynamic>;

                    // Ambil list posisi, ini diasumsikan tidak null karena sudah difilter
                    final positionList =
                        adjustMap['posisi'] as List<dynamic>? ?? [];

                    // Filter hanya posisi yang memiliki adjusmentPressure
                    final validAdjustments = positionList.where((pl) {
                      return pl['adjusmentPressure'] != null &&
                          pl['adjusmentPressure'].toString().trim().isNotEmpty;
                    }).toList();

                    if (validAdjustments.isEmpty) {
                      // Jika dokumen tidak memiliki adjustment yang valid, lewati item ini
                      return const SizedBox.shrink();
                    }

                    // Format tanggal
                    String formattedDate = '';
                    try {
                      formattedDate =
                          DateFormat('dd MMMM yyyy HH:mm:ss', 'id_ID')
                              .format(DateTime.parse(adjustMap['tanggal']));
                    } catch (_) {
                      formattedDate = 'Tanggal tidak valid';
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header info
                          Text(
                            'Tanggal: $formattedDate',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            'Tireman: ${adjustMap['user'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14),
                          ),

                          const Divider(height: 10, thickness: 1),

                          // List Adjustment Posisi
                          ...validAdjustments.map((pl) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 8.0, bottom: 4.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Pos. ${pl['pos'] ?? 'N/A'}: ${pl['adjusmentPressure']} Psi',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  // Tombol Lihat Gambar
                                  if (pl['image'] != null &&
                                      pl['image'].toString().isNotEmpty)
                                    TextButton(
                                      onPressed: () {
                                        // Fungsi untuk menampilkan gambar (gunakan kode dari query Anda)
                                        showImageDialog(context, pl['image']);
                                      },
                                      child: const Text('Lihat Gambar 🖼️'),
                                    ),
                                ],
                              ),
                            );
                          }).toList(),

                          const Divider(height: 16, color: Colors.grey),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

// Fungsi pembantu untuk menampilkan dialog gambar
  void showImageDialog(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
              ),
            ),
            Positioned(
              top: 8.0,
              right: 8.0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Map<String, dynamic> data =
    //     ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    // log('data before spm : ${data}');

    return Scaffold(
      appBar: appBarWidget('SPM Page', context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                    hintText: 'Search... (Unit ID)',
                    hintStyle: getGreyTextStyle(grey8391A1),
                    prefixIcon: Icon(Icons.search)),
              ),
              const SizedBox(
                height: 12,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(
                        height: 12,
                      ),
                      ButtonWidget(
                          name: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: white,
                              ),
                              SizedBox(
                                width: 12,
                              ),
                              Text(
                                'Refresh',
                                style: getWhiteTextStyle(),
                              ),
                            ],
                          ),
                          function: () {
                            pressures.clear();
                            temperatures.clear();
                            pressureStatus.clear();
                            context
                                .read<SpmBloc>()
                                .add(GetListSpmEvent(idSite: idSite));
                          }),
                      SizedBox(
                        height: 12,
                      ),
                      // Unit
                      BlocConsumer<SpmBloc, SpmState>(
                        listener: (context, state) {},
                        builder: (context, state) {
                          if (state is SpmLoadingState) {
                            return CircularProgressIndicator();
                          }

                          if (state is SpmLoadedState) {
                            List<Spm> list = state.listSpm;
                            List<bool> isShowMore = state.isShowMore;

                            if (list.isEmpty) {
                              return Text(
                                'No Unit Found!',
                                style: getBlackTextStyle(),
                              );
                            }

                            if (searchQuery.length > 0) {
                              list = list.where((element) {
                                return element.devicename
                                    .toString()
                                    .toLowerCase()
                                    .contains(searchQuery.toLowerCase());
                              }).toList();
                            }

                            allUnits.clear();
                            list.forEach((element) {
                              allUnits.add(
                                [
                                  [
                                    {
                                      'pressure1': element.pressure1,
                                    },
                                    {
                                      'pressure2': element.pressure2,
                                    },
                                    {
                                      'pressure3': element.pressure3,
                                    },
                                    {
                                      'pressure4': element.pressure4,
                                    },
                                    {
                                      'pressure5': element.pressure5,
                                    },
                                    {
                                      'pressure6': element.pressure6,
                                    },
                                  ],
                                  [
                                    {
                                      'press1': element.press1,
                                    },
                                    {
                                      'press2': element.press2,
                                    },
                                    {
                                      'press3': element.press3,
                                    },
                                    {
                                      'press4': element.press4,
                                    },
                                    {
                                      'press5': element.press5,
                                    },
                                    {
                                      'press6': element.press6,
                                    },
                                  ],
                                  [
                                    {'temperature1': element.temperature1},
                                    {'temperature2': element.temperature2},
                                    {'temperature3': element.temperature3},
                                    {'temperature4': element.temperature4},
                                    {'temperature5': element.temperature5},
                                    {'temperature6': element.temperature6},
                                  ],
                                  [
                                    {'rating1': element.rating1},
                                    {'rating2': element.rating2},
                                    {'rating3': element.rating3},
                                    {'rating4': element.rating4},
                                    {'rating5': element.rating5},
                                    {'rating6': element.rating6},
                                  ],
                                  [
                                    {
                                      'temp1': element.temp1,
                                    },
                                    {
                                      'temp2': element.temp2,
                                    },
                                    {
                                      'temp3': element.temp3,
                                    },
                                    {
                                      'temp4': element.temp4,
                                    },
                                    {
                                      'temp5': element.temp5,
                                    },
                                    {
                                      'temp6': element.temp6,
                                    },
                                  ],
                                  [
                                    {
                                      'reccAdj1': element.reccAdj1,
                                    },
                                    {
                                      'reccAdj2': element.reccAdj2,
                                    },
                                    {
                                      'reccAdj3': element.reccAdj3,
                                    },
                                    {
                                      'reccAdj4': element.reccAdj4,
                                    },
                                    {
                                      'reccAdj5': element.reccAdj5,
                                    },
                                    {
                                      'reccAdj6': element.reccAdj6,
                                    },
                                  ],
                                ],
                              );
                            });

                            return Column(
                              children: list.map((e) {
                                final unit = list[list.indexOf(e)];
                                final indexUnit = list.indexOf(e);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 24.0),
                                  child: Stack(
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Pos 1, 2
                                          Stack(
                                            children: [
                                              Positioned(
                                                top: 20,
                                                left: 0,
                                                right: 0,
                                                child: Column(
                                                  children: [
                                                    Text(
                                                      unit.devicename ?? '',
                                                      style: getBlackTextStyle(
                                                        fontSize: 18,
                                                        fontWeight: w700,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 4,
                                                    ),
                                                    // FutureBuilder(
                                                    //     future: ApiService.getSite(
                                                    //         idSite),
                                                    //     builder: (context, snapshot) {
                                                    //       final data = snapshot.data;
                                                    //       log('future id site : $data');
                                                    //       if (snapshot
                                                    //               .connectionState ==
                                                    //           ConnectionState
                                                    //               .waiting) {
                                                    //         return Container();
                                                    //       }
                                                    //       return Text(
                                                    //         'Site : ${data?.site ?? ''}',
                                                    //         style: getBlackTextStyle(
                                                    //           fontSize: 14,
                                                    //           fontWeight: w700,
                                                    //         ),
                                                    //       );
                                                    //     }),
                                                    Text(
                                                      'Site : $siteName',
                                                      style:
                                                          getBlackTextStyle(),
                                                    ),
                                                    SizedBox(
                                                      height: 150,
                                                      width: 100,
                                                      child: Image.asset(
                                                          '${imagePath}/dump_truck.png'),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: allUnits[indexUnit][0]
                                                    .map((e) {
                                                  final index =
                                                      allUnits[indexUnit][0]
                                                          .indexOf(e);
                                                  if (index < 2) {
                                                    return Expanded(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                right: (index ==
                                                                        0)
                                                                    // ? 84
                                                                    ? MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.23
                                                                    : 0,
                                                                left: (index ==
                                                                        1)
                                                                    // ? 84
                                                                    ? MediaQuery.of(context)
                                                                            .size
                                                                            .width *
                                                                        0.23
                                                                    : 0),
                                                        child: PressureCard(
                                                          position:
                                                              '${index + 1}',
                                                          // temperature: temperatures[index]
                                                          //         [
                                                          //         'temperature${index + 1}'] ??
                                                          //     '',
                                                          temperature: allUnits[
                                                                          indexUnit]
                                                                      [2][index]
                                                                  [
                                                                  'temperature${index + 1}'] ??
                                                              '',
                                                          // pressureStatus: pressureStatus[
                                                          //             index]
                                                          //         ['press${index + 1}'] ??
                                                          //     '',
                                                          pressureStatus:
                                                              allUnits[indexUnit]
                                                                              [
                                                                              1]
                                                                          [
                                                                          index]
                                                                      [
                                                                      'press${index + 1}'] ??
                                                                  '',
                                                          // pressure:
                                                          //     e['pressure${index + 1}'],
                                                          pressure: allUnits[
                                                                          indexUnit]
                                                                      [0][index]
                                                                  [
                                                                  'pressure${index + 1}'] ??
                                                              '',
                                                          rating: allUnits[
                                                                          indexUnit]
                                                                      [3][index]
                                                                  [
                                                                  'rating${index + 1}'] ??
                                                              '',
                                                          temperatureStatus:
                                                              allUnits[indexUnit]
                                                                              [
                                                                              4]
                                                                          [
                                                                          index]
                                                                      [
                                                                      'temp${index + 1}'] ??
                                                                  '',
                                                          reccAdj: allUnits[
                                                                      indexUnit]
                                                                  [5][index][
                                                              'reccAdj${index + 1}'],
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                  return Container();
                                                }).toList(),
                                              ),
                                            ],
                                          ),
                                          // Pos 3, 4, 5, 6
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: List.generate(
                                                allUnits[indexUnit][0].length -
                                                    2, (index) {
                                              final dataIndex = index + 2;
                                              return Expanded(
                                                child: PressureCard(
                                                  position: '${dataIndex + 1}',
                                                  index: index,
                                                  // temperature: temperatures[dataIndex]
                                                  //         ['temperature${dataIndex + 1}'] ??
                                                  //     '',
                                                  temperature: allUnits[
                                                                  indexUnit][2]
                                                              [dataIndex][
                                                          'temperature${dataIndex + 1}'] ??
                                                      '',
                                                  // pressureStatus: pressureStatus[dataIndex]
                                                  //         ['press${dataIndex + 1}'] ??
                                                  //     '',
                                                  pressureStatus: allUnits[
                                                                  indexUnit][1]
                                                              [dataIndex][
                                                          'press${dataIndex + 1}'] ??
                                                      '',
                                                  // pressure: pressures[dataIndex]
                                                  //     ['pressure${dataIndex + 1}'],
                                                  pressure: allUnits[indexUnit]
                                                              [0][dataIndex][
                                                          'pressure${dataIndex + 1}'] ??
                                                      '',
                                                  rating: allUnits[indexUnit][3]
                                                              [dataIndex][
                                                          'rating${dataIndex + 1}'] ??
                                                      '',
                                                  temperatureStatus: allUnits[
                                                                  indexUnit][4]
                                                              [dataIndex][
                                                          'temp${dataIndex + 1}'] ??
                                                      '',
                                                  reccAdj: allUnits[indexUnit]
                                                              [5][dataIndex][
                                                          'reccAdj${dataIndex + 1}'] ??
                                                      '',
                                                ),
                                              );
                                            }),
                                          ),
                                          // GridView.builder(
                                          //   itemCount: allUnits[indexUnit][0].length -
                                          //       2, // Mengurangi 2 untuk menghilangkan index pertama dan kedua
                                          //   shrinkWrap: true,
                                          //   physics: NeverScrollableScrollPhysics(),
                                          //   gridDelegate:
                                          //       SliverGridDelegateWithFixedCrossAxisCount(
                                          //     crossAxisCount: 4,
                                          //     childAspectRatio: 0.4,
                                          //     mainAxisSpacing: 3,
                                          //   ),
                                          //   itemBuilder: (context, index) {
                                          //     // Memperhitungkan offset karena index pertama dan kedua diabaikan
                                          //     final dataIndex = index + 2;

                                          //     return PressureCard(
                                          //       position: '${dataIndex + 1}',
                                          //       index: index,
                                          //       // temperature: temperatures[dataIndex]
                                          //       //         ['temperature${dataIndex + 1}'] ??
                                          //       //     '',
                                          //       temperature: allUnits[indexUnit][2]
                                          //                   [dataIndex]
                                          //               ['temperature${dataIndex + 1}'] ??
                                          //           '',
                                          //       // pressureStatus: pressureStatus[dataIndex]
                                          //       //         ['press${dataIndex + 1}'] ??
                                          //       //     '',
                                          //       pressureStatus: allUnits[indexUnit][1]
                                          //                   [dataIndex]
                                          //               ['press${dataIndex + 1}'] ??
                                          //           '',
                                          //       // pressure: pressures[dataIndex]
                                          //       //     ['pressure${dataIndex + 1}'],
                                          //       pressure: allUnits[indexUnit][0]
                                          //                   [dataIndex]
                                          //               ['pressure${dataIndex + 1}'] ??
                                          //           '',
                                          //     );
                                          //   },
                                          // ),
                                          const SizedBox(
                                            height: 12,
                                          ),

                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                children: [
                                                  Row(
                                                    children: [
                                                      Icon(Icons.schedule),
                                                      const SizedBox(
                                                        width: 12,
                                                      ),
                                                      Text(
                                                        DateFormat(
                                                                'dd MMMM yyyy  HH:mm:ss',
                                                                'id_ID')
                                                            .format(DateTime.parse(
                                                                unit.timestamp ??
                                                                    '')),
                                                        style:
                                                            getBlackTextStyle(),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 12,
                                                  ),
                                                  Row(
                                                    children: [
                                                      Icon(Icons.location_on),
                                                      const SizedBox(
                                                        width: 12,
                                                      ),
                                                      Text(
                                                        '${unit.lat},${unit.lon} | ${unit.alt}',
                                                        style:
                                                            getBlackTextStyle(),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              Column(
                                                children: [
                                                  Text(
                                                    'Designed By: ',
                                                    style: getBlackTextStyle(
                                                      fontWeight: w700,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    height: 50,
                                                    width: 100,
                                                    child: Image.asset(
                                                        '${imagePath}/cp_logo_image.png'),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          const SizedBox(
                                            height: 12,
                                          ),
                                          SizedBox(
                                            height: 80,
                                            child: ButtonWidget(
                                              color: Colors.orange,
                                              name: Row(
                                                children: [
                                                  Icon(
                                                    Icons.adjust,
                                                    color: white,
                                                  ),
                                                  const SizedBox(
                                                    width: 6,
                                                  ),
                                                  Text(
                                                    'Adjust Pressure',
                                                    style: getWhiteTextStyle(
                                                        fontWeight: w700),
                                                  ),
                                                ],
                                              ),
                                              function: () async {
                                                if (!Get.isRegistered<
                                                    HomeState>()) {
                                                  Get.put(HomeState());
                                                }
                                                List<Position> position = [
                                                  Position(
                                                    pos: '1',
                                                    pressure:
                                                        '${allUnits[indexUnit][0][0]['pressure1']}',
                                                    rating: '',
                                                    adjusmentPressure: '',
                                                    luka: [],
                                                    image: '',
                                                    size: '',
                                                    idUnit: '',
                                                    idInventory: '',
                                                    idDaily: '',
                                                    kondisi: '',
                                                  ),
                                                  Position(
                                                    pos: '2',
                                                    pressure:
                                                        '${allUnits[indexUnit][0][1]['pressure2']}',
                                                    rating: '',
                                                    adjusmentPressure: '',
                                                    luka: [],
                                                    image: '',
                                                    size: '',
                                                    idUnit: '',
                                                    idInventory: '',
                                                    idDaily: '',
                                                    kondisi: '',
                                                  ),
                                                  Position(
                                                    pos: '3',
                                                    pressure:
                                                        '${allUnits[indexUnit][0][2]['pressure3']}',
                                                    rating: '',
                                                    adjusmentPressure: '',
                                                    luka: [],
                                                    image: '',
                                                    size: '',
                                                    idUnit: '',
                                                    idInventory: '',
                                                    idDaily: '',
                                                    kondisi: '',
                                                  ),
                                                  Position(
                                                    pos: '4',
                                                    pressure:
                                                        '${allUnits[indexUnit][0][3]['pressure4']}',
                                                    rating: '',
                                                    adjusmentPressure: '',
                                                    luka: [],
                                                    image: '',
                                                    size: '',
                                                    idUnit: '',
                                                    idInventory: '',
                                                    idDaily: '',
                                                    kondisi: '',
                                                  ),
                                                  Position(
                                                    pos: '5',
                                                    pressure:
                                                        '${allUnits[indexUnit][0][4]['pressure5']}',
                                                    rating: '',
                                                    adjusmentPressure: '',
                                                    luka: [],
                                                    image: '',
                                                    size: '',
                                                    idUnit: '',
                                                    idInventory: '',
                                                    idDaily: '',
                                                    kondisi: '',
                                                  ),
                                                  Position(
                                                    pos: '6',
                                                    pressure:
                                                        '${allUnits[indexUnit][0][5]['pressure6']}',
                                                    rating: '',
                                                    adjusmentPressure: '',
                                                    luka: [],
                                                    image: '',
                                                    size: '',
                                                    idUnit: '',
                                                    idInventory: '',
                                                    idDaily: '',
                                                    kondisi: '',
                                                  ),
                                                ];

                                                final user =
                                                    await getUserPreferences();

                                                Navigator.pushNamed(
                                                    context,
                                                    DailyCheckFormPage
                                                        .routeName,
                                                    arguments: {
                                                      'unitNumber':
                                                          unit.devicename,
                                                      'type': 'spm',
                                                      'position': position,
                                                      'isCTS': user['isCTS']
                                                    });
                                              },
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.adjust),
                                                  const SizedBox(
                                                    width: 6,
                                                  ),
                                                  Text(
                                                    'Last Adjustment',
                                                    style: getBlackTextStyle(
                                                        fontWeight: w700),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 6,
                                          ),

                                          SizedBox(
                                            width: double.infinity,
                                            child: ButtonWidget(
                                              color: Colors.green,
                                              function: () {
                                                // Panggil fungsi dialog yang baru dibuat
                                                showWeeklyAdjustmentDialog(
                                                    context, idSite, unit);
                                              },
                                              name: Text(
                                                'Show Last Adjustment',
                                                style: getWhiteTextStyle(),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 6,
                                          ),

                                          // Builder(builder: (context) {
                                          //   if (isShowMore[indexUnit]) {
                                          //     return StreamBuilder<
                                          //         QuerySnapshot>(
                                          //       stream: firestore
                                          //           .collection('adjusment_spm')
                                          //           .where('idSite',
                                          //               isEqualTo: idSite)
                                          //           .where('unit',
                                          //               isEqualTo:
                                          //                   unit.devicename)
                                          //           .where('tanggal',
                                          //               isGreaterThanOrEqualTo:
                                          //                   DateTime.now()
                                          //                       .subtract(
                                          //                           const Duration(
                                          //                               days:
                                          //                                   7))
                                          //                       .toIso8601String())
                                          //           .orderBy('tanggal',
                                          //               descending:
                                          //                   true) // Mengurutkan berdasarkan tanggal terbaru
                                          //           .limit(
                                          //               1) // Hanya mengambil 1 data terbaru
                                          //           .snapshots(),
                                          //       builder: (context, snapshot) {
                                          //         if (snapshot
                                          //                 .connectionState ==
                                          //             ConnectionState.waiting) {
                                          //           return Center(
                                          //               child:
                                          //                   CircularProgressIndicator());
                                          //         }
                                          //         if (!snapshot.hasData ||
                                          //             snapshot
                                          //                 .data!.docs.isEmpty) {
                                          //           return Container(
                                          //             margin: EdgeInsets.only(
                                          //                 bottom: 12),
                                          //             child: Center(
                                          //                 child: Text(
                                          //                     'No data available')),
                                          //           );
                                          //         }

                                          //         final latestDoc =
                                          //             snapshot.data!.docs.first;
                                          //         final Map<String, dynamic>
                                          //             latestAdjustMap =
                                          //             latestDoc.data() as Map<
                                          //                 String, dynamic>;
                                          //         final positionList =
                                          //             latestAdjustMap['posisi']
                                          //                 as List<dynamic>;

                                          //         bool adjustmentEmpty =
                                          //             positionList.any((item) =>
                                          //                 item['adjusmentPressure'] !=
                                          //                     null &&
                                          //                 item['adjusmentPressure']
                                          //                     .toString()
                                          //                     .trim()
                                          //                     .isNotEmpty);

                                          //         if (!adjustmentEmpty) {
                                          //           print('data adjust kosong');
                                          //           return Center(
                                          //             child: Container(
                                          //               margin: EdgeInsets.only(
                                          //                   bottom: 12),
                                          //               child: Text(
                                          //                 'No data available',
                                          //                 style:
                                          //                     getBlackTextStyle(),
                                          //               ),
                                          //             ),
                                          //           );
                                          //         }

                                          //         return Column(
                                          //           crossAxisAlignment:
                                          //               CrossAxisAlignment
                                          //                   .start,
                                          //           children: [
                                          //             Text(
                                          //               'Tireman : ${latestAdjustMap['user']}',
                                          //               style:
                                          //                   getBlackTextStyle(
                                          //                 fontSize: 18,
                                          //               ),
                                          //             ),
                                          //             const SizedBox(
                                          //               height: 12,
                                          //             ),
                                          //             // timelowpressure BIKIN ERROR
                                          //             if (latestAdjustMap[
                                          //                     'timeLowPressureSPM'] !=
                                          //                 null)
                                          //               Text(
                                          //                 'Last Event Low Pressure : ${DateFormat('dd MMMM yyyy  HH:mm:ss', 'id_ID').format(DateTime.parse(latestAdjustMap['timeLowPressureSPM']))}',
                                          //               )
                                          //             else
                                          //               SizedBox.shrink(),

                                          //             const SizedBox(
                                          //               height: 12,
                                          //             ),
                                          //             Column(
                                          //               children: positionList
                                          //                   .map((pl) {
                                          //                 if (pl['adjusmentPressure'] ==
                                          //                         '' ||
                                          //                     pl['adjusmentPressure'] ==
                                          //                         null) {
                                          //                   return Container();
                                          //                 }

                                          //                 return Column(
                                          //                   crossAxisAlignment:
                                          //                       CrossAxisAlignment
                                          //                           .start,
                                          //                   children: [
                                          //                     Row(
                                          //                       mainAxisAlignment:
                                          //                           MainAxisAlignment
                                          //                               .spaceBetween,
                                          //                       children: [
                                          //                         Text(
                                          //                           'Pos. ${pl['pos']} : ${pl['adjusmentPressure']} Psi',
                                          //                           style: getBlackTextStyle(
                                          //                               fontSize:
                                          //                                   16),
                                          //                         ),
                                          //                         const SizedBox(
                                          //                             width: 6),
                                          //                         Text(
                                          //                           DateFormat(
                                          //                                   'dd MMMM yyyy  HH:mm:ss',
                                          //                                   'id_ID')
                                          //                               .format(
                                          //                                   DateTime.parse(latestAdjustMap['tanggal'])),
                                          //                           style: getBlackTextStyle(
                                          //                               fontSize:
                                          //                                   16),
                                          //                         ),
                                          //                       ],
                                          //                     ),
                                          //                     (pl['image'] !=
                                          //                                 '' &&
                                          //                             pl['image'] !=
                                          //                                 null)
                                          //                         ? Container(
                                          //                             padding: EdgeInsets
                                          //                                 .only(
                                          //                                     top: 8),
                                          //                             width: double
                                          //                                 .infinity,
                                          //                             child:
                                          //                                 ElevatedButton(
                                          //                               onPressed:
                                          //                                   () {
                                          //                                 showDialog(
                                          //                                   context:
                                          //                                       context,
                                          //                                   builder: (context) =>
                                          //                                       Dialog(
                                          //                                     child: Stack(
                                          //                                       children: [
                                          //                                         InteractiveViewer(
                                          //                                           child: Image.network(
                                          //                                             pl['image'],
                                          //                                             fit: BoxFit.contain,
                                          //                                           ),
                                          //                                         ),
                                          //                                         Positioned(
                                          //                                           top: 8.0,
                                          //                                           right: 8.0,
                                          //                                           child: IconButton(
                                          //                                             icon: Icon(Icons.close, color: Colors.black),
                                          //                                             onPressed: () {
                                          //                                               Navigator.of(context).pop();
                                          //                                             },
                                          //                                           ),
                                          //                                         ),
                                          //                                       ],
                                          //                                     ),
                                          //                                   ),
                                          //                                 );
                                          //                               },
                                          //                               style: ElevatedButton
                                          //                                   .styleFrom(
                                          //                                 backgroundColor:
                                          //                                     Colors.orange,
                                          //                               ),
                                          //                               child:
                                          //                                   Padding(
                                          //                                 padding: const EdgeInsets
                                          //                                     .all(
                                          //                                     8.0),
                                          //                                 child:
                                          //                                     Row(
                                          //                                   mainAxisAlignment:
                                          //                                       MainAxisAlignment.center,
                                          //                                   children: [
                                          //                                     const Icon(Icons.photo, color: white),
                                          //                                     const SizedBox(width: 8),
                                          //                                     Text(
                                          //                                       'Show Image',
                                          //                                       style: getWhiteTextStyle(fontWeight: w700, fontSize: 18),
                                          //                                     ),
                                          //                                   ],
                                          //                                 ),
                                          //                               ),
                                          //                             ),
                                          //                           )
                                          //                         : Container(),
                                          //                     const Padding(
                                          //                       padding: EdgeInsets
                                          //                           .symmetric(
                                          //                               vertical:
                                          //                                   8.0),
                                          //                       child:
                                          //                           Divider(),
                                          //                     )
                                          //                   ],
                                          //                 );
                                          //               }).toList(),
                                          //             ),
                                          //           ],
                                          //         );
                                          //       },
                                          //     );
                                          //   }
                                          //   return Container();
                                          // }),

                                          // const SizedBox(
                                          //   height: 12,
                                          // ),
                                          Row(
                                            children: [
                                              Expanded(
                                                  child: SizedBox(
                                                height: 80,
                                                child: ButtonWidget(
                                                    color: blue344BEF,
                                                    name: Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.copy,
                                                          color: white,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          'Copy Location',
                                                          style:
                                                              getWhiteTextStyle(
                                                                  fontWeight:
                                                                      w700),
                                                        ),
                                                      ],
                                                    ),
                                                    function: () {
                                                      Clipboard.setData(
                                                          ClipboardData(
                                                              text:
                                                                  '${unit.lat},${unit.lon}'));
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .hideCurrentSnackBar();
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                              SnackBar(
                                                                  content: Text(
                                                        'Location copied! You can now paste it anywhere.',
                                                        style:
                                                            getWhiteTextStyle(),
                                                      )));
                                                    }),
                                              )),
                                              const SizedBox(
                                                width: 6,
                                              ),
                                              Expanded(
                                                  child: SizedBox(
                                                height: 80,
                                                child: ButtonWidget(
                                                    color: Colors.red,
                                                    name: Row(
                                                      children: [
                                                        Icon(
                                                          Icons.map,
                                                          color: white,
                                                        ),
                                                        const SizedBox(
                                                          width: 6,
                                                        ),
                                                        SizedBox(
                                                          width: 90,
                                                          child: Text(
                                                            'Open with Google Maps',
                                                            style:
                                                                getWhiteTextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        w700),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    function: () async {
                                                      await launchUrl(Uri.parse(
                                                          'https://www.google.com/maps?q=${unit.lat},${unit.lon}'));
                                                    }),
                                              )),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 24,
                                          ),
                                          Divider(
                                            thickness: 2,
                                            color: black,
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.height *
                                                0.6,
                                        width:
                                            MediaQuery.of(context).size.height *
                                                0.9,
                                        child: Opacity(
                                          opacity:
                                              0.06, // Nilai dari 0.0 (transparan) sampai 1.0 (penuh)
                                          child: Image.asset(
                                              '${imagePath}/cp_logo_vertical_image.png'),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          }

                          return Container();
                        },
                      ),
                      // event
                      // Card(
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(4),
                      //   ),
                      //   color: Colors.red,
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: <Widget>[
                      //       Container(
                      //         padding: const EdgeInsets.all(15),
                      //         child: Column(
                      //           crossAxisAlignment: CrossAxisAlignment.start,
                      //           children: <Widget>[
                      //             const Text(
                      //               "- Position 3 Low Tire Pressure",
                      //               style:
                      //                   TextStyle(fontSize: 16, color: Colors.white),
                      //             ),
                      //             Container(height: 10),
                      //             const Text(
                      //               "- Position 4 Low Tire Pressure",
                      //               style:
                      //                   TextStyle(fontSize: 16, color: Colors.white),
                      //             ),
                      //           ],
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PressureCard extends StatelessWidget {
  const PressureCard({
    super.key,
    required this.position,
    this.index = -1,
    required this.pressure,
    required this.pressureStatus,
    required this.temperature,
    required this.rating,
    required this.temperatureStatus,
    required this.reccAdj,
  });

  final String position;
  final int index;
  final String pressure;
  final String temperature;
  final String pressureStatus;
  final String rating;
  final String temperatureStatus;
  final String reccAdj;

  @override
  Widget build(BuildContext context) {
    final bool isCold = temperatureStatus == '0';
    final Color thermalColor = isCold ? Colors.blue : Colors.red;
    final IconData thermalIcon =
        isCold ? Icons.ac_unit : Icons.local_fire_department;

    return Card(
      elevation: 2,
      child: Container(
        child: Column(
          children: [
            // ================= HEADER =================
            Container(
              padding: EdgeInsets.all(12),
              height: MediaQuery.of(context).size.height * 0.103,
              width: double.infinity,
              decoration: BoxDecoration(
                color: (pressureStatus == '2')
                    ? Color(0xff9C27B0)
                    : (pressureStatus == '1')
                        ? green00968A
                        : (pressureStatus == '0' && pressure != '0')
                            ? Colors.red
                            : black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      position,
                      style: getWhiteTextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    (pressureStatus == '2')
                        ? Text(
                            'Over',
                            style: getWhiteTextStyle(
                                fontSize: 10, fontWeight: w700),
                          )
                        : (pressureStatus == '0')
                            ? (pressure != '0')
                                ? Text(
                                    'Low',
                                    style: getWhiteTextStyle(
                                      fontSize: 10,
                                    ),
                                  )
                                : Container()
                            : Container()
                  ],
                ),
              ),
            ),

            // ================= PRESSURE =================
            (pressureStatus == '1')
                ? Column(
                    children: [
                      Text(
                        pressure,
                        style: getBlackTextStyle(fontSize: 22),
                      ),
                      Text(
                        'Psi',
                        style: getBlackTextStyle(fontSize: 22),
                      ),
                    ],
                  )
                : (pressure == '0')
                    ? Column(
                        children: [
                          Text(
                            pressure,
                            style: getBlackTextStyle(fontSize: 22),
                          ),
                          Text(
                            'Psi',
                            style: getBlackTextStyle(fontSize: 22),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '$pressure Psi',
                            textAlign: TextAlign.center,
                            style: getBlackTextStyle(fontSize: 22),
                          ),
                          Text(
                            'Rec. pressure $reccAdj Psi',
                            textAlign: TextAlign.center,
                            style:
                                getRedTextStyle(fontSize: 10, fontWeight: w700),
                          ),
                        ],
                      ),

            const Divider(),

            // ================= TEMPERATURE =================
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$temperature °C',
                    style: getBlackTextStyle(fontSize: 16)
                        .copyWith(color: thermalColor),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    thermalIcon,
                    color: thermalColor,
                    size: 24,
                  ),
                ],
              ),
            ),

            // ================= RATING (OPTIONAL) =================
            if (rating != 'N/A' && rating != '' && rating != null)
              Column(
                children: [
                  const Divider(),
                  Text('Rat. $rating', style: getBlackTextStyle(fontSize: 24)),
                ],
              ),

            const SizedBox(height: 6),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// class PressureCard extends StatelessWidget {
//   const PressureCard({
//     super.key,
//     required this.position,
//     this.index = -1,
//     required this.pressure,
//     required this.pressureStatus,
//     required this.temperature,
//     required this.rating,
//   });

//   final String position;
//   final int index;
//   final String pressure;
//   final String temperature;
//   final String pressureStatus;
//   final String rating;

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       elevation: 2,
//       child: Container(
//         child: Column(
//           children: [
//             Container(
//                 padding: EdgeInsets.all(12),
//                 width: double.infinity,
//                 decoration: BoxDecoration(
//                     color: (pressureStatus == '1')
//                         ? green00968A
//                         : (pressureStatus == '0' && pressure != '0')
//                             ? Colors.red
//                             : black,
//                     borderRadius: BorderRadius.only(
//                         topLeft: Radius.circular(12),
//                         topRight: Radius.circular(12))),
//                 child: Center(
//                   child: Text(
//                     position,
//                     style: getWhiteTextStyle(fontSize: 36, fontWeight: w700),
//                   ),
//                 )),
//             Column(
//               children: [
//                 Text(
//                   pressure,
//                   style: getBlackTextStyle(fontSize: 24),
//                 ),
//                 Text('Psi', style: getBlackTextStyle(fontSize: 24)),
//               ],
//             ),
//             const Divider(),
//             Text('$temperature °C', style: getBlackTextStyle(fontSize: 24)),
//             if (rating != 'N/A' || rating == null || rating == '')
//               Column(
//                 children: [
//                   const Divider(),
//                   Text('Rat. $rating', style: getBlackTextStyle(fontSize: 24))
//                 ],
//               )
//             else
//               Container()
//           ],
//         ),
//       ),
//     );
//   }
// }
