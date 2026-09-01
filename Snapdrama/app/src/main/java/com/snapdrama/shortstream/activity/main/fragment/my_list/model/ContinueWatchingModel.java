package com.snapdrama.shortstream.activity.main.fragment.my_list.model;

public class ContinueWatchingModel {

    private String seriesId;
    private long lastPositionMs;
    private int completionPct;
    private String status;
    private String seriesTitle;
    private String seriesThumbnail;
    private String episodeTitle;
    private String episodeThumbnail;
    private int episodesTotalCount;
    private int episodesIndex;
    private boolean my_list;

    public boolean isMy_list() {
        return my_list;
    }

    public void setMy_list(boolean my_list) {
        this.my_list = my_list;
    }

    public int getEpisodesIndex() {
        return episodesIndex;
    }

    public int getEpisodesTotalCount() {
        return episodesTotalCount;
    }

    private com.google.firebase.Timestamp lastWatchedAt;

    public ContinueWatchingModel() {
        // Firestore needs empty constructor
    }

    // 🔹 Getters
    public String getSeriesId() { return seriesId; }
    public long getLastPositionMs() { return lastPositionMs; }
    public int getCompletionPct() { return completionPct; }
    public String getStatus() { return status; }
    public String getSeriesTitle() { return seriesTitle; }
    public String getSeriesThumbnail() { return seriesThumbnail; }
    public String getEpisodeTitle() { return episodeTitle; }
    public String getEpisodeThumbnail() { return episodeThumbnail; }
    public com.google.firebase.Timestamp getLastWatchedAt() { return lastWatchedAt; }
}