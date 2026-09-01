package com.snapdrama.shortstream.activity.premium

import android.app.Activity
import android.graphics.Paint
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.widget.TextView
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity

import com.google.firebase.auth.FirebaseAuth
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.adapter.ShortDramaAdapter
import com.snapdrama.shortstream.ads.PremiumPlanManager
import com.snapdrama.shortstream.ads.PremiumPlanManager.SavePremiumCallback
import com.snapdrama.shortstream.ads.RewardAdManager
import com.snapdrama.shortstream.applicationPreference.ControlPreference
import com.snapdrama.shortstream.databinding.ActivityPremiumMemberBinding
import com.snapdrama.shortstream.mvvmRepo.model.PopularSeriesViewModel
import com.snapdrama.shortstream.utils.coins.CoinsManager
import com.stripe.android.PaymentConfiguration
import com.stripe.android.paymentsheet.PaymentSheet
import com.stripe.android.paymentsheet.PaymentSheet.CustomerConfiguration
import com.stripe.android.paymentsheet.PaymentSheetResult
import com.stripe.android.paymentsheet.PaymentSheetResultCallback
import okhttp3.Call
import okhttp3.Callback
import okhttp3.FormBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import org.json.JSONObject
import java.io.IOException
import androidx.lifecycle.ViewModelProvider
import androidx.recyclerview.widget.GridLayoutManager
import com.google.android.gms.tasks.OnFailureListener
import com.google.android.gms.tasks.OnSuccessListener
class PremiumMemberActivity : BaseOtherActivity() {
    lateinit var binding: ActivityPremiumMemberBinding
    lateinit var popularSeriesViewModel: PopularSeriesViewModel
    private val http = OkHttpClient()
    private val mainHandler = Handler(Looper.getMainLooper())
    private var isPaymentProcessing = false

    private lateinit var paymentSheet: PaymentSheet
    private lateinit var customerConfig: CustomerConfiguration
    private lateinit var paymentIntentClientSecret: String

    private var pendingPurchaseType = 0
    private var pendingCoinsToAdd = 0L
    private var pendingPrice = 0.0
    var planCheck = true
    private var adShowing = false

    private lateinit var adapter: ShortDramaAdapter
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityPremiumMemberBinding.inflate(layoutInflater)
        setContentView(binding.root)
        binding.textViewWeekMemberShip2.setPaintFlags(Paint.STRIKE_THRU_TEXT_FLAG)

        paymentSheet = PaymentSheet(
            this,
            PaymentSheetResultCallback { result: PaymentSheetResult ->
                this.onPaymentSheetResult(
                    result
                )
            })

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                finish()
            }
        })
        binding.btnBack.setOnClickListener {
            finish()
        }


        val country = ControlPreference.getCountryName()

        val jsonObject: JSONObject?

        if (country.equals("IN", ignoreCase = true)) {
            jsonObject = JSONObject(ControlPreference.getInrPlans())
        } else {
            jsonObject = JSONObject(ControlPreference.getUsdPlans())
        }


        val plan5 = jsonObject.getJSONObject("weekly_membership")
        setMemberPlan(
            plan5,
            binding.textViewWeekMemberShip1,
            binding.textViewWeekMemberShip2,
            binding.textViewWeekMemberShip3,
            country
        )

        val plan6 = jsonObject.getJSONObject("yearly_membership")
        setMemberPlan(
            plan6,
            binding.textViewYearMemberShip1,
            binding.textViewYearMemberShip2,
            binding.textViewYearMemberShip3,
            country
        )
        val main_price1 = plan5.getDouble("main_price")
        val main_price2 = plan6.getDouble("main_price")

        val padding = (26 * resources.displayMetrics.density).toInt()

        binding.linearWeeklyMember.setOnClickListener {
            planCheck = true

            binding.relativeWeeklyMemberShip.setBackgroundResource(R.drawable.background_reward_coins_rec3)
            binding.relativeAnnualMemberShip.setBackgroundResource(R.drawable.background_annual_membership)

            binding.relativeWeeklyMemberShip.setPadding(
                binding.relativeWeeklyMemberShip.paddingLeft,
                padding,
                binding.relativeWeeklyMemberShip.paddingRight,
                padding
            )

            binding.relativeAnnualMemberShip.setPadding(
                binding.relativeAnnualMemberShip.paddingLeft,
                padding,
                binding.relativeAnnualMemberShip.paddingRight,
                padding
            )
        }

        binding.linearAnnualMember.setOnClickListener {
            planCheck = false

            binding.relativeWeeklyMemberShip.setBackgroundResource(R.drawable.background_annual_membership)
            binding.relativeAnnualMemberShip.setBackgroundResource(R.drawable.background_reward_coins_rec3)

            binding.relativeWeeklyMemberShip.setPadding(
                binding.relativeWeeklyMemberShip.paddingLeft,
                padding,
                binding.relativeWeeklyMemberShip.paddingRight,
                padding
            )

            binding.relativeAnnualMemberShip.setPadding(
                binding.relativeAnnualMemberShip.paddingLeft,
                padding,
                binding.relativeAnnualMemberShip.paddingRight,
                padding
            )
        }
