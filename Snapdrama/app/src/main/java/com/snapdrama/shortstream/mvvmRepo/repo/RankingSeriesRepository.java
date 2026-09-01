package com.snapdrama.shortstream.mvvmRepo.repo;

import android.util.Log;

import androidx.lifecycle.MutableLiveData;

import com.snapdrama.shortstream.engineBox.client.EngineClient;
import com.snapdrama.shortstream.engineBox.interfaces.EngineInterface;
import com.snapdrama.shortstream.engineBox.model.rank.RankSeriesModel;

import retrofit2.Call;



public class RankingSeriesRepository {

    private final EngineInterface apiService;

    public RankingSeriesRepository() {
        apiService = EngineClient.getClient().create(EngineInterface.class);
    }

    public MutableLiveData<RankSeriesModel> getRankingSeries(
            String language, int page, int pageSize) {

        MutableLiveData<RankSeriesModel> liveData = new MutableLiveData<>();

        apiService.getShortDramaRank(language, page, pageSize)
                .enqueue(new retrofit2.Callback<RankSeriesModel>() {
                    @Override
                    public void onResponse(Call<RankSeriesModel> call,
                                           retrofit2.Response<RankSeriesModel> response) {

                        if (response.isSuccessful() && response.body() != null) {
                            liveData.setValue(response.body());
                        } else {
                            liveData.setValue(null);
                        }
                    }

                    @Override
                    public void onFailure(Call<RankSeriesModel> call, Throwable t) {
                        liveData.setValue(null);
                    }
                });

        return liveData;
    }
}