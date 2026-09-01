package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.FirebaseEventManager
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard2TwoNativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard3NativeAdView
import com.snapdrama.shortstream.applicationPreference.ControlPreference

/** Sheet screen: onboard_2 → For You player tutorial */
class ForYouPageActivity : BaseOtherActivity() {

    companion object {
        private var hasEverViewedOnb2 = false
    }

    private var hasNavigated = false
    private var screenStartTime = 0L
    private var onb2ViewLoggedThisVisit = false
    private var onb2CompleteLogged = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_for_you_page)
        FirebaseEventManager.init(this)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)

        // Display priority → native-ob2-2 (onboard_2_native_2) — IDs from RC only
        OnBoard2TwoNativeAdView.adsViewNativeAds = 0
        OnBoard2TwoNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard2TwoNative_Ids_List(),
            linearSmallNtv
        )

        // Preload → native-ob3-1 for My List
        OnBoard3NativeAdView.adsViewNativeAds = 0
        OnBoard3NativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard3Native_Ids_List(),
            null
        )

        findViewById<android.view.View>(R.id.btnBack).setOnClickListener {
            navigateBack()
        }

        nextButton.setOnClickListener {
            navigateForward()
        }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                navigateBack()
            }
        })
    }

    override fun onStart() {
        super.onStart()
        if (!onb2ViewLoggedThisVisit) {
            onb2ViewLoggedThisVisit = true
            onb2CompleteLogged = false
            hasNavigated = false
            screenStartTime = System.currentTimeMillis()
            val viewType = if (hasEverViewedOnb2) "revisit" else "first_view"
            hasEverViewedOnb2 = true
            FirebaseEventManager.onb2View(viewType)
        }
    }

    override fun onStop() {
        super.onStop()
        onb2ViewLoggedThisVisit = false
        onb2CompleteLogged = false
    }

    private fun logCompleteOnce(actionMethod: String, navDirection: String, toScreen: String) {
        if (onb2CompleteLogged || screenStartTime <= 0L) return
        onb2CompleteLogged = true
        FirebaseEventManager.onb2Complete(
            screenStartTime,
            actionMethod,
            navDirection,
            toScreen
        )
    }

    private fun navigateBack() {
        // Sheet: backward → onb1
        logCompleteOnce("click", "backward", "onb1")
        finish()
    }

    private fun navigateForward() {
        if (hasNavigated) {
            return
        }
        hasNavigated = true

        // Sheet: Next → foward → onb3 (My List onboarding)
        logCompleteOnce("click", "foward", "onb3")
        startActivity(Intent(this, OnboardingMyListActivity::class.java))
    }
}
