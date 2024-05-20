import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/detail_non_running_tire_inspection_page.dart';
import 'package:flutter/material.dart';

class NonRunningInspectionPage extends StatelessWidget {
  static const routeName = '/non-running-inspection-page';
  const NonRunningInspectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('List Unit', context),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [],
        ),
      )),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ButtonWidget(
            name: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  color: white,
                ),
                const SizedBox(
                  width: 6,
                ),
                Text(
                  'Add Unit',
                  style: getWhiteTextStyle(),
                ),
              ],
            ),
            function: () {
              Navigator.pushNamed(
                  context, DetailNonTireRunningTireInspection.routeName);
            }),
      ),
    );
  }
}
