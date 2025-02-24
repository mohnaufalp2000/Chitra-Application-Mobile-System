import 'dart:developer';
import 'dart:io';

import 'package:camos/core/blocs/attendance/attendance_bloc.dart';
import 'package:camos/core/blocs/authentication/authentication_bloc.dart';
import 'package:camos/core/blocs/site/site_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/local_database/attendance/attendance_entity.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/text_button_widget.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:camos/pages/attendance/all_presence_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:uuid/uuid.dart';

class AttendancePage extends StatefulWidget {
  static const routeName = '/attendance-page';
  const AttendancePage({super.key});

  @override
  State<AttendancePage> createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String site = '';
  final Box<AttendanceEntity> attendanceBox = store.box<AttendanceEntity>();

  Stream<DocumentSnapshot<Map<String, dynamic>>> todayPresence() async* {
    String uid = firebaseAuth.currentUser!.uid;

    String todayId =
        DateFormat.yMd().format(DateTime.now()).replaceAll('/', '-');

    DateTime now = DateTime.now();
    TimeOfDay targetTime = TimeOfDay(hour: (16), minute: 0);

    yield* firestore
        .collection('users')
        .doc(uid)
        .collection('presensi')
        .doc(todayId)
        .snapshots();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAuth auth = FirebaseAuth.instance;
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: appBarWidget('Attendance Page', context),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: BlocListener<AttendanceBloc, AttendanceState>(
          listener: (context, state) {
            if (state is AttendanceErrorState) {
              if (state.isAlreadyPresence!) {
                // error jika memaksa absen di hari yang sama
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    'You\'ve done check-in and check-out',
                    style: getWhiteTextStyle(fontWeight: w700),
                  ),
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(bottom: 32),
                  backgroundColor: Colors.red,
                ));
              }
            }

