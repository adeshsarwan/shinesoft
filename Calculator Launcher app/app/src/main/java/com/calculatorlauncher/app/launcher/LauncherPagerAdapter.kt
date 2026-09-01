package com.calculatorlauncher.app.launcher

import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.viewpager2.adapter.FragmentStateAdapter

/**
 * ========== LAUNCHER_MODE_START ==========
 * Vertical pages: 0 = home, 1 = all apps (swipe up).
 * ========== LAUNCHER_MODE_END ==========
 */
class LauncherPagerAdapter(activity: FragmentActivity) : FragmentStateAdapter(activity) {
    override fun getItemCount(): Int = 2
    override fun createFragment(position: Int): Fragment = when (position) {
        0 -> HomeScreenFragment()
        else -> AppsFragment()
    }
}
