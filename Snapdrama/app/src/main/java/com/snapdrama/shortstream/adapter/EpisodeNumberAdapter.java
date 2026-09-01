package com.snapdrama.shortstream.adapter;

import android.content.Context;
import android.content.SharedPreferences;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.airbnb.lottie.LottieAnimationView;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.main.fragment.reels.interfaces.OnEpisodeClickListener;
import com.snapdrama.shortstream.ads.PremiumPlanManager;
import com.snapdrama.shortstream.ads.RewardAdManager;

import java.util.Set;

public class EpisodeNumberAdapter
        extends RecyclerView.Adapter<EpisodeNumberAdapter.ViewHolder> {

    private final int start, end;
    private final String seriesId;
    private final Context context;
    private final OnEpisodeClickListener listener;

    private int selectedEpisodeIndex = -1;

    private static final String PREFS_NAME = "EpisodePrefs";
    private static final String KEY_SELECTED_EPISODE = "selected_episode";

    public EpisodeNumberAdapter(
            Context context,
            String seriesId,
            int start,
            int end,
            OnEpisodeClickListener listener) {

        this.context = context;
        this.seriesId = seriesId;
        this.start = start;
        this.end = end;
        this.listener = listener;

        SharedPreferences prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
        selectedEpisodeIndex = prefs.getInt(KEY_SELECTED_EPISODE, -1);
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(
            @NonNull ViewGroup parent,
            int viewType) {

        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.layout_episodes_number, parent, false);
        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        int episodeNumber = start + position;
        int episodeIndex = episodeNumber - 1;

        holder.txtItem.setText(String.valueOf(episodeNumber));

        // Hide lock: free episodes (1-10), OR purchased with coins for this episode, OR active premium (weekly/yearly) membership
        boolean isFree = episodeNumber <= 10;
        boolean isUnlockedByCoins = isEpisodeUnlocked(episodeIndex);
        boolean isPremiumActive = PremiumPlanManager.isPremiumActive(context);
        boolean shouldHideLock = isFree || isUnlockedByCoins || isPremiumActive;
        if (holder.imgLock != null) {
            holder.imgLock.setVisibility(shouldHideLock ? View.INVISIBLE : View.VISIBLE);
        }

        boolean isSelected = (episodeIndex == selectedEpisodeIndex);
        applySelectionStyle(holder, isSelected);

        holder.itemView.setOnClickListener(v -> {
            int oldSelected = selectedEpisodeIndex;
            selectedEpisodeIndex = episodeIndex;

            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                    .edit()
                    .putInt(KEY_SELECTED_EPISODE, selectedEpisodeIndex)
                    .apply();

            if (oldSelected >= start && oldSelected <= end) {
                notifyItemChanged(oldSelected - start);
            }
            notifyItemChanged(position);

            if (listener != null) {
                listener.onEpisodeClicked(episodeIndex);
            }
        });
    }

    @Override
    public int getItemCount() {
        return (end - start) + 1;
    }

    private void applySelectionStyle(ViewHolder holder, boolean selected) {
        if (selected) {
            holder.relativeSeriesNumber.setBackground(ContextCompat.getDrawable(context, R.drawable.background_episode_num_select_red));
            holder.relativeSeriesNumber2.setBackground(ContextCompat.getDrawable(context, R.drawable.background_episode_num_select_red2));
            holder.txtItem.setTextColor(ContextCompat.getColor(context, R.color.grid_color));
            holder.lottieAnimation.setVisibility(View.VISIBLE);
        } else {
            holder.relativeSeriesNumber.setBackground(ContextCompat.getDrawable(context, R.drawable.background_episode_num));
            holder.relativeSeriesNumber2.setBackgroundColor(ContextCompat.getColor(context, android.R.color.transparent));
            holder.txtItem.setTextColor(ContextCompat.getColor(context, R.color.white));
            holder.lottieAnimation.setVisibility(View.INVISIBLE);
        }
    }

    private boolean isEpisodeUnlocked(int episodeIndex) {
        SharedPreferences prefs = context.getSharedPreferences(RewardAdManager.PREF_NAME, Context.MODE_PRIVATE);
        Set<String> set = prefs.getStringSet(RewardAdManager.KEY_UNLOCKED_EPISODES, null);
        if (set == null || set.isEmpty()) return false;
        String unlockKey = RewardAdManager.buildUnlockKey(seriesId, episodeIndex);
        return set.contains(unlockKey);
    }

    static class ViewHolder extends RecyclerView.ViewHolder {

        TextView txtItem;
        RelativeLayout relativeSeriesNumber;
        RelativeLayout relativeSeriesNumber2;
        LottieAnimationView lottieAnimation;
        ImageView imgLock;

        ViewHolder(View itemView) {
            super(itemView);
            txtItem = itemView.findViewById(R.id.textEpisodesNumber);
            relativeSeriesNumber = itemView.findViewById(R.id.relativeSeriesNumber);
            relativeSeriesNumber2 = itemView.findViewById(R.id.relativeSeriesNumber2);
            lottieAnimation = itemView.findViewById(R.id.lottieAnimation);
            imgLock = itemView.findViewById(R.id.imgLock);
        }
    }
}