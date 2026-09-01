package com.snapdrama.shortstream.activity.main.fragment;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.viewpager.widget.ViewPager;

import android.os.Handler;
import android.os.Looper;
import android.support.annotation.NonNull;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.gms.auth.api.phone.SmsRetriever;
import com.google.android.gms.auth.api.phone.SmsRetrieverClient;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.android.material.bottomsheet.BottomSheetDialog;
import com.google.firebase.FirebaseException;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.auth.PhoneAuthCredential;
import com.google.firebase.auth.PhoneAuthOptions;
import com.google.firebase.auth.PhoneAuthProvider;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;
import com.hbb20.CountryCodePicker;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.login.OTPReceiver;
import com.snapdrama.shortstream.activity.login.auth.AuthManager;
import com.snapdrama.shortstream.activity.main.activity.HomeScreenActivity;
import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.databinding.FragmentMyListBinding;
import com.snapdrama.shortstream.activity.main.fragment.my_list.adapter.ViewPagerAdapter;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;


public class MyListFragment extends Fragment {
    public interface OnLoginSuccessListener {
        void onLoginSuccess();
    }
    private OnLoginSuccessListener loginListener;
    private AuthManager authManager;
    FirebaseAuth mAuth;
    private static final long GOOGLE_SIGN_IN_TIMEOUT = 30000L;
    FragmentMyListBinding binding;
    private Handler googleSignInTimeoutHandler = null;
    private Runnable googleSignInTimeoutRunnable = null;
    private String verificationId;
    private OTPReceiver otpReceiver;
    private PhoneAuthProvider.ForceResendingToken resendToken;
    private String phoneNumber;
    private View dialogLoginView;
    private boolean isOtpSent = false;
    private BottomSheetDialog loginDialog;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        binding = FragmentMyListBinding.inflate(inflater, container, false);
        mAuth = FirebaseAuth.getInstance();
        authManager = AuthManager.getInstance();
        authManager.initializeGoogleSignIn(requireActivity());
        if (authManager.isUserLoggedIn()) {
        } else {
            showLoginFullDialog();
        }
        setupViewPager();

