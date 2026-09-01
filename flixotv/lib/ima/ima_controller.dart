import 'dart:async';

import 'package:flutter/material.dart';
import 'package:interactive_media_ads/interactive_media_ads.dart';

import 'ima_ad_manager.dart';

/// Simple controller that coordinates the ad container lifecycle.
class ImaController extends ChangeNotifier {
  ImaController({required this.adManager});

  final ImaAdManager adManager;
  AdDisplayContainer? _container;
  Completer<AdDisplayContainer>? _containerCompleter;
  bool _isAdPlaying = false;
  bool _isLoadingAd = false;
  String? _errorMessage;

  bool get isAdPlaying => _isAdPlaying;
  bool get isLoadingAd => _isLoadingAd;
  String? get errorMessage => _errorMessage;
  AdDisplayContainer? get container => _container;

  void setContainer(AdDisplayContainer container) {
    _container = container;
    if (_containerCompleter != null && !_containerCompleter!.isCompleted) {
      _containerCompleter!.complete(container);
    }
    _containerCompleter = null;
    notifyListeners();
  }

  Future<AdDisplayContainer> _waitForContainer() async {
    if (_container != null) return _container!;
    final completer = Completer<AdDisplayContainer>();
    _containerCompleter = completer;
    return completer.future;
  }

  Future<void> playAd({
    required String adTagUrl,
    List<String> fallbackAdTagUrls = const [],
    required ValueChanged<bool> onStateChanged,
    required ValueChanged<String> onError,
    required VoidCallback onAdFinished,
  }) async {
    final container = await _waitForContainer();
    final completer = Completer<void>();

    _errorMessage = null;
    _isLoadingAd = true;
    _isAdPlaying = false;
    notifyListeners();

    try {
      await adManager.playAd(
        container: container,
        adTagUrl: adTagUrl,
        fallbackAdTagUrls: fallbackAdTagUrls,
        onStateChanged: (playing) {
          _isLoadingAd = false;
          _isAdPlaying = playing;
          onStateChanged(playing);
          notifyListeners();
          if (!playing && !completer.isCompleted) {
            completer.complete();
            onAdFinished();
          }
        },
        onError: (message) {
          _isLoadingAd = false;
          _isAdPlaying = false;
          _errorMessage = message;
          onError(message);
          notifyListeners();
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      );
    } catch (e) {
      _isLoadingAd = false;
      _isAdPlaying = false;
      _errorMessage = e.toString();
      onError(e.toString());
      notifyListeners();
      if (!completer.isCompleted) {
        completer.complete();
      }
    }

    await completer.future;
  }

  Future<void> disposeAd() async {
    await adManager.disposeCurrentAd();
    _isLoadingAd = false;
    _isAdPlaying = false;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await adManager.dispose();
    super.dispose();
  }
}
