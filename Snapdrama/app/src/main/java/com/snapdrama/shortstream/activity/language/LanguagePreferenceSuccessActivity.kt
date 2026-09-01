package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdLfo2Three
import com.snapdrama.shortstream.applicationPreference.ControlPreference

class LanguagePreferenceSuccessActivity : BaseOtherActivity() {

    private var hasNavigated = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_language_preference_success)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)
        val savedText = findViewById<TextView>(R.id.tvLanguagePreferencesSaved)

        // Black shadow only (XML shadow often clipped / ignored on MIUI)
        savedText.setLayerType(View.LAYER_TYPE_SOFTWARE, null)
        savedText.setShadowLayer(6f, 1.5f, 2.5f, Color.BLACK)

        // Display priority (fallback): native-lfo2-3 → native-lfo2-2 — IDs from RC only
        LanguageNativeAdLfo2Three.adsViewNativeAds = 0
        val lfo23Ids = mutableListOf<String>()
        ControlPreference.get_LanguageNativeLfo2Three_Ids_List()
            ?.takeIf { it.isNotEmpty() }
            ?.let { lfo23Ids.addAll(it) }
        ControlPreference.get_LanguageNativeLfo2Two_Ids_List()
            ?.firstOrNull()
            ?.let { if (!lfo23Ids.contains(it)) lfo23Ids.add(it) }
        LanguageNativeAdLfo2Three.loadAdmobBigNativeAd(this, lfo23Ids, linearSmallNtv)

        findViewById<View>(R.id.btnBack).setOnClickListener {
            navigateBack()
        }

        nextButton.setOnClickListener {
            navigateToContentPreference()
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

    private fun navigateToContentPreference() {
        if (hasNavigated) {
            return
        }
        hasNavigated = true

        startActivity(Intent(this, ContentPreferenceActivity::class.java))
    }
}
