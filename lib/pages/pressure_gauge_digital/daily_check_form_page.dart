import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_cubit.dart';
import 'package:camos/core/blocs/bluetooth/bluetooth_on_off_cubit/bluetooth_on_off_state.dart';
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_cubit.dart';
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart'
    as connectedDevicesState;
import 'package:camos/core/blocs/bluetooth/connected_devices_cubit/connected_devices_state.dart';
import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_cubit.dart';
import 'package:camos/core/blocs/bluetooth/discover_services_cubit/discover_services_state.dart';
import 'package:camos/core/utils/bluetooth/utils/bluetooth_utils.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:camos/pages/pressure_gauge_digital/trial/scan_device_page.dart';
import 'package:camos/pages/pressure_gauge_digital/widget/bluetooth/list_of_connected_devices_widget.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/blocs/tire/tire_bloc.dart';
import '../../core/services/shared_preferences/shared_preferences.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/utils/data/id_site.dart';
import '../../core/services/model/daily_press.dart';
import '../../core/utils/functions/functions.dart';
import '../../core/widgets/appbar_widget.dart';
import '../../core/widgets/button_widget.dart';
import '../../core/widgets/input_form_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

class DailyCheckFormPage extends StatefulWidget {
  static const routeName = '/daily-check-pressure-page';

  const DailyCheckFormPage({super.key});

  @override
  State<DailyCheckFormPage> createState() => _DailyCheckFormPageState();
}

