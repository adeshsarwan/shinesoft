package com.snapdrama.shortstream.mvvmRepo.repo;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;

import com.snapdrama.shortstream.engineBox.client.EngineClient;
import com.snapdrama.shortstream.engineBox.interfaces.EngineInterface;
import com.snapdrama.shortstream.engineBox.model.detail.ShortDetailModel;

import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

public class SeriesRepository {

    private static SeriesRepository instance;
    private EngineInterface apiService;

    private SeriesRepository() {
        apiService = EngineClient.getClient().create(EngineInterface.class);
    }

    public static SeriesRepository getInstance() {
        if (instance == null) {
            instance = new SeriesRepository();
        }
        return instance;
    }

    // ✅ Repository returns LiveData
    public LiveData<ShortDetailModel> getSeriesDetail(String language, String epId) {

        MutableLiveData<ShortDetailModel> liveData = new MutableLiveData<>();

        apiService.getShortDramaDetail(language, epId)
                .enqueue(new Callback<ShortDetailModel>() {
                    @Override
                    public void onResponse(Call<ShortDetailModel> call,
                                           Response<ShortDetailModel> response) {

                        if (response.isSuccessful() && response.body() != null) {
                            liveData.postValue(response.body());
                        } else {
                            liveData.postValue(null);
                        }
                    }

                    @Override
                    public void onFailure(Call<ShortDetailModel> call, Throwable t) {
                        liveData.postValue(null);
                    }
                });

        return liveData;
    }
}