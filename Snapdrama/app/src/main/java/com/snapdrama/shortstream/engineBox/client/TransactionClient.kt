package com.snapdrama.shortstream.engineBox.client

import com.snapdrama.shortstream.applicationPreference.ControlPreference
import com.snapdrama.shortstream.engineBox.interfaces.ApiService
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory


object TransactionClient {


    val instance: ApiService by lazy {
        val retrofit = Retrofit.Builder()
            .baseUrl(ControlPreference.getTransactionUrl())
            .addConverterFactory(GsonConverterFactory.create())
            .build()

        retrofit.create(ApiService::class.java)
    }
}
