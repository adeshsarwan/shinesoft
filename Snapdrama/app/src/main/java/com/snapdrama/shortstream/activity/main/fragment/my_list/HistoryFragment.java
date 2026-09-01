package com.snapdrama.shortstream.activity.main.fragment.my_list;

import android.os.Bundle;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.ads.PremiumPlanManager;
import com.snapdrama.shortstream.databinding.FragmentHistoryBinding;
import com.snapdrama.shortstream.activity.main.fragment.my_list.adapter.ContinueWatchingAdapter;
import com.snapdrama.shortstream.activity.main.fragment.my_list.model.ContinueWatchingModel;

import java.util.ArrayList;
import java.util.List;


public class HistoryFragment extends Fragment {

    ContinueWatchingAdapter continueWatchingAdapter;
    FragmentHistoryBinding binding;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {

        binding = FragmentHistoryBinding.inflate(inflater, container, false);
        
        continueWatchingAdapter = new ContinueWatchingAdapter(requireContext(),0);
        binding.recyclerMyList.setLayoutManager(new LinearLayoutManager(getContext()));
        binding.recyclerMyList.setAdapter(continueWatchingAdapter);
        binding.swipeRefresh.setColorSchemeResources(
                R.color.app_colors,
                R.color.app_colors
        );

        binding.swipeRefresh.setOnRefreshListener(() -> {
            loadContinueWatching();
        });
        
        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        if (user == null) {
            showEmpty();

        }
        else {
            binding.progressLayout.progressAnimation.setVisibility(View.GONE);
            binding.progressLayout.emptyLayout.setVisibility(View.VISIBLE);
            binding.swipeRefresh.setRefreshing(true);
            showLoading();
            loadContinueWatching();
        }

        return binding.getRoot();
    }
    
    @Override
    public void onResume() {
        super.onResume();
        loadContinueWatching();
    }

    private void loadContinueWatching() {

        String userId = FirebaseAuth.getInstance().getUid();
        if (userId == null) {
            binding.swipeRefresh.setRefreshing(false);
            if (continueWatchingAdapter != null) {
                continueWatchingAdapter.setData(new ArrayList<>());
            }
            showEmpty();

            return;
        }

        FirebaseFirestore db = FirebaseFirestore.getInstance();

        db.collection("users")
                .document(userId)
                .collection("continueWatching")
                .whereEqualTo("status", "IN_PROGRESS")
                .orderBy("lastWatchedAt", Query.Direction.DESCENDING)
                .limit(20)
                .get()
                .addOnSuccessListener(querySnapshot -> {

                    List<ContinueWatchingModel> list = new ArrayList<>();

                    for (DocumentSnapshot doc : querySnapshot.getDocuments()) {
                        ContinueWatchingModel model =
                                doc.toObject(ContinueWatchingModel.class);
                        if (model != null) {
                            list.add(model);
                        }
                    }
                    if (list.isEmpty()) {
                        showEmpty();
                    } else {
                        showData();
                    }

                    List<Object> items = new ArrayList<>();
                    int adPosition = com.snapdrama.shortstream.applicationPreference.ControlPreference.get_Home_New_Ads_Position();

                    if (adPosition > 0
                            && !list.isEmpty()
                            && !PremiumPlanManager.shouldSkipAfterLoginAd(requireContext())) {
                        for (int i = 0; i < list.size(); i++) {
                            items.add(list.get(i));
                            if ((i + 1) % adPosition == 0 && i != list.size() - 1) {
                                items.add("AD_ITEM");
                            }
                        }
                    } else {
                        items.addAll(list);
                    }

                    continueWatchingAdapter.setData(items);

                    binding.swipeRefresh.setRefreshing(false);
                })
                .addOnFailureListener(e -> {
                    binding.swipeRefresh.setRefreshing(false);
                    showEmpty();

                });
    }

    private void showLoading() {
        binding.progressLayout.progressAnimation.setVisibility(View.VISIBLE);
        binding.swipeRefresh.setVisibility(View.GONE);
        binding.progressLayout.emptyLayout.setVisibility(View.GONE);
    }

    private void showData() {
        binding.progressLayout.progressAnimation.setVisibility(View.GONE);
        binding.swipeRefresh.setVisibility(View.VISIBLE);
        binding.progressLayout.emptyLayout.setVisibility(View.GONE);
    }

    private void showEmpty() {
        binding.progressLayout.progressAnimation.setVisibility(View.GONE);
        binding.swipeRefresh.setVisibility(View.GONE);
        binding.progressLayout.emptyLayout.setVisibility(View.VISIBLE);
    }
}
