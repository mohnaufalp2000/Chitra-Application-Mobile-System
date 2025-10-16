import '../utils/bluetooth_utils.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

extension ScanResultExtension on ScanResult {
  String getName() {
    return advertisementData.advName.isNotEmpty
        ? advertisementData.advName
        : device.platformName.isNotEmpty
            ? device.platformName
            : BluetoothUtils.getNameFromManufacturerData(
                advertisementData.manufacturerData);
  }
}
