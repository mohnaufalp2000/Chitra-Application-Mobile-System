import 'package:camos/core/services/model/auto_tapping_model.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import 'auto_tapping_state.dart';

class AutoTappingPage extends StatefulWidget {
  static const routeName = '/auto-tapping-page';

  const AutoTappingPage({super.key});

  @override
  State<AutoTappingPage> createState() => _AutoTappingPageState();
}

class _AutoTappingPageState extends State<AutoTappingPage> {
  late final AutoTappingState autoTappingState;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    autoTappingState = Get.isRegistered<AutoTappingState>()
        ? Get.find<AutoTappingState>()
        : Get.put(AutoTappingState());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_isInitialized) return;

    final args = ModalRoute.of(context)?.settings.arguments;

    String idSite = '';
    String siteName = '';

    if (args is Map) {
      idSite = args['idSite']?.toString() ?? '';
      siteName = args['siteName']?.toString() ?? '';
    }

    autoTappingState.loadAutoTapping(
      idSite: idSite,
      siteName: siteName,
    );

    _isInitialized = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'export_excel_fab',
        backgroundColor: white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(
            color: green00968A,
            width: 1.5,
          ),
        ),
        onPressed: () {
          // TODO: export excel logic
        },
        icon: Image.asset(
          'assets/icons/excel.png',
          width: 20,
        ),
        label: Text(
          'Export',
          style: getGreenTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Auto Tapping History',
          style: getBlackTextStyle(),
        ),
        actions: [
          IconButton(
            onPressed: () {
              autoTappingState.loadAutoTapping(
                forceRefresh: true,
                idSite: autoTappingState.selectedIdSite.value,
                siteName: autoTappingState.selectedSiteName.value,
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Obx(
              () {
                if (autoTappingState.selectedIdSite.value.isEmpty) {
                  return const SizedBox();
                }

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: green00968A.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: green00968A.withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: green00968A,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Site: ${autoTappingState.selectedSiteName.value}',
                        style: getBlackTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ).copyWith(
                          color: green00968A,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Obx(
                    () => _buildDropdownFilter(
                      width: 178,
                      label: 'Unit ID',
                      value: autoTappingState.selectedUnit.value,
                      items: autoTappingState.unitItems,
                      onSelected: autoTappingState.setSelectedUnit,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => _buildDropdownFilter(
                      width: 128,
                      label: 'Posisi',
                      value: autoTappingState.selectedPosition.value,
                      items: autoTappingState.positionItems,
                      onSelected: autoTappingState.setSelectedPosition,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => _buildDropdownFilter(
                      width: 190,
                      label: 'Date',
                      value: autoTappingState.selectedDateLabel,
                      selectedMenuValue: autoTappingState.selectedDate.value,
                      items: autoTappingState.dateItems,
                      onSelected: (value) async {
                        final now = DateTime.now();

                        if (value == 'Select Date') {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate:
                                autoTappingState.selectedCustomDate.value ??
                                    now,
                            firstDate: DateTime(now.year - 5),
                            lastDate: DateTime(now.year + 1),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: green00968A,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (pickedDate != null) {
                            autoTappingState.setCustomDate(pickedDate);
                          }

                          return;
                        }

                        if (value == 'Select Date Range') {
                          final pickedRange = await showDateRangePicker(
                            context: context,
                            initialDateRange: autoTappingState
                                            .selectedStartDate.value !=
                                        null &&
                                    autoTappingState.selectedEndDate.value !=
                                        null
                                ? DateTimeRange(
                                    start: autoTappingState
                                        .selectedStartDate.value!,
                                    end:
                                        autoTappingState.selectedEndDate.value!,
                                  )
                                : null,
                            firstDate: DateTime(now.year - 5),
                            lastDate: DateTime(now.year + 1),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: green00968A,
                                    onPrimary: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );

                          if (pickedRange != null) {
                            autoTappingState.setDateRange(
                              startDate: pickedRange.start,
                              endDate: pickedRange.end,
                            );
                          }

                          return;
                        }

                        autoTappingState.setSelectedDate(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(
                () {
                  if (autoTappingState.isLoadingAutoTapping.value &&
                      autoTappingState.autoTappingList.isEmpty) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: green00968A,
                      ),
                    );
                  }

                  final list = autoTappingState.filteredList;

                  if (list.isEmpty) {
                    return _buildEmptyState();
                  }

                  return RefreshIndicator(
                    color: green00968A,
                    onRefresh: () {
                      return autoTappingState.loadAutoTapping(
                        forceRefresh: true,
                        idSite: autoTappingState.selectedIdSite.value,
                      );
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        return AutoTappingHistoryCard(
                          item: list[index],
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownFilter({
    required double width,
    required String label,
    required String value,
    String? selectedMenuValue,
    required List<String> items,
    required ValueChanged<String> onSelected,
  }) {
    final activeValue = selectedMenuValue ?? value;

    return PopupMenuButton<String>(
      initialValue: items.contains(activeValue) ? activeValue : null,
      color: Colors.white,
      elevation: 8,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xffE3DFF4),
          width: 1,
        ),
      ),
      onSelected: onSelected,
      itemBuilder: (context) {
        return items.map((item) {
          final isSelected = item == activeValue;

          return PopupMenuItem<String>(
            value: item,
            height: 42,
            child: Row(
              children: [
                SizedBox(
                  width: 22,
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 18,
                          color: green00968A,
                        )
                      : const SizedBox(),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    item,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: getBlackTextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
      child: Container(
        width: width,
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          color: const Color(0xffF7F5FF),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: const Color(0xffE3DFF4),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$label: $value',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: getBlackTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 22,
              color: Color(0xff20212B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 56,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 14),
            Text(
              'Data adjustment kosong',
              style: getBlackTextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada data auto tapping untuk site dan filter yang dipilih.',
              textAlign: TextAlign.center,
              style: getBlackTextStyle(
                fontSize: 13,
              ).copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AutoTappingHistoryCard extends StatelessWidget {
  final AutoTappingModel item;

  const AutoTappingHistoryCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final position = item.posisi.toString();

    final beforePsi = _toInt(item.pressureBefore);
    final afterPsi = _toInt(item.pressureAfter);
    final changePsi = afterPsi - beforePsi;

    final isIncrease = changePsi >= 0;

    final changeColor =
        isIncrease ? Colors.green.shade700 : Colors.red.shade600;

    final beforeDate = _formatDate(item.timestampBefore.toString());
    final beforeTime = _formatTime(item.timestampBefore.toString());

    final afterDate = _formatDate(item.timestampAfter.toString());
    final afterTime = _formatTime(item.timestampAfter.toString());

    final durationMinute = _durationMinute(
      item.timestampBefore.toString(),
      item.timestampAfter.toString(),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xffE8E8EF),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _positionBadge(position),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _pressureTitle(
                          beforePsi: beforePsi,
                          afterPsi: afterPsi,
                        ),
                      ),
                      Text(
                        '${changePsi > 0 ? '+' : ''}$changePsi PSI',
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailRow(
                    label: 'Unit ID',
                    child: Text(
                      item.devicename.toString(),
                      style: getBlackTextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    label: 'Before',
                    child: RichText(
                      text: TextSpan(
                        style: getBlackTextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: '$beforePsi PSI',
                            style: TextStyle(
                              color: Colors.red.shade600,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' (${_barFromPsi(beforePsi)} BAR)',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    label: 'After',
                    child: RichText(
                      text: TextSpan(
                        style: getBlackTextStyle(fontSize: 14),
                        children: [
                          TextSpan(
                            text: '$afterPsi PSI',
                            style: TextStyle(
                              color: green00968A,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' (${_barFromPsi(afterPsi)} BAR)',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _detailRow(
                    label: 'Time',
                    child: _timeRangeWidget(
                      beforeDate: beforeDate,
                      beforeTime: beforeTime,
                      afterDate: afterDate,
                      afterTime: afterTime,
                      durationMinute: durationMinute,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: green00968A.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Duration low pressure : $durationMinute min',
                          style: TextStyle(
                            color: green00968A,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _successBadge(),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _positionBadge(String position) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: green00968A,
        borderRadius: BorderRadius.circular(9),
        boxShadow: [
          BoxShadow(
            color: green00968A.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          position,
          style: getWhiteTextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  String _formatDate(String value) {
    final date = _parseDate(value);

    if (date == null) return '-';

    return DateFormat(
      'EEEE, dd MMMM yyyy,',
      'en_US',
    ).format(date);
  }

  Widget _timeRangeWidget({
    required String beforeDate,
    required String beforeTime,
    required String afterDate,
    required String afterTime,
    required int durationMinute,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          beforeDate,
          style: getBlackTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ).copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          beforeTime,
          style: getBlackTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Icon(
          Icons.arrow_downward,
          size: 14,
          color: Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          afterDate,
          style: getBlackTextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w400,
          ).copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          afterTime,
          style: getBlackTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _pressureTitle({
    required int beforePsi,
    required int afterPsi,
  }) {
    return Row(
      children: [
        Text(
          '$beforePsi',
          style: getBlackTextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 12),
        const Icon(
          Icons.arrow_forward,
          size: 18,
          color: Colors.black87,
        ),
        const SizedBox(width: 12),
        Text(
          '$afterPsi',
          style: getBlackTextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'PSI',
          style: getBlackTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _detailRow({
    required String label,
    required Widget child,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: getBlackTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          ':',
          style: getBlackTextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }

  Widget _successBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.10),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: Colors.green.withOpacity(0.18),
        ),
      ),
      child: Text(
        'Success',
        style: TextStyle(
          color: Colors.green.shade700,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

int _toInt(Object? value) {
  final raw = value?.toString() ?? '';
  final parsed = num.tryParse(raw);
  return parsed?.round() ?? 0;
}

String _barFromPsi(int psi) {
  return (psi * 0.0689476).toStringAsFixed(1);
}

DateTime? _parseDate(String value) {
  try {
    return DateTime.tryParse(value.replaceAll(' ', 'T'));
  } catch (_) {
    return null;
  }
}

String _formatTime(String value) {
  final date = _parseDate(value);

  if (date == null) return '-';

  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');

  return '$hour:$minute';
}

int _durationMinute(
  String startTime,
  String endTime,
) {
  final start = _parseDate(startTime);
  final end = _parseDate(endTime);

  if (start == null || end == null) return 0;

  final minute = end.difference(start).inMinutes;

  return minute == 0 ? 1 : minute;
}
