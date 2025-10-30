import 'dart:convert';
import 'dart:developer';
import 'package:camos/pages/home/home_state.dart';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/api_service.dart';
import '../../core/services/model/site.dart';
import '../../core/services/model/tire_spec.dart';

class TireInventoryState extends GetxController {
  final HomeState homeState = Get.find<HomeState>();

  /// 🔹 Data utama
  var mapSizeInvent = <String, dynamic>{}.obs;

  /// 🔹 State flags
  var isLoading = false.obs;
  var loadingPercent = 0.0.obs;
  var hasError = false.obs;
  var errorMessage = ''.obs;

  /// 🔹 Info sync
  var lastSyncInvent = ''.obs;

  /// ✅ Fungsi utama
  Future<void> getDetailTireInvent({
    required String total,
    required String idSite,
    required String status,
  }) async {
    try {
      isLoading.value = true;
      hasError.value = false;
      errorMessage.value = '';

      final connectivityResult = await Connectivity().checkConnectivity();

      final userAccessId = homeState.userAccessId.value; // ✅ dari HomeState

      log('📦 Get Detail Tire Invent => '
          'total: $total | idSite: $idSite | status: $status | userAccessId: $userAccessId | connectivity: $connectivityResult');

      // === OFFLINE MODE ===
      if (connectivityResult == ConnectivityResult.none) {
        if (userAccessId == '1' || userAccessId == '2') {
          hasError.value = true;
          errorMessage.value = 'No internet connection.';
          isLoading.value = false;
          return;
        } else {
          log('📴 Offline mode (local cache)');

          final prefs = await SharedPreferences.getInstance();
          final cachedData = prefs.getString('detail_tire_spec');

          if (cachedData == null) {
            hasError.value = true;
            errorMessage.value = 'No cached data found.';
            isLoading.value = false;
            return;
          }

          final decodedData = jsonDecode(cachedData) as Map<String, dynamic>;

          mapSizeInvent.value = {
            'New': decodedData['new'],
            'Repair': decodedData['repair'],
            'Spare': decodedData['spare'],
            'Scrap': decodedData['scrap'],
          };

          lastSyncInvent.value = 'Offline Cache';
          isLoading.value = false;
          return;
        }
      }

      // === ONLINE MODE ===
      if (connectivityResult == ConnectivityResult.mobile ||
          connectivityResult == ConnectivityResult.ethernet ||
          connectivityResult == ConnectivityResult.wifi) {
        if (userAccessId == '1' || userAccessId == '2') {
          await _fetchFromServer(total, idSite, status);
        } else {
          await _fetchFromCache(status);
        }
      }
    } catch (e, s) {
      log('❌ Error getDetailTireInvent: $e\n$s');
      hasError.value = true;
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  /// 🔹 Ambil data dari API
  Future<void> _fetchFromServer(
      String total, String idSite, String status) async {
    try {
      hasError.value = false;
      loadingPercent.value = 0.0;

      List<TireSpec> listInvent = [];
      if (status == 'Scrap') {
        total = total.split('|')[1];
      }
      int totalInt = int.parse(total);
      int processed = 0;

      // 🔸 Gunakan langsung dari HomeState
      final userAccessId = homeState.userAccessId.value;
      final selectedIdSite = homeState.currentSiteId;

      Site site = await ApiService.getSite(selectedIdSite);
      idSite = site.idSite ?? idSite;

      if (totalInt > 0) {
        // ambil data per batch 10 item
        for (int i = 0; i < totalInt; i += 10) {
          // 🔹 Ambil data batch dari API
          final batch = await ApiService.getDetailInventory(
            status,
            i.toString(),
            idSite,
          );
          listInvent.addAll(batch);

          // 🔹 Update progress
          processed = i + 10;
          if (processed > totalInt) processed = totalInt;

          loadingPercent.value = processed / totalInt * 100;

          // beri delay agar progress terlihat halus
          await Future.delayed(const Duration(milliseconds: 30));
        }
      }

      Map<String, dynamic> resultData =
          _processInventoryData(status, listInvent);

      mapSizeInvent.value = {
        'New': status == 'New' ? resultData : {},
        'Repair': status == 'Repair' ? resultData : {},
        'Spare': status == 'Spare' ? resultData : {},
        'Scrap': status == 'Scrap' ? resultData : {},
      };

      final now = DateTime.now();
      lastSyncInvent.value =
          'Last sync: ${now.hour}:${now.minute.toString().padLeft(2, '0')}';
      loadingPercent.value = 1.0;
    } catch (e) {
      log('❌ Server fetch error: $e');
      hasError.value = true;
      errorMessage.value = e.toString();
    }
  }

  /// 🔹 Ambil dari cache lokal
  Future<void> _fetchFromCache(String status) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString('detail_tire_spec');

    if (cachedData == null) {
      hasError.value = true;
      errorMessage.value = 'No cache data.';
      return;
    }

    final decodedData = jsonDecode(cachedData) as Map<String, dynamic>;

    mapSizeInvent.value = {
      'New': decodedData['new'],
      'Repair': decodedData['repair'],
      'Spare': decodedData['spare'],
      'Scrap': decodedData['scrap'],
    };

    lastSyncInvent.value = 'Offline Cache';
  }

  /// 🔹 Helper pemrosesan data
  Map<String, dynamic> _processInventoryData(
      String status, List<TireSpec> listInvent) {
    switch (status) {
      case 'Scrap':
        Map<String, Map<String, Map<String, List<TireSpec>>>> groupedData = {};
        Map<String, Map<String, Map<String, Map<String, int>>>> resultScrap =
            {};
        for (var invent in listInvent) {
          groupedData.putIfAbsent(invent.size ?? '', () => {});
          groupedData[invent.size]!.putIfAbsent(invent.brand ?? '', () => {});
          groupedData[invent.size]![invent.brand]!
              .putIfAbsent(invent.pattern ?? '', () => []);
          groupedData[invent.size]![invent.brand]![invent.pattern]!.add(invent);
        }

        groupedData.forEach((size, brands) {
          resultScrap[size] = {};
          brands.forEach((brand, patterns) {
            resultScrap[size]![brand] = {};
            patterns.forEach((pattern, tires) {
              int qty = tires.length;
              int totalLifetime = tires.fold(
                  0, (acc, tire) => acc + int.parse(tire.lifetime ?? '0'));
              int avgLifetime = qty > 0 ? totalLifetime ~/ qty : 0;
              resultScrap[size]![brand]![pattern] = {
                'Quantity': qty,
                'Lifetime Avg': avgLifetime,
              };
            });
          });
        });
        return resultScrap;

      case 'Spare':
      case 'New':
        Map<String, Map<String, dynamic>> result = {};
        for (var tire in listInvent) {
          final size = tire.size ?? "Unknown";
          final brand = tire.brand ?? "Unknown";
          final pattern = tire.pattern ?? "Unknown";
          final sn = tire.sn ?? "Unknown";
          final lifetime = tire.lifetime ?? "Unknown";

          final quantity = (result[size]?.containsKey('quantity') ?? false)
              ? result[size]!['quantity']! + 1
              : 1;

          result.putIfAbsent(size, () => {'quantity': 0, 'listTire': []});
          result[size]!['listTire'].add({
            'brand': brand,
            'pattern': pattern,
            'sn': sn,
            'lifetime': lifetime,
          });
          result[size]!['quantity'] = quantity;
        }
        return result;

      case 'Repair':
        Map<String, dynamic> repairMap = {};
        final uniqueSizes = listInvent.map((t) => t.size).toSet();
        for (var size in uniqueSizes) {
          final listTire = listInvent.where((t) => t.size == size).toList();
          final listSn = listTire
              .map((e) => {
                    'brand': e.brand,
                    'pattern': e.pattern,
                    'sn': e.sn,
                    'lifetime': e.lifetime
                  })
              .toList();
          repairMap[size ?? ''] = listSn;
        }
        return repairMap;

      default:
        return {};
    }
  }

  Future<void> _animateProgressTo(double target) async {
    while (loadingPercent.value < target) {
      loadingPercent.value += 1;
      await Future.delayed(
          const Duration(milliseconds: 20)); // kecepatan animasi
    }
  }
}
