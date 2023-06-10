import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:learningmate/services/ad_service.dart';
import 'package:learningmate/services/permission_service.dart';
import 'package:learningmate/services/review_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final PlatformWebViewController _controller;
  BannerAd? myBanner;
  var isBannerLoaded = false;

  final _reviewService = Get.find<ReviewService>();
  final _permissionService = Get.find<PermissionService>();
  final _adService = Get.find<AdService>();
  String? _prevUrl;

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
          onMessageReceived: (message) async {
            log("onMessageReceived: Message is ${message.message}.");
            switch (message.message) {
              case 'requestMicrophonePermission':
                if (await _permissionService.requestMicrophonePermission() ==
                    PermissionStatus.granted) {
                  _controller.runJavaScript(
                      "MicrophonePermissionBridge.receiveMessage('GRANTED')");
                } else {
                  _controller.runJavaScript(
                      "MicrophonePermissionBridge.receiveMessage('DENIED')");
                }
                break;
              // case 'requestReview':
              //   _reviewService.requestReview();
              //   break;
              case 'openStoreListing':
                _reviewService.openStoreListing();
                break;
              // case 'showInterstitialAd':
              //   _adService.showInterstitial();
              //   break;
              default:
                break;
            }
          },
        ),
      )
      ..setPlatformNavigationDelegate(
        PlatformNavigationDelegate(
          const PlatformNavigationDelegateCreationParams(),
        )..setOnUrlChange((url) {
            var currentUrl = url.url;
            if (currentUrl == null) return;

            log("setOnUrlChange: URL is $currentUrl.");

            if (currentUrl ==
                "https://www.thelearningmate.com/feedback?process=lecture&record=progress") {
              log("setOnUrlChange: showInterstitialAd");
              _adService.showInterstitial();
            } else if (_prevUrl ==
                    "https://www.thelearningmate.com/feedback?process=lecture&record=success" &&
                currentUrl == "https://www.thelearningmate.com/") {
              log("setOnUrlChange: requestReview");
              _reviewService.requestReview();
            }

            _prevUrl = currentUrl;
          }),
      );

    // 배너 광고 처리
    (() async {
      // isAttAsked 셋팅될 때까지 대기, 1초 간격 폴링.

      if (myBanner != null) return;

      while (true) {
        if (_adService.availableForAskingBannerUnitId) break;
        await Future.delayed(const Duration(milliseconds: 100));
      }

      var adUnitId = await _adService.getBannerAdUnitId();
      if (adUnitId == null) return;

      myBanner = BannerAd(
        adUnitId: adUnitId,
        size: AdSize.largeBanner,
        request: const AdRequest(),
        listener: BannerAdListener(
          // Called when an ad is successfully received.
          onAdLoaded: (Ad ad) {
            if (!isBannerLoaded) {
              setState(() {
                isBannerLoaded = true;
              });
            }
          },
          // Called when an ad request failed.
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            // Dispose the ad here to free resources.
            ad.dispose();
          },
          // Called when an ad opens an overlay that covers the screen.
          onAdOpened: (Ad ad) => {},
          // Called when an ad removes an overlay that covers the screen.
          onAdClosed: (Ad ad) => {},
          // Called when an impression occurs on the ad.
          onAdImpression: (Ad ad) => {},
        ),
      )..load();
    })();
  }

  @override
  Widget build(BuildContext context) {
    final Container adContainer = Container(
      alignment: Alignment.center,
      width: AdSize.largeBanner.width.toDouble(),
      height: AdSize.largeBanner.height.toDouble(),
      child: isBannerLoaded ? AdWidget(ad: myBanner!) : null,
    );

    return WillPopScope(
      onWillPop: () => _exitApp(context),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              adContainer,
              Expanded(
                child: PlatformWebViewWidget(
                  PlatformWebViewWidgetCreationParams(
                    controller: _controller,
                  ),
                ).build(context),
              ),
            ],
          ),
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
}
