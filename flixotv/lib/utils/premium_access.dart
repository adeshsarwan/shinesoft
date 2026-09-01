import 'package:get/get.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/services/auth_service.dart';

/// Whether the signed-in user has premium / active subscription (no ads).
bool get userHasPremiumAccess {
  if (!Get.isRegistered<AuthService>()) {
    return AdsVariable.isPurchased.value;
  }
  return Get.find<AuthService>().hasAdFreeAccess;
}

/// Whether ads and the "watch ad first" gate should be shown in the main app.
bool get shouldShowAdsToUser => !userHasPremiumAccess;

/// Native ads on login / sign-up (guests only).
bool get shouldShowAuthScreenAds {
  if (!Get.isRegistered<AuthService>()) return true;
  final auth = Get.find<AuthService>();
  if (!auth.isLoggedIn.value) return true;
  return shouldShowAdsToUser;
}

/// App-open ads: guests always; signed-in users only when not ad-free.
bool get shouldShowAppOpenAd {
  if (!Get.isRegistered<AuthService>()) return true;
  final auth = Get.find<AuthService>();
  if (!auth.isLoggedIn.value) return true;
  return shouldShowAdsToUser;
}
