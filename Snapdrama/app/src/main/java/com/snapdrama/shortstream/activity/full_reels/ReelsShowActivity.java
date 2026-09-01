package com.snapdrama.shortstream.activity.full_reels;

import android.app.PictureInPictureParams;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.res.Configuration;
import android.graphics.Insets;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.util.Rational;
import android.view.LayoutInflater;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.widget.TextView;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.RequiresApi;
import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.Observer;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.PagerSnapHelper;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager2.widget.CompositePageTransformer;
import androidx.viewpager2.widget.MarginPageTransformer;
import androidx.viewpager2.widget.ViewPager2;

import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.full_reels.adapter.FullReelsAdapter;
import com.snapdrama.shortstream.adapter.InfiniteExitAdapter;
import com.snapdrama.shortstream.ads.ReelsInterstitialManager;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.databinding.ActivityReelsShowAllBinding;
import com.snapdrama.shortstream.engineBox.client.EngineClient;
import com.snapdrama.shortstream.engineBox.interfaces.EngineInterface;
import com.snapdrama.shortstream.engineBox.model.videodata.AllEpisodeModel;
import com.snapdrama.shortstream.engineBox.model.rank.RankSeriesModel;
import com.snapdrama.shortstream.engineBox.model.detail.ShortDetailModel;
import com.snapdrama.shortstream.activity.main.fragment.reels.interfaces.PipPlayerListener;
import com.snapdrama.shortstream.model.SliderItemModel;
import com.snapdrama.shortstream.mvvmRepo.model.RankingSeriesViewModel;
import com.snapdrama.shortstream.mvvmRepo.model.SeriesViewModel;
import com.stripe.android.paymentsheet.PaymentSheet;
import com.stripe.android.paymentsheet.PaymentSheetResult;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import retrofit2.Call;
import retrofit2.Response;

public class ReelsShowActivity extends AppCompatActivity implements PipPlayerListener {
    List<AllEpisodeModel> episodeList = new ArrayList<>();
    ActivityReelsShowAllBinding binding;
    FullReelsAdapter adapter;
    private ActivityResultLauncher<Intent> infoLauncher;
    String SERIES_ID_EXTRA = "";
    private ExoPlayer currentPlayer;
    private PaymentSheet paymentSheet;
    private BroadcastReceiver pipStopReceiver;
    private int lastPlayedPosition = -1;
    private ReelsInterstitialManager interstitialManager;
    private RankingSeriesViewModel rankingSeriesViewModel;
    InfiniteExitAdapter infiniteExitAdapter;
    private boolean isUserScrolling = false;
    Handler sliderHandler;
    Runnable sliderRunnable;
    public static ReelsShowActivity instance;


    List<RankSeriesModel.Datum> data = new ArrayList<>();
    List<SliderItemModel> sliderItemModels = new ArrayList<>();

    private static final String ACTION_MEDIA_CONTROL = "media_control";
    private static final String EXTRA_CONTROL_TYPE = "control_type";
    private static final int CONTROL_TYPE_PLAY = 1;
    private static final int CONTROL_TYPE_PAUSE = 2;
    private static final int REQUEST_PLAY = 1;
    private static final int REQUEST_PAUSE = 2;


