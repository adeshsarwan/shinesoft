package com.snapdrama.shortstream.utils.coins;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;
import com.google.firebase.firestore.DocumentReference;
import com.google.firebase.firestore.DocumentSnapshot;
import com.google.firebase.firestore.EventListener;
import com.google.firebase.firestore.FieldValue;
import com.google.firebase.firestore.FirebaseFirestore;
import com.google.firebase.firestore.FirebaseFirestoreException;
import com.google.firebase.firestore.ListenerRegistration;
import com.google.firebase.firestore.SetOptions;
import com.google.firebase.firestore.Transaction;

import java.util.HashMap;
import java.util.Map;

public final class CoinsManager {
    private CoinsManager() {}

    public static final String USERS_COLLECTION = "users";
    public static final String FIELD_COINS = "coins";
    public static final String FIELD_CREATED_AT = "createdAt";
    public static final String FIELD_UPDATED_AT = "updatedAt";

    public static final long DEFAULT_FIRST_LOGIN_COINS = 200L;

    @NonNull
    public static DocumentReference userRef(@NonNull String uid) {
        return FirebaseFirestore.getInstance()
                .collection(USERS_COLLECTION)
                .document(uid);
    }

    public interface CoinsListener {
        void onCoinsChanged(long coins);
        void onError(@NonNull Exception e);
    }

    public interface SpendCallback {
        void onSuccess(long newBalance);
        void onInsufficient(long currentBalance);
        void onError(@NonNull Exception e);
    }

    public static void ensureUserInitialized(
            @NonNull String uid,
            @NonNull Map<String, Object> userFields,
            long initialCoins
    ) {
        final DocumentReference ref = userRef(uid);

        FirebaseFirestore.getInstance().runTransaction(tx -> {
            DocumentSnapshot snap = tx.get(ref);

            Map<String, Object> map = new HashMap<>(userFields);
            map.put(FIELD_UPDATED_AT, FieldValue.serverTimestamp());

            boolean shouldSetInitialCoins = false;
            if (!snap.exists()) {
                shouldSetInitialCoins = true;
                map.put(FIELD_CREATED_AT, FieldValue.serverTimestamp());
            } else if (!snap.contains(FIELD_COINS) || snap.get(FIELD_COINS) == null) {
                shouldSetInitialCoins = true;
            }

            if (shouldSetInitialCoins) {
                map.put(FIELD_COINS, Math.max(0L, initialCoins));
            }

            tx.set(ref, map, SetOptions.merge());
            return null;
        });
    }

    public static void addCoins(
            @NonNull String uid,
            long amount,
            @Nullable OnSuccessListener<Void> onSuccess,
            @Nullable OnFailureListener onFailure
    ) {
        if (amount <= 0) {
            if (onFailure != null) onFailure.onFailure(new IllegalArgumentException("amount must be > 0"));
            return;
        }
        final DocumentReference ref = userRef(uid);
        FirebaseFirestore.getInstance()
                .runTransaction(new Transaction.Function<Void>() {
                    @Override
                    public Void apply(@NonNull Transaction tx) throws FirebaseFirestoreException {
                        DocumentSnapshot snap = tx.get(ref);

                        long current = 0L;
                        Object coinsObj = snap.get(FIELD_COINS);
                        if (coinsObj instanceof Number) {
                            current = ((Number) coinsObj).longValue();
                        }

                        Map<String, Object> updates = new HashMap<>();
                        if (!snap.exists()) {
                            updates.put(FIELD_CREATED_AT, FieldValue.serverTimestamp());
                        }
                        updates.put(FIELD_COINS, Math.max(0L, current) + amount);
                        updates.put(FIELD_UPDATED_AT, FieldValue.serverTimestamp());

                        tx.set(ref, updates, SetOptions.merge());
                        return null;
                    }
                })
                .addOnSuccessListener(onSuccess)
                .addOnFailureListener(onFailure);
    }

    public static void spendCoins(
            @NonNull String uid,
            long amount,
            @NonNull SpendCallback callback
    ) {
        if (amount <= 0) {
            callback.onError(new IllegalArgumentException("amount must be > 0"));
            return;
        }

        final DocumentReference ref = userRef(uid);
        FirebaseFirestore.getInstance().runTransaction(tx -> {
            DocumentSnapshot snap = tx.get(ref);
            long current = 0L;
            Object coinsObj = snap.get(FIELD_COINS);
            if (coinsObj instanceof Number) {
                current = ((Number) coinsObj).longValue();
            }

            if (current < amount) {
                return new long[]{ current, -1L };
            }

            long newBalance = current - amount;
            Map<String, Object> updates = new HashMap<>();
            updates.put(FIELD_COINS, newBalance);
            updates.put(FIELD_UPDATED_AT, FieldValue.serverTimestamp());
            tx.set(ref, updates, SetOptions.merge());

            return new long[]{current, newBalance};
        }).addOnSuccessListener(result -> {
            long current = result[0];
            long newBal = result[1];
            if (newBal < 0L) {
                callback.onInsufficient(current);
            } else {
                callback.onSuccess(newBal);
            }
        }).addOnFailureListener(callback::onError);
    }

    @NonNull
    public static ListenerRegistration listenCoins(
            @NonNull String uid,
            @NonNull CoinsListener listener
    ) {
        return userRef(uid).addSnapshotListener(new EventListener<DocumentSnapshot>() {
            @Override
            public void onEvent(@Nullable DocumentSnapshot value, @Nullable FirebaseFirestoreException error) {
                if (error != null) {
                    listener.onError(error);
                    return;
                }
                if (value == null || !value.exists()) {
                    listener.onCoinsChanged(0L);
                    return;
                }
                long coins = 0L;
                Object obj = value.get(FIELD_COINS);
                if (obj instanceof Number) {
                    coins = ((Number) obj).longValue();
                }
                listener.onCoinsChanged(Math.max(0L, coins));
            }
        });
    }
}

