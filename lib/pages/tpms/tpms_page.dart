import 'package:camos/core/styles/asset_path.dart';
import 'package:camos/core/styles/color.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:camos/core/widgets/tire_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TpmsPage extends StatefulWidget {
  static const routeName = '/tpmsPage';
  const TpmsPage({super.key});

  @override
  State<TpmsPage> createState() => _TpmsPageState();
}

class _TpmsPageState extends State<TpmsPage> {
  WebViewController? webViewController;
  List<String> pressureData = [
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
  ];

  @override
  void initState() {
    super.initState();
    webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.chitraparatama.co.id/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://chitraparatama.co.id/esp-weather-station.php?readingsCount='));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarWidget('SPM Page', context),
      body: SafeArea(
        child: WebViewWidget(controller: webViewController!),
        // child: Padding(
        //   padding: const EdgeInsets.all(24.0),
        //   child: SingleChildScrollView(
        //     child: Column(
        //       children: [
        //         // Identity Data
        //         Card(
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(4),
        //           ),
        //           color: Color(0xFF0C44A3),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: <Widget>[
        //               Container(
        //                 padding: const EdgeInsets.all(15),
        //                 child: Column(
        //                   crossAxisAlignment: CrossAxisAlignment.start,
        //                   children: <Widget>[
        //                     const Text(
        //                       "Operator : Naufal",
        //                       style:
        //                           TextStyle(fontSize: 16, color: Colors.white),
        //                     ),
        //                     Container(height: 10),
        //                     Text('ID / SN : 72618',
        //                         style: TextStyle(
        //                             fontSize: 16, color: Colors.grey[200])),
        //                   ],
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //         SizedBox(
        //           height: 12,
        //         ),
        //         // Unit
        //         Column(
        //           children: [
        //             // Pos 1, 2
        //             Stack(
        //               children: [
        //                 Positioned(
        //                   top: 20,
        //                   left: 0,
        //                   right: 0,
        //                   child: Column(
        //                     children: [
        //                       Text(
        //                         'CO 3374',
        //                         style: getBlackTextStyle(
        //                           fontSize: 18,
        //                           fontWeight: w700,
        //                         ),
        //                       ),
        //                       SizedBox(
        //                         height: 150,
        //                         width: 100,
        //                         child:
        //                             Image.asset('${imagePath}/dump_truck.png'),
        //                       ),
        //                     ],
        //                   ),
        //                 ),
        //                 Row(
        //                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //                   children: pressureData.map((e) {
        //                     final index = pressureData.indexOf(e);
        //                     if (index < 2) {
        //                       return Expanded(
        //                         child: Padding(
        //                           padding: EdgeInsets.only(
        //                               right: (index == 0) ? 84 : 0,
        //                               left: (index == 1) ? 84 : 0),
        //                           child: PressureCard(
        //                             position: e,
        //                           ),
        //                         ),
        //                       );
        //                     }
        //                     return Container();
        //                   }).toList(),
        //                 ),
        //               ],
        //             ),
        //             // Pos 3, 4, 5, 6
        //             GridView.builder(
        //               itemCount: pressureData.length -
        //                   2, // Mengurangi 2 untuk menghilangkan index pertama dan kedua
        //               shrinkWrap: true,
        //               physics: NeverScrollableScrollPhysics(),
        //               gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        //                 crossAxisCount: 4,
        //                 childAspectRatio: 0.4,
        //                 mainAxisSpacing: 3,
        //               ),
        //               itemBuilder: (context, index) {
        //                 // Memperhitungkan offset karena index pertama dan kedua diabaikan
        //                 final dataIndex = index + 2;
        //                 return PressureCard(
        //                   position: pressureData[dataIndex],
        //                   index: index,
        //                 );
        //               },
        //             )
        //           ],
        //         ),
        //         const SizedBox(
        //           height: 12,
        //         ),
        //         // event
        //         Card(
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(4),
        //           ),
        //           color: Colors.red,
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: <Widget>[
        //               Container(
        //                 padding: const EdgeInsets.all(15),
        //                 child: Column(
        //                   crossAxisAlignment: CrossAxisAlignment.start,
        //                   children: <Widget>[
        //                     const Text(
        //                       "- Position 3 Low Tire Pressure",
        //                       style:
        //                           TextStyle(fontSize: 16, color: Colors.white),
        //                     ),
        //                     Container(height: 10),
        //                     const Text(
        //                       "- Position 4 Low Tire Pressure",
        //                       style:
        //                           TextStyle(fontSize: 16, color: Colors.white),
        //                     ),
        //                   ],
        //                 ),
        //               ),
        //             ],
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
      ),
    );
  }
}

class PressureCard extends StatelessWidget {
  const PressureCard({super.key, required this.position, this.index = -1});

  final String position;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        child: Column(
          children: [
            Container(
                padding: EdgeInsets.all(12),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: (index == 0 || index == 1) ? Colors.red : black,
                    borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12))),
                child: Center(
                  child: Text(
                    position,
                    style: getWhiteTextStyle(fontSize: 36, fontWeight: w700),
                  ),
                )),
            Column(
              children: [
                Text(
                  (index == 0 || index == 1) ? '70' : '120',
                  style: getBlackTextStyle(fontSize: 24),
                ),
                Text('Psi', style: getBlackTextStyle(fontSize: 24)),
              ],
            ),
            Divider(),
            Text('35 °C', style: getBlackTextStyle(fontSize: 24))
          ],
        ),
      ),
    );
  }
}
