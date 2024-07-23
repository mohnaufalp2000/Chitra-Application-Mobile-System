import 'package:camos/core/navigator/navigation_route.dart';
import 'package:camos/core/styles/text_manager.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ChatMaximaWidget extends StatefulWidget {
  const ChatMaximaWidget({Key? key}) : super(key: key);

  @override
  _ChatMaximaWidgetState createState() => _ChatMaximaWidgetState();
}

class _ChatMaximaWidgetState extends State<ChatMaximaWidget> {
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
            if (request.url.startsWith(
                'https://chatmaxima.com/chatbot/public/jmornk6qh7/')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
          Uri.parse('https://chatmaxima.com/chatbot/public/jmornk6qh7/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
            'Chitra Chat Bot',
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
