import 'package:flutter/material.dart';
import 'package:learningmate/screens/webview_screen.dart';
import 'package:webview_flutter/webview_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '스터디 메이트',
      themeMode: ThemeMode.dark,
      theme: ThemeData(useMaterial3: true),
      home: WebViewScreen(),
    );
  }
}
