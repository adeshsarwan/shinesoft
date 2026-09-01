package com.snapdrama.shortstream.activity.main.fragment;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;

import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Toast;

import com.bumptech.glide.Glide;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.Query;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.login.LoginMainActivity;
import com.snapdrama.shortstream.activity.premium.PremiumMemberActivity;
import com.snapdrama.shortstream.activity.premium.TopUpActivity;
import com.snapdrama.shortstream.activity.setting.GiftsActivity;
import com.snapdrama.shortstream.activity.language.LanguageActivity;
import com.snapdrama.shortstream.activity.setting.MyWalletActivity;
import com.snapdrama.shortstream.activity.login.auth.AuthManager;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.databinding.FragmentProfileBinding;
import com.snapdrama.shortstream.activity.main.fragment.my_list.adapter.ContinueWatchingAdapter;
import com.snapdrama.shortstream.activity.main.fragment.my_list.model.ContinueWatchingModel;

import java.util.ArrayList;
import java.util.List;


public class ProfileFragment extends Fragment {


    FragmentProfileBinding binding;
    ContinueWatchingAdapter continueWatchingAdapter;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding = FragmentProfileBinding.inflate(inflater, container, false);
        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
        if (user == null) {
            binding.imageNext.setVisibility(View.GONE);
            binding.buttonLogin.setVisibility(View.VISIBLE);
            binding.buttonLogout.setVisibility(View.GONE);


        } else {
            binding.imageNext.setVisibility(View.VISIBLE);

            binding.buttonLogin.setVisibility(View.GONE);
            binding.buttonLogout.setVisibility(View.VISIBLE);

            getUserData();
        }
        binding.buttonLogin.setOnClickListener(v -> {
            Intent intent = new Intent(requireActivity(), LoginMainActivity.class);
            intent.putExtra("ForWardScreenName", "ProfileFragment");
            startActivity(intent);
        });

