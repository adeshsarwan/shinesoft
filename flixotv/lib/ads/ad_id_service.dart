import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdIdService {
  AdIdService._();

  static const MethodChannel _channel = MethodChannel('com.flixotv.ignia/advertising_info');

  static String? _cachedAdId;
  static bool _isLimitAdTracking = false;

  static Future<void> init() async {
    try {
      final Map<dynamic, dynamic>? info = await _channel.invokeMapMethod('getAdvertisingId');
      if (info != null) {
        _cachedAdId = info['id'] as String?;
        _isLimitAdTracking = info['isLimitAdTrackingEnabled'] as bool? ?? false;
      }
    } catch (e) {
      // Print/log error but do not crash
      print('[AdIdService] Failed to get native advertising ID: $e');
    }

    // If native ID is not available or is all-zeros (limited/opt-out),
    // we use/generate our own persistent custom ID.
    if (_cachedAdId == null || _cachedAdId == '00000000-0000-0000-0000-000000000000') {
      final prefs = await SharedPreferences.getInstance();
      String? customId = prefs.getString('custom_ad_id');
      if (customId == null) {
        customId = _generateRandomUuid();
        await prefs.setString('custom_ad_id', customId);
      }
      _cachedAdId = customId;
      _isLimitAdTracking = false; // Treat custom UUID as trackable for ad delivery
    }
  }

  static String get advertisingId => _cachedAdId ?? '00000000-0000-0000-0000-000000000000';
  static bool get isLimitAdTracking => _isLimitAdTracking;

  static Future<void> resetAdvertisingId() async {
    final prefs = await SharedPreferences.getInstance();
    final newId = _generateRandomUuid();
    await prefs.setString('custom_ad_id', newId);
    _cachedAdId = newId;
    _isLimitAdTracking = false;
  }

  static String _generateRandomUuid() {
    final random = Random();
    final hexDigits = '0123456789abcdef';
    String generateHex(int length) {
      return List.generate(length, (_) => hexDigits[random.nextInt(16)]).join();
    }
    return '${generateHex(8)}-${generateHex(4)}-4${generateHex(3)}-a${generateHex(3)}-${generateHex(12)}';
  }
}
