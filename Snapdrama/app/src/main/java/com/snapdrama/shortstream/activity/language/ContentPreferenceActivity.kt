package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard1TwoNativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard2TwoNativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard3TwoNativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoardNativeAdView
import com.snapdrama.shortstream.applicationPreference.ControlPreference

class ContentPreferenceActivity : BaseOtherActivity() {

    private var hasNavigated = false
    private lateinit var chips: List<TextView>

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_content_preference)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)

        // Display priority → native-ob1-1 (onboard_1_native) — IDs from RC only
        OnBoardNativeAdView.adsViewNativeAds = 0
        OnBoardNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard1Native_Ids_List(),
            linearSmallNtv
        )

        // Preload → native-ob1-2 (onboard_1_native_2) for Content Preferences Saved
        OnBoard1TwoNativeAdView.adsViewNativeAds = 0
        OnBoard1TwoNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard1TwoNative_Ids_List(),
            null
        )

        // Preload 1 → native-ob2-2 (onboard_2_native_2)
        OnBoard2TwoNativeAdView.adsViewNativeAds = 0
        OnBoard2TwoNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard2TwoNative_Ids_List(),
            null
        )

        // Preload 1 → native-ob3-2 (onboard_3_native_2)
        OnBoard3TwoNativeAdView.adsViewNativeAds = 0
        OnBoard3TwoNativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard3TwoNative_Ids_List(),
            null
        )

        findViewById<android.view.View>(R.id.btnBack).setOnClickListener {
            navigateBack()
        }

        chips = listOf(
            findViewById(R.id.chipRomance),
            findViewById(R.id.chipBillionaire),
            findViewById(R.id.chipRevenge),
            findViewById(R.id.chipFantasy),
            findViewById(R.id.chipMarriage),
            findViewById(R.id.chipCampus),
            findViewById(R.id.chipTimeTravel),
            findViewById(R.id.chipMafia)
        )

        chips.forEach { chip ->
            chip.setOnClickListener {
                chip.isSelected = !chip.isSelected
                updateChipSelection(chip)
            }
        }

        chips.first().isSelected = true
        updateChipSelection(chips.first())

        nextButton.setOnClickListener {
            navigateToPreferencesSaved()
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

    private fun updateChipSelection(chip: TextView) {
        if (chip.isSelected) {
            chip.setBackgroundResource(R.drawable.bg_content_category_selected)
        } else {
            chip.setBackgroundResource(R.drawable.bg_content_category_unselected)
        }
    }

    private fun navigateToPreferencesSaved() {
        if (hasNavigated) {
            return
        }

        if (chips.none { it.isSelected }) {
            Toast.makeText(
                this,
                getString(R.string.please_select_at_least_one_category),
                Toast.LENGTH_SHORT
            ).show()
            return
        }

        hasNavigated = true

        startActivity(Intent(this, PreferencesSavedActivity::class.java))
    }
}
