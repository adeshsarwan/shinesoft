package com.snapdrama.shortstream.ads;

import android.content.Context;
import android.os.Bundle;
import android.view.View;
import android.widget.LinearLayout;

import androidx.annotation.NonNull;

import com.facebook.shimmer.ShimmerFrameLayout;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdSize;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.AdView;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.OnPaidEventListener;
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import com.google.firebase.analytics.FirebaseAnalytics;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;

import java.util.List;

public class BannerSmallView {
    public static int adsViewBannerAds = 0;
    public static boolean isFailArrayId = false;
    public static String bannerAdsType = "";

    public static void bannerNativeAds(Context context, LinearLayout lnr_adview , ShimmerFrameLayout shimmerFrameLayout) {

        if (context == null) return;
        shimmerFrameLayout.setVisibility(View.VISIBLE);
        if (PremiumPlanManager.shouldSkipAfterLoginAd(context)) {
            if (lnr_adview != null) {
                lnr_adview.removeAllViews();
                lnr_adview.setVisibility(View.GONE);
                shimmerFrameLayout.setVisibility(View.GONE);
                // Collapse SmallBannerView host (and Home SmallNative slot if present)
                View p = lnr_adview;
                while (p != null) {
                    if (p instanceof SmallBannerView || (p.getId() == com.snapdrama.shortstream.R.id.SmallNative)) {
                        p.setVisibility(View.GONE);
                        break;
                    }
                    Object parent = p.getParent();
                    p = parent instanceof View ? (View) parent : null;
                }
            }
            return;
        }
        BannerAdsId(ControlPreference.get_BannerList_Ids_List());
        if (!isFailArrayId) {
            shimmerFrameLayout.setVisibility(View.GONE);
            return;
        }
        AdView adView = new AdView(context);
        adView.setAdUnitId(bannerAdsType);

        adView.setAdListener(new AdListener() {
            @Override
            public void onAdLoaded() {
                super.onAdLoaded();
                shimmerFrameLayout.setVisibility(View.GONE);
                FirebaseAnalytics firebaseAnalytics;
                firebaseAnalytics = FirebaseAnalytics.getInstance(context);
                adView.setOnPaidEventListener(new OnPaidEventListener() {
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
            }

            @Override
            public void onAdFailedToLoad(@NonNull LoadAdError loadAdError) {
                super.onAdFailedToLoad(loadAdError);
                shimmerFrameLayout.setVisibility(View.GONE);
                if (lnr_adview != null) {
                    lnr_adview.removeAllViews();
                    lnr_adview.setVisibility(View.GONE);
                }
                View p = lnr_adview;
                while (p != null) {
                    if (p instanceof SmallBannerView || (p.getId() == com.snapdrama.shortstream.R.id.SmallNative)) {
                        p.setVisibility(View.GONE);
                        break;
                    }
                    Object parent = p.getParent();
                    p = parent instanceof View ? (View) parent : null;
                }
            }
        });
        lnr_adview.removeAllViews();
        lnr_adview.addView(adView);

        adView.setAdSize(AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(context, 360));

        AdManagerAdRequest adRequest = new AdManagerAdRequest.Builder().build();

        adView.loadAd(adRequest);
    }

    public static void BannerAdsId(List<String> nativeAdsIds) {
        try {
            if (nativeAdsIds != null && !nativeAdsIds.isEmpty() && adsViewBannerAds < nativeAdsIds.size()) {
                isFailArrayId = true;
                bannerAdsType = nativeAdsIds.get(adsViewBannerAds);
//                android.util.Log.d("SplashNativeAd", "Requesting Native Ad with ID at position " + adsViewBannerAds + ": " + bannerAdsType);
                adsViewBannerAds = adsViewBannerAds + 1;
            } else {
//                android.util.Log.d("SplashNativeAd", "No more Native Ad IDs to request or list is empty. Resetting index.");
                isFailArrayId = false;
                adsViewBannerAds = 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            isFailArrayId = false;
            adsViewBannerAds = 0;
        }
    }
}
