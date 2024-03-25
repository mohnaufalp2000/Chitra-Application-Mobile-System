import 'package:camos/core/styles/color.dart';
import 'package:camos/core/widgets/appbar_widget.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TpmsPage extends StatefulWidget {
  static const routeName = '/tpmsPage';
  const TpmsPage({super.key});

  @override
  State<TpmsPage> createState() => _TpmsPageState();
}

class _TpmsPageState extends State<TpmsPage> {
  WebViewController? webViewController;

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
      appBar: appBarWidget('TPMS Page', context),
      body: SafeArea(
        child: WebViewWidget(
          controller: webViewController!,
        ),
      ),
    );
  }
}
