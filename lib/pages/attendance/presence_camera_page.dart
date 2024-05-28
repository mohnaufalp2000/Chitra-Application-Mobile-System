// import 'dart:developer';

// import 'package:camera/camera.dart';
// import 'package:camos/core/styles/text_manager.dart';
// import 'package:camos/core/utils/functions/functions.dart';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';

// class PresenceCameraPage extends StatefulWidget {
//   static const routeName = '/presence-camera-page';
//   const PresenceCameraPage({super.key});

//   @override
//   State<PresenceCameraPage> createState() => _PresenceCameraPageState();
// }

// class _PresenceCameraPageState extends State<PresenceCameraPage> {
//   CameraController? cameraController;
//   final List<String> img = [];
//   bool _flashEffectVisible = false;
//   List<CameraDescription>? cameras;
//   int _selectedCameraIndex = 1;
//   bool isFront = true;
//   late Position position;

//   @override
//   void initState() {
//     super.initState();
//     _initializeCamera();

//     getCurrentLocation();
//   }

//   void getCurrentLocation() async {
//     requestGeolocatorPermission();
//     Position currentPosition = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);
//     setState(() {
//       position = currentPosition;
//     });
//     log('posisi : $position');
//   }

//   // mendapatkan kamera yg tersedia
//   Future<void> _initializeCamera() async {
//     // Fetch the list of available cameras.
//     cameras = await availableCameras();

//     if (cameras!.isEmpty) {
//       log('No cameras available');
//       return;
//     }

//     _initCameraController(cameras![_selectedCameraIndex]);
//   }

//   // men set camera controller
//   Future<void> _initCameraController(
//       CameraDescription cameraDescription) async {
//     // cameraController?.dispose();

//     cameraController =
//         CameraController(cameraDescription, ResolutionPreset.max);

//     try {
//       await cameraController!.initialize();
//     } catch (e) {
//       log('Error initializing camera: $e');
//     }

//     if (!mounted) {
//       return;
//     }

//     setState(() {});
//   }

//   @override
//   void dispose() {
//     cameraController?.dispose();
//     super.dispose();
//   }

//   // mengganti kamera depan / belakang
//   void _switchCamera() {
//     if (cameras == null || cameras!.isEmpty) {
//       return;
//     }

//     isFront = !isFront;

//     if (isFront) {
//       _selectedCameraIndex = 0;
//     } else {
//       _selectedCameraIndex = 1;
//     }
//     _initCameraController(cameras![_selectedCameraIndex]);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (cameraController == null || !cameraController!.value.isInitialized) {
//       return Container(
//         color: Colors.black,
//         child: Center(
//           child: CircularProgressIndicator(),
//         ),
//       );
//     }

//     return Scaffold(
//       body: Stack(
//         children: [
//           Container(
//             height: double.infinity,
//             child: CameraPreview(cameraController!),
//           ),
//           AnimatedContainer(
//             duration: Duration(milliseconds: 150),
//             color: _flashEffectVisible ? Colors.black : Colors.transparent,
//             curve: Curves.easeInOut,
//             width: double.infinity,
//             height: double.infinity,
//             child: _flashEffectVisible
//                 ? null
//                 : SizedBox(), // Hide the container when not needed
//           ),
//           Positioned(
//             bottom: 0,
//             left: 0,
//             right: 0,
//             child: Column(
//               children: [
//                 Container(
//                   height: MediaQuery.of(context).size.height * 0.2,
//                   color: Colors.white.withOpacity(0.3),
//                   child: Text(
//                     '${position.latitude},${position.longitude}',
//                     style: getBlackTextStyle(),
//                   ),
//                 ),
//                 Container(
//                   width: double.infinity,
//                   padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//                   height: 100,
//                   color: Colors.white.withOpacity(0.4),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       RawMaterialButton(
//                         onPressed: () {
//                           Navigator.pop(context, img);
//                         },
//                         elevation: 2.0,
//                         fillColor: Colors.white,
//                         child: Icon(
//                           Icons.arrow_back,
//                           size: 35.0,
//                         ),
//                         padding: EdgeInsets.all(15.0),
//                         shape: CircleBorder(),
//                       ),
//                       RawMaterialButton(
//                         onPressed: () async {
//                           if (cameraController == null ||
//                               !cameraController!.value.isInitialized) {
//                             return;
//                           }
//                           if (cameraController!.value.isTakingPicture) {
//                             return;
//                           }

//                           try {
//                             await cameraController!.setFlashMode(FlashMode.off);
//                             XFile picture =
//                                 await cameraController!.takePicture();

//                             setState(() {
//                               _flashEffectVisible = true;
//                             });

//                             // Delay for the flash effect
//                             await Future.delayed(Duration(milliseconds: 100));

//                             img.add(picture.path);

//                             log('daftar gambar : $img');

//                             // Hide flash effect
//                             setState(() {
//                               _flashEffectVisible = false;
//                             });
//                           } on CameraException catch (e) {
//                             log('kamera error');
//                             return;
//                           }
//                         },
//                         elevation: 2.0,
//                         fillColor: Colors.white,
//                         child: Icon(
//                           Icons.camera_alt,
//                           size: 35.0,
//                         ),
//                         padding: EdgeInsets.all(15.0),
//                         shape: CircleBorder(),
//                       ),
//                       RawMaterialButton(
//                         onPressed: () {
//                           _switchCamera();
//                         },
//                         elevation: 2.0,
//                         fillColor: Colors.white,
//                         child: Icon(
//                           Icons.switch_camera,
//                           size: 35.0,
//                         ),
//                         padding: EdgeInsets.all(15.0),
//                         shape: CircleBorder(),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'dart:developer';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/button_widget.dart';
import 'package:camos/main.dart';
import 'package:camos/pages/attendance/presence_camera_result_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PresenceCameraPage extends StatefulWidget {
  static const routeName = '/presence-camera-page';
  const PresenceCameraPage({super.key});

  @override
  State<PresenceCameraPage> createState() => _PresenceCameraPageState();
}

