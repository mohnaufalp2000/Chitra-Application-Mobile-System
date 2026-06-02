import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import '../../services/api_service.dart';
import '../../services/model/daily_press.dart';
import '../../services/model/recc_press.dart';
import '../../services/model/unit_tire.dart';
import '../../services/shared_preferences/shared_preferences.dart';
import 'package:connection_network_type/connection_network_type.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

part 'unit_event.dart';
part 'unit_state.dart';

class UnitBloc extends Bloc<UnitEvent, UnitState> {
  UnitBloc() : super(UnitInitial()) {
    on<GetUnitsEvent>((event, emit) async {
      emit(UnitLoadingState());
      final connectivityResult = await Connectivity().checkConnectivity();

      log('isOnline unit bloc : ${event.isOnline}');

      if (event.isOnline) {
        if (connectivityResult == ConnectivityResult.none) {
          emit(UnitErrorState(
            message: 'Please Check Your Internet Connection!',
          ));
        } else {
          final units = await ApiService.getUnits(event.idSite);
          final reccPress = await ApiService.getCachedReccPress();
          final countAllTire = await ApiService.getCachedCountAllTire();
          final allTireSize =
              await ApiService.getCachedTireSize(idSite: event.idSite);

          // emit(UnitLoadedState(units: units, reccPress: reccPress));
          emit(UnitLoadedState(
              units: units,
              reccPress: reccPress,
              countAllTire: countAllTire,
              allTireSize: allTireSize));
          log('list unit bloc : ${units}');
          log('wkwkwkwk : ${units[0]}');
        }

        // return;
      } else {
        final totalActualUnits = await ApiService.getUnits(event.idSite);
        final cachedData =
            await ApiService.getCachedUnits(idSite: event.idSite);
        final cachedDataReccPress = await ApiService.getCachedReccPress();
        final cachedCountAllTire =
            await ApiService.getCachedCountAllTire(idSite: event.idSite);
        final allTireSize =
            await ApiService.getCachedTireSize(idSite: event.idSite);

        emit(UnitLoadedState(
            units: cachedData,
            totalActualUnits: totalActualUnits,
            reccPress: cachedDataReccPress,
            countAllTire: cachedCountAllTire,
            allTireSize: allTireSize));

        log('list unit bloc : ${cachedData.length}');

        if (Platform.isAndroid) {
          await Permission.phone.request();
        }
        // return;
      }
    });
  }
}
