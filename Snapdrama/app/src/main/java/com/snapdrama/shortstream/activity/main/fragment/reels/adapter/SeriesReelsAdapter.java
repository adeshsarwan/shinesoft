package com.snapdrama.shortstream.activity.main.fragment.reels.adapter;

import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.SeekBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager2.widget.ViewPager2;

import com.bumptech.glide.Glide;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.full_reels.ReelsShowActivity;
import com.snapdrama.shortstream.activity.main.fragment.ReelsFragment;
import com.snapdrama.shortstream.databinding.ItemReelBinding;
import com.snapdrama.shortstream.engineBox.model.episdata.EpisodeListModel;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.Player;
import com.google.android.material.bottomsheet.BottomSheetDialog;

import java.util.ArrayList;
import java.util.List;

import kotlin.Unit;
import kotlin.jvm.functions.Function1;
import kotlin.jvm.functions.Function2;
import kotlin.jvm.internal.DefaultConstructorMarker;

public final class SeriesReelsAdapter extends RecyclerView.Adapter<SeriesReelsAdapter.ReelViewHolder> {
    public static final Companion Companion = new Companion(null);
    private static SeriesReelsAdapter instance;
    private final Context context;
    private int currentPlayingPosition;
    //    private final Handler handler;
    private final ActivityResultLauncher<Intent> infoLauncher;
    private boolean isMuted;
    private boolean isSeries;
    private final Function1<Integer, Unit> onClickMoreEpisodeListener;
    private final Function2<Integer, EpisodeListModel.Datum, Unit> onLikeChangeListener;
    private final Function1<Boolean, Unit> onMuteChangeListener;
    private final Function1<EpisodeListModel.Datum, Unit> onPlay;
    private final Function2<Integer, EpisodeListModel.Datum, Unit> onSetFavouriteListener;
    private final Function1<Integer, Unit> onShowPaymentDialog;
    private final List<ExoPlayer> players;
    private RecyclerView recyclerView;
    private List<EpisodeListModel.Datum> reels;
    private final ReelsFragment reelsFragment;
    private Runnable updateSeekBarRunnable;
    private Handler handler = new Handler(Looper.getMainLooper());

    public final List<EpisodeListModel.Datum> getReels() {
        return (List<EpisodeListModel.Datum>) this.reels;
    }

    public final void setReels(List<EpisodeListModel.Datum> list) {
        this.reels = list;
    }

    public final ActivityResultLauncher<Intent> getInfoLauncher() {
        return this.infoLauncher;
    }


    public SeriesReelsAdapter(Context context, ReelsFragment reelsFragment, List<EpisodeListModel.Datum> reels, boolean z, boolean z2, ActivityResultLauncher<Intent> infoLauncher, Function2<? super Integer, ? super EpisodeListModel.Datum, Unit> onLikeChangeListener, Function2<? super Integer, ? super EpisodeListModel.Datum, Unit> onSetFavouriteListener, Function1<? super Boolean, Unit> onMuteChangeListener, Function1<? super Integer, Unit> onClickMoreEpisodeListener, Function1<? super Integer, Unit> onShowPaymentDialog,  Function1<? super EpisodeListModel.Datum, Unit> onPlay) {
        this.context = context;
        this.reelsFragment = reelsFragment;
        this.reels = reels;
        this.isSeries = z;
        this.isMuted = z2;
        this.infoLauncher = infoLauncher;
        this.onLikeChangeListener = (Function2<Integer, EpisodeListModel.Datum, Unit>) onLikeChangeListener;
        this.onSetFavouriteListener = (Function2<Integer, EpisodeListModel.Datum, Unit>) onSetFavouriteListener;
        this.onMuteChangeListener = (Function1<Boolean, Unit>) onMuteChangeListener;
        this.onClickMoreEpisodeListener = (Function1<Integer, Unit>) onClickMoreEpisodeListener;
        this.onShowPaymentDialog = (Function1<Integer, Unit>) onShowPaymentDialog;
        this.onPlay = (Function1<EpisodeListModel.Datum, Unit>) onPlay;
        this.currentPlayingPosition = -1;
        this.players = new ArrayList();
        this.handler = new Handler(Looper.getMainLooper());
        this.updateSeekBarRunnable = new Runnable() {
            @Override
            public void run() {
                ExoPlayer exoPlayer;
                RecyclerView recyclerView;
                if (SeriesReelsAdapter.this.getCurrentPlayingPosition() != -1 && SeriesReelsAdapter.this.getCurrentPlayingPosition() < SeriesReelsAdapter.this.players.size() && (exoPlayer = (ExoPlayer) SeriesReelsAdapter.this.players.get(SeriesReelsAdapter.this.getCurrentPlayingPosition())) != null) {
                    SeriesReelsAdapter seriesReelsAdapter = SeriesReelsAdapter.this;
                    recyclerView = seriesReelsAdapter.recyclerView;
                    RecyclerView.ViewHolder findViewHolderForAdapterPosition = recyclerView != null ? recyclerView.findViewHolderForAdapterPosition(seriesReelsAdapter.getCurrentPlayingPosition()) : null;
                    SeriesReelsAdapter.ReelViewHolder reelViewHolder = findViewHolderForAdapterPosition instanceof SeriesReelsAdapter.ReelViewHolder ? (SeriesReelsAdapter.ReelViewHolder) findViewHolderForAdapterPosition : null;
                    if (reelViewHolder != null) {
                        reelViewHolder.updateSeekBar(exoPlayer);
                    }
                }
                SeriesReelsAdapter.this.handler.postDelayed(this, 500L);
            }
        };
        int size = this.reels.size();
        for (int i = 0; i < size; i++) {
            this.players.add(null);
        }
        instance = this;
    }

