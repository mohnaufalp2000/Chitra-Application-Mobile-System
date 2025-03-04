import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/daily_press.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

        // Data 1
        List<Map<String, dynamic>> data1 = [];
        try {
          List<String> uniqueDay = dailyCheckConverted
              .map((e) => e.tanggal.split('T')[0])
              .toSet()
              .toList();

          final countCheckedTire = uniqueDay
              .map((day) => {
                    'tgl_daily': day,
                    'checked_tire': dailyCheckConverted
                        .where((daily) => daily.tanggal.split('T')[0] == day)
                        .fold(0,
                            (total, element) => total + element.posisi.length)
                  })
              .toList();

          final countLowPressureTire = uniqueDay
              .map((day) => {
                    'tgl_daily': day,
                    'low_pressure_tire': dailyCheckConverted
                        .where((daily) => daily.tanggal.split('T')[0] == day)
                        .fold(
                            0,
                            (total, element) =>
                                total +
                                element.posisi
                                    .where(
                                        (pos) => pos.kondisi == "Low Pressure")
                                    .length)
                  })
              .toList();

          data1 = countCheckedTire.asMap().entries.map((entry) {
            int index = entry.key;
            return {
              'target_daily': event.countAllTire,
              'tgl_daily': entry.value['tgl_daily'],
              'checked': entry.value['checked_tire'],
              'low': countLowPressureTire[index]['low_pressure_tire'],
              // 'id_site': dailyCheckConverted[0].idSite,
              'id_site': '3',
            };
          }).toList();
        } catch (e) {
          log('error data 1 : $e');
        }

        // Data 2
        List<Map<String, dynamic>> data2 = [];
        try {
          data2 = dailyCheckConverted
              .expand((daily) => daily.posisi
                  .map((pos) => {
                        "id_daily": pos.idDaily,
                        "id_unit_site": pos.idUnit,
                        "pos": pos.pos,
                        "inv": pos.idInventory,
                        "tanggal_daily": daily.tanggal.split('T')[0],
                        "press": pos.pressure,
                        "kondisi": pos.kondisi,
                        // 'id_site': dailyCheckConverted[0].idSite,
                        "id_site": "3",
                        "adj": "0"
                      })
                  .toList())
              .toList();
        } catch (e) {
          log('error data 2 : ${e.toString()}');
        }

        // Data 3
        List<Map<String, dynamic>> data3 = [];
        try {
          final now = DateTime.now();
          final startOfMonth =
              DateTime(now.year, now.month, 1); // Tanggal 1 di bulan ini
          final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59,
              59); // Tanggal terakhir bulan ini

          log('tanggal awal : ${startOfMonth}');
          log('tanggal akhir : ${endOfMonth}');

          QuerySnapshot snapshot = await firestore
              .collection('daily_pressure')
              .where('tanggal',
                  isGreaterThanOrEqualTo: startOfMonth.toIso8601String())
              .where('tanggal',
                  isLessThanOrEqualTo: endOfMonth.toIso8601String())
              .where('idSite',
                  isEqualTo: dailyCheckConverted[0].idSite) // Filter site
              .get(); // Ambil semua data dulu

          List<Map<String, dynamic>> firestoreData = snapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

          List<DailyPress> convertedData3 =
              firestoreData.map((e) => DailyPress.fromFirestore(e)).toList();

          final distinctData3 = Set<DailyPress>.from(convertedData3).toList();

          data3 = event.allUnit.map((e) {
            var filteredList =
                distinctData3.where((element) => element.unit == e.unitNumber);
            return {
              "id_daily_unit":
                  "${e.unitNumber}3${DateFormat('yyyy-MM').format(startOfMonth)}",
              "unit": e.unitNumber,
              "date": DateFormat('yyyy-MM').format(startOfMonth),
              "qty": filteredList.isEmpty ? 0 : filteredList.length,
              // 'site': dailyCheckConverted[0].idSite,
              "site": "3"
            };
          }).toList();
        } catch (e) {
          log('error data 3 $e');
        }

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
