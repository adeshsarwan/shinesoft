package com.snapdrama.shortstream.activity.full_reels.adapter;

import static android.content.Context.LAYOUT_INFLATER_SERVICE;
import static android.view.View.VISIBLE;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.net.Uri;
import android.os.Build;
import android.graphics.drawable.ColorDrawable;
import android.os.Handler;
import android.os.Looper;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewConfiguration;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.PopupWindow;
import android.widget.SeekBar;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.core.content.FileProvider;
import androidx.fragment.app.FragmentManager;
import androidx.lifecycle.Lifecycle;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager2.widget.ViewPager2;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.CustomTarget;
import com.bumptech.glide.request.transition.Transition;
import com.google.ads.interactivemedia.v3.api.AdEvent;
import com.google.ads.interactivemedia.v3.api.ImaSdkFactory;
import com.google.ads.interactivemedia.v3.api.ImaSdkSettings;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.ext.ima.ImaAdsLoader;
import com.google.android.exoplayer2.source.DefaultMediaSourceFactory;
import com.google.android.exoplayer2.source.MediaSource;
import com.google.android.exoplayer2.upstream.DataSource;
import com.google.android.exoplayer2.upstream.DefaultDataSource;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.adapter.CategoryNameAdapter;
import com.snapdrama.shortstream.ads.RewardAdManager;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.databinding.ItemReelBinding;
import com.snapdrama.shortstream.databinding.LayoutPopupDialogBinding;
import com.snapdrama.shortstream.engineBox.model.videodata.AllEpisodeModel;
import com.snapdrama.shortstream.engineBox.model.detail.ShortDetailModel;
import com.snapdrama.shortstream.activity.main.fragment.reels.fragment.MainPagerAdapter;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.ui.AspectRatioFrameLayout;
import com.google.android.exoplayer2.ui.PlayerView;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.snapdrama.shortstream.activity.main.fragment.reels.interfaces.PipPlayerListener;
import com.snapdrama.shortstream.activity.full_reels.ReelsShowActivity;

import java.io.File;
import java.io.FileOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import kotlin.jvm.internal.DefaultConstructorMarker;

public final class FullReelsAdapter extends RecyclerView.Adapter<FullReelsAdapter.ReelViewHolder> {
    private Set<String> addedEpisodeIds = new HashSet<>();
    private boolean completionHandled = false;
    private BottomSheetDialog activeBottomSheetDialog;

    public void dismissBottomSheet() {
        if (activeBottomSheetDialog != null && activeBottomSheetDialog.isShowing()) {
            activeBottomSheetDialog.dismiss();
            activeBottomSheetDialog = null;
        }
    }
    public void setAddedEpisodeIds(Set<String> ids) {
        this.addedEpisodeIds.clear();
        if (ids != null) {
            this.addedEpisodeIds.addAll(ids);
        }
        notifyDataSetChanged();


}
    RewardAdManager rewardUnlocker;
    private ImaAdsLoader adsLoader;
    public static final Companion Companion = new Companion(null);
    private static FullReelsAdapter instance;
    private final Context context;
    private int currentPlayingPosition;
    private final ActivityResultLauncher<Intent> infoLauncher;
    private boolean isMuted;
    private boolean isSeries;
    private final List<ExoPlayer> players;
    private RecyclerView recyclerView;
    private boolean scrollBlockedByLock = false;
    private boolean lockTouchListenerAttached = false;
    private int lockTouchSlop = 0;
    private float lockDownY = 0f;
    private boolean lockHasDown = false;
    private final RecyclerView.OnItemTouchListener lockTouchListener = new RecyclerView.SimpleOnItemTouchListener() {
        @Override
        public boolean onInterceptTouchEvent(@NonNull RecyclerView rv, @NonNull MotionEvent e) {
            if (!scrollBlockedByLock) return false;

            // While lock UI is visible, allow ONLY "previous video" direction.
            // Block "next video" direction (typical reels: swipe UP -> next).
            switch (e.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    lockDownY = e.getY();
                    lockHasDown = true;
                    return false;

                case MotionEvent.ACTION_MOVE:
                    if (!lockHasDown) {
                        lockDownY = e.getY();
                        lockHasDown = true;
                        return false;
                    }

                    float dy = e.getY() - lockDownY; // +dy: finger moved down, -dy: finger moved up
                    if (Math.abs(dy) < lockTouchSlop) return false;

                    // Finger moved UP => user tries to go to NEXT item -> block.
                    if (dy < 0f) {
                        rv.stopScroll();
                        return true;
                    }
                    return false;

                case MotionEvent.ACTION_CANCEL:
                case MotionEvent.ACTION_UP:
                    lockHasDown = false;
                    return false;
            }

            return false;
        }

        @Override
        public void onTouchEvent(@NonNull RecyclerView rv, @NonNull MotionEvent e) {
            // If we intercepted, keep it stable (no fling).
            if (scrollBlockedByLock) {
                rv.stopScroll();
            }
        }
    };
    private List<AllEpisodeModel> reels;
    private final Activity activity;
    private Runnable updateSeekBarRunnable;
    private Handler handler;

    private FragmentManager fragmentManager;
    private Lifecycle lifecycle;
    private int lastSavedBucket = -1;

    private final Map<Integer, Long> savedVideoPositions = new HashMap<>();

    private boolean isInPictureInPictureMode = false;
    private boolean IsListHistory = false;

    public final List<AllEpisodeModel> getReels() {
        return (List<AllEpisodeModel>) this.reels;
    }

    private ImaSdkSettings imaSdkSettings;

    List<ShortDetailModel> shortDetailModels;

    private ImaSdkSettings getImaSdkSettings() {
        if (imaSdkSettings == null) {
            imaSdkSettings = ImaSdkFactory.getInstance().createImaSdkSettings();
        }
        return imaSdkSettings;
    }

    public AdEvent.AdEventListener buildAdEventListener() {


        return event -> {

        };
    }

    public final void setReels(List<AllEpisodeModel> list) {
        this.reels = list;
    }

    public final ActivityResultLauncher<Intent> getInfoLauncher() {
        return this.infoLauncher;
    }

    private PipPlayerListener backClickListener;
    int episodeIndex;

