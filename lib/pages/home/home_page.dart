import 'dart:async';
import 'dart:math';

import 'package:camos/core/blocs/authentication/authentication_bloc.dart';
import 'package:camos/core/blocs/network/network_bloc.dart';
import 'package:camos/core/blocs/outstanding_task/outstanding_task_bloc.dart';
import 'package:camos/core/blocs/tire/tire_bloc.dart';
import 'package:camos/core/blocs/tire_condition/tire_condition_bloc.dart';
import 'package:camos/core/blocs/tire_invent/tire_invent_bloc.dart';
import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/services/local_database/outstanding_task/outstanding_task_entity.dart';
import 'package:camos/core/services/model/outstanding_task.dart';
import 'package:camos/core/services/model/tire_spec.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/services/sheets/attendance_sheets.dart';
import 'package:camos/core/services/sheets/model_sheets/attendance.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/menu.dart';
import 'package:camos/core/utils/data/oustanding_task.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/utils/notification/notification_api.dart';
import 'package:camos/core/widgets/box_menu_widget.dart';
import 'package:camos/core/widgets/box_tire_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/check_box_modal_widget.dart';
import 'package:camos/core/widgets/custom_error_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/core/widgets/network_checker_widget.dart';
import 'package:camos/core/widgets/oustandingtask_tile_widget.dart';
import 'package:camos/main.dart';
import 'package:camos/objectbox.g.dart';
import 'package:camos/pages/authentication/login_page.dart';
import 'package:camos/pages/home/detail_tire_site_page.dart';
import 'package:camos/pages/home/outstanding_filter_page.dart';
import 'package:camos/pages/settings/settings_page.dart';
import 'package:camos/pages/site/site_page.dart';
import 'package:camos/pages/tire_condition/tire_condition_page.dart';
import 'package:camos/pages/tire_inventory/tire_inventory_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class HomePage extends StatefulWidget {
  static const routeName = '/home_page';
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  final Box<OutstandingTaskEntity> box = store.box<OutstandingTaskEntity>();
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  late CollectionReference users;
  int _selectedIndex = 0;
  String versionNumberFirebase = '';

  var time;
  Map<String, dynamic> map = {};
  final status = ['New', 'Repair', 'Spare', 'Scrap'];
  String idSite = '';
  String actualIdSite = '';
  String siteName = '';
  bool isUniqueDatesFilled = false;
  late ConnectivityResult connectivityResult;
  bool isAccessed = true;

  List<String> selectedFilter = [];
  List<Map<String, dynamic>> filteredItemTask = [];
  final StreamController<QuerySnapshot> _streamController =
      StreamController<QuerySnapshot>();
  final StreamController<QuerySnapshot> _streamController2 =
      StreamController<QuerySnapshot>();
  StreamSubscription<User?>? _authStateSubscription;
  TextEditingController searchTaskController = TextEditingController();
  String searchTaskText = '';

  final allChecked = CheckBoxModalWidget(title: 'All');
  List<CheckBoxModalWidget> checkBoxList = [
    // CheckBoxModalWidget(title: 'CheckBox 1'),
    // CheckBoxModalWidget(title: 'CheckBox 2'),
    // CheckBoxModalWidget(title: 'CheckBox 3'),
  ];
  List<String> checkBoxTitleSelected = [];
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
    buildSignature: 'Unknown',
    installerStore: 'Unknown',
  );

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  void initState() {
    super.initState();
    requestStoragePermission();
    requestGeolocatorPermission();

    WidgetsBinding.instance.addObserver(this);
    _initPackageInfo();
    retrieveVersionNumber();
    retrieveIdSite();
    context
        .read<OutstandingTaskBloc>()
        .add(ReadOutStandingTaskEvent(selectedDate: []));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      var connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('Tidak ada koneksi internet');
      } else {
        showPosterDialog(context);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _streamController.close();
    _streamController2.close();
    _authStateSubscription?.cancel();
    super.dispose();
  }

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) async {
  //   super.didChangeAppLifecycleState(state);

  //   if (state == AppLifecycleState.inactive ||
  //       state == AppLifecycleState.detached) {
  //     final prefs = await SharedPreferences.getInstance();
  //     prefs.remove('detail_tire_spec');
  //   }
  // }

  void retrieveVersionNumber() async {
    final versionCol = FirebaseFirestore.instance.collection('version');
    final versionDoc = await versionCol.doc('version').get();
    String versionNumber = versionDoc.data()?['number'];
    if (_packageInfo.version != versionNumber) {
      showUpdateDialog(context);
    }
  }

  Future<void> showPosterDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: EdgeInsets.zero,
          content: StreamBuilder(
            stream: firestore.collection('poster').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container();
              }

              var posterMap = {};
              snapshot.data?.docs.forEach((element) {
                posterMap = element.data();
              });

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Image.network(
                    posterMap['image'],
                    fit: BoxFit.cover,
                    loadingBuilder: ((context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                            value: (loadingProgress.expectedTotalBytes != null)
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null),
                      );
                    }),
                  ),
                  Positioned(
                    top: -10, // Sesuaikan dengan jarak dari atas
                    right: -15, // Sesuaikan dengan jarak dari kanan
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Icon(Icons.close),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> showUpdateDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Dialog tidak dapat ditutup dengan mengetuk di luar dialog
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Update Available'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('A new version is available.'),
                Text('Please update to the latest version.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Close',
                style: getGreyTextStyle(grey6A707C),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Update Now'),
              onPressed: () {
                Navigator.of(context).pop();
                openPlayStore('camos');
              },
            ),
          ],
        );
      },
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void refreshPageData() {
    context
        .read<OutstandingTaskBloc>()
        .add(ReadOutStandingTaskEvent(selectedDate: checkBoxTitleSelected));
  }

  onAllClicked(CheckBoxModalWidget ckbItem) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    checkBoxTitleSelected.clear();
    final newValue = !ckbItem.value;

    ckbItem.value = newValue;
    checkBoxList.forEach((element) {
      element.value = newValue;
    });

    if (ckbItem.value) {
      // checkBoxTitleSelected.add(ckbItem.title);
      checkBoxList.forEach((element) {
        checkBoxTitleSelected.add(element.title);
      });
    } else {
      checkBoxTitleSelected.clear();
      // checkBoxTitleSelected.removeWhere((element) {
      //   return element == ckbItem.title;
      // });
    }
    print('tercentang : $checkBoxTitleSelected');
  }

  onItemClicked(CheckBoxModalWidget ckbItem) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
    final newValue = !ckbItem.value;

    ckbItem.value = newValue;

    if (!newValue) {
      allChecked.value = false;
    } else {
      final allListChecked = checkBoxList.every((element) => element.value);
      allChecked.value = allListChecked;
    }

    if (ckbItem.value) {
      checkBoxTitleSelected.add(ckbItem.title);
    } else {
      checkBoxTitleSelected.removeWhere((element) {
        return element == ckbItem.title;
      });
    }
    print('tercentang2 : $checkBoxTitleSelected');
  }

  setUniqueDate(List<String> dates) {
    checkBoxList.clear();
    List<String> uniqDateList = [];
    // print('hahaha $dates');
    dates.forEach((item) {
      final splitData = item.split('T');
      uniqDateList.add(splitData[0]);
    });
    // mengurutkan dari tanggal terbaru
    final nonParsedDates = Set<String>.from(uniqDateList);
    final List<DateTime> parsedDates =
        nonParsedDates.map((dateString) => DateTime.parse(dateString)).toList();
    parsedDates.sort((a, b) => b.compareTo(a));

    final Set<String> uniqDatesSet =
        Set<String>.from(parsedDates.map((date) => date.toString()));

    print('tanggal unik : $uniqDatesSet');
    uniqDatesSet.forEach((element) {
      final date = formatDateTime(DateTime.parse(element));
      checkBoxList.add(CheckBoxModalWidget(title: date));
    });
  }

  Future<void> _checkUserData(String uid) async {
    try {
      final DocumentSnapshot snapshot =
          await firestore.collection('users').doc(uid).get();

      if (!snapshot.exists) {
        auth.signOut();
      }
    } catch (e) {
      print('Error checking user data: $e');
    }
  }

  // void initialCallIdSite() async {
  //   String id = await getIdSitePreferences();
  //   idSite = id;
  // }

  String greeting() {
    var hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Morning';
    } else if (hour < 15) {
      return 'Afternoon';
    } else if (hour < 18) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  logoutConfirmation() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Logout Confirmation',
                  style: getBlackTextStyle(
                    fontSize: 16,
                    fontWeight: w600,
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'Are you sure you want to logout?',
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
                    // removeTireConditionPreferences();
                    // removeTireSpecPreferences();
                    // removeIdSitePreferences();
                    // removeUserPreferences();
                    context
                        .read<AuthenticationBloc>()
                        .add(AuthenticationEventLogout());
                    pushRemoveUntil(context, LoginPage.routeName);
                  },
                  child: Text('Yes')),
            ],
          );
        });
  }

  void retrieveIdSite() async {
    connectivityResult = await Connectivity().checkConnectivity();

    String id = await getIdSitePreferences();
    idSite = id;
    print('id site : $idSite');

    // if (idSite == '1') {
    //   idSite = await getSelectedIdSitePreferences();
    // }
    if (mounted) {}

    Stream<QuerySnapshot> stream = firestore
        .collection('task')
        .where('id_site', isEqualTo: idSite)
        // .where('is_done', isEqualTo: false)
        .snapshots();
    _streamController.addStream(stream);
    Stream<QuerySnapshot> stream2 = firestore
        .collection('task')
        .where('id_site', isEqualTo: idSite)
        // .where('is_done', isEqualTo: false)
        .snapshots();
    _streamController2.addStream(stream2);
  }

  @override
  Widget build(BuildContext context) {
    CollectionReference taskCollection = firestore.collection('task');
    final siteData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (siteData != null) {
      // setelah milih site
      print('id site home page : ${siteData['idSite']}');
      context
          .read<TireInventBloc>()
          .add(GetTireInventEvent(idSite: siteData['idSite'], status: status));

      context
          .read<TireConditionBloc>()
          .add(GetTireConditionEvent(idSite: siteData['idSite']));

      actualIdSite = siteData['idSite'];
      saveSelectedIdSitePreferences(actualIdSite);
    } else {
      // default site
      context
          .read<TireInventBloc>()
          .add(GetTireInventEvent(idSite: idSite, status: status));

      context
          .read<TireConditionBloc>()
          .add(GetTireConditionEvent(idSite: idSite));

      actualIdSite = idSite;
      saveSelectedIdSitePreferences(actualIdSite);
    }

    print('else site : $actualIdSite');

    return Scaffold(
      backgroundColor: white,
      body: WillPopScope(
          onWillPop: () async {
            DateTime now = DateTime.now();
            if (time == null ||
                now.difference(time) > const Duration(seconds: 2)) {
              time = now;
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Press Back Button Again to Exit')));
              return Future.value(false);
            }
            // final prefs = await SharedPreferences.getInstance();
            // prefs.remove('tire_spec');
            // prefs.remove('detail_tire_spec');
            return Future.value(true);
          },
          child: SafeArea(
            child: (_selectedIndex == 0)
                ? SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 24.0),
                      child: Column(
                        children: [
                          // NetworkCheckerWidget(),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: StreamBuilder(
                                stream: firestore
                                    .collection('users')
                                    .where('email',
                                        isEqualTo: auth.currentUser!.email)
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  final data = snapshot.data;

                                  data?.docs.forEach(
                                    (element) {
                                      map = element.data();
                                    },
                                  );

                                  saveUserPreferences(map);

                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  }

                                  // user dihapus oleh developer
                                  if (snapshot.connectionState ==
                                      ConnectionState.active) {
                                    if (map == {} || map.isEmpty) {
                                      removeIdSitePreferences();
                                      context
                                          .read<AuthenticationBloc>()
                                          .add(AuthenticationEventLogout());
                                      pushRemoveUntil(
                                          context, LoginPage.routeName);
                                    }
                                  }

                                  return Row(
                                    children: [
                                      InkWell(
                                        onTap: () async {
                                          // final id = await AttendanceSheetsAPI
                                          //         .getRowCount() +
                                          //     1;
                                          // final user = AttendanceSheetsModel(
                                          //     namaKaryawan: 'Agus',
                                          //     sn: '72413',
                                          //     tanggal:
                                          //         '${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
                                          //     masuk: '',
                                          //     pulang: '',
                                          //     keteranganMasuk: '',
                                          //     keteranganPulang: '');
                                          // final newUser = user.copy(id: id);

                                          // await AttendanceSheetsAPI
                                          //     .insertAttendanceSheet(
                                          //         [newUser.toJson()]);

                                          // await AttendanceSheetsAPI
                                          //     .updateAttendanceCell(
                                          //         id: 1,
                                          //         key: 'Nama_Karyawan',
                                          //         value: 'Tono');
                                          // print(
                                          //     'data satu karyawan : ${await AttendanceSheetsAPI.getSingleDataAttendance('Naufal', '06-07-2024')}');
                                        },
                                        child: CircleAvatar(
                                          backgroundImage: (map['image'] ==
                                                      '' ||
                                                  map['image'] == null ||
                                                  map['image'] == 'image')
                                              ? AssetImage(
                                                      '$imagePath/default_user_image.png')
                                                  as ImageProvider
                                              : NetworkImage(map['image']),
                                          backgroundColor:
                                              Colors.grey.withOpacity(0.4),
                                          radius: 30,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            RichText(
                                              textAlign: TextAlign.left,
                                              maxLines: 2,
                                              text:
                                                  TextSpan(children: <TextSpan>[
                                                TextSpan(
                                                  text: 'Good ${greeting()}, ',
                                                  style: getBlackTextStyle(
                                                    fontSize: 20,
                                                    fontWeight: w700,
                                                  ),
                                                ),
                                                TextSpan(
                                                  text: '\n${map['username']}',
                                                  style: getGreenTextStyle(
                                                    fontSize: 20,
                                                    fontWeight: w700,
                                                  ),
                                                ),
                                              ]),
                                            ),
                                            Text(
                                                'Your latest updates are below.',
                                                style: getBlackTextStyle())
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                              onPressed: () {
                                                Navigator.pushNamed(context,
                                                    SettingsPage.routeName);
                                              },
                                              icon: Icon(Icons.settings)),
                                          const SizedBox(
                                            width: 24,
                                          ),
                                          IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: BoxConstraints(),
                                              onPressed: () {
                                                logoutConfirmation();
                                              },
                                              icon: Icon(
                                                Icons.logout,
                                                color: Colors.red,
                                              )),
                                          const SizedBox(
                                            width: 12,
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }),
                          ),

                          const SizedBox(
                            height: 12,
                          ),
                          Text(
                            'App Version : ${_packageInfo.version}',
                            style: getBlackTextStyle(fontWeight: w700),
                          ),
                          const SizedBox(
                            height: 12,
                          ),

                          BlocConsumer<TireInventBloc, TireInventState>(
                              builder: (context, state) {
                                print('state saat ini :$state');
                                if (state is TireInventErrorState) {
                                  return CustomErrorWidget(
                                      errorMessage: state.message,
                                      onRefresh: () {
                                        if (siteData != null) {
                                          context.read<TireInventBloc>().add(
                                              GetTireInventEvent(
                                                  idSite: siteData['idSite'],
                                                  status: status));
                                        } else {
                                          context.read<TireInventBloc>().add(
                                              GetTireInventEvent(
                                                  idSite: idSite,
                                                  status: status));
                                        }
                                      });
                                }
                                if (state is TireInventLoadingState) {
                                  return Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }
                                if (state is TireInventLoadedState) {
                                  print(
                                      'data state ${state.nameSite} | ${state.site} | ${state.tireBlocData}');
                                  siteName = state.site['siteName'];
                                  print('nama site ${siteName}');
                                  map['siteName'] = siteName;
                                  saveUserPreferences(map);
                                  return Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        color: Colors.grey.withOpacity(0.1),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Site',
                                                  style: getBlackTextStyle(
                                                    fontSize: 20,
                                                    fontWeight: w700,
                                                  ),
                                                ),
                                                Text(
                                                  (siteData == null)
                                                      ? state.site['siteName']
                                                      : siteData['siteName'],
                                                  style: getGreenTextStyle(
                                                      fontSize: 16,
                                                      fontWeight: w700),
                                                ),
                                              ],
                                            ),
                                            (idSite == '1' || idSite == '2')
                                                ? SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.3,
                                                    child: ButtonWidget(
                                                        name: Text(
                                                          'Choose Site',
                                                          style:
                                                              getWhiteTextStyle(),
                                                        ),
                                                        function: () {
                                                          if (idSite == '1' ||
                                                              idSite == '2') {
                                                            Navigator.pushNamed(
                                                                context,
                                                                DetailTireSitePage
                                                                    .routeName);
                                                          }
                                                        }),
                                                  )
                                                : SizedBox()
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 12,
                                      ),
                                      InkWell(
                                        onTap: () async {
                                          final prefs = await SharedPreferences
                                              .getInstance();
                                          final cachedData =
                                              prefs.getString('tire_spec');
                                          print('data invent $cachedData');
                                        },
                                        child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 12),
                                            child: Container(
                                              padding: EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                    colors: [
                                                      green00968A,
                                                      blue344BEF,
                                                    ]),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Column(
                                                children: [
                                                  Text(
                                                    'Tire Inventory',
                                                    style: getWhiteTextStyle(
                                                        fontWeight: w700),
                                                  ),
                                                  const SizedBox(
                                                    height: 12,
                                                  ),
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: state.tireBlocData
                                                        .map((tire) {
                                                      final index = state
                                                          .tireBlocData
                                                          .indexOf(tire);
                                                      return InkWell(
                                                        onTap: () {
                                                          Navigator.pushNamed(
                                                            context,
                                                            TireInventoryPage
                                                                .routeName,
                                                            arguments: {
                                                              'idSite':
                                                                  actualIdSite,
                                                              'status':
                                                                  status[index],
                                                              'total': (tire[
                                                                          'status'] ==
                                                                      'Scrap')
                                                                  ? tire['total']
                                                                      .split(
                                                                          '|')[1]
                                                                  : tire['total'],
                                                            },
                                                          );
                                                        },
                                                        child: BoxTireWidget(
                                                          tire: tire,
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ),
                                            )),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Container();
                                }
                              },
                              listener: (context, state) {}),
                          const SizedBox(
                            height: 12,
                          ),

                          BlocBuilder<TireConditionBloc, TireConditionState>(
                            builder: (context, state) {
                              if (state is TireConditionLoadingState) {
                                return CircularProgressIndicator();
                              }

                              if (state is TireConditionLoadedState) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0),
                                  child: Card(
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Container(
                                      padding: EdgeInsets.all(12),
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                          gradient:
                                              const LinearGradient(colors: [
                                            green00968A,
                                            blue344BEF,
                                          ]),
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                      child: Column(
                                        children: [
                                          Text(
                                            'Tire Running Condition',
                                            style: getWhiteTextStyle(
                                                fontWeight: w700),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: state.mapRating.entries
                                                .map((rating) {
                                              return Card(
                                                elevation: 2,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.all(12),
                                                  width: MediaQuery.of(context)
                                                          .size
                                                          .width *
                                                      0.17,
                                                  height: MediaQuery.of(context)
                                                          .size
                                                          .height *
                                                      0.1,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      LayoutBuilder(builder:
                                                          (context,
                                                              constraints) {
                                                        double fontSize =
                                                            constraints
                                                                    .maxWidth *
                                                                0.2;

                                                        return Text(
                                                          'Rating ${rating.key}',
                                                          style:
                                                              getBlackTextStyle(
                                                                  fontSize:
                                                                      fontSize,
                                                                  fontWeight:
                                                                      w700),
                                                        );
                                                      }),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      LayoutBuilder(builder:
                                                          (context,
                                                              constraints) {
                                                        double fontSize =
                                                            constraints
                                                                    .maxWidth *
                                                                0.32;
                                                        return Text(
                                                          rating.value
                                                              .toString(),
                                                          textAlign:
                                                              TextAlign.center,
                                                          style:
                                                              getBlackTextStyle(
                                                            fontSize: fontSize,
                                                          ),
                                                        );
                                                      })
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                          const SizedBox(
                                            height: 12,
                                          ),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ButtonWidget(
                                                name: Text(
                                                  'Detail',
                                                  style: getWhiteTextStyle(
                                                    fontWeight: w700,
                                                  ),
                                                ),
                                                function: () {
                                                  Navigator.pushNamed(
                                                      context,
                                                      TireConditionPage
                                                          .routeName);
                                                }),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // if (state is TireConditionErrorState) {
                              //   return CustomErrorWidget(
                              //       errorMessage: state.message,
                              //       onRefresh: () {
                              //         context
                              //             .read<TireConditionBloc>()
                              //             .add(GetTireConditionEvent(
                              //               idSite: idSite,
                              //             ));
                              //       });
                              // }

                              return Container();
                            },
                          ),

                          const SizedBox(
                            height: 24,
                          ),
                          Container(
                            width: double.infinity,
                            constraints: BoxConstraints(
                              minHeight:
                                  MediaQuery.of(context).size.height * 0.5,
                            ),
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                            decoration: BoxDecoration(
                                color: white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(12),
                                  topRight: Radius.circular(12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    offset: const Offset(
                                      5.0,
                                      5.0,
                                    ),
                                    blurRadius: 10.0,
                                    spreadRadius: 2.0,
                                  ),
                                ]),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Quick Service',
                                  style: getBlackTextStyle(
                                    fontWeight: w700,
                                  ),
                                ),
                                const SizedBox(
                                  height: 24,
                                ),
                                GridView.builder(
                                    shrinkWrap: true,
                                    physics: NeverScrollableScrollPhysics(),
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                            mainAxisSpacing: 10,
                                            crossAxisSpacing: 10,
                                            crossAxisCount: 3,
                                            childAspectRatio: 0.9),
                                    itemCount: menus.length,
                                    itemBuilder: (context, index) {
                                      return BoxMenuWidget(
                                        menu: menus[index],
                                        argument: {'siteName': siteName},
                                      );
                                    }),
                                const SizedBox(
                                  height: 24,
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tire Inspection Result',
                            style: getGreenTextStyle(
                                fontWeight: w700, fontSize: 20),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                                onPressed: () async {
                                  final id = Uuid();
                                  print('tugas : $filteredItemTask');
                                  // print('terpesona $filteredItemTask');
                                  // final file = await createFolderPath(id.v4(), 'outstanding');
                                  print(
                                      'site mana : ${filteredItemTask[0]['id_site']}');

                                  final file = await createFolderPath(
                                      id.v4(), 'outstanding',
                                      email: auth.currentUser?.email ?? '',
                                      site: filteredItemTask[0]['id_site']);
                                  final bytes = await createExcel(
                                    'outstanding',
                                    task: filteredItemTask,
                                  );
                                  final saved = await file.writeAsBytes(bytes,
                                      flush: true);
                                  print('laper : $saved');
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                          backgroundColor: green00968A,
                                          content: Text(
                                            'Successfull Save Data!',
                                            style: getWhiteTextStyle(),
                                          )));
                                  final result = await OpenFile.open(file.path);

                                  if (result.type == ResultType.done) {
                                    print('File berhasil dibuka');
                                  } else {
                                    print(result.message);
                                    if (result.type == ResultType.noAppToOpen) {
                                      openPlayStore('attendance');
                                    }
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.table_chart),
                                      const SizedBox(
                                        width: 12,
                                      ),
                                      Text(
                                        'Export to Excel',
                                        style: getBlackTextStyle(),
                                      ),
                                    ],
                                  ),
                                )),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          // BlocBuilder<OutstandingTaskBloc,
                          //     OutstandingTaskState>(
                          //   builder: (context, state) {
                          //     if (state is OutStandingTaskEmptyState) {
                          //       return Column(
                          //         children: [
                          //           const SizedBox(
                          //             height: 72,
                          //           ),
                          //           Center(
                          //             child: Text(
                          //               'There is no task',
                          //               style: getBlackTextStyle(),
                          //             ),
                          //           ),
                          //         ],
                          //       );
                          //     }
                          //     if (state is OutStandingTaskLoadedState) {
                          //       final initialTask = state.initialTasks;
                          //       final tasks = state.tasks;

                          //       return Column(
                          //         children: [
                          //           InkWell(
                          //             onTap: () {
                          //               showModalBottomSheet(
                          //                   isScrollControlled: true,
                          //                   context: context,
                          //                   builder: (BuildContext context) {
                          //                     return SingleChildScrollView(
                          //                         child: Padding(
                          //                       padding: EdgeInsets.only(
                          //                           bottom:
                          //                               MediaQuery.of(context)
                          //                                   .viewInsets
                          //                                   .bottom),
                          //                       child: StatefulBuilder(
                          //                         builder:
                          //                             (BuildContext context,
                          //                                 setState) {
                          //                           if (isAccessed) {
                          //                             List<String> taskDates =
                          //                                 initialTask.map((e) {
                          //                               return e.lastUpdate;
                          //                             }).toList();

                          //                             setUniqueDate(taskDates);
                          //                             onAllClicked(allChecked);
                          //                             isAccessed = false;
                          //                           }

                          //                           return Container(
                          //                             padding:
                          //                                 EdgeInsets.symmetric(
                          //                                     vertical: 16),
                          //                             child: Column(
                          //                               mainAxisSize:
                          //                                   MainAxisSize.min,
                          //                               children: [
                          //                                 Padding(
                          //                                   padding:
                          //                                       const EdgeInsets
                          //                                               .symmetric(
                          //                                           horizontal:
                          //                                               16.0),
                          //                                   child: Row(
                          //                                     mainAxisAlignment:
                          //                                         MainAxisAlignment
                          //                                             .spaceBetween,
                          //                                     children: [
                          //                                       Text(
                          //                                         'Filter Outstanding Task',
                          //                                         style:
                          //                                             getBlackTextStyle(),
                          //                                       ),
                          //                                       GestureDetector(
                          //                                           onTap: () {
                          //                                             Navigator.pop(
                          //                                                 context);
                          //                                           },
                          //                                           child: Icon(
                          //                                               Icons
                          //                                                   .clear))
                          //                                     ],
                          //                                   ),
                          //                                 ),
                          //                                 SizedBox(
                          //                                   height: 8,
                          //                                 ),
                          //                                 ListTile(
                          //                                   onTap: () {
                          //                                     setState(() {
                          //                                       onAllClicked(
                          //                                           allChecked);
                          //                                     });
                          //                                   },
                          //                                   leading: Checkbox(
                          //                                     value: allChecked
                          //                                         .value,
                          //                                     onChanged:
                          //                                         (value) {
                          //                                       setState(() {
                          //                                         onAllClicked(
                          //                                             allChecked);
                          //                                       });
                          //                                     },
                          //                                   ),
                          //                                   title: Text(
                          //                                     'All',
                          //                                     style:
                          //                                         getBlackTextStyle(),
                          //                                   ),
                          //                                 ),
                          //                                 ...checkBoxList
                          //                                     .map((item) {
                          //                                   return ListTile(
                          //                                     onTap: () {
                          //                                       setState(() {
                          //                                         onItemClicked(
                          //                                             item);
                          //                                       });
                          //                                     },
                          //                                     leading: Checkbox(
                          //                                       value:
                          //                                           item.value,
                          //                                       onChanged:
                          //                                           (value) {
                          //                                         setState(() {
                          //                                           onItemClicked(
                          //                                               item);
                          //                                         });
                          //                                       },
                          //                                     ),
                          //                                     title: Text(
                          //                                       item.title,
                          //                                       style:
                          //                                           getBlackTextStyle(),
                          //                                     ),
                          //                                   );
                          //                                 }),
                          //                                 Container(
                          //                                     width: double
                          //                                         .infinity,
                          //                                     padding: EdgeInsets
                          //                                         .symmetric(
                          //                                             horizontal:
                          //                                                 12),
                          //                                     child:
                          //                                         ElevatedButton(
                          //                                             onPressed:
                          //                                                 () {
                          //                                               Navigator.pop(
                          //                                                   context);
                          //                                               refreshPageData();
                          //                                             },
                          //                                             child:
                          //                                                 Text(
                          //                                               'Save',
                          //                                               style:
                          //                                                   getWhiteTextStyle(),
                          //                                             ))),
                          //                               ],
                          //                             ),
                          //                           );
                          //                         },
                          //                       ),
                          //                     ));
                          //                   });
                          //             },
                          //             child: Container(
                          //               // height: 40,
                          //               width: double.infinity,
                          //               padding: const EdgeInsets.fromLTRB(
                          //                   10, 6, 7.5, 6),
                          //               margin: EdgeInsets.only(right: 8),
                          //               decoration: BoxDecoration(
                          //                 borderRadius: const BorderRadius.all(
                          //                   Radius.circular(8),
                          //                 ),
                          //                 border: Border.all(
                          //                   color: const Color(0xff313131),
                          //                 ),
                          //               ),
                          //               child: Row(
                          //                 mainAxisSize: MainAxisSize.min,
                          //                 mainAxisAlignment:
                          //                     MainAxisAlignment.spaceBetween,
                          //                 children: [
                          //                   Builder(builder: (context) {
                          //                     final formated =
                          //                         checkBoxTitleSelected
                          //                             .map((title) {
                          //                       String inputDateString = title;
                          //                       DateFormat inputFormat =
                          //                           DateFormat(
                          //                               'EEEE, d MMMM y, H:m:s');
                          //                       DateTime inputDate = inputFormat
                          //                           .parse(inputDateString);

                          //                       DateFormat outputFormat =
                          //                           DateFormat(
                          //                               "EEEE, d MMMM y");
                          //                       return outputFormat
                          //                           .format(inputDate);
                          //                     }).toList();
                          //                     return Text(
                          //                       (allChecked.value)
                          //                           ? 'All'
                          //                           : '${formated.join('\n')}',
                          //                       style: getBlackTextStyle(),
                          //                     );
                          //                   }),
                          //                   Container(
                          //                     padding: const EdgeInsets.only(
                          //                         bottom: 4),
                          //                     child: Transform.rotate(
                          //                       angle: (22 / 7) / -2,
                          //                       child: const Icon(
                          //                         Icons.arrow_back_ios,
                          //                         color: Color(0xffC5C6C6),
                          //                         size: 15,
                          //                       ),
                          //                     ),
                          //                   ),
                          //                 ],
                          //               ),
                          //             ),
                          //           ),
                          //           const SizedBox(
                          //             height: 12,
                          //           ),
                          //           ListView.builder(
                          //               shrinkWrap: true,
                          //               physics: NeverScrollableScrollPhysics(),
                          //               itemCount: tasks.length,
                          //               itemBuilder: (context, index) {
                          //                 final task = tasks[index];
                          //                 final outstandingTask =
                          //                     OutstandingTask(
                          //                   id: task.idTask,
                          //                   idSite: task.idSite,
                          //                   user: task.user,
                          //                   unit: task.unit,
                          //                   serialNumber: task.serialNumber,
                          //                   condition: task.condition,
                          //                   tireSize: task.tireSize,
                          //                   position: task.position,
                          //                   brand: task.brand,
                          //                   tireDamage: task.tireDamage,
                          //                   remarks: task.remarks,
                          //                   pressure: task.pressure,
                          //                   lastUpdate: task.lastUpdate,
                          //                 );
                          //                 return Dismissible(
                          //                     key: Key('${task.id}'),
                          //                     onDismissed: (direction) {
                          //                       // context
                          //                       //     .read<OutstandingTaskBloc>()
                          //                       //     .add(DeleteOutStandingTaskEvent(
                          //                       //         id: task.id));
                          //                       // context
                          //                       //     .read<OutstandingTaskBloc>()
                          //                       //     .add(
                          //                       //         ReadOutStandingTaskEvent());
                          //                       ScaffoldMessenger.of(context)
                          //                           .hideCurrentSnackBar();
                          //                       ScaffoldMessenger.of(context)
                          //                           .showSnackBar(SnackBar(
                          //                               content: Text(
                          //                         'Succesful delete outstanding task',
                          //                         style: getWhiteTextStyle(),
                          //                       )));
                          //                     },
                          //                     background: Container(
                          //                         color: Colors.red,
                          //                         padding: const EdgeInsets
                          //                                 .symmetric(
                          //                             horizontal: 24),
                          //                         child: const Row(
                          //                           mainAxisAlignment:
                          //                               MainAxisAlignment
                          //                                   .spaceBetween,
                          //                           children: [
                          //                             Icon(
                          //                               Icons.delete,
                          //                               color: white,
                          //                             ),
                          //                             Icon(
                          //                               Icons.delete,
                          //                               color: white,
                          //                             )
                          //                           ],
                          //                         )),
                          //                     child: OustandingTileWidget(
                          //                       task: outstandingTask,
                          //                     ));
                          //               })
                          //         ],
                          //       );
                          //     }
                          //     return Container();
                          //   },
                          // ),
                          TextField(
                            controller: searchTaskController,
                            onChanged: (value) {
                              setState(() {
                                searchTaskText = value;
                              });
                            },
                            decoration: InputDecoration(
                                hintText: 'Search... (Unit Number)',
                                hintStyle: getGreyTextStyle(grey8391A1),
                                prefixIcon: Icon(Icons.search)),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          StreamBuilder<QuerySnapshot>(
                              stream: firestore
                                  .collection('task')
                                  .where('id_site', isEqualTo: actualIdSite)
                                  .where('is_done', isEqualTo: false)
                                  .snapshots(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return CircularProgressIndicator();
                                }

                                List<DocumentSnapshot> docs =
                                    snapshot.data!.docs;

                                final listTaskDate = docs.map((element) {
                                  final elementMap =
                                      element.data() as Map<String, dynamic>;
                                  return elementMap['last_update'] as String;
                                }).toList();

                                print('lapar $listTaskDate');

                                if (isAccessed) {
                                  setUniqueDate(listTaskDate);
                                  onAllClicked(allChecked);
                                  isAccessed = false;
                                }

                                List<DocumentSnapshot> filteredDocsExcel =
                                    snapshot.data!.docs;

                                DateFormat inputFormat =
                                    DateFormat('EEEE, d MMMM y, H:m:s');

                                final formatedDates =
                                    checkBoxTitleSelected.map((date) {
                                  DateTime inputDate = inputFormat.parse(date);
                                  DateFormat outputFormat = DateFormat(
                                      "yyyy-MM-dd'T'HH:mm:ss.SSSSSS");
                                  String outputDateString =
                                      outputFormat.format(inputDate);
                                  List<String> splittedDate =
                                      outputDateString.split('T');
                                  return splittedDate[0];
                                }).toList();

                                List<DocumentSnapshot<Object?>> filteredTask =
                                    docs.where((task) {
                                  List<String> splittedDate =
                                      task['last_update'].split('T');
                                  return formatedDates
                                      .contains(splittedDate[0]);
                                }).toList();

                                // untuk data export excel
                                filteredItemTask.clear();
                                filteredTask.forEach((item) {
                                  Map<String, dynamic> cast =
                                      item.data() as Map<String, dynamic>;
                                  cast['id_site'] = siteName;
                                  filteredItemTask.add(cast);
                                });

                                // filter berdasarkan tanggal input data
                                filteredTask.sort((a, b) {
                                  Map<String, dynamic> first =
                                      a.data() as Map<String, dynamic>;
                                  Map<String, dynamic> second =
                                      b.data() as Map<String, dynamic>;
                                  ;
                                  // Ambil nilai last_update dari masing-masing DocumentSnapshot
                                  DateTime timeA =
                                      DateTime.parse(first['last_update']);
                                  DateTime timeB =
                                      DateTime.parse(second['last_update']);

                                  // Bandingkan waktu last_update dari kedua DocumentSnapshot
                                  return timeB.compareTo(
                                      timeA); // Dari yang terbaru ke yang terlama
                                });

                                // pencarian data berdasarkan id unit
                                if (searchTaskText.length > 0) {
                                  filteredTask = filteredTask.where((element) {
                                    return element
                                        .get('unit')
                                        .toString()
                                        .toLowerCase()
                                        .contains(searchTaskText.toLowerCase());
                                  }).toList();
                                }

                                return Column(
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        showModalBottomSheet(
                                            isScrollControlled: true,
                                            context: context,
                                            builder: (BuildContext context) {
                                              return SingleChildScrollView(
                                                  child: Padding(
                                                padding: EdgeInsets.only(
                                                    bottom:
                                                        MediaQuery.of(context)
                                                            .viewInsets
                                                            .bottom),
                                                child: StatefulBuilder(
                                                  builder:
                                                      (BuildContext context,
                                                          setState) {
                                                    return Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              vertical: 16),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .symmetric(
                                                                    horizontal:
                                                                        16.0),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .spaceBetween,
                                                              children: [
                                                                Text(
                                                                  'Filter Outstanding Task',
                                                                  style:
                                                                      getBlackTextStyle(),
                                                                ),
                                                                GestureDetector(
                                                                    onTap: () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child: Icon(
                                                                        Icons
                                                                            .clear))
                                                              ],
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height: 8,
                                                          ),
                                                          ListTile(
                                                            onTap: () {
                                                              Future.microtask(
                                                                  () {
                                                                setState(() {
                                                                  onAllClicked(
                                                                      allChecked);
                                                                });
                                                              });
                                                            },
                                                            leading: Checkbox(
                                                              value: allChecked
                                                                  .value,
                                                              onChanged:
                                                                  (value) {
                                                                Future
                                                                    .microtask(
                                                                        () {
                                                                  setState(() {
                                                                    onAllClicked(
                                                                        allChecked);
                                                                  });
                                                                });
                                                              },
                                                            ),
                                                            title: Text(
                                                              'All',
                                                              style:
                                                                  getBlackTextStyle(),
                                                            ),
                                                          ),

                                                          // check box list tidak muncul
                                                          ...checkBoxList
                                                              .map((item) {
                                                            return ListTile(
                                                              onTap: () {
                                                                Future
                                                                    .microtask(
                                                                        () {
                                                                  setState(() {
                                                                    onItemClicked(
                                                                        item);
                                                                  });
                                                                });
                                                              },
                                                              leading: Checkbox(
                                                                value:
                                                                    item.value,
                                                                onChanged:
                                                                    (value) {
                                                                  Future
                                                                      .microtask(
                                                                          () {
                                                                    setState(
                                                                        () {
                                                                      onItemClicked(
                                                                          item);
                                                                    });
                                                                  });
                                                                },
                                                              ),
                                                              title: Text(
                                                                item.title,
                                                                style:
                                                                    getBlackTextStyle(),
                                                              ),
                                                            );
                                                          }),
                                                          // ButtonWidget(
                                                          //     name:
                                                          //         Text('Save'),
                                                          //     function: () {
                                                          //       setState(() {});
                                                          //     })
                                                        ],
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ));
                                            });
                                      },
                                      child: Container(
                                        // height: 40,
                                        width: double.infinity,
                                        padding: const EdgeInsets.fromLTRB(
                                            10, 6, 7.5, 6),
                                        margin: EdgeInsets.only(right: 8),
                                        decoration: BoxDecoration(
                                          borderRadius: const BorderRadius.all(
                                            Radius.circular(8),
                                          ),
                                          border: Border.all(
                                            color: const Color(0xff313131),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Builder(builder: (context) {
                                              final formated =
                                                  checkBoxTitleSelected
                                                      .map((title) {
                                                String inputDateString = title;
                                                DateFormat inputFormat =
                                                    DateFormat(
                                                        'EEEE, d MMMM y, H:m:s');
                                                DateTime inputDate = inputFormat
                                                    .parse(inputDateString);

                                                DateFormat outputFormat =
                                                    DateFormat(
                                                        "EEEE, d MMMM y");
                                                return outputFormat
                                                    .format(inputDate);
                                              }).toList();
                                              return Text(
                                                (allChecked.value)
                                                    ? 'All'
                                                    : '${formated.join('\n')}',
                                                style: getBlackTextStyle(),
                                              );
                                            }),
                                            Container(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: Transform.rotate(
                                                angle: (22 / 7) / -2,
                                                child: const Icon(
                                                  Icons.arrow_back_ios,
                                                  color: Color(0xffC5C6C6),
                                                  size: 15,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 4,
                                    ),
                                    ListView.builder(
                                        shrinkWrap: true,
                                        physics: NeverScrollableScrollPhysics(),
                                        itemCount: filteredTask.length,
                                        itemBuilder: (context, index) {
                                          Map<String, dynamic> task =
                                              // docs[index].data() as Map<
                                              //     String, dynamic>;
                                              filteredTask[index].data()
                                                  as Map<String, dynamic>;

                                          return OustandingTileWidget(
                                              task: OutstandingTask(
                                                  id: task['id'] ?? '',
                                                  idSite: task['id_site'] ?? '',
                                                  user: task['user'] ?? '',
                                                  unit: task['unit'] ?? '',
                                                  serialNumber:
                                                      task['serial_number'] ??
                                                          '',
                                                  condition: (task['condition'] != null)
                                                      ? List<String>.from(
                                                          task['condition'].map(
                                                              (condition) =>
                                                                  condition
                                                                      .toString()))
                                                      : [],
                                                  tireSize:
                                                      task['tire_size'] ?? '',
                                                  hm: task['hm'] ?? '',
                                                  position: task['position'] is String
                                                      ? int.tryParse(task['position']) ??
                                                          0
                                                      : task['position'] ?? 0,
                                                  brand: task['brand'] ?? '',
                                                  tireDamage: task['tire_damage']
                                                          is List<dynamic>
                                                      ? task['tire_damage'].join(', ')
                                                      : task['tire_damage'],
                                                  remarks: task['remarks'] ?? '',
                                                  rtd: task['rtd'] ?? '',
                                                  pressure: task['pressure'] ?? '',
                                                  adjusmentPressure: task['adjusmentPressure'] ?? '',
                                                  lastUpdate: task['last_update'] ?? '',
                                                  isDone: task['is_done'] ?? '',
                                                  sn: task['sn'] ?? '',
                                                  kunciUnit: task['kunci_unit'] ?? '',
                                                  kunciTire: task['kunci_tire'] ?? '',
                                                  images: []));
                                        }),
                                  ],
                                );
                              }),
                        ],
                      ),
                    ),
                  ),
          )),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.task), label: 'Tire Inspection Result'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
