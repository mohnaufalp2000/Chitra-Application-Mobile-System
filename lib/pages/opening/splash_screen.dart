import 'dart:async';

import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/utils/notification/notification_api.dart';
import 'package:camos/pages/authentication/email_verification_page.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:camos/pages/home/home_page.dart';
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

  @override
  void initState() {
    super.initState();
    splashScreen();
  }

  splashScreen() async {
    return Timer(
        const Duration(seconds: 2),
        () => pushReplace(
              context,
              // check login is exist or not
              (auth.currentUser != null)
                  ? (auth.currentUser!.emailVerified)
                      ? HomePage.routeName
                      : LoginPage.routeName
                  : LoginPage.routeName,
            ));
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
