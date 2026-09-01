package com.snapdrama.shortstream.applicationPreference;

import android.content.Context;
import android.content.SharedPreferences;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;

import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;


public class ControlPreference {

    private static final String store_lan = "store_lan";
    private static final String AppLanguage = "app_language";
    private static final String store_firebase_banner = "store_firebase_banner";
    private static final String store_firebase_appOpen = "store_firebase_appOpen";
    private static final String store_firebase_Interstitial = "store_firebase_Interstitial";
    private static final String store_firebase_native = "store_firebase_native";
    private static final String publisher_Reward_Ad_Id = "publisher_Reward_Ad_Id";
    private static final String store_firebase_WatchAdFreeVideo = "store_firebase_WatchAdFreeVideo";
    private static final String store_firebase_int_user_free_episode = "store_firebase_int_user_free_episode";
    private static final String store_country_Name = "store_country_Name";
    private static final String store_inr_plans = "store_inr_plans";
    private static final String store_usd_plans = "store_usd_plans";
    private static final String store_interstitial_ad_count = "store_interstitial_ad_count";
    private static final String store_interstitial_ad_threshold = "store_interstitial_ad_threshold";
    private static final String store_interstitial_click_count = "store_interstitial_click_count";
    private static final String store_interstitial_show = "store_interstitial_show";
    private static final String store_after_login_ads_show = "store_after_login_ads_show";
    private static final String store_test_id_ads = "store_test_id_ads";
    private static final String store_inter_bottom_ads_count = "store_inter_bottom_ads_count";
    private static final String store_inter_bottom_ads_click_count = "store_inter_bottom_ads_click_count";
    private static final String store_privacy_policy = "store_privacy_policy";
    private static final String store_help_feedback = "store_help_feedback";
    private static final String store_vast_exoPlayer_url = "store_vast_exoPlayer_url";
    private static final String store_exo_player_ima_show = "store_exo_player_ima_show";
    private static final String store_exo_player_ima_after_reels_show_count = "store_exo_player_ima_after_reels_show_count";
    private static final String store_MAIN_BASE_URL = "store_main_base_url";
    private static final String store_MAIN_AK = "store_main_ak";
    private static final String store_MAIN_SK = "store_main_sk";
    private static final String store_MAIN_TRANSACTION_URL = "store_main_transaction_url";
    private static final String store_MAIN_COUNTRY_URL = "store_main_country_url";
    public static final String LANGUAGE_SCREEN = "language_screen";
    public static final String LOGIN_SCREEN = "login_screen";

    public static void setMainBaseUrl(String value) {
        manegePrefUtils().edit().putString(store_MAIN_BASE_URL, value).apply();
    }

    public static void setMainAk(String value) {
        manegePrefUtils().edit().putString(store_MAIN_AK, value).apply();
    }

    public static void setMainSk(String value) {
        manegePrefUtils().edit().putString(store_MAIN_SK, value).apply();
    }

    public static void setTransactionUrl(String value) {
        manegePrefUtils().edit().putString(store_MAIN_TRANSACTION_URL, value).apply();
    }

    public static void setCountryUrl(String value) {
        manegePrefUtils().edit().putString(store_MAIN_COUNTRY_URL, value).apply();
    }

    public static String getMainBaseUrl() {
        return manegePrefUtils().getString(store_MAIN_BASE_URL, "");
    }

    public static String getMainAk() {
        return manegePrefUtils().getString(store_MAIN_AK, "");
    }

    public static String getMainSk() {
        return manegePrefUtils().getString(store_MAIN_SK, "");
    }

    public static String getTransactionUrl() {
        return manegePrefUtils().getString(store_MAIN_TRANSACTION_URL, "");
    }

    public static String getCountryUrl() {
        return manegePrefUtils().getString(store_MAIN_COUNTRY_URL, "");
    }

    public static void setExoplayerImaShow(boolean value) {
        manegePrefUtils().edit().putBoolean(store_exo_player_ima_show, value).apply();
    }

    public static boolean getExoplayerImaShow() {
        return manegePrefUtils().getBoolean(store_exo_player_ima_show, false);
    }

