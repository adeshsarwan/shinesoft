package com.calculatorlauncher.app.launcher

import android.animation.ObjectAnimator
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.animation.DecelerateInterpolator
import android.widget.ProgressBar
import androidx.appcompat.app.AppCompatActivity
import com.calculatorlauncher.app.LauncherConfig
import com.calculatorlauncher.app.MainActivity
import com.calculatorlauncher.app.R

/**
 * ========== LAUNCHER_MODE_START ==========
 * Loading splash → first-time onboarding OR launcher home.
 * ========== LAUNCHER_MODE_END ==========
 */
class SplashActivity : AppCompatActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_splash)

        val progress = findViewById<ProgressBar>(R.id.splashProgress)
        progress.max = 100
        ObjectAnimator.ofInt(progress, "progress", 0, 100).apply {
            duration = LauncherConfig.SPLASH_DELAY_MS
            interpolator = DecelerateInterpolator()
            start()
        }

        Handler(Looper.getMainLooper()).postDelayed({
            routeNext()
        }, LauncherConfig.SPLASH_DELAY_MS)
    }

    private fun routeNext() {
        val next = when {
            !LauncherConfig.ENABLE_LAUNCHER_MODE -> MainActivity::class.java
            !OnboardingPrefs.isDone(this) -> OnboardingActivity::class.java
            else -> LauncherHomeActivity::class.java
        }
        startActivity(Intent(this, next))
        finish()
    }
}
