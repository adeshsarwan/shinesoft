package com.snapdrama.shortstream.activity.premium

import android.os.Bundle
import androidx.fragment.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.databinding.FragmentMemberBinding

class MemberFragment : Fragment() {
    lateinit var binding: FragmentMemberBinding
    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        binding = FragmentMemberBinding.inflate(layoutInflater, container, false)
        return binding.root
    }


}