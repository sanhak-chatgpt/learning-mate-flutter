import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:in_app_review/in_app_review.dart';
import 'dart:developer';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String channelName = 'FlutterBridge';

  final MethodChannel _channel = const MethodChannel(channelName);

  @override
  Widget build(BuildContext context) {
    log("123");
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
    log("1231231");
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView Example'),
      ),
      body: WebView(
        initialUrl: 'https://www.thelearningmate.com/',
        javascriptMode: JavascriptMode.unrestricted,
        onWebViewCreated: (WebViewController webViewController) {
          _controller.complete(webViewController);
          log("onwebviewcreated");
        },
        javascriptChannels: <JavascriptChannel>{
          JavascriptChannel(
            name: 'FlutterBridge',
            onMessageReceived: (JavascriptMessage message) {
              log("bridge message");
              log(message.message);
              switch(message.message){
                case 'requestMicrophonePermission':
                  requestMicrophone();
                  break;
                case 'requestOpenStoreListing':
                  openStoreListing();
                  break;
                default:
                  break;
              }
              widget.channel.invokeMethod('your_method_name', message.message);
            },
          ),
        },
      ),
    );
  }

  Future<void> requestMicrophone() async {
    log("mic fun start");
    // 마이크 권한 요청 코드 작성
    PermissionStatus status = await Permission.microphone.request();

    //권한 요청 결과에 따라 front에 message를 보냄
    final webViewController = await _controller.future;
    log(status.name);
    if(status==PermissionStatus.granted){
      webViewController.runJavascript('MicrophonePermissionBridge.receiveMessage(\'GRANTED\')');
    }else{
      webViewController.runJavascript('MicrophonePermissionBridge.receiveMessage(\'DENIED\')');
    }
  }

  Future<void> openStoreListing() async {
    // Flutter 앱에서 openStoreListing을 호출하는 로직을 작성하세요
    final InAppReview inAppReview = InAppReview.instance;
    final webViewController = await _controller.future;

    if (await inAppReview.isAvailable()) {
      InAppReview.instance.openStoreListing(appStoreId: '6449399069');
      webViewController.runJavascript('OpenStoreListBridge.receiveMessage(\'GRANTED\')');
    } else {
    // In-App Review가 사용 불가능한 경우 처리할 로직 작성
      webViewController.runJavascript('OpenStoreListBridge.receiveMessage(\'DENIED\')');
    }
    //InAppReview.instance.openStoreListing(appStoreId: '1662203668');
  }
}
