import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'connected_devices_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConnectedDevicesCubit extends Cubit<ConnectedDevicesState> {
  ConnectedDevicesCubit() : super(LoadingState());

  void fetchConnectedDevices() async {
    emit(LoadingState());

    List<BluetoothDevice> connectedAppDevices =
        FlutterBluePlus.connectedDevices;
    List<BluetoothDevice> connectedSystemDevices =
        await FlutterBluePlus.connectedSystemDevices;
    List<BluetoothDevice> allDevices =
        connectedAppDevices + connectedSystemDevices;

    emit(ConnectedDevicesLoadedState(connectedDevices: allDevices));
  }
}
