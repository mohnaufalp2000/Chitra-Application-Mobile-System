import 'dart:developer';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/home/new_tire_inspection_state.dart';
import 'package:camos/pages/home/tire_inspection_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection/tire_repair_inspection_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
                  Column(
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
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),

              // Detail posisi ban
              if (isExpanded) ...[
                const Divider(height: 20),
                ...posisiList.map((p) {
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
