import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/daily_press.dart';
import 'package:equatable/equatable.dart';

part 'daily_check_post_event.dart';
part 'daily_check_post_state.dart';

class DailyCheckPostBloc
    extends Bloc<DailyCheckPostEvent, DailyCheckPostState> {
  DailyCheckPostBloc() : super(DailyCheckPostInitial()) {
    on<DailyCheckPostEvent>((event, emit) async {
      // emit(DailyCheckPostLoadingState());

      try {
        final data = event.dailyCheck;

        List<DailyPress> dailyCheckConverted =
            data.map((e) => DailyPress.fromFirestore(e)).toList();

        log('daily check post 1 $data');
        log('daily check post 2 $dailyCheckConverted');

        await ApiService.postDailyCheckPressure(dailyCheckConverted);

        emit(DailyCheckPostSuccessState(message: "Data berhasil dikirim!"));
      } catch (e) {
        emit(DailyCheckPostErrorState(error: e.toString()));
      }
    });
  }
}
