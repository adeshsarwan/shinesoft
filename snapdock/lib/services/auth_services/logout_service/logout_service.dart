import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/services/api_client/api_client.dart';

class LogoutService {
  final ApiClient apiClient;

  LogoutService({required this.apiClient});

  Future<Map<String, dynamic>> logout() async {
    final accessToken = SharedPrefs.getData(PrefsConstants.accessToken) as String?;
    final refreshToken = SharedPrefs.getData(PrefsConstants.refreshToken) as String?;

    final headers = <String, String>{};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final body = <String, dynamic>{};
    if (refreshToken != null && refreshToken.isNotEmpty) {
      body['refresh_token'] = refreshToken;
    }

    final response = await apiClient.postRequest(
      ApiEndpoints.logout,
      body,
      headers: headers,
    );
    return response;
  }
}