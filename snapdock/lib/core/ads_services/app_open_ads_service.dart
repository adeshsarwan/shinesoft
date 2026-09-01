import 'dart:async';
import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/state/premium_state.dart';

class AppOpenAdsService {
  // Singleton instance
  static final AppOpenAdsService _instance = AppOpenAdsService._internal();
  factory AppOpenAdsService() => _instance;
  AppOpenAdsService._internal();

  // Ad Unit IDs
  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1350781778307915/7741327328'; // Android test ID for App Open
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1350781778307915/8122692970'; // iOS app-open ID
    }
    return '';
  }

  // SharedPreferences keys
  static const String _prefOpenCount = 'app_open_count';
  static const String _prefLastAdShown = 'last_ad_shown_time';
  static const String _prefFirstOpenDate = 'first_open_date';
  static const String _prefsName = 'app_open_ads_prefs';

  // Configuration
  static const int _initialAdShows = 3; // Show ad first 3 opens
  static const int _cooldownHours = 4; // Cooldown between ads
  static const int _maxAdsPerDay = 2; // Max ads per day for regular users

  AppOpenAd? _appOpenAd;
  bool _isAdLoaded = false;
  DateTime? _appOpenTime;
  bool _isShowingAd = false;
  Completer<void>? _adDismissedCompleter;
  Completer<bool>? _adLoadCompleter;

  // Initialize Mobile Ads
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    print('AppOpenAdsService initialized');
  }

  // Load App Open Ad
  Future<bool> loadAd() async {
    if (_isAdLoaded && _appOpenAd != null) {
      print('✅ App Open Ad already loaded');
      return true;
    }

    // If already loading, wait for that to complete
    if (_adLoadCompleter != null) {
      print('⏳ App Open Ad already loading, waiting...');
      return await _adLoadCompleter!.future;
    }

    _adLoadCompleter = Completer<bool>();
    print('🔄 Starting to load App Open Ad with ID: $appOpenAdUnitId');

    try {
      await AppOpenAd.load(
        adUnitId: appOpenAdUnitId,
        request: const AdRequest(),
        // orientation: AppOpenAd.orientationPortrait,
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isAdLoaded = true;
            _appOpenTime = DateTime.now();
            print('✅ App Open Ad loaded successfully!');
            
            // Set full screen content callbacks
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (ad) {
                _isShowingAd = true;
                print('✅ App Open Ad showed full screen content');
              },
              onAdDismissedFullScreenContent: (ad) {
                _isShowingAd = false;
                print('✅ App Open Ad dismissed full screen content');
                disposeAd();
                _adDismissedCompleter?.complete();
                _adDismissedCompleter = null;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                _isShowingAd = false;
                print('❌ App Open Ad failed to show: $error');
                disposeAd();
                _adDismissedCompleter?.complete();
                _adDismissedCompleter = null;
              },
              onAdImpression: (ad) {
                print('✅ App Open Ad impression recorded');
              },
            );
            _adLoadCompleter?.complete(true);
            _adLoadCompleter = null;
          },
          onAdFailedToLoad: (error) {
            _isAdLoaded = false;
            print('❌ App Open Ad failed to load:');
            print('   Error Code: ${error.code}');
            print('   Error Message: ${error.message}');
            print('   Error Domain: ${error.domain}');
            print('   Response Info: ${error.responseInfo}');
            _adLoadCompleter?.complete(false);
            _adLoadCompleter = null;
          },
        ),
      );
      return await _adLoadCompleter!.future;
    } catch (e, stackTrace) {
      print('❌ Exception loading App Open Ad: $e');
      print('Stack trace: $stackTrace');
      _adLoadCompleter?.complete(false);
      _adLoadCompleter = null;
      return false;
    }
  }

  // Show Ad if available and conditions are met
  // Returns a Future that completes when ad is dismissed or fails
  Future<bool> showAdIfAvailable({bool forceShow = false}) async {
    // Never show app-open ads to premium users.
    final isPremiumSaved =
        (await SharedPreferences.getInstance()).getBool(PrefsConstants.isPremiumUser) ??
            false;
    if (PremiumState.isPremium.value || isPremiumSaved) {
      print('⚠️ Premium user detected - skipping App Open Ad');
      return false;
    }

    // If ad is already showing, wait for it to complete
    if (_isShowingAd && _adDismissedCompleter != null) {
      print('⏳ App Open Ad already showing, waiting for dismissal...');
      await _adDismissedCompleter!.future;
      return true;
    }

    if (!_isAdLoaded || _appOpenAd == null) {
      print('❌ App Open Ad not loaded - cannot show');
      print('   isAdLoaded: $_isAdLoaded');
      print('   _appOpenAd is null: ${_appOpenAd == null}');
      return false;
    }

    if (!forceShow) {
      final shouldShow = await _shouldShowAd();
      if (!shouldShow) {
        print('⚠️ Ad not shown based on frequency rules');
        return false;
      }
    } else {
      print('🔓 Force show enabled - bypassing frequency rules');
    }

    // Create completer to wait for ad dismissal.
    // Store a local reference so callbacks can safely null out
    // `_adDismissedCompleter` without breaking this await chain.
    _adDismissedCompleter = Completer<void>();
    final currentDismissedCompleter = _adDismissedCompleter!;

    try {
      print('🎬 Calling _appOpenAd.show()...');
      await _appOpenAd!.show();
      await _recordAdShown(); // Record after successful show
      print('✅ App Open Ad show() called successfully, waiting for dismissal...');
      // Wait for ad to be dismissed
      await currentDismissedCompleter.future;
      print('✅ App Open Ad dismissal completed');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error showing App Open Ad: $e');
      print('Stack trace: $stackTrace');
      disposeAd();
      _adDismissedCompleter?.complete();
      _adDismissedCompleter = null;
      return false;
    }
  }

  // Check if ad should be shown based on frequency rules
  Future<bool> _shouldShowAd() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get open count
    int openCount = prefs.getInt(_prefOpenCount) ?? 0;
    openCount++;
    await prefs.setInt(_prefOpenCount, openCount);

    // First 3 opens after install
    if (openCount <= _initialAdShows) {
      print('Showing ad for open #$openCount (first $_initialAdShows opens)');
      return true;
    }

    // Get first open date
    final firstOpenTimestamp = prefs.getInt(_prefFirstOpenDate);
    if (firstOpenTimestamp == null) {
      await prefs.setInt(_prefFirstOpenDate, DateTime.now().millisecondsSinceEpoch);
    }

    // Check cooldown
    final lastShownTimestamp = prefs.getInt(_prefLastAdShown) ?? 0;
    final now = DateTime.now();
    final lastShownTime = DateTime.fromMillisecondsSinceEpoch(lastShownTimestamp);
    
    final hoursSinceLastAd = now.difference(lastShownTime).inHours;
    
    if (hoursSinceLastAd < _cooldownHours) {
      print('Ad cooldown active: ${_cooldownHours - hoursSinceLastAd} hours remaining');
      return false;
    }

    // Check max ads per day
    final adsToday = await _getAdsShownToday();
    if (adsToday >= _maxAdsPerDay) {
      print('Max ads per day ($_maxAdsPerDay) reached');
      return false;
    }

    return true;
  }

  // Get number of ads shown today
  Future<int> _getAdsShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    final lastShownTimestamp = prefs.getInt(_prefLastAdShown) ?? 0;
    final lastShownDate = DateTime.fromMillisecondsSinceEpoch(lastShownTimestamp);
    final today = DateTime.now();
    
    // If last ad was shown on a different day, reset count
    if (lastShownDate.year != today.year || 
        lastShownDate.month != today.month || 
        lastShownDate.day != today.day) {
      return 0;
    }
    
    // In a real app, you'd track daily count separately
    // For simplicity, we're using this approach
    return 1; // Assuming 1 ad shown today if timestamp is today
  }

  // Record when ad was shown
  Future<void> _recordAdShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _prefLastAdShown, 
      DateTime.now().millisecondsSinceEpoch
    );
  }

  // Preload ad for next use
  Future<bool> preloadAd() async {
    final isPremiumSaved =
        (await SharedPreferences.getInstance()).getBool(PrefsConstants.isPremiumUser) ??
            false;
    if (PremiumState.isPremium.value || isPremiumSaved) {
      print('⚠️ Premium user detected - skipping App Open Ad preload');
      return false;
    }

    if (!_isAdLoaded) {
      return await loadAd();
    }
    return true;
  }

  // Dispose ad
  void disposeAd() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isAdLoaded = false;
    _isShowingAd = false;
    if (_adDismissedCompleter != null && !_adDismissedCompleter!.isCompleted) {
      _adDismissedCompleter!.complete();
      _adDismissedCompleter = null;
    }
    if (_adLoadCompleter != null && !_adLoadCompleter!.isCompleted) {
      _adLoadCompleter!.complete(false);
      _adLoadCompleter = null;
    }
  }

  // Check if ad is loaded
  bool get isAdLoaded => _isAdLoaded;

  // Reset tracking (for testing or user preferences)
  Future<void> resetTracking() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefOpenCount);
    await prefs.remove(_prefLastAdShown);
    await prefs.remove(_prefFirstOpenDate);
    print('App Open Ads tracking reset');
  }

  // Get statistics (for debugging)
  Future<Map<String, dynamic>> getStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'openCount': prefs.getInt(_prefOpenCount) ?? 0,
      'lastAdShown': prefs.getInt(_prefLastAdShown) ?? 0,
      'firstOpenDate': prefs.getInt(_prefFirstOpenDate) ?? 0,
      'isAdLoaded': _isAdLoaded,
      'isShowingAd': _isShowingAd,
    };
  }
}