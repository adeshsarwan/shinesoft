package com.calculatorlauncher.app.ui

import android.os.Bundle
import android.widget.TextView
import com.calculatorlauncher.app.R

class InfoActivity : BaseToolActivity(R.layout.activity_info) {

    override val screenTitle: String
        get() = intent.getStringExtra(EXTRA_TITLE).orEmpty()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        findViewById<TextView>(R.id.tvInfoContent).text =
            intent.getStringExtra(EXTRA_CONTENT).orEmpty()
    }

    companion object {
        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_CONTENT = "extra_content"
    }
}
