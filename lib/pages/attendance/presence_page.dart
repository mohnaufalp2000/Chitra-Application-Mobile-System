import 'dart:async';
import 'dart:developer';

import 'package:camos/core/blocs/attendance/attendance_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/local_database/attendance/attendance_entity.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/services/sheets/attendance_sheets.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/core/widgets/text_button_widget.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:camos/pages/attendance/all_presence_page.dart';
import 'package:camos/pages/attendance/presence_camera_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PresencePage extends StatefulWidget {
  static const routeName = '/presence-page';
  const PresencePage({super.key});

  @override
  State<PresencePage> createState() => _PresencePageState();
}

class _PresencePageState extends State<PresencePage> {
  final Box<AttendanceEntity> attendanceBox = store.box<AttendanceEntity>();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  String selectedShift = 'morning';
  int selectedDate = -1;
  List<Map<int, dynamic>> generalDate = [
    {1: 'January'},
    {2: 'February'},
    {3: 'March'},
    {4: 'April'},
    {5: 'May'},
    {6: 'June'},
    {7: 'July'},
    {8: 'August'},
    {9: 'September'},
    {10: 'October'},
    {11: 'November'},
    {12: 'December'},
  ];

  Stream<List<AttendanceEntity>>? attendanceStream;

  Future<List<dynamic>> fetchBothData() async {
    final result = await Future.wait([
      getUserPreferences(),
      getIdSitePreferences(),
    ]);
    return result;
  }

  Map<String, dynamic> user = {};
  String idSite = '';
  List<String> dates = [];

  TextEditingController infoCheckInCtrl = TextEditingController();
  TextEditingController infoCheckOutCtrl = TextEditingController();

  String InfoCheckIn = '';
  String InfoCheckOut = '';

  AttendanceEntity? isPresenceToday;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now().month;

