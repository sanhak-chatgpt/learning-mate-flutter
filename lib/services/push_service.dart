import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

// https://dalgonakit.tistory.com/120
class PushService extends GetxController {
  Future requestPermission() async {
    if (Platform.isIOS) {
      await FirebaseMessaging.instance.requestPermission();
    }
  }

  Future subscribeTopic() async {
    try {
      await FirebaseMessaging.instance.subscribeToTopic("learningmate_all");
    } catch (e) {
      // 인터넷 연결에 실패하는 경우 예외 발생
      if (kDebugMode) {
        print("Error subscribe! - $e");
      }
    }
  }
}
