import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iptv_demo/ads/ad_config.dart';
import 'package:iptv_demo/ads/ad_mob_diagnostics.dart';
import 'package:iptv_demo/ads/tv_ad_policy.dart';
import 'package:iptv_demo/ads/tv_home_ad_pool.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';

/// Configures AdMob (test devices, etc.) and initializes the SDK.
///
/// [main] calls [configureAndInitialize] on every cold start and hot restart;
/// a fresh [whenReady] is created each time so ad widgets never load against a
/// torn-down native layer after hot restart.
class AdMobBootstrap {
  AdMobBootstrap._();

  static Completer<void>? _ready;
  static bool _testDevicesConfigured = false;

  /// Completes after the latest [configureAndInitialize] run finishes.
  static Future<void> get whenReady {
    final c = _ready;
    if (c == null) return configureAndInitialize();
    return c.future;
  }

  /// From logcat: "Use RequestConfiguration.Builder().setTestDeviceIds(...)"
  static const List<String> _knownTestDeviceIds = [
    '7148B2DF5B7B5F8D22CCBD5F536EF258', // BeyondTV
    'C78A4F81DA09FA2563E11B799D90043C', // Xiaomi / phones
  ];

  static Future<void> configureAndInitialize() async {
    final ready = Completer<void>();
    _ready = ready;

    try {
      if ((AdConfig.useTestAdMob || kDebugMode) && !_testDevicesConfigured) {
        await MobileAds.instance.updateRequestConfiguration(
          RequestConfiguration(
            testDeviceIds: _knownTestDeviceIds,
          ),
        );
        _testDevicesConfigured = true;
        debugPrint(
          '[AdMob] test device IDs configured (${_knownTestDeviceIds.length})',
        );
      }

      final status = await MobileAds.instance.initialize();
      final isTv = await isAndroidTvLeanbackDevice();
      if (isTv) {
        TvAdPolicy.markSdkInitialized();
        await AdMobDiagnostics.logTvHealth(status);
        TvHomeAdPool.instance.reset();
      }
      debugPrint(
        '[AdMob] initialized (testMode=${AdConfig.useTestAdMob} isTv=$isTv) '
        'adapters=${status.adapterStatuses.length}',
      );
    } finally {
      if (!ready.isCompleted) ready.complete();
    }
  }
}
