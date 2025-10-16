import '../../../../core/blocs/bluetooth/pair_device_cubit/pair_device_cubit.dart';
import '../../../../core/blocs/bluetooth/pair_device_cubit/pair_device_state.dart';
import '../../../../core/services/model/color_range_model.dart';
import '../../../../core/styles/text_manager.dart';
import '../../../../core/utils/bluetooth/extensions/scanresult_extension.dart';
import '../../../../core/utils/bluetooth/utils/interpolation_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class AvailableDeviceTileWidget extends StatefulWidget {
  final ScanResult device;
  const AvailableDeviceTileWidget({super.key, required this.device});

  @override
  State<AvailableDeviceTileWidget> createState() =>
      _AvailableDeviceTileWidgetState();
}

class _AvailableDeviceTileWidgetState extends State<AvailableDeviceTileWidget> {
  @override
  Widget build(BuildContext context) {
    bool canConnect = widget.device.advertisementData.connectable;
    if (widget.device.getName() == 'Unknown Device') {
      return Container();
    }

    return ListTile(
      // tileColor: InterpolationUtils.getInterpolatedColor(
      //     value: device.rssi,
      //     colorRange: ColorRangeModel(
      //         firstColor: const Color(0xFFF46666),
      //         midColor: const Color(0xFFF2CB44),
      //         lastColor: const Color(0xFF3BDE86))),
      // leading: Text("Id: ${device.}"),
      title: Text(
        "${widget.device.getName()} RSSI: ${widget.device.rssi}",
        style: getBlackTextStyle(),
      ),
      subtitle: ElevatedButton(
        onPressed: () async {
          if (!canConnect) {
            // Navigator.of(context)
            //     .pushNamed(AppRoutes.connectedDeviceScreen, arguments: device);
          }
          if (!widget.device.device.isConnected) {
            debugPrint("debugCanConnect: Can be connected");
            BlocProvider.of<PairDeviceCubit>(context).tryConnect(widget.device);
          }
          if (widget.device.device.isConnected) {
            setState(() {});
            debugPrint("debugCanDisonnect: Can be disconnected");
            await widget.device.device.disconnect();
          }
        },
        child: BlocBuilder<PairDeviceCubit, PairDeviceState>(
          builder: (context, state) {
            if (state is PairingDeviceState &&
                widget.device.device.remoteId.str ==
                    state.device.device.remoteId.str) {
              return const Text("Pairing...");
            }
            //  else if (state is PairedState &&
            //     device.device.remoteId.str ==
            //         state.device.device.remoteId.str) {
            //   return const Text("Disconnect");
            // }
            return Text(widget.device.device.isConnected
                ? "Disconnect"
                : canConnect
                    ? "Connect"
                    : "Cannot connect");
          },
          buildWhen: (previousState, state) {
            if (state is PairingDeviceState &&
                state.device.device.remoteId.str !=
                    widget.device.device.remoteId.str) {
              return false;
            }
            return true;
          },
        ),
      ),
    );
  }
}
