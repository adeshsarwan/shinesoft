import 'package:get/get.dart';
import 'package:iptv_demo/utils/premium_access.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdsVariable {
  // Ad configuration
  static const int maxAdLoadAttempts = 3;
  static const Duration adLoadTimeout = Duration(seconds: 10);
  static const Duration minIntervalBetweenAds = Duration(minutes: 2);

  // Premium check — synced from AuthService / Stripe / profile API.
  static RxBool isPurchased =
      false.obs; // Will be true when user purchases premium

  /// When true, ads and the watch-ad-before-play sheet may be shown.
  static bool get shouldShowAds => shouldShowAdsToUser;

  static const String _prefsPremiumKey = 'local_premium_purchased';
  static const String _authPremiumKey = 'is_premium_user';

  /// [includeAuthPremium] — only set when the user has a saved session; guests
  /// should not inherit `is_premium_user` from a previous account.
  static Future<void> loadPersistedPurchase({
    bool includeAuthPremium = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final local = prefs.getBool(_prefsPremiumKey) ?? false;
      final auth = includeAuthPremium
          ? (prefs.getBool(_authPremiumKey) ?? false)
          : false;
      isPurchased.value = local || auth;
    } catch (_) {}
  }

  static Future<void> markPurchased() async {
    await setPurchased(true);
  }

  static Future<void> setPurchased(bool purchased) async {
    isPurchased.value = purchased;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsPremiumKey, purchased);
    } catch (_) {}
  }

  // Ad states
  static bool isAdLoaded = false;
  static bool isAdShowing = false;
  static DateTime? lastAdShownTime;
}
