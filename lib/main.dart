import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String channelName = 'your_channel_name';

  final MethodChannel _channel = const MethodChannel(channelName);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '스터디 메이트',
      themeMode: ThemeMode.dark,
      theme: ThemeData(useMaterial3: true),
      home: MyWebView(channel: _channel),
    );
  }
}

class MyWebView extends StatefulWidget {
  final MethodChannel channel;

  const MyWebView({Key? key, required this.channel}) : super(key: key);

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView Example'),
      ),
      body: WebView(
        initialUrl: 'https://www.thelearningmate.com/',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
        },
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
            name: 'Microphone',
            onMessageReceived: (JavascriptMessage message) {
              requestMicrophone();
              widget.channel.invokeMethod('your_method_name', message.message);
            },
          ),
        },
      ),
    );
  }

  void requestMicrophone() async {
    // 마이크 권한 요청
  }
}
