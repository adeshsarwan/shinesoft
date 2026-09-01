import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iptv_demo/ads/ad_config.dart';
import 'package:iptv_demo/ads/ad_load_scheduler.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/ads/tv_ad_policy.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/utils/premium_access.dart';

class NativeAdWidget extends StatefulWidget {
  /// When true, uses [shouldShowAuthScreenAds] (login / sign-up).
  final bool authScreen;

  const NativeAdWidget({super.key, this.authScreen = false});

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _stopped = false;
  int _loadAttempts = 0;
  int _unitFallback = 0;
  bool? _isTv;

  double _adHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.15;

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
    if (_isTv == true && !TvAdPolicy.useNativeAdsOnTv) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleLoad());
  }

  @override
  void didUpdateWidget(covariant NativeAdWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authScreen != widget.authScreen) {
      _disposeAd();
      _stopped = false;
      _unitFallback = 0;
      _scheduleLoad();
    }
  }

  void _scheduleLoad() {
    if (_isTv == true && !TvAdPolicy.useNativeAdsOnTv) return;
    if (!_shouldShow || _isLoading || _isLoaded || _stopped) return;
    if (_loadAttempts >= _maxAttempts) {
      _stopped = true;
      return;
    }
    unawaited(_loadNativeAd());
  }

  Future<void> _loadNativeAd() async {
    if (!_shouldShow || _isLoading || _stopped) return;
    if (_loadAttempts >= _maxAttempts) {
      _stopped = true;
      return;
    }

    _isTv ??= await TvAdPolicy.isTv;
    final isTv = _isTv == true;
    if (isTv && !TvAdPolicy.useNativeAdsOnTv) return;

    if (isTv && !TvAdPolicy.canRequestNow) {
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

    _nativeAd?.dispose();
    final unitId = _unitIdForAttempt(_unitFallback, isTv);
    final unitLabel = _unitFallback == 0 ? 'native' : 'nativeVideo';
    debugPrint(
      '[NativeAd] loading unit=$unitId label=$unitLabel ' 
      'attempt=$_loadAttempts fallback=$_unitFallback isTv=$isTv',
    );
    _nativeAd = NativeAd(
      adUnitId: unitId,
      factoryId:
          defaultTargetPlatform == TargetPlatform.android ? 'listTile' : null,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (!mounted || !_shouldShow) {
            ad.dispose();
            return;
          }
          if (isTv) TvAdPolicy.recordSuccess();
          setState(() {
            _isLoading = false;
            _isLoaded = true;
            _unitFallback = 0;
          });
          debugPrint(
            '[NativeAd] loaded (${AdConfig.useTestAdMob ? 'test' : 'prod'}) '
            'unit=$unitLabel',
          );
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint(
            '[NativeAd] load failed (attempt $_loadAttempts/$_maxAttempts, '
            'fallback $_unitFallback): $error',
          );
          if (!mounted) return;

          if (error.code == 3 && isTv) {
            TvAdPolicy.recordNoFill();
          }

          if (error.code == 3 && isTv && _unitFallback == 0) {
            _unitFallback = 1;
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
              _unitFallback = 0;
              _scheduleLoad();
            }
          });
          if (mounted) setState(() {});
        },
      ),
    );

    await AdLoadScheduler.instance.enqueue(() async {
      if (!mounted || !_shouldShow) return;
      _nativeAd!.load();
    });

    if (mounted && _isLoading && !_isLoaded) {
      setState(() {});
    }
  }

  String _unitIdForAttempt(int attempt, bool isTv) {
    if (!isTv || attempt == 0) return AdConfig.nativeAdUnitId;
    return AdConfig.nativeVideoAdUnitId;
  }

  void _disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
    _isLoading = false;
    _loadAttempts = 0;
    _stopped = false;
    _unitFallback = 0;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  Widget _buildLoadingPlaceholder(double height) {
    return Shimmer.fromColors(
      baseColor: Colors.white.withValues(alpha: 0.14),
      highlightColor: Colors.white.withValues(alpha: 0.28),
      child: Container(
        height: height,
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
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
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
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
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
              height: 36,
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

      // On TV, native is handled by explicit [BannerAdWidget] slots in TV layouts.
      if (_isTv == true && !TvAdPolicy.useNativeAdsOnTv) {
        return const SizedBox.shrink();
      }

      final height = _adHeight(context);

      if (!_isLoaded) {
        return SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: _buildLoadingPlaceholder(height),
          ),
        );
      }

      return SizedBox(
        height: height,
        child: AdWidget(ad: _nativeAd!),
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
          : (8 * attempts).clamp(10, 50);
      return Duration(seconds: secs);
    }
    return const Duration(seconds: 20);
  }
}
