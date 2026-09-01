package com.snapdrama.shortstream.activity.main.fragment.category_fragment;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.ViewModelProvider;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import com.google.android.material.tabs.TabLayout;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.adapter.ShortCategoryDetailAdapter;
import com.snapdrama.shortstream.adapter.ShortDramaAdapter;
import com.snapdrama.shortstream.databinding.FragmentCategoriesBinding;
import com.snapdrama.shortstream.engineBox.client.EngineClient;
import com.snapdrama.shortstream.engineBox.interfaces.EngineInterface;
import com.snapdrama.shortstream.engineBox.model.series.SeriesCategoryDetailModel;
import com.snapdrama.shortstream.engineBox.model.series.SeriesCategoryModel;
import com.snapdrama.shortstream.mvvmRepo.model.PopularSeriesViewModel;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import java.util.ArrayList;
import java.util.List;
import retrofit2.Call;


public class CategoriesFragment extends Fragment {
    private PopularSeriesViewModel popularSeriesViewModel;
    ShortDramaAdapter adapter;

    FragmentCategoriesBinding binding;
    ShortCategoryDetailAdapter adapter2;
    List<SeriesCategoryModel.Datum> categoryList = new ArrayList<>();
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding =  FragmentCategoriesBinding.inflate(inflater, container, false);

        binding.recycleCategoryList.setLayoutManager(new GridLayoutManager(getContext(), 3));
        binding.recycleCategoryList.setHasFixedSize(true);
        binding.recycleCategoryList.setItemViewCacheSize(20);

        getCategories();
        return binding.getRoot();
    }
    private void setupTabLayout() {

        TabLayout tabLayout = binding.tabLayout;
        tabLayout.removeAllTabs();

        for (SeriesCategoryModel.Datum item : categoryList) {
            TabLayout.Tab tab = tabLayout.newTab();
            tab.setText(item.getName());
            tabLayout.addTab(tab);
        }

        if (tabLayout.getTabCount() > 0) {
            tabLayout.getTabAt(0).select();
            getCallingCategories("All");
        }

        tabLayout.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {

                String categoryName = tab.getText().toString();
                ControlPreference.incrementInterstitialAdCount();
                getCallingCategories(categoryName);
            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) { }

            @Override
            public void onTabReselected(TabLayout.Tab tab) {
                String categoryName = tab.getText().toString();
                getCallingCategories(categoryName);
            }
        });
    }


    private void getCategories() {
        EngineInterface apiService =
                EngineClient.getClient().create(EngineInterface.class);

        apiService.getQueryCategory(1, 20)
                .enqueue(new retrofit2.Callback<SeriesCategoryModel>() {
                    @Override
                    public void onResponse(Call<SeriesCategoryModel> call,
                                           retrofit2.Response<SeriesCategoryModel> response) {

                        if (!isAdded()) return;

                        if (response.isSuccessful()
                                && response.body() != null
                                && response.body().getData() != null) {
                            categoryList.clear();
                            SeriesCategoryModel.Datum allItem =
                                    new SeriesCategoryModel.Datum();
                            allItem.setName("All");
                            categoryList.add(allItem);

                            categoryList.addAll(response.body().getData());
                            setupTabLayout();




                        } else {
                        }
                    }

                    @Override
                    public void onFailure(Call<SeriesCategoryModel> call, Throwable t) {
                    }
                });
    }
    public interface OnCategoryClickListener {
        void onCategoryClick(String categoryName, SeriesCategoryModel.Datum item);
    }
    public class CategoryAdapter
            extends RecyclerView.Adapter<CategoryAdapter.ViewHolder> {

        List<SeriesCategoryModel.Datum> list;
        OnCategoryClickListener listener;
        private int selectedPosition = 0;

        public CategoryAdapter(List<SeriesCategoryModel.Datum> list,
                               OnCategoryClickListener listener) {
            this.list = list;
            this.listener = listener;
        }

        @NonNull
        @Override
        public ViewHolder onCreateViewHolder(
                @NonNull ViewGroup parent, int viewType) {

            View view = LayoutInflater.from(parent.getContext())
                    .inflate(R.layout.layout_categories, parent, false);
            return new ViewHolder(view);
        }

        @Override
        public void onBindViewHolder(
                @NonNull ViewHolder holder, int position) {

            SeriesCategoryModel.Datum item = list.get(position);
            holder.textName.setText(item.getName());

            if (position == selectedPosition) {
                holder.textName.setBackgroundResource(R.drawable.background_selected_categories);
                holder.textName.setTextColor(
                        holder.itemView.getContext().getColor(R.color.app_colors));
            } else {
                holder.textName.setBackgroundResource(R.drawable.background_unselected_categories);
                holder.textName.setTextColor(
                        holder.itemView.getContext().getColor(R.color.grey_colors));
            }

            holder.itemView.setOnClickListener(v -> {

                int oldPos = selectedPosition;
                selectedPosition = holder.getAdapterPosition();

                notifyItemChanged(oldPos);
                notifyItemChanged(selectedPosition);

                if (listener != null) {
                    listener.onCategoryClick(item.getName(), item);
                }
            });
        }
        @Override
        public int getItemCount() {
            return list.size();
        }

        class ViewHolder extends RecyclerView.ViewHolder {
            TextView textName;

            public ViewHolder(@NonNull View itemView) {
                super(itemView);
                textName = itemView.findViewById(R.id.textShortDrama);
            }
        }
    }
    private void getCallingCategories(String categoryName) {

        if (categoryName == null || categoryName.trim().isEmpty()) {
            return;
        }
        if ("All".equals(categoryName)) {
            setupObserver();
            return;
        }


        EngineInterface apiService =
                EngineClient.getClient().create(EngineInterface.class);

        apiService.getQueryCategoryDetail("en", categoryName, 1, 20)
                .enqueue(new retrofit2.Callback<SeriesCategoryDetailModel>() {
                    @Override
                    public void onResponse(Call<SeriesCategoryDetailModel> call,
                                           retrofit2.Response<SeriesCategoryDetailModel> response) {

                        if (!isAdded() || getContext() == null) return;

                        if (response.isSuccessful()
                                && response.body() != null
                                && response.body().getData() != null
                                && !response.body().getData().isEmpty()) {

                            adapter2 = new ShortCategoryDetailAdapter(
                                    getContext(),
                                    response.body().getData()
                            );

                            binding.recycleCategoryList.setAdapter(adapter2);

                        } else {
                            showEmptyState();
                        }
                    }

                    @Override
                    public void onFailure(Call<SeriesCategoryDetailModel> call, Throwable t) {
                        if (!isAdded()) return;
                        showErrorState();
                    }
                });
    }
    private void showEmptyState() {
        binding.recycleCategoryList.setAdapter(null);
//        binding.textEmpty.setVisibility(View.VISIBLE);
    }

    private void showErrorState() {
        binding.recycleCategoryList.setAdapter(null);
//        binding.textEmpty.setVisibility(View.VISIBLE);
    }
    private void setupObserver() {
        if (!isAdded() || getView() == null) {
            return;
        }

        popularSeriesViewModel = new ViewModelProvider(getActivity()).get(PopularSeriesViewModel.class);



        popularSeriesViewModel.getPopularSeries()
                .observe(getViewLifecycleOwner(), response -> {

                    if (response != null
                            && response.getData() != null
                            && !response.getData().isEmpty()) {

                        adapter = new ShortDramaAdapter(
                                getContext(),
                                response.getData(),0
                        );
                        binding.recycleCategoryList.setAdapter(adapter);


                    } else {
                    }
                });
    }
}