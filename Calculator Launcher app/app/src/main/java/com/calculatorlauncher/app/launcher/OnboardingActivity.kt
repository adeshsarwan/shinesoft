package com.calculatorlauncher.app.launcher

import android.content.Intent
import android.os.Bundle
import android.view.View
import androidx.activity.result.contract.ActivityResultContracts
import androidx.appcompat.app.AppCompatActivity
import com.calculatorlauncher.app.R

/**
 * ========== LAUNCHER_MODE_START ==========
 * First-open flow:
 * 1) Calculate Anything intro
 * 2) Default home app intro → system picker
 * 3) If Not now / not selected → last guide page → Got it
 * ========== LAUNCHER_MODE_END ==========
 */
class OnboardingActivity : AppCompatActivity() {

    private lateinit var pageIntro: View
    private lateinit var pageDefaultIntro: View
    private lateinit var pageLast: View
    private var waitingForHomePick = false

    private val homeRoleLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) {
        waitingForHomePick = false
        handleHomePickResult()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_onboarding)

        pageIntro = findViewById(R.id.pageIntro)
        pageDefaultIntro = findViewById(R.id.pageDefaultIntro)
        pageLast = findViewById(R.id.pageLast)

        findViewById<View>(R.id.btnIntroContinue).setOnClickListener { showPage(1) }

        findViewById<View>(R.id.btnDefaultContinue).setOnClickListener {
            waitingForHomePick = true
            // Opens phone system "Default home app" / role picker
            SetDefaultLauncherHelper.openDefaultLauncherSettings(this, homeRoleLauncher)
        }
        findViewById<View>(R.id.btnDefaultNotNow).setOnClickListener { showPage(2) }

        findViewById<View>(R.id.btnRevertHome).setOnClickListener {
            waitingForHomePick = true
            SetDefaultLauncherHelper.openDefaultLauncherSettings(this, homeRoleLauncher)
        }
        findViewById<View>(R.id.btnGotIt).setOnClickListener { finishOnboarding() }

        showPage(0)
    }

    override fun onResume() {
        super.onResume()
        if (waitingForHomePick) {
            waitingForHomePick = false
            handleHomePickResult()
        }
    }

    private fun handleHomePickResult() {
        if (SetDefaultLauncherHelper.isDefaultLauncher(this)) {
            finishOnboarding()
        } else {
            showPage(2)
        }
    }

    private fun showPage(index: Int) {
        pageIntro.visibility = if (index == 0) View.VISIBLE else View.GONE
        pageDefaultIntro.visibility = if (index == 1) View.VISIBLE else View.GONE
        pageLast.visibility = if (index == 2) View.VISIBLE else View.GONE
    }

    private fun finishOnboarding() {
        OnboardingPrefs.markDone(this)
        startActivity(
            Intent(this, LauncherHomeActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK)
        )
        finish()
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        when {
            pageLast.visibility == View.VISIBLE -> showPage(1)
            pageDefaultIntro.visibility == View.VISIBLE -> showPage(0)
            else -> {
                @Suppress("DEPRECATION")
                super.onBackPressed()
            }
        }
    }
}
