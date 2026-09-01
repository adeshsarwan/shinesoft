import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/state/premium_state.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/services/api_client/api_client.dart';

class GetSubscriptionService {
  final ApiClient apiClient;

  GetSubscriptionService({required this.apiClient});

  Future<Map<String, dynamic>> getSubscription() async {
    final accessToken = SharedPrefs.getData(PrefsConstants.accessToken) as String?;
    final Map<String, String>? headers =
        (accessToken != null && accessToken.isNotEmpty)
            ? {'Authorization': 'Bearer $accessToken'}
            : null;

    final response = await apiClient.getRequest(
      ApiEndpoints.getMySubscription,
      headers: headers,
    );
    return response;
  }

  /// Syncs premium flag from `/my-subscription` response.
  ///
  /// Returns true when an active subscription exists.
  Future<bool> syncPremiumStateFromSubscription() async {
    final response = await getSubscription();
    if (response['success'] != true) {
      return PremiumState.isPremium.value;
    }

    final payload = response['data'];
    if (payload is! Map<String, dynamic>) {
      return PremiumState.isPremium.value;
    }

    final data = payload['data'];
    final active = data is Map<String, dynamic> ? data['active'] : null;
    final isPremiumNow = active is Map<String, dynamic>;

    PremiumState.isPremium.value = isPremiumNow;
    await SharedPrefs.saveData(PrefsConstants.isPremiumUser, isPremiumNow);
    return isPremiumNow;
  }
}