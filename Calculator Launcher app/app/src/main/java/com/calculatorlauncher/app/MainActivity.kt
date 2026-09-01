package com.calculatorlauncher.app

import android.content.Intent
import android.os.Bundle
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import com.calculatorlauncher.app.util.CalcHistoryStore

class MainActivity : AppCompatActivity() {

    private lateinit var screenController: CalculatorScreenController

    private val historyLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val value = result.data?.getStringExtra(CalcHistoryStore.EXTRA_USE_RESULT) ?: return@registerForActivityResult
        screenController.onHistoryResult(value)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        screenController = CalculatorScreenController(this, findViewById(R.id.drawerLayout), historyLauncher)
        screenController.bind()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (screenController.handleBack()) return
        @Suppress("DEPRECATION")
        super.onBackPressed()
    }
}
