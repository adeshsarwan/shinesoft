package com.snapdrama.shortstream.engineBox.model.detail;

import android.os.Parcel;
import android.os.Parcelable;

import java.util.List;
import com.google.gson.annotations.Expose;
import com.google.gson.annotations.SerializedName;

import javax.annotation.processing.Generated;

@Generated("jsonschema2pojo")
public class ShortDetailModel implements Parcelable {
    private boolean isFavourite;

    public boolean isFavourite() {
        return isFavourite;
    }

    public void setFavourite(boolean favourite) {
        isFavourite = favourite;
    }
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

    public ShortDetailModel(Parcel in) {
        id = in.readString();
        language = in.readString();
        title = in.readString();
        episodeNo = in.readString();
        intro = in.readString();
        alias = in.readString();
        description = in.readString();
        tags = in.createStringArrayList();
        categories = in.createStringArrayList();
        cover = in.readString();
        episodeCount = (Integer) in.readValue(Integer.class.getClassLoader());
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        dest.writeString(id);
        dest.writeString(language);
        dest.writeString(title);
        dest.writeString(episodeNo);
        dest.writeString(intro);
        dest.writeString(alias);
        dest.writeString(description);
        dest.writeStringList(tags);
        dest.writeStringList(categories);
        dest.writeString(cover);
        dest.writeValue(episodeCount);
    }
    @Override
    public int describeContents() {
        return 0;
    }

    public static final Creator<ShortDetailModel> CREATOR =
            new Creator<ShortDetailModel>() {
                @Override
                public ShortDetailModel createFromParcel(Parcel in) {
                    return new ShortDetailModel(in);
                }

                @Override
                public ShortDetailModel[] newArray(int size) {
                    return new ShortDetailModel[size];
                }
            };
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
