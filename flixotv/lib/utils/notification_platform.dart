import 'package:get/get.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';
import 'package:iptv_demo/utils/push_token_util.dart';

/// Whether this device is Android TV (leanback).
Future<bool> isTvDevice() => isAndroidTvLeanbackDevice();

/// Server push (FCM schedule notifications) on TV: user must be signed in and
/// have registered with `platform: tv` at login (backend routes by platform).
bool get isTvPushRegisteredWithServer {
  if (!Get.isRegistered<AuthService>()) return false;
  final auth = Get.find<AuthService>();
  return auth.isLoggedIn.value &&
      auth.registeredPlatform.value == authPlatformTv;
}

/// TV schedule / program notifications are allowed only when logged in on TV.
Future<bool> canUseTvPushNotifications() async {
  if (!await isTvDevice()) return false;
  if (!Get.isRegistered<AuthService>()) return false;
  return Get.find<AuthService>().isLoggedIn.value;
}

/// After login on TV, warm up FCM permission + token for push delivery.
Future<void> ensureTvPushReadyAfterLogin() async {
  if (!await isTvDevice()) return;
  attachFcmTokenRefreshListener();
  await prefetchFcmToken();
}
