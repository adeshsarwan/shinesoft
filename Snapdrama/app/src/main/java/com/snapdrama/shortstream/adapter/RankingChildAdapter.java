package com.snapdrama.shortstream.adapter;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.full_reels.ReelsShowActivity;
import com.snapdrama.shortstream.engineBox.model.rank.RankSeriesModel;
import com.snapdrama.shortstream.utils.SeriesViewCountHelper;

import java.util.ArrayList;
import java.util.List;

public class RankingChildAdapter
        extends RecyclerView.Adapter<RankingChildAdapter.VH> {

    private Context context;
    private List<RankSeriesModel.Datum> list;
    private int startRank;

    public RankingChildAdapter(Context context,
                               List<RankSeriesModel.Datum> list,
                               int startRank) {
        this.context = context;
        this.list = list != null ? list : new ArrayList<>();
        this.startRank = startRank;

    }
    @Override
    public VH onCreateViewHolder(ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(context)
                .inflate(R.layout.layout_dyanamic_ranking_sublist, parent, false);
        return new VH(v);
    }

    @Override
    public void onBindViewHolder(VH holder, int position) {

        RankSeriesModel.Datum model = list.get(position);

//        holder.rank.setText(String.valueOf(position + 1));
        holder.title.setText(model.getTitle());
//        holder.textRankCurrentViews.setText(model.ge());
//        holder.episode.setText(
//                "Episodes: " + model.getEpisodeCount()
//        );
        int actualRank = startRank + position;
        SeriesViewCountHelper.setPermanentRandomMillion(
                holder.itemView.getContext(),
                holder.textRankCurrentViews,
                model.getId(),
                list.size()
        );
        switch (actualRank) {
            case 0:
                holder.imageRankImage.setImageResource(R.drawable.image_ranking1);
                break;
            case 1:
                holder.imageRankImage.setImageResource(R.drawable.image_ranking2);
                break;
            case 2:
                holder.imageRankImage.setImageResource(R.drawable.image_ranking3);
                break;
            case 3:
                holder.imageRankImage.setImageResource(R.drawable.image_ranking4);
                break;
            case 4:
                holder.imageRankImage.setImageResource(R.drawable.image_ranking5);
                break;
            case 5:
                holder.imageRankImage.setImageResource(R.drawable.image_ranking6);
                break;
            default:
                holder.imageRankImage.setVisibility(View.GONE);
                break;
        }
        Glide.with(holder.itemView.getContext())
                .load(model.getCover())
                .placeholder(R.drawable.image_poster_placeholder)
                .error(R.drawable.image_poster_placeholder)
                .into( holder.imageSeries);
        holder.itemView.setOnClickListener(v -> {
            Intent intent = new Intent(context, ReelsShowActivity.class);
            intent.putExtra("SERIES_ID_EXTRA", model.getId());
            intent.putExtra("SERIES_ID_Episode",0);

            context.startActivity(intent);
        });

    }

    @Override
    public int getItemCount() {
        return list == null ? 0 : list.size();
    }

    static class VH extends RecyclerView.ViewHolder {
        TextView  title;
        TextView  textRankCurrentViews;
        ImageView imageSeries;
        ImageView imageRankImage;

        VH(View itemView) {
            super(itemView);
//            rank = itemView.findViewById(R.id.txtRank);
            title = itemView.findViewById(R.id.textView1);
            imageSeries = itemView.findViewById(R.id.imageSeries);
            imageRankImage = itemView.findViewById(R.id.imageRankImage);
            textRankCurrentViews = itemView.findViewById(R.id.textRankCurrentViews);
        }
    }
}