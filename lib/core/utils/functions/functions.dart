import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camos/core/services/local_database/attendance/attendance_entity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import 'package:camos/core/blocs/network/network_bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
// import 'package:here_sdk/core.dart';
// import 'package:here_sdk/core.engine.dart';
// import 'package:here_sdk/core.errors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:store_redirect/store_redirect.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

/// konversi angka ke format mata uang
String currencyFormat(String amount, String prefix) {
  var _numF = NumberFormat.currency(decimalDigits: 0, symbol: ' ');
  var formatted = _numF.format(int.parse(amount)).replaceAll(",", ".");
  return prefix + formatted;
}

/// mencari nilai k1 (TKPH Calculator)
double k1Coefficients(double distance) {
  final finalDistance = distance.round();

  switch (finalDistance) {
    case 0:
    case 1:
    case 2:
    case 3:
    case 4:
    case 5:
      return 1.00;
    case 6:
      return 1.04;
    case 7:
      return 1.06;
    case 8:
      return 1.09;
    case 9:
      return 1.10;
    case 10:
      return 1.12;
    case 11:
      return 1.13;
    case 12:
      return 1.14;
    case 13:
      return 1.15;
    case 14:
      return 1.16;
    case 15:
      return 1.16;
    case 16:
      return 1.17;
    case 17:
      return 1.17;
    case 18:
      return 1.18;
    case 19:
      return 1.18;
    case 20:
      return 1.19;
    case 21:
      return 1.19;
    case 22:
      return 1.19;
    case 23:
      return 1.20;
    case 24:
      return 1.20;
    case 25:
      return 1.20;
    case 26:
      return 1.20;
    case 27:
      return 1.21;
    case 28:
      return 1.21;
    case 29:
      return 1.21;
    case 30:
      return 1.21;
    case 31:
      return 1.21;
    case 32:
      return 1.21;
    case 33:
      return 1.22;
    case 34:
      return 1.22;
    case 35:
      return 1.22;
    case 36:
      return 1.22;
    case 37:
      return 1.22;
    case 38:
      return 1.22;
    case 39:
      return 1.22;
    case 40:
      return 1.22;
    case 41:
      return 1.23;
    case 42:
      return 1.23;
    case 43:
      return 1.23;
    case 44:
      return 1.23;
    case 45:
      return 1.23;
    case 46:
      return 1.23;
    case 47:
      return 1.23;
    case 48:
      return 1.23;
    case 49:
      return 1.23;
    case 50:
      return 1.23;
    default:
      return 1.23;
  }
}

/// mengconvert nilai waktu (HH:mm) menjadi (HH)
double convertTime(String time) {
  final splitTime = time.split(',');
  final hours = int.parse(splitTime[0]);
  final minutes = int.parse(splitTime[1]);

  final hoursToMinutes = hours * 60;

  final calculatedTime = hoursToMinutes + minutes;

  final finalTime = calculatedTime / 60;

  print('waktu $finalTime');
  return finalTime;
}

/// izin penyimpanan pada aplikasi
void requestStoragePermission() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    log('storage permission : $status');

    await Permission.storage.request();
  }

  // var statusManage = await Permission.manageExternalStorage.status;
  // if (!statusManage.isGranted) {
  //   await Permission.manageExternalStorage.request();
  // }
}

/// izin bluetooth pada aplikasi
void requestBluetoothPermission() async {
  var bluetoothStatus = await Permission.bluetooth.status;
  if (!bluetoothStatus.isGranted) {
    await Permission.bluetooth.request();
  }
  log('izin bluetooth 1 : $bluetoothStatus');

  var bluetoothConnectStatus = await Permission.bluetoothConnect.status;
  if (!bluetoothConnectStatus.isGranted) {
    await Permission.bluetoothConnect.request();
  }
  log('izin bluetooth 2 : $bluetoothConnectStatus');

  var bluetoothScanStatus = await Permission.bluetoothScan.status;
  if (!bluetoothScanStatus.isGranted) {
    await Permission.bluetoothScan.request();
  }
  log('izin bluetooth 3 : $bluetoothScanStatus');
}

/// izin lokasi pada aplikasi
void requestPlacePermission() async {
  var status = await Permission.location.status;
  log('location permission : $status');
  if (!status.isGranted) {
    await Permission.location.request();
  }
}

void requestGeolocatorPermission() async {
  var status = await Geolocator.checkPermission();
  log('location permission : $status');
  if (status == LocationPermission.denied) {
    await Geolocator.requestPermission();
    log('location permission terbaru: $status');
  }
}

void requestCameraPermission() async {
  var status = await Permission.camera.status;
  log('camera permission : $status');
  if (!status.isGranted) {
    await Permission.camera.request();
  }
}

/// mengizinkan semua permission yang dibutuhkan
void requestAllPermission() async {
  // requestBluetoothPermission();
  // requestStoragePermission();
  // requestGeolocatorPermission();
  // requestPlacePermission();
  // requestCameraPermission();
}

/// screenshot satu halaman penuh
Future<Uint8List?> capturePage(
    ScreenshotController screenshotController) async {
  var image = await screenshotController.capture();
  return image;
}

