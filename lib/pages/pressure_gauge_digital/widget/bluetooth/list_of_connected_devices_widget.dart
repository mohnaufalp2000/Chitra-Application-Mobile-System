import 'package:camos/pages/pressure_gauge_digital/widget/bluetooth/connected_device_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ListOfConnectedDevicesWidget extends StatelessWidget {
  final List<BluetoothDevice> connectedDevices;
  const ListOfConnectedDevicesWidget(
      {super.key, required this.connectedDevices});

  @override
  Widget build(BuildContext context) {
    return connectedDevices.isEmpty
        ? const Center(child: Text("No devices were found at the moment."))
        : ListView.builder(
            itemCount: connectedDevices.length - 1,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child:
                    ConnectedDeviceTileWidget(device: connectedDevices[index]),
              );
            },
          );
  }
}
