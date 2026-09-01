package com.snapdrama.shortstream.engineBox.aauth;

import com.snapdrama.shortstream.applicationPreference.ControlPreference;
import com.snapdrama.shortstream.engineBox.client.ApiConfig;

import okhttp3.HttpUrl;
import okhttp3.Interceptor;
import okhttp3.Request;
import okhttp3.Response;
import java.io.IOException;
import java.util.*;

public class AuthInterceptor implements Interceptor {

    @Override
    public Response intercept(Chain chain) throws IOException {

        Request original = chain.request();
        HttpUrl url = original.url();

        String timestamp = String.valueOf(System.currentTimeMillis() / 1000);

        String nonce = SignatureUtil.generateNonce(12);

        String path = url.encodedPath();

        List<String> keys = new ArrayList<>(url.queryParameterNames());
        Collections.sort(keys);

        List<String> values = new ArrayList<>();
        for (String key : keys) {
            values.add(url.queryParameter(key));
        }

        String queryValue = String.join(":", values);

        String toSign =
                timestamp +
                        ControlPreference.getMainAk() +
                        path +
                        nonce +
                        queryValue +
                        ControlPreference.getMainSk();

        String signature = SignatureUtil.hmacSHA256(toSign,  ControlPreference.getMainSk());

        Request newRequest = original.newBuilder()
                .addHeader("timestamp", timestamp)
                .addHeader("account", ControlPreference.getMainAk())
                .addHeader("Nonce", nonce)
                .addHeader("signature", signature)
                .addHeader("X-Side", "A")
                .addHeader("X-Package", ApiConfig.PACKAGE_NAME)
                .addHeader("Content-Type", "application/json")
                .build();

        return chain.proceed(newRequest);
    }
}
