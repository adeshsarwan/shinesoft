package com.snapdrama.shortstream.activity.main.fragment.reels.fragment;

import android.graphics.Color;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.snapdrama.shortstream.R;

import java.util.List;

public class EpisodeRangeAdapter
        extends RecyclerView.Adapter<EpisodeRangeAdapter.ViewHolder> {

    List<EpisodeRange> list;
    OnRangeClickListener listener;
    int selectedPosition = 0;

    public interface OnRangeClickListener {
        void onRangeClick(int position);
    }

    public void setSelected(int position) {
        selectedPosition = position;
        notifyDataSetChanged();
    }
    public EpisodeRangeAdapter(List<EpisodeRange> list,
                               OnRangeClickListener listener) {
        this.list = list;
        this.listener = listener;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View v = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_episode_range, parent, false);
        return new ViewHolder(v);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        EpisodeRange range = list.get(position);
        holder.text.setText(range.start + " - " + range.end);

        if (position == selectedPosition) {
            holder.text.setBackgroundResource(R.drawable.background_episode_number_select);
            holder.text.setTextColor(Color.WHITE);
        } else {
            holder.text.setBackgroundResource(R.drawable.background_episode_number_unselect);
            holder.text.setTextColor(Color.parseColor("#7B7B7B"));
        }

        holder.itemView.setOnClickListener(v -> {
            if (listener != null) listener.onRangeClick(position);
        });
    }
    @Override
    public int getItemCount() {
        return list.size();
    }

    static class ViewHolder extends RecyclerView.ViewHolder {
        TextView text;
        ViewHolder(View itemView) {
            super(itemView);
            text = itemView.findViewById(R.id.textNumberCategory);
        }
    }
}
