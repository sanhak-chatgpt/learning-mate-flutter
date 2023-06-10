import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:learningmate/screens/offline_screen.dart';
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

  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future _initializeApp() async {
    var connectivity = await Connectivity().checkConnectivity();
    Get.log('connectivity: $connectivity');

    if (connectivity == ConnectivityResult.none) {
      setState(() {
        _isOffline = true;
      });
    } else {
      setState(() {
        _isOffline = false;
      });
      await _adService.initializeApp();
      await _pushService.requestPermission();
      await _pushService.subscribeTopic();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return OfflineScreen(onRefresh: () => _initializeApp());
    } else {
      return const WebViewScreen();
    }
  }
}
