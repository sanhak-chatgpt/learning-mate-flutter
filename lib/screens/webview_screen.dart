import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewScreen extends StatelessWidget {
  const WebViewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('스터디 메이트')),
      body: const WebView(
        initialUrl: 'https://www.thelearningmate.com',
        javascriptMode: JavascriptMode.unrestricted,
      ),
    );
  }
}
