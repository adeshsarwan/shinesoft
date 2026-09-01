package com.calculatorlauncher.app.launcher

import android.content.Intent
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.WindowCompat
import androidx.viewpager2.widget.ViewPager2
import com.calculatorlauncher.app.R

/**
 * ========== LAUNCHER_MODE_START ==========
 * MI-style: system wallpaper home, swipe UP → all apps drawer page.
 * ========== LAUNCHER_MODE_END ==========
 */
class LauncherHomeActivity : AppCompatActivity() {

    private lateinit var viewPager: ViewPager2

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        setContentView(R.layout.activity_launcher_home)

        viewPager = findViewById(R.id.launcherPager)
        viewPager.orientation = ViewPager2.ORIENTATION_VERTICAL
        viewPager.adapter = LauncherPagerAdapter(this)
        viewPager.offscreenPageLimit = 1
        viewPager.isUserInputEnabled = true
    }

    fun openAppsDrawer() {
        viewPager.setCurrentItem(1, true)
    }

    fun closeAppsDrawer() {
        viewPager.setCurrentItem(0, true)
    }

    fun isAppsDrawerOpen(): Boolean = viewPager.currentItem == 1

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        closeAppsDrawer()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        if (viewPager.currentItem == 1) {
            closeAppsDrawer()
            return
        }
    }
}
