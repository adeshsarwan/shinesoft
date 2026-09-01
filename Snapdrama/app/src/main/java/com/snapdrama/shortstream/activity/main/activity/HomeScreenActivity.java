package com.snapdrama.shortstream.activity.main.activity;

import android.Manifest;
import android.app.Activity;
import android.app.Dialog;
import android.content.ComponentCallbacks;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.graphics.Insets;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.View;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.activity.OnBackPressedCallback;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.PagerSnapHelper;
import androidx.recyclerview.widget.RecyclerView;
import androidx.viewpager2.adapter.FragmentStateAdapter;
import androidx.viewpager2.widget.ViewPager2;

import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.databinding.ActivityHomeScreenActvityBinding;
import com.snapdrama.shortstream.engineBox.client.EngineClient;
import com.snapdrama.shortstream.engineBox.interfaces.EngineInterface;
import com.snapdrama.shortstream.engineBox.model.language.LanguageGetModel;
import com.snapdrama.shortstream.activity.main.fragment.HomeFragment;
import com.snapdrama.shortstream.activity.main.fragment.MyListFragment;
import com.snapdrama.shortstream.activity.main.fragment.ProfileFragment;
import com.snapdrama.shortstream.activity.main.fragment.ReelsFragment;
import com.snapdrama.shortstream.ads.GeneralAdsManager;
import com.snapdrama.shortstream.ads.PremiumPlanManager;

import java.util.ArrayList;

import retrofit2.Call;

