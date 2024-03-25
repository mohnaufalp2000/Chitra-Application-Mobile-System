import 'dart:io';

import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/data/tire.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/core/widgets/tire_axle_widget.dart';
import 'package:camos/core/widgets/input_form_widget.dart';
import 'package:camos/core/widgets/tire_widget.dart';
import 'package:camos/pages/tkph_calculator/result_tkph_page.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';

// ignore_for_file: camel_case_types, prefer_typing_uninitialized_variables

class TKHPCalculator extends StatefulWidget {
  static const routeName = '/tkph-calculator';
  const TKHPCalculator({Key? key}) : super(key: key);

  @override
  State<TKHPCalculator> createState() => _TKHPCalculatorState();
}

class _TKHPCalculatorState extends State<TKHPCalculator> {
  ScreenshotController screenshotController = ScreenshotController();

  TextEditingController idUnitCtrl = TextEditingController(text: '');
  TextEditingController emptyWeightCtrl = TextEditingController(text: '');
  TextEditingController loadedWeightCtrl = TextEditingController(text: '');
  TextEditingController onceTripDistCtrl = TextEditingController(text: '');
  TextEditingController roundCycleDistCtrl = TextEditingController(text: '');
  TextEditingController roundCycleTimeHCtrl = TextEditingController(text: '');
  TextEditingController roundCycleTimeMCtrl = TextEditingController(text: '');
  TextEditingController averageHighTempCtrl = TextEditingController(text: '');
  TextEditingController emptyFrontCtrl = TextEditingController(text: '');
  TextEditingController loadedFrontCtrl = TextEditingController(text: '');
  TextEditingController emptyRearCtrl = TextEditingController(text: '');
  TextEditingController loadedRearCtrl = TextEditingController(text: '');

  int realsiteTKPH = 0;
  double emptyWeight = 0.0;
  double loadedWeight = 0.0;
  double totalWeight = 0.0;
  double frontEmptyDistribution = 0.0;
  double frontLoadDistribution = 0.0;
  double rearEmptyDistribution = 0.0;
  double rearLoadDistribution = 0.0;
  double roundCycleDist = 0.0;
  double roundCycleTime = 0.0;
  double temperature = 0.0;
  double emptyFrontWeightTire = 0.0;
  double loadedFrontWeightTire = 0.0;
  double emptyRearWeightTire = 0.0;
  double loadedRearWeightTire = 0.0;
  double avgFrontTireLoad = 0.0;
  double avgRearTireLoad = 0.0;
  double qm = 0;
  double vm = 0;
  double basicTKPH = 0;
  double k1 = 0.0;
  double k2 = 0.0;
  double resultTkph = 0;

  bool isCalculated = false;

  @override
  void dispose() {
    // idUnitCtrl.dispose();
    // emptyWeightCtrl.dispose();
    // loadedWeightCtrl.dispose();
    // onceTripDistCtrl.dispose();
    // roundCycleDistCtrl.dispose();
    // roundCycleTimeCtrl.dispose();
    // averageHighTempCtrl.dispose();
    // emptyFrontCtrl.dispose();
    // loadedFrontCtrl.dispose();
    // emptyRearCtrl.dispose();
    // loadedRearCtrl.dispose();

    clearAllText();
    super.dispose();
  }

  clearAllText() {
    idUnitCtrl.clear();

    emptyWeightCtrl.clear();
    loadedWeightCtrl.clear();
    onceTripDistCtrl.clear();
    roundCycleDistCtrl.clear();
    roundCycleTimeHCtrl.clear();
    roundCycleTimeMCtrl.clear();
    averageHighTempCtrl.clear();
    emptyFrontCtrl.clear();
    loadedFrontCtrl.clear();
    emptyRearCtrl.clear();
    loadedRearCtrl.clear();
  }

  // Future<bool> saveLocal() async {
  //   Directory? directory;

  //   try {
  //     directory = await getExternalStorageDirectory();

