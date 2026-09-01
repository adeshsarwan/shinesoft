package com.snapdrama.shortstream.utils;

import android.content.Context;
import android.content.SharedPreferences;

public class TimerManager {

    private static final String PREF_NAME = "timer_pref";
    private static final String END_TIME = "end_time";

    public static void startTimer(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);

        if (!prefs.contains(END_TIME)) {
            long endTime = System.currentTimeMillis() + (60 * 60 * 1000); // 1 hour
            prefs.edit().putLong(END_TIME, endTime).apply();
        }
    }

    public static long getRemainingTime(Context context) {
        SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        long endTime = prefs.getLong(END_TIME, 0);
        return endTime - System.currentTimeMillis();
    }
}
