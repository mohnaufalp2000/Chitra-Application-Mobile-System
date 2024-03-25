import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/select_unit_page.dart';
import 'package:flutter/material.dart';

class SelectInspectionPage extends StatelessWidget {
  static const routeName = '/select-inspection-page';
  const SelectInspectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Select Activity', context),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, SelectUnitPage.routeName,
                        arguments: 'daily_check');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          '${iconPath}/tire_pressure_icon.png',
                          width: MediaQuery.of(context).size.width * 0.1,
                          height: MediaQuery.of(context).size.height * 0.1,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Center(
                          child: LayoutBuilder(builder: (context, constraints) {
                            double fontSize = constraints.maxWidth * 0.12;
                            return Text(
                              'Daily Check Pressure',
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
            const SizedBox(
              height: 12,
            ),
            Expanded(
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
                child: InkWell(
                  onTap: () {
                    Navigator.pushNamed(context, SelectUnitPage.routeName,
                        arguments: 'tire_inspection');
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          '${iconPath}/heavy_tire_icon.png',
                          width: MediaQuery.of(context).size.width * 0.1,
                          height: MediaQuery.of(context).size.height * 0.1,
                        ),
                        const SizedBox(
                          height: 4,
                        ),
                        Center(
                          child: LayoutBuilder(builder: (context, constraints) {
                            double fontSize = constraints.maxWidth * 0.12;
                            return Text(
                              'Tire Inspection',
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
          ],
        ),
      )),
    );
  }
}
