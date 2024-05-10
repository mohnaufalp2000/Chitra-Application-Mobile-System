import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/utils/data/spm.dart';
import 'package:equatable/equatable.dart';

part 'spm_event.dart';
part 'spm_state.dart';

class SpmBloc extends Bloc<SpmEvent, SpmState> {
  SpmBloc() : super(SpmInitial()) {
    on<GetListSpmEvent>((event, emit) async {
      emit(SpmLoadingState());
      try {
        final listSpm = await ApiService.getApiSpm();
        emit(SpmLoadedState(listSpm: listSpm));
        log('daftar spm $listSpm');
      } catch (e) {}
    });
  }
}
