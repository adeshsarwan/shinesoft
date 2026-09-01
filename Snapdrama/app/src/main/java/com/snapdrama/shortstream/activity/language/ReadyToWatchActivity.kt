package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.login.LoginMainActivity
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard4NativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard4TwoNativeAdView
import com.snapdrama.shortstream.applicationPreference.ControlPreference

class ReadyToWatchActivity : BaseOtherActivity() {

    private var hasNavigated = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_ready_to_watch)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)

        // Display priority → native-ob4-1 (onboard_4_native) — IDs from RC only
        OnBoard4NativeAdView.adsViewNativeAds = 0
        OnBoard4NativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard4Native_Ids_List(),
            linearSmallNtv
        )

        // Preload → native-ob4-2 for Login
        OnBoard4TwoNativeAdView.adsViewNativeAds = 0
        OnBoard4TwoNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard4TwoNative_Ids_List(),
            null
        )

        findViewById<android.view.View>(R.id.btnBack).setOnClickListener {
            navigateBack()
        }

        nextButton.setOnClickListener {
            navigateToLogin()
        }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                navigateBack()
            }
        })
    }

    private fun navigateBack() {
        finish()
    }

    private fun navigateToLogin() {
        if (hasNavigated) return
        hasNavigated = true

        ControlPreference.setLanguageScreen(true)
        startActivity(
            Intent(this, LoginMainActivity::class.java)
                .putExtra("LoginFirstTime", true)
                .putExtra("ForWardScreenName", "ReadyToWatchActivity")
        )
    }
}
