package com.snapdrama.shortstream.engineBox.model.episodeindex;

import java.util.List;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

import javax.annotation.processing.Generated;


@Generated("jsonschema2pojo")
public class EpisodeVideoStream {

	@SerializedName("id")
	@Expose
	private Integer id;
	@SerializedName("language")
	@Expose
	private String language;
	@SerializedName("title")
	@Expose
	private String title;
	@SerializedName("intro")
	@Expose
	private String intro;
	@SerializedName("alias")
	@Expose
	private String alias;
	@SerializedName("description")
	@Expose
	private String description;
	@SerializedName("tags")
	@Expose
	private List<String> tags;
	@SerializedName("categories")
	@Expose
	private List<String> categories;
	@SerializedName("cover")
	@Expose
	private String cover;
	@SerializedName("episode_count")
	@Expose
	private Double episodeCount;
	@SerializedName("episode_part")
	@Expose
	private EpisodePart episodePart;

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

	public String getTitle() {
		return title;
	}

	public void setTitle(String title) {
		this.title = title;
	}

	public String getIntro() {
		return intro;
	}

	public void setIntro(String intro) {
		this.intro = intro;
	}

	public String getAlias() {
		return alias;
	}

	public void setAlias(String alias) {
		this.alias = alias;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public List<String> getTags() {
		return tags;
	}

	public void setTags(List<String> tags) {
		this.tags = tags;
	}

	public List<String> getCategories() {
		return categories;
	}

	public void setCategories(List<String> categories) {
		this.categories = categories;
	}

	public String getCover() {
		return cover;
	}

	public void setCover(String cover) {
		this.cover = cover;
	}

	public Double getEpisodeCount() {
		return episodeCount;
	}

	public void setEpisodeCount(Double episodeCount) {
		this.episodeCount = episodeCount;
	}

	public EpisodePart getEpisodePart() {
		return episodePart;
	}

	public void setEpisodePart(EpisodePart episodePart) {
		this.episodePart = episodePart;
	}
	@Generated("jsonschema2pojo")
	public class EpisodePart {

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
}