    // New preference: after how many reels an ad should be shown
    public static void setExoplayerImaAfterReelsShowCount(int count) {
        manegePrefUtils().edit().putInt(store_exo_player_ima_after_reels_show_count, count).apply();
    }

    public static int getExoplayerImaAfterReelsShowCount() {
        // Default to 3 if not set
        return manegePrefUtils().getInt(store_exo_player_ima_after_reels_show_count, 4);
    }

    public static void setVastExoPlayerUrl(String value) {
        manegePrefUtils().edit().putString(store_vast_exoPlayer_url, value).apply();
    }

    public static String getVastExoPlayerUrl() {
        return manegePrefUtils().getString(store_vast_exoPlayer_url, "");
    }

    public static void setPrivacyPolicy(String value) {
        manegePrefUtils().edit().putString(store_privacy_policy, value).apply();
    }

    public static String getPrivacyPolicy() {
        return manegePrefUtils().getString(store_privacy_policy, "");
    }

    public static void setHelpFeedback(String value) {
        manegePrefUtils().edit().putString(store_help_feedback, value).apply();
    }

    public static String getHelpFeedback() {
        return manegePrefUtils().getString(store_help_feedback, "");
    }

    public static void setInterstitialShow(boolean value) {
        manegePrefUtils().edit().putBoolean(store_interstitial_show, value).apply();
    }

    public static boolean getInterstitialShow() {
        return manegePrefUtils().getBoolean(store_interstitial_show, false);
    }

    /** Master switch for Home + all post-login ads (native/banner/inter/reward/IMA). Default false = hidden. */
    public static void setAfterLoginAdsShow(boolean value) {
        manegePrefUtils().edit().putBoolean(store_after_login_ads_show, value).apply();
    }

    public static boolean getAfterLoginAdsShow() {
        return manegePrefUtils().getBoolean(store_after_login_ads_show, false);
    }

    /** Remote Config test_id: true = Google test ad units, false = live AdMob units. */
    public static void setTestIdAds(boolean value) {
        manegePrefUtils().edit().putBoolean(store_test_id_ads, value).apply();
    }

    public static boolean getTestIdAds() {
        return manegePrefUtils().getBoolean(store_test_id_ads, false);
    }

    public static void setInterstitialAdCount(int value) {
        setInterstitialAdThreshold(value);
    }

    public static int getInterstitialAdCount() {
        return getInterstitialClickCount();
    }
    public static void setInterBottomAdsCount(int value) {
        manegePrefUtils().edit().putInt(store_inter_bottom_ads_count, value).apply();
    }

    public static int getInterBottomAdsCount() {
        return manegePrefUtils().getInt(store_inter_bottom_ads_count, 0);
    }

    public static void incrementInterBottomAdsClickCount() {
        int count = getInterBottomAdsClickCount();
        manegePrefUtils().edit().putInt(store_inter_bottom_ads_click_count, count + 1).apply();
    }

    public static int getInterBottomAdsClickCount() {
        return manegePrefUtils().getInt(store_inter_bottom_ads_click_count, 0);
    }

    public static void resetInterBottomAdsClickCount() {
        manegePrefUtils().edit().putInt(store_inter_bottom_ads_click_count, 0).apply();
    }



    public static void setInterstitialAdThreshold(int value) {
        manegePrefUtils().edit().putInt(store_interstitial_ad_threshold, value).apply();
    }

    public static int getInterstitialAdThreshold() {
        return manegePrefUtils().getInt(store_interstitial_ad_threshold, 3);
    }

    public static void incrementInterstitialAdCount() {
        incrementInterstitialClickCount();
    }

    public static void incrementInterstitialClickCount() {
        int count = getInterstitialClickCount();
        manegePrefUtils().edit().putInt(store_interstitial_click_count, count + 1).apply();
    }

    public static int getInterstitialClickCount() {
        return manegePrefUtils().getInt(store_interstitial_click_count, 0);
    }

    public static void resetInterstitialAdCount() {
        resetInterstitialClickCount();
    }