class _PresenceCameraPageState extends State<PresenceCameraPage> {
  late CameraController cameraController;
  int selectedCameraIndex = 1;
  DateTime now = DateTime.now();
  DateFormat formatter1 = DateFormat('dd/MM/yy');
  DateFormat formatter2 = DateFormat('EEEE, d MMMM yyyy');
  DateFormat timeFormatter = DateFormat('HH:mm');
  String location = 'Office';

  String formattedDate1 = '';
  String formattedDate2 = '';
  String formattedTime = '';

  bool _flashEffectVisible = false;

  @override
  void initState() {
    super.initState();
    formattedDate1 = formatter1.format(now);
    formattedDate2 = formatter2.format(now);
    formattedTime = timeFormatter.format(now);

    cameraController =
        CameraController(cameras[selectedCameraIndex], ResolutionPreset.max);
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
  void dispose() {
    super.dispose();
    cameraController
        .dispose(); // Pastikan untuk memanggil dispose() pada controller saat widget dihapus
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            if (cameraController != null &&
                cameraController!.value.isInitialized)
              Align(
                alignment: Alignment.center,
                child: cameraPreview(),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    color: white.withOpacity(0.4),
                    width: double.infinity,
                    padding: EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formattedDate1}',
                          style: getBlackTextStyle(),
                        ),
                        Row(
                          children: [
                            Icon(Icons.calendar_month),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              '${formattedDate2}',
                              style: getBlackTextStyle(
                                fontSize: 16,
                                fontWeight: w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Row(
                          children: [
                            Icon(Icons.timer_rounded),
                            const SizedBox(
                              width: 12,
                            ),
                            Text(
                              '${formattedTime}',
                              style: getBlackTextStyle(
                                fontSize: 16,
                                fontWeight: w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 2,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.location_pin),
                            const SizedBox(
                              width: 12,
                            ),
                            Container(
                              width: 160,
                              child: Text(
                                '$location',
                                style: getBlackTextStyle(
                                  fontSize: 16,
                                  fontWeight: w700,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 24,
                            ),
                            SizedBox(
                                width: 150,
                                height: 50,
                                child: ButtonWidget(
                                    name: Text(
                                      'Edit Location',
                                      style: getWhiteTextStyle(),
                                    ),
                                    function: () {
                                      showEditLocationDialog();
                                    }))
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    height: 120,
                    color: grey6A707C,
                    width: double.infinity,
                    padding: EdgeInsets.all(15),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        cameraToggle(),
                        cameraControl(context),
                        Spacer()
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (!(cameraController != null &&
                cameraController!.value.isInitialized))
              Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  void showEditLocationDialog() {
    TextEditingController locationController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Location'),
          content: TextField(
            controller: locationController,
            decoration: InputDecoration(hintText: "Enter new location"),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                setState(() {
                  location = locationController.text;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget cameraPreview() {
    return AspectRatio(
      aspectRatio: 6 / 19,
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: cameraController.value.previewSize!.height,
          height: cameraController.value.previewSize!.width,
          child: CameraPreview(cameraController),
        ),
      ),
    );
  }

  Widget cameraToggle() {
    if (cameras == null || cameras.isEmpty) {
      return Spacer();
    }
    CameraDescription selectedCamera = cameras[selectedCameraIndex];
    CameraLensDirection lensDirection = selectedCamera.lensDirection;

    return Expanded(
        child: Align(
      alignment: Alignment.centerLeft,
      child: RawMaterialButton(
        onPressed: () {
          onSwitchCamera();
        },
        elevation: 2.0,
        fillColor: Colors.white,
        child: Icon(
          getCameraLensIcon(lensDirection),
          size: 35.0,
        ),
        padding: EdgeInsets.all(15.0),
        shape: CircleBorder(),
      ),
    ));
  }

  getCameraLensIcon(lensDirection) {
    switch (lensDirection) {
      case CameraLensDirection.back:
        return CupertinoIcons.switch_camera;
        break;
      case CameraLensDirection.front:
        return CupertinoIcons.switch_camera_solid;
        break;
    }
  }

  onSwitchCamera() {
    selectedCameraIndex =
        selectedCameraIndex < cameras.length - 1 ? selectedCameraIndex + 1 : 0;
    cameraController =
        CameraController(cameras[selectedCameraIndex], ResolutionPreset.max);
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

  Widget cameraControl(BuildContext context) {
    return Expanded(
        child: Align(
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: [
          FloatingActionButton(
            onPressed: () {
              onCapture(context);
            },
            backgroundColor: black,
            child: Icon(
              Icons.camera,
              color: white,
            ),
          )
        ],
      ),
    ));
  }

  onCapture(context) async {
    try {
      await cameraController.takePicture().then((value) async {
        setState(() {
          _flashEffectVisible = true;
        });
        await Future.delayed(Duration(milliseconds: 100));

        // Hide flash effect
        setState(() {
          _flashEffectVisible = false;
        });
        Navigator.pushNamed(context, PresenceCameraResultPage.routeName,
            arguments: {
              'imagePath': value,
              'date1': formattedDate1,
              'date2': formattedDate2,
              'time': formattedTime,
              'location': location,
            });
        log('gambar $value');
      });
    } catch (e) {
      print('$e');
    }
  }
}
