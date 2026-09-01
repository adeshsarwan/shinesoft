package com.snapdrama.shortstream.ads.adsMenu.Splash;

import android.app.Activity;
import android.os.Bundle;

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
import com.snapdrama.shortstream.activity.main.base.BaseActivity;
import com.snapdrama.shortstream.ads.FirebaseEventManager;
import com.snapdrama.shortstream.ads.PremiumPlanManager;

import java.util.List;

/**
 * Splash interstitial: preload with alternate fallback (id1 fail → id2), then show when ready.
 */
public class SplashInterMange {
    public static int adsViewInterAds = 0;
    public static boolean isFailArrayId = false;
    public static String interAdsType = "";

    private static InterstitialAd interstitialAd;
    private static boolean isLoading = false;
    private static boolean showWhenReady = false;
    private static List<String> pendingIds;
    private static Long interSplashTime;

    public interface OnCompleteAds {
        void onCompleteAds(boolean shown);
    }

    private static OnCompleteAds onCompleteAds;

    /** Preload only (alternate: try id1, on fail try id2). Does not show. */
    public static void preload(Activity activity, List<String> adsIdList) {
        if (activity == null || PremiumPlanManager.isPremiumActive(activity)) {
            return;
        }
        pendingIds = adsIdList;
        if (interstitialAd != null || isLoading) {
            return;
        }
        showWhenReady = false;
        adsViewInterAds = 0;
        loadInternal(activity, adsIdList);
    }

    /** Show preloaded ad, or load+show with alternate fallback if not ready. */
    public static void appOpenCall(Activity activity, List<String> adsIdList, OnCompleteAds callback) {
        onCompleteAds = callback;
        pendingIds = adsIdList;

        if (PremiumPlanManager.isPremiumActive(activity)) {
            if (onCompleteAds != null) onCompleteAds.onCompleteAds(false);
            return;
        }

        if (interstitialAd != null) {
            showAd(activity);
            return;
        }

        showWhenReady = true;
        if (isLoading) {
            // Preload in flight — show when it finishes
            return;
        }

        adsViewInterAds = 0;
        loadInternal(activity, adsIdList);
    }

    private static void loadInternal(Activity activity, List<String> adsIdList) {
        if (isLoading) {
            return;
        }

        isLoading = true;
        interAdsId(adsIdList);
        if (!isFailArrayId) {
            isLoading = false;
            android.util.Log.e("SplashInterMange", "No splash_inter IDs available");
            if (showWhenReady && onCompleteAds != null) {
                onCompleteAds.onCompleteAds(false);
            }
            showWhenReady = false;
            return;
        }

        android.util.Log.d("SplashInterMange", "Loading interstitial: " + interAdsType);
        AdRequest adRequest = new AdRequest.Builder().build();

        InterstitialAd.load(
                activity,
                interAdsType,
                adRequest,
                new InterstitialAdLoadCallback() {

                    @Override
                    public void onAdLoaded(@NonNull InterstitialAd ad) {
                        android.util.Log.d("SplashInterMange", "Interstitial loaded: " + interAdsType);
                        interstitialAd = ad;
                        isLoading = false;

                        FirebaseAnalytics firebaseAnalytics = FirebaseAnalytics.getInstance(activity);
                        interstitialAd.setOnPaidEventListener(new OnPaidEventListener() {
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

                        if (showWhenReady) {
                            showWhenReady = false;
                            showAd(activity);
                        }
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull LoadAdError error) {
                        android.util.Log.e(
                                "SplashInterMange",
                                "Inter fail [" + interAdsType + "]: " + error.getCode() + " " + error.getMessage()
                        );
                        interstitialAd = null;
                        isLoading = false;
                        // Alternate fallback: next id in list
                        if (adsIdList != null && adsViewInterAds < adsIdList.size()) {
                            loadInternal(activity, adsIdList);
                            return;
                        }
                        if (showWhenReady && onCompleteAds != null) {
                            showWhenReady = false;
                            onCompleteAds.onCompleteAds(false);
                        }
                    }
                }
        );
    }

    public static void interAdsId(List<String> nativeAdsIds) {
        try {
            if (nativeAdsIds != null && !nativeAdsIds.isEmpty() && adsViewInterAds < nativeAdsIds.size()) {
                isFailArrayId = true;
                interAdsType = nativeAdsIds.get(adsViewInterAds);
                adsViewInterAds = adsViewInterAds + 1;
            } else {
                isFailArrayId = false;
                adsViewInterAds = 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            isFailArrayId = false;
            adsViewInterAds = 0;
        }
    }

    private static void showAd(Activity activity) {
        if (interstitialAd == null || activity.isFinishing()) {
            // Nothing ready — try load with pending ids
            if (pendingIds != null && !isLoading) {
                showWhenReady = true;
                adsViewInterAds = 0;
                loadInternal(activity, pendingIds);
                return;
            }
            if (onCompleteAds != null) onCompleteAds.onCompleteAds(false);
            return;
        }

        interstitialAd.setFullScreenContentCallback(
                new FullScreenContentCallback() {

                    @Override
                    public void onAdShowedFullScreenContent() {
                        interSplashTime = System.currentTimeMillis();
                        FirebaseEventManager.interSplashView();
                        isLoading = true;
                    }

                    @Override
                    public void onAdDismissedFullScreenContent() {
                        interstitialAd = null;
                        isLoading = false;
                        restoreImmersiveMode(activity);
                        if (onCompleteAds != null)
                            onCompleteAds.onCompleteAds(true);
                        if (interSplashTime != null) {
                            FirebaseEventManager.interSplashComplete(interSplashTime);
                            interSplashTime = null;
                        }
                    }

                    @Override
                    public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                        interstitialAd = null;
                        isLoading = false;
                        restoreImmersiveMode(activity);
                        if (onCompleteAds != null)
                            onCompleteAds.onCompleteAds(false);
                        // No inter_splash_complete — ad never shown / user did not exit it
                        interSplashTime = null;
                    }
                }
        );

        interstitialAd.show(activity);
    }

    private static void restoreImmersiveMode(Activity activity) {
        if (activity == null || activity.isFinishing()) {
            return;
        }
        activity.getWindow().getDecorView().post(() -> {
            if (activity.isFinishing()) {
                return;
            }
            if (activity instanceof BaseActivity) {
                ((BaseActivity) activity).restoreFullScreenImmersive();
            }
        });
    }
}
