package com.snapdrama.shortstream.activity.main.fragment.new_fragment;

import android.os.Bundle;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.snapdrama.shortstream.adapter.NewDramaAdapter;
import com.snapdrama.shortstream.ads.PremiumPlanManager;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.databinding.FragmentNewBinding;
import com.snapdrama.shortstream.engineBox.client.EngineClient;
import com.snapdrama.shortstream.engineBox.interfaces.EngineInterface;
import com.snapdrama.shortstream.engineBox.model.episdata.EpisodeListModel;

import java.util.ArrayList;
import java.util.List;

import retrofit2.Call;


public class NewCateFragment extends Fragment {

    NewDramaAdapter adapter;

    FragmentNewBinding binding;
    private View rootView;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        if (rootView == null) {
            binding = FragmentNewBinding.inflate(inflater, container, false);
            binding.recycleView.setLayoutManager(
                    new LinearLayoutManager(getContext()));
            binding.recycleView.setHasFixedSize(true);
            getQueryDrama();
            rootView = binding.getRoot();
        } else {
            ViewGroup parent = (ViewGroup) rootView.getParent();
            if (parent != null) {
                parent.removeView(rootView);
            }
        }
        return rootView;
    }
    private void getQueryDrama() {
        binding.progressLayout.mainLayout.setVisibility(View.VISIBLE);
        binding.recycleView.setVisibility(View.GONE);
        EngineInterface apiService = EngineClient.getClient().create(EngineInterface.class);

        String currentLang = ControlPreference.getLanguage();

        apiService.getQueryShortDrama(currentLang, 1, 20).enqueue(new retrofit2.Callback<EpisodeListModel>() {
            @Override
            public void onResponse(
                    Call<EpisodeListModel> call,
                    retrofit2.Response<EpisodeListModel> response) {
                if (response.isSuccessful()
                        && response.body() != null
                        && response.body().getData() != null) {
                    binding.progressLayout.mainLayout.setVisibility(View.GONE);
                    binding.recycleView.setVisibility(View.VISIBLE);

                    List<EpisodeListModel.Datum> dataList = response.body().getData();
                    List<Object> items = new ArrayList<>();
                    int adPosition = ControlPreference.get_Home_New_Ads_Position();

                    if (adPosition > 0
                            && dataList != null
                            && !PremiumPlanManager.shouldSkipAfterLoginAd(getContext())) {
                        for (int i = 0; i < dataList.size(); i++) {
                            items.add(dataList.get(i));
                            if ((i + 1) % adPosition == 0 && i != dataList.size() - 1) {
                                items.add("AD_ITEM");
                            }
                        }
                    } else if (dataList != null) {
                        items.addAll(dataList);
                    }

                    adapter = new NewDramaAdapter(getContext(), items);
                    binding.recycleView.setAdapter(adapter);


                } else {
                }
            }


            @Override
            public void onFailure(Call<EpisodeListModel> call, Throwable t) {
                t.printStackTrace();

            }
        });
    }

}