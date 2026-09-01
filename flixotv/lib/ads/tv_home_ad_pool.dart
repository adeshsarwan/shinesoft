import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iptv_demo/ads/ad_config.dart';
import 'package:iptv_demo/ads/ad_load_scheduler.dart';
import 'package:iptv_demo/ads/ad_mob_bootstrap.dart';
import 'package:iptv_demo/ads/tv_ad_policy.dart';

enum TvHomeAdKind { none, banner, native }

/// Single TV home ad: loads only after home is visible, one format at a time.
class TvHomeAdPool extends ChangeNotifier {
  TvHomeAdPool._();
  static final TvHomeAdPool instance = TvHomeAdPool._();

  BannerAd? _banner;
  NativeAd? _native;
  TvHomeAdKind _kind = TvHomeAdKind.none;
  bool _warming = false;
  bool _failed = false;
  int _retryRound = 0;
  Timer? _retryTimer;
  static bool _started = false;

  bool get hasAd => _kind != TvHomeAdKind.none;
  bool get hasFailed => _failed;
  TvHomeAdKind get kind => _kind;
  BannerAd? get banner => _kind == TvHomeAdKind.banner ? _banner : null;
  NativeAd? get native => _kind == TvHomeAdKind.native ? _native : null;

  void reset() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _banner?.dispose();
    _native?.dispose();
    _banner = null;
    _native = null;
    _kind = TvHomeAdKind.none;
    _warming = false;
    _failed = false;
    _retryRound = 0;
    _started = false;
    TvAdPolicy.homeAdPhaseComplete = false;
  }

  /// Call from [TvHomeHeroAd] when home is on screen (not during cold-start).
  Future<void> startWhenHomeVisible() async {
    if (_started || !await TvAdPolicy.isTv) return;
    _started = true;

    await AdMobBootstrap.whenReady;
    await Future<void>.delayed(const Duration(milliseconds: 500));
    await WidgetsBinding.instance.endOfFrame;

    final wait = TvAdPolicy.waitUntilReady();
    if (wait > Duration.zero) await Future.delayed(wait);

    unawaited(_runLoadCycle());
  }

  Future<void> _runLoadCycle() async {
    if (_warming || hasAd) return;
    _warming = true;
    _failed = false;
    notifyListeners();

    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final width = (view.physicalSize.width / view.devicePixelRatio).truncate();

    final adaptive = await AdSize.getAnchoredAdaptiveBannerAdSize(
      Orientation.landscape,
      width,
    );

    final attempts = <Future<bool> Function()>[
      () => _loadBanner(AdConfig.fixedBannerAdUnitId, AdSize.banner, 'banner'),
      () => _loadBanner(
          AdConfig.fixedBannerAdUnitId, AdSize.leaderboard, 'leaderboard'),
      if (adaptive != null)
        () => _loadBanner(
            AdConfig.adaptiveBannerAdUnitId, adaptive, 'adaptive'),
      () => _loadNative(AdConfig.nativeAdUnitId, 'native'),
      () => _loadNative(AdConfig.nativeVideoAdUnitId, 'nativeVideo'),
    ];

    for (final attempt in attempts) {
      if (hasAd) break;
      if (!TvAdPolicy.canRequestNow) {
        await Future.delayed(TvAdPolicy.waitUntilReady());
      }
      final ok = await attempt();
      if (ok) break;
      AdLoadScheduler.instance.deferNextSlot(TvAdPolicy.homeFormatGap);
      await Future.delayed(TvAdPolicy.homeFormatGap);
    }

    _warming = false;
    if (hasAd) {
      TvAdPolicy.recordSuccess();
      TvAdPolicy.markHomeAdPhaseComplete();
      debugPrint('[TvHomeAdPool] home ad ready ($_kind)');
    } else {
      _failed = true;
      debugPrint(
        '[TvHomeAdPool] no fill (round $_retryRound) — '
        'device GMS may not serve test ads on this TV',
      );
      _scheduleRetry();
    }
    notifyListeners();
  }

  void _scheduleRetry() {
    if (_retryRound >= TvAdPolicy.maxHomeRetryRounds) {
      TvAdPolicy.markHomeAdPhaseComplete();
      return;
    }
    _retryTimer?.cancel();
    _retryTimer = Timer(TvAdPolicy.homeRetryInterval, () {
      _retryRound++;
      _failed = false;
      _started = true;
      unawaited(_runLoadCycle());
    });
  }

  Future<bool> _loadBanner(String unitId, AdSize size, String label) async {
    final done = Completer<bool>();
    late final BannerAd ad;
    ad = BannerAd(
      adUnitId: unitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _disposeAds();
          _banner = ad;
          _kind = TvHomeAdKind.banner;
          debugPrint('[TvHomeAdPool] loaded $label ${size.width}x${size.height}');
          if (!done.isCompleted) done.complete(true);
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (error.code == 3) TvAdPolicy.recordNoFill();
          debugPrint('[TvHomeAdPool] $label failed: $error');
          if (!done.isCompleted) done.complete(false);
        },
      ),
    );

    await AdLoadScheduler.instance.enqueue(() async {
      try {
        await ad.load();
      } catch (e) {
        debugPrint('[TvHomeAdPool] $label error: $e');
        if (!done.isCompleted) done.complete(false);
      }
    });

    return done.future.timeout(
      const Duration(seconds: 65),
      onTimeout: () {
        if (!done.isCompleted) done.complete(false);
        return false;
      },
    );
  }

  Future<bool> _loadNative(String unitId, String label) async {
    final done = Completer<bool>();
    late final NativeAd ad;
    ad = NativeAd(
      adUnitId: unitId,
      factoryId: defaultTargetPlatform == TargetPlatform.android
          ? 'listTile'
          : null,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) {
          _disposeAds();
          _native = ad;
          _kind = TvHomeAdKind.native;
          debugPrint('[TvHomeAdPool] loaded $label');
          if (!done.isCompleted) done.complete(true);
        },
        onAdFailedToLoad: (failed, error) {
          failed.dispose();
          if (error.code == 3) TvAdPolicy.recordNoFill();
          debugPrint('[TvHomeAdPool] $label failed: $error');
          if (!done.isCompleted) done.complete(false);
        },
      ),
    );

    await AdLoadScheduler.instance.enqueue(() async {
      try {
        await ad.load();
      } catch (e) {
        debugPrint('[TvHomeAdPool] $label error: $e');
        if (!done.isCompleted) done.complete(false);
      }
    });

    return done.future.timeout(
      const Duration(seconds: 65),
      onTimeout: () {
        if (!done.isCompleted) done.complete(false);
        return false;
      },
    );
  }

  void _disposeAds() {
    _banner?.dispose();
    _native?.dispose();
    _banner = null;
    _native = null;
    _kind = TvHomeAdKind.none;
  }
}
