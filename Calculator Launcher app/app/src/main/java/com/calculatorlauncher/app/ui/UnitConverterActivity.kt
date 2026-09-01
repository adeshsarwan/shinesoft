package com.calculatorlauncher.app.ui

import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.core.content.ContextCompat
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.util.KeypadBinder
import com.calculatorlauncher.app.util.NumberInput
import com.calculatorlauncher.app.util.UnitData

class UnitConverterActivity : BaseToolActivity(R.layout.activity_unit_converter) {
    override val screenTitle: String get() = getString(R.string.tool_unit)

    private var category = "Length"
    private var fromIndex = 0
    private var toIndex = 1
    private var editingFrom = true
    private var inputRaw = "1"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tabs = listOf(
            R.id.tabArea to "Area",
            R.id.tabLength to "Length",
            R.id.tabTemperature to "Temperature",
            R.id.tabVolume to "Volume",
            R.id.tabMass to "Mass",
            R.id.tabData to "Data",
            R.id.tabSpeed to "Speed",
            R.id.tabTime to "Time"
        )
        val tvFromUnit = findViewById<TextView>(R.id.tvFromUnit)
        val tvToUnit = findViewById<TextView>(R.id.tvToUnit)
        val tvFromValue = findViewById<TextView>(R.id.tvFromValue)
        val tvToValue = findViewById<TextView>(R.id.tvToValue)

        fun refresh() {
            val units = UnitData.units(category)
            if (units.isEmpty()) return
            fromIndex = fromIndex.coerceIn(0, units.lastIndex)
            toIndex = toIndex.coerceIn(0, units.lastIndex)
            tvFromUnit.text = units[fromIndex].label
            tvToUnit.text = units[toIndex].label

            val input = NumberInput.toDouble(inputRaw)
            if (editingFrom) {
                tvFromValue.text = NumberInput.smart(input)
                tvToValue.text = NumberInput.smart(
                    UnitData.convert(category, input, fromIndex, toIndex)
                )
            } else {
                tvToValue.text = NumberInput.smart(input)
                tvFromValue.text = NumberInput.smart(
                    UnitData.convert(category, input, toIndex, fromIndex)
                )
            }
            tvFromValue.setBackgroundResource(if (editingFrom) R.drawable.bg_input_focus else 0)
            tvToValue.setBackgroundResource(if (!editingFrom) R.drawable.bg_input_focus else 0)
        }

        fun openUnitDropdown(isFrom: Boolean) {
            val options = UnitData.labels(category)
            if (options.isEmpty()) return
            val selected = if (isFrom) fromIndex else toIndex
            AlertDialog.Builder(this)
                .setTitle(R.string.unit)
                .setSingleChoiceItems(options, selected) { dialog, which ->
                    if (isFrom) {
                        fromIndex = which
                    } else {
                        toIndex = which
                    }
                    refresh()
                    dialog.dismiss()
                }
                .setNegativeButton(android.R.string.cancel, null)
                .show()
        }

        fun selectCategory(name: String) {
            category = name
            val defaults = UnitData.defaultIndexes(name)
            fromIndex = defaults.first
            toIndex = defaults.second
            inputRaw = "1"
            editingFrom = true
            tabs.forEach { (id, cat) ->
                val tv = findViewById<TextView>(id)
                if (cat == name) {
                    tv.setTextColor(ContextCompat.getColor(this, R.color.text_green))
                    tv.setTypeface(tv.typeface, android.graphics.Typeface.BOLD)
                    tv.setBackgroundResource(R.drawable.bg_tab_active)
                } else {
                    tv.setTextColor(ContextCompat.getColor(this, R.color.text_secondary))
                    tv.setTypeface(tv.typeface, android.graphics.Typeface.NORMAL)
                    tv.setBackgroundResource(R.drawable.bg_tab_inactive)
                }
            }
            refresh()
        }

        tabs.forEach { (id, cat) ->
            findViewById<TextView>(id).setOnClickListener { selectCategory(cat) }
        }

        findViewById<View>(R.id.fromUnitDrop).setOnClickListener { openUnitDropdown(isFrom = true) }
        findViewById<View>(R.id.toUnitDrop).setOnClickListener { openUnitDropdown(isFrom = false) }

        tvFromValue.setOnClickListener {
            if (!editingFrom) {
                inputRaw = NumberInput.smart(NumberInput.toDouble(tvFromValue.text.toString()))
            }
            editingFrom = true
            refresh()
        }
        tvToValue.setOnClickListener {
            if (editingFrom) {
                inputRaw = NumberInput.smart(NumberInput.toDouble(tvToValue.text.toString()))
            }
            editingFrom = false
            refresh()
        }

        KeypadBinder(
            root = findViewById(R.id.keypadInclude),
            onDigit = {
                inputRaw = NumberInput.appendDigit(inputRaw, it)
                refresh()
            },
            onDot = {
                inputRaw = NumberInput.appendDot(inputRaw)
                refresh()
            },
            onBackspace = {
                inputRaw = NumberInput.backspace(inputRaw)
                refresh()
            },
            onClear = {
                inputRaw = NumberInput.clear()
                refresh()
            },
            onSign = {
                inputRaw = NumberInput.toggleSign(inputRaw)
                refresh()
            },
            onUp = {
                editingFrom = true
                refresh()
            },
            onDown = {
                editingFrom = false
                refresh()
            }
        )
        selectCategory("Length")
    }
}
