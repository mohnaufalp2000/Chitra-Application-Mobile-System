import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class ExportExcelButton extends StatelessWidget {
  const ExportExcelButton(
      {super.key,
      required this.user,
      required this.pit,
      required this.selectedPit,
      required this.filteredItemTask,
      required this.date});

  final Map<String, dynamic> user;
  final List<String> pit;
  final int selectedPit;
  final List<Map<String, dynamic>> filteredItemTask;
  final String date;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
          onPressed: () async {
            final id = Uuid();
            final file = await createFolderPath(id.v4(), 'daily-check',
                email: user['email'] ?? '',
                site: user['siteName'] ?? '',
                pit: (pit.isNotEmpty) ? pit[selectedPit] : '',
                date: date);

            final bytes =
                await createExcel('daily-check', daily: filteredItemTask);
            final saved = await file.writeAsBytes(bytes, flush: true);
            // print('laper : $saved');
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                backgroundColor: green00968A,
                content: Text(
                  'Successfull Save Data!',
                  style: getWhiteTextStyle(),
                )));
            final result = await OpenFile.open(file.path);

            if (result.type == ResultType.done) {
              print('File berhasil dibuka');
            } else {
              print(result.message);
              if (result.type == ResultType.noAppToOpen) {
                openPlayStore('attendance');
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.table_chart,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  'Export to Excel',
                  style: getWhiteTextStyle(),
                ),
              ],
            ),
          )),
    );
  }
}
