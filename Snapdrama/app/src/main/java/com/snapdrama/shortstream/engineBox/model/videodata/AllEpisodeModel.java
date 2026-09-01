package com.snapdrama.shortstream.engineBox.model.videodata;

import com.google.gson.annotations.SerializedName;

import com.google.gson.annotations.Expose;

import javax.annotation.processing.Generated;

@Generated("jsonschema2pojo")
public class AllEpisodeModel {

	@SerializedName("id")
	@Expose
	private Integer id;
	@SerializedName("language")
	@Expose
	private String language;
	@SerializedName("thumbnail")
	@Expose
	private String thumbnail;
	@SerializedName("duration")
	@Expose
	private Double duration;
	@SerializedName("episode_id")
	@Expose
	private Integer episodeId;
	@SerializedName("part_index")
	@Expose
	private Double partIndex;
	@SerializedName("stream_hls")
	@Expose
	private String streamHls;

	public Integer getId() {
		return id;
	}

	public void setId(Integer id) {
		this.id = id;
	}

	public String getLanguage() {
		return language;
	}

	public void setLanguage(String language) {
		this.language = language;
	}

	public String getThumbnail() {
		return thumbnail;
	}

	public void setThumbnail(String thumbnail) {
		this.thumbnail = thumbnail;
	}

	public Double getDuration() {
		return duration;
	}

	public void setDuration(Double duration) {
		this.duration = duration;
	}

	public Integer getEpisodeId() {
		return episodeId;
	}

	public void setEpisodeId(Integer episodeId) {
		this.episodeId = episodeId;
	}

	public Double getPartIndex() {
		return partIndex;
	}

	public void setPartIndex(Double partIndex) {
		this.partIndex = partIndex;
	}

	public String getStreamHls() {
		return streamHls;
	}

	public void setStreamHls(String streamHls) {
		this.streamHls = streamHls;
	}

}