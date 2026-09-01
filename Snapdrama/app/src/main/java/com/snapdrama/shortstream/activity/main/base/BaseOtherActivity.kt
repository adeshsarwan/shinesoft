package com.snapdrama.shortstream.activity.main.base

import android.annotation.SuppressLint
import android.os.Bundle
import android.view.View
import android.view.ViewGroup
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.ViewCompat
import androidx.core.view.WindowCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updatePadding
import com.snapdrama.shortstream.applicationPreference.ControlPreference

open class BaseOtherActivity : AppCompatActivity() {

    internal var lastLanguage: String = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        lastLanguage = ControlPreference.getAppLanguage()
    }

    override fun setContentView(layoutResID: Int) {
        super.setContentView(layoutResID)
        applySystemBarInsets()
    }

    override fun setContentView(view: View?) {
        super.setContentView(view)
        applySystemBarInsets()
    }

    override fun setContentView(view: View?, params: ViewGroup.LayoutParams?) {
        super.setContentView(view, params)
        applySystemBarInsets()
    }

    override fun onContentChanged() {
        super.onContentChanged()
        wireBackButton()
    }

    private fun wireBackButton() {
        val root = findViewById<ViewGroup?>(android.R.id.content) ?: return
        val backButton = root.findViewById<View?>(com.snapdrama.shortstream.R.id.btnBack) ?: return
        backButton.setOnClickListener { finish() }
    }

    private fun applySystemBarInsets() {
        val content = findViewById<ViewGroup>(android.R.id.content) ?: return
        val root = content.getChildAt(0) ?: content
        ViewCompat.setOnApplyWindowInsetsListener(root) { v, insets ->
            val bars = insets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
            )
            var top = bars.top
            if (top == 0) {
                top = statusBarHeightPx()
            }
            v.updatePadding(
                left = bars.left,
                top = top,
                right = bars.right,
                bottom = bars.bottom
            )
            WindowInsetsCompat.CONSUMED
        }
        root.requestApplyInsets()
        ViewCompat.requestApplyInsets(root)
    }

    private fun statusBarHeightPx(): Int {
        val resId = resources.getIdentifier("status_bar_height", "dimen", "android")
        return if (resId > 0) resources.getDimensionPixelSize(resId) else 0
    }

    @SuppressLint("NewApi")
    override fun onResume() {
        if (ControlPreference.getAppLanguage() != lastLanguage) {
            recreate()
        }
        resetNavigationState()
        super.onResume()
    }

    private fun resetNavigationState() {
        runCatching {
            val field = javaClass.getDeclaredField("hasNavigated")
            field.isAccessible = true
            if (field.type == Boolean::class.javaPrimitiveType) {
                field.setBoolean(this, false)
            } else if (field.type == java.lang.Boolean::class.java) {
                field.set(this, false)
            }
        }
    }
}
