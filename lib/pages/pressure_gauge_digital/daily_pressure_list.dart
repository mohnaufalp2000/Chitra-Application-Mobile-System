import 'dart:developer';

import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class DailyPressureListPage extends StatefulWidget {
  static const routeName = '/daily-pressure-list-page';
  const DailyPressureListPage({super.key});

  @override
  State<DailyPressureListPage> createState() => _DailyPressureListPageState();
}

class _DailyPressureListPageState extends State<DailyPressureListPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  List<String> pit = [];
  int selectedPit = 0;
  String searchQuery = '';
  List<Map<String, dynamic>> filteredItemTask = [];

  @override
  void initState() {
    super.initState();

    insertPit();
  }

  insertPit() async {
    String idSite = await getIdSitePreferences();
    if (idSite == '1') {
      idSite = await getSelectedIdSitePreferences();
    }
    setState(() {
      // BMB COYYY
      if (idSite == '52') {
        pit.add('Utara');
        pit.add('Selatan');
        pit.add('RML');
      }
    });
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
                Row(
                  children: pit.map((e) {
                    final pitIndex = pit.indexOf(e);
                    return Expanded(
                        child: Padding(
                      padding: EdgeInsets.only(
                          right: (pitIndex == 0) ? 12 : 0,
                          left: (pitIndex == pit.length - 1) ? 12 : 0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: (selectedPit == pitIndex)
                                ? Colors.orange
                                : greyF7F8F9),
                        onPressed: () {
                          setState(() {
                            selectedPit = pitIndex;
                          });
                        },
                        child: Text(
                          e,
                          style: (selectedPit == pitIndex)
                              ? getWhiteTextStyle()
                              : getBlackTextStyle(),
                        ),
                      ),
                    ));
                  }).toList(),
                ),
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
                        final file =
                            await createFolderPath(id.v4(), 'daily-check');
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

                      // ada pit
                      if (data['pit'] != 'Default') {
                        return dateTime.year == now.year &&
                            dateTime.month == now.month &&
                            dateTime.day == now.day &&
                            data['pit'] == pit[selectedPit];
                      }

                      // tidak ada pit
                      return dateTime.year == now.year &&
                          dateTime.month == now.month &&
                          dateTime.day == now.day;
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

                      filteredItemTask.add(cast);
                    });
                    log('dailyexcel: $filteredItemTask');

                    return Column(
                      children: [
                        const SizedBox(
                          height: 12,
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: filteredDocument.length,
                          itemBuilder: (context, index) {
                            final Map<String, dynamic> dailyMap =
                                filteredDocument[index].data()
                                    as Map<String, dynamic>;
                            final positionList =
                                dailyMap['posisi'] as List<dynamic>;

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
                                              fontWeight: w700, fontSize: 24),
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
                                          log('hohoho : ${pl}');
                                          final plIndex =
                                              positionList.indexOf(pl);
                                          List<dynamic> luka = [];
                                          if (pl['luka'] != null) {
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
                                                      Text(
                                                        '${pl['pressure']} Psi',
                                                        style:
                                                            getWhiteTextStyle(
                                                                fontWeight:
                                                                    w700,
                                                                fontSize: 18),
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
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
