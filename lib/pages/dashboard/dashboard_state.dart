import 'package:camos/pages/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DashboardState extends GetxController {
  var currentIndex = 0.obs;

  final pages = <Widget>[
    const Center(child: HomePage()),
    const Center(child: Text('Tire Inspection')),
  ];

  void changePage(int index) {
    currentIndex.value = index;
  }

  void onScanPressed() {
    // Contoh: buka halaman QR Scanner
    Get.snackbar('Scan', 'Tombol scan ditekan!');
  }
}