    public FullReelsAdapter(PipPlayerListener backClickListener, List<ShortDetailModel> shortDetailModels, FragmentManager fragmentManager,
                            Lifecycle lifecycle, Context context, Activity activity, List<AllEpisodeModel> reels, boolean z, boolean z2, ActivityResultLauncher<Intent> infoLauncher, int episodeIndex) {
        this.backClickListener = backClickListener;
        this.shortDetailModels = shortDetailModels;
        this.fragmentManager = fragmentManager;
        this.lifecycle = lifecycle;
        this.context = context;
        this.activity = activity;
        this.reels = reels;
        this.isSeries = z;
        this.isMuted = z2;
        this.infoLauncher = infoLauncher;
        this.currentPlayingPosition = 0;
        this.episodeIndex = episodeIndex;
        this.players = new ArrayList();
        this.handler = new Handler(Looper.getMainLooper());
        this.lockTouchSlop = ViewConfiguration.get(context).getScaledTouchSlop();
        this.updateSeekBarRunnable = new Runnable() {
            @Override
            public void run() {
                ExoPlayer exoPlayer;
                RecyclerView recyclerView;
                if (FullReelsAdapter.this.getCurrentPlayingPosition() != -1 && FullReelsAdapter.this.getCurrentPlayingPosition() < FullReelsAdapter.this.players.size() && (exoPlayer = (ExoPlayer) FullReelsAdapter.this.players.get(FullReelsAdapter.this.getCurrentPlayingPosition())) != null) {
                    FullReelsAdapter seriesReelsAdapter = FullReelsAdapter.this;
                    recyclerView = seriesReelsAdapter.recyclerView;
                    RecyclerView.ViewHolder findViewHolderForAdapterPosition = recyclerView != null ? recyclerView.findViewHolderForAdapterPosition(seriesReelsAdapter.getCurrentPlayingPosition()) : null;
                    ReelViewHolder reelViewHolder = findViewHolderForAdapterPosition instanceof ReelViewHolder ? (ReelViewHolder) findViewHolderForAdapterPosition : null;
                    if (reelViewHolder != null) {
                        reelViewHolder.updateSeekBar(exoPlayer);
                    }
                }
                FullReelsAdapter.this.handler.postDelayed(this, 500L);
            }
        };
        int size = this.reels.size();
        for (int i = 0; i < size; i++) {
            this.players.add(null);
        }
        instance = this;
        rewardUnlocker = new RewardAdManager(context);
        rewardUnlocker.setLockUiListener(new RewardAdManager.LockUiListener() {
            @Override
            public void onLockUiShown() {
                setScrollBlocked(true);
            }

            @Override
            public void onLockUiHidden() {
                setScrollBlocked(false);
            }
        });

    }

    private void setScrollBlocked(boolean blocked) {
        scrollBlockedByLock = blocked;
        lockHasDown = false;
        if (recyclerView != null && blocked) {
            recyclerView.stopScroll();
        }
    }

    public final int getCurrentPlayingPosition() {
        return this.currentPlayingPosition;
    }

    public final void setCurrentPlayingPosition(int i) {
        this.currentPlayingPosition = i;
    }

    public ExoPlayer getCurrentPlayer() {
        if (currentPlayingPosition != -1 && currentPlayingPosition < players.size()) {
            return players.get(currentPlayingPosition);
        }
        return null;
    }

    public RewardAdManager getRewardUnlocker() {
        return rewardUnlocker;
    }

    public static final class Companion {
        public Companion(DefaultConstructorMarker defaultConstructorMarker) {
            this();
        }

        private Companion() {
        }

        public final FullReelsAdapter getInstance() {
            return FullReelsAdapter.instance;
        }

        public final void setInstance(FullReelsAdapter seriesReelsAdapter) {
            FullReelsAdapter.instance = seriesReelsAdapter;
        }
    }

    @Override
    public int getItemCount() {
        return this.reels.size();
    }

    @Override
    public ReelViewHolder onCreateViewHolder(ViewGroup parent, int i) {
        ItemReelBinding inflate = ItemReelBinding.inflate(LayoutInflater.from(this.context), parent, false);
        return new ReelViewHolder(this, inflate);
    }

    @Override
    public void onBindViewHolder(ReelViewHolder holder, int i) {
        holder.bind(holder, this.reels.get(i), this.isMuted, i == this.currentPlayingPosition, i);
    }



    @Override
    public void onViewRecycled(@NonNull ReelViewHolder holder) {
        super.onViewRecycled(holder);

        int pos = holder.getBindingAdapterPosition();
        if (pos == RecyclerView.NO_POSITION || pos < 0 || pos >= players.size()) return;

        ExoPlayer player = players.get(pos);
        if (player != null) {

            if (player.getDuration() > 0) {
                savedVideoPositions.put(pos, player.getCurrentPosition());
            }

            player.setPlayWhenReady(false);
            player.pause();
        }

        holder.detachPlayer();
        

    }

    public void updatePlayback(int position) {

        if (position == -1 || position == currentPlayingPosition) {
            return;
        }

        if (currentPlayingPosition != -1
                && currentPlayingPosition < players.size()) {

            ExoPlayer oldPlayer = players.get(currentPlayingPosition);
            if (oldPlayer != null) {
                if (oldPlayer.getDuration() > 0) {
                    long currentPosition = oldPlayer.getCurrentPosition();
                    savedVideoPositions.put(currentPlayingPosition, currentPosition);
                }
                oldPlayer.setPlayWhenReady(false);
                oldPlayer.pause();
            }
        }

        currentPlayingPosition = position;

        if (position < players.size()) {
            ExoPlayer newPlayer = players.get(position);
            RecyclerView.ViewHolder viewHolder = recyclerView != null ?
                    recyclerView.findViewHolderForAdapterPosition(position) : null;

            if (newPlayer != null) {
                if (viewHolder instanceof ReelViewHolder) {
                    ReelViewHolder reelViewHolder = (ReelViewHolder) viewHolder;
                    if (reelViewHolder.getBinding().playerView.getPlayer() != newPlayer) {
                        reelViewHolder.getBinding().playerView.setPlayer(newPlayer);
                    }
                }

                if (newPlayer.getPlaybackState() == Player.STATE_IDLE) {

                    if (viewHolder instanceof ReelViewHolder && position < reels.size()) {
                        notifyItemChanged(position);
                    }
                } else if (newPlayer.getPlaybackState() == Player.STATE_READY ||
                        newPlayer.getPlaybackState() == Player.STATE_BUFFERING) {
                    Long savedPosition = savedVideoPositions.get(position);
                    if (savedPosition != null && savedPosition > 0 && newPlayer.getDuration() > 0) {
                        if (savedPosition < newPlayer.getDuration()) {
                            newPlayer.seekTo(savedPosition);
                        }
                    }
                    newPlayer.setPlayWhenReady(true);
                    if (viewHolder instanceof ReelViewHolder) {
                        ReelViewHolder reelViewHolder = (ReelViewHolder) viewHolder;
                        String seriesId = shortDetailModels != null && !shortDetailModels.isEmpty()
                                ? shortDetailModels.get(0).getId()
                                : "unknown_series";
                        String unlockKey = RewardAdManager.buildUnlockKey(seriesId, position);
                        if (rewardUnlocker.verifyVideoLock(position, unlockKey, newPlayer, shortDetailModels.get(0), reelViewHolder.getBinding())) {
                            return;
                        }
                    }


                    if (!newPlayer.isPlaying()) {
                        newPlayer.play();
                    }
                } else if (newPlayer.getPlaybackState() == Player.STATE_ENDED) {
                    newPlayer.seekTo(0);
                    newPlayer.setPlayWhenReady(true);
                    newPlayer.play();
                }
            } else {
                if (viewHolder == null || !(viewHolder instanceof ReelViewHolder)) {

                    return;
                }
            }
        }

        handler.removeCallbacks(updateSeekBarRunnable);
        handler.post(updateSeekBarRunnable);
    }

    public void pauseAllPlayers() {

        if (players == null || players.isEmpty()) {
            return;
        }

        for (ExoPlayer player : players) {
            if (player != null) {
                player.setPlayWhenReady(false);
                player.pause();
            }
        }

        currentPlayingPosition = -1;

        if (handler != null && updateSeekBarRunnable != null) {
            handler.removeCallbacks(updateSeekBarRunnable);
        }
    }

