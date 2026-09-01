package com.snapdrama.shortstream.ads.adsMenu.Home;
//


import android.content.Context;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RatingBar;
import android.widget.TextView;

import com.facebook.shimmer.ShimmerFrameLayout;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdLoader;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MediaContent;
import com.google.android.gms.ads.OnPaidEventListener;
import com.google.android.gms.ads.VideoController;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAdView;
import com.google.firebase.analytics.FirebaseAnalytics;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.ads.PremiumPlanManager;

import java.util.List;

public class HomeNewDataNativeAds {
    public static void displayNativeBottomId(Context context, NativeAd nativeAd, final LinearLayout linearLayout) {

//        if (SetterMethodAdView.gettrsv__Ads_Type().equals("Load")) {
//            loadAdmobBigNativeAd(context, nativeAdsIds, linearLayout, lnr_view, banner_flag);
//            return;
//        }

        if (nativeAd != null) {
            LayoutInflater inflater = (LayoutInflater) context
                    .getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            NativeAdView adView = (NativeAdView) inflater.inflate(R.layout.ads_medium_ntv_template, null);
//            if (lnr_view != null) {
//                lnr_view.setVisibility(View.GONE);
//            }
            if (linearLayout != null) {
                linearLayout.setVisibility(View.VISIBLE);
            }
            nativePopulateAdView(nativeAd, adView, false);
            if (linearLayout != null) {
                linearLayout.removeAllViews();
                linearLayout.addView(adView, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT));
            }
//            SystemDeveloperService.admobNativeHashMap.put(SystemDeveloperService.helperPosition, adView);
        } else {
            if (linearLayout != null) {
                linearLayout.setVisibility(View.GONE);
            }
//            if (lnr_view != null) {
//                lnr_view.setVisibility(View.GONE);
//            }
        }
//        loadAdmobBigNativeAd(context, nativeAdsIds, linearLayout);
    }

    public static void loadAdmobBigNativeAd(final Context context, List<String> nativeAdsIds, final LinearLayout linearLayout, final LinearLayout linearLayoutMain, final ShimmerFrameLayout shimmerFrameLayout, final int index) {

        if (context != null && PremiumPlanManager.shouldSkipAfterLoginAd(context)) {
            // Collapse whole ad row (shimmer + container) so no empty black gap remains
            if (shimmerFrameLayout != null) shimmerFrameLayout.setVisibility(View.GONE);
            if (linearLayout != null) {
                linearLayout.removeAllViews();
                linearLayout.setVisibility(View.GONE);
            }
            if (linearLayoutMain != null) {
                linearLayoutMain.setVisibility(View.GONE);
                ViewGroup.LayoutParams lp = linearLayoutMain.getLayoutParams();
                if (lp != null) {
                    lp.height = 0;
                    linearLayoutMain.setLayoutParams(lp);
                }
            }
            return;
        }
        if (shimmerFrameLayout != null) {
            shimmerFrameLayout.setVisibility(View.VISIBLE);
        }
        if (nativeAdsIds == null || nativeAdsIds.isEmpty() || index >= nativeAdsIds.size()) {
//            android.util.Log.d("SplashNativeAd", "No more Native Ad IDs to request or list is empty.");
            return;
        }

        String adUnitId = nativeAdsIds.get(index);
//        android.util.Log.d("SplashNativeAd", "Requesting Native Ad with ID at position " + index + ": " + adUnitId);

        AdLoader.Builder builder = new AdLoader.Builder(context, adUnitId)
                .forNativeAd(new NativeAd.OnNativeAdLoadedListener() {
                    @Override
                    public void onNativeAdLoaded(NativeAd nativeAd) {
                        shimmerFrameLayout.setVisibility(View.GONE);
                        FirebaseAnalytics firebaseAnalytics;
                        firebaseAnalytics = FirebaseAnalytics.getInstance(context);
                        nativeAd.setOnPaidEventListener(new OnPaidEventListener() {
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

//                        android.util.Log.d("SplashNativeAd", "Native Ad loaded successfully.");
                        displayNativeBottomId(context, nativeAd, linearLayout);

                    }
                });

        AdLoader adLoader = builder.withAdListener(new AdListener() {
                    @Override
                    public void onAdFailedToLoad(LoadAdError adError) {
//                        android.util.Log.e("SplashNativeAd", "Native Ad failed to load: " + adError.getMessage());
                        loadAdmobBigNativeAd(context, nativeAdsIds, linearLayout, linearLayoutMain, shimmerFrameLayout, index + 1);
                        linearLayoutMain.setVisibility(View.GONE);
                        shimmerFrameLayout.setVisibility(View.GONE);

                    }

                    @Override
                    public void onAdClicked() {
//                        AdViewController.isAppFastStart = true;
//                        adsShowCheckEvent(false);
                    }
                })
                .build();


        AdRequest adRequest = new AdRequest.Builder().build();
        adLoader.loadAd(adRequest);
    }

    public static void nativePopulateAdView(NativeAd nativeAd, NativeAdView adView, boolean flag) {

        com.google.android.gms.ads.nativead.MediaView mediaView = adView.findViewById(R.id.nrps__media_view);

        adView.setMediaView(mediaView);
        adView.setHeadlineView(adView.findViewById(R.id.nrps__top_line));
        adView.setBodyView(adView.findViewById(R.id.nrps__body));
        adView.setCallToActionView(adView.findViewById(R.id.nrps__install_button));
        adView.setIconView(adView.findViewById(R.id.nrps__logo));
        adView.setPriceView(adView.findViewById(R.id.nrps__fees));
        adView.setStarRatingView(adView.findViewById(R.id.nrps__rate_stars));
        adView.setStoreView(adView.findViewById(R.id.nrps__store));
        adView.setAdvertiserView(adView.findViewById(R.id.nrps__advertisment));
        ((TextView) adView.getHeadlineView()).setText(nativeAd.getHeadline());


        try {
//            ((TextView) adView.getCallToActionView()).setBackgroundTintList(ColorStateList.valueOf(Color.parseColor(SetterMethodAdView.gettrsv__Native_Button_Color())));
//            ((TextView) adView.getCallToActionView()).setTextColor(Color.parseColor(SetterMethodAdView.gettrsv__Native_Button_Text_Color()));
        } catch (NullPointerException n) {
            n.printStackTrace();
        } catch (Exception e) {
            e.printStackTrace();
        }

        if (nativeAd.getBody() == null) {
            adView.getBodyView().setVisibility(View.INVISIBLE);
        } else {
            adView.getBodyView().setVisibility(View.VISIBLE);
            ((TextView) adView.getBodyView()).setText(nativeAd.getBody());
        }

        if (nativeAd.getCallToAction() == null) {
            adView.getCallToActionView().setVisibility(View.INVISIBLE);
        } else {
            adView.getCallToActionView().setVisibility(View.VISIBLE);
            ((TextView) adView.getCallToActionView()).setText(nativeAd.getCallToAction());
        }

        if (nativeAd.getIcon() == null) {
            adView.getIconView().setVisibility(View.GONE);
        } else {
            ((ImageView) adView.getIconView()).setImageDrawable(
                    nativeAd.getIcon().getDrawable());
            adView.getIconView().setVisibility(View.VISIBLE);
        }

        if (nativeAd.getPrice() == null) {
            adView.getPriceView().setVisibility(View.GONE);
        } else {
            adView.getPriceView().setVisibility(View.VISIBLE);
            ((TextView) adView.getPriceView()).setText(nativeAd.getPrice());
        }

        if (nativeAd.getStore() == null) {
            adView.getStoreView().setVisibility(View.INVISIBLE);
        } else {
            adView.getStoreView().setVisibility(View.VISIBLE);
            ((TextView) adView.getStoreView()).setText(nativeAd.getStore());
        }

        if (nativeAd.getStarRating() == null) {
            if (flag) {
                adView.getStarRatingView().setVisibility(View.GONE);
            } else {
                adView.getStarRatingView().setVisibility(View.GONE);
            }
        } else {
            ((RatingBar) adView.getStarRatingView())
                    .setRating(nativeAd.getStarRating().floatValue());
            if (flag) {
                adView.getStarRatingView().setVisibility(View.GONE);
            } else {
                adView.getStarRatingView().setVisibility(View.VISIBLE);
            }
        }


        if (nativeAd.getAdvertiser() == null) {
            if (flag) {
                adView.getAdvertiserView().setVisibility(View.GONE);
            } else {
                adView.getAdvertiserView().setVisibility(View.GONE);
            }
        } else {
            ((TextView) adView.getAdvertiserView()).setText(nativeAd.getAdvertiser());
            if (flag) {
                adView.getAdvertiserView().setVisibility(View.GONE);
            } else {
                adView.getAdvertiserView().setVisibility(View.VISIBLE);
            }
        }

        adView.setNativeAd(nativeAd);

        MediaContent vc = nativeAd.getMediaContent();

        if (vc.hasVideoContent()) {
            nativeAd.getMediaContent().getVideoController().setVideoLifecycleCallbacks(new VideoController.VideoLifecycleCallbacks() {
                @Override
                public void onVideoEnd() {
                    super.onVideoEnd();
                }
            });
        } else {
//            mediaView.setImageScaleType(ImageView.ScaleType.CENTER_CROP);
        }
    }

}
