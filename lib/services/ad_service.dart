import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_expenses_plan/core/constants/ad_constants.dart';
import 'package:smart_expenses_plan/core/constants/app_constants.dart';

class AdService {
  AdService._internal();
  static final AdService instance = AdService._internal();

  InterstitialAd? _interstitialAd;
  AppOpenAd? _appOpenAd;
  bool _isInterstitialLoading = false;
  bool _isAppOpenLoading = false;
  bool _isAppOpenShowing = false;
  Timer? _adTimer;

  bool get _isSupportedPlatform {
    return !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  String get _appOpenAdUnitId {
    if (AdConstants.useTestAds) {
      return defaultTargetPlatform == TargetPlatform.android
          ? AdConstants.appOpenAdUnitIdAndroidTest
          : AdConstants.appOpenAdUnitIdIOSTest;
    } else {
      return defaultTargetPlatform == TargetPlatform.android
          ? AdConstants.appOpenAdUnitIdAndroid
          : AdConstants.appOpenAdUnitIdIOS;
    }
  }

  String get _interstitialAdUnitId {
    if (AdConstants.useTestAds) {
      return defaultTargetPlatform == TargetPlatform.android
          ? AdConstants.interstitialAdUnitIdAndroidTest
          : AdConstants.interstitialAdUnitIdIOSTest;
    } else {
      return defaultTargetPlatform == TargetPlatform.android
          ? AdConstants.interstitialAdUnitIdAndroid
          : AdConstants.interstitialAdUnitIdIOS;
    }
  }

  Future<void> initialize() async {
    if (!_isSupportedPlatform) {
      return;
    }

    try {
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: <String>['EMULATOR']),
      );
      _loadAppOpenAd();
      _loadInterstitialAd();
      _startAdTimer();
    } catch (e) {
      print('AdService: Failed to initialize ads: $e');
      // Continue without ads if initialization fails
    }
  }

  void _loadAppOpenAd() {
    if (!_isSupportedPlatform || _isAppOpenLoading) {
      return;
    }

    _isAppOpenLoading = true;
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
          _setupAppOpenCallbacks();
        },
        onAdFailedToLoad: (error) {
          print('AdService: App Open ad failed to load: $error');
          _appOpenAd = null;
          _isAppOpenLoading = false;
        },
      ),
    );
  }

  void _setupAppOpenCallbacks() {
    _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _isAppOpenShowing = false;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        _isAppOpenShowing = false;
        _loadAppOpenAd();
      },
    );
  }

  void _loadInterstitialAd() {
    if (!_isSupportedPlatform || _isInterstitialLoading) {
      return;
    }

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _setupInterstitialCallbacks();
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  void _setupInterstitialCallbacks() {
    _interstitialAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('AdService: Failed to show Interstitial ad: $error');
        ad.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      },
    );
  }

  Future<void> showAppOpenAd() async {
    if (!_isSupportedPlatform) {
      print('AdService: Platform not supported for ads');
      return;
    }
    
    // Don't show if already showing
    if (_isAppOpenShowing) {
      print('AdService: App Open ad is already showing, skipping');
      return;
    }

    print('AdService: showAppOpenAd called. isAppOpenLoading=$_isAppOpenLoading, hasAd=${_appOpenAd != null}');

    // If ad is already loaded, show it
    if (_appOpenAd != null) {
      _isAppOpenShowing = true;
      try {
        print('AdService: Showing already loaded App Open ad');
        _appOpenAd?.show();
      } catch (e) {
        print('AdService: Exception showing loaded App Open ad: $e');
        _appOpenAd?.dispose();
        _appOpenAd = null;
        _isAppOpenShowing = false;
        _loadAppOpenAd();
      }
      return;
    }

    // If ad is loading or not available, wait for it with a timeout
    print('AdService: App Open ad not ready, waiting up to 5 seconds...');
    
    // Ensure a load is triggered if not already loading
    if (!_isAppOpenLoading) {
      _loadAppOpenAd();
    }

    // Wait up to 5 seconds (50 * 100ms) for the ad to load
    for (int i = 0; i < 50; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_appOpenAd != null) {
        print('AdService: App Open ad loaded after ${i * 100}ms, showing now');
        _isAppOpenShowing = true;
        try {
          _appOpenAd?.show();
        } catch (e) {
          print('AdService: Exception showing delayed App Open ad: $e');
          _appOpenAd?.dispose();
          _appOpenAd = null;
          _isAppOpenShowing = false;
          _loadAppOpenAd();
        }
        return;
      }
    }

    print('AdService: App Open ad failed to load within timeout period');
  }

  Future<void> showInterstitialAd() async {
    if (!_isSupportedPlatform) {
      return;
    }

    if (_interstitialAd != null) {
      try {
        _interstitialAd?.show();
      } catch (_) {
        _interstitialAd?.dispose();
        _interstitialAd = null;
        _loadInterstitialAd();
      }
      return;
    }

    if (_isInterstitialLoading) {
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_interstitialAd != null) {
          try {
            _interstitialAd?.show();
          } catch (_) {
            _interstitialAd?.dispose();
            _interstitialAd = null;
            _loadInterstitialAd();
          }
          return;
        }
      }
    }

    _loadInterstitialAd();
    for (int i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_interstitialAd != null) {
        try {
          _interstitialAd?.show();
        } catch (_) {
          _interstitialAd?.dispose();
          _interstitialAd = null;
          _loadInterstitialAd();
        }
        return;
      }
    }
  }

  Future<void> registerAddOperation() async {
    if (!_isSupportedPlatform) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(AppConstants.adAddOperationCounterKey) ?? 0;
    final nextCount = currentCount + 1;
    await prefs.setInt(AppConstants.adAddOperationCounterKey, nextCount);

    if (nextCount % AdConstants.adAddOperationThreshold == 0) {
      await showInterstitialAd();
    }
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (!_isAppOpenShowing) {
        showAppOpenAd();
      }
    });
  }

  void dispose() {
    _adTimer?.cancel();
  }
}
