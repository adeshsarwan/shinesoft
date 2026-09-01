package com.snapdrama.shortstream.activity.login;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;

import com.google.android.gms.auth.api.phone.SmsRetriever;
import com.google.android.gms.common.api.CommonStatusCodes;
import com.google.android.gms.common.api.Status;

import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class OTPReceiver extends BroadcastReceiver {

    private OtpReceiverListener otpReceiverListener;

    public void initListener(OtpReceiverListener otpReceiverListener) {
        this.otpReceiverListener = otpReceiverListener;
    }

    @Override
    public void onReceive(Context context, Intent intent) {
        if (SmsRetriever.SMS_RETRIEVED_ACTION.equals(intent.getAction())) {
            Bundle extras = intent.getExtras();
            if (extras == null) return;

            Status status = (Status) extras.get(SmsRetriever.EXTRA_STATUS);
            if (status == null) return;

            switch (status.getStatusCode()) {
                case CommonStatusCodes.SUCCESS:
                    String message = (String) extras.get(SmsRetriever.EXTRA_SMS_MESSAGE);
                    if (message != null) {
                        Pattern pattern = Pattern.compile("\\d{6}");
                        Matcher matcher = pattern.matcher(message);
                        if (matcher.find()) {
                            String myOtp = matcher.group(0);
                            if (otpReceiverListener != null) {
                                otpReceiverListener.onOtpSuccess(myOtp);
                            }
                        } else {
                            if (otpReceiverListener != null) {
                                otpReceiverListener.onOtpTimeout();
                            }
                        }
                    }
                    break;

                case CommonStatusCodes.TIMEOUT:
                    if (otpReceiverListener != null) {
                        otpReceiverListener.onOtpTimeout();
                    }
                    break;

                default:
                    break;
            }
        }
    }

    public interface OtpReceiverListener {
        void onOtpSuccess(String otp);
        void onOtpTimeout();
    }
}

