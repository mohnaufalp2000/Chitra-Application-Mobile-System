import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/daily_press.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'daily_check_post_event.dart';
part 'daily_check_post_state.dart';

class DailyCheckPostBloc
    extends Bloc<DailyCheckPostEvent, DailyCheckPostState> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  DailyCheckPostBloc() : super(DailyCheckPostInitial()) {
    on<DailyCheckPostEvent>((event, emit) async {
      // emit(DailyCheckPostLoadingState());

      try {
        log('unit hohohoho');

        final data = event.dailyCheck;

        List<DailyPress> dailyCheckConverted =
            data.map((e) => DailyPress.fromFirestore(e)).toList();

        // log('daily check converted : $dailyCheckConverted');
        List<String> uniqueDay =
            dailyCheckConverted.map((e) => e.hari).toSet().toList();

        final countCheckedTire = uniqueDay
            .map((day) => {
                  'tgl_daily': day,
                  'checked_tire': dailyCheckConverted
                      .where((daily) => daily.hari == day)
                      .fold(
                          0, (total, element) => total + element.posisi.length)
                })
            .toList();

        final countLowPressureTire = uniqueDay
            .map((day) => {
                  'tgl_daily': day,
                  'low_pressure_tire': dailyCheckConverted
                      .where((daily) => daily.hari == day)
                      .fold(
                          0,
                          (total, element) =>
                              total +
                              element.posisi
                                  .where((pos) => pos.kondisi == "Low Pressure")
                                  .length)
                })
            .toList();

        // Data 1
        final data1 = countCheckedTire.asMap().entries.map((entry) {
          int index = entry.key;
          return {
            'target_daily': event.countAllTire,
            'tgl_daily': entry.value['tgl_daily'],
            'checked': entry.value['checked_tire'],
            'low': countLowPressureTire[index]['low_pressure_tire'],
            // 'id_site': dailyCheckConverted[0].idSite,
            'id_site': '2',
          };
        }).toList();

        // Data 2
        final data2 = dailyCheckConverted
            .expand((daily) => daily.posisi
                .map((pos) => {
                      "id_daily": pos.idDaily,
                      "id_unit_site": pos.idUnit,
                      "pos": pos.pos,
                      "inv": pos.idInventory,
                      "tanggal_daily": daily.hari,
                      "press": pos.pressure,
                      "kondisi": pos.kondisi,
                      "id_site": "2",
                      "adj": "0"
                    })
                .toList())
            .toList();

        // Data 3

        final Set<String> availableMonths = dailyCheckConverted
            .map((daily) => daily.hari.split('-').sublist(0, 2).join('-'))
            .toSet();

        QuerySnapshot snapshot = await firestore
            .collection('daily_pressure')
            .where('idSite',
                isEqualTo: dailyCheckConverted[0].idSite) // Filter site
            .get(); // Ambil semua data dulu

        List<Map<String, dynamic>> firestoreData = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();

        List<DailyPress> convertedData3 =
            firestoreData.map((e) => DailyPress.fromFirestore(e)).toList();

        final distinctData3 = Set<DailyPress>.from(convertedData3).toList();

        final data3 = event.allUnit.expand((unit) {
          return availableMonths.map((month) {
            int count = distinctData3
                .where((data) =>
                    data.unit == unit.unitNumber &&
                    (data.tanggal).startsWith(month))
                .length;

            return {
              "id_daily_unit": "${unit.unitNumber}2$month",
              "unit": unit.unitNumber,
              "date": month,
              // "qty": dailyCheckConverted
              //     .where((daily) =>
              //         daily.unit == unit.unitNumber &&
              //         daily.hari.startsWith(
              //             month)) // Pastikan unit cocok dan di bulan yang benar
              //     .length,
              "qty": count,
              "site": "2"
            };
          });
        }).toList();

        log('data multiple multiple : ${jsonEncode({
              "data1": data1,
              "data2": data2,
              "data3": data3,
            })}');

        // JANGAN LUPA RUBAH ID SITE KE AKTUAL KALAU UDAH SELESAI
        // await ApiService.postDailyCheckPressure(data1, data2, data3);

        emit(DailyCheckPostSuccessState(message: "Data berhasil dikirim!"));
      } catch (e) {
        emit(DailyCheckPostErrorState(error: e.toString()));
      }
    });
  }
}
