import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iptv_demo/ads/ad_banner_size_resolver.dart';
import 'package:iptv_demo/ads/ad_config.dart';
import 'package:iptv_demo/ads/ad_mob_bootstrap.dart';
import 'package:iptv_demo/ads/ad_load_scheduler.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/ads/tv_ad_policy.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/utils/premium_access.dart';

class BannerAdWidget extends StatefulWidget {
  /// When true, uses [shouldShowAuthScreenAds] (login / sign-up).
  final bool authScreen;

  /// Large wide slot (TV home hero). Uses adaptive/leaderboard sizes first.
  final bool hero;

  const BannerAdWidget({
    super.key,
    this.authScreen = false,
    this.hero = false,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  AdSize _placeholderSize = AdSize.banner;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _stopped = false;
  int _loadAttempts = 0;
  int _fallbackStep = 0;
  bool? _isTv;

  bool get _shouldShow =>
      widget.authScreen ? shouldShowAuthScreenAds : shouldShowAdsToUser;

  int get _maxAttempts =>
      _isTv == true ? TvAdPolicy.maxLoadAttemptsPerWidget : AdsVariable.maxAdLoadAttempts;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    _isTv = await TvAdPolicy.isTv;
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleLoad());
  }

  @override
  void didUpdateWidget(covariant BannerAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authScreen != widget.authScreen ||
        oldWidget.hero != widget.hero) {
      _disposeAd();
      _stopped = false;
      _fallbackStep = 0;
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    if (!_shouldShow || _isLoading || _isLoaded || _stopped) return;
    if (_loadAttempts >= _maxAttempts) {
      _stopped = true;
      return;
    }
    unawaited(_loadBannerAd());
  }

