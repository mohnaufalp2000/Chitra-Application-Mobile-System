// import 'dart:developer';
// import 'dart:io';

// import 'package:bloc/bloc.dart';
// import '../../services/api_service.dart';
// import '../../services/model/daily_press.dart';
// import '../../services/model/recc_press.dart';
// import '../../services/model/unit_tire.dart';
// import '../../services/shared_preferences/shared_preferences.dart';
// import 'package:connection_network_type/connection_network_type.dart';
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:equatable/equatable.dart';
// import 'package:permission_handler/permission_handler.dart';

// part 'unit_event.dart';
// part 'unit_state.dart';

// class UnitBloc extends Bloc<UnitEvent, UnitState> {
//   UnitBloc() : super(UnitInitial()) {
//     on<GetUnitsEvent>((event, emit) async {
//       emit(UnitLoadingState());
//       final connectivityResult = await Connectivity().checkConnectivity();

//       log('isOnline unit bloc : ${event.isOnline}');

//       if (event.isOnline) {
//         if (connectivityResult == ConnectivityResult.none) {
//           emit(UnitErrorState(
//             message: 'Please Check Your Internet Connection!',
//           ));
//         } else {
//           final units = await ApiService.getUnits(event.idSite);
//           final reccPress = await ApiService.getCachedReccPress();
//           final countAllTire = await ApiService.getCachedCountAllTire();
//           final allTireSize =
//               await ApiService.getCachedTireSize(idSite: event.idSite);

//           // emit(UnitLoadedState(units: units, reccPress: reccPress));
//           emit(UnitLoadedState(
//               units: units,
//               reccPress: reccPress,
//               countAllTire: countAllTire,
//               allTireSize: allTireSize));
//           log('list unit bloc : ${units}');
//           log('wkwkwkwk : ${units[0]}');
//         }

//         // return;
//       } else {
//         // final totalActualUnits = await ApiService.getUnits(event.idSite);
//         final cachedData =
//             await ApiService.getCachedUnits(idSite: event.idSite);
//         final cachedDataReccPress = await ApiService.getCachedReccPress();
//         final cachedCountAllTire =
//             await ApiService.getCachedCountAllTire(idSite: event.idSite);
//         final allTireSize =
//             await ApiService.getCachedTireSize(idSite: event.idSite);

//         emit(UnitLoadedState(
//             units: cachedData,
//             // totalActualUnits: totalActualUnits,
//             reccPress: cachedDataReccPress,
//             countAllTire: cachedCountAllTire,
//             allTireSize: allTireSize));

//         log('list unit bloc : ${cachedData.length}');

//         if (Platform.isAndroid) {
//           await Permission.phone.request();
//         }
//         // return;
//       }
//     });
//   }
// }

import 'dart:developer';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:camos/core/services/model/daily_press.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../services/api_service.dart';
import '../../services/model/unit_tire.dart';

part 'unit_event.dart';
part 'unit_state.dart';

class UnitBloc extends Bloc<UnitEvent, UnitState> {
  UnitBloc() : super(UnitInitial()) {
    on<GetUnitsEvent>(_onGetUnits);
  }

