package com.calculatorlauncher.app.util

import android.view.View
import android.widget.TextView
import com.calculatorlauncher.app.R

class KeypadBinder(
    root: View,
    private val onDigit: (Char) -> Unit,
    private val onDot: () -> Unit,
    private val onBackspace: () -> Unit,
    private val onClear: () -> Unit,
    private val onSign: (() -> Unit)? = null,
    private val onUp: (() -> Unit)? = null,
    private val onDown: (() -> Unit)? = null
) {
    init {
        val digits = listOf(
            R.id.key0 to '0',
            R.id.key1 to '1',
            R.id.key2 to '2',
            R.id.key3 to '3',
            R.id.key4 to '4',
            R.id.key5 to '5',
            R.id.key6 to '6',
            R.id.key7 to '7',
            R.id.key8 to '8',
            R.id.key9 to '9'
        )
        digits.forEach { (id, digit) ->
            root.findViewById<TextView?>(id)?.setOnClickListener { onDigit(digit) }
        }
        root.findViewById<View?>(R.id.keyDot)?.setOnClickListener { onDot() }
        root.findViewById<View?>(R.id.keyBackspace)?.setOnClickListener { onBackspace() }
        root.findViewById<View?>(R.id.keyClear)?.setOnClickListener { onClear() }
        root.findViewById<View?>(R.id.keySign)?.setOnClickListener { onSign?.invoke() }
        root.findViewById<View?>(R.id.keyUp)?.setOnClickListener { onUp?.invoke() }
        root.findViewById<View?>(R.id.keyDown)?.setOnClickListener { onDown?.invoke() }
    }
}
