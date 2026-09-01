package com.snapdrama.shortstream.activity.main.fragment.new_fragment;

import android.os.Bundle;

import androidx.fragment.app.Fragment;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import com.snapdrama.shortstream.databinding.FragmentLiveNowBinding;



public class LiveNowFragment extends Fragment {

   FragmentLiveNowBinding binding;


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding =  FragmentLiveNowBinding.inflate(inflater, container, false);

        return binding.getRoot();

    }

}