  Future<void> _onGetUnits(
    GetUnitsEvent event,
    Emitter<UnitState> emit,
  ) async {
    emit(UnitLoadingState());

    try {
      final ConnectivityResult connectivityResult =
          await Connectivity().checkConnectivity();

      final bool hasInternet = connectivityResult != ConnectivityResult.none;

      log('========================================');
      log('GET UNIT BLOC');
      log('idSite       : ${event.idSite}');
      log('event online : ${event.isOnline}');
      log('has internet : $hasInternet');

      /*
       * ==========================================================
       * MODE ONLINE
       * ==========================================================
       */

      if (event.isOnline) {
        if (!hasInternet) {
          log(
            'Tidak ada koneksi. Mencoba mengambil data dari cache.',
          );

          await _emitCachedData(
            event: event,
            emit: emit,
            showErrorWhenEmpty: true,
          );

          return;
        }

        try {
          /*
           * ApiService.getUnits() akan:
           *
           * 1. Mengambil get_tire_running.
           * 2. Menyimpan cache seluruh data unit.
           * 3. Menyimpan cache total tire.
           * 4. Menyimpan cache tire size.
           * 5. Menyimpan cache recommended pressure.
           * 6. Menyimpan cache target area.
           */
          final List<UnitTire> units = await ApiService.getUnits(event.idSite);

          /*
           * Setelah API selesai, ambil data pendukung
           * dari cache yang baru diperbarui.
           */
          final List<Map<String, dynamic>> reccPress =
              await ApiService.getCachedReccPress();

          final int countAllTire = await ApiService.getCachedCountAllTire(
            idSite: event.idSite,
          );

          final Map<String, dynamic> allTireSize =
              await ApiService.getCachedTireSize(
            idSite: event.idSite,
          );

          final Map<String, int> targetArea =
              await ApiService.getCachedTargetArea(
            idSite: event.idSite,
          );

          log('Online units       : ${units.length}');
          log('Online recc press  : ${reccPress.length}');
          log('Online all tire    : $countAllTire');
          log('Online tire size   : $allTireSize');
          log('Online target area : $targetArea');

          emit(
            UnitLoadedState(
              idSite: event.idSite,
              requestSource: event.requestSource,
              units: units,
              reccPress: reccPress,
              countAllTire: countAllTire,
              allTireSize: allTireSize,
              targetArea: targetArea,
              loadedFromApi: true,
            ),
          );
        } catch (e, st) {
          /*
           * Jika internet ada tetapi API gagal, timeout,
           * server error, atau response tidak valid,
           * coba tampilkan cache lama.
           */
          log('Get unit online gagal: $e');
          log('$st');
          log('Mencoba fallback ke cache.');

          await _emitCachedData(
            event: event,
            emit: emit,
            showErrorWhenEmpty: true,
          );
        }

        return;
      }

      /*
       * ==========================================================
       * MODE OFFLINE / CACHE
       * ==========================================================
       */

      await _emitCachedData(
        event: event,
        emit: emit,
        showErrorWhenEmpty: false,
      );
    } catch (e, st) {
      log('UnitBloc error: $e');
      log('$st');

      emit(
        UnitErrorState(
          message: 'Gagal mengambil data unit: $e',
        ),
      );
    }
  }

  /*
   * ==========================================================
   * AMBIL SEMUA DATA CACHE
   * ==========================================================
   */

  Future<void> _emitCachedData({
    required GetUnitsEvent event,
    required Emitter<UnitState> emit,
    required bool showErrorWhenEmpty,
  }) async {
    try {
      final List<UnitTire> cachedUnits = await ApiService.getCachedUnits(
        idSite: event.idSite,
      );

      final List<Map<String, dynamic>> cachedReccPress =
          await ApiService.getCachedReccPress();

      final int cachedCountAllTire = await ApiService.getCachedCountAllTire(
        idSite: event.idSite,
      );

      final Map<String, dynamic> cachedTireSize =
          await ApiService.getCachedTireSize(
        idSite: event.idSite,
      );

      final Map<String, int> cachedTargetArea =
          await ApiService.getCachedTargetArea(
        idSite: event.idSite,
      );

      log('Cached units       : ${cachedUnits.length}');
      log('Cached recc press  : ${cachedReccPress.length}');
      log('Cached all tire    : $cachedCountAllTire');
      log('Cached tire size   : $cachedTireSize');
      log('Cached target area : $cachedTargetArea');

      if (cachedUnits.isEmpty && showErrorWhenEmpty) {
        emit(
          UnitErrorState(
            message:
                'Tidak ada koneksi internet dan cache unit belum tersedia.',
          ),
        );

        return;
      }

      emit(
        UnitLoadedState(
          idSite: event.idSite,
          requestSource: event.requestSource,
          units: cachedUnits,
          reccPress: cachedReccPress,
          countAllTire: cachedCountAllTire,
          allTireSize: cachedTireSize,
          targetArea: cachedTargetArea,
          loadedFromApi: false,
        ),
      );

      await _requestAndroidPermission();
    } catch (e, st) {
      log('Error mengambil cache unit: $e');
      log('$st');

      emit(
        UnitErrorState(
          message: 'Gagal mengambil cache unit: $e',
        ),
      );
    }
  }

  Future<void> _requestAndroidPermission() async {
    if (!Platform.isAndroid) {
      return;
    }

    try {
      final PermissionStatus currentStatus = await Permission.phone.status;

      if (!currentStatus.isGranted) {
        await Permission.phone.request();
      }
    } catch (e) {
      log('Error request phone permission: $e');
    }
  }
}
