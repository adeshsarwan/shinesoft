package com.snapdrama.shortstream.activity.premium

import android.os.Bundle
import android.view.View
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.Query
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.databinding.ActivityCosumtionRewardScreenBinding

class ConsumptionRewardScreen : BaseOtherActivity() {
    private lateinit var binding: ActivityCosumtionRewardScreenBinding
    private lateinit var adapter: ConsumptionRecordAdapter
    private val db = FirebaseFirestore.getInstance()
    private val auth = FirebaseAuth.getInstance()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityCosumtionRewardScreenBinding.inflate(layoutInflater)
        setContentView(binding.root)

        initUI()
        loadConsumptionRecords()
    }

    private fun initUI() {
        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                finish()
            }
        })

        binding.btnBack.setOnClickListener {
            finish()
        }
        
        adapter = ConsumptionRecordAdapter(emptyList())
        binding.recyclerView.layoutManager = LinearLayoutManager(this)
        binding.recyclerView.adapter = adapter
    }

    private fun loadConsumptionRecords() {
        val userId = FirebaseAuth.getInstance().getUid()
        if (userId == null) {
            showEmpty()

            return
        }
        showLoading()


        db.collection("users")
            .document(userId)
            .collection("consumption_records")
            .orderBy("episodeSpendCutTime", Query.Direction.DESCENDING)
            .get()
            .addOnSuccessListener { documents ->
                showData()

                val records = documents.toObjects(ConsumptionRecord::class.java)
                
                if (records.isEmpty()) {
                   showEmpty()
                } else {
                   showData()
                    adapter.updateData(records)
                }
            }
            .addOnFailureListener {
                showEmpty()

            }
    }

    private fun showLoading() {
        binding.progressLayout.progressAnimation.setVisibility(View.VISIBLE)
        binding.recyclerView.setVisibility(View.GONE)
        binding.progressLayout.emptyLayout.setVisibility(View.GONE)
    }

    private fun showData() {
        binding.progressLayout.progressAnimation.setVisibility(View.GONE)
        binding.recyclerView.setVisibility(View.VISIBLE)
        binding.progressLayout.emptyLayout.setVisibility(View.GONE)
    }

    private fun showEmpty() {
        binding.progressLayout.progressAnimation.setVisibility(View.GONE)
        binding.recyclerView.setVisibility(View.GONE)
        binding.progressLayout.emptyLayout.setVisibility(View.VISIBLE)
    }
}