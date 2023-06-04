import 'dart:developer';

import 'package:get/get.dart';
import 'package:learningmate/services/ad_service.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService extends GetxService {
  final _adService = Get.find<AdService>();

  Future<PermissionStatus> requestMicrophonePermission() async {
    // 권한을 물어본 후 앱 오프닝 광고가 나타나지 않게 설정
    _adService.isShowingAd = true;

    log("requestMicrophone: Requesting mic permission...");

    PermissionStatus status = await Permission.microphone.request();
    log("requestMicrophone: Permission status is $status.");

    () async {
      await Future.delayed(const Duration(seconds: 1));
      _adService.isShowingAd = false;
    }();

    return status;
  }
}
