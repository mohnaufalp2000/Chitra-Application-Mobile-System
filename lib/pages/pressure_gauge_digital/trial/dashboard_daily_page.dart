import '../../../core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
import '../../../core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
import '../../../core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
import 'daily_pressure_trial_page.dart';
import 'scan_device_page.dart';
import '../widget/bluetooth/bluetooth_on_off_toggle_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DashboardDailyPage extends StatefulWidget {
  static const routeName = '/dashboard-daily-page';
  const DashboardDailyPage({super.key});

  @override
  State<DashboardDailyPage> createState() => _DashboardDailyPageState();
}

class _DashboardDailyPageState extends State<DashboardDailyPage> {
  ValueNotifier<int> navAt = ValueNotifier<int>(0);
  PageController pageController = PageController(initialPage: 0);
  final ScrollController scanDevicesScreenController = ScrollController();
  final ScrollController connectedDevicesScreenController = ScrollController();

  @override
  void initState() {
    if (BlocProvider.of<BluetoothOnOffCubit>(context).state
        is BluetoothOnState) {
      BlocProvider.of<ConnectedDevicesCubit>(context).fetchConnectedDevices();
    }
    super.initState();
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String idSite = ModalRoute.of(context)?.settings.arguments as String;

    return Scaffold(
        floatingActionButton: const BluetoothToggleWidget(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
        bottomNavigationBar: ValueListenableBuilder(
          valueListenable: navAt,
          builder: (context, currentIndex, child) {
            return CupertinoTabBar(
                currentIndex: currentIndex,
                onTap: (value) {
                  if (navAt.value != value) {
                    pageController.jumpToPage(value);
                  }
                },
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.bluetooth),
                      label: "Scan Devices"),
                  BottomNavigationBarItem(
                      icon: Icon(CupertinoIcons.home),
                      label: "Daily Check Form"),
                ]);
          },
        ),
        body: PageView(
          physics: const NeverScrollableScrollPhysics(),
          controller: pageController,
          onPageChanged: (newPage) => navAt.value = newPage,
          children: const [
            ScanDevicePage(),
            DailyPressureTrialPage()
            // ConnectedDevicesScreen(),
          ],
        ));
  }
}
