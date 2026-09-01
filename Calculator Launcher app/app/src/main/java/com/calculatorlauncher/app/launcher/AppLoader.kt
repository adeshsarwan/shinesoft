package com.calculatorlauncher.app.launcher

import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.drawable.Drawable
import android.os.Build

/**
 * ========== LAUNCHER_MODE_START ==========
 * Loads all installed launcher apps for the apps drawer (vertical scroll).
 * ========== LAUNCHER_MODE_END ==========
 */
data class LauncherApp(
    val label: String,
    val packageName: String,
    val activityName: String,
    val icon: Drawable
)

object AppLoader {

    fun loadLauncherApps(packageManager: PackageManager): List<LauncherApp> {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PackageManager.MATCH_ALL
        } else {
            0
        }

        @Suppress("DEPRECATION")
        val activities: List<ResolveInfo> = packageManager.queryIntentActivities(intent, flags)

        val byComponent = linkedMapOf<String, LauncherApp>()
        activities.forEach { info ->
            val activityInfo = info.activityInfo ?: return@forEach
            val pkg = activityInfo.packageName ?: return@forEach
            val name = activityInfo.name ?: return@forEach
            val label = info.loadLabel(packageManager)?.toString()?.trim().orEmpty()
            if (label.isEmpty()) return@forEach
            val key = "$pkg/$name"
            byComponent[key] = LauncherApp(
                label = label,
                packageName = pkg,
                activityName = name,
                icon = info.loadIcon(packageManager)
            )
        }

        // Fallback: some OEMs hide apps from MATCH query — try launch intents
        @Suppress("DEPRECATION")
        val installed = packageManager.getInstalledApplications(PackageManager.GET_META_DATA)
        installed.forEach { appInfo ->
            val launch = packageManager.getLaunchIntentForPackage(appInfo.packageName) ?: return@forEach
            val component = launch.component ?: return@forEach
            val key = "${component.packageName}/${component.className}"
            if (byComponent.containsKey(key)) return@forEach
            val label = appInfo.loadLabel(packageManager)?.toString()?.trim().orEmpty()
            if (label.isEmpty()) return@forEach
            byComponent[key] = LauncherApp(
                label = label,
                packageName = component.packageName,
                activityName = component.className,
                icon = appInfo.loadIcon(packageManager)
            )
        }

        return byComponent.values.sortedBy { it.label.lowercase() }
    }
}