    public static void resetInterstitialClickCount() {
        manegePrefUtils().edit().putInt(store_interstitial_click_count, 0).apply();
    }

    public static void setInrPlans(String value) {
        manegePrefUtils().edit().putString(store_inr_plans, value).apply();
    }

    public static String getInrPlans() {
        return manegePrefUtils().getString(store_inr_plans, "");
    }

    public static void setUsdPlans(String value) {
        manegePrefUtils().edit().putString(store_usd_plans, value).apply();
    }

    public static String getUsdPlans() {
        return manegePrefUtils().getString(store_usd_plans, "");
    }

    private static SharedPreferences manegePrefUtils() {
        return ControllerApplication.Instance().getSharedPreferences(
                "reelsvideo_storybox", Context.MODE_PRIVATE);
    }

    public static void setCountryName(String value) {
        manegePrefUtils().edit().putString(store_country_Name, value).apply();
    }

    public static String getCountryName() {
        return manegePrefUtils().getString(store_country_Name, "en");
    }

    public static void setLanguage(String value) {
        manegePrefUtils().edit().putString(store_lan, value).apply();
    }

    public static String getLanguage() {
        return manegePrefUtils().getString(store_lan, "en");
    }

    public static void setAppLanguage(String value) {
        manegePrefUtils().edit().putString(AppLanguage, value).apply();
    }

    public static String getAppLanguage() {
        return manegePrefUtils().getString(AppLanguage, "en");
    }

    public static boolean getLanguageScreen() {
        return manegePrefUtils().getBoolean(LANGUAGE_SCREEN, false);
    }

    public static void setLanguageScreen(Boolean key) {
        manegePrefUtils().edit().putBoolean(LANGUAGE_SCREEN, key).apply();
    }

    public static boolean getLoginScreen() {
        return manegePrefUtils().getBoolean(LOGIN_SCREEN, false);
    }

    public static void setLoginScreen(Boolean key) {
        manegePrefUtils().edit().putBoolean(LOGIN_SCREEN, key).apply();
    }


    public static void setUserFreeEpisodes(int value) {
        manegePrefUtils().edit().putInt(store_firebase_int_user_free_episode, value).apply();
    }

    public static int getUserFreeEpisodes() {
        return manegePrefUtils().getInt(store_firebase_int_user_free_episode, 0);
    }

    public static void setWatchAdFreeVideo(int value) {
        manegePrefUtils().edit().putInt(store_firebase_WatchAdFreeVideo, value).apply();
    }

    public static int getWatchAdFreeVideo() {
        return manegePrefUtils().getInt(store_firebase_WatchAdFreeVideo, 0);
    }


    /// ////////////////////Config Names/////////////////////////////////////////
    public static final String PUBLISHER_AD_UNITS_MANGE = "publisher_ad_units_manage";
    public static final String PUBLISHER_AD_UNITS_MANGE_TEST = "publisher_ad_units_manage_test";


    public static final String SPLASH_NATIVE_ADS_ID_LIST = "splash_native";
    public static final String SPLASH_NATIVE_OLD_ADS_ID_LIST = "splash_native_old";

    public static final String SPLASH_INTER_ADS_ID_LIST = "splash_inter";
    public static final String SPLASH_INTER_OLD_ADS_ID_LIST = "splash_inter_old";

