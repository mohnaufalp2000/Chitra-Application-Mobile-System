import 'dart:developer';

import 'package:camos/core/services/sheets/model_sheets/attendance.dart';
import 'package:gsheets/gsheets.dart';
import 'package:intl/intl.dart';

class AttendanceSheetsAPI {
  static const credentials = r'''
{
  "type": "service_account",
  "project_id": "camosgsheets",
  "private_key_id": "06893c2304c2c4468540af4b796aafb83433fbbd",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC4/W+ZGZ0ulDoa\nO/Hmn3xqEM0wE10oYl7ZS+h4Ihqyd8zaYNsuoLbZSTOnUhAS7xyBhhhDPCtnpYJe\nFRoCGNIdvP1XXHcvl2fkecUb/+9vN7uWunoRC5uMQQPaaXscx/6WRl8k4jsL1eOA\nSWRBX9YhXtVTt0xJ/0lBodaxkIT46q/io7vnqi9OW058wrPa2tQuvkkhAqtkJCIo\nXw95zsVR2C6CBgH2Jp23TjuDudz1uPUVrBqCwfU4BC2HxS80EglxoUM80+xklfbJ\n3kTrmCUuMqdgfvTvyXKAvAqjJly68UMt9oNYlFGHOFzGLuR5M7cRiZZ75kFk4Bzf\njU3jHBv1AgMBAAECggEACEIqMAHMelacNG0eKr9OeNa4rk+C/mlL1jQVE/3jxrlh\n8BLYXh/HIfKqZ2satBmwIlkn7qJ6RpWFOSmEgHj2smSsQ7DpUjrWZMUJ52rY19R7\nX6qCBg5IWq3RW/gPCrUj+LX6C+W8oJXjIuhD3UZHwzQeXm8lrP0EWnV85e7vfMQ7\n4J0NXji73fISJAuvKr8aWu1+Dqcc29pj8ynfDZ9sEHX3vB6LpJY3jBlJ71wi/1Zi\nvDjr0eEqQfle9PTh2Ct3ayclb5ivJ+0KLS08UrsR3m0pUFBwbHHwfN6W9IG296aM\niw4F/zb2UnLhs6wjX68CRW7WtXOS9WjNuhXvksKUkQKBgQDwXykv04QVap119PEB\neFv/tlvVzPppSbkz9Bq51+rGQ0UDRbWPtzHUm3Vzp6LvZp1HQVh9pbnYNwCg4utP\nEYAhivFQ1Z2mxuyJFAcRwCAh0myZQd56XOIUKRp5K5RNZpXgIwiHukOGnZW7py8J\naXo3aDDKHxqWvmd/GDh1N1P88QKBgQDFBHrrsOqHSpSEUxKUnooyKDSDzyDdxEwE\nUJam6164FWs6+lDF+Igk2HypynPG3Whz9hZnT0NLWCbLrh5AYRq/GCPw2cgF6DGc\nlz7dP7C/WavI0pcNRqN5qKBhZly1rUEkYmaeFUYi7CeoiCpPfo1hnFf5/Vpt0W6b\njp4trlPfRQKBgQCYW3j7u5IJER7lWXA5glSt7KShC9/dRMGDUMJv8Y/6Q0FHJbRD\nd9a58B+uQx9fpychtyWj3pvBlHttfuevomQY3ry+g+f9gjEDYhJpCeJUDdCQA9RE\nswMJzFPfYeQKe2+cNhh+D24lsVTrMLj7ukOhQwVJ2BU+X0myoWOHyJ4PwQKBgCZe\nP/4EfzgHyzKV5wlwcqNf9xIwVUs6/j7c3un07oZVDYP32aEkTIc4bda3KaLx3XSv\n2R8XbZiPu0ZxS0zoXEgY0G8ISo7z8C15uvFlhOtO8Eh00pvwRMfdkhZF1ApBim0m\niKuCox0L9pE4q1y93ZTD2NJDh8fZQHwk4yMsTwMtAoGAGkpCQzXACITXk7qZ8fo1\nHPDYaZhrm0zOGae4obDo2QWOAiUjJ+kA5PDsOWJTOXWqYoc2J2TJV/1K0aNw1Es+\nib52+cOGaIpuWR1mOY4UV5wpkYH1Ho0MIBnt9e9T1yZu+OeZ0UtQSmu7WijVcLh4\ncV9KmeNE03DxeLz+9fcNHFA=\n-----END PRIVATE KEY-----\n",
  "client_email": "camosattendance@camosgsheets.iam.gserviceaccount.com",
  "client_id": "116631951713639549062",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/camosattendance%40camosgsheets.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}
''';
  static final spreadSheetId = '17ych7yYZP9ocWJYV1ZHHkKjtnJyTnMh_DCPSy0ScSPo';
  static final gsheets = GSheets(credentials);
  static Worksheet? userSheet;

  static Future initAttendanceSheets() async {
    try {
      final spreadsheet = await gsheets.spreadsheet(spreadSheetId);
      userSheet = await getWorkSheet(spreadsheet, title: 'Attendance');

      final firstRow = AttendanceFields.getFields();
      userSheet!.values.insertRow(1, firstRow);
    } catch (e) {
      print('Init Attendance Sheet Error : $e');
    }
  }

  static Future<Worksheet> getWorkSheet(Spreadsheet spreadsheet,
      {required String title}) async {
    try {
      return await spreadsheet.addWorksheet(title);
    } catch (e) {
      return await spreadsheet.worksheetByTitle(title)!;
    }
  }

  static Future insertAttendanceSheet(
      List<Map<String, dynamic>> rowList) async {
    if (userSheet == null) return;
    print('bisakah');
    userSheet!.values.map.appendRows(rowList);
  }

  static Future<bool> updateAttendanceSheet(
      int id, Map<String, dynamic> user) async {
    if (userSheet == null) return false;

    return userSheet!.values.map.insertRowByKey(id, user);
  }

  static Future<int> getRowCount() async {
    log('attendance_user_sheet : ${userSheet}');
    if (userSheet == null) return 0;

    final lastRow = await userSheet!.values.lastRow();
    log('attendance_user_last_row : ${lastRow}');
    return lastRow == null ? 0 : int.tryParse(lastRow.first) ?? 0;
  }

  static Future<bool> updateAttendanceCell({
    required int id,
    required String key,
    required dynamic value,
  }) async {
    if (userSheet == null) return false;

    return userSheet!.values
        .insertValueByKeys(value, columnKey: key, rowKey: id);
  }

  static Future<String?> getSingleDataAttendance(
      String sn, String tanggal) async {
    try {
      if (userSheet == null) return null;

      // Get all rows
      final rows =
          await userSheet!.values.allRows(fromRow: 2); // skip header row

      print('data absensi api : $rows');

      // Find the row with the matching Nama_Karyawan and Tanggal
      for (var row in rows) {
        var epoch = DateTime(1899, 12, 30);
        var currentDate = epoch.add(Duration(days: int.tryParse(row[3])!));
        var formattedDate = '${DateFormat('MM-dd-yyyy').format(currentDate)}';
        log('tanggal numerik : $formattedDate');

        if (row[2] == sn && (tanggal == formattedDate)) {
          return row[0]; // Return the id (first column)
        }
      }
    } catch (e) {
      print('Get Employee Id Error : $e');
    }
    return null;
  }
}
