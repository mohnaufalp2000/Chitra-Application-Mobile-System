import 'dart:developer';
import 'dart:io';

import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/pages/tire_repair_form/tire_repair_inspection_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

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
  String _selectedButton = '';

  DateTime? _selectedDate;
  DateTime? _selectedReceivedDate;
  TextEditingController customerCtrl = TextEditingController(text: '');
  TextEditingController siteCtrl = TextEditingController(text: '');
  TextEditingController reportNameCtrl = TextEditingController(text: '');
  TextEditingController tireSizeCtrl = TextEditingController(text: '');
  TextEditingController serialNumberCtrl = TextEditingController(text: '');
  TextEditingController brandCtrl = TextEditingController(text: '');
  TextEditingController typeConstCtrl = TextEditingController(text: '');
  TextEditingController patternCtrl = TextEditingController(text: '');
  TextEditingController noCM = TextEditingController(text: '');
  TextEditingController statusCtrl = TextEditingController(text: '');
  TextEditingController cargoManifestCtrl = TextEditingController(text: '');
  TextEditingController rtd1Ctrl = TextEditingController(text: '');
  TextEditingController rtd2Ctrl = TextEditingController(text: '');
  TextEditingController remarksCtrl = TextEditingController(text: '');

  List<String> serialNumberPict = [];
  List<String> sidewallPic = [];
  List<String> shoulderPic = [];
  List<String> threatPic = [];
  List<String> beadPic = [];
  List<String> innerLinerPic = [];

  List<String> serialNumberPictFirebase = [];
  List<String> sidewallPicFirebase = [];
  List<String> shoulderPicFirebase = [];
  List<String> threatPicFirebase = [];
  List<String> beadPicFirebase = [];
  List<String> innerLinerPicFirebase = [];

  final Map<String, String> buttonLabels = {
    'R1': '*Max 4 days',
    'R2': '*Max 8 days',
    'R3': '*Max 12 days',
    'R4': '*Max 18 days',
  };

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (type == 'inspect')
          ? _selectedDate
          : _selectedReceivedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (type == 'inspect') {
      if (picked != null && picked != _selectedDate) {
        setState(() {
          _selectedDate = picked;
          log('tanggal sekarang : $_selectedDate');
        });
      }
    } else {
      if (picked != null && picked != _selectedReceivedDate) {
        setState(() {
          _selectedReceivedDate = picked;
          log('tanggal sekarang : $_selectedDate');
        });
      }
    }
  }

  Future<void> uploadImage() async {
    if (serialNumberPict.isNotEmpty) {
      for (int i = 0; i < serialNumberPict.length; i++) {
        final ref = storage.ref().child(
            'tire_repair/${DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}');
        final uploadTask = ref.putFile(File(serialNumberPict[i]));
        final snapshot = await uploadTask.whenComplete(() {});
        final urlDownload = await snapshot.ref.getDownloadURL();

        serialNumberPictFirebase.add(urlDownload);
      }
    }
    if (sidewallPic.isNotEmpty) {
      for (int i = 0; i < sidewallPic.length; i++) {
        final ref = storage.ref().child(
            'tire_repair/${DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}');
        final uploadTask = ref.putFile(File(sidewallPic[i]));
        final snapshot = await uploadTask.whenComplete(() {});
        final urlDownload = await snapshot.ref.getDownloadURL();

        sidewallPicFirebase.add(urlDownload);
      }
    }
    if (shoulderPic.isNotEmpty) {
      for (int i = 0; i < shoulderPic.length; i++) {
        final ref = storage.ref().child(
            'tire_repair/${DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}');
        final uploadTask = ref.putFile(File(shoulderPic[i]));
        final snapshot = await uploadTask.whenComplete(() {});
        final urlDownload = await snapshot.ref.getDownloadURL();

        shoulderPicFirebase.add(urlDownload);
      }
    }
    if (threatPic.isNotEmpty) {
      for (int i = 0; i < threatPic.length; i++) {
        final ref = storage.ref().child(
            'tire_repair/${DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}');
        final uploadTask = ref.putFile(File(threatPic[i]));
        final snapshot = await uploadTask.whenComplete(() {});
        final urlDownload = await snapshot.ref.getDownloadURL();

        threatPicFirebase.add(urlDownload);
      }
    }
    if (beadPic.isNotEmpty) {
      for (int i = 0; i < beadPic.length; i++) {
        final ref = storage.ref().child(
            'tire_repair/${DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}');
        final uploadTask = ref.putFile(File(beadPic[i]));
        final snapshot = await uploadTask.whenComplete(() {});
        final urlDownload = await snapshot.ref.getDownloadURL();

        beadPicFirebase.add(urlDownload);
      }
    }
    if (innerLinerPic.isNotEmpty) {
      for (int i = 0; i < innerLinerPic.length; i++) {
        final ref = storage.ref().child(
            'tire_repair/${DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}');
        final uploadTask = ref.putFile(File(innerLinerPic[i]));
        final snapshot = await uploadTask.whenComplete(() {});
        final urlDownload = await snapshot.ref.getDownloadURL();

        innerLinerPicFirebase.add(urlDownload);
      }
    }
  }

  Future<void> loopingImage(List<String> images) async {
    for (int i = 0; i < images.length; i++) {
      final ref = storage.ref().child(
          'tire_repair/${DateFormat('yyyy-MM-dd').format(_selectedDate ?? DateTime.now())}-${customerCtrl.text}-${serialNumberCtrl.text}-${i + 1}');
      final uploadTask = ref.putFile(File(images[i]));
      final snapshot = await uploadTask.whenComplete(() {});
      final urlDownload = await snapshot.ref.getDownloadURL();

      serialNumberPictFirebase.add(urlDownload);
    }
  }

  @override
  void dispose() {
    disposeTextCtrl();

    super.dispose();
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
  }

  @override
  Widget build(BuildContext context) {
    log('repair duration : $_selectedButton');

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
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
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
          child: Container(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
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
                        _selectedDate == null
                            ? 'Select Date'
                            : '${_selectedDate?.day}/${_selectedDate?.month}/${_selectedDate?.year}',
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
                      controller: customerCtrl,
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
                  Container(
                    width: 400,
                    height: 2,
                    color: Colors.grey,
                    margin: EdgeInsets.symmetric(vertical: 20),
                  ),
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
                      controller: tireSizeCtrl,
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
                    child: TextField(
                      controller: typeConstCtrl,
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
                        _selectedReceivedDate == null
                            ? 'Select Date'
                            : '${_selectedReceivedDate?.day}/${_selectedReceivedDate?.month}/${_selectedReceivedDate?.year}',
                        style: const TextStyle(color: Colors.black),
                      ),
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
                    child: TextField(
                      controller: statusCtrl,
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
                  Container(
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
                              fontSize: 20, // Adjust text size if needed
                              fontWeight: FontWeight
                                  .bold, // Optional: Adjust text weight if needed
                            ),
                            textAlign: TextAlign
                                .center, // Center align text within the widget
                          ),
                        ),
                        SizedBox(height: 15), // Space between text and buttons
                        // Use a Column to stack the rows of buttons
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
                            SizedBox(height: 12), // Space between rows
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
                  // Serial Number Picture
                  takePictureButton('Serial Number'),
                  const SizedBox(height: 20.0),
                  takePictureButton('Area Sidewall'),
                  const SizedBox(height: 20.0),
                  takePictureButton('Area Shoulder'),
                  const SizedBox(height: 20.0),
                  takePictureButton('Area Threat'),
                  const SizedBox(height: 20.0),
                  takePictureButton('Area Bead'),
                  const SizedBox(height: 20.0),
                  takePictureButton('Area Inner Linner'),
                  const SizedBox(height: 20.0),
                  const SizedBox(height: 99.0),
                ],
              ),
            ),
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
                            if (_selectedButton == '') {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(
                                content: Text(
                                  'Please choose repair duration first!',
                                  style: getWhiteTextStyle(),
                                ),
                                backgroundColor: Colors.red,
                              ));
                              return;
                            }

                            try {
                              await uploadImage();

                              log('serial number : ${sidewallPicFirebase}');
                              final id = Uuid().v4();
                              await firestore
                                  .collection('tire_repair_ins_report')
                                  .add({
                                'id': id,
                                'date_inspect':
                                    '${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                                'customer': customerCtrl.text,
                                'site': siteCtrl.text,
                                'report_by': reportNameCtrl.text,
                                'tire_size': tireSizeCtrl.text,
                                'sn': serialNumberCtrl.text,
                                'brand': brandCtrl.text,
                                'type_construction': typeConstCtrl.text,
                                'pattern': patternCtrl.text,
                                'date_received':
                                    '${DateFormat('yyyy-MM-dd').format(_selectedReceivedDate!)}',
                                'status': statusCtrl.text,
                                'no_cargo_manifest': cargoManifestCtrl.text,
                                'rtd1': rtd1Ctrl.text,
                                'rtd2': rtd2Ctrl.text,
                                'repair_duration': _selectedButton,
                                'remarks': remarksCtrl.text,
                                'sn_pic': serialNumberPictFirebase,
                                'sidewall_pic': sidewallPicFirebase,
                                'shoulder_pic': shoulderPicFirebase,
                                'threat_pic': threatPicFirebase,
                                'bead_pic': beadPicFirebase,
                                'inner_linner_pic': innerLinerPicFirebase,
                              });
                            } catch (e) {}
                            Navigator.pushReplacementNamed(
                                context, TireRepairInspectionPage.routeName);
                          },
                          child: Text(
                            'Yes',
                            style: getRedTextStyle(),
                          )),
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
              InkWell(
                  onTap: () async {
                    requestCameraPermission();
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(
                        imageQuality: 50, source: ImageSource.camera);
                    try {
                      if (image != null) {
                        // Read image as a file
                        File imageFile = File(image.path);
                        // data size fotonya
                        log('gambar : ${imageFile.path}');

                        // Compress the image if needed (optional)
                        final compressedImageFile =
                            await FlutterImageCompress.compressAndGetFile(
                          imageFile.path,
                          imageFile.path + '_compressed.jpg',
                          quality: 50,
                        );

                        switch (type) {
                          case 'Serial Number':
                            serialNumberPict
                                .add('${compressedImageFile?.path}' ?? '');
                            break;
                          case 'Area Sidewall':
                            sidewallPic
                                .add('${compressedImageFile?.path}' ?? '');
                            break;
                          case 'Area Shoulder':
                            shoulderPic
                                .add('${compressedImageFile?.path}' ?? '');
                            break;
                          case 'Area Threat':
                            threatPic.add('${compressedImageFile?.path}' ?? '');
                            break;
                          case 'Area Bead':
                            beadPic.add('${compressedImageFile?.path}' ?? '');
                            break;
                          case 'Area Inner Linner':
                            innerLinerPic
                                .add('${compressedImageFile?.path}' ?? '');
                            break;
                        }
                        // listImg.add(
                        //     '${compressedImageFile?.path}|${position[index]['position']}' ??
                        //         '');
                        // // Convert image to base64
                      }
                    } catch (e) {
                      log('error gambar string : $e');
                    }

                    setState(() {});
                  },
                  child: BoxCamera())
            ],
          ),
          const SizedBox(
            height: 12,
          ),
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
              case 'Area Threat':
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
            }
            return Container();
          }),
        ],
      ),
    );
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
                    child: Image.file(File((i as String)))),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrange.withOpacity(0.3),
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
                                          style: getGreyTextStyle(grey8391A1),
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
                ),
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
}

class BoxCamera extends StatelessWidget {
  const BoxCamera({super.key});

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
          Icons.camera_alt,
          color: Colors.white,
        ),
      ),
    );
  }
}
