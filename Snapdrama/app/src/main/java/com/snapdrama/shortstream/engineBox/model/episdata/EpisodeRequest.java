package com.snapdrama.shortstream.engineBox.model.episdata;

import java.util.List;

public class EpisodeRequest {

    private List<String> episodeIds;

    public EpisodeRequest(List<String> episodeIds) {
        this.episodeIds = episodeIds;
    }

    public List<String> getEpisodeIds() {
        return episodeIds;
    }

    public void setEpisodeIds(List<String> episodeIds) {
        this.episodeIds = episodeIds;
    }
}
