// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/site.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/pages/attendance/absence_page.dart';
import 'package:camos/pages/attendance/attendance_page.dart';
import 'package:camos/pages/attendance/presence_page.dart';
import 'package:camos/pages/cts/cts_page.dart';
import 'package:camos/pages/pressure_gauge_digital/tire_inspection_form_page.dart';
import 'package:camos/pages/pressure_gauge_digital/select_inspection_page.dart';
import 'package:camos/pages/pressure_gauge_digital/select_unit_page.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/daily_pressure_trial_page.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/dashboard_daily_page.dart';
import 'package:camos/pages/site_condition/site_condition_page.dart';
import 'package:camos/pages/tire_repair_form/select_tire_repair_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection/tire_repair_inspection_page.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection_old/tire_repair_inspection_old_page.dart';
import 'package:camos/pages/tkph_calculator/tkph_calculator.dart';
import 'package:camos/pages/tpms/qr_tpms_page.dart';
import 'package:camos/pages/tpms/tpms_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/menu.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BoxMenuWidget extends StatefulWidget {
  const BoxMenuWidget({
    Key? key,
    required this.menu,
    this.isEnabled = true,
    this.argument,
  }) : super(key: key);

  final Menu menu;
  final bool isEnabled;
  final Map<String, dynamic>? argument;

  @override
  State<BoxMenuWidget> createState() => _BoxMenuWidgetState();
}

class _BoxMenuWidgetState extends State<BoxMenuWidget> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> getListFromSharedPrefs() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? encodedData = prefs.getString('listCustPgDigitalData');

    if (encodedData != null) {
      List<dynamic> decodedList = jsonDecode(encodedData);
      return decodedList.map((e) => e as Map<String, dynamic>).toList();
    }
    return []; // Return list kosong jika tidak ada data
  }

  selectMenu(int id) async {
    switch (id) {
      case 1:
        // push(context, SelectUnitPage.routeName);

        // List<Map<String, dynamic>> listCustPgDigitalData =
        //     await getListFromSharedPrefs();

        // if ((listCustPgDigitalData)
        //     .any((e) => e['id_site'] == widget.argument?['idSite'])) {
        //   Navigator.pushNamed(context, DashboardDailyPage.routeName,
        //       arguments: widget.argument?['idSite']);
        // } else {
        //   push(context, SelectInspectionPage.routeName);
        // }

        if (widget.argument?['isCTS'] == null) {
          Navigator.pushNamed(context, SelectInspectionPage.routeName,
              arguments: widget.argument?['idSite']);
        } else {
          Navigator.pushNamed(context, DashboardDailyPage.routeName,
              arguments: widget.argument?['idSite']);
        }

        break;
      case 2:
        // if (Platform.isAndroid) {
        Navigator.pushNamed(context, SiteConditionPage.routeName,
            arguments: widget.argument);
        // }
        break;
      case 3:
        push(context, TKHPCalculator.routeName);

        // if (Platform.isAndroid) {
        // }
        break;
      case 4:
        Navigator.pushNamed(context, TpmsPage.routeName,
            arguments: widget.argument);
        // push(context, CtsPage.routeName);

        break;
      case 5:
        // push(context, SelectTpmsPage.routeName);
        // push(context, QrTpmsPage.routeName);
        // Navigator.pushNamed(context, SelectTireRepairPage.routeName);
        Navigator.pushNamed(context, TireRepairInspectionOldPage.routeName);

        break;
      case 6:
        push(
          context,
          // AbsencePage.routeName,
          PresencePage.routeName,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Opacity(
          opacity: widget.isEnabled ? 1.0 : 0.5,
          child: InkWell(
            onTap: widget.isEnabled
                ? () {
                    selectMenu(widget.menu.id);
                  }
                : () {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(
                        'Please Contact Chitra Paratama Developer Team to Unlock',
                        style: getWhiteTextStyle(),
                      ),
                      backgroundColor: green00968A,
                    ));
                  },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Container(
                width: 150,
                padding: EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      '${iconPath}/${widget.menu.image}',
                      width: MediaQuery.of(context).size.width * 0.07,
                      height: MediaQuery.of(context).size.height * 0.07,
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                    Center(
                      child: LayoutBuilder(builder: (context, constraints) {
                        double fontSize = constraints.maxWidth * 0.12;
                        return Text(
                          widget.menu.name,
                          textAlign: TextAlign.center,
                          style: getBlackTextStyle(
                              fontSize: fontSize, fontWeight: w500),
                        );
                      }),
                    ),
                    const SizedBox(
                      height: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (!widget.isEnabled)
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                  'Please Contact Chitra Paratama Developer Team to Unlock',
                  style: getWhiteTextStyle(),
                ),
                backgroundColor: green00968A,
              ));
            },
            child: Positioned.fill(
              child: Container(
                alignment: Alignment.center,
                color: Colors.black.withOpacity(0.5),
                child: Text(
                  'Locked',
                  style: getWhiteTextStyle(
                    fontWeight: w700,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
