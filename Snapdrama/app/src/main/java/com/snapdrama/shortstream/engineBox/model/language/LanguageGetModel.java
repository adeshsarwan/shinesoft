package com.snapdrama.shortstream.engineBox.model.language;

import java.util.List;
import com.google.gson.annotations.SerializedName;

public class LanguageGetModel{

	@SerializedName("total")
	private int total;

	@SerializedName("data")
	private List<DataItem> data;

	@SerializedName("pageSize")
	private int pageSize;

	@SerializedName("page")
	private int page;

	public int getTotal(){
		return total;
	}

	public List<DataItem> getData(){
		return data;
	}

	public int getPageSize(){
		return pageSize;
	}

	public int getPage(){
		return page;
	}

	public class DataItem{

		@SerializedName("language")
		private String language;

		public String getLanguage(){
			return language;
		}
	}
}