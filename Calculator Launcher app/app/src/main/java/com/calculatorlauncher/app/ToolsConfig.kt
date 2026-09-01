package com.calculatorlauncher.app

/**
 * ============================================================
 * CALCULATOR TOOLS TOGGLE — Calculators tab (Tip, BMI, Loan, etc.)
 * ============================================================
 *
 * Design (grid icons) always shows on the Calculators tab.
 *
 * To turn tool screens OFF (design only, no navigation):
 *   1. Keep [ENABLE_CALCULATOR_TOOLS] = false below
 *   2. Keep CALCULATOR_TOOLS blocks commented in CalculatorScreenController.kt
 *   3. Keep CALCULATOR_TOOLS block commented in AndroidManifest.xml
 *
 * To enable tool screens again:
 *   1. Set [ENABLE_CALCULATOR_TOOLS] = true
 *   2. Uncomment CALCULATOR_TOOLS blocks in CalculatorScreenController.kt
 *   3. Uncomment CALCULATOR_TOOLS block in AndroidManifest.xml
 *   4. Uncomment tool Activity imports at top of CalculatorScreenController.kt
 * ============================================================
 */
object ToolsConfig {

    /** false = grid design only; true = cards open Tip/Unit/BMI/etc. screens */
    const val ENABLE_CALCULATOR_TOOLS = true
}
