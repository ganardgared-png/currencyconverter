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
  DateTime? _appOpenLoadTime;
  
  bool _isInterstitialLoading = false;
  bool _isAppOpenLoading = false;
  bool _isAppOpenShowing = false;
  Timer? _adTimer;
  
  // Public getters for status tracking
  bool get isInterstitialLoaded => _interstitialAd != null;
  bool get isAppOpenLoaded => _appOpenAd != null;
  bool get isInterstitialLoading => _isInterstitialLoading;
  bool get isAppOpenLoading => _isAppOpenLoading;
  bool get adsEnabled => _adsEnabled;

  // Ad expiration duration (4 hours)
  static const Duration _adExpirationDuration = Duration(hours: 4);

  static const bool _adsEnabled = true; // Ads enabled for production

  bool get _isSupportedPlatform {
    return _adsEnabled && !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  String get _appOpenAdUnitId {
    return AdConstants.appOpenAdUnitIdAndroid;
  }

  String get _interstitialAdUnitId {
    return AdConstants.interstitialAdUnitIdAndroid;
  }

  Future<void> initialize() async {
    if (!_isSupportedPlatform) {
      return;
    }

    try {
      print('AdService: Initializing Mobile Ads SDK...');
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(testDeviceIds: <String>['EMULATOR']),
      );
      _loadAppOpenAd();
      _loadInterstitialAd();
      _startAdTimer();
    } catch (e) {
      print('AdService: Failed to initialize ads: $e');
    }
  }

  bool _isAdAvailable() {
    return _appOpenAd != null && 
           _appOpenLoadTime != null && 
           DateTime.now().difference(_appOpenLoadTime!) < _adExpirationDuration;
  }

  void _loadAppOpenAd() {
    if (!_isSupportedPlatform || _isAppOpenLoading || _isAppOpenShowing) {
      return;
    }

    // If an ad is already available and not expired, don't load a new one
    if (_isAdAvailable()) {
      return;
    }

    print('AdService: Loading App Open ad...');
    _isAppOpenLoading = true;
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('AdService: App Open ad loaded successfully');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
          _isAppOpenLoading = false;
          _setupAppOpenCallbacks();
        },
        onAdFailedToLoad: (error) {
          print('AdService: App Open ad failed to load: $error');
          _appOpenAd = null;
          _appOpenLoadTime = null;
          _isAppOpenLoading = false;
        },
      ),
    );
  }

  void _setupAppOpenCallbacks() {
    _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('AdService: App Open ad showed full screen content');
        _isAppOpenShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        print('AdService: App Open ad dismissed');
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;
        _isAppOpenShowing = false;
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('AdService: App Open ad failed to show: $error');
        ad.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;
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
          print('AdService: Interstitial ad loaded successfully');
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _setupInterstitialCallbacks();
        },
        onAdFailedToLoad: (error) {
          print('AdService: Interstitial ad failed to load: $error');
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
      return;
    }
    
    if (_isAppOpenShowing) {
      print('AdService: App Open ad is already showing, skipping');
      return;
    }

    print('AdService: showAppOpenAd called. isAppOpenLoading=$_isAppOpenLoading, hasAd=${_appOpenAd != null}');

    // If ad is available and valid, show it
    if (_isAdAvailable()) {
      _isAppOpenShowing = true;
      try {
        print('AdService: Showing App Open ad');
        _appOpenAd?.show();
      } catch (e) {
        print('AdService: Exception showing App Open ad: $e');
        _appOpenAd?.dispose();
        _appOpenAd = null;
        _appOpenLoadTime = null;
        _isAppOpenShowing = false;
        _loadAppOpenAd();
      }
      return;
    }

    // If ad is loading, wait for it with a shorter timeout and check for failures
    if (_isAppOpenLoading) {
      print('AdService: App Open ad is loading, waiting...');
      for (int i = 0; i < 30; i++) { // Wait up to 3 seconds
        await Future.delayed(const Duration(milliseconds: 100));
        if (_isAdAvailable()) {
          _isAppOpenShowing = true;
          print('AdService: App Open ad loaded during wait, showing now');
          _appOpenAd?.show();
          return;
        }
        if (!_isAppOpenLoading && !_isAdAvailable()) {
          print('AdService: App Open ad failed to load during wait');
          return;
        }
      }
    } else {
      // Trigger a load if not loading and not available
      _loadAppOpenAd();
    }
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
    } else {
      _loadInterstitialAd();
    }
  }

  Future<void> registerAddOperation() async {
    if (!_isSupportedPlatform) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final currentCount = prefs.getInt(AppConstants.adAddOperationCounterKey) ?? 0;
      final nextCount = currentCount + 1;
      await prefs.setInt(AppConstants.adAddOperationCounterKey, nextCount);

      if (nextCount % AdConstants.adAddOperationThreshold == 0) {
        await showInterstitialAd();
      }
    } catch (e) {
      print('AdService: Error registering add operation: $e');
    }
  }

  void _startAdTimer() {
    _adTimer?.cancel();
    _adTimer = Timer.periodic(const Duration(minutes: 10), (timer) {
      if (!_isAppOpenShowing) {
        _loadAppOpenAd(); // Preload for next time if needed
      }
    });
  }

  void dispose() {
    _adTimer?.cancel();
    _appOpenAd?.dispose();
    _interstitialAd?.dispose();
  }
}

