import 'dart:io';

import 'package:appcheck/appcheck.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:camos/pages/home/new_tire_inspection_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DashboardState extends GetxController {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  final HomeState homeController = Get.put(HomeState());

  var currentIndex = 0.obs;
  Widget? _homePage;
  Widget? _inspectionPage;

  Widget get currentPage {
    switch (currentIndex.value) {
      case 1:
        return _inspectionPage ??= Center(child: NewTireInspectionPage());
      default:
        return _homePage ??= const Center(child: HomePage());
    }
  }

  void changePage(int index) {
    currentIndex.value = index;
  }

  void onScanPressed() async {
    // Cek apakah platform adalah iOS
    if (Platform.isIOS) {
      Get.snackbar(
        'Coming Soon',
        'Fitur ini belum tersedia untuk iOS.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF2196F3),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        borderRadius: 8,
      );
      return; // Hentikan eksekusi agar tidak lanjut ke Firestore atau Drive
    }

    // Tampilkan snackbar ketika tombol ditekan
    Get.snackbar('Scan', 'Tombol scan ditekan!');

    // Jika bukan iOS (Android), lanjutkan akses Firestore
    final doc =
        await firestore.collection("url_tire_damage_ai").doc("url").get();

    if (doc.exists) {
      final data = doc.data();
      final String downloadUrl = data?["url"] ?? "";
      final String targetPackageName = data?["targetName"] ?? "";

      print('url tire ai : $data');

      await openOrInstallApp(
        targetPackageName: targetPackageName,
        downloadUrl: downloadUrl,
      );
    } else {
      Get.snackbar('Error', 'Data tidak ditemukan di Firestore.');
    }
  }

  Future<void> openOrInstallApp({
    required String targetPackageName,
    required String downloadUrl,
  }) async {
    final appCheck = AppCheck();

    try {
      final app = await appCheck.checkAvailability(targetPackageName);

      if (app != null) {
        debugPrint("✅ App ditemukan → buka $targetPackageName");
        await appCheck.launchApp(targetPackageName);
      } else {
        debugPrint("❌ App tidak ditemukan → buka link download");
        await _openDownloadLink(downloadUrl, targetPackageName);
      }
    } catch (e) {
      debugPrint("⚠️ Error saat cek app: $e");
      await _openDownloadLink(downloadUrl, targetPackageName);
    }
  }

  Future<void> _openDownloadLink(
      String downloadUrl, String targetPackageName) async {
    final Uri url = Uri.parse(
      downloadUrl.isNotEmpty
          ? downloadUrl
          : "https://play.google.com/store/apps/details?id=$targetPackageName",
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  // Future<void> openOrInstallApp({
  //   required String targetPackageName,
  //   required String downloadUrl,
  // }) async {
  //   final appCheck = AppCheck();

  //   try {
  //     // cek apakah aplikasi tersedia
  //     final app = await appCheck.checkAvailability(targetPackageName);

  //     if (app != null) {
  //       debugPrint("✅ App ditemukan → buka $targetPackageName");
  //       await appCheck.launchApp(targetPackageName);
  //     } else {
  //       debugPrint("❌ App tidak ditemukan → buka link download");
  //       final Uri url = Uri.parse(downloadUrl);

  //       if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
  //         throw Exception('Could not launch $url');
  //       }
  //     }
  //   } catch (e) {
  //     debugPrint("⚠️ Error saat cek app: $e");
  //     // fallback ke link install
  //     final Uri url = Uri.parse(downloadUrl);
  //     await launchUrl(url, mode: LaunchMode.externalApplication);
  //   }
  // }
}
