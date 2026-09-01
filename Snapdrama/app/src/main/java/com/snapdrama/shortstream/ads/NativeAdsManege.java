package com.snapdrama.shortstream.ads;

import android.content.Context;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RatingBar;
import android.widget.TextView;

import com.facebook.shimmer.ShimmerFrameLayout;
import com.google.android.gms.ads.AdListener;
import com.google.android.gms.ads.AdLoader;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MediaContent;
import com.google.android.gms.ads.OnPaidEventListener;
import com.google.android.gms.ads.VideoController;
import com.google.android.gms.ads.admanager.AdManagerAdRequest;
import com.google.android.gms.ads.nativead.MediaView;
import com.google.android.gms.ads.nativead.NativeAd;
import com.google.android.gms.ads.nativead.NativeAdView;
import com.google.firebase.analytics.FirebaseAnalytics;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;

import java.util.List;

public class NativeAdsManege {
    public static NativeAd nrps__Admob_NativeAd;
    public static int adsViewNativeAds = 0;
    public static boolean isFailArrayId = false;
    public static String nativeAdsType = "";
    private static boolean isLoading = false;

    public static void displayNativeBottomId(Context context, final LinearLayout linearLayout, ShimmerFrameLayout shimmerFrameLayout, String type) {

        // If an ad is already loaded, just display it and ensure shimmer is hidden
        if (nrps__Admob_NativeAd != null) {
            shimmerFrameLayout.setVisibility(View.GONE);
            // Ensure container is clean before adding
            if (linearLayout != null) {
                linearLayout.removeAllViews();
                NativeAdView adView = null;
                LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                if (type.equals("small")) {
                    adView = (NativeAdView) inflater.inflate(R.layout.ads_small_native_layout, null);
                    populateSmallNativeAdView(nrps__Admob_NativeAd, adView, false);
                } else {
                    adView = (NativeAdView) inflater.inflate(R.layout.ads_medium_ntv_template, null);
                    populateNativeAdViewFullscreen(nrps__Admob_NativeAd, adView, false);
                }
                linearLayout.setVisibility(View.VISIBLE);
                linearLayout.addView(adView, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT));
            }
            // No need to request a new ad
            return;
        }

