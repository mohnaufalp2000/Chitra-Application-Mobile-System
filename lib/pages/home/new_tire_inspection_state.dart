import 'dart:convert';
import 'dart:developer';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/send_tire_inspection.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class NewTireInspectionState extends GetxController {
  final FirebaseAuth auth = FirebaseAuth.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeState homeState = Get.find<HomeState>();

  var tasks = <Map<String, dynamic>>[].obs;
  var filteredTasks = <Map<String, dynamic>>[].obs;

  var isLoading = false.obs;
  var isExporting = false.obs;
  var isSending = false.obs;

  var exportProgress = 0.0.obs;
  var sendTireInspectionProgress = 0.0.obs;

  var selectedDateRange = Rxn<DateTimeRange>();
  var searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    // Jika currentSiteId sudah ada, langsung fetch
    if (homeState.currentSiteId.isNotEmpty) {
      fetchTasks();
    }

    // Listen perubahan currentSiteId (jika belum ready saat onInit)
    ever(homeState.currentSiteIdRx, (String siteId) {
      if (siteId.isNotEmpty) {
        fetchTasks();
      }
    });
  }

  Future<void> fetchTasks() async {
    try {
      isLoading.value = true;
      final currentIdSite = homeState.currentSiteId;

      log('=== FETCH tire_inspection ===');
      log('currentIdSite: $currentIdSite');

      // Coba fetch semua dulu tanpa filter untuk debug
      final allSnapshot = await firestore.collection('tire_inspection').get();

      log('Total semua dokumen tire_inspection: ${allSnapshot.docs.length}');
      for (final doc in allSnapshot.docs) {
        log('doc id: ${doc.id} | id_site: ${doc.data()['id_site']} | unit: ${doc.data()['unit']}');
      }

      // Fetch dengan filter id_site
      final querySnapshot = await firestore
          .collection('tire_inspection')
          .where('id_site', isEqualTo: currentIdSite)
          .get();

      log('Filtered by id_site=$currentIdSite: ${querySnapshot.docs.length} docs');

      final result = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['doc_id'] = doc.id;
        return data;
      }).toList();

      result.sort((a, b) {
        final dateA = DateTime.tryParse(a['tanggal'] ?? '') ?? DateTime(2000);
        final dateB = DateTime.tryParse(b['tanggal'] ?? '') ?? DateTime(2000);
        return dateB.compareTo(dateA);
      });

      tasks.assignAll(result);
      applyFilters();
    } catch (e) {
      log('Error fetching tire_inspection: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    var list = List<Map<String, dynamic>>.from(tasks);

    if (selectedDateRange.value != null) {
      final start = selectedDateRange.value!.start;
      final end = DateTime(
        selectedDateRange.value!.end.year,
        selectedDateRange.value!.end.month,
        selectedDateRange.value!.end.day,
        23,
        59,
        59,
      );

      list = list.where((task) {
        final dateStr =
            task['hari']?.toString(); // ← pakai 'hari' bukan 'tanggal'
        if (dateStr == null || dateStr.isEmpty) return false;
        final date = DateTime.tryParse(dateStr);
        if (date == null) return false;
        return !date.isBefore(start) && !date.isAfter(end);
      }).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      list = list.where((task) {
        return (task['unit'] ?? '').toString().toLowerCase().contains(query);
      }).toList();
    }

    filteredTasks.assignAll(list);
    log('filtered task : $filteredTasks');
  }

  void resetFilters() {
    selectedDateRange.value = null;
    searchQuery.value = '';
    fetchTasks();
  }

  Future<void> sendTireInspection(BuildContext context) async {
    try {
      isSending.value = true;
      sendTireInspectionProgress.value = 0.1;

      await Future.delayed(const Duration(milliseconds: 300));
      sendTireInspectionProgress.value = 0.3;

      final List<SendTireInspection> sendTireInspectionData = [];

      for (final task in filteredTasks.value) {
        final positions = task['posisi'] as List<dynamic>;

        for (final tire in positions) {
          sendTireInspectionData.add(
            SendTireInspection(
              date: task['hari'].toString(),
              unitNumber: task['unit'].toString(),
              tirePosition: tire['position'].toString(),
              pressure: tire['pressure'].toString(),
              rtd1: tire['rtd1'].toString(),
              hmOnInspect: tire['hm'].toString(),
              remark: tire['remarks'].toString(),
              pics: '',
              adjPress: tire['adjusmentPressure'].toString(),
              inspectorLocation: task['pit'].toString(),
              tireDamage: tire['damageTire'].toString(),
              brokenComponent: '0',
              snTire: tire['sn'].toString(),
              rimBaseCondition: tire['rimCondition'][0]['condition'].toString(),
              rimBaseRemark: tire['rimCondition'][0]['remark'].toString(),
              flangeCondition: tire['rimCondition'][1]['condition'].toString(),
              flangeRemark: tire['rimCondition'][1]['remark'].toString(),
              lockRingCondition:
                  tire['rimCondition'][2]['condition'].toString(),
              lockRingRemark: tire['rimCondition'][2]['remark'].toString(),
              valveCondition: tire['rimCondition'][3]['condition'].toString(),
              valveRemark: tire['rimCondition'][3]['remark'].toString(),
              coreValveCondition:
                  tire['rimCondition'][4]['condition'].toString(),
              coreValveRemark: tire['rimCondition'][4]['remark'].toString(),
              nutStudCondition: tire['rimCondition'][5]['condition'].toString(),
              nutStudRemark: tire['rimCondition'][5]['remark'].toString(),
              temperatureStatus: tire['temperatureStatus']?.toString() ?? 'Hot',
              site: task['id_site'].toString(),
            ),
          );
        }
      }

      log(
        'Payload Tire Inspection : ${jsonEncode({
              'inspects':
                  sendTireInspectionData.map((e) => e.toJson()).toList(),
            })}',
      );

      await ApiService.sendTireInspection(sendTireInspectionData);

      sendTireInspectionProgress.value = 1.0;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF009688),
          content: Text(
            'Send data berhasil!',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      log('Error send tire inspection : $e');
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      isSending.value = false;
      sendTireInspectionProgress.value = 0.0;
    }
  }

  Future<void> exportToExcel(BuildContext context) async {
    try {
      isExporting.value = true;
      exportProgress.value = 0.1;

      final id = const Uuid();
      await Future.delayed(const Duration(milliseconds: 300));
      exportProgress.value = 0.3;

      // Ambil siteName dari homeState
      final siteName = homeState.siteName.isNotEmpty
          ? homeState.siteName
          : homeState.currentSiteId;

      final file = await createFolderPath(
        id.v4(),
        'tire_inspection',
        email: auth.currentUser?.email ?? 'unknown',
        site: siteName,
      );

      exportProgress.value = 0.65;

      // Langsung pass filteredTasks — tidak perlu flatten
      // createTireInspectionExcel sudah handle loop posisi di dalamnya
      exportProgress.value = 0.85;
      // yang bikin error !!
      final cleanedData = takeOutRimCondition(filteredTasks);
      log('filtered data : ${cleanedData.toList()}');

      final bytes =
          await createExcel('tire_inspection', task: cleanedData.toList());
      await file.writeAsBytes(bytes, flush: true);

      exportProgress.value = 1.0;

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF009688),
        content: const Text('Export berhasil!',
            style: TextStyle(color: Colors.white)),
      ));

      await OpenFile.open(file.path);
    } catch (e) {
      log('Export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text('Export gagal: $e'),
      ));
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      isExporting.value = false;
      exportProgress.value = 0.0;
    }
  }

  List<Map<String, dynamic>> takeOutRimCondition(List tasks) {
    return tasks.map((task) {
      final newTask = Map<String, dynamic>.from(task);

      if (newTask['posisi'] is List) {
        newTask['posisi'] = (newTask['posisi'] as List).map((pos) {
          final newPos = Map<String, dynamic>.from(pos);

          // 🔥 HAPUS rimCondition
          newPos.remove('rimCondition');

          return newPos;
        }).toList();
      }

      return newTask;
    }).toList();
  }
}
