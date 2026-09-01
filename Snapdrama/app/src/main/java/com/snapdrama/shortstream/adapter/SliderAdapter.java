package com.snapdrama.shortstream.adapter;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;
import com.bumptech.glide.Glide;
import com.bumptech.glide.load.resource.drawable.DrawableTransitionOptions;
import com.bumptech.glide.request.transition.DrawableCrossFadeFactory;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.model.SliderItemModel;
import com.makeramen.roundedimageview.RoundedImageView;
import java.util.List;

public class SliderAdapter extends RecyclerView.Adapter<SliderAdapter.SliderViewHolder> {

    private final List<SliderItemModel> sliderItemModels;
    private int currentPosition = 0;

    // Crossfade factory for smooth image transitions
    private final DrawableCrossFadeFactory factory =
            new DrawableCrossFadeFactory.Builder().setCrossFadeEnabled(true).build();

    public SliderAdapter(List<SliderItemModel> sliderItemModels) {
        this.sliderItemModels = sliderItemModels;
    }

    public void setCurrentPosition(int position) {
        if (currentPosition != position) {
            int old = currentPosition;
            currentPosition = position;

            // Only update the affected items for better performance
            if (old >= 0 && old < getItemCount()) {
                notifyItemChanged(old);
            }
            if (position >= 0 && position < getItemCount()) {
                notifyItemChanged(position);
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
        // Load image with smooth transition
        Glide.with(holder.imageView.getContext())
                .load(sliderItemModels.get(position).getImage())
                .placeholder(R.drawable.image_poster_placeholder)
                .error(R.drawable.image_poster_placeholder)
                .transition(DrawableTransitionOptions.withCrossFade(factory))
                .thumbnail(0.25f) // Load thumbnail first for smoother experience
                .centerCrop()
                .into(holder.imageView);

        // Smooth visibility transition for button
        if (position == currentPosition) {
            holder.buttonWatchNow.setVisibility(View.VISIBLE);
            holder.buttonWatchNow.setAlpha(0f);
            holder.buttonWatchNow.animate()
                    .alpha(1f)
                    .setDuration(300)
                    .start();
        } else {
            holder.buttonWatchNow.setVisibility(View.INVISIBLE);
            holder.buttonWatchNow.setAlpha(0f);
        }

        // Optional: Add click listener
        holder.itemView.setOnClickListener(v -> {
            if (mListener != null) {
                mListener.onItemClick(position);
            }
        });
    }

    @Override
    public int getItemCount() {
        return sliderItemModels.size();
    }

    @Override
    public void onViewRecycled(@NonNull SliderViewHolder holder) {
        // Clear Glide requests when view is recycled
        Glide.with(holder.imageView.getContext()).clear(holder.imageView);
        super.onViewRecycled(holder);
    }

    static class SliderViewHolder extends RecyclerView.ViewHolder {
        RoundedImageView imageView;
        TextView buttonWatchNow;

        SliderViewHolder(@NonNull View itemView) {
            super(itemView);
            imageView = itemView.findViewById(R.id.imageSlider);
            buttonWatchNow = itemView.findViewById(R.id.buttonWatchNow);

            // Optimize for animations
            imageView.setLayerType(View.LAYER_TYPE_HARDWARE, null);
        }
    }

    // Optional: Item click listener
    private OnItemClickListener mListener;

    public interface OnItemClickListener {
        void onItemClick(int position);
    }

    public void setOnItemClickListener(OnItemClickListener listener) {
        this.mListener = listener;
    }
}