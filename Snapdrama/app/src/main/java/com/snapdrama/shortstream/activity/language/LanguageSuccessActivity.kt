package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdSuccess
import com.snapdrama.shortstream.applicationPreference.ControlPreference

class LanguageSuccessActivity : BaseOtherActivity() {

    private var hasNavigated = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_language_success)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)

        // Display priority → native-lfo1-2 (lfo1_native_2) — IDs from RC only
        LanguageNativeAdSuccess.adsViewNativeAds = 0
        LanguageNativeAdSuccess.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_LanguageNativeSuccess_Ids_List(),
            linearSmallNtv
        )

        findViewById<android.view.View>(R.id.btnBack).setOnClickListener {
            navigateBack()
        }

        nextButton.setOnClickListener {
            navigateToPreference()
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

    private fun navigateToPreference() {
        if (hasNavigated) {
            return
        }
        hasNavigated = true

        startActivity(
            Intent(this, LanguagePreferenceActivity::class.java)
        )
    }
}
