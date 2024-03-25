import 'dart:developer';

import 'package:camos/core/blocs/unit/unit_bloc.dart';
import 'package:camos/core/services/shared_preferences/shared_preferences.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/pressure_gauge_digital/pgd_page.dart';
import 'package:camos/pages/pressure_gauge_digital/tire_inspection_page.dart';
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

  @override
  void initState() {
    super.initState();
    callUnits();
  }

  void callUnits() async {
    String id = await getIdSitePreferences();
    log('message : $id');
    if (id == '1' || id == '2') {
      id = await getSelectedIdSitePreferences();
    }
    context.read<UnitBloc>().add(GetUnitsEvent(idSite: id));
  }

  @override
  Widget build(BuildContext context) {
    final inspectionType = ModalRoute.of(context)?.settings.arguments as String;

    return Scaffold(
      appBar: appBarWidget('Select Unit First', context),
      body: SafeArea(
          child: SingleChildScrollView(
        child: Container(
          margin: EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: BlocBuilder<UnitBloc, UnitState>(
            builder: (context, state) {
              if (state is UnitLoadingState) {
                return Center(child: CircularProgressIndicator());
              }

              if (state is UnitLoadedState) {
                return Column(
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
                    Column(
                      children: state.units.map((unit) {
                        if (searchQuery.isNotEmpty &&
                            !unit.unitNumber!
                                .toLowerCase()
                                .contains(searchQuery) &&
                            !unit.model!.toLowerCase().contains(searchQuery)) {
                          return Container();
                        }
                        return InkWell(
                          onTap: () {
                            switch (inspectionType) {
                              case 'daily_check':
                                Navigator.pushNamed(
                                    context, TireInspectionPage.routeName,
                                    arguments: {
                                      'unitNumber': unit.unitNumber,
                                    });
                                break;
                              case 'tire_inspection':
                                Navigator.pushNamed(context, PgdPage.routeName,
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
                                padding: const EdgeInsets.only(bottom: 4.0),
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
