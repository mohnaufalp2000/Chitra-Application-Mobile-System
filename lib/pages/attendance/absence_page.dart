import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import '../../core/navigator/navigation_route.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/utils/functions/functions.dart';
import 'presence_camera_page.dart';
import 'presence_page.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

class AbsencePage extends StatefulWidget {
  static const routeName = '/absence-page';
  const AbsencePage({super.key});

  @override
  State<AbsencePage> createState() => _AbsencePageState();
}

class _AbsencePageState extends State<AbsencePage> {
  File? imageFile; // Menyimpan file gambar yang diambil dari kamera
  final GlobalKey globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
          child: Column(
        children: [(imageFile != null) ? Image.file(imageFile!) : Container()],
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
                          Navigator.pop(context);
                          Navigator.pushNamed(
                              context, PresenceCameraPage.routeName);
                          // final image = await ImagePicker().pickImage(
                          //     imageQuality: 50,
                          //     source: ImageSource.camera,
                          //     preferredCameraDevice: CameraDevice.front);

                          // img.Image? originalImage = img
                          //     .decodeImage(File(image!.path).readAsBytesSync());

                          // img.drawString(
                          //   originalImage!,
                          //   'Think Different',
                          //   font: img.arial48,
                          // );
                          // var encodeImage =
                          //     img.encodeJpg(originalImage, quality: 100);
                          // var finalImage = File(image.path)
                          //   ..writeAsBytesSync(encodeImage);
                          // setState(() {
                          //   imageFile = File(finalImage.path);
                          // });
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
}
