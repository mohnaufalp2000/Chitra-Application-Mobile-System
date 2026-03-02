import 'dart:developer';
import 'dart:io';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/home/new_tire_inspection_state.dart';
import 'package:camos/pages/home/tire_inspection_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection/tire_repair_inspection_page.dart';
import 'package:flutter/material.dart';
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
                      ntController.searchQuery.value = value;
                      ntController.applyFilters();
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
                          ntController.selectedDateRange.value = picked;
                          ntController.applyFilters();
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
                  onPressed: () {
                    searchController.clear();
                    ntController.resetFilters();
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // List
            Expanded(
              child: Obx(() {
                if (ntController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (ntController.filteredTasks.isEmpty) {
                  return const Center(child: Text('No data found.'));
                }

                return RefreshIndicator(
                  onRefresh: ntController.fetchTasks,
                  child: ListView.builder(
                    itemCount: ntController.filteredTasks.length,
                    itemBuilder: (context, index) {
                      final doc = ntController.filteredTasks[index];
                      final posisiList =
                          (doc['posisi'] as List<dynamic>? ?? []);

                      return _TireInspectionCard(
                          doc: doc, posisiList: posisiList);
                    },
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
                                                style: const p.TextStyle(
                                                    fontSize: 8)),
                                            p.Text('SMU : ${doc['hm'] ?? '-'}',
                                                style: const p.TextStyle(
                                                    fontSize: 8)),
                                            p.Text(
                                                'DATE : ${doc['hari'] ?? '-'}',
                                                style: const p.TextStyle(
                                                    fontSize: 8)),
                                          ],
                                        ),
                                      ],
                                    ),

                                    p.SizedBox(height: 10),

                                    /// ================= TABEL UTAMA =================
                                    p.Table.fromTextArray(
                                      border: p.TableBorder.all(width: 0.5),
                                      headerStyle: p.TextStyle(
                                          fontWeight: p.FontWeight.bold,
                                          fontSize: 7),
                                      cellStyle: const p.TextStyle(fontSize: 7),
                                      headers: [
                                        'POS',
                                        'SN',
                                        'SIZE',
                                        'PRESS',
                                        'ADJ',
                                        'RTD',
                                        'RATING',
                                        'DAMAGE',
                                        'REMARK'
                                      ],
                                      data: posisiList.map((pData) {
                                        final posisi =
                                            pData as Map<String, dynamic>;
                                        return [
                                          posisi['position']?.toString() ?? '',
                                          posisi['sn'] ?? '',
                                          posisi['tireSize'] ?? '',
                                          posisi['pressure'] ?? '',
                                          posisi['adjusmentPressure'] ?? '',
                                          '${posisi['rtd1'] ?? ''}/${posisi['rtd2'] ?? ''}',
                                          posisi['rating'] ?? '',
                                          (posisi['damageTire'] is List)
                                              ? (posisi['damageTire'] as List)
                                                  .join(', ')
                                              : posisi['damageTire']
                                                      ?.toString() ??
                                                  '',
                                          posisi['remarks'] ?? '',
                                        ];
                                      }).toList(),
                                    ),

                                    p.SizedBox(height: 12),

                                    /// ================= JOB DESCRIPTION =================
                                    p.Container(
                                      padding: const p.EdgeInsets.all(5),
                                      color: PdfColors.grey300,
                                      child: p.Text(
                                        'JOB DESCRIPTION',
                                        style: p.TextStyle(
                                            fontWeight: p.FontWeight.bold,
                                            fontSize: 8),
                                      ),
                                    ),

                                    p.SizedBox(height: 5),

                                    /// Rim condition per posisi
                                    if (posisiList.isNotEmpty) ...[
                                      (() {
                                        final posisi = posisiList.first
                                            as Map<String, dynamic>;
                                        final rimList = posisi['rimCondition']
                                                as List<dynamic>? ??
                                            [];

                                        return p.Column(
                                          crossAxisAlignment:
                                              p.CrossAxisAlignment.start,
                                          children: [
                                            p.SizedBox(height: 4),
                                            p.Text(
                                              'Position ${posisi['position']}',
                                              style: p.TextStyle(
                                                  fontWeight: p.FontWeight.bold,
                                                  fontSize: 8),
                                            ),
                                            p.SizedBox(height: 4),
                                            p.Table.fromTextArray(
                                              border:
                                                  p.TableBorder.all(width: 0.5),
                                              cellStyle: const p.TextStyle(
                                                  fontSize: 7),
                                              headers: [
                                                'JOB',
                                                'COND',
                                                'REMARK'
                                              ],
                                              data: rimList.map((r) {
                                                final rim =
                                                    r as Map<String, dynamic>;
                                                return [
                                                  rim['title'] ?? '',
                                                  rim['condition'] ?? '',
                                                  rim['remark'] ?? '',
                                                ];
                                              }).toList(),
                                            ),
                                          ],
                                        );
                                      })(),
                                    ],

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
                        _row('Pressure', '${posisi['pressure'] ?? '-'} Psi'),
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
                        _row('Remarks', posisi['remarks'] ?? '-'),
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
