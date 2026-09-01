import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iptv_demo/ads/ad_config.dart';
import 'package:iptv_demo/utils/app_build_flavor.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';

/// One-time TV AdMob health log after SDK init (read logcat for [AdMobDiag]).
class AdMobDiagnostics {
  AdMobDiagnostics._();

  static bool _logged = false;

  static Future<void> logTvHealth(InitializationStatus status) async {
    if (_logged || kIsWeb) return;
    if (!await isAndroidTvLeanbackDevice()) return;
    _logged = true;

    debugPrint('[AdMobDiag] ── Android TV ad check ──');
    final version = await AppBuildFlavor.versionName();
    final tvApk = await AppBuildFlavor.isTvApk();
    debugPrint('[AdMobDiag] versionName=$version tvApk=$tvApk');
    if (!tvApk) {
      debugPrint(
        '[AdMobDiag] WARNING: mobile APK on TV — run '
        '`flutter run --flavor tv -d BeyondTV` (expect app-tv-debug.apk)',
      );
    }
    debugPrint('[AdMobDiag] testMode=${AdConfig.useTestAdMob} debug=$kDebugMode');
    debugPrint(
      '[AdMobDiag] appId=(check AndroidManifest) (must match AndroidManifest)',
    );
    debugPrint(
      '[AdMobDiag] bannerTestUnit=${AdConfig.fixedBannerAdUnitId}',
    );

    for (final entry in status.adapterStatuses.entries) {
      final s = entry.value;
      debugPrint(
        '[AdMobDiag] adapter ${entry.key}: '
        'state=${s.state.name} '
        'latency=${s.latency}ms '
        'desc=${s.description}',
      );
    }

    debugPrint(
      '[AdMobDiag] If ads fail with code 3 (No fill) but log shows '
      '"This request is sent from a test device", the Flutter setup is OK — '
      'Google returned no creative for this TV (often outdated Play Services / WebView).',
    );
    debugPrint(
      '[AdMobDiag] Search logcat for "Use RequestConfiguration" to copy '
      'this TV\'s hashed device ID if it changed.',
    );
    debugPrint('[AdMobDiag] ── end ──');
  }
}
