package com.snapdrama.shortstream.activity.main.fragment.popular_fragment;

import android.os.Bundle;

import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager2.widget.CompositePageTransformer;
import androidx.viewpager2.widget.MarginPageTransformer;
import androidx.viewpager2.widget.ViewPager2;

import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.snapdrama.shortstream.adapter.RankingHomeAdapter;
import com.snapdrama.shortstream.adapter.ShortDramaAdapter;
import com.snapdrama.shortstream.adapter.InfiniteSliderAdapter;
import com.snapdrama.shortstream.databinding.FragmentPopularSeriesBinding;
import com.snapdrama.shortstream.engineBox.model.episdata.EpisodeListModel;
import com.snapdrama.shortstream.engineBox.model.rank.RankSeriesModel;
import com.snapdrama.shortstream.model.HomeUiItem;
import com.snapdrama.shortstream.model.SliderItemModel;
import com.snapdrama.shortstream.mvvmRepo.model.PopularSeriesViewModel;
import com.snapdrama.shortstream.mvvmRepo.model.RankingSeriesViewModel;

import java.util.ArrayList;
import java.util.List;


public class PopularSeriesFragment extends Fragment {

    FragmentPopularSeriesBinding binding;
    private PopularSeriesViewModel popularSeriesViewModel;
    private RankingSeriesViewModel rankingSeriesViewModel;
    ShortDramaAdapter adapter;
    List<EpisodeListModel.Datum> dataList = new ArrayList<>();
    List<SliderItemModel> sliderItemModels = new ArrayList<>();
    InfiniteSliderAdapter infiniteSliderAdapter;
    Handler sliderHandler;
    Runnable sliderRunnable;
    private boolean isUserScrolling = false;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding = FragmentPopularSeriesBinding.inflate(inflater, container, false);

        infiniteSliderAdapter = new InfiniteSliderAdapter(sliderItemModels);
        binding.viewPager2.setAdapter(infiniteSliderAdapter);
        infiniteSliderAdapter.showShimmer(true);

        binding.viewPager2.setClipToPadding(false);
        binding.viewPager2.setClipChildren(false);
        binding.viewPager2.setOffscreenPageLimit(3);

        View child = binding.viewPager2.getChildAt(0);
        if (child instanceof RecyclerView) {
            ((RecyclerView) child).setOverScrollMode(RecyclerView.OVER_SCROLL_NEVER);
        }
        binding.viewPager2.post(() -> {
            binding.viewPager2.setCurrentItem(1, false);
            infiniteSliderAdapter.setCurrentCenterPosition(1);
        });
        CompositePageTransformer transformer = new CompositePageTransformer();
        transformer.addTransformer(new MarginPageTransformer(40));
        transformer.addTransformer((page, position) -> {
            float r = 1 - Math.abs(position);
            page.setScaleY(0.85f + r * 0.15f);
            page.setAlpha(0.8f + r * 0.2f);
        });
        binding.viewPager2.setPageTransformer(transformer);

        sliderHandler = new Handler(Looper.getMainLooper());
        sliderRunnable = null;

        binding.viewPager2.registerOnPageChangeCallback(
                new ViewPager2.OnPageChangeCallback() {
                    private int realItemCount = infiniteSliderAdapter.getRealItemCount();
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
                        
                        infiniteSliderAdapter.setCurrentCenterPosition(position);

                        if (isUserScrolling || isScrolling) {
                            return;
                        }
                        
                        if (position != lastSelectedPosition) {
                            int realPosition = infiniteSliderAdapter.getRealPosition(position);
                            infiniteSliderAdapter.setCurrentPosition(realPosition);
                            lastSelectedPosition = position;
                            
                            if (position < realItemCount) {
                                binding.viewPager2.setCurrentItem(middlePosition + realPosition, false);
                            } else if (position > infiniteSliderAdapter.getItemCount() - realItemCount) {
                                binding.viewPager2.setCurrentItem(middlePosition + realPosition, false);
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
                            int position = binding.viewPager2.getCurrentItem();
                            infiniteSliderAdapter.setCurrentCenterPosition(position);
                            int realPosition = infiniteSliderAdapter.getRealPosition(position);
                            infiniteSliderAdapter.setCurrentPosition(realPosition);
                            lastSelectedPosition = position;
                            
                            if (position < realItemCount || position > infiniteSliderAdapter.getItemCount() - realItemCount) {
                                binding.viewPager2.setCurrentItem(middlePosition + realPosition, false);
                            }
                        }
                    }
                });

