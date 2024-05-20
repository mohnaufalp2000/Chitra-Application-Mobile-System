import 'dart:developer';
import 'dart:io';

import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/pages/tpms/tpms_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

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
          top: 100, // Ubah sesuai kebutuhan
          child: Text(
            'Please Scan QR Code',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ),
        Positioned(
          bottom: 100, // Ubah sesuai kebutuhan
          child: FutureBuilder(
              future: controller?.getFlashStatus(),
              builder: (context, snapshot) {
                return ElevatedButton(
                    onPressed: () async {
                      await controller?.toggleFlash();
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: (snapshot.data == false)
                            ? green00968A
                            : Colors.red),
                    child: Row(
                      children: [
                        Icon(
                          (snapshot.data == false)
                              ? Icons.flashlight_on
                              : Icons.flashlight_off,
                          color: white,
                        ),
                        const SizedBox(
                          width: 12,
                        ),
                        Text(
                          '${(snapshot.data == false) ? 'Turn On Flash' : 'Turn Off Flash'}',
                          style: getWhiteTextStyle(),
                        ),
                      ],
                    ));
              }),
        ),
      ],
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    // bool isError = false;
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
      } else {
        // isError = true;
        // if (isError) {
        //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        //     content: Text(
        //       'This is not SPM QR Code. Please find another QR Code and try again.',
        //       style: getWhiteTextStyle(),
        //     ),
        //     backgroundColor: Colors.red,
        //   ));

        //   isError = false;
        // }
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

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
