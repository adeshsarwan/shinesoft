package com.snapdrama.shortstream.activity.main.fragment.my_list.adapter;

import android.content.Context;
import android.content.Intent;
import android.support.annotation.NonNull;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.target.Target;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.full_reels.ReelsShowActivity;
import com.snapdrama.shortstream.activity.main.fragment.my_list.model.MySubListModel;

import java.util.ArrayList;
import java.util.List;

public class MyListSubAdapter
        extends RecyclerView.Adapter<RecyclerView.ViewHolder> {
    public static final int TYPE_NORMAL = 0;
    public static final int TYPE_BIG = 1;
    private   int i = 0;

    private final Context context;
    private final List<MySubListModel> list = new ArrayList<>();

    public MyListSubAdapter(Context context, int i) {
        this.context = context;
        this.i = i;
    }


    public void setData(List<MySubListModel> data) {
        list.clear();
        list.addAll(data);
        notifyDataSetChanged();
    }


    @Override
    public int getItemViewType(int position) {
        return i;
    }


    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(
            @NonNull ViewGroup parent, int viewType) {

        LayoutInflater inflater = LayoutInflater.from(context);

        if (viewType == TYPE_BIG) {
            View view = inflater.inflate(
                    R.layout.layout_history_data_big, parent, false);
            return new BigVH(view);
        } else {
            View view = inflater.inflate(
                    R.layout.layout_history_data, parent, false);
            return new NormalVH(view);
        }
    }


    @Override
    public void onBindViewHolder(
            @NonNull RecyclerView.ViewHolder holder, int position) {

        MySubListModel item = list.get(position);

        if (holder instanceof NormalVH) {
            bindNormal((NormalVH) holder, item);
        } else if (holder instanceof BigVH) {
            bindBig((BigVH) holder, item);
        }
    }


    private void bindNormal(NormalVH h, MySubListModel item) {

        h.title.setText(item.getSeriesTitle());
//        h.playCur.setText("EP." + item.getEpisodesIndex());
        h.textMYListEpisode.setText("EP." + item.getEpisodesTotalCount());
        h.progressContinue.setVisibility(View.GONE);
        h.linearEpisode.setVisibility(View.GONE);
        h.linearMYListEpisode.setVisibility(View.VISIBLE);


        Glide.with(context)
                .load(item.getSeriesThumbnail())
                .into(h.thumbnail);

        h.itemView.setOnClickListener(v -> openSeries(item));
    }

    private void bindBig(BigVH h, MySubListModel item) {

        h.title.setText(item.getSeriesTitle());
//        h.playCur.setText("EP." + item.getEpisodesIndex());
        h.playTotal.setText("EP." + item.getEpisodesTotalCount());
//
//        h.progressContinue.setMax(item.getEpisodesTotalCount());
//        h.progressContinue.setProgress(item.getEpisodesIndex());

        Glide.with(context)
                .load(item.getSeriesThumbnail())
                .placeholder(R.drawable.image_poster_placeholder)
                .error(R.drawable.image_poster_placeholder)
                .override(
                        Target.SIZE_ORIGINAL,
                        Target.SIZE_ORIGINAL
                )
                .dontTransform()
                .into(h.thumbnail);
//
        h.itemView.setOnClickListener(v -> openSeries(item));


    }




    private void openSeries(MySubListModel item) {
        Intent intent = new Intent(context, ReelsShowActivity.class);
        intent.putExtra("SERIES_ID_EXTRA", item.getSeriesId());
        intent.putExtra("SERIES_ID_Episode",0);

        context.startActivity(intent);
    }


    @Override
    public int getItemCount() {
        return list.size();
    }


    abstract static class BaseVH extends RecyclerView.ViewHolder {

        ImageView thumbnail;
        TextView title, playCur, playTotal,textEpisodesNumber,textMYListEpisode;
        ProgressBar progressContinue;
        LinearLayout linearEpisode;
        LinearLayout linearMYListEpisode;

        BaseVH(@NonNull View itemView) {
            super(itemView);
            thumbnail = itemView.findViewById(R.id.imageSeries);
            title = itemView.findViewById(R.id.textSeriesTitle);
            playCur = itemView.findViewById(R.id.play_cur);
            playTotal = itemView.findViewById(R.id.play_total);
            progressContinue = itemView.findViewById(R.id.progressContinue);
            textEpisodesNumber = itemView.findViewById(R.id.textEpisodesNumber);
            linearEpisode = itemView.findViewById(R.id.linearEpisode);
            linearMYListEpisode = itemView.findViewById(R.id.linearMYListEpisode);
            textMYListEpisode = itemView.findViewById(R.id.textMYListEpisode);
        }
    }

    static class NormalVH extends BaseVH {
        NormalVH(@NonNull View itemView) {
            super(itemView);
        }
    }

    static class BigVH extends BaseVH {
        BigVH(@NonNull View itemView) {
            super(itemView);
        }
    }

}

