package com.calculatorlauncher.app.util

import java.util.Locale
import kotlin.math.abs
import kotlin.math.pow

object NumberInput {

    fun appendDigit(current: String, digit: Char, maxLen: Int = 12): String {
        val base = if (current == "0" || current == "0.00" || current == "0.0") "" else current
        if (base.replace(".", "").replace("-", "").length >= maxLen) return current
        return base + digit
    }

    fun appendDot(current: String): String {
        val value = if (current.isBlank() || current == "0.00") "0" else current
        return if (value.contains('.')) value else "$value."
    }

    fun backspace(current: String): String {
        if (current.isEmpty() || current == "0" || current == "0.00") return "0"
        val next = current.dropLast(1)
        return if (next.isEmpty() || next == "-") "0" else next
    }

    fun clear(): String = "0"

    fun toggleSign(current: String): String {
        if (current == "0" || current == "0.00") return current
        return if (current.startsWith("-")) current.removePrefix("-") else "-$current"
    }

    fun toDouble(value: String): Double {
        return value.replace("%", "").toDoubleOrNull() ?: 0.0
    }

    fun money(value: Double): String {
        return String.format(Locale.US, "%.2f", value)
    }

    fun smart(value: Double): String {
        return if (abs(value % 1.0) < 0.0000001) {
            String.format(Locale.US, "%.0f", value)
        } else {
            String.format(Locale.US, "%.2f", value)
        }
    }

    fun percent(value: Double): String = "${money(value)}%"
}

object FinanceMath {
    fun tip(bill: Double, tipPercent: Double, split: Int): Triple<Double, Double, Double> {
        val tip = bill * tipPercent / 100.0
        val total = bill + tip
        val people = split.coerceAtLeast(1)
        return Triple(tip, total, total / people)
    }

    fun loanPayment(principal: Double, annualRate: Double, months: Int): Pair<Double, Double> {
        if (principal <= 0 || months <= 0) return 0.0 to 0.0
        val r = annualRate / 100.0 / 12.0
        val payment = if (r == 0.0) {
            principal / months
        } else {
            principal * r * (1 + r).pow(months) / ((1 + r).pow(months) - 1)
        }
        return payment to payment * months
    }

    fun compound(principal: Double, annualRate: Double, years: Double, n: Int): Pair<Double, Double> {
        if (principal <= 0 || years <= 0) return 0.0 to 0.0
        val finalValue = principal * (1 + annualRate / 100.0 / n).pow(n * years)
        return finalValue to (finalValue - principal)
    }

    fun bmiImperial(feet: Int, inches: Int, pounds: Double): Double {
        val totalInches = feet * 12 + inches
        if (totalInches <= 0 || pounds <= 0) return 0.0
        return 703.0 * pounds / (totalInches * totalInches)
    }

    fun bmiMetric(cm: Double, kg: Double): Double {
        if (cm <= 0 || kg <= 0) return 0.0
        val meters = cm / 100.0
        return kg / (meters * meters)
    }
}

/** Unit relative to category base. [toBase] multiplies input to convert into the base unit. */
data class UnitDef(val label: String, val toBase: Double)

object UnitData {

