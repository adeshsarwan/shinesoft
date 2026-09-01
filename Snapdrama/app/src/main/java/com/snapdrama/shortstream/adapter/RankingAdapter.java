package com.snapdrama.shortstream.adapter;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.facebook.shimmer.ShimmerFrameLayout;
import com.snapdrama.shortstream.activity.full_reels.ReelsShowActivity;
import com.snapdrama.shortstream.utils.GradientTextView;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.engineBox.model.rank.RankSeriesModel;
import com.snapdrama.shortstream.utils.SeriesViewCountHelper;

import android.widget.LinearLayout;
import com.snapdrama.shortstream.ads.adsMenu.Home.HomeNewDataNativeAds;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;

import java.util.List;

public class RankingAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private static final int VIEW_TYPE_DATA = 0;
    private static final int VIEW_TYPE_AD = 1;

    private Context context;
    private List<Object> list;

    public RankingAdapter(Context context, List<Object> list) {
        this.context = context;
        this.list = list;
    }

    @Override
    public int getItemViewType(int position) {
        if (list.get(position) instanceof String && "AD_ITEM".equals(list.get(position))) {
            return VIEW_TYPE_AD;
        }
        return VIEW_TYPE_DATA;
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(
            @NonNull ViewGroup parent, int viewType) {

        if (viewType == VIEW_TYPE_AD) {
            View view = LayoutInflater.from(context)
                    .inflate(R.layout.item_native_ad_container, parent, false);
            return new AdViewHolder(view);
        } else {
            View view = LayoutInflater.from(context)
                    .inflate(R.layout.layout_ranking_list, parent, false);
            return new DataViewHolder(view);
        }
    }

    @Override
    public void onBindViewHolder(
            @NonNull RecyclerView.ViewHolder holder, int position) {
        if (getItemViewType(position) == VIEW_TYPE_DATA) {
            DataViewHolder dataHolder = (DataViewHolder) holder;
            RankSeriesModel.Datum datum = (RankSeriesModel.Datum) list.get(position);

            Glide.with(dataHolder.itemView.getContext())
                    .load(datum.getCover())
                    .placeholder(R.drawable.image_poster_placeholder)
                    .error(R.drawable.image_poster_placeholder)
                    .into(dataHolder.imgCover);
            //        Glide.with(context).load(Uri.parse("http://static.rovedata.xyz/stub/TFBZENAY100035/original/cover.jpg")).load(holder.imgCover);
            dataHolder.txtTitle.setText(datum.getTitle());
            dataHolder.textDesc.setText(datum.getCategories().get(0)+", "+datum.getCategories().get(1));
            dataHolder.itemView.setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View view) {
                    Intent intent = new Intent(context, ReelsShowActivity.class);
                    intent.putExtra("SERIES_ID_EXTRA",datum.getId());
                    intent.putExtra("SERIES_ID_Episode",0);

                    context.startActivity(intent);
                }
            });

            // Calculate true rank (excluding ads)
            int rank = 0;
            for (int i = 0; i <= position; i++) {
                if (list.get(i) instanceof RankSeriesModel.Datum) {
                    rank++;
                }
            }
            dataHolder.gradiantTextView.setText(String.valueOf(rank));

            LinearLayoutManager layoutManager =
                    new LinearLayoutManager(context, LinearLayoutManager.HORIZONTAL, false);
            dataHolder.recycleViewCategory.setLayoutManager(layoutManager);

            CategoryNameAdapter2 categoryAdapter = new CategoryNameAdapter2(context, datum.getCategories());
            dataHolder.recycleViewCategory.setAdapter(categoryAdapter);
            SeriesViewCountHelper.setPermanentRankingMillion(
                    dataHolder.itemView.getContext(),
                    dataHolder.textViewTotalView,
                    datum.getId(),
                    position,
                    list.size()
            );
        } else {
            AdViewHolder adHolder = (AdViewHolder) holder;
            HomeNewDataNativeAds.loadAdmobBigNativeAd(context, ControlPreference.get_NativeList_Ids_List(), adHolder.adContainer,  adHolder.linearSmallBanner,
                    adHolder.shimmerAdsLayout,0);
        }
    }
    @Override
    public int getItemCount() {
        return list.size();
    }

    static class DataViewHolder extends RecyclerView.ViewHolder {

        ImageView imgCover;
        TextView txtTitle;
        TextView textViewTotalView;
        GradientTextView gradiantTextView;
        TextView textDesc;
        RecyclerView recycleViewCategory;

        DataViewHolder(@NonNull View itemView) {
            super(itemView);
            imgCover = itemView.findViewById(R.id.imageSeries);
            txtTitle = itemView.findViewById(R.id.textView1);
            textViewTotalView = itemView.findViewById(R.id.textViewTotalView);
            gradiantTextView = itemView.findViewById(R.id.gradiantTextView);
            textDesc = itemView.findViewById(R.id.textView2);
            recycleViewCategory = itemView.findViewById(R.id.recycleViewCategory);
        }
    }

    static class AdViewHolder extends RecyclerView.ViewHolder {
        LinearLayout adContainer;
        ShimmerFrameLayout shimmerAdsLayout;
        LinearLayout linearSmallBanner;
        AdViewHolder(@NonNull View itemView) {
            super(itemView);
            adContainer = itemView.findViewById(R.id.adContainer);
            shimmerAdsLayout = itemView.findViewById(R.id.shimmerAdsLayout);
            linearSmallBanner = itemView.findViewById(R.id.linearSmallBanner);
        }
    }
}