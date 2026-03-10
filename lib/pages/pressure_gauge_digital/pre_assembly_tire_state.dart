import 'package:get/get.dart';
import 'package:flutter/material.dart';

class PreAssemblyTireState extends GetxController {
  final rimSize = TextEditingController();
  final rimBrand = TextEditingController();
  final serialNo = TextEditingController();

  RxMap<String, dynamic> formData = <String, dynamic>{}.obs;

  RxString action = ''.obs;

  void setValue(String key, dynamic value) {
    formData[key] = value;
  }
}
