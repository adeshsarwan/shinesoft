package com.calculatorlauncher.app.launcher

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.View
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.ui.InfoActivity

/**
 * ========== LAUNCHER_MODE_START ==========
 * Dark settings opened from Customize → Calculator Settings tile.
 * ========== LAUNCHER_MODE_END ==========
 */
class LauncherSettingsActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_launcher_settings)

        findViewById<View>(R.id.btnSettingsBack).setOnClickListener { finish() }
        findViewById<View>(R.id.rowWallpaper).setOnClickListener {
            startActivity(Intent(this, WallpaperDiscoverActivity::class.java))
        }
        findViewById<View>(R.id.rowSearchEngine).setOnClickListener {
            startActivity(Intent(this, SearchEngineActivity::class.java))
        }
        findViewById<View>(R.id.rowAboutUs).setOnClickListener {
            startActivity(Intent(this, AboutMenuActivity::class.java))
        }
        findViewById<View>(R.id.rowHelp).setOnClickListener {
            openInfo(getString(R.string.menu_help), getString(R.string.help_content))
        }
        findViewById<View>(R.id.rowWriteUs).setOnClickListener {
            val intent = Intent(Intent.ACTION_SENDTO, Uri.parse("mailto:support@calculatorlauncher.app"))
            try {
                startActivity(intent)
            } catch (_: Exception) {
                Toast.makeText(this, R.string.settings_no_email, Toast.LENGTH_SHORT).show()
            }
        }
        findViewById<View>(R.id.rowPrivacy).setOnClickListener {
            openInfo(getString(R.string.menu_privacy), getString(R.string.privacy_content))
        }
        findViewById<View>(R.id.rowTerms).setOnClickListener {
            openInfo(getString(R.string.settings_terms), getString(R.string.terms_content))
        }
    }

    private fun openInfo(title: String, content: String) {
        startActivity(
            Intent(this, InfoActivity::class.java)
                .putExtra(InfoActivity.EXTRA_TITLE, title)
                .putExtra(InfoActivity.EXTRA_CONTENT, content)
        )
    }
}
