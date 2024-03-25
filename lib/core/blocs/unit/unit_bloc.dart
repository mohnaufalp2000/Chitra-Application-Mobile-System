import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:connection_network_type/connection_network_type.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

part 'unit_event.dart';
part 'unit_state.dart';

class UnitBloc extends Bloc<UnitEvent, UnitState> {
  UnitBloc() : super(UnitInitial()) {
    on<GetUnitsEvent>((event, emit) async {
      final connectivityResult = await Connectivity().checkConnectivity();

      if (connectivityResult == ConnectivityResult.none) {
        final cachedData = await ApiService.getCachedUnits();
        emit(UnitLoadedState(units: cachedData));
      } else {
        if (Platform.isAndroid) {
          await Permission.phone.request();
        }
        final checkNetworkType =
            await ConnectionNetworkType().currentNetworkStatus();
        if (checkNetworkType == NetworkStatus.otherMobile) {
          log('unit edge');

          final cachedData = await ApiService.getCachedUnits();
          emit(UnitLoadedState(units: cachedData));
          return;
        } else {
          log('unit aman');
          emit(UnitLoadingState());

          final units = await ApiService.getUnits(event.idSite);
          emit(UnitLoadedState(units: units));
        }
      }
      // try {
      //   emit(UnitLoadingState());

      //   final units = await ApiService.getUnits(event.idSite);
      //   emit(UnitLoadedState(units: units));
      // } catch (e) {
      //   final cachedData = await ApiService.getCachedUnits();
      //   emit(UnitLoadedState(units: cachedData));
      //   // emit(UnitErrorState());
      // }
    });

    // on<GetUnitTiresEvent>((event, emit) async {
    //   try {
    //     emit(UnitTiresLoadingState());

    //     final units =
    //         await ApiService.getUnitTires(event.idSite, event.unitNumber);
    //     emit(UnitTiresLoadedState(units: units));
    //   } catch (e) {
    //     emit(UnitTiresErrorState());
    //   }
    // });
  }
}
