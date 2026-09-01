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

public class ReelsInterstitialManager {

    private InterstitialAd interstitialAd;
    private final Activity activity;

    private boolean isLoading = false;
    private boolean pendingShowAd = false;
    private Runnable pendingOnAdClosed;
    private int pendingTargetPosition = -1;
    private int lastSeenPosition = -1;
    private int lastAdShownPosition = -1;

    public static int adsViewInterAds = 0;
    public static boolean isFailArrayId = false;
    public static String interAdsType = "";

    public ReelsInterstitialManager(Activity activity) {
        this.activity = activity;
        loadAd();
    }

    private void loadAd() {
        if (isLoading || interstitialAd != null) return;
        // Premium: do not load Interstitial at all
        if (PremiumPlanManager.shouldSkipAfterLoginAd(activity)) return;

        isLoading = true;
        Log.d("TAGdd", "loadAd: " + ControlPreference.get_InterList_Ids_List());
        InterAdsId(ControlPreference.get_InterList_Ids_List());
        if (!isFailArrayId) {
            isLoading = false;
            return;
        }
        Log.d("TAGdd", "loadAd interAdsType: " + interAdsType);

        AdRequest adRequest = new AdRequest.Builder().build();

        InterstitialAd.load(
                activity,
                interAdsType,
                adRequest,
                new InterstitialAdLoadCallback() {

                    @Override
                    public void onAdLoaded(@NonNull InterstitialAd ad) {

                        Log.d("TAGdd", "loadAd onAdLoaded: " );
                        FirebaseAnalytics firebaseAnalytics;
                        firebaseAnalytics = FirebaseAnalytics.getInstance(activity);
                        ad.setOnPaidEventListener(new OnPaidEventListener() {
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
                        interstitialAd = ad;
                        isLoading = false;
                        tryShowPendingAd();

                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull LoadAdError error) {
                        Log.d("TAGdd", "loadAd onAdLoaded: "  +error.getMessage());
                        interstitialAd = null;
                        isLoading = false;
                    }
                }
        );
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
    public void onReelScrolled(int currentPosition, @NonNull Runnable onAdClosed) {
        Log.d("TAG", "onReelScrolled: 1111" );
        // Premium user: no Interstitial ad
        if (PremiumPlanManager.shouldSkipAfterLoginAd(activity)) {
            onAdClosed.run();
            return;
        }
        Log.d("TAG", "onReelScrolled: 22222" );

        // Only count when moving forward (down). Scrolling back up should not create extra counts.
        if (lastSeenPosition != -1 && currentPosition <= lastSeenPosition) {
            lastSeenPosition = currentPosition;
            onAdClosed.run();
            return;
        }
        lastSeenPosition = currentPosition;

        if (pendingShowAd) {
            pendingOnAdClosed = onAdClosed;
            if (currentPosition >= pendingTargetPosition && tryShowAd(onAdClosed, pendingTargetPosition)) {
                return;
            }
            onAdClosed.run();
            return;
        }

        int showAfter = ControlPreference.getInterstitialAdThreshold();
        if (showAfter <= 0) {
            showAfter = 1;
        }

        // Position-based rule:
        // If threshold=3 => show at positions 3,6,9... (4th,7th,10th reels)
        boolean isAdSlot = currentPosition >= showAfter && (currentPosition % showAfter == 0);
        if (!isAdSlot) {
            onAdClosed.run();
            return;
        }

        if (currentPosition <= lastAdShownPosition) {
            onAdClosed.run();
            return;
        }

        Log.d("TAG", "onReelScrolled: 333333 - ad slot reached at position=" + currentPosition + " threshold=" + showAfter );
        pendingShowAd = true;
        pendingOnAdClosed = onAdClosed;
        pendingTargetPosition = currentPosition;

        if (tryShowAd(onAdClosed, currentPosition)) {
            return;
        }

        loadAd();
        onAdClosed.run();
    }

    private void tryShowPendingAd() {
        if (!pendingShowAd || pendingOnAdClosed == null) {
            return;
        }
        Runnable callback = pendingOnAdClosed;
        if (tryShowAd(callback, pendingTargetPosition)) {
            return;
        }
        loadAd();
    }

    private boolean tryShowAd(@NonNull Runnable onAdClosed, int shownAtPosition) {
        if (interstitialAd == null) {
            return false;
        }

        if (activity.isFinishing() || activity.isDestroyed()) {
            pendingShowAd = false;
            pendingOnAdClosed = null;
            pendingTargetPosition = -1;
            return false;
        }

        final InterstitialAd adToShow = interstitialAd;
        interstitialAd = null;
        pendingShowAd = false;
        pendingOnAdClosed = null;
        pendingTargetPosition = -1;
        lastAdShownPosition = shownAtPosition;

        Log.d("TAG", "onReelScrolled: showing ad at position=" + shownAtPosition);
        adToShow.setFullScreenContentCallback(
                new FullScreenContentCallback() {

                    @Override
                    public void onAdShowedFullScreenContent() {
                    }

                    @Override
                    public void onAdDismissedFullScreenContent() {
                        interstitialAd = null;
                        loadAd();
                        onAdClosed.run();
                    }

                    @Override
                    public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                        Log.d("TAG", "onReelScrolled: show failed " + adError.getMessage());
                        interstitialAd = null;
                        loadAd();
                        onAdClosed.run();
                    }
                }
        );

        adToShow.show(activity);
        return true;
    }
}
