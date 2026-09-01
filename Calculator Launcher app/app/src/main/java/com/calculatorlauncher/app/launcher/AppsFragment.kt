package com.calculatorlauncher.app.launcher

import android.content.Intent
import android.graphics.drawable.Drawable
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.EditText
import android.widget.TextView
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.GridLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.calculatorlauncher.app.R

/**
 * ========== LAUNCHER_MODE_START ==========
 * Vertical-scrolling all-apps drawer. First tile = Calculator Settings.
 * ========== LAUNCHER_MODE_END ==========
 */
class AppsFragment : Fragment() {

    companion object {
        const val ID_SETTINGS = "__calc_settings__"
    }

    private lateinit var adapter: AppAdapter
    private var allApps = listOf<LauncherApp>()

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View = inflater.inflate(R.layout.fragment_apps, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val recycler = view.findViewById<RecyclerView>(R.id.appsRecycler)
        val emptyView = view.findViewById<TextView>(R.id.appsEmpty)
        val search = view.findViewById<EditText>(R.id.etAppsSearch)

        adapter = AppAdapter { app -> onAppClick(app) }
        recycler.layoutManager = GridLayoutManager(requireContext(), 5)
        recycler.adapter = adapter
        recycler.setHasFixedSize(true)
        recycler.isNestedScrollingEnabled = true

        reloadApps()
        emptyView.visibility = if (allApps.size <= 1) View.VISIBLE else View.GONE

        search.addTextChangedListener(object : TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) = Unit
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) = Unit
            override fun afterTextChanged(s: Editable?) {
                filterApps(s?.toString().orEmpty())
            }
        })
    }

    override fun onResume() {
        super.onResume()
        if (::adapter.isInitialized) reloadApps()
    }

    private fun reloadApps() {
        val ctx = requireContext()
        val settingsApp = LauncherApp(
            label = getString(R.string.customize_calc_settings),
            packageName = ID_SETTINGS,
            activityName = ID_SETTINGS,
            icon = ContextCompat.getDrawable(ctx, R.drawable.ic_settings_tile) as Drawable
        )
        val installed = AppLoader.loadLauncherApps(ctx.packageManager)
            .filter { it.packageName != ctx.packageName }
        allApps = listOf(settingsApp) + installed
        val q = view?.findViewById<EditText>(R.id.etAppsSearch)?.text?.toString().orEmpty()
        filterApps(q)
    }

    private fun filterApps(query: String) {
        val q = query.trim().lowercase()
        val filtered = if (q.isEmpty()) {
            allApps
        } else {
            allApps.filter {
                it.packageName == ID_SETTINGS || it.label.lowercase().contains(q)
            }
        }
        adapter.submitList(filtered)
    }

    private fun onAppClick(app: LauncherApp) {
        if (app.packageName == ID_SETTINGS) {
            startActivity(Intent(requireContext(), LauncherSettingsActivity::class.java))
            return
        }
        val launch = Intent(Intent.ACTION_MAIN).apply {
            addCategory(Intent.CATEGORY_LAUNCHER)
            setClassName(app.packageName, app.activityName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            startActivity(launch)
        } catch (_: Exception) {
            val fallback = requireContext().packageManager.getLaunchIntentForPackage(app.packageName) ?: return
            fallback.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(fallback)
        }
    }
}
