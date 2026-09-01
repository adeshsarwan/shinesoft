package com.calculatorlauncher.app.launcher

import android.app.role.RoleManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.Settings
import androidx.activity.result.ActivityResultLauncher
import androidx.appcompat.app.AppCompatActivity

/**
 * ========== LAUNCHER_MODE_START ==========
 * Opens the phone's own Default Home App screen / role picker.
 * ========== LAUNCHER_MODE_END ==========
 */
object SetDefaultLauncherHelper {

    fun isDefaultLauncher(context: Context): Boolean {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        val resolveInfo = context.packageManager.resolveActivity(
            intent,
            PackageManager.MATCH_DEFAULT_ONLY
        )
        return resolveInfo?.activityInfo?.packageName == context.packageName
    }

    /**
     * Opens system UI to choose default launcher — same as
     * Settings → Apps → Default apps → Home / Launcher.
     */
    fun openDefaultLauncherSettings(
        activity: AppCompatActivity,
        resultLauncher: ActivityResultLauncher<Intent>? = null
    ) {
        val intent = createDefaultHomeIntent(activity) ?: return
        try {
            if (resultLauncher != null) {
                resultLauncher.launch(intent)
            } else {
                activity.startActivity(intent)
            }
        } catch (_: Exception) {
            val fallback = Intent(Settings.ACTION_HOME_SETTINGS)
            if (resultLauncher != null) resultLauncher.launch(fallback)
            else activity.startActivity(fallback)
        }
    }

    private fun createDefaultHomeIntent(activity: AppCompatActivity): Intent? {
        // Android 10+: system role request (official phone way)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val roleManager = activity.getSystemService(RoleManager::class.java)
            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_HOME)) {
                if (!roleManager.isRoleHeld(RoleManager.ROLE_HOME)) {
                    return roleManager.createRequestRoleIntent(RoleManager.ROLE_HOME)
                }
            }
        }
        // Settings list: "Default home app" (MIUI / many OEMs)
        return Intent(Settings.ACTION_HOME_SETTINGS)
    }
}
