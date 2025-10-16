import 'dart:developer';

import 'package:camera/camera.dart';
import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../main.dart';
import 'image_preview.dart';
import 'package:flutter/material.dart';

class TestCamera extends StatefulWidget {
  const TestCamera({super.key});

  @override
  State<TestCamera> createState() => _TestCameraState();
}

class _TestCameraState extends State<TestCamera> {
  late CameraController cameraController;
  final List<String> img = [];
  bool _flashEffectVisible = false;

  @override
  void initState() {
    super.initState();
    cameraController = CameraController(cameras[0], ResolutionPreset.max);
    cameraController.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            height: double.infinity,
            child: CameraPreview(cameraController),
          ),
          AnimatedContainer(
            duration: Duration(milliseconds: 150),
            color: _flashEffectVisible ? Colors.black : Colors.transparent,
            curve: Curves.easeInOut,
            width: double.infinity,
            height: double.infinity,
            child: _flashEffectVisible
                ? null
                : SizedBox(), // Hide the container when not needed
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              height: 100,
              color: Colors.white.withOpacity(0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RawMaterialButton(
                    onPressed: () {
                      Navigator.pop(context, img);
                    },
                    elevation: 2.0,
                    fillColor: Colors.white,
                    child: Icon(
                      Icons.arrow_back,
                      size: 35.0,
                    ),
                    padding: EdgeInsets.all(15.0),
                    shape: CircleBorder(),
                  ),
                  RawMaterialButton(
                    onPressed: () async {
                      if (!cameraController.value.isInitialized) {
                        return null;
                      }
                      if (cameraController.value.isTakingPicture) {
                        return null;
                      }

                      try {
                        await cameraController.setFlashMode(FlashMode.off);
                        XFile picture = await cameraController.takePicture();

                        setState(() {
                          _flashEffectVisible = true;
                        });

                        // Delay for the flash effect
                        await Future.delayed(Duration(milliseconds: 100));

                        img.add(picture.path);

                        log('daftar gambar : $img');
                        // setState(() {});
                        // Navigator.push(context,
                        //     MaterialPageRoute(builder: (context) {
                        //   return ImagePreview(file: picture);
                        // }));

                        // Hide flash effect
                        setState(() {
                          _flashEffectVisible = false;
                        });
                      } on CameraException catch (e) {
                        log('kamera error');
                        return null;
                      }
                    },
                    elevation: 2.0,
                    fillColor: Colors.white,
                    child: Icon(
                      Icons.camera_alt,
                      size: 35.0,
                    ),
                    padding: EdgeInsets.all(15.0),
                    shape: CircleBorder(),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    color: Colors.transparent,
                    // child: Center(
                    //   child: Text(
                    //     '${img.length}',
                    //     style: getBlackTextStyle(),
                    //   ),
                    // ),
                  )
                ],
              ),
            ),
          )
          // Column(
          //   mainAxisAlignment: MainAxisAlignment.center,
          //   crossAxisAlignment: CrossAxisAlignment.end,
          //   children: [
          //     Center(
          //       child: Container(
          //         margin: EdgeInsets.all(20),
          //         child: MaterialButton(
          //           onPressed: () async {
          //             if (!cameraController.value.isInitialized) {
          //               return null;
          //             }
          //             if (cameraController.value.isTakingPicture) {
          //               return null;
          //             }

          //             try {
          //               await cameraController.setFlashMode(FlashMode.auto);
          //               XFile picture = await cameraController.takePicture();

          //               img.add(picture.path);

          //               log('daftar gambar : $img');
          //               Navigator.pop(context, picture.path);

          //               // Navigator.push(context,
          //               //     MaterialPageRoute(builder: (context) {
          //               //   return ImagePreview(file: picture);
          //               // }));
          //             } on CameraException catch (e) {
          //               log('kamera error');
          //               return null;
          //             }
          //           },
          //           color: Colors.white,
          //           child: Text('Take Picture'),
          //         ),
          //       ),
          //     )
          //   ],
          // ),
        ],
      ),
    );
  }
}
