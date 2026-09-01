package com.snapdrama.shortstream.activity.login;

import android.app.Activity;
import android.content.Intent;
import android.graphics.Insets;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.NonNull;
import android.view.View;
import android.view.WindowInsets;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.OnBackPressedCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;

import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.firebase.FirebaseException;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.auth.PhoneAuthCredential;
import com.google.firebase.auth.PhoneAuthProvider;
import com.hbb20.CountryCodePicker;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.login.auth.AuthManager;
import com.snapdrama.shortstream.activity.main.activity.HomeScreenActivity;
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity;
import com.snapdrama.shortstream.ads.FirebaseEventManager;
import com.snapdrama.shortstream.ads.GeneralAdsManager;
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.InterOnboardAd;
import com.snapdrama.shortstream.ads.adsMenu.OnBoard.OnBoard4TwoNativeAdView;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.utils.coins.CoinsManager;
import com.snapdrama.shortstream.databinding.ActivityLoginMainBinding;

import java.util.HashMap;
import java.util.Map;

public class LoginMainActivity extends BaseOtherActivity {
    ActivityLoginMainBinding binding;
    private Handler googleSignInTimeoutHandler = null;
    private Runnable googleSignInTimeoutRunnable = null;
    private AuthManager authManager;
    FirebaseAuth mAuth;
    String verificationId;
    boolean inLoginFirstTime = false;
    String ForWardScreenName = "";
    public static Long loginTime;

    private static final String TAG = "LoginActivity";
    private static final long GOOGLE_SIGN_IN_TIMEOUT = 30000L;