class _DailyCheckFormPageState extends State<DailyCheckFormPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  final HomeState homeState = Get.find<HomeState>();
  bool _isInit = true;
  bool _listenerAdded = false;

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
  List<String> tireAccessories = [
    'Reseal Oring',
    'Rim Condition',
    'Inflate Tire',
    'Lock Driver',
    'Slide Lock',
    'Valve Cap',
    'Valve Protector',
    'Stud and Nut',
  ];
  List<String> damageType = [
    'Accident',
    'Bead Crack',
    'Block Valve',
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
  Map<String, dynamic> user = {};

  final ImagePicker _picker = ImagePicker();

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

  void applyPressureData(String pressureValue) {
    setState(() {
      pressureDigitalCtrl.text = pressureValue;
      final firstNumber = pressureValue; // Karena diasumsikan sudah angka saja

      switch (selectedType) {
        // PG DIGITAL Type
        case 0:
          // Logic auto-fill untuk PG Digital
          if (checkAmount < position.length) {
            position[inspectRoute[selectedRoute][checkAmount]] =
                position[inspectRoute[selectedRoute][checkAmount]]
                    .copyWith(pressure: firstNumber);
            checkAmount++;
          }
          break;
        case 1:
          // Manual Type - Logic ini mungkin perlu diubah karena tombol 'Pressure'
          // sekarang membuka dialog, bukan menunggu input Bluetooth
          if (selectedPosIndex != -1) {
            position[selectedPosIndex] =
                position[selectedPosIndex].copyWith(pressure: firstNumber);
            pressureDigitalCtrl.clear();
            selectedPosIndex = -1;
            // Jika ada dialog yang terbuka untuk input manual, tutup.
            // Anda perlu menyesuaikan alur UI untuk membedakan input manual dan BT.
          }
          break;
      }
      log('tekanan angin dari BT: ${pressureDigitalCtrl.text}');
    });
  }

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

  void callTires() async {
    // idSite = await getIdSitePreferences();
    // log('id site daliy check : $idSite');
    // if (idSite == '1' || idSite == '2') {
    //   idSite = await getSelectedIdSitePreferences();
    // }
    idSite = homeState.currentSiteId;

    if (dataUnit['isCTS'] == null) {
      if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
        context.read<TireBloc>().add(GetUnitTiresEvent(
            idSite: idSite, unitNumber: dataUnit['unitNumber']));
      }
    }
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

  // ADDITIONAL TIRE ACCESSORIES EDIT #4
  Future<void> uploadAllTireAccessories() async {
    for (int i = 0; i < position.length; i++) {
      final pos = position[i];

      // List baru untuk accessories setelah upload
      final List<TireAccessory> updatedAccessories = [];

      for (int j = 0; j < pos.tireAccessories.length; j++) {
        final acc = pos.tireAccessories[j];

        // kalau image kosong, langsung lanjut
        if (acc.image.isEmpty) {
          updatedAccessories.add(acc);
          continue;
        }

        try {
          final file = File(acc.image);
          if (!file.existsSync()) {
            print('⚠️ File tidak ditemukan: ${acc.image}');
            updatedAccessories.add(acc);
            continue;
          }

          // nama file unik (ex: ResealOring_1730201209500.jpg)
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final cleanName = acc.name.replaceAll(' ', '');
          final ext = path.extension(acc.image);
          final fileName =
              '${cleanName}_$timestamp${ext}_${idSite}_${pos.idUnit}';

          // lokasi penyimpanan: tire_acc/ResealOring_1730201209500.jpg
          final ref = storage.ref().child('tire_acc/$fileName');

          // upload ke Firebase Storage
          final uploadTask = await ref.putFile(file);
          final downloadUrl = await uploadTask.ref.getDownloadURL();

          print('✅ Upload sukses untuk ${acc.name}: $downloadUrl');

          // tambahkan versi baru yang pakai URL
          updatedAccessories.add(acc.copyWith(image: downloadUrl));
        } catch (e) {
          print('❌ Error upload ${acc.name}: $e');
          updatedAccessories.add(acc); // tetap masukkan data lamanya
        }
      }

      // Update position dengan accessories yang sudah diganti URL
      position[i] = pos.copyWith(tireAccessories: updatedAccessories);
    }

    print('🎯 Semua upload selesai.');
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
    super.initState();
    context.read<BluetoothOnOffCubit>().checkBluetoothStatus();
    final connectedCubit = context.read<ConnectedDevicesCubit>();
    log('connected cubit : $connectedCubit');
    connectedCubit.fetchConnectedDevices(); // HANYA MEMULAI fetch
    getUser();
  }

  // @override
  // void initState() {
  //   super.initState();

  //   // Panggil fungsi-fungsi Anda yang sudah ada
  //   context.read<BluetoothOnOffCubit>().checkBluetoothStatus();
  //   final connectedCubit = context.read<ConnectedDevicesCubit>();
  //   log('connected cubit : $connectedCubit');
  //   connectedCubit.fetchConnectedDevices();
  //   getUser();

  //   // --- TAMBAHKAN KODE INI ---
  //   // Cek state cubit SAAT INI
  //   final currentState = connectedCubit.state;
  //   log('connected cubit current state : $currentState');
  //   if (currentState is connectedDevicesState.ConnectedDevicesLoadedState) {
  //     if (currentState.connectedDevices.isNotEmpty) {
  //       // Jika sudah ada perangkat terhubung, LANGSUNG discover services
  //       log('initState: Perangkat sudah terhubung. Memulai discover services...');
  //       context.read<DiscoverServicesCubit>().discoverServices(
  //             currentState.connectedDevices[0],
  //           );
  //     }
  //   }
  //   // --- AKHIR KODE TAMBAHAN ---
  // }

  @override
  void dispose() {
    pressureCtrl.dispose();
    damageCtrl.dispose();
    hmCtrl.dispose();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    if (_isInit) {
      dataUnit =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
      // Setelah dataUnit didapat, panggil fungsi yang membutuhkannya
      callTires();
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // dataUnit =
    //     ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

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
          child: (dataUnit['isCTS'] != null)
              ? Builder(builder: (context) {
                  if (position.isEmpty) {
                    log('Data Unit Daily Check Pressure : ${dataUnit['position']}');
                    position.addAll(dataUnit['position']);
                  }
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

                      Column(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      width: MediaQuery.of(context).size.width *
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
                                            builder: (BuildContext context) {
                                              return Dialog(
                                                child: Container(
                                                  padding: EdgeInsets.all(20.0),
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        Text(
                                                          'Choose Pressure',
                                                          style: TextStyle(
                                                            fontSize: 24.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(height: 16.0),
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
                                                                      right: 16,
                                                                      bottom:
                                                                          18),
                                                              child:
                                                                  ElevatedButton(
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.green),
                                                                onPressed: () {
                                                                  // setState(
                                                                  //     () {
                                                                  //   position[posIndex]
                                                                  //       [
                                                                  //       'pressure'] = ps;
                                                                  //   Navigator.of(context)
                                                                  //       .pop();
                                                                  // });
                                                                  setState(() {
                                                                    position[
                                                                        posIndex] = position[
                                                                            posIndex]
                                                                        .copyWith(
                                                                            pressure:
                                                                                ps);
                                                                    // input kondisi pressure
                                                                    position[
                                                                        posIndex] = position[
                                                                            posIndex]
                                                                        .copyWith(
                                                                      kondisi:
                                                                          'Normal',
                                                                    );
                                                                    Navigator.of(
                                                                            context)
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
                                                              child: SizedBox(
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
                                                                onPressed: () {
                                                                  setState(() {
                                                                    if (pressureCtrl
                                                                            .text !=
                                                                        '') {
                                                                      // position[posIndex]['pressure'] =
                                                                      //     pressureCtrl.text;
                                                                      position[
                                                                          posIndex] = position[
                                                                              posIndex]
                                                                          .copyWith(
                                                                              pressure: pressureCtrl.text);
                                                                      position[
                                                                          posIndex] = position[
                                                                              posIndex]
                                                                          .copyWith(
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
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  });
                                                                },
                                                                child: Text(
                                                                    'Submit'))
                                                          ],
                                                        ),
                                                        SizedBox(height: 12.0),
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: ElevatedButton(
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
                                        // child: (position[posIndex]
                                        //             ['pressure'] ==
                                        //         '')
                                        child: (position[posIndex].pressure ==
                                                '')
                                            ? Row(
                                                mainAxisSize: MainAxisSize.min,
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
                                                    style: getWhiteTextStyle(),
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
                                      width: MediaQuery.of(context).size.width *
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
                                            builder: (BuildContext context) {
                                              return Dialog(
                                                child: Container(
                                                  padding: EdgeInsets.all(20.0),
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        Text(
                                                          'Choose Pressure',
                                                          style: TextStyle(
                                                            fontSize: 24.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(height: 16.0),
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
                                                                      right: 16,
                                                                      bottom:
                                                                          18),
                                                              child:
                                                                  ElevatedButton(
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.green),
                                                                onPressed: () {
                                                                  setState(() {
                                                                    // position[posIndex]
                                                                    //     [
                                                                    //     'adjusmentPressure'] = ps;
                                                                    position[
                                                                        posIndex] = position[
                                                                            posIndex]
                                                                        .copyWith(
                                                                            adjusmentPressure:
                                                                                ps);
                                                                    Navigator.of(
                                                                            context)
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
                                                              child: SizedBox(
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
                                                                onPressed: () {
                                                                  setState(() {
                                                                    if (pressureCtrl
                                                                            .text !=
                                                                        '') {
                                                                      position[
                                                                          posIndex] = position[
                                                                              posIndex]
                                                                          .copyWith(
                                                                              adjusmentPressure: pressureCtrl.text);
                                                                    }
                                                                    pressureCtrl
                                                                        .clear();
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                  });
                                                                },
                                                                child: Text(
                                                                    'Submit'))
                                                          ],
                                                        ),
                                                        SizedBox(height: 12.0),
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: ElevatedButton(
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
                                      width: MediaQuery.of(context).size.width *
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
                                            builder: (BuildContext context) {
                                              return Dialog(
                                                child: Container(
                                                  padding: EdgeInsets.all(20.0),
                                                  child: SingleChildScrollView(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: <Widget>[
                                                        Text(
                                                          'Choose Rating',
                                                          style: TextStyle(
                                                            fontSize: 24.0,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(height: 16.0),
                                                        Column(),
                                                        Wrap(
                                                          children:
                                                              rating.map((rat) {
                                                            final ratingIndex =
                                                                rating.indexOf(
                                                                    rat);
                                                            return Padding(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .only(
                                                                      right: 16,
                                                                      bottom:
                                                                          18),
                                                              child:
                                                                  ElevatedButton(
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                        backgroundColor:
                                                                            Colors.green),
                                                                onPressed: () {
                                                                  setState(() {
                                                                    // position[posIndex]['rating'] =
                                                                    //     rat;
                                                                    position[
                                                                        posIndex] = position[
                                                                            posIndex]
                                                                        .copyWith(
                                                                            rating:
                                                                                rat);
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
                                                        SizedBox(height: 12.0),
                                                        SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: ElevatedButton(
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
                                        // child: (position[posIndex]
                                        //             ['rating'] ==
                                        //         '')
                                        child: (position[posIndex].rating == '')
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
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.39,
                                        // height: 65,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            FocusScope.of(context).unfocus();
                                            List<bool> checkedDamageValues =
                                                List<bool>.filled(
                                                    damageType.length, false);

                                            if (position[posIndex]
                                                .luka
                                                .isNotEmpty) {
                                              for (int i = 0;
                                                  i < damageType.length;
                                                  i++) {
                                                if (position[posIndex]
                                                    .luka
                                                    .contains(damageType[i])) {
                                                  checkedDamageValues[i] = true;
                                                }
                                              }
                                              damageCtrl
                                                  .text = position[posIndex]
                                                      .luka
                                                      .isNotEmpty
                                                  ? position[posIndex].luka[0]
                                                  : '';
                                            }

                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
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
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                        SizedBox(height: 12.0),
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
                                                                return StatefulBuilder(
                                                                    builder:
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
                                                                            value ??
                                                                                false;
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
                                                                onPressed: () {
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
                                                                onPressed: () {
                                                                  setState(
                                                                      () {});

                                                                  final List<
                                                                          String>
                                                                      tmp = [];

                                                                  // isi damage dengan ketikan
                                                                  if (damageCtrl
                                                                              .text ==
                                                                          '' ||
                                                                      damageCtrl
                                                                          .text
                                                                          .isNotEmpty) {
                                                                    tmp.add(
                                                                        damageCtrl
                                                                            .text);
                                                                  }

                                                                  for (int i =
                                                                          0;
                                                                      i <
                                                                          checkedDamageValues
                                                                              .length;
                                                                      i++) {
                                                                    if (checkedDamageValues[
                                                                        i]) {
                                                                      tmp.add(
                                                                          damageType[
                                                                              i]);
                                                                    } else {
                                                                      tmp.removeWhere((element) =>
                                                                          element ==
                                                                          damageType[
                                                                              i]);
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
                                                                        .copyWith(
                                                                            luka: []);

                                                                    position[
                                                                            posIndex]
                                                                        .luka
                                                                        .addAll(
                                                                            tmp);

                                                                    log('hasil luka ban : ${position}');
                                                                  }

                                                                  // jika hapus damage hari kemarin
                                                                  if (position[posIndex].luka[
                                                                              0] ==
                                                                          '' &&
                                                                      position[posIndex]
                                                                              .luka
                                                                              .length ==
                                                                          1) {
                                                                    position[
                                                                        posIndex] = position[
                                                                            posIndex]
                                                                        .copyWith(
                                                                            luka: []);
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
                                          child: Text(
                                            (position[posIndex].luka == null ||
                                                    position[posIndex]
                                                        .luka
                                                        .isEmpty)
                                                ? 'Damage Tire (None)'
                                                : position[posIndex]
                                                    .luka
                                                    .join('\n---\n'),
                                            textAlign: TextAlign.center,
                                            style:
                                                getWhiteTextStyle(fontSize: 14),
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
                                                                image: image);
                                                  }

                                                  log('posisi terbaru : ${position}');
                                                },
                                                style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.orange,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    )),
                                                child: Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 8.0),
                                                  child: Text(
                                                    'Take Picture',
                                                    textAlign: TextAlign.center,
                                                    style: getWhiteTextStyle(
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
                })
              : BlocConsumer<TireBloc, TireState>(
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
                          pit.add('TIA');
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
                      if (dataUnit['position'] != null) {
                        position.addAll(dataUnit['position']);
                      } else {
                        final today = DateTime.now();
                        final formattedToday =
                            '${today.month.toString().padLeft(2, '0')}' // MM
                            '${today.day.toString().padLeft(2, '0')}' // DD
                            '${(today.year % 100).toString().padLeft(2, '0')}'; // YY
                        // Memilih unit dari daily pressure list
                        // ADDITIONAL ACCESSORIES EDIT #1
                        for (var i = 0; i < state.units.length; i++) {
                          if (position.length < state.units.length) {
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
                                  tireAccessories: []),
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
                          position[i] =
                              position[i].copyWith(rating: ratings[i]);
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
                                        backgroundColor: MaterialStateProperty
                                            .resolveWith<Color>(
                                                (Set<MaterialState> states) {
                                          if (selectedType == 0) {
                                            return Colors.lightGreen;
                                          }
                                          return greyDADADA;
                                        }),
                                      ),
                                      child: Text(
                                        'PG Digital',
                                        style:
                                            getWhiteTextStyle(fontWeight: w700),
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
                                        backgroundColor: MaterialStateProperty
                                            .resolveWith<Color>(
                                                (Set<MaterialState> states) {
                                          if (selectedType == 1) {
                                            return Colors.lightGreen;
                                          }
                                          return greyDADADA;
                                        }),
                                      ),
                                      child: Text(
                                        'Manual',
                                        style:
                                            getWhiteTextStyle(fontWeight: w700),
                                      )),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          // UNIT NUMBER DAN HM UNIT
                          // EDIT INI AJA
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
                                          (idSite == bmbhauling.idSite)
                                              ? Icons.edit_road_sharp
                                              : Icons.watch,
                                          color: (idSite == bmbhauling.idSite)
                                              ? Colors.black
                                              : Colors.red,
                                          size: 38,
                                        ),
                                        const SizedBox(
                                          width: 12,
                                        ),
                                        Text(
                                          (idSite == bmbhauling.idSite)
                                              ? 'KM UNIT'
                                              : 'HM UNIT',
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
                                          hint:
                                              'Fill ${(idSite == bmbhauling.idSite) ? 'KM' : 'HM'}'),
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
                                    spacing:
                                        8.0, // Jarak horizontal antar tombol
                                    children: pit.map((e) {
                                      final pitIndex = pit.indexOf(e);
                                      return ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              (selectedPit == pitIndex)
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
                                      children: inspectRoute
                                          .asMap()
                                          .entries
                                          .map((entry) {
                                        int index = entry.key;
                                        List<int> route = entry.value;

                                        return RadioListTile<int>(
                                          title: Text(route
                                              .map((index) =>
                                                  (index + 1).toString())
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
                                    BlocBuilder<ConnectedDevicesCubit,
                                        ConnectedDevicesState>(
                                      builder: (context, cState) {
                                        // Asumsikan perangkat TPMS adalah yang terhubung jika statusnya Success
                                        final isConnected = cState
                                                is ConnectedDevicesLoadedState &&
                                            cState.connectedDevices.isNotEmpty;

                                        // Cari perangkat yang terhubung yang memiliki nama yang relevan
                                        // (Anda harus menyesuaikan logika pencarian ini sesuai nama perangkat BT Anda)
                                        final BluetoothDevice? connectedDevice =
                                            isConnected
                                                ? cState.connectedDevices
                                                    .firstWhereOrNull((d) =>
                                                        d.advName.isNotEmpty)
                                                : null;

                                        final String buttonText = isConnected
                                            ? 'Connected: ${connectedDevice?.advName ?? connectedDevice?.remoteId.str}'
                                            : 'Scan Devices';

                                        return ButtonWidget(
                                          // Warna tombol berdasarkan status koneksi
                                          color: isConnected
                                              ? green00968A
                                              : Colors.blue,
                                          name: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
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
                                          function: () async {
                                            if (isConnected) {
                                              // LOGIC DISCONNECT (JANGAN LUPA MENGIMPLEMENTASIKAN INI DI CUBIT ANDA)
                                              log('Disconnect action triggered. Implement disconnect logic in ConnectedDevicesCubit.');
                                            } else {
                                              // Navigasi ke halaman scan
                                              log('Navigating to Scan Device Page');
                                              await Navigator.of(context)
                                                  .pushNamed(
                                                      ScanDevicePage.routeName);

                                              // Setelah kembali dari halaman scan, panggil fetchConnectedDevices
                                              // untuk memperbarui UI di halaman ini
                                              // Cek apakah context masih valid sebelum memanggil Cubit
                                              if (mounted) {
                                                BlocProvider.of<
                                                            ConnectedDevicesCubit>(
                                                        context)
                                                    .fetchConnectedDevices();
                                              }
                                            }
                                          },
                                        );
                                      },
                                    ),
                                    const SizedBox(
                                      height: 12,
                                    ),
                                    // #EDIT BLUETOOTH
                                    const SizedBox(
                                      height: 24,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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
                                    BlocListener<BluetoothOnOffCubit,
                                        BluetoothOnOffState>(
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
                                          if (state
                                                  is ConnectedDevicesLoadedState &&
                                              state.connectedDevices
                                                  .isNotEmpty) {
                                            context
                                                .read<DiscoverServicesCubit>()
                                                .discoverServices(state
                                                    .connectedDevices.first);
                                          }
                                        },
                                        builder: (context, state) {
                                          if (state
                                              is ConnectedDevicesLoadedState) {
                                            // return _buildConnectedDeviceUI(
                                            //     state.connectedDevices);
                                            BlocProvider.of<
                                                DiscoverServicesCubit>(
                                              context,
                                            ).discoverServices(
                                                state.connectedDevices[0]);
                                            return BlocConsumer<
                                                DiscoverServicesCubit,
                                                DiscoverServiceState>(
                                              listener:
                                                  (context, discoverState) {
                                                if (discoverState
                                                    is ServicesLoadedState) {
                                                  final services =
                                                      discoverState.services;
                                                  log('services pgd : $services');

                                                  if (!_listenerAdded) {
                                                    _listenerAdded = true;
                                                    for (BluetoothService service
                                                        in services) {
                                                      for (BluetoothCharacteristic characteristic
                                                          in service
                                                              .characteristics) {
                                                        if (characteristic
                                                            .properties
                                                            .notify) {
                                                          characteristic
                                                              .onValueReceived
                                                              .listen((value) {
                                                            final notifInString =
                                                                String
                                                                    .fromCharCodes(
                                                                        value);
                                                            log("pengendali angin: $notifInString");

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

                                                              if (notifInString
                                                                  .contains(
                                                                      '|')) {
                                                                int floorPressure =
                                                                    double
                                                                        .parse(
                                                                  notifInString
                                                                      .split(
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
                                                                    floorPressure
                                                                        .toString());
                                                              } else {
                                                                int floorPressure =
                                                                    double
                                                                        .parse(
                                                                  notifInString,
                                                                ).floor();
                                                                press
                                                                    .toString();
                                                                applyPressureData(
                                                                    floorPressure
                                                                        .toString());
                                                              }
                                                            });

                                                            debugPrint(
                                                              "debugBluetoothNotification*************",
                                                            );
                                                          });

                                                          characteristic
                                                              .setNotifyValue(
                                                                  true); // WAJIB
                                                        }
                                                      }
                                                    }
                                                  }
                                                }
                                              },
                                              builder:
                                                  (context, discoverState) {
                                                if (discoverState
                                                    is ErrorLoadingServiceState) {
                                                  return Center(
                                                      child: Text('Error'));
                                                }
                                                return Container();
                                              },
                                            );
                                          }
                                          return CircularProgressIndicator();
                                        },
                                      ),
                                    ),

                                    // BlocBuilder<BluetoothOnOffCubit,
                                    //     BluetoothOnOffState>(
                                    //   builder: (context, onOffState) {
                                    //     log('bluetooth is on state : ${onOffState is BluetoothOnState}');
                                    //     log('bluetooth is off state : ${onOffState is BluetoothOffState}');

                                    //     if (onOffState is BluetoothOnState) {
                                    //       return BlocConsumer<
                                    //           ConnectedDevicesCubit,
                                    //           connectedDevicesState
                                    //           .ConnectedDevicesState>(
                                    //         listener: (context, state) {
                                    //           if (state is connectedDevicesState
                                    //               .ConnectedDevicesLoadedState) {
                                    //             if (state.connectedDevices
                                    //                 .isNotEmpty) {
                                    //               BlocProvider.of<
                                    //                   DiscoverServicesCubit>(
                                    //                 context,
                                    //               ).discoverServices(state
                                    //                   .connectedDevices[0]);
                                    //             }
                                    //           }
                                    //         },
                                    //         builder: (context, state) {
                                    //           if (state is connectedDevicesState
                                    //               .ConnectedDevicesLoadedState) {
                                    //             return Column(
                                    //               children: [
                                    //                 ListOfConnectedDevicesWidget(
                                    //                   connectedDevices: state
                                    //                       .connectedDevices,
                                    //                 ),
                                    //                 BlocConsumer<
                                    //                     DiscoverServicesCubit,
                                    //                     DiscoverServiceState>(
                                    //                   listener: (context,
                                    //                       discoverState) {
                                    //                     if (discoverState
                                    //                         is ServicesLoadedState) {
                                    //                       final services =
                                    //                           discoverState
                                    //                               .services;
                                    //                       log('services pgd : $services');

                                    //                       for (BluetoothService service
                                    //                           in services) {
                                    //                         for (BluetoothCharacteristic characteristic
                                    //                             in service
                                    //                                 .characteristics) {
                                    //                           characteristic
                                    //                               .lastValueStream
                                    //                               .listen((
                                    //                             event,
                                    //                           ) {
                                    //                             String
                                    //                                 notifInString =
                                    //                                 String.fromCharCodes(
                                    //                                     event);
                                    //                             debugPrint(
                                    //                               "debugBluetoothNotification*************",
                                    //                             );
                                    //                             debugPrint(
                                    //                               "debugBluetoothNotification: charName: ${BluetoothUtils.getBluetoothChar(characteristic.characteristicUuid.str)}",
                                    //                             );

                                    //                             debugPrint(
                                    //                               "notifhohoho: stringNotif: $notifInString",
                                    //                             );
                                    //                             setState(() {
                                    //                               String press =
                                    //                                   '';

                                    //                               if (notifInString
                                    //                                   .contains(
                                    //                                       '|')) {
                                    //                                 int floorPressure =
                                    //                                     double
                                    //                                         .parse(
                                    //                                   notifInString
                                    //                                       .split(
                                    //                                     '|',
                                    //                                   )[0],
                                    //                                 ).floor();

                                    //                                 // int floorTemperature =
                                    //                                 //     double.parse(
                                    //                                 //       notifInString.split(
                                    //                                 //         '|',
                                    //                                 //       )[1],
                                    //                                 //     ).floor();
                                    //                                 // temperature = floorTemperature
                                    //                                 //     .toString();
                                    //                                 applyPressureData(
                                    //                                     floorPressure
                                    //                                         .toString());
                                    //                               } else {
                                    //                                 int floorPressure =
                                    //                                     double
                                    //                                         .parse(
                                    //                                   notifInString,
                                    //                                 ).floor();
                                    //                                 press
                                    //                                     .toString();
                                    //                                 applyPressureData(
                                    //                                     floorPressure
                                    //                                         .toString());
                                    //                               }
                                    //                             });

                                    //                             debugPrint(
                                    //                               "debugBluetoothNotification*************",
                                    //                             );
                                    //                           });
                                    //                         }
                                    //                       }
                                    //                     }
                                    //                   },
                                    //                   builder: (context,
                                    //                       discoverState) {
                                    //                     if (discoverState
                                    //                         is ErrorLoadingServiceState) {
                                    //                       return Center(
                                    //                           child: Text(
                                    //                               'Error'));
                                    //                     }
                                    //                     return Container();
                                    //                   },
                                    //                 ),
                                    //               ],
                                    //             );
                                    //           } else if (state
                                    //               is connectedDevicesState
                                    //               .LoadingState) {
                                    //             return const Center(
                                    //               child:
                                    //                   CircularProgressIndicator(),
                                    //             );
                                    //           }
                                    //           return const SizedBox();
                                    //         },
                                    //       );
                                    //     } else if (onOffState
                                    //         is BluetoothOffState) {
                                    //       return const Center(
                                    //         child:
                                    //             Text("Bluetooth is turned off"),
                                    //       );
                                    //     } else if (onOffState
                                    //         is BluetoothNotSupportedState) {
                                    //       return Center(
                                    //           child: Text(
                                    //               onOffState.failData.msg));
                                    //     }
                                    //     return const Center(
                                    //         child: CircularProgressIndicator());
                                    //   },
                                    // ),
                                    Column(
                                        children: position.map((pos) {
                                      final posIndex = position.indexOf(pos);
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
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
                                                        BorderRadius.circular(
                                                            12),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
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

                                    LayoutBuilder(
                                        builder: (context, constraints) {
                                      // spacing antar item
                                      const spacing = 34.0;
                                      // jumlah kolom tetap 2
                                      const crossAxisCount = 2;

                                      // hitung lebar setiap item agar pas dua kolom + jarak antar kolom
                                      double itemWidth = (constraints.maxWidth -
                                              ((crossAxisCount - 1) *
                                                  spacing)) /
                                          crossAxisCount;
                                      return Wrap(
                                        spacing: 34,
                                        runSpacing: 24,
                                        alignment: WrapAlignment.center,
                                        children: position.map((pos) {
                                          final posIndex =
                                              position.indexOf(pos);
                                          return Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // POSITION
                                              Text(
                                                'Pos. ${posIndex + 1}',
                                                style: getBlackTextStyle(
                                                    fontSize: 16,
                                                    fontWeight: w700),
                                              ),
                                              const SizedBox(
                                                height: 6,
                                              ),
                                              SizedBox(
                                                width: itemWidth,
                                                height: 45,
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    setState(() {
                                                      selectedPosIndex =
                                                          posIndex;
                                                    });
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
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
                                                                        pressure
                                                                            .map((ps) {
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
                                                                          style:
                                                                              ElevatedButton.styleFrom(backgroundColor: Colors.green),
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
                                                                            setState(() {
                                                                              position[posIndex] = position[posIndex].copyWith(pressure: ps);
                                                                              // input kondisi pressure
                                                                              position[posIndex] = position[posIndex].copyWith(
                                                                                kondisi: int.parse(((dataUnit['reccPress'] as List<Map<String, dynamic>>).firstWhere(
                                                                                          (element) => element.containsKey(position[posIndex].size),
                                                                                          orElse: () => <String, dynamic>{},
                                                                                        )[position[posIndex].size])) <
                                                                                        int.parse(ps)
                                                                                    ? 'Normal'
                                                                                    : 'Low Pressure',
                                                                              );
                                                                              Navigator.of(context).pop();
                                                                            });
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            ps,
                                                                            style:
                                                                                getWhiteTextStyle(
                                                                              fontWeight: w700,
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
                                                                          width:
                                                                              double.infinity,
                                                                          child: InputFormWidget(
                                                                              controller: pressureCtrl,
                                                                              isDigitOnly: true,
                                                                              type: TextInputType.number,
                                                                              hint: 'Input Manual'),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            6,
                                                                      ),
                                                                      ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              if (pressureCtrl.text != '') {
                                                                                // position[posIndex]['pressure'] =
                                                                                //     pressureCtrl.text;
                                                                                position[posIndex] = position[posIndex].copyWith(pressure: pressureCtrl.text);
                                                                                position[posIndex] = position[posIndex].copyWith(
                                                                                  kondisi: int.parse(((dataUnit['reccPress'] as List<Map<String, dynamic>>).firstWhere(
                                                                                            (element) => element.containsKey(position[posIndex].size),
                                                                                            orElse: () => <String, dynamic>{},
                                                                                          )[position[posIndex].size])) <
                                                                                          int.parse(pressureCtrl.text)
                                                                                      ? 'Normal'
                                                                                      : 'Low Pressure',
                                                                                );
                                                                              }
                                                                              pressureCtrl.clear();
                                                                              Navigator.of(context).pop();
                                                                            });
                                                                          },
                                                                          child:
                                                                              Text('Submit'))
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
                                                                        Navigator.of(context)
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
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
                                                          style:
                                                              getWhiteTextStyle(
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
                                                width: itemWidth,
                                                height: 45,
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    setState(() {
                                                      selectedPosIndex =
                                                          posIndex;
                                                    });
                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
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
                                                                        pressure
                                                                            .map((ps) {
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
                                                                          style:
                                                                              ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              // position[posIndex]
                                                                              //     [
                                                                              //     'adjusmentPressure'] = ps;
                                                                              position[posIndex] = position[posIndex].copyWith(adjusmentPressure: ps);
                                                                              Navigator.of(context).pop();
                                                                            });
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            ps,
                                                                            style:
                                                                                getWhiteTextStyle(
                                                                              fontWeight: w700,
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
                                                                          width:
                                                                              double.infinity,
                                                                          child: InputFormWidget(
                                                                              controller: pressureCtrl,
                                                                              isDigitOnly: true,
                                                                              type: TextInputType.number,
                                                                              hint: 'Input Manual'),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        width:
                                                                            6,
                                                                      ),
                                                                      ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              if (pressureCtrl.text != '') {
                                                                                // position[posIndex]['adjusmentPressure'] =
                                                                                //     pressureCtrl.text;
                                                                                position[posIndex] = position[posIndex].copyWith(adjusmentPressure: pressureCtrl.text);
                                                                              }
                                                                              pressureCtrl.clear();
                                                                              Navigator.of(context).pop();
                                                                            });
                                                                          },
                                                                          child:
                                                                              Text('Submit'))
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
                                                                        Navigator.of(context)
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          )),
                                                  // child: (position[posIndex]
                                                  //             ['adjusmentPressure'] ==
                                                  //         '')
                                                  child: (position[posIndex]
                                                              .adjusmentPressure ==
                                                          '')
                                                      ? Text(
                                                          'Adj Pressure',
                                                          style:
                                                              getWhiteTextStyle(),
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
                                                          style:
                                                              getWhiteTextStyle(
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
                                                width: itemWidth,
                                                height: 45,
                                                child: ElevatedButton(
                                                  onPressed: () async {
                                                    FocusScope.of(context)
                                                        .unfocus();
                                                    setState(() {
                                                      selectedPosIndex =
                                                          posIndex;
                                                    });

                                                    showDialog(
                                                      context: context,
                                                      builder: (BuildContext
                                                          context) {
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
                                                                    'Choose Rating',
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
                                                                        rating.map(
                                                                            (rat) {
                                                                      final ratingIndex =
                                                                          rating
                                                                              .indexOf(rat);
                                                                      return Padding(
                                                                        padding: const EdgeInsets
                                                                            .only(
                                                                            right:
                                                                                16,
                                                                            bottom:
                                                                                18),
                                                                        child:
                                                                            ElevatedButton(
                                                                          style:
                                                                              ElevatedButton.styleFrom(backgroundColor: Colors.green),
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {
                                                                              // position[posIndex]['rating'] =
                                                                              //     rat;
                                                                              position[posIndex] = position[posIndex].copyWith(rating: rat);
                                                                              Navigator.of(context).pop();
                                                                            });
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            rat,
                                                                            style:
                                                                                getWhiteTextStyle(
                                                                              fontWeight: w700,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }).toList(),
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
                                                                        Navigator.of(context)
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
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor:
                                                              Colors.blue,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12),
                                                          )),
                                                  child: (position[posIndex]
                                                              .rating ==
                                                          '')
                                                      ? Text(
                                                          'Rating',
                                                          style:
                                                              getWhiteTextStyle(),
                                                        )
                                                      : Text(
                                                          'Rating ${position[posIndex].rating}',
                                                          style:
                                                              getWhiteTextStyle(
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
                                                  width: itemWidth,
                                                  // height: 65,
                                                  child: ElevatedButton(
                                                    onPressed: () {
                                                      FocusScope.of(context)
                                                          .unfocus();
                                                      List<bool>
                                                          checkedDamageValues =
                                                          List<bool>.filled(
                                                              damageType.length,
                                                              false);

                                                      if (position[posIndex]
                                                          .luka
                                                          .isNotEmpty) {
                                                        for (int i = 0;
                                                            i <
                                                                damageType
                                                                    .length;
                                                            i++) {
                                                          if (position[posIndex]
                                                              .luka
                                                              .contains(
                                                                  damageType[
                                                                      i])) {
                                                            checkedDamageValues[
                                                                i] = true;
                                                          }
                                                        }
                                                        damageCtrl
                                                            .text = position[
                                                                    posIndex]
                                                                .luka
                                                                .isNotEmpty
                                                            ? position[posIndex]
                                                                .luka[0]
                                                            : '';
                                                      }

                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return Dialog(
                                                            child: Container(
                                                              padding:
                                                                  EdgeInsets
                                                                      .all(
                                                                          20.0),
                                                              child: Column(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .min,
                                                                children: <Widget>[
                                                                  Text(
                                                                    'Choose Damage Tire',
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
                                                                          12.0),
                                                                  Expanded(
                                                                    child:
                                                                        SingleChildScrollView(
                                                                      child:
                                                                          Column(
                                                                        children:
                                                                            damageType.map((damage) {
                                                                          final dmgIndex =
                                                                              damageType.indexOf(damage);
                                                                          return StatefulBuilder(builder:
                                                                              (context, setState) {
                                                                            return CheckboxListTile(
                                                                              title: Text(damage),
                                                                              value: checkedDamageValues[dmgIndex],
                                                                              onChanged: (bool? value) {
                                                                                setState(() {
                                                                                  checkedDamageValues[dmgIndex] = value ?? false;
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
                                                                        height:
                                                                            42,
                                                                        width: double
                                                                            .infinity,
                                                                        child: InputFormWidget(
                                                                            controller:
                                                                                damageCtrl,
                                                                            hint:
                                                                                'Input Manual Here....'),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            12,
                                                                      ),
                                                                      SizedBox(
                                                                        width: double
                                                                            .infinity,
                                                                        child:
                                                                            ElevatedButton(
                                                                          onPressed:
                                                                              () {
                                                                            damageCtrl.clear();
                                                                            Navigator.pop(context);
                                                                          },
                                                                          child:
                                                                              Text('Close'),
                                                                        ),
                                                                      ),
                                                                      const SizedBox(
                                                                        height:
                                                                            12,
                                                                      ),
                                                                      SizedBox(
                                                                        width: double
                                                                            .infinity,
                                                                        child:
                                                                            ElevatedButton(
                                                                          style:
                                                                              ElevatedButton.styleFrom(
                                                                            backgroundColor:
                                                                                Colors.green,
                                                                          ),
                                                                          onPressed:
                                                                              () {
                                                                            setState(() {});

                                                                            final List<String>
                                                                                tmp =
                                                                                [];

                                                                            // isi damage dengan ketikan
                                                                            if (damageCtrl.text == '' ||
                                                                                damageCtrl.text.isNotEmpty) {
                                                                              tmp.add(damageCtrl.text);
                                                                            }

                                                                            for (int i = 0;
                                                                                i < checkedDamageValues.length;
                                                                                i++) {
                                                                              if (checkedDamageValues[i]) {
                                                                                tmp.add(damageType[i]);
                                                                              } else {
                                                                                tmp.removeWhere((element) => element == damageType[i]);
                                                                              }
                                                                            }
                                                                            log('idx luka ban : $posIndex');

                                                                            if (tmp.isNotEmpty) {
                                                                              // position[posIndex]
                                                                              //     [
                                                                              //     'damage'] = [];
                                                                              position[posIndex] = position[posIndex].copyWith(luka: []);

                                                                              position[posIndex].luka.addAll(tmp);

                                                                              log('hasil luka ban : ${position}');
                                                                            }

                                                                            // jika hapus damage hari kemarin
                                                                            if (position[posIndex].luka[0] == '' &&
                                                                                position[posIndex].luka.length == 1) {
                                                                              position[posIndex] = position[posIndex].copyWith(luka: []);
                                                                            }

                                                                            damageCtrl.clear();

                                                                            Navigator.pop(context);
                                                                          },
                                                                          child:
                                                                              Text(
                                                                            'Submit',
                                                                            style:
                                                                                getWhiteTextStyle(
                                                                              fontWeight: w700,
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
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                            backgroundColor:
                                                                blue344BEF,
                                                            shape:
                                                                RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12),
                                                            )),
                                                    child: Text(
                                                      (position[posIndex]
                                                                      .luka ==
                                                                  null ||
                                                              position[posIndex]
                                                                  .luka
                                                                  .isEmpty)
                                                          ? 'Damage Tire (None)'
                                                          : position[posIndex]
                                                              .luka
                                                              .join('\n---\n'),
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: getWhiteTextStyle(
                                                          fontSize: 14),
                                                    ),
                                                  )),

                                              // Memilih Tire Accessories
                                              // ADDITIONAL TIRE ACCESSORIES EDIT #2
                                              // Jangan lupa tambahkan if id site 33 (CK-KIM)
                                              if (idSite == '33')
                                                Container(
                                                  margin: const EdgeInsets.only(
                                                      top: 8),
                                                  width: itemWidth,
                                                  child: ElevatedButton(
                                                    onPressed: () async {
                                                      FocusScope.of(context)
                                                          .unfocus();

                                                      // Ambil data dari posisi
                                                      List<TireAccessory>
                                                          componentStatus =
                                                          position[posIndex]
                                                              .tireAccessories;

                                                      final result =
                                                          await showDialog<
                                                              List<
                                                                  TireAccessory>>(
                                                        context: context,
                                                        builder: (context) =>
                                                            TireComponentDialog(
                                                          initialData:
                                                              componentStatus,
                                                        ),
                                                      );

                                                      if (result != null) {
                                                        // Simpan hasil (hanya yang rusak/hilang)
                                                        // final filtered = result
                                                        //     .where((e) =>
                                                        //         e.condition !=
                                                        //         'Normal')
                                                        //     .toList();

                                                        setState(() {
                                                          position[
                                                              posIndex] = position[
                                                                  posIndex]
                                                              .copyWith(
                                                                  tireAccessories:
                                                                      result);
                                                        });
                                                        log('TIRE ACCESSORIES SELECTED : $result');
                                                        log('POSITION AFTER TIRE ACC: $position');
                                                      }
                                                    },
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          blue344BEF,
                                                      shape:
                                                          RoundedRectangleBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          12)),
                                                    ),
                                                    child: Builder(
                                                      builder: (context) {
                                                        final accs = position[
                                                                posIndex]
                                                            .tireAccessories;

                                                        if (accs.isEmpty) {
                                                          return Text(
                                                            'Tire Accessories (None)',
                                                            textAlign: TextAlign
                                                                .center,
                                                            style:
                                                                getWhiteTextStyle(
                                                                    fontSize:
                                                                        14),
                                                          );
                                                        }

                                                        // Gabungkan nama + kondisi
                                                        final names = accs
                                                            .map((e) =>
                                                                '${e.name} (${e.condition})')
                                                            .join('\n');

                                                        return Text(
                                                          'Tire Accessories:\n $names',
                                                          textAlign:
                                                              TextAlign.center,
                                                          softWrap: true,
                                                          style:
                                                              getWhiteTextStyle(
                                                                  fontSize: 10),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),

                                              const SizedBox(
                                                height: 12,
                                              ),
                                              // IMAGE DAILY CHECK
                                              (dataUnit['type'] != null)
                                                  ? SizedBox(
                                                      width: itemWidth,
                                                      child: ElevatedButton(
                                                          onPressed: () async {
                                                            final image =
                                                                await showImageSourceDialog(
                                                                    context,
                                                                    position[
                                                                            posIndex]
                                                                        .image,
                                                                    posIndex);
                                                            if (image != '') {
                                                              position[
                                                                  posIndex] = position[
                                                                      posIndex]
                                                                  .copyWith(
                                                                      image:
                                                                          image);
                                                            }

                                                            log('posisi terbaru : ${position}');
                                                          },
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .orange,
                                                                  shape:
                                                                      RoundedRectangleBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            12),
                                                                  )),
                                                          child: Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    vertical:
                                                                        8.0),
                                                            child: Text(
                                                              'Take Picture',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style:
                                                                  getWhiteTextStyle(
                                                                      fontSize:
                                                                          14),
                                                            ),
                                                          )),
                                                    )
                                                  : SizedBox(),
                                            ],
                                          );
                                        }).toList(),
                                      );
                                    }),
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
              DateTime? selectedDateTimeSPM = DateTime.now();

              // POP UP input time event low pressure (hanya adjustment tapping spm)
              if (dataUnit['type'] == 'spm') {
                bool adjustmentEmpty = position.any((item) =>
                    item.adjusmentPressure != null &&
                    item.adjusmentPressure.toString().trim().isNotEmpty);

                if (!adjustmentEmpty) {
                  print('data adjust kosong');
                  return;
                }

                print('POP UP MUNCUL!');

                selectedDateTimeSPM = await showDialog<DateTime>(
                  context: context,
                  barrierDismissible: true,
                  builder: (BuildContext context) {
                    DateTime tempDate =
                        DateTime.now(); // waktu sementara di dalam dialog

                    return StatefulBuilder(
                      builder: (context, setStateBtn) {
                        return AlertDialog(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.battery_alert,
                                      color: Colors.black),
                                  const SizedBox(width: 12),
                                  Text('Event Low Pressure Time',
                                      style: getBlackTextStyle(
                                          fontSize: 18, fontWeight: w700)),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Silahkan pilih tanggal dan waktu terjadinya event notifikasi low tire pressure :',
                                style: getBlackTextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 32),
                              Text('Pilih tanggal',
                                  style: getBlackTextStyle(fontSize: 14)),
                              ElevatedButton(
                                onPressed: () async {
                                  final DateTime? pickedDate =
                                      await showDatePicker(
                                    context: context,
                                    initialDate: tempDate,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                  );
                                  if (pickedDate != null) {
                                    tempDate = DateTime(
                                      pickedDate.year,
                                      pickedDate.month,
                                      pickedDate.day,
                                      tempDate.hour,
                                      tempDate.minute,
                                    );
                                    setStateBtn(() {});
                                  }
                                },
                                child: Text(
                                    DateFormat('dd MMM yyyy').format(tempDate)),
                              ),
                              const SizedBox(height: 16),
                              Text('Pilih jam dan menit',
                                  style: getBlackTextStyle(fontSize: 14)),
                              ElevatedButton(
                                onPressed: () async {
                                  final TimeOfDay? pickedTime =
                                      await showTimePicker(
                                    context: context,
                                    initialTime:
                                        TimeOfDay.fromDateTime(tempDate),
                                  );
                                  if (pickedTime != null) {
                                    tempDate = DateTime(
                                      tempDate.year,
                                      tempDate.month,
                                      tempDate.day,
                                      pickedTime.hour,
                                      pickedTime.minute,
                                    );
                                    setStateBtn(() {});
                                  }
                                },
                                child:
                                    Text(DateFormat('HH:mm').format(tempDate)),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context,
                                      tempDate); // ⬅️ kirim balik waktu
                                },
                                child: Text('Save', style: getWhiteTextStyle()),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              }

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
                  idSite == bibkgb.idSite ||
                  idSite == bibgh.idSite) {
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

              try {
                final today = DateTime.now();
                final startOfDay = DateTime(today.year, today.month, today.day);
                final endOfDay =
                    DateTime(today.year, today.month, today.day, 23, 59, 59);

                final listImage = await uploadImageFirebase(idSite);
                await uploadAllTireAccessories();

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
                        'tireAccessories':
                            p.tireAccessories.map((a) => a.toMap()).toList(),
                      };
                    }),
                    'pit': (selectedPit == -1) ? 'Default' : pit[selectedPit],
                    'timeLowPressureSPM': (dataUnit['type'] == 'spm')
                        ? selectedDateTimeSPM?.toIso8601String()
                        : '',
                  });
                } else {
                  // tambah data kemarin (khusus site CK-BIB)
                  if (idSite == bibkgb.idSite || idSite == bibgh.idSite) {
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
                            'tireAccessories': p.tireAccessories
                                .map((a) => a.toMap())
                                .toList(),
                          };
                        }),
                        'pit':
                            (selectedPit == -1) ? 'Default' : pit[selectedPit],
                        'timeLowPressureSPM': (dataUnit['type'] == 'spm')
                            ? selectedDateTimeSPM?.toIso8601String()
                            : '',
                      });
                    }
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
                        'tireAccessories':
                            p.tireAccessories.map((a) => a.toMap()).toList(),
                      };
                    }),
                    'pit': (selectedPit == -1) ? 'Default' : pit[selectedPit],
                    'timeLowPressureSPM': (dataUnit['type'] == 'spm')
                        ? selectedDateTimeSPM?.toIso8601String()
                        : '',
                  });

                  // tambah data ke daily check 3

                  // updateDailyPressure3(dataUnit, idSite);
                }
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: green00968A,
                    content: Text(
                      'Data Succesfully Added',
                      style: getWhiteTextStyle(),
                    )));
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

  Future<void> updateDailyPressure3(
      Map<String, dynamic> dataUnit, String idSite) async {
    final monthNow = DateFormat('yyyy-MM').format(DateTime.now());

    String idDailyUnit = '${dataUnit['unitNumber']}${idSite}${monthNow}';

    DocumentReference docRef =
        firestore.collection('daily_pressure_3').doc(idDailyUnit);

    // Ambil data saat ini
    DocumentSnapshot docSnap = await docRef.get();

    if (docSnap.exists) {
      Map<String, dynamic> docData = docSnap.data() as Map<String, dynamic>;

      List<dynamic> dataArray = docData['data'] ?? [];

      // Cek apakah id_daily_unit sudah ada di array
      bool isUpdated = false;

      for (var item in dataArray) {
        if (item['id_daily_unit'] == idDailyUnit) {
          item['qty'] = (item['qty'] ?? 0) + 1; // Increment qty
          isUpdated = true;
          break;
        }
      }

      if (isUpdated) {
        // Jika sudah ada, update seluruh array
        await docRef.update({'data': dataArray});
      } else {
        // Jika belum ada, tambahkan ke array
        await docRef.update({
          'data': FieldValue.arrayUnion([
            {
              'id_daily_unit': idDailyUnit,
              'unit': dataUnit['unitNumber'],
              'date': monthNow,
              'qty': 1, // Set qty awal ke 1
              'site': idSite,
            }
          ])
        });
      }
    } else {
      // Jika dokumen belum ada, buat dokumen baru
      await docRef.set({
        'idSite': idSite,
        'tanggal': monthNow,
        'data': [
          {
            'id_daily_unit': idDailyUnit,
            'unit': dataUnit['unitNumber'],
            'date': monthNow,
            'qty': 1,
            'site': idSite,
          }
        ],
      });
    }
  }
}

// ADDITIONAL ACCESORIES TIRE EDIT #3

class TireComponentDialog extends StatefulWidget {
  final List<TireAccessory> initialData;
  final String image;

  const TireComponentDialog(
      {super.key, required this.initialData, this.image = ''});

  @override
  State<TireComponentDialog> createState() => _TireComponentDialogState();
}

class _TireComponentDialogState extends State<TireComponentDialog> {
  final List<String> components = [
    'Reseal Oring',
    'Rim Condition',
    'Nut',
  ];
  final ImagePicker _picker = ImagePicker();

  late List<TireAccessory> accessories;

  @override
  void initState() {
    super.initState();
    if (BlocProvider.of<BluetoothOnOffCubit>(context).state
        is BluetoothOnState) {
      BlocProvider.of<ConnectedDevicesCubit>(context).fetchConnectedDevices();
    }
    // Ambil data dari initialData, lalu pastikan semua komponen ada
    final Map<String, TireAccessory> existing = {
      for (var acc in widget.initialData) acc.name: acc,
    };

    accessories = components.map((name) {
      return existing[name] ??
          TireAccessory(
            name: name,
            condition: name == 'Reseal Oring' ? 'Tidak' : 'Normal',
            remark: '',
            image: '', // foto dummy
          );
    }).toList();
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

  Future<String> showImageSourceDialog() async {
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
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tire Component Check',
              style:
                  getBlackTextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: accessories.length,
                itemBuilder: (context, index) {
                  final acc = accessories[index];
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            acc.name,
                            style: getBlackTextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (acc.name == 'Reseal Oring') ...[
                                ChoiceChip(
                                  label: Text(
                                    'Ya',
                                    style: getBlackTextStyle(),
                                  ),
                                  selected: acc.condition == 'Ya',
                                  selectedColor: Colors.green.shade300,
                                  onSelected: (selected) {
                                    setState(() {
                                      accessories[index] = acc.copyWith(
                                        condition: selected ? 'Ya' : 'Tidak',
                                      );
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(
                                    'Tidak',
                                    style: getBlackTextStyle(),
                                  ),
                                  selected: acc.condition == 'Tidak',
                                  selectedColor: Colors.red.shade300,
                                  onSelected: (selected) {
                                    setState(() {
                                      accessories[index] = acc.copyWith(
                                        condition: selected ? 'Tidak' : 'Ya',
                                      );
                                    });
                                  },
                                ),
                              ] else if (acc.name == 'Rim Condition') ...[
                                ChoiceChip(
                                  label: Text(
                                    'Normal',
                                    style: getBlackTextStyle(),
                                  ),
                                  selected: acc.condition == 'Normal',
                                  selectedColor: Colors.green.shade300,
                                  onSelected: (selected) {
                                    setState(() {
                                      accessories[index] = acc.copyWith(
                                        condition: selected ? 'Normal' : '',
                                      );
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(
                                    'Rusak',
                                    style: getBlackTextStyle(),
                                  ),
                                  selected: acc.condition == 'Rusak',
                                  selectedColor: Colors.orange.shade300,
                                  onSelected: (selected) {
                                    setState(() {
                                      accessories[index] = acc.copyWith(
                                        condition:
                                            selected ? 'Rusak' : 'Normal',
                                      );
                                    });
                                  },
                                ),
                              ] else ...[
                                ChoiceChip(
                                  label: Text(
                                    'Normal',
                                    style: getBlackTextStyle(),
                                  ),
                                  selected: acc.condition == 'Normal',
                                  selectedColor: Colors.green.shade300,
                                  onSelected: (selected) {
                                    setState(() {
                                      accessories[index] = acc.copyWith(
                                        condition: selected ? 'Normal' : '',
                                      );
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(
                                    'Rusak',
                                    style: getBlackTextStyle(),
                                  ),
                                  selected: acc.condition == 'Rusak',
                                  selectedColor: Colors.orange.shade300,
                                  onSelected: (selected) {
                                    setState(() {
                                      accessories[index] = acc.copyWith(
                                        condition:
                                            selected ? 'Rusak' : 'Normal',
                                      );
                                    });
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(
                                    'Hilang',
                                    style: getBlackTextStyle(),
                                  ),
                                  selected: acc.condition == 'Hilang',
                                  selectedColor: Colors.red.shade300,
                                  onSelected: (selected) {
                                    setState(() {
                                      accessories[index] = acc.copyWith(
                                        condition:
                                            selected ? 'Hilang' : 'Normal',
                                      );
                                    });
                                  },
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: acc.remark,
                            onChanged: (val) {
                              accessories[index] = acc.copyWith(remark: val);
                            },
                            decoration: const InputDecoration(
                              labelText: 'Keterangan (opsional)',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(
                            height: 6,
                          ),
                          if (acc.image.isNotEmpty && acc.image != 'image.png')
                            Padding(
                              padding:
                                  const EdgeInsets.only(top: 8.0, bottom: 8.0),
                              child: SizedBox(
                                width: double.infinity,
                                height: 150,
                                child: Image.file(
                                  File(acc.image),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ButtonWidget(
                              color: Colors.orange,
                              name: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    LucideIcons.camera,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(
                                    width: 6,
                                  ),
                                  Text(
                                    'Take Picture',
                                    style: getWhiteTextStyle(),
                                  ),
                                ],
                              ),
                              function: () async {
                                final imagePath = await showImageSourceDialog();
                                if (imagePath.isNotEmpty) {
                                  setState(() {
                                    accessories[index] =
                                        acc.copyWith(image: imagePath);
                                  });
                                }
                              }),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                    child: Text(
                      'Close',
                      style: getWhiteTextStyle(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context, accessories);
                    },
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text(
                      'Submit',
                      style: getWhiteTextStyle(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
