import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CtsPage extends StatefulWidget {
  static const routeName = '/cts_page';
  const CtsPage({super.key});

  @override
  State<CtsPage> createState() => _CtsPageState();
}

class _CtsPageState extends State<CtsPage> {
  WebViewController? controller;

  @override
  void initState() {
    super.initState();
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.startsWith('https://www.youtube.com/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(
          'https://cts-chitraparatama.co.id/ChitraTireMngr/product/login.php'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Chitra Tire System',
            style: getWhiteTextStyle(),
          ),
          leading:
              InkWell(onTap: () => back(context), child: Icon(Icons.close)),
        ),
        body: SafeArea(
          child: SafeArea(
            child: WebViewWidget(controller: controller!),
          ),
        ));
  }
}