    private final BroadcastReceiver broadcastReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            if (ACTION_MEDIA_CONTROL.equals(intent.getAction())) {
                int controlType = intent.getIntExtra(EXTRA_CONTROL_TYPE, 0);
                if (currentPlayer != null) {
                    switch (controlType) {
                        case CONTROL_TYPE_PLAY:
                            currentPlayer.play();
                            break;
                        case CONTROL_TYPE_PAUSE:
                            currentPlayer.pause();
                            break;
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        updatePictureInPictureParams(currentPlayer.isPlaying());
                    }
                }
            }
        }
    };

    @Override
    public void onPlayerReady(ExoPlayer player) {
        currentPlayer = player;
        currentPlayer.addListener(new com.google.android.exoplayer2.Player.Listener() {
            @Override
            public void onIsPlayingChanged(boolean isPlaying) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && isInPictureInPictureMode()) {
                    updatePictureInPictureParams(isPlaying);
                }
            }
        });
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    public void enterPictureInPictureMode() {
        if (currentPlayer == null && adapter != null) {
            currentPlayer = adapter.getCurrentPlayer();
        }

        if (currentPlayer != null && currentPlayer.isPlaying()) {
            Rational aspectRatio = new Rational(9, 16);
            PictureInPictureParams.Builder paramsBuilder = new PictureInPictureParams.Builder()
                    .setAspectRatio(aspectRatio);

            updatePictureInPictureParams(paramsBuilder, currentPlayer.isPlaying());

            try {
                enterPictureInPictureMode(paramsBuilder.build());
            } catch (IllegalStateException e) {
                finish();
            }
        } else {
            finish();
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private void updatePictureInPictureParams(boolean isPlaying) {
        if (currentPlayer == null) return;

        PictureInPictureParams.Builder paramsBuilder = new PictureInPictureParams.Builder();
        updatePictureInPictureParams(paramsBuilder, isPlaying);
        setPictureInPictureParams(paramsBuilder.build());
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private void updatePictureInPictureParams(PictureInPictureParams.Builder paramsBuilder, boolean isPlaying) {
        ArrayList<android.app.RemoteAction> actions = new ArrayList<>();

        if (isPlaying) {
            actions.add(createRemoteAction(
                    R.drawable.ic_pause,
                    getString(R.string.pause),
                    CONTROL_TYPE_PAUSE,
                    REQUEST_PAUSE
            ));
        } else {
            actions.add(createRemoteAction(
                    R.drawable.ic_play,
                    getString(R.string.play),
                    CONTROL_TYPE_PLAY,
                    REQUEST_PLAY
            ));
        }

        paramsBuilder.setActions(actions);
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    private android.app.RemoteAction createRemoteAction(int iconResId, String title, int controlType, int requestCode) {
        return new android.app.RemoteAction(
                android.graphics.drawable.Icon.createWithResource(this, iconResId),
                title,
                title,
                android.app.PendingIntent.getBroadcast(
                        this,
                        requestCode,
                        new Intent(ACTION_MEDIA_CONTROL).putExtra(EXTRA_CONTROL_TYPE, controlType),
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT | android.app.PendingIntent.FLAG_IMMUTABLE
                )
        );
    }

    @Override
    public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode, Configuration newConfig) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);
        if (adapter != null) {
            adapter.onPictureInPictureModeChanged(isInPictureInPictureMode);
        }

        if (isInPictureInPictureMode) {
            IntentFilter filter = new IntentFilter();
            filter.addAction(ACTION_MEDIA_CONTROL);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(broadcastReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
            } else {
                registerReceiver(broadcastReceiver, filter);
            }

            if (currentPlayer != null) {
                currentPlayer.setPlayWhenReady(true);
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    updatePictureInPictureParams(true);
                }
            }
        } else {
            try {
                unregisterReceiver(broadcastReceiver);
            } catch (Exception e) {
            }
        }
    }

    @Override
    public void onUserLeaveHint() {
        super.onUserLeaveHint();
        if (adapter != null) {
            currentPlayer = adapter.getCurrentPlayer();
        }
        if (currentPlayer != null && currentPlayer.isPlaying()) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                enterPictureInPictureMode();
            }
        }
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);

        paymentSheet = new PaymentSheet(this, this::onPaymentSheetResult);
        instance = this;
        getOnBackPressedDispatcher().addCallback(this,new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                showBottomSheet(ReelsShowActivity.this);

            }
        });

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            View root = findViewById(android.R.id.content);

            root.setOnApplyWindowInsetsListener((v, insets) -> {
                Insets systemBars = insets.getInsets(WindowInsets.Type.systemBars());
                v.setPadding(
                        systemBars.left,
                        systemBars.top,
                        systemBars.right,
                        systemBars.bottom
                );
                return insets;
            });
        }
        setupRankObserver();
        interstitialManager = new ReelsInterstitialManager(this);

        FullReelsAdapter existingAdapter = FullReelsAdapter.Companion.getInstance();
        if (existingAdapter != null) {
            existingAdapter.pauseAllPlayers();
            existingAdapter.releaseAllPlayers();
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && isInPictureInPictureMode()) {
            finish();
        }

        pipStopReceiver = new BroadcastReceiver() {
            @Override
            public void onReceive(Context context, Intent intent) {
                if ("com.shortreel.dramatv.STOP_PIP_MODE".equals(intent.getAction())) {
                    releasePlayers();
                    finish();
                }
            }
        };
        IntentFilter filter = new IntentFilter("com.shortreel.dramatv.STOP_PIP_MODE");

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(pipStopReceiver, filter, Context.RECEIVER_NOT_EXPORTED);
        } else {
            registerReceiver(pipStopReceiver, filter);
        }

        binding = ActivityReelsShowAllBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        PagerSnapHelper snapHelper = new PagerSnapHelper();
        snapHelper.attachToRecyclerView(binding.reelsRecyclerView);
        this.infoLauncher = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), (result) -> {});
        binding.reelsRecyclerView.setLayoutManager(new LinearLayoutManager(this));

        binding.reelsRecyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {

            @Override
            public void onScrollStateChanged(RecyclerView recyclerView, int state) {
                super.onScrollStateChanged(recyclerView, state);

                if (state == RecyclerView.SCROLL_STATE_IDLE) {

                    RecyclerView.LayoutManager layoutManager = recyclerView.getLayoutManager();
                    if (!(layoutManager instanceof LinearLayoutManager)) return;

                    int position =
                            ((LinearLayoutManager) layoutManager)
                                    .findFirstCompletelyVisibleItemPosition();

                    if (position == RecyclerView.NO_POSITION) return;
                    if (position == lastPlayedPosition) return;

                    lastPlayedPosition = position;
                    FullReelsAdapter adapter = getSeriesReelsAdapter();
                    if (adapter == null) return;

                    adapter.pauseAllPlayers();

                    boolean isInterstitialEnabled = ControlPreference.getInterstitialShow();
                    if (isInterstitialEnabled) {
                        interstitialManager.onReelScrolled(position, () -> {
                            adapter.updatePlayback(position);
                        });

                    } else {
                        adapter.updatePlayback(position);
                    }
                }
            }

            @Override
            public void onScrolled(RecyclerView recyclerView, int dx, int dy) {
                super.onScrolled(recyclerView, dx, dy);
            }
        });
        if (getIntent().getStringExtra("SERIES_ID_EXTRA") != null) {
            SERIES_ID_EXTRA = getIntent().getStringExtra("SERIES_ID_EXTRA");
        }

        handleIntent(getIntent());

        SeriesViewModel viewModel =
                new ViewModelProvider(this).get(SeriesViewModel.class);

        viewModel.loadSeries("en", SERIES_ID_EXTRA);

        viewModel.getSeriesLiveData().observe(this, data -> {
            if (data != null) {
                List<ShortDetailModel> list = new ArrayList<>();
                list.add(data);
                getShortDramaVIDEO(list);
            }
        });

    }

    private void getShortDramaVIDEO(List<ShortDetailModel> shortDetailModels) {
        binding.progressLayout.mainLayout.setVisibility(View.VISIBLE);
        binding.reelsRecyclerView.setVisibility(View.GONE);
        EngineInterface apiService =
                EngineClient.getClient().create(EngineInterface.class);

        apiService.getShortDramaVideoTvSeries("en", shortDetailModels.get(0).getId()).enqueue(new retrofit2.Callback<List<AllEpisodeModel>>() {
            @Override
            public void onResponse(Call<List<AllEpisodeModel>> call, Response<List<AllEpisodeModel>> response) {

                if (response.isSuccessful()
                        && response.body() != null
                        && !response.body().isEmpty()) {

                    episodeList = response.body();
                    binding.reelsRecyclerView.setVisibility(View.VISIBLE);
                    binding.progressLayout.mainLayout.setVisibility(View.GONE);

                    adapter = new FullReelsAdapter(
                            ReelsShowActivity.this,
                            shortDetailModels,
                            getSupportFragmentManager(),
                            getLifecycle(),
                            ReelsShowActivity.this,
                            ReelsShowActivity.this,
                            episodeList,
                            true,
                            false,
                            infoLauncher,
                            1
                    );
                    if (adapter.getRewardUnlocker() != null) {
                        adapter.getRewardUnlocker().setPaymentSheet(paymentSheet);
                    }

                    binding.reelsRecyclerView.setAdapter(adapter);
                    fetchMyListEpisodes();

                    binding.reelsRecyclerView.post(() -> {
                        if (adapter != null && episodeList != null && !episodeList.isEmpty()) {

                            int startEpisode = 0;

                            if (getIntent() != null && getIntent().hasExtra("SERIES_ID_Episode")) {
                                startEpisode = getIntent().getIntExtra("SERIES_ID_Episode", 1) - 1;
                            }

                            if (startEpisode < 0 || startEpisode >= episodeList.size()) {
                                startEpisode = 0;
                            }
                            binding.reelsRecyclerView.scrollToPosition(startEpisode);
                            adapter.setCurrentPlayingPosition(startEpisode);
                            adapter.updatePlayback(startEpisode);

                        } else {
                        }
                    });

                } else {
                }

            }

            @Override
            public void onFailure(Call<List<AllEpisodeModel>> call, Throwable t) {
                t.printStackTrace();
            }
        });
    }
    public void changeSeries(String seriesId, int episodeIndex) {

        if (adapter != null) {
            adapter.dismissBottomSheet();
            adapter.pauseAllPlayers();
            adapter.releaseAllPlayers();
        }

        SERIES_ID_EXTRA = seriesId;

        if (getIntent() != null) {
            getIntent().putExtra("SERIES_ID_EXTRA", seriesId);
            getIntent().putExtra("SERIES_ID_Episode", episodeIndex );
        }

        SeriesViewModel viewModel =
                new ViewModelProvider(this).get(SeriesViewModel.class);

        viewModel.loadSeries("en", SERIES_ID_EXTRA);

        Observer<ShortDetailModel> observer = new Observer<ShortDetailModel>() {
            @Override
            public void onChanged(ShortDetailModel data) {

                if (data != null && data.getId() != null && data.getId().equals(SERIES_ID_EXTRA)) {

                    List<ShortDetailModel> list = new ArrayList<>();
                    list.add(data);

                    getShortDramaVIDEO(list);
                    viewModel.getSeriesLiveData().removeObserver(this);
                }
            }
        };

        viewModel.getSeriesLiveData().observe(this, observer);
    }
    private void onPaymentSheetResult(PaymentSheetResult result) {
        FullReelsAdapter a = getSeriesReelsAdapter();
        if (a != null && a.getRewardUnlocker() != null) {
            a.getRewardUnlocker().handlePaymentSheetResult(result);
        }
    }

    private void fetchMyListEpisodes() {

        String userId = FirebaseAuth.getInstance().getUid();
        if (userId == null || adapter == null) return;

        FirebaseFirestore.getInstance()
                .collection("users")
                .document(userId)
                .collection("my_list_data")
                .get()
                .addOnSuccessListener(querySnapshot -> {

                    Set<String> ids = new HashSet<>();

                    for (DocumentSnapshot doc : querySnapshot) {
                        String episodeId = doc.getString("episodeId");
                        if (episodeId != null) {
                            ids.add(episodeId);
                        }
                    }

                    adapter.setAddedEpisodeIds(ids);
                });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        instance = null;

        if (sliderHandler != null && sliderRunnable != null) {
            sliderHandler.removeCallbacks(sliderRunnable);
        }
        sliderHandler = null;
        sliderRunnable = null;
        if (pipStopReceiver != null) {
            try {
                unregisterReceiver(pipStopReceiver);
            } catch (IllegalArgumentException e) {
                Log.w("PiP", "BroadcastReceiver not registered or already unregistered.");
            }
        }
        releasePlayers();
    }

    private void releasePlayers() {
        if (currentPlayer != null) {
            try {
                currentPlayer.release();
                currentPlayer = null;
            } catch (Exception e) {
            }
        }
        if (adapter != null) {
            adapter.releaseAllPlayers();
        }
    }


    @Override
    protected void onPause() {
        super.onPause();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                && isInPictureInPictureMode()) {
            return;
        }

        if (adapter != null) {
            adapter.pauseAllPlayers();
        }
        if (sliderHandler != null && sliderRunnable != null) {
            sliderHandler.removeCallbacks(sliderRunnable);
        }
    }

    @Override
    protected void onNewIntent(Intent intent) {
        super.onNewIntent(intent);
        setIntent(intent);
        handleIntent(intent);
    }

    private void handleIntent(Intent intent) {
        if (intent != null && intent.hasExtra("SERIES_ID_EXTRA")) {
            String newSeriesId = intent.getStringExtra("SERIES_ID_EXTRA");

            if (adapter != null) {
                adapter.pauseAllPlayers();
                adapter.releaseAllPlayers();
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && isInPictureInPictureMode()) {
                finish();
                return;
            }

            if (newSeriesId != null && !newSeriesId.equals(SERIES_ID_EXTRA)) {
                SERIES_ID_EXTRA = newSeriesId;
                SeriesViewModel viewModel = new ViewModelProvider(this).get(SeriesViewModel.class);
                viewModel.loadSeries("en", SERIES_ID_EXTRA);
            }
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        if (adapter != null) {
            adapter.resumeCurrentPlayer();
        }
    }

    public final FullReelsAdapter getSeriesReelsAdapter() {
        return adapter;
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                && isInPictureInPictureMode()) {
            return;
        }

        if (adapter != null) {
            adapter.pauseAllPlayers();
        }
    }

    private void setupRankObserver() {


        rankingSeriesViewModel = new ViewModelProvider(this).get(RankingSeriesViewModel.class);


        rankingSeriesViewModel.getRankingSeries()
                .observe(this, response -> {

                    if (response == null || response.getData() == null
                            || response.getData().isEmpty())
                        return;
                    data = response.getData();


                });
    }

    private void showBottomSheet(Context context) {


        BottomSheetDialog bottomSheetDialog = new BottomSheetDialog(context, R.style.TransparentBottomSheetDialog);
        View view = LayoutInflater.from(context).inflate(R.layout.layout_exit_dialog, null);

        ViewPager2 viewPager2 = view.findViewById(R.id.viewPager2);
        TextView textWatch = view.findViewById(R.id.textWatch);
        TextView textExit = view.findViewById(R.id.textExit);
        TextView textViewSeriesTitle = view.findViewById(R.id.textViewSeriesTitle);
        TextView textSeriesDescription = view.findViewById(R.id.textSeriesDescription);
        bottomSheetDialog.setContentView(view);
        bottomSheetDialog.setCancelable(true);


        textExit.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                bottomSheetDialog.dismiss();
                finish();
            }
        });
        textWatch.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (sliderItemModels != null && !sliderItemModels.isEmpty()) {
                    int pos = infiniteExitAdapter.getRealPosition(viewPager2.getCurrentItem());
                    SliderItemModel item = sliderItemModels.get(pos);
                    bottomSheetDialog.dismiss();

                   changeSeries(item.getIds(), 0);


                } else {

                    bottomSheetDialog.dismiss();
                    finish();
                }
            }
        });
        infiniteExitAdapter = new InfiniteExitAdapter(sliderItemModels);
        viewPager2.setAdapter(infiniteExitAdapter);
        infiniteExitAdapter.showShimmer(true);

        viewPager2.setClipToPadding(false);
        viewPager2.setClipChildren(false);
        viewPager2.setOffscreenPageLimit(3);

        View child = viewPager2.getChildAt(0);
        if (child instanceof RecyclerView) {
            ((RecyclerView) child).setOverScrollMode(RecyclerView.OVER_SCROLL_NEVER);
        }

        viewPager2.post(() -> {
            viewPager2.setCurrentItem(1, false);
            infiniteExitAdapter.setCurrentCenterPosition(1);
        });

        CompositePageTransformer transformer = new CompositePageTransformer();
        transformer.addTransformer(new MarginPageTransformer(40));
        transformer.addTransformer((page, position) -> {
            float r = 1 - Math.abs(position);
            page.setScaleY(0.85f + r * 0.15f);
            page.setAlpha(0.8f + r * 0.2f);
        });
        viewPager2.setPageTransformer(transformer);

        sliderHandler = new Handler(Looper.getMainLooper());
        sliderRunnable = null;

        viewPager2.registerOnPageChangeCallback(
                new ViewPager2.OnPageChangeCallback() {
                    private int realItemCount = infiniteExitAdapter.getRealItemCount();
                    private int middlePosition = realItemCount * 1000;
                    private boolean isScrolling = false;
                    private int lastSelectedPosition = -1;

                    @Override
                    public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
                        super.onPageScrolled(position, positionOffset, positionOffsetPixels);
                    }

                    @Override
                    public void onPageSelected(int position) {
                        super.onPageSelected(position);

                        infiniteExitAdapter.setCurrentCenterPosition(position);

                        int realPosition = infiniteExitAdapter.getRealPosition(position);
                        if (sliderItemModels != null && !sliderItemModels.isEmpty() && realPosition >= 0 && realPosition < sliderItemModels.size()) {
                            SliderItemModel item = sliderItemModels.get(realPosition);
                            textViewSeriesTitle.setText(item.getTitle() != null ? item.getTitle() : "");
                            textSeriesDescription.setText(item.getDescription() != null ? item.getDescription() : "");
                        }

                        if (isUserScrolling || isScrolling) {
                            return;
                        }

                        if (position != lastSelectedPosition) {
                            int realPosition2 = infiniteExitAdapter.getRealPosition(position);
                            infiniteExitAdapter.setCurrentPosition(realPosition2);
                            lastSelectedPosition = position;

                            if (position < realItemCount) {
                                viewPager2.setCurrentItem(middlePosition + realPosition2, false);
                            } else if (position > infiniteExitAdapter.getItemCount() - realItemCount) {
                                viewPager2.setCurrentItem(middlePosition + realPosition2, false);
                            }

                        }
                    }

                    @Override
                    public void onPageScrollStateChanged(int state) {
                        super.onPageScrollStateChanged(state);

                        if (state == ViewPager2.SCROLL_STATE_DRAGGING) {
                            isUserScrolling = true;
                            isScrolling = true;
                        } else if (state == ViewPager2.SCROLL_STATE_SETTLING) {
                            isScrolling = true;
                        } else if (state == ViewPager2.SCROLL_STATE_IDLE) {
                            isScrolling = false;
                            isUserScrolling = false;
                            int position = viewPager2.getCurrentItem();
                            infiniteExitAdapter.setCurrentCenterPosition(position);
                            int realPosition = infiniteExitAdapter.getRealPosition(position);
                            infiniteExitAdapter.setCurrentPosition(realPosition);
                            lastSelectedPosition = position;

                            if (position < realItemCount || position > infiniteExitAdapter.getItemCount() - realItemCount) {
                                viewPager2.setCurrentItem(middlePosition + realPosition, false);
                            }
                        }
                    }
                });
        setupSliderWithApiData(data, viewPager2);
        bottomSheetDialog.show();


    }

    private void setupSliderWithApiData(List<RankSeriesModel.Datum> dataList, ViewPager2 viewPager2) {
        if (dataList == null || dataList.isEmpty()) {
            if (infiniteExitAdapter != null) {
                infiniteExitAdapter.showShimmer(false);
            }
            return;
        }

        sliderItemModels.clear();

        for (RankSeriesModel.Datum datum : dataList) {
            String imageUrl = datum.getCover() != null ? datum.getCover() : "";
            String title = datum.getTitle() != null ? datum.getTitle() : "";
            String description = datum.getDescription() != null ? datum.getDescription() : "";
            String ids = datum.getId() != null ? datum.getId() : "";

            if (description.length() > 100) {
                description = description.substring(0, 97) + "...";
            }

            sliderItemModels.add(new SliderItemModel(imageUrl, title, description, ids));
        }

        if (infiniteExitAdapter != null && viewPager2 != null) {
            infiniteExitAdapter.showShimmer(false);
            infiniteExitAdapter.notifyDataSetChanged();

            if (sliderItemModels.size() > 0) {
                int initialPosition = infiniteExitAdapter.getRealItemCount() * 1000;
                viewPager2.setCurrentItem(initialPosition, false);
                infiniteExitAdapter.setCurrentCenterPosition(initialPosition);
            }
        }
    }
}
