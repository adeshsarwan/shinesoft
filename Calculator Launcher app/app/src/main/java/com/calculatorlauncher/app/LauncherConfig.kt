package com.calculatorlauncher.app

/**
 * ============================================================
 * LAUNCHER FEATURE TOGGLE — read this first
 * ============================================================
 *
 * To turn the phone-launcher OFF and keep only the calculator app:
 *   1. Set [ENABLE_LAUNCHER_MODE] = false below
 *   2. In AndroidManifest.xml, comment the block between
 *      LAUNCHER_MODE_START and LAUNCHER_MODE_END
 *   3. Uncomment the block between CALCULATOR_ONLY_START and CALCULATOR_ONLY_END
 *
 * To turn the launcher back ON, reverse those steps.
 *
 * All launcher-only Kotlin files live under package `launcher`.
 * SplashActivity still compiles when launcher is off — it routes to MainActivity.
 * ============================================================
 */
object LauncherConfig {

    /** Master switch: true = splash + home-screen launcher; false = normal calculator app */
    const val ENABLE_LAUNCHER_MODE = true

    /** Splash delay before opening home (milliseconds) */
    const val SPLASH_DELAY_MS = 1500L

    /** Show "Set as default home app" guide on first launcher open */
    const val SHOW_DEFAULT_LAUNCHER_PROMPT = true
}
