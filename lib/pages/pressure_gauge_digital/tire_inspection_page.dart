import 'dart:async';
import 'dart:developer';

import 'package:camos/core/blocs/tire/tire_bloc.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class TireInspectionPage extends StatefulWidget {
  static const routeName = '/tire-inspection-page';

  const TireInspectionPage({super.key});

  @override
  State<TireInspectionPage> createState() => _TireInspectionPageState();
}

class _TireInspectionPageState extends State<TireInspectionPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  List<Map<String, dynamic>> position = [];
  String idSite = '';
  List<String> pressure = [
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
  List<String> damageType = [
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
    'Tread Chungking',
    'Tread Lifting',
    'Tread Cut',
    'Tread Cut Separation',
    'Worn Out',
  ];
  List<List<int>> inspectRoute = [
    [0, 1, 2, 3, 4, 5],
    [0, 2, 3, 4, 5, 1],
    [1, 5, 4, 3, 2, 0],
  ];
  List<String> pit = [];

  TextEditingController pressureCtrl = TextEditingController(text: '');
  TextEditingController pressureDigitalCtrl = TextEditingController(text: '');
  TextEditingController damageCtrl = TextEditingController(text: '');
  TextEditingController hmCtrl = TextEditingController(text: '');
  List<String> selectedDamage = [];
  int selectedPit = -1;
  int selectedPosIndex = -1;
  int selectedType = 0;
  int selectedRoute = 0;
  int checkAmount = 0;
  Map<String, dynamic> dataUnit = {};
  String buttonText = 'Select';

  // Bluetooth
  FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  bool get isConnected => connection != null && connection!.isConnected;
  List<BluetoothDevice> devices = [];

  // startScanBluetooth() async {
  //   bluetoothSerial.startDiscovery().listen((device) {
  //     if (!devices.contains(device.device)) {
  //       log('device yg tersedia ' + device.device.toString());
  //       setState(() {
  //         devices.add(device.device);
  //       });
  //     }
  //   }, onDone: () {
  //     setState(() {});
  //   });
  // }

  startScanBluetooth() async {
    StreamSubscription<BluetoothDiscoveryResult>? scanSubscription;

    scanSubscription = bluetoothSerial.startDiscovery().listen((device) {
      if (!devices.contains(device.device)) {
        log('device yg tersedia ' + device.device.toString());
        setState(() {
          devices.add(device.device);
        });
      }
    }, onDone: () {
      setState(() {});
    });

    // Tunda pembatalan pemindaian setelah beberapa waktu (misalnya 10 detik)
    await Future.delayed(Duration(seconds: 10));

    // Setelah tunda, batalkan pemindaian
    if (scanSubscription != null) {
      scanSubscription.cancel();
      log('Bluetooth scan stopped');
    }
  }

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
        pressureDigitalCtrl.text = firstNumber;
        switch (selectedType) {
          // PG DIGITAL Type
          case 0:
            switch (selectedRoute) {
              case 0:
                setState(() {
                  if (checkAmount < 6)
                    position[inspectRoute[0][checkAmount]]['pressure'] =
                        firstNumber;
                  checkAmount++;
                });
                break;
              case 1:
                setState(() {
                  if (checkAmount < 6)
                    position[inspectRoute[1][checkAmount]]['pressure'] =
                        firstNumber;
                  checkAmount++;
                });
                break;
              case 2:
                setState(() {
                  if (checkAmount < 6)
                    position[inspectRoute[2][checkAmount]]['pressure'] =
                        firstNumber;
                  checkAmount++;
                });
                break;
            }
            print('tekananangin : ${pressureDigitalCtrl.text}');
            break;
          case 1:
            // Manual Type
            if (selectedPosIndex != -1) {
              position[selectedPosIndex]['pressure'] = firstNumber;
              pressureDigitalCtrl.clear();
              selectedPosIndex = -1;
              Navigator.pop(context);
            }
            break;
        }
      });
    });
  }

  void callTires() async {
    idSite = await getIdSitePreferences();
    log('id site daliy check : $idSite');
    if (idSite == '1') {
      idSite = await getSelectedIdSitePreferences();
    }
    if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
      context.read<TireBloc>().add(GetUnitTiresEvent(
          idSite: idSite, unitNumber: dataUnit['unitNumber']));
    }

