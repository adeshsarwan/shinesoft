package com.snapdrama.shortstream.engineBox.model.series;

import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

import java.util.List;

import javax.annotation.processing.Generated;

@Generated("jsonschema2pojo")
public class SeriesCategoryDetailModel {

    @SerializedName("page")
    @Expose
    private Integer page;
    @SerializedName("pageSize")
    @Expose
    private Integer pageSize;
    @SerializedName("data")
    @Expose
    private List<Datum> data;
    @SerializedName("total")
    @Expose
    private Integer total;

    public Integer getPage() {
        return page;
    }

    public void setPage(Integer page) {
        this.page = page;
    }

    public Integer getPageSize() {
        return pageSize;
    }

    public void setPageSize(Integer pageSize) {
        this.pageSize = pageSize;
    }

    public List<Datum> getData() {
        return data;
    }

    public void setData(List<Datum> data) {
        this.data = data;
    }

    public Integer getTotal() {
        return total;
    }

    public void setTotal(Integer total) {
        this.total = total;
    }
    @Generated("jsonschema2pojo")
    public class Datum {

        @SerializedName("id")
        @Expose
        private String id;
        @SerializedName("language")
        @Expose
        private String language;
        @SerializedName("title")
        @Expose
        private String title;
        @SerializedName("episodeNo")
        @Expose
        private String episodeNo;
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
        private Integer episodeCount;

        public String getId() {
            return id;
        }

        public void setId(String id) {
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

        public String getEpisodeNo() {
            return episodeNo;
        }

        public void setEpisodeNo(String episodeNo) {
            this.episodeNo = episodeNo;
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

        public Integer getEpisodeCount() {
            return episodeCount;
        }

        public void setEpisodeCount(Integer episodeCount) {
            this.episodeCount = episodeCount;
        }

    }
}