    private ActivityResultLauncher<Intent> googleSignInLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.StartActivityForResult(),
                    result -> {
                        cancelGoogleSignInTimeout();

                        Intent data = result.getData();
                        // Always try to parse Google result — DEVELOPER_ERROR (10) often
                        // returns RESULT_CANCELED instead of RESULT_OK.
                        if (data != null) {
                            try {
                                GoogleSignInAccount account = authManager.handleGoogleSignInResult(data);
                                if (account != null) {
                                    signInWithGoogleAccount(account);
                                    return;
                                }
                            } catch (com.google.android.gms.common.api.ApiException e) {
                                showLoading(false);
                                int code = e.getStatusCode();
                                // 10 = DEVELOPER_ERROR (SHA-1 / OAuth client mismatch in Firebase)
                                showError(getString(R.string.google_sign_in_failed_error_code) + code);
                                android.util.Log.e(TAG, "Google sign in failed status=" + code, e);
                                return;
                            }
                        }

                        showLoading(false);
                        if (result.getResultCode() == Activity.RESULT_OK) {
                            showError(getString(R.string.google_sign_in_failed_account_null));
                        } else {
                            showError(getString(R.string.google_sign_in_cancelled) + result.getResultCode() + ")");
                        }
                    }
            );


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityLoginMainBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());

        inLoginFirstTime = getIntent().getBooleanExtra("LoginFirstTime", false);
        ForWardScreenName = getIntent().getStringExtra("ForWardScreenName");
        loginTime = System.currentTimeMillis();
        if (inLoginFirstTime) {
            FirebaseEventManager.onb1View("first_view");
        } else {
            FirebaseEventManager.onb1View("revisit");
        }


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
        // Display priority → native-ob4-2 (onboard_4_native_2) — IDs from RC only
        OnBoard4TwoNativeAdView.adsViewNativeAds = 0;
        OnBoard4TwoNativeAdView.loadAdmobBigNativeAd(
                this,
                ControlPreference.get_OnBoard4TwoNative_Ids_List(),
                binding.linearSmallNtv
        );
        if (binding.shimmerAdsLayout != null) {
            binding.shimmerAdsLayout.setVisibility(View.GONE);
        }
        mAuth = FirebaseAuth.getInstance();
        authManager = AuthManager.getInstance();
        authManager.initializeGoogleSignIn(this);

        findViewById(R.id.linearPrivacyTermOfUse).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!ControlPreference.getPrivacyPolicy().equals("")) {
                    startActivity(new Intent("android.intent.action.VIEW", Uri.parse(ControlPreference.getPrivacyPolicy())));
                } else {
                    Toast.makeText(LoginMainActivity.this, getString(R.string.something_went_wrong), Toast.LENGTH_SHORT).show();
                }
            }
        });

        binding.buttonSkip.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                FirebaseEventManager.onb1Complete(loginTime, "Skip_Click", "forward", "HomeScreenActivity");
                startMainActivity();
            }
        });
        binding.buttonSingInGoogle.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                signInWithGoogle();
            }
        });


        checkIfUserIsLoggedIn();

        setupPhoneLogin();

        GeneralAdsManager.loadInterstitialAd(this);

        getOnBackPressedDispatcher().addCallback(new OnBackPressedCallback(true) {
            @Override
            public void handleOnBackPressed() {
                onBack();
            }
        });


    }

    private void onBack() {
        if (ForWardScreenName.equals("SplashScreenActivity")) {
            FirebaseEventManager.onb1Complete(loginTime, "Back_Click", "backward", ForWardScreenName);
            finishAffinity();
        } else {
            FirebaseEventManager.onb1Complete(loginTime, "Back_Click", "backward", ForWardScreenName);
            finish();
        }
    }

    private void setupPhoneLogin() {
        CountryCodePicker ccp = binding.ccp;
        ccp.registerCarrierNumberEditText(binding.etPhone);

        TextView btnLoginPhone = binding.btnLoginPhone;

        btnLoginPhone.setOnClickListener(v -> {
            String rawPhone = binding.etPhone.getText().toString().trim();
            if (rawPhone.isEmpty()) {
                binding.etPhone.setError(getString(R.string.enter_phone_number));
                return;
            }

            if (!ccp.isValidFullNumber()) {
                binding.etPhone.setError(getString(R.string.enter_valid_number));
                return;
            }

            String fullPhone = ccp.getFullNumberWithPlus();

            Intent intent = new Intent(this, OtpReceiveScreen.class);
            intent.putExtra(OtpReceiveScreen.EXTRA_PHONE, fullPhone);
            startActivity(intent);
        });
    }

    private void signInWithGoogle() {
        showLoading(true);

        Intent signInIntent = authManager.getGoogleSignInIntent(this);
        if (signInIntent != null) {
            startGoogleSignInTimeout();
            googleSignInLauncher.launch(signInIntent);
        } else {
            showLoading(false);
            showError(getString(R.string.google_sign_in_not_available));
        }
    }

    private void checkIfUserIsLoggedIn() {
        if (authManager.isUserLoggedIn()) {
            startMainActivity();
        }
    }

    private void startMainActivity() {
        if (isFinishing()) {
            return;
        }
        ControlPreference.setLoginScreen(true);

        // After onboarding login/skip → show inter-ob5-1 → inter-ob5-2 (RC only)
        if (inLoginFirstTime) {
            InterOnboardAd.showThen(this, ControlPreference.get_InterOnboard_Ids_List(), shown -> openHomeScreen());
            return;
        }

        GeneralAdsManager.showInterstitialAdThen(this, this::openHomeScreen);
    }

    private void openHomeScreen() {
        if (isFinishing()) {
            return;
        }
        Intent intent = new Intent(LoginMainActivity.this, HomeScreenActivity.class);
        // Clear splash/onboarding/login stack so Back from Home cannot return there
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }

    private void startGoogleSignInTimeout() {
        googleSignInTimeoutHandler = new Handler(Looper.getMainLooper());

        googleSignInTimeoutRunnable = new Runnable() {
            @Override
            public void run() {
                showError(getString(R.string.google_sign_in_timed_out));
                showLoading(false);
            }
        };

        googleSignInTimeoutHandler.postDelayed(
                googleSignInTimeoutRunnable,
                GOOGLE_SIGN_IN_TIMEOUT
        );
    }

    private void showLoading(Boolean show) {
//        binding.progressBar.visibility = if (show) View.VISIBLE else View.GONE
//        binding.btnLogin.isEnabled = !show
//        binding.btnGoogleSignInContainer.isEnabled = !show
    }

    private void signInWithGoogleAccount(GoogleSignInAccount account) {

        showLoading(true);

        authManager.signInWithGoogle(account, new AuthManager.AuthCallback() {
            @Override
            public void onSuccess(FirebaseUser user) {
                if (user != null) {
                    insertGoogleUserToFirestore(user);
                }
                FirebaseEventManager.onb1Complete(loginTime, "Login_Click", "forward", "HomeScreenActivity");
                startMainActivity();
                showLoading(false);
            }

            @Override
            public void onError(Exception e) {
                showLoading(false);
                showError(e.getMessage() != null
                        ? e.getMessage()
                        : getString(R.string.google_sign_in_failed));
            }
        });

    }

    private void insertGoogleUserToFirestore(FirebaseUser user) {

        String uid = user.getUid();
        String email = user.getEmail();
        String phone = user.getPhoneNumber();

        String firstName = "";
        String lastName = "";

        if (user.getDisplayName() != null) {
            String[] parts = user.getDisplayName().split(" ", 2);
            firstName = parts[0];
            if (parts.length > 1) lastName = parts[1];
        }

        String photoUrl = "";
        if (user.getPhotoUrl() != null) {
            photoUrl = user.getPhotoUrl().toString();
        }

        saveUserToFirestore(
                uid,
                firstName,
                lastName,
                phone,
                email,
                photoUrl,
                "google"
        );
    }

    private void saveUserToFirestore(
            String uid,
            String firstName,
            String lastName,
            String phone,
            String email,
            String photoUrl,
            String provider
    ) {
        Map<String, Object> map = new HashMap<>();
        map.put("firstName", firstName);
        map.put("lastName", lastName);
        map.put("phone", phone);
        map.put("email", email);
        map.put("photoUrl", photoUrl);
        map.put("provider", provider);
        map.put("profileCompleted", true);
        CoinsManager.ensureUserInitialized(uid, map, CoinsManager.DEFAULT_FIRST_LOGIN_COINS);
    }

    private void showError(String message) {
        Toast.makeText(this, message, Toast.LENGTH_LONG).show();
    }


    private void cancelGoogleSignInTimeout() {
        if (googleSignInTimeoutHandler != null && googleSignInTimeoutRunnable != null) {
            googleSignInTimeoutHandler.removeCallbacks(googleSignInTimeoutRunnable);
        }
        googleSignInTimeoutHandler = null;
        googleSignInTimeoutRunnable = null;
    }


    private final PhoneAuthProvider.OnVerificationStateChangedCallbacks callbacks =
            new PhoneAuthProvider.OnVerificationStateChangedCallbacks() {

                @Override
                public void onVerificationCompleted(@NonNull PhoneAuthCredential credential) {
                    signInWithCredential(credential);
                }

                @Override
                public void onVerificationFailed(@NonNull FirebaseException e) {
                    Toast.makeText(LoginMainActivity.this,
                            getString(R.string.failed_prefix) + e.getMessage(), Toast.LENGTH_LONG).show();
                }

                @Override
                public void onCodeSent(@NonNull String s,
                                       @NonNull PhoneAuthProvider.ForceResendingToken token) {
                    verificationId = s;
                    Toast.makeText(LoginMainActivity.this,
                            getString(R.string.otp_sent), Toast.LENGTH_SHORT).show();
                }
            };


    private void signInWithCredential(PhoneAuthCredential credential) {
        mAuth.signInWithCredential(credential)
                .addOnCompleteListener(task -> {
                    if (task.isSuccessful()) {
                        Toast.makeText(this,
                                getString(R.string.login_successful), Toast.LENGTH_SHORT).show();
                    } else {
                        Toast.makeText(this,
                                getString(R.string.invalid_otp), Toast.LENGTH_SHORT).show();
                    }
                });
    }


}