package com.snapdrama.shortstream.mvvmRepo.model;

import androidx.lifecycle.LiveData;
import androidx.lifecycle.MutableLiveData;
import androidx.lifecycle.ViewModel;

import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.engineBox.model.rank.RankSeriesModel;
import com.snapdrama.shortstream.mvvmRepo.repo.RankingSeriesRepository;


public class RankingSeriesViewModel extends ViewModel {

    private final RankingSeriesRepository repository;
    private MutableLiveData<RankSeriesModel> popularSeriesLiveData;

    public RankingSeriesViewModel() {
        repository = new RankingSeriesRepository();
    }

    private String currentLang = "";

    public LiveData<RankSeriesModel> getRankingSeries() {
        String lang = ControlPreference.getLanguage();
        if (popularSeriesLiveData == null || !currentLang.equals(lang)) {
            currentLang = lang;
            popularSeriesLiveData = repository.getRankingSeries(lang, 1, 10);
        }
        return popularSeriesLiveData;
    }
}