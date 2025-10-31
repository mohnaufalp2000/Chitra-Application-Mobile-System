import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/pages/network/network_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/data/id_site.dart';

class HomeState extends GetxController {
  final InternetState networkController = Get.find<InternetState>();
  final firestore = FirebaseFirestore.instance;

  final RxString versionNumberRx = ''.obs;
  String get versionNumber => versionNumberRx.value;

  // === STATE BARU: SITE LIST (Mengganti SiteBloc) ===
  final RxBool isSiteLoading = false.obs;
  final RxList<Site> listSite = <Site>[].obs;
  final RxString siteError = ''.obs;
  final RxString currentSiteIdRx = ''.obs;

  final RxString userAccessId = ''.obs;

  // === STATE INVENTORY BAN (TireInventBloc) ===
  final RxBool isInventLoading = false.obs;
  final RxString inventErrorMessage = ''.obs;
  final RxBool hasInventError = false.obs;
  final inventLoadingPercent = 0.0.obs;
  final RxList<Map<String, dynamic>> tireInventData =
      <Map<String, dynamic>>[].obs;
  final List<String> statusList = ['New', 'Repair', 'Spare', 'Scrap'];
  final lastSyncInvent = ''.obs;
  var selectedInventoryStatus = ''.obs;
  var selectedInventoryIdSite = ''.obs;
  var selectedInventoryTotal = ''.obs;

  // === STATE KONDISI BAN ===
  final RxBool isConditionLoading = false.obs;
  final RxBool hasConditionError = false.obs;
  final RxMap<String, int> mapRating = <String, int>{}.obs;
  final RxString conditionErrorMessage = ''.obs;
  final conditionLoadingPercent = 0.0.obs;
  final lastSyncCondition = ''.obs;

  final RxMap<String, dynamic> rxUser = <String, dynamic>{}.obs;
  Map<String, dynamic> get user => rxUser.value;

  String get currentSiteId => currentSiteIdRx.value;
  Site? get selectedSite =>
      listSite.firstWhereOrNull((site) => site.idSite == currentSiteId);
  String get siteName => selectedSite?.site ?? 'Loading Site...';

  bool get isUserOffice =>
      userAccessId.value == '1' || userAccessId.value == '2';

  bool get isSingleSiteUser =>
      !isUserOffice &&
      userAccessId.value.isNotEmpty &&
      userAccessId.value != '1' &&
      userAccessId.value != '2';

  bool get hasSingleClusterSite => clusterSites.length == 1;

  @override
  void onInit() {
    super.onInit();
    retrieveUser();
    retrieveVersionNumber();
    fetchSites().then((_) async {
      await _loadInitialDataAfterSitesReady();
    });
  }

  Future<void> retrieveUser() async {
    rxUser.value = await getUserPreferences();
  }

  List<IdSite> get clusterSites {
    final id = userAccessId.value;

    if (['52', '35', '137'].contains(id)) return bmbSites;
    if (['65', '166', '174', '172'].contains(id)) return bibSites;
    if (['32', '130'].contains(id)) return mhuSites;

    return []; // fallback: no cluster
  }

  String get clusterName {
    final id = userAccessId.value;
    if (['52', '35', '137'].contains(id)) return 'BMB';
    if (['65', '166', '174', '172'].contains(id)) return 'BIB';
    if (['32', '130'].contains(id)) return 'MHU';
    return 'Unknown';
  }

  bool get shouldShowSiteWarning {
    // Jika user access adalah 1 atau 2 (Office / All-CK)
    // dan site yang aktif belum dipilih (masih kosong atau sama dengan idSite awal)
    return (userAccessId.value == '1' || userAccessId.value == '2') &&
        (currentSiteIdRx.value == '1' || currentSiteIdRx.value == '2');
  }

