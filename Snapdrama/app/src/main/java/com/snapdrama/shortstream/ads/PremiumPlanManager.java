package com.snapdrama.shortstream.ads;

import android.content.Context;
import android.util.Log;

import androidx.annotation.Nullable;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;

import java.util.HashMap;
import java.util.Map;

public class PremiumPlanManager {

    private static final String COLLECTION_USERS = "users";

    public static final String FIELD_PREMIUM_EXPIRY_MILLIS = "premium_expiry_millis";
    public static final String FIELD_PREMIUM_PURCHASE_DATE = "premium_purchase_date";
    public static final String FIELD_PREMIUM_PRICE = "premium_price";
    public static final String FIELD_PREMIUM_IS_WEEKLY = "premium_is_weekly";
    public static final String FIELD_PREMIUM_IS_YEARLY = "premium_is_yearly";
    public static final String FIELD_PREMIUM_DURATION_DAYS = "premium_duration_days";

    public static final long DURATION_WEEKLY_MS = 7L * 24 * 60 * 60 * 1000;
    public static final long DURATION_YEARLY_MS = 365L * 24 * 60 * 60 * 1000;

    private static volatile long cachedExpiryMillis = 0L;
    private static volatile String cachedUid = null;

    private PremiumPlanManager() {}

    public static boolean isPremiumActive(Context context) {
        if (context == null) return false;
        String uid = getCurrentUid();
        if (uid == null || uid.isEmpty()) return false;
        if (cachedUid == null || !cachedUid.equals(uid)) return false;


        return cachedExpiryMillis > System.currentTimeMillis();
    }

    /**
     * Skip Home / post-login ads when premium OR Remote Config after_login_ads_show=false.
     * Does not affect splash/onboarding ads (those use isPremiumActive only).
     */
    public static boolean shouldSkipAfterLoginAd(Context context) {
        if (isPremiumActive(context)) {
            return true;
        }
        return !com.snapdrama.shortstream.applicationPreference.ControlPreference.getAfterLoginAdsShow();
    }

    public static void savePremiumPurchaseToFirestore(
            Context context,
            boolean isWeekly,
            boolean isYearly,
            double price,
            long durationMs,
            @Nullable SavePremiumCallback callback) {

        if (context == null) {
            if (callback != null) callback.onError(new IllegalArgumentException("context is null"));
            return;
        }

        String uid = getCurrentUid();
        if (uid == null || uid.isEmpty()) {
            if (callback != null) callback.onError(new IllegalArgumentException("User not logged in"));
            return;
        }

        long now = System.currentTimeMillis();
        long expiry = now + durationMs;
        int durationDays = (int) (durationMs / (24 * 60 * 60 * 1000));

        Map<String, Object> data = new HashMap<>();
        data.put(FIELD_PREMIUM_EXPIRY_MILLIS, expiry);
        data.put(FIELD_PREMIUM_PURCHASE_DATE, now);
        data.put(FIELD_PREMIUM_PRICE, price);
        data.put(FIELD_PREMIUM_IS_WEEKLY, isWeekly);
        data.put(FIELD_PREMIUM_IS_YEARLY, isYearly);
        data.put(FIELD_PREMIUM_DURATION_DAYS, durationDays);

        FirebaseFirestore.getInstance()
                .collection(COLLECTION_USERS)
                .document(uid)
                .set(data, SetOptions.merge())
                .addOnSuccessListener(aVoid -> {
                    updateCache(uid, expiry);
                    if (callback != null) callback.onSuccess();
                })
                .addOnFailureListener(e -> {
                    if (callback != null) callback.onError(e);
                });
    }


    public static void setPremiumPurchased(Context context, long durationMs) {
        boolean isWeekly = (durationMs == DURATION_WEEKLY_MS);
        boolean isYearly = (durationMs == DURATION_YEARLY_MS);
        double price = isWeekly ? 300.0 : (isYearly ? 5120.0 : 0.0);
        savePremiumPurchaseToFirestore(context, isWeekly, isYearly, price, durationMs, null);
    }


    public static void refreshPremiumFromFirestore(Context context, @Nullable RefreshCallback callback) {
        if (context == null) {
            if (callback != null) callback.onDone(false);
            return;
        }
        String uid = getCurrentUid();
        if (uid == null || uid.isEmpty()) {
            clearCache();
            if (callback != null) callback.onDone(false);
            return;
        }

        FirebaseFirestore.getInstance()
                .collection(COLLECTION_USERS)
                .document(uid)
                .get()
                .addOnSuccessListener(snapshot -> {
                    if (snapshot != null && snapshot.exists() && snapshot.contains(FIELD_PREMIUM_EXPIRY_MILLIS)) {
                        Object val = snapshot.get(FIELD_PREMIUM_EXPIRY_MILLIS);
                        long expiry = val instanceof Number ? ((Number) val).longValue() : 0L;
                        updateCache(uid, expiry);
                        if (callback != null) callback.onDone(true);
                    } else {
                        updateCache(uid, 0L);
                        if (callback != null) callback.onDone(false);
                    }
                })
                .addOnFailureListener(e -> {
                    if (callback != null) callback.onDone(false);
                });
    }





    public static long getPremiumExpiryMillis(Context context) {
        if (context == null) return 0L;
        String uid = getCurrentUid();
        if (uid == null || !uid.equals(cachedUid)) return 0L;
        return cachedExpiryMillis;
    }


    public static void clearPremium(Context context) {
        if (context == null) return;
        String uid = getCurrentUid();
        if (uid == null || uid.isEmpty()) {
            clearCache();
            return;
        }
        Map<String, Object> data = new HashMap<>();
        data.put(FIELD_PREMIUM_EXPIRY_MILLIS, 0L);

        FirebaseFirestore.getInstance()
                .collection(COLLECTION_USERS)
                .document(uid)
                .set(data, SetOptions.merge())
                .addOnSuccessListener(aVoid -> clearCache())
                .addOnFailureListener(e -> clearCache());
    }

    private static String getCurrentUid() {
        if (FirebaseAuth.getInstance().getCurrentUser() == null) return null;
        return FirebaseAuth.getInstance().getCurrentUser().getUid();
    }

    private static void updateCache(String uid, long expiryMillis) {
        cachedUid = uid;
        cachedExpiryMillis = expiryMillis;
    }

    private static void clearCache() {
        cachedUid = null;
        cachedExpiryMillis = 0L;
    }

    public interface SavePremiumCallback {
        void onSuccess();
        void onError(Exception e);
    }

    public interface RefreshCallback {
        void onDone(boolean hasPremium);
    }
}