    public static final String LANGUAGE_NATIVE_ADS_ID_LIST = "lfo1_native";
    public static final String LANGUAGE_NATIVE_SUCCESS_ADS_ID_LIST = "lfo1_native_2";
    public static final String LANGUAGE_NATIVE_OLD_ADS_ID_LIST = "lfo2_native";
    public static final String LANGUAGE_NATIVE_LFO2_TWO_ADS_ID_LIST = "lfo2_native_2";
    public static final String LANGUAGE_NATIVE_LFO2_THREE_ADS_ID_LIST = "lfo2_native_3";
    public static final String ONBOARD1_NATIVE_OLD_ADS_ID_LIST = "onboard_1_native";
    public static final String ONBOARD1_NATIVE_TWO_ADS_ID_LIST = "onboard_1_native_2";
    public static final String ONBOARD2_NATIVE_ADS_ID_LIST = "onboard_2_native";
    public static final String ONBOARD2_NATIVE_TWO_ADS_ID_LIST = "onboard_2_native_2";
    public static final String ONBOARD3_NATIVE_ADS_ID_LIST = "onboard_3_native";
    public static final String ONBOARD3_NATIVE_TWO_ADS_ID_LIST = "onboard_3_native_2";
    public static final String ONBOARD3_NATIVE_THREE_ADS_ID_LIST = "onboard_3_native_3";
    public static final String ONBOARD4_NATIVE_ADS_ID_LIST = "onboard_4_native";
    public static final String ONBOARD4_NATIVE_TWO_ADS_ID_LIST = "onboard_4_native_2";
    public static final String INTER_ONBOARD_ADS_ID_LIST = "inter_onboard";

    public static final String PUBLISHER_APP_OPEN_AD_ID = "publisher_AppOpen_Ad_Id";
    public static final String PUBLISHER_NATIVE_AD_ID = "publisher_Native_Ad_Id";
    public static final String PUBLISHER_INTERSTITIAL_AD_ID = "publisher_Interstitial_Ad_Id";
    public static final String PUBLISHER_BANNER_AD_ID = "publisher_Banner_Ad_Id";
    public static final String PUBLISHER_REWARD_AD_ID = "publisher_Reward_Ad_Id";


    /// ///////////////////////////////
    public static final String SplashNativeList = "splash_native_list";
    public static final String SplashNativeOldList = "splash_native_old_list";

    public static final String SplashInterList = "splash_inter_list";
    public static final String SplashInterOldList = "splash_inter_old_list";

    public static final String LanguageNativeList = "langauge_native_list";
    public static final String LanguageNativeSuccessList = "language_native_success_list";
    public static final String LanguageNativeOldList = "langauge_native_old_list";
    public static final String LanguageNativeLfo2TwoList = "language_native_lfo2_two_list";
    public static final String LanguageNativeLfo2ThreeList = "language_native_lfo2_three_list";
    public static final String OnBoard1NativeList = "onBoard_native_old_list";
    public static final String OnBoard1TwoNativeList = "onBoard1_two_native_list";
    public static final String OnBoard2NativeList = "onBoard2_native_list";
    public static final String OnBoard2TwoNativeList = "onBoard2_two_native_list";
    public static final String OnBoard3NativeList = "onBoard3_native_list";
    public static final String OnBoard3TwoNativeList = "onBoard3_two_native_list";
    public static final String OnBoard3ThreeNativeList = "onBoard3_three_native_list";
    public static final String OnBoard4NativeList = "onBoard4_native_list";
    public static final String OnBoard4TwoNativeList = "onBoard4_two_native_list";
    public static final String InterOnboardList = "inter_onboard_list";

    public static final String AppOpenList = "app_open_list";
    public static final String NativeList = "native_list";
    public static final String InterList = "inter_list";
    public static final String BannerList = "banner_list";
    public static final String RewardList = "reward_list";


    public static final String SPLASH_ADS_SHOW_TYPE = "splash_ads_show_type";
    public static final String HOME_NEW_NATIVE_ADS_POSITION = "home_new_native_ads_positions";
    public static final String HOME_RANKING_NATIVE_ADS_POSITION = "home_ranking_native_ads_position";


    ///  //////////////////////////////////////////////////////

    private static final String InSplashFirstTime = "in_splash_first_time";
    private static final String SplashAdsTypeValue = "splash_ads_type_value";
    private static final String HomeNewAdsPosition = "home_new_ads_positions";
    private static final String HomeRankingAdsPosition = "home_ranking_ads_positions";

    public static String getString(String key) {
        return manegePrefUtils().getString(SplashAdsTypeValue, "AppOpen");
    }

    public static void setString(String key, String value) {
        manegePrefUtils().edit().putString(SplashAdsTypeValue, value).apply();
    }

    public static Boolean get_in_splash_first_time() {
        return manegePrefUtils().getBoolean(InSplashFirstTime, true);
    }

