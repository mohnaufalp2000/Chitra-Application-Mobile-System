import 'dart:async';

import '../../../services/model/failure_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'bluetooth_on_off_state.dart';

class BluetoothOnOffCubit extends Cubit<BluetoothOnOffState> {
  BluetoothOnOffCubit() : super(LoadingState()) {
    checkBluetoothStatus();
  }

  StreamSubscription<BluetoothAdapterState>? _adapterStateSubscription;
  int _statusCheckGeneration = 0;
  bool _isClosing = false;

  bool get _canEmit => !_isClosing && !isClosed;

  Future<void> checkBluetoothStatus() async {
    if (!_canEmit) return;

    final int checkGeneration = ++_statusCheckGeneration;
    await _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;

    if (!_canEmit || checkGeneration != _statusCheckGeneration) return;
    emit(LoadingState());

    if (!await FlutterBluePlus.isSupported) {
      if (!_canEmit || checkGeneration != _statusCheckGeneration) return;
      emit(BluetoothNotSupportedState(
          failData:
              FailureModel(msg: "Bluetooth is not supported in this device")));
      return;
    }

    if (!_canEmit || checkGeneration != _statusCheckGeneration) return;
    _adapterStateSubscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (!_canEmit || checkGeneration != _statusCheckGeneration) return;

      if (state == BluetoothAdapterState.on) {
        emit(BluetoothOnState());
      } else if (state == BluetoothAdapterState.off) {
        emit(BluetoothOffState());
      } else {
        emit(BluetoothNotSupportedState(
            failData: FailureModel(msg: "Bluetooth State: ${state.name}")));
        return;
      }
    });
  }

  @override
  Future<void> close() async {
    _isClosing = true;
    _statusCheckGeneration++;
    await _adapterStateSubscription?.cancel();
    _adapterStateSubscription = null;
    return super.close();
  }
}
