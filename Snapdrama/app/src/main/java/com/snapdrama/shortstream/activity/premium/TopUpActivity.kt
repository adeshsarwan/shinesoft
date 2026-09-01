package com.snapdrama.shortstream.activity.premium

import android.app.Activity
import android.graphics.Paint
import android.os.Bundle
import android.os.CountDownTimer
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.TextView
import android.widget.Toast
import androidx.activity.OnBackPressedCallback
import androidx.appcompat.app.AppCompatActivity
import com.google.android.gms.tasks.OnFailureListener
import com.google.android.gms.tasks.OnSuccessListener
import com.google.firebase.auth.FirebaseAuth
import com.snapdrama.shortstream.R
import com.snapdrama.shortstream.activity.main.base.BaseOtherActivity
import com.snapdrama.shortstream.ads.PremiumPlanManager
import com.snapdrama.shortstream.ads.PremiumPlanManager.SavePremiumCallback
import com.snapdrama.shortstream.ads.RewardAdManager
import com.snapdrama.shortstream.applicationPreference.ControlPreference
import com.snapdrama.shortstream.databinding.ActivityTopUpBinding
import com.snapdrama.shortstream.utils.TimerManager
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
import org.json.JSONException
import org.json.JSONObject
import java.io.IOException

class TopUpActivity : BaseOtherActivity() {
    lateinit var binding: ActivityTopUpBinding
    private val http = OkHttpClient()
    private val mainHandler = Handler(Looper.getMainLooper())
    val EPISODE_COIN_COST: Long = 20L
    private var isPaymentProcessing = false

    private lateinit var paymentSheet: PaymentSheet
    private lateinit var customerConfig: CustomerConfiguration
    private lateinit var paymentIntentClientSecret: String

    private var pendingPurchaseType = 0
    private var pendingCoinsToAdd = 0L
    private var pendingPrice = 0.0
    private var adShowing = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        binding = ActivityTopUpBinding.inflate(layoutInflater)
        setContentView(binding.root)

        onBackPressedDispatcher.addCallback(this, object : OnBackPressedCallback(true) {
            override fun handleOnBackPressed() {
                finish()
            }
        })
        binding.btnBack.setOnClickListener {
            finish()
        }
        paymentSheet = PaymentSheet(
            this,
            PaymentSheetResultCallback { result: PaymentSheetResult ->
                this.onPaymentSheetResult(
                    result
                )
            })

        val pack1: View? = findViewById<View?>(R.id.pack1)
        val pack2: View? = findViewById<View?>(R.id.pack2)
        val pack3: View? = findViewById<View?>(R.id.pack3)
        val pack4: View? = findViewById<View?>(R.id.pack4)
        val relativeWeeklyMemberShip: View? =
            findViewById<View?>(R.id.relativeWeeklyMemberShip)
        val relativeYearlyMemberShip: View? =
            findViewById<View?>(R.id.relativeYearlyMemberShip)

        setPremiumPlans()


        val remaining = TimerManager.getRemainingTime(this)

        object : CountDownTimer(remaining, 1000) {

            override fun onTick(millisUntilFinished: Long) {

                val hours = millisUntilFinished / (1000 * 60 * 60)
                val minutes = (millisUntilFinished / (1000 * 60)) % 60
                val seconds = (millisUntilFinished / 1000) % 60

                val time = String.format(getString(R.string.limited_time) + " %02d:%02d:%02d", hours, minutes, seconds)
                binding.textWeeklyMemberShipTimeOut.text = time
            }

            override fun onFinish() {
                binding.textWeeklyMemberShipTimeOut.text = getString(R.string.offer_expired_soon)
            }

        }.start()


        val packClickListener = View.OnClickListener { v: View? ->
            val firebaseUser = FirebaseAuth.getInstance().currentUser
            if (firebaseUser == null) {
                Toast.makeText(this@TopUpActivity, getString(R.string.please_login_first), Toast.LENGTH_SHORT).show()
                return@OnClickListener
            }
            val id = v!!.getId()
            val planKey: String?
            val purchaseType: Int
            if (id == R.id.pack1) {
                planKey = "standard_plan_1"
                purchaseType = RewardAdManager.PURCHASE_TYPE_COINS_PACK_1
            } else if (id == R.id.pack2) {
                planKey = "standard_plan_2"
                purchaseType = RewardAdManager.PURCHASE_TYPE_COINS_PACK_2
            } else if (id == R.id.pack3) {
                planKey = "standard_plan_3"
                purchaseType = RewardAdManager.PURCHASE_TYPE_COINS_PACK_3
            } else if (id == R.id.pack4) {
                planKey = "standard_plan_4"
                purchaseType = RewardAdManager.PURCHASE_TYPE_COINS_PACK_4
            } else return@OnClickListener

            val planData: FloatArray? = getPlanPriceAndCoins(planKey)
            val amount =
                if (planData != null) planData[0] else (if (id == R.id.pack1) 99f else if (id == R.id.pack2) 49f else if (id == R.id.pack3) 199f else 499f)
            val coinsToAdd =
                if (planData != null && planData.size > 1) planData[1].toLong() else (if (id == R.id.pack1) 500L else if (id == R.id.pack2) 200L else if (id == R.id.pack3) 550L else 1350L)
            if (isPaymentProcessing) return@OnClickListener
            isPaymentProcessing = true
            startStripePayment(
                this@TopUpActivity,
                amount,
                purchaseType,
                coinsToAdd,
                0.0

            )
        }

