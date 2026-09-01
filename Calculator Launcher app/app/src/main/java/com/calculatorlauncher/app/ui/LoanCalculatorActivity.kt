package com.calculatorlauncher.app.ui

import android.os.Bundle
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.util.FinanceMath
import com.calculatorlauncher.app.util.KeypadBinder
import com.calculatorlauncher.app.util.NumberInput

class LoanCalculatorActivity : BaseToolActivity(R.layout.activity_loan_calculator) {
    override val screenTitle: String get() = getString(R.string.tool_loan)

    private var focus = 0
    private var loan = "0"
    private var rate = "0"
    private var years = 1
    private var months = 0

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tvLoan = findViewById<TextView>(R.id.tvLoan)
        val tvRate = findViewById<TextView>(R.id.tvRate)
        val tvYears = findViewById<TextView>(R.id.tvYears)
        val tvMonths = findViewById<TextView>(R.id.tvMonths)
        val tvMonthly = findViewById<TextView>(R.id.tvMonthlyPay)
        val tvTotal = findViewById<TextView>(R.id.tvTotalPay)
        val tvTotalLabel = findViewById<TextView>(R.id.tvTotalLabel)
        val fieldLoan = findViewById<View>(R.id.fieldLoan)

        fun refresh() {
            tvLoan.text = NumberInput.money(NumberInput.toDouble(loan))
            tvRate.text = NumberInput.percent(NumberInput.toDouble(rate))
            tvYears.text = years.toString()
            tvMonths.text = months.toString()
            val totalMonths = years * 12 + months
            val (monthly, total) = FinanceMath.loanPayment(
                NumberInput.toDouble(loan),
                NumberInput.toDouble(rate),
                totalMonths
            )
            tvMonthly.text = NumberInput.money(monthly)
            tvTotal.text = NumberInput.money(total)
            tvTotalLabel.text = "Total of $totalMonths Payments"
            fieldLoan.setBackgroundResource(
                if (focus == 0) R.drawable.bg_input_focus else R.drawable.bg_input_box
            )
            tvRate.setBackgroundResource(
                if (focus == 1) R.drawable.bg_input_focus else R.drawable.bg_input_box
            )
        }

        fun current() = if (focus == 0) loan else rate
        fun setCurrent(v: String) {
            if (focus == 0) loan = v else rate = v
            refresh()
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

        fieldLoan.setOnClickListener { focus = 0; refresh() }
        tvRate.setOnClickListener { focus = 1; refresh() }

        findViewById<View>(R.id.fieldYears).setOnClickListener {
            val options = Array(41) { it.toString() }
            openChoice("Years", options, years) { years = it }
        }
        findViewById<View>(R.id.fieldMonths).setOnClickListener {
            val options = Array(12) { it.toString() }
            openChoice("Months", options, months) { months = it }
        }

        KeypadBinder(
            root = window.decorView,
            onDigit = { setCurrent(NumberInput.appendDigit(current(), it)) },
            onDot = { setCurrent(NumberInput.appendDot(current())) },
            onBackspace = { setCurrent(NumberInput.backspace(current())) },
            onClear = { setCurrent(NumberInput.clear()) },
            onUp = { focus = 0; refresh() },
            onDown = { focus = 1; refresh() }
        )
        refresh()
    }
}
