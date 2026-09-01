package com.calculatorlauncher.app.launcher

import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.calculatorlauncher.app.R

/**
 * ========== LAUNCHER_MODE_START ==========
 * Search Engine settings — tap card to pick Recommended / Yahoo / Bing / Google.
 * ========== LAUNCHER_MODE_END ==========
 */
class SearchEngineActivity : AppCompatActivity() {

    private lateinit var tvValue: TextView

    private val options = listOf(
        SearchEngineStore.RECOMMENDED,
        SearchEngineStore.YAHOO,
        SearchEngineStore.BING,
        SearchEngineStore.GOOGLE
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_search_engine)

        tvValue = findViewById(R.id.tvSearchEngineValue)
        refresh()

        findViewById<View>(R.id.btnSearchEngineBack).setOnClickListener { finish() }
        findViewById<View>(R.id.cardSearchEngine).setOnClickListener { showPicker() }
    }

    private fun refresh() {
        tvValue.text = SearchEngineStore.displayName(this)
    }

    private fun showPicker() {
        val labels = options.map { SearchEngineStore.displayName(this, it) }.toTypedArray()
        val selected = options.indexOf(SearchEngineStore.get(this)).coerceAtLeast(0)
        AlertDialog.Builder(this, R.style.Theme_SearchEngineDialog)
            .setTitle(R.string.settings_search_engine)
            .setSingleChoiceItems(labels, selected) { dialog, which ->
                SearchEngineStore.set(this, options[which])
                refresh()
                dialog.dismiss()
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }
}
