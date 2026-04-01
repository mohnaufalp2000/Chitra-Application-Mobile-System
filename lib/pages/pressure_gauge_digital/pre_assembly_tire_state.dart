import 'package:get/get.dart';
import 'package:flutter/material.dart';

class PreAssemblyTireState extends GetxController {
  final rimSize = TextEditingController();
  final rimBrand = TextEditingController();
  final serialNo = TextEditingController();

  RxMap<String, dynamic> formData = <String, dynamic>{
    'rim_condition': <String>[].obs,
  }.obs;

  RxString action = ''.obs;

  void setValue(String key, dynamic value) {
    formData[key] = value;
  }

  void toggleMultiCondition(String key, String value) {
    final list = (formData[key] as List).cast<String>();

    if (value == "Normal") {
      // kalau klik Normal → reset semua
      formData[key] = ["Normal"];
      return;
    }

    // kalau klik selain Normal → hapus Normal
    list.remove("Normal");

    if (list.contains(value)) {
      list.remove(value);
    } else {
      list.add(value);
    }

    formData[key] = List.from(list);
  }
}
