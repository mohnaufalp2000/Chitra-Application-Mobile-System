import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:camos/pages/dashboard/dashboard_page.dart';

import '../../core/navigator/navigation_route.dart';
import '../../core/services/api_service.dart';
import '../../core/services/model/site.dart';
import '../../core/styles/asset_path.dart';
import '../authentication/login_page.dart';
import '../home/home_page.dart';
import '../home/trial/home_page_trial.dart';
import '../tpms/tpms_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  static const routeName = '/splash_screen';
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Duration _requestTimeout = Duration(seconds: 15);

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    splashScreen();
  }

  Future<List<Map<String, dynamic>>> getListFromSharedPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('listCustPgDigitalData');

    if (encodedData == null || encodedData.trim().isEmpty) return [];

    try {
      final decodedList = jsonDecode(encodedData);
      if (decodedList is! List) return [];
      return decodedList
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (e) {
      log('Error membaca cache customer PG: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> _getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedUser = prefs.getString('user');

    if (encodedUser != null && encodedUser.trim().isNotEmpty) {
      try {
        final decodedUser = jsonDecode(encodedUser);
        if (decodedUser is Map) {
          return Map<String, dynamic>.from(decodedUser);
        }
      } catch (e) {
        log('Error membaca cache user di splash: $e');
      }
    }

    final cachedIdSite = prefs.getString('idSite');
    if (cachedIdSite != null && cachedIdSite.isNotEmpty) {
      return {'id_site': cachedIdSite};
    }

    return null;
  }

  Future<Map<String, dynamic>?> _loadUserData(String email) async {
    try {
      final snapshot = await firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .get()
          .timeout(_requestTimeout);

      if (snapshot.docs.isEmpty) return null;
      return snapshot.docs.first.data();
    } on TimeoutException catch (e) {
      log('Query user timeout, menggunakan cache: $e');
      return _getCachedUser();
    } catch (e, stackTrace) {
      log(
        'Query user gagal, menggunakan cache: $e',
        stackTrace: stackTrace,
      );
      return _getCachedUser();
    }
  }

  Future<void> _navigateTo(
    String routeName, {
    Map<String, dynamic>? arguments,
  }) async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (arguments == null) {
      pushReplace(context, routeName);
    } else {
      Navigator.pushReplacementNamed(
        context,
        routeName,
        arguments: arguments,
      );
    }
  }

  Future<void> splashScreen() async {
    try {
      final currentUser = auth.currentUser;
      if (currentUser == null || !currentUser.emailVerified) {
        await _navigateTo(LoginPage.routeName);
        return;
      }

      final email = currentUser.email;
      if (email == null || email.isEmpty) {
        await _navigateTo(LoginPage.routeName);
        return;
      }

      final userData = await _loadUserData(email);
      if (userData == null || userData.isEmpty) {
        await _navigateTo(LoginPage.routeName);
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userIdSite =
          (userData['id_site'] ?? prefs.getString('idSite') ?? '').toString();
      if (userIdSite.isEmpty) {
        await _navigateTo(LoginPage.routeName);
        return;
      }

      // Firebase Auth dapat bertahan saat instalasi diperbarui, sedangkan
      // SharedPreferences dapat kosong. Sinkronkan ulang agar ApiService
      // selalu memiliki id_company dan id_site yang dibutuhkan.
      await prefs.setString('user', jsonEncode(userData));
      await prefs.setString('idSite', userIdSite);

      List<Site> allSites = await ApiService.getCachedAllSites();
      if (allSites.isEmpty) {
        try {
          allSites = await ApiService.getAllSite().timeout(_requestTimeout);
        } catch (e, stackTrace) {
          log(
            'Get all site gagal, menggunakan konfigurasi default: $e',
            stackTrace: stackTrace,
          );
        }
      }

      final listCustPgDigitalData = await getListFromSharedPrefs();
      final selectedSite = allSites.firstWhere(
        (site) => site.idSite == userIdSite,
        orElse: () => Site(
          idSite: userIdSite,
          cts: '0',
          spm: '0',
        ),
      );
      final isCTS = selectedSite.cts;
      final isSPM = selectedSite.spm;
      final isSitePGInList =
          listCustPgDigitalData.any((e) => e['id_site'] == userIdSite);

      log('isCTS : $isCTS');
      String targetRoute;
      Map<String, dynamic>? arguments;

      if (isCTS == '0' || isCTS == null) {
        if (userIdSite == '1' || userIdSite == '15') {
          targetRoute = DashboardPage.routeName;
        } else {
          targetRoute = HomePageTrial.routeName;
          arguments = {
            'idSite': userIdSite,
            'isSPM': isSPM == '1',
            'isCTS': isCTS == '1',
            'isPG': isSitePGInList,
          };
        }
      } else {
        targetRoute = DashboardPage.routeName;
      }

      await _navigateTo(targetRoute, arguments: arguments);
    } catch (e, stackTrace) {
      log('Startup splash gagal: $e', stackTrace: stackTrace);
      await _navigateTo(LoginPage.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Image.asset(
          '${imagePath}/splash_screen_image.png',
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
        ),
      ),
    );
  }
}
