package com.snapdrama.shortstream.activity.main.fragment.reels.fragment;

import android.os.Bundle;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.adapter.EpisodeNumberAdapter;
import com.snapdrama.shortstream.activity.main.fragment.reels.interfaces.OnEpisodeClickListener;
import com.snapdrama.shortstream.ads.RewardAdManager;


public class EpisodeGridFragment extends Fragment {

    private static final String ARG_START = "start";
    private static final String ARG_END = "end";
    private static final String ARG_SERIES_ID = "series_id";

    private OnEpisodeClickListener listener;
    private EpisodeNumberAdapter episodeAdapter;
    private Runnable refreshLockIconsRunnable;

    public static EpisodeGridFragment newInstance(
            int start,
            int end,
            String seriesId,
            OnEpisodeClickListener listener) {

        EpisodeGridFragment fragment = new EpisodeGridFragment();
        fragment.listener = listener;

        Bundle b = new Bundle();
        b.putInt(ARG_START, start);
        b.putInt(ARG_END, end);
        b.putString(ARG_SERIES_ID, seriesId);
        fragment.setArguments(b);

        return fragment;
    }

    @Override
    public View onCreateView(
            LayoutInflater inflater,
            ViewGroup container,
            Bundle savedInstanceState) {

        View view = inflater.inflate(
                R.layout.fragment_episode_grid,
                container,
                false
        );

        RecyclerView recyclerView = view.findViewById(R.id.recycleNumber);
        recyclerView.setLayoutManager(new GridLayoutManager(getContext(), 6));

        int start = getArguments().getInt(ARG_START);
        int end = getArguments().getInt(ARG_END);
        String seriesId = getArguments().getString(ARG_SERIES_ID, "unknown_series");

        episodeAdapter = new EpisodeNumberAdapter(
                requireContext(),
                seriesId,
                start,
                end,
                listener
        );
        recyclerView.setAdapter(episodeAdapter);

        refreshLockIconsRunnable = () -> {
            if (episodeAdapter != null) {
                episodeAdapter.notifyDataSetChanged();
            }
        };
        RewardAdManager.addOnLockUiHiddenRunnable(refreshLockIconsRunnable);

        return view;
    }

    @Override
    public void onDestroyView() {
        if (refreshLockIconsRunnable != null) {
            RewardAdManager.removeOnLockUiHiddenRunnable(refreshLockIconsRunnable);
            refreshLockIconsRunnable = null;
        }
        episodeAdapter = null;
        super.onDestroyView();
    }
}