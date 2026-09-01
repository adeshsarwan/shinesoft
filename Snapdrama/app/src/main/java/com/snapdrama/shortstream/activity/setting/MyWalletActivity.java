package com.snapdrama.shortstream.activity.setting;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;

import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.firestore.ListenerRegistration;
import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity;
import com.snapdrama.shortstream.activity.payment.TransactionHistoryScreen;
import com.snapdrama.shortstream.activity.premium.ConsumptionRewardScreen;
import com.snapdrama.shortstream.activity.premium.TopUpActivity;
import com.snapdrama.shortstream.databinding.ActivityMyWalletBinding;
import com.snapdrama.shortstream.utils.coins.CoinsManager;

public class MyWalletActivity extends BaseOtherActivity {
    ActivityMyWalletBinding binding;
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        binding = ActivityMyWalletBinding.inflate(getLayoutInflater());
        setContentView(binding.getRoot());
        findViewById(R.id.btnBack).setOnClickListener(v -> {
            onBackPressed();
        });
        binding.btnTopupCoins.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MyWalletActivity.this, TopUpActivity.class);
                startActivity(intent);
            }
        });
        binding.imageTransactionHistory.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MyWalletActivity.this, TransactionHistoryScreen.class);
                startActivity(intent);

            }
        });
        binding.buttonConsumptionRecords.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(MyWalletActivity.this, ConsumptionRewardScreen.class);
                startActivity(intent);

            }
        });
        final String uid = FirebaseAuth.getInstance().getUid();
        if (uid!=null){
            ListenerRegistration[] reg = new ListenerRegistration[1];
            reg[0] = CoinsManager.listenCoins(uid, new CoinsManager.CoinsListener() {
                @Override
                public void onCoinsChanged(long coins) {
                    if (binding.tvBalanceValue != null) binding.tvBalanceValue.setText(String.valueOf(coins));

                }

                @Override
                public void onError(@NonNull Exception e) {
                }
            });
        }





    }

    @Override
    public void onBackPressed() {
        super.onBackPressed();
        finish();
    }
}