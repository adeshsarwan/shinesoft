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
import com.snapdrama.shortstream.ads.FirebaseEventManager
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdLfo2Two
import com.snapdrama.shortstream.applicationPreference.ControlPreference

class LanguageMoreActivity : BaseOtherActivity() {

    private var hasNavigated = false
    private var screenStartTime = 0L
    private var lfo2ViewLoggedThisVisit = false
    private var lfo2CompleteLogged = false
    private val languageCards = mutableListOf<View>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_language_more)
        FirebaseEventManager.init(this)

        val linearSmallNtv = findViewById<LinearLayout>(R.id.linearSmallNtv)
        val nextButton = findViewById<TextView>(R.id.tvNext)
        val backButton = findViewById<ImageView>(R.id.btnBack)

        // Display priority (fallback): native-lfo2-2 → native-lfo2-3 — IDs from RC only
        LanguageNativeAdLfo2Two.adsViewNativeAds = 0
        val lfo22Ids = mutableListOf<String>()
        ControlPreference.get_LanguageNativeLfo2Two_Ids_List()
            ?.takeIf { it.isNotEmpty() }
            ?.let { lfo22Ids.addAll(it) }
        ControlPreference.get_LanguageNativeLfo2Three_Ids_List()
            ?.firstOrNull()
            ?.let { if (!lfo22Ids.contains(it)) lfo22Ids.add(it) }
        LanguageNativeAdLfo2Two.loadAdmobBigNativeAd(this, lfo22Ids, linearSmallNtv)

        bindLanguageCard(
            cardId = R.id.cardSpanish,
            nameRes = R.string.spanish,
            imageRes = R.drawable.spanish_image
        )
        bindLanguageCard(
            cardId = R.id.cardItalian,
            nameRes = R.string.italian,
            imageRes = R.drawable.italian_image
        )
        bindLanguageCard(
            cardId = R.id.cardGerman,
            nameRes = R.string.german,
            imageRes = R.drawable.german_image
        )
        bindLanguageCard(
            cardId = R.id.cardFrench,
            nameRes = R.string.french,
            imageRes = R.drawable.french_image
        )

        backButton.setOnClickListener {
            navigateBack()
        }

        // Sheet: Confirm = Next on this screen
        nextButton.setOnClickListener {
            navigateToSuccess()
        }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                navigateBack()
            }
        })
    }

    override fun onStart() {
        super.onStart()
        // language_2 → lfo2_view when user views this screen
        if (!lfo2ViewLoggedThisVisit) {
            lfo2ViewLoggedThisVisit = true
            lfo2CompleteLogged = false
            screenStartTime = System.currentTimeMillis()
            FirebaseEventManager.lfo2View()
            android.util.Log.d("FirebaseEventManager", "lfo2_view (language_2 / Add More Languages)")
        }
    }

    override fun onStop() {
        super.onStop()
        // Leave page → clear so return visit can fire events again
        lfo2ViewLoggedThisVisit = false
        lfo2CompleteLogged = false
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

    private fun navigateToSuccess() {
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

        // Sheet: lfo2_complete when Confirm/Next is clicked
        if (!lfo2CompleteLogged && screenStartTime > 0L) {
            lfo2CompleteLogged = true
            FirebaseEventManager.lfo2Complete(screenStartTime)
        }

        startActivity(Intent(this, LanguagePreferenceSuccessActivity::class.java))
    }
}
