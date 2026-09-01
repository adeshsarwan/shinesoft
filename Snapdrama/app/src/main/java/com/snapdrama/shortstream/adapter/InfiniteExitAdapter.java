package com.snapdrama.shortstream.adapter;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.bumptech.glide.request.transition.DrawableCrossFadeFactory;
import com.facebook.shimmer.ShimmerFrameLayout;
import com.makeramen.roundedimageview.RoundedImageView;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.full_reels.ReelsShowActivity;
import com.snapdrama.shortstream.activity.full_reels.adapter.FullReelsAdapter;
import com.snapdrama.shortstream.model.SliderItemModel;

import java.util.List;

public class InfiniteExitAdapter extends RecyclerView.Adapter<InfiniteExitAdapter.SliderViewHolder> {

    private final List<SliderItemModel> sliderItemModels;
    private int currentPosition = 0;
    private int currentCenterPosition = -1;
    private static final int MULTIPLIER = 2000;
    private boolean isLoading = true;
    private boolean showShimmer = true;


    private final DrawableCrossFadeFactory factory =
            new DrawableCrossFadeFactory.Builder().setCrossFadeEnabled(true).build();

    public InfiniteExitAdapter(List<SliderItemModel> sliderItemModels) {
        this.sliderItemModels = sliderItemModels;
    }

    public int getRealItemCount() {
        return sliderItemModels.size();
    }

    public int getRealPosition(int position) {
        if (sliderItemModels.isEmpty()) return 0;
        return position % sliderItemModels.size();
    }

    public void setCurrentPosition(int position) {
        if (currentPosition != position && position >= 0 && position < getRealItemCount()) {
            int old = currentPosition;
            currentPosition = position;

            if (old != position) {

                int updateCount = Math.min(100, MULTIPLIER);
                for (int i = 0; i < updateCount; i++) {
                    int oldPos = old + (i * getRealItemCount());
                    int newPos = position + (i * getRealItemCount());
                    if (oldPos < getItemCount()) {
                        notifyItemChanged(oldPos, "button_visibility");
                    }
                    if (newPos < getItemCount()) {
                        notifyItemChanged(newPos, "button_visibility");
                    }
                }
            }
        }
    }

    public void setCurrentCenterPosition(int centerPosition) {
        if (currentCenterPosition != centerPosition) {
            int oldCenter = currentCenterPosition;
            currentCenterPosition = centerPosition;

            if (oldCenter >= 0 && oldCenter < getItemCount()) {
                notifyItemChanged(oldCenter, "button_visibility");
            }
            if (centerPosition >= 0 && centerPosition < getItemCount()) {
                notifyItemChanged(centerPosition, "button_visibility");
            }
        }
    }

