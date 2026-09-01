package com.snapdrama.shortstream.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.widget.TextView;

import java.util.Locale;
import java.util.Random;

public class SeriesViewCountHelper {
    
    private static final String PREF_NAME = "permanent_prefs21";
    private static final String KEY_PREFIX = "series_million_value_";
    

    public static void setPermanentRandomMillion(
            Context context,
            TextView textView,
            String seriesId,
            int listSize
    ) {
        if (seriesId == null || seriesId.isEmpty()) {
            return;
        }
        
        SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        
        String key = KEY_PREFIX + seriesId;
        
        String savedValue = prefs.getString(key, null);
        
        if (savedValue == null) {
            String randomMillion = generateRandomMillionByListSize(listSize);
            
            prefs.edit()
                    .putString(key, randomMillion)
                    .apply();
            
            textView.setText(randomMillion);
        } else {
            textView.setText(savedValue);
        }
    }
    

    public static void setPermanentRankingMillion(
            Context context,
            TextView textView,
            String seriesId,
            int position,
            int listSize
    ) {
        if (seriesId == null || seriesId.isEmpty()) {
            return;
        }
        
        SharedPreferences prefs = context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        
        String key = KEY_PREFIX + seriesId;
        
        String savedValue = prefs.getString(key, null);
        
        if (savedValue == null) {
            String rankingMillion = generateRankingMillionByPosition(position, listSize);
            
            prefs.edit()
                    .putString(key, rankingMillion)
                    .apply();
            
            textView.setText(rankingMillion);
        } else {
            textView.setText(savedValue);
        }
    }

    private static String generateRandomMillionByListSize(int listSize) {
        double min = 2.4;
        double max = 25.5;
        
        double step = (max - min) / Math.max(listSize - 1, 1);
        
        int randomIndex = new Random().nextInt(listSize);
        
        double value = min + (randomIndex * step);
        
        return String.format(Locale.US, "%.1f M", value);
    }
    

    private static String generateRankingMillionByPosition(int position, int listSize) {
        double min = 2.4;
        double max = 25.5;
        if (listSize <= 1) {
            double value = (min + max) / 2.0;
            return String.format(Locale.US, "%.1f M", value);
        }
        double positionRatio = (double) position / (listSize - 1);
        double reversedRatio = 1.0 - positionRatio;
        double baseValue = min + (reversedRatio * (max - min));
        double step = (max - min) / (listSize - 1);
        double randomVariation = (new Random().nextDouble() - 0.5) * step * 0.2;
        double value = baseValue + randomVariation;
        value = Math.max(min, Math.min(max, value));
        return String.format(Locale.US, "%.1f M", value);
    }
}
