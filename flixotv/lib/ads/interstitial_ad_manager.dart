import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iptv_demo/ads/ad_config.dart';
import 'package:iptv_demo/ads/ad_load_scheduler.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/ads/app_open_ad_manager.dart';
import 'package:iptv_demo/ads/tv_ad_policy.dart';
import 'package:iptv_demo/utils/premium_access.dart';

/// Preloads and shows full-screen **video** rewarded interstitials for Watch Ad.
class InterstitialAdManager {
  InterstitialAdManager._();
  static final InterstitialAdManager instance = InterstitialAdManager._();

  RewardedInterstitialAd? _rewardedInterstitialAd;
  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  int _loadAttempts = 0;
  Completer<void>? _showCompleter;

  bool get isAdReady => _rewardedInterstitialAd != null || _rewardedAd != null;

  /// Start loading so the ad is ready when the user taps Watch.
  void preload() {
    if (!shouldShowAdsToUser) return;
    unawaited(_preloadWhenAllowed());
  }

  Future<void> _preloadWhenAllowed() async {
    if (!await TvAdPolicy.allowSecondaryTvAds()) {
      await Future.any<void>([
        Future<void>.delayed(const Duration(minutes: 2)),
        _waitForHomeAdPhase(),
      ]);
    }
    if (!shouldShowAdsToUser) return;
    if (_isLoading || isAdReady) return;
    if (_loadAttempts >= AdsVariable.maxAdLoadAttempts) return;
    _loadAd();
  }

