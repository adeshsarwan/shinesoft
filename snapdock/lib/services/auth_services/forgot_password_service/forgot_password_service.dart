import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/services/api_client/api_client.dart';

class ForgotPasswordService {
  final ApiClient apiClient;

  ForgotPasswordService({required this.apiClient});

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await apiClient.postRequest(ApiEndpoints.forgotPassword, {
      "email": email,
    });
    return response;
  }
}