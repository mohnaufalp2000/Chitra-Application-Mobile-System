import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:equatable/equatable.dart';

part 'new_tire_repair_event.dart';
part 'new_tire_repair_state.dart';

class NewTireRepairBloc extends Bloc<NewTireRepairEvent, NewTireRepairState> {
  NewTireRepairBloc() : super(NewTireRepairInitial()) {
    on<NewTireRepairEvent>((event, emit) async {
      try {
        final newTireMap = event.newTireMap;

        // await ApiService.postNewTireRepair(newTireMap);

        emit(NewTireRepairSuccessState(message: "Data berhasil dikirim!"));
      } catch (e) {
        emit(NewTireRepairErrorState(error: e.toString()));
      }
    });
  }
}
