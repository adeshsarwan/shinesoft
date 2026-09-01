package com.snapdrama.shortstream.mvvmRepo.model;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MediatorLiveData;
import androidx.lifecycle.ViewModel;

import com.snapdrama.shortstream.engineBox.model.detail.ShortDetailModel;
import com.snapdrama.shortstream.mvvmRepo.repo.SeriesRepository;

public class SeriesViewModel extends ViewModel {

    private final SeriesRepository repository;
    private final MediatorLiveData<ShortDetailModel> seriesLiveData =
            new MediatorLiveData<>();

    public SeriesViewModel() {
        repository = SeriesRepository.getInstance();
    }

    public LiveData<ShortDetailModel> getSeriesLiveData() {
        return seriesLiveData;
    }

    public void loadSeries(String language, String epId) {

        LiveData<ShortDetailModel> source =
                repository.getSeriesDetail(language, epId);

        seriesLiveData.addSource(source, data -> {
            seriesLiveData.setValue(data);
            seriesLiveData.removeSource(source); // ✅ avoid multiple calls
        });
    }
}
