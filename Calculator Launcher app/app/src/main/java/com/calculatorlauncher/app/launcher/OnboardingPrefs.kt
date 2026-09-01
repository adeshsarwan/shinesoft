package com.calculatorlauncher.app.launcher

import android.content.Context

/**
 * ========== LAUNCHER_MODE_START ==========
 * First-open onboarding state (intro + default home guide).
 * ========== LAUNCHER_MODE_END ==========
 */
object OnboardingPrefs {

    private const val PREFS = "onboarding_prefs"
    private const val KEY_DONE = "onboarding_done"

    fun isDone(context: Context): Boolean =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getBoolean(KEY_DONE, false)

    fun markDone(context: Context) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putBoolean(KEY_DONE, true)
            .apply()
    }
}
