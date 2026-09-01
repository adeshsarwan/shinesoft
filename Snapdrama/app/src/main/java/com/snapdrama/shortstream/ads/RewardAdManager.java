package com.snapdrama.shortstream.ads;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Paint;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.AdValue;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.AdError;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.OnPaidEventListener;
import com.google.android.gms.ads.rewarded.RewardedAd;
import com.google.android.gms.ads.rewarded.RewardedAdLoadCallback;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.google.firebase.analytics.FirebaseAnalytics;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.login.LoginMainActivity;
import com.snapdrama.shortstream.activity.premium.TopUpActivity;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.utils.coins.CoinsManager;
import com.snapdrama.shortstream.databinding.ItemReelBinding;
import com.snapdrama.shortstream.engineBox.model.detail.ShortDetailModel;
import com.stripe.android.PaymentConfiguration;
import com.stripe.android.paymentsheet.PaymentSheet;
import com.stripe.android.paymentsheet.PaymentSheetResult;

import java.io.IOException;
import java.util.HashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArrayList;

import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.SetOptions;

import java.util.HashMap;
import java.util.Map;

import okhttp3.Call;
import okhttp3.Callback;
import okhttp3.FormBody;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;

import org.json.JSONException;
import org.json.JSONObject;

public class RewardAdManager {

    public static final int PURCHASE_TYPE_COINS_PACK_1 = 1;
    public static final int PURCHASE_TYPE_COINS_PACK_2 = 2;
    public static final int PURCHASE_TYPE_COINS_PACK_3 = 3;
    public static final int PURCHASE_TYPE_COINS_PACK_4 = 4;
    public static final int PURCHASE_TYPE_WEEKLY = 10;
    public static final int PURCHASE_TYPE_YEARLY = 11;

    public static int adsViewRewardAds = 0;
    public static boolean isFailArrayId = false;
    public static String rewardAdsType = "";

    public interface LockUiListener {
        void onLockUiShown();

        void onLockUiHidden();
    }

    public static final String PREF_NAME = "reward_session_pref";
    private static final String KEY_WATCHED = "watched_count";
    private static final String KEY_REWARD_LIMIT = "reward_limit";
    private static final String KEY_REWARD_USED = "reward_used_count";
    public static final String KEY_UNLOCKED_EPISODES = "unlocked_episodes";

    private final Context context;

    private RewardedAd rewardedAd;

    private boolean adShowing = false;
    private LockUiListener lockUiListener;

    private final OkHttpClient http = new OkHttpClient();
    private final Handler mainHandler = new Handler(Looper.getMainLooper());

    private PaymentSheet paymentSheet;
    private PaymentSheet.CustomerConfiguration customerConfig;
    private String paymentIntentClientSecret;

    private BottomSheetDialog pendingStripeDialog;
    private ExoPlayer pendingStripePlayer;
    private ItemReelBinding pendingStripeReelBinding;
    private int pendingPurchaseType = 0;
    private long pendingCoinsToAdd = 0L;
    private double pendingPrice = 0.0;

    public void setPaymentSheet(@NonNull PaymentSheet sheet) {
        this.paymentSheet = sheet;
    }

    public void handlePaymentSheetResult(@NonNull PaymentSheetResult paymentSheetResult) {
        onPaymentSheetResult(paymentSheetResult);
    }

    public static void RewardAdsId(List<String> list) {
        try {
            if (list != null && !list.isEmpty() && adsViewRewardAds < list.size()) {
                isFailArrayId = true;
                rewardAdsType = list.get(adsViewRewardAds);
//                android.util.Log.d("SplashNativeAd", "Requesting Native Ad with ID at position " + adsViewRewardAds + ": " + rewardAdsType);
                adsViewRewardAds = adsViewRewardAds + 1;
            } else {
//                android.util.Log.d("SplashNativeAd", "No more Native Ad IDs to request or list is empty. Resetting index.");
                isFailArrayId = false;
                adsViewRewardAds = 0;
            }
        } catch (Exception e) {
            e.printStackTrace();
            isFailArrayId = false;
            adsViewRewardAds = 0;
        }
    }

    private void startStripePayment(
            Activity activity,
            float amount,
            int purchaseType,
            long coinsToAdd,
            double priceForPremium,
            BottomSheetDialog dialog,
            ExoPlayer player,
            ItemReelBinding reelBinding
    ) {
        if (paymentSheet == null) {
            Toast.makeText(context, "Stripe not initialized yet", Toast.LENGTH_SHORT).show();
            return;
        }

        pendingStripeDialog = dialog;
        pendingStripePlayer = player;
        pendingStripeReelBinding = reelBinding;
        pendingPurchaseType = purchaseType;
        pendingCoinsToAdd = coinsToAdd;
        pendingPrice = priceForPremium;

        validateFromServerAndPresent(activity, amount);
    }

