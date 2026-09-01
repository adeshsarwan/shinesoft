package com.snapdrama.shortstream.activity.main.fragment.rankingFragment;

import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.databinding.FragmentMostTredingBinding;


public class MostTredingFragment extends Fragment {

  FragmentMostTredingBinding binding;
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding =  FragmentMostTredingBinding.inflate(inflater, container, false);
        return binding.getRoot();
    }
}