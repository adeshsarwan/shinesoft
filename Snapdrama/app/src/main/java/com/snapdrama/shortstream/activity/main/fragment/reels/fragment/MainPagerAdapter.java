package com.snapdrama.shortstream.activity.main.fragment.reels.fragment;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.lifecycle.Lifecycle;
import androidx.viewpager2.adapter.FragmentStateAdapter;

import com.snapdrama.shortstream.engineBox.model.detail.ShortDetailModel;
import com.snapdrama.shortstream.activity.main.fragment.reels.interfaces.OnEpisodeClickListener;

import java.util.ArrayList;
import java.util.List;

public class MainPagerAdapter extends FragmentStateAdapter {

    int totalEpisodes;
    String description;
    List<ShortDetailModel> shortList;
    OnEpisodeClickListener listener;

    public MainPagerAdapter(@NonNull FragmentManager fm,
                            @NonNull Lifecycle lifecycle,
                            int totalEpisodes,List<ShortDetailModel> shortList, OnEpisodeClickListener listener) {
        super(fm, lifecycle);
        this.totalEpisodes = totalEpisodes;
        this.description = description;
        this.shortList   = new ArrayList<>(shortList);
        this.listener = listener;

    }

    @NonNull
    @Override
    public Fragment createFragment(int position) {
        if (position == 0) {
            return InfoEpiFragment.newInstance(shortList);

        } else {
            return NumberEpiFragment.newInstance(totalEpisodes, shortList,listener);

        }
    }

    @Override
    public int getItemCount() {
        return 2;
    }
}
