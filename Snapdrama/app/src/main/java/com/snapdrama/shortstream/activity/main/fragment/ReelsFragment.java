

package com.snapdrama.shortstream.activity.main.fragment;

import android.content.Intent;
import android.os.Bundle;

import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.PagerSnapHelper;
import androidx.recyclerview.widget.RecyclerView;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.WindowManager;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.snapdrama.shortstream.databinding.FragmentReelsBinding;
import com.snapdrama.shortstream.engineBox.model.episdata.EpisodeListModel;
import com.snapdrama.shortstream.activity.main.fragment.reels.adapter.ReelsAdapter;
import com.snapdrama.shortstream.mvvmRepo.model.PopularSeriesViewModel;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;


public class ReelsFragment extends Fragment {
    private PopularSeriesViewModel popularSeriesViewModel;

    ReelsAdapter adapter;
    FragmentReelsBinding binding;
    private ActivityResultLauncher<Intent> infoLauncher;
    ReelsFragment reelsFragment;
    List<EpisodeListModel.Datum> reels = new ArrayList<>();

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding = FragmentReelsBinding.inflate(inflater, container, false);
        if (getActivity() != null) {
            getActivity().getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        }

        PagerSnapHelper snapHelper = new PagerSnapHelper();
        snapHelper.attachToRecyclerView(binding.reelsRecyclerView);
        reelsFragment = this;
        infoLauncher = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), new ActivityResultCallback() {
            @Override
            public final void onActivityResult(Object obj) {

            }
        });

        binding.reelsRecyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrollStateChanged(RecyclerView recyclerView, int i) {
                super.onScrollStateChanged(recyclerView, i);
                if (i == 1 || i == 2) {
                    if (adapter != null) {
                        adapter.pauseAllPlayers();
                    }
                }
            }

            @Override
            public void onScrolled(RecyclerView recyclerView, int i, int i2) {
                super.onScrolled(recyclerView, i, i2);
                RecyclerView.LayoutManager layoutManager = recyclerView.getLayoutManager();
                int findFirstCompletelyVisibleItemPosition = ((LinearLayoutManager) layoutManager).findFirstCompletelyVisibleItemPosition();
                if (findFirstCompletelyVisibleItemPosition != -1) {
                    if (adapter != null) {
                        adapter.updatePlayback(findFirstCompletelyVisibleItemPosition);
                    }
                }
            }
        });
        binding.reelsRecyclerView.addOnScrollListener(new RecyclerView.OnScrollListener() {
            @Override
            public void onScrolled(RecyclerView recyclerView, int i, int i2) {
                super.onScrolled(recyclerView, i, i2);
                RecyclerView.LayoutManager layoutManager = recyclerView.getLayoutManager();
                ((LinearLayoutManager) layoutManager).findFirstVisibleItemPosition();
            }
        });
        return binding.getRoot();
    }

    private void getReelsList() {
        binding.progressLayout.mainLayout.setVisibility(View.VISIBLE);
        binding.reelsRecyclerView.setVisibility(View.GONE);
        popularSeriesViewModel = new ViewModelProvider(this).get(PopularSeriesViewModel.class);

        popularSeriesViewModel.getPopularSeries()
                .observe(getViewLifecycleOwner(), response -> {

                    if (response != null
                            && response.getData() != null
                            && !response.getData().isEmpty()) {

                        reels = response.getData();
                        Collections.shuffle(reels);

                        binding.reelsRecyclerView.setVisibility(View.VISIBLE);
                        binding.progressLayout.mainLayout.setVisibility(View.GONE);

                        binding.reelsRecyclerView.setLayoutManager(new LinearLayoutManager(getContext()));

                        adapter = new ReelsAdapter(
                                requireContext(),
                                reelsFragment,
                                reels,
                                true,
                                false,



                                infoLauncher,
0

                        );

                        binding.reelsRecyclerView.setAdapter(adapter);
                        binding.progressLayout.emptyLayout
                                .setVisibility(View.GONE);
                        fetchMyListEpisodes();

                    } else {
                        binding.reelsRecyclerView.setVisibility(View.GONE);

                        View emptyLayout =
                                binding.progressLayout.emptyLayout;

                        emptyLayout.setVisibility(View.VISIBLE);
                    }
                });
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
    public void onDestroyView() {
        super.onDestroyView();
        if (adapter != null) {
            adapter.releaseAllPlayers();
            adapter = null;
        }
        binding = null;
    }

    @Override
    public void onDetach() {
        super.onDetach();
        if (adapter != null) {
            adapter.pauseAllPlayers();
        }
    }

    @Override
    public void onPause() {
        super.onPause();
        if (adapter != null) {
            adapter.pauseAllPlayers();
        }
    }

    @Override
    public void onResume() {
        super.onResume();
        if (this.reels.isEmpty()) {
            getReelsList();
        } else {
            getReelsList();
            getSeriesReelsAdapter().resumeCurrentPlayer();
        }

    }

    private ReelsAdapter getSeriesReelsAdapter() {
        return adapter;
    }


    @Override
    public void onStop() {
        super.onStop();
        if (adapter != null) {
            adapter.pauseAllPlayers();
        }
    }


}