    retrieveUser();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> todayPresence() async* {
    String uid = firebaseAuth.currentUser!.uid;

    String todayId =
        DateFormat.yMd().format(DateTime.now()).replaceAll('/', '-');
    yield* firestore
        .collection('users')
        .doc(uid)
        .collection('presensi')
        .doc(todayId)
        .snapshots();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> getYesterdayPresence() async {
    String uid = firebaseAuth.currentUser!.uid;

    // Ambil tanggal kemarin dalam format yang sesuai
    String yesterdayId = DateFormat.yMd()
        .format(DateTime.now().subtract(Duration(days: 1)))
        .replaceAll('/', '-');

    return await firestore
        .collection('users')
        .doc(uid)
        .collection('presensi')
        .doc(yesterdayId)
        .get();
  }

  Future<void> retrieveUser() async {
    user = await getUserPreferences();
    idSite = await getIdSitePreferences();
    log(user.toString());
    // {image: image, id_site: 1, position: Innovation, sn: 72618, email: naufaldev2000@gmail.com, age: 23, username: Naufal, siteName: CK-MIFA Mining}
  }

  void showAddInfoDialog(String type) {
    // Check data on database offline to add additional info

    log('data absen hari ini : $isPresenceToday');

    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add Additional Info',
                  style: getBlackTextStyle(
                    fontSize: 16,
                    fontWeight: w600,
                  ),
                ),
                const SizedBox(
                  height: 6,
                ),
                Text(
                  'Please fill in the information if you arrive late, leave later, or are outside the office.',
                  style: getGreyTextStyle(
                    grey6A707C,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                SizedBox(
                  width: double.infinity,
                  child: InputFormWidget(
                      controller: (type == 'check-in')
                          ? infoCheckInCtrl
                          : infoCheckOutCtrl,
                      hint: 'Type Here...'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    back(context);
                  },
                  child: Text(
                    'Cancel',
                    style: getGreyTextStyle(grey8391A1),
                  )),
              TextButton(
                  onPressed: () async {
                    if (isPresenceToday != null) {
                      Navigator.pop(context);

                      if (type == 'check-in') {
                        isPresenceToday?.keteranganMasuk = infoCheckInCtrl.text;
                        InfoCheckIn = infoCheckInCtrl.text;
                        try {
                          final id =
                              await AttendanceSheetsAPI.getSingleDataAttendance(
                                  user['sn'],
                                  DateFormat('MM-dd-yyyy')
                                      .format(DateTime.now()));
                          await AttendanceSheetsAPI.updateAttendanceCell(
                              id: int.parse(id ?? ''),
                              key: 'Keterangan_Masuk',
                              value: infoCheckInCtrl.text);
                        } catch (e) {
                          print('error spreadsheet di page : $e');
                        }
                      } else {
                        isPresenceToday?.keteranganKeluar =
                            infoCheckOutCtrl.text;
                        InfoCheckOut = infoCheckOutCtrl.text;
                        try {
                          final id =
                              await AttendanceSheetsAPI.getSingleDataAttendance(
                                  user['sn'],
                                  DateFormat('MM-dd-yyyy')
                                      .format(DateTime.now()));
                          await AttendanceSheetsAPI.updateAttendanceCell(
                              id: int.parse(id ?? ''),
                              key: 'Keterangan_Pulang',
                              value: infoCheckOutCtrl.text);
                        } catch (e) {
                          print('error spreadsheet di page : $e');
                        }
                      }
                      attendanceBox.put(isPresenceToday!);
                      setState(() {});
                    }
                    // setState(() async {
                    //   log('apakah data kosong : ${isPresenceToday == null}');
                    //   if (isPresenceToday != null) {
                    //     if (type == 'check-in') {
                    //       isPresenceToday?.keteranganMasuk =
                    //           infoCheckInCtrl.text;
                    //       InfoCheckIn = infoCheckInCtrl.text;
                    //       try {
                    //         final id = await AttendanceSheetsAPI
                    //             .getSingleDataAttendance(
                    //                 user['username'],
                    //                 DateFormat('MM-dd-yyyy')
                    //                     .format(DateTime.now()));
                    //         await AttendanceSheetsAPI.updateAttendanceCell(
                    //             id: int.parse(id ?? ''),
                    //             key: 'Keterangan_Masuk',
                    //             value: infoCheckInCtrl.text);
                    //       } catch (e) {
                    //         print('error spreadsheet di page : $e');
                    //       }
                    //     } else {
                    //       isPresenceToday?.keteranganKeluar =
                    //           infoCheckOutCtrl.text;
                    //       InfoCheckOut = infoCheckOutCtrl.text;
                    //       try {
                    //         final id = await AttendanceSheetsAPI
                    //             .getSingleDataAttendance(
                    //                 user['username'],
                    //                 DateFormat('MM-dd-yyyy')
                    //                     .format(DateTime.now()));
                    //         await AttendanceSheetsAPI.updateAttendanceCell(
                    //             id: int.parse(id ?? ''),
                    //             key: 'Keterangan_Pulang',
                    //             value: infoCheckOutCtrl.text);
                    //       } catch (e) {
                    //         print('error spreadsheet di page : $e');
                    //       }
                    //     }
                    //     attendanceBox.put(isPresenceToday!);
                    //   }
                    // });
                  },
                  child: Text('Save')),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Attendance Page', context),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocConsumer<AttendanceBloc, AttendanceState>(
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
            },
            builder: (context, state) {
              return FutureBuilder(
                  future: fetchBothData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator()); // Loading state
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text(
                              'Error: ${snapshot.error}')); // Error handling
                    }

                    // Ambil data dari snapshot
                    user = snapshot.data![0];
                    idSite = snapshot.data![1];
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        profileCard(),
                        const SizedBox(
                          height: 12,
                        ),
                        // Container(
                        //   height:
                        //       50.0, // Sesuaikan tinggi container sesuai kebutuhan
                        //   child: ListView.builder(
                        //     scrollDirection: Axis.horizontal,
                        //     itemCount: generalDate.length,
                        //     itemBuilder: (BuildContext context, int index) {
                        //       return Padding(
                        //         padding: EdgeInsets.symmetric(horizontal: 8.0),
                        //         child: ElevatedButton(
                        //           onPressed: () {
                        //             setState(() {
                        //               selectedDate =
                        //                   generalDate[index].keys.first;
                        //             });
                        //           },
                        //           style: ElevatedButton.styleFrom(
                        //               shape: RoundedRectangleBorder(
                        //                   borderRadius:
                        //                       BorderRadius.circular(6)),
                        //               backgroundColor: (selectedDate ==
                        //                       generalDate[index].keys.first)
                        //                   ? Colors.orange
                        //                   : Colors.white70,
                        //               padding: EdgeInsets.all(12.0)),
                        //           child: Text(
                        //             generalDate[index].values.first,
                        //             style: TextStyle(
                        //                 color: (selectedDate ==
                        //                         generalDate[index].keys.first)
                        //                     ? white
                        //                     : black,
                        //                 fontSize: 18.0),
                        //           ),
                        //         ),
                        //       );
                        //     },
                        //   ),
                        // ),
                        // const SizedBox(
                        //   height: 12,
                        // ),
                        // buttonSave(),
                        const SizedBox(
                          height: 24,
                        ),
                        todayPresenceCard(),
                        const SizedBox(
                          height: 24,
                        ),
                        historyPresence(),
                      ],
                    );
                  });
            },
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
                        child: Text('Yes'),
                        onPressed: () async {
                          requestCameraPermission();
                          // Navigator.pop(context);
                          // Navigator.pushNamed(
                          //     context, PresenceCameraPage.routeName,
                          //     arguments: {'selectedShift': selectedShift});
                          context.read<AttendanceBloc>().add(
                              PresenceAttendanceEvent(
                                  context: context,
                                  user: user,
                                  selectedShift: selectedShift));
                          back(context);
                        },
                      ),
                    ],
                  );
                });
          }
        },
      ),
    );
  }

  Column todayPresenceCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Today Presence',
          style: getBlackTextStyle(
            fontWeight: w700,
          ),
        ),
        const SizedBox(
          height: 12,
        ),
        Card(
          color: grey8391A1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  }
                  Map<String, dynamic>? dataToday = snapshot.data?.data();
                  if (dataToday?['masuk'] == null) {
                    return Center(
                      child: Text(
                        'You haven\'t done attendance today',
                        style: getWhiteTextStyle(fontWeight: w700),
                      ),
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-in',
                              style: getWhiteTextStyle(),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Divider(
                            thickness: 2,
                            color: white,
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check-out',
                              style: getWhiteTextStyle(),
                            ),
                            const SizedBox(
                              height: 12,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                  }
                }),
          ),
        )
      ],
    );
  }

  Column historyPresence() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'History',
              style: getBlackTextStyle(
                fontWeight: w700,
              ),
            ),
            TextButtonWidget(
                name: 'See All',
                style: getGreenTextStyle(fontWeight: w700),
                function: () {
                  Navigator.pushNamed(context, AllPresencePage.routeName);
                })
          ],
        ),
        const SizedBox(
          height: 12,
        ),
        FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: getYesterdayPresence(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                  child: Container(
                margin: EdgeInsets.only(bottom: 18),
                child: Text(
                  "There is no data attendance yesterday",
                  style: getBlackTextStyle(),
                ),
              ));
            }

            var presence = snapshot.data!.data();

            return Card(
              color: grey8391A1,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 2,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [green00968A, blue344BEF]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('In', style: getWhiteTextStyle(fontWeight: w700)),
                        Text(
                          DateFormat.yMMMMEEEEd().format(DateTime.parse(
                              presence?['date'] ?? DateTime.now().toString())),
                          style: getWhiteTextStyle(fontWeight: w700),
                        ),
                      ],
                    ),
                    Text(
                      presence?['masuk']['date'] == null ||
                              presence?['masuk']['date'] == ''
                          ? '-'
                          : '${DateFormat.Hms().format(DateTime.parse(presence?['masuk']['date']))}',
                      style: getWhiteTextStyle(),
                    ),
                    const SizedBox(height: 10),
                    Text('Out', style: getWhiteTextStyle(fontWeight: w700)),
                    Text(
                      presence?['keluar']['date'] == null ||
                              presence?['keluar']['date'] == ''
                          ? '-'
                          : '${DateFormat.Hms().format(DateTime.parse(presence?['keluar']['date']))}',
                      style: getWhiteTextStyle(),
                    ),
                  ],
                ),
              ),
            );
          },
        )
      ],
    );
  }

  ButtonWidget buttonSave() {
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
        function: (selectedDate == -1)
            ? null
            : () async {
                context.read<AttendanceBloc>().add(SaveCsvPresenceEvent(
                    username: user['username'] ?? '',
                    position: user['position'] ?? '',
                    sn: user['sn'] ?? '',
                    site: (idSite == '1') ? 'Office' : user['siteName'],
                    date: selectedDate,
                    presence: attendanceBox.getAll()));
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: green00968A,
                    content: Text(
                      'Successfull Save Data!',
                      style: getWhiteTextStyle(),
                    )));
              });
  }

  Widget profileCard() {
    return InkWell(
      onTap: () {},
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                green00968A,
                blue344BEF,
              ]),
              borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: [
              CircleAvatar(
                backgroundImage: (user['image'] == '' ||
                        user['image'] == null ||
                        user['image'] == 'image')
                    ? AssetImage('$imagePath/default_user_image.png')
                        as ImageProvider
                    : NetworkImage(user['image']),
                backgroundColor: Colors.grey.withOpacity(0.4),
                radius: 50,
              ),
              const SizedBox(
                height: 24,
              ),
              Text(
                user['username'] ?? '',
                style: getWhiteTextStyle(
                  fontSize: 24,
                  fontWeight: w700,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                user['position'] ?? '',
                style: getWhiteTextStyle(fontSize: 16),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                (idSite == '1') ? 'Office' : user['siteName'],
                style: getWhiteTextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
