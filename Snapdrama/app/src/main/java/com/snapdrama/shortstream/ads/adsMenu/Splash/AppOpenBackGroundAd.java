package com.snapdrama.shortstream.ads.adsMenu.Splash;

import android.app.Activity;
import android.content.Context;
import android.os.Bundle;
import android.util.Log;

import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.OnPaidEventListener;
import com.google.android.gms.ads.appopen.AppOpenAd;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.firebase.analytics.FirebaseAnalytics;
import com.snapdrama.shortstream.activity.main.base.BaseActivity;
import com.snapdrama.shortstream.ads.FirebaseEventManager;
import com.snapdrama.shortstream.ads.PremiumPlanManager;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;

import java.util.List;

public class AppOpenBackGroundAd {

    private static AppOpenAd appOpenAd;
    private static boolean isAdShowing = false;

    public static int adsViewAppOpenAds = 0;
    public static boolean isFailArrayId = false;
    public static String appOpenAdsType = "";
    public static Long interSplashTime;

    public interface OnCompleteAds {
        void onCompleteAds(boolean shown);
    }

    private static OnCompleteAds onCompleteAds;

//    private static final String APP_OPEN_ID = ControlPreference.getString(ControlPreference.PUBLISHER_APP_OPEN_AD_ID);
    public static void appOpenCall(Activity activity, List<String> appOpedAdsIds, OnCompleteAds callback) {
        onCompleteAds = callback;
        // Ad already on screen — keep callback; dismiss will complete navigation
        if (isAdShowing) {
            return;
        }
        loadAndShowAd(activity,appOpedAdsIds);
    }


    private static void loadAndShowAd(Activity activity, List<String> appOpedAdsIds) {

        if (isAdShowing) {
            return;
        }
        if (activity.isFinishing()) {
            if (onCompleteAds != null) onCompleteAds.onCompleteAds(false);
            return;
        }

        if (PremiumPlanManager.isPremiumActive(activity)) {
            if (onCompleteAds != null) onCompleteAds.onCompleteAds(false);
            return;
        }
        AppOpenAdsId(appOpedAdsIds);
        if (!isFailArrayId) {
            if (onCompleteAds != null) onCompleteAds.onCompleteAds(false);
            return;
        }

        AdRequest adRequest = new AdRequest.Builder().build();

        AppOpenAd.load(
                activity,
                appOpenAdsType,
                adRequest,
                AppOpenAd.APP_OPEN_AD_ORIENTATION_PORTRAIT,
                new AppOpenAd.AppOpenAdLoadCallback() {

                    @Override
                    public void onAdLoaded(AppOpenAd ad) {
                        appOpenAd = ad;
                        FirebaseAnalytics firebaseAnalytics;
                        firebaseAnalytics = FirebaseAnalytics.getInstance(activity);
                        appOpenAd.setOnPaidEventListener(new OnPaidEventListener() {
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
                        showAd(activity);
                    }

                    @Override
                    public void onAdFailedToLoad(LoadAdError error) {
                        appOpenAd = null;
                        isAdShowing = false;
                        if (onCompleteAds != null)
                            onCompleteAds.onCompleteAds(false);
                    }
                }
        );
    }


    private static void showAd(Activity activity) {

        if (appOpenAd == null || activity.isFinishing()) {
            if (onCompleteAds != null) onCompleteAds.onCompleteAds(false);
            return;
        }

        appOpenAd.setFullScreenContentCallback(
                new FullScreenContentCallback() {

                    @Override
                    public void onAdShowedFullScreenContent() {
                        interSplashTime =   System.currentTimeMillis();
                        FirebaseEventManager.interSplashView();
//                        Log.d("TAG", "onAdShowedFullScreenContent: AppOpen Show " );
                        isAdShowing = true;
                    }

                    @Override
                    public void onAdDismissedFullScreenContent() {
                        isAdShowing = false;
                        appOpenAd = null;
                        restoreImmersiveMode(activity);
                        if (onCompleteAds != null)
                            onCompleteAds.onCompleteAds(true);
                        if (interSplashTime != null) {
                            FirebaseEventManager.interSplashComplete(interSplashTime);
                            interSplashTime = null;
                        }
                    }

                    @Override
                    public void onAdFailedToShowFullScreenContent(AdError error) {
                        isAdShowing = false;
                        appOpenAd = null;
                        restoreImmersiveMode(activity);
                        if (onCompleteAds != null)
                            onCompleteAds.onCompleteAds(false);
                        interSplashTime = null;
                    }
                }
        );

        appOpenAd.show(activity);
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

    public static void AppOpenAdsId(List<String> nativeAdsIds) {
        try {
            if (nativeAdsIds != null && !nativeAdsIds.isEmpty() && adsViewAppOpenAds < nativeAdsIds.size()) {
                isFailArrayId = true;
                appOpenAdsType = nativeAdsIds.get(adsViewAppOpenAds);
//                android.util.Log.d("SplashNativeAd", "Requesting Native Ad with ID at position " + adsViewAppOpenAds + ": " + appOpenAdsType);
                adsViewAppOpenAds = adsViewAppOpenAds + 1;
            } else {
//                android.util.Log.d("SplashNativeAd", "No more Native Ad IDs to request or list is empty. Resetting index.");
                isFailArrayId = false;
                adsViewAppOpenAds = 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            isFailArrayId = false;
            adsViewAppOpenAds = 0;
        }
    }

}
