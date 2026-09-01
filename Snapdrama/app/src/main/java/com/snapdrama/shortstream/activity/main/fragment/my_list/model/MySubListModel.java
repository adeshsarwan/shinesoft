package com.snapdrama.shortstream.activity.main.fragment.my_list.model;

public class MySubListModel {

    private boolean added;
    private com.google.firebase.Timestamp addedAt;

    private String episodeId;
    private int episodesTotalCount;

    private String seriesId;
    private String seriesTitle;
    private String seriesThumbnail;

    public MySubListModel() {
    }

    public boolean isAdded() {
        return added;
    }

    public com.google.firebase.Timestamp getAddedAt() {
        return addedAt;
    }

    public String getEpisodeId() {
        return episodeId;
    }

    public int getEpisodesTotalCount() {
        return episodesTotalCount;
    }

    public String getSeriesId() {
        return seriesId;
    }

    public String getSeriesTitle() {
        return seriesTitle;
    }

    public String getSeriesThumbnail() {
        return seriesThumbnail;
    }

    // 🔹 Optional Setters (use if you write data)
    public void setAdded(boolean added) {
        this.added = added;
    }

    public void setAddedAt(com.google.firebase.Timestamp addedAt) {
        this.addedAt = addedAt;
    }

    public void setEpisodeId(String episodeId) {
        this.episodeId = episodeId;
    }

    public void setEpisodesTotalCount(int episodesTotalCount) {
        this.episodesTotalCount = episodesTotalCount;
    }

    public void setSeriesId(String seriesId) {
        this.seriesId = seriesId;
    }

    public void setSeriesTitle(String seriesTitle) {
        this.seriesTitle = seriesTitle;
    }

    public void setSeriesThumbnail(String seriesThumbnail) {
        this.seriesThumbnail = seriesThumbnail;
    }
}
