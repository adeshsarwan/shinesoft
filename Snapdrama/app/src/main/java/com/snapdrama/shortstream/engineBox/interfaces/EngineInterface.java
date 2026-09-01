package com.snapdrama.shortstream.engineBox.interfaces;

import com.snapdrama.shortstream.engineBox.model.videodata.AllEpisodeModel;
import com.snapdrama.shortstream.engineBox.model.episdata.EpisodeListModel;
import com.snapdrama.shortstream.engineBox.model.episodeindex.EpisodeVideoStream;
import com.snapdrama.shortstream.engineBox.model.language.LanguageGetModel;
import com.snapdrama.shortstream.engineBox.model.rank.RankSeriesModel;
import com.snapdrama.shortstream.engineBox.model.series.SeriesCategoryDetailModel;
import com.snapdrama.shortstream.engineBox.model.series.SeriesCategoryModel;
import com.snapdrama.shortstream.engineBox.model.detail.ShortDetailModel;
import com.snapdrama.shortstream.engineBox.model.episdata.EpisodeRequest;

import java.util.List;

import retrofit2.Call;
import retrofit2.http.Body;
import retrofit2.http.GET;
import retrofit2.http.POST;
import retrofit2.http.Path;
import retrofit2.http.Query;

public interface EngineInterface {

    @GET("v1/languages")
    Call<LanguageGetModel> getLanguages(
            @Query("page") int page,
            @Query("pageSize") int pageSize
    );

    @GET("/v1/languages/{language}/episodes")
    Call<EpisodeListModel> getQueryShortDrama(
            @Path("language") String language,
            @Query("page") int page,
            @Query("pageSize") int pageSize
    );

    @GET("/v1/languages/{language}/episodes/{episode-id}")
    Call<ShortDetailModel> getShortDramaDetail(@Path("language") String language,@Path("episode-id") String episode_id);



    @GET("/v1/languages/{language}/episodes/{episode-id}/playlist")
    Call<List<AllEpisodeModel>> getShortDramaVideoTvSeries (@Path("language") String language,@Path("episode-id") String episode_id

    );

    @GET("/v1/languages/{language}/episodes/ranking")
    Call<RankSeriesModel> getShortDramaRank (@Path("language") String language, @Query("page") int page,
                                             @Query("pageSize") int pageSize

    );

    @GET("/v1/languages/en/categories")
    Call<SeriesCategoryModel> getQueryCategory(
            @Query("page") int page,
            @Query("pageSize") int pageSize
    );

    @GET("v1/languages/{language}/categories/{category}/episodes")
    Call<SeriesCategoryDetailModel> getQueryCategoryDetail(
            @Path("language") String language,
            @Path("category") String category,
            @Query("page") int page,
            @Query("pageSize") int pageSize
    );
    @POST("/v1/languages/en/episodes")
    Call<List<EpisodeVideoStream>> getVideoStreamEpisode (@Body EpisodeRequest body

    );

}