    private void validateFromServerAndPresent(@NonNull Activity activity, float amount) {
        String apiUrl = ControlPreference.getTransactionUrl() + context.getString(R.string.end_point);
        String country = ControlPreference.getCountryName();
        String currency = country != null && country.equalsIgnoreCase("IN") ? "inr" : "usd";

        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        String email = user != null && user.getEmail() != null ? user.getEmail() : "user@example.com";
        String name = user != null && user.getDisplayName() != null ? user.getDisplayName()
                : (email.contains("@") ? email.substring(0, email.indexOf('@')) : "User");

        long amountSmallestUnit = (long) (amount * 100f);

//        FormBody body = new FormBody.Builder()
//                .add("amount", String.valueOf(amountSmallestUnit))
//                .add("currency", currency)
//                .add("email", email)
//                .add("name", name)
//                .build();
        FormBody body = new FormBody.Builder()
                .add("amount", String.valueOf(amountSmallestUnit))
                .add("currency", currency)
                .add("email", email)
                .add("name", name)
                .add("user_id", String.valueOf(user))
                .build();

        Request request = new Request.Builder()
                .url(apiUrl)
                .post(body)
                .build();

        http.newCall(request).enqueue(new Callback() {
            @Override
            public void onFailure(@NonNull Call call, @NonNull IOException e) {
                mainHandler.post(() -> Toast.makeText(context, "Payment init failed", Toast.LENGTH_SHORT).show());
            }

            @Override
            public void onResponse(@NonNull Call call, @NonNull Response response) {
                try (Response r = response) {
                    String json = r.body() != null ? r.body().string() : "";
                    JSONObject responseJson = new JSONObject(json);
                    paymentIntentClientSecret = responseJson.getString("paymentIntent");
                    String customerId = responseJson.getString("customer");
                    String ephemeralKeySecret = responseJson.getString("ephemeralKey");
                    String publishableKey = responseJson.getString("publishableKey");
                    customerConfig = new PaymentSheet.CustomerConfiguration(customerId, ephemeralKeySecret);

                    mainHandler.post(() -> {
                        try {
                            PaymentConfiguration.init(activity.getApplicationContext(), publishableKey);
                            PaymentSheet.Configuration configuration =
                                    new PaymentSheet.Configuration.Builder("Snap Drama")
                                            .customer(customerConfig)
                                            .allowsDelayedPaymentMethods(true)
                                            .build();
                            paymentSheet.presentWithPaymentIntent(paymentIntentClientSecret, configuration);
                        } catch (Exception e) {
                            Toast.makeText(context, "Stripe error", Toast.LENGTH_SHORT).show();
                        }
                    });
                } catch (Exception e) {
                    mainHandler.post(() -> Toast.makeText(context, "Payment init failed", Toast.LENGTH_SHORT).show());
                }
            }
        });
    }

    private void onPaymentSheetResult(@NonNull PaymentSheetResult paymentSheetResult) {
        if (paymentSheetResult instanceof PaymentSheetResult.Completed) {
            onStripePaymentCompleted();
            isPaymentProcessing = false;
        } else if (paymentSheetResult instanceof PaymentSheetResult.Canceled) {
            Toast.makeText(context, "Payment cancelled", Toast.LENGTH_SHORT).show();
            isPaymentProcessing = false;
        } else if (paymentSheetResult instanceof PaymentSheetResult.Failed) {
            PaymentSheetResult.Failed failed = (PaymentSheetResult.Failed) paymentSheetResult;
            isPaymentProcessing = false;
            Toast.makeText(context, context.getString(R.string.payment_failed) + ": " + (failed.getError() != null ? failed.getError().getMessage() : ""), Toast.LENGTH_SHORT).show();
        }
    }

    private void onStripePaymentCompleted() {
        String uid = FirebaseAuth.getInstance().getUid();
        if (uid == null) return;

        if (pendingPurchaseType >= PURCHASE_TYPE_COINS_PACK_1 && pendingPurchaseType <= PURCHASE_TYPE_COINS_PACK_4) {
            final long coinsToAddNow = pendingCoinsToAdd;
            if (coinsToAddNow > 0) {
                CoinsManager.addCoins(uid, coinsToAddNow,
                        unused -> Toast.makeText(context, "+" + coinsToAddNow + " coins added!", Toast.LENGTH_SHORT).show(),
                        e -> Toast.makeText(context, "Failed to add coins", Toast.LENGTH_SHORT).show());
            }
        } else if (pendingPurchaseType == PURCHASE_TYPE_WEEKLY) {
            PremiumPlanManager.savePremiumPurchaseToFirestore(context, true, false, pendingPrice,
                    PremiumPlanManager.DURATION_WEEKLY_MS, new PremiumPlanManager.SavePremiumCallback() {
                        @Override
                        public void onSuccess() {
                            Toast.makeText(context, "Weekly Membership activated! All episodes free & Ads free for 1 week.", Toast.LENGTH_LONG).show();
                        }

                        @Override
                        public void onError(Exception e) {
                            Toast.makeText(context, "Failed to activate membership. Try again.", Toast.LENGTH_SHORT).show();
                        }
                    });
        } else if (pendingPurchaseType == PURCHASE_TYPE_YEARLY) {
            PremiumPlanManager.savePremiumPurchaseToFirestore(context, false, true, pendingPrice,
                    PremiumPlanManager.DURATION_YEARLY_MS, new PremiumPlanManager.SavePremiumCallback() {
                        @Override
                        public void onSuccess() {
                            Toast.makeText(context, "Yearly Membership activated! All episodes free & Ads free for 1 year.", Toast.LENGTH_LONG).show();
                        }

                        @Override
                        public void onError(Exception e) {
                            Toast.makeText(context, "Failed to activate membership. Try again.", Toast.LENGTH_SHORT).show();
                        }
                    });
        }

        adShowing = false;
        notifyLockUiHidden();
        if (pendingStripeDialog != null) {
            pendingStripeDialog.dismiss();
            pendingStripeDialog = null;
        }
        if (pendingStripeReelBinding != null) {
            pendingStripeReelBinding.relativeWatchToUnlock.setVisibility(View.GONE);
            updateWatchAdAttemptsText(pendingStripeReelBinding);
            pendingStripeReelBinding.seekbar.setEnabled(true);
            pendingStripeReelBinding = null;
        }
        if (pendingStripePlayer != null) {
            pendingStripePlayer.setPlayWhenReady(true);
            pendingStripePlayer.play();
            pendingStripePlayer = null;
        }

        pendingPurchaseType = 0;
        pendingCoinsToAdd = 0L;
        pendingPrice = 0.0;
    }