  // 🚀 Metode baru untuk memuat ID awal dan data ban setelah sites siap
  Future<void> _loadInitialDataAfterSitesReady() async {
    // 1. Ambil ID awal dari SharedPreferences
    String initialId = await getIdSitePreferences();
    userAccessId.value = initialId;
    // 2. Jika ID awal adalah '1' (Office) atau '2' (All-CK), kita hanya tampilkan Dropdown.
    // Data ban tidak akan dimuat sampai pengguna memilih site dari Dropdown.
    if (initialId == '1' || initialId == '2') {
      currentSiteIdRx.value =
          initialId; // Set current ID agar Dropdown tahu defaultnya
      // *Tire data tidak di-fetch di sini.*
    } else {
      // 3. Jika ID adalah Site biasa (misal: '52'), fetch data ban.
      fetchAllHomeData(idSite: initialId);
    }
    log('print userAccessId : $userAccessId');
    log('print currentId : $currentSiteId');
    log('print selectedId : $selectedSite');
  }

  Future<void> fetchAllHomeData({required String idSite}) async {
    // 1. Set ID Site sebagai sumber kebenaran utama. Ini memicu Obx.
    currentSiteIdRx.value = idSite;
    // inventLoadingPercent.value = 0;

    // 2. Ambil Site object yang sedang aktif (melalui getter)
    String idToFetch = selectedSite?.idSite ?? idSite;

    // 3. Hanya fetch data ban/kondisi jika ID Site bukan ID yang non-Site (Office/All-CK)
    if (idToFetch != '1' && idToFetch != '2') {
      await Future.wait([
        fetchTireInventory(idToFetch),
        fetchTireCondition(idToFetch),
      ]);
    } else {
      // Jika idToFetch adalah '1' atau '2', reset data ban/kondisi.
      tireInventData.clear();
      mapRating.clear();
      inventErrorMessage.value = '';
      conditionErrorMessage.value = '';
      isInventLoading.value = false;
      isConditionLoading.value = false;
      log('ID Site Office/All-CK: Skipping tire data fetch.');
    }
  }

  // --- LOGIKA TIRE INVENTORY (Ganti TireInventBloc) ---
  Future<void> fetchTireInventory(String idSite) async {
    log('print userAccessId Invent: $userAccessId');
    log('print currentId Invent : $currentSiteId');
    log('print selectedId Invent : $selectedSite');
    isInventLoading.value = true;
    inventErrorMessage.value = '';
    inventLoadingPercent.value = 0;

    // Jika userAccessId adalah 1 atau 2, skip cache total
    if (userAccessId.value == '1' || userAccessId.value == '2') {
      log('⚡ User $userAccessId → skip cache, ambil langsung dari API');
      try {
        if (Platform.isAndroid) {
          await Permission.phone.request();
        }

        final totalStatus = statusList.length;
        int processed = 0;

        final count = await Future.wait(statusList.map((status) async {
          final total = await ApiService.getTireSpecCount(idSite, status);
          processed++;
          double targetPercent = (processed / totalStatus) * 100;
          await _animateProgressTo(targetPercent);
          return {'status': status, 'total': total};
        }));

        tireInventData.value = count;
      } catch (e) {
        log('Error fetching inventory (no cache mode): $e');
        inventErrorMessage.value = 'Failed to load inventory: ${e.toString()}';
        hasInventError.value = true;
      } finally {
        isInventLoading.value = false;
      }
      return; // stop di sini
    }
    // if (networkController.isConnected.isFalse) {
    //   // await _loadCachedInventData();
    //   isInventLoading.value = false;
    //   return;
    // }

    // --- MODE NORMAL (DENGAN CACHE) ---
    if (networkController.isConnected.isFalse ||
        await networkController.isNetworkReliable() == false) {
      final cached = await _loadCachedInventData(idSite);
      if (cached.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final savedTime =
            prefs.getString('last_sync_invent_$idSite') ?? 'Unknown';
        lastSyncInvent.value = '📦 Offline mode (Last synced: $savedTime)';
        tireInventData.value = cached;

        log('📴 Loaded inventory from cache (offline mode)');
        isInventLoading.value = false;
        return;
      }
    }

    try {
      if (Platform.isAndroid) {
        await Permission.phone.request();
      }

      final totalStatus = statusList.length;
      int processed = 0;

      final count = await Future.wait(statusList.map((status) async {
        final total = await ApiService.getTireSpecCount(idSite, status);
        processed++;
        double targetPercent = (processed / totalStatus) * 100;
        await _animateProgressTo(targetPercent);
        return {'status': status, 'total': total};
      }));

      tireInventData.value = count;

      // Simpan cache hanya untuk user selain 1 & 2
      await _cacheInventData(idSite, count);

      // Simpan waktu sync (saat ini)
      final now = DateTime.now();
      final formatted = DateFormat("dd MMM yyyy HH:mm").format(now);
      lastSyncInvent.value = 'Last synced: $formatted';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_invent_$idSite', formatted);
    } catch (e) {
      log('Error fetching tire inventory: $e');
      inventErrorMessage.value = 'Failed to load inventory: ${e.toString()}';
      hasInventError.value = true;
    } finally {
      isInventLoading.value = false;
    }
  }

