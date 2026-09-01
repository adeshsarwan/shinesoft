package com.calculatorlauncher.app.util

import android.content.Context
import org.json.JSONArray
import org.json.JSONObject

data class HistoryEntry(
    val id: Long,
    val expression: String,
    val result: String,
    val timestamp: Long = System.currentTimeMillis()
)

class CalcHistoryStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun all(): List<HistoryEntry> {
        val arr = JSONArray(prefs.getString(KEY, "[]"))
        return buildList {
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                add(
                    HistoryEntry(
                        id = o.getLong("id"),
                        expression = o.getString("expression"),
                        result = o.getString("result"),
                        timestamp = o.optLong("timestamp", 0L)
                    )
                )
            }
        }
    }

    fun add(expression: String, result: String) {
        if (expression.isBlank() || result.isBlank()) return
        val list = all().toMutableList()
        // Avoid duplicate consecutive same entry
        if (list.firstOrNull()?.expression == expression && list.firstOrNull()?.result == result) return
        list.add(0, HistoryEntry(System.currentTimeMillis(), expression, result))
        while (list.size > MAX) list.removeAt(list.lastIndex)
        save(list)
    }

    fun remove(id: Long) {
        save(all().filterNot { it.id == id })
    }

    fun clear() {
        prefs.edit().putString(KEY, "[]").apply()
    }

    private fun save(list: List<HistoryEntry>) {
        val arr = JSONArray()
        list.forEach {
            arr.put(
                JSONObject()
                    .put("id", it.id)
                    .put("expression", it.expression)
                    .put("result", it.result)
                    .put("timestamp", it.timestamp)
            )
        }
        prefs.edit().putString(KEY, arr.toString()).apply()
    }

    companion object {
        private const val PREFS = "calc_history"
        private const val KEY = "entries"
        private const val MAX = 50
        const val EXTRA_USE_RESULT = "use_result"
    }
}
