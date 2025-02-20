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
        // target
        // checked
        // low
        final data = event.dailyCheck;
        // final summaryTire = {
        //   'target_daily': data.length,
        // };

        List<DailyPress> dailyCheckConverted =
            data.map((e) => DailyPress.fromFirestore(e)).toList();

        final countCheckedTire = dailyCheckConverted.fold(
            0, (sum, item) => sum + item.posisi.length);

        final countLowPressureTire = dailyCheckConverted.fold(
            0,
            (sum, item) =>
                sum +
                item.posisi
                    .where((pos) => pos.kondisi == "Low Pressure")
                    .length);

        log('jumlah ban tercheck: $countCheckedTire');
        log('jumlah ban low pressure: $countLowPressureTire');
        log('jumlah ban semua: ${event.countAllTire}');

        final summaryData = {
          'target_daily': event.countAllTire,
          'checked': countCheckedTire,
          'low': countLowPressureTire,
        };

        await ApiService.postDailyCheckPressure(
            dailyCheckConverted, summaryData);

        emit(DailyCheckPostSuccessState(message: "Data berhasil dikirim!"));
      } catch (e) {
        emit(DailyCheckPostErrorState(error: e.toString()));
      }
    });
  }
}
