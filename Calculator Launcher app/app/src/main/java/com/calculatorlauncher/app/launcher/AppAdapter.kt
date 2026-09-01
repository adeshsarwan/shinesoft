package com.calculatorlauncher.app.launcher

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.TextView
import androidx.recyclerview.widget.RecyclerView
import com.calculatorlauncher.app.R

/**
 * ========== LAUNCHER_MODE_START ==========
 * Grid adapter for installed apps on the launcher apps page.
 * ========== LAUNCHER_MODE_END ==========
 */
class AppAdapter(
    private val onAppClick: (LauncherApp) -> Unit
) : RecyclerView.Adapter<AppAdapter.AppViewHolder>() {

    private val items = mutableListOf<LauncherApp>()

    fun submitList(apps: List<LauncherApp>) {
        items.clear()
        items.addAll(apps)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): AppViewHolder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_app_icon, parent, false)
        return AppViewHolder(view)
    }

    override fun onBindViewHolder(holder: AppViewHolder, position: Int) {
        holder.bind(items[position], onAppClick)
    }

    override fun getItemCount(): Int = items.size

    class AppViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val icon = itemView.findViewById<ImageView>(R.id.appIcon)
        private val label = itemView.findViewById<TextView>(R.id.appLabel)

        fun bind(app: LauncherApp, onAppClick: (LauncherApp) -> Unit) {
            icon.setImageDrawable(app.icon)
            label.text = app.label
            itemView.setOnClickListener { onAppClick(app) }
        }
    }
}
