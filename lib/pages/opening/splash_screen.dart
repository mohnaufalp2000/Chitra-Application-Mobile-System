import 'dart:async';

import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/utils/notification/notification_api.dart';
import 'package:camos/pages/authentication/email_verification_page.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:camos/pages/home/trial/home_page_trial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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

  splashScreen() async {
    final user = await firestore
        .collection('users')
        .where('email', isEqualTo: auth.currentUser?.email)
        .get();

    return Timer(
        const Duration(seconds: 2),
        () => pushReplace(
            context,
            // check login is exist or not
            // (auth.currentUser != null)
            //     ? (auth.currentUser!.emailVerified)
            //         ? HomePage.routeName
            //         : LoginPage.routeName
            //     : LoginPage.routeName,
            (auth.currentUser != null)
                ? (auth.currentUser!.emailVerified)
                    ? (user.docs[0]['id_site'] == '3' ||
                            user.docs[0]['id_site'] == '4' ||
                            user.docs[0]['id_site'] == '999')
                        ? HomePageTrial.routeName
                        : HomePage.routeName
                    : LoginPage.routeName
                : LoginPage.routeName));
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
