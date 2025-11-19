import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:app_settings/app_settings.dart';
import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart'
    as connectedDevicesState;
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart';
import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_cubit.dart';
import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_state.dart';
import 'package:camos/core/utils/bluetooth/utils/bluetooth_utils.dart';
import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/scan_device_page.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:camos/core/blocs/outstanding_task/outstanding_task_bloc.dart';
import 'package:camos/core/blocs/tire/tire_bloc.dart';
import 'package:camos/core/blocs/unit/unit_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
import 'package:camos/core/services/local_database/tire_inspect_picture/tire_inspect_picture_entity.dart';
import 'package:camos/core/services/model/outstanding_task.dart';
import 'package:camos/core/services/model/unit_tire.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/oustanding_task.dart';
import 'package:camos/core/utils/data/pgd.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/core/widgets/pgd_tire_card_widget.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:camos/pages/home/home_page.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:carousel_slider/carousel_controller.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';

class TireInspectionFormPage extends StatefulWidget {
  static const routeName = '/pgd-page';
  const TireInspectionFormPage({super.key});

  @override
  State<TireInspectionFormPage> createState() => _TireInspectionFormPageState();
}

class _TireInspectionFormPageState extends State<TireInspectionFormPage>
    with WidgetsBindingObserver {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  final HomeState homeState = Get.find<HomeState>();

  bool _isInit = true;
  int selectedMenu = 1;
  var map = {};
  String idSite = '';
  bool isSaved = false;
  Map<String, dynamic> dataUnit = {};

  TextEditingController idUnit = TextEditingController(text: '');
  TextEditingController hmUnit = TextEditingController(text: '');
  TextEditingController pressureCtrl = TextEditingController(text: '');
  TextEditingController remarksCtrl = TextEditingController(text: '');
  TextEditingController damageCtrl = TextEditingController(text: '');
  TextEditingController rtd1 = TextEditingController(text: '');
  TextEditingController rtd2 = TextEditingController(text: '');
  List<TextEditingController> remarksControllers = [];
  List<TextEditingController> snControllers = [];
  List<TextEditingController> rtd1Controllers = [];
  List<TextEditingController> rtd2Controllers = [];

  SwiperController swiperController = SwiperController();

  String selectedUnit = '';
  List<String> checkedCategories = [];
  List<Map<String, dynamic>> checkedCategoriesManual = [
    {'name': 'Reseal Oring', 'checked': false},
    {'name': 'Rim Condition', 'checked': false},
    {'name': 'Inflate Tire', 'checked': false},
    {'name': 'Lock Driver', 'checked': false},
    {'name': 'Slide Lock', 'checked': false},
    {'name': 'Valve Cap', 'checked': false},
    {'name': 'Valve Protector', 'checked': false},
    {'name': 'Stud and Nut', 'checked': false},
  ];

  List<bool> checkedListCategory = List<bool>.filled(8, false);
  String selectedTireDamage = '';
  String remarks = '';
  String rtd = '';
  List<String> listImg = [];
  Map<String, dynamic> user = {};
  bool _listenerAdded = false;
  int checkAmount = 0;
  int selectedRoute = 0;
  List<List<int>> inspectRoute = [
    [0, 1, 2, 3, 4, 5],
    [0, 2, 3, 4, 5, 1],
    [1, 5, 4, 3, 2, 0],
  ];

  List<String> pressure = [
    '0',
    '95',
    '100',
    '105',
    '110',
    '115',
    '120',
    '125',
    '130',
    '135',
  ];
  List<Map<String, dynamic>> position = [];

  List<String> damageType = [
    'Good Condition',
    'Accident',
    'Bead Crack',
    'Boulder',
    'Bulging',
    'Bead Damage',
    'Chaffer Separation',
    'Dog Bound',
    'Foreign Object',
    'Heat Separation',
    'Inner Linner Separation',
    'Impact',
    'Repair Failure',
    'Radial Crack',
    'Run Flat',
    'Sidewall Crack',
    'Sidewall Cut',
    'Sidewall Cut 2',
    'Sidewall Cut 3',
    'Sidewall Separation',
    'Shoulder Cut',
    'Shoulder Separation',
    'Tread Chipping',
    'Tread Chunking',
    'Tread Lifting',
    'Tread Cut',
    'Tread Cut Separation',
    'Worn Out',
  ];

  List<String> selectedDamage = [];

  List<String> categories = [
    'Reseal Oring',
    'Rim Condition',
    'Inflate Tire',
    'Lock Driver',
    'Slide Lock',
    'Valve Cap',
    'Valve Protector',
    'Stud and Nut',
  ];

  List<String> rating = [
    'A',
    'B',
    'C',
    'X',
  ];

  List<String> pit = [];
  int selectedPit = -1;

  @override
  void initState() {
    idSite = homeState.currentSiteId;

    super.initState();
    requestPlacePermission();

    context.read<BluetoothOnOffCubit>().checkBluetoothStatus();
    final connectedCubit = context.read<ConnectedDevicesCubit>();
    log('connected cubit : $connectedCubit');
    connectedCubit.fetchConnectedDevices(); // HANYA MEMULAI fetch

    // callTires();
    WidgetsBinding.instance.addObserver(this);
    getUser();
  }

  getUser() async {
    user = await getUserPreferences();
    log('username : ${user}');
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null) {
        dataUnit = args as Map<String, dynamic>;
        log('TireInspectionPage: dataUnit berhasil diambil -> $dataUnit');

        // Panggil callTires() setelah dataUnit pasti terisi
        callTires();
      } else {
        log('TireInspectionPage: ERROR! Argumen navigasi null.');
      }

      _isInit = false; // Set flag agar tidak dijalankan lagi
    }
  }

  List<BluetoothDevice> devices = [];
  String tmpPressure = '';
  final Box<TireInspectPictureEntity> imageBox =
      store.box<TireInspectPictureEntity>();

  insertPit() {
    setState(() {
      // if (idSite == '52') {
      //   pit.add('Utara');
      //   pit.add('Selatan');
      //   pit.add('RML');
      //   pit.add('WS');
      // }
    });
  }

  void handleDataChecked(List<bool> checkedList, int index) {
    checkedCategories.clear();

    for (int i = 0; i < checkedList.length; i++) {
      if (checkedList[i] == true) {
        // setState(() {
        checkedCategories.add(categories[i]);
        // });
      }
    }

    // Cetak hasil untuk tujuan pengujian
  }

  void handleDataSelected(String tireDamage, int index) {
    // Perbarui data tire damage
    selectedTireDamage = tireDamage;
  }

  void handleImageTire(List<String> images) {
    listImg.clear();
    listImg.addAll(images);
  }

  void callTires() async {
    String userAccessId = homeState.userAccessId.value;
    if (mounted) {
      if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
        idUnit.text = dataUnit['unitNumber'];
        // hmUnit.text = dataUnit['hm'];
        context.read<TireBloc>().add(GetUnitTiresEvent(
            idSite: idSite, unitNumber: dataUnit['unitNumber']));
      }
    }

    insertPit();
  }

  void handleDataRemarks(String remarks, int index) {
    this.remarks = remarks;
    print('remarks (pgd) : ${this.remarks}');
  }

  void handleDataRTD(String rtd, int index) {
    this.rtd = rtd;
    print('remarks (pgd) : ${this.remarks}');
  }

  void applyPressureData(String pressureValue) {
    setState(() {
      final firstNumber = pressureValue;

      if (checkAmount < position.length) {
        int targetIndex = inspectRoute[selectedRoute][checkAmount];
        log('target position : ${targetIndex}');
        log('target pressure : ${firstNumber}');

        // Update Map di index tersebut
        position[targetIndex]["pressure"] = firstNumber;

        checkAmount++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    pit.clear();
    // if (idSite == '52') {
    //   pit.add('Utara');
    //   pit.add('Selatan');
    //   pit.add('RML');
    //   pit.add('WS');
    // }
    switch (idSite) {
      case '52':
        pit.add('Utara');
        pit.add('Selatan');
        pit.add('RML');
        pit.add('WS');
        break;
      case '137':
        pit.add('Japun');
        pit.add('PCE');
        break;
      case '35':
        pit.add('Tabuhan');
        pit.add('EBL');
        pit.add('Workshop');
        break;
      case '65':
        pit.add('Room B1 Selatan');
        pit.add('Utara');
        pit.add('Serongga');
        pit.add('CSA Selatan');
        pit.add('WS');
        break;
      case '166':
        pit.add('WS');
        pit.add('Pondok Operator');
        pit.add('Pit Stop Toll');
        break;
    }
    print('dipanggil (pgd)');
    dataUnit =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Text(
            'Tire Inspection',
            textAlign: TextAlign.center,
            style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: black),
            ),
            child: IconButton(
                onPressed: () {
                  if (isSaved) {
                    pushReplace(context, HomePage.routeName);
                  } else {
                    back(context);
                  }
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: black,
                  size: 24,
                )),
          ),
        ),
      ),
      body: SafeArea(
          child: BlocConsumer<TireBloc, TireState>(
        listener: (context, state) {
          if (state is TiresLoadedState) {
            position.clear();

            for (int i = 0; i < state.units.length; i++) {
              final unit = state.units[i];
              remarksControllers.add(TextEditingController(text: ''));
              snControllers.add(TextEditingController(text: ''));
              rtd1Controllers.add(TextEditingController(text: ''));
              rtd2Controllers.add(TextEditingController(text: ''));
              position.add({
                'position': i + 1,
                'pressure': '',
                'adjusmentPressure': '',
                'hm': '',
                'damageTire': [],
                'rtd1': '',
                'rtd2': '',
                'remarks': '',
                'sn': unit.sn,
                'rating': '',
                'image': [],
                'idInventory': unit.idinventory,
                'idUnit': unit.idUnit,
                'tireSize': unit.size,
                'condition': [
                  {'name': 'Reseal Oring', 'checked': false},
                  {'name': 'Rim Condition', 'checked': false},
                  {'name': 'Inflate Tire', 'checked': false},
                  {'name': 'Lock Driver', 'checked': false},
                  {'name': 'Slide Lock', 'checked': false},
                  {'name': 'Valve Cap', 'checked': false},
                  {'name': 'Valve Protector', 'checked': false},
                  {'name': 'Stud and Nut', 'checked': false},
                ],
                'tireAccessories': []
              });
            }
            log('message position tire inspect : ${position}');
          }
        },
        builder: (context, state) {
          if (state is TireLoadingState) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (state is TiresLoadedState) {
            final units = state.units;

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    (pit.isNotEmpty)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.ev_station,
                                size: 38,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(
                                'Unit Location',
                                style: getBlackTextStyle(
                                    fontSize: 18, fontWeight: w700),
                              ),
                            ],
                          )
                        : Container(),
                    SizedBox(
                      height: (pit.isNotEmpty) ? 24 : 0,
                    ),
                    (pit.isNotEmpty)
                        ? Center(
                            child: Wrap(
                              spacing: 8.0, // Jarak horizontal antar tombol
                              children: pit.map((e) {
                                final pitIndex = pit.indexOf(e);
                                return ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: (selectedPit == pitIndex)
                                        ? Colors.orange
                                        : greyF7F8F9,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      selectedPit = pitIndex;
                                    });
                                  },
                                  child: Text(
                                    e,
                                    style: (selectedPit == pitIndex)
                                        ? getWhiteTextStyle()
                                        : getBlackTextStyle(),
                                  ),
                                );
                              }).toList(),
                            ),
                          )
                        : Container(),
                    SizedBox(
                      height: (pit.isNotEmpty) ? 24 : 0,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.front_loader,
                                    color: Colors.orange,
                                    size: 38,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    'UNIT',
                                    style: getBlackTextStyle(
                                        fontWeight: w700, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: InputFormWidget(
                                    isReadOnly: true,
                                    controller: TextEditingController(
                                      text: units[0].unitNumber,
                                    ),
                                    hint: ''),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.watch,
                                    color: Colors.red,
                                    size: 38,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    (idSite == bmbhauling.idSite)
                                        ? 'KM Unit'
                                        : 'HM Unit',
                                    style: getBlackTextStyle(
                                        fontWeight: w700, fontSize: 18),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Builder(builder: (context) {
                                print("id site hauling : $idSite");
                                hmUnit.text = (idSite != bmbhauling.idSite)
                                    ? (units[0].hm ?? '')
                                    : '';

                                return SizedBox(
                                  width: double.infinity,
                                  child: InputFormWidget(
                                      // isReadOnly: true,
                                      // controller: hmCtrl,
                                      controller: hmUnit,
                                      isDecimalOnly: true,
                                      type: TextInputType.number,
                                      hint:
                                          'Fill ${idSite == bmbhauling.idSite ? 'KM' : 'HM'}'),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    BlocBuilder<ConnectedDevicesCubit, ConnectedDevicesState>(
                      builder: (context, cState) {
                        // Asumsikan perangkat TPMS adalah yang terhubung jika statusnya Success
                        final isConnected =
                            cState is ConnectedDevicesLoadedState &&
                                cState.connectedDevices.isNotEmpty;

                        // Cari perangkat yang terhubung yang memiliki nama yang relevan
                        // (Anda harus menyesuaikan logika pencarian ini sesuai nama perangkat BT Anda)
                        final BluetoothDevice? connectedDevice = isConnected
                            ? cState.connectedDevices
                                .firstWhereOrNull((d) => d.advName.isNotEmpty)
                            : null;

                        final String buttonText = isConnected
                            ? 'Connected: ${connectedDevice?.advName ?? connectedDevice?.remoteId.str}'
                            : 'Scan Devices';

                        return ButtonWidget(
                          // Warna tombol berdasarkan status koneksi
                          color: isConnected ? green00968A : Colors.blue,
                          name: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bluetooth,
                                color: white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                buttonText,
                                style: getWhiteTextStyle(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          function: () async {},
                        );
                      },
                    ),
                    BlocListener<BluetoothOnOffCubit, BluetoothOnOffState>(
                      listener: (context, onOffState) {
                        if (onOffState is BluetoothOnState) {
                          context
                              .read<ConnectedDevicesCubit>()
                              .fetchConnectedDevices();
                        }
                      },
                      child: BlocConsumer<ConnectedDevicesCubit,
                          ConnectedDevicesState>(
                        listener: (context, state) {
                          if (state is ConnectedDevicesLoadedState &&
                              state.connectedDevices.isNotEmpty) {
                            context
                                .read<DiscoverServicesCubit>()
                                .discoverServices(state.connectedDevices.first);
                          }
                        },
                        builder: (context, state) {
                          if (state is ConnectedDevicesLoadedState) {
                            // return _buildConnectedDeviceUI(
                            //     state.connectedDevices);
                            BlocProvider.of<DiscoverServicesCubit>(
                              context,
                            ).discoverServices(state.connectedDevices[0]);
                            return BlocConsumer<DiscoverServicesCubit,
                                DiscoverServiceState>(
                              listener: (context, discoverState) {
                                if (discoverState is ServicesLoadedState) {
                                  final services = discoverState.services;
                                  log('services pgd : $services');

                                  if (!_listenerAdded) {
                                    _listenerAdded = true;
                                    for (BluetoothService service in services) {
                                      for (BluetoothCharacteristic characteristic
                                          in service.characteristics) {
                                        if (characteristic.properties.notify) {
                                          characteristic.onValueReceived
                                              .listen((value) {
                                            final notifInString =
                                                String.fromCharCodes(value);
                                            log("angin bergejolak: $notifInString");

                                            debugPrint(
                                              "debugBluetoothNotification*************",
                                            );
                                            debugPrint(
                                              "debugBluetoothNotification: charName: ${BluetoothUtils.getBluetoothChar(characteristic.characteristicUuid.str)}",
                                            );

                                            debugPrint(
                                              "notifhohoho: stringNotif: $notifInString",
                                            );
                                            setState(() {
                                              String press = '';

                                              if (notifInString.contains('|')) {
                                                int floorPressure =
                                                    double.parse(
                                                  notifInString.split(
                                                    '|',
                                                  )[0],
                                                ).floor();

                                                // int floorTemperature =
                                                //     double.parse(
                                                //       notifInString.split(
                                                //         '|',
                                                //       )[1],
                                                //     ).floor();
                                                // temperature = floorTemperature
                                                //     .toString();
                                                applyPressureData(
                                                    floorPressure.toString());
                                              } else {
                                                int floorPressure =
                                                    double.parse(
                                                  notifInString,
                                                ).floor();
                                                press.toString();
                                                applyPressureData(
                                                    floorPressure.toString());
                                              }
                                            });

                                            debugPrint(
                                              "debugBluetoothNotification*************",
                                            );
                                          });

                                          characteristic
                                              .setNotifyValue(true); // WAJIB
                                        }
                                      }
                                    }
                                  }
                                }
                              },
                              builder: (context, discoverState) {
                                if (discoverState is ErrorLoadingServiceState) {
                                  return Center(child: Text('Error'));
                                }
                                return Container();
                              },
                            );
                          }
                          return CircularProgressIndicator();
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: units.length,
                        itemBuilder: (context, index) {
                          final unit = units[index];
                          snControllers[index].text = unit.sn ?? '';

                          return Card(
                            elevation: 2,
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              padding: EdgeInsets.all(24),
                              child: Stack(
                                children: [
                                  Opacity(
                                    opacity: 0.1,
                                    child: Center(
                                      child: Text(
                                        unit.rating ?? '',
                                        style: TextStyle(
                                          fontSize: 100,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          SizedBox(
                                            width: 35,
                                            height: 53,
                                            child: Image.asset(
                                              '$imagePath/em_tire_image.png',
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Position',
                                                style: getBlackTextStyle(
                                                    fontSize: 14),
                                              ),
                                              const SizedBox(
                                                height: 6,
                                              ),
                                              Text(
                                                '${index + 1}',
                                                style: getBlackTextStyle(
                                                    fontSize: 22,
                                                    fontWeight: w700),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6),
                                        child: Divider(
                                          thickness: 1.5,
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Unit',
                                                style: getBlackTextStyle(
                                                    fontWeight: w700),
                                              ),
                                              Text(
                                                unit.unitNumber ?? '',
                                                style: getBlackTextStyle(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'SN',
                                                style: getBlackTextStyle(
                                                    fontWeight: w700),
                                              ),
                                              Text(
                                                unit.sn ?? '',
                                                style: getBlackTextStyle(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Brand',
                                                style: getBlackTextStyle(
                                                    fontWeight: w700),
                                              ),
                                              Text(
                                                unit.brand ?? '',
                                                style: getBlackTextStyle(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Tire Lifetime',
                                                style: getBlackTextStyle(
                                                    fontWeight: w700),
                                              ),
                                              Text(
                                                unit.lifetime ?? '',
                                                style: getBlackTextStyle(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Rating',
                                                style: getBlackTextStyle(
                                                    fontWeight: w700),
                                              ),
                                              Text(
                                                unit.rating ?? '',
                                                style: getBlackTextStyle(),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'RTD',
                                                style: getBlackTextStyle(
                                                    fontWeight: w700),
                                              ),
                                              Text(
                                                '${unit.rtd} / ${unit.otd}' ??
                                                    '',
                                                style: getBlackTextStyle(),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6),
                                        child: Divider(
                                          thickness: 1.5,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: 45,
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                  setState(() {
                                                    // selectedPosIndex = posIndex;
                                                  });
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return Dialog(
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  20.0),
                                                          child:
                                                              SingleChildScrollView(
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <Widget>[
                                                                Text(
                                                                  'Choose Pressure',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        24.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        16.0),
                                                                Column(),
                                                                Wrap(
                                                                  children:
                                                                      pressure.map(
                                                                          (ps) {
                                                                    final psIndex =
                                                                        pressure
                                                                            .indexOf(ps);
                                                                    return Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              16,
                                                                          bottom:
                                                                              18),
                                                                      child:
                                                                          ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.green),
                                                                        onPressed:
                                                                            () {
                                                                          final id =
                                                                              Uuid();
                                                                          setState(
                                                                              () {
                                                                            position[index]['pressure'] =
                                                                                ps;
                                                                            Navigator.of(context).pop();
                                                                          });
                                                                        },
                                                                        child:
                                                                            Text(
                                                                          ps,
                                                                          style:
                                                                              getWhiteTextStyle(
                                                                            fontWeight:
                                                                                w700,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          SizedBox(
                                                                        width: double
                                                                            .infinity,
                                                                        child: InputFormWidget(
                                                                            controller:
                                                                                pressureCtrl,
                                                                            isDigitOnly:
                                                                                true,
                                                                            type:
                                                                                TextInputType.number,
                                                                            hint: 'Input Manual'),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    ElevatedButton(
                                                                        onPressed:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            if (pressureCtrl.text !=
                                                                                '') {
                                                                              position[index]['pressure'] = pressureCtrl.text;
                                                                            }
                                                                            pressureCtrl.clear();
                                                                            Navigator.of(context).pop();
                                                                          });
                                                                        },
                                                                        child: Text(
                                                                            'Submit'))
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        12.0),
                                                                SizedBox(
                                                                  width: double
                                                                      .infinity,
                                                                  child:
                                                                      ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      pressureCtrl
                                                                          .clear();
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                    child: Text(
                                                                        'Close'),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    )),
                                                child: (position[index]
                                                                ['pressure'] ==
                                                            '' ||
                                                        (position[index]
                                                                ['pressure'] ==
                                                            null))
                                                    ? Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.add,
                                                            color: white,
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            'Pressure',
                                                            style:
                                                                getWhiteTextStyle(),
                                                          )
                                                        ],
                                                      )
                                                    : Text(
                                                        '${position[index]['pressure']} Psi',
                                                        style:
                                                            getWhiteTextStyle(
                                                          fontSize: 24,
                                                          fontWeight: w700,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                          // adjusment pressure
                                          Expanded(
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                  .size
                                                  .width,
                                              height: 45,
                                              child: ElevatedButton(
                                                onPressed: () async {
                                                  FocusScope.of(context)
                                                      .unfocus();
                                                  setState(() {
                                                    // selectedPosIndex = posIndex;
                                                  });
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return Dialog(
                                                        child: Container(
                                                          padding:
                                                              EdgeInsets.all(
                                                                  20.0),
                                                          child:
                                                              SingleChildScrollView(
                                                            child: Column(
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: <Widget>[
                                                                Text(
                                                                  'Choose Pressure',
                                                                  style:
                                                                      TextStyle(
                                                                    fontSize:
                                                                        24.0,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        16.0),
                                                                Column(),
                                                                Wrap(
                                                                  children:
                                                                      pressure.map(
                                                                          (ps) {
                                                                    final psIndex =
                                                                        pressure
                                                                            .indexOf(ps);
                                                                    return Padding(
                                                                      padding: const EdgeInsets
                                                                          .only(
                                                                          right:
                                                                              16,
                                                                          bottom:
                                                                              18),
                                                                      child:
                                                                          ElevatedButton(
                                                                        style: ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.green),
                                                                        onPressed:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            position[index]['adjusmentPressure'] =
                                                                                ps;
                                                                            Navigator.of(context).pop();
                                                                          });
                                                                        },
                                                                        child:
                                                                            Text(
                                                                          ps,
                                                                          style:
                                                                              getWhiteTextStyle(
                                                                            fontWeight:
                                                                                w700,
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  }).toList(),
                                                                ),
                                                                Row(
                                                                  children: [
                                                                    Expanded(
                                                                      child:
                                                                          SizedBox(
                                                                        width: double
                                                                            .infinity,
                                                                        child: InputFormWidget(
                                                                            controller:
                                                                                pressureCtrl,
                                                                            isDigitOnly:
                                                                                true,
                                                                            type:
                                                                                TextInputType.number,
                                                                            hint: 'Input Manual'),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(
                                                                      width: 6,
                                                                    ),
                                                                    ElevatedButton(
                                                                        onPressed:
                                                                            () {
                                                                          setState(
                                                                              () {
                                                                            if (pressureCtrl.text !=
                                                                                '') {
                                                                              position[index]['adjusmentPressure'] = pressureCtrl.text;
                                                                            }
                                                                            pressureCtrl.clear();
                                                                            Navigator.of(context).pop();
                                                                          });
                                                                        },
                                                                        child: Text(
                                                                            'Submit'))
                                                                  ],
                                                                ),
                                                                SizedBox(
                                                                    height:
                                                                        12.0),
                                                                SizedBox(
                                                                  width: double
                                                                      .infinity,
                                                                  child:
                                                                      ElevatedButton(
                                                                    onPressed:
                                                                        () {
                                                                      pressureCtrl
                                                                          .clear();
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    },
                                                                    child: Text(
                                                                        'Close'),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.blue,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    )),
                                                child: (position[index][
                                                            'adjusmentPressure'] ==
                                                        '')
                                                    ? Text(
                                                        'Adj Pressure',
                                                        style:
                                                            getWhiteTextStyle(),
                                                      )
                                                    : Text(
                                                        '${position[index]['adjusmentPressure']} Psi (Adj)',
                                                        style:
                                                            getWhiteTextStyle(
                                                          fontSize: 16,
                                                          fontWeight: w700,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(
                                        height: 12,
                                      ),

                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        height: 45,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            FocusScope.of(context).unfocus();
                                            // setState(() {
                                            //   selectedPosIndex = posIndex;
                                            // });

                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return Dialog(
                                                  child: Container(
                                                    padding:
                                                        EdgeInsets.all(20.0),
                                                    child:
                                                        SingleChildScrollView(
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          Text(
                                                            'Choose Rating',
                                                            style: TextStyle(
                                                              fontSize: 24.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height: 16.0),
                                                          Column(),
                                                          Wrap(
                                                            children: rating
                                                                .map((rat) {
                                                              final ratingIndex =
                                                                  rating
                                                                      .indexOf(
                                                                          rat);
                                                              return Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            16,
                                                                        bottom:
                                                                            18),
                                                                child:
                                                                    ElevatedButton(
                                                                  style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .green),
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {
                                                                      position[index]
                                                                              [
                                                                              'rating'] =
                                                                          rat;
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop();
                                                                    });
                                                                  },
                                                                  child: Text(
                                                                    rat,
                                                                    style:
                                                                        getWhiteTextStyle(
                                                                      fontWeight:
                                                                          w700,
                                                                    ),
                                                                  ),
                                                                ),
                                                              );
                                                            }).toList(),
                                                          ),
                                                          SizedBox(
                                                              height: 12.0),
                                                          SizedBox(
                                                            width:
                                                                double.infinity,
                                                            child:
                                                                ElevatedButton(
                                                              onPressed: () {
                                                                pressureCtrl
                                                                    .clear();
                                                                Navigator.of(
                                                                        context)
                                                                    .pop();
                                                              },
                                                              child:
                                                                  Text('Close'),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              )),
                                          child: (position[index]['rating'] ==
                                                  '')
                                              ? Text(
                                                  'Rating',
                                                  style: getWhiteTextStyle(),
                                                )
                                              : Text(
                                                  'Rating ${position[index]['rating']}',
                                                  style: getWhiteTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: w700,
                                                  ),
                                                ),
                                        ),
                                      ),

                                      const SizedBox(
                                        height: 12,
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        child: ElevatedButton(
                                            onPressed: () {
                                              FocusScope.of(context).unfocus();
                                              List<bool> checkedDamageValues =
                                                  List<bool>.filled(
                                                      damageType.length, false);

                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  return Dialog(
                                                    child: Container(
                                                      padding:
                                                          EdgeInsets.all(20.0),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: <Widget>[
                                                          Text(
                                                            'Choose Damage Tire',
                                                            style: TextStyle(
                                                              fontSize: 24.0,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height: 12.0),
                                                          Expanded(
                                                            child:
                                                                SingleChildScrollView(
                                                              child: Column(
                                                                children:
                                                                    damageType.map(
                                                                        (damage) {
                                                                  final dmgIndex =
                                                                      damageType
                                                                          .indexOf(
                                                                              damage);

                                                                  if (dmgIndex >
                                                                      0) {
                                                                    return StatefulBuilder(builder:
                                                                        (context,
                                                                            setState) {
                                                                      return CheckboxListTile(
                                                                        title: Text(
                                                                            damage),
                                                                        value: checkedDamageValues[
                                                                            dmgIndex],
                                                                        onChanged:
                                                                            (bool?
                                                                                value) {
                                                                          setState(
                                                                              () {
                                                                            checkedDamageValues[dmgIndex] =
                                                                                value ?? false;
                                                                          });
                                                                        },
                                                                      );
                                                                    });
                                                                  }
                                                                  return Container();
                                                                }).toList(),
                                                              ),
                                                            ),
                                                          ),
                                                          SizedBox(
                                                              height:
                                                                  12.0), // Tambahkan sedikit jarak antara daftar checkbox dan tombol "Close"
                                                          Column(
                                                            children: [
                                                              SizedBox(
                                                                height: 42,
                                                                width: double
                                                                    .infinity,
                                                                child: InputFormWidget(
                                                                    controller:
                                                                        damageCtrl,
                                                                    hint:
                                                                        'Input Manual Here....'),
                                                              ),
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                              SizedBox(
                                                                width: double
                                                                    .infinity,
                                                                child:
                                                                    ElevatedButton(
                                                                  onPressed:
                                                                      () {
                                                                    damageCtrl
                                                                        .clear();
                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: Text(
                                                                      'Close'),
                                                                ),
                                                              ),
                                                              const SizedBox(
                                                                height: 12,
                                                              ),
                                                              SizedBox(
                                                                width: double
                                                                    .infinity,
                                                                child:
                                                                    ElevatedButton(
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .green,
                                                                  ),
                                                                  onPressed:
                                                                      () {
                                                                    setState(
                                                                        () {});

                                                                    selectedDamage
                                                                        .clear();
                                                                    final List<
                                                                            String>
                                                                        tmp =
                                                                        [];
                                                                    if (damageCtrl.text ==
                                                                            '' ||
                                                                        damageCtrl
                                                                            .text
                                                                            .isNotEmpty) {
                                                                      tmp.add(damageCtrl
                                                                          .text);
                                                                    }
                                                                    for (int i =
                                                                            0;
                                                                        i < checkedDamageValues.length;
                                                                        i++) {
                                                                      if (checkedDamageValues[
                                                                          i]) {
                                                                        tmp.add(
                                                                            damageType[i]);
                                                                      }
                                                                    }
                                                                    position[index]
                                                                            [
                                                                            'damageTire'] =
                                                                        tmp;
                                                                    if (tmp
                                                                        .isNotEmpty) {
                                                                      position[index]
                                                                              [
                                                                              'damageTire'] =
                                                                          tmp;
                                                                      selectedDamage
                                                                          .addAll(
                                                                              tmp);
                                                                      log('hasil luka ban : ${position}');
                                                                    }
                                                                    damageCtrl
                                                                        .clear();

                                                                    Navigator.pop(
                                                                        context);
                                                                  },
                                                                  child: Text(
                                                                    'Submit',
                                                                    style:
                                                                        getWhiteTextStyle(
                                                                      fontWeight:
                                                                          w700,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: blue344BEF,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                )),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8.0),
                                              child: Text(
                                                (position[index][
                                                                'damageTire'] ==
                                                            null ||
                                                        position[index][
                                                                'damageTire'] ==
                                                            [] ||
                                                        (position[index][
                                                                    'damageTire']
                                                                as List<
                                                                    dynamic>)
                                                            .isEmpty)
                                                    ? 'Damage Tire (None)'
                                                    : position[index]
                                                            ['damageTire']
                                                        .join('\n---\n'),
                                                textAlign: TextAlign.center,
                                                style: getWhiteTextStyle(
                                                    fontSize: 14),
                                              ),
                                            )),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 45,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.green,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                )),
                                            onPressed: () async {
                                              requestCameraPermission();
                                              final ImagePicker picker =
                                                  ImagePicker();
                                              final XFile? image =
                                                  await picker.pickImage(
                                                      imageQuality: 50,
                                                      source:
                                                          ImageSource.camera);
                                              try {
                                                if (image != null) {
                                                  Directory? directory;

                                                  if (Platform.isAndroid) {
                                                    // path = await getExternalStorageDirectory();
                                                    directory =
                                                        await DownloadsPath
                                                            .downloadsDirectory();
                                                  }

                                                  if (Platform.isIOS) {
                                                    // final directory = await getApplicationDocumentsDirectory();
                                                    // path = directory;
                                                    directory =
                                                        await getApplicationDocumentsDirectory();
                                                  }

                                                  // Read image as a file
                                                  File imageFile =
                                                      File(image.path);
                                                  // data size fotonya
                                                  final compressedFilePath =
                                                      '${directory?.path}/${DateTime.now().millisecondsSinceEpoch}_tireinspectionimage_compressed.jpg';

                                                  // Compress the image if needed (optional)
                                                  final compressedImageFile =
                                                      await FlutterImageCompress
                                                          .compressAndGetFile(
                                                    imageFile.path,
                                                    compressedFilePath,
                                                    quality: 50,
                                                  );
                                                  log('gambar : ${compressedFilePath}');

                                                  // listImg.add(
                                                  //     '${compressedImageFile?.path}|${position[index]['position']}' ??
                                                  //         '');
                                                  position[index]['image'] = [
                                                    '${compressedImageFile?.path}|${position[index]['position']}'
                                                  ];

                                                  // // Convert image to base64
                                                }
                                              } catch (e) {
                                                log('error gambar string : $e');
                                              }

                                              setState(() {});
                                            },
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.camera_alt,
                                                  color: white,
                                                ),
                                                const SizedBox(
                                                  width: 12,
                                                ),
                                                Text(
                                                  'Take Picture',
                                                  style: getWhiteTextStyle(),
                                                ),
                                              ],
                                            )),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Text(
                                        '*You can only take one picture. If you take another picture, the previous one will be deleted.',
                                        style: getRedTextStyle(),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      ((position[index]['image']
                                                  as List<dynamic>)
                                              .isNotEmpty)
                                          ? Column(
                                              children: [
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 45,
                                                  child: ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                              backgroundColor:
                                                                  Colors
                                                                      .deepOrange,
                                                              shape:
                                                                  RoundedRectangleBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              )),
                                                      onPressed: () async {
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) {
                                                              return AlertDialog(
                                                                content: Text(
                                                                  'Are you sure you want to delete this image?',
                                                                  style:
                                                                      getBlackTextStyle(),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.pop(
                                                                            context);
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        'Cancel',
                                                                        style: getGreyTextStyle(
                                                                            grey8391A1),
                                                                      )),
                                                                  TextButton(
                                                                      onPressed:
                                                                          () {
                                                                        position[index]
                                                                            [
                                                                            'image'] = [];
                                                                        Navigator.pop(
                                                                            context);
                                                                        setState(
                                                                            () {});
                                                                      },
                                                                      child:
                                                                          Text(
                                                                        'Yes',
                                                                        style:
                                                                            getRedTextStyle(),
                                                                      )),
                                                                ],
                                                              );
                                                            });

                                                        setState(() {});
                                                      },
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(
                                                            Icons.delete,
                                                            color: white,
                                                          ),
                                                          const SizedBox(
                                                            width: 12,
                                                          ),
                                                          Text(
                                                            'Delete Picture',
                                                            style:
                                                                getWhiteTextStyle(),
                                                          ),
                                                        ],
                                                      )),
                                                ),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                Container(
                                                    width: double.infinity,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    child: Image.file(File(
                                                        (position[index]
                                                                    ['image'][0]
                                                                as String)
                                                            .split('|')[0]))),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                              ],
                                            )
                                          : Container(),

                                      // Show More Images
                                      // (listImg.isNotEmpty)
                                      //     ? Column(
                                      //         children: [
                                      //           SizedBox(
                                      //             width: double.infinity,
                                      //             height: 45,
                                      //             child: ElevatedButton(
                                      //                 style: ElevatedButton
                                      //                     .styleFrom(
                                      //                         backgroundColor:
                                      //                             Colors
                                      //                                 .orange,
                                      //                         shape:
                                      //                             RoundedRectangleBorder(
                                      //                           borderRadius:
                                      //                               BorderRadius.circular(
                                      //                                   12),
                                      //                         )),
                                      //                 onPressed: () async {
                                      //                   final CarouselController
                                      //                       _controller =
                                      //                       CarouselController();

                                      //                   showDialog(
                                      //                       context:
                                      //                           context,
                                      //                       builder:
                                      //                           (BuildContext
                                      //                               context) {
                                      //                         return AlertDialog(
                                      //                           content:
                                      //                               Padding(
                                      //                             padding: const EdgeInsets
                                      //                                 .all(
                                      //                                 24.0),
                                      //                             child:
                                      //                                 Column(
                                      //                               mainAxisSize:
                                      //                                   MainAxisSize.min,
                                      //                               children: [
                                      //                                 Text(
                                      //                                   'Show Image',
                                      //                                   style:
                                      //                                       getBlackTextStyle(),
                                      //                                 ),
                                      //                                 const SizedBox(
                                      //                                   height:
                                      //                                       12,
                                      //                                 ),
                                      //                                 Container(
                                      //                                   width:
                                      //                                       400,
                                      //                                   height:
                                      //                                       400,
                                      //                                   child:
                                      //                                       CarouselSlider(
                                      //                                     carouselController: _controller,
                                      //                                     // items: listImg.map((img) {
                                      //                                     //   final splitImg = img.split('|');

                                      //                                     //   if ((position[index]['position']).toString() == splitImg[1]) {
                                      //                                     //     return Image.file(File(splitImg[0]));
                                      //                                     //   }
                                      //                                     //   return Container();
                                      //                                     // }).toList(),
                                      //                                     items: listImg
                                      //                                         .where((img) {
                                      //                                           final splitImg = img.split('|');
                                      //                                           return splitImg[1] == (position[index]['position']).toString();
                                      //                                         })
                                      //                                         .toList()
                                      //                                         .map((img2) {
                                      //                                           final splitImg2 = img2.split('|');
                                      //                                           return Image.file(File(splitImg2[0]));
                                      //                                         })
                                      //                                         .toList(),
                                      //                                     options: CarouselOptions(
                                      //                                       aspectRatio: 3.0,
                                      //                                       height: 400,
                                      //                                       enableInfiniteScroll: false,
                                      //                                       enlargeCenterPage: true,
                                      //                                     ),
                                      //                                   ),
                                      //                                 ),
                                      //                               ],
                                      //                             ),
                                      //                           ),
                                      //                         );
                                      //                       });
                                      //                   setState(() {});
                                      //                 },
                                      //                 child: Row(
                                      //                   mainAxisAlignment:
                                      //                       MainAxisAlignment
                                      //                           .center,
                                      //                   children: [
                                      //                     Icon(
                                      //                       Icons.image,
                                      //                       color: white,
                                      //                     ),
                                      //                     const SizedBox(
                                      //                       width: 12,
                                      //                     ),
                                      //                     Text(
                                      //                       'Show Image',
                                      //                       style:
                                      //                           getWhiteTextStyle(),
                                      //                     ),
                                      //                   ],
                                      //                 )),
                                      //           ),
                                      //           const SizedBox(
                                      //             height: 12,
                                      //           ),
                                      //         ],
                                      //       )
                                      //     : Container(),

                                      Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  'RTD 1',
                                                  style: getBlackTextStyle(
                                                      fontWeight: w700),
                                                ),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: InputFormWidget(
                                                      onChng: (value) {
                                                        position[index]
                                                            ['rtd1'] = value;
                                                      },
                                                      controller:
                                                          rtd1Controllers[
                                                              index],
                                                      hint: ''),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text(
                                                  'RTD 2',
                                                  style: getBlackTextStyle(
                                                      fontWeight: w700),
                                                ),
                                                const SizedBox(
                                                  height: 12,
                                                ),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: InputFormWidget(
                                                      onChng: (value) {
                                                        position[index]
                                                            ['rtd2'] = value;
                                                      },
                                                      controller:
                                                          rtd2Controllers[
                                                              index],
                                                      hint: ''),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'Serial Number',
                                            style: getBlackTextStyle(
                                                fontWeight: w700),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: InputFormWidget(
                                                onChng: (value) {
                                                  position[index]['sn'] = value;
                                                },
                                                controller:
                                                    snControllers[index],
                                                hint: ''),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'Remarks',
                                            style: getBlackTextStyle(
                                                fontWeight: w700),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: InputFormWidget(
                                                onChng: (value) {
                                                  position[index]['remarks'] =
                                                      value;
                                                },
                                                controller:
                                                    remarksControllers[index],
                                                hint: ''),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(
                                        height: 24,
                                      ),
                                      Text(
                                        'Broken Component (Optional)',
                                        style:
                                            getBlackTextStyle(fontWeight: w700),
                                      ),
                                      SizedBox(
                                        // height: 160,
                                        child: GridView.builder(
                                            physics:
                                                NeverScrollableScrollPhysics(),
                                            shrinkWrap: true,
                                            itemCount: position[index]
                                                    ['condition']
                                                .length,
                                            gridDelegate:
                                                SliverGridDelegateWithFixedCrossAxisCount(
                                                    crossAxisCount: 2,
                                                    childAspectRatio: 3),
                                            itemBuilder:
                                                (context, indexBroken) {
                                              final broken = position[index]
                                                  ['condition'][indexBroken];
                                              return InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    // checkedListCategory[
                                                    //         index] =
                                                    //     !checkedListCategory[
                                                    //         index];
                                                    broken['checked'] =
                                                        !broken['checked'];
                                                  });
                                                  // widget.onCategoryChecked(checkedListCategory);
                                                },
                                                child: Container(
                                                  padding: EdgeInsets.all(10),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 24,
                                                        height: 24,
                                                        decoration:
                                                            BoxDecoration(
                                                          color: broken[
                                                                  'checked']
                                                              ? black
                                                              : Colors
                                                                  .transparent,
                                                          border: Border.all(
                                                              color:
                                                                  Colors.black),
                                                        ),
                                                        child: Icon(
                                                          Icons.check,
                                                          color: Colors.white,
                                                          size: 16,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      LayoutBuilder(builder:
                                                          (context,
                                                              constraints) {
                                                        double fontSize =
                                                            constraints
                                                                    .maxHeight *
                                                                0.35;
                                                        // log('ukuran' + fontSize.toString());
                                                        return Text(
                                                          broken['name'],
                                                          style:
                                                              getBlackTextStyle(
                                                                  fontSize:
                                                                      fontSize),
                                                        );
                                                      }),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                  ],
                ),
              ),
            );
          }
          return Container();
        },
      )),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocBuilder<TireBloc, TireState>(
            builder: (context, state) {
              if (state is TiresLoadedState) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 24),
                  child: ButtonWidget(
                      name: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.save_alt),
                          const SizedBox(
                            width: 6,
                          ),
                          Text(
                            'Save',
                            style: getWhiteTextStyle(),
                          ),
                        ],
                      ),
                      function: (selectedMenu == 0)
                          ? () {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                  'Successful save data, please check in home page',
                                  style: getWhiteTextStyle(),
                                ),
                                backgroundColor: green00968A,
                              ));
                              final id = Uuid();
                              final fixId = id.v4();
                              isSaved = true;
                              final savedTires =
                                  state.units[swiperController.index];

                              imageBox.put(TireInspectPictureEntity(
                                  idImage: fixId, image: ''));

                              // Disimpan di objectbox
                              context
                                  .read<OutstandingTaskBloc>()
                                  .add(AddOutStandingTaskEvent(
                                      task: OutstandingTask(
                                    id: id.v4(),
                                    idSite: idSite,
                                    user: auth.currentUser!.email ?? '',
                                    userEmail: auth.currentUser!.email ?? '',
                                    unit: idUnit.text,
                                    position:
                                        int.parse(savedTires.posisi ?? '0'),
                                    brand: savedTires.brand ?? '',
                                    serialNumber: savedTires.sn ?? '',
                                    tireSize: savedTires.size ?? '',
                                    hm: hmUnit.text,
                                    condition: checkedCategories
                                        .map((category) => category)
                                        .toList(),
                                    tireDamage: selectedTireDamage,
                                    remarks: remarks,
                                    rtd: rtd,
                                    pressure: pressureCtrl.text,
                                    adjusmentPressure: pressureCtrl.text,
                                    lastUpdate:
                                        DateTime.now().toIso8601String(),
                                    isDone: false,
                                    sn: savedTires.sn ?? '',
                                    images: (Platform.isAndroid) ? listImg : [],
                                    kunciUnit: savedTires.kunciUnit ?? '',
                                    kunciTire: savedTires.kunciTire ?? '',
                                  )));

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                      backgroundColor: green00968A,
                                      content: Text(
                                        'Succesful Save Data',
                                        style: getWhiteTextStyle(),
                                      )));
                            }
                          // PAKAI YANG INI!!!!
                          : () async {
                              // jika data pressure kosong
                              bool hasEmptyPressure =
                                  position.any((p) => p['pressure'] == '');

                              if (hasEmptyPressure) {
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: Colors.red,
                                    content: Text(
                                      'Please input data pressure (Choose 0 Psi if No Tire or Block Valve)',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                );
                                return;
                              }
                              // jika belum memeilih pit
                              if (idSite == bmbsitarum.idSite ||
                                  idSite == bmbhauling.idSite ||
                                  idSite == bmbtabuhan.idSite ||
                                  idSite == bibkgb.idSite) {
                                if (selectedPit == -1) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        'Please select location of unit first!',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }

                              // input ke tire inspection
                              try {
                                position.removeWhere((element) =>
                                    element['pressure'] == '' &&
                                    (element['damageTire'] as List<dynamic>)
                                        .isEmpty &&
                                    element['adjusmentPressure'] == '' &&
                                    element['rtd1'] == '' &&
                                    element['rtd2'] == '' &&
                                    element['rating'] == '' &&
                                    element['sn'] == '' &&
                                    element['remarks'] == '');

                                for (int i = 0; i < position.length; i++) {
                                  final unit = state.units[i];
                                  final id = Uuid();

                                  if (position[i]['pressure'] != '' ||
                                      position[i]['hm'] != '' ||
                                      position[i]['damageTire'] != [] ||
                                      position[i]['damageTire'][0] !=
                                          damageType[0] ||
                                      position[i]['adjusmentPressure'] != '' ||
                                      position[i]['rtd1'] != '' ||
                                      position[i]['rtd2'] != '' ||
                                      position[i]['rating'] != '' ||
                                      position[i]['sn'] != '' ||
                                      position[i]['remarks'] != '') {
                                    final today = DateTime.now();
                                    final startOfDay = DateTime(
                                        today.year, today.month, today.day);
                                    final endOfDay = DateTime(today.year,
                                        today.month, today.day, 23, 59, 59);

                                    final querySnapshot = await firestore
                                        .collection('task')
                                        .where('kunci_unit',
                                            isEqualTo: unit.kunciUnit)
                                        .where('kunci_tire',
                                            isEqualTo: unit.kunciTire)
                                        .where('position',
                                            isEqualTo: position[i]['position'])
                                        .where('last_update',
                                            isGreaterThanOrEqualTo:
                                                startOfDay.toIso8601String())
                                        .where('last_update',
                                            isLessThanOrEqualTo:
                                                endOfDay.toIso8601String())
                                        .get();

                                    log('adakah query : ${querySnapshot.docs.isNotEmpty}');

                                    if (querySnapshot.docs.isNotEmpty) {
                                      // Update the existing document
                                      final docId = querySnapshot.docs.first.id;
                                      // try {
                                      //   log('kenapa gagal 3 ${position[i]['image'] as List<dynamic>}');
                                      // } catch (e) {
                                      //   log('kenapa gagal 4 ${e}');
                                      // }

                                      await firestore
                                          .collection('task')
                                          .doc(docId)
                                          .update({
                                        'id': id.v4(),
                                        'id_site': idSite,
                                        'user': user['username'] ?? 'username',
                                        'user_email': auth.currentUser!.email,
                                        'unit': unit.unitNumber,
                                        'serial_number': unit.sn,
                                        'condition': position[i]['condition']
                                            .where((condition) =>
                                                condition['checked'] == true)
                                            .map((condition) =>
                                                condition['name'].toString())
                                            .toList(),
                                        'tire_size': unit.size,
                                        'hm': hmUnit.text,
                                        'position': position[i]['position'],
                                        'rating': position[i]['rating'],
                                        'brand': unit.brand,
                                        'tire_damage':
                                            (position[i]['damageTire'].isEmpty)
                                                ? damageType[0]
                                                : position[i]['damageTire'],
                                        'remarks': position[i]['remarks'],
                                        'rtd':
                                            '${position[i]['rtd1']}/${position[i]['rtd2']}',
                                        'pressure': position[i]['pressure'],
                                        'adjusmentPressure': position[i]
                                            ['adjusmentPressure'],
                                        'last_update':
                                            DateTime.now().toIso8601String(),
                                        'is_done': false,
                                        // 'images': (listImg.isNotEmpty)
                                        //     ? listImg
                                        //         .where((img) {
                                        //           final splitImg =
                                        //               img.split('|');
                                        //           return splitImg[1] ==
                                        //               (position[i]
                                        //                       ['position'])
                                        //                   .toString();
                                        //         })
                                        //         .toList()
                                        //         .map((img2) {
                                        //           final splitImg2 =
                                        //               img2.split('|');
                                        //           return (splitImg2[0])
                                        //               .toString();
                                        //         })
                                        //         .toList()
                                        //     : [],
                                        'images': ((position[i]['image']
                                                    as List<dynamic>)
                                                .isNotEmpty)
                                            ? [
                                                (position[i]['image'][0]
                                                        as String)
                                                    .split('|')[0]
                                              ]
                                            : [],
                                        'sn': (position[i]['sn'] != null ||
                                                position[i]['sn'] != '')
                                            ? position[i]['sn']
                                            : unit.sn,
                                        'kunci_unit': unit.kunciUnit,
                                        'kunci_tire': unit.kunciTire,
                                        'pit': (idSite == bmbsitarum.idSite ||
                                                idSite == bmbhauling.idSite ||
                                                idSite == bmbtabuhan.idSite ||
                                                idSite == bibkgb.idSite)
                                            ? pit[selectedPit]
                                            : 'Default'
                                      });
                                    } else {
                                      await firestore.collection('task').add({
                                        'id': id.v4(),
                                        'id_site': idSite,
                                        'user': user['username'] ?? 'username',
                                        'user_email': auth.currentUser!.email,
                                        'unit': unit.unitNumber,
                                        'serial_number': unit.sn,
                                        'condition': position[i]['condition']
                                            .where((condition) =>
                                                condition['checked'] == true)
                                            .map((condition) =>
                                                condition['name'].toString())
                                            .toList(),
                                        'tire_size': unit.size,
                                        'hm': hmUnit.text,
                                        'position': position[i]['position'],
                                        'rating': position[i]['rating'],

                                        'brand': unit.brand,
                                        'tire_damage':
                                            (position[i]['damageTire'].isEmpty)
                                                ? damageType[0]
                                                : position[i]['damageTire'],
                                        'remarks': position[i]['remarks'],
                                        'rtd':
                                            '${position[i]['rtd1']}/${position[i]['rtd2']}',
                                        'pressure': position[i]['pressure'],
                                        'adjusmentPressure': position[i]
                                            ['adjusmentPressure'],
                                        'last_update':
                                            DateTime.now().toIso8601String(),
                                        'is_done': false,
                                        'images': ((position[i]['image']
                                                    as List<dynamic>)
                                                .isNotEmpty)
                                            ? [
                                                (position[i]['image'][0]
                                                        as String)
                                                    .split('|')[0]
                                              ]
                                            : [],
                                        // 'images': (listImg.isNotEmpty)
                                        //     ? listImg
                                        //         .where((img) {
                                        //           final splitImg =
                                        //               img.split('|');
                                        //           return splitImg[1] ==
                                        //               (position[i]
                                        //                       ['position'])
                                        //                   .toString();
                                        //         })
                                        //         .toList()
                                        //         .map((img2) {
                                        //           final splitImg2 =
                                        //               img2.split('|');
                                        //           return (splitImg2[0])
                                        //               .toString();
                                        //         })
                                        //         .toList()
                                        //     : [],
                                        'sn': (position[i]['sn'] != '')
                                            ? position[i]['sn']
                                            : unit.sn,
                                        'kunci_unit': unit.kunciUnit,
                                        'kunci_tire': unit.kunciTire,
                                        'pit': (idSite == bmbsitarum.idSite ||
                                                idSite == bmbhauling.idSite ||
                                                idSite == bmbtabuhan.idSite ||
                                                idSite == bibkgb.idSite)
                                            ? pit[selectedPit]
                                            : 'Default'
                                      });
                                    }
                                  }
                                }

                                // input ke daily check pressure
                                try {
                                  final today = DateTime.now();
                                  final startOfDay = DateTime(
                                      today.year, today.month, today.day);
                                  final endOfDay = DateTime(today.year,
                                      today.month, today.day, 23, 59, 59);
                                  final formattedToday =
                                      '${today.month.toString().padLeft(2, '0')}' // MM
                                      '${today.day.toString().padLeft(2, '0')}' // DD
                                      '${(today.year % 100).toString().padLeft(2, '0')}'; // YY

                                  final querySnapshot = await FirebaseFirestore
                                      .instance
                                      .collection('daily_pressure')
                                      .where('unit',
                                          isEqualTo: dataUnit['unitNumber'])
                                      .where('tanggal',
                                          isGreaterThanOrEqualTo:
                                              startOfDay.toIso8601String())
                                      .where('tanggal',
                                          isLessThanOrEqualTo:
                                              endOfDay.toIso8601String())
                                      .get();

                                  print(
                                      'Documents found: ${querySnapshot.docs.length}');

                                  if (querySnapshot.docs.isNotEmpty) {
                                    final docId = querySnapshot.docs.first.id;

                                    // revisi data
                                    await firestore
                                        .collection('daily_pressure')
                                        .doc(docId)
                                        .update({
                                      'idSite': idSite,
                                      'user': user['username'] ??
                                          auth.currentUser!.email,
                                      'tanggal':
                                          DateTime.now().toIso8601String(),
                                      'unit': idUnit.text,
                                      'hm': hmUnit.text,
                                      'posisi': position.map((p) {
                                        final pIndex = position.indexOf(p);

                                        log('tekanan angin : ${p['pressure']}');
                                        return {
                                          'pos': '${pIndex + 1}',
                                          'pressure': (p['pressure']) ?? '0',
                                          'rating': (p['rating']) ?? '',
                                          'adjusmentPressure':
                                              (p['adjusmentPressure']) ?? '0',
                                          'luka': p['damageTire'],
                                          'idUnit': p['idUnit'],
                                          'idInventory': p['idInventory'],
                                          'tireSize': p['tireSize'],
                                          'idDaily':
                                              '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
                                          'tireAccessories': []
                                        };
                                      }),
                                      'pit': (idSite == bmbsitarum.idSite ||
                                              idSite == bmbhauling.idSite ||
                                              idSite == bmbtabuhan.idSite ||
                                              idSite == bibkgb.idSite)
                                          ? pit[selectedPit]
                                          : 'Default'
                                    });
                                  } else {
                                    // tambah data
                                    await firestore
                                        .collection('daily_pressure')
                                        .add({
                                      // 'nama': (user),
                                      'idSite': idSite,
                                      'user': user['username'] ??
                                          auth.currentUser!.email,
                                      'tanggal':
                                          DateTime.now().toIso8601String(),
                                      'unit': idUnit.text,
                                      'hm': hmUnit.text,
                                      'posisi': position.map((p) {
                                        final pIndex = position.indexOf(p);
                                        log('tekanan angin : ${p['pressure']}');

                                        return {
                                          'pos': '${pIndex + 1}',
                                          'pressure': (p['pressure']) ?? '0',
                                          'rating': (p['rating']) ?? '0',
                                          'adjusmentPressure':
                                              (p['adjusmentPressure']) ?? '0',
                                          'luka': p['damageTire'],
                                          'idUnit': p['idUnit'],
                                          'idInventory': p['idInventory'],
                                          'tireSize': p['tireSize'],
                                          'idDaily':
                                              '${p['idUnit']}${pIndex + 1}${formattedToday}${idSite}',
                                          'tireAccessories': []
                                        };
                                      }),
                                      'pit': (idSite == bmbsitarum.idSite ||
                                              idSite == bmbhauling.idSite ||
                                              idSite == bmbtabuhan.idSite ||
                                              idSite == bibkgb.idSite)
                                          ? pit[selectedPit]
                                          : 'Default'
                                    });
                                  }
                                } catch (e) {
                                  print('error bmb : $e');
                                }
                                ScaffoldMessenger.of(context)
                                    .hideCurrentSnackBar();
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(SnackBar(
                                  content: Text(
                                    'Successful save data, please check in home page',
                                    style: getWhiteTextStyle(),
                                  ),
                                  backgroundColor: green00968A,
                                ));
                                Navigator.pop(context);
                              } catch (e) {
                                log('kenapa gagal : $e');
                              }
                            }),
                );
              }
              return Container();
            },
          ),
          const SizedBox(
            height: 12,
          ),
        ],
      ),
    );
  }
}