            if (state is AttendanceSaveCsvLoadingState) {
              // loading save csv
              showDialog(
                  barrierDismissible: false,
                  context: context,
                  builder: (_) {
                    return Dialog(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(
                              'Please Wait...',
                              style: getBlackTextStyle(),
                            )
                          ],
                        ),
                      ),
                    );
                  });
            }

            if (state is AttendanceSuccessSaveCsvState) {
              back(context);
            }
          },
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: StreamBuilder(
                stream: firestore
                    .collection('users')
                    .where('email', isEqualTo: auth.currentUser!.email)
                    .snapshots(),
                builder: (context, snapshot) {
                  Map<String, dynamic> map = {};

                  snapshot.data?.docs.forEach(
                    (element) {
                      map = element.data();
                    },
                  );

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }
                  context
                      .read<SiteBloc>()
                      .add(GetSiteEvent(idSite: map['id_site'] ?? ''));
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(
                        height: 12,
                      ),
                      InkWell(
                        onTap: () async {
                          log('kehadiran : ${attendanceBox.getAll()}');
                        },
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  green00968A,
                                  blue344BEF,
                                ]),
                                borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  backgroundImage: (map['image'] == '' ||
                                          map['image'] == null ||
                                          map['image'] == 'image')
                                      ? AssetImage(
                                              '$imagePath/default_user_image.png')
                                          as ImageProvider
                                      : NetworkImage(map['image']),
                                  backgroundColor: Colors.grey.withOpacity(0.4),
                                  radius: 50,
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                Text(
                                  map['username'],
                                  style: getWhiteTextStyle(
                                    fontSize: 24,
                                    fontWeight: w700,
                                  ),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                Text(
                                  map['position'],
                                  style: getWhiteTextStyle(fontSize: 16),
                                ),
                                const SizedBox(
                                  height: 6,
                                ),
                                BlocBuilder<SiteBloc, SiteState>(
                                  builder: (context, state) {
                                    if (state is SiteOneLoadedState) {
                                      site = state.site.site ?? '';
                                      return Text(
                                        state.site.site ?? '',
                                        style: getWhiteTextStyle(fontSize: 16),
                                      );
                                    }
                                    return Container();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      StreamBuilder(
                          stream: firestore
                              .collection('users')
                              .doc(firebaseAuth.currentUser!.uid)
                              .collection('presensi')
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Container();
                            }

                            return ButtonWidget(
                                name: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.table_view),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    Text(
                                      'Save',
                                      style: getWhiteTextStyle(),
                                    ),
                                  ],
                                ),
                                color: Colors.blue,
                                function: () async {
                                  context.read<AttendanceBloc>().add(
                                      SaveCsvAttendanceEvent(
                                          username: map['username'],
                                          position: map['position'],
                                          sn: map['sn'],
                                          site: site,
                                          presence: snapshot.data?.docs));
                                });
                          }),

                      const SizedBox(
                        height: 24,
                      ),
                      Text(
                        'Today Presence',
                        style: getBlackTextStyle(
                          fontWeight: w700,
                        ),
                      ),
                      const SizedBox(
                        height: 24,
                      ),
                      Card(
                        color: grey8391A1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [
                                green00968A,
                                blue344BEF,
                              ]),
                              borderRadius: BorderRadius.circular(16)),
                          child: StreamBuilder(
                              stream: todayPresence(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container();
                                }
                                Map<String, dynamic>? dataToday =
                                    snapshot.data?.data();
                                if (dataToday?['masuk'] == null) {
                                  return Center(
                                    child: Text(
                                      'You haven\'t done attendance today',
                                      style:
                                          getWhiteTextStyle(fontWeight: w700),
                                    ),
                                  );
                                } else {
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Check-in',
                                            style: getWhiteTextStyle(),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (dataToday?['masuk'] == null)
                                                    ? '-'
                                                    : '${DateFormat.yMMMMEEEEd().format(DateTime.parse(dataToday?['masuk']['date']))}',
                                                style: getWhiteTextStyle(),
                                              ),
                                              Text(
                                                (dataToday?['masuk'] == null)
                                                    ? '-'
                                                    : '${DateFormat.Hms().format(DateTime.parse(dataToday?['masuk']['date']))}',
                                                style: getWhiteTextStyle(),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Divider(
                                          thickness: 2,
                                          color: white,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Check-out',
                                            style: getWhiteTextStyle(),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                (dataToday?['keluar'] == null)
                                                    ? '-'
                                                    : '${DateFormat.yMMMMEEEEd().format(DateTime.parse(dataToday?['keluar']['date']))}',
                                                style: getWhiteTextStyle(),
                                              ),
                                              Text(
                                                (dataToday?['keluar'] == null)
                                                    ? '-'
                                                    : '${DateFormat.Hms().format(DateTime.parse(dataToday?['keluar']['date']))}',
                                                style: getWhiteTextStyle(),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                    ],
                                  );
                                  // return Row(
                                  //   mainAxisAlignment:
                                  //       MainAxisAlignment.spaceAround,
                                  //   children: [
                                  //     Column(
                                  //       children: [
                                  //         Text(
                                  //           'Check-in',
                                  //           style: getWhiteTextStyle(),
                                  //         ),
                                  //         const SizedBox(
                                  //           height: 12,
                                  //         ),
                                  //         Text(
                                  //           (dataToday?['masuk'] == null)
                                  //               ? '-'
                                  //               : '${DateFormat.Hms().format(DateTime.parse(dataToday?['masuk']['date']))}',
                                  //           style: getWhiteTextStyle(),
                                  //         )
                                  //       ],
                                  //     ),
                                  //     Container(
                                  //       width: 2,
                                  //       height: 20,
                                  //       color: white,
                                  //     ),
                                  //     Column(
                                  //       children: [
                                  //         Text(
                                  //           'Check-out',
                                  //           style: getWhiteTextStyle(),
                                  //         ),
                                  //         const SizedBox(
                                  //           height: 12,
                                  //         ),
                                  //         Text(
                                  //           (dataToday?['keluar'] == null)
                                  //               ? '-'
                                  //               : '${DateFormat.Hms().format(DateTime.parse(dataToday?['keluar']['date']))}',
                                  //           style: getWhiteTextStyle(),
                                  //         )
                                  //       ],
                                  //     ),
                                  //   ],
                                  // );
                                }
                              }),
                        ),
                      ),
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(vertical: 12.0),
                      //   child: Divider(
                      //     thickness: 2,
                      //   ),
                      // ),
                      // Row(
                      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      //   children: [
                      //     Text(
                      //       'Last 5 Days',
                      //       style: getBlackTextStyle(
                      //         fontWeight: w700,
                      //       ),
                      //     ),
                      //     TextButtonWidget(
                      //         name: 'See more',
                      //         style: getGreenTextStyle(),
                      //         function: () {
                      //           push(context, AllPresencePage.routeName);
                      //         }),
                      //   ],
                      // ),
                      // const SizedBox(
                      //   height: 12,
                      // ),
                      // StreamBuilder(
                      //     stream: firestore
                      //         .collection('users')
                      //         .doc(firebaseAuth.currentUser!.uid)
                      //         .collection('presensi')
                      //         .orderBy('date', descending: true)
                      //         .limitToLast(5)
                      //         .snapshots(),
                      //     builder: (context, snapshot) {
                      //       if (snapshot.connectionState ==
                      //           ConnectionState.waiting) {
                      //         return Container();
                      //       }

                      //       if (snapshot.data!.docs.isEmpty) {
                      //         return Container(
                      //           margin: EdgeInsets.only(
                      //               top: MediaQuery.of(context).size.height *
                      //                   0.1),
                      //           child: Center(
                      //             child: Text(
                      //               'There is no history presence',
                      //               style: getBlackTextStyle(),
                      //             ),
                      //           ),
                      //         );
                      //       }

                      //       return ListView.builder(
                      //           shrinkWrap: true,
                      //           physics: NeverScrollableScrollPhysics(),
                      //           itemCount: snapshot.data!.docs.length,
                      //           itemBuilder: (context, index) {
                      //             Map<String, dynamic> data =
                      //                 snapshot.data!.docs[index].data();
                      //             return Card(
                      //               elevation: 2,
                      //               shape: RoundedRectangleBorder(
                      //                 borderRadius: BorderRadius.circular(16),
                      //               ),
                      //               child: Container(
                      //                 padding: EdgeInsets.all(12),
                      //                 decoration: BoxDecoration(
                      //                     gradient:
                      //                         const LinearGradient(colors: [
                      //                       green00968A,
                      //                       blue344BEF,
                      //                     ]),
                      //                     borderRadius:
                      //                         BorderRadius.circular(16)),
                      //                 child: Column(
                      //                   crossAxisAlignment:
                      //                       CrossAxisAlignment.start,
                      //                   children: [
                      //                     Row(
                      //                       mainAxisAlignment:
                      //                           MainAxisAlignment.spaceBetween,
                      //                       children: [
                      //                         Text(
                      //                           'In',
                      //                           style: getWhiteTextStyle(
                      //                               fontWeight: w700),
                      //                         ),
                      //                         Text(
                      //                           DateFormat.yMMMMEEEEd().format(
                      //                               DateTime.parse(
                      //                                   data['date'])),
                      //                           style: getWhiteTextStyle(
                      //                             fontWeight: w700,
                      //                           ),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                     Text(
                      //                       data['masuk']?['date'] == null
                      //                           ? '-'
                      //                           : '${DateFormat.Hms().format(DateTime.parse(data['masuk']['date']))}',
                      //                       style: getWhiteTextStyle(),
                      //                     ),
                      //                     const SizedBox(
                      //                       height: 10,
                      //                     ),
                      //                     Text(
                      //                       'Out',
                      //                       style: getWhiteTextStyle(
                      //                           fontWeight: w700),
                      //                     ),
                      //                     Text(
                      //                       data['keluar']?['date'] == null
                      //                           ? '-'
                      //                           : '${DateFormat.Hms().format(DateTime.parse(data['keluar']['date']))}',
                      //                       style: getWhiteTextStyle(),
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ),
                      //             );
                      //           });
                      //     }),

                      const SizedBox(
                        height: 32,
                      ),
                    ],
                  );
                }),
          ),
        ),
      )),
      bottomNavigationBar: ConvexAppBar(
        items: [TabItem(icon: Icons.fingerprint, title: 'Presence')],
        initialActiveIndex: 0,
        onTap: (index) async {
          if (index == 0) {
            showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Attendance Confirmation',
                          style: getBlackTextStyle(
                            fontSize: 16,
                            fontWeight: w600,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Text(
                          'Are you sure you want to take presence?',
                          style: getBlackTextStyle(),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                          onPressed: () {
                            back(context);
                          },
                          child: Text(
                            'No',
                            style: getGreyTextStyle(grey8391A1),
                          )),
                      TextButton(
                          onPressed: () async {
                            // back(context);

                            // context.read<AttendanceBloc>().add(
                            //     PresenceAttendanceEvent(
                            //         context: context,
                            //         selectedShift: selectedShift));
                          },
                          child: BlocConsumer<AttendanceBloc, AttendanceState>(
                            listener: (context, state) {
                              if (state is AttendanceSuccessPresenceState) {
                                back(context);
                              }
                            },
                            builder: (context, state) {
                              // if (state is AttendancePresenceLoadingState) {
                              //   return Row(
                              //     mainAxisSize: MainAxisSize.min,
                              //     children: [
                              //       CircularProgressIndicator(),
                              //       const SizedBox(
                              //         width: 6,
                              //       ),
                              //       Text(
                              //         'Please Wait',
                              //         style: getBlackTextStyle(),
                              //       )
                              //     ],
                              //   );
                              // }

                              if (state is AttendanceSuccessPresenceState) {
                                return Text('Yes');
                              }
                              return Text('Yes');
                            },
                          )),
                    ],
                  );
                });
          }
        },
      ),
    );
  }
}
