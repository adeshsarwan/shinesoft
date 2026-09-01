import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/services/api_client/api_client.dart';

class PaymentStatusService {
  final ApiClient apiClient;

  PaymentStatusService({required this.apiClient});

  Future<Map<String, dynamic>> getPaymentStatus(String paymentIntentId) async {
    final accessToken = SharedPrefs.getData(PrefsConstants.accessToken) as String?;
    final Map<String, String>? headers =
        (accessToken != null && accessToken.isNotEmpty)
            ? {'Authorization': 'Bearer $accessToken'}
            : null;

    final base = Uri.parse(ApiEndpoints.stripePaymentStatus);
    final url = base.replace(
      pathSegments: [
        ...base.pathSegments.where((s) => s.isNotEmpty),
        paymentIntentId,
      ],
    ).toString();

    return apiClient.getRequest(url, headers: headers);
  }
}
