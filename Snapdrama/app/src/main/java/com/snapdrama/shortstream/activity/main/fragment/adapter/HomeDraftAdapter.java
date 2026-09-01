package com.snapdrama.shortstream.activity.main.fragment.adapter;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

import com.snapdrama.shortstream.activity.main.fragment.HomeFragment;
import com.snapdrama.shortstream.activity.main.fragment.MyListFragment;
import com.snapdrama.shortstream.activity.main.fragment.ProfileFragment;
import com.snapdrama.shortstream.activity.main.fragment.ReelsFragment;

public class HomeDraftAdapter extends FragmentPagerAdapter {

    private final Fragment[] fragments;

    public HomeDraftAdapter(FragmentManager fm) {
        super(fm, BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT);

        fragments = new Fragment[]{
                new HomeFragment(),
                new ReelsFragment(),
                new MyListFragment(),
                new ProfileFragment()
        };
    }

    @Override
    public Fragment getItem(int position) {
        return fragments[position];
    }

    @Override
    public int getCount() {
        return fragments.length;
    }
}