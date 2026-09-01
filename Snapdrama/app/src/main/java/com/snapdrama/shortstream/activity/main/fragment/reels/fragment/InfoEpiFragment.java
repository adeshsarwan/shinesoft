package com.snapdrama.shortstream.activity.main.fragment.reels.fragment;

import android.os.Bundle;

import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.snapdrama.shortstream.adapter.ShortDramaAdapter;
import com.snapdrama.shortstream.databinding.FragmentInfoEpiBinding;
import com.snapdrama.shortstream.engineBox.model.detail.ShortDetailModel;
import com.snapdrama.shortstream.mvvmRepo.model.PopularSeriesViewModel;

import java.util.ArrayList;
import java.util.List;


public class InfoEpiFragment extends Fragment {
    private PopularSeriesViewModel popularSeriesViewModel;

    private static final String ARG_LIST = "short_list";
    List<ShortDetailModel> shortList;

    public static InfoEpiFragment newInstance( List<ShortDetailModel> list) {
        InfoEpiFragment fragment = new InfoEpiFragment();
        Bundle bundle = new Bundle();
        bundle.putParcelableArrayList(ARG_LIST, new ArrayList<>(list));
        fragment.setArguments(bundle);
        return fragment;
    }
    ShortDramaAdapter adapter;

    FragmentInfoEpiBinding binding;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding =  FragmentInfoEpiBinding.inflate(inflater, container, false);
        shortList = getArguments().getParcelableArrayList(ARG_LIST);
      binding.  textSeriesDescription.setText(shortList.get(0).getDescription());
        setupObserver();

        return binding.getRoot();
    }
    private void setupObserver() {

        popularSeriesViewModel = new ViewModelProvider(this).get(PopularSeriesViewModel.class);

        popularSeriesViewModel.getPopularSeries()
                .observe(getViewLifecycleOwner(), response -> {

                    if (response != null
                            && response.getData() != null
                            && !response.getData().isEmpty()) {

                        LinearLayoutManager layoutManager = new LinearLayoutManager(getContext(), LinearLayoutManager.HORIZONTAL, false);
                        binding.recycleView.setLayoutManager(layoutManager);

                        adapter = new ShortDramaAdapter(
                                getContext(),
                                response.getData(),1
                        );


                        binding.recycleView.setAdapter(adapter);

                    } else {
                    }
                });
    }

}