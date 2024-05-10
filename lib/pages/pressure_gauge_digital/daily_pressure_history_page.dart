import 'dart:developer';

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
  List<Map<String, dynamic>> filteredItemTask = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('History', context),
      body: SafeArea(
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
                  final now = DateTime.now();

                  // tidak ada pit
                  return dateTime.year == now.year &&
                      dateTime.month == now.month &&
                      dateTime.day == now.day;
                }).toList();
                return Container();
              })
        ],
      )),
    );
  }
}
