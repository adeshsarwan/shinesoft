package com.snapdrama.shortstream.engineBox.model.transaction


class TransactionResponse {
    val user_id: String? = null
    val total_transactions: Int = 0
    lateinit var  transactions: MutableList<TransactionModel?>


}


class TransactionModel {
    val payment_id: String? = null
    val amount: Double = 0.0
    val currency: String? = null
    val status: String? = null
    val customer: String? = null
    val description: String? = null
    val receipt_email: String? = null
    val created: Long = 0
    val payment_method: String? = null
    val decline_reason: String? = null
    val metadata: MutableMap<String?, String?>? = null
}