package com.snapdrama.shortstream.activity.main.base

import android.content.Context
import android.content.pm.PackageManager
import android.graphics.Color
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import com.android.volley.Request
import com.android.volley.toolbox.JsonObjectRequest
import com.android.volley.toolbox.Volley
import com.google.firebase.analytics.FirebaseAnalytics
import com.google.firebase.remoteconfig.FirebaseRemoteConfig
import com.google.firebase.remoteconfig.FirebaseRemoteConfigSettings
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.ads.FirebaseEventManager
import com.snapdrama.shortstream.ads.ManegeUtilsView
import com.snapdrama.shortstream.ads.PremiumPlanManager
import com.snapdrama.shortstream.ads.SystemService
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdFirst
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdOld
import com.snapdrama.shortstream.ads.adsMenu.Language.LanguageNativeAdSuccess
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoardNativeAdView
import com.snapdrama.shortstream.ads.adsMenu.Splash.AppOpenBackGroundAd
import com.snapdrama.shortstream.ads.adsMenu.Splash.SplashInterMange
import com.snapdrama.shortstream.ads.adsMenu.Splash.SplashNativeAdView
import com.snapdrama.shortstream.applicationPreference.ControlPreference
import com.snapdrama.shortstream.databinding.ActivitySplashScreenBinding
import com.snapdrama.shortstream.engineBox.client.ApiConfig
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

abstract class BaseActivity : AppCompatActivity() {
    var splashStartTime: Long = 0

    private lateinit var firebaseRemoteConfig: FirebaseRemoteConfig
    abstract fun initActivity()
    var buildSignature: String = ""
    var splashNativeAdId: String = ""
    var anInt: Int = 0

    private var hasStartedAppFlow = false
    private var hasNavigatedFromSplash = false
    private var splashNativeReady = false
    private var splashPremiumReady = false
    private var splashFullscreenStarted = false

    var splashNativeList: MutableList<String?> = ArrayList<String?>()
    var splashNativeOldList: MutableList<String?> = ArrayList<String?>()

    var languageNativeList: MutableList<String?> = ArrayList<String?>()
    var languageNativeSuccessList: MutableList<String?> = ArrayList<String?>()
    var languageNativeOldList: MutableList<String?> = ArrayList<String?>()
    var languageNativeLfo2TwoList: MutableList<String?> = ArrayList<String?>()
    var languageNativeLfo2ThreeList: MutableList<String?> = ArrayList<String?>()
    var onboard1NativeList: MutableList<String?> = ArrayList<String?>()
    var onboard1TwoNativeList: MutableList<String?> = ArrayList<String?>()
    var onboard2NativeList: MutableList<String?> = ArrayList<String?>()
    var onboard2TwoNativeList: MutableList<String?> = ArrayList<String?>()
    var onboard3NativeList: MutableList<String?> = ArrayList<String?>()
    var onboard3TwoNativeList: MutableList<String?> = ArrayList<String?>()
    var onboard3ThreeNativeList: MutableList<String?> = ArrayList<String?>()
    var onboard4NativeList: MutableList<String?> = ArrayList<String?>()
    var onboard4TwoNativeList: MutableList<String?> = ArrayList<String?>()
    var interOnboardList: MutableList<String?> = ArrayList<String?>()

    var splashInterList: MutableList<String?> = ArrayList<String?>()
    var splashInterOldList: MutableList<String?> = ArrayList<String?>()

    var appOpenList: MutableList<String?> = ArrayList<String?>()
    var nativeList: MutableList<String?> = ArrayList<String?>()
    var interList: MutableList<String?> = ArrayList<String?>()
    var bannerList: MutableList<String?> = ArrayList<String?>()
    var rewardList: MutableList<String?> = ArrayList<String?>()

    protected lateinit var binding: ActivitySplashScreenBinding
//    abstract fun getViewBinding(): ActivitySplashScreenBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
//        binding = getViewBinding()
        binding = ActivitySplashScreenBinding.inflate(getLayoutInflater())

