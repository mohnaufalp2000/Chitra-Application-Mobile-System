import 'dart:developer';
import 'package:get/get.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/auto_tapping_model.dart';

class TpmsState extends GetxController {
  final isLoadingAutoTapping = false.obs;

  final autoTappingList = <AutoTappingModel>[].obs;

  bool isLoaded = false;

  Future<void> loadAutoTappingOnce() async {
    if (isLoaded) return;

    try {
      isLoadingAutoTapping.value = true;

      final result = await ApiService.getAutoTappingSPM();

      autoTappingList.assignAll(result);
      isLoaded = true;
    } catch (e) {
      log('load autotapping error: $e');
    } finally {
      isLoadingAutoTapping.value = false;
    }
  }

  AutoTappingModel? findAutoTapping({
    required String idSite,
    required String deviceName,
    required String position,
  }) {
    try {
      return autoTappingList.firstWhere(
        (item) =>
            item.idSite == idSite &&
            item.devicename == deviceName &&
            item.posisi.toString() == position,
      );
    } catch (_) {
      return null;
    }
  }
}
