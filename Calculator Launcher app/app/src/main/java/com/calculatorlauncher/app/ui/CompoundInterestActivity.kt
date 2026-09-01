package com.calculatorlauncher.app.ui

import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.util.FinanceMath
import com.calculatorlauncher.app.util.KeypadBinder
import com.calculatorlauncher.app.util.NumberInput

class CompoundInterestActivity : BaseToolActivity(R.layout.activity_compound_interest) {
    override val screenTitle: String get() = getString(R.string.tool_compound)

    private var focus = 0
    private var initial = "0"
    private var rate = "0"
    private var period = "0"
    private val compounds = listOf(
        "Yearly" to 1,
        "Semi-Annually" to 2,
        "Quarterly" to 4,
        "Monthly" to 12,
        "Daily" to 365
    )
    private var compoundIndex = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tvInitial = findViewById<TextView>(R.id.tvInitial)
        val tvRate = findViewById<TextView>(R.id.tvRate)
        val tvPeriod = findViewById<TextView>(R.id.tvPeriod)
        val tvCompound = findViewById<TextView>(R.id.tvCompound)
        val tvFinal = findViewById<TextView>(R.id.tvFinal)
        val tvInterest = findViewById<TextView>(R.id.tvInterest)
        val fieldInitial = findViewById<View>(R.id.fieldInitial)
        val fieldCompound = findViewById<View>(R.id.fieldCompound)

        fun refresh() {
            tvInitial.text = NumberInput.money(NumberInput.toDouble(initial))
            tvRate.text = NumberInput.percent(NumberInput.toDouble(rate))
            tvPeriod.text = NumberInput.money(NumberInput.toDouble(period))
            tvCompound.text = compounds[compoundIndex].first
            val (finalValue, interest) = FinanceMath.compound(
                NumberInput.toDouble(initial),
                NumberInput.toDouble(rate),
                NumberInput.toDouble(period),
                compounds[compoundIndex].second
            )
            tvFinal.text = NumberInput.money(finalValue)
            tvInterest.text = NumberInput.money(interest)
            fieldInitial.setBackgroundResource(
                if (focus == 0) R.drawable.bg_input_focus else R.drawable.bg_input_box
            )
            tvRate.setBackgroundResource(
                if (focus == 1) R.drawable.bg_input_focus else R.drawable.bg_input_box
            )
            tvPeriod.setBackgroundResource(
                if (focus == 2) R.drawable.bg_input_focus else R.drawable.bg_input_box
            )
        }

        fun current() = when (focus) {
            0 -> initial
            1 -> rate
            else -> period
        }

        fun setCurrent(v: String) {
            when (focus) {
                0 -> initial = v
                1 -> rate = v
                else -> period = v
            }
            refresh()
        }

        fieldInitial.setOnClickListener { focus = 0; refresh() }
        tvRate.setOnClickListener { focus = 1; refresh() }
        tvPeriod.setOnClickListener { focus = 2; refresh() }
        fieldCompound.setOnClickListener {
            val labels = compounds.map { it.first }.toTypedArray()
            AlertDialog.Builder(this)
                .setTitle(R.string.compound)
                .setSingleChoiceItems(labels, compoundIndex) { dialog, which ->
                    compoundIndex = which
                    refresh()
                    dialog.dismiss()
                }
                .setNegativeButton(android.R.string.cancel, null)
                .show()
        }

        KeypadBinder(
            root = window.decorView,
            onDigit = { setCurrent(NumberInput.appendDigit(current(), it)) },
            onDot = { setCurrent(NumberInput.appendDot(current())) },
            onBackspace = { setCurrent(NumberInput.backspace(current())) },
            onClear = { setCurrent(NumberInput.clear()) },
            onUp = { focus = (focus - 1 + 3) % 3; refresh() },
            onDown = { focus = (focus + 1) % 3; refresh() }
        )
        refresh()
    }
}
