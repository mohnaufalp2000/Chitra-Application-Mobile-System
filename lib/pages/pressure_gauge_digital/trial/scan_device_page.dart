import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
import 'package:camos/core/blocs/bluetooth/scan_devices_cubit/scan_devices_cubit.dart';
import 'package:camos/core/blocs/bluetooth/scan_devices_cubit/scan_devices_state.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/bluetooth/list_of_scanned_devices_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ScanDevicePage extends StatefulWidget {
  static const routeName = '/scan-device-page';
  const ScanDevicePage({super.key});

  @override
  State<ScanDevicePage> createState() => _ScanDevicePageState();
}

class _ScanDevicePageState extends State<ScanDevicePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Scan Device', context),
      body: SafeArea(
        child: BlocBuilder<BluetoothOnOffCubit, BluetoothOnOffState>(
          builder: (context, onOffState) {
            if (onOffState is BluetoothOnState) {
              return BlocBuilder<ScanDevicesCubit, ScanDevicesState>(
                builder: (context, state) {
                  return RefreshIndicator(
                    onRefresh: () async => scanDevices(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          height: 24,
                        ),
                        Container(
                          color: Colors.white,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Center(
                                child: Text(
                                  "${state.getTitle()}${state is ScanSuccessState ? ": ${state.scannedDevices.length}" : ""}",
                                ),
                              ),
                              if (state is ScanSuccessState ||
                                  state is ScanFailState)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                        onPressed: () {
                                          scanDevices(context);
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.bluetooth_searching,
                                              color: white,
                                            ),
                                            const SizedBox(
                                              width: 6,
                                            ),
                                            Text(
                                              "Scan Again",
                                              style: getWhiteTextStyle(),
                                            ),
                                          ],
                                        )),
                                  ),
                                )
                            ],
                          ),
                        ),
                        if (state is InitialState)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                  onPressed: () {
                                    scanDevices(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bluetooth_searching,
                                        color: white,
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      Text(
                                        "Scan Devices",
                                        style: getWhiteTextStyle(),
                                      ),
                                    ],
                                  )),
                            ),
                          )
                        else if (state is ScanningState)
                          const Center(child: CircularProgressIndicator())
                        else if (state is ScanSuccessState)
                          Expanded(
                            child: ListOfScannedDevicesWidget(
                                connectedDevices: state.scannedDevices),
                          )
                        else if (state is ScanFailState)
                          Text(state.failData.msg)
                      ],
                    ),
                  );
                },
              );
            } else if (onOffState is BluetoothOffState) {
              return const Center(
                child: Text("Bluetooth is turned off"),
              );
            } else if (onOffState is BluetoothNotSupportedState) {
              return Center(
                child: Text(onOffState.failData.msg),
              );
            }
            return const Center(
              child: CircularProgressIndicator(),
            );
          },
        ),
      ),
    );
  }

  void scanDevices(BuildContext context) {
    BlocProvider.of<ScanDevicesCubit>(context).scanDevices();
    BlocProvider.of<ConnectedDevicesCubit>(context).fetchConnectedDevices();
  }
}
