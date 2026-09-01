import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:iptv_demo/ads/ad_config.dart';
import 'package:iptv_demo/ads/ad_load_scheduler.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/utils/premium_access.dart';

class AppOpenAdManager with WidgetsBindingObserver {
  AppOpenAdManager._();
  static final AppOpenAdManager instance = AppOpenAdManager._();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _hasShownThisSession = false;
  bool _isLoading = false;
  bool _pendingShow = false;
  bool _showOnNextLogin = false;
  bool _showOnNextHome = false;
  int _loadAttempts = 0;
  DateTime? _loadTime;
  DateTime? _suppressUntil;

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Start loading early (e.g. splash on cold start).
  void preload() {
    if (!shouldShowAppOpenAd) return;
    _pendingShow = true;
    _loadAd();
  }

  /// Marks which screen may show the app-open ad after splash (once per app launch).
  void prepareColdStartForRoute(String route) {
    if (!shouldShowAppOpenAd) return;
    _showOnNextLogin = false;
    _showOnNextHome = false;
    if (route == '/login') {
      _showOnNextLogin = true;
    } else if (route == '/home' || route == '/tv/home') {
      _showOnNextHome = true;
    }
    preload();
  }

  /// Login screen: only after a cold start from splash — not after logout.
  void showOnLoginIfColdStart({
    Duration delay = const Duration(milliseconds: 600),
  }) {
    if (!_showOnNextLogin) return;
    _showOnNextLogin = false;
    ensureLoadedAndShow(delay: delay);
  }

  /// Home shell: only after a cold start when user was already signed in.
  void showOnHomeIfColdStart({
    Duration delay = const Duration(milliseconds: 500),
  }) {
    if (!_showOnNextHome) return;
    _showOnNextHome = false;
    ensureLoadedAndShow(delay: delay);
  }

  /// Load if needed, then show once the ad is ready (after route is visible).
  void ensureLoadedAndShow({Duration delay = const Duration(milliseconds: 400)}) {
    if (!shouldShowAppOpenAd) return;
    if (_hasShownThisSession || _isShowingAd) return;

    _pendingShow = true;
    if (_isAdAvailable) {
      Future.delayed(delay, () {
        if (_pendingShow) showAdIfAvailable();
      });
      return;
    }
    _loadAd();
  }

  void _loadAd() {
    if (!shouldShowAppOpenAd) return;
    if (_isLoading || _isAdAvailable) return;
    if (_loadAttempts >= AdsVariable.maxAdLoadAttempts) {
      debugPrint('[AppOpenAd] max load attempts reached');
      return;
    }

    _isLoading = true;
    _loadAttempts++;

    unawaited(
      AdLoadScheduler.instance.enqueue(() async {
        AppOpenAd.load(
          adUnitId: AdConfig.appOpenAdUnitId,
          request: const AdRequest(),
          adLoadCallback: AppOpenAdLoadCallback(
            onAdLoaded: (ad) {
              _isLoading = false;
              _loadAttempts = 0;
              _appOpenAd = ad;
              _loadTime = DateTime.now();
              debugPrint('[AppOpenAd] loaded');
              if (_pendingShow &&
                  !_hasShownThisSession &&
                  !_isShowingAd &&
                  !_isSuppressed) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Future.delayed(
                    const Duration(milliseconds: 300),
                    showAdIfAvailable,
                  );
                });
              }
            },
            onAdFailedToLoad: (error) {
              _isLoading = false;
              _appOpenAd = null;
              debugPrint('[AppOpenAd] load failed: $error');
              final delay = error.code == 1
                  ? const Duration(seconds: 35)
                  : const Duration(seconds: 12);
              AdLoadScheduler.instance.deferNextSlot(delay);
              if (_pendingShow &&
                  _loadAttempts < AdsVariable.maxAdLoadAttempts) {
                Future.delayed(delay, _loadAd);
              }
            },
          ),
        );
      }),
    );
  }

  bool get _isAdAvailable {
    return _appOpenAd != null &&
        _loadTime != null &&
        DateTime.now().difference(_loadTime!) < const Duration(hours: 4);
  }

  bool get _isSuppressed =>
      _suppressUntil != null && DateTime.now().isBefore(_suppressUntil!);

  void suppressFor(Duration duration) {
    final candidate = DateTime.now().add(duration);
    if (_suppressUntil == null || candidate.isAfter(_suppressUntil!)) {
      _suppressUntil = candidate;
    }
  }

  void showAdIfAvailable() {
    if (!shouldShowAppOpenAd) return;
    if (_hasShownThisSession || _isShowingAd || _isSuppressed) return;

    if (!_isAdAvailable) {
      _pendingShow = true;
      _loadAd();
      return;
    }

    _pendingShow = false;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AppOpenAd] showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        _hasShownThisSession = true;
        ad.dispose();
        _appOpenAd = null;
        _loadTime = null;
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AppOpenAd] show failed: $error');
        _isShowingAd = false;
        _hasShownThisSession = false;
        ad.dispose();
        _appOpenAd = null;
        _loadTime = null;
        _loadAd();
      },
    );

    _isShowingAd = true;
    _hasShownThisSession = true;
    _appOpenAd!.show();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only show on cold start / first launch — not every time the app resumes.
    if (state == AppLifecycleState.resumed) {
      return;
    }
  }

  void resetSession() {
    _hasShownThisSession = false;
    _pendingShow = false;
    _showOnNextLogin = false;
    _showOnNextHome = false;
    _isShowingAd = false;
    _loadAttempts = 0;
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _loadTime = null;
    _isLoading = false;
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appOpenAd?.dispose();
  }
}
