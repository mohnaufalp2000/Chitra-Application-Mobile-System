import 'dart:developer';

import '../../../core/services/model/daily_press.dart';
import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/functions/functions.dart';
import 'enum_export_type.dart';
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
    required this.idSite,
    required this.date,
    required this.type,
  });

  final Map<String, dynamic> user;
  final List<String> pit;
  final int selectedPit;
  final List<Map<String, dynamic>> filteredItemTask;
  final String idSite;
  final String date;
  final String type;

  @override
  State<ExportExcelButton> createState() => _ExportExcelButtonState();
}

class _ExportExcelButtonState extends State<ExportExcelButton> {
  List<bool> selectedMonths = List.generate(12, (index) => false);
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool _isLoading = false; // Tambahkan variabel untuk indikator loading
  DateTime now = DateTime.now();

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

  Future<List<Map<String, dynamic>>> getMultipleDayExportData({
    required DateTime firstPicked,
    required DateTime lastPicked,
  }) async {
    final idSite = widget.idSite.trim();

    if (idSite.isEmpty) {
      throw Exception('Site belum tersedia. Silakan buka ulang halaman.');
    }

    final startDate = DateTime(
      firstPicked.year,
      firstPicked.month,
      firstPicked.day,
    );

    final endDateExclusive = DateTime(
      lastPicked.year,
      lastPicked.month,
      lastPicked.day,
    ).add(const Duration(days: 1));

    Query<Map<String, dynamic>> query = firestore
        .collection('daily_pressure')
        .where('idSite', isEqualTo: idSite)
        .where(
          'tanggal',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        )
        .where(
          'tanggal',
          isLessThan: endDateExclusive.toIso8601String(),
        );

    log(
      'Export daily | site: $idSite | '
      'tanggal: ${startDate.toIso8601String()} - '
      '< ${endDateExclusive.toIso8601String()}',
    );

    // Kalau user pilih pit tertentu, filter langsung di Firestore.
    // Ini mengurangi jumlah dokumen yang dibaca dan mempercepat proses export.
    if (widget.pit.isNotEmpty &&
        widget.selectedPit != 0 &&
        widget.selectedPit < widget.pit.length) {
      query = query.where(
        'pit',
        isEqualTo: widget.pit[widget.selectedPit],
      );
    }

    final snapshot = await query.get();

    final rawData = snapshot.docs.map((doc) {
      return doc.data();
    }).toList();

    log('jumlah daily sebelum distinct: ${rawData.length}');

    // Sort terbaru dulu.
    rawData.sort((a, b) {
      final aTanggal = a['tanggal']?.toString() ?? '';
      final bTanggal = b['tanggal']?.toString() ?? '';
      return bTanggal.compareTo(aTanggal);
    });

    // DISTINCT BY UNIT + HARI
    // Kalau export range 3 hari, unit yang sama tetap muncul 3x,
    // tapi hanya 1 data terbaru per hari.
    final latestMap = <String, Map<String, dynamic>>{};

    for (final item in rawData) {
      final unit = item['unit']?.toString() ?? '';
      final tanggal = item['tanggal']?.toString() ?? '';

      if (unit.isEmpty || tanggal.isEmpty) {
        continue;
      }

      final hari = item['hari']?.toString().isNotEmpty == true
          ? item['hari'].toString()
          : tanggal.split('T').first;

      final key = '$unit-$hari';

      if (!latestMap.containsKey(key)) {
        latestMap[key] = Map<String, dynamic>.from(item);
      }
    }

    final distinctDaily = latestMap.values.toList();

    distinctDaily.sort((a, b) {
      final aTanggal = a['tanggal']?.toString() ?? '';
      final bTanggal = b['tanggal']?.toString() ?? '';
      return aTanggal.compareTo(bTanggal);
    });

    log('jumlah daily setelah distinct: ${distinctDaily.length}');

    return distinctDaily;
  }

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

