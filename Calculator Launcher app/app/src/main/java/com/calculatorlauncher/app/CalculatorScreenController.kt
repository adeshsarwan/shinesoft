package com.calculatorlauncher.app

import android.content.Intent
import android.view.View
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import androidx.activity.result.ActivityResultLauncher
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.core.view.GravityCompat
import androidx.drawerlayout.widget.DrawerLayout
import com.calculatorlauncher.app.ui.BmiCalculatorActivity
import com.calculatorlauncher.app.ui.CompoundInterestActivity
import com.calculatorlauncher.app.ui.CurrencyConverterActivity
import com.calculatorlauncher.app.ui.HistoryActivity
import com.calculatorlauncher.app.ui.InfoActivity
import com.calculatorlauncher.app.ui.LoanCalculatorActivity
import com.calculatorlauncher.app.ui.MortgageCalculatorActivity
import com.calculatorlauncher.app.ui.TipCalculatorActivity
import com.calculatorlauncher.app.ui.UnitConverterActivity
import com.calculatorlauncher.app.util.CalcHistoryStore
import com.calculatorlauncher.app.util.NumberInput
import java.util.Locale
import kotlin.math.abs

/**
 * Shared calculator UI wiring used by MainActivity and launcher HomeFragment.
 */
class CalculatorScreenController(
    private val activity: AppCompatActivity,
    private val root: View,
    private val historyLauncher: ActivityResultLauncher<Intent>
) {
    private var expression = ""
    private var history = ""
    private var justEvaluated = false
    private lateinit var drawerLayout: DrawerLayout
    private lateinit var historyStore: CalcHistoryStore

    private var runningTotal = ""
    private var pendingOp = ""
    private var currentInput = ""
    private var showTotal = false
    private var refreshCalc: (() -> Unit)? = null

    fun bind() {
        historyStore = CalcHistoryStore(activity)
        setupDrawer()
        setupTabs()
        setupBasicCalculator()
        setupToolsGrid()
        root.findViewById<ImageButton>(R.id.btnHistory).setOnClickListener {
            historyLauncher.launch(Intent(activity, HistoryActivity::class.java))
        }
    }

    fun onHistoryResult(value: String) {
        runningTotal = value
        pendingOp = ""
        currentInput = ""
        showTotal = true
        justEvaluated = true
        history = value
        expression = value
        refreshCalc?.invoke()
    }

    fun handleBack(): Boolean {
        if (::drawerLayout.isInitialized && drawerLayout.isDrawerOpen(GravityCompat.START)) {
            drawerLayout.closeDrawer(GravityCompat.START)
            return true
        }
        return false
    }

    private fun setupDrawer() {
        drawerLayout = root.findViewById(R.id.drawerLayout)
        root.findViewById<ImageButton>(R.id.btnMenu).setOnClickListener {
            drawerLayout.openDrawer(GravityCompat.START)
        }
        root.findViewById<TextView>(R.id.navAbout).setOnClickListener {
            openInfo(activity.getString(R.string.about_menu_about), activity.getString(R.string.about_content))
        }
        root.findViewById<TextView>(R.id.navHelp).setOnClickListener {
            openInfo(activity.getString(R.string.menu_help), activity.getString(R.string.help_content))
        }
        root.findViewById<TextView>(R.id.navRevert).setOnClickListener {
            drawerLayout.closeDrawer(GravityCompat.START)
            showRevertSheet()
        }
        root.findViewById<TextView>(R.id.navPrivacy).setOnClickListener {
            openInfo(activity.getString(R.string.menu_privacy), activity.getString(R.string.privacy_content))
        }
        root.findViewById<TextView>(R.id.navTerms).setOnClickListener {
            openInfo(activity.getString(R.string.settings_terms), activity.getString(R.string.terms_content))
        }
        root.findViewById<TextView>(R.id.navDoNotSell).setOnClickListener {
            openInfo(activity.getString(R.string.about_do_not_sell), activity.getString(R.string.do_not_sell_content))
        }
    }

    private fun showRevertSheet() {
        val sheet = com.google.android.material.bottomsheet.BottomSheetDialog(activity)
        val view = activity.layoutInflater.inflate(R.layout.bottom_sheet_revert, null)
        sheet.setContentView(view)
        view.findViewById<View>(R.id.btnConfirmRevert).setOnClickListener {
            sheet.dismiss()
            com.calculatorlauncher.app.launcher.SetDefaultLauncherHelper.openDefaultLauncherSettings(activity)
        }
        view.findViewById<View>(R.id.btnKeepHome).setOnClickListener { sheet.dismiss() }
        sheet.show()
    }

    private fun openInfo(title: String, content: String) {
        drawerLayout.closeDrawer(GravityCompat.START)
        activity.startActivity(
            Intent(activity, InfoActivity::class.java)
                .putExtra(InfoActivity.EXTRA_TITLE, title)
                .putExtra(InfoActivity.EXTRA_CONTENT, content)
        )
    }

    private fun setupTabs() {
        val panelBasic = root.findViewById<View>(R.id.panelBasic)
        val panelCalculators = root.findViewById<View>(R.id.panelCalculators)
        val tabBasic = root.findViewById<LinearLayout>(R.id.tabBasic)
        val tabCalculators = root.findViewById<LinearLayout>(R.id.tabCalculators)
        val labelBasic = root.findViewById<TextView>(R.id.labelBasic)
        val labelCalculators = root.findViewById<TextView>(R.id.labelCalculators)
        val iconBasic = root.findViewById<ImageView>(R.id.iconBasic)
        val iconCalculators = root.findViewById<ImageView>(R.id.iconCalculators)

        fun showBasic() {
            panelBasic.visibility = View.VISIBLE
            panelCalculators.visibility = View.GONE
            tabBasic.setBackgroundResource(R.drawable.bg_nav_pill)
            tabCalculators.background = null
            labelBasic.setTextColor(ContextCompat.getColor(activity, R.color.text_primary))
            labelCalculators.setTextColor(ContextCompat.getColor(activity, R.color.text_secondary))
            iconBasic.setColorFilter(ContextCompat.getColor(activity, R.color.text_primary))
            iconCalculators.setColorFilter(ContextCompat.getColor(activity, R.color.text_secondary))
        }

        fun showCalculators() {
            panelBasic.visibility = View.GONE
            panelCalculators.visibility = View.VISIBLE
            tabCalculators.setBackgroundResource(R.drawable.bg_nav_pill)
            tabBasic.background = null
            labelCalculators.setTextColor(ContextCompat.getColor(activity, R.color.text_primary))
            labelBasic.setTextColor(ContextCompat.getColor(activity, R.color.text_secondary))
            iconCalculators.setColorFilter(ContextCompat.getColor(activity, R.color.text_primary))
            iconBasic.setColorFilter(ContextCompat.getColor(activity, R.color.text_secondary))
        }

        tabBasic.setOnClickListener { showBasic() }
        tabCalculators.setOnClickListener { showCalculators() }
        showBasic()
    }

    private fun setupBasicCalculator() {
        val tvExpression = root.findViewById<TextView>(R.id.tvExpression)
        val tvResult = root.findViewById<TextView>(R.id.tvResult)

        fun prettyOp(op: String): String = when (op) {
            "*" -> "×"
            "/" -> "÷"
            "-" -> "−"
            else -> op
        }

        fun refresh() {
            when {
                showTotal && pendingOp.isEmpty() && currentInput.isEmpty() -> {
                    tvExpression.text = history
                    tvResult.text = runningTotal
                }
                pendingOp.isNotEmpty() && currentInput.isEmpty() -> {
                    tvExpression.text = "${runningTotal}${prettyOp(pendingOp)}"
                    tvResult.text = runningTotal
                }
                pendingOp.isNotEmpty() -> {
                    tvExpression.text = "${runningTotal}${prettyOp(pendingOp)}$currentInput"
                    val live = evaluate("$runningTotal$pendingOp$currentInput")
                    tvResult.text = live?.let { formatResult(it) } ?: currentInput
                }
                else -> {
                    tvExpression.text = history
                    tvResult.text = currentInput.ifEmpty { runningTotal.ifEmpty { "" } }
                }
            }
        }
        refreshCalc = { refresh() }

        fun saveHistory(expr: String, result: String) {
            historyStore.add(expr, result)
        }

        fun applyPending() {
            if (runningTotal.isNotEmpty() && pendingOp.isNotEmpty() && currentInput.isNotEmpty()) {
                val expr = "${runningTotal}${prettyOp(pendingOp)}$currentInput"
                val result = evaluate("$runningTotal$pendingOp$currentInput") ?: return
                history = expr
                runningTotal = formatResult(result)
                pendingOp = ""
                currentInput = ""
                showTotal = true
                saveHistory(expr, runningTotal)
            } else if (currentInput.isNotEmpty() && runningTotal.isEmpty()) {
                runningTotal = currentInput
                currentInput = ""
                showTotal = true
            }
        }

        fun onDigit(digit: String) {
            if (showTotal && pendingOp.isEmpty()) {
                runningTotal = ""
                history = ""
                currentInput = digit
                showTotal = false
            } else {
                showTotal = false
                if (currentInput == "0") currentInput = digit else currentInput += digit
            }
            refresh()
        }

        fun onDot() {
            if (showTotal && pendingOp.isEmpty()) {
                runningTotal = ""
                history = ""
                currentInput = "0."
                showTotal = false
            } else if (!currentInput.contains('.')) {
                showTotal = false
                currentInput = if (currentInput.isEmpty()) "0." else "$currentInput."
            }
            refresh()
        }

        fun onOperator(op: String) {
            when {
                pendingOp.isNotEmpty() && currentInput.isEmpty() -> pendingOp = op
                currentInput.isNotEmpty() -> {
                    if (runningTotal.isEmpty()) {
                        runningTotal = currentInput
                    } else if (pendingOp.isNotEmpty()) {
                        val expr = "${runningTotal}${prettyOp(pendingOp)}$currentInput"
                        val result = evaluate("$runningTotal$pendingOp$currentInput") ?: return
                        history = expr
                        runningTotal = formatResult(result)
                        saveHistory(expr, runningTotal)
                    }
                    currentInput = ""
                    pendingOp = op
                    showTotal = false
                }
                runningTotal.isNotEmpty() -> {
                    pendingOp = op
                    showTotal = false
                }
            }
            refresh()
        }

        mapOf(
            R.id.btn0 to "0", R.id.btn1 to "1", R.id.btn2 to "2", R.id.btn3 to "3",
            R.id.btn4 to "4", R.id.btn5 to "5", R.id.btn6 to "6",
            R.id.btn7 to "7", R.id.btn8 to "8", R.id.btn9 to "9"
        ).forEach { (id, digit) ->
            root.findViewById<View>(id).setOnClickListener { onDigit(digit) }
        }
        root.findViewById<View>(R.id.btnDot).setOnClickListener { onDot() }
        root.findViewById<View>(R.id.btnPlus).setOnClickListener { onOperator("+") }
        root.findViewById<View>(R.id.btnMinus).setOnClickListener { onOperator("-") }
        root.findViewById<View>(R.id.btnMultiply).setOnClickListener { onOperator("*") }
        root.findViewById<View>(R.id.btnDivide).setOnClickListener { onOperator("/") }
        root.findViewById<View>(R.id.btnPercent).setOnClickListener {
            val base = when {
                currentInput.isNotEmpty() -> currentInput
                runningTotal.isNotEmpty() -> runningTotal
                else -> return@setOnClickListener
            }
            val value = (base.toDoubleOrNull() ?: return@setOnClickListener) / 100.0
            if (currentInput.isNotEmpty()) {
                currentInput = formatResult(value)
            } else {
                runningTotal = formatResult(value)
                showTotal = true
            }
            refresh()
        }
        root.findViewById<View>(R.id.btnClear).setOnClickListener {
            expression = ""
            history = ""
            runningTotal = ""
            pendingOp = ""
            currentInput = ""
            showTotal = false
            justEvaluated = false
            tvExpression.text = ""
            tvResult.text = ""
        }
        root.findViewById<View>(R.id.btnBackspace).setOnClickListener {
            when {
                currentInput.isNotEmpty() -> {
                    currentInput = currentInput.dropLast(1)
                    refresh()
                }
                pendingOp.isNotEmpty() -> {
                    pendingOp = ""
                    showTotal = true
                    refresh()
                }
            }
        }
        root.findViewById<View>(R.id.btnParen).setOnClickListener { }
        root.findViewById<View>(R.id.btnEquals).setOnClickListener {
            applyPending()
            pendingOp = ""
            currentInput = ""
            showTotal = true
            justEvaluated = true
            expression = runningTotal
            refresh()
        }
    }

    private fun setupToolsGrid() {
        bindTool(R.id.cardTip, R.string.tool_tip, R.drawable.ic_tool_tip, TipCalculatorActivity::class.java)
        bindTool(R.id.cardUnit, R.string.tool_unit, R.drawable.ic_tool_unit, UnitConverterActivity::class.java)
        bindTool(R.id.cardBmi, R.string.tool_bmi, R.drawable.ic_tool_bmi, BmiCalculatorActivity::class.java)
        bindTool(R.id.cardMortgage, R.string.tool_mortgage, R.drawable.ic_tool_mortgage, MortgageCalculatorActivity::class.java)
        bindTool(R.id.cardLoan, R.string.tool_loan, R.drawable.ic_tool_loan, LoanCalculatorActivity::class.java)
        bindTool(R.id.cardCompound, R.string.tool_compound, R.drawable.ic_tool_compound, CompoundInterestActivity::class.java)
        bindTool(R.id.cardCurrency, R.string.tool_currency, R.drawable.ic_tool_currency, CurrencyConverterActivity::class.java)
    }

    private fun bindTool(cardId: Int, title: Int, icon: Int, destination: Class<*>) {
        val card = root.findViewById<View>(cardId)
        card.findViewById<TextView>(R.id.toolTitle).setText(title)
        card.findViewById<ImageView>(R.id.toolIcon).setImageResource(icon)
        card.setOnClickListener { activity.startActivity(Intent(activity, destination)) }
    }

    private fun evaluate(raw: String): Double? {
        if (raw.isBlank()) return null
        return try {
            val expr = raw.replace("%", "/100")
            evalRpn(toRpn(tokenize(expr)))
        } catch (_: Exception) {
            null
        }
    }

    private fun tokenize(expr: String): List<String> {
        val out = mutableListOf<String>()
        var i = 0
        while (i < expr.length) {
            val c = expr[i]
            when {
                c.isDigit() || c == '.' -> {
                    var j = i + 1
                    while (j < expr.length && (expr[j].isDigit() || expr[j] == '.')) j++
                    out += expr.substring(i, j)
                    i = j
                }
                c == '+' || c == '*' || c == '/' || c == '(' || c == ')' -> {
                    out += c.toString()
                    i++
                }
                c == '-' -> {
                    val prev = out.lastOrNull()
                    if (prev == null || prev in listOf("+", "-", "*", "/", "(")) {
                        var j = i + 1
                        while (j < expr.length && (expr[j].isDigit() || expr[j] == '.')) j++
                        out += expr.substring(i, j)
                        i = j
                    } else {
                        out += "-"
                        i++
                    }
                }
                else -> i++
            }
        }
        return out
    }

    private fun toRpn(tokens: List<String>): List<String> {
        val output = mutableListOf<String>()
        val stack = ArrayDeque<String>()
        val precedence = mapOf("+" to 1, "-" to 1, "*" to 2, "/" to 2)
        tokens.forEach { token ->
            when {
                token.toDoubleOrNull() != null -> output += token
                token in precedence -> {
                    while (stack.isNotEmpty() && stack.last() in precedence &&
                        (precedence[stack.last()] ?: 0) >= (precedence[token] ?: 0)
                    ) {
                        output += stack.removeLast()
                    }
                    stack.addLast(token)
                }
                token == "(" -> stack.addLast(token)
                token == ")" -> {
                    while (stack.isNotEmpty() && stack.last() != "(") {
                        output += stack.removeLast()
                    }
                    if (stack.isNotEmpty() && stack.last() == "(") stack.removeLast()
                }
            }
        }
        while (stack.isNotEmpty()) output += stack.removeLast()
        return output
    }

    private fun evalRpn(tokens: List<String>): Double {
        val stack = ArrayDeque<Double>()
        tokens.forEach { token ->
            val num = token.toDoubleOrNull()
            if (num != null) {
                stack.addLast(num)
            } else {
                val b = stack.removeLast()
                val a = stack.removeLast()
                stack.addLast(
                    when (token) {
                        "+" -> a + b
                        "-" -> a - b
                        "*" -> a * b
                        "/" -> a / b
                        else -> error("bad op")
                    }
                )
            }
        }
        return stack.last()
    }

    private fun formatResult(value: Double): String {
        return if (abs(value % 1.0) < 1e-9) {
            String.format(Locale.US, "%.0f", value)
        } else {
            NumberInput.money(value)
        }
    }
}