  //     String newPath = '';
  //     List<String> folders = directory!.path.split('/');
  //     String fileName = idUnitCtrl.text;
  //     for (var i = 0; i < folders.length; i++) {
  //       String folder = folders[i];
  //       if (folder != 'Android') {
  //         newPath += '/$folder';
  //       } else {
  //         break;
  //       }
  //     }
  //     newPath = '$newPath/CAMOSApp';
  //     directory = Directory(newPath);
  //     print('haha ${directory.path}');

  //     if (!await directory.exists()) ;
  //     {
  //       await directory.create(recursive: true);
  //     }

  //     if (await directory.exists()) {
  //       File saveFile = File(directory.path + '/TKPH-${fileName}');
  //     }
  //     return true;
  //   } catch (e) {
  //     print('hoho ${e.toString()}');
  //   }
  //   return false;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(top: 18.0),
          child: Text(
            'TKPH Calculator',
            style: getBlackTextStyle(fontSize: 20, fontWeight: w700),
          ),
        ),
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: black),
            ),
            child: IconButton(
                onPressed: () {
                  back(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: black,
                  size: 24,
                )),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InputFormWidget(
                        controller: idUnitCtrl, hint: 'Insert ID Unit'),
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  SizedBox(
                      width: 100,
                      child: ButtonWidget(
                          name: Text('Reset'),
                          function: () {
                            clearAllText();
                            FocusManager.instance.primaryFocus?.unfocus();
                          }))
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              // EMPTY WEIGHT & LOADED WEIGHT (TON)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Empty Vehicle Weight \n(Ton)',
                          style: getBlackTextStyle(),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: InputFormWidget(
                              controller: emptyWeightCtrl,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              isDecimalOnly: true,
                              hint: '0'),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loaded Vehicle Weight \n(Ton)',
                          style: getBlackTextStyle(),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: InputFormWidget(
                              controller: loadedWeightCtrl,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              isDecimalOnly: true,
                              hint: '0'),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              // ONCE TRIP & ROUND CYCLE (DISTANCE)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Once Trip Distance \n(Km)',
                          style: getBlackTextStyle(),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: InputFormWidget(
                              controller: onceTripDistCtrl,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              isDecimalOnly: true,
                              hint: '0'),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Round Cycle Dist. \n(Km)',
                          style: getBlackTextStyle(),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: InputFormWidget(
                              controller: roundCycleDistCtrl,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              isDecimalOnly: true,
                              hint: '0'),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              // ROUND CYCLE TIME & AVERAGE HIGH TEMP
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Round Cycle Time \n(H & M)',
                          style: getBlackTextStyle(),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: InputFormWidget(
                                    controller: roundCycleTimeHCtrl,
                                    type: TextInputType.number,
                                    isDigitOnly: true,
                                    hint: 'Hours'),
                              ),
                            ),
                            // const SizedBox(
                            //   width: 12,
                            // ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                ':',
                                style: getBlackTextStyle(
                                    fontSize: 16, fontWeight: w700),
                              ),
                            ),
                            Expanded(
                              child: SizedBox(
                                width: double.infinity,
                                child: InputFormWidget(
                                    controller: roundCycleTimeMCtrl,
                                    type: TextInputType.number,
                                    isDigitOnly: true,
                                    hint: 'Minutes'),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Average High Temp. \n(°C)',
                          style: getBlackTextStyle(),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: InputFormWidget(
                              controller: averageHighTempCtrl,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              isDecimalOnly: true,
                              hint: '0'),
                        )
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              // Empty & loaded Weight Dist. Front %
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Empty Weight Dist. \nFront %',
                          style: getBlackTextStyle(),
                        ),
                        const Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Divider(
                            thickness: 1,
                            color: greyDADADA,
                          ),
                        ),
                        // BUTTON ADD TIRE FRONT
                        Container(
                          height: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // AXLE 1
                              Text(
                                'Number of Tires on \nAxle 1',
                                style: getGreyTextStyle(grey6A707C),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.05,
                                    width: MediaQuery.of(context).size.width *
                                        0.16,
                                    child: ElevatedButton(
                                        onPressed: () {
                                          if ((leftFrontTire.length +
                                                  rightFrontTire.length) <
                                              4) {
                                            leftFrontTire.add(TireWidget());
                                            rightFrontTire.add(TireWidget());
                                          }
                                          setState(() {});
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: Text(
                                          '+',
                                          style:
                                              getWhiteTextStyle(fontSize: 24),
                                        )),
                                  ),
                                  Text(
                                      '${leftFrontTire.length + rightFrontTire.length}',
                                      style: getBlackTextStyle(fontSize: 20)),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.05,
                                    width: MediaQuery.of(context).size.width *
                                        0.16,
                                    child: ElevatedButton(
                                        onPressed: () {
                                          if ((leftFrontTire.length +
                                                  rightFrontTire.length) >
                                              2) {
                                            leftFrontTire.removeLast();
                                            rightFrontTire.removeLast();
                                          }
                                          setState(() {});
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: Text('-',
                                            style: getWhiteTextStyle(
                                                fontSize: 24))),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: InputFormWidget(
                              controller: emptyFrontCtrl,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              hint: '0 (%)',
                              isDecimalOnly: true,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),

                        TireAxleWidget(
                          leftTire: leftFrontTire,
                          rightTire: rightFrontTire,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  // Loaded Weight Dist. Front %
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loaded Weight Dist. \nFront %',
                          style: getBlackTextStyle(),
                        ),
                        const Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Divider(
                            thickness: 1,
                            color: greyDADADA,
                          ),
                        ),
                        Container(
                          height: 100,
                        ),
                        Center(
                          child: SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: InputFormWidget(
                              controller: loadedFrontCtrl,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              hint: '0 (%)',
                              isDecimalOnly: true,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TireAxleWidget(
                          leftTire: leftFrontTire,
                          rightTire: rightFrontTire,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              // Empty Weight Dist. Rear %
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Empty Weight Dist. \nRear %',
                          style: getBlackTextStyle(),
                        ),
                        const Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Divider(
                            thickness: 1,
                            color: greyDADADA,
                          ),
                        ),
                        // BUTTON ADD TIRE REAR
                        Container(
                          height: 100,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // AXLE 2
                              Text(
                                'Number of Tires on \nAxle 2',
                                style: getGreyTextStyle(grey6A707C),
                              ),
                              const SizedBox(
                                height: 12,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.05,
                                    width: MediaQuery.of(context).size.width *
                                        0.16,
                                    child: ElevatedButton(
                                        onPressed: () {
                                          if ((leftRearTire.length +
                                                  rightRearTire.length) <
                                              4) {
                                            leftRearTire.add(TireWidget());
                                            rightRearTire.add(TireWidget());
                                          }

                                          setState(() {});
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                        child: Text(
                                          '+',
                                          style:
                                              getWhiteTextStyle(fontSize: 24),
                                        )),
                                  ),
                                  Text(
                                      '${leftRearTire.length + rightRearTire.length}',
                                      style: getBlackTextStyle(fontSize: 20)),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.05,
                                    width: MediaQuery.of(context).size.width *
                                        0.16,
                                    child: ElevatedButton(
                                        onPressed: () {
                                          if ((leftRearTire.length +
                                                  rightRearTire.length) >
                                              2) {
                                            leftRearTire.removeLast();
                                            rightRearTire.removeLast();
                                          }

                                          setState(() {});
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        child: Text('-',
                                            style: getWhiteTextStyle(
                                                fontSize: 24))),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        Center(
                          child: SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: InputFormWidget(
                              controller: emptyRearCtrl,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              hint: '0 (%)',
                              isDecimalOnly: true,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TireAxleWidget(
                          leftTire: leftRearTire,
                          rightTire: rightRearTire,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 16,
                  ),
                  // Loaded Weight Dist. Rear %
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loaded Weight Dist. \nRear %',
                          style: getBlackTextStyle(),
                        ),
                        const Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Divider(
                            thickness: 1,
                            color: greyDADADA,
                          ),
                        ),
                        const SizedBox(
                          height: 100,
                        ),
                        Center(
                          child: SizedBox(
                            height: 50,
                            width: double.infinity,
                            child: InputFormWidget(
                              controller: loadedRearCtrl,
                              type: const TextInputType.numberWithOptions(
                                  decimal: true),
                              hint: '0 (%)',
                              isDecimalOnly: true,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        TireAxleWidget(
                          leftTire: leftRearTire,
                          rightTire: rightRearTire,
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
                children: [
                  // TKPH RESULT
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TKPH',
                          style: getBlackTextStyle(
                            fontSize: 18,
                          )),
                      const SizedBox(
                        width: 6,
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.7,
                        child: Text(realsiteTKPH.toString(),
                            style: getBlackTextStyle(
                              fontSize: 32,
                              fontWeight: w700,
                            )),
                      )
                    ],
                  ),
                ],
              ),
              const SizedBox(
                height: 24,
              ),
              SizedBox(
                height: 50,
                child: ButtonWidget(
                    name: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Save & Share',
                          style: getWhiteTextStyle(),
                        )
                      ],
                    ),
                    function: (isCalculated)
                        ? () {
                            final data = {
                              'idUnit': idUnitCtrl.text,
                              'totalVehicleWeight': '$totalWeight',
                              'emptyFrontWeightTire': '$emptyFrontWeightTire',
                              'loadedFrontWeightTire': '$loadedFrontWeightTire',
                              'avgFrontLoad': '$avgFrontTireLoad',
                              'emptyRearWeightTire': '$emptyRearWeightTire',
                              'loadedRearWeightTire': '$loadedRearWeightTire',
                              'avgRearLoad': '$avgRearTireLoad',
                              // 'totalVehicleWeight': currencyFormat(
                              //     '${int.parse(totalWeight.round().toString())}',
                              //     ''),
                              // 'emptyFrontWeightTire': currencyFormat(
                              //     '${int.parse(emptyFrontWeightTire.round().toString())}',
                              //     ''),
                              // 'loadedFrontWeightTire': currencyFormat(
                              //     '${int.parse(loadedFrontWeightTire.round().toString())}',
                              //     ''),
                              // 'avgFrontLoad': currencyFormat(
                              //     '${int.parse(avgFrontTireLoad.round().toString())}',
                              //     ''),
                              // 'emptyRearWeightTire': currencyFormat(
                              //     '${int.parse(emptyRearWeightTire.round().toString())}',
                              //     ''),
                              // 'loadedRearWeightTire': currencyFormat(
                              //     '${int.parse(loadedRearWeightTire.round().toString())}',
                              //     ''),
                              // 'avgRearLoad': currencyFormat(
                              //     '${int.parse(avgRearTireLoad.round().toString())}',
                              //     ''),
                              'qm': qm.toString(),
                              'roundCycleDistance': roundCycleDist.toString(),
                              'roundCycleTime': roundCycleTime.toString(),
                              'vm': vm.toString(),
                              'basicTkph': basicTKPH.toString(),
                              'k1': k1.toString(),
                              'k2': k2.toString(),
                              'realsiteTkph': realsiteTKPH.toString(),
                            };
                            Navigator.pushNamed(
                              context,
                              ResultTkphPage.routeName,
                              arguments: data,
                            );
                          }
                        : null),
              ),
              const SizedBox(
                height: 12,
              ),
              // BUTTON CALCULATE
              ButtonWidget(
                  name: Text(
                    'Calculate',
                    style: getWhiteTextStyle(),
                  ),
                  function: () {
                    // VALIDATE FORM
                    if (idUnitCtrl.text == '' ||
                        emptyWeightCtrl.text == '' ||
                        loadedWeightCtrl.text == '' ||
                        onceTripDistCtrl.text == '' ||
                        roundCycleDistCtrl.text == '' ||
                        roundCycleTimeHCtrl.text == '' ||
                        roundCycleTimeMCtrl.text == '' ||
                        averageHighTempCtrl.text == '' ||
                        emptyFrontCtrl.text == '' ||
                        loadedFrontCtrl.text == '' ||
                        emptyRearCtrl.text == '' ||
                        loadedRearCtrl.text == '') {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Please input data first!')));
                      return;
                    }

                    // ACTIVATE BTN SAVE AND SHARE
                    isCalculated = true;

                    // DEFINE DATA
                    final frontTires =
                        leftFrontTire.length + rightFrontTire.length;
                    final rearTires =
                        leftRearTire.length + rightRearTire.length;
                    emptyWeight = double.parse(emptyWeightCtrl.text);
                    print('emptyWeight : $emptyWeight');
                    loadedWeight = double.parse(loadedWeightCtrl.text);
                    print('loadedWeight : $loadedWeight');
                    totalWeight = emptyWeight + loadedWeight;
                    print('totalWeight : $totalWeight');
                    frontEmptyDistribution =
                        double.parse(emptyFrontCtrl.text) / 100;
                    frontLoadDistribution =
                        double.parse(loadedFrontCtrl.text) / 100;
                    rearEmptyDistribution =
                        double.parse(emptyRearCtrl.text) / 100;
                    rearLoadDistribution =
                        double.parse(loadedRearCtrl.text) / 100;
                    roundCycleDist = double.parse(roundCycleDistCtrl.text);
                    roundCycleTime = convertTime(
                        '${roundCycleTimeHCtrl.text},${roundCycleTimeMCtrl.text}');
                    temperature = double.parse(averageHighTempCtrl.text);

                    // Calculation //

                    // QM
                    emptyFrontWeightTire =
                        (emptyWeight * frontEmptyDistribution) / frontTires;
                    print('emptyFrontWeightTire : $emptyFrontWeightTire');
                    loadedFrontWeightTire =
                        (totalWeight * frontLoadDistribution) / frontTires;
                    print('loadedFrontWeightTire : $loadedFrontWeightTire');
                    emptyRearWeightTire =
                        (emptyWeight * rearEmptyDistribution) / rearTires;
                    print('object : $rearTires');
                    print('emptyRearWeightTire : $emptyRearWeightTire');
                    loadedRearWeightTire =
                        (totalWeight * rearLoadDistribution) / rearTires;
                    print('loadedRearWeightTire : $loadedRearWeightTire');
                    avgFrontTireLoad =
                        (emptyFrontWeightTire + loadedFrontWeightTire) / 2;
                    print('avgFrontTireLoad : $avgFrontTireLoad');
                    avgRearTireLoad =
                        (emptyRearWeightTire + loadedRearWeightTire) / 2;
                    print('avgRearTireLoad : $avgRearTireLoad');
                    qm = avgFrontTireLoad;
                    print('qm : $qm');

                    // VM
                    vm = (roundCycleDist / roundCycleTime);
                    print('vm : $vm');

                    // BASIC TKPH
                    basicTKPH = qm * vm;
                    print('basicTKPH : $basicTKPH');

                    // REALSITE TKPH
                    k1 = k1Coefficients(roundCycleDist);
                    print('k1 : $k1');
                    k2 = 1 /
                        (1 -
                            (((temperature < 38) ? 0.25 : 0.40) *
                                    (temperature - 38)) /
                                vm);
                    // k2 = 1 /
                    //     (1 -
                    //         (((temperature < 38) ? 0.25 : 0.40) *
                    //                 (temperature - 38)) /
                    //             vm);
                    print('k2 : $k2');
                    resultTkph = basicTKPH * k1 * k2;
                    realsiteTKPH = resultTkph.round();
                    print('realsiteTKPH : $realsiteTKPH');

                    setState(() {});
                  }),
            ],
          ),
        ),
      ),
    );
  }
}
