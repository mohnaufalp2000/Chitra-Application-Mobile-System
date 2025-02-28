import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camos/core/blocs/tire/tire_bloc.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/core/services/model/daily_press.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class DailyCheckFormPage extends StatefulWidget {
  static const routeName = '/tire-inspection-page';

  const DailyCheckFormPage({super.key});

  @override
  State<DailyCheckFormPage> createState() => _DailyCheckFormPageState();
}

class _DailyCheckFormPageState extends State<DailyCheckFormPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  // List<Map<String, dynamic>> position = [];
  List<String> tireCondition = ['Normal', 'Low Pressure'];
  List<Position> position = [];
  String idSite = '';
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
  List<String> rating = [
    'A',
    'B',
    'C',
    'X',
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
  int selectedPit = -1;
  int selectedPosIndex = -1;
  int selectedType = 1;
  int selectedRoute = 0;
  int checkAmount = 0;
  Map<String, dynamic> dataUnit = {};
  String buttonText = 'Select';

  // Bluetooth
  FlutterBluetoothSerial bluetoothSerial = FlutterBluetoothSerial.instance;
  BluetoothConnection? connection;
  bool get isConnected => connection != null && connection!.isConnected;
  List<BluetoothDevice> devices = [];
  Map<String, dynamic> user = {};

  bool isProcessing = false;
  final ImagePicker _picker = ImagePicker();

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

  // Future<List<String>> receiveRatingTire(String unit) async {
  //   List<String> fixRating = [];
  //   final yesterday = DateTime.now().subtract(Duration(days: 1));
  //   final startOfDay = DateTime(yesterday.year, yesterday.month, yesterday.day);
  //   final endOfDay =
  //       DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
  //   final ratingQuery = await firestore
  //       .collection(dataUnit['type'] == 'spm' ? 'adjusment_spm' : 'daily_pressure')
  //       .where('unit', isEqualTo: unit)
  //       .where('tanggal', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
  //       .where('tanggal', isLessThanOrEqualTo: endOfDay.toIso8601String())
  //       .get();
  //   final ratingMap = ratingQuery.docs.first;
  //   List<dynamic> ratingList = ratingMap.data()['posisi'] as List<dynamic>;
  //   for (int i = 0; i < ratingList.length; i++) {
  //     fixRating.add(ratingList[i]['rating'] ?? '');
  //   }
  //   return fixRating;
  // }

  Future<List<String>> receiveRatingTire(String unit) async {
    List<String> fixRating = [];

    Future<List<String>> fetchRatingData(DateTime date) async {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final ratingQuery = await firestore
          .collection(
              dataUnit['type'] == 'spm' ? 'adjusment_spm' : 'daily_pressure')
          .where('unit', isEqualTo: unit)
          .where('tanggal',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('tanggal', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      if (ratingQuery.docs.isNotEmpty) {
        final ratingMap = ratingQuery.docs.first;
        List<dynamic> ratingList = ratingMap.data()['posisi'] as List<dynamic>;
        return ratingList
            .map((item) => item['rating'] ?? '')
            .toList()
            .cast<String>();
      }

      return [];
    }

    // Coba ambil data untuk kemarin
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    fixRating = await fetchRatingData(yesterday);

    // Jika data kemarin kosong, coba ambil data untuk kemarin lusa
    if (fixRating.isEmpty) {
      final dayBeforeYesterday = DateTime.now().subtract(Duration(days: 2));
      fixRating = await fetchRatingData(dayBeforeYesterday);
    }

    return fixRating;
  }

  Future<List<dynamic>> receiveDamageTire(String unit) async {
    List<dynamic> fixDamage = [];

    Future<List<dynamic>> fetchDamageData(DateTime date) async {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      final damageQuery = await firestore
          .collection(
              dataUnit['type'] == 'spm' ? 'adjusment_spm' : 'daily_pressure')
          .where('unit', isEqualTo: unit)
          .where('tanggal',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('tanggal', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      if (damageQuery.docs.isNotEmpty) {
        final damageMap = damageQuery.docs.first;
        List<dynamic> damageList = damageMap.data()['posisi'] as List<dynamic>;

        return damageList.map((item) => item['luka'] ?? '').toList();
      }

      return [];
    }

    // Coba ambil data untuk kemarin
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    fixDamage = await fetchDamageData(yesterday);

    // Jika data kemarin kosong, coba ambil data untuk kemarin lusa
    if (fixDamage.isEmpty) {
      final dayBeforeYesterday = DateTime.now().subtract(Duration(days: 2));
      fixDamage = await fetchDamageData(dayBeforeYesterday);
    }

    log('damage tire: ${fixDamage[0].length}');
    return fixDamage;
  }

  List<bool> updateCheckedDamageValues(
      List<dynamic> damage, List<bool> checkedDamageValues) {
    for (int i = 0; i < damageType.length; i++) {
      // Set true jika damageType[i] ada dalam damage
      checkedDamageValues[i] = damage.contains(damageType[i]);
    }
    log('jenis kerusakan : $checkedDamageValues');

    return checkedDamageValues;
  }

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
                    // position[inspectRoute[0][checkAmount]]=
                    //     firstNumber;
                    position[inspectRoute[0][checkAmount]] =
                        position[inspectRoute[0][checkAmount]]
                            .copyWith(pressure: firstNumber);
                  checkAmount++;
                });
                break;
              case 1:
                setState(() {
                  if (checkAmount < 6)
                    // position[inspectRoute[1][checkAmount]]['pressure'] =
                    //     firstNumber;
                    position[inspectRoute[1][checkAmount]] =
                        position[inspectRoute[1][checkAmount]]
                            .copyWith(pressure: firstNumber);
                  checkAmount++;
                });
                break;
              case 2:
                setState(() {
                  if (checkAmount < 6)
                    // position[inspectRoute[2][checkAmount]]['pressure'] =
                    //     firstNumber;
                    position[inspectRoute[2][checkAmount]] =
                        position[inspectRoute[2][checkAmount]]
                            .copyWith(pressure: firstNumber);
                  checkAmount++;
                });
                break;
            }
            print('tekananangin : ${pressureDigitalCtrl.text}');
            break;
          case 1:
            // Manual Type
            if (selectedPosIndex != -1) {
              // position[selectedPosIndex]['pressure'] = firstNumber;
              position[selectedPosIndex] =
                  position[selectedPosIndex].copyWith(pressure: firstNumber);
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
    if (idSite == '1' || idSite == '2') {
      idSite = await getSelectedIdSitePreferences();
    }
    if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
      context.read<TireBloc>().add(GetUnitTiresEvent(
          idSite: idSite, unitNumber: dataUnit['unitNumber']));
    }

    // setState(() {
    //   if (idSite == '52') {
    //     pit.add('Utara');
    //     pit.add('Selatan');
    //     pit.add('RML');
    //     pit.add('WS');
    //   }
    // });
  }

  Future<List<String>> uploadImageFirebase(String idSite) async {
    final List<String> list = [];

    for (int i = 0; i < position.length; i++) {
      // final image = position[i]['image'];
      final image = position[i].image;

      if (image != '' && image != null) {
        final ref = storage.ref().child(
            'daily_check/${DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now())}-pos${i + 1}-$idSite');
        final uploadTask = ref.putFile(File(image));
        final snapshot = await uploadTask.whenComplete(() {});
        final downloadUrl = await snapshot.ref.getDownloadURL();
        list.add(downloadUrl);
      } else {
        list.add('');
      }
    }
    return list;
  }

  getUser() async {
    user = await getUserPreferences();
    log('username : ${user}');
  }

  Future<String> pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        return image.path;
      }
    } catch (e) {
      print('Error picking image: $e');
    }
    return '';
  }

  Future<String> showImageSourceDialog(
      BuildContext context, String image, int index) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Choose One',
            style: getBlackTextStyle(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text(
                  'Gallery',
                  style: getBlackTextStyle(),
                ),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  String image = await pickImage(ImageSource.gallery);
                  log('Image from gallery: $image');
                  Navigator.pop(context, image); // Kembalikan nilai ke pop
                },
              ),
              Divider(),
              ListTile(
                leading: Icon(Icons.camera_alt),
                title: Text(
                  'Camera',
                  style: getBlackTextStyle(),
                ),
                trailing: Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  String image = await pickImage(ImageSource.camera);
                  log('Image from camera: $image');
                  Navigator.pop(context, image); // Kembalikan nilai ke pop
                },
              ),
              (image != '')
                  ? Column(
                      children: [
                        SizedBox(
                            width: 300,
                            height: 300,
                            child: Image.file(
                              File(image),
                              fit: BoxFit.cover,
                            )),
                        const SizedBox(
                          height: 6,
                        ),
                        ElevatedButton(
                            onPressed: () {
                              showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(
                                      'Confirmation',
                                      style:
                                          getBlackTextStyle(fontWeight: w700),
                                    ),
                                    content: Text(
                                      'Are you sure?',
                                      style: getBlackTextStyle(),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(
                                          'No',
                                          style: getGreyTextStyle(grey6A707C),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          // position[index]['image'] = '';
                                          position[index] = position[index]
                                              .copyWith(image: '');

                                          Navigator.pop(context);
                                          Navigator.pop(context);
                                        },
                                        child: Text(
                                          'Yes',
                                          style: getBlackTextStyle(),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            style: ButtonStyle(
                              backgroundColor:
                                  MaterialStateProperty.resolveWith<Color>(
                                      (Set<MaterialState> states) {
                                return Colors.red;
                              }),
                            ),
                            child: Text(
                              'Delete Image',
                              style: getWhiteTextStyle(),
                            ))
                      ],
                    )
                  : SizedBox(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                    context, ''); // Kembalikan nilai kosong jika batal
              },
              child: Text('Batal'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    // addPositionVariable();
    super.initState();
    callTires();
    getUser();
  }

  @override
  void dispose() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    dataUnit =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    log('data ban : ${dataUnit}');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Daily Check Pressure',
          style: getBlackTextStyle(),
        ),
        actions: [],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocConsumer<TireBloc, TireState>(
            listener: (context, state) async {
              if (state is TiresLoadedState) {
                //? BLOC TER EKSEKUSI dua kali dan mengambil jumlah tire sebelumnya
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
                    pit.add('WS');
                    break;
                }
                if (dataUnit['position'] != null) {
                  position.addAll(dataUnit['position']);
                } else {
                  final today = DateTime.now();
                  final formattedToday =
                      '${today.month.toString().padLeft(2, '0')}' // MM
                      '${today.day.toString().padLeft(2, '0')}' // DD
                      '${(today.year % 100).toString().padLeft(2, '0')}'; // YY
                  for (var i = 0; i < state.units.length; i++) {
                    if (position.length < state.units.length) {
                      // position.add({
                      //   'pressure': '',
                      //   'adjusmentPressure': '',
                      //   'rating': '',
                      //   'damage': null
                      // });
                      position.add(
                        Position(
                          pos: '${i + 1}',
                          pressure: '',
                          adjusmentPressure: '',
                          rating: '',
                          luka: [],
                          image: '',
                          size: state.units[i].size ?? '',
                          idInventory: state.units[i].idinventory ?? '',
                          idUnit: state.units[i].idUnit ?? '',
                          idDaily:
                              '${state.units[i].idUnit}${i + 1}${formattedToday}${idSite}',
                          kondisi: '',
                        ),
                      );
                    }
                  }
                }

                // Input data rating sebelumnya
                List<dynamic> ratings =
                    await receiveRatingTire(dataUnit['unitNumber']);
                log('list rating : $ratings');
                setState(() {
                  for (int i = 0; i < ratings.length; i++) {
                    // position[i]['rating'] = ratings[i];
                    position[i] = position[i].copyWith(rating: ratings[i]);
                  }
                });
                // Input data damage sebelumnya
                List<dynamic> damages =
                    await receiveDamageTire(dataUnit['unitNumber']);
                List<List<String>> convertedDamage = damages
                    .map<List<String>>((e) => List<String>.from(e))
                    .toList();

                log('damage tire : $damages');
                setState(() {
                  for (int i = 0; i < convertedDamage.length; i++) {
                    // Cek jika posisi 'damage' sudah memiliki nilai, tidak akan ditimpa

                    if (position[i].luka.isEmpty) {
                      position[i] =
                          position[i].copyWith(luka: convertedDamage[i]);
                    }
                  }
                });
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
                      height: (pit.isNotEmpty) ? 12 : 0,
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
                                          // '${position[posIndex]['pressure']} Psi',
                                          '${position[posIndex].pressure} Psi',
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
                                  InkWell(
                                    onTap: () {
                                      log('posisi sebelum : $position');
                                    },
                                    child: Text(
                                      'Tire',
                                      style: getBlackTextStyle(
                                          fontSize: 18, fontWeight: w700),
                                    ),
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
                                                                      // setState(
                                                                      //     () {
                                                                      //   position[posIndex]
                                                                      //       [
                                                                      //       'pressure'] = ps;
                                                                      //   Navigator.of(context)
                                                                      //       .pop();
                                                                      // });
                                                                      setState(
                                                                          () {
                                                                        position[
                                                                            posIndex] = position[
                                                                                posIndex]
                                                                            .copyWith(pressure: ps);
                                                                        // input kondisi pressure
                                                                        position[
                                                                            posIndex] = position[
                                                                                posIndex]
                                                                            .copyWith(
                                                                          kondisi: int.parse(((dataUnit['reccPress'] as List<Map<String, dynamic>>).firstWhere(
                                                                                    (element) => element.containsKey(position[posIndex].size),
                                                                                    orElse: () => <String, dynamic>{},
                                                                                  )[position[posIndex].size])) <
                                                                                  int.parse(ps)
                                                                              ? 'Normal'
                                                                              : 'Low Pressure',
                                                                        );
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
                                                                          // position[posIndex]['pressure'] =
                                                                          //     pressureCtrl.text;
                                                                          position[posIndex] =
                                                                              position[posIndex].copyWith(pressure: pressureCtrl.text);
                                                                          position[posIndex] =
                                                                              position[posIndex].copyWith(
                                                                            kondisi: int.parse(((dataUnit['reccPress'] as List<Map<String, dynamic>>).firstWhere(
                                                                                      (element) => element.containsKey(position[posIndex].size),
                                                                                      orElse: () => <String, dynamic>{},
                                                                                    )[position[posIndex].size])) <
                                                                                    int.parse(pressureCtrl.text)
                                                                                ? 'Normal'
                                                                                : 'Low Pressure',
                                                                          );
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
                                            // child: (position[posIndex]
                                            //             ['pressure'] ==
                                            //         '')
                                            child: (position[posIndex]
                                                        .pressure ==
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
                                                // : Text(
                                                //     '${position[posIndex]['pressure']} Psi',
                                                //     style: getWhiteTextStyle(
                                                //       fontSize: 24,
                                                //       fontWeight: w700,
                                                //     ),
                                                //   ),
                                                : Text(
                                                    '${position[posIndex].pressure} Psi',
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
                                        // adjusment pressure
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
                                                                        // position[posIndex]
                                                                        //     [
                                                                        //     'adjusmentPressure'] = ps;
                                                                        position[
                                                                            posIndex] = position[
                                                                                posIndex]
                                                                            .copyWith(adjusmentPressure: ps);
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
                                                                          // position[posIndex]['adjusmentPressure'] =
                                                                          //     pressureCtrl.text;
                                                                          position[posIndex] =
                                                                              position[posIndex].copyWith(adjusmentPressure: pressureCtrl.text);
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
                                            // child: (position[posIndex]
                                            //             ['adjusmentPressure'] ==
                                            //         '')
                                            child: (position[posIndex]
                                                        .adjusmentPressure ==
                                                    '')
                                                ? Text(
                                                    'Adj Pressure',
                                                    style: getWhiteTextStyle(),
                                                  )
                                                // : Text(
                                                //     '${position[posIndex]['adjusmentPressure']} Psi (Adj)',
                                                //     style: getWhiteTextStyle(
                                                //       fontSize: 16,
                                                //       fontWeight: w700,
                                                //     ),
                                                //   ),
                                                : Text(
                                                    '${position[posIndex].adjusmentPressure} Psi (Adj)',
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
                                        // rating tire
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
                                                                            Colors.green),
                                                                    onPressed:
                                                                        () {
                                                                      setState(
                                                                          () {
                                                                        // position[posIndex]['rating'] =
                                                                        //     rat;
                                                                        position[
                                                                            posIndex] = position[
                                                                                posIndex]
                                                                            .copyWith(rating: rat);
                                                                        Navigator.of(context)
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
                                            // child: (position[posIndex]
                                            //             ['rating'] ==
                                            //         '')
                                            child: (position[posIndex].rating ==
                                                    '')
                                                ? Text(
                                                    'Rating',
                                                    style: getWhiteTextStyle(),
                                                  )
                                                // : Text(
                                                //     'Rating ${position[posIndex]['rating']}',
                                                //     style: getWhiteTextStyle(
                                                //       fontSize: 16,
                                                //       fontWeight: w700,
                                                //     ),
                                                //   ),
                                                : Text(
                                                    'Rating ${position[posIndex].rating}',
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

                                                if (position[posIndex]
                                                    .luka
                                                    .isNotEmpty) {
                                                  for (int i = 0;
                                                      i < damageType.length;
                                                      i++) {
                                                    if (position[posIndex]
                                                        .luka
                                                        .contains(
                                                            damageType[i])) {
                                                      checkedDamageValues[i] =
                                                          true;
                                                    }
                                                  }
                                                  damageCtrl.text =
                                                      position[posIndex]
                                                              .luka
                                                              .isNotEmpty
                                                          ? position[posIndex]
                                                              .luka[0]
                                                          : '';
                                                }

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

                                                                      final List<
                                                                              String>
                                                                          tmp =
                                                                          [];

                                                                      // isi damage dengan ketikan
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
                                                                        } else {
                                                                          tmp.removeWhere((element) =>
                                                                              element ==
                                                                              damageType[i]);
                                                                        }
                                                                      }
                                                                      log('idx luka ban : $posIndex');

                                                                      if (tmp
                                                                          .isNotEmpty) {
                                                                        // position[posIndex]
                                                                        //     [
                                                                        //     'damage'] = [];
                                                                        position[
                                                                            posIndex] = position[
                                                                                posIndex]
                                                                            .copyWith(luka: []);

                                                                        position[posIndex]
                                                                            .luka
                                                                            .addAll(tmp);

                                                                        log('hasil luka ban : ${position}');
                                                                      }

                                                                      // jika hapus damage hari kemarin
                                                                      if (position[posIndex].luka[0] ==
                                                                              '' &&
                                                                          position[posIndex].luka.length ==
                                                                              1) {
                                                                        position[
                                                                            posIndex] = position[
                                                                                posIndex]
                                                                            .copyWith(luka: []);
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
                                              child: Text(
                                                (position[posIndex].luka ==
                                                            null ||
                                                        position[posIndex]
                                                            .luka
                                                            .isEmpty)
                                                    ? 'Damage Tire (None)'
                                                    : position[posIndex]
                                                        .luka
                                                        .join('\n---\n'),
                                                textAlign: TextAlign.center,
                                                style: getWhiteTextStyle(
                                                    fontSize: 14),
                                              ),
                                            )),

                                        const SizedBox(
                                          height: 12,
                                        ),
                                        // IMAGE DAILY CHECK
                                        (dataUnit['type'] != null)
                                            ? SizedBox(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.39,
                                                child: ElevatedButton(
                                                    onPressed: () async {
                                                      // final image =
                                                      //     await showImageSourceDialog(
                                                      //         context,
                                                      //         position[posIndex]
                                                      //             ['image'],
                                                      //         posIndex);
                                                      // if (image != '') {
                                                      //   position[posIndex]
                                                      //       ['image'] = image;
                                                      // }
                                                      final image =
                                                          await showImageSourceDialog(
                                                              context,
                                                              position[posIndex]
                                                                  .image,
                                                              posIndex);
                                                      if (image != '') {
                                                        position[posIndex] =
                                                            position[posIndex]
                                                                .copyWith(
                                                                    image:
                                                                        image);
                                                      }

                                                      log('posisi terbaru : ${position}');
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                Colors.orange,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            )),
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          vertical: 8.0),
                                                      child: Text(
                                                        'Take Picture',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style:
                                                            getWhiteTextStyle(
                                                                fontSize: 14),
                                                      ),
                                                    )),
                                              )
                                            : SizedBox(),
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
              // jika salah satu data pressure ada yang kosong
              bool hasEmptyPressure = position.any((p) => p.pressure.isEmpty);

              if (hasEmptyPressure) {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

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

              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              if (isProcessing) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      'Please wait a moment before pressing again.',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
                return;
              }

              setState(() {
                isProcessing = true;
              });

              log('posisi ban : $position');

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: green00968A,
                  content: Text(
                    'Data Succesfully Added',
                    style: getWhiteTextStyle(),
                  )));
              try {
                final today = DateTime.now();
                final startOfDay = DateTime(today.year, today.month, today.day);
                final endOfDay =
                    DateTime(today.year, today.month, today.day, 23, 59, 59);

                final listImage = await uploadImageFirebase(idSite);

                final querySnapshot = await FirebaseFirestore.instance
                    .collection(dataUnit['type'] == 'spm'
                        ? 'adjusment_spm'
                        : 'daily_pressure')
                    .where('unit', isEqualTo: dataUnit['unitNumber'])
                    .where('tanggal',
                        isGreaterThanOrEqualTo: startOfDay.toIso8601String())
                    .where('tanggal',
                        isLessThanOrEqualTo: endOfDay.toIso8601String())
                    .get();

                if (querySnapshot.docs.isNotEmpty) {
                  final docId = querySnapshot.docs.first.id;

                  // revisi data
                  await firestore
                      .collection(dataUnit['type'] == 'spm'
                          ? 'adjusment_spm'
                          : 'daily_pressure')
                      .doc(docId)
                      .update({
                    'idSite': idSite,
                    'user': user['username'] ?? auth.currentUser!.email,
                    'tanggal': DateTime.now().toIso8601String(),
                    'hari': DateTime.now().toIso8601String().substring(0, 10),
                    'jam': DateTime.now().toIso8601String().substring(11, 19),
                    'unit': dataUnit['unitNumber'],
                    'hm': hmCtrl.text,
                    'posisi': position.map((p) {
                      final pIndex = position.indexOf(p);

                      // return {
                      //   'pos': '${pIndex + 1}',
                      //   'rating': (p['rating']) ?? '',
                      //   'pressure': (p['pressure']) ?? '0',
                      //   'adjusmentPressure': (p['adjusmentPressure']) ?? '0',
                      //   'luka': (selectedType == 0) ? '' : p['damage'],
                      //   'image':
                      //       (listImage[pIndex] != '') ? listImage[pIndex] : '',
                      // };
                      return {
                        'pos': '${pIndex + 1}',
                        'rating': (p.rating) ?? '',
                        'pressure': (p.pressure) ?? '0',
                        'adjusmentPressure': (p.adjusmentPressure) ?? '0',
                        'luka': (selectedType == 0) ? '' : p.luka,
                        'image':
                            (listImage[pIndex] != '') ? listImage[pIndex] : '',
                        'tireSize': (p.size ?? ''),
                        'idInventory': (p.idInventory ?? ''),
                        'idUnit': (p.idUnit ?? ''),
                        'idDaily': '${p.idDaily}',
                        'kondisi': '${p.kondisi}',
                      };
                    }),
                    'pit': (selectedPit == -1) ? 'Default' : pit[selectedPit],
                  });
                } else {
                  final queryYesterdaySnapshot = await FirebaseFirestore
                      .instance
                      .collection(dataUnit['type'] == 'spm'
                          ? 'adjusment_spm'
                          : 'daily_pressure')
                      .where('unit', isEqualTo: dataUnit['unitNumber'])
                      .where('tanggal',
                          isGreaterThanOrEqualTo: DateTime(
                                  today.year,
                                  today.month,
                                  today.subtract(Duration(days: 1)).day)
                              .toIso8601String())
                      .where('tanggal',
                          isLessThanOrEqualTo: endOfDay.toIso8601String())
                      .get();

                  if (queryYesterdaySnapshot.docs.isEmpty) {
                    // tambah data kemarin
                    await firestore
                        .collection(dataUnit['type'] == 'spm'
                            ? 'adjusment_spm'
                            : 'daily_pressure')
                        .add({
                      // 'nama': (user),
                      'idSite': idSite,
                      'user': user['username'] ?? auth.currentUser!.email,
                      'tanggal': DateTime.now()
                          .subtract(Duration(days: 1))
                          .toIso8601String(),
                      'hari': DateTime.now()
                          .subtract(Duration(days: 1))
                          .toIso8601String()
                          .substring(0, 10),
                      'jam': DateTime.now()
                          .subtract(Duration(days: 1))
                          .toIso8601String()
                          .substring(11, 19),
                      'unit': dataUnit['unitNumber'],
                      'hm': hmCtrl.text,
                      'posisi': position.map((p) {
                        final pIndex = position.indexOf(p);
                        // return {
                        //   'pos': '${pIndex + 1}',
                        //   'pressure': (p['pressure']) ?? '0',
                        //   'rating': (p['rating']) ?? '',
                        //   'adjusmentPressure': (p['adjusmentPressure']) ?? '0',
                        //   'luka': (selectedType == 0) ? '' : p['damage'],
                        //   'image': (listImage[pIndex] != '')
                        //       ? listImage[pIndex]
                        //       : '',
                        // };
                        return {
                          'pos': '${pIndex + 1}',
                          'pressure': (p.pressure) ?? '0',
                          'rating': (p.rating) ?? '',
                          'adjusmentPressure': (p.adjusmentPressure) ?? '0',
                          'luka': (selectedType == 0) ? '' : p.luka,
                          'image': (listImage[pIndex] != '')
                              ? listImage[pIndex]
                              : '',
                          'tireSize': (p.size ?? ''),
                          'idInventory': (p.idInventory ?? ''),
                          'idUnit': (p.idUnit ?? ''),
                          'idDaily': '${p.idDaily}',
                          'kondisi': '${p.kondisi}',
                        };
                      }),
                      'pit': (selectedPit == -1) ? 'Default' : pit[selectedPit],
                    });
                  }

                  // tambah data
                  await firestore
                      .collection(dataUnit['type'] == 'spm'
                          ? 'adjusment_spm'
                          : 'daily_pressure')
                      .add({
                    // 'nama': (user),
                    'idSite': idSite,
                    'user': user['username'] ?? auth.currentUser!.email,
                    'tanggal': DateTime.now().toIso8601String(),
                    'hari': DateTime.now().toIso8601String().substring(0, 10),
                    'jam': DateTime.now().toIso8601String().substring(11, 19),
                    'unit': dataUnit['unitNumber'],
                    'hm': hmCtrl.text,
                    'posisi': position.map((p) {
                      final pIndex = position.indexOf(p);
                      // return {
                      //   'pos': '${pIndex + 1}',
                      //   'pressure': (p['pressure']) ?? '0',
                      //   'rating': (p['rating']) ?? '',
                      //   'adjusmentPressure': (p['adjusmentPressure']) ?? '0',
                      //   'luka': (selectedType == 0) ? '' : p['damage'],
                      //   'image':
                      //       (listImage[pIndex] != '') ? listImage[pIndex] : '',
                      // };
                      return {
                        'pos': '${pIndex + 1}',
                        'pressure': (p.pressure) ?? '0',
                        'rating': (p.rating) ?? '',
                        'adjusmentPressure': (p.adjusmentPressure) ?? '0',
                        'luka': (selectedType == 0) ? '' : p.luka,
                        'image':
                            (listImage[pIndex] != '') ? listImage[pIndex] : '',
                        'tireSize': (p.size ?? ''),
                        'idInventory': (p.idInventory ?? ''),
                        'idUnit': (p.idUnit ?? ''),
                        'idDaily': '${p.idDaily}',
                        'kondisi': '${p.kondisi}',
                      };
                    }),
                    'pit': (selectedPit == -1) ? 'Default' : pit[selectedPit],
                  });
                }
              } catch (e) {
                print('error bmb : $e');
              } finally {
                await Future.delayed(
                    Duration(seconds: 3)); // Jeda waktu 3 detik
                setState(() {
                  isProcessing = false;
                });
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
