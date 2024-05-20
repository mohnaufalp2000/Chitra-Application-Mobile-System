import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:flutter/material.dart';

class DetailNonTireRunningTireInspection extends StatefulWidget {
  static const routeName = '/detail-non-tire-running';
  const DetailNonTireRunningTireInspection({super.key});

  @override
  State<DetailNonTireRunningTireInspection> createState() =>
      _DetailNonTireRunningTireInspectionState();
}

class _DetailNonTireRunningTireInspectionState
    extends State<DetailNonTireRunningTireInspection> {
  List<Map<String, dynamic>> tires = [
    {
      'position': '1',
      'pressure': 0,
      'brand': '',
      'injury': '',
    },
    {
      'position': '2',
      'pressure': 0,
      'brand': '',
      'injury': '',
    },
    {
      'position': '3',
      'pressure': 0,
      'brand': '',
      'injury': '',
    },
    {
      'position': '4',
      'pressure': 0,
      'brand': '',
      'injury': '',
    },
    {
      'position': '5',
      'pressure': 0,
      'brand': '',
      'injury': '',
    },
    {
      'position': '6',
      'pressure': 0,
      'brand': '',
      'injury': '',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('Form Tire Inspection', context),
      body: SafeArea(
          child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                child: TextFormField(
                  controller: TextEditingController(text: ''),
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  // validator: _validateUserName,
                  onFieldSubmitted: (String value) {
                    // FocusScope.of(context).requestFocus(_passwordEmail);
                  },
                  decoration: InputDecoration(
                      labelText: 'Unit Id', icon: Icon(Icons.front_loader)),
                ),
              ),
              const SizedBox(
                height: 18,
              ),
              Column(
                children: tires.map((tire) {
                  return Container(
                    margin: EdgeInsets.only(bottom: 24),
                    child: Card(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 24.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(Icons.radio_button_checked),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  'Position ${tire['position']}',
                                  style: getBlackTextStyle(
                                    fontSize: 20,
                                    fontWeight: w700,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              child: TextFormField(
                                controller: TextEditingController(text: ''),
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                // validator: _validateUserName,
                                onFieldSubmitted: (String value) {
                                  // FocusScope.of(context).requestFocus(_passwordEmail);
                                },
                                decoration: InputDecoration(
                                    labelText: 'Pressure (Psi)',
                                    icon: Icon(Icons.tire_repair)),
                              ),
                            ),
                            Container(
                              child: TextFormField(
                                controller: TextEditingController(text: ''),
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                // validator: _validateUserName,
                                onFieldSubmitted: (String value) {
                                  // FocusScope.of(context).requestFocus(_passwordEmail);
                                },
                                decoration: InputDecoration(
                                    labelText: 'Brand', icon: Icon(Icons.abc)),
                              ),
                            ),
                            Container(
                              child: TextFormField(
                                controller: TextEditingController(text: ''),
                                keyboardType: TextInputType.text,
                                textInputAction: TextInputAction.next,
                                // validator: _validateUserName,
                                onFieldSubmitted: (String value) {
                                  // FocusScope.of(context).requestFocus(_passwordEmail);
                                },
                                decoration: InputDecoration(
                                    labelText: 'Injury',
                                    icon: Icon(Icons.dangerous)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )
            ],
          ),
        ),
      )),
    );
  }
}
