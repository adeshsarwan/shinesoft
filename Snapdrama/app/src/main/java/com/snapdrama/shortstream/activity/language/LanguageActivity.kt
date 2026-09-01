package com.snapdrama.shortstream.activity.language

import android.content.Intent
import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.OnBackPressedCallback
import androidx.recyclerview.widget.RecyclerView
import com.facebook.shimmer.ShimmerFrameLayout
import com.smsmessenger.chat.Language.Data
import com.smsmessenger.chat.Language.LanguageAdapter
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.FirebaseEventManager
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdFirst
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdLfo2Three
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdLfo2Two
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdOld
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard1TwoNativeAdView
import com.snapdrama.shortstream.applicationPreference.ControlPreference
import kotlin.jvm.java

class LanguageActivity : BaseOtherActivity() {
    lateinit var recyclerViewLanguage: RecyclerView
    lateinit var next: TextView
    lateinit var ivBack: ImageView
    private var showIcon = false
    var languageStartTime: Long = 0
    private var lfo1CompleteLogged = false
    /** Clears when screen stops so return visit can fire lfo1_view / lfo1_complete again */
    private var lfo1ViewLoggedThisVisit = false


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_language)
        FirebaseEventManager.init(this)
        recyclerViewLanguage = findViewById(R.id.recyclerViewLanguage)
        next = findViewById(R.id.tvNext)
        ivBack = findViewById(R.id.btnBack)
        val shimmerNext = findViewById<com.facebook.shimmer.ShimmerFrameLayout>(R.id.shimmerNext)
        if (shimmerNext != null) {
            shimmerNext.setLayerType(View.LAYER_TYPE_SOFTWARE, null)
            shimmerNext.post { shimmerNext.startShimmer() }
        }

        showIcon = intent.getBooleanExtra("LANGUAGE_SCREEN_AVAILABLE", false)
        setBackEvent()
        setRecyclerViewData()
        if (showIcon) {
            ivBack.visibility = View.VISIBLE
            FirebaseEventManager.lfo2View()
        } else {
            ivBack.visibility = View.GONE
        }

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                onBack()
            }
        })

        val container = findViewById<LinearLayout>(R.id.linearSmallNtv)
        if (showIcon) {
            LanguageNativeAdOld.adsViewNativeAds = 0
            LanguageNativeAdOld.displayNativeBottomId(
                this,
                container,
                ControlPreference.get_LanguageNativeOld_Ids_List()
            )
        } else {
            LanguageNativeAdFirst.adsViewNativeAds = 0
            LanguageNativeAdFirst.loadAdmobBigNativeAd(
                this,
                ControlPreference.get_LanguageNative_Ids_List(),
                container
            )

            LanguageNativeAdLfo2Two.adsViewNativeAds = 0
            LanguageNativeAdLfo2Two.loadAdmobBigNativeAd(
                this,
                ControlPreference.get_LanguageNativeLfo2Two_Ids_List(),
                null
            )

            LanguageNativeAdLfo2Three.adsViewNativeAds = 0
            LanguageNativeAdLfo2Three.loadAdmobBigNativeAd(
                this,
                ControlPreference.get_LanguageNativeLfo2Three_Ids_List(),
                null
            )

            OnBoard1TwoNativeAdView.adsViewNativeAds = 0
            OnBoard1TwoNativeAdView.loadAdmobBigNativeAd(
                this,
                ControlPreference.get_OnBoard1TwoNative_Ids_List(),
                null
            )
        }
    }

    override fun onStart() {
        super.onStart()
        // language_1: fire again every time user lands on this screen
        if (!showIcon && !lfo1ViewLoggedThisVisit) {
            lfo1ViewLoggedThisVisit = true
            lfo1CompleteLogged = false
            languageStartTime = System.currentTimeMillis()
            FirebaseEventManager.lfo1View()
            android.util.Log.d("FirebaseEventManager", "lfo1_view (language_1 visit)")
        }
    }

    override fun onStop() {
        super.onStop()
        // Leaving page (Done → next, or Home, or back) → clear so next open can log again
        if (!showIcon) {
            lfo1ViewLoggedThisVisit = false
            lfo1CompleteLogged = false
        }
    }

    private fun setBackEvent() {
        ivBack.setOnClickListener {
            onBack()
        }
    }

    private fun logLfo1CompleteOnce() {
        if (showIcon || lfo1CompleteLogged || languageStartTime <= 0L) return
        lfo1CompleteLogged = true
        FirebaseEventManager.lfo1Complete(languageStartTime)
    }

    private fun setRecyclerViewData() {
        val list = listOf(
            Data("English - ", "(English)", "en", R.drawable.language1),
            Data("Spanish - ", "(Española)", "es", R.drawable.language2),
            Data("Korean - ", "(한국인)", "ko", R.drawable.language9),
            Data("French - ", "(Français)", "fr", R.drawable.language3),
            Data("German - ", "(Deutsch)", "de", R.drawable.language4),
            Data("Hindi - ", "(हिंदी)", "hi", R.drawable.language5),
            Data("Russian - ", "(Русский)", "ru", R.drawable.language6),
            Data("Italian - ", "(Italiana)", "it", R.drawable.language7),
            Data("Japanese - ", "(日本語)", "ja", R.drawable.language8),
            Data("Chinese - ", "(中国人)", "zh", R.drawable.language10),
            Data("Greek - ", "(ελληνικά)", "el", R.drawable.language11),
            Data("Danish - ", "(Dansk)", "da", R.drawable.language12),
            Data("Thai - ", "(แบบไทย)", "th", R.drawable.language19),
            Data("Swedish - ", "(Svenska)", "sv", R.drawable.language18),
            Data("Turkish - ", "(Türkçe)", "tr", R.drawable.language24),
            Data("Ukrainian - ", "(українська)", "uk", R.drawable.language25),
            Data("Vietnamese - ", "(Tiếng Việt)", "vi", R.drawable.language26),
        )

        var selectedLanguageCode = ControlPreference.getAppLanguage()

        recyclerViewLanguage.adapter =
            LanguageAdapter(this, list, showIcon, object : LanguageAdapter.SetOnClick {
                override fun onClickItem(position: Int, view: ImageView) {
                    selectedLanguageCode = list[position].code
                    logLfo1CompleteOnce()
                }
            })

        next.setOnClickListener {
            ControlPreference.setAppLanguage(selectedLanguageCode)
            setLocale(selectedLanguageCode)
            if (showIcon) {
                val resultIntent = Intent()
                setResult(RESULT_OK, resultIntent)
                FirebaseEventManager.lfo2Complete(languageStartTime)
                finish()
            } else {
                logLfo1CompleteOnce()
                startActivity(Intent(this, LanguageSuccessActivity::class.java))
            }
        }
    }

    fun onBack() {
        if (showIcon) {
            finish()
            return
        }
        finishAffinity()
    }
}