/// membuat path penyimpanan file
Future<File> createFolderPath(String id, String type,
    {String site = '',
    String email = '',
    String date = '',
    String username = '',
    String pit = '',
    String sn = ''}) async {
  /// final output = await getApplicationDocumentsDirectory();
  // String path = '';
  Directory? path;
  if (Platform.isAndroid) {
    // path = await getExternalStorageDirectory();
    path = await DownloadsPath.downloadsDirectory();
    log('lokasi android : ${path?.path}');
  }

  if (Platform.isIOS) {
    // final directory = await getApplicationDocumentsDirectory();
    // path = directory;
    path = await getApplicationDocumentsDirectory();
  }

  switch (type) {
    case 'tkph':
      final outputFile = File("${path?.path}/TKPH-$id.pdf");
      return outputFile;
    case 'site':
      // final outputFile = File("${path?.path}/Site-$id.pdf");
      final outputFile = File(
          "${path?.path}/SiteCondition_${date}_${site}_${email}_CAMOS_${id.substring(0, 4)}.pdf");
      return outputFile;
    case 'attendance':
      // final outputFile = File("${path?.path}/Attendance-$id.xlsx");
      final outputFile = File(
          "${path?.path}/Attendance_${username}_${sn}_${DateFormat.MMMM().format(DateTime(DateTime.now().year, int.parse(date)))} ${DateTime.now().year}_${id.substring(0, 4)}.xlsx");
      return outputFile;
    case 'outstanding':
      final outputFile = File(
          "${path?.path}/TireInspection_${site}_${email}_${id}_CAMOS.xlsx");
      // final outputFile = File("${path?.path}/Outstanding-$id.xlsx");
      return outputFile;
    case 'daily-check':
      final outputFile = File(
          "${path?.path}/DailyTireCheck_${date}_${site}_${pit}_${email}_${id.substring(0, 8)}_CAMOS.xlsx");
      // final outputFile = File("${path?.path}/daily-check_${id}xlsx");
      return outputFile;
    case 'outstanding-image':
      final outputFile = File("${path?.path}/outstanding-image-$id.jpg");
      return outputFile;
  }
  return File('');
}