    public static void set_in_splash_first_time(Boolean value) {
        manegePrefUtils().edit().putBoolean(InSplashFirstTime, value).apply();
    }


    public static String get_Splash_ads_show_type() {
        return manegePrefUtils().getString(SplashAdsTypeValue, "AppOpen");
    }

    public static void set_Splash_ads_show_type(String value) {
        manegePrefUtils().edit().putString(SplashAdsTypeValue, value).apply();
    }

    public static int get_Home_New_Ads_Position() {
        return manegePrefUtils().getInt(HomeNewAdsPosition, 0);
    }

    public static void set_Home_New_Ads_Position(int value) {
        manegePrefUtils().edit().putInt(HomeNewAdsPosition, value).apply();
    }

    public static int get_Home_Ranking_Ads_Position() {
        return manegePrefUtils().getInt(HomeRankingAdsPosition, 0);
    }

    public static void set_Home_Ranking_Ads_Position(int value) {
        manegePrefUtils().edit().putInt(HomeRankingAdsPosition, value).apply();
    }

    public static List<String> get_SplashNative_Ids_List() {
        String Json = manegePrefUtils().getString(SplashNativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_SplashNative_Ids_List(List<String> splashNativeIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(splashNativeIdsList);
        manegePrefUtils().edit().putString(SplashNativeList, json).apply();
    }

    public static List<String> get_SplashNativeOld_Ids_List() {
        String Json = manegePrefUtils().getString(SplashNativeOldList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_SplashNativeOld_Ids_List(List<String> splashNativeOldIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(splashNativeOldIdsList);
        manegePrefUtils().edit().putString(SplashNativeOldList, json).apply();
    }

    public static List<String> get_LanguageNative_Ids_List() {
        String Json = manegePrefUtils().getString(LanguageNativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_LanguageNative_Ids_List(List<String> splashNativeIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(splashNativeIdsList);
        manegePrefUtils().edit().putString(LanguageNativeList, json).apply();
    }

    public static List<String> get_LanguageNativeSuccess_Ids_List() {
        String Json = manegePrefUtils().getString(LanguageNativeSuccessList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_LanguageNativeSuccess_Ids_List(List<String> nativeSuccessIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(nativeSuccessIdsList);
        manegePrefUtils().edit().putString(LanguageNativeSuccessList, json).apply();
    }

    public static List<String> get_LanguageNativeOld_Ids_List() {
        String Json = manegePrefUtils().getString(LanguageNativeOldList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_LanguageNativeOld_Ids_List(List<String> splashNativeIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(splashNativeIdsList);
        manegePrefUtils().edit().putString(LanguageNativeOldList, json).apply();
    }

    public static List<String> get_LanguageNativeLfo2Two_Ids_List() {
        String Json = manegePrefUtils().getString(LanguageNativeLfo2TwoList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_LanguageNativeLfo2Two_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(LanguageNativeLfo2TwoList, json).apply();
    }

    public static List<String> get_LanguageNativeLfo2Three_Ids_List() {
        String Json = manegePrefUtils().getString(LanguageNativeLfo2ThreeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_LanguageNativeLfo2Three_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(LanguageNativeLfo2ThreeList, json).apply();
    }

    public static List<String> get_OnBoard1Native_Ids_List() {
        String Json = manegePrefUtils().getString(OnBoard1NativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_OnBoard1Native_Ids_List(List<String> splashNativeIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(splashNativeIdsList);
        manegePrefUtils().edit().putString(OnBoard1NativeList, json).apply();
    }

    public static List<String> get_OnBoard1TwoNative_Ids_List() {
        String Json = manegePrefUtils().getString(OnBoard1TwoNativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList != null ? arrayList : new ArrayList<String>();
    }

    public static void set_OnBoard1TwoNative_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(OnBoard1TwoNativeList, json).apply();
    }

    public static List<String> get_OnBoard2Native_Ids_List() {
        String Json = manegePrefUtils().getString(OnBoard2NativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_OnBoard2Native_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(OnBoard2NativeList, json).apply();
    }

    public static List<String> get_OnBoard3Native_Ids_List() {
        String Json = manegePrefUtils().getString(OnBoard3NativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_OnBoard3Native_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(OnBoard3NativeList, json).apply();
    }

    public static List<String> get_OnBoard2TwoNative_Ids_List() {
        String Json = manegePrefUtils().getString(OnBoard2TwoNativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_OnBoard2TwoNative_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(OnBoard2TwoNativeList, json).apply();
    }

    public static List<String> get_OnBoard3TwoNative_Ids_List() {
        String Json = manegePrefUtils().getString(OnBoard3TwoNativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_OnBoard3TwoNative_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(OnBoard3TwoNativeList, json).apply();
    }

    public static List<String> get_OnBoard3ThreeNative_Ids_List() {
        String Json = manegePrefUtils().getString(OnBoard3ThreeNativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_OnBoard3ThreeNative_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(OnBoard3ThreeNativeList, json).apply();
    }

    public static List<String> get_OnBoard4Native_Ids_List() {
        String Json = manegePrefUtils().getString(OnBoard4NativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_OnBoard4Native_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(OnBoard4NativeList, json).apply();
    }

    public static List<String> get_OnBoard4TwoNative_Ids_List() {
        String Json = manegePrefUtils().getString(OnBoard4TwoNativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList != null ? arrayList : new ArrayList<String>();
    }

    public static void set_OnBoard4TwoNative_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(OnBoard4TwoNativeList, json).apply();
    }

    public static List<String> get_InterOnboard_Ids_List() {
        String Json = manegePrefUtils().getString(InterOnboardList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_InterOnboard_Ids_List(List<String> idsList) {
        Gson gson = new Gson();
        String json = gson.toJson(idsList);
        manegePrefUtils().edit().putString(InterOnboardList, json).apply();
    }


    public static List<String> get_SplashInter_Ids_List() {
        String Json = manegePrefUtils().getString(SplashInterList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_SplashInter_Ids_List(List<String> splashInterIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(splashInterIdsList);
        manegePrefUtils().edit().putString(SplashInterList, json).apply();
    }

    public static List<String> get_SplashInterOld_Ids_List() {
        String Json = manegePrefUtils().getString(SplashInterOldList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_SplashInterOld_Ids_List(List<String> splashInterOldIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(splashInterOldIdsList);
        manegePrefUtils().edit().putString(SplashInterOldList, json).apply();
    }


    public static List<String> get_AppOpenList_Ids_List() {
        String Json = manegePrefUtils().getString(AppOpenList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_AppOpenList_Ids_List(List<String> appOpenListIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(appOpenListIdsList);
        manegePrefUtils().edit().putString(AppOpenList, json).apply();
    }


    public static List<String> get_NativeList_Ids_List() {
        String Json = manegePrefUtils().getString(NativeList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_NativeList_Ids_List(List<String> nativeListIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(nativeListIdsList);
        manegePrefUtils().edit().putString(NativeList, json).apply();
    }

    public static List<String> get_InterList_Ids_List() {
        String Json = manegePrefUtils().getString(InterList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_InterList_Ids_List(List<String> nativeListIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(nativeListIdsList);
        manegePrefUtils().edit().putString(InterList, json).apply();
    }

    public static List<String> get_BannerList_Ids_List() {
        String Json = manegePrefUtils().getString(BannerList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_BannerList_Ids_List(List<String> nativeListIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(nativeListIdsList);
        manegePrefUtils().edit().putString(BannerList, json).apply();
    }


    public static List<String> get_RewardList_Ids_List() {
        String Json = manegePrefUtils().getString(RewardList, "");
        Type type = new TypeToken<ArrayList<String>>() {
        }.getType();
        Gson gson = new Gson();
        ArrayList<String> arrayList = gson.fromJson(Json, type);
        return arrayList;
    }

    public static void set_RewardList_Ids_List(List<String> nativeListIdsList) {
        Gson gson = new Gson();
        String json = gson.toJson(nativeListIdsList);
        manegePrefUtils().edit().putString(RewardList, json).apply();
    }
}

