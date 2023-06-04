import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:learningmate/screens/app_screen.dart';
import 'package:learningmate/services/ad_service.dart';
import 'package:learningmate/services/permission_service.dart';
import 'package:learningmate/services/review_service.dart';

import 'firebase_options.dart';
import 'services/push_service.dart';

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

  await initServices();

  runApp(const MyApp());
}

Future<void> initServices() async {
  final remoteConfig = FirebaseRemoteConfig.instance;
  remoteConfig.setDefaults({
    "ad_unit_id": "[]",
  });
  try {
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    Get.log("Remote Config 초기화 실패 - $e");
  }

  Get.put(PushService());
  Get.put(ReviewService());
  Get.put(AdService());
  Get.put(PermissionService());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: '스터디 메이트',
        themeMode: ThemeMode.dark,
        theme: ThemeData(useMaterial3: true),
        home: const AppScreen(),
      ),
    );
  }
}
