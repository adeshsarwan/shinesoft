import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:iptv_demo/constant/app_urls.dart';
import 'package:iptv_demo/services/api_service.dart';

typedef StripePlan = ({
  String id,
  String name,
  String interval,
  String description,
  num price,
  String currency,
  int durationDays,
  int trialDays,
  bool isActive,
  bool isPopular,
});

/// Calls your backend to create a Stripe PaymentIntent and returns its client secret.
class StripeRepository {
  StripeRepository(this._api);

  final ApiService _api;

  /// Plan row from `GET /plans` or legacy `GET /payment/plans`.
  StripePlan? _parsePlan(dynamic row) {
    if (row is! Map) return null;
    final map = Map<String, dynamic>.from(row);
    final id = (map['_id'] ?? map['id'] ?? '').toString().trim();
    if (id.isEmpty) return null;
    final name = (map['name'] ?? '').toString().trim();
    final interval = (map['interval'] ?? '').toString().trim().toLowerCase();
    final description = (map['description'] ?? '').toString().trim();
    final rawPrice = map['price'];
    final price = rawPrice is num ? rawPrice : num.tryParse('$rawPrice') ?? 0;
    final currency = (map['currency'] ?? '').toString().trim().toLowerCase();
    final durationDays =
        (map['durationDays'] is num) ? (map['durationDays'] as num).toInt() : 30;
    final trialDays =
        (map['trialDays'] is num) ? (map['trialDays'] as num).toInt() : 0;
    final isActive = map['isActive'] != false;
    final isPopularRaw = map['isPopular'] ?? map['is_popular'];
    final isPopular = isPopularRaw == true ||
        isPopularRaw == 1 ||
        isPopularRaw?.toString().toLowerCase() == 'true';
    return (
      id: id,
      name: name,
      interval: interval,
      description: description,
      price: price,
      currency: currency,
      durationDays: durationDays,
      trialDays: trialDays,
      isActive: isActive,
      isPopular: isPopular,
    );
  }

  /// POST create-intent and parse `clientSecret` from root or `data`.
  Future<String?> createPaymentIntentClientSecret({
    required String planId,
    required String email,
    String? accessToken,
    int? amount,
    String? description,
  }) async {
    final endpoints = <String>[
      AppUrls.stripeCreatePaymentIntent,
      '${AppUrls.stripeApiBase}/payments/create-intent',
      '${AppUrls.stripeApiBase}/payments/stripe/create-payment-intent',
    ];

    final payload = jsonEncode({
      'planId': planId,
      'email': email,
      if (amount != null) 'amount': amount,
      if (description != null && description.isNotEmpty) 'description': description,
    });

    for (final endpoint in endpoints) {
      final response = await _api.post(
        Uri.parse(endpoint),
        headers: accessToken == null || accessToken.isEmpty
            ? null
            : {'Authorization': 'Bearer $accessToken'},
        body: payload,
        timeout: const Duration(seconds: 30),
        debugTag: 'Stripe / create payment intent',
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        continue;
      }
      if (response.body.isEmpty) {
        continue;
      }

      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) continue;
        final map = Map<String, dynamic>.from(decoded);

        final data = map['data'];
        if (data is Map) {
          final d = Map<String, dynamic>.from(data);
          final nested = _readClientSecret(d);
          if (nested != null) return nested;
        }

        final direct = _readClientSecret(map);
        if (direct != null) return direct;
      } catch (_) {
        continue;
      }
    }

    debugPrint(
      '[Stripe] Unable to extract clientSecret from backend. Tried endpoints: ${endpoints.join(', ')}',
    );
    return null;
  }

  String? _readClientSecret(Map<String, dynamic> map) {
    final keys = ['clientSecret', 'client_secret', 'paymentIntentClientSecret'];
    for (final k in keys) {
      final v = map[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  /// Fetches subscription plans and returns yearly plans when available.
  Future<List<StripePlan>> fetchPlans({
    String? interval,
  }) async {
    final endpoints = <Uri>[
      Uri.parse(AppUrls.stripePlans).replace(
        queryParameters: interval == null ? null : {'interval': interval},
      ),
      Uri.parse('${AppUrls.stripeApiBase}/payment/plans').replace(
        queryParameters: interval == null ? null : {'interval': interval},
      ),
    ];

    for (final endpoint in endpoints) {
      final response = await _api.get(
        endpoint,
        timeout: const Duration(seconds: 30),
        debugTag: 'Stripe / payment plans',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        continue;
      }
      if (response.body.isEmpty) {
        continue;
      }
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) continue;
        final map = Map<String, dynamic>.from(decoded);
        if (map['success'] == false) continue;
        final data = map['data'];
        if (data is! List) continue;
        final plans = data.map(_parsePlan).whereType<StripePlan>().toList();
        if (plans.isNotEmpty) return plans;
      } catch (_) {
        continue;
      }
    }
    return const [];
  }

  /// Confirms successful payment on backend so subscription is attached to user.
  Future<(bool, String)> confirmPayment({
    required String accessToken,
    required String paymentIntentId,
  }) async {
    final endpoints = <String>[
      AppUrls.stripeConfirmPayment,
      '${AppUrls.stripeApiBase}/payments/confirm-payment',
    ];
    final payload = jsonEncode(<String, dynamic>{
      'paymentIntentId': paymentIntentId,
    });

    for (final endpoint in endpoints) {
      final response = await _api.post(
        Uri.parse(endpoint),
        headers: {'Authorization': 'Bearer $accessToken'},
        body: payload,
        timeout: const Duration(seconds: 30),
        debugTag: 'Stripe / confirm payment',
      );
      if (response.statusCode < 200 || response.statusCode >= 300) {
        continue;
      }
      if (response.body.isEmpty) {
        return (true, 'Payment confirmed');
      }
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) return (true, 'Payment confirmed');
        final map = Map<String, dynamic>.from(decoded);
        final ok = map['success'];
        if (ok is bool && !ok) {
          final msg = (map['message'] as String?) ?? 'Payment confirmation failed';
          return (false, msg);
        }
        return (true, (map['message'] as String?) ?? 'Payment confirmed');
      } catch (_) {
        return (true, 'Payment confirmed');
      }
    }

    return (false, 'Could not confirm payment on server');
  }
}
