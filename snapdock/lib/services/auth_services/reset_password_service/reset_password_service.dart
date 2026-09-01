import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/services/api_client/api_client.dart';

class ResetPasswordService {
  final ApiClient apiClient;

  ResetPasswordService({required this.apiClient});

  Future<Map<String, dynamic>> resetPassword(String email, String otp, String password) async {
    final response = await apiClient.postRequest(ApiEndpoints.resetPassword, {
      "email": email,
      "otp": otp,
      "new_password": password
    });
    return response;
  }
}