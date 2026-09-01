package com.snapdrama.shortstream.mvvmRepo.model;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.engineBox.model.episdata.EpisodeListModel;
import com.snapdrama.shortstream.mvvmRepo.repo.PopularSeriesRepository;

public class PopularSeriesViewModel extends ViewModel {

    private final PopularSeriesRepository repository;
    private MutableLiveData<EpisodeListModel> popularSeriesLiveData;

    public PopularSeriesViewModel() {
        repository = new PopularSeriesRepository();
    }

    private String currentLang = "";

    public LiveData<EpisodeListModel> getPopularSeries() {
        String lang = ControlPreference.getLanguage();
        if (popularSeriesLiveData == null || !currentLang.equals(lang)) {
            currentLang = lang;
            popularSeriesLiveData = repository.getPopularSeries(lang, 1, 10);
        }
        return popularSeriesLiveData;
    }
}