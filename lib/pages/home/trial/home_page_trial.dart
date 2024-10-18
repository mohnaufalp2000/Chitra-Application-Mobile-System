import 'dart:developer';

import 'package:camos/core/blocs/authentication/authentication_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/menu.dart';
import 'package:camos/core/widgets/box_menu_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HomePageTrial extends StatefulWidget {
  static const routeName = '/home-page-trial';
  const HomePageTrial({super.key});

  @override
  State<HomePageTrial> createState() => _HomePageTrialState();
}

class _HomePageTrialState extends State<HomePageTrial> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    getIdSite();
    _initPackageInfo();
  }

  void getIdSite() async {
    // saveIdSitePreferences('3');
    log('id site home pama : ${await getIdSitePreferences()}');
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
          child: StreamBuilder(
              stream: firestore
                  .collection('users')
                  .where('email', isEqualTo: auth.currentUser!.email)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data;

                final idSite = data?.docs[0].data()['id_site'];

                return Container(
                  height: MediaQuery.of(context).size.height,
                  child: Stack(
                    children: [
                      SingleChildScrollView(
                          child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                    width: 92,
                                    height: 92,
                                    child: Image.asset(
                                        '$iconPath/logo_camos_icon.png')),
                                SizedBox(
                                  width:
                                      MediaQuery.of(context).size.width * 0.6,
                                  child: Text(
                                    'Chitra Application Mobile System',
                                    textAlign: TextAlign.end,
                                    style: getBlackTextStyle(
                                      fontSize: 18,
                                      fontWeight: w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 24,
                            ),
                            GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                        mainAxisSpacing: 10,
                                        crossAxisSpacing: 10,
                                        crossAxisCount: 3,
                                        childAspectRatio: 0.9),
                                itemCount: 3,
                                itemBuilder: (context, index) {
                                  // bool isEnabled = index == 0;
                                  return BoxMenuWidget(
                                    menu: menus[index],
                                    isEnabled: true,
                                    argument: {'idSite': idSite},
                                  );
                                }),
                            const SizedBox(
                              height: 12,
                            ),
                            InkWell(
                              onTap: () async {
                                // context
                                //     .read<AuthenticationBloc>()
                                //     .add(AuthenticationEventLogout());
                                // pushRemoveUntil(context, LoginPage.routeName);
                              },
                              child: Text(
                                'App Version : ${_packageInfo.version}',
                                style: getBlackTextStyle(fontWeight: w700),
                              ),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            ButtonWidget(
                              name: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.logout,
                                    color: white,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    'Logout',
                                    style: getWhiteTextStyle(),
                                  ),
                                ],
                              ),
                              function: () {
                                // logout
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        content: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Logout Confirmation',
                                              style: getBlackTextStyle(
                                                fontSize: 16,
                                                fontWeight: w600,
                                              ),
                                            ),
                                            const SizedBox(
                                              height: 12,
                                            ),
                                            Text(
                                              'Are you sure you want to logout?',
                                              style: getBlackTextStyle(),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                back(context);
                                              },
                                              child: Text(
                                                'No',
                                                style: getGreyTextStyle(
                                                    grey8391A1),
                                              )),
                                          TextButton(
                                              onPressed: () async {
                                                context
                                                    .read<AuthenticationBloc>()
                                                    .add(
                                                        AuthenticationEventLogout());
                                                pushRemoveUntil(context,
                                                    LoginPage.routeName);
                                              },
                                              child: Text('Yes')),
                                        ],
                                      );
                                    });
                              },
                              color: Colors.red,
                            )
                          ],
                        ),
                      )),
                      Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: SizedBox(
                              height: 300,
                              child: Image.asset(
                                '$imagePath/bg_tire.png',
                                fit: BoxFit.cover,
                              )))
                    ],
                  ),
                );
              })),
    );
  }
}
