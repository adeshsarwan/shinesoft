package com.flixotv.ignia

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugins.GeneratedPluginRegistrant
import io.flutter.plugins.googlemobileads.GoogleMobileAdsPlugin

import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.ads.identifier.AdvertisingIdClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Keep the focused field in the Flutter layer above TV IME overlays.
        @Suppress("DEPRECATION")
        window.setSoftInputMode(
            WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE or
                WindowManager.LayoutParams.SOFT_INPUT_STATE_HIDDEN,
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        GeneratedPluginRegistrant.registerWith(flutterEngine)

        GoogleMobileAdsPlugin.registerNativeAdFactory(
            flutterEngine,
            "listTile",
            ListTileNativeAdFactory(layoutInflater)
        )

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.flixotv.ignia/advertising_info").setMethodCallHandler { call, result ->
            if (call.method == "getAdvertisingId") {
                CoroutineScope(Dispatchers.IO).launch {
                    try {
                        val info = AdvertisingIdClient.getAdvertisingIdInfo(applicationContext)
                        val id = info.id
                        val isLimitAdTrackingEnabled = info.isLimitAdTrackingEnabled
                        withContext(Dispatchers.Main) {
                            result.success(mapOf(
                                "id" to id,
                                "isLimitAdTrackingEnabled" to isLimitAdTrackingEnabled
                            ))
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.success(null)
                        }
                    }
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        GoogleMobileAdsPlugin.unregisterNativeAdFactory(flutterEngine, "listTile")
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
