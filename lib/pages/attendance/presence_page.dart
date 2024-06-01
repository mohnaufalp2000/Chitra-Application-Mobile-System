import 'dart:async';
import 'dart:developer';

import 'package:camos/core/blocs/attendance/attendance_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/local_database/attendance/attendance_entity.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
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
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
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

  String selectedShift = 'morning';

  Stream<List<AttendanceEntity>>? attendanceStream;

  Map<String, dynamic> user = {};
  String idSite = '';

  TextEditingController infoCheckInCtrl = TextEditingController();
  TextEditingController infoCheckOutCtrl = TextEditingController();

  String InfoCheckIn = '';
  String InfoCheckOut = '';

  AttendanceEntity? isPresenceToday;

  @override
  void initState() {
    super.initState();
    log('kemarin : ${DateTime.now().subtract(Duration(days: 1)).toIso8601String().split('T')[0]}');
    retrieveManpowerShift();
    retrieveUser();
    getDataPresenceToday();
  }

  void getDataPresenceToday() {
    DateTime now = DateTime.now();
    String todayDocId = DateFormat.yMd().format(now).replaceAll('/', '-');
    final tmpDate = DateFormat('MM-dd-yyyy').parse(todayDocId);
    String formattedDate = DateFormat('yyyy-MM-dd').format(tmpDate);
    isPresenceToday = attendanceBox
        .query(AttendanceEntity_.date
            .contains(formattedDate, caseSensitive: false))
        .build()
        .findFirst();

    setState(() {});
    if (isPresenceToday != null) {
      InfoCheckIn = isPresenceToday!.keteranganMasuk;
      InfoCheckOut = isPresenceToday!.keteranganKeluar;

      infoCheckInCtrl.text = isPresenceToday!.keteranganMasuk;
      infoCheckOutCtrl.text = isPresenceToday!.keteranganKeluar;
    }
  }

  void retrieveUser() async {
    user = await getUserPreferences();
    idSite = await getIdSitePreferences();
    log(user.toString());
  }

  void retrieveManpowerShift() async {
    String shift = await getManpowerShiftPreferences();
    setState(() {
      selectedShift = shift;
    });
    print('shift dipilih $selectedShift');
    DateTime now = DateTime.now();
    TimeOfDay targetTime = TimeOfDay(hour: (16), minute: 0);

    DateTime targetDateTime = DateTime(
        now.year, now.month, now.day, targetTime.hour, targetTime.minute);
    if (selectedShift == 'morning') {
      attendanceStream = attendanceBox
          .query(AttendanceEntity_.date
              .contains(DateTime.now().toIso8601String().split('T')[0]))
          .watch(triggerImmediately: true)
          .map((event) => event.find());
    } else {
      if (now.isAfter(targetDateTime)) {
        print('malam');
        attendanceStream = attendanceBox
            .query(AttendanceEntity_.date
                .contains(DateTime.now().toIso8601String().split('T')[0]))
            .watch(triggerImmediately: true)
            .map((event) => event.find());
      } else {
        print('pagi');
        attendanceStream = attendanceBox
            .query(AttendanceEntity_.date.contains(DateTime.now()
                .subtract(Duration(days: 1))
                .toIso8601String()
                .split('T')[0]))
            .watch(triggerImmediately: true)
            .map((event) => event.find());
      }
      ;
    }
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
                    setState(() {
                      log('apakah data kosong : ${isPresenceToday == null}');
                      if (isPresenceToday != null) {
                        if (type == 'check-in') {
                          isPresenceToday?.keteranganMasuk =
                              infoCheckInCtrl.text;
                          InfoCheckIn = infoCheckInCtrl.text;
                        } else {
                          isPresenceToday?.keteranganKeluar =
                              infoCheckOutCtrl.text;
                          InfoCheckOut = infoCheckOutCtrl.text;
                        }
                        attendanceBox.put(isPresenceToday!);
                      }
                    });
                    Navigator.pop(context);
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
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  profileCard(),
                  const SizedBox(
                    height: 12,
                  ),
                  buttonSave(),
                  const SizedBox(
                    height: 24,
                  ),
                  dropdownShift(),
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
                stream: attendanceStream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final att = snapshot.data;

                    if (att!.isNotEmpty) {
                      log('data checkout : ${att?[0].keluar}');

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
                                    (att![0].masuk == '')
                                        ? '-'
                                        : '${DateFormat.yMMMMEEEEd().format(DateTime.parse(att[0].masuk))}',
                                    style: getWhiteTextStyle(),
                                  ),
                                  Text(
                                    (att[0].masuk == '')
                                        ? '-'
                                        : '${DateFormat.Hms().format(DateTime.parse(att[0].masuk ?? ''))}',
                                    style: getWhiteTextStyle(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              (att![0].masuk == '')
                                  ? Text(
                                      '-',
                                      style: getWhiteTextStyle(),
                                    )
                                  : Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.7,
                                          child: ButtonWidget(
                                              name: (InfoCheckIn.isEmpty)
                                                  ? Row(
                                                      children: [
                                                        Icon(
                                                          Icons.add,
                                                        ),
                                                        SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          'Add Additional Info',
                                                          style:
                                                              getBlackTextStyle(),
                                                        ),
                                                      ],
                                                    )
                                                  : Column(
                                                      children: [
                                                        Text(
                                                          InfoCheckIn,
                                                          style:
                                                              getBlackTextStyle(),
                                                        ),
                                                        Divider(),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.edit),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Text(
                                                              'Edit',
                                                              style:
                                                                  getBlackTextStyle(),
                                                            ),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                              color: white,
                                              function: () {
                                                getDataPresenceToday();
                                                showAddInfoDialog('check-in');
                                              }),
                                        ),
                                      ],
                                    ),
                              const SizedBox()
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
                                    (att[0].keluar == '')
                                        ? '-'
                                        : '${DateFormat.yMMMMEEEEd().format(DateTime.parse(att[0].keluar ?? ''))}',
                                    style: getWhiteTextStyle(),
                                  ),
                                  Text(
                                    (att[0].keluar == '')
                                        ? '-'
                                        : '${DateFormat.Hms().format(DateTime.parse(att[0].keluar ?? ''))}',
                                    style: getWhiteTextStyle(),
                                  ),
                                ],
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              (att![0].keluar == '')
                                  ? Text(
                                      '-',
                                      style: getWhiteTextStyle(),
                                    )
                                  : Row(
                                      children: [
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.7,
                                          child: ButtonWidget(
                                              name: ((InfoCheckOut.isEmpty))
                                                  ? Row(
                                                      children: [
                                                        Icon(
                                                          Icons.add,
                                                        ),
                                                        SizedBox(
                                                          width: 6,
                                                        ),
                                                        Text(
                                                          'Add Additional Info',
                                                          style:
                                                              getBlackTextStyle(),
                                                        ),
                                                      ],
                                                    )
                                                  : Column(
                                                      children: [
                                                        Text(
                                                          InfoCheckOut,
                                                          style:
                                                              getBlackTextStyle(),
                                                        ),
                                                        Divider(),
                                                        Row(
                                                          children: [
                                                            Icon(Icons.edit),
                                                            const SizedBox(
                                                              width: 6,
                                                            ),
                                                            Text(
                                                              'Edit',
                                                              style:
                                                                  getBlackTextStyle(),
                                                            ),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                              color: white,
                                              function: () {
                                                getDataPresenceToday();
                                                showAddInfoDialog('check-out');
                                              }),
                                        ),
                                      ],
                                    ),
                            ],
                          ),
                        ],
                      );
                    }
                  }

                  return Container(
                    child: Center(
                      child: Text(
                        'You haven\'t done attendance today',
                        style: getWhiteTextStyle(),
                      ),
                    ),
                  );
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
        ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: attendanceBox.getAll().length,
            itemBuilder: (contenxt, index) {
              final presence = attendanceBox.getAll()[index];
              return Card(
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
                                .format(DateTime.parse(presence.date)),
                            style: getWhiteTextStyle(
                              fontWeight: w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        presence.masuk == null || presence.masuk == ''
                            ? '-'
                            : '${DateFormat.Hms().format(DateTime.parse(presence.masuk))}',
                        style: getWhiteTextStyle(),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        'Out',
                        style: getWhiteTextStyle(fontWeight: w700),
                      ),
                      Text(
                        presence.keluar == null || presence.keluar == ''
                            ? '-'
                            : '${DateFormat.Hms().format(DateTime.parse(presence.keluar))}',
                        style: getWhiteTextStyle(),
                      ),
                    ],
                  ),
                ),
              );
            })
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
        function: () async {
          context.read<AttendanceBloc>().add(SaveCsvPresenceEvent(
              username: user['username'] ?? '',
              position: user['position'] ?? '',
              sn: user['sn'] ?? '',
              site: (idSite == '1') ? 'Office' : user['siteName'],
              presence: attendanceBox.getAll()));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              backgroundColor: green00968A,
              content: Text(
                'Successfull Save Data!',
                style: getWhiteTextStyle(),
              )));
        });
  }

  SizedBox dropdownShift() {
    return SizedBox(
      width: double.infinity,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
            isDense: true,
            style: getBlackTextStyle(),
            value: selectedShift,
            items: [
              DropdownMenuItem(
                child: Text('Shift Pagi'),
                value: 'morning',
              ),
              DropdownMenuItem(
                child: Text('Shift Malam'),
                value: 'night',
              ),
            ],
            onChanged: (value) async {
              log('changed value : $value');
              updateManpowerShiftPreference(value ?? '');
              setState(() {
                selectedShift = value ?? '';
              });
            }),
      ),
    );
  }

  Widget profileCard() {
    return InkWell(
      onTap: () {
        log(attendanceBox.getAll().toString());
      },
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
