import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/tire_spec.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:meta/meta.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'tire_event.dart';
part 'tire_state.dart';

class TireBloc extends Bloc<TireEvent, TireState> {
  TireBloc() : super(TireInitial()) {
    on<GetUnitTiresEvent>((event, emit) async {
      emit(TireLoadingState());
      final units = await ApiService.getCachedUnits(
          unitNumber: event.unitNumber, idSite: event.idSite);
      log('unitsunitsunits : ${units.length}');
      emit(TiresLoadedState(units: units));
      // try {
      //   emit(TireLoadingState());
      //   final units =
      //       await ApiService.getCachedUnits(unitNumber: event.unitNumber);
      //   emit(TiresLoadedState(units: units));
      // } catch (e) {
      //   final cachedTires =
      //       await ApiService.getCachedUnitTires(event.unitNumber);
      //   emit(TiresLoadedState(units: cachedTires));
      // }
    });
  }
}
