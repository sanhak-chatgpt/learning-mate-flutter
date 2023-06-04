import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:learningmate/screens/app_screen.dart';

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: '스터디 메이트',
        themeMode: ThemeMode.dark,
        theme: ThemeData(useMaterial3: true),
        home: AppScreen(),
      ),
    );
  }
}
