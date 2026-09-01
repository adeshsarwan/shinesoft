import 'dart:io';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  static final InterstitialAdService _instance = InterstitialAdService._internal();
  factory InterstitialAdService() => _instance;
  InterstitialAdService._internal();

  // Ad Unit IDs
  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1350781778307915/6428245653'; // Android test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1350781778307915/7666696709'; // iOS interstitial ID
    }
    return '';
  }

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  bool _isLoading = false;

  bool get isInterstitialAdReady => _isInterstitialAdReady;
  
  // Callback for when ad is dismissed
  VoidCallback? _onAdDismissedCallback;

  Future<void> loadInterstitialAd({
    VoidCallback? onAdLoaded,
    Function(String)? onAdFailedToLoad,
    VoidCallback? onAdDismissed,
  }) async {
    if (_isLoading || _isInterstitialAdReady) return;
    
    _isLoading = true;
    _onAdDismissedCallback = onAdDismissed;

    try {
      await InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            print('Interstitial ad loaded successfully.');
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            _isLoading = false;
            
            // Set up full screen content callbacks
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('Interstitial ad dismissed.');
                _isInterstitialAdReady = false;
                ad.dispose();
                _interstitialAd = null;
                
                // Call the onAdDismissed callback if provided
                if (_onAdDismissedCallback != null) {
                  _onAdDismissedCallback!();
                }
                
                // Load a new ad for next time
                loadInterstitialAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('Failed to show interstitial ad: $error');
                _isInterstitialAdReady = false;
                ad.dispose();
                _interstitialAd = null;
                
                // Load a new ad for next time
                Future.delayed(const Duration(seconds: 30), () {
                  loadInterstitialAd();
                });
              },
              onAdShowedFullScreenContent: (ad) {
                print('Interstitial ad showed.');
              },
              onAdImpression: (ad) {
                print('Interstitial ad impression recorded.');
              },
            );
            
            if (onAdLoaded != null) onAdLoaded();
          },
          onAdFailedToLoad: (error) {
            print('Interstitial ad failed to load: $error');
            _isInterstitialAdReady = false;
            _isLoading = false;
            _interstitialAd = null;
            
            if (onAdFailedToLoad != null) onAdFailedToLoad(error.message);
            
            // Retry after 30 seconds
            Future.delayed(const Duration(seconds: 30), () {
              loadInterstitialAd();
            });
          },
        ),
      );
    } catch (e) {
      print('Error loading interstitial ad: $e');
      _isLoading = false;
      _isInterstitialAdReady = false;
    }
  }

  void showInterstitialAd() {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _isInterstitialAdReady = false;
    } else {
      print('Interstitial ad is not ready yet.');
      
      // If ad is not ready, load one and show it when ready
      loadInterstitialAd(
        onAdLoaded: () {
          if (_interstitialAd != null) {
            _interstitialAd!.show();
            _isInterstitialAdReady = false;
          }
        },
      );
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
    _isLoading = false;
  }
}