        return binding.getRoot();
    }

    @Override
    public void onAttach(@NonNull Context context) {
        super.onAttach(context);
        if (context instanceof OnLoginSuccessListener) {
            loginListener = (OnLoginSuccessListener) context;
        } else {
            throw new RuntimeException(context.toString()
                    + " must implement OnLoginSuccessListener");
        }
    }

    private void setupViewPager() {
        ViewPagerAdapter adapter = new ViewPagerAdapter(getChildFragmentManager());
        binding.viewPagerMyList.setAdapter(adapter);
        binding.imgViewCategory1.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                binding.imgView1.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_select));
                binding.imgView2.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_unselect));
                binding.viewPagerMyList.setCurrentItem(0);
            }
        });
        binding.imgViewCategory2.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                binding.imgView1.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_unselect));
                binding.imgView2.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_select));
                binding.viewPagerMyList.setCurrentItem(1);

            }
        });
        binding.viewPagerMyList.addOnPageChangeListener(new ViewPager.OnPageChangeListener() {
            @Override
            public void onPageScrolled(int position, float positionOffset, int positionOffsetPixels) {

            }

            @Override
            public void onPageSelected(int position) {
                if (position == 0) {
                    binding.imgView1.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_select));
                    binding.imgView2.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_unselect));
                } else {
                    binding.imgView1.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_unselect));
                    binding.imgView2.setImageDrawable(getResources().getDrawable(R.drawable.ic_tab_select));
                }

            }

            @Override
            public void onPageScrollStateChanged(int state) {

            }
        });

    }


    private void cancelGoogleSignInTimeout() {
        if (googleSignInTimeoutHandler != null && googleSignInTimeoutRunnable != null) {
            googleSignInTimeoutHandler.removeCallbacks(googleSignInTimeoutRunnable);
        }
        googleSignInTimeoutHandler = null;
        googleSignInTimeoutRunnable = null;
    }

    private void signInWithGoogle() {
        showLoading(true);

        Intent signInIntent = authManager.getGoogleSignInIntent(requireActivity());
        if (signInIntent != null) {
            startGoogleSignInTimeout();
            googleSignInLauncher.launch(signInIntent);
        } else {
            showLoading(false);
            showError(getString(R.string.google_sign_in_not_available));
        }
    }

    private void showError(String message) {
        Toast.makeText(requireActivity(), message, Toast.LENGTH_LONG).show();
    }



    private void checkIfUserIsLoggedIn() {
        if (authManager.isUserLoggedIn()) {
            startMainActivity();
        }
    }

    private void showLoading(Boolean show) {
//        binding.progressBar.visibility = if (show) View.VISIBLE else View.GONE
//        binding.btnLogin.isEnabled = !show
//        binding.btnGoogleSignInContainer.isEnabled = !show
    }

    private void startMainActivity() {
        Intent intent = new Intent(requireActivity(), HomeScreenActivity.class);
        startActivity(intent);

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

    private ActivityResultLauncher<Intent> googleSignInLauncher =
            registerForActivityResult(
                    new ActivityResultContracts.StartActivityForResult(),
                    result -> {
                        cancelGoogleSignInTimeout();

                        if (result.getResultCode() == Activity.RESULT_OK && result.getData() != null) {

                            GoogleSignInAccount account =
                                    null;
                            try {
                                account = authManager.handleGoogleSignInResult(result.getData());
                            } catch (ApiException e) {
                                throw new RuntimeException(e);
                            }

                            if (account != null) {
                                signInWithGoogleAccount(account);
                            } else {
                                showLoading(false);
                                showError(getString(R.string.google_sign_in_failed_please_try_again));
                            }

                        } else {
                            showLoading(false);
                            showError(getString(R.string.google_sign_in_cancelled));
                        }
                    }
            );

    private void signInWithGoogleAccount(GoogleSignInAccount account) {

        showLoading(true);

        authManager.signInWithGoogle(account, new AuthManager.AuthCallback() {
            @Override
            public void onSuccess(FirebaseUser user) {
                if (user != null) {
                    insertGoogleUserToFirestore(user);
                }

                setupViewPager();
                if (loginDialog != null && loginDialog.isShowing()) {
                    loginDialog.dismiss();
                }
                showLoading(false);
                if (loginListener != null) {
                    loginListener.onLoginSuccess();
                }
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
        map.put("createdAt", FieldValue.serverTimestamp());

        FirebaseFirestore.getInstance()
                .collection("users")
                .document(uid)
                .set(map, SetOptions.merge());
    }

    private void showLoginFullDialog() {
        loginDialog = new BottomSheetDialog(requireActivity(), R.style.TransparentBottomSheetDialog);
        dialogLoginView = LayoutInflater.from(requireActivity())
                .inflate(R.layout.layout_login_user, null);

        LinearLayout signInGoogle = dialogLoginView.findViewById(R.id.signInGoogle);
        ImageView buttonClose = dialogLoginView.findViewById(R.id.buttonClose);
        TextView btnConfirm = dialogLoginView.findViewById(R.id.btnConfirm);
        LinearLayout linearPrivacyTermOfUse = dialogLoginView.findViewById(R.id.linearPrivacyTermOfUse);
        linearPrivacyTermOfUse.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (!ControlPreference.getPrivacyPolicy().equals("")) {
                    startActivity(new Intent("android.intent.action.VIEW", Uri.parse(ControlPreference.getPrivacyPolicy())));
                } else {
                    Toast.makeText(requireActivity(), getString(R.string.something_went_wrong), Toast.LENGTH_SHORT).show();
                }
            }
        });

        setupOtpInputs(dialogLoginView);
        initOtpReceiver(dialogLoginView);
        startSmsRetriever();
        
        isOtpSent = false;
        dialogLoginView.findViewById(R.id.linearNumberLayout).setVisibility(View.VISIBLE);
        dialogLoginView.findViewById(R.id.layoutOtpBoxes).setVisibility(View.GONE);

        btnConfirm.setOnClickListener(v -> {
            if (!isOtpSent) {
                initiatePhoneLogin();
            } else {
                verifyCodeFromInput(dialogLoginView);
            }
        });
        buttonClose.setOnClickListener(v -> {
            loginDialog.dismiss();
        });

        signInGoogle.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                signInWithGoogle();
            loginDialog.dismiss();
            }
        });

        loginDialog.setContentView(dialogLoginView);
        loginDialog.setCancelable(true);
        loginDialog.show();
    }

    private void initiatePhoneLogin() {
        EditText etPhone = dialogLoginView.findViewById(R.id.etPhone);
        CountryCodePicker ccp = dialogLoginView.findViewById(R.id.ccp);
        ccp.registerCarrierNumberEditText(etPhone);

        if (!ccp.isValidFullNumber()) {
            etPhone.setError(getString(R.string.enter_valid_number));
            return;
        }

        phoneNumber = ccp.getFullNumberWithPlus();
        startPhoneNumberVerification(phoneNumber);
    }

    private void setupOtpInputs(View view) {


        EditText etOtp1, etOtp2, etOtp3, etOtp4, etOtp5, etOtp6;
        etOtp1 = view.findViewById(R.id.etOtp1);
        etOtp2 = view.findViewById(R.id.etOtp2);
        etOtp3 = view.findViewById(R.id.etOtp3);
        etOtp4 = view.findViewById(R.id.etOtp4);
        etOtp5 = view.findViewById(R.id.etOtp5);
        etOtp6 = view.findViewById(R.id.etOtp6);

        EditText[] fields = new EditText[]{
                etOtp1, etOtp2, etOtp3, etOtp4, etOtp5, etOtp6
        };

        for (int i = 0; i < fields.length; i++) {
            final int index = i;
            EditText current = fields[i];

            current.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {
                }

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {
                }

                @Override
                public void afterTextChanged(Editable s) {
                    fields[index].setBackground(getResources().getDrawable(R.drawable.background_episode_num));
                    if (s.length() == 1) {
                        if (index < fields.length - 1) {
                            fields[index + 1].requestFocus();
                            fields[index + 1].setBackground(getResources().getDrawable(R.drawable.background_mobile_number));
                        } else {
                            verifyCodeFromInput(view);
                        }
                    }
                }
            });

            current.setOnKeyListener((v, keyCode, event) -> {

                if (event.getAction() == KeyEvent.ACTION_DOWN &&
                        keyCode == KeyEvent.KEYCODE_DEL) {
                    fields[index].setBackground(getResources().getDrawable(R.drawable.background_episode_num));

                    if (current.getText().length() == 0 && index > 0) {
                        fields[index - 1].requestFocus();
                        fields[index - 1].setText("");
                        fields[index - 1].setBackground(getResources().getDrawable(R.drawable.background_mobile_number));

                        return true;
                    }
                }
                return false;
            });
        }
    }

    private void verifyCodeFromInput(View view) {
        EditText etOtp1, etOtp2, etOtp3, etOtp4, etOtp5, etOtp6;
        etOtp1 = view.findViewById(R.id.etOtp1);
        etOtp2 = view.findViewById(R.id.etOtp2);
        etOtp3 = view.findViewById(R.id.etOtp3);
        etOtp4 = view.findViewById(R.id.etOtp4);
        etOtp5 = view.findViewById(R.id.etOtp5);
        etOtp6 = view.findViewById(R.id.etOtp6);


        String code = getEnteredOtp(etOtp1, etOtp2, etOtp3, etOtp4, etOtp5, etOtp6, view);
        if (TextUtils.isEmpty(code) || code.length() < 6) {
            Toast.makeText(requireActivity(), getString(R.string.enter_6_otp), Toast.LENGTH_SHORT).show();
            return;
        }
        if (verificationId == null) {
            Toast.makeText(requireActivity(), getString(R.string.otp_not_sent_please_wait),
                    Toast.LENGTH_SHORT).show();
            return;
        }

        PhoneAuthCredential credential =
                PhoneAuthProvider.getCredential(verificationId, code);
        signInWithCredential(credential, view);
    }

    private String getEnteredOtp(EditText etOtp1, EditText etOtp2, EditText etOtp3, EditText etOtp4, EditText etOtp5, EditText etOtp6, View view) {
        String d1 = etOtp1.getText().toString().trim();
        String d2 = etOtp2.getText().toString().trim();
        String d3 = etOtp3.getText().toString().trim();
        String d4 = etOtp4.getText().toString().trim();
        String d5 = etOtp5.getText().toString().trim();
        String d6 = etOtp6.getText().toString().trim();
        return d1 + d2 + d3 + d4 + d5 + d6;
    }

    private void signInWithCredential(PhoneAuthCredential credential, View view) {

        TextView btnConfirm = view.findViewById(R.id.btnConfirm);

      btnConfirm.setEnabled(false);
        mAuth.signInWithCredential(credential)
                .addOnCompleteListener(task -> {
                btnConfirm.setEnabled(true);
                    if (task.isSuccessful()) {
                        FirebaseUser user = FirebaseAuth.getInstance().getCurrentUser();
                        String uid = user.getUid();
                        String phone = user.getPhoneNumber();

                        String userId = "User" + phone.replace("+", "@").replaceAll("\\D", "");
                        saveUserToFirestore(
                                uid,
                                userId,
                                userId,
                                user.getPhoneNumber(),
                                "-",
                                "null",
                                "phone"
                        );

                        Toast.makeText(requireActivity(),
                                getString(R.string.login_successful),
                                Toast.LENGTH_SHORT).show();

                        if (loginListener != null) {
                            loginListener.onLoginSuccess();
                        }

                        // Setup ViewPager and dismiss dialog
                        setupViewPager();
                        if (loginDialog != null && loginDialog.isShowing()) {
                            loginDialog.dismiss();
                        }

                    } else {
                        Toast.makeText(requireActivity(), getString(R.string.invalid_or_expired_otp), Toast.LENGTH_SHORT).show();
                    }
                });
    }
    private void startPhoneNumberVerification(String phone) {
        PhoneAuthOptions options =
                PhoneAuthOptions.newBuilder(mAuth)
                        .setPhoneNumber(phone)
                        .setTimeout(60L, TimeUnit.SECONDS)
                        .setActivity(requireActivity())
                        .setCallbacks(callbacks)
                        .build();

        PhoneAuthProvider.verifyPhoneNumber(options);
    }

    private void initOtpReceiver(View view) {
        otpReceiver = new OTPReceiver();
        otpReceiver.initListener(new OTPReceiver.OtpReceiverListener() {
            @Override
            public void onOtpSuccess(String otp) {
                fillOtpBoxesFromCode(otp,view);
                verifyCodeFromInput(view);
            }

            @Override
            public void onOtpTimeout() {
                Toast.makeText(requireActivity(),
                        getString(R.string.unable_to_detect_otp),
                        Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void startSmsRetriever() {
        SmsRetrieverClient client = SmsRetriever.getClient(requireActivity());
        Task<Void> task = client.startSmsRetriever();
        task.addOnSuccessListener(new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(Void aVoid) {
            }
        }).addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
//                Toast.makeText(requireActivity(),
//                        "Failed to start SMS listener.",
//                        Toast.LENGTH_SHORT).show();
            }
        });
    }

//    private void resendCode() {
//        if (resendToken == null) {
//            if (phoneNumber != null) {
//                startPhoneNumberVerification(phoneNumber);
//            } else {
//                Toast.makeText(requireActivity(), "Phone number not found", Toast.LENGTH_SHORT).show();
//            }
//            return;
//        }
//
//        PhoneAuthOptions options =
//                PhoneAuthOptions.newBuilder(mAuth)
//                        .setPhoneNumber(phoneNumber)
//                        .setTimeout(60L, TimeUnit.SECONDS)
//                        .setActivity(requireActivity())
//                        .setCallbacks(callbacks)
//                        .setForceResendingToken(resendToken)
//                        .build();
//
//        PhoneAuthProvider.verifyPhoneNumber(options);
//    }

    private final PhoneAuthProvider.OnVerificationStateChangedCallbacks callbacks =
            new PhoneAuthProvider.OnVerificationStateChangedCallbacks() {

                @Override
                public void onVerificationCompleted(@NonNull PhoneAuthCredential credential) {
                    String smsCode = credential.getSmsCode();
                    if (smsCode != null && dialogLoginView != null) {
                        fillOtpBoxesFromCode(smsCode, dialogLoginView);
                    }
                    if (dialogLoginView != null) {
                        signInWithCredential(credential, dialogLoginView);
                    }
                }

                @Override
                public void onVerificationFailed(@NonNull FirebaseException e) {
                    Toast.makeText(requireActivity(),
                            getString(R.string.verification_failed) + ": " + e.getMessage(),
                            Toast.LENGTH_LONG).show();
                }

                             @Override
                public void onCodeSent(@NonNull String s,
                                       @NonNull PhoneAuthProvider.ForceResendingToken token) {
                    super.onCodeSent(s, token);
                    verificationId = s;
                    resendToken = token;
                    isOtpSent = true;
                    
                    if (dialogLoginView != null) {
                        dialogLoginView.findViewById(R.id.linearNumberLayout).setVisibility(View.GONE);
                        dialogLoginView.findViewById(R.id.layoutOtpBoxes).setVisibility(View.VISIBLE);
                    }
                    
                    Toast.makeText(requireActivity(),
                            getString(R.string.otp_sent),
                            Toast.LENGTH_SHORT).show();
                }
            };

    @Override
    public void onStart() {
        super.onStart();
        if (otpReceiver != null) {
            IntentFilter intentFilter = new IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                requireActivity().registerReceiver(otpReceiver, intentFilter, Context.RECEIVER_EXPORTED);
            } else {
                ContextCompat.registerReceiver(requireActivity(), otpReceiver, intentFilter, ContextCompat.RECEIVER_NOT_EXPORTED);
            }
        }
    }

    @Override
    public void onStop() {
        super.onStop();
        if (otpReceiver != null) {
            try {
                requireActivity().unregisterReceiver(otpReceiver);
            } catch (IllegalArgumentException ignored) {
            }
        }
    }
    private void fillOtpBoxesFromCode(String code, View view) {
        EditText etOtp1, etOtp2, etOtp3, etOtp4, etOtp5, etOtp6;
        etOtp1 = view.findViewById(R.id.etOtp1);
        etOtp2 = view.findViewById(R.id.etOtp2);
        etOtp3 = view.findViewById(R.id.etOtp3);
        etOtp4 = view.findViewById(R.id.etOtp4);
        etOtp5 = view.findViewById(R.id.etOtp5);
        etOtp6 = view.findViewById(R.id.etOtp6);
        if (code == null) return;
        if (code.length() >= 1) etOtp1.setText(String.valueOf(code.charAt(0)));
        if (code.length() >= 2) etOtp2.setText(String.valueOf(code.charAt(1)));
        if (code.length() >= 3) etOtp3.setText(String.valueOf(code.charAt(2)));
        if (code.length() >= 4) etOtp4.setText(String.valueOf(code.charAt(3)));
        if (code.length() >= 5) etOtp5.setText(String.valueOf(code.charAt(4)));
        if (code.length() >= 6) etOtp6.setText(String.valueOf(code.charAt(5)));
    }
}
