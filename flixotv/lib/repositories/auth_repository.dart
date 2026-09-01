import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:iptv_demo/constant/app_urls.dart';
import 'package:iptv_demo/services/api_service.dart';

/// Auth API calls only — parsing and session state live in [AuthService].
class AuthRepository {
  AuthRepository(this._api);

  final ApiService _api;

  Future<http.Response> login({
    required String email,
    required String password,
    required String platform,
    required String fcmToken,
  }) {
    return _api.post(
      Uri.parse(AppUrls.authLogin),
      body: jsonEncode({
        'email': email,
        'password': password,
        'platform': platform,
        'fcmToken': fcmToken,
      }),
      debugTag: 'Auth / login',
    );
  }

  Future<http.Response> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _api.post(
      Uri.parse(AppUrls.authRegister),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
      debugTag: 'Auth / register',
    );
  }

  Future<http.Response> forgotPassword({required String email}) {
    return _api.post(
      Uri.parse(AppUrls.otpSendOtp),
      body: jsonEncode({'email': email}),
      debugTag: 'OTP / send',
    );
  }

  Future<http.Response> verifyOtp({
    required String email,
    required String otp,
  }) {
    return _api.post(
      Uri.parse(AppUrls.otpVerifyOtp),
      body: jsonEncode({'email': email, 'otp': otp}),
      debugTag: 'OTP / verify',
    );
  }

  Future<http.Response> resetPassword({
    required String email,
    required String newPassword,
  }) {
    return _api.post(
      Uri.parse(AppUrls.authResetPassword),
      body: jsonEncode({'email': email, 'newPassword': newPassword}),
      debugTag: 'Auth / reset password',
    );
  }

  /// Exchanges a valid refresh token for new access (and usually refresh) tokens.
  Future<http.Response> refreshTokens({required String refreshToken}) {
    return _api.post(
      Uri.parse(AppUrls.authRefresh),
      body: jsonEncode({'refreshToken': refreshToken}),
      timeout: const Duration(seconds: 20),
      debugTag: 'Auth / refresh',
    );
  }

  Future<http.Response> logout({
    required String refreshToken,
    required String fcmToken,
  }) {
    return _api.post(
      Uri.parse(AppUrls.authLogout),
      body: jsonEncode({
        'refreshToken': refreshToken,
        'fcmToken': fcmToken,
      }),
      timeout: const Duration(seconds: 15),
      debugTag: 'Auth / logout',
    );
  }

  Future<http.Response> fetchProfile({required String accessToken}) {
    return _api.get(
      Uri.parse(AppUrls.authProfile),
      headers: {'Authorization': 'Bearer $accessToken'},
      debugTag: 'Auth / profile',
    );
  }

  Future<http.Response> deleteAccount({required String accessToken}) {
    return _api.delete(
      Uri.parse(AppUrls.authDelete),
      headers: {'Authorization': 'Bearer $accessToken'},
      debugTag: 'Auth / delete account',
    );
  }
}
