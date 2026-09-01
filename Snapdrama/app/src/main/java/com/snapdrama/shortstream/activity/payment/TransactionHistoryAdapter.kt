package com.snapdrama.shortstream.activity.payment

import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.recyclerview.widget.RecyclerView
import com.snapdrama.shortstream.databinding.ItemTransactionBinding
import com.snapdrama.shortstream.engineBox.model.transaction.TransactionModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TransactionHistoryAdapter(
    private val context: Context,
    private val list: List<TransactionModel?>
) : RecyclerView.Adapter<TransactionHistoryAdapter.ViewHolder>() {

    inner class ViewHolder(val binding: ItemTransactionBinding) : RecyclerView.ViewHolder(binding.root)

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val binding = ItemTransactionBinding.inflate(LayoutInflater.from(context), parent, false)
        return ViewHolder(binding)
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val item = list[position] ?: return

        with(holder.binding) {
            tvPaymentId.text = item.payment_id ?: "N/A"
            
            val currency = item.currency?.uppercase(Locale.getDefault()) ?: "INR"
            val symbol = if (currency == "INR") "₹" else if (currency == "USD") "$" else currency + " "
            tvAmount.text = "$symbol${item.amount}"

            val date = Date(item.created * 1000)
            val sdf = SimpleDateFormat("MMM d, yyyy, h:mm a", Locale.getDefault())
            tvDate.text = sdf.format(date)

            val status = item.status ?: "Unknown"
            tvStatus.text = status.replace("_", " ").replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
            
            when (status.lowercase(Locale.getDefault())) {
                "succeeded", "successful", "success" -> {
                    tvStatus.setTextColor(Color.parseColor("#66BB6A"))
                }
                "failed" -> {
                    tvStatus.setTextColor(Color.parseColor("#EF5350"))
                }
                "requires_payment_method" -> {
                    tvStatus.setTextColor(Color.parseColor("#EF5350"))
                    tvStatus.text = "Failed"
                    tvCustomer.text = "Customer: ${item.customer ?: "N/A"}"
                }
                else -> {
                    tvStatus.setTextColor(Color.parseColor("#9E9E9E"))
                }
            }

            if (status.lowercase(Locale.getDefault()) != "requires_payment_method") {
                tvCustomer.visibility = View.GONE
            }

            root.setOnClickListener {
                val intent = Intent(context, TransactionDetailScreen::class.java).apply {
                    putExtra("payment_id", item.payment_id)
                    putExtra("amount", item.amount)
                    putExtra("currency", item.currency)
                    putExtra("status", item.status)
                    putExtra("customer", item.customer)
                    putExtra("description", item.description)
                    putExtra("receipt_email", item.receipt_email)
                    putExtra("created", item.created)
                    putExtra("payment_method", item.payment_method)
                }
                context.startActivity(intent)
            }
        }
    }

    override fun getItemCount(): Int = list.size
}
