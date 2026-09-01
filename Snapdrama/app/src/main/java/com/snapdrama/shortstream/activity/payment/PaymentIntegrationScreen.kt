package com.snapdrama.shortstream.activity.payment

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import android.widget.EditText
import android.widget.ImageView
import androidx.appcompat.app.AppCompatActivity
import com.snapdrama.shortstream.R

class PaymentIntegrationScreen : AppCompatActivity() {
    lateinit var btnCheckout: Button
    lateinit var totalAmt: EditText
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_payment_integration_screen)
        btnCheckout = findViewById<Button>(R.id.btnCheckout)
        totalAmt = findViewById<EditText>(R.id.totalAmt)
 btnCheckout.setOnClickListener {
            Intent(this, CheckoutActivity::class.java).also {
                it.putExtra("amount", totalAmt.text.toString().toFloat())
                startActivity(it)
            }
        }
    }

}