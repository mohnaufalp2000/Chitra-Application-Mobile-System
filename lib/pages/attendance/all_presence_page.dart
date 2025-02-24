// import 'package:camos/core/styles/color.dart';
// import 'package:camos/core/styles/text_manager.dart';
// import 'package:camos/core/widgets/appbar_widget.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';

// class AllPresencePage extends StatefulWidget {
//   static const routeName = '/all-presence-page';
//   const AllPresencePage({super.key});

//   @override
//   State<AllPresencePage> createState() => _AllPresencePageState();
// }

// class _AllPresencePageState extends State<AllPresencePage> {
//   FirebaseAuth auth = FirebaseAuth.instance;
//   FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

//   @override
//   Widget build(BuildContext context) {
//     final String uid = auth.currentUser!.uid;

//     return Scaffold(
//       appBar: appBarWidget('All Presence', context),
//       body: SafeArea(
//           child: SingleChildScrollView(
//         child: Padding(
//           padding: EdgeInsets.all(24),
//           child: StreamBuilder(
//               stream: firebaseFirestore
//                   .collection('users')
//                   .doc(uid)
//                   .collection('presensi')
//                   .orderBy('date', descending: true)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return Center(
//                     child: CircularProgressIndicator(),
//                   );
//                 }

//                 if (snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: Text(
//                       'There is no history presence',
//                       style: getBlackTextStyle(),
//                     ),
//                   );
//                 }
//                 return ListView.builder(
//                     shrinkWrap: true,
//                     physics: NeverScrollableScrollPhysics(),
//                     itemCount: snapshot.data?.docs.length,
//                     itemBuilder: (context, index) {
//                       Map<String, dynamic> data =
//                           snapshot.data?.docs[index].data() ?? {};

//                       return Card(
//                         elevation: 2,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         child: Container(
//                           padding: EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                               gradient: const LinearGradient(colors: [
//                                 green00968A,
//                                 blue344BEF,
//                               ]),
//                               borderRadius: BorderRadius.circular(16)),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Row(
//                                 mainAxisAlignment:
//                                     MainAxisAlignment.spaceBetween,
//                                 children: [
//                                   Text(
//                                     'In',
//                                     style: getWhiteTextStyle(fontWeight: w700),
//                                   ),
//                                   Text(
//                                     DateFormat.yMMMMEEEEd()
//                                         .format(DateTime.parse(data['date'])),
//                                     style: getWhiteTextStyle(
//                                       fontWeight: w700,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               Text(
//                                 data['masuk']?['date'] == null
//                                     ? '-'
//                                     : '${DateFormat.Hms().format(DateTime.parse(data['masuk']['date']))}',
//                                 style: getWhiteTextStyle(),
//                               ),
//                               const SizedBox(
//                                 height: 10,
//                               ),
//                               Text(
//                                 'Out',
//                                 style: getWhiteTextStyle(fontWeight: w700),
//                               ),
//                               Text(
//                                 data['keluar']?['date'] == null
//                                     ? '-'
//                                     : '${DateFormat.Hms().format(DateTime.parse(data['keluar']['date']))}',
//                                 style: getWhiteTextStyle(),
//                               ),
//                             ],
//                           ),
//                         ),
//                       );
//                     });
//               }),
//         ),
//       )),
//     );
//   }
// }
import 'package:camos/core/services/local_database/attendance/attendance_entity.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutterflow_paginate_firestore/paginate_firestore.dart';
import 'package:intl/intl.dart';

class AllPresencePage extends StatefulWidget {
  static const routeName = '/all-presence-page';
  const AllPresencePage({super.key});

  @override
  State<AllPresencePage> createState() => _AllPresencePageState();
}

class _AllPresencePageState extends State<AllPresencePage> {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  final Box<AttendanceEntity> attendanceBox = store.box<AttendanceEntity>();

  @override
  Widget build(BuildContext context) {
    final String uid = auth.currentUser!.uid;

    return Scaffold(
      appBar: appBarWidget('All Presence', context),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: PaginateFirestore(
            query: firebaseFirestore
                .collection('users')
                .doc(uid)
                .collection('presensi')
                .orderBy('date',
                    descending: true), // Sesuai kebutuhan, bisa ubah orderBy
            itemBuilderType: PaginateBuilderType.listView,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemsPerPage: 5,
            isLive: true,
            initialLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            bottomLoader:
                const Center(child: CircularProgressIndicator.adaptive()),
            onEmpty: Center(
              child: Text(
                'There is no data',
                style: getWhiteTextStyle(fontWeight: w700),
              ),
            ),
            itemBuilder: (context, snapshot, firebaseIndex) {
              final presence =
                  snapshot[firebaseIndex].data() as Map<String, dynamic>;

              return Card(
                color: grey8391A1,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 2,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [green00968A, blue344BEF],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'In',
                            style: getWhiteTextStyle(fontWeight: w700),
                          ),
                          Text(
                            DateFormat.yMMMMEEEEd()
                                .format(DateTime.parse(presence['date'])),
                            style: getWhiteTextStyle(fontWeight: w700),
                          ),
                        ],
                      ),
                      Text(
                        presence['masuk'] == null
                            ? '-'
                            : DateFormat.Hms().format(
                                DateTime.parse(presence['masuk']['date'])),
                        style: getWhiteTextStyle(),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Out',
                        style: getWhiteTextStyle(fontWeight: w700),
                      ),
                      Text(
                        presence['keluar'] == null
                            ? '-'
                            : DateFormat.Hms().format(
                                DateTime.parse(presence['keluar']['date'])),
                        style: getWhiteTextStyle(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      )),
    );
  }
}
