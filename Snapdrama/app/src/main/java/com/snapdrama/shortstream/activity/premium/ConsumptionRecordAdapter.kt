package com.snapdrama.shortstream.activity.premium

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.bumptech.glide.Glide
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.databinding.ItemConsumptionRecordBinding
import java.text.SimpleDateFormat
import java.util.Locale

class ConsumptionRecordAdapter(private var records: List<ConsumptionRecord>) :
    RecyclerView.Adapter<ConsumptionRecordAdapter.ViewHolder>() {

    class ViewHolder(val binding: ItemConsumptionRecordBinding) : RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemConsumptionRecordBinding.inflate(LayoutInflater.from(parent.context), parent, false)
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val record = records[position]
        holder.binding.apply {
            tvTitle.text = record.episodeName
            tvEpisode.text = "Episode ${record.episodeNumber}"
            tvPrice.text = "-${record.spendPrice} Coins"
            
            val date = record.episodeSpendCutTime?.toDate()
            if (date != null) {
                val sdf = SimpleDateFormat("MMM dd, yyyy HH:mm", Locale.getDefault())
                tvDate.text = sdf.format(date)
            } else {
                tvDate.text = ""
            }

            Glide.with(ivPoster.context)
                .load(record.episodePhoto)
                .placeholder(R.drawable.image_poster_placeholder)
                .into(ivPoster)
        }
    }

    override fun getItemCount() = records.size

    fun updateData(newRecords: List<ConsumptionRecord>) {
        records = newRecords
        notifyDataSetChanged()
    }
}