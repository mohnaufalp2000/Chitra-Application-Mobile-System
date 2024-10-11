import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConnectedDeviceTileWidget extends StatelessWidget {
  final BluetoothDevice device;
  const ConnectedDeviceTileWidget({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(
        children: [
          Icon(Icons.devices_rounded),
          const SizedBox(
            width: 12,
          ),
          Text(device.platformName),
        ],
      ),
      // subtitle: ElevatedButton(
      //     onPressed: () {
      //       // Navigator.of(context)
      //       //     .pushNamed(AppRoutes.viewServicesScreen, arguments: device);
      //     },
      //     child: const Text("View Services")
      //     ),
    );
  }
}
