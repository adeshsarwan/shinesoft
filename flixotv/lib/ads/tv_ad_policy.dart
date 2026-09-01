import 'package:flutter/foundation.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';

/// Shared limits for Android TV — avoids request storms that cause error 3 on leanback.
class TvAdPolicy {
  TvAdPolicy._();

  static const int maxLoadAttemptsPerWidget = 6;

  static const int globalNoFillThreshold = 12;
  static const Duration globalNoFillPause = Duration(seconds: 45);

  /// Wait for UI + WebView after AdMob init before the first TV ad request.
  static const Duration initialLoadDelay = Duration(seconds: 4);

  /// Gap between format attempts on TV home hero.
  static const Duration homeFormatGap = Duration(seconds: 12);

  /// Background retries when home hero has no fill.
  static const Duration homeRetryInterval = Duration(seconds: 90);
  static const int maxHomeRetryRounds = 8;

  /// Inline list/search native slots stay off; home hero uses [TvHomeAdPool].
  static const bool useNativeAdsOnTv = false;

  static bool? _isTv;
  static DateTime? _readyAfter;
  static int _globalNoFillCount = 0;
  static DateTime? _globalPausedUntil;

  /// True after home hero loaded or gave up (allows interstitial / other slots).
  static bool homeAdPhaseComplete = false;

  static Future<bool> get isTv async {
    _isTv ??= await isAndroidTvLeanbackDevice();
    return _isTv!;
  }

  static void markSdkInitialized() {
    _readyAfter = DateTime.now().add(initialLoadDelay);
  }

  static void markHomeAdPhaseComplete() {
    homeAdPhaseComplete = true;
  }

  static Future<bool> allowSecondaryTvAds() async {
    if (!await isTv) return true;
    return homeAdPhaseComplete;
  }

  static bool get canRequestNow {
    final pause = _globalPausedUntil;
    if (pause != null && DateTime.now().isBefore(pause)) {
      return false;
    }
    final ready = _readyAfter;
    if (ready != null && DateTime.now().isBefore(ready)) {
      return false;
    }
    return true;
  }

  static void recordNoFill() {
    _globalNoFillCount++;
    if (_globalNoFillCount >= globalNoFillThreshold) {
      _globalPausedUntil = DateTime.now().add(globalNoFillPause);
      _globalNoFillCount = 0;
      debugPrint(
        '[TvAdPolicy] global no-fill pause until $_globalPausedUntil',
      );
    }
  }

  static void recordSuccess() {
    _globalNoFillCount = 0;
    _globalPausedUntil = null;
  }

  static Duration waitUntilReady() {
    final now = DateTime.now();
    var latest = now;

    final pause = _globalPausedUntil;
    if (pause != null && pause.isAfter(latest)) latest = pause;

    final ready = _readyAfter;
    if (ready != null && ready.isAfter(latest)) latest = ready;

    return latest.difference(now);
  }
}
