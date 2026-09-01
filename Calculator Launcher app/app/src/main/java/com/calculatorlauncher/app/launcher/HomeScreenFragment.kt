package com.calculatorlauncher.app.launcher

import android.content.Intent
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.calculatorlauncher.app.MainActivity
import com.calculatorlauncher.app.R
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * ========== LAUNCHER_MODE_START ==========
 * MI-style home: weather, pinned apps, search, bottom dock.
 * Swipe up (host activity) opens all-apps drawer.
 * ========== LAUNCHER_MODE_END ==========
 */
class HomeScreenFragment : Fragment() {

    private lateinit var adapter: HomeAppAdapter
    private lateinit var hint: View

    private val dockCandidates = listOf(
        listOf("com.android.contacts", "com.google.android.contacts", "com.android.dialer"),
        listOf("com.google.android.apps.messaging", "com.android.mms", "com.android.messaging"),
        listOf("com.android.chrome", "com.chrome.beta"),
        listOf("com.android.camera", "com.android.camera2", "com.google.android.GoogleCamera"),
        listOf("com.google.android.gm")
    )

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View = inflater.inflate(R.layout.fragment_home_screen, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val tvTime = view.findViewById<TextView>(R.id.tvHomeTime)
        val tvDate = view.findViewById<TextView>(R.id.tvHomeDate)
        hint = view.findViewById(R.id.customizeHint)

        tvTime.text = SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date())
        tvDate.text = SimpleDateFormat("MMMM d", Locale.getDefault()).format(Date())

        adapter = HomeAppAdapter { item -> onHomeItemClick(item) }
        val recycler = view.findViewById<RecyclerView>(R.id.homeAppsRecycler)
        recycler.layoutManager = GridLayoutManager(requireContext(), 4)
        recycler.adapter = adapter

        view.findViewById<View>(R.id.searchBar).setOnClickListener {
            startActivity(
                Intent(Intent.ACTION_VIEW, SearchEngineStore.searchUri(requireContext()))
            )
        }

        bindDock(view.findViewById(R.id.dockRow))
        view.findViewById<View>(R.id.pageIndicator).setOnClickListener {
            (activity as? LauncherHomeActivity)?.openAppsDrawer()
        }
        refreshHomeApps()
        maybeShowCustomizeHint()
    }

    override fun onResume() {
        super.onResume()
        view?.findViewById<TextView>(R.id.tvHomeTime)?.text =
            SimpleDateFormat("h:mm a", Locale.getDefault()).format(Date())
        refreshHomeApps()
    }

    private fun bindDock(dock: LinearLayout) {
        dock.removeAllViews()
        val pm = requireContext().packageManager
        val inflater = LayoutInflater.from(requireContext())
        dockCandidates.forEach { packages ->
            val pkg = packages.firstOrNull { pm.getLaunchIntentForPackage(it) != null } ?: return@forEach
            val launch = pm.getLaunchIntentForPackage(pkg) ?: return@forEach
            val label = try {
                pm.getApplicationLabel(pm.getApplicationInfo(pkg, 0)).toString()
            } catch (_: Exception) {
                pkg
            }
            val icon = try {
                pm.getApplicationIcon(pkg)
            } catch (_: Exception) {
                ContextCompat.getDrawable(requireContext(), R.drawable.ic_calc_quad)!!
            }
            val item = inflater.inflate(R.layout.item_home_app, dock, false)
            item.layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT, 1f)
            item.findViewById<ImageView>(R.id.appIcon).setImageDrawable(icon)
            item.findViewById<TextView>(R.id.appLabel).text = label
            item.setOnClickListener {
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launch)
            }
            dock.addView(item)
        }
    }

    private fun refreshHomeApps() {
        val ctx = requireContext()
        val pm = ctx.packageManager
        val all = AppLoader.loadLauncherApps(pm).associateBy { it.packageName }
        val items = mutableListOf<HomeAppItem>()

        // MI reference order: user apps first, then Customize + Calculator
        HomeAppsStore.getSelectedPackages(ctx).forEach { pkg ->
            val app = all[pkg] ?: return@forEach
            items += HomeAppItem(id = pkg, label = app.label, icon = app.icon)
        }
        items += HomeAppItem(
            id = HomeAppsStore.ID_CUSTOMIZE,
            label = getString(R.string.home_customize),
            icon = ContextCompat.getDrawable(ctx, R.drawable.ic_customize_home)!!
        )
        items += HomeAppItem(
            id = HomeAppsStore.ID_CALCULATOR,
            label = getString(R.string.home_calculator),
            icon = ContextCompat.getDrawable(ctx, R.drawable.ic_calc_quad)!!
        )
        adapter.submitList(items)
    }

    private fun maybeShowCustomizeHint() {
        val prefs = requireContext().getSharedPreferences("home_apps_prefs", 0)
        val shown = prefs.getBoolean("hint_shown", false)
        if (!shown) {
            hint.visibility = View.VISIBLE
            hint.postDelayed({
                if (isAdded) hint.visibility = View.GONE
            }, 4000)
            prefs.edit().putBoolean("hint_shown", true).apply()
        }
    }

    private fun onHomeItemClick(item: HomeAppItem) {
        when (item.id) {
            HomeAppsStore.ID_CUSTOMIZE ->
                startActivity(Intent(requireContext(), CustomizeAppsActivity::class.java))
            HomeAppsStore.ID_CALCULATOR ->
                startActivity(Intent(requireContext(), MainActivity::class.java))
            else -> {
                val launch = requireContext().packageManager.getLaunchIntentForPackage(item.id) ?: return
                launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(launch)
            }
        }
    }
}

data class HomeAppItem(val id: String, val label: String, val icon: Drawable)

class HomeAppAdapter(
    private val onClick: (HomeAppItem) -> Unit
) : RecyclerView.Adapter<HomeAppAdapter.Holder>() {

    private val items = mutableListOf<HomeAppItem>()

    fun submitList(data: List<HomeAppItem>) {
        items.clear()
        items.addAll(data)
        notifyDataSetChanged()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): Holder {
        val view = LayoutInflater.from(parent.context).inflate(R.layout.item_home_app, parent, false)
        return Holder(view)
    }

    override fun onBindViewHolder(holder: Holder, position: Int) {
        holder.bind(items[position], onClick)
    }

    override fun getItemCount(): Int = items.size

    class Holder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val icon = itemView.findViewById<ImageView>(R.id.appIcon)
        private val label = itemView.findViewById<TextView>(R.id.appLabel)

        fun bind(item: HomeAppItem, onClick: (HomeAppItem) -> Unit) {
            icon.setImageDrawable(item.icon)
            label.text = item.label
            itemView.setOnClickListener { onClick(item) }
        }
    }
}
