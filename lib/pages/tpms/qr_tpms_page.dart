import 'dart:developer';
import 'dart:io';

import '../../core/styles/color.dart';
import '../../core/styles/text_manager.dart';
import '../../core/widgets/appbar_widget.dart';
import 'tpms_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_code_tools/qr_code_tools.dart';

class QrTpmsPage extends StatefulWidget {
  static const routeName = '/qr-tpms-page';
  const QrTpmsPage({super.key});

  @override
  State<QrTpmsPage> createState() => _QrTpmsPageState();
}

class _QrTpmsPageState extends State<QrTpmsPage> {
  Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  final ImagePicker _picker = ImagePicker();

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget(' Scan QR SPM', context),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(
              height: 12,
            ),
            Expanded(child: _buildQrView(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? 150.0
        : 300.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
          overlay: QrScannerOverlayShape(
            borderColor: Colors.red,
            borderRadius: 10,
            borderLength: 30,
            borderWidth: 10,
            cutOutSize: scanArea,
          ),
          onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
        ),
        Positioned(
          top: 100,
          child: Text(
            'Please Scan QR Code',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        Positioned(
          bottom: 100,
          child: Container(
            width: MediaQuery.of(context).size.width,
            child: FutureBuilder(
                future: controller?.getFlashStatus(),
                builder: (context, snapshot) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 42.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ClipOval(
                          child: Material(
                            color: (snapshot.data == false)
                                ? green00968A
                                : Colors.red, // Warna latar belakang
                            child: InkWell(
                              splashColor:
                                  Colors.white, // Warna saat tombol ditekan
                              onTap: () async {
                                await controller?.toggleFlash();
                                setState(() {});
                              },
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: Icon(
                                  (snapshot.data == false)
                                      ? Icons.flashlight_on
                                      : Icons.flashlight_off,
                                  color: white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        ClipOval(
                          child: Material(
                            color: Colors.orange, // Warna latar belakang
                            child: InkWell(
                              splashColor:
                                  Colors.white, // Warna saat tombol ditekan
                              onTap: _scanQrFromGallery,
                              child: SizedBox(
                                width: 64,
                                height: 64,
                                child: Icon(
                                  Icons.image,
                                  color: white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
          ),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      log('apakah valuenya sama = ${result?.code == 'https://cts-chitraparatama.co.id/ChitraTireMngr/product/api_get.php?function=get_tpms'}');
      if (result?.code ==
          'https://cts-chitraparatama.co.id/ChitraTireMngr/product/api_get.php?function=get_tpms') {
        Navigator.pushReplacementNamed(context, TpmsPage.routeName);
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }

  Future<void> _scanQrFromGallery() async {
    // final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      String? qrCode = await QrCodeToolsPlugin.decodeFrom(image.path);
      if (qrCode != null) {
        setState(() {
          result = Barcode(qrCode, BarcodeFormat.qrcode, []);
        });
        log('QR Code from gallery: $qrCode');
        if (qrCode ==
            'https://cts-chitraparatama.co.id/ChitraTireMngr/product/api_get.php?function=get_tpms') {
          Navigator.pushReplacementNamed(context, TpmsPage.routeName);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Unable to recognize QR Code from the selected image.',
            style: getWhiteTextStyle(),
          ),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
