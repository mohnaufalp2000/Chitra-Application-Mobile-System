import 'dart:developer';

import 'package:bloc/bloc.dart';
import '../../services/api_service.dart';
import 'package:equatable/equatable.dart';

part 'wo_jobcard_event.dart';
part 'wo_jobcard_state.dart';

class WoJobcardBloc extends Bloc<WoJobcardEvent, WoJobcardState> {
  WoJobcardBloc() : super(WoJobcardInitial()) {
    on<WoJobcardEvent>((event, emit) async {
      emit(WoJobcardLoadingState());

      try {
        final WOList = await ApiService.getWOJobcardList();
        emit(WoJobcardLoadedState(WOList: WOList));
      } catch (e) {
        log('error wo jobcard di bloc : $e');
        emit(WoJobcardErrorState());
      }
    });
  }
}
