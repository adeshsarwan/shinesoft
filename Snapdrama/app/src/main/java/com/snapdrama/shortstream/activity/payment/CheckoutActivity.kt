package com.snapdrama.shortstream.activity.payment

import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import com.github.kittinunf.fuel.httpPost
import com.github.kittinunf.fuel.json.responseJson
import com.github.kittinunf.result.Result
import com.google.firebase.auth.FirebaseAuth
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.applicationPreference.ControlPreference
import com.snapdrama.shortstream.databinding.ActivityCheckoutBinding
import com.stripe.android.PaymentConfiguration
import com.stripe.android.paymentsheet.PaymentSheet
import com.stripe.android.paymentsheet.PaymentSheetResult

/**
 * Stripe Checkout Activity - used from RewardAdManager premium dialog.
 * Extras: amount (float), purchase_type (int: 1-4=coin packs, 10=weekly, 11=yearly), coins_to_add (long).
 * On success: setResult(RESULT_OK) with same extras for caller to add coins / save premium.
 */
class CheckoutActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_AMOUNT = "amount"
        const val EXTRA_PURCHASE_TYPE = "purchase_type"
        const val EXTRA_COINS_TO_ADD = "coins_to_add"
        const val PURCHASE_TYPE_COINS_PACK_1 = 1
        const val PURCHASE_TYPE_COINS_PACK_2 = 2
        const val PURCHASE_TYPE_COINS_PACK_3 = 3
        const val PURCHASE_TYPE_COINS_PACK_4 = 4
        const val PURCHASE_TYPE_WEEKLY = 10
        const val PURCHASE_TYPE_YEARLY = 11
    }

    private lateinit var paymentSheet: PaymentSheet
    private lateinit var customerConfig: PaymentSheet.CustomerConfiguration
    private lateinit var paymentIntentClientSecret: String
    private lateinit var binding: ActivityCheckoutBinding

    private var amount: Float = 0f
    private var purchaseType: Int = 0
    private var coinsToAdd: Long = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityCheckoutBinding.inflate(layoutInflater)
        setContentView(binding.root)
        paymentSheet = PaymentSheet(this, ::onPaymentSheetResult)

        amount = intent.getFloatExtra(EXTRA_AMOUNT, 0f)
        purchaseType = intent.getIntExtra(EXTRA_PURCHASE_TYPE, 0)
        coinsToAdd = intent.getLongExtra(EXTRA_COINS_TO_ADD, 0L)

        binding.tvTotalAmount.text = amount.toString()
        binding.button.setOnClickListener { presentPaymentSheet() }
        binding.button.isEnabled = false
        validateFromServer(amount)
    }

    private fun validateFromServer(amount: Float) {
        val url = ControlPreference.getTransactionUrl() + getString(R.string.end_point)
        val country = ControlPreference.getCountryName()
        val currency = if (country.equals("IN", ignoreCase = true)) "inr" else "usd"
        val user = FirebaseAuth.getInstance().currentUser
        val email = user?.email ?: "user@example.com"
        val name = user?.displayName ?: (user?.email?.substringBefore('@') ?: "User")

        val amountSmallestUnit = (amount * 100).toLong()
        val params = listOf(
            "amount" to amountSmallestUnit,
            "currency" to currency,
            "email" to email,
            "name" to name,
        )
        url.httpPost(params).responseJson { req, res, result ->
            Log.d("StripeCheckout", "Request: $req, Response: $res")
            runOnUiThread {
                when (result) {
                    is Result.Success -> {
                        val responseJson = result.get().obj()
                        paymentIntentClientSecret = responseJson.getString("paymentIntent")
                        val customerId = responseJson.getString("customer")
                        val ephemeralKeySecret = responseJson.getString("ephemeralKey")
                        customerConfig = PaymentSheet.CustomerConfiguration(customerId, ephemeralKeySecret)
                        val publishableKey = responseJson.getString("publishableKey")
                        PaymentConfiguration.init(this, publishableKey)
                        presentPaymentSheet()
                        binding.button.isEnabled = true
                    }
                    is Result.Failure -> {
                        showAlert("Error validating from server. Make sure server is running and API URL is correct in strings.xml")
                    }
                }
            }
        }
    }

    private fun presentPaymentSheet() {
        paymentSheet.presentWithPaymentIntent(
            paymentIntentClientSecret,
            PaymentSheet.Configuration(
                merchantDisplayName = "Snap Drama",
                customer = customerConfig,
                allowsDelayedPaymentMethods = true
            )
        )
    }

    private fun onPaymentSheetResult(paymentSheetResult: PaymentSheetResult) {
        when (paymentSheetResult) {
            is PaymentSheetResult.Canceled -> {
                Toast.makeText(this, getString(R.string.payment_cancelled), Toast.LENGTH_SHORT).show()
                setResult(RESULT_CANCELED)
                finish()
            }
            is PaymentSheetResult.Failed -> {
                showAlert(getString(R.string.payment_failed) + ": ${paymentSheetResult.error.message}")
                setResult(RESULT_CANCELED)
                finish()
            }
            is PaymentSheetResult.Completed -> {
                val resultIntent = Intent().apply {
                    putExtra(EXTRA_AMOUNT, amount)
                    putExtra(EXTRA_PURCHASE_TYPE, purchaseType)
                    putExtra(EXTRA_COINS_TO_ADD, coinsToAdd)
                }
                setResult(RESULT_OK, resultIntent)
                finish()
            }
        }
    }

    private fun showAlert(message: String) {
        AlertDialog.Builder(this)
            .setTitle("Stripe " +  getString(R.string.stripe_checkout))
            .setMessage(message)
            .setPositiveButton(getString(R.string.ok)) { _, _ -> finish() }
            .setCancelable(false)
            .show()
    }
}