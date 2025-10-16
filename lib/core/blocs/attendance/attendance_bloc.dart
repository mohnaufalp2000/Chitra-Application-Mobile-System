import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import '../../services/local_database/attendance/attendance_entity.dart';
import '../../services/shared_preferences/shared_preferences.dart';
import '../../services/sheets/attendance_sheets.dart';
import '../../services/sheets/model_sheets/attendance.dart';
import '../../styles/color.dart';
import '../../utils/functions/functions.dart';
import '../../../main.dart';
import '../../../objectbox.g.dart';
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

    on<PresenceAttendanceEvent>((event, emit) async {
      emit(AttendancePresenceLoadingState());
      try {
        String id = await auth.currentUser!.uid;
        CollectionReference<Map<String, dynamic>> colPresence =
            users.doc(id).collection('presensi');

        QuerySnapshot<Map<String, dynamic>> snapPresence =
            await colPresence.get();

        DateTime now = DateTime.now();
        String todayDocId = DateFormat.yMd().format(now).replaceAll('/', '-');
        String yesterdayDocId = DateFormat.yMd()
            .format(now.subtract(Duration(days: 1)))
            .replaceAll('/', '-');

        // belum pernah absen sama sekali
        if (snapPresence.docs.length == 0) {
          final capturedCamera = await cameraPicture(event.context);
          final uploadedPicture =
              await uploadImage(File(capturedCamera), event.user['username']);

          {
            // input ke spreadsheet online absen masuk
            try {
              final id = await AttendanceSheetsAPI.getRowCount() + 1;
              log('attendance_row_count : ${await AttendanceSheetsAPI.getRowCount()}');
              log('attendance_tanggal : ${DateFormat('MM/dd/yyyy').format(now)}');
              log('attendance_masuk: ${DateFormat.Hms().format(DateTime.parse(now.toIso8601String()))}');
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
          }

          colPresence.doc(todayDocId).set({
            "date": now.toIso8601String(),
            "masuk": {
              "date": now.toIso8601String(),
              "image": uploadedPicture,
              "remarks": '',
            }
          });
        } else {
          DocumentSnapshot<Map<String, dynamic>> todayDoc =
              await colPresence.doc(todayDocId).get();
          // sudah pernah absen di hari yg sama
          if (todayDoc.exists == true) {
            Map<String, dynamic>? dataPresenceToday = todayDoc.data();

            if (dataPresenceToday!["keluar"] != null) {
              emit(AttendanceErrorState(isAlreadyPresence: true));
            } else {
              // absen keluar
              final capturedCamera = await cameraPicture(event.context);
              final uploadedPicture = await uploadImage(
                  File(capturedCamera), event.user['username']);

              {
                // input spreadsheet online absen keluar
                try {
                  final id = await AttendanceSheetsAPI.getSingleDataAttendance(
                      event.user['sn'], DateFormat('MM-dd-yyyy').format(now));

                  log('id absen keluar : $id');

                  await AttendanceSheetsAPI.updateAttendanceCell(
                      id: int.parse(id ?? ''),
                      key: 'Pulang',
                      value:
                          '${DateFormat.Hms().format(DateTime.parse(now.toIso8601String()))}');
                } catch (e) {
                  print('error spreadsheet di bloc keluar: $e');
                }
              }

              await colPresence.doc(todayDocId).update({
                "date": now.toIso8601String(),
                "keluar": {
                  "date": now.toIso8601String(),
                  "image": uploadedPicture,
                  "remarks": '',
                }
              });
            }
          } else {
            // absen masuk di hari lain
            final capturedCamera = await cameraPicture(event.context);
            final uploadedPicture =
                await uploadImage(File(capturedCamera), event.user['username']);

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

            await colPresence.doc(todayDocId).set({
              "date": now.toIso8601String(),
              "masuk": {
                "date": now.toIso8601String(),
                "image": uploadedPicture,
                "remarks": '',
              }
            });
          }
        }
        emit(AttendanceSuccessPresenceState());
      } catch (e) {
        log('error wah ${e.toString()}');
        emit(AttendanceErrorState());
      }
    });

    on<SelectShiftAttendanceEvent>((event, emit) async {
      updateManpowerShiftPreference(event.shift);
      emit(AttendanceSelectedShiftState(shift: event.shift));
    });

    on<SaveCsvPresenceEvent>((event, emit) async {
      try {
        // emit(AttendanceSaveCsvLoadingState());
        final id = Uuid();
        final file = await createFolderPath(id.v4(), 'attendance',
            username: event.username,
            sn: event.sn,
            date: event.date.toString());
        final bytes = await createExcel(
          'attendance',
          username: event.username,
          position: event.position,
          sn: event.sn,
          date: event.date,
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

Future<String> cameraPicture(BuildContext context) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image =
      await picker.pickImage(imageQuality: 30, source: ImageSource.camera);
  if (image != null) {
    print('image attendance ' + image.name);
    print('image attendance ' + image.name.split('.').last);
    print('image attendance ' + image.path);
    return image.path;
  }

  return '';
}

Future<String?> uploadImage(File capturedCamera, String username) async {
  final id = Uuid();
  final DateTime now = DateTime.now();
  String extension = capturedCamera.path.split('.').last;

  // Tentukan MIME type berdasarkan ekstensi
  String mimeType = 'image/jpeg'; // Default
  if (extension == 'png') {
    mimeType = 'image/png';
  } else if (extension == 'jpg' || extension == 'jpeg') {
    mimeType = 'image/jpeg';
  }

  final path = 'presence/${now.toIso8601String()}-$username}.$extension';
  if (capturedCamera != null) {
    final file = capturedCamera;

    final ref = FirebaseStorage.instance.ref().child(path);
    // final uploadTask = ref.putFile(file);
    final uploadTask = ref.putFile(
      capturedCamera,
      SettableMetadata(contentType: mimeType),
    );

    final snapshot = await uploadTask.whenComplete(() {});

    final urlDownload = await snapshot.ref.getDownloadURL();
    print('link gambar $urlDownload');

    return urlDownload;
  }

  return '';
}
