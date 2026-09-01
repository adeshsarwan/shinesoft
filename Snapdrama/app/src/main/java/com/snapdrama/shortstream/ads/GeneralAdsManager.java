package com.snapdrama.shortstream.ads;

import android.app.Activity;
import android.os.Bundle;
import android.util.Log;

import androidx.annotation.NonNull;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.OnPaidEventListener;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.firebase.analytics.FirebaseAnalytics;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;

import java.util.List;

public class GeneralAdsManager {

    private static InterstitialAd mInterstitialAd;
    private static boolean isLoading = false;
    private static final String TAG = "GeneralAdsManager";

    public static int adsViewInterAds = 0;
    public static boolean isFailArrayId = false;
    public static String interAdsType = "";

    /**
     * Loads an interstitial ad if one is not already loaded or loading.
     *
     * @param activity The activity context.
     */
    public static void loadInterstitialAd(Activity activity) {
        if (isLoading || mInterstitialAd != null) return;
        if (PremiumPlanManager.shouldSkipAfterLoginAd(activity)) return;

        InterAdsId(ControlPreference.get_InterList_Ids_List());
        if (!isFailArrayId) {
            return;
        }
        isLoading = true;
        AdRequest adRequest = new AdRequest.Builder().build();

        InterstitialAd.load(activity, interAdsType, adRequest,
                new InterstitialAdLoadCallback() {
                    @Override
                    public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {
                        mInterstitialAd = interstitialAd;
                        isLoading = false;
                        FirebaseAnalytics firebaseAnalytics;
                        firebaseAnalytics = FirebaseAnalytics.getInstance(activity);
                        mInterstitialAd.setOnPaidEventListener(new OnPaidEventListener() {
                            @Override
                            public void onPaidEvent(AdValue adValue) {
                                double revenue = adValue.getValueMicros() / 1_000_000.0;
                                String currency = adValue.getCurrencyCode();
                                Bundle adRevenueParams = new Bundle();
                                adRevenueParams.putString(FirebaseAnalytics.Param.AD_PLATFORM, "Google Ad Manager");
                                adRevenueParams.putString(FirebaseAnalytics.Param.CURRENCY, currency);
                                adRevenueParams.putDouble(FirebaseAnalytics.Param.VALUE, revenue);
                                firebaseAnalytics.logEvent(FirebaseAnalytics.Event.AD_IMPRESSION, adRevenueParams);
                            }
                        });
//                        Log.d(TAG, "Ad Loaded successfully");
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                        mInterstitialAd = null;
                        isLoading = false;
//                        Log.d(TAG, "Ad failed to load: " + loadAdError.getMessage());
                    }
                });
    }


    public static void InterAdsId(List<String> list) {
        try {
            if (list != null && !list.isEmpty() && adsViewInterAds < list.size()) {
                isFailArrayId = true;
                interAdsType = list.get(adsViewInterAds);
//                android.util.Log.d("SplashNativeAd", "Requesting Native Ad with ID at position " + adsViewInterAds + ": " + interAdsType);
                adsViewInterAds = adsViewInterAds + 1;
            } else {
//                android.util.Log.d("SplashNativeAd", "No more Native Ad IDs to request or list is empty. Resetting index.");
                isFailArrayId = false;
                adsViewInterAds = 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            isFailArrayId = false;
            adsViewInterAds = 0;
        }
    }

    public static void showInterstitialAdWithCounter(Activity activity, Runnable onAdClosed) {
        if (PremiumPlanManager.shouldSkipAfterLoginAd(activity)) {
            if (onAdClosed != null) onAdClosed.run();
            return;
        }

        int threshold = ControlPreference.getInterBottomAdsCount(); // Firebase: after how many clicks to show
        if (threshold <= 0) {
            onAdClosed.run();
            return;
        }

        ControlPreference.incrementInterBottomAdsClickCount();
        int currentCount = ControlPreference.getInterBottomAdsClickCount();
        Log.d(TAG, "showInterstitialAdWithCounter: count=" + currentCount + " threshold=" + threshold);

        if (currentCount >= threshold) {
            if (mInterstitialAd != null) {
                mInterstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                    @Override
                    public void onAdDismissedFullScreenContent() {
                        mInterstitialAd = null;
                        ControlPreference.resetInterBottomAdsClickCount();
                        loadInterstitialAd(activity);
                        if (onAdClosed != null) onAdClosed.run();
                    }

                    @Override
                    public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                        mInterstitialAd = null;
                        loadInterstitialAd(activity);
                        if (onAdClosed != null) onAdClosed.run();
                    }

                    @Override
                    public void onAdShowedFullScreenContent() {
                        mInterstitialAd = null;
                    }
                });
                mInterstitialAd.show(activity);
            } else {
                // Ad was supposed to show but not loaded
                loadInterstitialAd(activity);
                if (onAdClosed != null) onAdClosed.run();
            }
        } else {
            // Threshold not reached
            if (onAdClosed != null) onAdClosed.run();
            // Preload for next time if needed
            if (mInterstitialAd == null) {
                loadInterstitialAd(activity);
            }
        }
    }

    /**
     * Always attempt to show an interstitial, then run {@code onAdClosed}
     * (used after Google sign-in / Skip before opening Home).
     */
    public static void showInterstitialAdThen(Activity activity, Runnable onAdClosed) {
        if (activity == null || activity.isFinishing()) {
            if (onAdClosed != null) onAdClosed.run();
            return;
        }
        if (PremiumPlanManager.shouldSkipAfterLoginAd(activity)) {
            if (onAdClosed != null) onAdClosed.run();
            return;
        }

        Runnable proceed = () -> {
            if (onAdClosed != null) onAdClosed.run();
        };

        if (mInterstitialAd != null) {
            showLoadedInterstitial(activity, proceed);
            return;
        }

        if (isLoading) {
            proceed.run();
            return;
        }

        InterAdsId(ControlPreference.get_InterList_Ids_List());
        if (!isFailArrayId) {
            proceed.run();
            return;
        }

        isLoading = true;
        AdRequest adRequest = new AdRequest.Builder().build();
        InterstitialAd.load(activity, interAdsType, adRequest,
                new InterstitialAdLoadCallback() {
                    @Override
                    public void onAdLoaded(@NonNull InterstitialAd interstitialAd) {
                        mInterstitialAd = interstitialAd;
                        isLoading = false;
                        if (activity.isFinishing()) {
                            proceed.run();
                            return;
                        }
                        showLoadedInterstitial(activity, proceed);
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                        mInterstitialAd = null;
                        isLoading = false;
                        proceed.run();
                    }
                });
    }

    private static void showLoadedInterstitial(Activity activity, Runnable onAdClosed) {
        if (mInterstitialAd == null || activity.isFinishing()) {
            if (onAdClosed != null) onAdClosed.run();
            return;
        }

        mInterstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
            @Override
            public void onAdDismissedFullScreenContent() {
                mInterstitialAd = null;
                loadInterstitialAd(activity);
                if (onAdClosed != null) onAdClosed.run();
            }

            @Override
            public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                mInterstitialAd = null;
                loadInterstitialAd(activity);
                if (onAdClosed != null) onAdClosed.run();
            }

            @Override
            public void onAdShowedFullScreenContent() {
                // Keep reference until dismiss; cleared in dismiss/fail
            }
        });
        mInterstitialAd.show(activity);
    }
}
