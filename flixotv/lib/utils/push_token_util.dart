import 'dart:async';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// SharedPreferences key used by [fetchFcmToken] and schedule reminders.
const String fcmTokenPrefsKey = 'fcm_token_cache';
const String _fallbackPushIdKey = 'device_push_fallback_id';

/// API `platform` values accepted by the auth/login endpoint.
const String authPlatformAndroid = 'android';
const String authPlatformIos = 'ios';
const String authPlatformWeb = 'web';
const String authPlatformTv = 'tv';

/// Last [resolveAuthPlatformForApi] result (set during login).
String? cachedAuthPlatformForApi;

/// Resolves the `platform` field for auth/login.
/// Android TV (leanback) → `tv`; phones → `android` / `ios`; web → `web`.
Future<String> resolveAuthPlatformForApi() async {
  if (kIsWeb) {
    cachedAuthPlatformForApi = authPlatformWeb;
    return authPlatformWeb;
  }
  if (await isAndroidTvLeanbackDevice()) {
    cachedAuthPlatformForApi = authPlatformTv;
    return authPlatformTv;
  }
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      cachedAuthPlatformForApi = authPlatformIos;
      return authPlatformIos;
    case TargetPlatform.android:
      cachedAuthPlatformForApi = authPlatformAndroid;
      return authPlatformAndroid;
    default:
      cachedAuthPlatformForApi = authPlatformAndroid;
      return authPlatformAndroid;
  }
}

@Deprecated('Use resolveAuthPlatformForApi()')
String authPlatformForApi() {
  if (cachedAuthPlatformForApi != null) return cachedAuthPlatformForApi!;
  if (kIsWeb) return authPlatformWeb;
  switch (defaultTargetPlatform) {
    case TargetPlatform.iOS:
      return authPlatformIos;
    case TargetPlatform.android:
      return authPlatformAndroid;
    default:
      return authPlatformAndroid;
  }
}

Future<void> cacheFcmToken(String token) async {
  if (token.isEmpty) return;
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(fcmTokenPrefsKey, token);
  } catch (e) {
    debugPrint('[Push] cache FCM token failed: $e');
  }
}

Future<String> readCachedFcmToken() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(fcmTokenPrefsKey) ?? '';
  } catch (e) {
    debugPrint('[Push] read cached FCM token failed: $e');
    return '';
  }
}

/// Stable device id used when FCM returns SERVICE_NOT_AVAILABLE (login still works).
Future<String> getOrCreateFallbackPushId() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_fallbackPushIdKey);
    if (existing != null && existing.isNotEmpty) return existing;

    final id = _generateFallbackId();
    await prefs.setString(_fallbackPushIdKey, id);
    return id;
  } catch (e) {
    debugPrint('[Push] fallback id error: $e');
    return _generateFallbackId();
  }
}

String _generateFallbackId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

bool _isServiceNotAvailable(Object error) {
  return error.toString().contains('SERVICE_NOT_AVAILABLE');
}

/// Call once after [Firebase.initializeApp] (registers [onTokenRefresh]).
void attachFcmTokenRefreshListener() {
  if (kIsWeb) return;
  _FcmTokenCoordinator.instance.attachRefreshListener();
}

/// Non-blocking warm-up; safe to call from [main].
Future<void> prefetchFcmToken() async {
  await _FcmTokenCoordinator.instance.fetchToken(forAuth: false);
}

/// Token for login API — real FCM token when possible, else stable fallback id.
Future<String> resolvePushTokenForAuth() async {
  if (kIsWeb) return getOrCreateFallbackPushId();

  final token = await _FcmTokenCoordinator.instance.fetchToken(forAuth: true);
  if (token.isNotEmpty) return token;

  final fallback = await getOrCreateFallbackPushId();
  debugPrint(
    '[Push] FCM SERVICE_NOT_AVAILABLE — login uses fallback device id '
    '(${fallback.length} chars). Push may not work until FCM recovers.',
  );
  return fallback;
}

/// Returns the device FCM token when available, otherwise cached or empty.
Future<String> fetchFcmToken({
  bool requiredForAuth = false,
}) =>
    _FcmTokenCoordinator.instance.fetchToken(forAuth: requiredForAuth);

// ---------------------------------------------------------------------------
// Coordinator — single in-flight fetch; avoids hammering GMS/FCM.
// ---------------------------------------------------------------------------

class _FcmTokenCoordinator {
  _FcmTokenCoordinator._();
  static final _FcmTokenCoordinator instance = _FcmTokenCoordinator._();

  Future<String>? _inFlight;
  bool _refreshListenerAttached = false;
  DateTime? _lastServiceUnavailable;

