package com.snapdrama.shortstream.adapter

import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import androidx.viewpager2.adapter.FragmentStateAdapter
import com.snapdrama.shortstream.activity.premium.MemberFragment
import com.snapdrama.shortstream.activity.premium.RewardFragment

class PremiumPagerAdapter(activity: FragmentActivity) :
    FragmentStateAdapter(activity) {

    override fun getItemCount(): Int = 2

    override fun createFragment(position: Int): Fragment {
        return when (position) {
            0 -> RewardFragment()
            else -> MemberFragment()
        }
    }
}