import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camos/core/utils/data/id_site.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../../services/local_database/attendance/attendance_entity.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image/image.dart' as img;
import '../../blocs/network/network_bloc.dart';
import '../../services/api_service.dart';
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
import 'package:http/http.dart' as http;

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
    String customer = '',
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
    case 'repair':
      // final outputFile = File("${path?.path}/Site-$id.pdf");
      final outputFile = File(
          "${path?.path}/TireRepairInspectionReport_${date}_${customer}_${sn}_CAMOS_${id.substring(0, 4)}.pdf");
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
    case 'tire_inspection':
      final outputFile = File(
          "${path?.path}/TireInspection_${site}_${email}_${id.substring(0, 8)}_CAMOS.xlsx");
      // final outputFile = File("${path?.path}/daily-check_${id}xlsx");
      return outputFile;
    case 'outstanding-image':
      final outputFile = File("${path?.path}/outstanding-image-$id.jpg");
      return outputFile;
  }
  return File('');
}

/// Try reduce image until base64 length <= maxAllowed.
/// Returns resulting base64 if success, otherwise null.
///
// Future<String?> tryShrinkToOneCell(
//   Uint8List originalBytes, {
//   int maxAllowed = 32000,
// }) async {
//   // === quick check
//   final originalB64 = base64Encode(originalBytes);
//   if (originalB64.length <= maxAllowed) return originalB64;

//   Uint8List currentBytes = originalBytes;
//   String? bestB64;

//   // STEP 1 — resize aggressively first (paling berdampak)
//   const widths = [800, 600, 400, 300, 200];
//   for (final w in widths) {
//     final resized = await FlutterImageCompress.compressWithList(
//       currentBytes,
//       minWidth: w,
//       minHeight: 0,
//       quality: 85, // tetap tinggi dulu
//       format: CompressFormat.webp,
//     );

//     if (resized == null || resized.isEmpty) continue;

//     final b64 = base64Encode(Uint8List.fromList(resized));
//     bestB64 ??= b64;
//     if (b64.length <= maxAllowed) return b64;

//     // lanjut dari hasil resize, bukan original
//     currentBytes = Uint8List.fromList(resized);
//     break; // ⛔ stop resize lebih kecil dulu
//   }

//   // STEP 2 — turunkan quality dari hasil resize
//   const qualities = [80, 65, 50, 40, 30];
//   for (final q in qualities) {
//     final comp = await FlutterImageCompress.compressWithList(
//       currentBytes,
//       quality: q,
//       format: CompressFormat.webp,
//     );

//     if (comp == null || comp.isEmpty) continue;

//     final b64 = base64Encode(Uint8List.fromList(comp));
//     if (b64.length <= maxAllowed) return b64;

//     if (bestB64 == null || b64.length < bestB64.length) {
//       bestB64 = b64;
//     }
//   }

//   // STEP 3 — fallback JPEG (hanya sekali!)
//   final jpeg = await FlutterImageCompress.compressWithList(
//     currentBytes,
//     quality: 40,
//     format: CompressFormat.jpeg,
//   );

//   if (jpeg != null && jpeg.isNotEmpty) {
//     final b64 = base64Encode(Uint8List.fromList(jpeg));
//     if (b64.length <= maxAllowed) return b64;
//   }

//   return null;
// }

