package com.snapdrama.shortstream.adapter;

import static android.content.Context.MODE_PRIVATE;

import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.full_reels.ReelsShowActivity;
import com.snapdrama.shortstream.engineBox.model.rank.RankSeriesModel;
import com.snapdrama.shortstream.model.HomeUiItem;
import com.snapdrama.shortstream.utils.SeriesViewCountHelper;

import java.util.List;
import java.util.Random;

public class RankingHomeAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private Context context;
    private List<HomeUiItem> list;

    public RankingHomeAdapter(Context context, List<HomeUiItem> list) {
        this.context = context;
        this.list = list;
    }

    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(ViewGroup parent, int viewType) {

        if (viewType == HomeUiItem.TYPE_BANNER) {
            View v = LayoutInflater.from(context)
                    .inflate(R.layout.layout_home_ranking_list, parent, false);
            return new BannerVH(v);
        } else {
            View v = LayoutInflater.from(context)
                    .inflate(R.layout.layout_dyanamic_home_ranking_list, parent, false);
            return new RankingVH(v);
        }
    }

    @Override
    public void onBindViewHolder(RecyclerView.ViewHolder holder, int position) {

        HomeUiItem item = list.get(position);

        if (holder instanceof BannerVH) {

            RankSeriesModel.Datum model = item.getBannerItem();
            if (model == null) return;

            Glide.with(holder.itemView.getContext())
                    .load(model.getCover())
                    .placeholder(R.drawable.image_poster_placeholder)
                    .error(R.drawable.image_poster_placeholder)
                    .into(((BannerVH) holder).imgCover);

            ((BannerVH) holder).txtTitle.setText(model.getTitle());
            ((BannerVH) holder).textTagCategory.setText(model.getCategories().get(0));

            holder.itemView.setOnClickListener(v -> {
                Intent intent = new Intent(context, ReelsShowActivity.class);
                intent.putExtra("SERIES_ID_Episode",0);
                intent.putExtra("SERIES_ID_EXTRA", model.getId());
                context.startActivity(intent);
            });
            // For banner item, use position 0 (top ranking)
            SeriesViewCountHelper.setPermanentRankingMillion(
                    holder.itemView.getContext(),
                    ((BannerVH) holder).textViewTotalView,
                    model.getId(),
                    0, // Top position for banner
                    list.size()
            );
            setPermanentRandomBadge(
                    holder.itemView.getContext(),
                    ((BannerVH) holder) .textCategory,
                    position
            );
        } else {

            List<RankSeriesModel.Datum> rankingList =
                    item.getRankingItems();

            RankingVH vh = (RankingVH) holder;

            vh.recyclerView.setLayoutManager(
                    new LinearLayoutManager(context));
            int startRank = item.getStartRank();


            vh.recyclerView.setAdapter(
                    new RankingChildAdapter(context, rankingList, startRank));
        }
    }
    private String generateRandomBadge() {

        String[] badges = {"Free", "Dubbed", "Hot","NONE"};

        int index = new Random().nextInt(badges.length);
        return badges[index];
    }
    public void setPermanentRandomBadge(
            Context context,
            TextView badgeTextView,
            int position
    ) {

        SharedPreferences prefs =
                context.getSharedPreferences("permanent_prefs21", MODE_PRIVATE);

        String key = "badge_value_" + position;

        String savedBadge = prefs.getString(key, null);

        if (savedBadge == null) {
            String randomBadge = generateRandomBadge();

            prefs.edit()
                    .putString(key, randomBadge)
                    .apply();

            applyBadgeUI(badgeTextView, randomBadge);

        } else {
            applyBadgeUI(badgeTextView, savedBadge);
        }
    }
    private void applyBadgeUI(TextView badgeTextView, String badge) {

        if ("NONE".equals(badge)) {
            badgeTextView.setVisibility(View.GONE);
            return;
        }

        badgeTextView.setVisibility(View.VISIBLE);
        badgeTextView.setText(badge);

        switch (badge) {
            case "Free":
                badgeTextView.setBackgroundResource(R.drawable.background_back_category2);
                break;

            case "Dubbed":
                badgeTextView.setBackgroundResource(R.drawable.background_back_category3);
                break;

            case "Hot":
                badgeTextView.setBackgroundResource(R.drawable.background_back_category4);
                break;
        }
    }
    @Override
    public int getItemViewType(int position) {
        return list.get(position).getViewType();
    }
    @Override
    public int getItemCount() {
        return list.size();
    }




    static class BannerVH extends RecyclerView.ViewHolder {
        ImageView imgCover;
        TextView txtTitle;
        TextView textCategory;
        TextView textViewTotalView;
        TextView textTagCategory;
        BannerVH(View itemView) {
            super(itemView);
            imgCover = itemView.findViewById(R.id.imageSeries);
            txtTitle = itemView.findViewById(R.id.textSeriesName);
            textViewTotalView = itemView.findViewById(R.id.textViewTotalView);
            textCategory = itemView.findViewById(R.id.textCategory);
            textTagCategory = itemView.findViewById(R.id.textTagCategory);
        }
    }

    static class RankingVH extends RecyclerView.ViewHolder {
        RecyclerView recyclerView;

        RankingVH(View itemView) {
            super(itemView);
            recyclerView = itemView.findViewById(R.id.rankingRecycler);
        }
    }
}