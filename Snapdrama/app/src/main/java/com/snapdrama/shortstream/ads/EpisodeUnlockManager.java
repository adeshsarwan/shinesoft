package com.snapdrama.shortstream.ads;

import android.content.Context;

public class EpisodeUnlockManager {

    private static final String PREF = "episode_unlock_pref";
    private static final String KEY_COUNT = "watch_count";

    public static int getCount(Context context) {
        return context.getSharedPreferences(PREF, Context.MODE_PRIVATE)
                .getInt(KEY_COUNT, 0);
    }

    public static void increase(Context context) {
        int count = getCount(context);
        context.getSharedPreferences(PREF, Context.MODE_PRIVATE)
                .edit()
                .putInt(KEY_COUNT, count + 1)
                .apply();
    }

    public static boolean isLocked(Context context) {
        return getCount(context) >= 10;
    }

    public static void reset(Context context) {
        context.getSharedPreferences(PREF, Context.MODE_PRIVATE)
                .edit()
                .putInt(KEY_COUNT, 0)
                .apply();
    }
}