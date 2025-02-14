import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/model/recc_press.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
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

          // emit(UnitLoadedState(units: units, reccPress: reccPress));
          emit(UnitLoadedState(units: units, reccPress: reccPress));
          log('list unit bloc : ${units}');
          log('wkwkwkwk : ${units[0]}');
        }

        // return;
      } else {
        final cachedData =
            await ApiService.getCachedUnits(idSite: event.idSite);
        final cachedDataReccPress = await ApiService.getCachedReccPress();

        emit(
            UnitLoadedState(units: cachedData, reccPress: cachedDataReccPress));
        UnitLoadedState(units: cachedData, reccPress: cachedDataReccPress);
        log('list unit bloc : ${cachedData.length}');

        if (Platform.isAndroid) {
          await Permission.phone.request();
        }
        // return;
      }

      // if (connectivityResult == ConnectivityResult.none) {
      //   final cachedData =
      //       await ApiService.getCachedUnits(idSite: event.idSite);
      //   emit(UnitLoadedState(units: cachedData));
      // } else {
      //   if (Platform.isAndroid) {
      //     await Permission.phone.request();
      //   }
      //   final checkNetworkType =
      //       await ConnectionNetworkType().currentNetworkStatus();
      //   if (checkNetworkType == NetworkStatus.otherMobile) {
      //     log('unit edge');

      //     final cachedData =
      //         await ApiService.getCachedUnits(idSite: event.idSite);
      //     emit(UnitLoadedState(units: cachedData));
      //     return;
      //   } else {
      //     log('unit aman == ${await getSavedMonthYear()}, ${"${DateTime.now().year}-${DateTime.now().month}"}');
      //     emit(UnitLoadingState());

      //     // belum ganti bulan
      //     if (await getSavedMonthYear() ==
      //         "${DateTime.now().year}-${DateTime.now().month}") {
      //       final cachedData =
      //           await ApiService.getCachedUnits(idSite: event.idSite);
      //       emit(UnitLoadedState(units: cachedData));
      //     } else {
      //       // sudah ganti bulan
      //       final units = await ApiService.getUnits(event.idSite);
      //       emit(UnitLoadedState(units: units));
      //     }
      //   }
      // }
    });
  }
}