  void attachRefreshListener() {
    if (_refreshListenerAttached || kIsWeb) return;
    _refreshListenerAttached = true;
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      if (token.isNotEmpty) {
        unawaited(cacheFcmToken(token));
        debugPrint('[Push] onTokenRefresh (${token.length} chars)');
      }
    });
  }

  Future<String> fetchToken({required bool forAuth}) async {
    if (kIsWeb) return '';

    final existing = _inFlight;
    if (existing != null) return existing;

    final future = _fetchTokenInternal(forAuth: forAuth);
    _inFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_inFlight, future)) _inFlight = null;
    }
  }

  Future<String> _fetchTokenInternal({required bool forAuth}) async {
    final cached = await readCachedFcmToken();
    if (cached.isNotEmpty && !_recentServiceUnavailable) {
      debugPrint('[Push] using cached FCM token (${cached.length} chars)');
      return cached;
    }

    try {
      await FirebaseMessaging.instance.setAutoInitEnabled(true);
    } catch (e) {
      debugPrint('[Push] setAutoInitEnabled: $e');
    }

    await _ensureNotificationPermission();

    // Let Google Play Services settle after cold start.
    if (forAuth) {
      await Future<void>.delayed(const Duration(seconds: 2));
    }

    final maxAttempts = forAuth ? 4 : 2;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      final token = await _tryGetTokenOnce();
      if (token != null && token.isNotEmpty) {
        _lastServiceUnavailable = null;
        debugPrint('[Push] FCM token ready (${token.length} chars)');
        return token;
      }

      if (_recentServiceUnavailable && attempt < maxAttempts - 1) {
        // FCM won't retry internally; back off before next attempt.
        final wait = Duration(seconds: 5 * (attempt + 1));
        debugPrint('[Push] SERVICE_NOT_AVAILABLE — waiting ${wait.inSeconds}s');
        await Future<void>.delayed(wait);
      } else if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }

    if (forAuth && !_recentServiceUnavailable) {
      final refreshed = await _waitForTokenRefresh(
        timeout: const Duration(seconds: 8),
      );
      if (refreshed != null && refreshed.isNotEmpty) return refreshed;
    }

    if (cached.isNotEmpty) {
      debugPrint('[Push] using cached FCM token after retries');
      return cached;
    }

    debugPrint('[Push] FCM token unavailable');
    return '';
  }

  bool get _recentServiceUnavailable {
    final t = _lastServiceUnavailable;
    if (t == null) return false;
    return DateTime.now().difference(t) < const Duration(minutes: 2);
  }

  Future<String?> _tryGetTokenOnce() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await FirebaseMessaging.instance.getAPNSToken();
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await cacheFcmToken(token);
        return token;
      }
      debugPrint('[Push] getToken returned null/empty');
    } catch (e, st) {
      if (_isServiceNotAvailable(e)) {
        _lastServiceUnavailable = DateTime.now();
        debugPrint('[Push] SERVICE_NOT_AVAILABLE (GMS/FCM busy or restricted)');
      } else {
        debugPrint('[Push] getToken error: $e\n$st');
      }
    }
    return null;
  }
}

Future<void> _requestAndroidNotificationPermission() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;

  try {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt < 33) return;

    final plugin = FlutterLocalNotificationsPlugin();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await plugin.initialize(const InitializationSettings(android: android));

    final androidImpl = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await androidImpl?.requestNotificationsPermission();
    debugPrint('[Push] Android notification permission: $granted');
  } catch (e) {
    debugPrint('[Push] Android notification permission skipped: $e');
  }
}

Future<void> _ensureNotificationPermission() async {
  if (kIsWeb) return;

  try {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      debugPrint('[Push] iOS permission: ${settings.authorizationStatus}');
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _requestAndroidNotificationPermission();
    }
  } catch (e, st) {
    debugPrint('[Push] notification permission error (continuing): $e\n$st');
  }
}

Future<String?> _waitForTokenRefresh({
  Duration timeout = const Duration(seconds: 8),
}) async {
  final completer = Completer<String?>();
  late final StreamSubscription<String> sub;

  sub = FirebaseMessaging.instance.onTokenRefresh.listen(
    (token) {
      if (token.isNotEmpty && !completer.isCompleted) {
        cacheFcmToken(token);
        completer.complete(token);
      }
    },
    onError: (Object e) {
      debugPrint('[Push] onTokenRefresh error: $e');
    },
  );

  try {
    return await completer.future.timeout(
      timeout,
      onTimeout: () => null,
    );
  } finally {
    await sub.cancel();
  }
}
