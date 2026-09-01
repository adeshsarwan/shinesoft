package com.snapdrama.shortstream.activity.login;

import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.graphics.Insets;
import android.os.Build;
import android.os.Bundle;
import android.support.annotation.NonNull;
import android.text.Editable;
import android.text.TextUtils;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.View;
import android.view.WindowInsets;
import android.widget.EditText;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.gms.auth.api.phone.SmsRetriever;
import com.google.android.gms.auth.api.phone.SmsRetrieverClient;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.android.gms.tasks.Task;
import com.google.firebase.FirebaseException;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.auth.PhoneAuthCredential;
import com.google.firebase.auth.PhoneAuthOptions;
import com.google.firebase.auth.PhoneAuthProvider;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.main.activity.HomeScreenActivity;
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity;
import com.snapdrama.shortstream.utils.coins.CoinsManager;
import com.snapdrama.shortstream.databinding.ActivityOtpReceiveScreenBinding;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

public class OtpReceiveScreen extends BaseOtherActivity {

    public static final String EXTRA_PHONE = "PHONE_NUMBER";

    private ActivityOtpReceiveScreenBinding binding;
    private FirebaseAuth mAuth;
    private String phoneNumber;
    private String verificationId;
    private PhoneAuthProvider.ForceResendingToken resendToken;

    private OTPReceiver otpReceiver;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityOtpReceiveScreenBinding.inflate(getLayoutInflater());
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
        mAuth = FirebaseAuth.getInstance();
        phoneNumber = getIntent().getStringExtra(EXTRA_PHONE);
        if (TextUtils.isEmpty(phoneNumber)) {
            Toast.makeText(this, getString(R.string.invalid_otp), Toast.LENGTH_LONG).show();
            finish();
            return;
        }

            binding.textSubtitle.setText( getString(R.string.we_have_sent_the_verification_code_to_your_phone_number) + " " + phoneNumber);
        binding.btnBack.setOnClickListener(v -> onBackPressed());
        binding.btnConfirm.setOnClickListener(v -> verifyCodeFromInput());
        binding.textResend.setOnClickListener(v -> resendCode());

