package com.calculatorlauncher.app.ui

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.util.KeypadBinder
import com.calculatorlauncher.app.util.NumberInput
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.concurrent.Executors

data class CurrencyItem(
    val code: String,
    val name: String,
    val region: String,
    val flag: String,
    var rateToUsd: Double
)

class CurrencyConverterActivity : BaseToolActivity(R.layout.activity_currency_converter) {
    override val screenTitle: String get() = getString(R.string.tool_currency)

    private val allCurrencies = mutableListOf(
        CurrencyItem("USD", "United States Dollar", "United States", "🇺🇸", 1.0),
        CurrencyItem("EUR", "Euro", "European Union", "🇪🇺", 0.92),
        CurrencyItem("GBP", "British Pound", "United Kingdom", "🇬🇧", 0.79),
        CurrencyItem("INR", "Indian Rupee", "India", "🇮🇳", 83.10),
        CurrencyItem("JPY", "Japanese Yen", "Japan", "🇯🇵", 149.50),
        CurrencyItem("CAD", "Canadian Dollar", "Canada", "🇨🇦", 1.36),
        CurrencyItem("AUD", "Australian Dollar", "Australia", "🇦🇺", 1.52),
        CurrencyItem("CHF", "Swiss Franc", "Switzerland", "🇨🇭", 0.88),
        CurrencyItem("CNY", "Chinese Yuan", "China", "🇨🇳", 7.24),
        CurrencyItem("AED", "UAE Dirham", "United Arab Emirates", "🇦🇪", 3.67)
    )

    private val selected = mutableListOf(
        allCurrencies.first { it.code == "USD" },
        allCurrencies.first { it.code == "INR" }
    )
    private var activeIndex = 0
    private var amountRaw = "1"
    private lateinit var currencyList: LinearLayout
    private lateinit var tvUpdated: TextView
    private val io = Executors.newSingleThreadExecutor()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        currencyList = findViewById(R.id.currencyList)
        tvUpdated = findViewById(R.id.tvUpdated)
        tvUpdated.text = getString(R.string.updated_sample)

        findViewById<View>(R.id.btnAddCurrency).setOnClickListener { addCurrency() }
        tvUpdated.setOnClickListener { fetchLiveRates() }