    private float[] getPlanPriceAndCoins(String planKey) {
        try {
            String country = ControlPreference.getCountryName();
            JSONObject jsonObject = country.equalsIgnoreCase("IN")
                    ? new JSONObject(ControlPreference.getInrPlans())
                    : new JSONObject(ControlPreference.getUsdPlans());
            JSONObject plan = jsonObject.getJSONObject(planKey);
            float price = country.equalsIgnoreCase("IN") ? plan.getInt("price") : (float) plan.getDouble("price");
            int coins = plan.getInt("coins");
            int extraCoins = plan.getInt("extra_coins");


            return new float[]{price, coins + extraCoins, 0};
        } catch (Exception e) {
            return null;
        }
    }

    private static final List<Runnable> onLockUiHiddenRunnables = new CopyOnWriteArrayList<>();

    public static void addOnLockUiHiddenRunnable(Runnable r) {
        if (r != null) onLockUiHiddenRunnables.add(r);
    }

    public static void removeOnLockUiHiddenRunnable(Runnable r) {
        if (r != null) onLockUiHiddenRunnables.remove(r);
    }

    private static final long EPISODE_COIN_COST = 20L;

    public static String buildUnlockKey(String seriesId, int episodeIndex) {
        if (seriesId == null) seriesId = "unknown_series";
        return seriesId + "_ep_" + episodeIndex;
    }

    public RewardAdManager(Context context) {
        this.context = context;
        // Default 10 unless remotely configured in ControlPreference
        int cpLimit = ControlPreference.getWatchAdFreeVideo();
        if (cpLimit > 0) {
            setRewardLimit(cpLimit);
        } else if (getRewardLimit() <= 0) {
            setRewardLimit(10);
        }
        loadRewardAd();
    }

    public void setLockUiListener(LockUiListener listener) {
        this.lockUiListener = listener;
    }

    private void notifyLockUiShown() {
        if (lockUiListener != null) lockUiListener.onLockUiShown();
    }

    private void notifyLockUiHidden() {
        if (lockUiListener != null) lockUiListener.onLockUiHidden();
        for (Runnable r : onLockUiHiddenRunnables) {
            try {
                r.run();
            } catch (Exception ignored) {
            }
        }
    }

    private SharedPreferences prefs() {
        return context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
    }

    public void setRewardLimit(int limit) {
        prefs().edit().putInt(KEY_REWARD_LIMIT, Math.max(0, limit)).apply();
    }

    public int getRewardLimit() {
        int saved = prefs().getInt(KEY_REWARD_LIMIT, 10);
        return Math.max(0, saved);
    }

    public int getRewardUsedCount() {
        int used = prefs().getInt(KEY_REWARD_USED, 0);
        return Math.max(0, used);
    }

    private void incrementRewardUsed() {
        int used = getRewardUsedCount();
        prefs().edit().putInt(KEY_REWARD_USED, used + 1).apply();
    }

    public boolean canWatchAdToUnlock() {
        int limit = getRewardLimit();
        if (limit <= 0) return false;
        return getRewardUsedCount() < limit;
    }

    public void updateWatchAdAttemptsText(ItemReelBinding binding) {
        if (binding == null || binding.textWatchFreeVideos == null) return;
        int limit = getRewardLimit();
        int used = getRewardUsedCount();
        if (limit <= 0 || used >= limit) {
            binding.textWatchFreeVideos.setVisibility(View.GONE);
        } else {
            binding.textWatchFreeVideos.setVisibility(View.VISIBLE);
            binding.textWatchFreeVideos.setText("Free Unlock Attempts ( " + used + " / " + limit + " )");
        }
    }

    public boolean isEpisodeUnlocked(String unlockKey) {
        if (unlockKey == null || unlockKey.trim().isEmpty()) return false;
        Set<String> set = prefs().getStringSet(KEY_UNLOCKED_EPISODES, null);
        return set != null && set.contains(unlockKey);
    }

    private void markEpisodeUnlocked(String unlockKey) {
        if (unlockKey == null || unlockKey.trim().isEmpty()) return;
        Set<String> current = prefs().getStringSet(KEY_UNLOCKED_EPISODES, null);
        Set<String> copy = current == null ? new HashSet<>() : new HashSet<>(current);
        if (copy.add(unlockKey)) {
            prefs().edit().putStringSet(KEY_UNLOCKED_EPISODES, copy).apply();
        }
    }


