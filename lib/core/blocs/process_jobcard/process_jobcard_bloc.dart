import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/material_repair_model.dart';
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

        emit(MaterialLoadedState(materialList));
      } catch (e) {
        emit(MaterialErrorState());
      }
    });

    on<SubmitJobcardEvent>((event, emit) {});
  }
}