// tambahkan pit
    setState(() {
      // BMB COYYY
      log('id site bmb : $idSite');
      if (idSite == '52') {
        pit.add('Utara');
        pit.add('Selatan');
        pit.add('RML');
      }
    });
  }

  @override
  void initState() {
    // addPositionVariable();
    super.initState();
    callTires();
  }

  @override
  Widget build(BuildContext context) {
    dataUnit =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    log('data ban : $position');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Daily Check Pressure',
          style: getBlackTextStyle(),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, DailyPressureListPage.routeName);
            },
            child: Padding(
              padding: const EdgeInsets.only(
                right: 8.0,
                top: 8.0,
              ),
              child: Icon(
                Icons.list,
                size: 32,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocConsumer<TireBloc, TireState>(
            listener: (context, state) {
              if (state is TiresLoadedState) {
                //? BLOC TER EKSEKUSI dua kali dan mengambil jumlah tire sebelumnya
                for (var i = 0; i < state.units.length; i++) {
                  if (position.length < state.units.length) {
                    position.add({'pressure': '', 'damage': null});
                  }
                }
              }
            },
            builder: (context, state) {
              if (state is TireLoadingState) {
                return CircularProgressIndicator();
              }

              if (state is TiresLoadedState) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // UNIT NUMBER DAN HM UNIT
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
                                        text: dataUnit['unitNumber']),
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
                                    'HM UNIT',
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
                                    // isReadOnly: true,
                                    controller: hmCtrl,
                                    isDecimalOnly: true,
                                    type: TextInputType.number,
                                    hint: 'Fill HM'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    (pit.isNotEmpty)
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.ev_station,
                                size: 38,
                              ),
                              const SizedBox(
                                width: 12,
                              ),
                              Text(
                                'Pit',
                                style: getBlackTextStyle(
                                    fontSize: 18, fontWeight: w700),
                              ),
                            ],
                          )
                        : Container(),
                    SizedBox(
                      height: (pit.isNotEmpty) ? 24 : 0,
                    ),
                    Row(
                      children: pit.map((e) {
                        final pitIndex = pit.indexOf(e);
                        return Expanded(
                            child: Padding(
                          padding: EdgeInsets.only(
                              right: (pitIndex == 0) ? 12 : 0,
                              left: (pitIndex == pit.length - 1) ? 12 : 0),
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: (selectedPit == pitIndex)
                                    ? Colors.orange
                                    : greyF7F8F9),
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
                        ));
                      }).toList(),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedType = 0;
                                  });
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                    if (selectedType == 0) {
                                      return Colors.lightGreen;
                                    }
                                    return greyDADADA;
                                  }),
                                ),
                                child: Text(
                                  'PG Digital',
                                  style: getWhiteTextStyle(fontWeight: w700),
                                )),
                          ),
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    selectedType = 1;
                                  });
                                },
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.resolveWith<Color>(
                                          (Set<MaterialState> states) {
                                    if (selectedType == 1) {
                                      return Colors.lightGreen;
                                    }
                                    return greyDADADA;
                                  }),
                                ),
                                child: Text(
                                  'Manual',
                                  style: getWhiteTextStyle(fontWeight: w700),
                                )),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 24,
                    ),
                    // PG Digital Inspect
                    (selectedType == 0)
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Inspection Tire Route',
                                style: getBlackTextStyle(
                                    fontWeight: w700, fontSize: 18),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Column(
                                children:
                                    inspectRoute.asMap().entries.map((entry) {
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
                              // Bluetooth Pressure Gauge Digital
                              ButtonWidget(
                                  name: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bluetooth,
                                        color: white,
                                      ),
                                      const SizedBox(
                                        width: 6,
                                      ),
                                      Text(
                                        'Connect Pressure Gauge Digital',
                                        style: getWhiteTextStyle(),
                                      ),
                                    ],
                                  ),
                                  function: () async {
                                    log('tombol pressure gauge');
                                    if (connection != null) {
                                      stopScanBluetooth();
                                      connection?.close();
                                    }
                                    requestBluetoothPermission();
                                    startScanBluetooth();
                                    setState(() {
                                      devices.clear();
                                    });
                                    // AppSettings.openBluetoothSettings();
                                  }),
                              const SizedBox(
                                height: 12,
                              ),
                              Column(
                                children: devices.map((device) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      device.name ?? 'Uknown Device',
                                      style: getBlackTextStyle(),
                                    ),
                                    subtitle: Text(
                                      device.address,
                                      style: getGreyTextStyle(
                                        grey6A707C,
                                      ),
                                    ),
                                    trailing: SizedBox(
                                        width: 110,
                                        height: 60,
                                        child: ButtonWidget(
                                            name: Text(
                                              (isConnected)
                                                  ? 'Disconnect'
                                                  : 'Connect',
                                              style: getWhiteTextStyle(),
                                            ),
                                            function: () async {
                                              if (isConnected) {
                                                await connection!.close();
                                                devices.clear();
                                                setState(() {});
                                              } else {
                                                try {
                                                  connection =
                                                      await BluetoothConnection
                                                          .toAddress(
                                                              device.address);
                                                  print(
                                                      'Connected to the device');
                                                  _listenForData();
                                                  devices.clear();
                                                  devices.add(device);
                                                  setState(() {});
                                                } catch (e) {
                                                  print(
                                                      'Cannot connect to the device: $e');
                                                }
                                              }
                                            })),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(
                                height: 24,
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.tire_repair,
                                    size: 38,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    'Tire',
                                    style: getBlackTextStyle(
                                        fontSize: 18, fontWeight: w700),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Text(
                                'Please select Inspection Route once and send data with Pressure Gauge Digital',
                                style: getBlackTextStyle(),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Column(
                                  children: position.map((pos) {
                                final posIndex = position.indexOf(pos);
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pos. ${posIndex + 1}',
                                      style: getBlackTextStyle(
                                          fontSize: 16, fontWeight: w700),
                                    ),
                                    const SizedBox(
                                      height: 6,
                                    ),
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {},
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            )),
                                        child: Text(
                                          '${position[posIndex]['pressure']} Psi',
                                          style: getWhiteTextStyle(
                                            fontSize: 24,
                                            fontWeight: w700,
                                          ),
                                        ),
                                      ),
                                    )
                                  ],
                                );
                              }).toList())
                            ],
                          )
                        // Manual Inspect
                        : Column(
                            children: [
                              // POSITION
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.tire_repair,
                                    size: 38,
                                  ),
                                  const SizedBox(
                                    width: 12,
                                  ),
                                  Text(
                                    'Tire',
                                    style: getBlackTextStyle(
                                        fontSize: 18, fontWeight: w700),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Container(
                                child: Wrap(
                                  spacing: 34,
                                  runSpacing: 24,
                                  alignment: WrapAlignment.center,
                                  children: position.map((pos) {
                                    final posIndex = position.indexOf(pos);
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // POSITION
                                        Text(
                                          'Pos. ${posIndex + 1}',
                                          style: getBlackTextStyle(
                                              fontSize: 16, fontWeight: w700),
                                        ),
                                        const SizedBox(
                                          height: 6,
                                        ),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.39,
                                          height: 45,
                                          child: ElevatedButton(
                                            onPressed: () async {
                                              FocusScope.of(context).unfocus();
                                              setState(() {
                                                selectedPosIndex = posIndex;
                                              });
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
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
                                                              'Choose Pressure',
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
                                                              children: pressure
                                                                  .map((ps) {
                                                                final psIndex =
                                                                    pressure
                                                                        .indexOf(
                                                                            ps);
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
                                                                            Colors.green),
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        position[posIndex]
                                                                            [
                                                                            'pressure'] = ps;
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      });
                                                                    },
                                                                    child: Text(
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
                                                                        type: TextInputType
                                                                            .number,
                                                                        hint:
                                                                            'Input Manual'),
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
                                                                          position[posIndex]['pressure'] =
                                                                              pressureCtrl.text;
                                                                        }
                                                                        pressureCtrl
                                                                            .clear();
                                                                        Navigator.of(context)
                                                                            .pop();
                                                                      });
                                                                    },
                                                                    child: Text(
                                                                        'Submit'))
                                                              ],
                                                            ),
                                                            SizedBox(
                                                                height: 12.0),
                                                            SizedBox(
                                                              width: double
                                                                  .infinity,
                                                              child:
                                                                  ElevatedButton(
                                                                onPressed: () {
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
                                                backgroundColor: Colors.blue,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                )),
                                            child: (position[posIndex]
                                                        ['pressure'] ==
                                                    '')
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
                                                    '${position[posIndex]['pressure']} Psi',
                                                    style: getWhiteTextStyle(
                                                      fontSize: 24,
                                                      fontWeight: w700,
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 12,
                                        ),
                                        // SELECT DAMAGE TIRE
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.39,
                                          // height: 65,
                                          child: ElevatedButton(
                                              onPressed: () {
                                                FocusScope.of(context)
                                                    .unfocus();
                                                List<bool> checkedDamageValues =
                                                    List<bool>.filled(
                                                        damageType.length,
                                                        false);

                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return Dialog(
                                                      child: Container(
                                                        padding: EdgeInsets.all(
                                                            20.0),
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
                                                                      damageType
                                                                          .map(
                                                                              (damage) {
                                                                    final dmgIndex =
                                                                        damageType
                                                                            .indexOf(damage);
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
                                                                        tmp.add(
                                                                            damageCtrl.text);
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
                                                                      log('idx luka ban : $posIndex');
                                                                      // position[posIndex]
                                                                      //     ['damage'] = tmp;
                                                                      if (tmp
                                                                          .isNotEmpty) {
                                                                        position[posIndex]['damage'] =
                                                                            tmp;
                                                                        selectedDamage
                                                                            .addAll(tmp);
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
                                                        BorderRadius.circular(
                                                            12),
                                                  )),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 8.0),
                                                child: Text(
                                                  (position[posIndex]
                                                              ['damage'] ==
                                                          null)
                                                      ? 'Damage Tire (None)'
                                                      : position[posIndex]
                                                              ['damage']
                                                          .join('\n---\n'),
                                                  textAlign: TextAlign.center,
                                                  style: getWhiteTextStyle(
                                                      fontSize: 14),
                                                ),
                                              )),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          )
                  ],
                );
              }
              return Container();
            },
          ),
        ),
      )),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (pit.isNotEmpty) {
                if (selectedPit == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: Colors.red,
                      content: Text(
                        'Please select PIT',
                        style: getWhiteTextStyle(),
                      )));
                  return;
                }
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
                    .where('unit', isEqualTo: dataUnit['unitNumber'])
                    .get();

                if (querySnapshot.docs.isNotEmpty) {
                  final docId = querySnapshot.docs.first.id;

                  // revisi data
                  await firestore
                      .collection('daily_pressure')
                      .doc(docId)
                      .update({
                    'idSite': idSite,
                    'tanggal': DateTime.now().toIso8601String(),
                    'unit': dataUnit['unitNumber'],
                    'hm': hmCtrl.text,
                    'posisi': position.map((p) {
                      final pIndex = position.indexOf(p);
                      return {
                        'pos': '${pIndex + 1}',
                        'pressure': (p['pressure']) ?? '0',
                        'luka': (selectedType == 0) ? '' : p['damage']
                      };
                    }),
                    'pit': (pit.isEmpty) ? 'Default' : pit[selectedPit],
                  });
                } else {
                  // tambah data
                  await firestore.collection('daily_pressure').add({
                    'idSite': idSite,
                    'tanggal': DateTime.now().toIso8601String(),
                    'unit': dataUnit['unitNumber'],
                    'hm': hmCtrl.text,
                    'posisi': position.map((p) {
                      final pIndex = position.indexOf(p);
                      return {
                        'pos': '${pIndex + 1}',
                        'pressure': (p['pressure']) ?? '0',
                        'luka': (selectedType == 0) ? '' : p['damage']
                      };
                    }),
                    'pit': (pit.isEmpty) ? 'Default' : pit[selectedPit],
                  });
                }
              } catch (e) {
                print('error bmb : $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              'Save',
              style: getWhiteTextStyle(
                fontSize: 16,
                fontWeight: w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
