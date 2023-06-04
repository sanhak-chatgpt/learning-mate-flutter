import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '스터디 메이트',
      themeMode: ThemeMode.dark,
      theme: ThemeData(useMaterial3: true),
      home: MyWebView(),
    );
  }
}

class MyWebView extends StatefulWidget {
  const MyWebView({Key? key}) : super(key: key);

  @override
  State<MyWebView> createState() => _MyWebViewState();
}

class _MyWebViewState extends State<MyWebView> {
  late final PlatformWebViewController _controller;

  @override
  void initState() {
    super.initState();

    if (Platform.isIOS) {
      _controller =
          WebKitWebViewController(WebKitWebViewControllerCreationParams())
            ..setAllowsBackForwardNavigationGestures(true);
    } else {
      _controller =
          AndroidWebViewController(AndroidWebViewControllerCreationParams());
    }

    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
          LoadRequestParams(uri: Uri.parse('https://www.thelearningmate.com/')))
      ..setOnPlatformPermissionRequest((request) => request.grant())
      ..enableZoom(false)
      ..addJavaScriptChannel(
        JavaScriptChannelParams(
          name: 'FlutterBridge',
          onMessageReceived: (message) {
            log("onMessageReceived: Message is ${message.message}.");
            switch (message.message) {
              case 'requestMicrophonePermission':
                _requestMicrophone();
                break;
              case 'requestOpenStoreListing':
                _openStoreListing();
                break;
              default:
                break;
            }
          },
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
        body: SafeArea(
          child: PlatformWebViewWidget(
            PlatformWebViewWidgetCreationParams(
              controller: _controller,
            ),
          ).build(context),
        ),
      ),
    );
  }

  /// 뒤로 가기 버튼 처리
  Future<bool> _exitApp(BuildContext context) async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    } else {
      return true;
    }
  }

  /// 마이크 권한 요청
  Future<void> _requestMicrophone() async {
    log("requestMicrophone: Requesting mic permission...");
    PermissionStatus status = await Permission.microphone.request();
    log("requestMicrophone: Permission status is $status.");

    // 권한 요청 결과에 따라 JavaScript 코드 실행
    if (status == PermissionStatus.granted) {
      _controller.runJavaScript(
          "MicrophonePermissionBridge.receiveMessage('GRANTED')");
    } else {
      _controller
          .runJavaScript("MicrophonePermissionBridge.receiveMessage('DENIED')");
    }
  }

  /// 스토어 평가 팝업 열기
  Future<void> _openStoreListing() async {
    final InAppReview inAppReview = InAppReview.instance;

    log("openStoreListing: Checking if in-app review is available...");
    if (await inAppReview.isAvailable()) {
      log("openStoreListing: In-app review is available. Opening store listing...");
      InAppReview.instance.openStoreListing(appStoreId: '6449399069');
    }
  }
}