/// membuat excel
Future<List<int>> createExcel(String type,
    {String username = '',
    String position = '',
    String sn = 'test',
    String site = '',
    int date = 0,
    List<Map<String, dynamic>>? task,
    List<Map<String, dynamic>>? daily,
    List<AttendanceEntity>? presence}) async {
  switch (type) {
    case 'attendance':
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      /// title
      sheet.getRangeByName('A1:G1').merge();
      sheet.getRangeByName('A1:G1').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('A1:G1').setText('ATTENDANCE RECORD');

      sheet.getRangeByName('A2:G2').merge();

      /// Date
      sheet.getRangeByName('A3:G3').merge();
      // sheet.getRangeByName('A3:G3').setText(
      //     'Date                    : ${DateFormat.yMMMM().format(DateTime.now())}');
      sheet.getRangeByName('A3:G3').setText(
          'Date                    : ${DateFormat.MMMM().format(DateTime(DateTime.now().year, date))} ${DateTime.now().year}');

      /// Name
      sheet.getRangeByName('A4:G4').merge();
      sheet
          .getRangeByName('A4:G4')
          .setText('Name                  : $username');

      /// SN
      sheet.getRangeByName('A5:G5').merge();
      sheet.getRangeByName('A5:G5').setText('SN                  : $sn');

      /// Position
      sheet.getRangeByName('A6:G6').merge();
      sheet
          .getRangeByName('A6:G6')
          .setText('Position              : $position');

      /// Site
      sheet.getRangeByName('A7:G7').merge();
      sheet.getRangeByName('A7:G7').setText('Site              : $site');

      /// Presence
      sheet.getRangeByName('A8:G8').merge();
      sheet.getRangeByName('A8:G8').setText('Working Time');
      sheet.getRangeByName('A8:G8').cellStyle.hAlign = HAlignType.center;

      sheet.getRangeByName('A9').setText('Date');

      sheet.getRangeByName('B9:C9').merge();
      sheet.getRangeByName('B9:C9').setText('Day');
      sheet.getRangeByName('B9:C9').cellStyle.hAlign = HAlignType.center;

      sheet.getRangeByName('D9').setText('From');
      sheet.getRangeByName('D9').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('D9').columnWidth = 15;
      sheet.getRangeByName('E9').setText('To');
      sheet.getRangeByName('E9').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('E9').columnWidth = 15;
      sheet.getRangeByName('F9').setText('Check-In');
      sheet.getRangeByName('F9').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('F9').columnWidth = 92;
      sheet.getRangeByName('G9').setText('Check-Out');
      sheet.getRangeByName('G9').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('G9').columnWidth = 92;
      sheet.getRangeByName('H9').setText('Description-In');
      sheet.getRangeByName('H9').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('H9').columnWidth = 70;
      sheet.getRangeByName('I9').setText('Description-Out');
      sheet.getRangeByName('I9').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('I9').columnWidth = 70;

      /// get date
      int days = daysInMonth(DateTime.now());
      for (int i = 0; i < days; i++) {
        sheet.getRangeByName('A${i + 10}').setText('${i + 1}');
        sheet.getRangeByName('A${i + 10}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('A${i + 10}').cellStyle.vAlign = VAlignType.center;

        for (int j = 0; j < presence!.length; j++) {
          // if (DateTime(DateTime.now().year, DateTime.now().month, i + 1)
          if (DateTime(DateTime.now().year, date, i + 1)
                  .toIso8601String()
                  .split('T')[0] ==
              presence[j].masuk.split('T')[0]) {
            sheet.getRangeByName('D${i + 10}:E${i + 10}').unmerge();
            sheet.getRangeByName('D${i + 10}:E${i + 10}').cellStyle.fontColor =
                '#00968A';

            /// From
            sheet.getRangeByName('D${i + 10}').setText(
                '${DateFormat.Hms().format(DateTime.parse(presence[j].masuk))}');
            sheet.getRangeByName('D${i + 10}').cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByName('D${i + 10}').cellStyle.vAlign =
                VAlignType.center;
            sheet.getRangeByName('D${i + 10}').columnWidth = 15;

            /// masukkan gambar check in
            final resizedImage = await resizeImage(
                base64Decode(presence[j].masukImage), 600, 600);
            sheet.pictures.addStream(i + 10, 6, resizedImage);

            sheet.getRangeByIndex(i + 10, 6).rowHeight = 550;
            sheet.getRangeByIndex(i + 10, 6).columnWidth = 92;
            sheet.getRangeByIndex(i + 10, 6).cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByIndex(i + 10, 6).cellStyle.vAlign =
                VAlignType.center;

            // keterangan masuk
            sheet
                .getRangeByName('H${i + 10}')
                .setText('${presence[j].keteranganMasuk}');
            sheet.getRangeByName('H${i + 10}').cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByName('H${i + 10}').cellStyle.vAlign =
                VAlignType.center;
            sheet.getRangeByName('H${i + 10}').columnWidth = 70;

            /// To
            /// cek apakah ada data absen keluar atau tidak
            if (presence[j].keluar != '' && presence[j].keluar != null) {
              sheet.getRangeByName('E${i + 10}').setText(
                  '${DateFormat.Hms().format(DateTime.parse(presence[j].keluar))}');
              sheet.getRangeByName('E${i + 10}').cellStyle.hAlign =
                  HAlignType.center;
              sheet.getRangeByName('E${i + 10}').cellStyle.vAlign =
                  VAlignType.center;
              sheet.getRangeByName('E${i + 10}').columnWidth = 15;

              /// masukkan gambar check out
              final resizedImage = await resizeImage(
                  base64Decode(presence[j].keluarImage), 600, 600);
              sheet.pictures.addStream(i + 10, 7, resizedImage);

              sheet.getRangeByIndex(i + 10, 7).rowHeight = 550;
              sheet.getRangeByIndex(i + 10, 7).columnWidth = 92;
              sheet.getRangeByIndex(i + 10, 7).cellStyle.hAlign =
                  HAlignType.center;
              sheet.getRangeByIndex(i + 10, 7).cellStyle.vAlign =
                  VAlignType.center;

              // keterangan keluar
              sheet
                  .getRangeByName('I${i + 10}')
                  .setText('${presence[j].keteranganKeluar}');
              sheet.getRangeByName('I${i + 10}').cellStyle.hAlign =
                  HAlignType.center;
              sheet.getRangeByName('I${i + 10}').cellStyle.vAlign =
                  VAlignType.center;
              sheet.getRangeByName('I${i + 10}').columnWidth = 70;
            }
          }
        }
      }

      /// get days
      for (int i = 0; i < days; i++) {
        DateTime date =
            DateTime(DateTime.now().year, DateTime.now().month, i + 1);
        sheet.getRangeByName('B${i + 10}:C${i + 10}').merge();
        sheet
            .getRangeByName('B${i + 10}:C${i + 10}')
            .setText(DateFormat('EEEE').format(date));
        sheet.getRangeByName('B${i + 10}:C${i + 10}').cellStyle.hAlign =
            HAlignType.center;
        sheet.getRangeByName('B${i + 10}:C${i + 10}').cellStyle.vAlign =
            VAlignType.center;
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      return bytes;

    // final Workbook workbook = Workbook();
    // final Worksheet sheet = workbook.worksheets[0];

    // /// title
    // sheet.getRangeByName('A1:G1').merge();
    // sheet.getRangeByName('A1:G1').cellStyle.hAlign = HAlignType.center;
    // sheet.getRangeByName('A1:G1').setText('ATTENDANCE RECORD');

    // sheet.getRangeByName('A2:G2').merge();

    // /// Date
    // sheet.getRangeByName('A3:G3').merge();
    // sheet.getRangeByName('A3:G3').setText(
    //     'Date                    : ${DateFormat.yMMMM().format(DateTime.now())}');

    // /// Name
    // sheet.getRangeByName('A4:G4').merge();
    // sheet
    //     .getRangeByName('A4:G4')
    //     .setText('Name                  : $username');

    // /// SN
    // sheet.getRangeByName('A5:G5').merge();
    // sheet.getRangeByName('A5:G5').setText('SN                  : $sn');

    // /// Position
    // sheet.getRangeByName('A6:G6').merge();
    // sheet
    //     .getRangeByName('A6:G6')
    //     .setText('Position              : $position');

    // /// Site
    // sheet.getRangeByName('A7:G7').merge();
    // sheet.getRangeByName('A7:G7').setText('Site              : $site');

    // /// Presence
    // sheet.getRangeByName('A8:G8').merge();
    // sheet.getRangeByName('A8:G8').setText('Working Time');
    // sheet.getRangeByName('A8:G8').cellStyle.hAlign = HAlignType.center;

    // sheet.getRangeByName('A9').setText('Date');

    // sheet.getRangeByName('B9:C9').merge();
    // sheet.getRangeByName('B9:C9').setText('Day');
    // sheet.getRangeByName('B9:C9').cellStyle.hAlign = HAlignType.center;

    // sheet.getRangeByName('D9').setText('From');
    // sheet.getRangeByName('D9').cellStyle.hAlign = HAlignType.center;
    // sheet.getRangeByName('D9').columnWidth = 15;
    // sheet.getRangeByName('E9').setText('To');
    // sheet.getRangeByName('E9').cellStyle.hAlign = HAlignType.center;
    // sheet.getRangeByName('E9').columnWidth = 15;
    // sheet.getRangeByName('F9').setText('Check-In');
    // sheet.getRangeByName('F9').cellStyle.hAlign = HAlignType.center;
    // sheet.getRangeByName('F9').columnWidth = 92;
    // sheet.getRangeByName('G9').setText('Check-Out');
    // sheet.getRangeByName('G9').cellStyle.hAlign = HAlignType.center;
    // sheet.getRangeByName('G9').columnWidth = 92;
    // sheet.getRangeByName('H9').setText('Description-In');
    // sheet.getRangeByName('H9').cellStyle.hAlign = HAlignType.center;
    // sheet.getRangeByName('H9').columnWidth = 70;
    // sheet.getRangeByName('I9').setText('Description-Out');
    // sheet.getRangeByName('I9').cellStyle.hAlign = HAlignType.center;
    // sheet.getRangeByName('I9').columnWidth = 70;

    // /// get date
    // // int days = daysInMonth(DateTime.now());
    // DateTime now = DateTime.now();
    // DateTime firstDayOfCurrentMonth = DateTime(now.year, now.month, 1);
    // DateTime firstDayOfPreviousMonth =
    //     firstDayOfCurrentMonth.subtract(Duration(days: 1));
    // DateTime lastDayOfPreviousMonth = DateTime(
    //     firstDayOfPreviousMonth.year, firstDayOfPreviousMonth.month + 1, 0);

    // int days = lastDayOfPreviousMonth.day;

    // for (int i = 0; i < days; i++) {
    //   sheet.getRangeByName('A${i + 10}').setText('${i + 1}');
    //   sheet.getRangeByName('A${i + 10}').cellStyle.hAlign = HAlignType.center;
    //   sheet.getRangeByName('A${i + 10}').cellStyle.vAlign = VAlignType.center;

    //   for (int j = 0; j < presence!.length; j++) {
    //     if (DateTime(DateTime.now().year, DateTime.now().month - 1, i + 1)
    //             .toIso8601String()
    //             .split('T')[0] ==
    //         presence[j].masuk.split('T')[0]) {
    //       sheet.getRangeByName('D${i + 10}:E${i + 10}').unmerge();
    //       sheet.getRangeByName('D${i + 10}:E${i + 10}').cellStyle.fontColor =
    //           '#00968A';

    //       /// From
    //       sheet.getRangeByName('D${i + 10}').setText(
    //           '${DateFormat.Hms().format(DateTime.parse(presence[j].masuk))}');
    //       sheet.getRangeByName('D${i + 10}').cellStyle.hAlign =
    //           HAlignType.center;
    //       sheet.getRangeByName('D${i + 10}').cellStyle.vAlign =
    //           VAlignType.center;
    //       sheet.getRangeByName('D${i + 10}').columnWidth = 15;

    //       /// masukkan gambar check in
    //       final resizedImage = await resizeImage(
    //           base64Decode(presence[j].masukImage), 600, 600);
    //       sheet.pictures.addStream(i + 10, 6, resizedImage);

    //       sheet.getRangeByIndex(i + 10, 6).rowHeight = 550;
    //       sheet.getRangeByIndex(i + 10, 6).columnWidth = 92;
    //       sheet.getRangeByIndex(i + 10, 6).cellStyle.hAlign =
    //           HAlignType.center;
    //       sheet.getRangeByIndex(i + 10, 6).cellStyle.vAlign =
    //           VAlignType.center;

    //       // keterangan masuk
    //       sheet
    //           .getRangeByName('H${i + 10}')
    //           .setText('${presence[j].keteranganMasuk}');
    //       sheet.getRangeByName('H${i + 10}').cellStyle.hAlign =
    //           HAlignType.center;
    //       sheet.getRangeByName('H${i + 10}').cellStyle.vAlign =
    //           VAlignType.center;
    //       sheet.getRangeByName('H${i + 10}').columnWidth = 70;

    //       /// To
    //       /// cek apakah ada data absen keluar atau tidak
    //       if (presence[j].keluar != '' && presence[j].keluar != null) {
    //         sheet.getRangeByName('E${i + 10}').setText(
    //             '${DateFormat.Hms().format(DateTime.parse(presence[j].keluar))}');
    //         sheet.getRangeByName('E${i + 10}').cellStyle.hAlign =
    //             HAlignType.center;
    //         sheet.getRangeByName('E${i + 10}').cellStyle.vAlign =
    //             VAlignType.center;
    //         sheet.getRangeByName('E${i + 10}').columnWidth = 15;

    //         /// masukkan gambar check out
    //         final resizedImage = await resizeImage(
    //             base64Decode(presence[j].keluarImage), 600, 600);
    //         sheet.pictures.addStream(i + 10, 7, resizedImage);

    //         sheet.getRangeByIndex(i + 10, 7).rowHeight = 550;
    //         sheet.getRangeByIndex(i + 10, 7).columnWidth = 92;
    //         sheet.getRangeByIndex(i + 10, 7).cellStyle.hAlign =
    //             HAlignType.center;
    //         sheet.getRangeByIndex(i + 10, 7).cellStyle.vAlign =
    //             VAlignType.center;

    //         // keterangan keluar
    //         sheet
    //             .getRangeByName('I${i + 10}')
    //             .setText('${presence[j].keteranganKeluar}');
    //         sheet.getRangeByName('I${i + 10}').cellStyle.hAlign =
    //             HAlignType.center;
    //         sheet.getRangeByName('I${i + 10}').cellStyle.vAlign =
    //             VAlignType.center;
    //         sheet.getRangeByName('I${i + 10}').columnWidth = 70;
    //       }
    //     }
    //   }
    // }

    // /// get days
    // for (int i = 0; i < days; i++) {
    //   DateTime date =
    //       DateTime(DateTime.now().year, DateTime.now().month - 1, i + 1);
    //   sheet.getRangeByName('B${i + 10}:C${i + 10}').merge();
    //   sheet
    //       .getRangeByName('B${i + 10}:C${i + 10}')
    //       .setText(DateFormat('EEEE').format(date));
    //   sheet.getRangeByName('B${i + 10}:C${i + 10}').cellStyle.hAlign =
    //       HAlignType.center;
    //   sheet.getRangeByName('B${i + 10}:C${i + 10}').cellStyle.vAlign =
    //       VAlignType.center;
    // }

    // final List<int> bytes = workbook.saveAsStream();
    // workbook.dispose();
    // return bytes;
    case 'outstanding':
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      log('function export' + task.toString());

      /// title
      // sheet.getRangeByName('A1:Q1').merge();
      // sheet.getRangeByName('A1:Q1').cellStyle.hAlign = HAlignType.center;
      // sheet.getRangeByName('A1:Q1').setText('Outstanding task');

      // sheet.getRangeByName('A2:Q2').merge();
      // sheet.getRangeByName('A2:Q2').setText('Site : ${task?[0]['id_site']}');

      // sheet.getRangeByName('A3:D3').merge();
      // sheet.getRangeByName('A3:D3').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('A1').setText('Inspector');

      // sheet.getRangeByName('E3:F3').merge();
      // sheet.getRangeByName('E3:F3').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('B1').setText('Date');

      // sheet.getRangeByName('G3:H3').merge();
      // sheet.getRangeByName('G3:H3').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('C1').setText('Unit Number');

      // sheet.getRangeByName('I3:J3').merge();
      // sheet.getRangeByName('I3:J3').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('D1').setText('Tire Position');

      // sheet.getRangeByName('K3:L3').merge();
      // sheet.getRangeByName('K3:L3').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('E1').setText('Pressure');

      // sheet.getRangeByName('M3:Q3').merge();
      // sheet.getRangeByName('M3:Q3').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('F1').setText('Tire Damage');

      // sheet.getRangeByName('R3:S3').merge();
      // sheet.getRangeByName('R3:S3').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('G1').setText('RTD 1');

      // sheet.getRangeByName('T3:U3').merge();
      // sheet.getRangeByName('T3:U3').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('H1').setText('RTD 2');

      // sheet.getRangeByName('V3:Z3').merge();
      // sheet.getRangeByName('V3:Z3').cellStyle.hAlign = HAlignType.center;
      sheet.getRangeByName('I1').setText('Adj. Pressure');
      sheet.getRangeByName('J1').setText('Gambar_1');

      for (var i = 0; i < task!.length; i++) {
        // inspector
        // sheet.getRangeByName('A${i + 1}').merge();
        sheet.getRangeByName('A${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('A${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('A${i + 2}').setText(task[i]['user']);

        // tanggal
        DateTime originalDateTime = DateTime.parse(task[i]['last_update']);
        String formattedDate =
            "${originalDateTime.year}-${_twoDigits(originalDateTime.month)}-${_twoDigits(originalDateTime.day)}";
        // sheet.getRangeByName('E${i + 4}:F${i + 4}').merge();
        sheet.getRangeByName('B${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('B${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('B${i + 2}').setText(formattedDate);

        // unit number
        // sheet.getRangeByName('G${i + 4}:H${i + 4}').merge();
        sheet.getRangeByName('C${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('C${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('C${i + 2}').setText(task[i]['unit']);

        // tire position
        // sheet.getRangeByName('I${i + 4}:J${i + 4}').merge();
        sheet.getRangeByName('D${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('D${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet
            .getRangeByName('D${i + 2}')
            .setText(task[i]['position'].toString());

        // pressure
        // sheet.getRangeByName('E${i + 2}').merge();
        try {
          sheet.getRangeByName('E${i + 2}').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('E${i + 2}').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('E${i + 2}').setText(
              (task[i]['pressure'] == '' || task[i]['pressure'] == null)
                  ? '0 Psi'
                  : task[i]['pressure'] + 'Psi');
        } catch (e) {}

        // TIRE DAMAGE
        // sheet.getRangeByName('F${i + 2}').merge();
        sheet.getRangeByName('F${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('F${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('F${i + 2}').setText(
            (task[i]['tire_damage'] is List<dynamic>)
                ? (task[i]['tire_damage'] as List<dynamic>).join('\n')
                : task[i]['tire_damage']);

        try {
          //RTD 1
          // sheet.getRangeByName('G${i + 1}').merge();
          if (task[i]['rtd'] != '/') {
            final splitRtd = (task[i]['rtd'] as String).split('/');
            sheet.getRangeByName('G${i + 2}').cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByName('G${i + 2}').cellStyle.vAlign =
                VAlignType.center;
            sheet.getRangeByName('G${i + 2}').setText(splitRtd[0]);

            //RTD 2
            // sheet.getRangeByName('I${i + 4}').merge();
            sheet.getRangeByName('H${i + 2}').cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByName('H${i + 2}').cellStyle.vAlign =
                VAlignType.center;
            sheet.getRangeByName('H${i + 2}').setText(splitRtd[1]);
          } else {
            sheet.getRangeByName('G${i + 2}').cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByName('G${i + 2}').cellStyle.vAlign =
                VAlignType.center;
            sheet.getRangeByName('G${i + 2}').setText('0');

            //RTD 2
            // sheet.getRangeByName('I${i + 4}').merge();
            sheet.getRangeByName('H${i + 2}').cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByName('H${i + 2}').cellStyle.vAlign =
                VAlignType.center;
            sheet.getRangeByName('H${i + 2}').setText('0');
          }
        } catch (e) {
          log('error rtd : $e');
        }

        //ADJUSMNET PRESSURE
        // sheet.getRangeByName('T${i + 4}:U${i + 4}').merge();
        sheet.getRangeByName('I${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('I${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('I${i + 2}').setText(
            (task[i]['adjusmentPressure'] == '' ||
                    task[i]['adjusmentPressure'] == null)
                ? '0 Psi'
                : task[i]['adjusmentPressure'] + 'Psi');

        // IMAGE TIRE
        int columnBroken = 11;
        final urlImage = task[i]['images'];
        if (urlImage != null) {
          for (var j = 0; j < urlImage.length; j++) {
            log('gambar dari firebase : ${urlImage[j]}');

            try {
              if (urlImage[j] != null) {
                final file = File(urlImage[j]);
                final bytes = await file.readAsBytes();
                final base64String = base64Encode(bytes);

                if (j == 0) {
                  sheet.getRangeByName('J${i + 2}').cellStyle.hAlign =
                      HAlignType.center;
                  sheet.getRangeByName('J${i + 2}').cellStyle.vAlign =
                      VAlignType.center;
                  sheet.getRangeByName('J${i + 2}').setText(base64String);
                }
                // else {
                //   sheet.getRangeByIndex(i + 2, j + 10).setText(base64String);
                //   sheet.getRangeByIndex(1, j + 10).setText('Gambar_${j + 1}');
                //   sheet.getRangeByIndex(1, j + 10).cellStyle.hAlign =
                //       HAlignType.center;
                //   sheet.getRangeByIndex(i + 2, j + 10).cellStyle.hAlign =
                //       HAlignType.center;
                //   sheet.getRangeByIndex(i + 2, j + 10).cellStyle.vAlign =
                //       VAlignType.center;
                //   columnBroken += j;
                // }
              }
            } catch (e) {
              log('kenapa gambar error : $e');
            }
          }
        }

        // BROKEN COMPONENT
        sheet.getRangeByName('K1').setText('Broken Component');
        sheet.getRangeByName('K1').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('K1').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('K${i + 2}').setText(
            (task[i]['condition'] == null ||
                    (task[i]['condition'] is List<dynamic> &&
                        (task[i]['condition'] as List<dynamic>).isEmpty))
                ? ' '
                : (task[i]['condition'] is List<dynamic>)
                    ? (task[i]['condition'] as List<dynamic>).join(', ')
                    : task[i]['condition']);
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      return bytes;
    case 'daily-check':
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      // sheet.getRangeByName('A1').setText('Date');
      // sheet.getRangeByName('B1').setText('Unit');
      // sheet.getRangeByName('C1').setText('Pos');
      // sheet.getRangeByName('D1').setText('Pressure');

      // log('funcdailyexcel: $daily');
      // for(int i = 0; i < daily!.length; i++){
      //   // merubah tanggal jadi dd/MM/yyyy
      //   DateTime parse = DateTime.parse(daily[i]['tanggal']);
      //   String formattedDate = DateFormat('dd/MM/yyyy').format(parse);

      //   final unit = daily[i]['unit'];
      //   final posisi = daily[i]['posisi'] as List<dynamic>;

      //   for(int j = 0; j < posisi.length; j++){
      //     sheet.getRangeByName('A${j+2}').setText(formattedDate);
      //     sheet.getRangeByName('B${j+2}').setText(unit);
      //     sheet.getRangeByName('C${j+2}').setText(posisi[j]['pos']);
      //     sheet.getRangeByName('D${j+2}').setText(posisi[j]['pressure']);
      //   }

      // }
      sheet.getRangeByName('A1').setText('Date');
      sheet.getRangeByName('B1').setText('Unit');
      sheet.getRangeByName('C1').setText('Pos');
      sheet.getRangeByName('D1').setText('Pressure');
      sheet.getRangeByName('E1').setText('Adj');
      sheet.getRangeByName('F1').setText('Tire Damage');
      sheet.getRangeByName('F1').columnWidth = 25;

      for (int i = 0; i < daily!.length; i++) {
        final unit = daily[i]['unit'];
        final posisi = daily[i]['posisi'] as List<dynamic>;

        if (i == 4) {
          log('unit4: ${daily[i]['unit']}');
          log('posisi4: ${daily[i]['posisi']}');
        }

        for (int j = 0; j < posisi.length; j++) {
          // Merubah tanggal menjadi dd/MM/yyyy
          DateTime parse = DateTime.parse(daily[i]['tanggal']);
          String formattedDate = DateFormat('MM/dd/yyyy').format(parse);
          sheet
              .getRangeByName('A${i * posisi.length + j + 2}')
              .setText(formattedDate);
          sheet.getRangeByName('B${i * posisi.length + j + 2}').setText(unit);

          sheet
              .getRangeByName('C${i * posisi.length + j + 2}')
              .setText(posisi[j]['pos']);
          sheet
              .getRangeByName('D${i * posisi.length + j + 2}')
              .setText(posisi[j]['pressure']);
          sheet.getRangeByName('E${i * posisi.length + j + 2}').setText(
              (posisi[j]['adjusmentPressure'] == '')
                  ? '0'
                  : posisi[j]['adjusmentPressure']);
          if (posisi[j]['luka'] != null && posisi[j]['luka'] is! String) {
            sheet.getRangeByName('F${i * posisi.length + j + 2}').setText(
                (posisi[j]['luka'] as List<dynamic>)
                    .where((element) => element.isNotEmpty)
                    .join('\n'));
            sheet.getRangeByName('F${i * posisi.length + j + 2}').columnWidth =
                25;
          }
        }
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      return bytes;
  }
  return [];
}

/// membuat pdf
pw.Document createPdf(Uint8List image) {
  if (image == null) {
    return pw.Document();
  }

  pw.Document pdf = pw.Document();
  pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (pw.Context context) {
        return pw.Center(child: pw.Image(pw.MemoryImage(image)));
      }));

  return pdf;
}

/// menyimpan pdf
Future<String> savePdf(pw.Document pdf, File outputFile) async {
  await outputFile.writeAsBytes(await pdf.save());
  if (Platform.isIOS) {
    await OpenFile.open(outputFile.path);
  }
  print('gambar ${outputFile.path}');
  return outputFile.path;
}

int getLetterPosition(String letter) {
  // Pastikan huruf yang diberikan hanya satu karakter
  // if (letter.length != 1) {
  //   throw ArgumentError('Input should be a single letter.');
  // }

  // Mengubah huruf ke huruf kecil untuk konsistensi
  letter = letter.toLowerCase();

  // Menghitung posisi huruf dalam alfabet
  return letter.codeUnitAt(0) - 'a'.codeUnitAt(0) + 1;
}

/// membuka playstore secara otomatis
openPlayStore(String type) async {
  switch (type) {
    case 'attendance':
      if (Platform.isAndroid) {
        StoreRedirect.redirect(
            androidAppId: 'com.google.android.apps.docs.editors.sheets');
      }

      break;

    case 'camos':
      if (Platform.isAndroid) {
        StoreRedirect.redirect(androidAppId: 'com.chitraparatama.camos');
      }

      if (Platform.isIOS) {
        StoreRedirect.redirect(iOSAppId: '6468975738');
      }
      break;
  }
}

/// mengirim email
void sendEmailWithAttachment(String path, String type) async {
  /// Tentukan alamat email penerima, subjek, dan isi pesan
  final recipient = '';
  var subject = '';
  var body = '';

  switch (type) {
    case 'tkph':
      subject = 'Hasil Perhitungan TKPH';
      body =
          'Saya ingin memberitahukan bahwa saya telah mengirimkan file perhitungan TKPH dalam format PDF melalui email terlampir. Mohon periksa email Anda untuk mendapatkan akses ke file tersebut.\nMohon untuk meluangkan waktu sejenak untuk meninjau hasil perhitungan TKPH tersebut. Jika ada pertanyaan atau klarifikasi lebih lanjut, jangan ragu untuk menghubungi saya melalui email ini atau melalui nomor kontak yang telah saya sertakan di tanda tangan email ini.\nTerima kasih atas perhatian dan bantuan Anda dalam melakukan perhitungan TKPH ini. Saya sangat menghargainya.';
      break;
    case 'site':
      subject = 'Site Condition';
      body =
          'Saya ingin memberitahukan bahwa saya telah mengirimkan file site condition dalam format PDF melalui email terlampir. Mohon periksa email Anda untuk mendapatkan akses ke file tersebut. \nSaya sangat menghargainya.';
      break;
  }

  /// Siapkan email dengan lampiran file
  final Email email = Email(
    recipients: [recipient],
    subject: subject,
    body: body,
    attachmentPaths: [path],
  );

  /// Buka aplikasi email default pengguna
  try {
    await FlutterEmailSender.send(email);
  } catch (e) {
    log('email gaiso : $e');
  }
}

/// inisialisasi Here Maps (Terdapat token)
void initializeHERESDK() async {
  // Needs to be called before accessing SDKOptions to load necessary libraries.
  // SdkContext.init(IsolateOrigin.main);

  // // // Set your credentials for the HERE SDK.
  // String accessKeyId = "sx2DVsK_X2WXleHob1bipw";
  // String accessKeySecret =
  //     "cZmc8GFGhIIaiKKeAZFAftEVJV4Akx-Vr9oI6XGUfZGgZ1qAA62IPxQJpmLHwqn7AEHcmuQl7ML6o0JcJZQDEg";
  // SDKOptions sdkOptions =
  //     SDKOptions.withAccessKeySecret(accessKeyId, accessKeySecret);

  // try {
  //   await SDKNativeEngine.makeSharedInstance(sdkOptions);
  // } on InstantiationException {
  //   throw Exception("Failed to initialize the HERE SDK.");
  // }
}

/// mengecek koneksi internet perangkat
class NetworkHelper {
  static void observeNetwork() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      if (result == ConnectivityResult.none) {
        NetworkBloc().add(NetworkNotifyEvent());
      } else {
        NetworkBloc().add(NetworkNotifyEvent(isConnected: true));
      }
    });
  }
}

/// mendapatkan jumlah hari dari suatu bulan
int daysInMonth(DateTime date) {
  // Menggunakan DateTime untuk mendapatkan tanggal pertama bulan berikutnya
  DateTime firstDayOfNextMonth = DateTime(date.year, date.month + 1, 1);

  // Mengurangi satu hari dari tanggal pertama bulan berikutnya untuk mendapatkan tanggal terakhir bulan saat ini
  DateTime lastDayOfMonth = firstDayOfNextMonth.subtract(Duration(days: 1));

  // Mengembalikan hari terakhir bulan saat ini
  return lastDayOfMonth.day;
}

String getDayOfWeek(DateTime date) {
  List<String> days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu'
  ];

  // Menggunakan properti weekday untuk mendapatkan indeks hari dalam seminggu
  int dayIndex = date.weekday - 1;

  // Mengembalikan nama hari berdasarkan indeks
  return days[dayIndex];
}

/// mengurangi ukuran gambar
Future<Uint8List> resizeImage(
    Uint8List imageBytes, int targetWidth, int targetHeight) async {
  img.Image image = img.decodeImage(imageBytes)!;

  img.Image resizedImage =
      img.copyResize(image, width: targetWidth, height: targetHeight);

  Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));
  return resizedBytes;
}

// formatDateTimeString(String dateTimeString) {
//   initializeDateFormatting('id_ID', null).then((_) {
//     DateTime dateTime = DateTime.parse(dateTimeString);
//     formatDateTime(dateTime);
//   });
// }

// convert time
String formatDateTime(DateTime dateTime) {
  String dayOfWeek = DateFormat('EEEE', 'en_US').format(dateTime); // Hari
  String day = DateFormat('d', 'en_US').format(dateTime); // Tanggal
  String monthYear =
      DateFormat('MMMM y', 'en_US').format(dateTime); // Bulan dan Tahun
  String time = DateFormat('H:mm:ss').format(dateTime); // Jam, Menit, Detik

  return '$dayOfWeek, $day $monthYear, $time';
}

String _twoDigits(int n) {
  if (n >= 10) {
    return "$n";
  }
  return "0$n";
}
