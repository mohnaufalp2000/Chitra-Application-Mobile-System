import 'package:camos/pages/network/network_state.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_list.dart';
import 'package:camos/pages/pressure_gauge_digital/pre_assembly_tire_page.dart';
import 'package:camos/pages/pressure_gauge_digital/select_unit_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../home/home_state.dart';

class SelectInspectionState extends GetxController {
  final home = Get.find<HomeState>();
  final networkController = Get.find<InternetState>();

  /// Menyimpan status apakah user sedang membuka Daily Check atau Tire Inspection
  final selectedActivity = ''.obs;

  var isConnected = false.obs;
  var deviceName = 'Device A'.obs;

  void scanBluetooth(BuildContext context) {
    // Dummy simulasi connect
    isConnected.value = true;
    deviceName.value = 'Device A';
    Get.snackbar('Bluetooth', 'Connected to ${deviceName.value}');
  }

  void disconnectBluetooth() {
    // Dummy simulasi disconnect
    isConnected.value = false;
    Get.snackbar('Bluetooth', 'Disconnected');
  }

  /// Navigasi ke Daily Check Pressure
  Future<void> openDailyCheck(BuildContext context) async {
    selectedActivity.value = 'daily_check';

    // Pastikan koneksi dicek dulu
    await _handleNavigation(
      context,
      onOffline: () {
        _showOfflineDialog(context);
      },
      onOnline: () {
        Navigator.pushNamed(context, DailyPressureListPage.routeName);
      },
    );
  }

  Future<void> openPreAssemblyTire(BuildContext context) async {
    selectedActivity.value = 'pre_assembly_tire';

    // Pastikan koneksi dicek dulu
    await _handleNavigation(
      context,
      onOffline: () {
        _showOfflineDialog(context);
      },
      onOnline: () {
        Navigator.pushNamed(context, PreAssemblyTirePage.routeName);
      },
    );
  }

  /// Navigasi ke Tire Inspection
  Future<void> openTireInspection(BuildContext context) async {
    selectedActivity.value = 'tire_inspection';

    await _handleNavigation(
      context,
      onOffline: () {
        _showOfflineDialog(context);
      },
      onOnline: () {
        // Sama seperti di atas, bisa disesuaikan tergantung role
        Navigator.pushNamed(
          context,
          SelectUnitPage.routeName,
          arguments: 'tire_inspection',
        );
      },
    );
  }

  /// Fungsi bantu untuk handle koneksi & navigasi aman
  Future<void> _handleNavigation(
    BuildContext context, {
    required VoidCallback onOnline,
    required VoidCallback onOffline,
  }) async {
    if (networkController.isConnected.isFalse ||
        await networkController.isNetworkReliable() == false) {
      onOffline();
    } else {
      onOnline();
    }
  }

  /// Dialog kalau tidak ada koneksi
  void _showOfflineDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Offline Mode'),
        content: const Text(
          'Tidak ada koneksi internet.\nBeberapa fitur mungkin tidak dapat digunakan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
