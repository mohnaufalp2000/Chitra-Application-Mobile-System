import '../../core/styles/asset_path.dart';
import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import '../pressure_gauge_digital/daily_pressure_list.dart';
import '../pressure_gauge_digital/select_unit_page.dart';
import 'jobcard_repair/list_jobcard_repair_page.dart';
import 'tire_repair_inspection/tire_repair_inspection_page.dart';
import 'package:flutter/material.dart';

class SelectTireRepairPage extends StatelessWidget {
  static const routeName = '/select-tire-repair-page';
  const SelectTireRepairPage({super.key});

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
                    Navigator.pushNamed(
                      context,
                      TireRepairInspectionPage.routeName,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          '${iconPath}/tire_repair_inspection.png',
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
                              'Tire Repair Inspection',
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
                    Navigator.pushNamed(
                      context,
                      ListJobcardRepair.routeName,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          '${iconPath}/jobcard_repair.png',
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
                              'Jobcard Repair',
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
