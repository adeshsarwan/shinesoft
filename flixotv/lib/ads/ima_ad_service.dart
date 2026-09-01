import 'package:flutter/foundation.dart';
import 'package:iptv_demo/ima/ima_ad_manager.dart';
import 'package:iptv_demo/ima/ima_controller.dart';

/// IMA-backed ad service used by mobile and TV player screens.
class ImaAdService {
  ImaAdService({ImaAdManager? adManager}) : _adManager = adManager ?? ImaAdManager();

  final ImaAdManager _adManager;
  ImaController? _controller;

  ImaController get controller => _controller ??= ImaController(adManager: _adManager);

  Future<void> playBreak({
    required String adTagUrl,
    List<String> fallbackAdTagUrls = const [],
    required ValueChanged<bool> onStateChanged,
    required ValueChanged<String> onError,
  }) async {
    await controller.playAd(
      adTagUrl: adTagUrl,
      fallbackAdTagUrls: fallbackAdTagUrls,
      onStateChanged: onStateChanged,
      onError: onError,
      onAdFinished: () => onStateChanged(false),
    );
  }

  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
