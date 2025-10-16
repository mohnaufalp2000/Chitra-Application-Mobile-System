import 'dart:developer';

import 'package:bloc/bloc.dart';
import '../../services/api_service.dart';
import '../../services/model/unit_tire.dart';
import 'package:equatable/equatable.dart';

part 'detail_tire_condition_event.dart';
part 'detail_tire_condition_state.dart';

class DetailTireConditionBloc
    extends Bloc<DetailTireConditionEvent, DetailTireConditionState> {
  DetailTireConditionBloc() : super(DetailTireConditionInitial()) {
    on<GetDetailTireConditionEvent>((event, emit) async {
      try {
        emit(DetailTireConditionLoadingState());
        final units = await ApiService.getUniqueUnits(event.idSite);

        final selectedTires =
            units.where((element) => element.size == event.size).toList();

        emit(DetailTireConditionLoadedState(units: selectedTires));
      } catch (e) {}
    });
  }
}
