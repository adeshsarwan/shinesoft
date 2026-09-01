package com.snapdrama.shortstream.adapter;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.full_reels.ReelsShowActivity;
import com.snapdrama.shortstream.engineBox.model.series.SeriesCategoryDetailModel;
import com.snapdrama.shortstream.ads.GeneralAdsManager;
import android.app.Activity;

import java.util.List;

public class ShortCategoryDetailAdapter    extends RecyclerView.Adapter<ShortCategoryDetailAdapter.ViewHolder> {

    private Context context;
    private List<SeriesCategoryDetailModel.Datum> list;

    public ShortCategoryDetailAdapter(Context context, List<SeriesCategoryDetailModel.Datum> list) {
        this.context = context;
        this.list = list;
    }

    @NonNull
    @Override
    public ShortCategoryDetailAdapter.ViewHolder onCreateViewHolder(
            @NonNull ViewGroup parent, int viewType) {

        View view = LayoutInflater.from(context)
                .inflate(R.layout.layout_drama_list, parent, false);
        return new ShortCategoryDetailAdapter.ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(
            @NonNull ShortCategoryDetailAdapter.ViewHolder holder, int position) {
        Glide.with(holder.itemView.getContext())
                .load(list.get(position).getCover())
                .placeholder(R.drawable.image_poster_placeholder)
                .error(R.drawable.image_poster_placeholder)
                .into(holder.imgCover);

        holder.txtTitle.setText(list.get(position).getTitle());
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
//                if (context instanceof Activity) {
//                    GeneralAdsManager.showInterstitialAdWithCounter((Activity) context, new Runnable() {
//                        @Override
//                        public void run() {
//                            Intent intent = new Intent(context, ReelsShowActivity.class);
//                            intent.putExtra("SERIES_ID_EXTRA", list.get(position).getId());
//                            intent.putExtra("SERIES_ID_Episode", 0);
//                            context.startActivity(intent);
//                        }
//                    });
//                } else {
                    Intent intent = new Intent(context, ReelsShowActivity.class);
                    intent.putExtra("SERIES_ID_EXTRA", list.get(position).getId());
                    intent.putExtra("SERIES_ID_Episode", 0);
                    context.startActivity(intent);
//                }
            }
        });
    }

    @Override
    public int getItemCount() {
        return list.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {

        ImageView imgCover;
        TextView txtTitle;

        ViewHolder(@NonNull View itemView) {
            super(itemView);
            imgCover = itemView.findViewById(R.id.imageSeries);
            txtTitle = itemView.findViewById(R.id.textSeriesName);
        }
    }
}