    public final int getCurrentPlayingPosition() {
        return this.currentPlayingPosition;
    }

    public final void setCurrentPlayingPosition(int i) {
        this.currentPlayingPosition = i;
    }


    public static final class Companion {
        public Companion(DefaultConstructorMarker defaultConstructorMarker) {
            this();
        }

        private Companion() {
        }

        public final SeriesReelsAdapter getInstance() {
            return SeriesReelsAdapter.instance;
        }

        public final void setInstance(SeriesReelsAdapter seriesReelsAdapter) {
            SeriesReelsAdapter.instance = seriesReelsAdapter;
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
        getSeriesDetail();
    }

    private void getSeriesDetail() {

    }

    @Override
    public void onViewRecycled(ReelViewHolder holder) {

        super.onViewRecycled(holder);
        holder.releasePlayer();
    }

    public void updatePlayback(int position) {

        if (position == -1 || position == currentPlayingPosition) {
            return;
        }

        // 1️⃣ Update playing state in reels list
        if (reels != null && !reels.isEmpty()) {
            for (int i = 0; i < reels.size(); i++) {
                EpisodeListModel.Datum reel = reels.get(i);
                if (reel != null) {
//                    reel.setPlaying(i == position);
                }
            }
            notifyDataSetChanged();
        }

        // 2️⃣ Pause previous player
        if (currentPlayingPosition != -1
                && currentPlayingPosition < players.size()) {

            ExoPlayer oldPlayer = players.get(currentPlayingPosition);
            if (oldPlayer != null) {
                oldPlayer.setPlayWhenReady(false);
                oldPlayer.pause();
            }
        }

        // 3️⃣ Play new player
        currentPlayingPosition = position;

        if (position < players.size()) {
            ExoPlayer newPlayer = players.get(position);
            if (newPlayer != null) {
                newPlayer.setPlayWhenReady(true);
                newPlayer.play();
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
                exoPlayer.setPlayWhenReady(this.reelsFragment.isVisible());
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
    }

    @Override
    public void onDetachedFromRecyclerView(RecyclerView recyclerView) {
        super.onDetachedFromRecyclerView(recyclerView);
        releaseAllPlayers();
        this.recyclerView = null;
    }


    public final class ReelViewHolder extends RecyclerView.ViewHolder {
        private final ItemReelBinding binding;
        private ExoPlayer exoPlayer;
        final SeriesReelsAdapter this$0;

        public ReelViewHolder(SeriesReelsAdapter seriesReelsAdapter, ItemReelBinding binding) {
            super(binding.getRoot());

            this.this$0 = seriesReelsAdapter;
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

        private void showBottomSheet(List<EpisodeListModel.Datum> reels, int i) {
            BottomSheetDialog bottomSheetDialog =
                    new BottomSheetDialog(context, R.style.TransparentBottomSheetDialog);
            View view = LayoutInflater.from(context)
                    .inflate(R.layout.layout_episode_list, null);

            ViewPager2 mainViewPager = view.findViewById(R.id.mainViewPager);
            ImageView imgViewCategory1 = view.findViewById(R.id.imgViewCategory1);
            ImageView imgViewCategory2 = view.findViewById(R.id.imgViewCategory2);
            ImageView imageSeries = view.findViewById(R.id.imageSeries);
            TextView textView1 = view.findViewById(R.id.textView1);
            TextView textView2 = view.findViewById(R.id.textView2);


            bottomSheetDialog.setContentView(view);
            bottomSheetDialog.setCancelable(true);

            View bottomSheet =
                    bottomSheetDialog.findViewById(com.google.android.material.R.id.design_bottom_sheet);

            if (bottomSheet != null) {
                bottomSheet.setBackgroundResource(android.R.color.transparent);
            }

            if (reels.get(i).getEpisodePart().getThumbnail() != null) {
                Glide.with(context).load(reels.get(i).getEpisodePart().getThumbnail()).placeholder(R.drawable.image_poster_placeholder).into(imageSeries);
            }
            textView1.setText(reels.get(i).getTitle());
            textView2.setText(reels.get(i).getIntro());

//            //    SeriesReelsAdapter
//            MainPagerAdapter adapter =
//                    new MainPagerAdapter(
//                            reelsFragment.getChildFragmentManager(),
//                            reelsFragment.getLifecycle(),
//                           new ShortDetailModel("")
//                    );
//
//            mainViewPager.setAdapter(adapter);
            imgViewCategory1.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    mainViewPager.setCurrentItem(0);
                    imgViewCategory1.setImageDrawable(
                            ContextCompat.getDrawable(context, R.drawable.image_cate_synopsis_select)
                    );
                    imgViewCategory2.setImageDrawable(
                            ContextCompat.getDrawable(context, R.drawable.image_cate_episodes_unselect)
                    );
                }
            });
            imgViewCategory2.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    mainViewPager.setCurrentItem(1);
                    imgViewCategory1.setImageDrawable(
                            ContextCompat.getDrawable(context, R.drawable.image_cate_synopsis_unselect)
                    );
                    imgViewCategory2.setImageDrawable(
                            ContextCompat.getDrawable(context, R.drawable.image_cate_episodes_select)
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
                                ContextCompat.getDrawable(context, R.drawable.image_cate_synopsis_select)
                        );
                        imgViewCategory2.setImageDrawable(
                                ContextCompat.getDrawable(context, R.drawable.image_cate_episodes_unselect)
                        );
                    } else if (position == 1) {
                        imgViewCategory1.setImageDrawable(
                                ContextCompat.getDrawable(context, R.drawable.image_cate_synopsis_unselect)
                        );
                        imgViewCategory2.setImageDrawable(
                                ContextCompat.getDrawable(context, R.drawable.image_cate_episodes_select)
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

        public final void bind(ReelViewHolder holder, final EpisodeListModel.Datum reelInfo, boolean z, boolean z2, final int i) {
            this.binding.playTotal.setVisibility(View.VISIBLE);
            binding.playTotal.setText("/EP. " + reelInfo.getEpisodeCount());
            binding.playCur.setText("EP." + reelInfo.getEpisodePart().getPartIndex());

//
//
//            getBinding().linearEpisodesList.setVisibility(View.INVISIBLE);
//
//            getBinding().linearEpisodesList.setOnClickListener(new View.OnClickListener() {
//                @Override
//                public void onClick(View view) {
////                    showBottomSheet(reels, i);
//                    showBottomSheet(reels, i);
//                }
//            });
            getBinding().linearWatchFullSeries.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
//                    showBottomSheet(reels, i);
                    Intent intent = new Intent(context, ReelsShowActivity.class);
                    intent.putExtra("SERIES_ID_EXTRA",reels.get(i).getId());
                    intent.putExtra("SERIES_ID_Episode",0);
                    context.startActivity(intent);
                }
            });
            getBinding().buttonList.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    Intent intent = new Intent(context, ReelsShowActivity.class);
                    intent.putExtra("SERIES_ID_EXTRA",reels.get(i).getId());
                    intent.putExtra("SERIES_ID_Episode",0);
                    context.startActivity(intent);
                }
            });

            releasePlayer();
            final ExoPlayer build = new ExoPlayer.Builder(this.this$0.context).build();
            final SeriesReelsAdapter seriesReelsAdapter = this.this$0;

            String videoUrl = reelInfo.getEpisodePart().getStreamHls();
            if (videoUrl != null) {
                build.setVideoScalingMode(1);
                build.setHandleAudioBecomingNoisy(true);
                MediaItem mediaItem = MediaItem.fromUri(videoUrl);

                build.setMediaItem(mediaItem);

                build.prepare();
                build.setVolume(z ? 0.0f : 1.0f);
                build.setPlayWhenReady(true);
                build.addListener(new Player.Listener() {
                    @Override
                    public void onPlaybackStateChanged(int i4) {
                        ReelsFragment reelsFragment;
                        Function1 function1;
                        ExoPlayer exoPlayer = null;
                        RecyclerView recyclerView;
                        RecyclerView.LayoutManager layoutManager;
                        if (i4 == 3) {
                            reelsFragment = SeriesReelsAdapter.this.reelsFragment;
                            if (!reelsFragment.isAdded() && (exoPlayer != null)) {
                                exoPlayer.setPlayWhenReady(false);
                            }
                            if (getAdapterPosition() == SeriesReelsAdapter.this.getCurrentPlayingPosition()) {
                                updateSeekBar(build);
                                if (build.isPlaying()) {
                                    function1 = SeriesReelsAdapter.this.onPlay;
                                    function1.invoke(reelInfo);
                                    getBinding().playPauseIcon.setImageResource(R.drawable.ic_pause);
//                                    binding.flContainer.setVisibility(View.GONE);

                                    return;
                                }
                                getBinding().playPauseIcon.setImageResource(R.drawable.ic_play);
                            }
                        } else if (i4 == 4 && getAdapterPosition() == SeriesReelsAdapter.this.getCurrentPlayingPosition()) {
                            int adapterPosition = getAdapterPosition() + 1;
                            if (adapterPosition < SeriesReelsAdapter.this.getReels().size()) {
                                setCurrentPlayingPosition(adapterPosition);
                                updatePlayback(adapterPosition);
                                recyclerView = SeriesReelsAdapter.this.recyclerView;
                                if (recyclerView == null || (layoutManager = recyclerView.getLayoutManager()) == null) {
                                    return;
                                }
                                layoutManager.scrollToPosition(adapterPosition);
                                return;
                            }
                            build.setPlayWhenReady(false);
                            SeriesReelsAdapter.this.setCurrentPlayingPosition(-1);
                            SeriesReelsAdapter.this.handler.removeCallbacks(SeriesReelsAdapter.this.updateSeekBarRunnable);
                            getBinding().playPauseIcon.setImageResource(R.drawable.ic_play);
                            Context context = SeriesReelsAdapter.this.context;
                            AppCompatActivity appCompatActivity = context instanceof AppCompatActivity ? (AppCompatActivity) context : null;
                            if (appCompatActivity == null) {
                                Toast.makeText(
                                        SeriesReelsAdapter.this.context,
                                        "finish activity is null",
                                        Toast.LENGTH_SHORT
                                ).show();
                            } else {
                                appCompatActivity.finish();
                            }

                            Toast.makeText(
                                    SeriesReelsAdapter.this.context,
                                    "No more items to play",
                                    Toast.LENGTH_SHORT
                            ).show();
                        }
                    }

                    @Override
                    public void onPlayWhenReadyChanged(boolean z3, int i4) {
                        if (z3 && getAdapterPosition() == SeriesReelsAdapter.this.getCurrentPlayingPosition()) {
                            if (build.isPlaying()) {
                                getBinding().playPauseIcon.setImageResource(R.drawable.ic_pause);

                                hideFlContainer(binding);
                                return;
                            }
                            getBinding().playPauseIcon.setImageResource(R.drawable.ic_play);
                        }
                    }
                });
            }
            this.exoPlayer = build;
            this.binding.playerView.setPlayer(this.exoPlayer);
            this.binding.playerView.setShowBuffering(2);
            this.binding.playerView.setResizeMode(4);
            this.binding.playerView.setUseController(false);
            this.this$0.players.set(i, this.exoPlayer);

            this.binding.btnBack.setVisibility(4);
            this.binding.textSeriesName.setText(reelInfo.getTitle());
            this.binding.textSeriesDescription.setText(reelInfo.getDescription());

            this.binding.volumeIcon.setImageResource(z ? R.drawable.ic_volume_off : R.drawable.ic_volume_on);
            ImageView imageView3 = this.binding.volumeIcon;
            final SeriesReelsAdapter seriesReelsAdapter3 = this.this$0;
            imageView3.setOnClickListener(new View.OnClickListener() {
                @Override
                public final void onClick(View view) {
                    ExoPlayer exoPlayer = holder.exoPlayer;
                    if (exoPlayer == null || !exoPlayer.isPlaying()) {
                        return;
                    }
                    seriesReelsAdapter.isMuted = !seriesReelsAdapter.isMuted;
                    exoPlayer.setVolume(seriesReelsAdapter.isMuted ? 0.0f : 1.0f);
                    getBinding().volumeIcon.setImageResource(seriesReelsAdapter.isMuted ? R.drawable.ic_volume_off : R.drawable.ic_volume_on);
                    seriesReelsAdapter.onMuteChangeListener.invoke(Boolean.valueOf(seriesReelsAdapter.isMuted));
                }
            });
            this.binding.seekbar.setMax(100);
            updateSeekBar(this.exoPlayer);
            ImageView imageView4 = this.binding.playPauseIcon;
            final SeriesReelsAdapter seriesReelsAdapter4 = this.this$0;
            imageView4.setOnClickListener(new View.OnClickListener() {
                @Override
                public final void onClick(View view) {
                    ExoPlayer exoPlayer = holder.exoPlayer;
                    if (exoPlayer != null) {
//                        if (reelInfo.isLocked()) {
//                            seriesReelsAdapter.onShowPaymentDialog.invoke(Integer.valueOf(i));
//                            return;
//                        }
                        if (exoPlayer.isPlaying()) {
                            exoPlayer.setPlayWhenReady(false);
//                            reelInfo.setPlaying(false);
                            binding.playPauseIcon.setImageResource(R.drawable.ic_play);
                        } else {
                            exoPlayer.setPlayWhenReady(true);
//                            reelInfo.setPlaying(true);
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
            this.binding.playerView.setOnClickListener(new View.OnClickListener() {
                @Override
                public final void onClick(View view) {
                    if (binding.flContainer.getVisibility() != View.VISIBLE) {
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
//            ImageView imageView5 = this.binding.imgLike;
//            final SeriesReelsAdapter seriesReelsAdapter5 = this.this$0;
//            imageView5.setOnClickListener(new View.OnClickListener() {
//                @Override
//                public final void onClick(View view) {
//                    String valueOf;
//                    int i;
//                    reelInfo.setLiked(reelInfo.isLiked() == 0 ? 1 : 0);
//                    TextView textView = binding.textLike;
//                    if (reelInfo.isLiked() == 1) {
//                        valueOf = String.valueOf(Integer.parseInt(binding.textLike.getText().toString()) + 1);
//                    } else {
//                        valueOf = String.valueOf(Integer.parseInt(binding.textLike.getText().toString()) - 1);
//                    }
//                    textView.setText(valueOf);
//                    ImageView imageView = binding.imgLike;
//                    if (reelInfo.isLiked() == 1) {
//                        i = R.drawable.ic_like_fill;
//                    } else {
//                        i = R.drawable.ic_like;
//                    }
//                    imageView.setImageResource(i);
//                    seriesReelsAdapter.onLikeChangeListener.invoke(Integer.valueOf(getAdapterPosition()), reelInfo);
//                }
//            });

        }





        public final void hideFlContainer(ItemReelBinding binding) {

            binding.flContainer.setVisibility(View.GONE);

        }

        public final void showFlContainer(ItemReelBinding binding) {

            binding.flContainer.setVisibility(View.VISIBLE);
        }

        public final void updateSeekBar(ExoPlayer exoPlayer) {
            if (exoPlayer != null) {
                long duration = exoPlayer.getDuration();
                long currentPosition = exoPlayer.getCurrentPosition();
                if (duration > 0) {
                    this.binding.seekbar.setProgress((int) ((currentPosition * 100) / duration));
                    return;
                }
                this.binding.seekbar.setProgress(0);
            }
        }

        public final void releasePlayer() {
            try {
                ExoPlayer exoPlayer = this.exoPlayer;
                if (exoPlayer != null) {
                    SeriesReelsAdapter seriesReelsAdapter = this.this$0;
                    exoPlayer.stop();
                    exoPlayer.release();
                    if (seriesReelsAdapter.players.get(getAdapterPosition()) != null) {
                        seriesReelsAdapter.players.set(getAdapterPosition(), null);
                    }
                }
                this.exoPlayer = null;
                this.binding.playerView.setPlayer(null);
                this.binding.seekbar.setProgress(0);
            } catch (Exception unused) {
            }
        }
    }
}