package com.snapdrama.shortstream.ads.adsMenu.OnBoard;

import android.app.Activity;
import android.content.Context;
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
import com.snapdrama.shortstream.ads.FirebaseEventManager;
import com.snapdrama.shortstream.ads.PremiumPlanManager;

import java.util.List;

/**
 * Onboard interstitial (inter-ob5-1 / inter-ob5-2): preload with alternate fallback, show after login.
 */
public class InterOnboardAd {
    public static int adsViewInterAds = 0;
    public static boolean isFailArrayId = false;
    public static String interAdsType = "";

    private static InterstitialAd interstitialAd;
    private static boolean isLoading = false;
    private static boolean showWhenReady = false;
    private static List<String> pendingIds;
    private static Long interShowTime;
    private static OnCompleteAds onCompleteAds;

    public interface OnCompleteAds {
        void onCompleteAds(boolean shown);
    }

    public static void preload(Context context, List<String> adsIdList) {
        if (context == null || PremiumPlanManager.isPremiumActive(context)) {
            return;
        }
        pendingIds = adsIdList;
        if (isLoading || interstitialAd != null) {
            return;
        }
        showWhenReady = false;
        adsViewInterAds = 0;
        loadNext(context, adsIdList);
    }

    /**
     * Show preloaded ad, or load+show with alternate fallback (inter-ob5-1 → inter-ob5-2) if not ready.
     */
    public static void showThen(Activity activity, List<String> adsIdList, OnCompleteAds callback) {
        onCompleteAds = callback;
        if (adsIdList != null) {
            pendingIds = adsIdList;
        }

        if (activity == null || activity.isFinishing()) {
            if (onCompleteAds != null) onCompleteAds.onCompleteAds(false);
            return;
        }
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
            return;
        }

        adsViewInterAds = 0;
        loadNext(activity, pendingIds != null ? pendingIds : adsIdList);
    }

    private static void loadNext(Context context, List<String> adsIdList) {
        if (isLoading) {
            return;
        }
        interAdsId(adsIdList);
        if (!isFailArrayId) {
            if (showWhenReady && onCompleteAds != null) {
                showWhenReady = false;
                onCompleteAds.onCompleteAds(false);
            }
            return;
        }
        isLoading = true;
        AdRequest adRequest = new AdRequest.Builder().build();
        InterstitialAd.load(
                context,
                interAdsType,
                adRequest,
                new InterstitialAdLoadCallback() {
                    @Override
                    public void onAdLoaded(@NonNull InterstitialAd ad) {
                        interstitialAd = ad;
                        isLoading = false;
                        FirebaseAnalytics firebaseAnalytics = FirebaseAnalytics.getInstance(context);
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
                        if (showWhenReady && context instanceof Activity) {
                            showWhenReady = false;
                            showAd((Activity) context);
                        }
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull LoadAdError error) {
                        interstitialAd = null;
                        isLoading = false;
                        if (adsIdList != null && adsViewInterAds < adsIdList.size()) {
                            loadNext(context, adsIdList);
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

    public static void interAdsId(List<String> adsIds) {
        try {
            if (adsIds != null && !adsIds.isEmpty() && adsViewInterAds < adsIds.size()) {
                isFailArrayId = true;
                interAdsType = adsIds.get(adsViewInterAds);
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

    /** @deprecated Prefer {@link #showThen} so missing preload still loads with fallback. */
    public static void show(Activity activity, OnCompleteAds callback) {
        showThen(activity, pendingIds, callback);
    }

    private static void showAd(Activity activity) {
        if (activity == null || activity.isFinishing() || interstitialAd == null) {
            if (onCompleteAds != null) onCompleteAds.onCompleteAds(false);
            return;
        }

        FirebaseEventManager.init(activity);

        interstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
            @Override
            public void onAdShowedFullScreenContent() {
                interShowTime = System.currentTimeMillis();
                FirebaseEventManager.interOnboardView();
            }

            @Override
            public void onAdDismissedFullScreenContent() {
                interstitialAd = null;
                // Sheet: inter_onboard_complete when user exits the ad
                if (interShowTime != null) {
                    FirebaseEventManager.interOnboardComplete(interShowTime);
                    interShowTime = null;
                }
                if (onCompleteAds != null) onCompleteAds.onCompleteAds(true);
            }

            @Override
            public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                interstitialAd = null;
                // No inter_onboard_complete — ad never shown / user did not exit it
                interShowTime = null;
                if (onCompleteAds != null) onCompleteAds.onCompleteAds(false);
            }
        });
        interstitialAd.show(activity);
    }
}
