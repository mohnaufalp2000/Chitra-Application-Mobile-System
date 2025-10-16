import 'dart:developer';
import 'dart:io';

import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/pages/network/network_state.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeState extends GetxController {
  final InternetState networkController = Get.find<InternetState>();

  // === STATE BARU: SITE LIST (Mengganti SiteBloc) ===
  final RxBool isSiteLoading = false.obs;
  final RxList<Site> listSite = <Site>[].obs;
  final RxString siteError = ''.obs;
  final RxString currentSiteIdRx = ''.obs;

  final RxString userAccessId = ''.obs;

  // === STATE INVENTORY BAN (TireInventBloc) ===
  final RxBool isInventLoading = false.obs;
  final RxString inventErrorMessage = ''.obs;
  final RxList<Map<String, dynamic>> tireInventData =
      <Map<String, dynamic>>[].obs;
  final List<String> statusList = ['New', 'Repair', 'Spare', 'Scrap'];

  // === STATE KONDISI BAN ===
  final RxBool isConditionLoading = false.obs;
  final RxMap<String, int> mapRating = <String, int>{}.obs;
  final RxString conditionErrorMessage = ''.obs;

  String get currentSiteId => currentSiteIdRx.value;
  Site? get selectedSite =>
      listSite.firstWhereOrNull((site) => site.idSite == currentSiteId);
  String get siteName => selectedSite?.site ?? 'Loading Site...';

  @override
  void onInit() {
    super.onInit();
    fetchSites().then((_) async {
      await _loadInitialDataAfterSitesReady();
    });
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
  }

  Future<void> fetchAllHomeData({required String idSite}) async {
    // 1. Set ID Site sebagai sumber kebenaran utama. Ini memicu Obx.
    currentSiteIdRx.value = idSite;

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
    isInventLoading.value = true;
    inventErrorMessage.value = '';

    // Penanganan Koneksi dan Cache Awal
    if (networkController.isConnected.isFalse) {
      // await _loadCachedInventData();
      isInventLoading.value = false;
      return;
    }

    if (await networkController.isNetworkReliable() == false) {
      //  await _loadCachedInventData();
      isInventLoading.value = false;
      return;
    }

    try {
      if (Platform.isAndroid) {
        await Permission.phone.request();
      }

      // Mengambil total ban dari setiap status (future.wait untuk efisiensi)
      final count = await Future.wait(statusList.map((status) async {
        final total = await ApiService.getTireSpecCount(idSite, status);
        return {'status': status, 'total': total};
      }));

      // Update state data utama
      tireInventData.value = count;

      // Logika caching data detail ban
      // await _cacheInventData(idSite, count, siteData['siteName'] ?? '');
    } catch (e) {
      log('Error fetching tire inventory: $e');
      inventErrorMessage.value = 'Failed to load inventory: ${e.toString()}';
      // await _loadCachedInventData(); // Coba muat cache sebagai fallback
    } finally {
      isInventLoading.value = false;
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

    if (networkController.isConnected.isFalse) {
      // await _loadCachedConditionData();
      isConditionLoading.value = false;
      return;
    }

    try {
      final listSize = await ApiService.getTireCondition(idSite);

      // Logika Pemrosesan Data Rating
      List<String> allRating =
          listSize.map((unit) => unit.rating ?? '').toList();

      final result = {
        "A": allRating.where((r) => r == "A").length,
        "B": allRating.where((r) => r == "B").length,
        "C": allRating.where((r) => r == "C").length,
        "X": allRating.where((r) => r == "X").length,
      };

      mapRating.value = result;

      // Save to local
      // final prefs = await SharedPreferences.getInstance();
      // final jsonData = jsonEncode({'allRatingResult': result});
      // await prefs.setString('tire_condition', jsonData);
    } catch (e) {
      log('Error fetching tire condition: $e');
      conditionErrorMessage.value = 'Failed to load condition data.';
      // await _loadCachedConditionData();
    } finally {
      isConditionLoading.value = false;
    }
  }
}
