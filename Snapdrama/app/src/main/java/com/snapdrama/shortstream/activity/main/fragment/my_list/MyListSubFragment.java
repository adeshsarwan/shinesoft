package com.snapdrama.shortstream.activity.main.fragment.my_list;

import android.os.Bundle;

import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.adapter.ShortDramaAdapter;
import com.snapdrama.shortstream.databinding.FragmentMyListSubBinding;
import com.snapdrama.shortstream.activity.main.fragment.my_list.adapter.MyListSubAdapter;
import com.snapdrama.shortstream.activity.main.fragment.my_list.model.MySubListModel;
import com.snapdrama.shortstream.mvvmRepo.model.PopularSeriesViewModel;

import java.util.ArrayList;
import java.util.List;

public class MyListSubFragment extends Fragment {

    MyListSubAdapter listSubAdapter;
    private PopularSeriesViewModel popularSeriesViewModel;
    ShortDramaAdapter adapter;

     FragmentMyListSubBinding binding;
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding =  FragmentMyListSubBinding.inflate(inflater, container, false);
        
        listSubAdapter = new MyListSubAdapter(requireContext(),0);
        binding.recyclerMyList.setLayoutManager(new LinearLayoutManager(getContext()));
        binding.recyclerMyList.setAdapter(listSubAdapter);
        binding.swipeRefresh.setColorSchemeResources(
                R.color.app_colors,
                R.color.app_colors
        );

        binding.swipeRefresh.setOnRefreshListener(() -> {
            loadMyListData();
        });

        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        if (user!=null){
            binding.swipeRefresh.setRefreshing(true);
            showLoading();
            loadMyListData();
        }
        else {
            showEmpty();
        }

        setupObserver();

        return binding.getRoot();
    }

    @Override
    public void onResume() {
        super.onResume();
        loadMyListData();
    }
    private void setupObserver() {


        popularSeriesViewModel = new ViewModelProvider(getActivity()).get(PopularSeriesViewModel.class);


        popularSeriesViewModel.getPopularSeries()
                .observe(getViewLifecycleOwner(), response -> {

                    if (response != null
                            && response.getData() != null
                            && !response.getData().isEmpty()) {

                        binding.recycleView.setLayoutManager(
                                new GridLayoutManager(getContext(), 3));
                        binding.recycleView.setHasFixedSize(true);
                        adapter = new ShortDramaAdapter(
                                getContext(),
                                response.getData(),0
                        );
                        binding.recycleView.setAdapter(adapter);


                    } else {
                    }
                });
    }
    private void loadMyListData() {

        String userId = FirebaseAuth.getInstance().getUid();
        if (userId == null) {
            binding.swipeRefresh.setRefreshing(false);
            if (listSubAdapter != null) {
                listSubAdapter.setData(new ArrayList<>());
            }
            showEmpty();

            return;
        }

        FirebaseFirestore db = FirebaseFirestore.getInstance();

        db.collection("users")
                .document(userId)
                .collection("my_list_data")

                .limit(20)
                .get()
                .addOnSuccessListener(querySnapshot -> {
                    List<MySubListModel> list = new ArrayList<>();
                    for (DocumentSnapshot doc : querySnapshot.getDocuments()) {
                        MySubListModel model =
                                doc.toObject(MySubListModel.class);
                        if (model != null) {
                            list.add(model);

                        }
                    }
                    if (list.isEmpty()) {
                        showEmpty();
                    } else {
                        showData();
                    }
                    listSubAdapter.setData(list);

                    binding.swipeRefresh.setRefreshing(false);
                })
                .addOnFailureListener(e -> {
                    binding.swipeRefresh.setRefreshing(false);
                    showEmpty();

                });
    }
    private void showLoading() {
//        binding.progressLayout.progressAnimation.setVisibility(View.VISIBLE);
        binding.swipeRefresh.setVisibility(View.GONE);
//        binding.progressLayout.emptyLayout.setVisibility(View.GONE);
    }

    private void showData() {
//        binding.progressLayout.progressAnimation.setVisibility(View.GONE);
        binding.swipeRefresh.setVisibility(View.VISIBLE);
//        binding.progressLayout.emptyLayout.setVisibility(View.GONE);
    }

    private void showEmpty() {
//        binding.progressLayout.progressAnimation.setVisibility(View.GONE);
        binding.swipeRefresh.setVisibility(View.GONE);
        binding.emptyLayout.setVisibility(View.VISIBLE);
    }
}
