import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../../core/blocs/attendance/attendance_bloc.dart';
import '../../core/services/local_database/attendance/attendance_entity.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/utils/functions/functions.dart';
import '../../main.dart';
import '../../objectbox.g.dart';
import 'absence_page.dart';
import 'presence_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshot/screenshot.dart';

class PresenceCameraResultPage extends StatefulWidget {
  static const routeName = '/presence-camera-result-page';
  const PresenceCameraResultPage({super.key});

  @override
  State<PresenceCameraResultPage> createState() =>
      _PresenceCameraResultPageState();
}

class _PresenceCameraResultPageState extends State<PresenceCameraResultPage> {
  @override
  Widget build(BuildContext context) {
    final cameraResult =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    ScreenshotController screenshotController = ScreenshotController();

    return Scaffold(
      // body: SafeArea(
      //     child: Column(
      //   children: [
      //     Expanded(
      //         child: Image.file(
      //       File(
      //         (cameraResult['imagePath'] as XFile).path,
      //       ),
      //       fit: BoxFit.cover,
      //     )),
      //     Container(
      //       child: Text('${cameraResult['date1']}'),
      //     )
      //   ],
      // )),
      body: SafeArea(
        child: Stack(
          children: [
            Screenshot(
              controller: screenshotController,
              child: Column(
                children: [
                  Expanded(
                    child: Container(
                      height: double.infinity,
                      width: double.infinity,
                      child: Image.file(
                        File((cameraResult['imagePath'] as XFile).path),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    color: white.withOpacity(0.4),
                    width: double.infinity,
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cameraResult['date1']}',
                          style: getBlackTextStyle(),
                        ),
                        Row(
                          children: [
                            Icon(Icons.calendar_month),
                            const SizedBox(width: 12),
                            Text(
                              '${cameraResult['date2']}',
                              style: getBlackTextStyle(
                                fontSize: 16,
                                fontWeight: w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.timer_rounded),
                            const SizedBox(width: 12),
                            Text(
                              '${cameraResult['time']}',
                              style: getBlackTextStyle(
                                fontSize: 16,
                                fontWeight: w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_pin),
                            const SizedBox(width: 12),
                            Container(
                              width: 160,
                              child: Text(
                                '${cameraResult['location']}',
                                style: getBlackTextStyle(
                                  fontSize: 16,
                                  fontWeight: w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 135,
              child: Container(
                height: 125,
                color: grey6A707C.withOpacity(0.4),
                width: double.infinity,
                padding: EdgeInsets.all(15),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    optionButton('retry', screenshotController, cameraResult),
                    optionButton('save', screenshotController, cameraResult),
                    optionButton('cancel', screenshotController, cameraResult),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget optionButton(String type, ScreenshotController screenshotController,
      Map<String, dynamic> cameraResult) {
    return Expanded(
        child: Column(
      children: [
        RawMaterialButton(
          onPressed: () async {
            switch (type) {
              case 'retry':
                Navigator.pop(context);
                break;
              case 'save':
                final image = await capturePage(screenshotController);
                // context.read<AttendanceBloc>().add(PresenceAttendanceEvent(
                //     context: context,
                //     image: image!,
                //     selectedShift: cameraResult['selectedShift']));
                Navigator.popUntil(
                    context, ModalRoute.withName(PresencePage.routeName));
                //                     print('gambar sc : $image');
                //  String imgString = base64Encode(image!);
                presence();
                break;
              case 'cancel':
                Navigator.popUntil(
                    context, ModalRoute.withName(AbsencePage.routeName));
                break;
            }
          },
          elevation: 2.0,
          fillColor: Colors.white,
          child: Icon(
            (type == 'save')
                ? Icons.save
                : (type == 'retry')
                    ? Icons.refresh
                    : Icons.close,
            size: 35.0,
          ),
          padding: EdgeInsets.all(15.0),
          shape: CircleBorder(),
        ),
        const SizedBox(
          height: 6,
        ),
        Text(
          (type == 'save')
              ? 'Save'
              : (type == 'retry')
                  ? 'Retry'
                  : 'Cancel',
          style: getWhiteTextStyle(),
        )
      ],
    ));
  }
}

void presence() {
  final Box<AttendanceEntity> attendanceBox = store.box<AttendanceEntity>();
}
