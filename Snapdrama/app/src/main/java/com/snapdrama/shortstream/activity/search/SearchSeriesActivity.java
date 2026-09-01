package com.snapdrama.shortstream.activity.search;

import android.graphics.Insets;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.util.Log;
import android.view.View;
import android.view.WindowInsets;
import android.view.inputmethod.InputMethodManager;

import androidx.appcompat.app.AppCompatActivity;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.GridLayoutManager;

import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity;
import com.snapdrama.shortstream.adapter.ShortDramaAdapter;
import com.snapdrama.shortstream.databinding.ActivitySearchSeriesBinding;
import com.snapdrama.shortstream.mvvmRepo.model.PopularSeriesViewModel;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;

public class SearchSeriesActivity extends BaseOtherActivity {
    ActivitySearchSeriesBinding binding;
    private PopularSeriesViewModel popularSeriesViewModel;
    ShortDramaAdapter adapter;
    private Handler searchHandler;
    private Runnable searchRunnable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivitySearchSeriesBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            View root = findViewById(android.R.id.content);

            root.setOnApplyWindowInsetsListener((v, insets) -> {
                Insets systemBars = insets.getInsets(WindowInsets.Type.systemBars());
                v.setPadding(
                        systemBars.left,
                        systemBars.top,
                        systemBars.right,
                        systemBars.bottom
                );
                return insets;
            });
        }


        recycleLayoutManager();
        setupObserver();
        setupSearch();
        searchAutoListener();


        binding.btnBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onBackPressed();
            }
        });
    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        finish();
    }

    private void recycleLayoutManager() {
        binding.peopleSearchingRv.setLayoutManager(new GridLayoutManager(this, 3));
        binding.peopleSearchingRv.setHasFixedSize(true);
        searchHandler = new Handler(Looper.getMainLooper());

    }

    private void searchAutoListener() {
        binding.searchInput.requestFocus();
        binding.searchInput.postDelayed(new Runnable() {
            @Override
            public void run() {
                InputMethodManager imm = (InputMethodManager) getSystemService(INPUT_METHOD_SERVICE);
                if (imm != null) {
                    imm.showSoftInput(binding.searchInput, InputMethodManager.SHOW_IMPLICIT);
                }
            }
        }, 100L);
    }

    private void setupObserver() {
        popularSeriesViewModel = new ViewModelProvider(this).get(PopularSeriesViewModel.class);

        popularSeriesViewModel.getPopularSeries()
                .observe(this, response -> {
                    if (response != null
                            && response.getData() != null
                            && !response.getData().isEmpty()) {

                        adapter = new ShortDramaAdapter(
                                SearchSeriesActivity.this,
                                response.getData(), 0
                        );

                        binding.peopleSearchingRv.setAdapter(adapter);

                        binding.peopleSearchingRv.setVisibility(View.VISIBLE);
                        if (binding.progressLayout != null) {
                            binding.progressLayout.emptyLayout.setVisibility(View.GONE);
                            binding.progressLayout.progressAnimation.setVisibility(View.GONE);
                        }

                    } else {
                        if (binding.progressLayout != null) {
                            binding.progressLayout.emptyLayout.setVisibility(View.VISIBLE);
                        }
                        binding.peopleSearchingRv.setVisibility(View.GONE);
                    }
                });
    }

    private void setupSearch() {
        binding.searchInput.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
                if (searchRunnable != null) {
                    searchHandler.removeCallbacks(searchRunnable);
                }

                if (binding.progressLayout != null) {
                    binding.progressLayout.progressAnimation.setVisibility(View.VISIBLE);
                }

                String query = s.toString().trim();
                ControlPreference.incrementInterstitialAdCount();
                searchRunnable = new Runnable() {
                    @Override
                    public void run() {
                        if (adapter != null) {
                            adapter.filter(query);

                            if (binding.progressLayout != null) {
                                binding.progressLayout.progressAnimation.setVisibility(View.GONE);
                            }

                            if (adapter.getItemCount() == 0) {
                                if (binding.progressLayout != null) {
                                    binding.progressLayout.emptyLayout.setVisibility(View.VISIBLE);
                                }
                                binding.peopleSearchingRv.setVisibility(View.GONE);
                            } else {
                                if (binding.progressLayout != null) {
                                    binding.progressLayout.emptyLayout.setVisibility(View.GONE);
                                }
                                binding.peopleSearchingRv.setVisibility(View.VISIBLE);
                            }
                        } else {
                            if (binding.progressLayout != null) {
                                binding.progressLayout.progressAnimation.setVisibility(View.GONE);
                            }
                        }
                    }
                };

                searchHandler.postDelayed(searchRunnable, 300);
            }

            @Override
            public void afterTextChanged(Editable s) {
            }
        });
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (searchHandler != null && searchRunnable != null) {
            searchHandler.removeCallbacks(searchRunnable);
        }
    }
}