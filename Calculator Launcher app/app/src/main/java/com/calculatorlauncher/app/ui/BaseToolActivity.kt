package com.calculatorlauncher.app.ui

import android.os.Bundle
import android.widget.ImageButton
import android.widget.TextView
import androidx.annotation.LayoutRes
import androidx.appcompat.app.AppCompatActivity
import com.calculatorlauncher.app.R

abstract class BaseToolActivity(@LayoutRes private val layoutRes: Int) : AppCompatActivity() {

    protected abstract val screenTitle: String

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(layoutRes)
        findViewById<TextView>(R.id.tvToolbarTitle).text = screenTitle
        findViewById<ImageButton>(R.id.btnBack).setOnClickListener { finish() }
    }
}
