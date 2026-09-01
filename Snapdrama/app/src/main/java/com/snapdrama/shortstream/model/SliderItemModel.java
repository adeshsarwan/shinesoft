package com.snapdrama.shortstream.model;

public class SliderItemModel {

    String image;
    String title;
    String description;
    String ids;

    public String getIds() {
        return ids;
    }

    public void setIds(String ids) {
        this.ids = ids;
    }

    public SliderItemModel(String image) {
        this.image = image;
    }

    public SliderItemModel(String image, String title, String description, String ids) {
        this.image = image;
        this.title = title;
        this.description = description;
        this.ids = ids;
    }

    public String getImage() {
        return image;
    }

    public void setImage(String image) {
        this.image = image;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }
}
