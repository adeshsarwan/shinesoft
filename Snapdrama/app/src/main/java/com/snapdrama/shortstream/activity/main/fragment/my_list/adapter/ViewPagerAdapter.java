package com.snapdrama.shortstream.activity.main.fragment.my_list.adapter;

import android.support.annotation.NonNull;

import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentPagerAdapter;

import com.snapdrama.shortstream.activity.main.fragment.my_list.HistoryFragment;
import com.snapdrama.shortstream.activity.main.fragment.my_list.MyListSubFragment;

public class ViewPagerAdapter extends FragmentPagerAdapter {

    public ViewPagerAdapter(@NonNull FragmentManager fm) {
        super(fm, BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT);
    }

    @NonNull
    @Override
    public Fragment getItem(int position) {
        switch (position) {
            case 0:
                return new MyListSubFragment();
            case 1:
                return new HistoryFragment();
            default:
                return new MyListSubFragment();
        }
    }

    @Override
    public int getCount() {
        return 2;
    }
}