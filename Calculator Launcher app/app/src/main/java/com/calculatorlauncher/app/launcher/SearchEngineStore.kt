package com.calculatorlauncher.app.launcher

import android.content.Context
import android.net.Uri
import com.calculatorlauncher.app.R

/**
 * ========== LAUNCHER_MODE_START ==========
 * Persists selected home-screen search engine.
 * ========== LAUNCHER_MODE_END ==========
 */
object SearchEngineStore {

    private const val PREFS = "search_engine_prefs"
    private const val KEY = "engine"

    const val RECOMMENDED = "recommended"
    const val YAHOO = "yahoo"
    const val BING = "bing"
    const val GOOGLE = "google"

    fun get(context: Context): String =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, RECOMMENDED) ?: RECOMMENDED

    fun set(context: Context, engine: String) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY, engine)
            .apply()
    }

    fun displayName(context: Context, engine: String = get(context)): String = when (engine) {
        YAHOO -> context.getString(R.string.search_engine_yahoo)
        BING -> context.getString(R.string.search_engine_bing)
        GOOGLE -> context.getString(R.string.search_engine_google)
        else -> context.getString(R.string.search_engine_recommended)
    }

    fun searchUri(context: Context, query: String = ""): Uri {
        val q = Uri.encode(query)
        val url = when (get(context)) {
            YAHOO -> "https://search.yahoo.com/search?p=$q"
            BING -> "https://www.bing.com/search?q=$q"
            else -> "https://www.google.com/search?q=$q"
        }
        return Uri.parse(url)
    }
}
