package com.snapdrama.shortstream.ads;



import android.content.Context;
import android.os.Bundle;
import android.util.Log;

import com.google.firebase.analytics.FirebaseAnalytics;

public class FirebaseEventManager {

    private static FirebaseAnalytics firebaseAnalytics;

    public static void init(FirebaseAnalytics analytics) {
        firebaseAnalytics = analytics;
    }

    public static void init(Context context) {
        if (context == null) return;
        firebaseAnalytics = FirebaseAnalytics.getInstance(context.getApplicationContext());
    }

    // =========================
    // Common Method
    // =========================

    public static void logEvent(String eventName, Bundle bundle) {
        if (firebaseAnalytics == null) {
            Log.w("FirebaseEventManager", "Analytics not initialized; drop event=" + eventName);
            return;
        }
        firebaseAnalytics.logEvent(eventName, bundle != null ? bundle : new Bundle());
        Log.d("FirebaseEventManager", "event=" + eventName + " params=" + (bundle != null ? bundle : "{}"));
    }

    // =========================
    // Splash
    // =========================

    public static void splashView() {
        logEvent("splash_view", null);
    }

    public static void splashComplete(long splashStartTimeMs) {
        long engagementTimeMs = Math.max(0L, System.currentTimeMillis() - splashStartTimeMs);
        Bundle bundle = new Bundle();
        bundle.putLong("engagement_time", engagementTimeMs);
        Log.d("TAG", "splash_complete engagement_time=" + engagementTimeMs);
        logEvent("splash_complete", bundle);
    }

    // =========================
    // Inter Splash
    // =========================

    public static void interSplashView() {
        logEvent("inter_splash_view", null);
    }

    /**
     * @param interSplashStartTimeMs timestamp when inter_splash_view was logged (ad showed)
     */
    public static void interSplashComplete(long interSplashStartTimeMs) {
        if (interSplashStartTimeMs <= 0L) {
            return;
        }
        long engagementTimeMs = Math.max(0L, System.currentTimeMillis() - interSplashStartTimeMs);
        Bundle bundle = new Bundle();
        bundle.putLong("engagement_time", engagementTimeMs);
        Log.d("TAG", "inter_splash_complete engagement_time=" + engagementTimeMs);
        logEvent("inter_splash_complete", bundle);
    }


    public static void lfo1View() {
        logEvent("lfo1_view", null);
    }

    /** @param screenStartTimeMs timestamp when lfo1_view was logged */
    public static void lfo1Complete(long screenStartTimeMs) {
        long engagementTimeMs = Math.max(0L, System.currentTimeMillis() - screenStartTimeMs);
        Bundle bundle = new Bundle();
        bundle.putLong("engagement_time", engagementTimeMs);
        Log.d("FirebaseEventManager", "lfo1_complete engagement_time=" + engagementTimeMs);
        logEvent("lfo1_complete", bundle);
    }


    public static void lfo2View() {
        logEvent("lfo2_view", null);
    }

    /** @param screenStartTimeMs timestamp when lfo2_view was logged */
    public static void lfo2Complete(long screenStartTimeMs) {
        long engagementTimeMs = Math.max(0L, System.currentTimeMillis() - screenStartTimeMs);
        Bundle bundle = new Bundle();
        bundle.putLong("engagement_time", engagementTimeMs);
        Log.d("FirebaseEventManager", "lfo2_complete engagement_time=" + engagementTimeMs);
        logEvent("lfo2_complete", bundle);
    }


    public static void onb1View(String viewType) {

        Bundle bundle = new Bundle();
        bundle.putString("view_type", viewType);

        logEvent("onb1_view", bundle);
    }

    /**
     * @param screenStartTimeMs timestamp when onb1_view was logged for this visit
     */
    public static void onb1Complete(long screenStartTimeMs,
                                    String actionMethod,
                                    String navDirection,
                                    String toScreen) {

        long engagementTimeMs = Math.max(0L, System.currentTimeMillis() - screenStartTimeMs);
        Bundle bundle = new Bundle();

        bundle.putLong("engagement_time", engagementTimeMs);
        bundle.putString("action_method", actionMethod);
        bundle.putString("nav_direction", navDirection);
        bundle.putString("to_screen", toScreen);

        Log.d("FirebaseEventManager", "onb1_complete engagement_time=" + engagementTimeMs
                + " action=" + actionMethod + " dir=" + navDirection + " to=" + toScreen);
        logEvent("onb1_complete", bundle);
    }