binding.buttonJoinNow.setOnClickListener {
    val firebaseUser = FirebaseAuth.getInstance().currentUser
    if (firebaseUser == null) {
        Toast.makeText(this@PremiumMemberActivity, getString(R.string.please_login_first), Toast.LENGTH_SHORT).show()
        return@setOnClickListener
    }
    if (planCheck){
        val finalMain_price: Double = main_price1
        if (isPaymentProcessing) return@setOnClickListener
        isPaymentProcessing = true


        startStripePayment(
            this@PremiumMemberActivity,
            finalMain_price.toString().toFloat(),
            RewardAdManager.PURCHASE_TYPE_WEEKLY,
            0L,
            finalMain_price
        )
    }
    else{
        val finalMain_price1: Double = main_price2
        if (isPaymentProcessing) return@setOnClickListener
        isPaymentProcessing = true
            startStripePayment(
                this@PremiumMemberActivity,
                finalMain_price1.toString().toFloat(),
                RewardAdManager.PURCHASE_TYPE_YEARLY,
                0L,
                finalMain_price1
            )

    }
}

        setupObserver()
    }


    private fun setupObserver() {

        popularSeriesViewModel = ViewModelProvider(this)
            .get(PopularSeriesViewModel::class.java)

        popularSeriesViewModel.getPopularSeries()
            .observe(this) { response ->

                if (response != null &&
                    response.data != null &&
                    response.data.isNotEmpty()
                ) {

                    binding.recycleView.layoutManager =
                        GridLayoutManager(this, 3)

                    binding.recycleView.setHasFixedSize(true)

                    adapter = ShortDramaAdapter(
                        this,
                        response.data,
                        0
                    )

                    binding.recycleView.adapter = adapter

                } else {
                }
            }
    }

    private fun setMemberPlan(
        plan5: JSONObject,
        tvWeeklyMemberShip1: TextView,
        tvWeeklyMemberShip2: TextView,
        tvWeeklyMemberTitle: TextView,
        country: String
    ) {
        try {
            val main_price = plan5.getDouble("main_price")
            val discount_price = plan5.getString("discount_price")
            val title = plan5.getString("title")



            if (country.equals("IN", ignoreCase = true)) {
                tvWeeklyMemberShip1.setText("₹ " + main_price)
                tvWeeklyMemberShip2.setText(discount_price)
                tvWeeklyMemberTitle.setText(title)
            } else {
                tvWeeklyMemberShip1.setText("$ " + main_price)
                tvWeeklyMemberTitle.setText(discount_price)
                tvWeeklyMemberTitle.setText(" + " + title)
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }



    private fun startStripePayment(
        activity: Activity,
        amount: Float,
        purchaseType: Int,
        coinsToAdd: Long,
        priceForPremium: Double,

        ) {
        if (paymentSheet == null) {
            Toast.makeText(
                this@PremiumMemberActivity,
                "Stripe not initialized yet",
                Toast.LENGTH_SHORT
            ).show()
            return
        }


        pendingPurchaseType = purchaseType
        pendingCoinsToAdd = coinsToAdd
        pendingPrice = priceForPremium

        validateFromServerAndPresent(activity, amount)
    }

    private fun validateFromServerAndPresent(activity: Activity, amount: Float) {
        val apiUrl: String = ControlPreference.getTransactionUrl() +this@PremiumMemberActivity.getString(R.string.end_point)
        val country = ControlPreference.getCountryName()
        val currency =
            if (country != null && country.equals("IN", ignoreCase = true)) "inr" else "usd"

        val user = FirebaseAuth.getInstance().getCurrentUser()
        val email =
            if (user != null && user.getEmail() != null) user.getEmail() else "user@example.com"
        val name = if (user != null && user.getDisplayName() != null)
            user.getDisplayName()
        else
            (if (email!!.contains("@")) email.substring(0, email.indexOf('@')) else "User")

        val amountSmallestUnit = (amount * 100f).toLong()

        val userId = FirebaseAuth.getInstance().uid
        val body = FormBody.Builder()
            .add("amount", amountSmallestUnit.toString())
            .add("currency", currency)
            .add("email", email!!)
            .add("name", name!!)
            .add("user_id", userId ?: "")
            .build()

        val request = Request.Builder()
            .url(apiUrl)
            .post(body)
            .build()

        http.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
//                Log.e("StripePayment", "Network failure: ${e.message}", e)
                isPaymentProcessing = false
                mainHandler.post(Runnable {
                    Toast.makeText(
                        this@PremiumMemberActivity,
                        getString(R.string.payment_init_failed),
                        Toast.LENGTH_SHORT
                    ).show()
                })
            }

            override fun onResponse(call: Call, response: Response) {
                try {
                    response.use { r ->
                        if (!r.isSuccessful) {
//                            Log.e("StripePayment", "Server returned error: ${r.code} ${r.message}")
                            isPaymentProcessing = false
                            mainHandler.post(Runnable {
                                Toast.makeText(
                                    this@PremiumMemberActivity,
                                    getString(R.string.payment_init_failed_server) +" ${r.code}",
                                    Toast.LENGTH_SHORT
                                ).show()
                            })
                            return
                        }
                        val json = if (r.body != null) r.body!!.string() else ""
                        val responseJson = JSONObject(json)
                        paymentIntentClientSecret = responseJson.getString("paymentIntent")
                        val customerId = responseJson.getString("customer")
                        val ephemeralKeySecret = responseJson.getString("ephemeralKey")
                        val publishableKey = responseJson.getString("publishableKey")
                        customerConfig = CustomerConfiguration(customerId, ephemeralKeySecret)
                        mainHandler.post(Runnable {
                            try {
                                PaymentConfiguration.init(
                                    activity.getApplicationContext(),
                                    publishableKey
                                )
                                val configuration =
                                    PaymentSheet.Configuration.Builder("Snap Drama")
                                        .customer(customerConfig)
                                        .allowsDelayedPaymentMethods(true)
                                        .build()
                                paymentSheet.presentWithPaymentIntent(
                                    paymentIntentClientSecret,
                                    configuration
                                )
                            } catch (e: java.lang.Exception) {
//                                Log.e("StripePayment", "Error presenting PaymentSheet: ${e.message}", e)
                                isPaymentProcessing = false
                                Toast.makeText(
                                    this@PremiumMemberActivity,
                                    "Stripe error",
                                    Toast.LENGTH_SHORT
                                ).show()
                            }
                        })
                    }
                } catch (e: java.lang.Exception) {
//                    Log.e("StripePayment", "Error parsing response or presenting: ${e.message}", e)
                    isPaymentProcessing = false
                    mainHandler.post(Runnable {
                        Toast.makeText(
                            this@PremiumMemberActivity,
                            getString(R.string.payment_init_failed_server),
                            Toast.LENGTH_SHORT
                        ).show()
                    })
                }
            }
        })
    }

    private fun onPaymentSheetResult(paymentSheetResult: PaymentSheetResult) {
        if (paymentSheetResult is PaymentSheetResult.Completed) {
            isPaymentProcessing = false

            onStripePaymentCompleted()
        } else if (paymentSheetResult is PaymentSheetResult.Canceled) {
            isPaymentProcessing = false

            Toast.makeText(this@PremiumMemberActivity, getString(R.string.payment_cancelled), Toast.LENGTH_SHORT)
                .show()
        } else if (paymentSheetResult is PaymentSheetResult.Failed) {
            isPaymentProcessing = false

            val failed = paymentSheetResult
            Toast.makeText(
                this@PremiumMemberActivity,
                getString(R.string.payment_failed) + ": " + (if (failed.error != null) failed.error.message else ""),
                Toast.LENGTH_SHORT
            ).show()
        }
    }

    private fun onStripePaymentCompleted() {
        val uid = FirebaseAuth.getInstance().getUid()
        if (uid == null) return

        if (pendingPurchaseType >= RewardAdManager.PURCHASE_TYPE_COINS_PACK_1 && pendingPurchaseType <= RewardAdManager.PURCHASE_TYPE_COINS_PACK_4) {
            val coinsToAddNow: Long = pendingCoinsToAdd
            if (coinsToAddNow > 0) {
                CoinsManager.addCoins(
                    uid, coinsToAddNow,
                    OnSuccessListener { unused: Void? ->
                        Toast.makeText(
                            this@PremiumMemberActivity,
                            "+" + coinsToAddNow + " " + getString(R.string.coins_added),
                            Toast.LENGTH_SHORT
                        ).show()
                    },
                    OnFailureListener { e: java.lang.Exception? ->
                        Toast.makeText(
                            this@PremiumMemberActivity,
                            getString(R.string.failed_to_add_coin),
                            Toast.LENGTH_SHORT
                        ).show()
                    })
            }
        } else if (pendingPurchaseType == RewardAdManager.PURCHASE_TYPE_WEEKLY) {
            PremiumPlanManager.savePremiumPurchaseToFirestore(
                this@PremiumMemberActivity, true, false, pendingPrice,
                PremiumPlanManager.DURATION_WEEKLY_MS, object : SavePremiumCallback {
                    override fun onSuccess() {
                        Toast.makeText(
                            this@PremiumMemberActivity,
                            getString(R.string.weekly_membership_activied),
                            Toast.LENGTH_LONG
                        ).show()
                    }

                    override fun onError(e: java.lang.Exception?) {
                        Toast.makeText(
                            this@PremiumMemberActivity,
                            getString(R.string.failed_to_activate_membership),
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                })
        } else if (pendingPurchaseType == RewardAdManager.PURCHASE_TYPE_YEARLY) {
            PremiumPlanManager.savePremiumPurchaseToFirestore(
                this@PremiumMemberActivity, false, true, pendingPrice,
                PremiumPlanManager.DURATION_YEARLY_MS, object : SavePremiumCallback {
                    override fun onSuccess() {
                        Toast.makeText(
                            this@PremiumMemberActivity,
                            getString(R.string.yearly_membership_activied),
                            Toast.LENGTH_LONG
                        ).show()
                    }

                    override fun onError(e: java.lang.Exception?) {
                        Toast.makeText(
                            this@PremiumMemberActivity,
                            getString(R.string.failed_to_activate_membership),
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                })
        }

        adShowing = false
        notifyLockUiHidden()



        pendingPurchaseType = 0
        pendingCoinsToAdd = 0L
        pendingPrice = 0.0
    }

//    private var lockUiListener: LockUiListener? = null

    private fun notifyLockUiHidden() {
//        if (lockUiListener != null) lockUiListener.onLockUiHidden()
//        for (r in RewardAdManager.onLockUiHiddenRunnables) {
//            try {
//                r.run()
//            } catch (ignored: java.lang.Exception) {
//            }
//        }
    }
}