  Future<void> _loadBannerAd() async {
    if (!_shouldShow || _isLoading || !mounted || _stopped) return;
    if (_loadAttempts >= _maxAttempts) {
      _stopped = true;
      return;
    }

    await AdMobBootstrap.whenReady;

    _isTv ??= await TvAdPolicy.isTv;
    if (_isTv == true && !widget.hero) {
      if (!await TvAdPolicy.allowSecondaryTvAds()) {
        Future<void>.delayed(const Duration(seconds: 5), () {
          if (mounted && _shouldShow) _scheduleLoad();
        });
        return;
      }
    }
    if (_isTv == true && !TvAdPolicy.canRequestNow) {
      final wait = TvAdPolicy.waitUntilReady();
      if (wait > Duration.zero) {
        Future.delayed(wait, () {
          if (mounted && _shouldShow) _scheduleLoad();
        });
      }
      return;
    }

    _isLoading = true;
    _loadAttempts++;

    if (!mounted) {
      _isLoading = false;
      return;
    }
    final width = MediaQuery.sizeOf(context).width.truncate();
    final config = await _configForAttempt(width, _fallbackStep);
    if (!mounted || !_shouldShow) {
      _isLoading = false;
      return;
    }

    _placeholderSize = config.size;
    debugPrint(
      '[BannerAd] loading unit=${config.adUnitId} mode=${config.mode.name} ' 
      'size=${config.size.width}x${config.size.height} ' 
      'attempt=$_loadAttempts fallback=$_fallbackStep',
    );
    _bannerAd?.dispose();
    _bannerAd = BannerAd(
      adUnitId: config.adUnitId,
      size: config.size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !_shouldShow) {
            ad.dispose();
            return;
          }
          if (_isTv == true) TvAdPolicy.recordSuccess();
          setState(() {
            _isLoading = false;
            _isLoaded = true;
            _fallbackStep = 0;
          });
          debugPrint(
            '[BannerAd] loaded ${config.mode.name} '
            '(${AdConfig.useTestAdMob ? 'test' : 'prod'}) '
            '${config.size.width}x${config.size.height}',
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint(
            '[BannerAd] load failed (attempt $_loadAttempts/$_maxAttempts, '
            'fallback $_fallbackStep, ${config.mode.name}): $error',
          );
          if (!mounted) return;

          if (error.code == 3 && _isTv == true) {
            TvAdPolicy.recordNoFill();
          }

          if (error.code == 3 && _fallbackStep < _maxFallbackSteps) {
            _fallbackStep++;
            _isLoading = false;
            _scheduleLoad();
            return;
          }

          final delay = _retryDelayForError(error.code, _loadAttempts);
          AdLoadScheduler.instance.deferNextSlot(delay);
          _isLoading = false;
          if (_loadAttempts >= _maxAttempts) {
            _stopped = true;
            if (mounted) setState(() {});
            return;
          }
          Future.delayed(delay, () {
            if (mounted && _shouldShow && !_stopped) {
              _fallbackStep = 0;
              _scheduleLoad();
            }
          });
          if (mounted) setState(() {});
        },
      ),
    );

    await AdLoadScheduler.instance.enqueue(() async {
      if (!mounted || !_shouldShow) return;
      await _bannerAd!.load();
    });

    if (mounted && _isLoading && !_isLoaded) {
      setState(() {});
    }
  }

  int get _maxFallbackSteps => _isTv == true ? 2 : 2;

  /// TV hero: adaptive → leaderboard → fixed. TV inline: fixed → leaderboard → adaptive.
  Future<ResolvedBannerConfig> _configForAttempt(int width, int step) async {
    _isTv ??= await TvAdPolicy.isTv;
    if (_isTv == true) {
      if (widget.hero) {
        if (step == 0) {
          final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
                Orientation.landscape,
                width,
              ) ??
              AdSize.leaderboard;
          return ResolvedBannerConfig(
            adUnitId: AdConfig.adaptiveBannerAdUnitId,
            size: size,
            mode: BannerLoadMode.adaptive,
          );
        }
        if (step == 1) {
          return ResolvedBannerConfig(
            adUnitId: AdConfig.fixedBannerAdUnitId,
            size: AdSize.leaderboard,
            mode: BannerLoadMode.fixed,
          );
        }
        return ResolvedBannerConfig(
          adUnitId: AdConfig.fixedBannerAdUnitId,
          size: AdSize.banner,
          mode: BannerLoadMode.fixed,
        );
      }
      if (step == 0) {
        return ResolvedBannerConfig(
          adUnitId: AdConfig.fixedBannerAdUnitId,
          size: AdSize.banner,
          mode: BannerLoadMode.fixed,
        );
      }
      if (step == 1) {
        return ResolvedBannerConfig(
          adUnitId: AdConfig.fixedBannerAdUnitId,
          size: AdSize.leaderboard,
          mode: BannerLoadMode.fixed,
        );
      }
      final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
            Orientation.landscape,
            width,
          ) ??
          AdSize.banner;
      return ResolvedBannerConfig(
        adUnitId: AdConfig.adaptiveBannerAdUnitId,
        size: size,
        mode: BannerLoadMode.adaptive,
      );
    }

    if (step == 0) {
      final size = await AdSize.getAnchoredAdaptiveBannerAdSize(
            Orientation.landscape,
            width,
          ) ??
          AdSize.banner;
      return ResolvedBannerConfig(
        adUnitId: AdConfig.adaptiveBannerAdUnitId,
        size: size,
        mode: BannerLoadMode.adaptive,
      );
    }
    if (step == 1) {
      final size =
          await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
                width,
              ) ??
              AdSize.banner;
      return ResolvedBannerConfig(
        adUnitId: AdConfig.adaptiveBannerAdUnitId,
        size: size,
        mode: BannerLoadMode.adaptive,
      );
    }
    return ResolvedBannerConfig(
      adUnitId: AdConfig.fixedBannerAdUnitId,
      size: AdSize.banner,
      mode: BannerLoadMode.fixed,
    );
  }

  void _disposeAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;
    _isLoading = false;
    _loadAttempts = 0;
    _stopped = false;
    _placeholderSize = AdSize.banner;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  Widget _buildLoadingPlaceholder({double? height, double? width}) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.14),
      highlightColor: Colors.white.withValues(alpha: 0.28),
      child: Container(
        height: height,
        width: width,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 16,
              width: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Container(
              height: 38,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        auth.isPremiumUser.value;
        auth.isLoggedIn.value;
        auth.currentProfile.value;
        AdsVariable.isPurchased.value;
        auth.hasAdFreeAccess;
      } else {
        AdsVariable.isPurchased.value;
      }

      if (!_shouldShow) {
        _disposeAd();
        return const SizedBox.shrink();
      }

      if (!_isLoaded) {
        if (widget.hero) {
          if (_stopped) return const SizedBox.shrink();
          return SizedBox(
            width: double.infinity,
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: _buildLoadingPlaceholder(height: 56, width: double.infinity),
            ),
          );
        }
        // TV inline / failed loads: no blank gap when AdMob returns no fill.
        if (_isTv == true || _stopped) {
          return const SizedBox.shrink();
        }
        return SizedBox(
          height: _placeholderSize.height.toDouble(),
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _buildLoadingPlaceholder(
              height: _placeholderSize.height.toDouble(),
              width: double.infinity,
            ),
          ),
        );
      }

      final adHeight = _bannerAd!.size.height.toDouble();
      return SizedBox(
        width: double.infinity,
        height: widget.hero
            ? adHeight.clamp(50.0, 250.0)
            : adHeight,
        child: AdWidget(ad: _bannerAd!),
      );
    });
  }

  Duration _retryDelayForError(int code, int attempts) {
    if (code == 1) return const Duration(seconds: 35);
    if (code == 3) {
      if (_isTv == true) {
        return Duration(seconds: (15 * attempts).clamp(15, 90));
      }
      final secs = AdConfig.useTestAdMob
          ? (4 * attempts).clamp(4, 20)
          : (6 * attempts).clamp(8, 45);
      return Duration(seconds: secs);
    }
    return const Duration(seconds: 20);
  }
}