        if (pack1 != null) pack1.setOnClickListener(packClickListener)
        if (pack2 != null) pack2.setOnClickListener(packClickListener)
        if (pack3 != null) pack3.setOnClickListener(packClickListener)
        if (pack4 != null) pack4.setOnClickListener(packClickListener)

        val country = ControlPreference.getCountryName()

        val jsonObject: JSONObject?
        val main_price_weekly: Double
        val main_price_yearly: Double

        if (country.equals("IN", ignoreCase = true)) {
            try {
                jsonObject = JSONObject(ControlPreference.getInrPlans())
                val plan5 = jsonObject.getJSONObject("weekly_membership")
                val plan6 = jsonObject.getJSONObject("yearly_membership")


                main_price_weekly = plan5.getDouble("main_price")
                main_price_yearly = plan6.getDouble("main_price")
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
        } else {
            try {
                jsonObject = JSONObject(ControlPreference.getUsdPlans())
                val plan5 = jsonObject.getJSONObject("weekly_membership")
                val plan6 = jsonObject.getJSONObject("yearly_membership")


                main_price_weekly = plan5.getDouble("main_price")
                main_price_yearly = plan6.getDouble("main_price")
            } catch (e: JSONException) {
                throw RuntimeException(e)
            }
        }


        if (relativeWeeklyMemberShip != null) {
            val finalMain_price = main_price_weekly
            relativeWeeklyMemberShip.setOnClickListener(View.OnClickListener { v: View? ->
                val firebaseUser = FirebaseAuth.getInstance().currentUser
                if (firebaseUser == null) {
                    Toast.makeText(this@TopUpActivity, getString(R.string.please_login_first), Toast.LENGTH_SHORT)
                        .show()
                    return@OnClickListener
                }
                if (isPaymentProcessing) return@OnClickListener
                isPaymentProcessing = true
                startStripePayment(
                    this@TopUpActivity,
                    finalMain_price.toString().toFloat(),
                    RewardAdManager.PURCHASE_TYPE_WEEKLY,
                    0L,
                    finalMain_price
                )
//                Log.e("skmdmfksfksdkfsmkfm", "onCreate: "+ finalMain_price.toString().toFloat() )
            })
        }

        if (relativeYearlyMemberShip != null) {
            val finalMain_price1 = main_price_yearly
            relativeYearlyMemberShip.setOnClickListener(View.OnClickListener { v: View? ->
                val firebaseUser = FirebaseAuth.getInstance().currentUser
                if (firebaseUser == null) {
                    Toast.makeText(this@TopUpActivity, getString(R.string.please_login_first), Toast.LENGTH_SHORT)
                        .show()
                    return@OnClickListener
                }
                if (isPaymentProcessing) return@OnClickListener
                isPaymentProcessing = true
                startStripePayment(
                    this@TopUpActivity,
                    finalMain_price1.toString().toFloat(),
                    RewardAdManager.PURCHASE_TYPE_YEARLY,
                    0L,
                    finalMain_price1
                )
            })
        }

    }

    private fun getPlanPriceAndCoins(planKey: String): FloatArray? {
        try {
            val country = ControlPreference.getCountryName()
            val jsonObject = if (country.equals("IN", ignoreCase = true))
                JSONObject(ControlPreference.getInrPlans())
            else
                JSONObject(ControlPreference.getUsdPlans())
            val plan = jsonObject.getJSONObject(planKey)
            val price = if (country.equals("IN", ignoreCase = true)) plan.getInt("price")
                .toFloat() else plan.getDouble("price").toFloat()
            val coins = plan.getInt("coins")
            val extraCoins = plan.getInt("extra_coins")


            return floatArrayOf(price, (coins + extraCoins).toFloat(), 0f)
        } catch (e: java.lang.Exception) {
            return null
        }
    }

