import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camos/pages/network/network_state.dart';
import 'package:camos/pages/dashboard/dashboard_page.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/upload_queue_service.dart';
import 'package:get_storage/get_storage.dart';
import 'core/blocs/attendance/attendance_bloc.dart';
import 'core/blocs/authentication/authentication_bloc.dart';
import 'core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
import 'core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
import 'core/blocs/bluetooth/discover_services_cubit/discover_services_cubit.dart';
import 'core/blocs/bluetooth/pair_device_cubit/pair_device_cubit.dart';
import 'core/blocs/bluetooth/scan_devices_cubit/scan_devices_cubit.dart';
import 'core/blocs/daily_check_post/daily_check_post_bloc.dart';
import 'core/blocs/detail_tire_condition/detail_tire_condition_bloc.dart';
import 'core/blocs/detail_tire_invent/detail_tire_invent_bloc.dart';
import 'core/blocs/network/network_bloc.dart';
import 'core/blocs/outstanding_task/outstanding_task_bloc.dart';
import 'core/blocs/process_jobcard/process_jobcard_bloc.dart';
import 'core/blocs/site/site_bloc.dart';
import 'core/blocs/spm/spm_bloc.dart';
import 'core/blocs/tire/tire_bloc.dart';
import 'core/blocs/tire_condition/tire_condition_bloc.dart';
import 'core/blocs/tire_invent/tire_invent_bloc.dart';
import 'core/blocs/unit/unit_bloc.dart';
import 'core/blocs/wo_jobcard/wo_jobcard_bloc.dart';
import 'core/navigator/routes.dart';
import 'core/services/local_database/outstanding_task/objectbox.dart';
import 'core/services/sheets/attendance_sheets.dart';
import 'core/services/tire_inspection_draft_service.dart';
import 'core/services/tire_inspection_offline_edit_service.dart';
import 'core/utils/functions/functions.dart';
import 'objectbox.g.dart';
import 'pages/opening/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:package_info_plus/package_info_plus.dart';

late Store store;
late List<CameraDescription> cameras;
late List<CameraDescription> camerasTireInspection;
final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(InternetState());
  cameras = await availableCameras();
  // cameras = [cameras[0], cameras[1]];
  store = (await ObjectBox.create()).store;
  TireInspectionDraftService.instance.initialize(store);
  TireInspectionOfflineEditService.instance.initialize(store);
  // initializeHERESDK();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await initializeDateFormatting('id_ID', null);
  if (Platform.isIOS) {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    await Firebase.initializeApp();

    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true, // Aktifkan disk persistence
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } else {
    await Firebase.initializeApp();

    FirebaseFirestore.instance.settings = Settings(
      persistenceEnabled: true, // Aktifkan disk persistence
    );
  }

  await GetStorage.init(); // WAJIB untuk GetStorage

  await Get.putAsync<UploadQueueService>(
    () => UploadQueueService().init(),
  );

  // requestAllPermission();
  requestStoragePermission();

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  runApp(const MyApp());

  // Google Sheets membutuhkan jaringan dan bukan syarat untuk menampilkan UI.
  // Jalankan setelah frame pertama agar koneksi yang lambat tidak menahan
  // aplikasi di native splash screen.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    // unawaited(AttendanceSheetsAPI.initAttendanceSheets());
    unawaited(() async {
      try {
        await TireInspectionDraftService.instance.prepareStorage();
      } catch (error, stackTrace) {
        log(
          'Gagal menyiapkan penyimpanan draft Tire Inspection: $error',
          stackTrace: stackTrace,
        );
      }
    }());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // autentikasi (login, register, verify email, ganti password, edit profil)
        BlocProvider<AuthenticationBloc>(
            create: (context) => AuthenticationBloc()),
        // mengolah data tire di tiap unit
        BlocProvider<TireBloc>(create: (context) => TireBloc()),
        // mengolah data site ck
        BlocProvider<SiteBloc>(create: (context) => SiteBloc()),
        // mengatur koneksi internet
        BlocProvider<NetworkBloc>(
            create: (context) => NetworkBloc()..add(NetworkObserverEvent())),
        // mengolah data absensi
        BlocProvider<AttendanceBloc>(create: (context) => AttendanceBloc()),
        // mengolah data outstanding task
        BlocProvider<OutstandingTaskBloc>(
            create: (context) => OutstandingTaskBloc()
              ..add(ReadOutStandingTaskEvent(selectedDate: []))),
        // mengolah data unit
        BlocProvider<UnitBloc>(create: (context) => UnitBloc()),
        // mengolah data tire running condition
        BlocProvider<TireConditionBloc>(
            create: (context) => TireConditionBloc()),
        // mengolah data tire inventory
        BlocProvider<TireInventBloc>(create: (context) => TireInventBloc()),
        // mengolah data detail tire inventory
        BlocProvider<DetailTireInventBloc>(
            create: (context) => DetailTireInventBloc()),
        // mengolah data detail tire condition
        BlocProvider<DetailTireConditionBloc>(
            create: (context) => DetailTireConditionBloc()),
        // mendapatkan nilai spm
        BlocProvider<SpmBloc>(create: (context) => SpmBloc()),
        // post daily check pressure
        BlocProvider<DailyCheckPostBloc>(
            create: (context) => DailyCheckPostBloc()),
        // get wo jobcard
        BlocProvider<WoJobcardBloc>(create: (context) => WoJobcardBloc()),
        // input jobcard
        BlocProvider<ProcessJobcardBloc>(
            create: (context) => ProcessJobcardBloc()),

        // bluetooth
        BlocProvider(create: ((context) => BluetoothOnOffCubit())),
        BlocProvider(create: ((context) => ScanDevicesCubit())),
        BlocProvider(create: ((context) => ConnectedDevicesCubit())),
        BlocProvider(create: ((context) => PairDeviceCubit())),
        BlocProvider(create: ((context) => DiscoverServicesCubit())),
      ],
      child: GetMaterialApp(
        title: 'Material App',
        debugShowCheckedModeBanner: false,
        navigatorObservers: [routeObserver],
        initialRoute: SplashScreen.routeName,
        routes: routes,
      ),
    );
  }
}