        binding.buttonLogout.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                AuthManager authManager = AuthManager.getInstance();
                authManager.initializeGoogleSignIn(requireActivity());
                authManager.signOut();
                refreshData();
                Toast.makeText(requireActivity(), getString(R.string.logged_out_successfully), Toast.LENGTH_SHORT).show();
            }
        });

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
        binding.imageTopUp.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(requireActivity(), TopUpActivity.class);
                startActivity(intent);
            }
        });
        binding.imageMyWallet.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onMyWallet();
            }
        });
        binding.imageLanguage.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onLanguageClick();
            }
        });
        binding.imageGift.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                onGiftClick();
            }
        });
        binding.imagePrivacyPolicy.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!ControlPreference.getPrivacyPolicy().equals("")) {
                    startActivity(new Intent("android.intent.action.VIEW", Uri.parse(ControlPreference.getPrivacyPolicy())));
                } else {
                    Toast.makeText(requireActivity(), getString(R.string.something_went_wrong), Toast.LENGTH_SHORT).show();
                }
            }
        });
        binding.imageHelpFeedBack.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!ControlPreference.getHelpFeedback().equals("")) {
                    startActivity(new Intent("android.intent.action.VIEW", Uri.parse(ControlPreference.getHelpFeedback())));
                } else {
                    Toast.makeText(requireActivity(), getString(R.string.something_went_wrong), Toast.LENGTH_SHORT).show();
                }
            }
        });

        continueWatchingAdapter = new ContinueWatchingAdapter(requireContext(), 1);
        LinearLayoutManager layoutManager = new LinearLayoutManager(getContext(), LinearLayoutManager.HORIZONTAL, false);
        binding.recycleViewHistory.setLayoutManager(layoutManager);
        binding.recycleViewHistory.setAdapter(continueWatchingAdapter);
        return binding.getRoot();
    }

    private void onLanguageClick() {
        Intent intent = new Intent(requireActivity(), LanguageActivity.class).putExtra("LANGUAGE_SCREEN_AVAILABLE", true);
        startActivity(intent);
    }

    private void onMyWallet() {
        Intent intent = new Intent(requireActivity(), MyWalletActivity.class);
        startActivity(intent);
    }

    private void onGiftClick() {
        Intent intent = new Intent(requireActivity(), GiftsActivity.class);
        startActivity(intent);
    }

    @Override
    public void onResume() {
        super.onResume();

        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();

        if (user != null) {
            loadContinueWatching();
        }
    }

    private void getUserData() {

        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();

        if (user != null) {

            String email = user.getEmail();

            String fullName = user.getDisplayName();

            String firstName = "";
            String lastName = "";
            if (fullName != null && fullName.contains(" ")) {
                String[] nameParts = fullName.split(" ");
                firstName = nameParts[0];
                lastName = nameParts.length > 1 ? nameParts[1] : "";
            } else {
                firstName = fullName;
            }

            Uri photoUri = user.getPhotoUrl();
            String photoUrl = photoUri != null ? photoUri.toString() : "";

            String uid = user.getUid();
            FirebaseFirestore.getInstance()
                    .collection("users")
                    .document(uid)
                    .addSnapshotListener((doc, e) -> {
                        binding.textViewProfileName.setText(doc.getString("firstName"));
                        binding.textViewEmailId.setText(doc.getString("email"));
                        Glide.with(this)
                                .load(photoUrl)
                                .placeholder(R.drawable.image_placeholder_profile)
                                .error(R.drawable.image_placeholder_profile)
                                .into(binding.profileImage);
                    });
            Glide.with(this)
                    .load(photoUrl)
                    .placeholder(R.drawable.image_placeholder_profile)
                    .error(R.drawable.image_placeholder_profile)
                    .into(binding.profileImage);
            binding.textViewProfileName.setText(fullName);
            binding.textViewEmailId.setText(email);

        }
    }

    private void loadContinueWatching() {

        String userId = FirebaseAuth.getInstance().getUid();

        FirebaseFirestore db = FirebaseFirestore.getInstance();

        db.collection("users")
                .document(userId)
                .collection("continueWatching")
                .whereEqualTo("status", "IN_PROGRESS")
                .orderBy("lastWatchedAt", Query.Direction.DESCENDING)
                .limit(20)
                .get()
                .addOnSuccessListener(querySnapshot -> {

                    List<ContinueWatchingModel> list = new ArrayList<>();

                    for (DocumentSnapshot doc : querySnapshot.getDocuments()) {
                        ContinueWatchingModel model =
                                doc.toObject(ContinueWatchingModel.class);
                        if (model != null) {
                            list.add(model);
                        }
                    }


                    continueWatchingAdapter.setData(list);

                    if (list.isEmpty()) {
                        binding.emptyTitle.setVisibility(View.VISIBLE);
                        binding.recycleViewHistory.setVisibility(View.INVISIBLE);
                    } else {
                        binding.emptyTitle.setVisibility(View.INVISIBLE);
                        binding.recycleViewHistory.setVisibility(View.VISIBLE);
                    }

                })
                .addOnFailureListener(e -> {
                });
    }

    public void refreshData() {

        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();

        if (user != null) {
            binding.imageNext.setVisibility(View.VISIBLE);
            binding.buttonLogin.setVisibility(View.GONE);
            getUserData();
            loadContinueWatching();
        } else {
            binding.imageNext.setVisibility(View.GONE);
            binding.buttonLogin.setVisibility(View.VISIBLE);

            binding.textViewProfileName.setText(getString(R.string.log_in));
            binding.textViewEmailId.setText(getString(R.string.id) + " 350262142");
            binding.profileImage.setImageResource(R.drawable.image_placeholder_profile);

            binding.emptyTitle.setVisibility(View.VISIBLE);
            binding.recycleViewHistory.setVisibility(View.INVISIBLE);
        }
    }
}