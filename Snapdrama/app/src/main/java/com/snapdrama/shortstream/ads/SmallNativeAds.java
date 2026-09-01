//package com.snapdrama.shortstream.ads;
//
//import android.content.Context;
//import android.content.res.ColorStateList;
//import android.graphics.Color;
//import android.os.Bundle;
//import android.view.LayoutInflater;
//import android.view.View;
//import android.widget.ImageView;
//import android.widget.LinearLayout;
//import android.widget.RatingBar;
//import android.widget.TextView;
//
//import com.facebook.shimmer.ShimmerFrameLayout;
//import com.google.android.gms.ads.AdListener;
//import com.google.android.gms.ads.AdLoader;
//import com.google.android.gms.ads.AdValue;
//import com.google.android.gms.ads.LoadAdError;
//import com.google.android.gms.ads.MediaContent;
//import com.google.android.gms.ads.OnPaidEventListener;
//import com.google.android.gms.ads.VideoController;
//import com.google.android.gms.ads.admanager.AdManagerAdRequest;
//import com.google.android.gms.ads.nativead.NativeAd;
//import com.google.android.gms.ads.nativead.NativeAdView;
//import com.google.firebase.analytics.FirebaseAnalytics;
//import com.snapdrama.shortstream.R;
//import com.snapdrama.shortstream.applicationPreference.ControlPreference;
//
//import java.util.List;
//
//public class SmallNativeAds {
//    public static NativeAd nrps__Admob_NativeAd;
//    public static int adsViewNativeAds = 0;
//    public static boolean isFailArrayId = false;
//    public static String nativeAdsType = "";
//
//    public static void nrps__Load_Admob_Big_NativeAd(final Context context, final LinearLayout linearLayout, ShimmerFrameLayout shimmerFrameLayout) {
//        shimmerFrameLayout.setVisibility(View.VISIBLE);
//        // Premium user: no Native ad
//        if (context != null && PremiumPlanManager.isPremiumActive(context)) {
//            if (linearLayout != null) {
//                linearLayout.setVisibility(View.GONE);
//                shimmerFrameLayout.setVisibility(View.GONE);
//            }
//            return;
//        }
//
//        NativeAdsId(ControlPreference.get_NativeList_Ids_List());
//        if (!isFailArrayId) {
//            shimmerFrameLayout.setVisibility(View.GONE);
//            return;
//        }
//
//        AdLoader.Builder builder = new AdLoader.Builder(context, nativeAdsType)
//                .forNativeAd(new NativeAd.OnNativeAdLoadedListener() {
//                    @Override
//                    public void onNativeAdLoaded(NativeAd nativeAd) {
//                        shimmerFrameLayout.setVisibility(View.GONE);
//                        FirebaseAnalytics firebaseAnalytics;
//                        firebaseAnalytics = FirebaseAnalytics.getInstance(context);
//                        nativeAd.setOnPaidEventListener(new OnPaidEventListener() {
//                            @Override
//                            public void onPaidEvent(AdValue adValue) {
//                                double revenue = adValue.getValueMicros() / 1_000_000.0;
//                                String currency = adValue.getCurrencyCode();
//                                Bundle adRevenueParams = new Bundle();
//                                adRevenueParams.putString(FirebaseAnalytics.Param.AD_PLATFORM, "Google Ad Manager");
//                                adRevenueParams.putString(FirebaseAnalytics.Param.CURRENCY, currency);
//                                adRevenueParams.putDouble(FirebaseAnalytics.Param.VALUE, revenue);
//                                firebaseAnalytics.logEvent(FirebaseAnalytics.Event.AD_IMPRESSION, adRevenueParams);
//                            }
//                        });
//                        nrps__Admob_NativeAd = nativeAd;
//
//
//                        if (nrps__Admob_NativeAd != null) {
//
//                            LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
//
//                            NativeAdView adView;
//
//                            adView = (NativeAdView) inflater.inflate(R.layout.ads_small_native_layout, null);
//
//
//                            linearLayout.setVisibility(View.VISIBLE);
//                            populateNativeAdViewFullscreen(nrps__Admob_NativeAd, adView, false);
//
//                            linearLayout.removeAllViews();
//                            linearLayout.addView(adView);
//                        }
//
//                    }
//                });
//
//        AdLoader adLoader = builder.withAdListener(new AdListener() {
//                    @Override
//                    public void onAdFailedToLoad(LoadAdError adError) {
//                        if (nrps__Admob_NativeAd != null) {
//                            nrps__Admob_NativeAd = null;
//                        }
//                        shimmerFrameLayout.setVisibility(View.GONE);
//
//                        nrps__Load_Admob_Big_NativeAd(context, linearLayout,shimmerFrameLayout);
//
//                    }
//
//                    @Override
//                    public void onAdClicked() {
//
//                    }
//                })
//                .build();
//
//
//        AdManagerAdRequest adRequest = new AdManagerAdRequest.Builder()
//                .build();
//        adLoader.loadAd(adRequest);
//    }
//
//    public static void populateNativeAdViewFullscreen(NativeAd nativeAd, NativeAdView adView, boolean flag) {
//
////        com.google.android.gms.ads.nativead.MediaView mediaView = adView.findViewById(R.id.nrps__media_view);
//
////        adView.setMediaView(mediaView);
//        adView.setHeadlineView(adView.findViewById(R.id.reso__top_line));
//        adView.setBodyView(adView.findViewById(R.id.reso__body));
//        adView.setCallToActionView(adView.findViewById(R.id.reso__install_button));
//        adView.setIconView(adView.findViewById(R.id.reso__logo));
//        adView.setPriceView(adView.findViewById(R.id.reso__fees));
//        adView.setStarRatingView(adView.findViewById(R.id.reso__rate_stars));
//        adView.setStoreView(adView.findViewById(R.id.reso__store));
//        adView.setAdvertiserView(adView.findViewById(R.id.reso__advertisment));
//        ((TextView) adView.getHeadlineView()).setText(nativeAd.getHeadline());
//
//
//        try {
//            ((TextView) adView.getCallToActionView()).setBackgroundTintList(ColorStateList.valueOf(Color.parseColor(String.valueOf(R.color.app_colors))));
//            ((TextView) adView.getCallToActionView()).setTextColor(Color.parseColor(String.valueOf(R.color.white)));
//        } catch (NullPointerException n) {
//            n.printStackTrace();
//        } catch (Exception e) {
//            e.printStackTrace();
//        }
//
//        if (nativeAd.getBody() == null) {
//            adView.getBodyView().setVisibility(View.INVISIBLE);
//        } else {
//            adView.getBodyView().setVisibility(View.VISIBLE);
//            ((TextView) adView.getBodyView()).setText(nativeAd.getBody());
//        }
//
//        if (nativeAd.getCallToAction() == null) {
//            adView.getCallToActionView().setVisibility(View.INVISIBLE);
//        } else {
//            adView.getCallToActionView().setVisibility(View.VISIBLE);
//            ((TextView) adView.getCallToActionView()).setText(nativeAd.getCallToAction());
//        }
//
//        if (nativeAd.getIcon() == null) {
//            adView.getIconView().setVisibility(View.GONE);
//        } else {
//            ((ImageView) adView.getIconView()).setImageDrawable(
//                    nativeAd.getIcon().getDrawable());
//            adView.getIconView().setVisibility(View.VISIBLE);
//        }
//
//        if (nativeAd.getPrice() == null) {
//            adView.getPriceView().setVisibility(View.GONE);
//        } else {
//            adView.getPriceView().setVisibility(View.VISIBLE);
//            ((TextView) adView.getPriceView()).setText(nativeAd.getPrice());
//        }
//
//        if (nativeAd.getStore() == null) {
//            adView.getStoreView().setVisibility(View.INVISIBLE);
//        } else {
//            adView.getStoreView().setVisibility(View.VISIBLE);
//            ((TextView) adView.getStoreView()).setText(nativeAd.getStore());
//        }
//
//        if (nativeAd.getStarRating() == null) {
//            if (flag) {
//                adView.getStarRatingView().setVisibility(View.GONE);
//            } else {
//                adView.getStarRatingView().setVisibility(View.GONE);
//            }
//        } else {
//            ((RatingBar) adView.getStarRatingView())
//                    .setRating(nativeAd.getStarRating().floatValue());
//            if (flag) {
//                adView.getStarRatingView().setVisibility(View.GONE);
//            } else {
//                adView.getStarRatingView().setVisibility(View.VISIBLE);
//            }
//        }
//
//
//        if (nativeAd.getAdvertiser() == null) {
//            if (flag) {
//                adView.getAdvertiserView().setVisibility(View.GONE);
//            } else {
//                adView.getAdvertiserView().setVisibility(View.GONE);
//            }
//        } else {
//            ((TextView) adView.getAdvertiserView()).setText(nativeAd.getAdvertiser());
//            if (flag) {
//                adView.getAdvertiserView().setVisibility(View.GONE);
//            } else {
//                adView.getAdvertiserView().setVisibility(View.VISIBLE);
//            }
//        }
//
//        adView.setNativeAd(nativeAd);
//
////        MediaContent vc = nativeAd.getMediaContent();
////
////        if (vc.hasVideoContent()) {
////            nativeAd.getMediaContent().getVideoController().setVideoLifecycleCallbacks(new VideoController.VideoLifecycleCallbacks() {
////                @Override
////                public void onVideoEnd() {
////                    super.onVideoEnd();
////                }
////            });
////        } else {
////            mediaView.setImageScaleType(ImageView.ScaleType.CENTER_CROP);
////        }
//    }
//
//    public static void NativeAdsId(List<String> nativeAdsIds) {
//        try {
//            if (nativeAdsIds != null && !nativeAdsIds.isEmpty() && adsViewNativeAds < nativeAdsIds.size()) {
//                isFailArrayId = true;
//                nativeAdsType = nativeAdsIds.get(adsViewNativeAds);
////                android.util.Log.d("SplashNativeAd", "Requesting Native Ad with ID at position " + adsViewNativeAds + ": " + nativeAdsType);
//                adsViewNativeAds = adsViewNativeAds + 1;
//            } else {
////                android.util.Log.d("SplashNativeAd", "No more Native Ad IDs to request or list is empty. Resetting index.");
//                isFailArrayId = false;
//                adsViewNativeAds = 0;
//            }
//        } catch (Exception e) {
//            e.printStackTrace();
//            isFailArrayId = false;
//            adsViewNativeAds = 0;
//        }
//    }
//
//}
