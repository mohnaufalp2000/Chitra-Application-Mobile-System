import 'dart:convert';
import 'dart:math';

import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class AddUserState extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;
  final HomeState homeState = Get.find<HomeState>();

  final TextEditingController usernameC = TextEditingController();
  final TextEditingController emailC = TextEditingController();
  final TextEditingController snC = TextEditingController();
  final TextEditingController positionC = TextEditingController();
  final TextEditingController ageC = TextEditingController();

  final RxBool isLoading = false.obs;

  Future<void> addUser() async {
    try {
      isLoading.value = true;

      if (usernameC.text.isEmpty || emailC.text.isEmpty) {
        Get.snackbar(
          'Warning',
          'Please fill required field',
        );
        return;
      }

      /// AUTO GENERATE PASSWORD
      final generatedPassword = generatePassword();

      /// CREATE ACCOUNT
      final credential = await auth.createUserWithEmailAndPassword(
        email: emailC.text.trim(),
        password: generatedPassword,
      );

      /// AUTO VERIFY EMAIL
      await verifyEmail(
        uid: credential.user!.uid,
        email: emailC.text.trim(),
        password: generatedPassword,
        username: usernameC.text.trim(),
      );

      /// SAVE FIRESTORE
      await firestore.collection('users').doc(credential.user!.uid).set({
        'id': credential.user!.uid,
        'username': usernameC.text.trim(),
        'email': emailC.text.trim(),
        'sn': snC.text.trim(),
        'id_site': homeState.userAccessId.value,
        'id_company': allSites
            .firstWhere((site) => site.idSite == homeState.userAccessId.value)
            .idCompany,
        'position': positionC.text.trim(),
        'age': int.tryParse(ageC.text.trim()) ?? 0,
        'created_at': DateTime.now().toString(),
        'image': 'image',
        'is_verified': false,
      });

      clearForm();

      Get.back();

      /// SHOW GENERATED PASSWORD
      Get.defaultDialog(
        title: 'User Created',
        middleText:
            'Temporary Password:\n\n$generatedPassword\n\nPlease save this password.',
        textConfirm: 'OK',
        onConfirm: () {
          Get.back();
        },
      );
    } on FirebaseAuthException catch (e) {
      Get.snackbar(
        'Error',
        e.message ?? '',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verifyEmail({
    required String uid,
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://verifyuseremail-yr2ee7dizq-as.a.run.app',
        ),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'uid': uid,
          'email': email,
          'password': password,
          'username': username,
        }),
      );

      debugPrint(response.body);
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void clearForm() {
    usernameC.clear();
    emailC.clear();
    snC.clear();
    positionC.clear();
    ageC.clear();
  }

  @override
  void onClose() {
    usernameC.dispose();
    emailC.dispose();
    snC.dispose();
    positionC.dispose();
    ageC.dispose();

    super.onClose();
  }

  String generatePassword() {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';

    final random = Random();

    return List.generate(
      8,
      (index) => chars[random.nextInt(chars.length)],
    ).join();
  }
}
