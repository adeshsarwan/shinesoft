package com.calculatorlauncher.app.ui

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ImageButton
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.recyclerview.widget.LinearLayoutManager
import androidx.recyclerview.widget.RecyclerView
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.util.CalcHistoryStore
import com.calculatorlauncher.app.util.HistoryEntry
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class HistoryActivity : AppCompatActivity() {

    private lateinit var store: CalcHistoryStore
    private lateinit var adapter: HistoryAdapter
    private lateinit var emptyView: TextView
    private lateinit var listView: RecyclerView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_history)

        store = CalcHistoryStore(this)
        emptyView = findViewById(R.id.tvEmptyHistory)
        listView = findViewById(R.id.historyList)

        findViewById<ImageButton>(R.id.btnBack).setOnClickListener { finish() }
        findViewById<TextView>(R.id.btnClearHistory).setOnClickListener {
            if (store.all().isEmpty()) return@setOnClickListener
            AlertDialog.Builder(this)
                .setTitle(R.string.clear_history)
                .setMessage(R.string.clear_history_confirm)
                .setPositiveButton(android.R.string.ok) { _, _ ->
                    store.clear()
                    refresh()
                }
                .setNegativeButton(android.R.string.cancel, null)
                .show()
        }

        adapter = HistoryAdapter(
            onClick = { entry ->
                setResult(
                    Activity.RESULT_OK,
                    Intent().putExtra(CalcHistoryStore.EXTRA_USE_RESULT, entry.result)
                )
                finish()
            },
            onDelete = { entry ->
                store.remove(entry.id)
                refresh()
            }
        )
        listView.layoutManager = LinearLayoutManager(this)
        listView.adapter = adapter
        refresh()
    }

    private fun refresh() {
        val items = store.all()
        adapter.submit(items)
        emptyView.visibility = if (items.isEmpty()) View.VISIBLE else View.GONE
        listView.visibility = if (items.isEmpty()) View.GONE else View.VISIBLE
    }

    private class HistoryAdapter(
        private val onClick: (HistoryEntry) -> Unit,
        private val onDelete: (HistoryEntry) -> Unit
    ) : RecyclerView.Adapter<HistoryAdapter.VH>() {

        private val items = mutableListOf<HistoryEntry>()
        private val timeFmt = SimpleDateFormat("MM/dd/yy - h:mm a", Locale.getDefault())

        fun submit(data: List<HistoryEntry>) {
            items.clear()
            items.addAll(data)
            notifyDataSetChanged()
        }

        override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): VH {
            val view = LayoutInflater.from(parent.context)
                .inflate(R.layout.item_history_row, parent, false)
            return VH(view)
        }

        override fun getItemCount(): Int = items.size

        override fun onBindViewHolder(holder: VH, position: Int) {
            val item = items[position]
            holder.expression.text = item.expression
            holder.result.text = "= ${item.result}"
            holder.time.text = timeFmt.format(Date(item.timestamp))
            holder.itemView.setOnClickListener { onClick(item) }
            holder.delete.setOnClickListener { onDelete(item) }
        }

        class VH(view: View) : RecyclerView.ViewHolder(view) {
            val expression: TextView = view.findViewById(R.id.tvHistoryExpression)
            val result: TextView = view.findViewById(R.id.tvHistoryResult)
            val time: TextView = view.findViewById(R.id.tvHistoryTime)
            val delete: ImageButton = view.findViewById(R.id.btnDeleteHistory)
        }
    }
}
