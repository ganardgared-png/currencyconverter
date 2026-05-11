class AdConstants {
  AdConstants._();

  static const bool useTestAds = true;

  // Production AdMob IDs - Replace with your actual AdMob IDs
  static const String androidAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX'; // Replace with your Android App ID
  static const String iosAppId = 'ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX'; // Replace with your iOS App ID
  static const String appOpenAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Replace with your Android App Open Ad Unit ID
  static const String appOpenAdUnitIdIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Replace with your iOS App Open Ad Unit ID
  static const String interstitialAdUnitIdAndroid = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Replace with your Android Interstitial Ad Unit ID
  static const String interstitialAdUnitIdIOS = 'ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX'; // Replace with your iOS Interstitial Ad Unit ID

  // Demo AdMob IDs for testing (only used if useTestAds = true)
  static const String androidAppIdTest = 'ca-app-pub-3940256099942544~3347511713';
  static const String iosAppIdTest = 'ca-app-pub-3940256099942544~1458002511';
  static const String appOpenAdUnitIdAndroidTest = 'ca-app-pub-3940256099942544/3419835294';
  static const String appOpenAdUnitIdIOSTest = 'ca-app-pub-3940256099942544/5662855259';
  static const String interstitialAdUnitIdAndroidTest = 'ca-app-pub-3940256099942544/1033173712';
  static const String interstitialAdUnitIdIOSTest = 'ca-app-pub-3940256099942544/8691691433';

  static const int adAddOperationThreshold = 2;
}
