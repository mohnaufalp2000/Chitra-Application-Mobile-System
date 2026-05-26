import 'dart:convert';
import 'dart:developer';

import 'package:bloc/bloc.dart';
import '../../services/api_service.dart';
import '../../services/model/daily_press.dart';
import '../../services/model/unit_tire.dart';
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
        log('all tire size post : ${event.allTireSize}');
        // all tire size post : {sizes: [24.00R35, 27.00R49, 20.5R25], sizeCount: {24.00R35: 210, 27.00R49: 138, 20.5R25: 30}}
        try {
          List<String> uniqueDay = dailyCheckConverted
              .map((e) => e.tanggal.split('T')[0])
              .toSet()
              .toList();
          final sizes = event.allTireSize['sizes'] as List<String>;
          final sizeCount =
              event.allTireSize['sizeCount'] as Map<String, dynamic>;

          List<Map<String, dynamic>> countCheckedTire = uniqueDay.map((day) {
            List<Map<String, dynamic>> checkedBySize = [];

            for (var size in sizes) {
              int count = dailyCheckConverted
                  .where((daily) => daily.tanggal.split('T')[0] == day)
                  .fold(0, (total, element) {
                return total +
                    element.posisi.where((pos) => pos.size == size).length;
              });

              checkedBySize.add({
                'size': size,
                'checked_tire': count,
              });
            }

            return {
              'tgl_daily': day,
              'sizes': checkedBySize,
            };
          }).toList();

          List<Map<String, dynamic>> countLowPressureTire =
              uniqueDay.map((day) {
            List<Map<String, dynamic>> lowPressureBySize = [];

            for (var size in sizes) {
              int count = dailyCheckConverted
                  .where((daily) => daily.tanggal.split('T')[0] == day)
                  .fold(0, (total, element) {
                return total +
                    element.posisi
                        .where((pos) =>
                            pos.size == size && pos.kondisi == "Low Pressure")
                        .length;
              });

              lowPressureBySize.add({
                'size': size,
                'low_pressure_tire': count,
              });
            }

            return {
              'tgl_daily': day,
              'sizes': lowPressureBySize,
            };
          }).toList();

          log('count checked tire : ${countCheckedTire}');
          // [{tgl_daily: 2025-03-07, sizes: [{size: 24.00R35, checked_tire: 114}, {size: 27.00R49, checked_tire: 66}, {size: 20.5R25, checked_tire: 6}]}]
          log('count low tire : ${countLowPressureTire}');
          // [{tgl_daily: 2025-03-07, sizes: [{size: 24.00R35, low_pressure_tire: 6}, {size: 27.00R49, low_pressure_tire: 8}, {size: 20.5R25, low_pressure_tire: 0}]}]

          for (int i = 0; i < countCheckedTire.length; i++) {
            String tglDaily = countCheckedTire[i]['tgl_daily'];

            for (var sizeData in countCheckedTire[i]['sizes']) {
              String size = sizeData['size'];
              int checkedTire = sizeData['checked_tire'];

              int lowPressure = countLowPressureTire[i]['sizes'].firstWhere(
                  (low) => low['size'] == size,
                  orElse: () => {'low_pressure_tire': 0})['low_pressure_tire'];

              data1.add({
                'target_daily':
                    sizeCount[size].toString(), // Ambil target dari sizeCount
                'tgl_daily': tglDaily,
                'checked': checkedTire.toString(),
                'low': lowPressure.toString(),
                'id_site': dailyCheckConverted[0].idSite.toString(),
                // 'id_site': '5',
                'size': size,
              });
            }
          }
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
                        // "tanggal_daily": daily.tanggal.split('T')[0],
                        "tanggal_daily": "${DateTime.parse(daily.tanggal).year}-"
                            "${DateTime.parse(daily.tanggal).month.toString().padLeft(2, '0')}-"
                            "${DateTime.parse(daily.tanggal).day.toString().padLeft(2, '0')} "
                            "${DateTime.parse(daily.tanggal).hour.toString().padLeft(2, '0')}:"
                            "${DateTime.parse(daily.tanggal).minute.toString().padLeft(2, '0')}:"
                            "${DateTime.parse(daily.tanggal).second.toString().padLeft(2, '0')}",
                        "press": pos.pressure,
                        "kondisi": pos.kondisi,
                        'id_site': dailyCheckConverted[0].idSite,
                        // "id_site": "5",
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
          log('data 3 converted data : $convertedData3');

          final distinctData3 = Set<DailyPress>.from(convertedData3).toList();

          log('data 3 distinct data : $convertedData3');

          data3 = event.allUnit.map((e) {
            var filteredList =
                distinctData3.where((element) => element.unit == e.unitNumber);

            log('data 3 filtered data : $filteredList');
            log('data 3 filtered data length : ${filteredList.length}');

            return {
              "id_daily_unit":
                  "${e.unitNumber}3${DateFormat('yyyy-MM').format(startOfMonth)}",
              "unit": e.unitNumber,
              "date": DateFormat('yyyy-MM').format(startOfMonth),
              "qty": filteredList.isEmpty ? 0 : filteredList.length,
              // 'site': dailyCheckConverted[0].idSite,
              "site": dailyCheckConverted[0].idSite,
            };
          }).toList();
        } catch (e) {
          log('error data 3 $e');
        }

        // log('jumlah data 2 id null : ${data2.where((e) => e['id_daily'] == null || e['id_unit_site'] == null || e['inv'] == null).length}');

        log('data multiple multiple : ${jsonEncode({
              "data1": data1,
              "data2": data2,
              "data3": data3,
            })}');

        // JANGAN LUPA RUBAH ID SITE KE AKTUAL KALAU UDAH SELESAI
        await ApiService.postDailyCheckPressure(data1, data2, data3);

        emit(DailyCheckPostSuccessState(message: "Data berhasil dikirim!"));
      } catch (e) {
        emit(DailyCheckPostErrorState(error: e.toString()));
      }
    });
  }
}
