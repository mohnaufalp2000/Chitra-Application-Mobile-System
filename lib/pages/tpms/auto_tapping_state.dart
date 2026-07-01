import 'dart:developer';

import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/auto_tapping_model.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AutoTappingState extends GetxController {
  final isLoadingAutoTapping = false.obs;

  final autoTappingList = <AutoTappingModel>[].obs;

  final selectedIdSite = ''.obs;
  final selectedSiteName = ''.obs;

  final selectedUnit = 'All'.obs;
  final selectedPosition = 'All'.obs;

  // DATE FILTER
  final selectedDate = 'All'.obs;

  // Single date
  final selectedCustomDate = Rxn<DateTime>();

  // Select Date Range
  final selectedStartDate = Rxn<DateTime>();
  final selectedEndDate = Rxn<DateTime>();

  final unitItems = <String>['All'].obs;

  final positionItems = <String>[
    'All',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
  ].obs;

  final dateItems = <String>[
    'All',
    'Today',
    'Yesterday',
    'Last 7 Days',
    'Last 30 Days',
    'Select Date',
    'Select Date Range',
  ].obs;

  String get selectedDateLabel {
    if (selectedDate.value == 'Select Date') {
      final date = selectedCustomDate.value;

      if (date == null) {
        return 'Select Date';
      }

      return DateFormat('dd MMM yyyy', 'id_ID').format(date);
    }

    if (selectedDate.value == 'Select Date Range') {
      final startDate = selectedStartDate.value;
      final endDate = selectedEndDate.value;

      if (startDate == null || endDate == null) {
        return 'Select Date Range';
      }

      final startText = DateFormat('dd MMM', 'id_ID').format(startDate);
      final endText = DateFormat('dd MMM yyyy', 'id_ID').format(endDate);

      return '$startText - $endText';
    }

    return selectedDate.value;
  }

  Future<void> loadAutoTapping({
    bool forceRefresh = false,
    String? idSite,
    String? siteName,
  }) async {
    if (idSite != null || siteName != null) {
      setSelectedSite(
        idSite: idSite ?? selectedIdSite.value,
        siteName: siteName ?? selectedSiteName.value,
      );
    }

    if (isLoadingAutoTapping.value) return;

    if (autoTappingList.isNotEmpty && !forceRefresh) {
      _refreshUnitItemsBySite();
      return;
    }

    try {
      isLoadingAutoTapping.value = true;

      final result = await ApiService.getAutoTappingSPM();

      autoTappingList.assignAll(result);

      _refreshUnitItemsBySite();
    } catch (e) {
      log('load auto tapping error: $e');
    } finally {
      isLoadingAutoTapping.value = false;
    }
  }

  void setSelectedSite({
    required String idSite,
    required String siteName,
  }) {
    final isDifferentSite = selectedIdSite.value != idSite;

    selectedIdSite.value = idSite;
    selectedSiteName.value = siteName;

    if (isDifferentSite) {
      selectedUnit.value = 'All';
      selectedPosition.value = 'All';
    }

    _refreshUnitItemsBySite();
  }

  void _refreshUnitItemsBySite() {
    final siteId = selectedIdSite.value;

    final siteFilteredList = autoTappingList.where((item) {
      if (siteId.isEmpty) return true;

      return item.idSite.toString() == siteId;
    }).toList();

    final units = siteFilteredList
        .map((item) => item.devicename.toString())
        .where((unit) => unit.isNotEmpty && unit != 'null')
        .toSet()
        .toList();

    units.sort();

    unitItems.assignAll([
      'All',
      ...units,
    ]);

    if (!unitItems.contains(selectedUnit.value)) {
      selectedUnit.value = 'All';
    }
  }

  List<AutoTappingModel> get filteredList {
    final siteId = selectedIdSite.value;

    final list = autoTappingList.where((item) {
      final itemSiteId = item.idSite.toString();
      final unit = item.devicename.toString();
      final position = item.posisi.toString();

      final isSiteMatch = siteId.isEmpty || itemSiteId == siteId;

      final isUnitMatch =
          selectedUnit.value == 'All' || unit == selectedUnit.value;

      final isPositionMatch =
          selectedPosition.value == 'All' || position == selectedPosition.value;

      final isDateMatch = _isDateMatch(
        item.timestampAfter.toString(),
        selectedDate.value,
      );

      return isSiteMatch && isUnitMatch && isPositionMatch && isDateMatch;
    }).toList();

    list.sort((a, b) {
      final dateA = _parseDate(a.timestampAfter.toString());
      final dateB = _parseDate(b.timestampAfter.toString());

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return list;
  }

  void setSelectedUnit(String value) {
    selectedUnit.value = value;
  }

  void setSelectedPosition(String value) {
    selectedPosition.value = value;
  }

  void setSelectedDate(String value) {
    selectedDate.value = value;

    if (value != 'Select Date') {
      selectedCustomDate.value = null;
    }

    if (value != 'Select Date Range') {
      selectedStartDate.value = null;
      selectedEndDate.value = null;
    }
  }

  void setCustomDate(DateTime value) {
    selectedCustomDate.value = DateTime(
      value.year,
      value.month,
      value.day,
    );

    selectedStartDate.value = null;
    selectedEndDate.value = null;

    selectedDate.value = 'Select Date';
  }

  void setDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    selectedStartDate.value = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    selectedEndDate.value = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    selectedCustomDate.value = null;

    selectedDate.value = 'Select Date Range';
  }

  bool _isDateMatch(String dateString, String filter) {
    if (filter == 'All') return true;

    final date = _parseDate(dateString);
    if (date == null) return false;

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final itemDate = DateTime(date.year, date.month, date.day);

    if (filter == 'Today') {
      return itemDate == today;
    }

    if (filter == 'Yesterday') {
      final yesterday = today.subtract(const Duration(days: 1));
      return itemDate == yesterday;
    }

    if (filter == 'Last 7 Days') {
      final startDate = today.subtract(const Duration(days: 7));

      return itemDate.isAtSameMomentAs(startDate) ||
          itemDate.isAfter(startDate);
    }

    if (filter == 'Last 30 Days') {
      final startDate = today.subtract(const Duration(days: 30));

      return itemDate.isAtSameMomentAs(startDate) ||
          itemDate.isAfter(startDate);
    }

    if (filter == 'Select Date') {
      final customDate = selectedCustomDate.value;

      if (customDate == null) return false;

      return itemDate.year == customDate.year &&
          itemDate.month == customDate.month &&
          itemDate.day == customDate.day;
    }

    if (filter == 'Select Date Range') {
      final startDate = selectedStartDate.value;
      final endDate = selectedEndDate.value;

      if (startDate == null || endDate == null) return false;

      final start = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
      );

      return (itemDate.isAtSameMomentAs(start) || itemDate.isAfter(start)) &&
          (itemDate.isAtSameMomentAs(end) || itemDate.isBefore(end));
    }

    return true;
  }

  DateTime? _parseDate(String value) {
    try {
      return DateTime.tryParse(value.replaceAll(' ', 'T'));
    } catch (_) {
      return null;
    }
  }
}
