import 'dart:io';

import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothToggleWidget extends StatelessWidget {
  const BluetoothToggleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BluetoothOnOffCubit, BluetoothOnOffState>(
      builder: (context, state) {
        if (state is BluetoothOffState || state is BluetoothOnState) {
          return CupertinoSwitch(
            value: state is BluetoothOffState ? false : true,
            onChanged: (makeOn) async {
              if (Platform.isAndroid) {
                makeOn ? FlutterBluePlus.turnOn() : FlutterBluePlus.turnOff();
              } else {
                showDialog(
                  context: context,
                  builder: (context) {
                    return const AlertDialog(
                      title: Text(
                          "In iOS, On/Off cannot be performed from the app itself."),
                    );
                  },
                );
              }
            },
          );
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
