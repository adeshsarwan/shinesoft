import 'package:flutter/foundation.dart';

/// Central AdMob unit IDs. Must match [androidAppAdMobId] in AndroidManifest.
///
/// While [useTestAdMob] is true, all units use Google's test IDs with the test
/// app id `ca-app-pub-3940256099942544~3347511713`.
/// For production: set [useTestAdMob] to false and update AndroidManifest
/// `com.google.android.gms.ads.APPLICATION_ID` to your real AdMob app id.
class AdConfig {
  AdConfig._();

  /// Automatically uses Google test IDs in debug builds.
  /// Release builds use the production AdMob IDs and live VAST tags.
  static bool get useTestAdMob => kDebugMode;

  /// Production AdMob app id (mobile) provided by user.
  static const String productionAppId =
      'ca-app-pub-1350781778307915~3148257729';

  // Google test app id (commented out for production).
  // static const String androidTestAppId =
  //     'ca-app-pub-3940256099942544~3347511713';

  /// Fixed 320×50 — phones. Google demo: …/6300978111
  // Banner: production id provided by user
  // Test id (commented): ca-app-pub-3940256099942544/6300978111
  static String get fixedBannerAdUnitId => useTestAdMob
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-1350781778307915/4233905428';

  /// Anchored / inline adaptive — required for TV & wide screens. Google demo: …/9214589741
  // Adaptive banner: production id provided by user
  // Test id (commented): ca-app-pub-3940256099942544/9214589741
  static String get adaptiveBannerAdUnitId => useTestAdMob
      ? 'ca-app-pub-3940256099942544/9214589741'
      : 'ca-app-pub-1350781778307915/4233905428';

  /// Prefer adaptive on TV; mobile uses fixed banner.
  static String get bannerAdUnitId => fixedBannerAdUnitId;

  // Native ad: production id provided by user
  // Test id (commented): ca-app-pub-3940256099942544/2247696110
  static String get nativeAdUnitId => useTestAdMob
      ? 'ca-app-pub-3940256099942544/2247696110'
      : 'ca-app-pub-1350781778307915/7347806891';

  /// Native video demo unit — better fill on some Android TV devices.
  // Native video ad (production uses same native id unless different)
  // Test id (commented): ca-app-pub-3940256099942544/1044960115
  static String get nativeVideoAdUnitId => useTestAdMob
      ? 'ca-app-pub-3940256099942544/1044960115'
      : 'ca-app-pub-1350781778307915/7347806891';

  // App open ad: production id provided by user
  // Test id (commented): ca-app-pub-3940256099942544/9257395921
  static String get appOpenAdUnitId => useTestAdMob
      ? 'ca-app-pub-3940256099942544/9257395921'
      : 'ca-app-pub-1350781778307915/2430906577';

  /// Static/image interstitial (Google test often shows the unicycle creative).
  // Interstitial: production id provided by user
  // Test id (commented): ca-app-pub-3940256099942544/1033173712
  static String get interstitialAdUnitId => useTestAdMob
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-1350781778307915/7521021112';

  /// Rewarded video for "Watch Ad" unlock.
  // Rewarded (watch ad): production id provided by user.
  // Test id (commented): ca-app-pub-3940256099942544/5224354917
  static String get rewardedAdUnitId => useTestAdMob
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-1350781778307915/5558595389';

  /// Fallback to the same unit for rewarded interstitial loading.
  static String get rewardedInterstitialAdUnitId => rewardedAdUnitId;

  /// Mobile test VAST tag (linear pre-roll).
  static const String mobileTestVastUrl =
      'https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_ad_samples&sz=640x480&cust_params=sample_ct%3Dlinear&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&correlator=';

  /// Mobile live VAST tag (linear pre-roll).
  static const String mobileLiveVastUrl =
      'https://pubads.g.doubleclick.net/gampad/ads?iu=/23342341691,23314616517/FlixoTV_110626&description_url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.flixotv.ignia%26hl%3Den&tfcd=0&npa=0&sz=300x250%7C640x480&gdfp_req=1&unviewed_position_start=1&output=vast&env=vp&impl=s&correlator=';

  /// Pre-roll VAST tag used before channel playback on mobile.
  static String get mobileVastUrl =>
      useTestAdMob ? mobileTestVastUrl : mobileLiveVastUrl;

  /// Backwards compatibility alias for mobile playback.
  static String get vastUrl => mobileVastUrl;

  /// TV test VAST tag for verification on TV devices.
  static const String tvTestVastUrl =
      'https://pubads.g.doubleclick.net/gampad/ads?iu=/21775744923/external/single_preroll_skippable&sz=640x480&ciu_szs=300x250%2C728x90&gdfp_req=1&output=vast&unviewed_position_start=1&env=vp&correlator=';

  /// TV live VAST tag (`FlixoTV_110626` line item in GAM).
  static const String tvLiveVastUrl =
      'https://pubads.g.doubleclick.net/gampad/ads?iu=/23342341691,23314616517/Flixotv_TV&description_url=https%3A%2F%2Fplay.google.com%2Fstore%2Fapps%2Fdetails%3Fid%3Dcom.flixotv.ignia%26hl%3Den%26pli%3D1&tfcd=0&npa=0&sz=1920x1080&gdfp_req=1&unviewed_position_start=1&output=vast&env=vp&msid=com.flixotv.ignia&an=Flixo%20TV&correlator=';

  /// Pre-roll VAST tag used before channel playback on TV.
  static String get tvVastUrl =>
      useTestAdMob ? tvTestVastUrl : tvLiveVastUrl;
}
