import 'dart:developer';

import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/scan_device_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import '../../../core/styles/asset_path.dart';
import '../../../core/styles/text_manager.dart';
import 'select_inspection_state.dart';

class SelectInspectionPage extends StatefulWidget {
  static const routeName = '/select-inspection-page';
  const SelectInspectionPage({super.key});

  @override
  State<SelectInspectionPage> createState() => _SelectInspectionPageState();
}

class _SelectInspectionPageState extends State<SelectInspectionPage> {
  @override
  Widget build(BuildContext context) {
    final SelectInspectionState controller = Get.put(SelectInspectionState());

    return Scaffold(
      appBar: AppBar(
        actions: [
          BlocBuilder<ConnectedDevicesCubit, ConnectedDevicesState>(
            builder: (context, cState) {
              // Cek apakah sudah terkoneksi
              final isConnected = cState is ConnectedDevicesLoadedState &&
                  cState.connectedDevices.isNotEmpty;

              // Ambil device yang terhubung (jika ada)
              final BluetoothDevice? connectedDevice = isConnected
                  ? cState.connectedDevices.firstWhereOrNull(
                      (d) => d.advName.isNotEmpty,
                    )
                  : null;

              // Nama tombol
              final String deviceName = connectedDevice?.advName ??
                  connectedDevice?.remoteId.str ??
                  'Unknown';

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: isConnected
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green.shade600,
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.bluetooth_connected,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 6),
                                Text(
                                  deviceName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onPressed: () {
                                    // LOGIC DISCONNECT
                                    log('Disconnect action triggered. Implement disconnect logic in ConnectedDevicesCubit.');
                                    // TODO: panggil cubit disconnect di sini
                                  },
                                  child: const Text(
                                    'Disconnect',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                        ),
                        onPressed: () async {
                          log('Navigating to Scan Device Page');
                          await Navigator.of(context)
                              .pushNamed(ScanDevicePage.routeName);

                          if (context.mounted) {
                            BlocProvider.of<ConnectedDevicesCubit>(context)
                                .fetchConnectedDevices();
                          }
                        },
                        icon: const Icon(Icons.bluetooth_searching,
                            color: Colors.white),
                        label: const Text(
                          'Scan Devices',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // === DAILY CHECK PRESSURE ===
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => controller.openDailyCheck(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            '${iconPath}/tire_pressure_icon.png',
                            width: MediaQuery.of(context).size.width * 0.12,
                            height: MediaQuery.of(context).size.height * 0.12,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Daily Check Pressure',
                            textAlign: TextAlign.center,
                            style: getBlackTextStyle(
                                fontSize: 18, fontWeight: w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // === TIRE INSPECTION ===
              Expanded(
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => controller.openTireInspection(context),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            '${iconPath}/heavy_tire_icon.png',
                            width: MediaQuery.of(context).size.width * 0.12,
                            height: MediaQuery.of(context).size.height * 0.12,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tire Inspection',
                            textAlign: TextAlign.center,
                            style: getBlackTextStyle(
                                fontSize: 18, fontWeight: w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
