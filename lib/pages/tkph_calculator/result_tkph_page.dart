import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/utils/functions/functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:open_file/open_file.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';

class ResultTkphPage extends StatefulWidget {
  static const routeName = '/result-tkph-page';
  const ResultTkphPage({super.key});

  @override
  State<ResultTkphPage> createState() => _ResultTkphPageState();
}

class _ResultTkphPageState extends State<ResultTkphPage> {
  ScreenshotController screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final data =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: green00968A,
        title: Text(
          'TKPH Calculation Details',
          style: getWhiteTextStyle(fontSize: 20),
        ),
      ),
      body: SafeArea(
          child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Screenshot(
            controller: screenshotController,
            child: Column(
              children: [
                const SizedBox(
                  height: 24,
                ),
                Image.asset(
                  '${iconPath}/logo_camos_icon.png',
                  width: 120,
                  height: 120,
                ),
                const SizedBox(
                  height: 24,
                ),
                Card(
                  elevation: 2,
                  child: Container(
                    width: double.infinity,
                    color: greyF7F8F9,
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Row(
                        children: [
                          Icon(Icons.front_loader),
                          const SizedBox(
                            width: 12,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Unit ID',
                                style: getBlackTextStyle(fontWeight: w700),
                              ),
                              const SizedBox(
                                height: 6,
                              ),
                              Text(
                                data['idUnit'],
                                style: getBlackTextStyle(fontSize: 24),
                              )
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 12,
                ),
                Card(
                  elevation: 2,
                  child: Container(
                    width: double.infinity,
                    color: greyF7F8F9,
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calculation Details',
                          style:
                              getBlackTextStyle(fontSize: 18, fontWeight: w700),
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Divider(
                          thickness: 2,
                        ),
                        const SizedBox(
                          height: 6,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Vehicle Weight',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${data['totalVehicleWeight']} Ton',
                              style: getBlackTextStyle(),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Front \nEmpty weight per tire',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${double.parse(data['emptyFrontWeightTire']).toStringAsFixed(1)} Ton',
                              style: getBlackTextStyle(),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Front \nLoaded weight per tire',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${double.parse(data['loadedFrontWeightTire']).toStringAsFixed(1)} Ton',
                              style: getBlackTextStyle(),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Front  \nAverage tire load',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${double.parse(data['avgFrontLoad']).toStringAsFixed(1)} Ton',
                              style: getBlackTextStyle(),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rear \nEmpty weight per tire',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${double.parse(data['emptyRearWeightTire']).toStringAsFixed(1)} Ton',
                              style: getBlackTextStyle(),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rear \nLoaded weight per tire',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${double.parse(data['loadedRearWeightTire']).toStringAsFixed(1)} Ton',
                              style: getBlackTextStyle(),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Rear \nAverage tire load',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${double.parse(data['avgRearLoad']).toStringAsFixed(1)} Ton',
                              style: getBlackTextStyle(),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Average load per tire',
                              style: getBlackTextStyle(
                                  fontWeight: w700, fontSize: 16),
                            ),
                            Text(
                              (double.parse(data['avgFrontLoad']) >
                                      double.parse(data['avgRearLoad']))
                                  ? '${double.parse(data['avgFrontLoad']).toStringAsFixed(1)} Ton'
                                  : '${double.parse(data['avgRearLoad']).toStringAsFixed(1)} Ton',
                              style: getBlackTextStyle(
                                  fontWeight: w700, fontSize: 16),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Divider(
                            thickness: 2,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Round Cycle Distance',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${data['roundCycleDistance']} km',
                              style: getBlackTextStyle(),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Round Cycle Time',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${double.parse(data['roundCycleTime']).toStringAsFixed(2)} hours',
                              style: getBlackTextStyle(),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Distance / Hour',
                              style: getBlackTextStyle(
                                  fontWeight: w700, fontSize: 16),
                            ),
                            Text(
                              '${double.parse(data['vm']).toStringAsFixed(2)} KMPH',
                              style: getBlackTextStyle(
                                  fontWeight: w700, fontSize: 16),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: Divider(
                            thickness: 2,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'K1',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              data['k1'],
                              style: getBlackTextStyle(),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'K2',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${double.parse(data['k2']).toStringAsFixed(3)}',
                              style: getBlackTextStyle(),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Basic TKPH',
                              style: getBlackTextStyle(),
                            ),
                            Text(
                              '${double.parse(data['basicTkph']).toStringAsFixed(1)} TKPH',
                              style: getBlackTextStyle(),
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Realsite TKPH',
                              style: getBlackTextStyle(
                                  fontWeight: w700, fontSize: 16),
                            ),
                            Text(
                              '${data['realsiteTkph']} TKPH',
                              style: getBlackTextStyle(
                                  fontWeight: w700, fontSize: 16),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 24,
                ),
              ],
            ),
          ),
        ),
      )),
      bottomNavigationBar: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () async {
                requestStoragePermission();

                final image = await capturePage(screenshotController);
                final pdf = createPdf(image!);
                final outputFile =
                    await createFolderPath(data['idUnit'], 'tkph');
                final filePath = await savePdf(pdf, outputFile);
                print('gambar $filePath');

                if (filePath != null || filePath != '') {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor: green00968A,
                      content: Text(
                        'Successfull Save Data!',
                        style: getWhiteTextStyle(),
                      )));
                }
              },
              child: Container(
                padding: EdgeInsets.all(24),
                color: blue344BEF,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.save,
                      color: white,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      'SAVE',
                      textAlign: TextAlign.center,
                      style: getWhiteTextStyle(
                        fontSize: 20,
                        fontWeight: w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () async {
                final image = await capturePage(screenshotController);
                final pdf = createPdf(image!);
                final outputFile =
                    await createFolderPath(data['idUnit'], 'tkph');
                final filePath = await savePdf(pdf, outputFile);
                sendEmailWithAttachment(filePath, 'tkph');
              },
              child: Container(
                padding: EdgeInsets.all(24),
                color: green00968A,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.share,
                      color: white,
                    ),
                    const SizedBox(
                      width: 12,
                    ),
                    Text(
                      'SHARE',
                      textAlign: TextAlign.center,
                      style: getWhiteTextStyle(
                        fontSize: 20,
                        fontWeight: w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
