import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/local_database/attendance/attendance_entity.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/services/sheets/attendance_sheets.dart';
import 'package:camos/core/services/sheets/model_sheets/attendance.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:image/image.dart' as img;
import 'package:uuid/uuid.dart';

part 'attendance_event.dart';
part 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  AttendanceBloc() : super(AttendanceInitial()) {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore fireStore = FirebaseFirestore.instance;
    CollectionReference users = fireStore.collection('users');
    final Box<AttendanceEntity> attendanceBox = store.box<AttendanceEntity>();

    on<PresenceAttendanceEvent>((event, emit) async {
      // emit(AttendancePresenceLoadingState());
      try {
        DateTime now = DateTime.now();
        String todayDocId = DateFormat.yMd().format(now).replaceAll('/', '-');
        log('jam masuk $todayDocId');
        String yesterdayDocId = DateFormat.yMd()
            .format(now.subtract(Duration(days: 1)))
            .replaceAll('/', '-');
        // change image
        // final String imgString = base64Encode(event.image);

        switch (event.selectedShift) {
          case 'morning':
            // final capturedCamera = await cameraPicture(event.context);
            // log('gambar absen : $capturedCamera');
            if (attendanceBox.getAll().isEmpty ||
                attendanceBox.getAll().length == 0) {
              // final uploadedPicture = await uploadImage(capturedCamera);

              // attendanceBox.put(AttendanceEntity(
              //     date: now.toIso8601String(),
              //     masuk: now.toIso8601String(),
              //     masukImage: imgString));'

              attendanceBox.put(AttendanceEntity(
                  date: now.toIso8601String(),
                  masuk: now.toIso8601String(),
                  masukImage: await ImagePicker()
                      .pickImage(imageQuality: 30, source: ImageSource.camera)
                      .then((value) async {
                    Uint8List bytes = await value!.readAsBytes();
                    img.Image originalImage = img.decodeImage(bytes)!;
                    int textPadding = 200;
                    int textPosX = originalImage.width - (textPadding + 550);
                    int textPosY = originalImage.height - textPadding;
                    img.drawString(
                        originalImage,
                        x: textPosX,
                        y: textPosY,
                        DateFormat('EEEE, d MMMM yyyy HH:mm').format(now),
                        font: img.arial48);
                    Uint8List modifiedBytes =
                        Uint8List.fromList(img.encodeJpg(originalImage));
                    String imgString = base64Encode(modifiedBytes);

                    return imgString;
                  })));

              try {
                final id = await AttendanceSheetsAPI.getRowCount() + 1;
                final user = AttendanceSheetsModel(
                    namaKaryawan: '${event.user['username'] ?? ''}',
                    sn: '${event.user['sn'] ?? ''}',
                    tanggal: '${DateFormat('MM/dd/yyyy').format(now)}',
                    masuk:
                        '${DateFormat.Hms().format(DateTime.parse(now.toIso8601String()))}',
                    pulang: '',
                    keteranganMasuk: '',
                    keteranganPulang: '');
                final newUser = user.copy(id: id);

                await AttendanceSheetsAPI.insertAttendanceSheet(
                    [newUser.toJson()]);
              } catch (e) {
                print('error spreadsheet di bloc : $e');
              }
            } else {
              final tmpDate = DateFormat('MM-dd-yyyy').parse(todayDocId);
              String formattedDate = DateFormat('yyyy-MM-dd').format(tmpDate);
              String formattedDateForSpreadsheet =
                  DateFormat('dd-MM-yyyy').format(tmpDate);
              final isPresenceToday = attendanceBox
                  .query(AttendanceEntity_.date
                      .contains(formattedDate, caseSensitive: false))
                  .build()
                  .findFirst();
              log('absen masuk : ${isPresenceToday}');
              log('waktu masuk : $formattedDate');
              // sudah pernah absen di hari yg sama
              if (isPresenceToday != null) {
                if (isPresenceToday.keluar != '' ||
                    isPresenceToday.keluar.isNotEmpty) {
                  emit(AttendanceErrorState(isAlreadyPresence: true));
                } else {
                  log('belum absen keluar : 3');

                  isPresenceToday.keluar = now.toIso8601String();
                  // isPresenceToday.keluarImage = imgString;
                  isPresenceToday.keluarImage = await ImagePicker()
                      .pickImage(imageQuality: 30, source: ImageSource.camera)
                      .then((value) async {
                    Uint8List bytes = await value!.readAsBytes();
                    img.Image originalImage = img.decodeImage(bytes)!;

                    int textPadding = 200;
                    int textPosX = originalImage.width - (textPadding + 350);
                    int textPosY = originalImage.height - textPadding;
                    img.drawString(
                        originalImage,
                        x: textPosX,
                        y: textPosY,
                        DateFormat('EEEE, d MMMM yyyy').format(now),
                        font: img.arial48);
                    Uint8List modifiedBytes =
                        Uint8List.fromList(img.encodeJpg(originalImage));
                    String imgString = base64Encode(modifiedBytes);

                    return imgString;
                  });
                  attendanceBox.put(isPresenceToday);
                  try {
                    print('bisa 1');
                    final id =
                        await AttendanceSheetsAPI.getSingleDataAttendance(
                            event.user['sn'],
                            DateFormat('MM-dd-yyyy').format(now));
                    print(
                        'bisa 2 : ${DateFormat('MM-dd-yyyy').format(now)} | ${event.user['username']} | id : $id');
                    await AttendanceSheetsAPI.updateAttendanceCell(
                        id: int.parse(id ?? ''),
                        key: 'Pulang',
                        value:
                            '${DateFormat.Hms().format(DateTime.parse(now.toIso8601String()))}');
                    print('bisa 3');
                  } catch (e) {
                    print('error spreadsheet di bloc keluar: $e');
                  }
                }
              } else {
                log('sudah absen keluar : 4');
                // attendanceBox.put(AttendanceEntity(
                //     date: now.toIso8601String(),
                //     masuk: now.toIso8601String(),
                //     masukImage: imgString));
                attendanceBox.put(AttendanceEntity(
                    date: now.toIso8601String(),
                    masuk: now.toIso8601String(),
                    masukImage: await ImagePicker()
                        .pickImage(imageQuality: 30, source: ImageSource.camera)
                        .then((value) async {
                      Uint8List bytes = await value!.readAsBytes();
                      img.Image originalImage = img.decodeImage(bytes)!;
                      int textPadding = 200;
                      int textPosX = originalImage.width - (textPadding + 350);
                      int textPosY = originalImage.height - textPadding;
                      img.drawString(
                          originalImage,
                          x: textPosX,
                          y: textPosY,
                          DateFormat('EEEE, d MMMM yyyy').format(now),
                          font: img.arial48);
                      Uint8List modifiedBytes =
                          Uint8List.fromList(img.encodeJpg(originalImage));
                      String imgString = base64Encode(modifiedBytes);

                      return imgString;
                    })));
                try {
                  final id = await AttendanceSheetsAPI.getRowCount() + 1;
                  final user = AttendanceSheetsModel(
                      namaKaryawan: '${event.user['username'] ?? ''}',
                      sn: '${event.user['sn'] ?? ''}',
                      tanggal: '${DateFormat('MM/dd/yyyy').format(now)}',
                      masuk:
                          '${DateFormat.Hms().format(DateTime.parse(now.toIso8601String()))}',
                      pulang: '',
                      keteranganMasuk: '',
                      keteranganPulang: '');
                  final newUser = user.copy(id: id);

                  await AttendanceSheetsAPI.insertAttendanceSheet(
                      [newUser.toJson()]);
                } catch (e) {
                  print('gabisa cuy');
                  print('error spreadsheet di bloc : $e');
                }
              }
            }
            break;
          case 'night':
            if (attendanceBox.getAll().isEmpty ||
                attendanceBox.getAll().length == 0) {
              log('siji');
              // final capturedCamera = await cameraPicture(event.context);
              // final uploadedPicture = await uploadImage(capturedCamera);

              attendanceBox.put(AttendanceEntity(
                date: now.toIso8601String(),
                masuk: now.toIso8601String(),
              ));
            } else {
              log('loro');
              final tmpDate = DateFormat('MM-dd-yyyy').parse(todayDocId);
              String formattedDate = DateFormat('yyyy-MM-dd').format(tmpDate);
              final isPresenceToday = attendanceBox
                  .query(AttendanceEntity_.date.startsWith(formattedDate))
                  .build()
                  .findFirst();
              // sudah pernah absen di hari yg sama
              if (isPresenceToday != null) {
                log('telu');
                if (isPresenceToday.keluar != '') {
                  log('papat');
                  emit(AttendanceErrorState(isAlreadyPresence: true));
                } else {
                  log('limo');
                  log('belum absen keluar : 3');

                  isPresenceToday.keluar = now.toIso8601String();
                  attendanceBox.put(isPresenceToday);
                }
              } else {
                log('enem');
                final tmpDate = DateFormat('MM-dd-yyyy').parse(yesterdayDocId);
                String formattedDate = DateFormat('yyyy-MM-dd').format(tmpDate);
                final isPresenceYesterday = attendanceBox
                    .query(AttendanceEntity_.date.contains(formattedDate))
                    .build()
                    .findFirst();
                log(isPresenceYesterday.toString());
                if (isPresenceYesterday != '' || isPresenceYesterday != null) {
                  log('pitu');
                  if (isPresenceYesterday!.keluar != '') {
                    log('wolu');
                    TimeOfDay startTime =
                        TimeOfDay(hour: 16, minute: 0); // 16:00
                    DateTime startTimeToday = DateTime(
                        DateTime.now().year,
                        DateTime.now().month,
                        DateTime.now().day,
                        startTime.hour,
                        startTime.minute);
                    if (DateTime.now().isAfter(startTimeToday)) {
                      log('songo');
                      // final capturedCamera = await cameraPicture(event.context);
                      // final uploadedPicture = await uploadImage(capturedCamera);

                      attendanceBox.put(AttendanceEntity(
                        date: now.toIso8601String(),
                        masuk: now.toIso8601String(),
                      ));
                      emit(AttendanceErrorState(isAlreadyPresence: false));
                    } else {
                      log('sepuluh');
                      emit(AttendanceErrorState(isAlreadyPresence: true));
                    }
                  } else {
                    log('sewelas');
                    isPresenceYesterday.keluar = now.toIso8601String();
                    attendanceBox.put(isPresenceYesterday);
                  }
                } else {
                  log('rolas');
                  attendanceBox.put(AttendanceEntity(
                    date: now.toIso8601String(),
                    masuk: now.toIso8601String(),
                  ));
                }
              }
            }
            break;
        }
        emit(AttendanceSuccessPresenceState());
      } catch (e) {
        log('error wah ${e.toString()}');
        emit(AttendanceErrorState(isAlreadyPresence: false));
      }
    });

    // on<PresenceAttendanceEvent>((event, emit) async {
    //   // emit(AttendancePresenceLoadingState());
    //   try {
    //     String id = await auth.currentUser!.uid;
    //     CollectionReference<Map<String, dynamic>> colPresence =
    //         users.doc(id).collection('presensi');

    //     QuerySnapshot<Map<String, dynamic>> snapPresence =
    //         await colPresence.get();

    //     DateTime now = DateTime.now();
    //     String todayDocId = DateFormat.yMd().format(now).replaceAll('/', '-');
    //     String yesterdayDocId = DateFormat.yMd()
    //         .format(now.subtract(Duration(days: 1)))
    //         .replaceAll('/', '-');

    //     switch (event.selectedShift) {
    //       case 'morning':
    //         // belum pernah absen sama sekali
    //         if (snapPresence.docs.length == 0) {
    //           final capturedCamera = await cameraPicture(event.context);
    //           final uploadedPicture = await uploadImage(capturedCamera);

    //           colPresence.doc(todayDocId).set({
    //             "date": now.toIso8601String(),
    //             "masuk": {
    //               "date": now.toIso8601String(),
    //               "image": uploadedPicture,
    //             }
    //           });
    //         } else {
    //           DocumentSnapshot<Map<String, dynamic>> todayDoc =
    //               await colPresence.doc(todayDocId).get();
    //           // sudah pernah absen di hari yg sama
    //           if (todayDoc.exists == true) {
    //             Map<String, dynamic>? dataPresenceToday = todayDoc.data();

    //             if (dataPresenceToday!["keluar"] != null) {
    //               emit(AttendanceErrorState(isAlreadyPresence: true));
    //             } else {
    //               // absen keluar
    //               final capturedCamera = await cameraPicture(event.context);
    //               final uploadedPicture = await uploadImage(capturedCamera);

    //               await colPresence.doc(todayDocId).update({
    //                 "date": now.toIso8601String(),
    //                 "keluar": {
    //                   "date": now.toIso8601String(),
    //                   "image": uploadedPicture,
    //                 }
    //               });
    //             }
    //           } else {
    //             // absen masuk di hari lain
    //             final capturedCamera = await cameraPicture(event.context);
    //             final uploadedPicture = await uploadImage(capturedCamera);

    //             await colPresence.doc(todayDocId).set({
    //               "date": now.toIso8601String(),
    //               "masuk": {
    //                 "date": now.toIso8601String(),
    //                 "image": uploadedPicture,
    //               }
    //             });
    //           }
    //         }
    //         break;
    //       case 'night':
    //         if (snapPresence.docs.length == 0) {
    //           final capturedCamera = await cameraPicture(event.context);
    //           final uploadedPicture = await uploadImage(capturedCamera);

    //           colPresence.doc(todayDocId).set({
    //             "date": now.toIso8601String(),
    //             "masuk": {
    //               "date": now.toIso8601String(),
    //               "image": uploadedPicture,
    //             }
    //           });
    //         } else {
    //           DocumentSnapshot<Map<String, dynamic>> todayDoc =
    //               await colPresence.doc(todayDocId).get();

    //           // sudah pernah absen di hari yg sama
    //           if (todayDoc.exists == true) {
    //             Map<String, dynamic>? dataPresenceToday = todayDoc.data();

    //             if (dataPresenceToday!["keluar"] != null) {
    //               emit(AttendanceErrorState(isAlreadyPresence: true));
    //             } else {
    //               // absen keluar
    //               final capturedCamera = await cameraPicture(event.context);
    //               final uploadedPicture = await uploadImage(capturedCamera);

    //               await colPresence.doc(todayDocId).update({
    //                 "date": now.toIso8601String(),
    //                 "keluar": {
    //                   "date": now.toIso8601String(),
    //                   "image": uploadedPicture,
    //                 }
    //               });
    //             }
    //           } else {
    //             // absen masuk di hari lain
    //             DocumentSnapshot<Map<String, dynamic>> yesterdayDoc =
    //                 await colPresence.doc(yesterdayDocId).get();

    //             if (yesterdayDoc.exists == true) {
    //               Map<String, dynamic>? dataPresenceYesterday =
    //                   yesterdayDoc.data();

    //               if (dataPresenceYesterday!["keluar"] != null) {
    //                 TimeOfDay startTime =
    //                     TimeOfDay(hour: 16, minute: 0); // 16:00
    //                 DateTime startTimeToday = DateTime(
    //                     DateTime.now().year,
    //                     DateTime.now().month,
    //                     DateTime.now().day,
    //                     startTime.hour,
    //                     startTime.minute);
    //                 if (DateTime.now().isAfter(startTimeToday)) {
    //                   final capturedCamera = await cameraPicture(event.context);
    //                   final uploadedPicture = await uploadImage(capturedCamera);

    //                   await colPresence.doc(todayDocId).set({
    //                     "date": now.toIso8601String(),
    //                     "masuk": {
    //                       "date": now.toIso8601String(),
    //                       "image": uploadedPicture,
    //                     }
    //                   });
    //                   emit(AttendanceErrorState(isAlreadyPresence: false));
    //                 } else {
    //                   emit(AttendanceErrorState(isAlreadyPresence: true));
    //                 }
    //               } else {
    //                 // absen keluar
    //                 final capturedCamera = await cameraPicture(event.context);
    //                 final uploadedPicture = await uploadImage(capturedCamera);

    //                 await colPresence.doc(yesterdayDocId).update({
    //                   "date": now.toIso8601String(),
    //                   "keluar": {
    //                     "date": now.toIso8601String(),
    //                     "image": uploadedPicture,
    //                   }
    //                 });
    //               }
    //             } else {
    //               print('cek selected shift ' + yesterdayDoc.exists.toString());

    //               final capturedCamera = await cameraPicture(event.context);
    //               final uploadedPicture = await uploadImage(capturedCamera);

    //               await colPresence.doc(todayDocId).set({
    //                 "date": now.toIso8601String(),
    //                 "masuk": {
    //                   "date": now.toIso8601String(),
    //                   "image": uploadedPicture,
    //                 }
    //               });
    //             }
    //           }
    //         }
    //         break;
    //     }
    //     emit(AttendanceSuccessPresenceState());
    //   } catch (e) {
    //     log('error wah ${e.toString()}');
    //     emit(AttendanceErrorState());
    //   }
    // });

    on<SelectShiftAttendanceEvent>((event, emit) async {
      updateManpowerShiftPreference(event.shift);
      emit(AttendanceSelectedShiftState(shift: event.shift));
    });

    // on<SaveCsvAttendanceEvent>((event, emit) async {
    //   try {
    //     emit(AttendanceSaveCsvLoadingState());
    //     final id = Uuid();
    //     final file = await createFolderPath(id.v4(), 'attendance');
    //     final bytes = await createExcel(
    //       'attendance',
    //       username: event.username,
    //       position: event.position,
    //       sn: event.sn,
    //       presence: event.presence,
    //       site: event.site,
    //     );
    //     await file.writeAsBytes(bytes, flush: true);
    //     final result = await OpenFile.open(file.path);

    //     if (result.type == ResultType.done) {
    //       print('File berhasil dibuka');
    //     } else {
    //       print(result.message);
    //       if (result.type == ResultType.noAppToOpen) {
    //         openPlayStore('attendance');
    //       }
    //     }
    //     emit(AttendanceSuccessSaveCsvState());
    //   } catch (e) {
    //     emit(AttendanceErrorState());
    //   }
    // });

    on<SaveCsvPresenceEvent>((event, emit) async {
      try {
        // emit(AttendanceSaveCsvLoadingState());
        final id = Uuid();
        final file = await createFolderPath(id.v4(), 'attendance',
            username: event.username,
            sn: event.sn,
            date:
                '${DateFormat('MMMM').format(DateTime.now())} ${DateTime.now().year}');
        final bytes = await createExcel(
          'attendance',
          username: event.username,
          position: event.position,
          sn: event.sn,
          presence: event.presence,
          site: event.site,
        );
        await file.writeAsBytes(bytes, flush: true);
        final result = await OpenFile.open(file.path);

        if (result.type == ResultType.done) {
          print('File berhasil dibuka');
        } else {
          print(result.message);
          log(result.message);
          if (result.type == ResultType.noAppToOpen) {
            openPlayStore('attendance');
          }
        }
        // emit(AttendanceSuccessSaveCsvState());
      } catch (e) {
        // emit(AttendanceErrorState());
      }
    });
  }
}