Future<String?> tryShrinkToOneCell(Uint8List originalBytes,
    {int maxAllowed = 32000, // safe threshold < 32767
    List<int> targetWidths = const [800, 600, 400, 300, 200, 150, 120, 80, 50],
    List<int> qualities = const [80, 70, 60, 50, 40, 30, 20]}) async {
  // quick check original
  String b64 = base64Encode(originalBytes);
  if (b64.length <= maxAllowed) return b64;

  // try progressive compress without resize first (quality down)
  for (final q in qualities) {
    try {
      final comp = await FlutterImageCompress.compressWithList(
        originalBytes,
        quality: q,
        format: CompressFormat.webp, // try webp first, smaller
      );
      if (comp != null && comp.isNotEmpty) {
        final b = base64Encode(Uint8List.fromList(comp));
        if (b.length <= maxAllowed) return b;
        // keep smallest candidate optionally
        if (b.length < b64.length) b64 = b;
      }
    } catch (_) {}
  }

  // try resizing to various widths, and compress at multiple qualities
  for (final w in targetWidths) {
    for (final q in qualities) {
      try {
        final comp = await FlutterImageCompress.compressWithList(
          originalBytes,
          minWidth: w,
          minHeight: 0, // let lib keep aspect ratio
          quality: q,
          format: CompressFormat.webp,
        );
        if (comp != null && comp.isNotEmpty) {
          final b = base64Encode(Uint8List.fromList(comp));
          if (b.length <= maxAllowed) return b;
          if (b.length < b64.length) b64 = b;
        }
      } catch (_) {}
    }
  }

  // final fallback - try JPEG encode if webp failed small enough
  for (final w in targetWidths) {
    for (final q in qualities) {
      try {
        final comp = await FlutterImageCompress.compressWithList(
          originalBytes,
          minWidth: w,
          quality: q,
          format: CompressFormat.jpeg,
        );
        if (comp != null && comp.isNotEmpty) {
          final b = base64Encode(Uint8List.fromList(comp));
          if (b.length <= maxAllowed) return b;
          if (b.length < b64.length) b64 = b;
        }
      } catch (_) {}
    }
  }

  // can't reduce enough
  return null;
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
    case 'tire_inspection':
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];
      sheet.name = 'Tire Inspection';

      // Header
      sheet.getRangeByName('A1').setText('Date');
      sheet.getRangeByName('B1').setText('Unit Number');
      sheet.getRangeByName('C1').setText('Tire Position');
      sheet.getRangeByName('D1').setText('Pressure');
      sheet.getRangeByName('E1').setText('RTD 1');
      sheet.getRangeByName('F1').setText('Hm On Inspect');
      sheet.getRangeByName('G1').setText('Remark');
      sheet.getRangeByName('H1').setText('Pics');
      sheet.getRangeByName('I1').setText('Adj. Pressure');
      sheet.getRangeByName('J1').setText('Inspector');
      sheet.getRangeByName('K1').setText('Location');
      sheet.getRangeByName('L1').setText('Tire Damage');
      sheet.getRangeByName('M1').setText('Broken Component');
      sheet.getRangeByName('N1').setText('SN Tire');

      int rowIndex = 2;

      for (final doc in task!) {
        final posisiList = doc['posisi'] as List<dynamic>? ?? [];

        for (final p in posisiList) {
          final posisi = p as Map<String, dynamic>;

          // Tanggal
          String formattedDate = doc['hari'] ?? '';
          try {
            if (doc['tanggal'] != null &&
                doc['tanggal'].toString().isNotEmpty) {
              final parsed = DateTime.parse(doc['tanggal']);
              formattedDate =
                  "${parsed.year}-${_twoDigits(parsed.month)}-${_twoDigits(parsed.day)}";
            }
          } catch (e) {
            log('error parse tanggal: $e');
          }

          // A = Date
          sheet.getRangeByName('A$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('A$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('A$rowIndex').setText(formattedDate);

          // B = Unit Number
          sheet.getRangeByName('B$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('B$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('B$rowIndex').setText(
              (doc['unit'] == '' || doc['unit'] == null) ? '0' : doc['unit']);

          // C = Tire Position
          sheet.getRangeByName('C$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('C$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('C$rowIndex').setText(
              (posisi['position'] == null)
                  ? '0'
                  : posisi['position'].toString());

          // D = Pressure
          sheet.getRangeByName('D$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('D$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('D$rowIndex').setText(
              (posisi['pressure'] == '' || posisi['pressure'] == null)
                  ? '0'
                  : posisi['pressure'].toString());

          // E = RTD 1
          try {
            sheet.getRangeByName('E$rowIndex').cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByName('E$rowIndex').cellStyle.vAlign =
                VAlignType.center;
            sheet.getRangeByName('E$rowIndex').setText(
                (posisi['rtd1'] == '' || posisi['rtd1'] == null)
                    ? '0'
                    : posisi['rtd1'].toString());
          } catch (e) {
            log('error rtd: $e');
          }

          // F = HM On Inspect
          sheet.getRangeByName('F$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('F$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('F$rowIndex').setText(
              (doc['hm'] == null || doc['hm'] == '')
                  ? '0'
                  : doc['hm'].toString());

          // G = Remark
          sheet.getRangeByName('G$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('G$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('G$rowIndex').setText(
              (posisi['remarks'] == '' || posisi['remarks'] == null)
                  ? '0'
                  : posisi['remarks']);

          // H = Pics (image dari Firebase Storage)
          try {
            final urlImage = posisi['images'] as List<dynamic>?;

            if (urlImage != null && urlImage.isNotEmpty) {
              final img = urlImage[0];
              if (img != null && img.toString().isNotEmpty) {
                Uint8List? bytes;
                final isUrl = img.toString().startsWith('http://') ||
                    img.toString().startsWith('https://');
                if (isUrl) {
                  log('img url: $img');
                  final response = await http.get(Uri.parse(img));
                  if (response.statusCode == 200) {
                    bytes = response.bodyBytes;
                  } else {
                    log('Failed to download image, status: ${response.statusCode}');
                  }
                } else {
                  final file = File(img);
                  if (await file.exists()) {
                    bytes = await file.readAsBytes();
                  } else {
                    log('Local image not found: $img');
                  }
                }

                if (bytes != null && bytes.isNotEmpty) {
                  final resizedImage = await resizeImage(bytes, 600, 600);
                  final range = sheet.getRangeByIndex(rowIndex, 8);
                  range.rowHeight = 120;
                  range.columnWidth = 20;
                  final picture =
                      sheet.pictures.addStream(rowIndex, 8, resizedImage);
                  picture.width = 110;
                  picture.height = 110;
                }
              } else {
                sheet.getRangeByIndex(rowIndex, 8).setNumber(0);
              }
            } else {
              sheet.getRangeByIndex(rowIndex, 8).setNumber(0);
            }
          } catch (e, st) {
            log('Error processing image for row $rowIndex: $e\n$st');
          }

          // I = Adj. Pressure
          sheet.getRangeByName('I$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('I$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('I$rowIndex').setText(
              (posisi['adjusmentPressure'] == '' ||
                      posisi['adjusmentPressure'] == null)
                  ? '0'
                  : posisi['adjusmentPressure'].toString());

          // J = Inspector
          sheet.getRangeByName('J$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('J$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('J$rowIndex').setText(
              (doc['user'] == '' || doc['user'] == null) ? '0' : doc['user']);

          // K = Location
          sheet.getRangeByName('K$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('K$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('K$rowIndex').setText(
              (doc['pit'] == '' || doc['pit'] == null)
                  ? 'Default'
                  : doc['pit']);

          // L = Tire Damage
          final lukaData = posisi['damageTire'];
          String damageText = '0';
          if (lukaData is List && lukaData.isNotEmpty) {
            damageText = (lukaData as List<dynamic>)
                .where((e) => e != null && e.toString().isNotEmpty)
                .join('\n');
          } else if (lukaData is String && lukaData.isNotEmpty) {
            damageText = lukaData;
          }
          sheet.getRangeByName('L$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('L$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('L$rowIndex').setText(damageText);

          // M = Broken Component (condition yang checked)
          final conditionList = posisi['condition'] as List<dynamic>? ?? [];
          final checkedConditions = conditionList
              .where((c) => c is Map && c['checked'] == true)
              .map((c) => c['name'].toString())
              .toList();
          final conditionText =
              checkedConditions.isEmpty ? '0' : checkedConditions.join(', ');
          sheet.getRangeByName('M$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('M$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('M$rowIndex').setText(conditionText);

          // N = SN Tire
          sheet.getRangeByName('N$rowIndex').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('N$rowIndex').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('N$rowIndex').setText(
              (posisi['sn'] == '' || posisi['sn'] == null)
                  ? '0'
                  : posisi['sn']);

          rowIndex++;
        }
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      return bytes;

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

    case 'outstanding':
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      sheet.getRangeByName('J1').setText('Inspector');

      sheet.getRangeByName('K1').setText('Location');

      sheet.getRangeByName('L1').setText('Tire Damage');

      sheet.getRangeByName('M1').setText('Broken Component');

      sheet.getRangeByName('N1').setText('SN Tire');

      sheet.getRangeByName('A1').setText('Date');

      sheet.getRangeByName('B1').setText('Unit Number');

      sheet.getRangeByName('C1').setText('Tire Position');

      sheet.getRangeByName('D1').setText('Pressure');

      sheet.getRangeByName('F1').setText('Hm On Inspect');

      sheet.getRangeByName('G1').setText('Remark');

      sheet.getRangeByName('E1').setText('RTD 1');

      // sheet.getRangeByName('H1').setText('RTD 2');

      sheet.getRangeByName('I1').setText('Adj. Pressure');

      sheet.getRangeByName('H1').setText('Pics');

      for (var i = 0; i < task!.length; i++) {
        // inspector
        sheet.getRangeByName('A${i + 1}').merge();
        sheet.getRangeByName('J${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('J${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('J${i + 2}').setText('0');
        sheet
            .getRangeByName('J${i + 2}')
            .setText((task[i]['user'] == '') ? '0' : task[i]['user']);

        // tanggal
        DateTime originalDateTime = DateTime.parse(task[i]['last_update']);
        String formattedDate =
            "${originalDateTime.year}-${_twoDigits(originalDateTime.month)}-${_twoDigits(originalDateTime.day)}";
        // sheet.getRangeByName('E${i + 4}:F${i + 4}').merge();
        sheet.getRangeByName('A${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('A${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('A${i + 2}').setText('0');
        sheet
            .getRangeByName('A${i + 2}')
            .setText((formattedDate == '') ? '0' : formattedDate);

        // unit number
        sheet.getRangeByName('B${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('B${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('B${i + 2}').setText('0');
        sheet
            .getRangeByName('B${i + 2}')
            .setText((task[i]['unit'] == '') ? '0' : task[i]['unit']);

        // tire position
        sheet.getRangeByName('C${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('C${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('C${i + 2}').setText('0');
        sheet.getRangeByName('C${i + 2}').setText(
            (task[i]['position'].toString() == '')
                ? '0'
                : task[i]['position'].toString());

        // pressure
        try {
          sheet.getRangeByName('D${i + 2}').cellStyle.hAlign =
              HAlignType.center;
          sheet.getRangeByName('D${i + 2}').cellStyle.vAlign =
              VAlignType.center;
          sheet.getRangeByName('D${i + 2}').setText('0');
          sheet.getRangeByName('D${i + 2}').setText(
              (task[i]['pressure'] == '' || task[i]['pressure'] == null)
                  ? '0'
                  : task[i]['pressure'] ?? '0');
        } catch (e) {}

        try {
          //RTD 1
          // sheet.getRangeByName('G${i + 1}').merge();
          sheet.getRangeByName('E${i + 2}').setText('0');
          if (task[i]['rtd'] != '/') {
            final splitRtd = (task[i]['rtd'] as String).split('/');
            sheet.getRangeByName('E${i + 2}').cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByName('E${i + 2}').cellStyle.vAlign =
                VAlignType.center;
            sheet
                .getRangeByName('E${i + 2}')
                .setText((splitRtd[0] == '') ? '0' : splitRtd[0]);

            // //RTD 2
            // // sheet.getRangeByName('I${i + 4}').merge();
            // sheet.getRangeByName('H${i + 2}').cellStyle.hAlign =
            //     HAlignType.center;
            // sheet.getRangeByName('H${i + 2}').cellStyle.vAlign =
            //     VAlignType.center;
            // sheet.getRangeByName('H${i + 2}').setText(splitRtd[1]);
          } else {
            sheet.getRangeByName('E${i + 2}').cellStyle.hAlign =
                HAlignType.center;
            sheet.getRangeByName('E${i + 2}').cellStyle.vAlign =
                VAlignType.center;
            sheet.getRangeByName('E${i + 2}').setText('0');

            //RTD 2
            // sheet.getRangeByName('I${i + 4}').merge();
            // sheet.getRangeByName('H${i + 2}').cellStyle.hAlign =
            //     HAlignType.center;
            // sheet.getRangeByName('H${i + 2}').cellStyle.vAlign =
            //     VAlignType.center;
            // sheet.getRangeByName('H${i + 2}').setText('0');
          }
        } catch (e) {
          log('error rtd : $e');
        }

        // HM unit
        sheet.getRangeByName('F${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('F${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('F${i + 2}').setText('0');
        sheet.getRangeByName('F${i + 2}').setText(
            (task[i]['hm'] == null || task[i]['hm'] == '')
                ? '0'
                : (task[i]['hm']).toString() ?? '0');

        //REMARK
        sheet.getRangeByName('G${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('G${i + 2}').cellStyle.vAlign = VAlignType.center;
        // sheet.getRangeByName('G${i + 2}').setText(
        //     (task[i]['tire_damage'] is List<dynamic>)
        //         ? (task[i]['tire_damage'] as List<dynamic>).join('\n')
        //         : task[i]['tire_damage']);
        sheet.getRangeByName('G${i + 2}').setText('0');
        sheet.getRangeByName('G${i + 2}').setText(
            (task[i]['tire_damage'] is List<dynamic>)
                ? ((task[i]['tire_damage'] as List<dynamic>).isEmpty &&
                        task[i]['tire_damage'] == null)
                    ? 'Good'
                    : (task[i]['tire_damage'].length > 1)
                        ? task[i]['tire_damage'][1]
                        : 'Good'
                : task[i]['tire_damage'] ?? 'Good');

        // TIRE DAMAGE
        sheet.getRangeByName('L${i + 2}').merge();
        sheet.getRangeByName('L${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('L${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('L${i + 2}').setText('0');
        sheet
            .getRangeByName('L${i + 2}')
            .setText((task[i]['tire_damage'] is List<dynamic>)
                ? (task[i]['tire_damage'] as List<dynamic>).join('\n')
                : (task[i]['tire_damage'] == '')
                    ? '0'
                    : task[i]['tire_damage']);

        //ADJUSMNET PRESSURE
        sheet.getRangeByName('T${i + 4}:U${i + 4}').merge();
        sheet.getRangeByName('I${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('I${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('I${i + 2}').setText('0');
        sheet.getRangeByName('I${i + 2}').setText(
            (task[i]['adjusmentPressure'] == '' ||
                    task[i]['adjusmentPressure'] == null)
                ? '0'
                : task[i]['adjusmentPressure'] ?? '0');

        // IMAGE TIRE
        // IMAGE TIRE (ganti blok lama dengan ini)
        int columnBroken = 11;
        int rowIndex = i + 2;
        final urlImage = task[i]['images'];

        final cellName = 'H${i + 2}';
        // sheet.getRangeByName(cellName).setText('0'); // default

        try {
          if (urlImage != null && urlImage.isNotEmpty) {
            // Ambil gambar pertama saja
            final img = urlImage[0];

            if (img != null && img.toString().isNotEmpty) {
              Uint8List? bytes;

              final isUrl = img.toString().startsWith('http://') ||
                  img.toString().startsWith('https://');

              if (isUrl) {
                // download image dari URL
                log('img url: $img');
                final response = await http.get(Uri.parse(img));
                if (response.statusCode == 200) {
                  bytes = response.bodyBytes;
                } else {
                  log('Failed to download image, status: ${response.statusCode}');
                }
              } else {
                // coba read sebagai local file path
                final file = File(img);
                if (await file.exists()) {
                  bytes = await file.readAsBytes();
                } else {
                  log('Local image not found: $img');
                }
              }
              log('img bytes: $bytes');

              if (bytes != null && bytes.isNotEmpty) {
                final resizedImage = await resizeImage(bytes, 600, 600);

                final rowIndex = i + 2;
                final colIndex = 8;

                final range = sheet.getRangeByIndex(rowIndex, colIndex);

                // ⚠️ JANGAN kebesaran
                range.rowHeight = 120; // ± 160px
                range.columnWidth = 20; // ± 140px (INI PENTING)

                final picture = sheet.pictures.addStream(
                  rowIndex,
                  colIndex,
                  resizedImage,
                );

                // atur ukuran gambar
                picture.width = 110;
                picture.height = 110;

                // coba shrink sampai muat 1 cell
                // final resultB64 =
                //     await tryShrinkToOneCell(bytes, maxAllowed: 32000);

                // if (resultB64 != null) {
                //   // sukses: tulis ke 1 sel
                //   sheet.getRangeByName(cellName).cellStyle.hAlign =
                //       HAlignType.center;
                //   sheet.getRangeByName(cellName).cellStyle.vAlign =
                //       VAlignType.center;
                //   sheet.getRangeByName(cellName).setText(resultB64);
                //   sheet.getRangeByIndex(i + 2, columnBroken).setText('1');
                // } else {
                //   // gagal: fallback -> tulis URL atau marker agar backend tahu harus download
                //   sheet
                //       .getRangeByName(cellName)
                //       .setText(img.toString()); // tulis URL
                //   sheet.getRangeByIndex(i + 2, columnBroken).setText('0');
                // }
              } else {
                // jika tidak dapat bytes, tulis 0 (sudah default), log saja
                // sheet.getRangeByName(cellName).setText('0');
              }
            } else {
              // sheet.getRangeByName(cellName).setText('0');
            }
          } else {
            // sheet.getRangeByName(cellName).setText('0');
          }
        } catch (e, st) {
          log('Error processing image for row ${i + 2}: $e\n$st');
          // sheet.getRangeByName(cellName).setText('0');
        }

        // Location
        sheet.getRangeByName('K${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('K${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('K${i + 2}').setText('Default');
        sheet
            .getRangeByName('K${i + 2}')
            .setText((task[i]['pit'] == '') ? 'Default' : task[i]['pit']);

        // BROKEN COMPONENT
        sheet.getRangeByName('M1').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('M1').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('M${i + 2}').setText('0');
        sheet.getRangeByName('M${i + 2}').setText(
            (task[i]['condition'] == null ||
                    (task[i]['condition'] is List<dynamic> &&
                        (task[i]['condition'] as List<dynamic>).isEmpty))
                ? '0'
                : (task[i]['condition'] is List<dynamic>)
                    ? (task[i]['condition'] as List<dynamic>).join(', ')
                    : (task[i]['condition'] == '')
                        ? '0'
                        : task[i]['condition']);

        // SN
        // Location
        sheet.getRangeByName('N${i + 2}').cellStyle.hAlign = HAlignType.center;
        sheet.getRangeByName('N${i + 2}').cellStyle.vAlign = VAlignType.center;
        sheet.getRangeByName('N${i + 2}').setText('0');
        sheet.getRangeByName('N${i + 2}').setText(
            (task[i]['sn'] == '' || task[i]['sn'] == null)
                ? '0'
                : task[i]['sn']);
      }

      final List<int> bytes = workbook.saveAsStream();
      workbook.dispose();
      return bytes;

    case 'daily-check':
      final Workbook workbook = Workbook();
      final Worksheet sheet = workbook.worksheets[0];

      sheet.getRangeByName('A1').setText('Date');
      sheet.getRangeByName('B1').setText('Unit');
      sheet.getRangeByName('C1').setText('Pos');
      sheet.getRangeByName('D1').setText('Pressure');
      sheet.getRangeByName('E1').setText('Adj');
      sheet
          .getRangeByName('F1')
          .setText((daily?[0]['idSite'] == bmbhauling.idSite) ? 'KM' : 'HM');
      sheet.getRangeByName('G1').setText('Tire Damage');
      sheet.getRangeByName('G1').columnWidth = 25;
      sheet.getRangeByName('H1').setText('Location');
      sheet.getRangeByName('I1').setText('Rating');
      sheet.getRangeByName('J1').setText('Condition');
      sheet.getRangeByName('K1').setText('Size');
      sheet.getRangeByName('L1').setText('Tire Pressure Condition');
      sheet.getRangeByName('M1').setText('min_press');
      sheet.getRangeByName('N1').setText('max_press');
      sheet.getRangeByName('O1').setText('avg_press');
      sheet.getRangeByName('P1').setText('temp');
      if (daily?[0]['idSite'] == '33') {
        sheet.getRangeByName('Q1').setText('Tire Accessories');
      }

      // log('daily excel daily excel : $daily');
      log('json hauling : ${jsonEncode(daily)}');

      int rowIndex = 2;
      for (int i = 0; i < daily!.length; i++) {
        final unit = daily[i]['unit'];
        final posisi = daily[i]['posisi'] as List<dynamic>;

        for (int j = 0; j < posisi.length; j++) {
          // Format tanggal menjadi MM/dd/yyyy
          DateTime parse = DateTime.parse(daily[i]['tanggal']);
          String formattedDate = DateFormat('MM/dd/yyyy').format(parse);

          sheet.getRangeByName('A${rowIndex}').setText(formattedDate); // Date
          sheet.getRangeByName('B${rowIndex}').setText(unit); // Unit
          sheet.getRangeByName('C${rowIndex}').setText(posisi[j]['pos']); // Pos
          sheet.getRangeByName('D${rowIndex}').setText(
              (posisi[j]['pressure'] == '')
                  ? '0'
                  : posisi[j]['pressure']); // Pressure
          sheet.getRangeByName('E${rowIndex}').setText(
              (posisi[j]['adjusmentPressure'] == '')
                  ? '0'
                  : posisi[j]['adjusmentPressure']); // Adj

          // F = HM
          sheet
              .getRangeByName('F${rowIndex}')
              .setText(daily[i]['hm']?.toString() ?? '');

          // G = Tire Damage
          var lukaData = posisi[j]['luka'];
          String textToSet = '';
          if (lukaData is List) {
            textToSet = lukaData
                .where((element) =>
                    element != null && element.toString().isNotEmpty)
                .join('\n');
          } else if (lukaData is String) {
            textToSet = lukaData;
          }
          if (textToSet.isNotEmpty) {
            sheet.getRangeByName('G${rowIndex}').setText(textToSet);
          }

          // H = Location
          sheet.getRangeByName('H${rowIndex}').setText(daily[i]['pit']);

          // I = Rating
          sheet.getRangeByName('I${rowIndex}').setText(posisi[j]['rating']);

          // J = Condition
          sheet
              .getRangeByName('J${rowIndex}')
              .setText(daily[i]['unit_condition'] ?? '');

          // K = Size
          sheet
              .getRangeByName('K${rowIndex}')
              .setText(posisi[j]['tireSize'] ?? '');

          // L = Tire Pressure Condition
          sheet
              .getRangeByName('L${rowIndex}')
              .setText(posisi[j]['kondisi'] ?? '');

          // M = min_press
          sheet
              .getRangeByName('M${rowIndex}')
              .setText(posisi[j]['min_press'] ?? '');

          // N = max_press
          sheet
              .getRangeByName('N${rowIndex}')
              .setText(posisi[j]['max_press'] ?? '');

          // O = avg_press
          sheet
              .getRangeByName('O${rowIndex}')
              .setText(posisi[j]['avg_press'] ?? '');

          // P = temp
          sheet.getRangeByName('P${rowIndex}').setText(posisi[j]['temp'] ?? '');

          // Q = Tire Accessories (jika site 33)
          if (daily[i]['idSite'] == '33') {
            sheet.getRangeByName('Q${rowIndex}').setText(
                  posisi[j]['tireAccessories']
                      .map((acc) =>
                          '${acc['name']} (${acc['condition']} ${(acc['remark'] != '') ? ': ${acc['remark']}' : ''})')
                      .join('\n'),
                );
          }

          rowIndex++;
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
// Future<Uint8List> resizeImage(
//     Uint8List imageBytes, int targetWidth, int targetHeight) async {
//   img.Image image = img.decodeImage(imageBytes)!;

//   img.Image resizedImage =
//       img.copyResize(image, width: targetWidth, height: targetHeight);

//   Uint8List resizedBytes = Uint8List.fromList(img.encodePng(resizedImage));
//   return resizedBytes;
// }
Future<Uint8List> resizeImage(
  Uint8List imageBytes,
  int maxWidth,
  int maxHeight,
) async {
  final image = img.decodeImage(imageBytes);
  if (image == null) {
    throw Exception('Invalid image bytes');
  }

  // hitung ratio supaya tidak gepeng
  final ratioW = maxWidth / image.width;
  final ratioH = maxHeight / image.height;
  final ratio = ratioW < ratioH ? ratioW : ratioH;

  final newWidth = (image.width * ratio).round();
  final newHeight = (image.height * ratio).round();

  final resized = img.copyResize(
    image,
    width: newWidth,
    height: newHeight,
    interpolation: img.Interpolation.average,
  );

  // ⚠️ PAKAI JPEG (lebih aman di Excel)
  return Uint8List.fromList(
    img.encodeJpg(resized, quality: 80),
  );
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