        setupObserver();
        return binding.getRoot();
    }


    private void setupSliderWithApiData(List<RankSeriesModel.Datum> dataList) {
        if (dataList == null || dataList.isEmpty()) {
            if (infiniteSliderAdapter != null) {
                infiniteSliderAdapter.showShimmer(false);
            }
            return;
        }

        sliderItemModels.clear();

        int limit = Math.min(dataList.size(), 5);

        for (int i = 0; i < limit; i++) {
            RankSeriesModel.Datum datum = dataList.get(i);

            String imageUrl = datum.getCover() != null ? datum.getCover() : "";
            String title = datum.getTitle() != null ? datum.getTitle() : "";
            String description = datum.getDescription() != null ? datum.getDescription() : "";
            String ids = datum.getId() != null ? datum.getId() : "";

            if (description.length() > 100) {
                description = description.substring(0, 97) + "...";
            }

            sliderItemModels.add(new SliderItemModel(imageUrl, title, description, ids));
        }

        if (infiniteSliderAdapter != null && binding.viewPager2 != null) {
            infiniteSliderAdapter.showShimmer(false);
            infiniteSliderAdapter.notifyDataSetChanged();

            if (!sliderItemModels.isEmpty()) {
                int initialPosition = infiniteSliderAdapter.getRealItemCount() * 1000;
                binding.viewPager2.setCurrentItem(initialPosition, false);
                infiniteSliderAdapter.setCurrentCenterPosition(initialPosition);
            }
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        if (sliderHandler != null && sliderRunnable != null) {
            sliderHandler.removeCallbacks(sliderRunnable);
        }
    }

    @Override
    public void onResume() {
        super.onResume();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        if (sliderHandler != null && sliderRunnable != null) {
            sliderHandler.removeCallbacks(sliderRunnable);
        }
        sliderHandler = null;
        sliderRunnable = null;
    }



    private void setupObserver() {
        binding.recycleView2.setVisibility(View.GONE);


            popularSeriesViewModel = new ViewModelProvider(getActivity()).get(PopularSeriesViewModel.class);


        popularSeriesViewModel.getPopularSeries()
                .observe(getViewLifecycleOwner(), response -> {

                    if (response != null
                            && response.getData() != null
                            && !response.getData().isEmpty()) {

                        binding.recycleView.setLayoutManager(
                                new GridLayoutManager(getContext(), 3));
                        binding.recycleView.setHasFixedSize(true);

                        adapter = new ShortDramaAdapter(
                                getContext(),
                                response.getData(),0
                        );
                        binding.recycleView.setAdapter(adapter);
                        // Keep slot collapsed when after-login ads are hidden (avoid empty gap)
                        if (!com.snapdrama.shortstream.ads.PremiumPlanManager.shouldSkipAfterLoginAd(getContext())) {
                            binding.nativeAds.setVisibility(View.VISIBLE);
                        } else {
                            binding.nativeAds.setVisibility(View.GONE);
                        }
                        setupRankObserver();


                    } else {
                        binding.nativeAds.setVisibility(View.GONE);
                    }
                });
    }

    private void setupRankObserver() {
        binding.recycleView2.setVisibility(View.VISIBLE);


        if (getActivity() != null) {
            rankingSeriesViewModel = new ViewModelProvider(getActivity()).get(RankingSeriesViewModel.class);
        } else {
            rankingSeriesViewModel = new ViewModelProvider(this).get(RankingSeriesViewModel.class);
        }

        rankingSeriesViewModel.getRankingSeries()
                .observe(getViewLifecycleOwner(), response -> {

                    if (response == null || response.getData() == null
                            || response.getData().isEmpty())
                        return;

                    List<RankSeriesModel.Datum> data = response.getData();

                    setupSliderWithApiData(data);


                    List<HomeUiItem> uiList = new ArrayList<>();

                    int size = data.size();

                    if (size > 0) {
                        uiList.add(new HomeUiItem(
                                HomeUiItem.TYPE_BANNER, data.get(0)));
                    }
                    if (size >= 3) {
                        uiList.add(new HomeUiItem(
                                HomeUiItem.TYPE_RANKING,
                                new ArrayList<>(data.subList(0, 3)),0));
                    }
                    if (size > 1) {
                        uiList.add(new HomeUiItem(
                                HomeUiItem.TYPE_BANNER, data.get(1)));
                    }
                    if (size > 2) {
                        uiList.add(new HomeUiItem(
                                HomeUiItem.TYPE_BANNER, data.get(2)));
                    }
                    if (size >= 6) {
                        uiList.add(new HomeUiItem(
                                HomeUiItem.TYPE_RANKING,
                                new ArrayList<>(data.subList(3, 6)),3));
                    }
                    for (int i = 3; i < size; i++) {
                        uiList.add(new HomeUiItem(
                                HomeUiItem.TYPE_BANNER, data.get(i)));
                    }
                    GridLayoutManager manager =
                            new GridLayoutManager(getContext(), 2);
                    binding.recycleView2.setLayoutManager(manager);
                    binding.recycleView2.setAdapter(
                            new RankingHomeAdapter(getContext(), uiList));
                });
    }


}