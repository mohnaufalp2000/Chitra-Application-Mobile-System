import 'dart:developer';

import 'package:bloc/bloc.dart';
import '../../services/api_service.dart';
import '../../services/model/material_repair_model.dart';
import 'package:equatable/equatable.dart';

part 'process_jobcard_event.dart';
part 'process_jobcard_state.dart';

class ProcessJobcardBloc
    extends Bloc<ProcessJobcardEvent, ProcessJobcardState> {
  ProcessJobcardBloc() : super(MaterialInitialState()) {
    on<FetchMaterialListEvent>((event, emit) async {
      emit(MaterialLoadingState());
      try {
        final materialList = await ApiService.getMaterialRepairList();

        log('material list : ${materialList}');

        emit(MaterialLoadedState(materialList));
      } catch (e) {
        emit(MaterialErrorState());
      }
    });

    on<SubmitJobcardEvent>((event, emit) async {
      emit(SubmitLoadingState());

      try {
        await ApiService.postJobJobcardRepair(event.jobcard);

        emit(SubmitSuccessState());
      } catch (e) {
        emit(SubmitErrorState());
      }
    });
  }
}
