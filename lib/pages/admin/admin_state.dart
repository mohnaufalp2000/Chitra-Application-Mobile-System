import 'dart:async';
import 'dart:developer';

import 'package:camos/pages/home/home_state.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AdminState extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final RxList<UserModel> users = <UserModel>[].obs;

  final RxList<UserModel> allUsers = <UserModel>[].obs;

  final TextEditingController searchC = TextEditingController();

  final HomeState homeState = Get.find<HomeState>();

  StreamSubscription? userListener;

  @override
  void onInit() {
    super.onInit();
    ever(
      homeState.currentSiteIdRx,
      (value) {
        getUsers();
      },
    );

    getUsers();
  }

  @override
  void onClose() {
    userListener?.cancel();
    searchC.dispose();

    super.onClose();
  }

  void getUsers() {
    userListener?.cancel();
    print('site changed : ${homeState.currentSiteIdRx.value}');

    userListener = firestore
        .collection('users')
        .where(
          'id_site',
          isEqualTo: homeState.currentSiteIdRx.value,
        )
        .snapshots()
        .listen((event) {
      final data = event.docs.map((doc) {
        return UserModel.fromJson(doc.data());
      }).toList();

      allUsers.value = data;
      users.value = data;

      log('user admin : $users');
    });
  }

  void searchUser(String value) {
    if (value.isEmpty) {
      users.value = allUsers;
      return;
    }

    final keyword = value.toLowerCase();

    users.value = allUsers.where((user) {
      final username = user.username.toLowerCase();
      final email = user.email.toLowerCase();
      final sn = user.sn.toLowerCase();

      return username.contains(keyword) ||
          email.contains(keyword) ||
          sn.contains(keyword);
    }).toList();
  }
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final String sn;
  final String idSite;
  final String position;
  final int age;
  final String createdAt;
  final String image;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.sn,
    required this.idSite,
    required this.position,
    required this.age,
    required this.createdAt,
    required this.image,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      sn: json['sn'] ?? '',
      idSite: json['id_site'] ?? '',
      position: json['position'] ?? '',
      age: json['age'] ?? 0,
      createdAt: json['created_at'] ?? '',
      image: json['image'] ?? '',
    );
  }
}
