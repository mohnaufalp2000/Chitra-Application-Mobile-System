import '../../../services/model/failure_model.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

abstract class ScanDevicesState {}

class InitialState extends ScanDevicesState {}

class ScanningState extends ScanDevicesState {}

class ScanSuccessState extends ScanDevicesState {
  final List<ScanResult> scannedDevices;

  ScanSuccessState({required this.scannedDevices});
}

class ScanFailState extends ScanDevicesState {
  final FailureModel failData;

  ScanFailState({required this.failData});
}

extension ScanDevicesStateExtension on ScanDevicesState {
  String getTitle() {
    switch (runtimeType) {
      case ScanningState:
        return 'Scanning...';
      case InitialState:
        return "Ready to Scan";
      case ScanSuccessState:
        return "Found Devices";
      case ScanFailState:
        return "Error Scanning";
      default:
        return "";
    }
  }
}