        setContentView(binding.root)
        splashStartTime = System.currentTimeMillis()

        FirebaseEventManager.init(this)
        FirebaseEventManager.splashView()

        makeFullScreenImmersive()
        applyBottomInsetForNativeAd()

    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            makeFullScreenImmersive()
        }
    }

    override fun onResume() {
        super.onResume()
        makeFullScreenImmersive()

        if (hasNavigatedFromSplash) {
            return
        }

        if (SystemService.checkNetwork(this)) {
            setupFirebaseConfig()
        } else {
            showNoInternetConnection()
        }
    }
    private fun showNoInternetConnection() {
        SystemService.displayNoInternetDialog(this)
        SystemService.checkNetworkAvailability(object : SystemService.no_internet {
            public override fun no_internet() {
                if (SystemService.checkNetwork(this@BaseActivity)) {
                    SystemService.noInternetDialog.dismiss()
                    setupFirebaseConfig()
                }
            }
        })
    }

    fun restoreFullScreenImmersive() {
        makeFullScreenImmersive()
        binding.root.requestApplyInsets()
    }

    private fun makeFullScreenImmersive() {
        anInt = getVCode(this)
        WindowCompat.setDecorFitsSystemWindows(window, false)

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            @Suppress("deprecation")
            val flags =
                View.SYSTEM_UI_FLAG_FULLSCREEN or
                        View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                        View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or
                        View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
                        View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION or
                        View.SYSTEM_UI_FLAG_LAYOUT_STABLE

            window.decorView.systemUiVisibility = flags
            @Suppress("deprecation")
            window.decorView.setOnSystemUiVisibilityChangeListener { visibility ->
                if (visibility and View.SYSTEM_UI_FLAG_FULLSCREEN == 0) {
                    window.decorView.systemUiVisibility = flags
                }
            }
        }

        window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        window.addFlags(WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS)

        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val controller = window.insetsController

            controller?.let {
                it.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())

                it.systemBarsBehavior =
                    WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        }
    }

    private fun applyBottomInsetForNativeAd() {
        binding.linearSmallBanner.setOnApplyWindowInsetsListener { view, insets ->
            val navInsets = insets.getInsets(WindowInsets.Type.navigationBars())
            view.setPadding(
                view.paddingLeft,
                view.paddingTop,
                view.paddingRight,
                navInsets.bottom
            )
            insets
        }
    }


    private fun setupFirebaseConfig() {
        ManegeUtilsView.isUtilsManege(this)
        firebaseRemoteConfig = FirebaseRemoteConfig.getInstance()

        val configSettings = FirebaseRemoteConfigSettings.Builder()
            .setMinimumFetchIntervalInSeconds(0)
            .build()

        firebaseRemoteConfig.setConfigSettingsAsync(configSettings)
        firebaseRemoteConfig.setDefaultsAsync(R.xml.firebase_default_config)

        firebaseRemoteConfig.fetchAndActivate()
            .addOnCompleteListener {

                if (it.isSuccessful) {
                    buildSignature = ApiConfig.ssfsfsfsf + anInt
                    setAdIdsFromRemote()

                } else {
                    Toast.makeText(
                        this,
                        getString(R.string.something_went_wrong),
                        Toast.LENGTH_SHORT
                    ).show()

                }

                startAppFlow()
            }.addOnFailureListener {
            }
    }

    private fun startAppFlow() {
        if (hasStartedAppFlow || hasNavigatedFromSplash) {
            return
        }
        hasStartedAppFlow = true
        splashNativeReady = false
        splashPremiumReady = false
        splashFullscreenStarted = false

        val isNewUser = ControlPreference.get_in_splash_first_time()
        val splashNativeIds = if (isNewUser) {
            ControlPreference.get_SplashNative_Ids_List()
        } else {
            ControlPreference.get_SplashNativeOld_Ids_List()
        }

        // Display splash native first; interstitial waits until native finishes
        SplashNativeAdView.adsViewNativeAds = 0
        SplashNativeAdView.loadAdmobBigNativeAd(
            this,
            splashNativeIds,
            binding.shimmerAdsLayout,
            binding.linearSmallNtv,
            object : SplashNativeAdView.OnNativeLoadComplete {
                override fun onComplete(loaded: Boolean) {
                    splashNativeReady = true
                    maybeShowSplashFullscreen()
                }
            }
        )

        if (isNewUser) {
            SplashInterMange.preload(this, ControlPreference.get_SplashInter_Ids_List())
            LanguageNativeAdFirst.loadAdmobBigNativeAd(
                this,
                ControlPreference.get_LanguageNative_Ids_List(),
                null
            )
            LanguageNativeAdOld.loadAdmobBigNativeAd(
                this,
                ControlPreference.get_LanguageNativeOld_Ids_List(),
                null
            )
            OnBoardNativeAdView.loadAdmobBigNativeAd(
                this,
                ControlPreference.get_OnBoard1Native_Ids_List(),
                null
            )
        } else {
            SplashInterMange.preload(this, ControlPreference.get_SplashInterOld_Ids_List())
        }

        fetchIpDetails(this) {
            PremiumPlanManager.refreshPremiumFromFirestore(this) {
                splashPremiumReady = true
                maybeShowSplashFullscreen()
            }
        }
    }

    /** Interstitial / AppOpen only after splash native finishes (success or fail). */
    private fun maybeShowSplashFullscreen() {
        if (!splashNativeReady || !splashPremiumReady || splashFullscreenStarted || hasNavigatedFromSplash) {
            return
        }
        splashFullscreenStarted = true
        // Splash screen done → next is interstitial/AppOpen
        FirebaseEventManager.splashComplete(splashStartTime)
        showAppOpenAd()
    }

    private fun setAdIdsFromRemote() {

        try {
            val jsonString = firebaseRemoteConfig.getString(buildSignature)
            if (jsonString.isBlank()) {
                android.util.Log.e("BaseActivity", "Remote Config empty for key=$buildSignature")
                return
            }
            val root = JSONObject(jsonString)
            FirebaseAnalytics.getInstance(this).setAnalyticsCollectionEnabled(true)

            // Clear so RC parse never appends onto old values
            splashNativeList.clear()
            splashNativeOldList.clear()
            languageNativeList.clear()
            languageNativeSuccessList.clear()
            languageNativeOldList.clear()
            languageNativeLfo2TwoList.clear()
            languageNativeLfo2ThreeList.clear()
            onboard1NativeList.clear()
            onboard1TwoNativeList.clear()
            onboard2NativeList.clear()
            onboard2TwoNativeList.clear()
            onboard3NativeList.clear()
            onboard3TwoNativeList.clear()
            onboard3ThreeNativeList.clear()
            onboard4NativeList.clear()
            onboard4TwoNativeList.clear()
            interOnboardList.clear()
            splashInterList.clear()
            splashInterOldList.clear()
            appOpenList.clear()
            nativeList.clear()
            interList.clear()
            bannerList.clear()
            rewardList.clear()

            // test_id=true → Google test units; false → live AdMob units
            val useTestAds = root.optBoolean("test_id", false)
            ControlPreference.setTestIdAds(useTestAds)
            val publisher_ad_units_manage = if (useTestAds) {
                root.optJSONObject(ControlPreference.PUBLISHER_AD_UNITS_MANGE_TEST)
                    ?: root.getJSONObject(ControlPreference.PUBLISHER_AD_UNITS_MANGE)
            } else {
                root.getJSONObject(ControlPreference.PUBLISHER_AD_UNITS_MANGE)
            }
            android.util.Log.d(
                "BaseActivity",
                "ads mode test_id=$useTestAds key=${if (useTestAds) ControlPreference.PUBLISHER_AD_UNITS_MANGE_TEST else ControlPreference.PUBLISHER_AD_UNITS_MANGE}"
            )

            val homeNewNativeAdsPosition = publisher_ad_units_manage.getInt(ControlPreference.HOME_NEW_NATIVE_ADS_POSITION)
            ControlPreference.set_Home_New_Ads_Position(homeNewNativeAdsPosition)

            val homeRankingNativeAdsPosition = publisher_ad_units_manage.getInt(ControlPreference.HOME_RANKING_NATIVE_ADS_POSITION)
            ControlPreference.set_Home_Ranking_Ads_Position(homeRankingNativeAdsPosition)

            ControlPreference.set_Splash_ads_show_type(
                publisher_ad_units_manage.getString("splash_ads_show_type")
            )
//////////// Splash Native
            try {
                val splashNative: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.SPLASH_NATIVE_ADS_ID_LIST)
                for (i in 0..<splashNative.length()) {
                    val Splash_Native_Id = splashNative.getString(i)
                    splashNativeList.add(Splash_Native_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_SplashNative_Ids_List(splashNativeList)

//////////// Splash Native Old
            try {
                val splashNativeOld: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.SPLASH_NATIVE_OLD_ADS_ID_LIST)
                for (i in 0..<splashNativeOld.length()) {
                    val Splash_Native_Old_Id = splashNativeOld.getString(i)
                    splashNativeOldList.add(Splash_Native_Old_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_SplashNativeOld_Ids_List(splashNativeOldList)

//////////// Splash Inter
            try {
                val splashInter: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.SPLASH_INTER_ADS_ID_LIST)
                for (i in 0..<splashInter.length()) {
                    val Splash_Inter_Id = splashInter.getString(i)
                    splashInterList.add(Splash_Inter_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_SplashInter_Ids_List(splashInterList)

//////////// Splash Inter Old
            try {
                val splashInterOld: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.SPLASH_INTER_OLD_ADS_ID_LIST)
                for (i in 0..<splashInterOld.length()) {
                    val Splash_Inter_Old_Id = splashInterOld.getString(i)
                    splashInterOldList.add(Splash_Inter_Old_Id)
//                    Log.d("TAG", "setAdIdsFromRemote: " + splashInterOld)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_SplashInterOld_Ids_List(splashInterOldList)

//////////// Language Native
            try {
                val languageNative: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.LANGUAGE_NATIVE_ADS_ID_LIST)
                for (i in 0..<languageNative.length()) {
                    val Language_Native_Id = languageNative.getString(i)
                    languageNativeList.add(Language_Native_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_LanguageNative_Ids_List(languageNativeList)

//////////// Language Success Native (lfo1_native_2)
            try {
                val languageNativeSuccess: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.LANGUAGE_NATIVE_SUCCESS_ADS_ID_LIST)
                for (i in 0..<languageNativeSuccess.length()) {
                    val languageNativeSuccessId = languageNativeSuccess.getString(i)
                    languageNativeSuccessList.add(languageNativeSuccessId)
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_LanguageNativeSuccess_Ids_List(languageNativeSuccessList)

//////////// Language Native Old
            try {
                val languageNativeOld: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.LANGUAGE_NATIVE_OLD_ADS_ID_LIST)
                for (i in 0..<languageNativeOld.length()) {
                    val Language_Native_Old_Id = languageNativeOld.getString(i)
                    languageNativeOldList.add(Language_Native_Old_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_LanguageNativeOld_Ids_List(languageNativeOldList)

//////////// Language LFO2-2 (Add More Languages display)
            try {
                val languageNativeLfo2Two: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.LANGUAGE_NATIVE_LFO2_TWO_ADS_ID_LIST)
                for (i in 0..<languageNativeLfo2Two.length()) {
                    languageNativeLfo2TwoList.add(languageNativeLfo2Two.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_LanguageNativeLfo2Two_Ids_List(languageNativeLfo2TwoList)

//////////// Language LFO2-3 (Language Preferences Saved display)
            try {
                val languageNativeLfo2Three: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.LANGUAGE_NATIVE_LFO2_THREE_ADS_ID_LIST)
                for (i in 0..<languageNativeLfo2Three.length()) {
                    languageNativeLfo2ThreeList.add(languageNativeLfo2Three.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_LanguageNativeLfo2Three_Ids_List(languageNativeLfo2ThreeList)

//////////// Language Native Old
            try {
                val onboard1NativeOld: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.ONBOARD1_NATIVE_OLD_ADS_ID_LIST)
                for (i in 0..<onboard1NativeOld.length()) {
                    val OnBoard_Native_Old_Id = onboard1NativeOld.getString(i)
                    onboard1NativeList.add(OnBoard_Native_Old_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_OnBoard1Native_Ids_List(onboard1NativeList)

//////////// Onboard 1 Native 2 (native-ob1-2)
            try {
                val onboard1TwoNative: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.ONBOARD1_NATIVE_TWO_ADS_ID_LIST)
                for (i in 0..<onboard1TwoNative.length()) {
                    onboard1TwoNativeList.add(onboard1TwoNative.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_OnBoard1TwoNative_Ids_List(onboard1TwoNativeList)

//////////// Onboard 2 Native
            try {
                val onboard2Native: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.ONBOARD2_NATIVE_ADS_ID_LIST)
                for (i in 0..<onboard2Native.length()) {
                    onboard2NativeList.add(onboard2Native.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_OnBoard2Native_Ids_List(onboard2NativeList)

//////////// Onboard 2 Native 2 (native-ob2-2)
            try {
                val onboard2TwoNative: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.ONBOARD2_NATIVE_TWO_ADS_ID_LIST)
                for (i in 0..<onboard2TwoNative.length()) {
                    onboard2TwoNativeList.add(onboard2TwoNative.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_OnBoard2TwoNative_Ids_List(onboard2TwoNativeList)

//////////// Onboard 3 Native
            try {
                val onboard3Native: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.ONBOARD3_NATIVE_ADS_ID_LIST)
                for (i in 0..<onboard3Native.length()) {
                    onboard3NativeList.add(onboard3Native.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_OnBoard3Native_Ids_List(onboard3NativeList)

//////////// Onboard 3 Native 2 (native-ob3-2)
            try {
                val onboard3TwoNative: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.ONBOARD3_NATIVE_TWO_ADS_ID_LIST)
                for (i in 0..<onboard3TwoNative.length()) {
                    onboard3TwoNativeList.add(onboard3TwoNative.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_OnBoard3TwoNative_Ids_List(onboard3TwoNativeList)

//////////// Onboard 3 Native 3 (native-ob3-3)
            try {
                val onboard3ThreeNative: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.ONBOARD3_NATIVE_THREE_ADS_ID_LIST)
                for (i in 0..<onboard3ThreeNative.length()) {
                    onboard3ThreeNativeList.add(onboard3ThreeNative.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_OnBoard3ThreeNative_Ids_List(onboard3ThreeNativeList)

//////////// Onboard 4 Native (native-ob4-1 / ob4-2)
            try {
                val onboard4Native: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.ONBOARD4_NATIVE_ADS_ID_LIST)
                for (i in 0..<onboard4Native.length()) {
                    onboard4NativeList.add(onboard4Native.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_OnBoard4Native_Ids_List(onboard4NativeList)

//////////// Onboard 4 Native 2 (native-ob4-2)
            try {
                val onboard4TwoNative: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.ONBOARD4_NATIVE_TWO_ADS_ID_LIST)
                for (i in 0..<onboard4TwoNative.length()) {
                    onboard4TwoNativeList.add(onboard4TwoNative.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_OnBoard4TwoNative_Ids_List(onboard4TwoNativeList)

//////////// Inter Onboard (inter-ob5-1 / ob5-2)
            try {
                val interOnboard: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.INTER_ONBOARD_ADS_ID_LIST)
                for (i in 0..<interOnboard.length()) {
                    interOnboardList.add(interOnboard.getString(i))
                }
            } catch (e: JSONException) {
                e.printStackTrace()
            }
            ControlPreference.set_InterOnboard_Ids_List(interOnboardList)

////////////  AppOpen
            try {
                val appOpenAds: JSONArray =
                    publisher_ad_units_manage.getJSONArray(ControlPreference.PUBLISHER_APP_OPEN_AD_ID)
                for (i in 0..<appOpenAds.length()) {
                    val App_open_Ads_Id = appOpenAds.getString(i)
                    appOpenList.add(App_open_Ads_Id)
//                    Log.d("TAG", "setAdIdsFromRemote: " + splashInterOld)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_AppOpenList_Ids_List(appOpenList)

////////////  Native
            try {
                val nativeAds: JSONArray = publisher_ad_units_manage.getJSONArray(ControlPreference.PUBLISHER_NATIVE_AD_ID)
                for (i in 0..<nativeAds.length()) {
                    val Native_Ads_Id = nativeAds.getString(i)
                    nativeList.add(Native_Ads_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_NativeList_Ids_List(nativeList)

//////////// Inter
            try {
                val interAds: JSONArray = publisher_ad_units_manage.getJSONArray(ControlPreference.PUBLISHER_INTERSTITIAL_AD_ID)
                for (i in 0..<interAds.length()) {
                    val Inter_Ads_Id = interAds.getString(i)
                    interList.add(Inter_Ads_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_InterList_Ids_List(interList)

//////////// banner
            try {
                val bannerAds: JSONArray = publisher_ad_units_manage.getJSONArray(ControlPreference.PUBLISHER_BANNER_AD_ID)
                for (i in 0..<bannerAds.length()) {
                    val Banner_Ads_Id = bannerAds.getString(i)
                    bannerList.add(Banner_Ads_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_BannerList_Ids_List(bannerList)

//////////// reward
            try {
                val rewardAds: JSONArray = publisher_ad_units_manage.getJSONArray(ControlPreference.PUBLISHER_REWARD_AD_ID)
                for (i in 0..<rewardAds.length()) {
                    val Reward_Ads_Id = rewardAds.getString(i)
                    rewardList.add(Reward_Ads_Id)
                }
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
            ControlPreference.set_RewardList_Ids_List(rewardList)

            ControlPreference.setWatchAdFreeVideo(
                root.getInt("int_watch_ad_free_video")
            )

            ControlPreference.setUserFreeEpisodes(
                root.getInt("int_user_free_episode")
            )
            ControlPreference.setPrivacyPolicy(
                root.getString("url_privacy_policy")
            )
            ControlPreference.setHelpFeedback(
                root.getString("url_help_feedback")
            )
            ControlPreference.setInterstitialAdThreshold(
                root.getInt("interstitial_ad_count")
            )
            ControlPreference.setInterstitialShow(
                root.getBoolean("interstitial_ad_show")
            )
            // Master switch: false = hide all Home / post-login ads
            ControlPreference.setAfterLoginAdsShow(
                root.optBoolean("after_login_ads_show", false)
            )
            ControlPreference.setVastExoPlayerUrl(
                root.getString("exo_player_vast_url")
            )

            ControlPreference.setInterBottomAdsCount(
                root.getInt("inter_bottom_ads_count")
            )


            ControlPreference.setExoplayerImaShow(
                root.getBoolean("exo_player_ima_show")
            )

            ControlPreference.setExoplayerImaAfterReelsShowCount(
                root.getInt("exo_player_ima_ads_count")
            )

            val inrObject = root.getJSONObject("inr_premium_plan_details")
            val usdObject = root.getJSONObject("usd_premium_plan_details")
            val engineBoxObject = root.getJSONObject("engine_box")
            ControlPreference.setMainBaseUrl(
                engineBoxObject.getString("main_base_url")
            )
            ControlPreference.setMainAk(
                engineBoxObject.getString("main_ak")
            )
            ControlPreference.setMainSk(
                engineBoxObject.getString("main_sk")
            )
            ControlPreference.setTransactionUrl(
                engineBoxObject.getString("main_transaction_url")
            )
            ControlPreference.setCountryUrl(
                engineBoxObject.getString("main_country_url")
            )

            ControlPreference.setInrPlans(inrObject.toString())
            ControlPreference.setUsdPlans(usdObject.toString())

        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun showAppOpenAd() {
        if (hasNavigatedFromSplash) {
            return
        }
        if (ControlPreference.get_Splash_ads_show_type().equals("AppOpen", ignoreCase = true)) {
            AppOpenBackGroundAd.appOpenCall(
                this,
                ControlPreference.get_AppOpenList_Ids_List(),
                object : AppOpenBackGroundAd.OnCompleteAds {
                    override fun onCompleteAds(isShown: Boolean) {
                        preloadAfterSplashFullscreen()
                        navigateAfterSplashAd()
                    }
                })
        } else {
            if (ControlPreference.get_in_splash_first_time()) {
                // NEW USER display priority (fallback): inter-spl-1 → inter-spl-2
                SplashInterMange.appOpenCall(
                    this,
                    ControlPreference.get_SplashInter_Ids_List(),
                    object : SplashInterMange.OnCompleteAds {
                        override fun onCompleteAds(shown: Boolean) {
                            // After interstitial closes → preload native-lfo1-2
                            preloadAfterSplashFullscreen()
                            navigateAfterSplashAd()
                        }
                    })
            } else {
                // OLD USER display priority (fallback): inter-spl-1-o → inter-spl-2-o
                SplashInterMange.appOpenCall(
                    this,
                    ControlPreference.get_SplashInterOld_Ids_List(),
                    object : SplashInterMange.OnCompleteAds {
                        override fun onCompleteAds(shown: Boolean) {
                            preloadAfterSplashFullscreen()
                            navigateAfterSplashAd()
                        }
                    })
            }
        }
    }

    /** After splash interstitial/AppOpen — preload native-lfo1-2 (Language Success) */
    private fun preloadAfterSplashFullscreen() {
        val ids = ControlPreference.get_LanguageNativeSuccess_Ids_List()
        LanguageNativeAdSuccess.adsViewNativeAds = 0
        LanguageNativeAdSuccess.loadAdmobBigNativeAd(this, ids, null)
    }

    private fun navigateAfterSplashAd() {
        if (hasNavigatedFromSplash || isFinishing) {
            return
        }
        hasNavigatedFromSplash = true
        restoreFullScreenImmersive()
        initActivity()
    }


    fun fetchIpDetails(
        context: Context,
        callback: (Boolean) -> Unit
    ) {

        val url = ControlPreference.getCountryUrl()

        val queue = Volley.newRequestQueue(context)

        val request = JsonObjectRequest(
            Request.Method.GET,
            url,
            null,
            { response ->

                try {

                    val countryObj = response.optJSONObject("country")
                    val code = countryObj?.optString("code", "")
                        ?.lowercase()
                        ?.trim() ?: ""

                    ControlPreference.setCountryName(code)

                    callback(true)

                } catch (e: Exception) {

                    callback(false)
                }

            },
            {

                callback(false)
            })

        queue.add(request)
    }
}

private fun getVCode(context: Context): Int {
    try {
        return context.getPackageManager()
            .getPackageInfo(context.getPackageName(), 0)
            .versionCode
    } catch (e: PackageManager.NameNotFoundException) {
        e.printStackTrace()
        return 1
    }
}