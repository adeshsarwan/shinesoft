package com.snapdrama.shortstream.activity.main.fragment.adapter;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

import com.snapdrama.shortstream.activity.main.fragment.category_fragment.CategoriesFragment;
import com.snapdrama.shortstream.activity.main.fragment.new_fragment.NewCateFragment;
import com.snapdrama.shortstream.activity.main.fragment.popular_fragment.PopularSeriesFragment;
import com.snapdrama.shortstream.activity.main.fragment.rankingFragment.RankingSeriesFragment;

public class CategoryDraftAdapter extends FragmentPagerAdapter {

    public CategoryDraftAdapter(FragmentManager fm) {
        super(fm, BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT);
    }

    @Override
    public Fragment getItem(int position) {
        switch (position) {
            case 0: return new PopularSeriesFragment();
            case 1: return new NewCateFragment();
            case 2: return new RankingSeriesFragment();
            case 3: return new CategoriesFragment();
            default: return new PopularSeriesFragment();
        }
    }

    @Override
    public int getCount() {
        return 4;
    }

}