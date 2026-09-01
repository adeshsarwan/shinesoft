package com.snapdrama.shortstream.model;

import com.snapdrama.shortstream.engineBox.model.rank.RankSeriesModel;

import java.util.List;

public class HomeUiItem {

    public static final int TYPE_BANNER = 1;
    public static final int TYPE_RANKING = 2;

    private int viewType;
    private int startRank;

    private RankSeriesModel.Datum bannerItem;

    private List<RankSeriesModel.Datum> rankingItems;

    public HomeUiItem(int viewType, RankSeriesModel.Datum bannerItem) {
        this.viewType = viewType;
        this.bannerItem = bannerItem;
    }

    public HomeUiItem(int viewType, List<RankSeriesModel.Datum> rankingItems,  int startRank) {
        this.viewType = viewType;
        this.rankingItems = rankingItems;
        this.startRank = startRank;

    }

    public int getViewType() {
        return viewType;
    }

    public RankSeriesModel.Datum getBannerItem() {
        return bannerItem;
    }

    public List<RankSeriesModel.Datum> getRankingItems() {
        return rankingItems;
    }
    public int getStartRank() {
        return startRank;
    }
}