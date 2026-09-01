package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.FirebaseEventManager
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard3NativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard3TwoNativeAdView
import com.snapdrama.shortstream.applicationPreference.ControlPreference

/** Sheet screen: onboard_3 → My List / History tutorial */
class OnboardingMyListActivity : BaseOtherActivity() {

    companion object {
        private var hasEverViewedOnb3 = false
    }

    private var hasNavigated = false
    private var screenStartTime = 0L
    private var onb3ViewLoggedThisVisit = false
    private var onb3CompleteLogged = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_onboarding_my_list)
        FirebaseEventManager.init(this)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)

        // Display priority → native-ob3-1 (onboard_3_native) — IDs from RC only
        OnBoard3NativeAdView.adsViewNativeAds = 0
        OnBoard3NativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard3Native_Ids_List(),
            linearSmallNtv
        )

        // Preload → native-ob3-2 for Player Features
        OnBoard3TwoNativeAdView.adsViewNativeAds = 0
        OnBoard3TwoNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard3TwoNative_Ids_List(),
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
        if (!onb3ViewLoggedThisVisit) {
            onb3ViewLoggedThisVisit = true
            onb3CompleteLogged = false
            hasNavigated = false
            screenStartTime = System.currentTimeMillis()
            val viewType = if (hasEverViewedOnb3) "revisit" else "first_view"
            hasEverViewedOnb3 = true
            FirebaseEventManager.onb3View(viewType)
        }
    }

    override fun onStop() {
        super.onStop()
        onb3ViewLoggedThisVisit = false
        onb3CompleteLogged = false
    }

    private fun logCompleteOnce(actionMethod: String, navDirection: String, toScreen: String) {
        if (onb3CompleteLogged || screenStartTime <= 0L) return
        onb3CompleteLogged = true
        FirebaseEventManager.onb3Complete(
            screenStartTime,
            actionMethod,
            navDirection,
            toScreen
        )
    }

    private fun navigateBack() {
        // Sheet: backward → onb2
        logCompleteOnce("click", "backward", "onb2")
        finish()
    }

    private fun navigateNext() {
        if (hasNavigated) return
        hasNavigated = true
        // Sheet: Next → foward → onb4 (Player Features)
        logCompleteOnce("click", "foward", "onb4")
        startActivity(Intent(this, PlayerFeaturesActivity::class.java))
    }
}
