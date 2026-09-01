import 'package:videodownloader/services/api_client/api_client.dart';

import '../../../apis/api_endpoints.dart';

class RegisterUserService {
  final ApiClient apiClient;

  RegisterUserService({required this.apiClient});

  Future<Map<String, dynamic>> registerUser(String name, String email, String password) async {
    final response = await apiClient.postRequest(
      ApiEndpoints.register, 
      {
      "name": name,
      "email": email,
      "password": password,
    });
    return response;
  }
}