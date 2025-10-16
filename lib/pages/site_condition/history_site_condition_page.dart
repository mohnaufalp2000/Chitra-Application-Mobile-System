import '../../core/styles/color.dart';
import '../../core/widgets/appbar_widget.dart';
import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';

class HistorySiteConditionPage extends StatefulWidget {
  static const routeName = '/history-site-condition-page';
  const HistorySiteConditionPage({super.key});

  @override
  State<HistorySiteConditionPage> createState() =>
      _HistorySiteConditionPageState();
}

class _HistorySiteConditionPageState extends State<HistorySiteConditionPage> {
  DateTime selectedDate = DateTime.now().subtract(Duration(days: 1));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('History Site Condition', context),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 24,
                horizontal: 12,
              ),
              child: DatePicker(
                DateTime.now().subtract(Duration(days: 10)),
                height: 100,
                width: 80,
                daysCount: 10,
                locale: 'id_ID',
                initialSelectedDate: DateTime.now().subtract(Duration(days: 1)),
                selectionColor: green00968A,
                selectedTextColor: white,
                onDateChange: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
                dateTextStyle: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: grey6A707C,
                ),
              ),
            ),
          ],
        ),
      )),
    );
  }
}