    private fun setPremiumPlans() {
        val textPrice1 = findViewById<TextView?>(R.id.textPrice1)
        val textPrice2 = findViewById<TextView?>(R.id.textPrice2)
        val textPrice3 = findViewById<TextView?>(R.id.textPrice3)
        val textPrice4 = findViewById<TextView?>(R.id.textPrice4)

        val textViewMainCoin1 = findViewById<TextView?>(R.id.textViewMainCoin1)
        val textViewMainCoin2 = findViewById<TextView?>(R.id.textViewMainCoin2)
        val textViewMainCoin3 = findViewById<TextView?>(R.id.textViewMainCoin3)
        val textViewMainCoin4 = findViewById<TextView?>(R.id.textViewMainCoin4)

        val textViewExtraCoin1 = findViewById<TextView?>(R.id.textViewExtraCoin1)
        val textViewExtraCoin2 = findViewById<TextView?>(R.id.textViewExtraCoin2)
        val textViewExtraCoin3 = findViewById<TextView?>(R.id.textViewExtraCoin3)
        val textViewExtraCoin4 = findViewById<TextView?>(R.id.textViewExtraCoin4)
        val tvWeeklyMemberShip1 = findViewById<TextView?>(R.id.tvWeeklyMemberShip1)
        val tvWeeklyMemberShip2 = findViewById<TextView?>(R.id.tvWeeklyMemberShip2)
        val tvWeeklyMemberTitle = findViewById<TextView?>(R.id.tvWeeklyMemberTitle)

        val tvYearlyMemberShip1 = findViewById<TextView?>(R.id.tvYearlyMemberShip1)
        val tvYearlyMemberShip2 = findViewById<TextView?>(R.id.tvYearlyMemberShip2)
        val tvYearlyMemberTitle = findViewById<TextView?>(R.id.tvYearlyMemberTitle)
        tvWeeklyMemberShip2.setPaintFlags(Paint.STRIKE_THRU_TEXT_FLAG)
        try {
            val country = ControlPreference.getCountryName()

            val jsonObject: JSONObject?

            if (country.equals("IN", ignoreCase = true)) {
                jsonObject = JSONObject(ControlPreference.getInrPlans())
            } else {
                jsonObject = JSONObject(ControlPreference.getUsdPlans())
            }

            val plan1 = jsonObject.getJSONObject("standard_plan_1")
            setPlanData(plan1, textPrice1, textViewMainCoin1, textViewExtraCoin1, country)

            val plan2 = jsonObject.getJSONObject("standard_plan_2")
            setPlanData(plan2, textPrice2, textViewMainCoin2, textViewExtraCoin2, country)

            val plan3 = jsonObject.getJSONObject("standard_plan_3")
            setPlanData(plan3, textPrice3, textViewMainCoin3, textViewExtraCoin3, country)

            val plan4 = jsonObject.getJSONObject("standard_plan_4")
            setPlanData(plan4, textPrice4, textViewMainCoin4, textViewExtraCoin4, country)

            val plan5 = jsonObject.getJSONObject("weekly_membership")
            setMemberPlan(
                plan5,
                tvWeeklyMemberShip1,
                tvWeeklyMemberShip2,
                tvWeeklyMemberTitle,
                country
            )

            val plan6 = jsonObject.getJSONObject("yearly_membership")
            setMemberPlan(
                plan6,
                tvYearlyMemberShip1,
                tvYearlyMemberShip2,
                tvYearlyMemberTitle,
                country
            )
        } catch (e: java.lang.Exception) {
            e.printStackTrace()
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
                tvWeeklyMemberShip2.setText(discount_price)
                tvWeeklyMemberTitle.setText(" + " + title)
            }
        } catch (e: java.lang.Exception) {
            e.printStackTrace()
        }
    }

    private fun setPlanData(
        plan: JSONObject,
        priceView: TextView,
        mainCoinView: TextView,
        extraCoinView: TextView,
        country: String
    ) {
        try {
            val coins = plan.getInt("coins")
            val extraCoins = plan.getInt("extra_coins")

            mainCoinView.setText(coins.toString())
            extraCoinView.setText(" + " + extraCoins)

            if (country.equals("IN", ignoreCase = true)) {
                val price = plan.getInt("price")
                priceView.setText("₹ " + price)
            } else {
                val price = plan.getDouble("price")
                priceView.setText("$ " + price)
            }
        } catch (e: java.lang.Exception) {
            e.printStackTrace()
        }
    }

    override fun onBackPressed() {
        super.onBackPressed()
    }

    private fun startStripePayment(
        activity: Activity,
        amount: Float,
        purchaseType: Int,
        coinsToAdd: Long,
        priceForPremium: Double,

        ) {
        if (paymentSheet == null) {
            Toast.makeText(this@TopUpActivity, "Stripe not initialized yet", Toast.LENGTH_SHORT)
                .show()
            return
        }


        pendingPurchaseType = purchaseType
        pendingCoinsToAdd = coinsToAdd
        pendingPrice = priceForPremium

        validateFromServerAndPresent(activity, amount)
    }

    private fun validateFromServerAndPresent(activity: Activity, amount: Float) {
        val apiUrl: String =
            ControlPreference.getTransactionUrl() + this@TopUpActivity.getString(R.string.end_point)
        val country = ControlPreference.getCountryName()
        val currency =
            if (country != null && country.equals("IN", ignoreCase = true)) "inr" else "usd"
        val userId = FirebaseAuth.getInstance().getUid()
        val user = FirebaseAuth.getInstance().getCurrentUser()
        val email =
            if (user != null && user.getEmail() != null) user.getEmail() else "user@example.com"
        val name = if (user != null && user.getDisplayName() != null)
            user.getDisplayName()
        else
            (if (email!!.contains("@")) email.substring(0, email.indexOf('@')) else "User")

        val amountSmallestUnit = (amount * 100f).toLong()
        val body = FormBody.Builder()
            .add("amount", amountSmallestUnit.toString())
            .add("currency", currency)
            .add("email", email!!)
            .add("name", name!!)
            .add("user_id", userId.toString())

            .build()

        val request = Request.Builder()
            .url(apiUrl)
            .post(body)
            .build()

        http.newCall(request).enqueue(object : Callback {
            override fun onFailure(call: Call, e: IOException) {
                mainHandler.post(Runnable {
                    Toast.makeText(
                        this@TopUpActivity,
                        getString(R.string.payment_init_failed),
                        Toast.LENGTH_SHORT
                    ).show()
                })
            }

            override fun onResponse(call: Call, response: Response) {
                try {
                    response.use { r ->
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
                                Toast.makeText(
                                    this@TopUpActivity,
                                    "Stripe error",
                                    Toast.LENGTH_SHORT
                                ).show()
                            }
                        })
                    }
                } catch (e: java.lang.Exception) {
                    mainHandler.post(Runnable {
                        Toast.makeText(
                            this@TopUpActivity,
                            getString(R.string.payment_init_failed),
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

            Toast.makeText(this@TopUpActivity, getString(R.string.payment_cancelled), Toast.LENGTH_SHORT).show()
        } else if (paymentSheetResult is PaymentSheetResult.Failed) {
            isPaymentProcessing = false

            val failed = paymentSheetResult
            Toast.makeText(
                this@TopUpActivity,
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
                            this@TopUpActivity,
                            "+" + coinsToAddNow + " " + getString(R.string.coins_added),
                            Toast.LENGTH_SHORT
                        ).show()
                    },
                    OnFailureListener { e: java.lang.Exception? ->
                        Toast.makeText(
                            this@TopUpActivity,
                            getString(R.string.failed_to_add_coin),
                            Toast.LENGTH_SHORT
                        ).show()
                    })
            }
        } else if (pendingPurchaseType == RewardAdManager.PURCHASE_TYPE_WEEKLY) {
            PremiumPlanManager.savePremiumPurchaseToFirestore(
                this@TopUpActivity, true, false, pendingPrice,
                PremiumPlanManager.DURATION_WEEKLY_MS, object : SavePremiumCallback {
                    override fun onSuccess() {
                        Toast.makeText(
                            this@TopUpActivity,
                            getString(R.string.weekly_membership_activied),
                            Toast.LENGTH_LONG
                        ).show()
                    }

                    override fun onError(e: java.lang.Exception?) {
                        Toast.makeText(
                            this@TopUpActivity,
                            getString(R.string.failed_to_activate_membership),
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                })
        } else if (pendingPurchaseType == RewardAdManager.PURCHASE_TYPE_YEARLY) {
            PremiumPlanManager.savePremiumPurchaseToFirestore(
                this@TopUpActivity, false, true, pendingPrice,
                PremiumPlanManager.DURATION_YEARLY_MS, object : SavePremiumCallback {
                    override fun onSuccess() {
                        Toast.makeText(
                            this@TopUpActivity,
                            getString(R.string.yearly_membership_activied),
                            Toast.LENGTH_LONG
                        ).show()
                    }

                    override fun onError(e: java.lang.Exception?) {
                        Toast.makeText(
                            this@TopUpActivity,
                            getString(R.string.failed_to_activate_membership),
                            Toast.LENGTH_SHORT
                        ).show()
                    }
                })
        }

        adShowing = false
//        notifyLockUiHidden()


        pendingPurchaseType = 0
        pendingCoinsToAdd = 0L
        pendingPrice = 0.0
    }
}