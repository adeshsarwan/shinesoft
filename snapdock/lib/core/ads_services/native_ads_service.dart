import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdsService {
  static final NativeAdsService _instance = NativeAdsService._internal();
  factory NativeAdsService() => _instance;
  NativeAdsService._internal();

  // Note: this service currently renders a medium-rectangle BannerAd,
  // not a true NativeAd widget.
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1350781778307915/7880928122';
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1350781778307915/8969137688'; // iOS native ID
    }
    return '';
  }

  // Ad Unit IDs used by the current medium-rectangle BannerAd implementation.
  static String get mediumRectangleAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1350781778307915/7880928122'; // Android test ID (same as banner, works for medium rectangle)
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1350781778307915/4347366399'; // iOS banner ID
    }
    return '';
  }

  BannerAd? _mediumRectangleAd;
  bool _isAdLoaded = false;
  bool _isLoading = false;

  BannerAd? get mediumRectangleAd => _mediumRectangleAd;
  bool get isAdLoaded => _isAdLoaded;

  Future<void> loadMediumRectangleAd({
    Function? onAdLoaded,
    Function(String)? onAdFailedToLoad,
  }) async {
    if (_isLoading || _isAdLoaded) return;

    _isLoading = true;

    try {
      _mediumRectangleAd = BannerAd(
        adUnitId: mediumRectangleAdUnitId,
        size: AdSize.mediumRectangle,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            print('Medium rectangle ad loaded successfully.');
            _isAdLoaded = true;
            _isLoading = false;
            if (onAdLoaded != null) onAdLoaded();
          },
          onAdFailedToLoad: (ad, error) {
            print('Medium rectangle ad failed to load: $error');
            _isAdLoaded = false;
            _isLoading = false;
            ad.dispose();
            _mediumRectangleAd = null;
            if (onAdFailedToLoad != null) onAdFailedToLoad(error.message);
            
            // Retry after 30 seconds
            Future.delayed(const Duration(seconds: 30), () {
              loadMediumRectangleAd(
                onAdLoaded: onAdLoaded,
                onAdFailedToLoad: onAdFailedToLoad,
              );
            });
          },
          onAdOpened: (ad) => print('Medium rectangle ad opened.'),
          onAdClosed: (ad) => print('Medium rectangle ad closed.'),
          onAdImpression: (ad) => print('Medium rectangle ad impression recorded.'),
        ),
      );

      await _mediumRectangleAd!.load();
      return;
    } catch (e) {
      print('Error loading medium rectangle ad: $e');
      _isLoading = false;
      _isAdLoaded = false;
      if (onAdFailedToLoad != null) onAdFailedToLoad(e.toString());
    }
  }

  void disposeAd() {
    _mediumRectangleAd?.dispose();
    _mediumRectangleAd = null;
    _isAdLoaded = false;
    _isLoading = false;
  }
}
