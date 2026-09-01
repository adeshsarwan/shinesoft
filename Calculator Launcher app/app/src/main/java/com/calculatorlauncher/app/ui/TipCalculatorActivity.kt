package com.calculatorlauncher.app.ui

import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.util.FinanceMath
import com.calculatorlauncher.app.util.KeypadBinder
import com.calculatorlauncher.app.util.NumberInput

class TipCalculatorActivity : BaseToolActivity(R.layout.activity_tip_calculator) {
    override val screenTitle: String get() = getString(R.string.tool_tip)

    private var focus = 0
    private var bill = "0"
    private var tipPercent = "0"
    private var split = 1

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tvBill = findViewById<TextView>(R.id.tvBill)
        val tvTipPercent = findViewById<TextView>(R.id.tvTipPercent)
        val tvSplit = findViewById<TextView>(R.id.tvSplit)
        val tvTipAmount = findViewById<TextView>(R.id.tvTipAmount)
        val tvTotal = findViewById<TextView>(R.id.tvTotal)
        val tvPerPerson = findViewById<TextView>(R.id.tvPerPerson)

        fun refresh() {
            tvBill.text = NumberInput.money(NumberInput.toDouble(bill))
            tvTipPercent.text = NumberInput.percent(NumberInput.toDouble(tipPercent))
            tvSplit.text = split.toString()
            val (tip, total, per) = FinanceMath.tip(
                NumberInput.toDouble(bill),
                NumberInput.toDouble(tipPercent),
                split
            )
            tvTipAmount.text = NumberInput.money(tip)
            tvTotal.text = NumberInput.money(total)
            tvPerPerson.text = NumberInput.money(per)
            findViewById<android.view.View>(R.id.fieldBill).setBackgroundResource(
                if (focus == 0) R.drawable.bg_input_focus else R.drawable.bg_input_box
            )
            tvTipPercent.setBackgroundResource(
                if (focus == 1) R.drawable.bg_input_focus else R.drawable.bg_input_box
            )
            findViewById<android.view.View>(R.id.fieldSplit).setBackgroundResource(R.drawable.bg_input_box)
        }

        fun current(): String = if (focus == 0) bill else tipPercent

        fun setCurrent(value: String) {
            if (focus == 0) bill = value else tipPercent = value
            refresh()
        }

        fun openSplitDropdown() {
            val options = Array(10) { index -> (index + 1).toString() }
            AlertDialog.Builder(this)
                .setTitle(R.string.split_with)
                .setSingleChoiceItems(options, split - 1) { dialog, which ->
                    split = which + 1
                    refresh()
                    dialog.dismiss()
                }
                .setNegativeButton(android.R.string.cancel, null)
                .show()
        }

        findViewById<android.view.View>(R.id.fieldBill).setOnClickListener { focus = 0; refresh() }
        tvTipPercent.setOnClickListener { focus = 1; refresh() }
        findViewById<android.view.View>(R.id.fieldSplit).setOnClickListener { openSplitDropdown() }

        KeypadBinder(
            root = findViewById(R.id.keypadInclude),
            onDigit = { setCurrent(NumberInput.appendDigit(current(), it)) },
            onDot = { setCurrent(NumberInput.appendDot(current())) },
            onBackspace = { setCurrent(NumberInput.backspace(current())) },
            onClear = { setCurrent(NumberInput.clear()) },
            onUp = { focus = if (focus == 0) 1 else 0; refresh() },
            onDown = { focus = if (focus == 0) 1 else 0; refresh() }
        )
        refresh()
    }
}