    public final void resumeCurrentPlayer() {
        int i;
        ExoPlayer exoPlayer;
        ItemReelBinding binding2;
        ImageView imageView2;
        Integer valueOf = Integer.valueOf(this.currentPlayingPosition);
        int intValue = valueOf.intValue();
        if (intValue == -1 || intValue >= this.players.size()) {
            valueOf = null;
        }
        if (valueOf == null) {
            RecyclerView recyclerView = this.recyclerView;
            RecyclerView.LayoutManager layoutManager = recyclerView != null ? recyclerView.getLayoutManager() : null;
            LinearLayoutManager linearLayoutManager = layoutManager instanceof LinearLayoutManager ? (LinearLayoutManager) layoutManager : null;
            valueOf = linearLayoutManager != null ? Integer.valueOf(linearLayoutManager.findFirstCompletelyVisibleItemPosition()) : null;
            if (valueOf == null) {
                i = -1;
                if (i != -1 || i >= this.players.size() || (exoPlayer = this.players.get(i)) == null) {
                    return;
                }
                this.currentPlayingPosition = i;
                this.handler.post(this.updateSeekBarRunnable);
                RecyclerView recyclerView2 = this.recyclerView;
                RecyclerView.ViewHolder findViewHolderForAdapterPosition = recyclerView2 != null ? recyclerView2.findViewHolderForAdapterPosition(this.currentPlayingPosition) : null;
                final ReelViewHolder reelViewHolder = findViewHolderForAdapterPosition instanceof ReelViewHolder ? (ReelViewHolder) findViewHolderForAdapterPosition : null;
                if (reelViewHolder != null) {
                    reelViewHolder.showFlContainer(reelViewHolder.getBinding());
                }
                if (reelViewHolder == null || (binding2 = reelViewHolder.getBinding()) == null || (imageView2 = binding2.playPauseIcon) == null) {
                    return;
                }
                imageView2.postDelayed(new Runnable() {
                    @Override
                    public final void run() {
                        reelViewHolder.hideFlContainer(reelViewHolder.getBinding());

                    }
                }, 5000L);
                return;
            }
        }
        i = valueOf.intValue();
        if (i != -1) {
        }
    }


    public void releaseAllPlayers() {

        if (players == null || players.isEmpty()) {
            return;
        }

        if (recyclerView != null) {
            for (int i = 0; i < recyclerView.getChildCount(); i++) {
                RecyclerView.ViewHolder viewHolder = recyclerView.getChildViewHolder(recyclerView.getChildAt(i));
                if (viewHolder instanceof ReelViewHolder) {
                    ReelViewHolder reelHolder = (ReelViewHolder) viewHolder;
                    if (reelHolder.getBinding() != null && reelHolder.getBinding().playerView != null) {
                        reelHolder.getBinding().playerView.setPlayer(null);
                    }
                }
            }
        }

        for (ExoPlayer player : players) {
            if (player != null) {
                player.release();
            }
        }

        players.clear();
        currentPlayingPosition = -1;

        if (handler != null && updateSeekBarRunnable != null) {
            handler.removeCallbacks(updateSeekBarRunnable);
        }
    }

    @Override
    public void onAttachedToRecyclerView(RecyclerView recyclerView) {
        super.onAttachedToRecyclerView(recyclerView);
        this.recyclerView = recyclerView;
        if (!lockTouchListenerAttached) {
            recyclerView.addOnItemTouchListener(lockTouchListener);
            lockTouchListenerAttached = true;
        }
    }

    @Override
    public void onDetachedFromRecyclerView(RecyclerView recyclerView) {
        super.onDetachedFromRecyclerView(recyclerView);
        releaseAllPlayers();
        if (lockTouchListenerAttached) {
            recyclerView.removeOnItemTouchListener(lockTouchListener);
            lockTouchListenerAttached = false;
        }
        this.recyclerView = null;
    }


    public final class ReelViewHolder extends RecyclerView.ViewHolder {
        private final ItemReelBinding binding;
        private ExoPlayer exoPlayer;
        final FullReelsAdapter fullReelsAdapter;

        public ReelViewHolder(FullReelsAdapter seriesReelsAdapter, ItemReelBinding binding) {
            super(binding.getRoot());

            this.fullReelsAdapter = seriesReelsAdapter;
            this.binding = binding;
            binding.seekbar.setOnSeekBarChangeListener(new SeekBar.OnSeekBarChangeListener() {
                @Override
                public void onProgressChanged(SeekBar seekBar, int i, boolean z) {
                    ExoPlayer exoPlayer;
                    if (!z || (exoPlayer = ReelViewHolder.this.exoPlayer) == null) {
                        return;
                    }
                    long duration = exoPlayer.getDuration();
                    if (duration > 0) {
                        exoPlayer.seekTo((i * duration) / 100);
                    }
                }

                @Override
                public void onStartTrackingTouch(SeekBar seekBar) {
                    ExoPlayer exoPlayer = ReelViewHolder.this.exoPlayer;
                    if (exoPlayer != null) {
                        exoPlayer.setPlayWhenReady(false);
                    }
                }

                @Override
                public void onStopTrackingTouch(SeekBar seekBar) {
                    ExoPlayer exoPlayer = ReelViewHolder.this.exoPlayer;
                    if (exoPlayer != null) {
                        exoPlayer.setPlayWhenReady(true);
                    }
                }
            });
        }

        public final ItemReelBinding getBinding() {
            return this.binding;
        }

        private void showBottomSheet(List<AllEpisodeModel> reels, int i, ReelViewHolder holder) {
            if (fullReelsAdapter.activeBottomSheetDialog != null && fullReelsAdapter.activeBottomSheetDialog.isShowing()) {
                return;
            }

            BottomSheetDialog bottomSheetDialog = new BottomSheetDialog(context, R.style.TransparentBottomSheetDialog);
            fullReelsAdapter.activeBottomSheetDialog = bottomSheetDialog;
            View view = LayoutInflater.from(context)
                    .inflate(R.layout.layout_episode_list, null);


            ViewPager2 mainViewPager = view.findViewById(R.id.mainViewPager);
            ImageView imgViewCategory1 = view.findViewById(R.id.imgView1);
            ImageView imgViewCategory2 = view.findViewById(R.id.imgView2);
            ImageView imageSeries = view.findViewById(R.id.imageSeries);
            ImageView buttonClose = view.findViewById(R.id.buttonClose);
            TextView textView1 = view.findViewById(R.id.textView1);
            TextView textView2 = view.findViewById(R.id.textView2);
            RecyclerView recycleViewCategory = view.findViewById(R.id.recycleViewCategory);


            bottomSheetDialog.setContentView(view);
            bottomSheetDialog.setCancelable(true);

            LinearLayoutManager layoutManager =
                    new LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false);
            recycleViewCategory.setLayoutManager(layoutManager);

