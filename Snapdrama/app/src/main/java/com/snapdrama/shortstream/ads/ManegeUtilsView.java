package com.snapdrama.shortstream.ads;

import android.content.Context;


import com.snapdrama.shortstream.R;
import com.snapdrama.shortstream.engineBox.client.ApiConfig;

import java.io.UnsupportedEncodingException;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.NoSuchAlgorithmException;

import javax.crypto.BadPaddingException;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.NoSuchPaddingException;

public class ManegeUtilsView {

    public static void isUtilsManege(Context context) {


        ManegeParameter.asadpass = String.format(ManegeParameter.sdfsvdfvs+ context.getString(R.string.awsdahdbh));
        ManegeParameter.sdasdada = ManegeParameter.ksgqwl+ context.getString(R.string.tyebsnbdanadjakjjdajjaoaduioskmdjk);


        try {
          ApiConfig.ssfsfsfsf = ManegeParameter.cipherSignatureSpace( ManegeParameter.asadpass,  ManegeParameter.sdasdada);
        } catch (UnsupportedEncodingException e) {
            throw new RuntimeException(e);
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException(e);
        } catch (NoSuchPaddingException e) {
            throw new RuntimeException(e);
        } catch (InvalidAlgorithmParameterException e) {
            throw new RuntimeException(e);
        } catch (InvalidKeyException e) {
            throw new RuntimeException(e);
        } catch (BadPaddingException e) {
            throw new RuntimeException(e);
        } catch (IllegalBlockSizeException e) {
            throw new RuntimeException(e);
        }

    }



}
