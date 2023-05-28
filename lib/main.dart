import 'dart:async';
import 'dart:developer';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (kDebugMode) {
    // Force disable Analytics and Crashlytics collection while doing every day development.
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  }

  // Pass all uncaught errors from the framework to Crashlytics.
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

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
  late final PlatformWebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PlatformWebViewController(
      // TODO: iOS
      AndroidWebViewControllerCreationParams(),
    )
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
          LoadRequestParams(uri: Uri.parse('https://www.thelearningmate.com/')))
      ..setOnPlatformPermissionRequest((request) {
        request.grant();
      })
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'FlutterBridge',
          onMessageReceived: (message) {
            log("bridge message");
            log(message.message);
            switch (message.message) {
              case 'requestMicrophonePermission':
                requestMicrophone();
                break;
              // case 'requestOpenStoreListing':
              //   openStoreListing();
              //   break;
              default:
                break;
            }
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    log("1231231");
    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
        body: SafeArea(
          child: PlatformWebViewWidget(
                  PlatformWebViewWidgetCreationParams(controller: _controller))
              .build(context),
        ),
      ),
    );
  }

  Future<void> requestMicrophone() async {
    log("mic fun start");
    // 마이크 권한 요청 코드 작성
    PermissionStatus status = await Permission.microphone.request();

    //권한 요청 결과에 따라 front에 message를 보냄
    log(status.name);
    if (status == PermissionStatus.granted) {
      _controller.runJavaScript(
          'MicrophonePermissionBridge.receiveMessage(\'GRANTED\')');
    } else {
      _controller.runJavaScript(
          'MicrophonePermissionBridge.receiveMessage(\'DENIED\')');
    }
  }

  Future<void> openStoreListing() async {
    // Flutter 앱에서 openStoreListing을 호출하는 로직을 작성하세요
    final InAppReview inAppReview = InAppReview.instance;

    if (await inAppReview.isAvailable()) {
      InAppReview.instance.openStoreListing(appStoreId: '6449399069');
      _controller
          .runJavaScript('OpenStoreListBridge.receiveMessage(\'GRANTED\')');
    } else {
      // In-App Review가 사용 불가능한 경우 처리할 로직 작성
      _controller
          .runJavaScript('OpenStoreListBridge.receiveMessage(\'DENIED\')');
    }
    //InAppReview.instance.openStoreListing(appStoreId: '1662203668');
  }

  Future<bool> _exitApp(BuildContext context) async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return Future.value(false);
    } else {
      return Future.value(true);
    }
  }
}
