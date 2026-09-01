import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdsService {
  static final BannerAdsService _instance = BannerAdsService._internal();
  factory BannerAdsService() => _instance;
  BannerAdsService._internal();
  
  // Production Ad Unit IDs
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1350781778307915/5442273529'; // Android test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1350781778307915/4347366399'; // iOS banner ID
    }
    return '';
  }
  
  // Banner ad methods
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  
  BannerAd? get bannerAd => _bannerAd;
  bool get isBannerAdLoaded => _isBannerAdLoaded;
  
  Future<void> initializeMobileAds() async {
    await MobileAds.instance.initialize();
  }
  
  Future<BannerAd?> loadBannerAd({
    required AdSize adSize,
    Function? onAdLoaded,
    Function(String)? onAdFailedToLoad,
  }) async {
    try {
      // Dispose existing banner if any
      _bannerAd?.dispose();
      
      _bannerAd = BannerAd(
        adUnitId: bannerAdUnitId,
        request: const AdRequest(),
        size: adSize,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            _isBannerAdLoaded = true;
            if (onAdLoaded != null) onAdLoaded();
            print('Banner ad loaded successfully.');
          },
          onAdFailedToLoad: (ad, error) {
            _isBannerAdLoaded = false;
            if (onAdFailedToLoad != null) onAdFailedToLoad(error.message);
            print('Banner ad failed to load: $error');
            ad.dispose();
          },
          onAdOpened: (ad) => print('Banner ad opened.'),
          onAdClosed: (ad) => print('Banner ad closed.'),
          onAdImpression: (ad) => print('Banner ad impression recorded.'),
        ),
      );
      
      await _bannerAd!.load();
      return _bannerAd;
    } catch (e) {
      print('Error loading banner ad: $e');
      return null;
    }
  }
  
  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }
}