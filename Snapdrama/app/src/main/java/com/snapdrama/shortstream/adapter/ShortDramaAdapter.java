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

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;

import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.full_reels.ReelsShowActivity;
import com.snapdrama.shortstream.activity.full_reels.adapter.FullReelsAdapter;
import com.snapdrama.shortstream.engineBox.model.episdata.EpisodeListModel;
import com.snapdrama.shortstream.utils.SeriesViewCountHelper;
import com.snapdrama.shortstream.ads.GeneralAdsManager;
import android.app.Activity;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;

public class ShortDramaAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    private Context context;
    private List<EpisodeListModel.Datum> list;
    private int layoutType; // 0 = Grid layout, 1 = Other layout

    private static final int VIEW_TYPE_GRID = 0;
    private static final int VIEW_TYPE_OTHER = 1;
    private List<EpisodeListModel.Datum> filteredList;

    public ShortDramaAdapter(Context context, List<EpisodeListModel.Datum> list, int layoutType) {
        this.context = context;
        this.list = list;
        this.layoutType = layoutType;
        this.filteredList = new ArrayList<>(list);

    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        LayoutInflater inflater = LayoutInflater.from(context);

        if (viewType == VIEW_TYPE_GRID) {
            View view = inflater.inflate(R.layout.item_episode, parent, false);
            return new GridViewHolder(view);
        } else {
            View view = inflater.inflate(R.layout.item_episode2, parent, false);
            return new OtherViewHolder(view);
        }
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int position) {
        EpisodeListModel.Datum item;
        if (layoutType == 0 && filteredList != null && !filteredList.isEmpty() && position < filteredList.size()) {
            item = filteredList.get(position);
        } else if (position < list.size()) {
            item = list.get(position);
        } else {
            return;
        }

        if (holder.getItemViewType() == VIEW_TYPE_GRID) {
            GridViewHolder gridHolder = (GridViewHolder) holder;
            bindGridViewHolder(gridHolder, item, position);
        } else {
            OtherViewHolder otherHolder = (OtherViewHolder) holder;
            bindOtherViewHolder(otherHolder, item, position);
        }
    }

    private void bindGridViewHolder(GridViewHolder holder, EpisodeListModel.Datum item, int position) {
        Glide.with(holder.itemView.getContext())
                .load(item.getCover())
                .placeholder(R.drawable.image_poster_placeholder)
                .error(R.drawable.image_poster_placeholder)
                .into(holder.imgCover);

        holder.txtTitle.setText(item.getTitle());

        if (item.getCategories() != null && !item.getCategories().isEmpty()) {
            holder.textCategory.setText(item.getCategories().get(0));
            holder.textCategory.setVisibility(View.VISIBLE);
        } else {
            holder.textCategory.setVisibility(View.GONE);
        }

//        holder.itemView.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View view) {
//
//                if (context instanceof ReelsShowAllActivity) {
//                    ((ReelsShowAllActivity) context).changeSeries(item.getId(), 0);
//                } else {
//                    stopExistingReelsActivity();
//
//                    Intent intent = new Intent(context, ReelsShowAllActivity.class);
//                    intent.putExtra("SERIES_ID_EXTRA", item.getId());
//                    intent.putExtra("SERIES_ID_Episode", 0);
//
//                    intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
//                    context.startActivity(intent);
//                }
//            }
//        });
        holder.itemView.setOnClickListener(v -> {
//            if (context instanceof Activity) {
//                GeneralAdsManager.showInterstitialAdWithCounter((Activity) context, new Runnable() {
//                    @Override
//                    public void run() {
//                        navigateToReels(item);
//                    }
//                });
//            } else {
                navigateToReels(item);
//            }
        });

        SeriesViewCountHelper.setPermanentRandomMillion(
                holder.itemView.getContext(),
                holder.textViewTotalView,
                item.getId(),
                list.size()
        );
        setPermanentRandomBadge(
                holder.itemView.getContext(),
                holder.textCategory,
                position
        );
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
    private void bindOtherViewHolder(OtherViewHolder holder, EpisodeListModel.Datum item, int position) {
        Glide.with(holder.itemView.getContext())
                .load(item.getCover())
                .placeholder(R.drawable.image_poster_placeholder)
                .error(R.drawable.image_poster_placeholder)
                .into(holder.imgCover);

        holder.txtTitle.setText(item.getTitle());

        if (item.getCategories() != null && !item.getCategories().isEmpty()) {
            holder.textCategory.setText(item.getCategories().get(0));
            holder.textCategory.setVisibility(View.VISIBLE);
        } else {
            holder.textCategory.setVisibility(View.GONE);
        }

//        holder.itemView.setOnClickListener(new View.OnClickListener() {
//            @Override
//            public void onClick(View view) {
//                if (context instanceof ReelsShowAllActivity) {
//
//                    ((ReelsShowAllActivity) context).changeSeries(item.getId(), 0);
//                } else {
//                    stopExistingReelsActivity();
//
//                    Intent intent = new Intent(context, ReelsShowAllActivity.class);
//                    intent.putExtra("SERIES_ID_EXTRA", item.getId());
//                    intent.putExtra("SERIES_ID_Episode", 0);
//
//                    intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
//                    context.startActivity(intent);
//                }
//
//            }
//        });
        holder.itemView.setOnClickListener(v -> {
//            if (context instanceof Activity) {
//                GeneralAdsManager.showInterstitialAdWithCounter((Activity) context, new Runnable() {
//                    @Override
//                    public void run() {
//                        navigateToReels(item);
//                    }
//                });
//            } else {
                navigateToReels(item);
//            }
        });
    }

    private void navigateToReels(EpisodeListModel.Datum item) {
        if (context instanceof ReelsShowActivity) {
            ReelsShowActivity activity = (ReelsShowActivity) context;
            if (!activity.isFinishing() && !activity.isDestroyed()) {
                activity.changeSeries(item.getId(), 0);
            }
        } else {
            stopExistingReelsActivity();
            Intent intent = new Intent(context, ReelsShowActivity.class);
            intent.putExtra("SERIES_ID_EXTRA", item.getId());
            intent.putExtra("SERIES_ID_Episode", 0);
            intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        }
    }
    
    private void stopExistingReelsActivity() {
        FullReelsAdapter existingAdapter = FullReelsAdapter.Companion.getInstance();
        if (existingAdapter != null) {
            existingAdapter.pauseAllPlayers();
            existingAdapter.releaseAllPlayers();
        }
        
        Intent stopIntent = new Intent("com.shortreel.dramatv.STOP_PIP_MODE");
        context.sendBroadcast(stopIntent);
    }

    @Override
    public int getItemViewType(int position) {
        return layoutType == 0 ? VIEW_TYPE_GRID : VIEW_TYPE_OTHER;
    }
    public void filter(String query) {
        if (filteredList == null) {
            filteredList = new ArrayList<>();
        }
        filteredList.clear();

        if (query == null || query.trim().isEmpty()) {
            filteredList.addAll(list);
        } else {
            String searchQuery = query.toLowerCase().trim();
            for (EpisodeListModel.Datum item : list) {
                if (item.getTitle() != null && 
                    item.getTitle().toLowerCase().contains(searchQuery)) {
                    filteredList.add(item);
                }
            }
        }
        notifyDataSetChanged();
    }
    @Override
    public int getItemCount() {
        return layoutType == 0 ? filteredList.size() : list.size();
    }

    public void updateList(List<EpisodeListModel.Datum> newList) {
        list.clear();
        list.addAll(newList);
        notifyDataSetChanged();
    }

    // ViewHolder for Grid Layout (original)
    static class GridViewHolder extends RecyclerView.ViewHolder {
        ImageView imgCover;
        TextView txtTitle;
        TextView textCategory;
        TextView textViewTotalView;

        GridViewHolder(@NonNull View itemView) {
            super(itemView);
            imgCover = itemView.findViewById(R.id.imageSeries);
            txtTitle = itemView.findViewById(R.id.textSeriesName);
            textCategory = itemView.findViewById(R.id.textCategory);
            textViewTotalView = itemView.findViewById(R.id.textViewTotalView);
        }
    }

    // ViewHolder for Other Layout
    static class OtherViewHolder extends RecyclerView.ViewHolder {
        ImageView imgCover;
        TextView txtTitle;
        TextView textCategory;

        // Add other views from R.layout.item_episode_other

        OtherViewHolder(@NonNull View itemView) {
            super(itemView);
            imgCover = itemView.findViewById(R.id.imageSeries);
            txtTitle = itemView.findViewById(R.id.textSeriesName);
            textCategory = itemView.findViewById(R.id.textCategory);
        }
    }
}