              log('data spm daily terbaru : ${widget.filteredItemTask}');

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
              _showDateRangePicker(context, (selectedDates) async {
                if (selectedDates.isEmpty) return;

                setState(() {
                  _isLoading = true;
                });

                try {
                  final firstPicked = selectedDates.first;
                  final lastPicked = selectedDates.last;

                  final excelItemTask = await getMultipleDayExportData(
                    firstPicked: firstPicked,
                    lastPicked: lastPicked,
                  );

                  if (excelItemTask.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.orange,
                        content: Text(
                            'Data export kosong untuk tanggal yang dipilih.'),
                      ),
                    );
                    return;
                  }

                  final id = Uuid();

                  final file = await createFolderPath(
                    id.v4(),
                    'daily-check',
                    email: widget.user['email'] ?? '',
                    site: widget.user['siteName'] ?? '',
                    pit: (widget.pit.isNotEmpty &&
                            widget.selectedPit < widget.pit.length)
                        ? widget.pit[widget.selectedPit]
                        : '',
                    date:
                        '${DateFormat('dd-MM-yyyy').format(DateTime(firstPicked.year, firstPicked.month, firstPicked.day))} - ${DateFormat('dd-MM-yyyy').format(DateTime(lastPicked.year, lastPicked.month, lastPicked.day))}',
                  );

                  final bytes = await createExcel(
                    'daily-check',
                    daily: excelItemTask,
                  );

                  await file.writeAsBytes(bytes, flush: true);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: green00968A,
                      content: Text(
                        'Successful Save Data!',
                        style: getWhiteTextStyle(),
                      ),
                    ),
                  );

                  final result = await OpenFile.open(file.path);

                  if (result.type != ResultType.done) {
                    log('Open file error: ${result.message}');

                    if (result.type == ResultType.noAppToOpen) {
                      openPlayStore('attendance');
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Colors.red,
                      content: Text('Error: $e'),
                    ),
                  );
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              });
              break;
            // case ExportType.multipleDay:
            //   List<Map<String, dynamic>> excelItemTask = [];
            //   _showDateRangePicker(context, (selectedMonths) async {
            //     setState(() {
            //       _isLoading = true; // Tampilkan loading
            //     });
            //     try {
            //       final firstPicked = selectedMonths[0];
            //       final lastPicked = selectedMonths[selectedMonths.length - 1];
            //       final snapshot = await firestore
            //           .collection('daily_pressure')
            //           .where('idSite',
            //               isEqualTo: widget.filteredItemTask[0]['idSite'])
            //           .where('tanggal',
            //               isGreaterThanOrEqualTo: DateTime(firstPicked.year,
            //                       firstPicked.month, firstPicked.day)
            //                   .toIso8601String())
            //           .where('tanggal',
            //               isLessThanOrEqualTo: DateTime(lastPicked.year,
            //                       lastPicked.month, lastPicked.day, 23, 59, 59)
            //                   .toIso8601String())
            //           .get();

            //       final allData = snapshot.docs
            //           .map((doc) => DailyPress.fromFirestore(
            //               doc.data() as Map<String, dynamic>))
            //           .toList();

            //       log('jumlah daily double 1 : ${allData.length}');

            //       final distinctDaily =
            //           Set<DailyPress>.from(allData ?? []).toList();

            //       log('jumlah daily double 2 : ${distinctDaily.length}');

            //       distinctDaily.forEach((item) {
            //         Map<String, dynamic> cast = item.toFirestore();
            //         excelItemTask.add(cast);
            //       });

            //       final id = Uuid();
            //       final file = await createFolderPath(
            //         id.v4(),
            //         'daily-check',
            //         email: widget.user['email'] ?? '',
            //         site: widget.user['siteName'] ?? '',
            //         pit: (widget.pit.isNotEmpty)
            //             ? widget.pit[widget.selectedPit]
            //             : '',
            //         date:
            //             '${DateFormat('dd-MM-yyyy').format(DateTime(firstPicked.year, firstPicked.month, firstPicked.day))} - ${DateFormat('dd-MM-yyyy').format(DateTime(lastPicked.year, lastPicked.month, lastPicked.day))}',
            //       );

            //       final bytes =
            //           await createExcel('daily-check', daily: excelItemTask);
            //       await file.writeAsBytes(bytes, flush: true);
            //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            //         backgroundColor: green00968A,
            //         content: Text(
            //           'Successful Save Data!',
            //           style: getWhiteTextStyle(),
            //         ),
            //       ));
            //       await OpenFile.open(file.path);
            //     } catch (e) {
            //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            //         backgroundColor: Colors.red,
            //         content: Text('Error: $e'),
            //       ));
            //     } finally {
            //       setState(() {
            //         _isLoading = false; // Sembunyikan loading
            //       });
            //     }
            //   });
            //   break;
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
