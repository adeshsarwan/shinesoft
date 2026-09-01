package com.calculatorlauncher.app.ui

import android.os.Bundle
import android.view.View
import android.widget.ImageView
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.util.FinanceMath
import com.calculatorlauncher.app.util.NumberInput

class MortgageCalculatorActivity : BaseToolActivity(R.layout.activity_mortgage_calculator) {
    override val screenTitle: String get() = getString(R.string.tool_mortgage)

    private var focus = 0 // 0 home, 1 down, 2 rate, 3 tax, 4 insurance
    private var home = "0"
    private var down = "0"
    private var rate = "0"
    private var propertyTax = "0"
    private var insurance = "0"
    private var years = 30
    private var downIsPercent = true
    private var taxesExpanded = false

    private val termOptions = listOf(10, 15, 20, 25, 30)

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val tvHome = findViewById<TextView>(R.id.tvHomePrice)
        val tvDown = findViewById<TextView>(R.id.tvDownPayment)
        val tvDownType = findViewById<TextView>(R.id.tvDownType)
        val tvRate = findViewById<TextView>(R.id.tvInterestRate)
        val tvTerm = findViewById<TextView>(R.id.tvLoanTerm)
        val tvTax = findViewById<TextView>(R.id.tvPropertyTax)
        val tvInsurance = findViewById<TextView>(R.id.tvInsurance)
        val tvMonthly = findViewById<TextView>(R.id.tvMonthlyResult)
        val tvTotal = findViewById<TextView>(R.id.tvTotalResult)
        val taxesSection = findViewById<View>(R.id.taxesSection)
        val ivTaxesArrow = findViewById<ImageView>(R.id.ivTaxesArrow)

        fun principal(): Double {
            val price = NumberInput.toDouble(home)
            val downValue = NumberInput.toDouble(down)
            return if (downIsPercent) {
                price * (1 - downValue / 100.0)
            } else {
                (price - downValue).coerceAtLeast(0.0)
            }
        }

        fun compute() {
            val months = years * 12
            val (monthlyLoan, totalLoan) = FinanceMath.loanPayment(
                principal(),
                NumberInput.toDouble(rate),
                months
            )
            val monthlyExtras =
                (NumberInput.toDouble(propertyTax) + NumberInput.toDouble(insurance)) / 12.0
            val monthly = monthlyLoan + monthlyExtras
            val total = totalLoan + monthlyExtras * months
            tvMonthly.text = NumberInput.money(monthly)
            tvTotal.text = NumberInput.money(total)
        }

        fun highlight(view: TextView, selected: Boolean) {
            view.setBackgroundResource(
                if (selected) R.drawable.bg_input_focus else R.drawable.bg_result_box
            )
        }

        fun refresh() {
            tvHome.text = NumberInput.money(NumberInput.toDouble(home))
            tvDown.text = NumberInput.money(NumberInput.toDouble(down))
            tvDownType.text = if (downIsPercent) "%" else "$"
            tvRate.text = NumberInput.percent(NumberInput.toDouble(rate))
            tvTerm.text = "$years Year"
            tvTax.text = NumberInput.money(NumberInput.toDouble(propertyTax))
            tvInsurance.text = NumberInput.money(NumberInput.toDouble(insurance))
            highlight(tvHome, focus == 0)
            highlight(tvDown, focus == 1)
            highlight(tvRate, focus == 2)
            highlight(tvTax, focus == 3)
            highlight(tvInsurance, focus == 4)
            taxesSection.visibility = if (taxesExpanded) View.VISIBLE else View.GONE
            ivTaxesArrow.rotation = if (taxesExpanded) 180f else 0f
            compute()
        }

        fun current(): String = when (focus) {
            0 -> home
            1 -> down
            2 -> rate
            3 -> propertyTax
            else -> insurance
        }

        fun setCurrent(value: String) {
            when (focus) {
                0 -> home = value
                1 -> down = value
                2 -> rate = value
                3 -> propertyTax = value
                else -> insurance = value
            }
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

        tvHome.setOnClickListener { focus = 0; refresh() }
        tvDown.setOnClickListener { focus = 1; refresh() }
        tvRate.setOnClickListener { focus = 2; refresh() }
        tvTax.setOnClickListener { focus = 3; refresh() }
        tvInsurance.setOnClickListener { focus = 4; refresh() }

        findViewById<View>(R.id.fieldDownType).setOnClickListener {
            openChoice(
                title = getString(R.string.down_payment),
                options = arrayOf("%", "$"),
                selected = if (downIsPercent) 0 else 1
            ) { which ->
                downIsPercent = which == 0
            }
        }

        findViewById<View>(R.id.fieldLoanTerm).setOnClickListener {
            val labels = termOptions.map { "$it Year" }.toTypedArray()
            val selected = termOptions.indexOf(years).coerceAtLeast(0)
            openChoice(getString(R.string.loan_term), labels, selected) { which ->
                years = termOptions[which]
            }
        }

        findViewById<View>(R.id.rowTaxesHeader).setOnClickListener {
            taxesExpanded = !taxesExpanded
            refresh()
        }

        val digitIds = listOf(
            R.id.key0 to '0', R.id.key1 to '1', R.id.key2 to '2', R.id.key3 to '3',
            R.id.key4 to '4', R.id.key5 to '5', R.id.key6 to '6',
            R.id.key7 to '7', R.id.key8 to '8', R.id.key9 to '9'
        )
        digitIds.forEach { (id, d) ->
            findViewById<TextView>(id).setOnClickListener {
                setCurrent(NumberInput.appendDigit(current(), d))
            }
        }
        findViewById<TextView>(R.id.keyDot).setOnClickListener {
            setCurrent(NumberInput.appendDot(current()))
        }
        findViewById<View>(R.id.keyBackspace).setOnClickListener {
            setCurrent(NumberInput.backspace(current()))
        }
        findViewById<TextView>(R.id.keyClear).setOnClickListener {
            setCurrent(NumberInput.clear())
        }
        findViewById<View>(R.id.keyReset).setOnClickListener {
            home = "0"
            down = "0"
            rate = "0"
            propertyTax = "0"
            insurance = "0"
            years = 30
            downIsPercent = true
            focus = 0
            refresh()
        }
        findViewById<TextView>(R.id.btnCalculate).setOnClickListener {
            compute()
            Toast.makeText(
                this,
                "Monthly: $${tvMonthly.text}\nTotal: $${tvTotal.text}",
                Toast.LENGTH_SHORT
            ).show()
        }

        refresh()
    }
}
