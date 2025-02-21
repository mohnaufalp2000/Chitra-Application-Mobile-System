import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/daily_press.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:equatable/equatable.dart';

part 'daily_check_post_event.dart';
part 'daily_check_post_state.dart';

class DailyCheckPostBloc
    extends Bloc<DailyCheckPostEvent, DailyCheckPostState> {
  DailyCheckPostBloc() : super(DailyCheckPostInitial()) {
    on<DailyCheckPostEvent>((event, emit) async {
      // emit(DailyCheckPostLoadingState());

      try {
        log('unit hohohoho');

        final data = event.dailyCheck;

        List<DailyPress> dailyCheckConverted =
            data.map((e) => DailyPress.fromFirestore(e)).toList();

        // log('daily check converted : $dailyCheckConverted');

        switch (event.typeSend) {
          case 'single':
            final countCheckedTire = dailyCheckConverted.fold(
                0, (sum, item) => sum + item.posisi.length);

            final countLowPressureTire = dailyCheckConverted.fold(
                0,
                (sum, item) =>
                    sum +
                    item.posisi
                        .where((pos) => pos.kondisi == "Low Pressure")
                        .length);

            // Data 1
            final summaryData = {
              'target_daily': event.countAllTire,
              'checked': countCheckedTire,
              'low': countLowPressureTire,
            };

            // Data 3
            final unitData = event.allUnit.map((unit) {
              return {
                "id_daily_unit":
                    "${unit.unitNumber}2${dailyCheckConverted[0].hari.split('-').sublist(0, 2).join('-')}",
                "unit": unit.unitNumber,
                "date": dailyCheckConverted[0]
                    .hari
                    .split('-')
                    .sublist(0, 2)
                    .join('-'),
                "qty": dailyCheckConverted
                    .where((daily) => daily.unit == unit.unitNumber)
                    .length,
                "site": "2"
              };
            }).toList();

            // await ApiService.postDailyCheckPressure(
            //     dailyCheckConverted, summaryData, unitData);
            break;

          case 'multiple':
            List<DailyPress> dailyCheckConverted =
                data.map((e) => DailyPress.fromFirestore(e)).toList();
            List<String> uniqueDay =
                dailyCheckConverted.map((e) => e.hari).toSet().toList();

            final countCheckedTire = uniqueDay
                .map((day) => {
                      'tgl_daily': day,
                      'checked_tire': dailyCheckConverted
                          .where((daily) => daily.hari == day)
                          .fold(0,
                              (total, element) => total + element.posisi.length)
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
                                      .where((pos) =>
                                          pos.kondisi == "Low Pressure")
                                      .length)
                    })
                .toList();

            // Data 1
            final summaryData = countCheckedTire.asMap().entries.map((entry) {
              int index = entry.key;
              return {
                'target_daily': event.countAllTire,
                'tgl_daily': entry.value['tgl_daily'],
                'checked': entry.value['checked_tire'],
                'low': countLowPressureTire[index]['low_pressure_tire'],
                'id_site': dailyCheckConverted[0].idSite,
              };
            }).toList();

            // Data 3
            final Set<String> availableMonths = dailyCheckConverted
                .map((daily) => daily.hari.split('-').sublist(0, 2).join('-'))
                .toSet(); // M

            // final unitData = event.allUnit.map((unit) {
            //   return {
            //     "id_daily_unit":
            //         "${unit.unitNumber}2${dailyCheckConverted[0].hari.split('-').sublist(0, 2).join('-')}",
            //     "unit": unit.unitNumber,
            //     "date": dailyCheckConverted[0]
            //         .hari
            //         .split('-')
            //         .sublist(0, 2)
            //         .join('-'),
            //     "qty": dailyCheckConverted
            //         .where((daily) => daily.unit == unit.unitNumber)
            //         .length,
            //     "site": "2"
            //   };
            // }).toList();
            final unitData = event.allUnit.expand((unit) {
              return availableMonths.map((month) {
                return {
                  "id_daily_unit": "${unit.unitNumber}2$month",
                  "unit": unit.unitNumber,
                  "date": month,
                  "qty": dailyCheckConverted
                      .where((daily) =>
                          daily.unit == unit.unitNumber &&
                          daily.hari.startsWith(
                              month)) // Pastikan unit cocok dan di bulan yang benar
                      .length,
                  "site": "2"
                };
              });
            }).toList();

            log('summary data multiple : $summaryData');
            log('unit data multiple : $unitData');

            break;
        }

        // final countCheckedTire = dailyCheckConverted.fold(
        //     0, (sum, item) => sum + item.posisi.length);

        // final countLowPressureTire = dailyCheckConverted.fold(
        //     0,
        //     (sum, item) =>
        //         sum +
        //         item.posisi
        //             .where((pos) => pos.kondisi == "Low Pressure")
        //             .length);

        // // Data 1
        // final summaryData = {
        //   'target_daily': event.countAllTire,
        //   'checked': countCheckedTire,
        //   'low': countLowPressureTire,
        // };

        // // Data 3
        // final unitData = event.allUnit.map((unit) {
        //   return {
        //     "id_daily_unit":
        //         "${unit.unitNumber}2${dailyCheckConverted[0].hari.split('-').sublist(0, 2).join('-')}",
        //     "unit": unit.unitNumber,
        //     "date":
        //         dailyCheckConverted[0].hari.split('-').sublist(0, 2).join('-'),
        //     "qty": dailyCheckConverted
        //             .any((daily) => daily.unit == unit.unitNumber)
        //         ? dailyCheckConverted
        //             .firstWhere((daily) => daily.unit == unit.unitNumber)
        //             .posisi
        //             .length
        //         : 0,
        //     "site": "2"
        //   };
        // }).toList();

        // await ApiService.postDailyCheckPressure(
        //     dailyCheckConverted, summaryData, unitData);

        emit(DailyCheckPostSuccessState(message: "Data berhasil dikirim!"));
      } catch (e) {
        emit(DailyCheckPostErrorState(error: e.toString()));
      }
    });
  }
}