    // =========================
    // Onboard 2
    // =========================

    public static void onb2View(String viewType) {

        Bundle bundle = new Bundle();
        bundle.putString("view_type", viewType);

        logEvent("onb2_view", bundle);
    }

    /**
     * @param screenStartTimeMs timestamp when onb2_view was logged for this visit
     */
    public static void onb2Complete(long screenStartTimeMs,
                                    String actionMethod,
                                    String navDirection,
                                    String toScreen) {

        long engagementTimeMs = Math.max(0L, System.currentTimeMillis() - screenStartTimeMs);
        Bundle bundle = new Bundle();

        bundle.putLong("engagement_time", engagementTimeMs);
        bundle.putString("action_method", actionMethod);
        bundle.putString("nav_direction", navDirection);
        bundle.putString("to_screen", toScreen);

        Log.d("FirebaseEventManager", "onb2_complete engagement_time=" + engagementTimeMs
                + " action=" + actionMethod + " dir=" + navDirection + " to=" + toScreen);
        logEvent("onb2_complete", bundle);
    }

    // =========================
    // Onboard 3
    // =========================

    public static void onb3View(String viewType) {

        Bundle bundle = new Bundle();
        bundle.putString("view_type", viewType);

        logEvent("onb3_view", bundle);
    }

    /**
     * @param screenStartTimeMs timestamp when onb3_view was logged for this visit
     */
    public static void onb3Complete(long screenStartTimeMs,
                                    String actionMethod,
                                    String navDirection,
                                    String toScreen) {

        long engagementTimeMs = Math.max(0L, System.currentTimeMillis() - screenStartTimeMs);
        Bundle bundle = new Bundle();

        bundle.putLong("engagement_time", engagementTimeMs);
        bundle.putString("action_method", actionMethod);
        bundle.putString("nav_direction", navDirection);
        bundle.putString("to_screen", toScreen);

        Log.d("FirebaseEventManager", "onb3_complete engagement_time=" + engagementTimeMs
                + " action=" + actionMethod + " dir=" + navDirection + " to=" + toScreen);
        logEvent("onb3_complete", bundle);
    }

    // =========================
    // Onboard 4
    // =========================

    public static void onb4View(String viewType) {

        Bundle bundle = new Bundle();
        bundle.putString("view_type", viewType);

        logEvent("onb4_view", bundle);
    }

    /**
     * @param screenStartTimeMs timestamp when onb4_view was logged for this visit
     */
    public static void onb4Complete(long screenStartTimeMs,
                                    String actionMethod,
                                    String navDirection,
                                    String toScreen) {

        long engagementTimeMs = Math.max(0L, System.currentTimeMillis() - screenStartTimeMs);
        Bundle bundle = new Bundle();

        bundle.putLong("engagement_time", engagementTimeMs);
        bundle.putString("action_method", actionMethod);
        bundle.putString("nav_direction", navDirection);
        bundle.putString("to_screen", toScreen);

        Log.d("FirebaseEventManager", "onb4_complete engagement_time=" + engagementTimeMs
                + " action=" + actionMethod + " dir=" + navDirection + " to=" + toScreen);
        logEvent("onb4_complete", bundle);
    }

    // =========================
    // Inter Onboard
    // =========================

    public static void interOnboardView() {
        logEvent("inter_onboard_view", null);
    }

    /**
     * @param interOnboardStartTimeMs timestamp when inter_onboard_view was logged (ad showed)
     */
    public static void interOnboardComplete(long interOnboardStartTimeMs) {
        if (interOnboardStartTimeMs <= 0L) {
            return;
        }
        long engagementTimeMs = Math.max(0L, System.currentTimeMillis() - interOnboardStartTimeMs);
        Bundle bundle = new Bundle();
        bundle.putLong("engagement_time", engagementTimeMs);
        Log.d("FirebaseEventManager", "inter_onboard_complete engagement_time=" + engagementTimeMs);
        logEvent("inter_onboard_complete", bundle);
    }
}