        // No cached ad – show shimmer and request a new one
        if (linearLayout != null) {
            linearLayout.setVisibility(View.GONE);
            nrps__Admob_NativeAd = null;
        }
        shimmerFrameLayout.setVisibility(View.VISIBLE);
        nrps__Load_Admob_Big_NativeAd(context, linearLayout, shimmerFrameLayout, type);
//    }

//        if (nrps__Admob_NativeAd != null) {
//
//            shimmerFrameLayout.setVisibility(View.GONE);
//            NativeAdView adView = null;
//            LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
////            shimmerFrameLayout.setVisibility(View.GONE);
//
//            if (type.equals("small")) {
//                adView = (NativeAdView) inflater.inflate(R.layout.ads_small_native_layout, null);
//                populateSmallNativeAdView(nrps__Admob_NativeAd, adView, false);
//            } else {
//                adView = (NativeAdView) inflater.inflate(R.layout.ads_medium_ntv_template, null);
//                populateNativeAdViewFullscreen(nrps__Admob_NativeAd, adView, false);
//            }
//            linearLayout.setVisibility(View.VISIBLE);
//            if (linearLayout != null) {
//                linearLayout.removeAllViews();
//                linearLayout.addView(adView, new LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.MATCH_PARENT));
//            }
//        } else {
//            if (linearLayout != null) {
//                linearLayout.setVisibility(View.GONE);
//                shimmerFrameLayout.setVisibility(View.GONE);
//            }
//        }
        // When the container is cleared (e.g., fragment view destroyed), clear cached ad to avoid stale display
//        if (linearLayout == null) {
//            nrps__Admob_NativeAd = null;
//        }
    }


    public static void nrps__Load_Admob_Big_NativeAd(final Context context, final LinearLayout linearLayout, ShimmerFrameLayout shimmerFrameLayout, String type) {
        if (isLoading) return;
        isLoading = true;
        shimmerFrameLayout.setVisibility(View.VISIBLE);
        // Premium / after-login ads off: collapse entire native container (no empty gap)
        if (context != null && PremiumPlanManager.shouldSkipAfterLoginAd(context)) {
            shimmerFrameLayout.setVisibility(View.GONE);
            if (linearLayout != null) {
                linearLayout.removeAllViews();
                linearLayout.setVisibility(View.GONE);
                hideOuterAdHost(linearLayout);
            }
            isLoading = false;
            return;
        }

        NativeAdsId(ControlPreference.get_NativeList_Ids_List());
        if (!isFailArrayId) {
            // If ID list cycled, reset and try once more to avoid "every other time" skip.
            List<String> ids = ControlPreference.get_NativeList_Ids_List();
            if (ids != null && !ids.isEmpty()) {
                NativeAdsId(ids);
            }
            if (!isFailArrayId) {
                shimmerFrameLayout.setVisibility(View.GONE);
                if (linearLayout != null) linearLayout.setVisibility(View.GONE);
                isLoading = false;
                return;
            }
        }

        AdLoader.Builder builder = new AdLoader.Builder(context, nativeAdsType)
                .forNativeAd(new NativeAd.OnNativeAdLoadedListener() {
                    @Override
                    public void onNativeAdLoaded(NativeAd nativeAd) {
                        shimmerFrameLayout.setVisibility(View.GONE);
                        isLoading = false;
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
                        if (nrps__Admob_NativeAd != null) {
                            try {
                                nrps__Admob_NativeAd.destroy();
                            } catch (Exception ignored) {
                            }
                        }
                        nrps__Admob_NativeAd = nativeAd;

                        // If the container is not available (view destroyed), cache the ad and show next time.
                        if (linearLayout == null) return;

                        LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
                        NativeAdView adView;
                        if (type.equals("small")) {
                            adView = (NativeAdView) inflater.inflate(R.layout.ads_small_native_layout, null);
                            populateSmallNativeAdView(nrps__Admob_NativeAd, adView, false);
                        } else {
                            adView = (NativeAdView) inflater.inflate(R.layout.ads_medium_ntv_template, null);
                            populateNativeAdViewFullscreen(nrps__Admob_NativeAd, adView, false);
                        }

                        linearLayout.setVisibility(View.VISIBLE);
                        linearLayout.removeAllViews();
                        linearLayout.addView(
                                adView,
                                new LinearLayout.LayoutParams(
                                        LinearLayout.LayoutParams.MATCH_PARENT,
                                        LinearLayout.LayoutParams.WRAP_CONTENT
                                )
                        );

                    }
                });

        AdLoader adLoader = builder.withAdListener(new AdListener() {
                    @Override
                    public void onAdFailedToLoad(LoadAdError adError) {
                        shimmerFrameLayout.setVisibility(View.GONE);
                        isLoading = false;
                        List<String> ids = ControlPreference.get_NativeList_Ids_List();
                        if (ids != null && !ids.isEmpty()) {
                            nrps__Load_Admob_Big_NativeAd(context, linearLayout, shimmerFrameLayout, type);
                        } else {
                            if (linearLayout != null) linearLayout.setVisibility(View.GONE);
                        }

                    }

                    @Override
                    public void onAdClicked() {

                    }
                })
                .build();


        AdManagerAdRequest adRequest = new AdManagerAdRequest.Builder()
                .build();
        adLoader.loadAd(adRequest);
    }

    public static void populateNativeAdViewFullscreen(NativeAd nativeAd, NativeAdView adView, boolean flag) {

        MediaView mediaView = adView.findViewById(R.id.nrps__media_view);

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
            ((TextView) adView.getCallToActionView()).setBackgroundTintList(ColorStateList.valueOf(Color.parseColor(String.valueOf(R.color.app_colors))));
            ((TextView) adView.getCallToActionView()).setTextColor(Color.parseColor(String.valueOf(R.color.white)));
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
            mediaView.setImageScaleType(ImageView.ScaleType.CENTER_CROP);
        }
    }

    public static void NativeAdsId(List<String> nativeAdsIds) {
        try {
            if (nativeAdsIds != null && !nativeAdsIds.isEmpty() && adsViewNativeAds < nativeAdsIds.size()) {
                isFailArrayId = true;
                nativeAdsType = nativeAdsIds.get(adsViewNativeAds);
//                android.util.Log.d("SplashNativeAd", "Requesting Native Ad with ID at position " + adsViewNativeAds + ": " + nativeAdsType);
                adsViewNativeAds = adsViewNativeAds + 1;
            } else {
//                android.util.Log.d("SplashNativeAd", "No more Native Ad IDs to request or list is empty. Resetting index.");
                isFailArrayId = false;
                adsViewNativeAds = 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            isFailArrayId = false;
            adsViewNativeAds = 0;
        }
    }

    /** Walk up and GONE custom ad host views so XML slots collapse with no empty gap. */
    private static void hideOuterAdHost(View from) {
        View p = from;
        while (p != null) {
            if (p instanceof MediumNativeViewAds
                    || p instanceof SmallNativeViewAds
                    || p instanceof SmallBannerView) {
                p.setVisibility(View.GONE);
                return;
            }
            Object parent = p.getParent();
            p = parent instanceof View ? (View) parent : null;
        }
        // Fallback: hide nearest parent layout
        if (from.getParent() instanceof View) {
            ((View) from.getParent()).setVisibility(View.GONE);
        }
    }


    public static void populateSmallNativeAdView(NativeAd nativeAd, NativeAdView adView, boolean flag) {

//        com.google.android.gms.ads.nativead.MediaView mediaView = adView.findViewById(R.id.nrps__media_view);

//        adView.setMediaView(mediaView);
        adView.setHeadlineView(adView.findViewById(R.id.reso__top_line));
        adView.setBodyView(adView.findViewById(R.id.reso__body));
        adView.setCallToActionView(adView.findViewById(R.id.reso__install_button));
        adView.setIconView(adView.findViewById(R.id.reso__logo));
        adView.setPriceView(adView.findViewById(R.id.reso__fees));
        adView.setStarRatingView(adView.findViewById(R.id.reso__rate_stars));
        adView.setStoreView(adView.findViewById(R.id.reso__store));
        adView.setAdvertiserView(adView.findViewById(R.id.reso__advertisment));
        ((TextView) adView.getHeadlineView()).setText(nativeAd.getHeadline());


        try {
            ((TextView) adView.getCallToActionView()).setBackgroundTintList(ColorStateList.valueOf(Color.parseColor(String.valueOf(R.color.app_colors))));
            ((TextView) adView.getCallToActionView()).setTextColor(Color.parseColor(String.valueOf(R.color.white)));
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

//        MediaContent vc = nativeAd.getMediaContent();
//
//        if (vc.hasVideoContent()) {
//            nativeAd.getMediaContent().getVideoController().setVideoLifecycleCallbacks(new VideoController.VideoLifecycleCallbacks() {
//                @Override
//                public void onVideoEnd() {
//                    super.onVideoEnd();
//                }
//            });
//        } else {
//            mediaView.setImageScaleType(ImageView.ScaleType.CENTER_CROP);
//        }
    }

}
