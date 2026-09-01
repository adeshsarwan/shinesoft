package com.snapdrama.shortstream.applicationPreference;

import android.app.Application;
import android.content.Context;

import com.google.android.gms.ads.MobileAds;

import androidx.appcompat.app.AppCompatDelegate;
import androidx.core.os.LocaleListCompat;

public class ControllerApplication extends Application {


    private static ControllerApplication pref_instance = new ControllerApplication();



    public static ControllerApplication Instance() {
        if (pref_instance == null) {
            pref_instance = new ControllerApplication();
        }
        return pref_instance;
    }
    

    @Override
    public void onCreate() {
        super.onCreate();

        pref_instance = this;

        // Apply saved language on app startup
        String savedLanguage = ControlPreference.getLanguage();
        AppCompatDelegate.setApplicationLocales(LocaleListCompat.forLanguageTags(savedLanguage));

        MobileAds.initialize(this);
    }


    @Override
    protected void attachBaseContext(Context base) {
        super.attachBaseContext(base);

    }


}