        KeypadBinder(
            root = window.decorView,
            onDigit = {
                amountRaw = NumberInput.appendDigit(amountRaw, it)
                renderRows()
            },
            onDot = {
                amountRaw = NumberInput.appendDot(amountRaw)
                renderRows()
            },
            onBackspace = {
                amountRaw = NumberInput.backspace(amountRaw)
                renderRows()
            },
            onClear = {
                amountRaw = NumberInput.clear()
                renderRows()
            },
            onSign = {
                amountRaw = NumberInput.toggleSign(amountRaw)
                renderRows()
            },
            onUp = {
                val usd = toUsd()
                activeIndex = (activeIndex - 1 + selected.size) % selected.size
                amountRaw = NumberInput.money(usd * selected[activeIndex].rateToUsd)
                renderRows()
            },
            onDown = {
                val usd = toUsd()
                activeIndex = (activeIndex + 1) % selected.size
                amountRaw = NumberInput.money(usd * selected[activeIndex].rateToUsd)
                renderRows()
            }
        )
        renderRows()
        fetchLiveRates()
    }

    private fun toUsd(): Double =
        NumberInput.toDouble(amountRaw) / selected[activeIndex].rateToUsd.coerceAtLeast(0.0000001)

    private fun fetchLiveRates() {
        tvUpdated.text = getString(R.string.updated_sample)
        io.execute {
            try {
                val connection = (URL("https://open.er-api.com/v6/latest/USD").openConnection() as HttpURLConnection).apply {
                    connectTimeout = 12000
                    readTimeout = 12000
                    requestMethod = "GET"
                }
                val body = connection.inputStream.bufferedReader().use { it.readText() }
                connection.disconnect()

                val json = JSONObject(body)
                if (json.optString("result") != "success") {
                    throw IllegalStateException("API error")
                }
                val rates = json.getJSONObject("rates")
                val updatedAt = formatNow()

                runOnUiThread {
                    allCurrencies.forEach { item ->
                        if (item.code == "USD") {
                            item.rateToUsd = 1.0
                        } else if (rates.has(item.code)) {
                            item.rateToUsd = rates.getDouble(item.code)
                        }
                    }
                    // Keep selected list pointing to updated allCurrencies objects
                    for (i in selected.indices) {
                        val code = selected[i].code
                        allCurrencies.find { it.code == code }?.let { selected[i] = it }
                    }
                    tvUpdated.text = getString(R.string.updated_at, updatedAt)
                    renderRows()
                }
            } catch (_: Exception) {
                runOnUiThread {
                    tvUpdated.text = getString(R.string.rates_failed)
                    Toast.makeText(this, R.string.rates_failed, Toast.LENGTH_SHORT).show()
                }
            }
        }
    }

    private fun formatNow(): String {
        return SimpleDateFormat("MM/dd/yy - h:mm a", Locale.getDefault()).format(Date())
    }

    private fun addCurrency() {
        val used = selected.map { it.code }.toSet()
        val available = allCurrencies.filter { it.code !in used }
        if (available.isEmpty()) {
            Toast.makeText(this, "All currencies added", Toast.LENGTH_SHORT).show()
            return
        }
        AlertDialog.Builder(this)
            .setTitle(R.string.add_currency)
            .setItems(available.map { "${it.flag}  ${it.code} - ${it.name}" }.toTypedArray()) { _, which ->
                selected.add(available[which])
                renderRows()
            }
            .setNegativeButton(android.R.string.cancel, null)
            .show()
    }

    private fun changeRowCurrency(rowIndex: Int) {
        val used = selected.map { it.code }.toSet()
        val options = allCurrencies.filter { it.code !in used || it.code == selected[rowIndex].code }
        AlertDialog.Builder(this)
            .setTitle("Select Currency")
            .setItems(options.map { "${it.flag}  ${it.code} - ${it.name}" }.toTypedArray()) { _, which ->
                selected[rowIndex] = options[which]
                renderRows()
            }
            .show()
    }

    private fun renderRows() {
        currencyList.removeAllViews()
        val inflater = LayoutInflater.from(this)
        val usd = toUsd()
        selected.forEachIndexed { index, currency ->
            val row = inflater.inflate(R.layout.item_currency_row, currencyList, false)
            row.findViewById<TextView>(R.id.tvFlag).text = currency.flag
            row.findViewById<TextView>(R.id.tvCurrencyName).text = currency.name
            row.findViewById<TextView>(R.id.tvCurrencyRegion).text =
                "${currency.region}  •  1 USD = ${NumberInput.money(currency.rateToUsd)} ${currency.code}"
            val valueView = row.findViewById<TextView>(R.id.tvCurrencyValue)
            valueView.text = NumberInput.money(usd * currency.rateToUsd)
            if (index == activeIndex) {
                row.setBackgroundResource(R.drawable.bg_currency_card_active)
                valueView.setBackgroundResource(R.drawable.bg_input_focus)
                valueView.setTextColor(getColor(R.color.text_primary))
            } else {
                row.setBackgroundResource(R.drawable.bg_currency_card)
                valueView.background = null
                valueView.setTextColor(getColor(R.color.text_green))
            }
            row.setOnClickListener {
                if (activeIndex != index) {
                    val keepUsd = toUsd()
                    activeIndex = index
                    amountRaw = NumberInput.money(keepUsd * selected[activeIndex].rateToUsd)
                }
                renderRows()
            }
            row.setOnLongClickListener {
                changeRowCurrency(index)
                true
            }
            currencyList.addView(row)
        }
    }

    override fun onDestroy() {
        io.shutdownNow()
        super.onDestroy()
    }
}
