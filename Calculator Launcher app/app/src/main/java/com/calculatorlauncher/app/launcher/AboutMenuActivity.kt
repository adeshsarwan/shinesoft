package com.calculatorlauncher.app.launcher

import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.appcompat.app.AppCompatActivity
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.ui.InfoActivity
import com.google.android.material.bottomsheet.BottomSheetDialog

/**
 * ========== LAUNCHER_MODE_START ==========
 * About / Help / Revert side-menu style screen.
 * ========== LAUNCHER_MODE_END ==========
 */
class AboutMenuActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_about_menu)

        findViewById<View>(R.id.btnAboutBack).setOnClickListener { finish() }
        findViewById<View>(R.id.rowAboutApp).setOnClickListener {
            openInfo(getString(R.string.about_menu_about), getString(R.string.about_content))
        }
        findViewById<View>(R.id.rowAboutHelp).setOnClickListener {
            openInfo(getString(R.string.menu_help), getString(R.string.help_content))
        }
        findViewById<View>(R.id.rowRevert).setOnClickListener { showRevertSheet() }
        findViewById<View>(R.id.linkPrivacy).setOnClickListener {
            openInfo(getString(R.string.menu_privacy), getString(R.string.privacy_content))
        }
        findViewById<View>(R.id.linkTerms).setOnClickListener {
            openInfo(getString(R.string.settings_terms), getString(R.string.terms_content))
        }
        findViewById<View>(R.id.linkDoNotSell).setOnClickListener {
            openInfo(getString(R.string.about_do_not_sell), getString(R.string.do_not_sell_content))
        }
    }

    private fun showRevertSheet() {
        val sheet = BottomSheetDialog(this)
        val view = layoutInflater.inflate(R.layout.bottom_sheet_revert, null)
        sheet.setContentView(view)
        view.findViewById<View>(R.id.btnConfirmRevert).setOnClickListener {
            sheet.dismiss()
            SetDefaultLauncherHelper.openDefaultLauncherSettings(this)
        }
        view.findViewById<View>(R.id.btnKeepHome).setOnClickListener { sheet.dismiss() }
        sheet.show()
    }

    private fun openInfo(title: String, content: String) {
        startActivity(
            Intent(this, InfoActivity::class.java)
                .putExtra(InfoActivity.EXTRA_TITLE, title)
                .putExtra(InfoActivity.EXTRA_CONTENT, content)
        )
    }
}
