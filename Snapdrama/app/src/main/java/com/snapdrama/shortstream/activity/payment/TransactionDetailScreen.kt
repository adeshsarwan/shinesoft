package com.snapdrama.shortstream.activity.payment

import android.content.ClipData
import android.content.ClipboardManager
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.databinding.ActivityTransactionDetailScreenBinding
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class TransactionDetailScreen : BaseOtherActivity() {

    private lateinit var binding: ActivityTransactionDetailScreenBinding

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTransactionDetailScreenBinding.inflate(layoutInflater)
        setContentView(binding.root)
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                finish()
            }
        })
        binding.btnBack.setOnClickListener {
            finish()
        }

        val paymentId = intent.getStringExtra("payment_id") ?: "N/A"
        val amount = intent.getDoubleExtra("amount", 0.0)
        val currencyRaw = intent.getStringExtra("currency") ?: "inr"
        val status = intent.getStringExtra("status") ?: "N/A"
        val customer = intent.getStringExtra("customer") ?: "N/A"
        val description = intent.getStringExtra("description") ?: "N/A"
        val receiptEmail = intent.getStringExtra("receipt_email") ?: "Not provided"
        val created = intent.getLongExtra("created", 0L)
        val paymentMethod = intent.getStringExtra("payment_method") ?: "Not selected"

        val currency = currencyRaw.uppercase(Locale.getDefault())
        val symbol = if (currency == "INR") "₹" else if (currency == "USD") "$" else "$currency "
        
        binding.tvAmtVal.text = "$symbol$amount"
        binding.tvPaymentIdVal.text = paymentId
        binding.tvCurrencyVal.text = currency
        binding.tvCustomerVal.text = customer
        binding.tvDescVal.text = description
        binding.tvReceiptVal.text = receiptEmail
        binding.tvPaymentMethodVal.text = paymentMethod

        val date = Date(created * 1000)
        val sdf = SimpleDateFormat("MMM d, yyyy, h:mm a", Locale.getDefault())
        binding.tvCreatedVal.text = sdf.format(date)
        binding.tvPaymentIdVal.setOnClickListener {

            val text = binding.tvPaymentIdVal.text.toString()

            val clipboard = getSystemService(CLIPBOARD_SERVICE) as ClipboardManager
            val clip = ClipData.newPlainText("Payment ID", text)

            clipboard.setPrimaryClip(clip)

            Toast.makeText(this, getString(R.string.payment_id_copied), Toast.LENGTH_SHORT).show()
        }

        if (status.lowercase(Locale.getDefault()) == "requires_payment_method") {
            binding.llStatusBanner.visibility = View.VISIBLE
            binding.tvStatusVal.setTextColor(Color.parseColor("#EF5350"))
            binding.tvStatusVal.text = "Failed"

        } else if (status.lowercase(Locale.getDefault()) in listOf("succeeded", "successful", "success")) {
            binding.llStatusBanner.visibility = View.GONE
            binding.tvStatusVal.setTextColor(Color.parseColor("#66BB6A"))
            binding.tvStatusVal.text = status.replace("_", " ").replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }

        } else {
            binding.llStatusBanner.visibility = View.GONE
            binding.tvStatusVal.setTextColor(Color.parseColor("#EF5350"))
            binding.tvStatusVal.text = status.replace("_", " ").replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }

        }

        if (customer == "N/A" || customer.isEmpty()) {
            binding.llCustomer.visibility = View.GONE
            binding.vCustomer.visibility = View.GONE
        }
        if (description == "N/A" || description.isEmpty() || description == "null") {
            binding.llDesc.visibility = View.GONE
            binding.vDesc.visibility = View.GONE
            binding.tvDescVal.text = "-"
        }
    }
}
