import 'dart:developer';

import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';

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
  List<Map<String, dynamic>> filteredItemTask = [];

  @override
  void initState() {
    super.initState();

    final yesterday = DateTime.now().subtract(Duration(days: 1));
    String formattedDate =
        "${yesterday.year}-${(yesterday.month).toString().padLeft(2, '0')}-${(yesterday.day).toString().padLeft(2, '0')}";
    log('tanggal kemarin : $formattedDate');
    getIdSite();
  }

  getIdSite() async {
    idSite = await getIdSitePreferences();
    if (idSite == '1') {
      idSite = await getSelectedIdSitePreferences();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                DateTime.now().subtract(Duration(days: 5)),
                height: 100,
                width: 80,
                daysCount: 5,
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

                    // Get date part from DateTime object
                    DateTime dateOnly =
                        DateTime(dateTime.year, dateTime.month, dateTime.day);

                    // Format date as desired
                    String formattedDate =
                        "${dateOnly.year}-${(dateOnly.month).toString().padLeft(2, '0')}-${(dateOnly.day).toString().padLeft(2, '0')}";
                    final formattedDateTime = DateTime.parse(formattedDate);

                    // tidak ada pit
                    return formattedDateTime.year == selectedDate.year &&
                        formattedDateTime.month == selectedDate.month &&
                        data['idSite'] == idSite &&
                        formattedDateTime.day == selectedDate.day;
                  }).toList();
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

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Card(
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
                                )),
                          );
                        },
                      ),
                    ],
                  );
                })
          ],
        ),
      )),
    );
  }
}
