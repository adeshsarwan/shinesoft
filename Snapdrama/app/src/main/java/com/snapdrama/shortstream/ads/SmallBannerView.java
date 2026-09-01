package com.snapdrama.shortstream.ads;

import android.content.Context;
import android.util.AttributeSet;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.LinearLayout;

import androidx.annotation.Nullable;

import com.facebook.shimmer.ShimmerFrameLayout;
import com.snapdrama.shortstream.R;

public class SmallBannerView extends LinearLayout {

    public SmallBannerView(Context context) {
        super(context);
        init(context);
    }

    public SmallBannerView(Context context, @Nullable AttributeSet attrs) {
        super(context, attrs);
        init(context);
    }

    public SmallBannerView(Context context, @Nullable AttributeSet attrs, int defStyleAttr) {
        super(context, attrs, defStyleAttr);
        init(context);
    }

    private void init(Context context) {

        if (isInEditMode()) return;

        if (PremiumPlanManager.shouldSkipAfterLoginAd(context)) {
            setVisibility(View.GONE);
            return;
        }


        LayoutInflater.from(context).inflate(R.layout.ads_small_banner, this, true);

        LinearLayout adContainer = findViewById(R.id.linearBottomAds);
        ShimmerFrameLayout shimmerAdsLayout = findViewById(R.id.shimmerAdsLayout);

        BannerSmallView.bannerNativeAds(context, adContainer,shimmerAdsLayout);
    }
}