        setupOtpInputs();
        initOtpReceiver();
        startSmsRetriever();
        startPhoneNumberVerification(phoneNumber);
    }

    private void startPhoneNumberVerification(String phone) {
        PhoneAuthOptions options =
                PhoneAuthOptions.newBuilder(mAuth)
                        .setPhoneNumber(phone)
                        .setTimeout(60L, TimeUnit.SECONDS)
                        .setActivity(this)
                        .setCallbacks(callbacks)
                        .build();

        PhoneAuthProvider.verifyPhoneNumber(options);
    }

    private void initOtpReceiver() {
        otpReceiver = new OTPReceiver();
        otpReceiver.initListener(new OTPReceiver.OtpReceiverListener() {
            @Override
            public void onOtpSuccess(String otp) {
                fillOtpBoxesFromCode(otp);
                verifyCodeFromInput();
            }

            @Override
            public void onOtpTimeout() {
                Toast.makeText(OtpReceiveScreen.this,
                        getString(R.string.unable_to_detect_otp),
                        Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void startSmsRetriever() {
        SmsRetrieverClient client = SmsRetriever.getClient(this);
        Task<Void> task = client.startSmsRetriever();
        task.addOnSuccessListener(new OnSuccessListener<Void>() {
            @Override
            public void onSuccess(Void aVoid) {
            }
        }).addOnFailureListener(new OnFailureListener() {
            @Override
            public void onFailure(@NonNull Exception e) {
//                Toast.makeText(OtpReceiveScreen.this,
//                        "Failed to start SMS listener.",
//                        Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void resendCode() {
        if (resendToken == null) {
            startPhoneNumberVerification(phoneNumber);
            return;
        }

        PhoneAuthOptions options =
                PhoneAuthOptions.newBuilder(mAuth)
                        .setPhoneNumber(phoneNumber)
                        .setTimeout(60L, TimeUnit.SECONDS)
                        .setActivity(this)
                        .setCallbacks(callbacks)
                        .setForceResendingToken(resendToken)
                        .build();

        PhoneAuthProvider.verifyPhoneNumber(options);
    }

    private final PhoneAuthProvider.OnVerificationStateChangedCallbacks callbacks =
            new PhoneAuthProvider.OnVerificationStateChangedCallbacks() {

                @Override
                public void onVerificationCompleted(@NonNull PhoneAuthCredential credential) {
                    String smsCode = credential.getSmsCode();
                    if (smsCode != null) {
                        fillOtpBoxesFromCode(smsCode);
                    }
                    signInWithCredential(credential);
                }

                @Override
                public void onVerificationFailed(@NonNull FirebaseException e) {
                    Toast.makeText(OtpReceiveScreen.this,
                            getString(R.string.request_blocked_please_try_again),
                            Toast.LENGTH_LONG).show();
                }

                @Override
                public void onCodeSent(@NonNull String s,
                                       @NonNull PhoneAuthProvider.ForceResendingToken token) {
                    super.onCodeSent(s, token);
                    verificationId = s;
                    resendToken = token;
                    Toast.makeText(OtpReceiveScreen.this,
                            getString(R.string.otp_sent),
                            Toast.LENGTH_SHORT).show();
                }
            };

    @Override
    protected void onStart() {
        super.onStart();
        if (otpReceiver != null) {
            IntentFilter intentFilter = new IntentFilter(SmsRetriever.SMS_RETRIEVED_ACTION);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(otpReceiver, intentFilter, Context.RECEIVER_EXPORTED);
            } else {
                registerReceiver(otpReceiver, intentFilter);
            }
        }
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (otpReceiver != null) {
            try {
                unregisterReceiver(otpReceiver);
            } catch (IllegalArgumentException ignored) {
            }
        }
    }

    private void verifyCodeFromInput() {
        String code = getEnteredOtp();
        if (TextUtils.isEmpty(code) || code.length() < 6) {
            Toast.makeText(this, getString(R.string.enter_6_otp), Toast.LENGTH_SHORT).show();
            return;
        }
        if (verificationId == null) {
            Toast.makeText(this, getString(R.string.otp_not_sent_please_wait),
                    Toast.LENGTH_SHORT).show();
            return;
        }

        PhoneAuthCredential credential =
                PhoneAuthProvider.getCredential(verificationId, code);
        signInWithCredential(credential);
    }

    private String getEnteredOtp() {
        String d1 = binding.etOtp1.getText().toString().trim();
        String d2 = binding.etOtp2.getText().toString().trim();
        String d3 = binding.etOtp3.getText().toString().trim();
        String d4 = binding.etOtp4.getText().toString().trim();
        String d5 = binding.etOtp5.getText().toString().trim();
        String d6 = binding.etOtp6.getText().toString().trim();
        return d1 + d2 + d3 + d4+ d5+ d6;
    }

    private void fillOtpBoxesFromCode(String code) {
        if (code == null) return;
        if (code.length() >= 1) binding.etOtp1.setText(String.valueOf(code.charAt(0)));
        if (code.length() >= 2) binding.etOtp2.setText(String.valueOf(code.charAt(1)));
        if (code.length() >= 3) binding.etOtp3.setText(String.valueOf(code.charAt(2)));
        if (code.length() >= 4) binding.etOtp4.setText(String.valueOf(code.charAt(3)));
        if (code.length() >= 5) binding.etOtp5.setText(String.valueOf(code.charAt(4)));
        if (code.length() >= 6) binding.etOtp6.setText(String.valueOf(code.charAt(5)));
    }


    private void setupOtpInputs() {
        EditText[] fields = new EditText[]{
                binding.etOtp1, binding.etOtp2, binding.etOtp3, binding.etOtp4,binding.etOtp5, binding.etOtp6
        };

        for (int i = 0; i < fields.length; i++) {
            final int index = i;
            EditText current = fields[i];

            current.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

                @Override
                public void onTextChanged(CharSequence s, int start, int before, int count) {}

                @Override
                public void afterTextChanged(Editable s) {
                    fields[index].setBackground(getResources().getDrawable(R.drawable.background_episode_num));
                    if (s.length() == 1) {
                        if (index < fields.length - 1) {
                            fields[index + 1].requestFocus();
                            fields[index + 1].setBackground(getResources().getDrawable(R.drawable.background_mobile_number));
                        } else {
                            verifyCodeFromInput();
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
                        fields[index- 1].setBackground(getResources().getDrawable(R.drawable.background_mobile_number));

                        return true;
                    }
                }
                return false;
            });
        }
    }

    private void signInWithCredential(PhoneAuthCredential credential) {
        binding.btnConfirm.setEnabled(false);
        mAuth.signInWithCredential(credential)
                .addOnCompleteListener(task -> {
                    binding.btnConfirm.setEnabled(true);
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

                        Toast.makeText(this,
                                getString(R.string.login_successful),
                                Toast.LENGTH_SHORT).show();

                        Intent intent = new Intent(this, HomeScreenActivity.class);
                        intent.addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP
                                | Intent.FLAG_ACTIVITY_NEW_TASK
                                | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                        startActivity(intent);
                        finish();
                    } else {
                        Toast.makeText(this, getString(R.string.invalid_or_expired_otp), Toast.LENGTH_SHORT).show();
                    }
                });
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
}
