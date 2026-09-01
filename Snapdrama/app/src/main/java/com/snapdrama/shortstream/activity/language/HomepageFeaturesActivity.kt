package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.FirebaseEventManager
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.InterOnboardAd
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard2NativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard2TwoNativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard3ThreeNativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard4NativeAdView
import com.snapdrama.shortstream.applicationPreference.ControlPreference

/** Sheet screen: onboard_1 → Homepage Features tutorial */
class HomepageFeaturesActivity : BaseOtherActivity() {

    companion object {
        /** Used for view_type first_view vs revisit */
        private var hasEverViewedOnb1 = false
    }

    private var hasNavigated = false
    private var screenStartTime = 0L
    private var onb1ViewLoggedThisVisit = false
    private var onb1CompleteLogged = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_homepage_features)
        FirebaseEventManager.init(this)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)

        // Display priority → native-ob2-1 (onboard_2_native) — IDs from RC only
        OnBoard2NativeAdView.adsViewNativeAds = 0
        OnBoard2NativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard2Native_Ids_List(),
            linearSmallNtv
        )

        // Preload → native-ob2-2 for For You page
        OnBoard2TwoNativeAdView.adsViewNativeAds = 0
        OnBoard2TwoNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard2TwoNative_Ids_List(),
            null
        )

        // Preload alternate 2 → native-ob3-3 → native-ob3-1
        OnBoard3ThreeNativeAdView.adsViewNativeAds = 0
        val ob33Alt = mutableListOf<String>()
        ControlPreference.get_OnBoard3ThreeNative_Ids_List()
            ?.takeIf { it.isNotEmpty() }
            ?.let { ob33Alt.addAll(it) }
        ControlPreference.get_OnBoard3Native_Ids_List()
            ?.firstOrNull()
            ?.let { if (!ob33Alt.contains(it)) ob33Alt.add(it) }
        OnBoard3ThreeNativeAdView.loadAdmobBigNativeAd(this, ob33Alt, null)

        // Preload alternate 2 → native-ob4-1 → native-ob4-2
        OnBoard4NativeAdView.adsViewNativeAds = 0
        val ob4Alt = mutableListOf<String>()
        ControlPreference.get_OnBoard4Native_Ids_List()
            ?.takeIf { it.isNotEmpty() }
            ?.let { ob4Alt.addAll(it) }
        ControlPreference.get_OnBoard4TwoNative_Ids_List()
            ?.firstOrNull()
            ?.let { if (!ob4Alt.contains(it)) ob4Alt.add(it) }
        OnBoard4NativeAdView.loadAdmobBigNativeAd(this, ob4Alt, null)

        // Preload alternate 2 → inter-ob5-1 → inter-ob5-2
        InterOnboardAd.preload(this, ControlPreference.get_InterOnboard_Ids_List())

        findViewById<android.view.View>(R.id.btnBack).setOnClickListener {
            navigateBack()
        }

        nextButton.setOnClickListener {
            navigateToForYouPage()
        }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                navigateBack()
            }
        })
    }

    override fun onStart() {
        super.onStart()
        if (!onb1ViewLoggedThisVisit) {
            onb1ViewLoggedThisVisit = true
            onb1CompleteLogged = false
            hasNavigated = false
            screenStartTime = System.currentTimeMillis()
            val viewType = if (hasEverViewedOnb1) "revisit" else "first_view"
            hasEverViewedOnb1 = true
            FirebaseEventManager.onb1View(viewType)
        }
    }

    override fun onStop() {
        super.onStop()
        // Leave page → next open can log again (revisit)
        onb1ViewLoggedThisVisit = false
        onb1CompleteLogged = false
    }

    private fun navigateBack() {
        finish()
    }

    private fun navigateToForYouPage() {
        if (hasNavigated) {
            return
        }
        hasNavigated = true

        // Sheet: Next click → onb1_complete (nav_direction "foward" per sheet)
        if (!onb1CompleteLogged && screenStartTime > 0L) {
            onb1CompleteLogged = true
            FirebaseEventManager.onb1Complete(
                screenStartTime,
                "click",
                "foward",
                "onb2"
            )
        }

        startActivity(Intent(this, ForYouPageActivity::class.java))
    }
}
