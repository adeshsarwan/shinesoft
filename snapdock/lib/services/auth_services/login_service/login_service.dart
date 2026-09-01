import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/services/api_client/api_client.dart';

class LoginService {
  final ApiClient apiClient;

  LoginService({required this.apiClient});

  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await apiClient.postRequest(ApiEndpoints.login, {
      "email": email,
      "password": password,
    });
    return response;
  }
}