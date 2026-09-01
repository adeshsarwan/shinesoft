package com.calculatorlauncher.app.ui

import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.util.FinanceMath
import com.calculatorlauncher.app.util.KeypadBinder
import com.calculatorlauncher.app.util.NumberInput

class BmiCalculatorActivity : BaseToolActivity(R.layout.activity_bmi_calculator) {
    override val screenTitle: String get() = getString(R.string.tool_bmi)

    private var imperial = true
    private var feet = 5
    private var inches = 10
    private var heightCm = "170"
    private var weight = "0"
    /** 0 = weight, 1 = height cm (metric only) */
    private var focus = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val tvUnit = findViewById<TextView>(R.id.tvUnitSystem)
        val tvHeightLabel = findViewById<TextView>(R.id.tvHeightLabel)
        val tvWeightLabel = findViewById<TextView>(R.id.tvWeightLabel)
        val heightImperialRow = findViewById<View>(R.id.heightImperialRow)
        val tvHeightCm = findViewById<TextView>(R.id.tvHeightCm)
        val tvFeet = findViewById<TextView>(R.id.tvFeet)
        val tvInches = findViewById<TextView>(R.id.tvInches)
        val tvWeight = findViewById<TextView>(R.id.tvWeight)
        val tvBmi = findViewById<TextView>(R.id.tvBmi)
        val fieldUnit = findViewById<View>(R.id.fieldUnit)
        val fieldFeet = findViewById<View>(R.id.fieldFeet)
        val fieldInches = findViewById<View>(R.id.fieldInches)

        fun calcBmi(): Double {
            val w = NumberInput.toDouble(weight)
            return if (imperial) {
                FinanceMath.bmiImperial(feet, inches, w)
            } else {
                FinanceMath.bmiMetric(NumberInput.toDouble(heightCm), w)
            }
        }

        fun refresh() {
            tvUnit.text = getString(if (imperial) R.string.unit_imperial else R.string.unit_metric)
            tvHeightLabel.text = getString(if (imperial) R.string.height_ft_in else R.string.height_cm)
            tvWeightLabel.text = getString(if (imperial) R.string.weight_lb else R.string.weight_kg)

            if (imperial) {
                heightImperialRow.visibility = View.VISIBLE
                tvHeightCm.visibility = View.GONE
                tvFeet.text = feet.toString()
                tvInches.text = inches.toString()
            } else {
                heightImperialRow.visibility = View.GONE
                tvHeightCm.visibility = View.VISIBLE
                tvHeightCm.text = NumberInput.smart(NumberInput.toDouble(heightCm))
                tvHeightCm.setBackgroundResource(
                    if (focus == 1) R.drawable.bg_input_focus else R.drawable.bg_input_box
                )
            }

            tvWeight.text = NumberInput.money(NumberInput.toDouble(weight))
            tvWeight.setBackgroundResource(
                if (focus == 0) R.drawable.bg_input_focus else R.drawable.bg_input_box
            )
            tvBmi.text = NumberInput.money(calcBmi())
        }

        fun openChoice(title: String, options: Array<String>, selected: Int, onPick: (Int) -> Unit) {
            AlertDialog.Builder(this)
                .setTitle(title)
                .setSingleChoiceItems(options, selected) { dialog, which ->
                    onPick(which)
                    refresh()
                    dialog.dismiss()
                }
                .setNegativeButton(android.R.string.cancel, null)
                .show()
        }

        fieldUnit.setOnClickListener {
            openChoice(
                title = getString(R.string.unit),
                options = arrayOf(getString(R.string.unit_imperial), getString(R.string.unit_metric)),
                selected = if (imperial) 0 else 1
            ) { which ->
                imperial = which == 0
                focus = 0
                weight = "0"
                if (!imperial) heightCm = "170"
            }
        }

        fieldFeet.setOnClickListener {
            val options = Array(8) { (it + 1).toString() }
            openChoice(getString(R.string.height_ft_in) + " (ft)", options, feet - 1) { which ->
                feet = which + 1
            }
        }

        fieldInches.setOnClickListener {
            val options = Array(12) { it.toString() }
            openChoice(getString(R.string.height_ft_in) + " (in)", options, inches) { which ->
                inches = which
            }
        }

        tvWeight.setOnClickListener {
            focus = 0
            refresh()
        }
        tvHeightCm.setOnClickListener {
            if (!imperial) {
                focus = 1
                refresh()
            }
        }

        fun current(): String = if (!imperial && focus == 1) heightCm else weight

        fun setCurrent(value: String) {
            if (!imperial && focus == 1) heightCm = value else weight = value
            refresh()
        }

        // Bind against activity content so keypad always receives clicks
        KeypadBinder(
            root = window.decorView,
            onDigit = { setCurrent(NumberInput.appendDigit(current(), it)) },
            onDot = { setCurrent(NumberInput.appendDot(current())) },
            onBackspace = { setCurrent(NumberInput.backspace(current())) },
            onClear = { setCurrent(NumberInput.clear()) },
            onUp = {
                if (!imperial) {
                    focus = 1
                    refresh()
                }
            },
            onDown = {
                focus = 0
                refresh()
            }
        )
        refresh()
    }
}
