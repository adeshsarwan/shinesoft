import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';
import 'package:iptv_demo/ads/ad_id_service.dart';

/// Handles ad loading and playback using the Google IMA SDK.
///
/// The content player stays in media_kit; this layer only owns the ad break.
class ImaAdManager {
  ImaAdManager();

  AdsLoader? _loader;
  AdsManager? _manager;
  bool _disposed = false;
  bool _adBreakFinished = false;

  String _appendAdIdentifierParameters(String url) {
    if (url.isEmpty) return url;
    try {
      final uri = Uri.parse(url);
      final queryParams = Map<String, String>.from(uri.queryParameters);

      queryParams['rdid'] = AdIdService.advertisingId;
      queryParams['idtype'] = 'adid';
      queryParams['is_lat'] = AdIdService.isLimitAdTracking ? '1' : '0';

      if (queryParams['correlator'] == null ||
          queryParams['correlator']!.isEmpty) {
        queryParams['correlator'] =
            DateTime.now().millisecondsSinceEpoch.toString();
      }

      final cleanUri = uri.replace(queryParameters: queryParams);
      debugPrint('[ImaAdManager] Base VAST tag: $url');
      debugPrint('[ImaAdManager] Final VAST tag: $cleanUri');
      return cleanUri.toString();
    } catch (e) {
      debugPrint('[ImaAdManager] Error parsing ad URL: $e');
      return url;
    }
  }

  Future<void> playAd({
    required AdDisplayContainer container,
    required String adTagUrl,
    List<String> fallbackAdTagUrls = const [],
    required ValueChanged<bool> onStateChanged,
    required ValueChanged<String> onError,
  }) async {
    if (_disposed) return;

    final tagUrls = <String>[
      adTagUrl,
      ...fallbackAdTagUrls.where((url) => url.isNotEmpty && url != adTagUrl),
    ];

    for (var i = 0; i < tagUrls.length; i++) {
      if (_disposed) return;

      if (i > 0) {
        debugPrint(
          '[ImaAdManager] Retrying with fallback VAST tag ($i/${tagUrls.length - 1})',
        );
      }

      final loaded = await _requestSingleAd(
        container: container,
        adTagUrl: tagUrls[i],
        onStateChanged: onStateChanged,
        onError: onError,
      );

      if (loaded) return;

      await disposeCurrentAd();
    }

    debugPrint('[ImaAdManager] No ads available from VAST tag(s)');
    onError('No ads available');
    onStateChanged(false);
  }

  Future<bool> _requestSingleAd({
    required AdDisplayContainer container,
    required String adTagUrl,
    required ValueChanged<bool> onStateChanged,
    required ValueChanged<String> onError,
  }) async {
    await disposeCurrentAd();
    _adBreakFinished = false;

    final loadResult = Completer<bool>();

    final imaSettings = ImaSettings();
    await imaSettings.setDebugMode(kDebugMode);

    final loader = AdsLoader(
      container: container,
      onAdsLoaded: (data) async {
        if (_disposed) return;

        _manager = data.manager;

        await data.manager.setAdsManagerDelegate(
          AdsManagerDelegate(
            onAdEvent: (event) async {
              switch (event.type) {
                case AdEventType.loaded:
                  if (!_disposed) {
                    if (!loadResult.isCompleted) {
                      loadResult.complete(true);
                    }
                    onStateChanged(true);
                    await data.manager.start();
                  }
                  break;
                case AdEventType.contentPauseRequested:
                case AdEventType.started:
                case AdEventType.adBreakStarted:
                  if (!_disposed) {
                    onStateChanged(true);
                  }
                  break;
                case AdEventType.complete:
                case AdEventType.allAdsCompleted:
                case AdEventType.adBreakEnded:
                case AdEventType.contentResumeRequested:
                  if (_disposed || _adBreakFinished) break;
                  _adBreakFinished = true;
                  await disposeCurrentAd();
                  if (!_disposed) {
                    onStateChanged(false);
                  }
                  break;
                default:
                  break;
              }
            },
            onAdErrorEvent: (errorEvent) async {
              if (_disposed || _adBreakFinished) return;
              final message =
                  errorEvent.error.message ?? 'IMA ad failed to play';
              debugPrint('[ImaAdManager] Ad error: $message');
              if (!loadResult.isCompleted) {
                loadResult.complete(false);
                await disposeCurrentAd();
                return;
              }
              _adBreakFinished = true;
              await disposeCurrentAd();
              if (!_disposed) {
                onError(message);
                onStateChanged(false);
              }
            },
          ),
        );

        await data.manager.init(
          settings: AdsRenderingSettings(enablePreloading: true),
        );
      },
      onAdsLoadError: (data) async {
        if (_disposed) return;
        final message = data.error.message ?? 'IMA ad failed to load';
        debugPrint('[ImaAdManager] Ad load error: $message');
        if (!loadResult.isCompleted) {
          loadResult.complete(false);
        }
        await disposeCurrentAd();
      },
      settings: imaSettings,
    );

    _loader = loader;

    final String finalAdTagUrl = _appendAdIdentifierParameters(adTagUrl);
    await loader.requestAds(
      AdsRequest(
        adTagUrl: finalAdTagUrl,
        adWillAutoPlay: true,
        adWillPlayMuted: false,
      ),
    );

    return loadResult.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        debugPrint('[ImaAdManager] Ad load timed out');
        return false;
      },
    );
  }

  Future<void> disposeCurrentAd() async {
    try {
      await _manager?.destroy();
    } catch (e) {
      debugPrint('[ImaAdManager] destroy error: $e');
    }
    try {
      await _loader?.contentComplete();
    } catch (e) {
      debugPrint('[ImaAdManager] contentComplete error: $e');
    }

    _manager = null;
    _loader = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await disposeCurrentAd();
  }
}
