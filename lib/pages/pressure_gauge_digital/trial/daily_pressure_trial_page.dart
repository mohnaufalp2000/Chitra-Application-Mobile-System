import 'dart:async';
import 'dart:developer';

import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_list.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/daily_pressure_list_trial_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

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
  List<BluetoothDevice> devices = [];
  List<Map<String, dynamic>> tires = [
    {
      'position': '1',
      'pressure': '',
      'injury': '',
    },
    {
      'position': '2',
      'pressure': '',
      'injury': '',
    },
    {
      'position': '3',
      'pressure': '',
      'injury': '',
    },
    {
      'position': '4',
      'pressure': '',
      'injury': '',
    },
    {
      'position': '5',
      'pressure': '',
      'injury': '',
    },
    {
      'position': '6',
      'pressure': '',
      'injury': '',
    },
  ];

  int selectedTire = -1;
  TextEditingController unitCtrl = TextEditingController(text: '');
  TextEditingController hmCtrl = TextEditingController(text: '');

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

  @override
  Widget build(BuildContext context) {
    idSite = ModalRoute.of(context)?.settings.arguments as String;

    return Scaffold(
      appBar: appBarWidget('Form Tire Inspection', context),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(
                height: 24,
              ),
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
                              (isConnected) ? 'Disconnect' : 'Connect',
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
                                      await BluetoothConnection.toAddress(
                                          device.address);
                                  print('Connected to the device');
                                  _listenForData();
                                  devices.clear();
                                  devices.add(device);
                                  setState(() {});
                                } catch (e) {
                                  print('Cannot connect to the device: $e');
                                }
                              }
                            })),
                  );
                }).toList(),
              ),
              Container(
                child: TextFormField(
                  controller: unitCtrl,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  // validator: _validateUserName,
                  onFieldSubmitted: (String value) {
                    // FocusScope.of(context).requestFocus(_passwordEmail);
                  },
                  decoration: InputDecoration(
                      labelText: 'Unit Id', icon: Icon(Icons.front_loader)),
                ),
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
              Column(
                children: tires.map((tire) {
                  final index = tires.indexOf(tire);
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
                                            controller: TextEditingController(
                                                text:
                                                    '${tires[index]['pressure']}'),
                                            isDigitOnly: true,
                                            onChng: (string) {
                                              tires[index]['pressure'] = string;
                                            },
                                            type: TextInputType.number,
                                            hint: '',
                                          )),
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
                                        backgroundColor: (selectedTire == index)
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
                }).toList(),
              )
            ],
          ),
        ),
      )),
      bottomNavigationBar: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
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

                    // revisi data
                    await firestore
                        .collection('daily_pressure')
                        .doc(docId)
                        .update({
                      'idSite': idSite,
                      'tanggal': DateTime.now().toIso8601String(),
                      'unit': unitCtrl.text,
                      'hm': hmCtrl.text,
                      'posisi': tires.map((tire) {
                        final pIndex = tires.indexOf(tire);
                        return {
                          'pos': '${pIndex + 1}',
                          'pressure':
                              (tire['pressure'] != '') ? tire['pressure'] : '0',
                          'luka':
                              (tire['injury'] == '') ? null : [tire['injury']]
                        };
                      }),
                      'pit': 'Default',
                    });
                  } else {
                    // tambah data
                    await firestore.collection('daily_pressure').add({
                      'idSite': idSite,
                      'tanggal': DateTime.now().toIso8601String(),
                      'unit': unitCtrl.text,
                      'hm': hmCtrl.text,
                      'posisi': tires.map((tire) {
                        final pIndex = tires.indexOf(tire);
                        return {
                          'pos': '${pIndex + 1}',
                          'pressure':
                              (tire['pressure'] != '') ? tire['pressure'] : '0',
                          'luka':
                              (tire['injury'] == '') ? null : [tire['injury']]
                        };
                      }),
                      'pit': 'Default',
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
