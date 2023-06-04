import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdUnitId {
  String key;
  List<String> value;

  AdUnitId({
    required this.key,
    required this.value,
  });

  factory AdUnitId.fromJson(Map<String, dynamic> map) {
    return AdUnitId(
      key: map['key'] as String,
      value: List<String>.from(map['value']),
    );
  }
}

class AdService extends GetxService {
  var _isInitialized = false;
  var availableForAskingBannerUnitId = false;

  InterstitialAd? _interstitial;

  AppOpenAd? _appOpen;
  bool isShowingAd = false;
  final Duration _maxCacheDuration = const Duration(hours: 4);
  DateTime _appOpenLoadTime = DateTime.now();

  /// iOS ATT 권한을 요청하고, 광고를 미리 로딩한다.
  Future initializeApp() async {
    if (_isInitialized) return;
    _isInitialized = true;

    if (Platform.isIOS) {
      var trackingStatus =
          await AppTrackingTransparency.trackingAuthorizationStatus;
      Get.log("trackingAuthorizationStatus = $trackingStatus");
      if (trackingStatus == TrackingStatus.notDetermined) {
        await Future.delayed(const Duration(seconds: 1));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
    availableForAskingBannerUnitId = true;

    final remoteConfig = FirebaseRemoteConfig.instance;

    try {
      var adUnitId = (jsonDecode(remoteConfig.getString("ad_unit_id")) as List)
          .map((e) => AdUnitId.fromJson(e));

      _loadInterstitial(adUnitId
          .firstWhere(
            (element) => element.key == "interstitial",
            orElse: () => AdUnitId(key: "", value: []),
          )
          .value);

      _loadAppOpen(adUnitId
          .firstWhere(
            (element) => element.key == "app_open",
            orElse: () => AdUnitId(key: "", value: []),
          )
          .value);
    } catch (e) {
      Get.log("광고 로드 중 오류 발생 - $e");
    }
  }

  Future<String?> getBannerAdUnitId() async {
    final remoteConfig = FirebaseRemoteConfig.instance;

    var adUnitId = (jsonDecode(remoteConfig.getString("ad_unit_id")) as List)
        .map((e) => AdUnitId.fromJson(e));

    var bannerAdUnitIds = adUnitId
        .firstWhere((element) => element.key == "banner",
            orElse: () => AdUnitId(key: "", value: []))
        .value;
    if (bannerAdUnitIds.length >= 1) {
      return bannerAdUnitIds[0];
    } else {
      return null;
    }
  }

  void _loadInterstitial(List<String> adUnitIds) {
    if (adUnitIds.isEmpty) return;
    var adUnitId = adUnitIds[0];

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
        },
        onAdFailedToLoad: (err) {
          _loadInterstitial(adUnitIds.sublist(1));
        },
      ),
    );
  }

  void _loadAppOpen(List<String> adUnitIds) {
    if (adUnitIds.isEmpty) return;
    var adUnitId = adUnitIds[0];

    AppOpenAd.load(
      adUnitId: adUnitId,
      orientation: AppOpenAd.orientationPortrait,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpen = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          _loadAppOpen(adUnitIds.sublist(1));
        },
      ),
    );

    WidgetsBinding.instance
        .addObserver(AppLifecycleReactor(appOpenAdManager: this));
  }

  void showInterstitial() {
    _interstitial?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        isShowingAd = false;
        ad.dispose();
        _appOpen = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        isShowingAd = false;
        ad.dispose();
        _appOpen = null;
      },
    );
    _interstitial?.show();
    _interstitial = null;
  }

  void showAppOpen() {
    if (isShowingAd) {
      return;
    }

    if (DateTime.now().subtract(_maxCacheDuration).isAfter(_appOpenLoadTime)) {
      _appOpen?.dispose();
      _appOpen = null;
      return;
    }
    _appOpen?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        isShowingAd = true;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        isShowingAd = false;
        ad.dispose();
        _appOpen = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        isShowingAd = false;
        ad.dispose();
        _appOpen = null;
      },
    );
    _appOpen?.show();
    _appOpen = null;
  }
}

class AppLifecycleReactor extends WidgetsBindingObserver {
  final AdService appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    // Try to show an app open ad if the app is being resumed and
    // we're not already showing an app open ad.
    if (state == AppLifecycleState.resumed) {
      appOpenAdManager.showAppOpen();
    }
  }
}
