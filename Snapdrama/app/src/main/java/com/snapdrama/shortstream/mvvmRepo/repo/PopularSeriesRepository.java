package com.snapdrama.shortstream.mvvmRepo.repo;

import androidx.lifecycle.MutableLiveData;

import com.snapdrama.shortstream.engineBox.client.EngineClient;
import com.snapdrama.shortstream.engineBox.interfaces.EngineInterface;
import com.snapdrama.shortstream.engineBox.model.episdata.EpisodeListModel;

import retrofit2.Call;

public class PopularSeriesRepository {

    private final EngineInterface apiService;

    public PopularSeriesRepository() {
        apiService = EngineClient.getClient().create(EngineInterface.class);
    }

    public MutableLiveData<EpisodeListModel> getPopularSeries(
            String language, int page, int pageSize) {

        MutableLiveData<EpisodeListModel> liveData = new MutableLiveData<>();

        apiService.getQueryShortDrama(language, page, pageSize)
                .enqueue(new retrofit2.Callback<EpisodeListModel>() {
                    @Override
                    public void onResponse(Call<EpisodeListModel> call,
                                           retrofit2.Response<EpisodeListModel> response) {

                        if (response.isSuccessful() && response.body() != null) {
                            liveData.setValue(response.body());
                        } else {
                            liveData.setValue(null);
                        }
                    }

                    @Override
                    public void onFailure(Call<EpisodeListModel> call, Throwable t) {
                        liveData.setValue(null);
                    }
                });

        return liveData;
    }
}