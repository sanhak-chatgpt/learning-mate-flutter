import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learningmate/screens/webview_screen.dart';
import 'package:learningmate/services/ad_service.dart';
import 'package:learningmate/services/push_service.dart';

class AppScreen extends StatefulWidget {
  const AppScreen({Key? key}) : super(key: key);

  @override
  State<AppScreen> createState() => _AppScreenState();
}

class _AppScreenState extends State<AppScreen> {
  final _adService = Get.find<AdService>();
  final _pushService = Get.find<PushService>();

  @override
  void initState() {
    super.initState();

    (() async {
      await _pushService.requestPermission();
      await _adService.initializeApp();
      await _pushService.subscribeTopic();
    })();
  }

  @override
  Widget build(BuildContext context) {
    return const WebViewScreen();
  }
}
