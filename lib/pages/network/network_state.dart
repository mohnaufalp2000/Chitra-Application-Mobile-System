import 'package:camos/objectbox.g.dart';
import 'package:connection_network_type/connection_network_type.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class InternetState extends GetxController {
  final RxBool isConnected = false.obs;

  final Rx<ConnectivityResult> connectionType =
      Rx<ConnectivityResult>(ConnectivityResult.none);

  @override
  void onInit() {
    super.onInit();
    Connectivity().onConnectivityChanged.listen((result) {
      connectionType.value = result;

      updateConnectionStatus(result);
    });
    checkInitialConnectivity();
  }

  void checkInitialConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    connectionType.value = result;
    updateConnectionStatus(result);
  }

  void updateConnectionStatus(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      isConnected.value = false;
    } else {
      isConnected.value = true;
    }
  }

  Future<bool> isNetworkReliable() async {
    final currentType = connectionType.value;
    if (currentType == ConnectivityResult.mobile) {
      final networkStatus =
          await ConnectionNetworkType().currentNetworkStatus();
      return networkStatus != NetworkStatus.otherMobile;
    }
    return currentType != ConnectivityResult.none;
  }
}
