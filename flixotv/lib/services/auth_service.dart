import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:http/http.dart' as http;
import 'package:iptv_demo/model/user_profile.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/repositories/auth_repository.dart';
import 'package:iptv_demo/utils/jwt_util.dart';
import 'package:iptv_demo/utils/notification_platform.dart';
import 'package:iptv_demo/utils/push_token_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends GetxService {
  AuthRepository get _authRepository => Get.find<AuthRepository>();

  static const String _keyAccessToken = 'access_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserId = 'user_id';
  static const String _keyIsPremium = 'is_premium_user';
  static const String _keyRegisteredPlatform = 'auth_registered_platform';

  var isLoggedIn = false.obs;
  var accessToken = ''.obs;
  var refreshToken = ''.obs;
  var userEmail = ''.obs;
  var userId = ''.obs;
  var isPremiumUser = false.obs;
  /// `platform` last sent to login API (`android` | `ios` | `web` | `tv`).
  final registeredPlatform = ''.obs;
  final currentProfile = Rxn<UserProfile>();

  /// Coalesces concurrent refresh attempts (e.g. multiple 401s) into one HTTP call.
  Future<bool>? _refreshInFlight;

  /// True when the signed-in user must not see ads (premium / active subscription).
  bool get hasAdFreeAccess {
    if (!isLoggedIn.value) return false;
    if (isPremiumUser.value || AdsVariable.isPurchased.value) return true;
    return currentProfile.value?.grantsAdFreeAccess ?? false;
  }

  /// Mongo user id for notification routes (`/notifications/:userId/...`).
  String? get resolvedUserId {
    final stored = userId.value.trim();
    if (stored.isNotEmpty) return stored;
    final fromToken = userIdFromAccessToken(accessToken.value);
    if (fromToken != null && fromToken.isNotEmpty) return fromToken;
    final profileId = currentProfile.value?.id.trim();
    if (profileId != null && profileId.isNotEmpty) return profileId;
    return null;
  }

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadTokens();
    if (isLoggedIn.value && refreshToken.value.isNotEmpty) {
      await refreshSession();
      await syncPremiumFromServer();
    }
  }

  /// Load tokens from SharedPreferences on app start.
  Future<void> _loadTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final access = prefs.getString(_keyAccessToken) ?? '';
      final refresh = prefs.getString(_keyRefreshToken) ?? '';
      final email = prefs.getString(_keyUserEmail) ?? '';
      final storedUserId = prefs.getString(_keyUserId) ?? '';

      if (access.isNotEmpty && refresh.isNotEmpty) {
        accessToken.value = access;
        refreshToken.value = refresh;
        userEmail.value = email;
        userId.value =
            storedUserId.isNotEmpty ? storedUserId : (userIdFromAccessToken(access) ?? '');
        isLoggedIn.value = true;
        isPremiumUser.value = prefs.getBool(_keyIsPremium) ?? false;
        registeredPlatform.value =
            prefs.getString(_keyRegisteredPlatform) ?? '';
        await AdsVariable.setPurchased(isPremiumUser.value);
        debugPrint(
          '[Auth] Loaded tokens from storage. User: $email '
          'platform=${registeredPlatform.value}',
        );
      } else {
        isLoggedIn.value = false;
        isPremiumUser.value = false;
        registeredPlatform.value = '';
        await AdsVariable.setPurchased(false);
        debugPrint('[Auth] No tokens found in storage.');
      }
    } catch (e) {
      debugPrint('[Auth] Error loading tokens: $e');
    }
  }

  /// Save tokens to SharedPreferences.
  void _syncUserIdFromTokenOrData(String access, Map<String, dynamic>? data) {
    final fromData = data == null
        ? null
        : (data['userId'] ??
                data['user_id'] ??
                data['userid'] ??
                (data['user'] is Map
                    ? (data['user'] as Map)['_id'] ?? (data['user'] as Map)['id']
                    : null))
            ?.toString()
            .trim();
    final resolved = (fromData != null && fromData.isNotEmpty)
        ? fromData
        : (userIdFromAccessToken(access) ?? '');
    if (resolved.isNotEmpty) userId.value = resolved;
  }

  Future<void> _persistRegisteredPlatform(String platform) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = platform.trim();
      if (p.isEmpty) {
        await prefs.remove(_keyRegisteredPlatform);
      } else {
        await prefs.setString(_keyRegisteredPlatform, p);
      }
    } catch (e) {
      debugPrint('[Auth] Error saving registered platform: $e');
    }
  }

  Future<void> _saveTokens({
    required String access,
    required String refresh,
    required String email,
    String? id,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, access);
      await prefs.setString(_keyRefreshToken, refresh);
      await prefs.setString(_keyUserEmail, email);
      final uid = id ?? userId.value;
      if (uid.isNotEmpty) {
        await prefs.setString(_keyUserId, uid);
      } else {
        await prefs.remove(_keyUserId);
      }
      debugPrint('[Auth] Tokens saved to storage.');
    } catch (e) {
      debugPrint('[Auth] Error saving tokens: $e');
    }
  }

  /// Clear all tokens from SharedPreferences.
  Future<void> _clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyIsPremium);
      await prefs.remove(_keyRegisteredPlatform);
      isPremiumUser.value = false;
      registeredPlatform.value = '';
      await AdsVariable.setPurchased(false);
      debugPrint('[Auth] Tokens cleared from storage.');
    } catch (e) {
      debugPrint('[Auth] Error clearing tokens: $e');
    }
  }

  /// Login with email and password.
  /// Returns (success, message).
  Future<(bool, String)> login({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[Auth] Login attempt for: $email');

      final platform = await resolveAuthPlatformForApi();
      final fcmToken = await resolvePushTokenForAuth();
      debugPrint(
        '[Auth] Login platform=$platform fcmToken=${fcmToken.length} chars',
      );

      final response = await _authRepository.login(
        email: email,
        password: password,
        platform: platform,
        fcmToken: fcmToken,
      );

      debugPrint('[Auth] Login response status: ${response.statusCode}');
      debugPrint('[Auth] Login response body: ${response.body}');

      if (response.statusCode != 200) {
        final msg =
            _extractMessage(response.body, 'Login failed. Please try again.');
        return (false, msg);
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        final msg = _extractMessage(
            response.body, 'Login failed. Please check your credentials.');
        return (false, msg);
      }

      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) {
        return (false, 'Invalid response format');
      }

      final access = data['accessToken'] as String? ?? '';
      final refresh = data['refreshToken'] as String? ?? '';

      if (access.isEmpty || refresh.isEmpty) {
        return (false, 'Missing tokens in response');
      }

      _syncUserIdFromTokenOrData(access, data);

      // Save tokens
      await _saveTokens(
        access: access,
        refresh: refresh,
        email: email,
        id: userId.value,
      );

      // Update state
      accessToken.value = access;
      refreshToken.value = refresh;
      userEmail.value = email;
      isLoggedIn.value = true;
      registeredPlatform.value = platform;
      await _persistRegisteredPlatform(platform);
      await _persistPremium(UserProfile.inferPremiumFromMap(data));
      await syncPremiumFromServer();

      if (platform == authPlatformTv) {
        unawaited(ensureTvPushReadyAfterLogin());
      }

      debugPrint(
        '[Auth] Login successful for: $email platform=$platform '
        '(adFree=$hasAdFreeAccess)',
      );
      return (true, 'Login successful');
    } catch (e) {
      debugPrint('[Auth] Login error: $e');
      if (e.toString().contains('TimeoutException')) {
        return (false, 'Connection timed out. Please check your internet.');
      }
      return (false, 'Network error. Please check your connection.');
    }
  }

  /// Register a new user.
  /// Returns (success, message).
  Future<(bool, String)> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('[Auth] Register attempt for: $email');

      final response = await _authRepository.register(
        name: name,
        email: email,
        password: password,
      );

      debugPrint('[Auth] Register response status: ${response.statusCode}');
      debugPrint('[Auth] Register response body: ${response.body}');

      if (response.statusCode != 201 && response.statusCode != 200) {
        final msg = _extractMessage(
            response.body, 'Registration failed. Please try again.');
        return (false, msg);
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final successField = decoded['success'];
          if (successField == false ||
              successField == 0 ||
              successField == 'false') {
            return (
              false,
              _extractMessage(response.body, 'Registration failed.'),
            );
          }
        }
      } catch (_) {}

      debugPrint('[Auth] Registration successful for: $email');
      return (
        true,
        _extractMessage(
          response.body,
          'Registration successful! Please login.',
        ),
      );
    } catch (e) {
      debugPrint('[Auth] Register error: $e');
      if (e.toString().contains('TimeoutException')) {
        return (false, 'Connection timed out. Please check your internet.');
      }
      return (false, 'Network error. Please check your connection.');
    }
  }

  Future<(bool, String)> forgotPassword({required String email}) async {
    try {
      final response = await _authRepository.forgotPassword(email: email);
      if (response.statusCode != 200) {
        final msg = _extractMessage(
          response.body,
          'Could not send OTP. Please try again.',
        );
        return (false, msg);
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return (false, _extractMessage(response.body, 'Could not send OTP.'));
      }
      return (true, _extractMessage(response.body, 'OTP sent successfully.'));
    } catch (e) {
      debugPrint('[Auth] forgotPassword error: $e');
      return (false, 'Network error. Please check your connection.');
    }
  }

  Future<(bool, String)> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await _authRepository.verifyOtp(email: email, otp: otp);
      if (response.statusCode != 200) {
        final msg = _extractMessage(
          response.body,
          'OTP verification failed. Please try again.',
        );
        return (false, msg);
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return (
          false,
          _extractMessage(response.body, 'Invalid OTP. Please try again.'),
        );
      }
      return (
        true,
        _extractMessage(response.body, 'OTP verified successfully.')
      );
    } catch (e) {
      debugPrint('[Auth] verifyOtp error: $e');
      return (false, 'Network error. Please check your connection.');
    }
  }

  Future<(bool, String)> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    try {
      final response = await _authRepository.resetPassword(
        email: email,
        newPassword: newPassword,
      );
      if (response.statusCode != 200) {
        final msg = _extractMessage(
          response.body,
          'Could not reset password. Please try again.',
        );
        return (false, msg);
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return (
          false,
          _extractMessage(response.body, 'Could not reset password.')
        );
      }
      return (
        true,
        _extractMessage(
            response.body, 'Password reset successful. Please login.'),
      );
    } catch (e) {
      debugPrint('[Auth] resetPassword error: $e');
      return (false, 'Network error. Please check your connection.');
    }
  }

  /// Calls `POST /auth/refresh` and persists new tokens when the backend succeeds.
  /// Returns `true` when access (and refresh when provided) tokens were updated.
  /// On 401/403 from the refresh endpoint, the local session is cleared.
  /// Concurrent callers share a single in-flight refresh.
  Future<bool> refreshSession() {
    if (_refreshInFlight != null) return _refreshInFlight!;
    final future = _performTokenRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
    _refreshInFlight = future;
    return future;
  }

  Future<bool> _performTokenRefresh() async {
    final refresh = refreshToken.value;
    if (refresh.isEmpty) return false;
    try {
      final response =
          await _authRepository.refreshTokens(refreshToken: refresh);
      debugPrint('[Auth] Refresh status: ${response.statusCode}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[Auth] Refresh rejected; clearing session');
        await logout();
        return false;
      }

      if (response.statusCode != 200 || response.body.isEmpty) {
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return false;
      }

      final data = decoded['data'] as Map<String, dynamic>?;
      if (data == null) return false;

      final access = data['accessToken'] as String? ?? '';
      final newRefresh = data['refreshToken'] as String? ?? '';
      if (access.isEmpty) return false;

      final r = newRefresh.isNotEmpty ? newRefresh : refresh;
      final email = userEmail.value;
      _syncUserIdFromTokenOrData(access, data);
      await _saveTokens(access: access, refresh: r, email: email, id: userId.value);
      accessToken.value = access;
      refreshToken.value = r;
      isLoggedIn.value = true;
      debugPrint('[Auth] Tokens refreshed');
      return true;
    } catch (e) {
      debugPrint('[Auth] Refresh error: $e');
      return false;
    }
  }

  Future<http.Response> _fetchProfileOnce() {
    return _authRepository.fetchProfile(accessToken: accessToken.value);
  }

  /// Loads the signed-in user profile from `GET /auth/profile`.
  /// Returns `(profile, errorMessage)`; [profile] is null on failure.
  Future<(UserProfile?, String)> fetchProfile() async {
    if (accessToken.value.isEmpty) {
      return (null, 'Not signed in');
    }
    try {
      var response = await _fetchProfileOnce();

      if (response.statusCode == 401 && refreshToken.value.isNotEmpty) {
        if (await refreshSession()) {
          response = await _fetchProfileOnce();
        }
      }

      if (response.statusCode != 200 || response.body.isEmpty) {
        return (
          null,
          _extractMessage(
            response.body,
            'Could not load profile (${response.statusCode})',
          ),
        );
      }
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded['success'] != true) {
        return (null, _extractMessage(response.body, 'Could not load profile'));
      }
      final raw = decoded['data'];
      if (raw is! Map) {
        return (null, 'Invalid profile response');
      }
      final data = Map<String, dynamic>.from(raw);
      final profile = UserProfile.fromJson(data);
      if (profile.email.isEmpty && profile.id.isEmpty) {
        return (null, 'Invalid profile data');
      }
      currentProfile.value = profile;
      await _persistPremium(profile.grantsAdFreeAccess);
      debugPrint('[Auth] Profile loaded — adFree=$hasAdFreeAccess');
      if (profile.id.isNotEmpty) {
        userId.value = profile.id;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_keyUserId, profile.id);
        } catch (_) {}
      }
      return (profile, '');
    } catch (e) {
      debugPrint('[Auth] fetchProfile error: $e');
      if (e.toString().contains('TimeoutException')) {
        return (null, 'Connection timed out.');
      }
      return (null, 'Network error. Please try again.');
    }
  }

  Future<void> _persistPremium(bool value) async {
    isPremiumUser.value = value;
    await AdsVariable.setPurchased(value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsPremium, value);
    } catch (e) {
      debugPrint('[Auth] Error saving premium flag: $e');
    }
  }

  /// Marks the user premium locally after a successful in-app Stripe checkout.
  /// Your backend should still confirm payment (e.g. webhook) and update the account.
  Future<void> applyLocalPremiumFromPurchase() async {
    await _persistPremium(true);
  }

  /// Refreshes [isPremiumUser] from `GET /auth/profile` (e.g. when opening Settings).
  Future<void> syncPremiumFromServer() async {
    if (!isLoggedIn.value || accessToken.value.isEmpty) return;
    await fetchProfile();
  }

  /// Extracts the `message` field from a JSON response body.
  /// Falls back to [fallback] if parsing fails or message is empty.
  String _extractMessage(String body, String fallback) {
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      final msg = decoded['message'] as String?;
      if (msg != null && msg.trim().isNotEmpty) return msg.trim();
    } catch (_) {}
    return fallback;
  }

  /// Permanently deletes the account via `DELETE /auth/delete`, then clears local session.
  /// Returns `(true, message)` on HTTP success (2xx); otherwise `(false, errorMessage)`.
  Future<(bool, String)> deleteAccount() async {
    if (accessToken.value.isEmpty) {
      return (false, 'Not signed in');
    }
    try {
      var response =
          await _authRepository.deleteAccount(accessToken: accessToken.value);

      if (response.statusCode == 401 && refreshToken.value.isNotEmpty) {
        if (await refreshSession()) {
          response = await _authRepository.deleteAccount(
            accessToken: accessToken.value,
          );
        }
      }

      debugPrint('[Auth] Delete account status: ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isNotEmpty) {
          try {
            final decoded = jsonDecode(response.body) as Map<String, dynamic>;
            if (decoded['success'] == false) {
              return (
                false,
                _extractMessage(response.body, 'Could not delete account'),
              );
            }
          } catch (_) {}
        }

        await _clearTokens();
        await _clearUserScopedLocalData();
        accessToken.value = '';
        refreshToken.value = '';
        userEmail.value = '';
        userId.value = '';
        isLoggedIn.value = false;
        currentProfile.value = null;
        debugPrint('[Auth] Account deleted; local session cleared');
        return (true, 'Account deleted');
      }

      return (
        false,
        _extractMessage(
          response.body,
          'Could not delete account (${response.statusCode})',
        ),
      );
    } catch (e) {
      debugPrint('[Auth] deleteAccount error: $e');
      if (e.toString().contains('TimeoutException')) {
        return (false, 'Connection timed out.');
      }
      return (false, 'Network error. Please try again.');
    }
  }

  Future<void> _clearUserScopedLocalData() async {
    if (Get.isRegistered<IptvController>()) {
      await Get.find<IptvController>().clearFavorites();
    }
  }

  /// Calls backend logout, then clears local tokens and state.
  /// Local session is cleared even if the network request fails.
  Future<void> logout() async {
    final refresh = refreshToken.value;
    if (refresh.isNotEmpty) {
      try {
        final fcmToken = await resolvePushTokenForAuth();
        final response = await _authRepository.logout(
          refreshToken: refresh,
          fcmToken: fcmToken,
        );
        debugPrint('[Auth] Logout API status: ${response.statusCode}');
        debugPrint('[Auth] Logout API body: ${response.body}');
      } catch (e) {
        debugPrint(
            '[Auth] Logout API error (clearing local session anyway): $e');
      }
    }

    await _clearTokens();
    await _clearUserScopedLocalData();
    accessToken.value = '';
    refreshToken.value = '';
    userEmail.value = '';
    userId.value = '';
    isLoggedIn.value = false;
    currentProfile.value = null;
    debugPrint('[Auth] Logged out locally');
  }

  /// Get authorization header for API calls.
  Map<String, String> get authHeaders => {
        'Authorization': 'Bearer ${accessToken.value}',
      };
}
