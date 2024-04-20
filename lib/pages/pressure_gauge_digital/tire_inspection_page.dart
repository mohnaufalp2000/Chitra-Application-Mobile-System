import 'dart:developer';

import 'package:camos/core/blocs/tire/tire_bloc.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_list.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TireInspectionPage extends StatefulWidget {
  static const routeName = '/tire-inspection-page';

  const TireInspectionPage({super.key});

  @override
  State<TireInspectionPage> createState() => _TireInspectionPageState();
}

class _TireInspectionPageState extends State<TireInspectionPage> {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  int unitTireAmount = 6;
  List<Map<String, dynamic>> position = [];
  String idSite = '';
  List<String> pressure = [
    '95',
    '100',
    '105',
    '110',
    '115',
    '120',
    '125',
    '130',
    '135',
  ];
  List<String> damageType = [
    'Accident',
    'Bead Crack',
    'Boulder',
    'Bulging',
    'Bead Damage',
    'Chaffer Separation',
    'Dog Bound',
    'Foreign Object',
    'Heat Separation',
    'Inner Linner Separation',
    'Impact',
    'Repair Failure',
    'Radial Crack',
    'Run Flat',
    'Sidewall Crack',
    'Sidewall Cut',
    'Sidewall Separation',
    'Shoulder Cut',
    'Shoulder Separation',
    'Tread Chipping',
    'Tread Chungking',
    'Tread Lifting',
    'Tread Cut',
    'Tread Cut Separation',
    'Worn Out',
  ];

  List<String> pit = [];

  TextEditingController pressureCtrl = TextEditingController(text: '');
  TextEditingController damageCtrl = TextEditingController(text: '');
  TextEditingController hmCtrl = TextEditingController(text: '');
  List<String> selectedDamage = [];
  int selectedPit = -1;
  Map<String, dynamic> dataUnit = {};
  String buttonText = 'Select';

  void callTires() async {
    idSite = await getIdSitePreferences();
    log('id site daliy check : $idSite');
    if (idSite == '1') {
      idSite = await getSelectedIdSitePreferences();
    }
    if (mounted) {
      if (dataUnit != {} || dataUnit != null || dataUnit.isNotEmpty) {
        context.read<TireBloc>().add(GetUnitTiresEvent(
            idSite: idSite, unitNumber: dataUnit['unitNumber']));
      }
    }

    // tambahkan pit
    setState(() {
      // BMB COYYY
      log('id site bmb : $idSite');
      if (idSite == '52') {
        pit.add('Utara');
        pit.add('Selatan');
        pit.add('RML');
      }
    });
  }

  @override
  void initState() {
    // addPositionVariable();
    super.initState();

    callTires();
  }