public class HomeScreenActivity extends BaseOtherActivity implements MyListFragment.OnLoginSuccessListener {
    ActivityHomeScreenActvityBinding binding;
    private ArrayList<ComponentCallbacks> fragmentsList = new ArrayList<>();
    private static final int NOTIFICATION_PERMISSION_CODE = 1001;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityHomeScreenActvityBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // Apply bottom inset to bottom nav (same #161616 bar), not root —
            // root padding.bottom leaves a black empty strip under the 4 tabs.
            binding.getRoot().setOnApplyWindowInsetsListener((v, insets) -> {
                Insets systemBars = insets.getInsets(WindowInsets.Type.systemBars());
                v.setPadding(systemBars.left, systemBars.top, systemBars.right, 0);
                binding.bottomNavContainer.setPadding(0, 0, 0, systemBars.bottom);
                return insets;
            });
        }


        getLanguage();
        setViewPagers();
        setClickListener();
        checkNotificationPermission();

        // Home is the app root after onboarding — Back exits (no return to splash/login)
        getOnBackPressedDispatcher().addCallback(this, new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                finishAffinity();
            }
        });

    }
    private void checkNotificationPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {

            if (ContextCompat.checkSelfPermission(this,
                    Manifest.permission.POST_NOTIFICATIONS)
                    != PackageManager.PERMISSION_GRANTED) {

                ActivityCompat.requestPermissions(this,
                        new String[]{Manifest.permission.POST_NOTIFICATIONS},
                        NOTIFICATION_PERMISSION_CODE);

            } else {

            }
        } else {

        }
    }
    @Override
    public void onRequestPermissionsResult(int requestCode,
                                           String[] permissions,
                                           int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == NOTIFICATION_PERMISSION_CODE) {
            if (grantResults.length > 0 &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED) {



            } else {
                // Permission Denied
                Toast.makeText(this, getString(R.string.notification_permission_denied), Toast.LENGTH_SHORT).show();
            }
        }
    }
    private void setClickListener() {
        binding.linearHomeButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                binding.imgIcon1.setImageDrawable(getResources().getDrawable(R.drawable.image_home_select));
                binding.imgIcon2.setImageDrawable(getResources().getDrawable(R.drawable.image_for_you_unselect));
                binding.imgIcon3.setImageDrawable(getResources().getDrawable(R.drawable.image_my_list_unselect));
                binding.imgIcon4.setImageDrawable(getResources().getDrawable(R.drawable.image_profile_unselect));

                binding.textView1.setTextColor(getResources().getColor(R.color.white));
                binding.textView2.setTextColor(getResources().getColor(R.color.grey_colors));
                binding.textView3.setTextColor(getResources().getColor(R.color.grey_colors));
                binding.textView4.setTextColor(getResources().getColor(R.color.grey_colors));

                GeneralAdsManager.showInterstitialAdWithCounter(HomeScreenActivity.this, new Runnable() {
                    @Override
                    public void run() {
                        binding.viewPagerMain.setCurrentItem(0,false);
                    }
                });

            }
        });
        binding.linearForYouButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                binding.imgIcon1.setImageDrawable(getResources().getDrawable(R.drawable.image_home_unselect));
                binding.imgIcon2.setImageDrawable(getResources().getDrawable(R.drawable.image_for_you_select));
                binding.imgIcon3.setImageDrawable(getResources().getDrawable(R.drawable.image_my_list_unselect));
                binding.imgIcon4.setImageDrawable(getResources().getDrawable(R.drawable.image_profile_unselect));

                binding.textView2.setTextColor(getResources().getColor(R.color.white));
                binding.textView1.setTextColor(getResources().getColor(R.color.grey_colors));
                binding.textView3.setTextColor(getResources().getColor(R.color.grey_colors));
                binding.textView4.setTextColor(getResources().getColor(R.color.grey_colors));
                GeneralAdsManager.showInterstitialAdWithCounter(HomeScreenActivity.this, new Runnable() {
                    @Override
                    public void run() {
                        binding.viewPagerMain.setCurrentItem(1,false);
                    }
                });
            }
        });
        binding.linearMyListButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                binding.imgIcon1.setImageDrawable(getResources().getDrawable(R.drawable.image_home_unselect));
                binding.imgIcon2.setImageDrawable(getResources().getDrawable(R.drawable.image_for_you_unselect));
                binding.imgIcon3.setImageDrawable(getResources().getDrawable(R.drawable.image_my_list_select));
                binding.imgIcon4.setImageDrawable(getResources().getDrawable(R.drawable.image_profile_unselect));
                binding.textView3.setTextColor(getResources().getColor(R.color.white));
                binding.textView2.setTextColor(getResources().getColor(R.color.grey_colors));
                binding.textView1.setTextColor(getResources().getColor(R.color.grey_colors));
                binding.textView4.setTextColor(getResources().getColor(R.color.grey_colors));

                GeneralAdsManager.showInterstitialAdWithCounter(HomeScreenActivity.this, new Runnable() {
                    @Override
                    public void run() {
                        binding.viewPagerMain.setCurrentItem(2, false);
                    }
                });
            }
        });
        binding.linearProfileButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                binding.imgIcon1.setImageDrawable(getResources().getDrawable(R.drawable.image_home_unselect));
                binding.imgIcon2.setImageDrawable(getResources().getDrawable(R.drawable.image_for_you_unselect));
                binding.imgIcon3.setImageDrawable(getResources().getDrawable(R.drawable.image_my_list_unselect));
                binding.imgIcon4.setImageDrawable(getResources().getDrawable(R.drawable.image_profile_select));
                binding.textView4.setTextColor(getResources().getColor(R.color.white));
                binding.textView2.setTextColor(getResources().getColor(R.color.grey_colors));
                binding.textView3.setTextColor(getResources().getColor(R.color.grey_colors));
                binding.textView1.setTextColor(getResources().getColor(R.color.grey_colors));

                GeneralAdsManager.showInterstitialAdWithCounter(HomeScreenActivity.this, new Runnable() {
                    @Override
                    public void run() {
                        binding.viewPagerMain.setCurrentItem(3,false);
                    }
                });

            }
        });

    }

    private void setViewPagers() {
        binding.viewPagerMain.setOffscreenPageLimit(1);
        binding.viewPagerMain.setPageTransformer(new ViewPager2.PageTransformer() {
            @Override
            public final void transformPage(View view, float f) {
                float abs = Math.abs(f);
                float f2 = 1;
                view.setAlpha(f2 - abs);
                view.setScaleY(f2 - (abs * 0.1f));
            }
        });
        View childAt = binding.viewPagerMain.getChildAt(0);
        RecyclerView recyclerView = childAt instanceof RecyclerView ? (RecyclerView) childAt : null;
        if (recyclerView != null && recyclerView.getOnFlingListener() == null) {
            new PagerSnapHelper().attachToRecyclerView(recyclerView);
        }
        binding.viewPagerMain.setAdapter(new FragmentStateAdapter(this) {
            @NonNull
            @Override
            public Fragment createFragment(int position) {
                switch (position) {
                    case 0: return new HomeFragment();
                    case 1: return new ReelsFragment();
                    case 2: return new MyListFragment();
                    case 3: return new ProfileFragment();
                    default: return new HomeFragment();
                }
            }

            @Override
            public int getItemCount() {
                return 4;
            }
        });
        binding.viewPagerMain.setUserInputEnabled(false);
        binding.viewPagerMain.registerOnPageChangeCallback(new ViewPager2.OnPageChangeCallback() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {
                super.onPageScrolled(position, positionOffset, positionOffsetPixels);
            }

            @Override
            public void onPageSelected(int position) {
                super.onPageSelected(position);
                if (position == 0) {

                    binding.imgIcon1.setImageDrawable(getResources().getDrawable(R.drawable.image_home_select));
                    binding.imgIcon2.setImageDrawable(getResources().getDrawable(R.drawable.image_for_you_unselect));
                    binding.imgIcon3.setImageDrawable(getResources().getDrawable(R.drawable.image_my_list_unselect));
                    binding.imgIcon4.setImageDrawable(getResources().getDrawable(R.drawable.image_profile_unselect));
                    binding.textView1.setTextColor(getResources().getColor(R.color.white));
                    binding.textView2.setTextColor(getResources().getColor(R.color.grey_colors));
                    binding.textView3.setTextColor(getResources().getColor(R.color.grey_colors));
                    binding.textView4.setTextColor(getResources().getColor(R.color.grey_colors));
                } else if (position == 1) {
                    binding.imgIcon1.setImageDrawable(getResources().getDrawable(R.drawable.image_home_unselect));
                    binding.imgIcon2.setImageDrawable(getResources().getDrawable(R.drawable.image_for_you_select));
                    binding.imgIcon3.setImageDrawable(getResources().getDrawable(R.drawable.image_my_list_unselect));
                    binding.imgIcon4.setImageDrawable(getResources().getDrawable(R.drawable.image_profile_unselect));
                    binding.textView2.setTextColor(getResources().getColor(R.color.white));
                    binding.textView1.setTextColor(getResources().getColor(R.color.grey_colors));
                    binding.textView3.setTextColor(getResources().getColor(R.color.grey_colors));
                    binding.textView4.setTextColor(getResources().getColor(R.color.grey_colors));
                } else if (position == 2) {
                    binding.imgIcon1.setImageDrawable(getResources().getDrawable(R.drawable.image_home_unselect));
                    binding.imgIcon2.setImageDrawable(getResources().getDrawable(R.drawable.image_for_you_unselect));
                    binding.imgIcon3.setImageDrawable(getResources().getDrawable(R.drawable.image_my_list_select));
                    binding.imgIcon4.setImageDrawable(getResources().getDrawable(R.drawable.image_profile_unselect));
                    binding.textView3.setTextColor(getResources().getColor(R.color.white));
                    binding.textView2.setTextColor(getResources().getColor(R.color.grey_colors));
                    binding.textView1.setTextColor(getResources().getColor(R.color.grey_colors));
                    binding.textView4.setTextColor(getResources().getColor(R.color.grey_colors));
                } else if (position == 3) {
                    binding.imgIcon1.setImageDrawable(getResources().getDrawable(R.drawable.image_home_unselect));
                    binding.imgIcon2.setImageDrawable(getResources().getDrawable(R.drawable.image_for_you_unselect));
                    binding.imgIcon3.setImageDrawable(getResources().getDrawable(R.drawable.image_my_list_unselect));
                    binding.imgIcon4.setImageDrawable(getResources().getDrawable(R.drawable.image_profile_select));
                    binding.textView4.setTextColor(getResources().getColor(R.color.white));
                    binding.textView2.setTextColor(getResources().getColor(R.color.grey_colors));
                    binding.textView3.setTextColor(getResources().getColor(R.color.grey_colors));
                    binding.textView1.setTextColor(getResources().getColor(R.color.grey_colors));
                }
            }

            @Override
            public void onPageScrollStateChanged(int state) {
                super.onPageScrollStateChanged(state);
            }
        });
    }


    private void getLanguage() {
//        EngineInterface apiService =
//                EngineClient.getClient().create(EngineInterface.class);

//        apiService.getLanguages(1, 20).enqueue(new retrofit2.Callback<LanguageGetModel>() {
//            @Override
//            public void onResponse(Call<LanguageGetModel> call,
//                                   retrofit2.Response<LanguageGetModel> response) {
//
//                if (response.isSuccessful()) {
//                    LanguageGetModel data = response.body();
//                    ControlPreference.setLanguage(data.getData().get(0).getLanguage());
//
//                } else {
//
//                }
//            }
//
//            @Override
//            public void onFailure(Call<LanguageGetModel> call, Throwable t) {
//                t.printStackTrace();
//
//            }
//        });
    }


    public void showWatchRewardDialog(Activity activity) {

        Dialog dialog = new Dialog(activity);
        dialog.requestWindowFeature(Window.FEATURE_NO_TITLE);
        dialog.setContentView(R.layout.layout_reward_claim);
        dialog.setCancelable(true);

        if (dialog.getWindow() != null) {
            dialog.getWindow().setBackgroundDrawable(
                    new ColorDrawable(Color.TRANSPARENT)
            );

            Window window = dialog.getWindow();
            WindowManager.LayoutParams params = window.getAttributes();
            params.width = WindowManager.LayoutParams.MATCH_PARENT;
            params.height = WindowManager.LayoutParams.WRAP_CONTENT;
            params.gravity = Gravity.CENTER;
            window.setAttributes(params);
        }



        dialog.show();
    }

    @Override
    public void onLoginSuccess() {
        if (fragmentsList != null && fragmentsList.size() > 3) {
            Object fragment = fragmentsList.get(3);
            if (fragment instanceof ProfileFragment) {
                ((ProfileFragment) fragment).refreshData();
            }
        }
    }


}