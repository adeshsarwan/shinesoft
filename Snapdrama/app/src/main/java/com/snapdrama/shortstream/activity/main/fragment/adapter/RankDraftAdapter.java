package com.snapdrama.shortstream.activity.main.fragment.adapter;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentActivity;
import androidx.viewpager2.adapter.FragmentStateAdapter;

import com.snapdrama.shortstream.activity.main.fragment.rankingFragment.MostTredingFragment;
import com.snapdrama.shortstream.activity.main.fragment.rankingFragment.TopSearchedFragment;

public class RankDraftAdapter extends FragmentStateAdapter {

    public RankDraftAdapter(@NonNull FragmentActivity fragmentActivity) {
        super(fragmentActivity);
    }

    @NonNull
    @Override
    public Fragment createFragment(int position) {
        switch (position) {
            case 0:
                return new MostTredingFragment();
            case 1:
                return new TopSearchedFragment();
            default:
                return new MostTredingFragment();
        }
    }

    @Override
    public int getItemCount() {
        return 2; // Number of tabs
    }
}