  @override
  Widget build(BuildContext context) {
    dataUnit =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Daily Check Pressure',
          style: getBlackTextStyle(),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, DailyPressureListPage.routeName);
            },
            child: Padding(
              padding: const EdgeInsets.only(
                right: 8.0,
                top: 8.0,
              ),
              child: Icon(
                Icons.list,
                size: 32,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // UNIT NUMBER DAN HM UNIT
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.front_loader,
                              color: Colors.orange,
                              size: 38,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              'UNIT',
                              style: getBlackTextStyle(
                                  fontWeight: w700, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: InputFormWidget(
                              isReadOnly: true,
                              controller: TextEditingController(
                                  text: dataUnit['unitNumber']),
                              hint: ''),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.watch,
                              color: Colors.red,
                              size: 38,
                            ),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              'HM UNIT',
                              style: getBlackTextStyle(
                                  fontWeight: w700, fontSize: 18),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: InputFormWidget(
                              // isReadOnly: true,
                              controller: hmCtrl,
                              isDecimalOnly: true,
                              type: TextInputType.number,
                              hint: 'Fill HM'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.ev_station,
                    size: 38,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    'Pit',
                    style: getBlackTextStyle(fontSize: 18, fontWeight: w700),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              Row(
                children: pit.map((e) {
                  final pitIndex = pit.indexOf(e);
                  return Expanded(
                      child: Padding(
                    padding: EdgeInsets.only(
                        right: (pitIndex == 0) ? 12 : 0,
                        left: (pitIndex == pit.length - 1) ? 12 : 0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: (selectedPit == pitIndex)
                              ? Colors.orange
                              : greyF7F8F9),
                      onPressed: () {
                        setState(() {
                          selectedPit = pitIndex;
                        });
                      },
                      child: Text(
                        e,
                        style: (selectedPit == pitIndex)
                            ? getWhiteTextStyle()
                            : getBlackTextStyle(),
                      ),
                    ),
                  ));
                }).toList(),
              ),
              const SizedBox(
                height: 24,
              ),
              // POSITION
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.tire_repair,
                    size: 38,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  Text(
                    'Tire',
                    style: getBlackTextStyle(fontSize: 18, fontWeight: w700),
                  ),
                ],
              ),
              const SizedBox(
                height: 12,
              ),
              BlocBuilder<TireBloc, TireState>(
                builder: (context, state) {
                  if (state is TireLoadingState) {
                    return CircularProgressIndicator();
                  }
                  if (state is TiresLoadedState) {
                    for (var i = 0; i < state.units.length; i++) {
                      if (position.length < state.units.length) {
                        position.add({'pressure': '', 'damage': null});
                      }
                    }
                    log('ban : ${state.units.length}');

                    return Container(
                      child: Wrap(
                        spacing: 34,
                        runSpacing: 24,
                        alignment: WrapAlignment.center,
                        children: position.map((pos) {
                          final posIndex = position.indexOf(pos);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // POSITION
                              Text(
                                'Pos. ${posIndex + 1}',
                                style: getBlackTextStyle(
                                    fontSize: 16, fontWeight: w700),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              SizedBox(
                                width: 130,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return Dialog(
                                          child: Container(
                                            padding: EdgeInsets.all(20.0),
                                            child: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Text(
                                                    'Choose Pressure',
                                                    style: TextStyle(
                                                      fontSize: 24.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 16.0),
                                                  Column(),
                                                  Wrap(
                                                    children:
                                                        pressure.map((ps) {
                                                      final psIndex =
                                                          pressure.indexOf(ps);
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                right: 16,
                                                                bottom: 18),
                                                        child: ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                                  backgroundColor:
                                                                      Colors
                                                                          .green),
                                                          onPressed: () {
                                                            setState(() {
                                                              position[posIndex]
                                                                  [
                                                                  'pressure'] = ps;
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            });
                                                          },
                                                          child: Text(
                                                            ps,
                                                            style:
                                                                getWhiteTextStyle(
                                                              fontWeight: w700,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: SizedBox(
                                                          width:
                                                              double.infinity,
                                                          child: InputFormWidget(
                                                              controller:
                                                                  pressureCtrl,
                                                              isDigitOnly: true,
                                                              type:
                                                                  TextInputType
                                                                      .number,
                                                              hint:
                                                                  'Input Manual'),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 6,
                                                      ),
                                                      ElevatedButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              if (pressureCtrl
                                                                      .text !=
                                                                  '') {
                                                                position[posIndex]
                                                                        [
                                                                        'pressure'] =
                                                                    pressureCtrl
                                                                        .text;
                                                              }
                                                              pressureCtrl
                                                                  .clear();
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            });
                                                          },
                                                          child: Text('Submit'))
                                                    ],
                                                  ),
                                                  SizedBox(height: 12.0),
                                                  SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () {
                                                        pressureCtrl.clear();
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                      child: Text('Close'),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      )),
                                  child: (position[posIndex]['pressure'] == '')
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.add,
                                              color: white,
                                            ),
                                            const SizedBox(
                                              width: 6,
                                            ),
                                            Text(
                                              'Pressure',
                                              style: getWhiteTextStyle(),
                                            )
                                          ],
                                        )
                                      : Text(
                                          '${position[posIndex]['pressure']} Psi',
                                          style: getWhiteTextStyle(
                                            fontSize: 24,
                                            fontWeight: w700,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              // SELECT DAMAGE TIRE
                              SizedBox(
                                width: 130,
                                child: ElevatedButton(
                                    onPressed: () {
                                      List<bool> checkedDamageValues =
                                          List<bool>.filled(
                                              damageType.length, false);

                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return Dialog(
                                            child: Container(
                                              padding: EdgeInsets.all(20.0),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Text(
                                                    'Choose Damage Tire',
                                                    style: TextStyle(
                                                      fontSize: 24.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  SizedBox(height: 12.0),
                                                  Expanded(
                                                    child:
                                                        SingleChildScrollView(
                                                      child: Column(
                                                        children: damageType
                                                            .map((damage) {
                                                          final dmgIndex =
                                                              damageType
                                                                  .indexOf(
                                                                      damage);
                                                          return StatefulBuilder(
                                                              builder: (context,
                                                                  setState) {
                                                            return CheckboxListTile(
                                                              title:
                                                                  Text(damage),
                                                              value:
                                                                  checkedDamageValues[
                                                                      dmgIndex],
                                                              onChanged: (bool?
                                                                  value) {
                                                                setState(() {
                                                                  checkedDamageValues[
                                                                          dmgIndex] =
                                                                      value ??
                                                                          false;
                                                                });
                                                              },
                                                            );
                                                          });
                                                        }).toList(),
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(
                                                      height:
                                                          12.0), // Tambahkan sedikit jarak antara daftar checkbox dan tombol "Close"
                                                  Column(
                                                    children: [
                                                      SizedBox(
                                                        height: 42,
                                                        width: double.infinity,
                                                        child: InputFormWidget(
                                                            controller:
                                                                damageCtrl,
                                                            hint:
                                                                'Input Manual Here....'),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton(
                                                          onPressed: () {
                                                            damageCtrl.clear();
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text('Close'),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        height: 12,
                                                      ),
                                                      SizedBox(
                                                        width: double.infinity,
                                                        child: ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.green,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {});

                                                            selectedDamage
                                                                .clear();
                                                            final List<String>
                                                                tmp = [];
                                                            if (damageCtrl
                                                                        .text ==
                                                                    '' ||
                                                                damageCtrl.text
                                                                    .isNotEmpty) {
                                                              tmp.add(damageCtrl
                                                                  .text);
                                                            }
                                                            for (int i = 0;
                                                                i <
                                                                    checkedDamageValues
                                                                        .length;
                                                                i++) {
                                                              if (checkedDamageValues[
                                                                  i]) {
                                                                tmp.add(
                                                                    damageType[
                                                                        i]);
                                                              }
                                                            }
                                                            log('idx luka ban : $posIndex');
                                                            // position[posIndex]
                                                            //     ['damage'] = tmp;
                                                            if (tmp
                                                                .isNotEmpty) {
                                                              position[posIndex]
                                                                      [
                                                                      'damage'] =
                                                                  tmp;
                                                              selectedDamage
                                                                  .addAll(tmp);
                                                              log('hasil luka ban : ${position}');
                                                            }
                                                            damageCtrl.clear();

                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: Text(
                                                            'Submit',
                                                            style:
                                                                getWhiteTextStyle(
                                                              fontWeight: w700,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: blue344BEF,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        )),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Text(
                                        (position[posIndex]['damage'] == null)
                                            ? 'Damage Tire (None)'
                                            : position[posIndex]['damage']
                                                .join('\n---\n'),
                                        textAlign: TextAlign.center,
                                        style: getWhiteTextStyle(fontSize: 14),
                                      ),
                                    )),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    );
                  }

                  return Container();
                },
              ),
            ],
          ),
        ),
      )),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          height: 52,
          child: ElevatedButton(
            onPressed: () async {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              if (selectedPit == -1) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    backgroundColor: Colors.red,
                    content: Text(
                      'Please select PIT',
                      style: getWhiteTextStyle(),
                    )));
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  backgroundColor: green00968A,
                  content: Text(
                    'Data Succesfully Added',
                    style: getWhiteTextStyle(),
                  )));
              try {
                final querySnapshot = await firestore
                    .collection('daily_pressure')
                    .where('unit', isEqualTo: dataUnit['unitNumber'])
                    .get();

                if (querySnapshot.docs.isNotEmpty) {
                  final docId = querySnapshot.docs.first.id;

                  await firestore
                      .collection('daily_pressure')
                      .doc(docId)
                      .update({
                    'tanggal': DateTime.now().toIso8601String(),
                    'unit': dataUnit['unitNumber'],
                    'hm': hmCtrl.text,
                    'posisi': position.map((p) {
                      final pIndex = position.indexOf(p);
                      return {
                        'pos': '${pIndex + 1}',
                        'pressure': p['pressure'],
                        'luka': p['damage']
                      };
                    }),
                    'pit': pit[selectedPit],
                  });
                } else {
                  await firestore.collection('daily_pressure').add({
                    'tanggal': DateTime.now().toIso8601String(),
                    'unit': dataUnit['unitNumber'],
                    'hm': hmCtrl.text,
                    'posisi': position.map((p) {
                      final pIndex = position.indexOf(p);
                      return {
                        'pos': '${pIndex + 1}',
                        'pressure': p['pressure'],
                        'luka': p['damage']
                      };
                    }),
                    'pit': pit[selectedPit],
                  });
                }
              } catch (e) {}
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(
              'Save',
              style: getWhiteTextStyle(
                fontSize: 16,
                fontWeight: w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
