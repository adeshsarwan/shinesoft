package com.calculatorlauncher.app.launcher

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.activity.result.contract.ActivityResultContracts
import androidx.fragment.app.Fragment
import com.calculatorlauncher.app.CalculatorScreenController
import com.calculatorlauncher.app.R
import com.calculatorlauncher.app.util.CalcHistoryStore

/**
 * ========== LAUNCHER_MODE_START ==========
 * Calculator home page inside the launcher ViewPager (page 0).
 * ========== LAUNCHER_MODE_END ==========
 */
class HomeFragment : Fragment() {

    private var screenController: CalculatorScreenController? = null

    private val historyLauncher = registerForActivityResult(
        ActivityResultContracts.StartActivityForResult()
    ) { result ->
        val value = result.data?.getStringExtra(CalcHistoryStore.EXTRA_USE_RESULT) ?: return@registerForActivityResult
        screenController?.onHistoryResult(value)
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View = inflater.inflate(R.layout.activity_main, container, false)

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        val activity = requireActivity() as androidx.appcompat.app.AppCompatActivity
        screenController = CalculatorScreenController(activity, view, historyLauncher).also { it.bind() }
    }

    fun handleBackPress(): Boolean = screenController?.handleBack() == true
}
