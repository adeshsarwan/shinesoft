// lib/Utility/ads_service/reward_ads_service.dart

import 'dart:io';
import 'dart:ui';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class RewardAdsService {
  static final RewardAdsService _instance = RewardAdsService._internal();
  factory RewardAdsService() => _instance;
  RewardAdsService._internal();

  // Ad Unit IDs
  static String get rewardedAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-1350781778307915/9189946842'; // Android test ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-1350781778307915/6562199292'; // iOS rewarded ID
    }
    return '';
  }

  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;
  bool _isLoading = false;

  bool get isRewardedAdReady => _isRewardedAdReady;

  // Callback for when ad is dismissed
  VoidCallback? _onAdDismissedCallback;
  // Callback for when user earns reward
  Function(RewardItem)? _onUserEarnedRewardCallback;

  Future<void> loadRewardedAd({
    VoidCallback? onAdLoaded,
    Function(String)? onAdFailedToLoad,
    VoidCallback? onAdDismissed,
    Function(RewardItem)? onUserEarnedReward,
  }) async {
    if (_isLoading || _isRewardedAdReady) return;

    _isLoading = true;
    _onAdDismissedCallback = onAdDismissed;
    _onUserEarnedRewardCallback = onUserEarnedReward;

    try {
      await RewardedAd.load(
        adUnitId: rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            print('Rewarded ad loaded successfully.');
            _rewardedAd = ad;
            _isRewardedAdReady = true;
            _isLoading = false;

            // Set up full screen content callbacks
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                print('Rewarded ad dismissed.');
                _isRewardedAdReady = false;
                ad.dispose();
                _rewardedAd = null;

                // Call the onAdDismissed callback if provided
                if (_onAdDismissedCallback != null) {
                  _onAdDismissedCallback!();
                }

                // Load a new ad for next time
                loadRewardedAd();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                print('Failed to show rewarded ad: $error');
                _isRewardedAdReady = false;
                ad.dispose();
                _rewardedAd = null;

                // Load a new ad for next time
                Future.delayed(const Duration(seconds: 30), () {
                  loadRewardedAd();
                });
              },
              onAdShowedFullScreenContent: (ad) {
                print('Rewarded ad showed.');
              },
              onAdImpression: (ad) {
                print('Rewarded ad impression recorded.');
              },
            );

            if (onAdLoaded != null) onAdLoaded();
          },
          onAdFailedToLoad: (error) {
            print('Rewarded ad failed to load: $error');
            _isRewardedAdReady = false;
            _isLoading = false;
            _rewardedAd = null;

            if (onAdFailedToLoad != null) onAdFailedToLoad(error.message);

            // Retry after 30 seconds
            Future.delayed(const Duration(seconds: 30), () {
              loadRewardedAd();
            });
          },
        ),
      );
    } catch (e) {
      print('Error loading rewarded ad: $e');
      _isLoading = false;
      _isRewardedAdReady = false;
    }
  }

  void showRewardedAd({
    VoidCallback? onAdDismissed,
    Function(RewardItem)? onUserEarnedReward,
  }) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      // Update callbacks
      _onAdDismissedCallback = onAdDismissed;
      _onUserEarnedRewardCallback = onUserEarnedReward;

      // Show the ad
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          print('User earned reward: ${reward.amount} ${reward.type}');

          // Call the user earned reward callback if provided
          if (_onUserEarnedRewardCallback != null) {
            _onUserEarnedRewardCallback!(reward);
          }
        },
      );
      _isRewardedAdReady = false;
    } else {
      print('Rewarded ad is not ready yet.');

      // If ad is not ready, load one and show it when ready
      loadRewardedAd(
        onAdLoaded: () {
          if (_rewardedAd != null) {
            // Update callbacks
            _onAdDismissedCallback = onAdDismissed;
            _onUserEarnedRewardCallback = onUserEarnedReward;

            _rewardedAd!.show(
              onUserEarnedReward: (ad, reward) {
                print('User earned reward: ${reward.amount} ${reward.type}');

                // Call the user earned reward callback if provided
                if (_onUserEarnedRewardCallback != null) {
                  _onUserEarnedRewardCallback!(reward);
                }
              },
            );
            _isRewardedAdReady = false;
          }
        },
        onAdFailedToLoad: (error) {
          print('Failed to load rewarded ad for showing: $error');
        },
      );
    }
  }

  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isRewardedAdReady = false;
    _isLoading = false;
    _onAdDismissedCallback = null;
    _onUserEarnedRewardCallback = null;
  }
}