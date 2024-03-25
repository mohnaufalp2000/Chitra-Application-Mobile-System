// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/pages/attendance/attendance_page.dart';
import 'package:camos/pages/attendance/presence_page.dart';
import 'package:camos/pages/cts/cts_page.dart';
import 'package:camos/pages/pressure_gauge_digital/pgd_page.dart';
import 'package:camos/pages/pressure_gauge_digital/select_inspection_page.dart';
import 'package:camos/pages/pressure_gauge_digital/select_unit_page.dart';
import 'package:camos/pages/site_condition/site_condition_page.dart';
import 'package:camos/pages/tkph_calculator/tkph_calculator.dart';
import 'package:camos/pages/tpms/tpms_page.dart';
import 'package:flutter/material.dart';

import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/menu.dart';

class BoxMenuWidget extends StatefulWidget {
  const BoxMenuWidget({
    Key? key,
    required this.menu,
    this.argument,
  }) : super(key: key);

  final Menu menu;
  final Map<String, dynamic>? argument;

  @override
  State<BoxMenuWidget> createState() => _BoxMenuWidgetState();
}

class _BoxMenuWidgetState extends State<BoxMenuWidget> {
  selectMenu(int id) {
    switch (id) {
      case 1:
        // push(context, SelectUnitPage.routeName);
        push(context, SelectInspectionPage.routeName);
        break;
      case 2:
        // if (Platform.isAndroid) {
        Navigator.pushNamed(context, SiteConditionPage.routeName,
            arguments: widget.argument);
        // }
        break;
      case 3:
        // if (Platform.isAndroid) {
        push(context, CtsPage.routeName);
        // }
        break;
      case 4:
        push(context, TKHPCalculator.routeName);
        break;
      case 5:
        push(context, TpmsPage.routeName);
        break;
      case 6:
        push(
          context,
          PresencePage.routeName,
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        selectMenu(widget.menu.id);
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
                    style:
                        getBlackTextStyle(fontSize: fontSize, fontWeight: w500),
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
    );
  }
}
