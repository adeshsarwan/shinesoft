package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.FirebaseEventManager
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard3ThreeNativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard3TwoNativeAdView
import com.snapdrama.shortstream.applicationPreference.ControlPreference

/** Sheet screen: onboard_4 → My Profile tutorial */
class PlayerFeaturesActivity : BaseOtherActivity() {

    companion object {
        private var hasEverViewedOnb4 = false
    }

    private var hasNavigated = false
    private var screenStartTime = 0L
    private var onb4ViewLoggedThisVisit = false
    private var onb4CompleteLogged = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_player_features)
        FirebaseEventManager.init(this)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)

        // Display priority → native-ob3-2 (onboard_3_native_2) — IDs from RC only
        OnBoard3TwoNativeAdView.adsViewNativeAds = 0
        OnBoard3TwoNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard3TwoNative_Ids_List(),
            linearSmallNtv
        )

        // Preload → native-ob3-3 for You're All Set
        OnBoard3ThreeNativeAdView.adsViewNativeAds = 0
        OnBoard3ThreeNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard3ThreeNative_Ids_List(),
            null
        )

        findViewById<android.view.View>(R.id.btnBack).setOnClickListener {
            navigateBack()
        }

        nextButton.setOnClickListener {
            navigateNext()
        }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                navigateBack()
            }
        })
    }

    override fun onStart() {
        super.onStart()
        if (!onb4ViewLoggedThisVisit) {
            onb4ViewLoggedThisVisit = true
            onb4CompleteLogged = false
            hasNavigated = false
            screenStartTime = System.currentTimeMillis()
            val viewType = if (hasEverViewedOnb4) "revisit" else "first_view"
            hasEverViewedOnb4 = true
            FirebaseEventManager.onb4View(viewType)
        }
    }

    override fun onStop() {
        super.onStop()
        onb4ViewLoggedThisVisit = false
        onb4CompleteLogged = false
    }

    private fun logCompleteOnce(actionMethod: String, navDirection: String, toScreen: String) {
        if (onb4CompleteLogged || screenStartTime <= 0L) return
        onb4CompleteLogged = true
        FirebaseEventManager.onb4Complete(
            screenStartTime,
            actionMethod,
            navDirection,
            toScreen
        )
    }

    private fun navigateBack() {
        // Sheet: backward → onb3
        logCompleteOnce("click", "backward", "onb3")
        finish()
    }

    private fun navigateNext() {
        if (hasNavigated) return
        hasNavigated = true
        // Sheet: Next / Get Started → foward → next_screen
        logCompleteOnce("click", "foward", "next_screen")
        startActivity(Intent(this, YoureAllSetActivity::class.java))
    }
}
