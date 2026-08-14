import 'dart:async';
import 'dart:convert';

import '../../../utils/bluetooth/extensions/bluetoothcharacteristic_extension.dart';
import '../../../utils/bluetooth/utils/bluetooth_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'discover_services_state.dart';

class MsgAndCharModel {
  final String msg;
  final String char;

  MsgAndCharModel({required this.msg, required this.char});
}

class DiscoverServicesCubit extends Cubit<DiscoverServiceState> {
  DiscoverServicesCubit() : super(InitialState());

  final List<StreamSubscription<List<int>>> _notificationSubscriptions = [];
  int _discoveryGeneration = 0;
  bool _isClosing = false;

  bool get _isActive => !_isClosing && !isClosed;

  ValueNotifier<List<MsgAndCharModel>> receivedMessagesFromBLE =
      ValueNotifier<List<MsgAndCharModel>>([]);

  void clearMessages() {
    if (!_isActive) return;
    receivedMessagesFromBLE.value = [];
  }

  void addMsgFromNotif(MsgAndCharModel msgAndChar) {
    if (!_isActive) return;
    List<MsgAndCharModel> msgsTillNow = receivedMessagesFromBLE.value;
    msgsTillNow.add(msgAndChar);
    receivedMessagesFromBLE.value = msgsTillNow;
  }

  Future<void> _cancelNotificationSubscriptions() async {
    final subscriptions = List<StreamSubscription<List<int>>>.from(
      _notificationSubscriptions,
    );
    _notificationSubscriptions.clear();

    await Future.wait(
      subscriptions.map((subscription) => subscription.cancel()),
    );
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    if (!_isActive) return;

    final int discoveryGeneration = ++_discoveryGeneration;
    await _cancelNotificationSubscriptions();

    if (!_isActive || discoveryGeneration != _discoveryGeneration) return;
    emit(InitialState());

    try {
      List<BluetoothService> services = await device.discoverServices();
      if (!_isActive || discoveryGeneration != _discoveryGeneration) return;

      // listen for notifications from all the characteristics of all services
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (!_isActive || discoveryGeneration != _discoveryGeneration) {
            return;
          }

          try {
            if (characteristic.properties.notify ||
                characteristic.properties.indicate) {
              await characteristic.setNotifyValue(true);
              if (!_isActive || discoveryGeneration != _discoveryGeneration) {
                return;
              }

              final subscription =
                  characteristic.lastValueStream.listen((event) {
                if (!_isActive || discoveryGeneration != _discoveryGeneration) {
                  return;
                }

                String notifInString = String.fromCharCodes(event);
                debugPrint("debugBluetoothNotification*************");
                debugPrint(
                    "debugBluetoothNotification: charName: ${BluetoothUtils.getBluetoothChar(characteristic.characteristicUuid.str)}");
                addMsgFromNotif(MsgAndCharModel(
                    msg: notifInString, char: characteristic.getName()));
                debugPrint(
                    "debugBluetoothNotification: stringNotif: $notifInString");
                try {
                  debugPrint(
                      "debugBluetoothNotification: jsonNotif: ${jsonDecode(notifInString)}");
                } catch (e) {
                  debugPrint(
                      "debugBluetoothNotification: invalid jsonNotif: $e");
                }
                debugPrint("debugBluetoothNotification*************");
              });
              _notificationSubscriptions.add(subscription);
            }
          } catch (e) {
            debugPrint(
                "debugBluetoothNotification: error in char loop: ${e.toString()}");
          }
        }
      }
      if (!_isActive || discoveryGeneration != _discoveryGeneration) return;
      emit(ServicesLoadedState(services: services));
    } catch (e) {
      debugPrint("debugBluetoothNotification: error: ${e.toString()}");
      // emit(
      //     ErrorLoadingServiceState(errorData: FailureModel(msg: e.toString())));
    }
  }

  @override
  Future<void> close() async {
    _isClosing = true;
    _discoveryGeneration++;
    await _cancelNotificationSubscriptions();
    receivedMessagesFromBLE.dispose();
    return super.close();
  }
}
