package com.snapdrama.shortstream.ads;

import android.content.Context;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.LinearLayout;

import androidx.annotation.Nullable;

import com.facebook.shimmer.ShimmerFrameLayout;
import com.snapdrama.shortstream.R;

public class SmallNativeViewAds extends LinearLayout {

    static LinearLayout linearMediumAds;
    static ShimmerFrameLayout shimmerAdsLayout;
    static Context context;

    public SmallNativeViewAds(Context nrps__context) {
        super(nrps__context);
    }

    public SmallNativeViewAds(Context nrps__context, @Nullable AttributeSet attrs) {
        super(nrps__context, attrs);
        SmallNativeViewAds.context = nrps__context;
        if (isInEditMode()) {
            return;
        }
        // Premium: do not load or show Native ad — hide entire view
        if (PremiumPlanManager.shouldSkipAfterLoginAd(nrps__context)) {
            setVisibility(View.GONE);

            return;
        }
        else {

        }
        LayoutInflater li = LayoutInflater.from(nrps__context);
        LinearLayout ll = (LinearLayout) li.inflate(R.layout.ads_small_native, this);
        linearMediumAds = (LinearLayout) findViewById(R.id.linearSmallNtv);
        shimmerAdsLayout = (ShimmerFrameLayout) findViewById(R.id.shimmerAdsLayout);
//        NativeAdsManege.displayNativeBottomId(context, linearMediumAds ,shimmerAdsLayout,"small");
        NativeAdsManege.nrps__Load_Admob_Big_NativeAd(context, linearMediumAds ,shimmerAdsLayout,"small");
    }

    public SmallNativeViewAds(Context nrps__context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(nrps__context, attrs, defStyleAttr);
    }

}