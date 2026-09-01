package com.snapdrama.shortstream.activity.main.fragment.reels.fragment;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.fragment.app.FragmentManager;
import androidx.fragment.app.FragmentStatePagerAdapter;

import com.snapdrama.shortstream.activity.main.fragment.reels.interfaces.OnEpisodeClickListener;

import java.util.List;

public class EpisodePagerAdapter extends FragmentStatePagerAdapter {

    List<EpisodeRange> ranges;
    private final OnEpisodeClickListener listener;
    private final String seriesId;

    public EpisodePagerAdapter(@NonNull FragmentManager fm,
                               List<EpisodeRange> ranges,
                               String seriesId,
                               OnEpisodeClickListener listener) {
        super(fm, BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT);
        this.ranges = ranges;
        this.seriesId = seriesId;
        this.listener = listener;

    }

    @NonNull
    @Override
    public Fragment getItem(int position) {
        EpisodeRange range = ranges.get(position);
        return EpisodeGridFragment.newInstance(range.start, range.end, seriesId, listener);
    }

    @Override
    public int getCount() {
        return ranges.size();
    }
}