  Future<void> _waitForHomeAdPhase() async {
    while (!TvAdPolicy.homeAdPhaseComplete) {
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  void _loadAd() {
    if (!shouldShowAdsToUser) return;
    if (_isLoading || isAdReady) return;

    _isLoading = true;
    _loadAttempts++;

    unawaited(
      AdLoadScheduler.instance.enqueue(() async {
        debugPrint(
          '[VideoAd] loading RewardedAd unit=${AdConfig.rewardedAdUnitId}',
        );
        RewardedAd.load(
          adUnitId: AdConfig.rewardedAdUnitId,
          request: const AdRequest(),
          rewardedAdLoadCallback: RewardedAdLoadCallback(
            onAdLoaded: (ad) {
              _isLoading = false;
              _loadAttempts = 0;
              _rewardedAd = ad;
              debugPrint(
                '[RewardedAd] loaded unit=${AdConfig.rewardedAdUnitId} ' 
                '(${AdConfig.useTestAdMob ? 'test' : 'prod'})',
              );
            },
            onAdFailedToLoad: (error) {
              debugPrint(
                '[RewardedAd] load failed unit=${AdConfig.rewardedAdUnitId} ' 
                'error=$error',
              );
              if (error.code == 3 &&
                  error.message.contains('doesn\'t match format')) {
                _loadRewardedInterstitialAd();
                return;
              }
              _isLoading = false;
              _rewardedAd = null;
              final delay = error.code == 1
                  ? const Duration(seconds: 35)
                  : Duration(seconds: (8 * _loadAttempts).clamp(10, 45));
              AdLoadScheduler.instance.deferNextSlot(delay);
              if (_loadAttempts < AdsVariable.maxAdLoadAttempts) {
                Future.delayed(delay, preload);
              }
            },
          ),
        );
      }),
    );
  }

  void _loadRewardedInterstitialAd() {
    debugPrint(
      '[VideoAd] falling back to RewardedInterstitialAd unit=${AdConfig.rewardedInterstitialAdUnitId}',
    );
    RewardedInterstitialAd.load(
      adUnitId: AdConfig.rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback:
          RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _isLoading = false;
          _loadAttempts = 0;
          _rewardedInterstitialAd = ad;
          debugPrint(
            '[VideoRewardedInterstitialAd] loaded (${AdConfig.useTestAdMob ? 'test' : 'prod'})',
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _rewardedInterstitialAd = null;
          debugPrint(
            '[RewardedInterstitialAd] load failed unit=${AdConfig.rewardedInterstitialAdUnitId} ' 
            'error=$error',
          );
          final delay = error.code == 1
              ? const Duration(seconds: 35)
              : Duration(seconds: (8 * _loadAttempts).clamp(10, 45));
          AdLoadScheduler.instance.deferNextSlot(delay);
          if (_loadAttempts < AdsVariable.maxAdLoadAttempts) {
            Future.delayed(delay, preload);
          }
        },
      ),
    );
  }

  /// Shows a loaded video ad, or loads one and shows it when ready.
  /// Completes after the ad closes, fails to show, or the load timeout is reached.
  Future<void> show({VoidCallback? onDismissed}) async {
    if (_showCompleter != null) {
      await _showCompleter!.future;
      onDismissed?.call();
      return;
    }

    final completer = Completer<void>();
    _showCompleter = completer;

    void complete() {
      if (!completer.isCompleted) completer.complete();
      _showCompleter = null;
      onDismissed?.call();
    }

    if (!shouldShowAdsToUser) {
      complete();
      return completer.future;
    }

    if (isAdReady) {
      _presentAd(complete);
      return completer.future;
    }

    preload();

    final deadline = DateTime.now().add(AdsVariable.adLoadTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (isAdReady) {
        _presentAd(complete);
        return completer.future;
      }
      if (!_isLoading && _loadAttempts >= AdsVariable.maxAdLoadAttempts) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }

    debugPrint('[VideoInterstitialAd] show skipped — ad not ready in time');
    complete();
    return completer.future;
  }

  void _presentAd(void Function() complete) {
    final interstitialAd = _rewardedInterstitialAd;
    if (interstitialAd != null) {
      _rewardedInterstitialAd = null;
      _showRewardedInterstitialAd(interstitialAd, complete);
      return;
    }

    final rewardedAd = _rewardedAd;
    if (rewardedAd != null) {
      _rewardedAd = null;
      _showRewardedAd(rewardedAd, complete);
      return;
    }

    complete();
    preload();
  }

  void _showRewardedInterstitialAd(
    RewardedInterstitialAd ad,
    void Function() complete,
  ) {
    AppOpenAdManager.instance.suppressFor(const Duration(seconds: 20));

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[VideoInterstitialAd] showed');
        AdsVariable.isAdShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        AppOpenAdManager.instance.suppressFor(const Duration(seconds: 10));
        AdsVariable.isAdShowing = false;
        AdsVariable.lastAdShownTime = DateTime.now();
        ad.dispose();
        preload();
        complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[VideoInterstitialAd] show failed: $error');
        AppOpenAdManager.instance.suppressFor(const Duration(seconds: 10));
        AdsVariable.isAdShowing = false;
        ad.dispose();
        preload();
        complete();
      },
    );

    ad.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint(
          '[VideoInterstitialAd] reward earned: ${reward.amount} ${reward.type}',
        );
      },
    );
  }

  void _showRewardedAd(RewardedAd ad, void Function() complete) {
    AppOpenAdManager.instance.suppressFor(const Duration(seconds: 20));

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[VideoRewardedAd] showed');
        AdsVariable.isAdShowing = true;
      },
      onAdDismissedFullScreenContent: (ad) {
        AppOpenAdManager.instance.suppressFor(const Duration(seconds: 10));
        AdsVariable.isAdShowing = false;
        AdsVariable.lastAdShownTime = DateTime.now();
        ad.dispose();
        preload();
        complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[VideoRewardedAd] show failed: $error');
        AppOpenAdManager.instance.suppressFor(const Duration(seconds: 10));
        AdsVariable.isAdShowing = false;
        ad.dispose();
        preload();
        complete();
      },
    );

    ad.show(onUserEarnedReward: (ad, reward) {
      debugPrint(
        '[VideoRewardedAd] reward earned: ${reward.amount} ${reward.type}',
      );
    });
  }

  void dispose() {
    _rewardedInterstitialAd?.dispose();
    _rewardedAd?.dispose();
    _rewardedInterstitialAd = null;
    _rewardedAd = null;
    _isLoading = false;
    _showCompleter = null;
  }
}
