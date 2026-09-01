import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/services/api_client/api_client.dart';

class DeleteAccountService {
  final ApiClient apiClient;

  DeleteAccountService({required this.apiClient});

  Future<Map<String, dynamic>> deleteAccount() async {
    final accessToken = SharedPrefs.getData(PrefsConstants.accessToken) as String?;

    final headers = <String, String>{};
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }

    final response = await apiClient.deleteRequest(
      ApiEndpoints.deleteAccount,
      headers: headers,
    );
    return response;
  }
}