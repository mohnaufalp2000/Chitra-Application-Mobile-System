import 'package:camos/pages/home/home_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:camos/core/services/model/site.dart'; // pastikan path sesuai

class TireInspectionState extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeState homeState = Get.find<HomeState>();

  // Observable variables
  var tasks = <Map<String, dynamic>>[].obs;
  var filteredTasks = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  var selectedDateRange = Rxn<DateTimeRange>();
  var searchQuery = ''.obs;
  var expandedIndex = (-1).obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  /// 🔹 Fetch data from Firestore
  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      final currentIdSite = homeState.currentSiteId;

      final querySnapshot = await firestore
          .collection('task')
          .where('id_site', isEqualTo: currentIdSite)
          .orderBy('last_update', descending: true)
          .get();

      final result = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'unit': data['unit'] ?? '-',
          'pressure': data['pressure'] ?? '-',
          'rtd': data['rtd'] ?? '-',
          'tire_size': data['tire_size'] ?? '-',
          'tire_damage': data['tire_damage'] ?? '-',
          'remarks': data['remarks'] ?? '-',
          'last_update': (data['last_update'] ?? '').toString(),
        };
      }).toList();

      tasks.assignAll(result);
      applyFilters();
    } catch (e) {
      print("Error fetching tasks: $e");
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Apply search and date filter
  void applyFilters() {
    var list = tasks;

    // filter berdasarkan date range
    if (selectedDateRange.value != null) {
      list = list
          .where((task) {
            final dateStr = task['date']?.toString();
            if (dateStr == null || dateStr.isEmpty) return false;
            final date = DateTime.tryParse(dateStr);
            if (date == null) return false;
            return date.isAfter(selectedDateRange.value!.start
                    .subtract(const Duration(days: 1))) &&
                date.isBefore(
                    selectedDateRange.value!.end.add(const Duration(days: 1)));
          })
          .toList()
          .obs;
    }

    // filter berdasarkan search
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list
          .where((task) {
            final unit = (task['unit'] ?? '').toString().toLowerCase();
            return unit.contains(query);
          })
          .toList()
          .obs;
    }

    filteredTasks.assignAll(list);
  }
}
