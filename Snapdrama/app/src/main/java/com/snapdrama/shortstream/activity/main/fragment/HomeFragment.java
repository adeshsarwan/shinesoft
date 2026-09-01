package com.snapdrama.shortstream.activity.main.fragment;

import static android.text.Selection.setSelection;

import android.content.Intent;
import android.graphics.Typeface;
import android.os.Bundle;

import androidx.core.content.ContextCompat;
import androidx.core.content.res.ResourcesCompat;
import androidx.fragment.app.Fragment;
import androidx.viewpager.widget.ViewPager;

import android.os.Handler;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.animation.Animation;
import android.view.animation.TranslateAnimation;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.premium.PremiumMemberActivity;
import com.snapdrama.shortstream.activity.search.SearchSeriesActivity;
import com.snapdrama.shortstream.databinding.FragmentHomeBinding;
import com.snapdrama.shortstream.activity.main.fragment.adapter.CategoryDraftAdapter;

public class HomeFragment extends Fragment {

    FragmentHomeBinding binding;

    private String[] suggestions;

//    private String[] suggestions = {
//            getString(R.string.suggestions1),getString(R.string.suggestions2), getString(R.string.suggestions3), getString(R.string.suggestions4),
//            getString(R.string.suggestions5),getString(R.string.suggestions6), getString(R.string.suggestions7),  getString(R.string.suggestions8)
//    };
    private int currentIndex = 0;
    private Handler handler = new Handler();
    private int delay = 2000;
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding = FragmentHomeBinding.inflate(inflater, container, false);
        suggestions = new String[]{
                getString(R.string.suggestions1),
                getString(R.string.suggestions2),
                getString(R.string.suggestions3),
                getString(R.string.suggestions4),
                getString(R.string.suggestions5),
                getString(R.string.suggestions6),
                getString(R.string.suggestions7),
                getString(R.string.suggestions8)
        };
        binding.buttonPremium.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(requireActivity(), PremiumMemberActivity.class);

                startActivity(intent);
            }
        });

        binding.buttonStrike.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Toast.makeText(requireActivity(), getString(R.string.coming_soon), Toast.LENGTH_SHORT).show();
            }
        });
        // Bottom banner: only show when after-login ads are enabled
        if (com.snapdrama.shortstream.ads.PremiumPlanManager.shouldSkipAfterLoginAd(requireContext())) {
            collapseHomeBottomAdSlot();
        } else {
            binding.SmallNative.setVisibility(View.VISIBLE);
        }
        CategoryDraftAdapter adapter = new CategoryDraftAdapter(getChildFragmentManager());
        binding.viewPagerHomeFrag.setAdapter(adapter);
        setCategory();
        startSuggestionAnimation();
        setupSearchClickListener();
        binding.viewPagerHomeFrag.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

            }

            @Override
            public void onPageSelected(int position) {
                if (position == 0) {
                    unselection();
                    selection(binding.imgView1, R.drawable.ic_tab_select);
                    scrollToCenter(binding.imgViewCategory1);
                } else if (position == 1) {
                    unselection();
                    selection(binding.imgView2, R.drawable.ic_tab_select);
                    scrollToCenter(binding.imgViewCategory2);
                } else if (position == 2) {
                    unselection();
                    selection(binding.imgView3, R.drawable.ic_tab_select);
                    scrollToCenter(binding.imgViewCategory3);
                } else if (position == 3) {
                    unselection();
                    selection(binding.imgView5, R.drawable.ic_tab_select);
                    scrollToCenter(binding.imgViewCategory5);
                }

            }

            @Override
            public void onPageScrollStateChanged(int state) {

            }
        });

        return binding.getRoot();
    }
    private void startSuggestionAnimation() {
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                showNextSuggestion();
                handler.postDelayed(this, delay);
            }
        }, delay);
    }

    private void showNextSuggestion() {

        if (!isAdded() || getActivity() == null) return;

        binding.suggestionContainer.removeAllViews();

        TextView tv = new TextView(getActivity());
        tv.setText(suggestions[currentIndex]);
        tv.setTextColor(ContextCompat.getColor(requireContext(), R.color.white));
        tv.setTextSize(14);

        Typeface typeface = ResourcesCompat.getFont(requireContext(), R.font.mulish_semibold);
        tv.setTypeface(typeface);
        tv.setGravity(Gravity.CENTER_VERTICAL);

        binding.suggestionContainer.addView(tv);

        Animation animation = new TranslateAnimation(
                0, 0, binding.suggestionContainer.getHeight(), 0
        );
        animation.setDuration(600);
        tv.startAnimation(animation);

        currentIndex++;
        if (currentIndex >= suggestions.length) currentIndex = 0;
    }
    private void setCategory() {
        binding.imgViewCategory1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                unselection();
                selection(binding.imgView1, R.drawable.ic_tab_select);
                binding.viewPagerHomeFrag.setCurrentItem(0);
            }
        });
        binding.imgViewCategory2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                unselection();
                selection(binding.imgView2, R.drawable.ic_tab_select);
                binding.viewPagerHomeFrag.setCurrentItem(1);

            }
        });
        binding.imgViewCategory3.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                unselection();
                selection(binding.imgView3, R.drawable.ic_tab_select);
                binding.viewPagerHomeFrag.setCurrentItem(2);

            }
        });
        binding.imgViewCategory5.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                unselection();
                selection(binding.imgView5, R.drawable.ic_tab_select);
                binding.viewPagerHomeFrag.setCurrentItem(3);

            }
        });

    }

    private void selection(ImageView imageView, int imageInt) {
        imageView.setImageDrawable(getResources().getDrawable(imageInt));

    }

    private void unselection() {
        binding.imgView1.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_unselect));
        binding.imgView2.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_unselect));
        binding.imgView3.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_unselect));
        binding.imgView5.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_unselect));

    }


    private void setupSearchClickListener() {
        binding.editSearchScreen.setFocusable(false);
        binding.editSearchScreen.setClickable(true);
        
        binding.editSearchScreen.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (getActivity() != null) {
                    Intent intent = new Intent(getActivity(), SearchSeriesActivity.class);
                    startActivity(intent);
                }
            }
        });
    }

    /** Hide bottom banner and let content fill down to bottom nav (no empty black strip). */
    private void collapseHomeBottomAdSlot() {
        binding.SmallNative.setVisibility(View.GONE);
        ViewGroup.LayoutParams slotLp = binding.SmallNative.getLayoutParams();
        if (slotLp != null) {
            slotLp.height = 0;
            binding.SmallNative.setLayoutParams(slotLp);
        }
        ViewGroup.LayoutParams contentLp = binding.homeContentContainer.getLayoutParams();
        if (contentLp instanceof android.widget.RelativeLayout.LayoutParams) {
            android.widget.RelativeLayout.LayoutParams rp =
                    (android.widget.RelativeLayout.LayoutParams) contentLp;
            rp.removeRule(android.widget.RelativeLayout.ABOVE);
            rp.addRule(android.widget.RelativeLayout.ALIGN_PARENT_BOTTOM);
            rp.height = ViewGroup.LayoutParams.MATCH_PARENT;
            binding.homeContentContainer.setLayoutParams(rp);
        }
    }

    private void scrollToCenter(final View view) {
        binding.horizontalScrollView.post(new Runnable() {
            @Override
            public void run() {
                int scrollX = (view.getLeft() + (view.getWidth() / 2)) - (binding.horizontalScrollView.getWidth() / 2);
                binding.horizontalScrollView.smoothScrollTo(scrollX, 0);
            }
        });
    }

}