package com.flixotv.ignia

import android.view.LayoutInflater
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import com.google.android.gms.ads.nativead.MediaView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin.NativeAdFactory

class ListTileNativeAdFactory(
    private val layoutInflater: LayoutInflater
) : NativeAdFactory {
    override fun createNativeAd(
        nativeAd: NativeAd,
        customOptions: MutableMap<String, Any>?
    ): NativeAdView {
        val adView = layoutInflater.inflate(
            R.layout.native_ad_list_tile,
            null
        ) as NativeAdView

        val headlineView = adView.findViewById<TextView>(R.id.ad_headline)
        val bodyView = adView.findViewById<TextView>(R.id.ad_body)
        val ctaView = adView.findViewById<TextView>(R.id.ad_call_to_action)
        val iconView = adView.findViewById<ImageView>(R.id.ad_app_icon)
        val mediaView = adView.findViewById<MediaView>(R.id.ad_media)

        adView.headlineView = headlineView
        adView.bodyView = bodyView
        adView.callToActionView = ctaView
        adView.iconView = iconView

        headlineView.text = nativeAd.headline

        val body = nativeAd.body
        if (body.isNullOrEmpty()) {
            bodyView.visibility = View.GONE
        } else {
            bodyView.visibility = View.VISIBLE
            bodyView.text = body
        }

        val callToAction = nativeAd.callToAction
        if (callToAction.isNullOrEmpty()) {
            ctaView.visibility = View.GONE
        } else {
            ctaView.visibility = View.VISIBLE
            ctaView.text = callToAction
        }

        val icon = nativeAd.icon
        if (icon == null) {
            iconView.visibility = View.GONE
        } else {
            iconView.visibility = View.VISIBLE
            iconView.setImageDrawable(icon.drawable)
        }

        val mediaContent = nativeAd.mediaContent
        if (mediaContent != null && mediaContent.hasVideoContent()) {
            mediaView.visibility = View.VISIBLE
            adView.mediaView = mediaView
            mediaView.mediaContent = mediaContent
        } else {
            mediaView.visibility = View.GONE
        }

        adView.setNativeAd(nativeAd)
        return adView
    }
}
