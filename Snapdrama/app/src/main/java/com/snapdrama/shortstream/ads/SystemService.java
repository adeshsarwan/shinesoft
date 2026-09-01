package com.snapdrama.shortstream.ads;

import android.app.Dialog;
import android.content.Context;
import android.graphics.drawable.ColorDrawable;
import android.net.ConnectivityManager;
import android.view.View;
import android.widget.TextView;

import com.snapdrama.shortstream.R;

public class SystemService {
    public static Dialog noInternetDialog;
    public static no_internet slide_noInternet;

    public static void displayNoInternetDialog(Context context) {
        noInternetDialog = new Dialog(context);
        noInternetDialog.requestWindowFeature(1);
        noInternetDialog.getWindow().setBackgroundDrawable(new ColorDrawable(0));
        noInternetDialog.setContentView(R.layout.layout_internet_dialog);
        int width = -1;
        noInternetDialog.getWindow().setLayout(width, -2);
        noInternetDialog.setCancelable(false);
        noInternetDialog.show();
        TextView Retry = noInternetDialog.findViewById(R.id.vesm__cancel);
        Retry.setOnClickListener(new View.OnClickListener() {
            public void onClick(View v) {
                SystemService.slide_noInternet.no_internet();
            }
        });
    }
    public interface no_internet {
        void no_internet();
    }
    public static void checkNetworkAvailability(no_internet no_internet) {
        SystemService.slide_noInternet = no_internet;
    }

    public static boolean checkNetwork(Context context) {
        ConnectivityManager cm = (ConnectivityManager) context.getSystemService(Context.CONNECTIVITY_SERVICE);
        return cm.getActiveNetworkInfo() != null && cm.getActiveNetworkInfo().isConnected();
    }

}
