import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/services/api_client/api_client.dart';
import 'package:videodownloader/services/models/stripe_payment_model/get_plans_model.dart';

class GetPlansService {
  final ApiClient apiClient;

  GetPlansService({required this.apiClient});

  /// Fetches plans from the backend. Returns null if the request fails or payload is invalid.
  Future<GetPlansModel?> getPlans() async {
    final response = await apiClient.getRequest(ApiEndpoints.getPlans);
    if (response['success'] != true) return null;
    final payload = response['data'];
    if (payload is! Map<String, dynamic>) return null;
    try {
      return GetPlansModel.fromJson(payload);
    } catch (_) {
      return null;
    }
  }
}