    @NonNull
    @Override
    public SliderViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.layout_slider_view, parent, false);

        view.setLayerType(View.LAYER_TYPE_HARDWARE, null);

        return new SliderViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull SliderViewHolder holder, int position) {
        onBindViewHolder(holder, position, java.util.Collections.emptyList());
    }
    public void showShimmer(boolean show) {
        showShimmer = show;
        notifyDataSetChanged();
    }

    @Override
    public void onBindViewHolder(@NonNull SliderViewHolder holder, int position, @NonNull List<Object> payloads) {
        if (showShimmer) {
            holder.shimmerLayout.setVisibility(View.VISIBLE);
            holder.mainLayout.setVisibility(View.GONE);
            holder.shimmerLayout.startShimmer();
            return;
        }

        holder.shimmerLayout.stopShimmer();
        holder.shimmerLayout.setVisibility(View.GONE);
        holder.mainLayout.setVisibility(View.VISIBLE);

        int realPosition = getRealPosition(position);

        if (!payloads.isEmpty() && payloads.contains("button_visibility")) {
            updateButtonVisibility(holder, position);
            return;
        }

        SliderItemModel item = sliderItemModels.get(realPosition);
        Glide.with(holder.imageView.getContext())
                .load(item.getImage())

                .into(holder.imageView);

        if (holder.textTitle != null) {
            if (item.getTitle() != null && !item.getTitle().isEmpty()) {
                holder.textTitle.setText(item.getTitle());
                holder.textTitle.setVisibility(View.VISIBLE);
            } else {
                holder.textTitle.setVisibility(View.GONE);
            }
        }

        if (holder.textDescription != null) {
            if (item.getDescription() != null && !item.getDescription().isEmpty()) {
                holder.textDescription.setText(item.getDescription());
                holder.textDescription.setVisibility(View.VISIBLE);
            } else {
                holder.textDescription.setVisibility(View.GONE);
            }
        }

        updateButtonVisibility(holder, position);
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {

                stopExistingReelsActivity(holder.itemView.getContext());

                Intent intent = new Intent(holder.itemView.getContext(), ReelsShowActivity.class);
                intent.putExtra("SERIES_ID_EXTRA", item.getIds());
                intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP | Intent.FLAG_ACTIVITY_NEW_TASK);
                holder.itemView.getContext().startActivity(intent);

                if (mListener != null) {
                    mListener.onItemClick(realPosition);
                }
            }
        });

        holder.textTitle.setVisibility(View.GONE);
        holder.textDescription.setVisibility(View.GONE);
        holder.buttonWatchNow.setVisibility(View.GONE);

    }
    private void stopExistingReelsActivity(Context context) {
        FullReelsAdapter existingAdapter = FullReelsAdapter.Companion.getInstance();
        if (existingAdapter != null) {
            existingAdapter.pauseAllPlayers();
            existingAdapter.releaseAllPlayers();
        }

        Intent stopIntent = new Intent("com.shortreel.dramatv.STOP_PIP_MODE");
        context.sendBroadcast(stopIntent);
    }
    public void stopLoading() {
        isLoading = false;
        notifyDataSetChanged();
    }

    private void updateButtonVisibility(@NonNull SliderViewHolder holder, int position) {
        boolean isCenter = (currentCenterPosition >= 0 && position == currentCenterPosition);

        if (isCenter) {
            holder.buttonWatchNow.setVisibility(View.VISIBLE);
            if (holder.buttonWatchNow.getAlpha() < 1f) {
                holder.buttonWatchNow.setAlpha(0f);
                holder.buttonWatchNow.animate()
                        .alpha(1f)
                        .setDuration(300)
                        .start();
            }
        } else {
            holder.buttonWatchNow.setVisibility(View.INVISIBLE);
            holder.buttonWatchNow.setAlpha(0f);
        }
    }

    @Override
    public int getItemCount() {
        if (showShimmer) {
            return 5;
        }
        return sliderItemModels.isEmpty() ? 0 : sliderItemModels.size() * MULTIPLIER;
    }

    @Override
    public void onViewRecycled(@NonNull SliderViewHolder holder) {
        Glide.with(holder.imageView.getContext()).clear(holder.imageView);
        super.onViewRecycled(holder);
    }

    static class SliderViewHolder extends RecyclerView.ViewHolder {
        RoundedImageView imageView;
        TextView buttonWatchNow;
        TextView textTitle;
        TextView textDescription;
        ShimmerFrameLayout shimmerLayout;
        RelativeLayout mainLayout;

        SliderViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.imageSlider);
            buttonWatchNow = itemView.findViewById(R.id.buttonWatchNow);
            textTitle = itemView.findViewById(R.id.textTitle);
            textDescription = itemView.findViewById(R.id.textDescription);
            shimmerLayout = itemView.findViewById(R.id.shimmerLayout);
            mainLayout = itemView.findViewById(R.id.mainLayout);

            imageView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        }
    }

    private OnItemClickListener mListener;

    public interface OnItemClickListener {
        void onItemClick(int position);
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        this.mListener = listener;
    }
}
