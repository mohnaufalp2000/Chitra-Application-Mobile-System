import 'dart:io';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/home/new_tire_inspection_state.dart';
import 'package:camos/pages/home/tire_inspection_page.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/temperature_status_badge_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/upload_queue_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as p;
import 'package:path_provider/path_provider.dart';

class NewTireInspectionPage extends StatelessWidget {
  NewTireInspectionPage({super.key});

  final ntController = Get.put(NewTireInspectionState());
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Tire Inspection Result',
                    style: getGreenTextStyle(fontWeight: w700, fontSize: 20),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ButtonWidget(
                      name: Row(
                        children: [
                          Icon(
                            Icons.arrow_downward,
                            size: 12,
                            color: Colors.white,
                          ),
                          Text(
                            'Old \nTire Inspection',
                            style: TextStyle(color: Colors.white, fontSize: 8),
                          ),
                        ],
                      ),
                      function: () {
                        Navigator.pushNamed(
                            context, TireInspectionPage.routeName);
                      }),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Send Data
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ntController.isSending.value
                        ? null
                        : () => ntController.sendTireInspection(context),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ntController.isSending.value
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: ntController
                                      .sendTireInspectionProgress.value,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade300,
                                  color: Colors.black,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Sending ${(ntController.sendTireInspectionProgress.value * 100).toInt()}%',
                                  style: getBlackTextStyle(),
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
                                Text('Send Data to CTS',
                                    style: getWhiteTextStyle()),
                              ],
                            ),
                    ),
                  ),
                )),

            const SizedBox(height: 16),
            // Export Button
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: ntController.isExporting.value
                        ? null
                        : () => ntController.exportToExcel(context),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: ntController.isExporting.value
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                LinearProgressIndicator(
                                  value: ntController.exportProgress.value,
                                  minHeight: 6,
                                  backgroundColor: Colors.grey.shade300,
                                  color: Colors.black,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Exporting ${(ntController.exportProgress.value * 100).toInt()}%',
                                  style: getBlackTextStyle(),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.table_chart),
                                const SizedBox(width: 12),
                                Text('Export to Excel',
                                    style: getBlackTextStyle()),
                              ],
                            ),
                    ),
                  ),
                )),

            const SizedBox(height: 12),

            // Search & Filter Row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    onChanged: (value) {
                      ntController.onSearchChanged(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Search... (Unit Number)',
                      hintStyle: getGreyTextStyle(grey8391A1),
                      prefixIcon: const Icon(Icons.search),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Date Range Picker
                Obx(() => GestureDetector(
                      onTap: () async {
                        final picked = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2024, 1, 1),
                          lastDate: DateTime.now(),
                          initialDateRange:
                              ntController.selectedDateRange.value,
                        );
                        if (picked != null) {
                          await ntController.selectDateRange(picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xff313131)),
                          borderRadius: BorderRadius.circular(8),
                          color: ntController.selectedDateRange.value != null
                              ? green00968A.withOpacity(0.1)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.date_range, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              ntController.selectedDateRange.value != null
                                  ? '${DateFormat('dd/MM').format(ntController.selectedDateRange.value!.start)} - ${DateFormat('dd/MM').format(ntController.selectedDateRange.value!.end)}'
                                  : 'Filter',
                              style: getBlackTextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    )),

                const SizedBox(width: 4),

                // Reset Filter
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () async {
                    await Get.putAsync<UploadQueueService>(
                      () => UploadQueueService().init(),
                    );

                    searchController.clear();
                    ntController.resetFilters();
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            Obx(
              () => Text(
                'Total Unit: ${ntController.totalFilteredTasks.value}',
                style: getBlackTextStyle(fontSize: 13),
              ),
            ),

            const SizedBox(height: 8),

            // List
            Expanded(
              child: Obx(() {
                if (ntController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (ntController.filteredTasks.isEmpty) {
                  return const Center(child: Text('No data found.'));
                }

                return NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 200) {
                      ntController.loadMoreTasks();
                    }
                    return false;
                  },
                  child: RefreshIndicator(
                    onRefresh: ntController.reloadForActiveFilters,
                    child: ListView.builder(
                      itemCount: ntController.filteredTasks.length +
                          (ntController.hasMoreTasks.value ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= ntController.filteredTasks.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: ntController.isLoadingMore.value
                                  ? const CircularProgressIndicator()
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }

                        final doc = ntController.filteredTasks[index];
                        final posisiList =
                            (doc['posisi'] as List<dynamic>? ?? []);

                        return _TireInspectionCard(
                            doc: doc, posisiList: posisiList);
                      },
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

p.Widget header(String text) {
  return p.Container(
    alignment: p.Alignment.center,
    padding: const p.EdgeInsets.all(3),
    child: p.Text(
      text,
      textAlign: p.TextAlign.center,
      style: p.TextStyle(
        fontSize: 7,
        fontWeight: p.FontWeight.bold,
      ),
    ),
  );
}

p.Widget spanHeader(String text, int span) {
  return p.Container(
    alignment: p.Alignment.center,
    padding: const p.EdgeInsets.all(3),
    child: p.Text(
      text,
      textAlign: p.TextAlign.center,
      style: p.TextStyle(
        fontSize: 7,
        fontWeight: p.FontWeight.bold,
      ),
    ),
  );
}

p.Widget cell(String text) {
  return p.Container(
    alignment: p.Alignment.centerLeft,
    padding: const p.EdgeInsets.all(3),
    child: p.Text(
      text,
      textAlign: p.TextAlign.left,
      style: const p.TextStyle(fontSize: 7),
    ),
  );
}

late p.MemoryImage checkImage;

Future<void> initChecklistAssets() async {
  checkImage = p.MemoryImage(
    (await rootBundle.load('assets/icons/check-mark.png')).buffer.asUint8List(),
  );
}

p.Widget cellCheckIcon(bool isChecked) {
  return p.Container(
    alignment: p.Alignment.center,
    padding: const p.EdgeInsets.all(3),
    decoration: p.BoxDecoration(
      color: isChecked ? PdfColors.green100 : PdfColors.red100,
    ),
    child: isChecked
        ? p.Image(
            checkImage,
            width: 10,
            height: 10,
            fit: p.BoxFit.contain,
          )
        : p.SizedBox(width: 10, height: 10),
  );
}

p.Widget empty() => p.Container();
p.Widget emptyDisable() => p.Container(
      color: PdfColors.grey300,
    );

class _TireInspectionCard extends StatefulWidget {
  final Map<String, dynamic> doc;
  final List<dynamic> posisiList;

  const _TireInspectionCard({required this.doc, required this.posisiList});

  @override
  State<_TireInspectionCard> createState() => _TireInspectionCardState();
}

class _TireInspectionCardState extends State<_TireInspectionCard> {
  bool isExpanded = false;
  Set<int> expandedRimPositions = {};

  @override
  Widget build(BuildContext context) {
    final doc = widget.doc;
    final posisiList = widget.posisiList;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => setState(() => isExpanded = !isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          doc['unit'] ?? '-',
                          style:
                              getBlackTextStyle(fontWeight: w700, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${doc['hari'] ?? ''} | ${doc['jam'] ?? ''}',
                          style: getGreyTextStyle(grey8391A1, fontSize: 12),
                        ),
                        Text(
                          'HM: ${doc['hm'] ?? '-'} | Inspector: ${doc['user'] ?? '-'}',
                          style: getGreyTextStyle(grey8391A1, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      /// PDF BUTTON
                      OutlinedButton.icon(
                        onPressed: () async {
                          final pdf = p.Document();
                          await initChecklistAssets();

                          final posisiList =
                              doc['posisi'] as List<dynamic>? ?? [];

                          pdf.addPage(
                            p.Page(
                              pageFormat: PdfPageFormat.a4.landscape,
                              margin: const p.EdgeInsets.all(15),
                              build: (context) {
                                return p.Column(
                                  crossAxisAlignment:
                                      p.CrossAxisAlignment.start,
                                  children: [
                                    /// ================= HEADER =================
                                    p.Center(
                                      child: p.Text(
                                        'FORM TYRE & WHEEL INSPECTION',
                                        style: p.TextStyle(
                                          fontSize: 14,
                                          fontWeight: p.FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    p.SizedBox(height: 8),

                                    p.Row(
                                      mainAxisAlignment:
                                          p.MainAxisAlignment.spaceBetween,
                                      children: [
                                        p.Text(
                                          'Project / Site : ${doc['id_site'] ?? '-'}',
                                          style: const p.TextStyle(fontSize: 8),
                                        ),
                                        p.Column(
                                          crossAxisAlignment:
                                              p.CrossAxisAlignment.start,
                                          children: [
                                            p.Text(
                                                'UNIT : ${doc['unit'] ?? '-'}',
                                                style: p.TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: p.FontWeight.bold,
                                                )),
                                            p.SizedBox(height: 6),
                                            p.Text('SMU : ${doc['hm'] ?? '-'}',
                                                style: p.TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: p.FontWeight.bold,
                                                )),
                                            p.SizedBox(height: 6),
                                            p.Text(
                                                'DATE : ${doc['hari'] ?? '-'}',
                                                style: p.TextStyle(
                                                  fontSize: 8,
                                                  fontWeight: p.FontWeight.bold,
                                                )),
                                            p.SizedBox(height: 6),
                                            p.Text('TYPE : 250/500/1000/2000',
                                                style: p.TextStyle(
                                                    fontWeight:
                                                        p.FontWeight.bold,
                                                    fontSize: 8)),
                                            p.SizedBox(height: 3),
                                            p.Text('*Lingkari type service',
                                                style:
                                                    p.TextStyle(fontSize: 8)),
                                          ],
                                        ),
                                      ],
                                    ),

                                    p.SizedBox(height: 10),

                                    /// ================= TABEL UTAMA =================

                                    p.Table(
                                      border: p.TableBorder.all(width: 0.5),
                                      columnWidths: {
                                        0: const p.FixedColumnWidth(25), // POS
                                        1: const p.FixedColumnWidth(
                                            50), // BRAND
                                        2: const p.FixedColumnWidth(
                                            70), // SERIAL
                                        3: const p.FixedColumnWidth(
                                            80), // PATTERN
                                        4: const p.FixedColumnWidth(30), // TYPE
                                        5: const p.FixedColumnWidth(
                                            45), // TREAD
                                        6: const p.FixedColumnWidth(30),
                                        7: const p.FixedColumnWidth(30),
                                        8: const p.FixedColumnWidth(30),
                                        9: const p.FixedColumnWidth(30),
                                        10: const p.FixedColumnWidth(35),
                                        11: const p.FixedColumnWidth(35),
                                        12: const p.FixedColumnWidth(45),
                                        13: const p.FixedColumnWidth(45),
                                        14: const p.FixedColumnWidth(
                                            80), // REMARK
                                      },
                                      children: [
                                        /// HEADER ROW 1
                                        p.TableRow(
                                          children: [
                                            header('POS'),
                                            header('BRAND'),
                                            header('SERIAL NUMBER'),
                                            header('PATTERN'),
                                            header('TYPE'),
                                            header('TREAD DEPT'),
                                            header('PRESSURE'),
                                            empty(),
                                            empty(),
                                            empty(),
                                            header('KONDISI'),
                                            empty(),
                                            empty(),
                                            empty(),
                                            header('REMARK'),
                                          ],
                                        ),

                                        /// HEADER ROW 2
                                        p.TableRow(
                                          children: [
                                            empty(),
                                            empty(),
                                            empty(),
                                            empty(),
                                            empty(),
                                            empty(),
                                            header('ACTUAL'),
                                            header('ADJUST'),
                                            header('HOT'),
                                            header('COLD'),
                                            header('BEAD'),
                                            header('TREAD'),
                                            header('SIDEWALL'),
                                            header('SHOULDER'),
                                            empty(),
                                          ],
                                        ),

                                        /// DATA ROW
                                        ...posisiList.map((pData) {
                                          final posisi =
                                              pData as Map<String, dynamic>;

                                          return p.TableRow(
                                            children: [
                                              cell(posisi['position']
                                                      ?.toString() ??
                                                  ''),
                                              cell(posisi['brand'] ?? ''),
                                              cell(posisi['sn'] ?? ''),
                                              cell(posisi['pattern'] ?? ''),
                                              cell(posisi['type'] ?? ''),
                                              cell(
                                                  '${posisi['rtd1'] ?? ''}/${posisi['rtd2'] ?? ''}'),
                                              cell(posisi['pressure'] ?? ''),
                                              cell(
                                                  posisi['adjusmentPressure'] ??
                                                      ''),
                                              cell(posisi['hot'] ?? ''),
                                              cell(posisi['cold'] ?? ''),
                                              cell(posisi['bead'] ?? ''),
                                              cell(posisi['tread'] ?? ''),
                                              cell(posisi['sidewall'] ?? ''),
                                              cell(posisi['shoulder'] ?? ''),
                                              cell(posisi['remarks'] ?? ''),
                                            ],
                                          );
                                        }).toList(),
                                      ],
                                    ),

                                    p.SizedBox(height: 12),

                                    /// ================= JOB DESCRIPTION =================

                                    p.Table(
                                      border: p.TableBorder.all(width: 0.5),
                                      columnWidths: {
                                        0: const p.FixedColumnWidth(18), // NO
                                        1: const p.FixedColumnWidth(
                                            68), // JOB DESCRIPTION

                                        for (int i = 2; i < 14; i++)
                                          i: const p.FixedColumnWidth(
                                              22), // semua kolom pos sama
                                      },
                                      children: [
                                        /// HEADER ROW 1
                                        p.TableRow(
                                          decoration: const p.BoxDecoration(
                                            color: PdfColors.orange100,
                                          ),
                                          children: [
                                            header('NO'),
                                            header('JOB DESCRIPTION'),
                                            spanHeader('POS 1', 2),
                                            empty(),
                                            spanHeader('POS 2', 2),
                                            empty(),
                                            spanHeader('POS 3', 2),
                                            empty(),
                                            spanHeader('POS 4', 2),
                                            empty(),
                                            spanHeader('POS 5', 2),
                                            empty(),
                                            spanHeader('POS 6', 2),
                                            empty(),
                                          ],
                                        ),

                                        p.TableRow(
                                          decoration: const p.BoxDecoration(
                                            color: PdfColors.orange100,
                                          ),
                                          children: [
                                            empty(),
                                            empty(),
                                            header('GOOD'),
                                            header('POOR'),
                                            header('GOOD'),
                                            header('POOR'),
                                            header('GOOD'),
                                            header('POOR'),
                                            header('GOOD'),
                                            header('POOR'),
                                            header('GOOD'),
                                            header('POOR'),
                                            header('GOOD'),
                                            header('POOR'),
                                            header('Remark'),
                                          ],
                                        ),

                                        p.TableRow(
                                          children: [
                                            cell('1'),
                                            cell('PERIKSA KONDISI FISIK RIM'),
                                            emptyDisable(),
                                            emptyDisable(),
                                            empty(),
                                            emptyDisable(),
                                            emptyDisable(),
                                            empty(),
                                            emptyDisable(),
                                            emptyDisable(),
                                            empty(),
                                            emptyDisable(),
                                            emptyDisable(),
                                            empty(),
                                            emptyDisable(),
                                            emptyDisable(),
                                            empty(),
                                            emptyDisable(),
                                            emptyDisable(),
                                            empty(),
                                          ],
                                        ),

                                        // /// a
                                        p.TableRow(
                                          children: [
                                            cell('a'),
                                            cell('RIM BASE'),
                                            ...posisiList.expand((posisi) {
                                              final rim = posisi['rimCondition']
                                                  as List;

                                              if (rim.isEmpty) {
                                                return [
                                                  cellCheckIcon(false),
                                                  cellCheckIcon(false),
                                                ];
                                              }

                                              final ri = rim[0];

                                              final isGood = ri['condition']
                                                      ?.toString()
                                                      .toUpperCase() ==
                                                  'GOOD';

                                              return [
                                                cellCheckIcon(isGood),
                                                cellCheckIcon(!isGood),
                                              ];
                                            }).toList(),
                                            ...List.generate(
                                                10, (_) => empty()),
                                          ],
                                        ),
                                        p.TableRow(
                                          children: [
                                            cell('b'),
                                            cell('FLANGE'),
                                            ...posisiList.expand((posisi) {
                                              final rim = posisi['rimCondition']
                                                  as List;

                                              if (rim.isEmpty) {
                                                return [
                                                  cellCheckIcon(false),
                                                  cellCheckIcon(false),
                                                ];
                                              }

                                              final ri = rim[1];

                                              final isGood = ri['condition']
                                                      ?.toString()
                                                      .toUpperCase() ==
                                                  'GOOD';

                                              return [
                                                cellCheckIcon(isGood),
                                                cellCheckIcon(!isGood),
                                              ];
                                            }).toList(),
                                            ...List.generate(
                                                10, (_) => empty()),
                                          ],
                                        ),
                                        p.TableRow(
                                          children: [
                                            cell('c'),
                                            cell('LOCK RING'),
                                            ...posisiList.expand((posisi) {
                                              final rim = posisi['rimCondition']
                                                  as List;

                                              if (rim.isEmpty) {
                                                return [
                                                  cellCheckIcon(false),
                                                  cellCheckIcon(false),
                                                ];
                                              }

                                              final ri = rim[2];

                                              final isGood = ri['condition']
                                                      ?.toString()
                                                      .toUpperCase() ==
                                                  'GOOD';

                                              return [
                                                cellCheckIcon(isGood),
                                                cellCheckIcon(!isGood),
                                              ];
                                            }).toList(),
                                            ...List.generate(
                                                10, (_) => empty()),
                                          ],
                                        ),

                                        p.TableRow(
                                          children: [
                                            cell('2'),
                                            cell(
                                                'PERIKSA KONDISI VALVE (Terpasang/Tidak Terpasang)'),
                                            ...posisiList.expand((posisi) {
                                              final rim = posisi['rimCondition']
                                                  as List;

                                              if (rim.isEmpty) {
                                                return [
                                                  cellCheckIcon(false),
                                                  cellCheckIcon(false),
                                                ];
                                              }

                                              final ri = rim[3];

                                              final isGood = ri['condition']
                                                      ?.toString()
                                                      .toUpperCase() ==
                                                  'GOOD';

                                              return [
                                                cellCheckIcon(isGood),
                                                cellCheckIcon(!isGood),
                                              ];
                                            }).toList(),
                                            ...List.generate(
                                                10, (_) => empty()),
                                          ],
                                        ),

                                        p.TableRow(
                                          children: [
                                            cell('3'),
                                            cell('PERIKSA KONDISI CORE VALVE'),
                                            ...posisiList.expand((posisi) {
                                              final rim = posisi['rimCondition']
                                                  as List;

                                              if (rim.isEmpty) {
                                                return [
                                                  cellCheckIcon(false),
                                                  cellCheckIcon(false),
                                                ];
                                              }

                                              final ri = rim[4];

                                              final isGood = ri['condition']
                                                      ?.toString()
                                                      .toUpperCase() ==
                                                  'GOOD';

                                              return [
                                                cellCheckIcon(isGood),
                                                cellCheckIcon(!isGood),
                                              ];
                                            }).toList(),
                                            ...List.generate(
                                                10, (_) => empty()),
                                          ],
                                        ),

                                        p.TableRow(
                                          children: [
                                            cell('4'),
                                            cell(
                                                'PERIKSA KONDISI NUT AND STUD RODA'),
                                            ...posisiList.expand((posisi) {
                                              final rim = posisi['rimCondition']
                                                  as List;

                                              if (rim.isEmpty) {
                                                return [
                                                  cellCheckIcon(false),
                                                  cellCheckIcon(false),
                                                ];
                                              }

                                              final ri = rim[5];

                                              final isGood = ri['condition']
                                                      ?.toString()
                                                      .toUpperCase() ==
                                                  'GOOD';

                                              return [
                                                cellCheckIcon(isGood),
                                                cellCheckIcon(!isGood),
                                              ];
                                            }).toList(),
                                            ...List.generate(
                                                10, (_) => empty()),
                                          ],
                                        ),
                                      ],
                                    ),

                                    p.SizedBox(height: 50),

                                    /// ================= SIGNATURE =================

                                    p.Row(
                                      mainAxisAlignment:
                                          p.MainAxisAlignment.spaceBetween,
                                      children: [
                                        p.Column(
                                          children: [
                                            p.Text('Di Inspeksi Oleh',
                                                style: const p.TextStyle(
                                                    fontSize: 7)),
                                            p.SizedBox(height: 70),
                                            p.Container(
                                                width: 100,
                                                height: 1,
                                                color: PdfColors.black),
                                            p.SizedBox(height: 6),
                                            p.Text('Nama, TTD, NIK',
                                                style: const p.TextStyle(
                                                    fontSize: 6)),
                                            p.SizedBox(height: 2),
                                            p.Text(doc['user'],
                                                style: p.TextStyle(
                                                    fontSize: 6,
                                                    fontWeight:
                                                        p.FontWeight.bold)),
                                          ],
                                        ),
                                        p.Column(
                                          children: [
                                            p.Text('Di Periksa Oleh',
                                                style: const p.TextStyle(
                                                    fontSize: 7)),
                                            p.SizedBox(height: 70),
                                            p.Container(
                                                width: 100,
                                                height: 1,
                                                color: PdfColors.black),
                                            p.SizedBox(height: 6),
                                            p.Text('Nama, TTD, NIK',
                                                style: const p.TextStyle(
                                                    fontSize: 6)),
                                            p.SizedBox(height: 2),
                                          ],
                                        ),
                                        p.Column(
                                          children: [
                                            p.Text('Di Setujui Oleh',
                                                style: const p.TextStyle(
                                                    fontSize: 7)),
                                            p.SizedBox(height: 70),
                                            p.Container(
                                                width: 100,
                                                height: 1,
                                                color: PdfColors.black),
                                            p.SizedBox(height: 6),
                                            p.Text('Nama, TTD, NIK',
                                                style: const p.TextStyle(
                                                    fontSize: 6)),
                                            p.SizedBox(height: 2),
                                          ],
                                        ),
                                        p.Column(
                                          children: [
                                            p.Text('Di Ketahui Oleh',
                                                style: const p.TextStyle(
                                                    fontSize: 7)),
                                            p.SizedBox(height: 70),
                                            p.Container(
                                                width: 100,
                                                height: 1,
                                                color: PdfColors.black),
                                            p.SizedBox(height: 6),
                                            p.Text('Nama, TTD, NIK',
                                                style: const p.TextStyle(
                                                    fontSize: 6)),
                                            p.SizedBox(height: 2),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          );

                          final output = await getTemporaryDirectory();
                          final file = File(
                              "${output.path}/tire_inspection_${doc['unit']}.pdf");

                          await file.writeAsBytes(await pdf.save());

                          await OpenFile.open(file.path);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 12),
                          minimumSize: Size.zero,
                          side: BorderSide(color: Colors.red),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.picture_as_pdf,
                          size: 14,
                          color: Colors.red,
                        ),
                        label: const Text(
                          'Export PDF',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      /// EXPAND ICON
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                        ),
                      ),
                    ],
                  )
                ],
              ),

              // Detail posisi ban
              if (isExpanded) ...[
                const Divider(height: 20),
                ...posisiList.asMap().entries.map((entry) {
                  final index = entry.key;
                  final p = entry.value;
                  final posisi = p as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Position ${posisi['position'] ?? '-'}',
                          style:
                              getBlackTextStyle(fontWeight: w700, fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        _row('SN', posisi['sn'] ?? '-'),
                        _row('Tire Size', posisi['tireSize'] ?? '-'),
                        Row(
                          children: [
                            Expanded(
                                child: _row('Pressure',
                                    '${posisi['pressure'] ?? '-'} Psi')),
                            const SizedBox(
                              width: 6,
                            ),
                            (posisi['temperatureStatus'] != null)
                                ? TemperatureStatusBadgeWidget(
                                    status: posisi['temperatureStatus'])
                                : Container()
                          ],
                        ),
                        _row('Adj Pressure',
                            '${posisi['adjusmentPressure'] ?? '-'} Psi'),
                        _row('RTD',
                            '${posisi['rtd1'] ?? '-'}/${posisi['rtd2'] ?? '-'}'),
                        _row('Rating', posisi['rating'] ?? '-'),
                        _row(
                            'Damage',
                            (posisi['damageTire'] is List)
                                ? (posisi['damageTire'] as List).join(', ')
                                : posisi['damageTire']?.toString() ?? '-'),
                        Builder(builder: (context) {
                          if (posisi['remarks'] is Map<String, dynamic>) {
                            return _row(
                                'Remarks', posisi['remarks']['remark'] ?? '-');
                          }
                          return _row('Remarks', posisi['remarks'] ?? '-');
                        }),
                        if (posisi['rimCondition'] != null &&
                            posisi['rimCondition'] is List &&
                            (posisi['rimCondition'] as List).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Builder(
                            builder: (_) {
                              final rimList = posisi['rimCondition'] as List;

                              final goodCount = rimList
                                  .where((e) => e['condition'] == 'Good')
                                  .length;

                              final poorCount = rimList
                                  .where((e) => e['condition'] == 'Poor')
                                  .length;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  /// HEADER SUMMARY
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (expandedRimPositions
                                            .contains(index)) {
                                          expandedRimPositions.remove(index);
                                        } else {
                                          expandedRimPositions.add(index);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Rim Condition : '
                                            '$goodCount Good'
                                            '${poorCount > 0 ? ' | $poorCount Poor' : ''}',
                                            style: getBlackTextStyle(
                                                fontWeight: w600, fontSize: 12),
                                          ),
                                          Icon(
                                            expandedRimPositions.contains(index)
                                                ? Icons.expand_less
                                                : Icons.expand_more,
                                            size: 16,
                                          )
                                        ],
                                      ),
                                    ),
                                  ),

                                  /// DETAIL
                                  if (expandedRimPositions.contains(index)) ...[
                                    const SizedBox(height: 6),
                                    ...rimList.map((item) {
                                      final rim = item as Map<String, dynamic>;
                                      final isGood = rim['condition'] == 'Good';

                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 4),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isGood
                                              ? Colors.green.withOpacity(0.08)
                                              : Colors.red.withOpacity(0.08),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              rim['title'] ?? '-',
                                              style: getBlackTextStyle(
                                                  fontSize: 11,
                                                  fontWeight: w600),
                                            ),
                                            if ((rim['jobDescription'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                'Job: ${rim['jobDescription']}',
                                                style: getGreyTextStyle(
                                                    grey8391A1,
                                                    fontSize: 10),
                                              ),
                                            Text(
                                              rim['condition'] ?? '-',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: isGood
                                                    ? Colors.green
                                                    : Colors.red,
                                              ),
                                            ),
                                            if ((rim['remark'] ?? '')
                                                .toString()
                                                .isNotEmpty)
                                              Text(
                                                'Remark: ${rim['remark']}',
                                                style: getGreyTextStyle(
                                                    grey8391A1,
                                                    fontSize: 10),
                                              ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ]
                                ],
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child:
                Text(label, style: getGreyTextStyle(grey8391A1, fontSize: 12)),
          ),
          Expanded(
            child: Text(': $value', style: getBlackTextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