            CategoryNameAdapter categoryAdapter = new CategoryNameAdapter(context, shortDetailModels.get(0).getCategories());
            recycleViewCategory.setAdapter(categoryAdapter);
            buttonClose.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    bottomSheetDialog.dismiss();

                }
            });

            if (shortDetailModels.get(0).getCover() != null) {
                Glide.with(context).load(shortDetailModels.get(0).getCover()).placeholder(R.drawable.image_poster_placeholder).into(imageSeries);
            }
            textView1.setText(shortDetailModels.get(0).getTitle());
            textView2.setText(shortDetailModels.get(0).getIntro());


            MainPagerAdapter adapter = new MainPagerAdapter(
                    fragmentManager,
                    lifecycle,
                    reels.size(),
                    shortDetailModels,
                    episodeIndex -> {

                        bottomSheetDialog.dismiss();

                        playEpisodeFromBottomSheet(episodeIndex);
                    }
            );
            mainViewPager.setAdapter(adapter);
            mainViewPager.setCurrentItem(1, false);

            imgViewCategory1.setImageDrawable(
                    ContextCompat.getDrawable(context, R.drawable.ic_tab_unselect)
            );
            imgViewCategory2.setImageDrawable(
                    ContextCompat.getDrawable(context, R.drawable.ic_tab_select)
            );
            imgViewCategory1.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    mainViewPager.setCurrentItem(0);
                    imgViewCategory1.setImageDrawable(
                            ContextCompat.getDrawable(context, R.drawable.ic_tab_select)
                    );
                    imgViewCategory2.setImageDrawable(
                            ContextCompat.getDrawable(context, R.drawable.ic_tab_unselect)
                    );
                }
            });
            imgViewCategory2.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    mainViewPager.setCurrentItem(1);
                    imgViewCategory1.setImageDrawable(
                            ContextCompat.getDrawable(context, R.drawable.ic_tab_unselect)
                    );
                    imgViewCategory2.setImageDrawable(
                            ContextCompat.getDrawable(context, R.drawable.ic_tab_select)
                    );
                }
            });

            mainViewPager.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
                @Override
                public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
                    super.onPageScrolled(position, positionOffset, positionOffsetPixels);
                }

                @Override
                public void onPageSelected(int position) {
                    super.onPageSelected(position);
                    if (position == 0) {
                        imgViewCategory1.setImageDrawable(
                                ContextCompat.getDrawable(context, R.drawable.ic_tab_select)
                        );
                        imgViewCategory2.setImageDrawable(
                                ContextCompat.getDrawable(context, R.drawable.ic_tab_unselect)
                        );
                    } else if (position == 1) {
                        imgViewCategory1.setImageDrawable(
                                ContextCompat.getDrawable(context, R.drawable.ic_tab_unselect)
                        );
                        imgViewCategory2.setImageDrawable(
                                ContextCompat.getDrawable(context, R.drawable.ic_tab_select)
                        );
                    }
                }

                @Override
                public void onPageScrollStateChanged(int state) {
                    super.onPageScrollStateChanged(state);
                }
            });

            bottomSheetDialog.show();


        }

        public void playEpisodeFromBottomSheet(int episodeIndex) {

            if (episodeIndex < 0 || episodeIndex >= reels.size()) return;

            pauseAllPlayers();
            setCurrentPlayingPosition(episodeIndex);

            if (recyclerView != null) {
                recyclerView.scrollToPosition(episodeIndex);
                recyclerView.postDelayed(() -> updatePlayback(episodeIndex), 350);
            } else {
                updatePlayback(episodeIndex);
            }
        }

        private void saveContinueWatching(
                AllEpisodeModel episode,
                ShortDetailModel series,
                long positionMs,
                long durationMs,
                boolean b) {

            String userId = FirebaseAuth.getInstance().getUid();
            if (userId == null || durationMs <= 0) return;

            int completionPct = (int) ((positionMs * 100) / durationMs);

            String status = completionPct >= 95
                    ? "COMPLETED"
                    : "IN_PROGRESS";

            FirebaseFirestore db = FirebaseFirestore.getInstance();

            DocumentReference ref = db.collection("users")
                    .document(userId)
                    .collection("continueWatching")
                    .document(series.getId());

            Map<String, Object> map = new HashMap<>();
            map.put("seriesId", series.getId());
            map.put("lastPositionMs", positionMs);
            map.put("completionPct", completionPct);
            map.put("status", status);
            map.put("lastWatchedAt", FieldValue.serverTimestamp());

            map.put("seriesTitle", series.getTitle());
            map.put("episodesIndex", episode.getPartIndex());
            map.put("episodeTitle", series.getTitle());
            map.put("seriesThumbnail", series.getCover());
            map.put("episodesTotalCount", series.getEpisodeCount());
            map.put("seriesThumbnail", series.getCover());
            map.put("my_list_history", b);

            ref.set(map, SetOptions.merge());
        }


        private void saveEpisodeProgress(
                AllEpisodeModel episode,
                ShortDetailModel series,
                long positionMs,
                long durationMs
        ) {

            String userId = FirebaseAuth.getInstance().getUid();
            if (userId == null || durationMs <= 0) return;

            int completionPct = (int) ((positionMs * 100) / durationMs);

            String status;
            if (completionPct >= 95) {
                status = "COMPLETED";
            } else if (completionPct >= 50) {
                status = "VIEWED_50";
            } else {
                status = "STARTED";
            }

            FirebaseFirestore db = FirebaseFirestore.getInstance();

            DocumentReference ref = db.collection("users")
                    .document(userId)
                    .collection("episodeProgress")
                    .document(String.valueOf(episode.getId()));

            Map<String, Object> map = new HashMap<>();
            map.put("episodeId", episode.getId());
            map.put("seriesId", series.getId());
            map.put("durationMs", durationMs);
            map.put("lastPositionMs", positionMs);
            map.put("completionPct", completionPct);
            map.put("status", status);
            map.put("episode_number", episode.getPartIndex());
            map.put("lastWatchedAt", FieldValue.serverTimestamp());

            if (completionPct >= 50) {
                map.put("viewed50CountedAt", FieldValue.serverTimestamp());
            }

            if (completionPct >= 95) {
                map.put("completedCountedAt", FieldValue.serverTimestamp());
            }

            ref.set(map, SetOptions.merge());
        }

        private void saveProgressIfNeeded(
                ExoPlayer player,
                AllEpisodeModel episode,
                ShortDetailModel series
        ) {
            if (player == null || !player.isCommandAvailable(Player.COMMAND_GET_CURRENT_MEDIA_ITEM))
                return;

            long position = player.getCurrentPosition();
            long duration = player.getDuration();

            if (duration <= 0 || position <= 0) return;

            saveEpisodeProgress(episode, series, position, duration);
            saveContinueWatching(episode, series, position, duration, false);
        }

        private boolean isReadyHandled = false;
        public  void shareContent(
                Context context,
                String posterUrl,
                String title,
                String description,
                String appUrl
        ) {

            Glide.with(context)
                    .asBitmap()
                    .load(posterUrl)
                    .into(new CustomTarget<Bitmap>() {

                        @Override
                        public void onResourceReady(
                                @NonNull Bitmap bitmap,
                                @Nullable Transition<? super Bitmap> transition
                        ) {

                            try {
                                File cachePath = new File(context.getCacheDir(), "shared_images");
                                if (!cachePath.exists()) cachePath.mkdirs();

                                File imageFile = new File(cachePath, "poster.png");

                                FileOutputStream fos = new FileOutputStream(imageFile);
                                bitmap.compress(Bitmap.CompressFormat.PNG, 100, fos);
                                fos.flush();
                                fos.close();

                                Uri imageUri = FileProvider.getUriForFile(
                                        context,
                                        context.getPackageName() + ".provider",
                                        imageFile
                                );

                                Intent shareIntent = new Intent(Intent.ACTION_SEND);
                                shareIntent.setType("image/*");
                                shareIntent.putExtra(Intent.EXTRA_STREAM, imageUri);
                                shareIntent.putExtra(
                                        Intent.EXTRA_TEXT,
                                        title + "\n\n" +
                                                description + "\n\n" +
                                                "Watch now 👉 " + appUrl
                                );

                                shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);

                                context.startActivity(
                                        Intent.createChooser(shareIntent, "Share via")
                                );

                            } catch (Exception e) {
                                e.printStackTrace();
                            }
                        }

                        @Override
                        public void onLoadCleared(@Nullable Drawable placeholder) {
                        }
                    });
        }
        public final void bind(ReelViewHolder holder, final AllEpisodeModel reelInfo, boolean z, boolean z2, final int i) {

            holder.updatePiPMode(fullReelsAdapter.isInPictureInPictureMode);

            if (ControlPreference.getUserFreeEpisodes() > 0
                    && i < ControlPreference.getUserFreeEpisodes()) {
                binding.relativeWatchToUnlock.setVisibility(View.GONE);
            } else {
                binding.relativeWatchToUnlock.setVisibility(View.GONE);
            }

            float s = getSavedSpeed(context);
            binding.textViewSpeed.setText(s + "x");
            if (rewardUnlocker != null) {
                rewardUnlocker.updateWatchAdAttemptsText(binding);
            }
            this.binding.imgShare.setOnClickListener(new View.OnClickListener() {
                private long lastClickTime = 0;

                @Override
                public final void onClick(View view) {
                    long currentTime = System.currentTimeMillis();
                    if (currentTime - lastClickTime < 1000) {
                        return;
                    }
                    lastClickTime = currentTime;

                    if (shortDetailModels == null || shortDetailModels.get(0).getCover() == null || shortDetailModels.get(0).getTitle() == null) return;

                    Context context = holder.binding.imgShare.getContext();

                    String playStoreUrl =
                            "https://play.google.com/store/apps/details?id=" + context.getPackageName();

                    String description =
                            "🎬 Don’t wait, watch on " + context.getString(R.string.app_name);

                    shareContent(
                            context,
                            shortDetailModels.get(0).getCover(),
                            shortDetailModels.get(0).getTitle(),
                            description,
                            playStoreUrl
                    );
                }
            });


            binding.imageSpeedButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {

                    LayoutInflater inflater = (LayoutInflater) context.getSystemService(LAYOUT_INFLATER_SERVICE);
                    LayoutPopupDialogBinding binding =
                            LayoutPopupDialogBinding.inflate(inflater);

                    View popupView = binding.getRoot();
                    PopupWindow popupWindow = new PopupWindow(
                            popupView,
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT,
                            true
                    );
                    float savedSpeed = getSavedSpeed(context);
                    applySavedSpeedUI(binding, savedSpeed);
                    popupWindow.setBackgroundDrawable(new ColorDrawable(android.graphics.Color.TRANSPARENT));
                    popupWindow.setElevation(16);

                    binding.menuItem1.setOnClickListener(v -> {
                        setSpeed(exoPlayer, 2.0f, popupWindow, getBinding().textViewSpeed);
                        saveSpeed(context, 2.0f);

                        unSelPopupItemBackground(binding);
                        setPopupItemBackground(binding.imageView1, binding.imageRight1);
                        popupWindow.dismiss();
                    });

                    binding.menuItem2.setOnClickListener(v -> {
                        setSpeed(exoPlayer, 1.5f, popupWindow, getBinding().textViewSpeed);
                        saveSpeed(context, 1.5f);
                        unSelPopupItemBackground(binding);
                        setPopupItemBackground(binding.imageView2, binding.imageRight2);

                        popupWindow.dismiss();
                    });

                    binding.menuItem3.setOnClickListener(v -> {
                        setSpeed(exoPlayer, 1.25f, popupWindow, getBinding().textViewSpeed);
                        saveSpeed(context, 1.25f);
                        unSelPopupItemBackground(binding);
                        setPopupItemBackground(binding.imageView3, binding.imageRight3);

                        popupWindow.dismiss();
                    });

                    binding.menuItem4.setOnClickListener(v -> {
                        setSpeed(exoPlayer, 1.0f, popupWindow, getBinding().textViewSpeed);
                        unSelPopupItemBackground(binding);
                        setPopupItemBackground(binding.imageView4, binding.imageRight4);
                        saveSpeed(context, 1.0f);

                        popupWindow.dismiss();
                    });

                    binding.menuItem5.setOnClickListener(v -> {
                        setSpeed(exoPlayer, 0.75f, popupWindow, getBinding().textViewSpeed);
                        unSelPopupItemBackground(binding);
                        setPopupItemBackground(binding.imageView5, binding.imageRight5);
                        saveSpeed(context, 0.75f);

                        popupWindow.dismiss();
                    });

                    binding.menuItem6.setOnClickListener(v -> {
                        setSpeed(exoPlayer, 0.5f, popupWindow, getBinding().textViewSpeed);
                        unSelPopupItemBackground(binding);
                        setPopupItemBackground(binding.imageView6, binding.imageRight6);
                        saveSpeed(context, 0.5f);

                        popupWindow.dismiss();
                    });


                    int[] location = new int[2];
                    view.getLocationOnScreen(location);

                    popupWindow.showAtLocation(
                            view,
                            Gravity.NO_GRAVITY,
                            location[0] + view.getWidth() - popupView.getMeasuredWidth(),
                            location[1] + view.getHeight()
                    );
                    popupView.measure(
                            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED),
                            View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
                    );
                    popupWindow.update(
                            location[0] + view.getWidth() - popupView.getMeasuredWidth(),
                            location[1] + view.getHeight(),
                            -1,
                            -1
                    );

                    popupWindow.setOutsideTouchable(true);
                    popupWindow.setFocusable(true);


                }
            });
            this.binding.playTotal.setVisibility(VISIBLE);
            binding.playTotal.setText(" /EP. " + shortDetailModels.get(0).getEpisodeCount());
            binding.playCur.setText("EP." + reelInfo.getPartIndex().intValue());
            context.getSharedPreferences("EpisodePrefs", Context.MODE_PRIVATE)
                    .edit()
                    .putInt("selected_episode", reelInfo.getPartIndex().intValue() - 1)
                    .apply();
            binding.linearWatchFullSeries.setVisibility(View.GONE);
            getBinding().linearEpisodesList.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    showBottomSheet(reels, i, holder);
                }
            });
            if (shortDetailModels.get(0).isFavourite()) {
                binding.imgViewLike.setVisibility(View.GONE);
                binding.animLike.setVisibility(View.VISIBLE);
                binding.animLike.playAnimation();
            } else {
                binding.animLike.cancelAnimation();
                binding.animLike.setVisibility(View.GONE);
                binding.imgViewLike.setVisibility(View.VISIBLE);
            }
            getBinding().relativeLikeButton.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    boolean newState = !shortDetailModels.get(0).isFavourite();
                    shortDetailModels.get(0).setFavourite(newState);

                    if (newState) {
                        binding.imgViewLike.setVisibility(View.GONE);
                        binding.animLike.setVisibility(View.VISIBLE);
                        binding.animLike.playAnimation();
                    } else {
                        binding.animLike.cancelAnimation();
                        binding.animLike.setVisibility(View.GONE);
                        binding.imgViewLike.setVisibility(View.VISIBLE);
                    }

                }
            });
            getBinding().buttonList.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    showBottomSheet(reels, i, holder);
                }
            });

            ExoPlayer existingPlayer = this.fullReelsAdapter.players.get(i);
            final ExoPlayer build;


            if (existingPlayer != null && existingPlayer.getPlaybackState() != Player.STATE_IDLE) {
                build = existingPlayer;
                this.exoPlayer = build;

                this.binding.playerView.setPlayer(build);
                this.binding.playerView.setShowBuffering(PlayerView.SHOW_BUFFERING_ALWAYS);
                this.binding.playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
                this.binding.playerView.setUseController(false);

                Long savedPosition = this.fullReelsAdapter.savedVideoPositions.get(i);
                if (savedPosition != null && savedPosition > 0 && build.getDuration() > 0) {
                    if (savedPosition < build.getDuration()) {
                        build.seekTo(savedPosition);
                    }
                }

                updateSeekBar(build);
                build.setVolume(z ? 0.0f : 1.0f);

                float savedSpeed = getSavedSpeed(context);
                build.setPlaybackParameters(new PlaybackParameters(savedSpeed));
                if (i == this.fullReelsAdapter.getCurrentPlayingPosition()) {
                    build.setPlayWhenReady(true);
                    build.play();

                } else {
                    build.setPlayWhenReady(false);
                    build.pause();
                }
                return;
            } else if (existingPlayer != null && existingPlayer.getPlaybackState() == Player.STATE_IDLE) {

                String videoUrl = reelInfo.getStreamHls();
                if (videoUrl != null) {
                    build = existingPlayer;
                    this.exoPlayer = build;
                    MediaItem mediaItem = MediaItem.fromUri(videoUrl);
                    build.setMediaItem(mediaItem);
                    build.prepare();

                    this.binding.playerView.setPlayer(build);
                    this.binding.playerView.setShowBuffering(PlayerView.SHOW_BUFFERING_ALWAYS);
                    this.binding.playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
                    this.binding.playerView.setUseController(false);

                    build.setVolume(z ? 0.0f : 1.0f);
                    float savedSpeed = getSavedSpeed(context);
                    build.setPlaybackParameters(new PlaybackParameters(savedSpeed));

                    final Long savedPosition = this.fullReelsAdapter.savedVideoPositions.get(i);
                    boolean shouldAutoPlay = (i == this.fullReelsAdapter.getCurrentPlayingPosition());

                    build.addListener(new Player.Listener() {
                        @Override
                        public void onPlaybackStateChanged(int playbackState) {
                            if (playbackState == Player.STATE_READY) {
                                if (savedPosition != null && savedPosition > 0) {
                                    long duration = build.getDuration();
                                    if (duration > 0 && savedPosition < duration) {
                                        build.seekTo(savedPosition);
                                    }
                                }
                                if (shouldAutoPlay && getAdapterPosition() == FullReelsAdapter.this.getCurrentPlayingPosition()) {
                                    int p = getAdapterPosition();
                                    String seriesId = shortDetailModels != null && !shortDetailModels.isEmpty()
                                            ? shortDetailModels.get(0).getId()
                                            : "unknown_series";
                                    String unlockKey = RewardAdManager.buildUnlockKey(seriesId, p);
                                    if (rewardUnlocker.verifyVideoLock(p, unlockKey, build, shortDetailModels.get(0), getBinding())) {
                                        return;
                                    }
                                    build.setPlayWhenReady(true);
                                    build.play();
                                }
                            } else if (playbackState == Player.STATE_BUFFERING && shouldAutoPlay
                                    && getAdapterPosition() == FullReelsAdapter.this.getCurrentPlayingPosition()) {
                                build.setPlayWhenReady(true);
                            }
                        }

                        @Override
                        public void onPlayWhenReadyChanged(boolean playWhenReady, int reason) {
                            if (playWhenReady && getAdapterPosition() == FullReelsAdapter.this.getCurrentPlayingPosition()) {
                                if (build.isPlaying()) {
                                    getBinding().playPauseIcon.setImageResource(R.drawable.ic_pause);
                                } else {
                                    getBinding().playPauseIcon.setImageResource(R.drawable.ic_play);
                                }
                            }
                        }
                    });

                    if (shouldAutoPlay) {
                        build.setPlayWhenReady(true);
                    } else {
                        build.setPlayWhenReady(false);
                    }

                    updateSeekBar(build);
                    return;
                }
            }
            boolean shouldShowImaAd = (i == 1)
                    && ControlPreference.getExoplayerImaShow()
                    && !com.snapdrama.shortstream.ads.PremiumPlanManager.shouldSkipAfterLoginAd(context);
            MediaSource.Factory mediaSourceFactory;
            DataSource.Factory dataSourceFactory;
            if (shouldShowImaAd) {

                adsLoader = new ImaAdsLoader.Builder(context)
                        .setAdEventListener(buildAdEventListener())
                        .setImaSdkSettings(getImaSdkSettings())
                        .build();

               dataSourceFactory =
                        new DefaultDataSource.Factory(context);

                mediaSourceFactory =
                        new DefaultMediaSourceFactory(dataSourceFactory)
                                .setLocalAdInsertionComponents(
                                        unusedAdTagUri -> adsLoader,
                                        binding.playerView
                                );

            } else {

                mediaSourceFactory =
                        new DefaultMediaSourceFactory(
                                new DefaultDataSource.Factory(context)
                        );
            }

            releasePlayer();
            build = new ExoPlayer.Builder(this.fullReelsAdapter.context).setMediaSourceFactory(mediaSourceFactory).build();
            final FullReelsAdapter seriesReelsAdapter = this.fullReelsAdapter;

            String videoUrl = reelInfo.getStreamHls();
            if (videoUrl != null) {
                build.setVideoScalingMode(1);
                build.setHandleAudioBecomingNoisy(true);
                MediaItem mediaItem;


                if (shouldShowImaAd) {
                    mediaItem =
                            new MediaItem.Builder()
                                    .setUri(Uri.parse(videoUrl))
                                    .setAdsConfiguration(
                                            new MediaItem.AdsConfiguration
                                                    .Builder(Uri.parse(ControlPreference.getVastExoPlayerUrl()))
                                                    .build()
                                    )
                                    .build();
                } else {
                    mediaItem = MediaItem.fromUri(videoUrl);
                }
                build.setMediaItem(mediaItem);

                build.prepare();
                build.setVolume(z ? 0.0f : 1.0f);

                final Long savedPosition = this.fullReelsAdapter.savedVideoPositions.get(i);

                boolean shouldAutoPlay = (i == fullReelsAdapter.getCurrentPlayingPosition());

                build.setPlayWhenReady(shouldAutoPlay);
                if (shouldAutoPlay) {
                    build.play();
                }


                float savedSpeed = getSavedSpeed(context);

                build.setPlaybackParameters(
                        new PlaybackParameters(savedSpeed));
                build.addListener(new Player.Listener() {
                    @Override
                    public void onPlaybackStateChanged(int state) {

                        int pos = getAdapterPosition();
                        if (pos == RecyclerView.NO_POSITION) return;

                        if (pos != fullReelsAdapter.getCurrentPlayingPosition()) return;

                        if (state == Player.STATE_READY) {
                            completionHandled = false;

                            if (isReadyHandled) return;
                            isReadyHandled = true;


                            binding.seekbar.setProgress(0);
                            hideFlContainer(binding);
                            getBinding().playPauseIcon.setImageResource(R.drawable.ic_pause);

                            fullReelsAdapter.savedVideoPositions.remove(pos);

                            if (savedPosition != null && savedPosition > 0) {
                                long duration = build.getDuration();
                                if (duration > 0 && savedPosition < duration) {
                                    build.seekTo(savedPosition);
                                }
                            }
                            fullReelsAdapter.handler.removeCallbacks(
                                    fullReelsAdapter.updateSeekBarRunnable
                            );
                            fullReelsAdapter.handler.post(
                                    fullReelsAdapter.updateSeekBarRunnable
                            );
//
                        } else if (state == Player.STATE_ENDED) {

                            isReadyHandled = false;
                            if (!completionHandled) {
                                completionHandled = true;
                                rewardUnlocker.onVideoCompleted();
                            }

                            build.setPlayWhenReady(false);
                            fullReelsAdapter.pauseAllPlayers();

                            int next = pos + 1;
                            if (next < fullReelsAdapter.getReels().size()) {
                                setCurrentPlayingPosition(next);
                                updatePlayback(next);

                                if (recyclerView != null && recyclerView.getLayoutManager() != null) {
                                    recyclerView.getLayoutManager().scrollToPosition(next);
                                }
                            }
                        }
                    }

                    @Override
                    public void onPlayWhenReadyChanged(boolean playWhenReady, int reason) {

                        int pos = getAdapterPosition();
                        if (pos == RecyclerView.NO_POSITION) return;
                        if (pos != fullReelsAdapter.getCurrentPlayingPosition()) return;

                        if (playWhenReady) {
                            getBinding().playPauseIcon.setImageResource(R.drawable.ic_pause);
                        } else {
                            getBinding().playPauseIcon.setImageResource(R.drawable.ic_play);
                            saveProgressIfNeeded(build, reelInfo, shortDetailModels.get(0));
                        }
                    }
                });
            }
            this.exoPlayer = build;

            this.binding.playerView.setPlayer(this.exoPlayer);
            this.binding.playerView.setShowBuffering(PlayerView.SHOW_BUFFERING_ALWAYS);
            this.binding.playerView.setResizeMode(AspectRatioFrameLayout.RESIZE_MODE_ZOOM);
            this.binding.playerView.setUseController(false);

            if (shouldShowImaAd && adsLoader != null) {
                adsLoader.setPlayer(build);
            }

            this.fullReelsAdapter.players.set(i, this.exoPlayer);

            if (i == this.fullReelsAdapter.getCurrentPlayingPosition()) {

                String seriesId = shortDetailModels != null && !shortDetailModels.isEmpty()
                        ? shortDetailModels.get(0).getId()
                        : "unknown_series";
                String unlockKey = RewardAdManager.buildUnlockKey(seriesId, i);
                if (rewardUnlocker.verifyVideoLock(i, unlockKey, exoPlayer, shortDetailModels.get(0),getBinding())) {
                     return;
                }

                this.exoPlayer.setPlayWhenReady(true);
                this.exoPlayer.play();

            } else {
                this.exoPlayer.setPlayWhenReady(false);
                this.exoPlayer.pause();
            }

            this.binding.textSeriesName.setText(shortDetailModels.get(0).getTitle());
            this.binding.textSeriesDescription.setText(shortDetailModels.get(0).getDescription());
            binding.btnBack.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    if (backClickListener != null && exoPlayer != null) {
                        backClickListener.onPlayerReady(exoPlayer);
                    }

                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        if (activity instanceof ReelsShowActivity) {
                            activity.finish();
                        }
                    }
                }
            });

            this.binding.volumeIcon.setImageResource(z ? R.drawable.ic_volume_off : R.drawable.ic_volume_on);
            binding.volumeIcon.setOnClickListener(new View.OnClickListener() {
                @Override
                public final void onClick(View view) {
                    ExoPlayer exoPlayer = holder.exoPlayer;
                    if (exoPlayer == null || !exoPlayer.isPlaying()) {
                        return;
                    }
                    seriesReelsAdapter.isMuted = !seriesReelsAdapter.isMuted;
                    exoPlayer.setVolume(seriesReelsAdapter.isMuted ? 0.0f : 1.0f);
                    getBinding().volumeIcon.setImageResource(seriesReelsAdapter.isMuted ? R.drawable.ic_volume_off : R.drawable.ic_volume_on);
//                    seriesReelsAdapter.onMuteChangeListener.invoke(Boolean.valueOf(seriesReelsAdapter.isMuted));
                }
            });
            this.binding.seekbar.setMax(100);
            updateSeekBar(this.exoPlayer);
            binding.playPauseIcon.setOnClickListener(new View.OnClickListener() {
                @Override
                public final void onClick(View view) {
                    ExoPlayer exoPlayer = holder.exoPlayer;
                    if (exoPlayer != null) {

                        if (exoPlayer.isPlaying()) {
                            exoPlayer.setPlayWhenReady(false);
                            binding.playPauseIcon.setImageResource(R.drawable.ic_play);
                        } else {

                            String seriesId = shortDetailModels != null && !shortDetailModels.isEmpty()
                                    ? shortDetailModels.get(0).getId()
                                    : "unknown_series";
                            String unlockKey = RewardAdManager.buildUnlockKey(seriesId, i);
                            if (rewardUnlocker.verifyVideoLock(i, unlockKey, exoPlayer, shortDetailModels.get(0), getBinding())) {
                                return;
                            }
                            exoPlayer.setPlayWhenReady(true);
                            binding.playPauseIcon.setImageResource(R.drawable.ic_pause);
                        }
                        showFlContainer(binding);
                        if (exoPlayer.isPlaying()) {
                            seriesReelsAdapter.setCurrentPlayingPosition(getAdapterPosition());
                            seriesReelsAdapter.handler.post(seriesReelsAdapter.updateSeekBarRunnable);
                            binding.playPauseIcon.postDelayed(new Runnable() {
                                @Override
                                public final void run() {
                                    hideFlContainer(binding);

                                }
                            }, 5000L);
                        } else if (seriesReelsAdapter.getCurrentPlayingPosition() == getAdapterPosition()) {
                            seriesReelsAdapter.setCurrentPlayingPosition(-1);
                            seriesReelsAdapter.handler.removeCallbacks(seriesReelsAdapter.updateSeekBarRunnable);
                        }
                    }
                }
            });
            boolean isAdded = addedEpisodeIds.contains(shortDetailModels.get(0).getId());

            if (isAdded) {
                binding.imageBookMark.setImageResource(R.drawable.image_book_mark_icon);
                binding.textAddList.setText(context.getString(R.string.added_1));

            } else {
                binding.imageBookMark.setImageResource(R.drawable.image_book_mark_icon);
                binding.textAddList.setText(context.getString(R.string.add_list));

            }
            binding.linearAddToList.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {

                    boolean alreadyAdded = addedEpisodeIds.contains(shortDetailModels.get(0).getId());

                    if (alreadyAdded) {
                        removeFromList(shortDetailModels.get(0));
                        addedEpisodeIds.remove(shortDetailModels.get(0).getId());
                        binding.imageBookMark.setImageResource(R.drawable.image_book_mark_icon);
                        binding.textAddList.setText(context.getString(R.string.add_list));
                    } else {
                        saveAddListData(shortDetailModels.get(0), true);
                        addedEpisodeIds.add(shortDetailModels.get(0).getId());
                        binding.imageBookMark.setImageResource(R.drawable.image_book_mark_icon);
                        binding.textAddList.setText(context.getString(R.string.added_1));

                    }
                    saveAddListData(shortDetailModels.get(0), true);
                }
            });


            this.binding.playerView.setOnClickListener(new View.OnClickListener() {
                @Override
                public final void onClick(View view) {
                    if (binding.flContainer.getVisibility() != VISIBLE) {
                        showFlContainer(binding);
                        binding.playPauseIcon.postDelayed(new Runnable() {
                            @Override
                            public final void run() {
                                hideFlContainer(binding);

                            }
                        }, 5000L);
                    }
                }
            });


        }

        private void saveAddListData(ShortDetailModel series, boolean added) {

            String userId = FirebaseAuth.getInstance().getUid();
            if (userId == null) return;

            FirebaseFirestore db = FirebaseFirestore.getInstance();

            DocumentReference ref = db.collection("users")
                    .document(userId)
                    .collection("my_list_data")
                    .document(series.getId());

            Map<String, Object> map = new HashMap<>();
            map.put("seriesId", series.getId());
            map.put("episodeId", series.getId());
            map.put("seriesTitle", series.getTitle());
            map.put("seriesThumbnail", series.getCover());
            map.put("episodesTotalCount", series.getEpisodeCount());
            map.put("added", true);
            map.put("addedAt", FieldValue.serverTimestamp());

            ref.set(map, SetOptions.merge());
        }

        private void removeFromList(ShortDetailModel series) {

            String userId = FirebaseAuth.getInstance().getUid();
            if (userId == null) return;

            FirebaseFirestore.getInstance()
                    .collection("users")
                    .document(userId)
                    .collection("my_list_data")
                    .document(series.getId())
                    .delete();
        }

        public final void hideFlContainer(ItemReelBinding binding) {

            binding.flContainer.setVisibility(View.GONE);

        }

        public final void showFlContainer(ItemReelBinding binding) {

            binding.flContainer.setVisibility(VISIBLE);
        }

        public final void updateSeekBar(ExoPlayer exoPlayer) {
            if (exoPlayer == null) return;

            long duration = exoPlayer.getDuration();
            long current = exoPlayer.getCurrentPosition();

            if (duration > 0 && current >= 0) {
                binding.seekbar.setProgress((int) ((current * 100) / duration));
            } else {
                binding.seekbar.setProgress(0);
            }
        }

        public final void detachPlayer() {
            try {
                ExoPlayer exoPlayer = this.exoPlayer;
                if (exoPlayer != null) {
                    int position = getAdapterPosition();
                    if (position != RecyclerView.NO_POSITION) {
                        if (exoPlayer.getDuration() > 0) {
                            long currentPosition = exoPlayer.getCurrentPosition();
                            this.fullReelsAdapter.savedVideoPositions.put(position, currentPosition);
                        }
                        exoPlayer.setPlayWhenReady(false);
                        exoPlayer.pause();
                    }
                    this.binding.playerView.setPlayer(null);
                }
            } catch (Exception unused) {
            }
        }


        public final void releasePlayer() {
            try {
                ExoPlayer exoPlayer = this.exoPlayer;
                if (exoPlayer != null) {
                    int position = getAdapterPosition();
                    if (position != RecyclerView.NO_POSITION) {
                        // Save position before releasing
                        if (exoPlayer.getDuration() > 0) {
                            long currentPosition = exoPlayer.getCurrentPosition();
                            this.fullReelsAdapter.savedVideoPositions.put(position, currentPosition);
                        }
                    }
                    FullReelsAdapter seriesReelsAdapter = this.fullReelsAdapter;
                    exoPlayer.stop();
                    exoPlayer.release();
                    if (position != RecyclerView.NO_POSITION && position < seriesReelsAdapter.players.size()) {
                        seriesReelsAdapter.players.set(position, null);
                    }
                }
                this.exoPlayer = null;
                this.binding.playerView.setPlayer(null);
                this.binding.seekbar.setProgress(0);
            } catch (Exception unused) {
            }
        }

        public void updatePiPMode(boolean isInPictureInPictureMode) {
            if (isInPictureInPictureMode) {
                binding.flContainer.setVisibility(View.GONE);
                binding.llEpisode.setVisibility(View.GONE);
                binding.viewShadowBottom.setVisibility(View.GONE);
                binding.btnBack.setVisibility(View.GONE);
                binding.imageSpeedButton.setVisibility(View.GONE);
                binding.playerView.setVisibility(View.VISIBLE);
            } else {
                binding.flContainer.setVisibility(View.VISIBLE);
                binding.llEpisode.setVisibility(View.VISIBLE);
                binding.viewShadowBottom.setVisibility(View.VISIBLE);
                binding.btnBack.setVisibility(View.VISIBLE);
                binding.imageSpeedButton.setVisibility(View.VISIBLE);
                binding.playerView.setVisibility(View.VISIBLE);
            }
        }
    }

    private void unSelPopupItemBackground(LayoutPopupDialogBinding binding) {
        binding.imageRight1.setVisibility(View.INVISIBLE);
        binding.imageView1.setVisibility(View.INVISIBLE);
        binding.imageRight2.setVisibility(View.INVISIBLE);
        binding.imageView2.setVisibility(View.INVISIBLE);
        binding.imageRight3.setVisibility(View.INVISIBLE);
        binding.imageView3.setVisibility(View.INVISIBLE);
        binding.imageRight4.setVisibility(View.INVISIBLE);
        binding.imageView4.setVisibility(View.INVISIBLE);
        binding.imageRight5.setVisibility(View.INVISIBLE);
        binding.imageView5.setVisibility(View.INVISIBLE);
        binding.imageRight6.setVisibility(View.INVISIBLE);
        binding.imageView6.setVisibility(View.INVISIBLE);

    }

    private void setPopupItemBackground(View imageview1, ImageView imageView) {
        imageview1.setVisibility(View.VISIBLE);
        imageView.setVisibility(View.VISIBLE);

    }

    private void applySavedSpeedUI(LayoutPopupDialogBinding binding, float speed) {

        unSelPopupItemBackground(binding);

        if (speed == 2.0f) {
            setPopupItemBackground(binding.imageView1, binding.imageRight1);
        } else if (speed == 1.5f) {
            setPopupItemBackground(binding.imageView2, binding.imageRight2);
        } else if (speed == 1.25f) {
            setPopupItemBackground(binding.imageView3, binding.imageRight3);
        } else if (speed == 1.0f) {
            setPopupItemBackground(binding.imageView4, binding.imageRight4);
        } else if (speed == 0.75f) {
            setPopupItemBackground(binding.imageView5, binding.imageRight5);
        } else if (speed == 0.5f) {
            setPopupItemBackground(binding.imageView6, binding.imageRight6);
        }
    }

    private void setSpeed(ExoPlayer exoPlayer, float v, PopupWindow popupWindow, TextView textViewSpeed) {
        if (exoPlayer != null) {
            exoPlayer.setPlaybackParameters(
                    new PlaybackParameters(v)
            );
        }
        textViewSpeed.setText(v + "x");
    }

    private static final String PREF_NAME = "player_pref";
    private static final String KEY_SPEED = "playback_speed";

    private void saveSpeed(Context context, float speed) {
        SharedPreferences prefs =
                context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        prefs.edit().putFloat(KEY_SPEED, speed).apply();
    }

    private float getSavedSpeed(Context context) {
        SharedPreferences prefs =
                context.getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
        return prefs.getFloat(KEY_SPEED, 1.0f); // default 1x
    }

    public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode) {
        this.isInPictureInPictureMode = isInPictureInPictureMode;

        if (recyclerView != null) {
            for (int i = 0; i < recyclerView.getChildCount(); i++) {
                RecyclerView.ViewHolder viewHolder = recyclerView.getChildViewHolder(recyclerView.getChildAt(i));
                if (viewHolder instanceof ReelViewHolder) {
                    ((ReelViewHolder) viewHolder).updatePiPMode(isInPictureInPictureMode);
                }
            }
        }
    }
}