  Future<void> _cacheInventData(
      String idSite, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('invent_$idSite', jsonEncode(data));
    log('✅ Cached tire inventory for site $idSite');
  }

  Future<List<Map<String, dynamic>>> _loadCachedInventData(
      String idSite) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('invent_$idSite');
    if (jsonString != null) {
      log('📦 Loaded cached tire inventory for $idSite');
      return List<Map<String, dynamic>>.from(jsonDecode(jsonString));
    }
    return [];
  }

  void setInventorySelection({
    required String status,
    required String idSite,
    required String total,
  }) {
    selectedInventoryStatus.value = status;
    selectedInventoryIdSite.value = idSite;
    selectedInventoryTotal.value = total;
  }

  Future<void> _animateProgressTo(double target) async {
    while (inventLoadingPercent.value < target) {
      inventLoadingPercent.value += 1;
      await Future.delayed(
          const Duration(milliseconds: 20)); // kecepatan animasi
    }
  }

  Future<void> fetchSites() async {
    isSiteLoading.value = true;
    siteError.value = '';

    try {
      if (networkController.isConnected.isFalse) {
        siteError.value = 'No internet connection.';
        return;
      }

      List<Site> fetchedList = await ApiService.getAllSite();

      // Sorting & Insering Logic (dari Bloc lama)
      fetchedList.sort((a, b) {
        return a.site!.toLowerCase().compareTo(b.site!.toLowerCase());
      });
      // fetchedList.insert(
      //   0,
      //   Site(idSite: '1', site: 'Office', lastUpdate: '2023-10-16'),
      // );
      // fetchedList.insert(
      //   1,
      //   Site(idSite: '2', site: 'All-CK', lastUpdate: '2023-10-16'),
      // );

      listSite.value = fetchedList;
      // saveSiteToLocalPreferences(fetchedList); // Simpan ke local
    } catch (e) {
      log('Error fetching sites: $e');
      siteError.value = e.toString();
    } finally {
      isSiteLoading.value = false;
    }
  }

  Future<void> fetchTireCondition(String idSite) async {
    isConditionLoading.value = true;
    conditionErrorMessage.value = '';
    conditionLoadingPercent.value = 0;

    if (userAccessId.value == '1' || userAccessId.value == '2') {
      log('⚡ User $userAccessId → skip cache, ambil langsung dari API');
      try {
        final listSize = await ApiService.getTireCondition(idSite);
        int total = listSize.length;
        int processed = 0;

        for (var unit in listSize) {
          processed++;
          conditionLoadingPercent.value = processed / total;
          await Future.delayed(const Duration(milliseconds: 5));
        }

        final allRating = listSize.map((u) => u.rating ?? '').toList();
        final result = {
          "A": allRating.where((r) => r == "A").length,
          "B": allRating.where((r) => r == "B").length,
          "C": allRating.where((r) => r == "C").length,
          "X": allRating.where((r) => r == "X").length,
        };

        mapRating.value = result;
      } catch (e) {
        log('Error fetching tire condition (no cache mode): $e');
        conditionErrorMessage.value = 'Failed to load condition data.';
        hasConditionError.value = true;
      } finally {
        isConditionLoading.value = false;
      }
      return; // stop di sini
    }

    // --- MODE NORMAL (DENGAN CACHE) ---
    if (networkController.isConnected.isFalse ||
        await networkController.isNetworkReliable() == false) {
      final cached = await _loadCachedConditionData(idSite);
      if (cached.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final savedTime =
            prefs.getString('last_sync_condition_$idSite') ?? 'Unknown';
        lastSyncCondition.value = '📦 Offline mode \n(Last synced: $savedTime)';
        mapRating.value = cached;
        log('📴 Loaded condition from cache (offline mode)');
        isConditionLoading.value = false;
        return;
      }
    }

    try {
      final listSize = await ApiService.getTireCondition(idSite);
      int total = listSize.length;
      int processed = 0;

      for (var unit in listSize) {
        processed++;
        conditionLoadingPercent.value = processed / total;
        await Future.delayed(const Duration(milliseconds: 5));
      }

      final allRating = listSize.map((u) => u.rating ?? '').toList();
      final result = {
        "A": allRating.where((r) => r == "A").length,
        "B": allRating.where((r) => r == "B").length,
        "C": allRating.where((r) => r == "C").length,
        "X": allRating.where((r) => r == "X").length,
      };

      mapRating.value = result;

      // Simpan cache hanya untuk user selain 1 & 2
      await _cacheConditionData(idSite, result);

      // Simpan waktu sync (saat ini)
      final now = DateTime.now();
      final formatted = DateFormat("dd MMM yyyy HH:mm").format(now);
      lastSyncCondition.value = 'Last synced: $formatted';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_sync_condition_$idSite', formatted);
    } catch (e) {
      log('Error fetching tire condition: $e');
      conditionErrorMessage.value = 'Failed to load condition data.';
      hasConditionError.value = true;
    } finally {
      isConditionLoading.value = false;
    }
  }

  Future<void> _cacheConditionData(String idSite, Map<String, int> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('condition_$idSite', jsonEncode(data));
    log('✅ Cached tire condition for site $idSite');
  }

  Future<Map<String, int>> _loadCachedConditionData(String idSite) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('condition_$idSite');
    if (jsonString != null) {
      log('📦 Loaded cached tire condition for $idSite');
      return Map<String, int>.from(jsonDecode(jsonString));
    }
    return {};
  }

  Future<void> retryFetch(
      {required String type, required String idSite}) async {
    if (type == 'inventory') {
      await fetchTireInventory(idSite);
    } else if (type == 'condition') {
      await fetchTireCondition(idSite);
    } else if (type == 'sites') {
      await fetchSites();
    }
  }

  Future<void> retrieveVersionNumber() async {
    try {
      // 🔹 Ambil versi aplikasi dari perangkat
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // 🔹 Ambil versi terbaru dari Firestore
      final versionDoc = await FirebaseFirestore.instance
          .collection('version')
          .doc('version')
          .get();

      final latestVersion = versionDoc.data()?['number'];

      if (latestVersion == null) {
        print('⚠️ Field "number" di Firestore kosong.');
        return;
      }

      versionNumberRx.value = latestVersion;

      // 🔹 Cek perbedaan versi
      if (currentVersion != latestVersion) {
        showUpdateDialog(currentVersion, latestVersion);
      }
    } catch (e) {
      print('❌ Gagal cek versi aplikasi: $e');
    }
  }

  void showUpdateDialog(String currentVersion, String latestVersion) {
    Get.dialog(
      barrierDismissible: false,
      AlertDialog(
        title: const Text('Update Diperlukan ⚠️'),
        content: Text(
          'Versi aplikasi kamu sudah tidak terbaru.\n\n'
          'Versi saat ini: $currentVersion\n'
          'Versi terbaru: $latestVersion\n\n'
          'Silakan update aplikasi ke versi terbaru untuk melanjutkan.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Get.back(); // ❌ Tutup dialog
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              // 🔹 Arahkan ke Play Store (opsional)
              // launchUrl(Uri.parse('https://play.google.com/store/apps/details?id=com.namapackage'));
              openPlayStore('camos');
            },
            child: const Text('Update Sekarang'),
          ),
        ],
      ),
    );
  }

  String greeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 15) {
      return 'Afternoon';
    } else if (hour < 18) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }
}
