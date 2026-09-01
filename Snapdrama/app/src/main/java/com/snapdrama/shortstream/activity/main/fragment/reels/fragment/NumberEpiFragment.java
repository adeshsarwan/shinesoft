package com.snapdrama.shortstream.activity.main.fragment.reels.fragment;

import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager.widget.ViewPager;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.engineBox.model.detail.ShortDetailModel;
import com.snapdrama.shortstream.activity.main.fragment.reels.interfaces.OnEpisodeClickListener;

import java.util.ArrayList;
import java.util.List;


public class NumberEpiFragment extends Fragment {

    EpisodeRangeAdapter rangeAdapter;
    LinearLayoutManager layoutManager;
    RecyclerView recyclerView;
    ViewPager viewPager;

    int TOTAL_EPISODES;
    private OnEpisodeClickListener listener;

    private static final String ARG_TOTAL = "total";
    private static final String ARG_LIST = "short_list";

    List<ShortDetailModel> shortList;

    public static NumberEpiFragment newInstance(
            int totalEpisodes,
            List<ShortDetailModel> list,
            OnEpisodeClickListener listener) {

        NumberEpiFragment fragment = new NumberEpiFragment();
        fragment.listener = listener;

        Bundle bundle = new Bundle();
        bundle.putInt(ARG_TOTAL, totalEpisodes);
        bundle.putParcelableArrayList(ARG_LIST, new ArrayList<>(list));
        fragment.setArguments(bundle);

        return fragment;
    }

    @Override
    public View onCreateView(
            LayoutInflater inflater,
            ViewGroup container,
            Bundle savedInstanceState) {

        View view = inflater.inflate(R.layout.fragment_number_epi, container, false);

        TOTAL_EPISODES = getArguments().getInt(ARG_TOTAL);
        shortList = getArguments().getParcelableArrayList(ARG_LIST);

        recyclerView = view.findViewById(R.id.recyclerView);
        viewPager = view.findViewById(R.id.mainViewPager);

        layoutManager = new LinearLayoutManager(
                getContext(),
                LinearLayoutManager.HORIZONTAL,
                false
        );

        recyclerView.setLayoutManager(layoutManager);

        setupRecycler();

        return view;
    }

    private void setupRecycler() {

        List<EpisodeRange> ranges = new ArrayList<>();

        int PAGE_SIZE = 29;
        int start = 1;
        while (start <= TOTAL_EPISODES) {
            int end = Math.min(start + PAGE_SIZE, TOTAL_EPISODES);
            ranges.add(new EpisodeRange(start, end));
            start = end + 1;
        }

        String seriesId = (shortList != null && !shortList.isEmpty())
                ? shortList.get(0).getId()
                : "unknown_series";

        EpisodePagerAdapter pagerAdapter =
                new EpisodePagerAdapter(getChildFragmentManager(), ranges, seriesId, listener);
        viewPager.setAdapter(pagerAdapter);

        rangeAdapter = new EpisodeRangeAdapter(
                ranges,
                position -> {
                    viewPager.setCurrentItem(position, true);
                    rangeAdapter.setSelected(position);
                }
        );
        SharedPreferences prefs =
                requireContext().getSharedPreferences("EpisodePrefs", Context.MODE_PRIVATE);
        int selectedEpisodeIndex = prefs.getInt("selected_episode", -1);


        if (selectedEpisodeIndex != -1) {
            final int finalPageIndex = getFinalPageIndex(selectedEpisodeIndex, PAGE_SIZE);
            viewPager.post(() -> {
                viewPager.setCurrentItem(finalPageIndex, false);
                rangeAdapter.setSelected(finalPageIndex);
                recyclerView.scrollToPosition(finalPageIndex);
            });
        }
        recyclerView.setAdapter(rangeAdapter);

        viewPager.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageSelected(int position) {
                rangeAdapter.setSelected(position);
                recyclerView.smoothScrollToPosition(position);
            }

            @Override public void onPageScrolled(int p, float o, int px) {}
            @Override public void onPageScrollStateChanged(int s) {}
        });
    }

    private static int getFinalPageIndex(int selectedEpisodeIndex, int PAGE_SIZE) {
        int pageIndex = selectedEpisodeIndex / PAGE_SIZE;


        if (selectedEpisodeIndex ==29 || selectedEpisodeIndex ==28){
            pageIndex=0;

        }
        else if (selectedEpisodeIndex == 59 || selectedEpisodeIndex == 58){
            pageIndex=1;

        }
        else if (selectedEpisodeIndex == 89 || selectedEpisodeIndex == 88){
            pageIndex=2;

        }
        else if (selectedEpisodeIndex == 119 || selectedEpisodeIndex == 118){
            pageIndex=3;

        }
        else if (selectedEpisodeIndex == 149 || selectedEpisodeIndex == 148){
            pageIndex=4;

        }
        else if (selectedEpisodeIndex == 179 || selectedEpisodeIndex == 178){
            pageIndex=5;

        }
        else if (selectedEpisodeIndex == 209 || selectedEpisodeIndex == 208){
            pageIndex=6;

        }
        else if (selectedEpisodeIndex == 239 || selectedEpisodeIndex == 238){
            pageIndex=7;

        }
        else if (selectedEpisodeIndex == 269 || selectedEpisodeIndex == 268){
            pageIndex=8;

        }
        else if (selectedEpisodeIndex == 299 || selectedEpisodeIndex == 298){
            pageIndex=8;

        }

        int finalPageIndex = pageIndex;
        return finalPageIndex;
    }
}