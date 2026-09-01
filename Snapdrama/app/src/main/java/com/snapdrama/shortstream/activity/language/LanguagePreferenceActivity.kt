package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdOld
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard2NativeAdView
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard3NativeAdView
import com.snapdrama.shortstream.applicationPreference.ControlPreference

class LanguagePreferenceActivity : BaseOtherActivity() {

    private var hasNavigated = false
    private val languageCards = mutableListOf<View>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_language_preference)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)

        // Display priority → native-lfo2-1 (lfo2_native) — IDs from RC only
        LanguageNativeAdOld.adsViewNativeAds = 0
        LanguageNativeAdOld.displayNativeBottomId(
            this,
            linearSmallNtv,
            ControlPreference.get_LanguageNativeOld_Ids_List()
        )

        // Preload 1 → native-ob2-1 (onboard_2_native)
        OnBoard2NativeAdView.adsViewNativeAds = 0
        OnBoard2NativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard2Native_Ids_List(),
            null
        )

        // Preload 1 → native-ob3-1 (onboard_3_native)
        OnBoard3NativeAdView.adsViewNativeAds = 0
        OnBoard3NativeAdView.loadAdmobBigNativeAd(
            this,
            ControlPreference.get_OnBoard3Native_Ids_List(),
            null
        )

        bindLanguageCard(
            cardId = R.id.cardEnglish,
            nameRes = R.string.english,
            imageRes = R.drawable.english_image
        )
        bindLanguageCard(
            cardId = R.id.cardKorean,
            nameRes = R.string.korean,
            imageRes = R.drawable.korean_image
        )
        bindLanguageCard(
            cardId = R.id.cardChinese,
            nameRes = R.string.chinese,
            imageRes = R.drawable.chinese_image
        )
        bindLanguageCard(
            cardId = R.id.cardJapanese,
            nameRes = R.string.japanese,
            imageRes = R.drawable.japanese_image
        )

        findViewById<android.view.View>(R.id.btnBack).setOnClickListener {
            navigateBack()
        }

        nextButton.setOnClickListener {
            navigateToMoreLanguages()
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

    private fun bindLanguageCard(cardId: Int, nameRes: Int, imageRes: Int) {
        val card = findViewById<View>(cardId)
        val image = card.findViewById<ImageView>(R.id.imageLanguage)
        val check = card.findViewById<ImageView>(R.id.checkLanguage)
        val name = card.findViewById<TextView>(R.id.tvLanguageName)

        name.setText(nameRes)
        image.setImageResource(imageRes)

        card.isSelected = false
        updateCardSelection(card, check)

        card.setOnClickListener {
            card.isSelected = !card.isSelected
            updateCardSelection(card, check)
        }

        languageCards += card
    }

    private fun updateCardSelection(card: View, check: ImageView) {
        if (card.isSelected) {
            card.setBackgroundResource(R.drawable.bg_language_interest_selected)
            check.setImageResource(R.drawable.ic_language_pref_check)
        } else {
            card.setBackgroundResource(R.drawable.bg_language_interest_unselected)
            check.setImageResource(R.drawable.ic_language_pref_uncheck)
        }
    }

    private fun navigateToMoreLanguages() {
        if (hasNavigated) {
            return
        }

        if (languageCards.none { it.isSelected }) {
            Toast.makeText(
                this,
                getString(R.string.please_select_at_least_one_language),
                Toast.LENGTH_SHORT
            ).show()
            return
        }

        hasNavigated = true

        startActivity(Intent(this, LanguageMoreActivity::class.java))
    }
}
