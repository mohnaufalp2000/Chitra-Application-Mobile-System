import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import '../../../core/services/api_service.dart';
import '../../../core/services/shared_preferences/shared_preferences.dart';
import '../../../core/styles/asset_path.dart';
import '../../../core/styles/color.dart';
import '../../../core/styles/text_manager.dart';
import '../../../core/utils/firebase_key/firebase_key.dart';
import '../../../core/utils/functions/functions.dart';
import '../../../core/widgets/text_button_widget.dart';
import 'tire_repair_inspection_page.dart';
import '../tire_repair_inspection_old/tire_repair_inspection_old_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class TireRepairInspectionFormPage extends StatefulWidget {
  static const routeName = '/tire-repair-inspection-form-page';
  const TireRepairInspectionFormPage({super.key});

  @override
  State<TireRepairInspectionFormPage> createState() =>
      _TireRepairInspectionFormPageState();
}

class _TireRepairInspectionFormPageState
    extends State<TireRepairInspectionFormPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  String _selectedButton = '';
  String selectedConstructionType = 'RADIAL';

  String? id = '';

  DateTime? selectedDate;
  DateTime? selectedReceivedDate;

  bool isShowMore = false;

  TextEditingController customerCtrl = TextEditingController(text: '');
  TextEditingController siteCtrl = TextEditingController(text: '');
  TextEditingController reportNameCtrl = TextEditingController(text: '');
  TextEditingController tireSizeCtrl = TextEditingController(text: '27.00R49');
  TextEditingController serialNumberCtrl = TextEditingController(text: '');
  TextEditingController brandCtrl = TextEditingController(text: '');
  TextEditingController typeConstCtrl = TextEditingController(text: '');
  TextEditingController patternCtrl = TextEditingController(text: '');
  TextEditingController noCM = TextEditingController(text: '');
  TextEditingController statusCtrl = TextEditingController(text: 'REPAIR');
  TextEditingController repairLocationCtrl = TextEditingController(text: '');
  TextEditingController cargoManifestCtrl = TextEditingController(text: '');
  TextEditingController rtd1Ctrl = TextEditingController(text: '');
  TextEditingController rtd2Ctrl = TextEditingController(text: '');
  TextEditingController remarksCtrl = TextEditingController(text: '');
  TextEditingController newLocationCtrl = TextEditingController();

  List<String> serialNumberPict = [];
  List<String> sidewallPic = [];
  List<String> shoulderPic = [];
  List<String> threatPic = [];
  List<String> beadPic = [];
  List<String> innerLinerPic = [];
  List<String> chafferPic = [];

  List<String> serialNumberPictFirebase = [];
  List<String> sidewallPicFirebase = [];
  List<String> shoulderPicFirebase = [];
  List<String> threatPicFirebase = [];
  List<String> beadPicFirebase = [];
  List<String> innerLinerPicFirebase = [];
  List<String> chafferPicFirebase = [];

  List<String> listStatus = ['REPAIR', 'RETREAD', 'REJECT'];

  final Map<String, String> buttonLabels = {
    'R1': '*Max 4 days',
    'R2': '*Max 8 days',
    'R3': '*Max 12 days',
    'R4': '*Max 18 days',
  };

  String selectedSize = '27.00R49';
  String selectedStatus = 'REPAIR';
  String? selectedRepairLocation;
  String? selectedCustomer;
  String idSite = '';
  Map<String, dynamic> user = {};

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (type == 'inspect')
          ? selectedDate
          : selectedReceivedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (type == 'inspect') {
      if (picked != null && picked != selectedDate) {
        setState(() {
          selectedDate = picked;
          log('tanggal sekarang : $selectedDate');
        });
      }
    } else {
      if (picked != null && picked != selectedReceivedDate) {
        setState(() {
          selectedReceivedDate = picked;
          log('tanggal sekarang : $selectedDate');
        });
      }
    }
  }

  Future<void> uploadImage() async {
    if (serialNumberPict.isNotEmpty) {
      for (int i = 0; i < serialNumberPict.length; i++) {
        if (!serialNumberPict[i].startsWith('http')) {
          final ref = storage.ref().child(
              'tire_repair/${DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}-sn');
          final uploadTask = ref.putFile(File(serialNumberPict[i]));
          final snapshot = await uploadTask.whenComplete(() {});
          final urlDownload = await snapshot.ref.getDownloadURL();
          serialNumberPictFirebase.add(urlDownload);
        }

        // serialNumberPictFirebase.add(urlDownload);
      }
    }
    if (sidewallPic.isNotEmpty) {
      for (int i = 0; i < sidewallPic.length; i++) {
        if (!sidewallPic[i].startsWith('http')) {
          final ref = storage.ref().child(
              'tire_repair/${DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}-sidewall');
          final uploadTask = ref.putFile(File(sidewallPic[i]));
          final snapshot = await uploadTask.whenComplete(() {});
          final urlDownload = await snapshot.ref.getDownloadURL();
          sidewallPicFirebase.add(urlDownload);
        }
      }
    }
    if (shoulderPic.isNotEmpty) {
      for (int i = 0; i < shoulderPic.length; i++) {
        if (!shoulderPic[i].startsWith('http')) {
          final ref = storage.ref().child(
              'tire_repair/${DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}-shoulder');
          final uploadTask = ref.putFile(File(shoulderPic[i]));
          final snapshot = await uploadTask.whenComplete(() {});
          final urlDownload = await snapshot.ref.getDownloadURL();
          shoulderPicFirebase.add(urlDownload);
        }
      }
    }
    if (threatPic.isNotEmpty) {
      for (int i = 0; i < threatPic.length; i++) {
        if (!threatPic[i].startsWith('http')) {
          final ref = storage.ref().child(
              'tire_repair/${DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}-tread');
          final uploadTask = ref.putFile(File(threatPic[i]));
          final snapshot = await uploadTask.whenComplete(() {});
          final urlDownload = await snapshot.ref.getDownloadURL();
          threatPicFirebase.add(urlDownload);
        }
      }
    }
    if (beadPic.isNotEmpty) {
      for (int i = 0; i < beadPic.length; i++) {
        if (!beadPic[i].startsWith('http')) {
          final ref = storage.ref().child(
              'tire_repair/${DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}-bead');
          final uploadTask = ref.putFile(File(beadPic[i]));
          final snapshot = await uploadTask.whenComplete(() {});
          final urlDownload = await snapshot.ref.getDownloadURL();
          beadPicFirebase.add(urlDownload);
        }
      }
    }
    if (innerLinerPic.isNotEmpty) {
      for (int i = 0; i < innerLinerPic.length; i++) {
        if (!innerLinerPic[i].startsWith('http')) {
          final ref = storage.ref().child(
              'tire_repair/${DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}-inner');
          final uploadTask = ref.putFile(File(innerLinerPic[i]));
          final snapshot = await uploadTask.whenComplete(() {});
          final urlDownload = await snapshot.ref.getDownloadURL();
          innerLinerPicFirebase.add(urlDownload);
        }
      }
    }

    if (chafferPic.isNotEmpty) {
      for (int i = 0; i < chafferPic.length; i++) {
        if (!chafferPic[i].startsWith('http')) {
          final ref = storage.ref().child(
              'tire_repair/${DateFormat('yyyy-MM-dd').format(selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}-chaffer');
          final uploadTask = ref.putFile(File(chafferPic[i]));
          final snapshot = await uploadTask.whenComplete(() {});
          final urlDownload = await snapshot.ref.getDownloadURL();
          chafferPicFirebase.add(urlDownload);
        }
      }
    }
  }

  Future<void> getIdSite() async {
    idSite = await getIdSitePreferences();
    user = await getUserPreferences();
  }

  Future<List<Map<String, dynamic>>> getRepairLocationList() async {
    final snapshot = await firestore.collection('list_repair_area').get();
    final dataList =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    return dataList;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      id = ModalRoute.of(context)?.settings.arguments as String?;
      // if (id != null || id != '') {
      if (id != null && id!.isNotEmpty) {
        await _fetchData(id ?? '');
      }
    });
    getIdSite();
  }

  @override
  void dispose() {
    disposeTextCtrl();

    super.dispose();
  }

  Future<void> _fetchData(String id) async {
    try {
      final querySnapshot = await firestore
          .collection(FirestoreKey.tireRepairInspectionReport)
          .where('id', isEqualTo: id)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();

        // log('tanggal sekarang : ${data['date_inspect']}');
        // selectedDate = DateTime.parse(data['date_inspect']);
        selectedReceivedDate = DateTime.parse(data['date_received']) ??
            DateTime.parse(DateTime.now().toIso8601String());

        log('received data : ${selectedReceivedDate}');

        selectedCustomer = data['customer'] ?? 'PT Cipta Kridatama';
        customerCtrl.text = data['customer'] ?? 'PT Cipta Kridatama';

        selectedSize = data['tire_size'] ?? '';
        tireSizeCtrl.text = data['tire_size'] ?? '';

        siteCtrl.text = data['site'] ?? '';
        tireSizeCtrl.text = data['tire_size'] ?? '';
        serialNumberCtrl.text = data['sn'] ?? '';
        brandCtrl.text = data['brand'] ?? '';
        typeConstCtrl.text = (data['type_construction'] ?? 'RADIAL')
            .toString()
            .toUpperCase()
            .trim();
        selectedConstructionType = (data['type_construction'] ?? 'RADIAL')
            .toString()
            .toUpperCase()
            .trim();

        patternCtrl.text = data['pattern'] ?? '';

        if (data['is_inspected'] == 1) {
          cargoManifestCtrl.text = data['no_cargo_manifest'] ?? '';
          rtd1Ctrl.text = data['rtd1'] ?? '';
          rtd2Ctrl.text = data['rtd2'] ?? '';
          remarksCtrl.text = data['remarks'] ?? '';
          reportNameCtrl.text = data['report_by'] ?? '';
          selectedStatus = data['status'];
          log('selected status : ${selectedStatus}');
          // _selectedButton = data['repair_duration'] ??
          //         (selectedStatus == ('REJECT').toUpperCase().trim())
          //     ? ""
          //     : 'R2';
          _selectedButton = (selectedStatus == ('REJECT').toUpperCase().trim())
              ? ''
              : data['repair_duration'] ?? '';

          statusCtrl.text = data['status'];
          selectedRepairLocation = data['repair_location'] ?? 'BSF';
          selectedDate = DateTime.parse(data['date_inspect']) ??
              DateTime.parse(DateTime.now().toIso8601String());

          serialNumberPict = (data['sn_pic'] as List<dynamic>)
              .map((item) => item.toString())
              .toList();
          sidewallPic = (data['sidewall_pic'] as List<dynamic>)
              .map((item) => item.toString())
              .toList();
          shoulderPic = (data['shoulder_pic'] as List<dynamic>)
              .map((item) => item.toString())
              .toList();
          threatPic = (data['threat_pic'] as List<dynamic>)
              .map((item) => item.toString())
              .toList();
          beadPic = (data['bead_pic'] as List<dynamic>)
              .map((item) => item.toString())
              .toList();
          innerLinerPic = (data['inner_linner_pic'] as List<dynamic>)
              .map((item) => item.toString())
              .toList();
          chafferPic = (data['chaffer_pic'] as List<dynamic>)
              .map((item) => item.toString())
              .toList();
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void disposeTextCtrl() {
    customerCtrl.clear();
    siteCtrl.clear();
    reportNameCtrl.clear();
    tireSizeCtrl.clear();
    serialNumberCtrl.clear();
    brandCtrl.clear();
    typeConstCtrl.clear();
    patternCtrl.clear();
    noCM.clear();
    statusCtrl.clear();
    cargoManifestCtrl.clear();
    rtd1Ctrl.clear();
    rtd2Ctrl.clear();
    remarksCtrl.clear();
    repairLocationCtrl.clear();
    newLocationCtrl.clear();

    customerCtrl.dispose();
    siteCtrl.dispose();
    reportNameCtrl.dispose();
    tireSizeCtrl.dispose();
    serialNumberCtrl.dispose();
    brandCtrl.dispose();
    typeConstCtrl.dispose();
    patternCtrl.dispose();
    noCM.dispose();
    statusCtrl.dispose();
    cargoManifestCtrl.dispose();
    rtd1Ctrl.dispose();
    rtd2Ctrl.dispose();
    remarksCtrl.dispose();
    repairLocationCtrl.clear();
    newLocationCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    id ??= '';
    log('repair duration : $id');

    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F1),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Tire Inspection Report',
          style: TextStyle(color: Colors.black, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          InkWell(
            onTap: () async {
              String phoneNumber = "+6281252073489";
              String url =
                  "https://wa.me/$phoneNumber?text=Saya mau menambah data ... karena tidak ada di CAMOS.";
              Uri uri = Uri.parse(url);

              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                print('error whatsapp : $e');
              }
            },
            child: Row(
              children: [
                Image.asset(
                  '${iconPath}/whatsapp.png',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(
                  width: 4,
                ),
                Text(
                  'Contact Dev.',
                  style: getBlackTextStyle(fontSize: 12),
                ),
                const SizedBox(
                  width: 16,
                ),
              ],
            ),
          ),
        ],
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20.0),
            bottomRight: Radius.circular(20.0),
          ),
        ),
        clipBehavior: Clip.antiAliasWithSaveLayer,
        backgroundColor: const Color(0xFFC6FFBD),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 15.0, right: 15.0, top: 15.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.topCenter,
                        child: const Text(
                          'Tire Detail',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Tire Size',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder(
                          stream: firestore.collection('tire_size').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }

                            List<Map<String, dynamic>> dataList =
                                snapshot.data!.docs.map((doc) {
                              return doc.data() as Map<String, dynamic>;
                            }).toList();

                            // log('size : ${dataList[0]['size']}');

                            List<dynamic> size = dataList[0]['size'];
                            log('tire size : $size');
                            selectedSize ??= size[4];

                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                value: selectedSize,
                                items: size.map((size) {
                                  return DropdownMenuItem<String>(
                                    value: size,
                                    child: Text(size),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedSize = newValue ?? '';
                                    tireSizeCtrl.text = newValue ?? '';
                                  });
                                },
                              ),
                            );
                          }),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Serial Number',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: serialNumberCtrl,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: EdgeInsets.only(left: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Brand',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: brandCtrl,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: EdgeInsets.only(left: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Type Construction',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.symmetric(
                            horizontal: 16), // agar dropdown tidak mepet
                        child: DropdownButtonFormField<String>(
                          value: selectedConstructionType,
                          items: ['RADIAL', 'BIAS'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            selectedConstructionType = value ?? '';
                            // setState(() {}); // jika di StatefulWidget
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide:
                                  BorderSide.none, // hilangkan border bawaan
                            ),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                          ),
                          dropdownColor: Colors.white,
                        ),
                      ),
                      // Container(
                      //   decoration: BoxDecoration(
                      //     border: Border.all(color: Colors.grey),
                      //     color: Colors.white,
                      //     borderRadius: BorderRadius.circular(30),
                      //     boxShadow: [
                      //       BoxShadow(
                      //         color: Colors.grey.withOpacity(0.5),
                      //         spreadRadius: 2,
                      //         blurRadius: 5,
                      //         offset: Offset(0, 3),
                      //       ),
                      //     ],
                      //   ),
                      //   child: TextField(
                      //     controller: typeConstCtrl,
                      //     decoration: InputDecoration(
                      //       border: OutlineInputBorder(
                      //         borderRadius: BorderRadius.circular(30),
                      //       ),
                      //       contentPadding: EdgeInsets.only(left: 20),
                      //     ),
                      //   ),
                      // ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Pattern',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: patternCtrl,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: EdgeInsets.only(left: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Date Received',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _selectDate(context, 'received'),
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 199.0, left: 20.0, top: 15, bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            selectedReceivedDate == null
                                ? 'Select Date'
                                : '${selectedReceivedDate?.day}/${selectedReceivedDate?.month}/${selectedReceivedDate?.year}',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Customer',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      StreamBuilder(
                          stream:
                              firestore.collection('list_customer').snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return CircularProgressIndicator();
                            }

                            List<Map<String, dynamic>> dataList =
                                snapshot.data!.docs.map((doc) {
                              return doc.data() as Map<String, dynamic>;
                            }).toList();

                            List<dynamic> customers = dataList[0]['customer'];
                            selectedCustomer ??= customers[0];

                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                value: selectedCustomer,
                                items: customers.map((customer) {
                                  return DropdownMenuItem<String>(
                                    value: customer,
                                    child: Text(customer),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedCustomer = newValue ?? '';
                                    customerCtrl.text = newValue ?? '';
                                  });
                                },
                              ),
                            );
                          }),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Site',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: siteCtrl,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: EdgeInsets.only(left: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Container(
                        width: 400,
                        height: 2,
                        color: Colors.grey,
                        margin: EdgeInsets.symmetric(vertical: 20),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              // --------------------------------------------------------------------Information Repair------------------------------------------------------------------------------------- //
              Container(
                padding:
                    const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.only(left: 16.0, right: 16.0, top: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Align(
                        alignment: Alignment.topCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Information Repair',
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            SizedBox(
                                height:
                                    4), // Jarak antara teks utama dan subteks
                            // Text(
                            //   'Can input later',
                            //   style: TextStyle(
                            //     color: Colors.grey,
                            //     fontSize: 14,
                            //     fontStyle: FontStyle.italic,
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Status',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: DropdownButton<String>(
                          isExpanded: true,
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          value: selectedStatus,
                          hint: Text('Choose Status'),
                          items: listStatus.map((status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              selectedStatus = newValue ?? '';
                              statusCtrl.text = newValue ?? '';
                              // kalau reject jangan pilih repair duration
                              if ((newValue)?.toUpperCase().trim() ==
                                  'REJECT') {
                                _selectedButton = '';
                              }
                              log('durasi kerja : ${_selectedButton}');
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Repair / Inspect Location',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      FutureBuilder(
                          future: getRepairLocationList(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData)
                              return CircularProgressIndicator();

                            List<Map<String, dynamic>> listRepairLocation =
                                snapshot.data ?? [];

                            selectedRepairLocation ??=
                                listRepairLocation[0]['site'];

                            return Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: DropdownButton<String>(
                                isExpanded: true,
                                padding: EdgeInsets.symmetric(horizontal: 24),
                                value: selectedRepairLocation,
                                hint: const Text('Choose Repair Location'),
                                items: listRepairLocation.map((location) {
                                  return DropdownMenuItem<String>(
                                    value: location['site'],
                                    child: Text(location['site']),
                                  );
                                }).toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedRepairLocation = newValue ?? '';
                                    // repairLocationCtrl.text = newValue ?? '';
                                  });
                                },
                              ),
                            );
                          }),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Date Inspect',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _selectDate(context, 'inspect'),
                        child: Container(
                          padding: const EdgeInsets.only(
                              right: 199.0, left: 20.0, top: 15, bottom: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            selectedDate == null
                                ? 'Select Date'
                                : '${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}',
                            style: const TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Report by',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: reportNameCtrl,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: EdgeInsets.only(left: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      (selectedStatus == 'REJECT')
                          ? Container()
                          : Container(
                              padding: EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Color(0xFFE2E2E2), // Hex color #E2E2E2
                                borderRadius: BorderRadius.circular(
                                    20), // Optional: Adjust border radius if needed
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize
                                    .min, // Use min to avoid unnecessary space
                                children: [
                                  Align(
                                    alignment: Alignment
                                        .topCenter, // Align text to the top center
                                    child: Text(
                                      'Repair Duration', // Replace with the content you want
                                      style: TextStyle(
                                        color: Color(0xFF45625E), // Text color
                                        fontSize:
                                            20, // Adjust text size if needed
                                        fontWeight: FontWeight
                                            .bold, // Optional: Adjust text weight if needed
                                      ),
                                      textAlign: TextAlign
                                          .center, // Center align text within the widget
                                    ),
                                  ),
                                  SizedBox(
                                      height:
                                          15), // Space between text and buttons
                                  Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceEvenly, // Distribute space evenly
                                        children: [
                                          _buildButton('R1', 'R1'),
                                          _buildButton('R2', 'R2'),
                                        ],
                                      ),
                                      SizedBox(
                                          height: 12), // Space between rows
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment
                                            .spaceEvenly, // Distribute space evenly
                                        children: [
                                          _buildButton('R3', 'R3'),
                                          _buildButton('R4', 'R4'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'No. Cargo Manifest',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: cargoManifestCtrl,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            contentPadding: EdgeInsets.only(left: 20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: const Text(
                          'RTD (mm)',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: rtd1Ctrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('/'),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: rtd2Ctrl,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16.0, vertical: 12.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Align(
                        alignment: Alignment.topLeft,
                        child: Text(
                          'Remarks',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.5),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: remarksCtrl,
                          maxLines: null,
                          minLines: 5,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: EdgeInsets.only(left: 20, top: 40),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Column(
                        children: [
                          Text(
                            '*Please Take a Picture with Landscape Mode!',
                            style: getRedTextStyle(
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12.0),
                          // Serial Number Picture
                          takePictureButton('Serial Number'),
                          const SizedBox(height: 20.0),
                          takePictureButton('Area Sidewall'),
                          const SizedBox(height: 20.0),
                          takePictureButton('Area Shoulder'),
                          const SizedBox(height: 20.0),
                          takePictureButton('Area Tread'),
                          const SizedBox(height: 20.0),
                          takePictureButton('Area Bead'),
                          const SizedBox(height: 20.0),
                          takePictureButton('Area Inner Linner'),
                          const SizedBox(height: 20.0),
                          takePictureButton('Area Chaffer'),
                          const SizedBox(height: 20.0),
                          const SizedBox(height: 99.0),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        height: 60,
        width: 350.0,
        child: ElevatedButton(
          onPressed: () async {
            showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Text(
                      'Are you sure you want to submit?',
                      style: getBlackTextStyle(),
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: Text(
                            'Cancel',
                            style: getGreyTextStyle(grey8391A1),
                          )),
                      TextButton(
                          onPressed: () async {
                            // Tampilkan loading awal saat upload gambar
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return const AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 20),
                                      Text("Uploading image..."),
                                    ],
                                  ),
                                );
                              },
                            );

                            await uploadImage();
                            Navigator.pop(context); // Tutup loading upload

                            // Tampilkan loading untuk proses simpan data
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (context) {
                                return const AlertDialog(
                                  content: Row(
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(width: 20),
                                      Text("Submitting data..."),
                                    ],
                                  ),
                                );
                              },
                            );

                            try {
                              if (id != null && id != '') {
                                // MODE: EDIT
                                final querySnapshot = await firestore
                                    .collection(
                                        FirestoreKey.tireRepairInspectionReport)
                                    .where('id', isEqualTo: id)
                                    .get();

                                if (querySnapshot.docs.isNotEmpty) {
                                  final doc = querySnapshot.docs.first;
                                  final docId = doc.id;

                                  Map<String, dynamic> updateData = {
                                    'id': id,
                                    'date_inspect': DateFormat('yyyy-MM-dd')
                                        .format(selectedDate!),
                                    'customer': customerCtrl.text,
                                    'email': auth.currentUser?.email ?? '',
                                    'site': siteCtrl.text,
                                    'report_by': reportNameCtrl.text,
                                    'tire_size': tireSizeCtrl.text,
                                    'sn': serialNumberCtrl.text,
                                    'brand': brandCtrl.text,
                                    'remark': remarksCtrl.text,
                                    'type_construction':
                                        selectedConstructionType,
                                    'pattern': patternCtrl.text,
                                    'date_received': DateFormat('yyyy-MM-dd')
                                        .format(selectedReceivedDate!),
                                    'is_inspected': 1,
                                    'jobcard1': [],
                                    'status': selectedStatus,
                                    'no_cargo_manifest': cargoManifestCtrl.text,
                                    'rtd1': rtd1Ctrl.text,
                                    'rtd2': rtd2Ctrl.text,
                                    'repair_duration': _selectedButton,
                                    'remarks': remarksCtrl.text,
                                    'repair_location': selectedRepairLocation,
                                    'process_repair_count': 1,
                                  };

                                  if (serialNumberPictFirebase.isNotEmpty) {
                                    updateData['sn_pic'] =
                                        FieldValue.arrayUnion(
                                            serialNumberPictFirebase);
                                  }
                                  if (sidewallPicFirebase.isNotEmpty) {
                                    updateData['sidewall_pic'] =
                                        FieldValue.arrayUnion(
                                            sidewallPicFirebase);
                                  }
                                  if (shoulderPicFirebase.isNotEmpty) {
                                    updateData['shoulder_pic'] =
                                        FieldValue.arrayUnion(
                                            shoulderPicFirebase);
                                  }
                                  if (threatPicFirebase.isNotEmpty) {
                                    updateData['threat_pic'] =
                                        FieldValue.arrayUnion(
                                            threatPicFirebase);
                                  }
                                  if (beadPicFirebase.isNotEmpty) {
                                    updateData['bead_pic'] =
                                        FieldValue.arrayUnion(beadPicFirebase);
                                  }
                                  if (innerLinerPicFirebase.isNotEmpty) {
                                    updateData['inner_linner_pic'] =
                                        FieldValue.arrayUnion(
                                            innerLinerPicFirebase);
                                  }
                                  if (chafferPicFirebase.isNotEmpty) {
                                    updateData['chaffer_pic'] =
                                        FieldValue.arrayUnion(
                                            chafferPicFirebase);
                                  }

                                  await firestore
                                      .collection(FirestoreKey
                                          .tireRepairInspectionReport)
                                      .doc(docId)
                                      .update(updateData);

                                  // Untuk post ke API, hapus field yg tidak perlu
                                  updateData.remove('jobcard1');
                                  updateData.remove('sn_pic');
                                  updateData.remove('sidewall_pic');
                                  updateData.remove('shoulder_pic');
                                  updateData.remove('threat_pic');
                                  updateData.remove('bead_pic');
                                  updateData.remove('inner_linner_pic');
                                  updateData.remove('chaffer_pic');
                                  updateData.remove('is_inspected');

                                  await ApiService.editNewTireRepair(
                                      updateData);
                                }
                              } else {
                                // MODE: ADD
                                // const chars =
                                //     'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
                                // final rand = math.Random.secure();
                                // final newId = List.generate(
                                //         10,
                                //         (_) =>
                                //             chars[rand.nextInt(chars.length)])
                                //     .join();
                                final uuid = Uuid();
                                final newId =
                                    '${DateTime.now().millisecondsSinceEpoch}_${uuid.v4().substring(0, 8)}';
                                final reportData = {
                                  'id': newId,
                                  'customer': customerCtrl.text,
                                  'created_at':
                                      DateTime.now().toIso8601String(),
                                  'site': siteCtrl.text,
                                  'receiver': auth.currentUser?.email,
                                  'email': auth.currentUser?.email ?? '',
                                  'tire_size': tireSizeCtrl.text,
                                  'sn': serialNumberCtrl.text,
                                  'brand': brandCtrl.text,
                                  'type_construction': selectedConstructionType,
                                  'pattern': patternCtrl.text,
                                  'date_received': DateFormat('yyyy-MM-dd')
                                          .format(selectedReceivedDate!) ??
                                      DateTime.parse(
                                          DateTime.now().toIso8601String()),
                                };

                                // 1. Cek apakah ADA salah satu field inspeksi yang diisi user
                                final bool hasAnyInspectField = selectedDate !=
                                        null ||
                                    reportNameCtrl.text.trim().isNotEmpty ||
                                    statusCtrl.text.trim().isNotEmpty ||
                                    rtd1Ctrl.text.trim().isNotEmpty ||
                                    rtd2Ctrl.text.trim().isNotEmpty ||
                                    selectedRepairLocation != null ||
                                    (serialNumberPictFirebase != null &&
                                        serialNumberPictFirebase.isNotEmpty) ||
                                    (_selectedButton != null &&
                                        _selectedButton!.isNotEmpty) ||
                                    remarksCtrl.text.trim().isNotEmpty;

                                // 2. Set nilai isInspected
                                int isInspected = hasAnyInspectField ? 1 : 0;

                                // 3. Simpan ke inspectReportData dengan default fallback ('' / 0 / [])
                                Map<String, dynamic> inspectReportData = {};

                                // if (selectedDate != null) {
                                //   inspectReportData['date_inspect'] =
                                //       DateFormat('yyyy-MM-dd')
                                //           .format(selectedDate!);
                                // }
                                inspectReportData['date_inspect'] =
                                    selectedDate != null
                                        ? DateFormat('yyyy-MM-dd')
                                            .format(selectedDate!)
                                        : DateFormat('yyyy-MM-dd')
                                            .format(DateTime.now());

                                // if (reportNameCtrl.text.isNotEmpty) {
                                //   inspectReportData['report_by'] =
                                //       reportNameCtrl.text;
                                // }
                                inspectReportData['report_by'] =
                                    reportNameCtrl.text.trim();

                                // if (statusCtrl.text.isNotEmpty ||
                                //     selectedStatus.isNotEmpty) {
                                //   inspectReportData['status'] = statusCtrl.text;
                                // }
                                inspectReportData['status'] =
                                    statusCtrl.text.trim();

                                // if (cargoManifestCtrl.text.isNotEmpty) {
                                //   inspectReportData['no_cargo_manifest'] =
                                //       cargoManifestCtrl.text;
                                // }
                                inspectReportData['no_cargo_manifest'] =
                                    cargoManifestCtrl.text.trim();

                                // if (rtd1Ctrl.text.isNotEmpty) {
                                //   inspectReportData['rtd1'] = rtd1Ctrl.text;
                                // }
                                inspectReportData['rtd1'] =
                                    rtd1Ctrl.text.isNotEmpty
                                        ? rtd1Ctrl.text
                                        : '0';

                                // if (rtd2Ctrl.text.isNotEmpty) {
                                //   inspectReportData['rtd2'] = rtd2Ctrl.text;
                                // }
                                inspectReportData['rtd2'] =
                                    rtd2Ctrl.text.isNotEmpty
                                        ? rtd2Ctrl.text
                                        : '0';

                                // if (selectedRepairLocation != '') {
                                //   inspectReportData['repair_location'] =
                                //       selectedRepairLocation;
                                // }
                                inspectReportData['repair_location'] =
                                    selectedRepairLocation ?? '';

                                // if (_selectedButton != null &&
                                //     _selectedButton.isNotEmpty) {
                                //   inspectReportData['repair_duration'] =
                                //       _selectedButton;
                                // }
                                inspectReportData['repair_duration'] =
                                    _selectedButton ?? '';

                                // if (remarksCtrl.text.isNotEmpty) {
                                //   inspectReportData['remarks'] =
                                //       remarksCtrl.text;
                                // }
                                inspectReportData['remarks'] =
                                    remarksCtrl.text.trim();

                                inspectReportData['sn_pic'] =
                                    serialNumberPictFirebase ?? [];
                                inspectReportData['sidewall_pic'] =
                                    sidewallPicFirebase ?? [];
                                inspectReportData['shoulder_pic'] =
                                    shoulderPicFirebase ?? [];
                                inspectReportData['threat_pic'] =
                                    threatPicFirebase ?? [];
                                inspectReportData['bead_pic'] =
                                    beadPicFirebase ?? [];
                                inspectReportData['inner_linner_pic'] =
                                    innerLinerPicFirebase ?? [];
                                inspectReportData['chaffer_pic'] =
                                    chafferPicFirebase ?? [];

                                inspectReportData['is_inspected'] = isInspected;

                                if (isInspected == 1) {
                                  inspectReportData['jobcard1'] = [];
                                  inspectReportData['process_repair_count'] = 1;
                                }

                                inspectReportData.addAll(reportData);

                                await ApiService.postNewTireRepair(reportData);

                                // 🔁 Jalankan API & Firestore secara paralel
                                List<Future> futures = [
                                  firestore
                                      .collection(FirestoreKey
                                          .tireRepairInspectionReport)
                                      .doc(DateTime.now().toIso8601String())
                                      .set(inspectReportData),
                                ];

                                if (isInspected == 1) {
                                  Map<String, dynamic> postToAPI =
                                      Map.from(inspectReportData)
                                        ..remove('jobcard1')
                                        ..remove('sn_pic')
                                        ..remove('sidewall_pic')
                                        ..remove('shoulder_pic')
                                        ..remove('threat_pic')
                                        ..remove('bead_pic')
                                        ..remove('inner_linner_pic')
                                        ..remove('chaffer_pic')
                                        ..remove('is_inspected')
                                        ..remove('receiver');

                                  futures.add(
                                      ApiService.editNewTireRepair(postToAPI));
                                  log('api yg dikirm : ${postToAPI}');
                                }

                                await Future.wait(futures);
                              }

                              Navigator.pop(context); // Tutup loading dialog
                              Navigator.pop(context); // Tutup current page
                              Navigator.pushReplacementNamed(
                                  context, TireRepairInspectionPage.routeName);
                            } catch (e) {
                              Navigator.pop(
                                  context); // pastikan dialog ditutup meski error
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text("Gagal submit: $e"),
                                backgroundColor: Colors.red,
                              ));
                            }
                          },
                          child: Text(
                            'Yes',
                            style: getRedTextStyle(),
                          ))
                    ],
                  );
                });
          },
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30.0),
            ),
            padding: const EdgeInsets.all(0),
          ),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF95E2A8),
                  Color(0xFF7098DB),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(30.0),
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Submit',
                style: TextStyle(fontSize: 18.0, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget takePictureButton(String type) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                type,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () async {
                      requestCameraPermission();
                      requestStoragePermission();
                      await _pickImage(type, ImageSource.camera);
                    },
                    child: BoxCamera(
                      type: 'camera',
                    ),
                  ),
                  const SizedBox(width: 10),
                  InkWell(
                    onTap: () async {
                      requestStoragePermission();
                      await _pickImage(type, ImageSource.gallery);
                    },
                    child: BoxCamera(
                      type: 'gallery',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Builder(builder: (context) {
            switch (type) {
              case 'Serial Number':
                if (serialNumberPict.isNotEmpty) {
                  return itemPicture(context, serialNumberPict);
                }
                return Container();
              case 'Area Sidewall':
                if (sidewallPic.isNotEmpty) {
                  return itemPicture(context, sidewallPic);
                }
                return Container();
              case 'Area Shoulder':
                if (shoulderPic.isNotEmpty) {
                  return itemPicture(context, shoulderPic);
                }
                return Container();
              case 'Area Tread':
                if (threatPic.isNotEmpty) {
                  return itemPicture(context, threatPic);
                }
                return Container();
              case 'Area Bead':
                if (beadPic.isNotEmpty) {
                  return itemPicture(context, beadPic);
                }
                return Container();
              case 'Area Inner Linner':
                if (innerLinerPic.isNotEmpty) {
                  return itemPicture(context, innerLinerPic);
                }
                return Container();
              case 'Area Chaffer':
                if (chafferPic.isNotEmpty) {
                  return itemPicture(context, chafferPic);
                }
                return Container();
            }
            return Container();
          }),
        ],
      ),
    );
  }

  Future<void> _pickImage(String type, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image =
        await picker.pickImage(imageQuality: 50, source: source);
    try {
      if (image != null) {
        File imageFile = File(image.path);

        final compressedImageFile =
            await FlutterImageCompress.compressAndGetFile(
          imageFile.path,
          imageFile.path + '_compressed.jpg',
          quality: 50,
        );

        // saveToGallery(compressedImageFile, type);

        switch (type) {
          case 'Serial Number':
            serialNumberPict.add('${compressedImageFile?.path}' ?? '');
            break;
          case 'Area Sidewall':
            sidewallPic.add('${compressedImageFile?.path}' ?? '');
            break;
          case 'Area Shoulder':
            shoulderPic.add('${compressedImageFile?.path}' ?? '');
            break;
          case 'Area Tread':
            threatPic.add('${compressedImageFile?.path}' ?? '');
            break;
          case 'Area Bead':
            beadPic.add('${compressedImageFile?.path}' ?? '');
            break;
          case 'Area Inner Linner':
            innerLinerPic.add('${compressedImageFile?.path}' ?? '');
            break;
          case 'Area Chaffer':
            chafferPic.add('${compressedImageFile?.path}' ?? '');
            break;
        }
      }
    } catch (e) {
      log('Error picking image: $e');
    }

    setState(() {});
  }

  Widget itemPicture(BuildContext context, List<String> img) {
    return Column(
      children: img.map((i) {
        final imgIndex = img.indexOf(i);
        return Column(
          children: [
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: i.startsWith('http')
                      ? Image.network(
                          i,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(i),
                          fit: BoxFit.cover,
                        ),
                ),
                (id == null || id == '')
                    ? Align(
                        alignment: Alignment.bottomCenter,
                        child: SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Colors.deepOrange.withOpacity(0.3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  )),
                              onPressed: () async {
                                showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        content: Text(
                                          'Are you sure you want to delete this image?',
                                          style: getBlackTextStyle(),
                                        ),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: Text(
                                                'Cancel',
                                                style: getGreyTextStyle(
                                                    grey8391A1),
                                              )),
                                          TextButton(
                                              onPressed: () {
                                                img.removeWhere((element) {
                                                  log('poto : $element | poto 2 : $i');
                                                  return element == i;
                                                });
                                                Navigator.pop(context);
                                                setState(() {});
                                              },
                                              child: Text(
                                                'Yes',
                                                style: getRedTextStyle(),
                                              )),
                                        ],
                                      );
                                    });

                                setState(() {});
                              },
                              child: Row(
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
                                    'Delete Picture',
                                    style: getWhiteTextStyle(),
                                  ),
                                ],
                              )),
                        ),
                      )
                    : Container(),
              ],
            ),
            const SizedBox(
              height: 12,
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildButton(String id, String label) {
    bool isSelected = _selectedButton == id;

    return Column(
      children: [
        ElevatedButton(
          onPressed: () => _handleButtonClick(id),
          style: ButtonStyle(
            minimumSize: MaterialStateProperty.all(
                Size(130, 50)), // Set width and height
            backgroundColor: MaterialStateProperty.all(
              isSelected
                  ? Colors.white
                  : Colors.white, // Button background color
            ),
            side: MaterialStateProperty.all(
              BorderSide(
                color: isSelected ? Color(0xFF45625E) : Colors.transparent,
                width: 3,
              ),
            ),
            foregroundColor: MaterialStateProperty.all(Color(0xFF45625E)
                // Change text color to black
                ),
          ),
          child: Text(
            id,
            style: TextStyle(
              fontSize: 18, // Set the desired text size here
              fontWeight:
                  FontWeight.bold, // Optional: Set the desired font weight
            ),
          ),
        ),
        SizedBox(height: 12), // Space between button and text
        Text(
          buttonLabels[id] ?? 'Max 4 days', // Default text if label not set
          style: TextStyle(
            fontSize: 14, // Adjust text size if needed
            color: Color(0xFF45625E), // Adjust text color if needed
          ),
        ),
      ],
    );
  }

  void _handleButtonClick(String buttonId) {
    setState(() {
      _selectedButton = buttonId;
    });
  }

  void saveToGallery(XFile? compressedImageFile, String type) async {
    final imageBytes = await compressedImageFile?.readAsBytes();

    await ImageGallerySaver.saveImage(
      imageBytes!,
      name: 'tire-repair-$type-${DateTime.now().millisecondsSinceEpoch}',
    );
    // Directory? directory;

    // if (Platform.isAndroid) {
    //   // path = await getExternalStorageDirectory();
    //   directory = await DownloadsPath.downloadsDirectory();
    // }

    // if (Platform.isIOS) {
    //   // final directory = await getApplicationDocumentsDirectory();
    //   // path = directory;
    //   directory = await getApplicationDocumentsDirectory();

    //   // Read image as a file

    //   final compressedFilePath =
    //       '${directory.path}/${DateTime.now().millisecondsSinceEpoch}_tireinspectionimage_compressed.jpg';
    // }
  }

  Future<dynamic> errorImage(BuildContext context, String type,
      {int count = 0}) {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text((type == 'Serial Number')
              ? 'Please take 1 (one) picture of serial number'
              : 'Please take ${4 - count} more picture of tire damage'),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class BoxCamera extends StatelessWidget {
  final String type;

  const BoxCamera({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70.0,
      height: 40.0,
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Center(
        child: Icon(
          (type == 'camera') ? Icons.camera_alt : Icons.image,
          color: Colors.white,
        ),
      ),
    );
  }
}
