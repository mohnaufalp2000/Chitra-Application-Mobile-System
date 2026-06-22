// import 'dart:async';
// import 'dart:developer';

// import 'package:camos/core/utils/data/user_model.dart';
// import 'package:camos/pages/home/home_state.dart';
// import 'package:flutter/widgets.dart';
// import 'package:get/get.dart';

// import 'package:cloud_firestore/cloud_firestore.dart';

// class AdminState extends GetxController {
//   final FirebaseFirestore firestore = FirebaseFirestore.instance;

//   final RxList<UserModel> users = <UserModel>[].obs;

//   final RxList<UserModel> allUsers = <UserModel>[].obs;

//   final TextEditingController searchC = TextEditingController();

//   final HomeState homeState = Get.find<HomeState>();

//   StreamSubscription? userListener;

//   @override
//   void onInit() {
//     super.onInit();
//     print('site changed : ${homeState.userAccessId.value}');

//     ever(
//       homeState.userAccessId,
//       (value) {
//         getUsers();
//       },
//     );

//     getUsers();
//   }

//   @override
//   void onClose() {
//     userListener?.cancel();
//     searchC.dispose();

//     super.onClose();
//   }

//   void getUsers() {
//     try {
//       userListener?.cancel();
//       print('site changed 2 : ${homeState.userAccessId.value}');

//       userListener = firestore
//           .collection('users')
//           .where(
//             'id_site',
//             isEqualTo: homeState.userAccessId.value,
//           )
//           .snapshots()
//           .listen((event) {
//         print('Jumlah docs: ${event.docs.length}');

//         final data = event.docs.map((doc) {
//           return UserModel.fromJson(doc.data());
//         }).toList();

//         allUsers.value = data;
//         users.value = data;

//         log('user admin : $data');
//       });
//     } catch (e) {
//       log('error users admin : $e');
//     }
//   }

//   void searchUser(String value) {
//     if (value.isEmpty) {
//       users.value = allUsers;
//       return;
//     }

//     final keyword = value.toLowerCase();

//     users.value = allUsers.where((user) {
//       final username = user.username.toLowerCase();
//       final email = user.email.toLowerCase();
//       final sn = user.sn.toLowerCase();

//       return username.contains(keyword) ||
//           email.contains(keyword) ||
//           sn.contains(keyword);
//     }).toList();
//   }
// }

import 'dart:async';
import 'dart:developer';

import 'package:camos/core/utils/data/id_site.dart';
import 'package:camos/pages/home/home_state.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminState extends GetxController {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> allUsers = <Map<String, dynamic>>[].obs;

  final TextEditingController searchC = TextEditingController();

  final HomeState homeState = Get.find<HomeState>();

  StreamSubscription? userListener;

  @override
  void onInit() {
    super.onInit();

    ever(homeState.userAccessId, (_) {
      getUsers();
    });

    getUsers();
  }

  @override
  void onClose() {
    userListener?.cancel();
    searchC.dispose();
    super.onClose();
  }

  void getUsers() {
    try {
      userListener?.cancel();

      final siteId = homeState.userAccessId.value;
      print("siteId = $siteId");

      userListener = firestore
          .collection('users')
          .where('id_site', isEqualTo: siteId)
          .snapshots()
          .listen((event) {
        print("Jumlah docs = ${event.docs.length}");

        final data = event.docs
            .map((doc) {
              final map = doc.data();
              map['doc_id'] = doc.id;
              return map;
            })
            .where((user) => user['isDelete'] != true)
            .where((user) =>
                user['id_company'] ==
                allSites
                    .firstWhere(
                        (site) => site.idSite == homeState.userAccessId.value)
                    .idCompany)
            .toList();

        log('user baru $data');

        users.value = data;
        allUsers.value = data;
      });
    } catch (e) {
      log("error = $e");
    }
  }

  Future<void> softDeleteUser(String docId) async {
    print('selected delete docId : $docId');
    try {
      await firestore.collection('users').doc(docId).set({
        'isDelete': true,
        'deletedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      log(e.toString());
    }
  }

  void searchUser(String value) {
    if (value.isEmpty) {
      users.value = allUsers;
      return;
    }

    final keyword = value.toLowerCase();

    users.value = allUsers.where((user) {
      final username = (user['username'] ?? '').toString().toLowerCase();

      final email = (user['email'] ?? '').toString().toLowerCase();

      final sn = (user['sn'] ?? '').toString().toLowerCase();

      return username.contains(keyword) ||
          email.contains(keyword) ||
          sn.contains(keyword);
    }).toList();
  }
}