    public void onVideoCompleted() {
        int count = getWatchedCount();
        saveWatchedCount(count + 1);
    }

    private int getWatchedCount() {
        return context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                .getInt(KEY_WATCHED, 0);
    }

    private void saveWatchedCount(int count) {
        context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                .edit()
                .putInt(KEY_WATCHED, count)
                .apply();
    }


    public boolean handleBeforePlay(ExoPlayer player) {

        return false;
    }

    public boolean verifyVideoLock(int position,
                                   String unlockKey,
                                   ExoPlayer player,
                                   ShortDetailModel shortDetailModel,
                                   ItemReelBinding binding) {

        binding.relativeWatchToUnlock.setVisibility(View.GONE);
        updateWatchAdAttemptsText(binding);

        // Premium user: all episodes free and ads-free
        if (PremiumPlanManager.shouldSkipAfterLoginAd(context)) {
            binding.seekbar.setEnabled(true);
            notifyLockUiHidden();
            return false;
        }

        int freeEpisodes = ControlPreference.getUserFreeEpisodes();
        if (position < freeEpisodes) {
            binding.seekbar.setEnabled(true);
            notifyLockUiHidden();
            return false;
        }

        if (isEpisodeUnlocked(unlockKey)) {
            binding.seekbar.setEnabled(true);
            notifyLockUiHidden();
            return false;
        }

        player.setPlayWhenReady(false);
        player.pause();
        binding.seekbar.setEnabled(false);

        binding.btnUnlock.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                showBottomSheet((Activity) context, player, shortDetailModel, binding, unlockKey, EPISODE_COIN_COST, position);
            }
        });

        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();

        if (user != null) {
            binding.btnSignIn.setVisibility(View.GONE);


        } else {
            binding.btnSignIn.setVisibility(View.VISIBLE);
        }

        binding.btnSignIn.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(context, LoginMainActivity.class);
                intent.putExtra("ForWardScreenName", "ReelsShowActivity");
                context.startActivity(intent);
            }
        });

        binding.btnWatchToAds.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!canWatchAdToUnlock()) {
                    updateWatchAdAttemptsText(binding);
                    Toast.makeText(context, "Free unlock attempts finished", Toast.LENGTH_SHORT).show();
                    adShowing = false;
                    notifyLockUiShown();
                    return;
                }
                showRewardAd(player, binding, unlockKey);
            }
        });

        if (adShowing) {
            binding.relativeWatchToUnlock.setVisibility(View.VISIBLE);
            updateWatchAdAttemptsText(binding);
            notifyLockUiShown();
            return true;
        }

        adShowing = true;

        binding.relativeWatchToUnlock.setVisibility(View.VISIBLE);
        updateWatchAdAttemptsText(binding);
        notifyLockUiShown();

        return true;
    }

    private void setPremiumPlans(View view) {

        TextView textPrice1 = view.findViewById(R.id.textPrice1);
        TextView textPrice2 = view.findViewById(R.id.textPrice2);
        TextView textPrice3 = view.findViewById(R.id.textPrice3);
        TextView textPrice4 = view.findViewById(R.id.textPrice4);

        TextView textViewMainCoin1 = view.findViewById(R.id.textViewMainCoin1);
        TextView textViewMainCoin2 = view.findViewById(R.id.textViewMainCoin2);
        TextView textViewMainCoin3 = view.findViewById(R.id.textViewMainCoin3);
        TextView textViewMainCoin4 = view.findViewById(R.id.textViewMainCoin4);

        TextView textViewExtraCoin1 = view.findViewById(R.id.textViewExtraCoin1);
        TextView textViewExtraCoin2 = view.findViewById(R.id.textViewExtraCoin2);
        TextView textViewExtraCoin3 = view.findViewById(R.id.textViewExtraCoin3);
        TextView textViewExtraCoin4 = view.findViewById(R.id.textViewExtraCoin4);
        TextView tvWeeklyMemberShip1 = view.findViewById(R.id.tvWeeklyMemberShip1);
        TextView tvWeeklyMemberShip2 = view.findViewById(R.id.tvWeeklyMemberShip2);
        TextView tvWeeklyMemberTitle = view.findViewById(R.id.tvWeeklyMemberTitle);

        TextView tvYearlyMemberShip1 = view.findViewById(R.id.tvYearlyMemberShip1);
        TextView tvYearlyMemberShip2 = view.findViewById(R.id.tvYearlyMemberShip3);
        TextView tvYearlyMemberTitle = view.findViewById(R.id.tvYearlyMemberTitle);
        tvWeeklyMemberShip2.setPaintFlags(Paint.STRIKE_THRU_TEXT_FLAG);
        try {

            String country = ControlPreference.getCountryName();

            JSONObject jsonObject;

            if (country.equalsIgnoreCase("IN")) {
                jsonObject = new JSONObject(ControlPreference.getInrPlans());
            } else {
                jsonObject = new JSONObject(ControlPreference.getUsdPlans());
            }

            JSONObject plan1 = jsonObject.getJSONObject("standard_plan_1");
            setPlanData(plan1, textPrice1, textViewMainCoin1, textViewExtraCoin1, country);

            JSONObject plan2 = jsonObject.getJSONObject("standard_plan_2");
            setPlanData(plan2, textPrice2, textViewMainCoin2, textViewExtraCoin2, country);

            JSONObject plan3 = jsonObject.getJSONObject("standard_plan_3");
            setPlanData(plan3, textPrice3, textViewMainCoin3, textViewExtraCoin3, country);

            JSONObject plan4 = jsonObject.getJSONObject("standard_plan_4");
            setPlanData(plan4, textPrice4, textViewMainCoin4, textViewExtraCoin4, country);

            JSONObject plan5 = jsonObject.getJSONObject("weekly_membership");
            setMemberPlan(plan5, tvWeeklyMemberShip1, tvWeeklyMemberShip2, tvWeeklyMemberTitle, country);

            JSONObject plan6 = jsonObject.getJSONObject("yearly_membership");
            setMemberPlan(plan6, tvYearlyMemberShip1, tvYearlyMemberShip2, tvYearlyMemberTitle, country);

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setMemberPlan(JSONObject plan5, TextView tvWeeklyMemberShip1, TextView tvWeeklyMemberShip2, TextView tvWeeklyMemberTitle, String country) {
        try {

            double main_price = plan5.getDouble("main_price");
            String discount_price = plan5.getString("discount_price");
            String title = plan5.getString("title");


            if (country.equalsIgnoreCase("IN")) {
                tvWeeklyMemberShip1.setText("₹ " + main_price);
                tvWeeklyMemberShip2.setText(discount_price);
                tvWeeklyMemberTitle.setText(title);
            } else {
                tvWeeklyMemberShip1.setText("$ " + main_price);
                tvWeeklyMemberShip2.setText(discount_price);
                tvWeeklyMemberTitle.setText(" + " + title);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private void setPlanData(JSONObject plan,
                             TextView priceView,
                             TextView mainCoinView,
                             TextView extraCoinView,
                             String country) {

        try {

            int coins = plan.getInt("coins");
            int extraCoins = plan.getInt("extra_coins");

            mainCoinView.setText(String.valueOf(coins));
            extraCoinView.setText(" + " + extraCoins);

            if (country.equalsIgnoreCase("IN")) {
                int price = plan.getInt("price");
                priceView.setText("₹ " + price);
            } else {
                double price = plan.getDouble("price");
                priceView.setText("$ " + price);
            }

        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private boolean isPaymentProcessing = false;

    private void saveConsumptionRecord(String unlockKey, ShortDetailModel shortDetailModel, int episodeIndex, long episodeCost) {
        String userId = FirebaseAuth.getInstance().getUid();
        if (userId == null) return;

        FirebaseFirestore db = FirebaseFirestore.getInstance();

        DocumentReference ref = db.collection("users")
                .document(userId)
                .collection("consumption_records")
                .document(unlockKey);

        Map<String, Object> map = new HashMap<>();
        map.put("seriesId", shortDetailModel != null ? shortDetailModel.getId() : "");
        map.put("episodeName", shortDetailModel != null ? shortDetailModel.getTitle() : "");
        map.put("episodePhoto", shortDetailModel != null ? shortDetailModel.getCover() : "");
        map.put("episodeDesc", shortDetailModel != null ? shortDetailModel.getDescription() : "");
        map.put("episodeNumber", episodeIndex);
        map.put("episodeSpendCutTime", FieldValue.serverTimestamp());
        map.put("spendPrice", episodeCost);
        map.put("unlockKey", unlockKey);

        ref.set(map, SetOptions.merge());
    }

    private void showBottomSheet(
            Activity activity,
            ExoPlayer player,
            ShortDetailModel shortDetailModel,
            ItemReelBinding reelBinding,
            String unlockKey,
            long episodeCost,
            int episodeIndex
    ) {
        BottomSheetDialog bottomSheetDialog =
                new BottomSheetDialog(activity, R.style.TransparentBottomSheetDialog);
        View view = LayoutInflater.from(activity)
                .inflate(R.layout.layout_premium_dialog, null);


        bottomSheetDialog.setContentView(view);
        bottomSheetDialog.setCancelable(true);

        View bottomSheet =
                bottomSheetDialog.findViewById(com.google.android.material.R.id.design_bottom_sheet);

        if (bottomSheet != null) {
            bottomSheet.setBackgroundResource(android.R.color.transparent);
        }

        ImageView ivClose = view.findViewById(R.id.ivClose);
        TextView tvBalanceValue = view.findViewById(R.id.tvBalanceValue);
        TextView tvEpisodeCost = view.findViewById(R.id.tvEpisodeCost);
        TextView btnUnlockEpisode = view.findViewById(R.id.btnUnlockEpisode);
        View pack1 = view.findViewById(R.id.pack1);
        View pack2 = view.findViewById(R.id.pack2);
        View pack3 = view.findViewById(R.id.pack3);
        View pack4 = view.findViewById(R.id.pack4);
        View relativeWeeklyMemberShip = view.findViewById(R.id.relativeWeeklyMemberShip);
        View relativeYearlyMemberShip = view.findViewById(R.id.relativeYearlyMemberShip);

        setPremiumPlans(view);
        if (tvEpisodeCost != null) {
            tvEpisodeCost.setText(String.valueOf(episodeCost));
        }

        if (ivClose != null) {
            ivClose.setOnClickListener(v -> bottomSheetDialog.dismiss());
        }

        final String uid = FirebaseAuth.getInstance().getUid();
        if (uid == null) {
            if (btnUnlockEpisode != null) btnUnlockEpisode.setEnabled(false);
            Toast.makeText(context, "Please login to use coins", Toast.LENGTH_SHORT).show();
            bottomSheetDialog.show();
            return;
        }

        ListenerRegistration[] reg = new ListenerRegistration[1];
        reg[0] = CoinsManager.listenCoins(uid, new CoinsManager.CoinsListener() {
            @Override
            public void onCoinsChanged(long coins) {
                if (tvBalanceValue != null) tvBalanceValue.setText(String.valueOf(coins));
                if (btnUnlockEpisode != null) {
                    boolean canUnlock = coins >= episodeCost;
                    btnUnlockEpisode.setEnabled(canUnlock);
                    btnUnlockEpisode.setAlpha(canUnlock ? 1f : 0.6f);
                    btnUnlockEpisode.setText(canUnlock
                            ? ("Unlock for " + episodeCost + " coins")
                            : ("Need " + episodeCost + " coins to unlock"));
                }
            }

            @Override
            public void onError(@NonNull Exception e) {
            }
        });

        bottomSheetDialog.setOnDismissListener(d -> {
            if (reg[0] != null) {
                reg[0].remove();
                reg[0] = null;
            }
        });

        if (btnUnlockEpisode != null) {
            btnUnlockEpisode.setOnClickListener(v -> {
                CoinsManager.spendCoins(uid, episodeCost, new CoinsManager.SpendCallback() {
                    @Override
                    public void onSuccess(long newBalance) {
                        saveConsumptionRecord(unlockKey, shortDetailModel, episodeIndex, episodeCost);
                        markEpisodeUnlocked(unlockKey);
                        adShowing = false;
                        notifyLockUiHidden();
                        if (reelBinding != null) {
                            reelBinding.relativeWatchToUnlock.setVisibility(View.GONE);
                            updateWatchAdAttemptsText(reelBinding);
                            reelBinding.seekbar.setEnabled(true);
                        }
                        bottomSheetDialog.dismiss();
                        player.setPlayWhenReady(true);
                        player.play();
                    }

                    @Override
                    public void onInsufficient(long currentBalance) {
                        Toast.makeText(context, "Not enough coins", Toast.LENGTH_SHORT).show();
                    }

                    @Override
                    public void onError(@NonNull Exception e) {
                        Toast.makeText(context, "Failed to unlock", Toast.LENGTH_SHORT).show();
                    }
                });
            });
        }

        View.OnClickListener packClickListener = v -> {
            FirebaseUser firebaseUser = FirebaseAuth.getInstance().getCurrentUser();

            if (firebaseUser == null) {
                Toast.makeText(activity, "Please Login First", Toast.LENGTH_SHORT).show();
                return;
            }
            int id = v.getId();
            String planKey;
            int purchaseType;
            if (id == R.id.pack1) {
                planKey = "standard_plan_1";
                purchaseType = PURCHASE_TYPE_COINS_PACK_1;
            } else if (id == R.id.pack2) {
                planKey = "standard_plan_2";
                purchaseType = PURCHASE_TYPE_COINS_PACK_2;
            } else if (id == R.id.pack3) {
                planKey = "standard_plan_3";
                purchaseType = PURCHASE_TYPE_COINS_PACK_3;
            } else if (id == R.id.pack4) {
                planKey = "standard_plan_4";
                purchaseType = PURCHASE_TYPE_COINS_PACK_4;
            } else return;

            float[] planData = getPlanPriceAndCoins(planKey);
            float amount = (planData != null) ? planData[0] : (id == R.id.pack1 ? 99f : id == R.id.pack2 ? 49f : id == R.id.pack3 ? 199f : 499f);
            long coinsToAdd = (planData != null && planData.length > 1) ? (long) planData[1] : (id == R.id.pack1 ? 500L : id == R.id.pack2 ? 200L : id == R.id.pack3 ? 550L : 1350L);
            if (isPaymentProcessing) return;
            isPaymentProcessing = true;
            startStripePayment(activity, amount, purchaseType, coinsToAdd, 0.0, bottomSheetDialog, player, reelBinding);
        };

        if (pack1 != null) pack1.setOnClickListener(packClickListener);
        if (pack2 != null) pack2.setOnClickListener(packClickListener);
        if (pack3 != null) pack3.setOnClickListener(packClickListener);
        if (pack4 != null) pack4.setOnClickListener(packClickListener);

        String country = ControlPreference.getCountryName();

        JSONObject jsonObject;
        double main_price_weekly;
        double main_price_yearly;

        if (country.equalsIgnoreCase("IN")) {
            try {
                jsonObject = new JSONObject(ControlPreference.getInrPlans());
                JSONObject plan5 = jsonObject.getJSONObject("weekly_membership");
                JSONObject plan6 = jsonObject.getJSONObject("yearly_membership");


                main_price_weekly = plan5.getDouble("main_price");
                main_price_yearly = plan6.getDouble("main_price");


            } catch (JSONException e) {
                throw new RuntimeException(e);
            }
        } else {
            try {
                jsonObject = new JSONObject(ControlPreference.getUsdPlans());
                JSONObject plan5 = jsonObject.getJSONObject("weekly_membership");
                JSONObject plan6 = jsonObject.getJSONObject("yearly_membership");


                main_price_weekly = plan5.getDouble("main_price");
                main_price_yearly = plan6.getDouble("main_price");


            } catch (JSONException e) {
                throw new RuntimeException(e);
            }

        }


        if (relativeWeeklyMemberShip != null) {
            double finalMain_price = main_price_weekly;
            relativeWeeklyMemberShip.setOnClickListener(v -> {
                FirebaseUser firebaseUser = FirebaseAuth.getInstance().getCurrentUser();

                if (firebaseUser == null) {
                    Toast.makeText(activity, "Please Login First", Toast.LENGTH_SHORT).show();
                    return;
                }
                if (isPaymentProcessing) return;
                isPaymentProcessing = true;

                startStripePayment(activity, Float.valueOf(String.valueOf(finalMain_price)), PURCHASE_TYPE_WEEKLY, 0L, finalMain_price, bottomSheetDialog, player, reelBinding);
            });
        }

        if (relativeYearlyMemberShip != null) {
            double finalMain_price1 = main_price_yearly;
            relativeYearlyMemberShip.setOnClickListener(v -> {
                FirebaseUser firebaseUser = FirebaseAuth.getInstance().getCurrentUser();

                if (firebaseUser == null) {
                    Toast.makeText(activity, "Please Login First", Toast.LENGTH_SHORT).show();
                    return;
                }
                if (isPaymentProcessing) return;
                isPaymentProcessing = true;
                startStripePayment(activity, Float.valueOf(String.valueOf(finalMain_price1)), PURCHASE_TYPE_YEARLY, 0L, finalMain_price1, bottomSheetDialog, player, reelBinding);
            });
        }

        bottomSheetDialog.show();

    }

    public void showWatchRewardDialog(Activity activity, ExoPlayer player, ShortDetailModel shortDetailModel) {
//
//        Dialog dialog = new Dialog(activity);
//        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
//        dialog.setContentView(R.layout.layout_premium_dialog);
//        dialog.setCancelable(true);

//        TextView textViewWatchAd = dialog.findViewById(R.id.textViewEpisode);
//        TextView textViewUnlock = dialog.findViewById(R.id.textViewUnlock);
//        TextView textView1 = dialog.findViewById(R.id.textView1);
//        TextView textView2 = dialog.findViewById(R.id.textView2);
//        TextView textViewAttempts = dialog.findViewById(R.id.textViewAttempts);
//        ImageView imageSeries = dialog.findViewById(R.id.imageSeries);
//        TextView buttonSkip = dialog.findViewById(R.id.buttonSkip);
//
//        // Series info
//        Glide.with(context).load(shortDetailModel.getCover()).placeholder(R.drawable.image_poster_placeholder).into(imageSeries);
//        textView1.setText(shortDetailModel.getTitle());
//        textView2.setText(shortDetailModel.getDescription());
//
//        // Attempts label: watched / freeLimit
//        int used = getWatchedCount();
//        int limit = getFreeLimit();
//        if (textViewAttempts != null) {
//            textViewAttempts.setText("Free Unlock Attempts (" + used + "/" + limit + ")");
//        }
//
//        // 1) Sign in / back (current Skip button)
//        buttonSkip.setOnClickListener(v -> {
//            dialog.dismiss();
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                if (activity instanceof ReelsShowAllActivity) {
//                    activity.finish();
//                }
//            }
//        });
//
//        // 2) Direct unlock (coins – placeholder)
//        if (textViewUnlock != null) {
//            textViewUnlock.setOnClickListener(v -> {
//                // TODO: integrate coin deduction here
//                singleVideoUnlocked = true;
//                adShowing = false;
//                dialog.dismiss();
//                player.play();
//            });
//        }
//
//        // 3) Watch ad to unlock
//        textViewWatchAd.setOnClickListener(v -> {
//            dialog.dismiss();
//            showRewardAd(player);
//        });
//
//        if (dialog.getWindow() != null) {
//            dialog.getWindow().setBackgroundDrawable(
//                    new ColorDrawable(Color.TRANSPARENT)
//            );
//
//            Window window = dialog.getWindow();
//            WindowManager.LayoutParams params = window.getAttributes();
//            params.width = WindowManager.LayoutParams.MATCH_PARENT;
//            params.height = WindowManager.LayoutParams.WRAP_CONTENT;
//            params.gravity = Gravity.CENTER;
//            window.setAttributes(params);
//        }


//        dialog.show();
    }

//    public void showWatchRewardDialog(Activity activity, ExoPlayer player, ShortDetailModel shortDetailModel) {
//
//        Dialog dialog = new Dialog(activity);
//        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
//        dialog.setContentView(R.layout.layout_reward_claim);
//        dialog.setCancelable(true);
//
//        TextView textViewWatchAd = dialog.findViewById(R.id.textViewEpisode);
//        TextView textViewUnlock = dialog.findViewById(R.id.textViewUnlock);
//        TextView textView1 = dialog.findViewById(R.id.textView1);
//        TextView textView2 = dialog.findViewById(R.id.textView2);
//        TextView textViewAttempts = dialog.findViewById(R.id.textViewAttempts);
//        ImageView imageSeries = dialog.findViewById(R.id.imageSeries);
//        TextView buttonSkip = dialog.findViewById(R.id.buttonSkip);
//
//        // Series info
//        Glide.with(context).load(shortDetailModel.getCover()).placeholder(R.drawable.image_poster_placeholder).into(imageSeries);
//        textView1.setText(shortDetailModel.getTitle());
//        textView2.setText(shortDetailModel.getDescription());
//
//        // Attempts label: watched / freeLimit
//        int used = getWatchedCount();
//        int limit = getFreeLimit();
//        if (textViewAttempts != null) {
//            textViewAttempts.setText("Free Unlock Attempts (" + used + "/" + limit + ")");
//        }
//
//        // 1) Sign in / back (current Skip button)
//        buttonSkip.setOnClickListener(v -> {
//            dialog.dismiss();
//            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
//                if (activity instanceof ReelsShowAllActivity) {
//                    activity.finish();
//                }
//            }
//        });
//
//        // 2) Direct unlock (coins – placeholder)
//        if (textViewUnlock != null) {
//            textViewUnlock.setOnClickListener(v -> {
//                // TODO: integrate coin deduction here
//                singleVideoUnlocked = true;
//                adShowing = false;
//                dialog.dismiss();
//                player.play();
//            });
//        }
//
//        // 3) Watch ad to unlock
//        textViewWatchAd.setOnClickListener(v -> {
//            dialog.dismiss();
//            showRewardAd(player);
//        });
//
//        if (dialog.getWindow() != null) {
//            dialog.getWindow().setBackgroundDrawable(
//                    new ColorDrawable(Color.TRANSPARENT)
//            );
//
//            Window window = dialog.getWindow();
//            WindowManager.LayoutParams params = window.getAttributes();
//            params.width = WindowManager.LayoutParams.MATCH_PARENT;
//            params.height = WindowManager.LayoutParams.WRAP_CONTENT;
//            params.gravity = Gravity.CENTER;
//            window.setAttributes(params);
//        }
//
//
//
//        dialog.show();
//    }

    private void loadRewardAd() {
        RewardAdsId(ControlPreference.get_RewardList_Ids_List());
        if (!isFailArrayId) {
            return;
        }
        RewardedAd.load(
                context,
                rewardAdsType,
                new AdRequest.Builder().build(),
                new RewardedAdLoadCallback() {

                    @Override
                    public void onAdLoaded(@NonNull RewardedAd ad) {
                        FirebaseAnalytics firebaseAnalytics;
                        firebaseAnalytics = FirebaseAnalytics.getInstance(context);
                        ad.setOnPaidEventListener(new OnPaidEventListener() {
                            @Override
                            public void onPaidEvent(AdValue adValue) {
                                double revenue = adValue.getValueMicros() / 1_000_000.0;
                                String currency = adValue.getCurrencyCode();
                                Bundle adRevenueParams = new Bundle();
                                adRevenueParams.putString(FirebaseAnalytics.Param.AD_PLATFORM, "Google Ad Manager");
                                adRevenueParams.putString(FirebaseAnalytics.Param.CURRENCY, currency);
                                adRevenueParams.putDouble(FirebaseAnalytics.Param.VALUE, revenue);
                                firebaseAnalytics.logEvent(FirebaseAnalytics.Event.AD_IMPRESSION, adRevenueParams);
                            }
                        });
                        rewardedAd = ad;
                    }

                    @Override
                    public void onAdFailedToLoad(@NonNull LoadAdError error) {
                        rewardedAd = null;
                    }
                }
        );
    }

    private void showRewardAd(ExoPlayer player, ItemReelBinding binding, String unlockKey) {
        if (rewardedAd == null) {
            adShowing = false;
            loadRewardAd();
            Toast.makeText(context, "Ad not ready", Toast.LENGTH_SHORT).show();
            return;
        }

        RewardedAd ad = rewardedAd;
        rewardedAd = null;

        ad.setFullScreenContentCallback(new FullScreenContentCallback() {
            @Override
            public void onAdDismissedFullScreenContent() {
                adShowing = false;
                loadRewardAd();
            }

            @Override
            public void onAdFailedToShowFullScreenContent(@NonNull AdError adError) {
                adShowing = false;
                loadRewardAd();
            }
        });

        ad.show((Activity) context, reward -> {
            // Consume 1 attempt and permanently unlock this episode
            incrementRewardUsed();
            markEpisodeUnlocked(unlockKey);

            adShowing = false;
            notifyLockUiHidden();

            if (binding != null) {
                binding.relativeWatchToUnlock.setVisibility(View.GONE);
                updateWatchAdAttemptsText(binding);
                binding.seekbar.setEnabled(true);
            }

            player.setPlayWhenReady(true);
            player.play();

            loadRewardAd();
        });
    }
}


