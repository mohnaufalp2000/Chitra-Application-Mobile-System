import 'dart:developer';

import 'package:camos/core/blocs/unit/unit_bloc.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_pressure_list.dart';
import 'package:camos/pages/pressure_gauge_digital/tire_inspection_form_page.dart';
import 'package:camos/pages/pressure_gauge_digital/daily_check_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectUnitPage extends StatefulWidget {
  static const routeName = '/select-unit-page';
  SelectUnitPage({super.key});

  @override
  State<SelectUnitPage> createState() => _SelectUnitPageState();
}

class _SelectUnitPageState extends State<SelectUnitPage> {
  String searchQuery = '';
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    callUnits();
  }

  Future<void> callUnits() async {
    String id = await getIdSitePreferences();
    String idOffice = await getIdSitePreferences();
    log('message : $id');
    if (id == '1' || id == '2') {
      id = await getSelectedIdSitePreferences();
    }
    log('test call units : $isOnline');
    context.read<UnitBloc>().add(GetUnitsEvent(
        idSite: id,
        isOnline: (idOffice == '1' || idOffice == '2') ? true : isOnline));
  }

  Future<String> getActualIdSite() async {
    final actIdSite = await getIdSitePreferences();

    return actIdSite;
  }

  @override
  Widget build(BuildContext context) {
    final inspectionType = ModalRoute.of(context)?.settings.arguments as String;

    return Scaffold(
      appBar: (inspectionType == 'daily_check')
          ? AppBar(
              centerTitle: true,
              title: Text(
                'Daily Check Pressure',
                style: getBlackTextStyle(),
              ),
              actions: [
                InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                        context, DailyPressureListPage.routeName);
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
            )
          : appBarWidget('Select Unit First', context),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: BlocConsumer<UnitBloc, UnitState>(
            listener: (context, state) {
              if (state is UnitErrorState) {
                setState(() {
                  isOnline = !isOnline;
                });
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(
                          'Please check your internet connection!',
                          style: getBlackTextStyle(),
                        ),
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: Text('Okay'))
                        ],
                      );
                    });
              }
            },
            builder: (context, state) {
              if (state is UnitLoadingState) {
                return Center(child: CircularProgressIndicator());
              }

              if (state is UnitLoadedState) {
                log('kondisi state : ${state.units.length}');

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                          hintText: 'Search... (Unit Number or Model)',
                          hintStyle: getGreyTextStyle(grey8391A1),
                          prefixIcon: Icon(Icons.search)),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    Text(
                      'Total Unit : ${state.units.length.toString()}',
                      style: getGreyTextStyle(grey8391A1),
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    FutureBuilder(
                        future: getActualIdSite(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return Container();
                          }

                          final data = snapshot.data;
                          log('id site future builder : $data');

                          if (data != '1' && data != '2' && data != '3') {
                            return FutureBuilder(
                                future: getActualIdSite(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Container();
                                  }

                                  final data = snapshot.data;
                                  log('id site future builder : $data');

                                  if (data != '1' &&
                                      data != '2' &&
                                      data != '3') {
                                    return SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            isOnline =
                                                !isOnline; // Toggle the status
                                            callUnits();
                                          });
                                        },
                                        style: ElevatedButton.styleFrom(
                                          primary: Colors.green,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.fire_truck,
                                              color: white,
                                            ),
                                            const SizedBox(
                                              width: 12,
                                            ),
                                            Text(
                                              'Update Unit',
                                              style: getWhiteTextStyle(),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                  return Container();
                                });
                          }
                          return Container();
                        }),
                    const SizedBox(
                      height: 12,
                    ),
                    (state.units == null || state.units.isEmpty)
                        ? Text(
                            'No Data, please press Get Unit to get data!',
                            textAlign: TextAlign.center,
                            style: getBlackTextStyle(fontSize: 18),
                          )
                        : Column(
                            children: state.units.map((unit) {
                              if (searchQuery.isNotEmpty &&
                                  !unit.unitNumber!
                                      .toLowerCase()
                                      .contains(searchQuery) &&
                                  !unit.model!
                                      .toLowerCase()
                                      .contains(searchQuery)) {
                                return Container();
                              }
                              return InkWell(
                                onTap: () {
                                  switch (inspectionType) {
                                    case 'daily_check':
                                      Navigator.pushNamed(
                                          context, DailyCheckFormPage.routeName,
                                          arguments: {
                                            'unitNumber': unit.unitNumber,
                                          });
                                      break;
                                    case 'tire_inspection':
                                      Navigator.pushNamed(context,
                                          TireInspectionFormPage.routeName,
                                          arguments: {
                                            'unitNumber': unit.unitNumber,
                                            'hm': unit.hm,
                                          });
                                      break;
                                  }
                                },
                                child: Container(
                                  margin: EdgeInsets.symmetric(vertical: 8.0),
                                  padding: EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.front_loader,
                                      color: Colors.orange,
                                    ),
                                    title: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        '${unit.unitNumber}',
                                        style: getBlackTextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${unit.model}',
                                      style: getGreyTextStyle(grey6A707C),
                                    ),
                                    trailing: Icon(Icons.arrow_forward_ios),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ],
                );
              }

              return Container();
            },
          ),
        ),
      )),
    );
  }
}