    /** Units per category. Conversion goes through a shared base unit. */
    val unitsByCategory: Map<String, List<UnitDef>> = linkedMapOf(
        "Area" to listOf(
            UnitDef("Square meters (m²)", 1.0),
            UnitDef("Square kilometers (km²)", 1_000_000.0),
            UnitDef("Square centimeters (cm²)", 0.0001),
            UnitDef("Square feet (ft²)", 0.092903),
            UnitDef("Square inches (in²)", 0.00064516),
            UnitDef("Acres (ac)", 4046.86),
            UnitDef("Hectares (ha)", 10_000.0)
        ),
        "Length" to listOf(
            UnitDef("Meters (m)", 1.0),
            UnitDef("Kilometers (km)", 1000.0),
            UnitDef("Centimeters (cm)", 0.01),
            UnitDef("Millimeters (mm)", 0.001),
            UnitDef("Inches (in)", 0.0254),
            UnitDef("Feet (ft)", 0.3048),
            UnitDef("Yards (yd)", 0.9144),
            UnitDef("Miles (mi)", 1609.344)
        ),
        "Temperature" to listOf(
            UnitDef("Celsius (°C)", Double.NaN),
            UnitDef("Fahrenheit (°F)", Double.NaN),
            UnitDef("Kelvin (K)", Double.NaN)
        ),
        "Volume" to listOf(
            UnitDef("Litres (l)", 1.0),
            UnitDef("Millilitres (ml)", 0.001),
            UnitDef("US Gallon (gal)", 3.78541),
            UnitDef("US Quart (qt)", 0.946353),
            UnitDef("US Cup (cup)", 0.236588),
            UnitDef("Cubic meters (m³)", 1000.0),
            UnitDef("Cubic feet (ft³)", 28.3168)
        ),
        "Mass" to listOf(
            UnitDef("Kilogrammes (kg)", 1.0),
            UnitDef("Grams (g)", 0.001),
            UnitDef("Milligrams (mg)", 0.000001),
            UnitDef("Pounds (lb)", 0.453592),
            UnitDef("Ounces (oz)", 0.0283495),
            UnitDef("Tons (t)", 1000.0)
        ),
        "Data" to listOf(
            UnitDef("Bytes (B)", 1.0),
            UnitDef("Kilobytes (KB)", 1024.0),
            UnitDef("Megabytes (MB)", 1024.0 * 1024.0),
            UnitDef("Gigabytes (GB)", 1024.0 * 1024.0 * 1024.0),
            UnitDef("Terabytes (TB)", 1024.0 * 1024.0 * 1024.0 * 1024.0)
        ),
        "Speed" to listOf(
            UnitDef("Meters per second (m/s)", 1.0),
            UnitDef("Kilometers per hour (km/h)", 1.0 / 3.6),
            UnitDef("Miles per hour (mph)", 0.44704),
            UnitDef("Feet per second (ft/s)", 0.3048),
            UnitDef("Inches per second (in/s)", 0.0254),
            UnitDef("Knots (kn)", 0.514444)
        ),
        "Time" to listOf(
            UnitDef("Seconds (s)", 1.0),
            UnitDef("Milliseconds (ms)", 0.001),
            UnitDef("Minutes (min)", 60.0),
            UnitDef("Hours (h)", 3600.0),
            UnitDef("Days (d)", 86400.0),
            UnitDef("Weeks (wk)", 604800.0)
        )
    )

    /** Default from/to indexes matching previous fixed pairs. */
    fun defaultIndexes(category: String): Pair<Int, Int> = when (category) {
        "Area" -> 5 to 0          // Acres → m²
        "Length" -> 4 to 2        // Inches → cm
        "Temperature" -> 1 to 0   // Fahrenheit → Celsius
        "Volume" -> 2 to 0        // US Gallon → Litres
        "Mass" -> 3 to 0          // Pounds → kg
        "Data" -> 1 to 2          // KB → MB
        "Speed" -> 0 to 4         // m/s → in/s
        "Time" -> 0 to 3          // Seconds → Hours
        else -> 0 to 1
    }

    fun units(category: String): List<UnitDef> =
        unitsByCategory[category] ?: emptyList()

    fun labels(category: String): Array<String> =
        units(category).map { it.label }.toTypedArray()

    fun convert(category: String, value: Double, fromIndex: Int, toIndex: Int): Double {
        val list = units(category)
        if (list.isEmpty()) return value
        val from = list.getOrElse(fromIndex) { list.first() }
        val to = list.getOrElse(toIndex) { list.last() }
        if (category == "Temperature") {
            val celsius = toCelsius(value, from.label)
            return fromCelsius(celsius, to.label)
        }
        val base = value * from.toBase
        return if (to.toBase == 0.0) 0.0 else base / to.toBase
    }

    private fun toCelsius(value: Double, label: String): Double = when {
        label.startsWith("Fahrenheit") -> (value - 32.0) * 5.0 / 9.0
        label.startsWith("Kelvin") -> value - 273.15
        else -> value
    }

    private fun fromCelsius(celsius: Double, label: String): Double = when {
        label.startsWith("Fahrenheit") -> celsius * 9.0 / 5.0 + 32.0
        label.startsWith("Kelvin") -> celsius + 273.15
        else -> celsius
    }
}