// Future<File> cameraPicture(BuildContext context) async {
//   final ImagePicker picker = ImagePicker();
//   final pickedImage =
//       await picker.getImage(imageQuality: 30, source: ImageSource.camera);

//   if (pickedImage != null) {
//     // menambahkan timestamp di foto
//     // img.Image? image =
//     //     img.decodeImage(File(pickedImage.path).readAsBytesSync());

//     // String formattedDate = DateTime.now().toString();
//     // int x = 10;
//     // int y = 10;
//     // img.BitmapFont customFont = img.arial48;
//     // customFont.bold = true;

//     // img.drawString(image!, formattedDate, font: customFont, x: x, y: y);

//     // File modifiedImage = File(pickedImage.path);
//     // modifiedImage.writeAsBytesSync(img.encodePng(image));

//     return File(pickedImage.path);
//   }

//   return File('');
// }

Future<String> cameraPicture(BuildContext context) async {
  final ImagePicker picker = ImagePicker();
  picker
      .pickImage(imageQuality: 30, source: ImageSource.camera)
      .then((value) async {
    Uint8List bytes = await value!.readAsBytes();
    String imgString = base64Encode(bytes);
    return imgString;
  });
  return '';
}

Future<String?> uploadImage(File capturedCamera) async {
  final id = Uuid();
  final path = 'presence/${id.v4()}';
  if (capturedCamera != null) {
    final file = capturedCamera;

    final ref = FirebaseStorage.instance.ref().child(path);
    final uploadTask = ref.putFile(file);

    final snapshot = await uploadTask.whenComplete(() {});

    final urlDownload = await snapshot.ref.getDownloadURL();
    print('link gambar $urlDownload');

    return urlDownload;
  }

  return '';
}
