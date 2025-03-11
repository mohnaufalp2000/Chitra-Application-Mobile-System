import 'dart:async';
import 'dart:convert';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:camos/pages/home/trial/home_page_trial.dart';
import 'package:camos/pages/tpms/tpms_page.dart';
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

    if (encodedData != null) {
      List<dynamic> decodedList = jsonDecode(encodedData);
      return decodedList.map((e) => e as Map<String, dynamic>).toList();
    }
    return []; // Return list kosong jika tidak ada data
  }

  splashScreen() async {
    final user = await firestore
        .collection('users')
        .where('email', isEqualTo: auth.currentUser?.email)
        .get();

    if (auth.currentUser != null) {
      if (auth.currentUser!.emailVerified) {
        List<Site> allSites = await ApiService.getCachedAllSites();

        print('data all sites : ${allSites}');

        if (allSites.isEmpty || allSites == null) {
          allSites = await ApiService.getAllSite();
        }

        List<Map<String, dynamic>> listCustPgDigitalData =
            await getListFromSharedPrefs();

        // Ambil id_site dari user Firestore
        String userIdSite = user.docs[0]['id_site'];

        // cek apakah menggunakan cts atau tidak
        final isCTS = allSites
            .firstWhere((site) => site.idSite == userIdSite,
                orElse: () => Site(idSite: userIdSite, cts: '1'))
            .cts;

        // Cek apakah id_site ada di listCustPgDigitalData
        bool isSiteInList =
            listCustPgDigitalData.any((e) => e['id_site'] == userIdSite);

        // Navigasi setelah delay 2 detik
        if (isCTS == '0') {
          // jika tidak langsung diarahkan ke halaman SPM
          return Timer(
              const Duration(seconds: 2),
              () => Navigator.pushReplacementNamed(context, TpmsPage.routeName,
                  arguments: {'idSite': userIdSite, 'isCTS': false}));
        } else {
          // apakah customer menggunakan CTS?
          return Timer(
            const Duration(seconds: 2),
            () => pushReplace(
              context,
              isSiteInList ? HomePageTrial.routeName : HomePage.routeName,
            ),
          );
        }
      } else {
        return Timer(const Duration(seconds: 2),
            () => pushReplace(context, LoginPage.routeName));
      }
    } else {
      return Timer(const Duration(seconds: 2),
          () => pushReplace(context, LoginPage.routeName));
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
