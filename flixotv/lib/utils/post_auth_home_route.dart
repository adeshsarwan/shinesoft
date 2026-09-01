import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:iptv_demo/routes/app_routes.dart';

/// Android TV (Leanback) — used for routing and splash behaviour.
Future<bool> isAndroidTvLeanbackDevice() async {
  if (kIsWeb) return false;
  try {
    final android = await DeviceInfoPlugin().androidInfo;
    return android.systemFeatures.contains('android.software.leanback');
  } catch (_) {
    return false;
  }
}

/// Main shell after login or when splash sends an already-logged-in user.
/// Android TV → [AppRoutes.HOME_TV]; phones → [AppRoutes.HOME].
Future<String> resolveHomeRouteForPlatform() async {
  if (await isAndroidTvLeanbackDevice()) {
    return AppRoutes.HOME_TV;
  }
  return AppRoutes.HOME;
}

/// First route after splash.
/// - Logged in → TV home or mobile home (same as [resolveHomeRouteForPlatform]).
/// - Logged out on **Android TV** → TV home (guest browse; no login gate).
/// - Logged out on phone → login.
Future<String> resolveSplashDestination({required bool isLoggedIn}) async {
  if (isLoggedIn) {
    return await resolveHomeRouteForPlatform();
  }
  if (await isAndroidTvLeanbackDevice()) {
    return AppRoutes.HOME_TV;
  }
  return AppRoutes.LOGIN;
}
