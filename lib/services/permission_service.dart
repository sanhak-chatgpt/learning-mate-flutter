import 'dart:developer';

import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService extends GetxService {
  Future<PermissionStatus> requestMicrophonePermission() async {
    log("requestMicrophone: Requesting mic permission...");
    PermissionStatus status = await Permission.microphone.request();
    log("requestMicrophone: Permission status is $status.");
    return status;
  }
}
