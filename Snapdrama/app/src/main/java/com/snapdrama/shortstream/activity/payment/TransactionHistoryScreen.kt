package com.snapdrama.shortstream.activity.payment

import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.firebase.auth.FirebaseAuth
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.databinding.ActivityTransactionHistoryScreenBinding
import com.snapdrama.shortstream.engineBox.client.TransactionClient
import com.snapdrama.shortstream.engineBox.model.transaction.TransactionResponse
import retrofit2.Call

class TransactionHistoryScreen : BaseOtherActivity() {
    lateinit var binding: ActivityTransactionHistoryScreenBinding
    private lateinit var adapter: TransactionHistoryAdapter

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityTransactionHistoryScreenBinding.inflate(layoutInflater)
        setContentView(binding.root)

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                finish()
            }
        })

        binding.btnBack.setOnClickListener {
            finish()
        }
        binding.rvTransactions.layoutManager = LinearLayoutManager(this)
        val user = FirebaseAuth.getInstance().currentUser

        if (user == null) {
            showEmpty()
        } else {
            fetchTransactions(user.uid)
        }
    }

    private fun fetchTransactions(user: String) {
        showLoading()

        TransactionClient.instance.getTransactions(user)
            .enqueue(object : retrofit2.Callback<TransactionResponse> {

                override fun onResponse(
                    call: Call<TransactionResponse>,
                    response: retrofit2.Response<TransactionResponse>
                ) {
                    showData()
                    if (response.isSuccessful) {
                        val data = response.body()
                        val list = data?.transactions

                        if (!list.isNullOrEmpty()) {
                            binding.rvTransactions.visibility = View.VISIBLE
                            adapter = TransactionHistoryAdapter(this@TransactionHistoryScreen, list)
                            binding.rvTransactions.adapter = adapter

                        } else {
                            showEmpty()
                        }
                    } else {
                        showEmpty()

                        Toast.makeText(
                            this@TransactionHistoryScreen,
                            getString(R.string.failed_to_load_data),
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                }

                override fun onFailure(call: Call<TransactionResponse>, t: Throwable) {
                    showEmpty()

                    Toast.makeText(
                        this@TransactionHistoryScreen,
                        "Error: ${t.message}",
                        Toast.LENGTH_SHORT
                    ).show()
                }
            })
    }

    private fun showLoading() {
        binding.progressAnimation.setVisibility(View.VISIBLE)
        binding.rvTransactions.setVisibility(View.GONE)
        binding.emptyLayout.setVisibility(View.GONE)
    }

    private fun showData() {
        binding.progressAnimation.setVisibility(View.GONE)
        binding.rvTransactions.setVisibility(View.VISIBLE)
        binding.emptyLayout.setVisibility(View.GONE)
    }

    private fun showEmpty() {
        binding.progressAnimation.setVisibility(View.GONE)
        binding.rvTransactions.setVisibility(View.GONE)
        binding.emptyLayout.setVisibility(View.VISIBLE)
    }
}