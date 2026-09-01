package com.snapdrama.shortstream.activity.premium

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.viewpager2.widget.ViewPager2
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.adapter.PremiumPagerAdapter
import com.snapdrama.shortstream.databinding.ActivityPremiumBinding

class PremiumActivity : BaseOtherActivity() {
    lateinit var binding: ActivityPremiumBinding
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityPremiumBinding.inflate(layoutInflater)
        setContentView(binding.root)
        val adapter = PremiumPagerAdapter(this)
        binding.viewPagerPremium.adapter = adapter
        binding.buttonRewardCoins.setOnClickListener {
            binding.viewPagerPremium.currentItem = 0
        }
        binding.buttonMemberCoins.setOnClickListener {
            binding.viewPagerPremium.currentItem = 1
        }

        binding.viewPagerPremium.registerOnPageChangeCallback(object :
            ViewPager2.OnPageChangeCallback() {
            override fun onPageSelected(position: Int) {
                super.onPageSelected(position)
                updateButtonUI(position)
            }
        })
    }

    private fun updateButtonUI(position: Int) {
        if (position == 0) {
            binding.buttonRewardCoins.setBackgroundResource(R.drawable.background_login_button)
            binding.buttonMemberCoins.setBackgroundResource(R.drawable.background_selection_premium)

        } else {

            binding.buttonMemberCoins.setBackgroundResource(R.drawable.background_login_button)
            binding.buttonRewardCoins.setBackgroundResource(R.drawable.background_selection_premium)


        }
    }
}