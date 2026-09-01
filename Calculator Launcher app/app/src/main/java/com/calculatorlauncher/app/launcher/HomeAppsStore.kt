package com.calculatorlauncher.app.launcher

import android.content.Context

/**
 * ========== LAUNCHER_MODE_START ==========
 * Persists apps the user pins on the launcher home screen.
 * ========== LAUNCHER_MODE_END ==========
 */
object HomeAppsStore {

    private const val PREFS = "home_apps_prefs"
    private const val KEY_PACKAGES = "packages"
    const val ID_CUSTOMIZE = "__customize__"
    const val ID_CALCULATOR = "__calculator__"

    fun getSelectedPackages(context: Context): LinkedHashSet<String> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_PACKAGES, "")
            .orEmpty()
        if (raw.isBlank()) return linkedSetOf()
        return raw.split(',').filter { it.isNotBlank() }.toCollection(LinkedHashSet())
    }

    fun setSelectedPackages(context: Context, packages: Collection<String>) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_PACKAGES, packages.joinToString(","))
            .apply()
    }

    fun isSelected(context: Context, packageName: String): Boolean =
        getSelectedPackages(context).contains(packageName)
}
