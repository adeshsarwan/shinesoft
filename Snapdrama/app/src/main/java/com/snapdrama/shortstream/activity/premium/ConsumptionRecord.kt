package com.snapdrama.shortstream.activity.premium

import com.google.firebase.Timestamp

data class ConsumptionRecord(
    val seriesId: String = "",
    val episodeName: String = "",
    val episodePhoto: String = "",
    val episodeDesc: String = "",
    val episodeNumber: Int = 0,
    val episodeSpendCutTime: Timestamp? = null,
    val spendPrice: Long = 0,
    val unlockKey: String = ""
)