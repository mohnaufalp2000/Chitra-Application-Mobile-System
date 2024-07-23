import 'dart:developer';

import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_history_page.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_check_form_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
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
  int selectedMenu = 1;
  String searchQuery = '';
  Map<String, dynamic> user = {};
  List<Map<String, dynamic>> filteredItemTask = [];
  List<UnitTire> units = [];

  @override
  void initState() {
    super.initState();

    insertPit();
    getUser();
  }

  Future<void> getUnits() async {
    log('id site : $idSite');

    // jika user office tidak perlu ambil dari cache
    if (await getIdSitePreferences() != '1') {
      // belum ganti bulan

      if (await getSavedMonthYear() ==
          "${DateTime.now().year}-${DateTime.now().month}") {
        units = await ApiService.getCachedUnits();
      } else {
        // sudah ganti bulan
        units = await ApiService.getUnits(idSite);
      }
    } else {
      units = await ApiService.getUnits(idSite);
    }
  }

  getUser() async {
    user = await getUserPreferences();
    log('username : ${user}');
  }

  insertPit() async {
    idSite = await getIdSitePreferences();
    actualIdSite = await getIdSitePreferences();
    if (idSite == '1') {
      idSite = await getSelectedIdSitePreferences();
    }
    getUnits();
  }

  @override
  Widget build(BuildContext context) {
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                      onPressed: () async {
                        final id = Uuid();
                        // print('tugas : $filteredItemTask');
                        // print('terpesona $filteredItemTask');
                        // final file = await createFolderPath(id.v4(), 'outstanding');
                        final file = await createFolderPath(
                            id.v4(), 'daily-check',
                            email: user['email'] ?? '',
                            site: user['siteName'] ?? '',
                            date:
                                "${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}-${DateTime.now().year}");

                        final bytes = await createExcel('daily-check',
                            daily: filteredItemTask);
                        final saved =
                            await file.writeAsBytes(bytes, flush: true);
                        // print('laper : $saved');
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            backgroundColor: green00968A,
                            content: Text(
                              'Successfull Save Data!',
                              style: getWhiteTextStyle(),
                            )));
                        final result = await OpenFile.open(file.path);

                        if (result.type == ResultType.done) {
                          print('File berhasil dibuka');
                        } else {
                          print(result.message);
                          if (result.type == ResultType.noAppToOpen) {
                            openPlayStore('attendance');
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue),
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.table_chart,
                              color: Colors.white,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              'Export to Excel',
                              style: getWhiteTextStyle(),
                            ),
                          ],
                        ),
                      )),
                ),
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
                StreamBuilder(
                    stream: firestore.collection('daily_pressure').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      }

                      List<DocumentSnapshot> documents = snapshot.data!.docs;

                      if (searchQuery.length > 0) {
                        documents = documents.where((element) {
                          return element
                              .get('unit')
                              .toString()
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase());
                        }).toList();
                      }

                      final filteredDocument = documents.where((doc) {
                        final Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;

                        final dateString = data['tanggal'] as String;
                        final dateTime = DateTime.parse(dateString);
                        final now = DateTime.now();

                        // tidak ada pit
                        return dateTime.year == now.year &&
                            dateTime.month == now.month &&
                            dateTime.day == now.day &&
                            data['idSite'] == idSite;
                      }).toList();

                      filteredDocument.sort((a, b) {
                        Map<String, dynamic> first =
                            a.data() as Map<String, dynamic>;
                        Map<String, dynamic> second =
                            b.data() as Map<String, dynamic>;
                        ;
                        // Ambil nilai last_update dari masing-masing DocumentSnapshot
                        DateTime timeA = DateTime.parse(first['tanggal']);
                        DateTime timeB = DateTime.parse(second['tanggal']);

                        // Bandingkan waktu last_update dari kedua DocumentSnapshot
                        return timeB.compareTo(
                            timeA); // Dari yang terbaru ke yang terlama
                      });

                      // untuk data export excel
                      filteredItemTask.clear();
                      filteredDocument.forEach((item) {
                        Map<String, dynamic> cast =
                            item.data() as Map<String, dynamic>;

                        units.removeWhere(
                            (element) => element.unitNumber == cast['unit']);
                        filteredItemTask.add(cast);
                      });
                      log('dailyexcel: $filteredItemTask');
                      log('jumlah kendaraan : ${units.length}');

                      return Column(
                        children: [
                          const SizedBox(
                            height: 12,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(
                              (selectedMenu == 0)
                                  ? 'Total Unit : ${filteredDocument.length}'
                                  : 'Total Unit : ${units.length}',
                              style: getBlackTextStyle(fontSize: 20),
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: (selectedMenu == 0)
                                ? filteredDocument.length
                                : units.length,
                            itemBuilder: (context, index) {
                              if (selectedMenu == 0) {
                                final Map<String, dynamic> dailyMap =
                                    filteredDocument[index].data()
                                        as Map<String, dynamic>;
                                final positionList =
                                    dailyMap['posisi'] as List<dynamic>;

                                log('subsub : $positionList');

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
                                              dailyMap['unit'],
                                              style: getWhiteTextStyle(
                                                  fontWeight: w700,
                                                  fontSize: 24),
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
                              } else {
                                final item = units[index];
                                if (searchQuery.isNotEmpty &&
                                    !item.unitNumber!
                                        .toLowerCase()
                                        .contains(searchQuery) &&
                                    !item.model!
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
                                                'unitNumber': item.unitNumber,
                                              });
                                        },
                                  child: Container(
                                    margin: EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    padding: EdgeInsets.symmetric(vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
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
                                            const EdgeInsets.only(bottom: 4.0),
                                        child: Text(
                                          '${item.unitNumber}',
                                          style: getBlackTextStyle(
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                      trailing: Icon(Icons.arrow_forward_ios),
                                    ),
                                  ),
                                );
                              }
                              return Container();
                            },
                          ),
                        ],
                      );
                    })
              ],
            ),
          ),
        ),
      ),
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
