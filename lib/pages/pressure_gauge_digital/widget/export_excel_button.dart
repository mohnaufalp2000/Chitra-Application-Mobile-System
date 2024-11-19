import 'dart:developer';

import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/enum_export_type.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class ExportExcelButton extends StatefulWidget {
  const ExportExcelButton({
    super.key,
    required this.user,
    required this.pit,
    required this.selectedPit,
    required this.filteredItemTask,
    required this.date,
    required this.type,
  });

  final Map<String, dynamic> user;
  final List<String> pit;
  final int selectedPit;
  final List<Map<String, dynamic>> filteredItemTask;
  final String date;
  final String type;

  @override
  State<ExportExcelButton> createState() => _ExportExcelButtonState();
}

class _ExportExcelButtonState extends State<ExportExcelButton> {
  List<bool> selectedMonths = List.generate(12, (index) => false);
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isLoading = false; // Tambahkan variabel untuk indikator loading

  final List<String> months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  void _showDateRangePicker(
      BuildContext context, Function(List<DateTime>) onDatesSelected) async {
    DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023, 1, 1),
      lastDate: DateTime(2024, 12, 31),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          switch (widget.type) {
            case ExportType.oneDay:
              final id = Uuid();
              final file = await createFolderPath(id.v4(), 'daily-check',
                  email: widget.user['email'] ?? '',
                  site: widget.user['siteName'] ?? '',
                  pit: (widget.pit.isNotEmpty)
                      ? widget.pit[widget.selectedPit]
                      : '',
                  date: widget.date);

              final bytes = await createExcel('daily-check',
                  daily: widget.filteredItemTask);
              final saved = await file.writeAsBytes(bytes, flush: true);
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
              break;
            case ExportType.multipleDay:
              List<Map<String, dynamic>> excelItemTask = [];
              _showDateRangePicker(context, (selectedMonths) async {
                setState(() {
                  _isLoading = true; // Tampilkan loading
                });
                try {
                  final firstPicked = selectedMonths[0];
                  final lastPicked = selectedMonths[selectedMonths.length - 1];
                  final snapshot = await firestore
                      .collection('daily_pressure')
                      .where('idSite',
                          isEqualTo: widget.filteredItemTask[0]['idSite'])
                      .where('tanggal',
                          isGreaterThanOrEqualTo: DateTime(firstPicked.year,
                                  firstPicked.month, firstPicked.day)
                              .toIso8601String())
                      .where('tanggal',
                          isLessThanOrEqualTo: DateTime(lastPicked.year,
                                  lastPicked.month, lastPicked.day, 23, 59, 59)
                              .toIso8601String())
                      .get();

                  snapshot.docs.forEach((data) {
                    final dataDaily = data.data() as Map<String, dynamic>;
                    excelItemTask.add(dataDaily);
                  });

                  final id = Uuid();
                  final file = await createFolderPath(
                    id.v4(),
                    'daily-check',
                    email: widget.user['email'] ?? '',
                    site: widget.user['siteName'] ?? '',
                    pit: (widget.pit.isNotEmpty)
                        ? widget.pit[widget.selectedPit]
                        : '',
                    date:
                        '${DateFormat('dd-MM-yyyy').format(DateTime(firstPicked.year, firstPicked.month, firstPicked.day))} - ${DateFormat('dd-MM-yyyy').format(DateTime(lastPicked.year, lastPicked.month, lastPicked.day))}',
                  );

                  final bytes =
                      await createExcel('daily-check', daily: excelItemTask);
                  await file.writeAsBytes(bytes, flush: true);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: green00968A,
                    content: Text(
                      'Successful Save Data!',
                      style: getWhiteTextStyle(),
                    ),
                  ));
                  await OpenFile.open(file.path);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.red,
                    content: Text('Error: $e'),
                  ));
                } finally {
                  setState(() {
                    _isLoading = false; // Sembunyikan loading
                  });
                }
              });
              break;
          }
        },
        style: ElevatedButton.styleFrom(
            backgroundColor: (widget.type == ExportType.oneDay)
                ? Colors.blueGrey
                : Colors.blue),
        child: _isLoading
            ? CircularProgressIndicator(
                color: Colors.white,
              )
            : Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      (widget.type == ExportType.oneDay)
                          ? Icons.table_chart
                          : Icons.copy_all_rounded,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Export to Excel ${(widget.type == ExportType.oneDay) ? '(One Day)' : '(Selected Date)'}',
                      style: getWhiteTextStyle(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
