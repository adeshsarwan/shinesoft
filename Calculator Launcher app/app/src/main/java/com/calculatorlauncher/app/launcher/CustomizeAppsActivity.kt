package com.calculatorlauncher.app.launcher

import android.content.Intent
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.ImageView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.calculatorlauncher.app.R

/**
 * ========== LAUNCHER_MODE_START ==========
 * Pick apps for home screen. Includes Calculator Settings tile → settings.
 * ========== LAUNCHER_MODE_END ==========
 */
class CustomizeAppsActivity : AppCompatActivity() {

    private lateinit var adapter: CustomizeAppAdapter
    private val selected = linkedSetOf<String>()
    private var allItems = listOf<CustomizeItem>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_customize_apps)

        selected.addAll(HomeAppsStore.getSelectedPackages(this))

        val settingsItem = CustomizeItem(
            id = "settings",
            label = getString(R.string.customize_calc_settings),
            icon = ContextCompat.getDrawable(this, R.drawable.ic_settings_tile)!!,
            isSettings = true
        )
        val apps = AppLoader.loadLauncherApps(packageManager)
            .filter { it.packageName != packageName }
            .map {
                CustomizeItem(
                    id = it.packageName,
                    label = it.label,
                    icon = it.icon,
                    isSettings = false
                )
            }
        allItems = listOf(settingsItem) + apps

        adapter = CustomizeAppAdapter(
            selected = selected,
            onToggle = { item ->
                if (item.isSettings) {
                    startActivity(Intent(this, LauncherSettingsActivity::class.java))
                } else {
                    if (!selected.add(item.id)) selected.remove(item.id)
                    adapter.notifyDataSetChanged()
                }
            }
        )
        val recycler = findViewById<RecyclerView>(R.id.customizeRecycler)
        recycler.layoutManager = GridLayoutManager(this, 3)
        recycler.adapter = adapter
        adapter.submitList(allItems)

        findViewById<View>(R.id.btnCloseCustomize).setOnClickListener { finish() }
        findViewById<View>(R.id.btnSelectAll).setOnClickListener {
            selected.clear()
            selected.addAll(allItems.filter { !it.isSettings }.map { it.id })
            adapter.notifyDataSetChanged()
        }
        findViewById<View>(R.id.btnAddToHome).setOnClickListener {
            HomeAppsStore.setSelectedPackages(this, selected)
            finish()
        }

        findViewById<EditText>(R.id.etSearchApps).addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) = Unit
            override fun afterTextChanged(s: Editable?) {
                val q = s?.toString()?.trim().orEmpty().lowercase()
                val filtered = if (q.isEmpty()) allItems else allItems.filter {
                    it.isSettings || it.label.lowercase().contains(q)
                }
                adapter.submitList(filtered)
            }
        })
    }
}

data class CustomizeItem(
    val id: String,
    val label: String,
    val icon: android.graphics.drawable.Drawable,
    val isSettings: Boolean
)

class CustomizeAppAdapter(
    private val selected: Set<String>,
    private val onToggle: (CustomizeItem) -> Unit
) : RecyclerView.Adapter<CustomizeAppAdapter.Holder>() {

    private val items = mutableListOf<CustomizeItem>()

    fun submitList(data: List<CustomizeItem>) {
        items.clear()
        items.addAll(data)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_customize_app, parent, false)
        return Holder(view)
    }

    override fun onBindViewHolder(holder: Holder, position: Int) {
        holder.bind(items[position], selected, onToggle)
    }

    override fun getItemCount(): Int = items.size

    class Holder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val icon = itemView.findViewById<ImageView>(R.id.appIcon)
        private val label = itemView.findViewById<TextView>(R.id.appLabel)
        private val overlay = itemView.findViewById<View>(R.id.selectedOverlay)

        fun bind(item: CustomizeItem, selected: Set<String>, onToggle: (CustomizeItem) -> Unit) {
            icon.setImageDrawable(item.icon)
            label.text = item.label
            overlay.visibility = if (!item.isSettings && selected.contains(item.id)) View.VISIBLE else View.GONE
            itemView.setOnClickListener { onToggle(item) }
        }
    }
}
