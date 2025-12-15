import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'dart:io' show Platform;
import '../../../core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
import '../../../core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart'
    as connectedDevicesState;
import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_cubit.dart';
import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_state.dart';
import 'package:camos/core/blocs/bluetooth/scan_devices_cubit/scan_devices_cubit.dart';
import 'package:camos/core/blocs/bluetooth/scan_devices_cubit/scan_devices_state.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/bluetooth/utils/bluetooth_utils.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_list.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/daily_pressure_list_trial_page.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/bluetooth/bluetooth_on_off_toggle_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/bluetooth/list_of_connected_devices_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/bluetooth/list_of_scanned_devices_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';

class DailyPressureTrialPage extends StatefulWidget {
  static const routeName = 'daily-pressure-trial-page';
  const DailyPressureTrialPage({super.key});

  @override
  State<DailyPressureTrialPage> createState() => _DailyPressureTrialPageState();
}

class _DailyPressureTrialPageState extends State<DailyPressureTrialPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String idSite = '';
  // Bluetooth
  FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  bool get isConnected => connection != null && connection!.isConnected;
  // List<BluetoothDevice> devices = [];
  int selectedRoute = 0;
  int selectedTireCheck = 0;
  int checkAmount = 0;
  int selectedPit = 0;
  bool isColdSelected = true;
  Map<String, dynamic> user = {};
  List<List<int>> inspectRoute = [
    [0, 1, 2, 3, 4, 5],
    [0, 2, 3, 4, 5, 1],
    [1, 5, 4, 3, 2, 0],
  ];
  List<String> pit = [];

  // 0 (6 tire), 1 (10 tire), 2 (12 tire)
  // List<int> tireCheck = [6, 10, 12];

  // List<Map<String, dynamic>> tires = [
  //   {
  //     'position': '1',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '2',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '3',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '4',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '5',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '6',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '7',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '8',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '9',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '10',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '11',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  //   {
  //     'position': '12',
  //     'pressure': '',
  //     'temperature': '',
  //     'injury': '',
  //   },
  // ];

  List<Map<String, dynamic>> tires = List.generate(128, (index) {
    return {
      'position': '${index + 1}',
      'pressure': '',
      'temperature': '',
      'injury': '',
    };
  });

  List<int> tireCheck = List.generate(62, (index) => 6 + (index * 2))
      .where((e) => e <= 128)
      .toList();

  ValueNotifier<List<int>> readCharValue = ValueNotifier([]);

  int selectedTire = -1;
  TextEditingController unitCtrl = TextEditingController(text: '');
  TextEditingController hmCtrl = TextEditingController(text: '');
  TextEditingController userCtrl = TextEditingController(text: '');

  String pressure = '';
  String temperature = '';

  @override
  void initState() {
    if (BlocProvider.of<BluetoothOnOffCubit>(context).state
        is BluetoothOnState) {
      BlocProvider.of<ConnectedDevicesCubit>(context).fetchConnectedDevices();
    }
    super.initState();

    getUser();
  }

  getUser() async {
    userCtrl.text = await getUserDaily();
  }

  // startScanBluetooth() async {
  //   StreamSubscription<BluetoothDiscoveryResult>? scanSubscription;

  //   scanSubscription = bluetoothSerial.startDiscovery().listen((device) {
  //     if (!devices.contains(device.device)) {
  //       log('device yg tersedia ' + device.device.toString());
  //       setState(() {
  //         devices.add(device.device);
  //       });
  //     }
  //   }, onDone: () {
  //     setState(() {});
  //   });

  //   // Tunda pembatalan pemindaian setelah beberapa waktu (misalnya 10 detik)
  //   await Future.delayed(Duration(seconds: 10));

  //   // Setelah tunda, batalkan pemindaian
  //   if (scanSubscription != null) {
  //     scanSubscription.cancel();
  //     log('Bluetooth scan stopped');
  //   }
  // }

  stopScanBluetooth() async {
    bluetoothSerial.cancelDiscovery();
  }

  // mendapatkan nilai pressure
  void _listenForData() {
    connection!.input!.listen((data) {
      String receivedData = String.fromCharCodes(data).trim();
      log('data json : $receivedData');
      String onlyNumber =
          '${double.parse(receivedData.replaceAll(RegExp(r'[^\d.-]+'), ''))}';
      print(
          'Received data: ${double.parse(receivedData.replaceAll(RegExp(r'[^\d.-]+'), ''))}');

      setState(() {
        int dot = onlyNumber.indexOf('.');
        String firstNumber =
            onlyNumber.substring(0, dot != -1 ? dot : onlyNumber.length);

        if (selectedTire != -1) {
          tires[selectedTire]['pressure'] = firstNumber;
        } else {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
              'Please select the position of tire!',
              style: getWhiteTextStyle(),
            ),
            backgroundColor: Colors.red,
          ));
        }

        // pressureDigitalCtrl.text = firstNumber;
      });
    });
  }

  void scanDevices(BuildContext context) {
    BlocProvider.of<ScanDevicesCubit>(context).scanDevices();
    BlocProvider.of<ConnectedDevicesCubit>(context).fetchConnectedDevices();
  }

  void readChar(BluetoothCharacteristic char) async {
    // readCharValue.value = await widget.char.read();
    if (char.properties.read) {
      try {
        readCharValue.value = await char.read();
      } catch (e) {
        debugPrint("debugReadChar: ${e.toString()}");
      }
    }
  }

  checkSelectionTire() {
    if (selectedTire == -1) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Please choose one tire position before send data!',
                    style: getBlackTextStyle(
                      fontSize: 16,
                      fontWeight: w600,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      back(context);
                    },
                    child: Text(
                      'Close',
                      style: getGreyTextStyle(grey8391A1),
                    )),
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    idSite = ModalRoute.of(context)?.settings.arguments as String;
    pit.clear();

    if (idSite == '4') {
      pit.add('Sektor 1 (Pit Firdaus)');
      pit.add('Sektor 2 (Pit Nirwana)');
      pit.add('Sektor 4 (Pit Harapan)');
      pit.add('Sektor 7 (Pit Paradise)');
      pit.add('Workshop');
    }

    return Scaffold(
      appBar: appBarWidget('Form Tire Inspection', context),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 24,
              ),
              // ButtonWidget(
              //     name: Row(
              //       mainAxisAlignment: MainAxisAlignment.center,
              //       children: [
              //         Icon(
              //           Icons.bluetooth,
              //           color: white,
              //         ),
              //         const SizedBox(
              //           width: 6,
              //         ),
              //         Text(
              //           'Connect Pressure Gauge Digital',
              //           style: getWhiteTextStyle(),
              //         ),
              //       ],
              //     ),
              //     function: () async {
              //       log('tombol pressure gauge');
              //       if (connection != null) {
              //         stopScanBluetooth();
              //         connection?.close();
              //       }
              //       requestBluetoothPermission();
              //       startScanBluetooth();
              //       setState(() {
              //         devices.clear();
              //       });
              //       // AppSettings.openBluetoothSettings();
              //     }),
              BlocBuilder<BluetoothOnOffCubit, BluetoothOnOffState>(
                builder: (context, onOffState) {
                  if (onOffState is BluetoothOnState) {
                    return BlocConsumer<ConnectedDevicesCubit,
                        connectedDevicesState.ConnectedDevicesState>(
                      listener: (context, state) {
                        if (state is connectedDevicesState
                            .ConnectedDevicesLoadedState) {
                          if (state.connectedDevices.isNotEmpty) {
                            BlocProvider.of<DiscoverServicesCubit>(context)
                                .discoverServices(state.connectedDevices[0]);
                          }
                        }
                      },
                      builder: (context, state) {
                        if (state is connectedDevicesState
                            .ConnectedDevicesLoadedState) {
                          return Column(
                            children: [
                              ListOfConnectedDevicesWidget(
                                  connectedDevices: state.connectedDevices),
                              BlocConsumer<DiscoverServicesCubit,
                                  DiscoverServiceState>(
                                listener: (context, discoverState) {
                                  if (discoverState is ServicesLoadedState) {
                                    final services = discoverState.services;
                                    log('services pgd : $services');

                                    for (BluetoothService service in services) {
                                      for (BluetoothCharacteristic characteristic
                                          in service.characteristics) {
                                        characteristic.lastValueStream
                                            .listen((event) {
                                          String notifInString =
                                              String.fromCharCodes(event);
                                          debugPrint(
                                              "debugBluetoothNotification*************");
                                          debugPrint(
                                              "debugBluetoothNotification: charName: ${BluetoothUtils.getBluetoothChar(characteristic.characteristicUuid.str)}");

                                          debugPrint(
                                              "notifhohoho: stringNotif: $notifInString");
                                          // debugPrint(
                                          //     "notifhahaha: jsonNotif: ${jsonDecode(notifInString)}");

                                          setState(() {
                                            // pressure = notifInString;
                                            if (notifInString.contains('|')) {
                                              int floorPressure = double.parse(
                                                      notifInString
                                                          .split('|')[0])
                                                  .floor();
                                              pressure =
                                                  floorPressure.toString();

                                              int floorTemperature =
                                                  double.parse(notifInString
                                                          .split('|')[1])
                                                      .floor();
                                              temperature =
                                                  floorTemperature.toString();
                                            } else {
                                              int floorPressure =
                                                  double.parse(notifInString)
                                                      .floor();
                                              pressure =
                                                  floorPressure.toString();
                                            }

                                            if (selectedTire != -1) {
                                              tires[selectedTire]['pressure'] =
                                                  pressure;
                                              tires[selectedTire]
                                                  ['temperature'] = temperature;
                                            } else {
                                              switch (selectedRoute) {
                                                case 0:
                                                  setState(() {
                                                    if (checkAmount < 6)
                                                      tires[inspectRoute[0]
                                                                  [checkAmount]]
                                                              ['pressure'] =
                                                          pressure;
                                                    tires[inspectRoute[0]
                                                                [checkAmount]]
                                                            ['temperature'] =
                                                        temperature;
                                                    checkAmount++;
                                                  });
                                                  break;
                                                case 1:
                                                  setState(() {
                                                    if (checkAmount < 6)
                                                      tires[inspectRoute[1]
                                                                  [checkAmount]]
                                                              ['pressure'] =
                                                          pressure;
                                                    tires[inspectRoute[1]
                                                                [checkAmount]]
                                                            ['temperature'] =
                                                        temperature;
                                                    checkAmount++;
                                                  });
                                                  break;
                                                case 2:
                                                  setState(() {
                                                    if (checkAmount < 6)
                                                      tires[inspectRoute[2]
                                                                  [checkAmount]]
                                                              ['pressure'] =
                                                          pressure;
                                                    tires[inspectRoute[2]
                                                                [checkAmount]]
                                                            ['temperature'] =
                                                        temperature;
                                                    checkAmount++;
                                                  });
                                                  break;
                                              }
                                              // checkSelectionTire();
                                            }
                                            log('pressure dibulatkan : $pressure');
                                          });

                                          debugPrint(
                                              "debugBluetoothNotification*************");
                                        });
                                      }
                                    }
                                  }
                                },
                                builder: (context, discoverState) {
                                  if (discoverState
                                      is ErrorLoadingServiceState) {
                                    return Center(
                                      child: Text('Error'),
                                    );
                                  }
                                  return Container();
                                },
                              ),
                            ],
                          );
                        } else if (state
                            is connectedDevicesState.LoadingState) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        return const SizedBox();
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

              // Text(
              //   'Pressure : $pressure',
              //   textAlign: TextAlign.start,
              // ),
              const SizedBox(
                height: 12,
              ),
              ButtonWidget(
                  color: Colors.red,
                  name: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete,
                          color: white,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          'Clear Text',
                          style: getWhiteTextStyle(),
                        )
                      ]),
                  function: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text("Confirmation"),
                          content:
                              Text("Are you sure you want to clear the data?"),
                          actions: <Widget>[
                            TextButton(
                              child: Text("No"),
                              onPressed: () {
                                Navigator.of(context)
                                    .pop(); // Close the dialog without action
                              },
                            ),
                            TextButton(
                              child: Text("Yes"),
                              onPressed: () {
                                // Action to clear the data

                                setState(() {
                                  unitCtrl.text = '';
                                  hmCtrl.text = '';
                                  userCtrl.text = '';
                                  selectedRoute = 0;
                                  selectedTireCheck = 0;
                                  checkAmount = 0;
                                  tires = List.generate(128, (index) {
                                    return {
                                      'position': '${index + 1}',
                                      'pressure': '',
                                      'temperature': '',
                                      'injury': '',
                                    };
                                  });
                                });

                                Navigator.of(context).pop(); // Close the dialog
                              },
                            ),
                          ],
                        );
                      },
                    );
                  }),
              Container(
                child: TextFormField(
                  controller: userCtrl,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  // validator: _validateUserName,
                  onFieldSubmitted: (String value) {
                    // FocusScope.of(context).requestFocus(_passwordEmail);
                  },
                  decoration: InputDecoration(
                      labelText: 'User', icon: Icon(Icons.account_box)),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: unitCtrl,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Unit Id',
                        icon: Icon(Icons.front_loader),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isColdSelected = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isColdSelected
                          ? Colors.lightBlueAccent
                          : Colors.grey[300],
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: TextStyle(fontSize: 12),
                    ),
                    child: Text(
                      'Cold',
                      style: getWhiteTextStyle(fontWeight: w700),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        isColdSelected = false;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !isColdSelected ? Colors.redAccent : Colors.grey[300],
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      textStyle: TextStyle(fontSize: 12),
                    ),
                    child: Text(
                      'Hot',
                      style: getWhiteTextStyle(fontWeight: w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 18,
              ),
              Container(
                child: TextFormField(
                  controller: hmCtrl,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  // validator: _validateUserName,
                  onFieldSubmitted: (String value) {
                    // FocusScope.of(context).requestFocus(_passwordEmail);
                  },
                  decoration: InputDecoration(
                      labelText: 'HM Unit', icon: Icon(Icons.lock_clock)),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              (pit.isNotEmpty)
                  ? Column(
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: pit.map((e) {
                              final pitIndex = pit.indexOf(e);
                              return Container(
                                margin: EdgeInsets.only(right: 12),
                                child: ElevatedButton(
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
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                      ],
                    )
                  : Container(),

              Text(
                'Qty Tire',
                style: getBlackTextStyle(fontWeight: w700, fontSize: 18),
              ),
              const SizedBox(
                height: 12,
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(tireCheck.length, (index) {
                    return SizedBox(
                      width: 140, // atur sesuai kebutuhan
                      child: RadioListTile<int>(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "${tireCheck[index]} Tires",
                          style: getBlackTextStyle(fontSize: 14),
                        ),
                        value: index,
                        groupValue: selectedTireCheck,
                        onChanged: (int? value) {
                          setState(() {
                            selectedTireCheck = value!;
                          });
                        },
                      ),
                    );
                  }),
                ),
              ),

              (selectedTireCheck == 0)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Inspection Tire Route',
                          style:
                              getBlackTextStyle(fontWeight: w700, fontSize: 18),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Column(
                          children: inspectRoute.asMap().entries.map((entry) {
                            int index = entry.key;
                            List<int> route = entry.value;

                            return RadioListTile<int>(
                              title: Text(route
                                  .map((index) => (index + 1).toString())
                                  .join(' -> ')),
                              value: index,
                              groupValue: selectedRoute,
                              onChanged: (value) {
                                setState(() {
                                  selectedRoute = value!;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                      ],
                    )
                  : Container(),
              ListView.builder(
                  itemCount: tireCheck[selectedTireCheck],
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final tire = tires[index];

                    return Container(
                      margin: EdgeInsets.only(bottom: 24),
                      child: Card(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12.0, vertical: 24.0),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.radio_button_checked),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    'Position ${tire['position']}',
                                    style: getBlackTextStyle(
                                      fontSize: 20,
                                      fontWeight: w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.tire_repair,
                                              size: 28,
                                            ),
                                            const SizedBox(
                                              width: 6,
                                            ),
                                            Text(
                                              'Pressure (Psi)',
                                              style: getBlackTextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 6,
                                        ),
                                        // Container(
                                        //     height: 50,
                                        //     width: double.infinity,
                                        //     child: InputFormWidget(
                                        //       controller: TextEditingController(
                                        //           text:
                                        //               '${tires[index]['pressure']}'),
                                        //       isDigitOnly: true,
                                        //       onChng: (string) {
                                        //         tires[index]['pressure'] = string;
                                        //       },
                                        //       type: TextInputType.number,
                                        //       hint: '',
                                        //     )),
                                        (tires[index]['pressure'] == '')
                                            ? Text(
                                                '-',
                                                style: getBlackTextStyle(
                                                    fontSize: 18,
                                                    fontWeight: w700),
                                              )
                                            : Text(
                                                '${'${tires[index]['pressure']} Psi'}',
                                                style: getGreenTextStyle(
                                                    fontSize: 24,
                                                    fontWeight: w700),
                                              ),
                                        const SizedBox(
                                          height: 6,
                                        ),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.thermostat,
                                              size: 28,
                                            ),
                                            const SizedBox(
                                              width: 6,
                                            ),
                                            Text(
                                              'Temperature (°C)',
                                              style: getBlackTextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 6,
                                        ),
                                        (tires[index]['temperature'] == '')
                                            ? Text(
                                                '-',
                                                style: getBlackTextStyle(
                                                    fontSize: 18,
                                                    fontWeight: w700),
                                              )
                                            : Text(
                                                '${'${tires[index]['temperature']} °C'}',
                                                style: getGreenTextStyle(
                                                    fontSize: 24,
                                                    fontWeight: w700),
                                              ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      height: 80,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            selectedTire = index;
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18)),
                                          backgroundColor:
                                              (selectedTire == index)
                                                  ? green00968A
                                                  : greyF7F8F9,
                                        ),
                                        child: Text(
                                          (selectedTire == index)
                                              ? 'Selected'
                                              : 'Select',
                                          style: (selectedTire == index)
                                              ? getWhiteTextStyle(
                                                  fontSize: 12,
                                                  fontWeight: w700,
                                                )
                                              : getBlackTextStyle(
                                                  fontSize: 12,
                                                  fontWeight: w700,
                                                ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              // Container(
                              //   child: TextFormField(
                              //     controller: TextEditingController(
                              //         text: tires[index]['injury']),
                              //     keyboardType: TextInputType.text,
                              //     textInputAction: TextInputAction.next,
                              //     // validator: _validateUserName,
                              //     onFieldSubmitted: (String value) {
                              //       // FocusScope.of(context).requestFocus(_passwordEmail);
                              //     },
                              //     decoration: InputDecoration(
                              //         labelText: 'Injury',
                              //         icon: Icon(Icons.dangerous)),
                              //   ),
                              // ),
                              const SizedBox(
                                height: 24,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.dangerous,
                                        size: 24,
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      Text(
                                        'Injury',
                                        style: getBlackTextStyle(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 6,
                                  ),
                                  Container(
                                      height: 50,
                                      width: double.infinity,
                                      child: InputFormWidget(
                                        onChng: (string) {
                                          tires[index]['injury'] = string;
                                        },
                                        controller: TextEditingController(
                                            text: tires[index]['injury']),
                                        hint: '',
                                      )),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  })
            ],
          ),
        ),
      )),
      bottomNavigationBar: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                saveUserDaily(userCtrl.text);
                if (unitCtrl.text.isEmpty ||
                    tires[0]['pressure'] == 0 ||
                    tires[1]['pressure'] == 0 ||
                    tires[2]['pressure'] == 0 ||
                    tires[3]['pressure'] == 0 ||
                    tires[4]['pressure'] == 0 ||
                    tires[5]['pressure'] == 0) {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        'Please insert Id Unit and Pressure',
                        style: getWhiteTextStyle(),
                      )));
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: green00968A,
                    content: Text(
                      'Data Succesfully Added',
                      style: getWhiteTextStyle(),
                    )));
                try {
                  final querySnapshot = await firestore
                      .collection('daily_pressure')
                      .where('unit', isEqualTo: unitCtrl.text)
                      .get();

                  if (querySnapshot.docs.isNotEmpty) {
                    final docId = querySnapshot.docs.first.id;

                    final existingData = querySnapshot.docs.first.data();

                    // revisi data
                    await firestore
                        .collection('daily_pressure')
                        .doc(docId)
                        .update({
                      'idSite': idSite,
                      'tanggal': DateTime.now().toIso8601String(),
                      'unit': unitCtrl.text.isNotEmpty
                          ? unitCtrl.text
                          : existingData['unit'],
                      'hm': hmCtrl.text.isNotEmpty
                          ? hmCtrl.text
                          : existingData['hm'],
                      'posisi': tires
                          .asMap()
                          .entries
                          .where((entry) =>
                              entry.key + 1 <= tireCheck[selectedTireCheck])
                          .map((entry) {
                        final tire = entry.value;
                        final pIndex = entry.key + 1;
                        return {
                          'pos': '$pIndex',
                          'pressure': tire['pressure'] != ''
                              ? tire['pressure']
                              : existingData['posisi']?[entry.key]
                                      ['pressure'] ??
                                  '0',
                          'temperature': tire['temperature'] != ''
                              ? tire['temperature']
                              : existingData['posisi']?[entry.key]
                                      ['temperature'] ??
                                  '0',
                          'luka': tire['injury'] != ''
                              ? [tire['injury']]
                              : existingData['posisi']?[entry.key]['luka']
                        };
                      }).toList(),
                      'user': userCtrl.text.isNotEmpty
                          ? userCtrl.text
                          : existingData['user'],
                      'pit': (pit.isNotEmpty) ? pit[selectedPit] : 'Default',
                      'unit_condition': isColdSelected ? 'Cold' : 'Hot'
                    });
                  } else {
                    // tambah data
                    await firestore.collection('daily_pressure').add({
                      'idSite': idSite,
                      'tanggal': DateTime.now().toIso8601String(),
                      'unit': unitCtrl.text,
                      'hm': hmCtrl.text,
                      'posisi': tires
                          .asMap()
                          .entries
                          .where((entry) =>
                              entry.key + 1 <=
                              tireCheck[
                                  selectedTireCheck]) // Saring hanya item yang memenuhi kondisi
                          .map((entry) {
                        final tire = entry.value;
                        final pIndex = entry.key + 1;
                        return {
                          'pos': '$pIndex',
                          'pressure': (tire['pressure'] != '')
                              ? tire['pressure']
                              : 'N/A',
                          'temperature': (tire['temperature'] != '')
                              ? tire['temperature']
                              : 'N/A',
                          'luka':
                              (tire['injury'] == '') ? null : [tire['injury']]
                        };
                      }).toList(),
                      'user': userCtrl.text,
                      'pit': (pit.isNotEmpty) ? pit[selectedPit] : 'Default',
                      'unit_condition': isColdSelected ? 'Cold' : 'Hot'
                    });
                  }
                } catch (e) {}
              },
              child: Container(
                padding: EdgeInsets.all(24),
                color: blue344BEF,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.save,
                      color: white,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      'SAVE',
                      textAlign: TextAlign.center,
                      style: getWhiteTextStyle(
                        fontSize: 20,
                        fontWeight: w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                Navigator.pushNamed(
                    context, DailyPressureListTrialPage.routeName);
              },
              child: Container(
                padding: EdgeInsets.all(24),
                color: green00968A,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.front_loader,
                      color: white,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      'List Unit',
                      textAlign: TextAlign.center,
                      style: getWhiteTextStyle(
                        fontSize: 20,
                        fontWeight: w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
