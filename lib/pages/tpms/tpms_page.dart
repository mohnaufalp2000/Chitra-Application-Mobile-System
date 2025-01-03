import 'dart:developer';

import 'package:camos/core/blocs/spm/spm_bloc.dart';
import 'package:camos/core/services/api_service.dart';
import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/spm.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/tire_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_check_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TpmsPage extends StatefulWidget {
  static const routeName = '/tpmsPage';
  const TpmsPage({super.key});

  @override
  State<TpmsPage> createState() => _TpmsPageState();
}

class _TpmsPageState extends State<TpmsPage> {
  WebViewController? webViewController;
  List<String> pressureData = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
  ];
  String searchQuery = '';
  List<Map<String, dynamic>> pressures = [];
  List<Map<String, dynamic>> pressureStatus = [];
  List<Map<String, dynamic>> temperatures = [];
  List<List<List<Map<String, dynamic>>>> allUnits = [];

  @override
  void initState() {
    super.initState();
    context.read<SpmBloc>().add(GetListSpmEvent());

    // webViewController = WebViewController()
    //   ..setJavaScriptMode(JavaScriptMode.unrestricted)
    //   ..setBackgroundColor(white)
    //   ..setNavigationDelegate(
    //     NavigationDelegate(
    //       onProgress: (int progress) {
    //         // Update loading bar.
    //       },
    //       onPageStarted: (String url) {},
    //       onPageFinished: (String url) {},
    //       onWebResourceError: (WebResourceError error) {},
    //       onNavigationRequest: (NavigationRequest request) {
    //         if (request.url.startsWith('https://www.chitraparatama.co.id/')) {
    //           return NavigationDecision.prevent;
    //         }
    //         return NavigationDecision.navigate;
    //       },
    //     ),
    //   )
    //   ..loadRequest(Uri.parse(
    //       'https://cts-chitraparatama.co.id/ChitraTireMngr/product/halamantpms.php'));
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> data =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    String idSite = data['idSite'];
    log('id site spm : $idSite');

    return Scaffold(
      appBar: appBarWidget('SPM Page', context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                      hintText: 'Search... (Unit ID)',
                      hintStyle: getGreyTextStyle(grey8391A1),
                      prefixIcon: Icon(Icons.search)),
                ),
                const SizedBox(
                  height: 12,
                ),
                // Identity Data
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  color: Color(0xFF0C44A3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              "Operator : CK",
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white),
                            ),
                            Container(height: 10),
                            Text('Project Synergy CP-CK',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[200])),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 12,
                ),
                ButtonWidget(
                    name: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          color: white,
                        ),
                        SizedBox(
                          width: 12,
                        ),
                        Text(
                          'Refresh',
                          style: getWhiteTextStyle(),
                        ),
                      ],
                    ),
                    function: () {
                      pressures.clear();
                      temperatures.clear();
                      pressureStatus.clear();
                      context.read<SpmBloc>().add(GetListSpmEvent());
                    }),
                SizedBox(
                  height: 12,
                ),
                // Unit
                BlocConsumer<SpmBloc, SpmState>(
                  listener: (context, state) {
                    log('state listener : $state');
                    if (state is SpmLoadedState) {
                      // index 1 PRESSURE
                      // index 2 PRESSURE STATUS / PRESS1
                      // index 3 TEMPERATURE
                      // allUnits.clear();
                      // state.listSpm.forEach((element) {
                      //   allUnits.add(
                      //     [
                      //       [
                      //         {
                      //           'pressure1': element.pressure1,
                      //         },
                      //         {
                      //           'pressure2': element.pressure2,
                      //         },
                      //         {
                      //           'pressure3': element.pressure3,
                      //         },
                      //         {
                      //           'pressure4': element.pressure4,
                      //         },
                      //         {
                      //           'pressure5': element.pressure5,
                      //         },
                      //         {
                      //           'pressure6': element.pressure6,
                      //         },
                      //       ],
                      //       [
                      //         {
                      //           'press1': element.press1,
                      //         },
                      //         {
                      //           'press2': element.press2,
                      //         },
                      //         {
                      //           'press3': element.press3,
                      //         },
                      //         {
                      //           'press4': element.press4,
                      //         },
                      //         {
                      //           'press5': element.press5,
                      //         },
                      //         {
                      //           'press6': element.press6,
                      //         },
                      //       ],
                      //       [
                      //         {'temperature1': element.temperature1},
                      //         {'temperature2': element.temperature2},
                      //         {'temperature3': element.temperature3},
                      //         {'temperature4': element.temperature4},
                      //         {'temperature5': element.temperature5},
                      //         {'temperature6': element.temperature6},
                      //       ],
                      //     ],
                      //   );
                      // });
                      // log('semua  : ${allUnits[0]}');
                      // log('semua unit : ${allUnits[0][1]}');

                      // log('semua 1: ${allUnits[1]}');
                      // log('semua unit 1: ${allUnits[1][1]}');

                      // log('jumlah semua unit: ${allUnits.length}');
                    }
                  },
                  builder: (context, state) {
                    log('listener listener: $state');
                    if (state is SpmLoadingState) {
                      return CircularProgressIndicator();
                    }

                    if (state is SpmLoadedState) {
                      List<Spm> actualList = state.listSpm;

                      List<Spm> list = actualList
                          .where((spm) => spm.idSite == idSite)
                          .toList();

                      if (list.isEmpty) {
                        return Text(
                          'No Unit Found!',
                          style: getBlackTextStyle(),
                        );
                      }

                      if (searchQuery.length > 0) {
                        list = list.where((element) {
                          return element.devicename
                              .toString()
                              .toLowerCase()
                              .contains(searchQuery.toLowerCase());
                        }).toList();
                      }

                      allUnits.clear();
                      list.forEach((element) {
                        allUnits.add(
                          [
                            [
                              {
                                'pressure1': element.pressure1,
                              },
                              {
                                'pressure2': element.pressure2,
                              },
                              {
                                'pressure3': element.pressure3,
                              },
                              {
                                'pressure4': element.pressure4,
                              },
                              {
                                'pressure5': element.pressure5,
                              },
                              {
                                'pressure6': element.pressure6,
                              },
                            ],
                            [
                              {
                                'press1': element.press1,
                              },
                              {
                                'press2': element.press2,
                              },
                              {
                                'press3': element.press3,
                              },
                              {
                                'press4': element.press4,
                              },
                              {
                                'press5': element.press5,
                              },
                              {
                                'press6': element.press6,
                              },
                            ],
                            [
                              {'temperature1': element.temperature1},
                              {'temperature2': element.temperature2},
                              {'temperature3': element.temperature3},
                              {'temperature4': element.temperature4},
                              {'temperature5': element.temperature5},
                              {'temperature6': element.temperature6},
                            ],
                          ],
                        );
                      });

                      return Column(
                        children: list.map((e) {
                          final unit = list[list.indexOf(e)];
                          final indexUnit = list.indexOf(e);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Column(
                              children: [
                                // Pos 1, 2
                                Stack(
                                  children: [
                                    Positioned(
                                      top: 20,
                                      left: 0,
                                      right: 0,
                                      child: Column(
                                        children: [
                                          Text(
                                            unit.devicename,
                                            style: getBlackTextStyle(
                                              fontSize: 18,
                                              fontWeight: w700,
                                            ),
                                          ),
                                          const SizedBox(
                                            height: 4,
                                          ),
                                          FutureBuilder(
                                              future:
                                                  ApiService.getSite(idSite),
                                              builder: (context, snapshot) {
                                                final data = snapshot.data;
                                                log('future id site : $data');
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Container();
                                                }
                                                return Text(
                                                  'Site : ${data?.site ?? ''}',
                                                  style: getBlackTextStyle(
                                                    fontSize: 14,
                                                    fontWeight: w700,
                                                  ),
                                                );
                                              }),
                                          SizedBox(
                                            height: 150,
                                            width: 100,
                                            child: Image.asset(
                                                '${imagePath}/dump_truck.png'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: allUnits[indexUnit][0].map((e) {
                                        final index =
                                            allUnits[indexUnit][0].indexOf(e);
                                        if (index < 2) {
                                          return Expanded(
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                  right: (index == 0) ? 84 : 0,
                                                  left: (index == 1) ? 84 : 0),
                                              child: PressureCard(
                                                  position: '${index + 1}',
                                                  // temperature: temperatures[index]
                                                  //         [
                                                  //         'temperature${index + 1}'] ??
                                                  //     '',
                                                  temperature: allUnits[indexUnit]
                                                              [2][index][
                                                          'temperature${index + 1}'] ??
                                                      '',
                                                  // pressureStatus: pressureStatus[
                                                  //             index]
                                                  //         ['press${index + 1}'] ??
                                                  //     '',
                                                  pressureStatus: allUnits[
                                                                  indexUnit][1]
                                                              [index][
                                                          'press${index + 1}'] ??
                                                      '',
                                                  // pressure:
                                                  //     e['pressure${index + 1}'],
                                                  pressure: allUnits[indexUnit]
                                                              [0][index]
                                                          ['pressure${index + 1}'] ??
                                                      ''),
                                            ),
                                          );
                                        }
                                        return Container();
                                      }).toList(),
                                    ),
                                  ],
                                ),
                                // Pos 3, 4, 5, 6
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                      allUnits[indexUnit][0].length - 2,
                                      (index) {
                                    final dataIndex = index + 2;
                                    return Expanded(
                                      child: PressureCard(
                                        position: '${dataIndex + 1}',
                                        index: index,
                                        // temperature: temperatures[dataIndex]
                                        //         ['temperature${dataIndex + 1}'] ??
                                        //     '',
                                        temperature: allUnits[indexUnit][2]
                                                    [dataIndex][
                                                'temperature${dataIndex + 1}'] ??
                                            '',
                                        // pressureStatus: pressureStatus[dataIndex]
                                        //         ['press${dataIndex + 1}'] ??
                                        //     '',
                                        pressureStatus: allUnits[indexUnit][1]
                                                    [dataIndex]
                                                ['press${dataIndex + 1}'] ??
                                            '',
                                        // pressure: pressures[dataIndex]
                                        //     ['pressure${dataIndex + 1}'],
                                        pressure: allUnits[indexUnit][0]
                                                    [dataIndex]
                                                ['pressure${dataIndex + 1}'] ??
                                            '',
                                      ),
                                    );
                                  }),
                                ),
                                // GridView.builder(
                                //   itemCount: allUnits[indexUnit][0].length -
                                //       2, // Mengurangi 2 untuk menghilangkan index pertama dan kedua
                                //   shrinkWrap: true,
                                //   physics: NeverScrollableScrollPhysics(),
                                //   gridDelegate:
                                //       SliverGridDelegateWithFixedCrossAxisCount(
                                //     crossAxisCount: 4,
                                //     childAspectRatio: 0.4,
                                //     mainAxisSpacing: 3,
                                //   ),
                                //   itemBuilder: (context, index) {
                                //     // Memperhitungkan offset karena index pertama dan kedua diabaikan
                                //     final dataIndex = index + 2;

                                //     return PressureCard(
                                //       position: '${dataIndex + 1}',
                                //       index: index,
                                //       // temperature: temperatures[dataIndex]
                                //       //         ['temperature${dataIndex + 1}'] ??
                                //       //     '',
                                //       temperature: allUnits[indexUnit][2]
                                //                   [dataIndex]
                                //               ['temperature${dataIndex + 1}'] ??
                                //           '',
                                //       // pressureStatus: pressureStatus[dataIndex]
                                //       //         ['press${dataIndex + 1}'] ??
                                //       //     '',
                                //       pressureStatus: allUnits[indexUnit][1]
                                //                   [dataIndex]
                                //               ['press${dataIndex + 1}'] ??
                                //           '',
                                //       // pressure: pressures[dataIndex]
                                //       //     ['pressure${dataIndex + 1}'],
                                //       pressure: allUnits[indexUnit][0]
                                //                   [dataIndex]
                                //               ['pressure${dataIndex + 1}'] ??
                                //           '',
                                //     );
                                //   },
                                // ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.schedule),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      unit.timestamp,
                                      style: getBlackTextStyle(),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  children: [
                                    Icon(Icons.location_on),
                                    const SizedBox(
                                      width: 12,
                                    ),
                                    Text(
                                      '${unit.lat},${unit.lon} | ${unit.alt}',
                                      style: getBlackTextStyle(),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                SizedBox(
                                  height: 80,
                                  child: ButtonWidget(
                                    color: Colors.orange,
                                    name: Row(
                                      children: [
                                        Icon(
                                          Icons.adjust,
                                          color: white,
                                        ),
                                        const SizedBox(
                                          width: 6,
                                        ),
                                        Text(
                                          'Adjust Pressure',
                                          style: getWhiteTextStyle(
                                              fontWeight: w700),
                                        ),
                                      ],
                                    ),
                                    function: () {
                                      Navigator.pushNamed(
                                          context, DailyCheckFormPage.routeName,
                                          arguments: {
                                            'unitNumber': unit.devicename,
                                          });
                                    },
                                  ),
                                ),
                                const SizedBox(
                                  height: 12,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                        child: SizedBox(
                                      height: 80,
                                      child: ButtonWidget(
                                          color: blue344BEF,
                                          name: Row(
                                            children: [
                                              Icon(
                                                Icons.copy,
                                                color: white,
                                              ),
                                              const SizedBox(
                                                width: 6,
                                              ),
                                              Text(
                                                'Copy Location',
                                                style: getWhiteTextStyle(
                                                    fontWeight: w700),
                                              ),
                                            ],
                                          ),
                                          function: () {
                                            Clipboard.setData(ClipboardData(
                                                text:
                                                    '${unit.lat},${unit.lon}'));
                                            ScaffoldMessenger.of(context)
                                                .hideCurrentSnackBar();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                              'Location copied! You can now paste it anywhere.',
                                              style: getWhiteTextStyle(),
                                            )));
                                          }),
                                    )),
                                    const SizedBox(
                                      width: 6,
                                    ),
                                    Expanded(
                                        child: SizedBox(
                                      height: 80,
                                      child: ButtonWidget(
                                          color: Colors.red,
                                          name: Row(
                                            children: [
                                              Icon(
                                                Icons.map,
                                                color: white,
                                              ),
                                              const SizedBox(
                                                width: 6,
                                              ),
                                              SizedBox(
                                                width: 90,
                                                child: Text(
                                                  'Open with Google Maps',
                                                  style: getWhiteTextStyle(
                                                      fontSize: 12,
                                                      fontWeight: w700),
                                                ),
                                              ),
                                            ],
                                          ),
                                          function: () async {
                                            await launchUrl(Uri.parse(
                                                'https://www.google.com/maps?q=${unit.lat},${unit.lon}'));
                                          }),
                                    )),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    }

                    return Container();
                  },
                ),
                // event
                // Card(
                //   shape: RoundedRectangleBorder(
                //     borderRadius: BorderRadius.circular(4),
                //   ),
                //   color: Colors.red,
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: <Widget>[
                //       Container(
                //         padding: const EdgeInsets.all(15),
                //         child: Column(
                //           crossAxisAlignment: CrossAxisAlignment.start,
                //           children: <Widget>[
                //             const Text(
                //               "- Position 3 Low Tire Pressure",
                //               style:
                //                   TextStyle(fontSize: 16, color: Colors.white),
                //             ),
                //             Container(height: 10),
                //             const Text(
                //               "- Position 4 Low Tire Pressure",
                //               style:
                //                   TextStyle(fontSize: 16, color: Colors.white),
                //             ),
                //           ],
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PressureCard extends StatelessWidget {
  const PressureCard(
      {super.key,
      required this.position,
      this.index = -1,
      required this.pressure,
      required this.pressureStatus,
      required this.temperature});

  final String position;
  final int index;
  final String pressure;
  final String temperature;
  final String pressureStatus;

  @override
  Widget build(BuildContext context) {
    log('status angin : $pressureStatus');
    return Card(
      elevation: 2,
      child: Container(
        child: Column(
          children: [
            Container(
                padding: EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: (pressureStatus == '1')
                        ? green00968A
                        : (pressureStatus == '0' && pressure != '0')
                            ? Colors.red
                            : black,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12))),
                child: Center(
                  child: Text(
                    position,
                    style: getWhiteTextStyle(fontSize: 36, fontWeight: w700),
                  ),
                )),
            Column(
              children: [
                Text(
                  pressure,
                  style: getBlackTextStyle(fontSize: 24),
                ),
                Text('Psi', style: getBlackTextStyle(fontSize: 24)),
              ],
            ),
            Divider(),
            Text('$temperature °C', style: getBlackTextStyle(fontSize: 24))
          ],
        ),
      ),
    );
  }
}
