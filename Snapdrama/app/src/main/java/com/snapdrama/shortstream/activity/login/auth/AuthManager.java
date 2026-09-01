package com.snapdrama.shortstream.activity.login.auth;

import android.content.Context;
import android.content.Intent;
import android.net.ConnectivityManager;
import android.net.NetworkCapabilities;
import android.util.Log;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInAccount;
import com.google.android.gms.auth.api.signin.GoogleSignInClient;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.android.gms.common.api.ApiException;
import com.google.android.gms.tasks.Task;
import com.google.firebase.auth.AuthCredential;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.auth.FirebaseUser;
import com.google.firebase.auth.GoogleAuthProvider;
import com.google.firebase.auth.UserProfileChangeRequest;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.SetOptions;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

public class AuthManager {

    private static final String TAG = "AuthManager";

    private static volatile AuthManager INSTANCE;

    private final FirebaseAuth firebaseAuth;
    private final FirebaseFirestore firestore;
    private GoogleSignInClient googleSignInClient;

    private AuthManager() {
        firebaseAuth = FirebaseAuth.getInstance();
        firestore = FirebaseFirestore.getInstance();
    }

    public static AuthManager getInstance() {
        if (INSTANCE == null) {
            synchronized (AuthManager.class) {
                if (INSTANCE == null) {
                    INSTANCE = new AuthManager();
                }
            }
        }
        return INSTANCE;
    }


    public void initializeGoogleSignIn(Context context) {

        if (!isNetworkAvailable(context)) {
            return;
        }

        GoogleSignInOptions gso = new GoogleSignInOptions.Builder(
                GoogleSignInOptions.DEFAULT_SIGN_IN)
                .requestIdToken(context.getString(com.snapdrama.shortstream.R.string.default_web_client_id))
                .requestEmail()
                .build();

        googleSignInClient = GoogleSignIn.getClient(context, gso);
    }

    public Intent getGoogleSignInIntent(Context context) {
        if (googleSignInClient == null || !isNetworkAvailable(context)) {
            return null;
        }
        return googleSignInClient.getSignInIntent();
    }

    public GoogleSignInAccount handleGoogleSignInResult(Intent data) throws ApiException {
        Task<GoogleSignInAccount> task = GoogleSignIn.getSignedInAccountFromIntent(data);
        return task.getResult(ApiException.class);
    }

    public void signInWithGoogle(
            GoogleSignInAccount account,
            AuthCallback callback
    ) {

        AuthCredential credential =
                GoogleAuthProvider.getCredential(account.getIdToken(), null);

        firebaseAuth.signInWithCredential(credential)
                .addOnSuccessListener(authResult -> {

                    FirebaseUser user = authResult.getUser();

                    if (user == null) {
                        callback.onError(new Exception("User is null"));
                        return;
                    }

                    if (authResult.getAdditionalUserInfo() != null &&
                            authResult.getAdditionalUserInfo().isNewUser()) {



                    }

                    callback.onSuccess(user);
                })
                .addOnFailureListener(callback::onError);
    }





    public void signUpWithEmail(
            String email,
            String password,
            String name,
            AuthCallback callback
    ) {

        firebaseAuth.createUserWithEmailAndPassword(email, password)
                .addOnSuccessListener(authResult -> {

                    FirebaseUser user = authResult.getUser();
                    if (user == null) {
                        callback.onError(new Exception("User is null"));
                        return;
                    }

                    UserProfileChangeRequest request =
                            new UserProfileChangeRequest.Builder()
                                    .setDisplayName(name)
                                    .build();

                    user.updateProfile(request)
                            .addOnSuccessListener(unused -> {
                                saveUserToFirestore(user, name, email);
                                callback.onSuccess(user);
                            })
                            .addOnFailureListener(callback::onError);
                })
                .addOnFailureListener(callback::onError);
    }

    public void signInWithEmail(
            String email,
            String password,
            AuthCallback callback
    ) {

        firebaseAuth.signInWithEmailAndPassword(email, password)
                .addOnSuccessListener(authResult -> {
                    FirebaseUser user = authResult.getUser();
                    if (user != null) {
                        callback.onSuccess(user);
                    } else {
                        callback.onError(new Exception("Login failed"));
                    }
                })
                .addOnFailureListener(callback::onError);
    }

    /* -------------------- FIRESTORE -------------------- */

    private void saveUserToFirestore(
            FirebaseUser user,
            String name,
            String email
    ) {

//        String referralCode = generateReferralCode(user.getUid());
//
//        Map<String, Object> data = new HashMap<>();
//        data.put("uid", user.getUid());
//        data.put("name", name);
//        data.put("email", email);
//        data.put("createdAt", System.currentTimeMillis());
//        data.put("totalBalance", "0.000000005000");
//        data.put("miningAmount", "0.00000005000");
//        data.put("referralAmount", "0.000000000000");
//        data.put("referralCode", referralCode);
//        data.put("speedGh", 5.30f);
//        data.put("activeMiners", 104526);
//        data.put("gift1Boost", 25.2f);
//        data.put("gift2Boost", 50.6f);
//        data.put("hyperMineGh", 250.0f);
//
//        firestore.collection("users")
//                .document(user.getUid())
//                .set(data);
    }

    public void loadUserData(
            String uid,
            FirestoreCallback callback
    ) {

        firestore.collection("users")
                .document(uid)
                .get()
                .addOnSuccessListener(documentSnapshot -> {
                    if (documentSnapshot.exists()) {
                        callback.onSuccess(documentSnapshot.getData());
                    } else {
                        callback.onError(new Exception("User data not found"));
                    }
                })
                .addOnFailureListener(callback::onError);
    }

    public void updateMiningAmount(String uid, String amount) {
        Map<String, Object> map = new HashMap<>();
        map.put("totalBalance", amount);

        firestore.collection("users")
                .document(uid)
                .set(map, SetOptions.merge());
    }


    public FirebaseUser getCurrentUser() {
        return firebaseAuth.getCurrentUser();
    }

    public boolean isUserLoggedIn() {
        return firebaseAuth.getCurrentUser() != null;
    }

    public void signOut() {
        firebaseAuth.signOut();
        if (googleSignInClient != null) {
            googleSignInClient.signOut();
        }
    }

    private boolean isNetworkAvailable(Context context) {
        ConnectivityManager cm =
                (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);

        if (cm == null) return false;

        NetworkCapabilities nc =
                cm.getNetworkCapabilities(cm.getActiveNetwork());

        return nc != null && nc.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET);
    }

    private String generateReferralCode(String uid) {
        String prefix = uid.substring(0, 8).toUpperCase();
        int random = new Random().nextInt(9000) + 1000;
        return "BTC" + prefix + random;
    }


    public interface AuthCallback {
        void onSuccess(FirebaseUser user);
        void onError(Exception e);
    }

    public interface FirestoreCallback {
        void onSuccess(Map<String, Object> data);
        void onError(Exception e);
    }
}

