import 'dart:convert';
import 'dart:developer' as developer;

import 'package:videodownloader/apis/api_endpoints.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/services/api_client/api_client.dart';

class CreatePaymentIntentService {
  final ApiClient apiClient;

  CreatePaymentIntentService({required this.apiClient});

  /// Creates a payment intent for the given plan [productId] (plan `id` from `/plans`).
  /// Sends `Authorization: Bearer <access_token>` when the user is logged in.
  Future<Map<String, dynamic>> createPaymentIntent(String productId) async {
    final accessToken = SharedPrefs.getData(PrefsConstants.accessToken) as String?;
    final Map<String, String>? headers =
        (accessToken != null && accessToken.isNotEmpty)
            ? {'Authorization': 'Bearer $accessToken'}
            : null;

    final response = await apiClient.postRequest(
      ApiEndpoints.stripeCreatePaymentIntent,
      {'product_id': productId},
      headers: headers,
    );

    try {
      developer.log(
        jsonEncode(response),
        name: 'CreatePaymentIntent',
      );
    } catch (_) {
      developer.log('$response', name: 'CreatePaymentIntent');
    }

    return response;
  }
}
