import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/constant/app_urls.dart';
import 'package:iptv_demo/constant/stripe_config.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/repositories/stripe_repository.dart';
import 'package:iptv_demo/services/auth_service.dart';

enum StripeCheckoutOutcome { success, cancelled, failed }

/// Stripe Payment Sheet flow for in-app premium (same steps as Stripe docs:
/// create PaymentIntent on server → init sheet → present sheet).
class StripePaymentService extends GetxService {
  StripeRepository get _repo => Get.find<StripeRepository>();

  @override
  void onInit() {
    super.onInit();
    Stripe.publishableKey = StripeConfig.publishableKey;
    debugPrint('[Stripe] Publishable key configured (test mode).');
  }

  /// Runs Payment Sheet for the yearly premium SKU. Updates local premium on success.
  Future<StripeCheckoutOutcome> checkoutPremiumYearly() async {
    final yearlyPlans = await _repo.fetchPlans(interval: 'yearly');
    if (yearlyPlans.isNotEmpty) {
      return checkoutPlan(yearlyPlans.first);
    }
    try {
      final auth = Get.find<AuthService>();
      if (!auth.isLoggedIn.value || auth.accessToken.value.isEmpty) {
        debugPrint('[Stripe] create-intent requires logged-in user token.');
        return StripeCheckoutOutcome.failed;
      }
      final email = auth.userEmail.value.trim();
      if (email.isEmpty) {
        debugPrint('[Stripe] create-intent requires user email.');
        return StripeCheckoutOutcome.failed;
      }
      await Stripe.instance.applySettings();
      final fallbackPlanId = await _resolvePremiumPlanId();
      if (fallbackPlanId.isEmpty) {
        debugPrint('[Stripe] Could not resolve a planId from payment/plans.');
        return StripeCheckoutOutcome.failed;
      }

      final clientSecret = await _repo.createPaymentIntentClientSecret(
        planId: fallbackPlanId,
        email: email,
        accessToken: auth.accessToken.value,
        amount: StripeConfig.premiumAmount,
        description: StripeConfig.premiumDescription,
      );

      if (clientSecret == null || clientSecret.isEmpty) {
        debugPrint(
          '[Stripe] Missing clientSecret — implement backend POST ${AppUrls.stripeCreatePaymentIntent}',
        );
        return StripeCheckoutOutcome.failed;
      }

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: AppStrings.appName,
          // Keep sheet compact on TV by showing only primary card flow.
          paymentMethodOrder: const ['card'],
          allowsDelayedPaymentMethods: false,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      final paymentIntentId = _extractPaymentIntentId(clientSecret);
      await _confirmAndSyncPremium(
        paymentIntentId: paymentIntentId,
      );

      return StripeCheckoutOutcome.success;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return StripeCheckoutOutcome.cancelled;
      }
      debugPrint('[Stripe] ${e.error.message}');
      return StripeCheckoutOutcome.failed;
    } on MissingPluginException catch (e, st) {
      debugPrint(
        '[Stripe] Native Stripe plugin not linked (MissingPluginException).\n'
        '1) Uninstall the app from the device (old APKs keep native code without Stripe).\n'
        '2) flutter clean && flutter pub get\n'
        '3) flutter run --flavor mobile (or your flavor) — not hot restart.\n'
        'Logcat: filter for "Error registering plugin stripe" if it still fails.\n'
        '$e\n$st',
      );
      return StripeCheckoutOutcome.failed;
    } catch (e, st) {
      debugPrint('[Stripe] checkout error: $e\n$st');
      return StripeCheckoutOutcome.failed;
    }
  }

  Future<List<StripePlan>> fetchAllPlans() => _repo.fetchPlans();

  Future<StripeCheckoutOutcome> checkoutPlan(StripePlan plan) async {
    if (plan.price <= 0) {
      return _activateFreePlan(plan);
    }
    try {
      final auth = Get.find<AuthService>();
      if (!auth.isLoggedIn.value || auth.accessToken.value.isEmpty) {
        debugPrint('[Stripe] create-intent requires logged-in user token.');
        return StripeCheckoutOutcome.failed;
      }
      final email = auth.userEmail.value.trim();
      if (email.isEmpty) {
        debugPrint('[Stripe] create-intent requires user email.');
        return StripeCheckoutOutcome.failed;
      }
      await Stripe.instance.applySettings();
      final amount = plan.price.round();
      final description =
          plan.description.isNotEmpty ? plan.description : '${plan.name} Plan';
      final clientSecret = await _repo.createPaymentIntentClientSecret(
        planId: plan.id,
        email: email,
        accessToken: auth.accessToken.value,
        amount: amount,
        description: description,
      );
      if (clientSecret == null || clientSecret.isEmpty) {
        return StripeCheckoutOutcome.failed;
      }
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: AppStrings.appName,
          paymentMethodOrder: const ['card'],
          allowsDelayedPaymentMethods: false,
        ),
      );
      await Stripe.instance.presentPaymentSheet();
      final paymentIntentId = _extractPaymentIntentId(clientSecret);
      await _confirmAndSyncPremium(
        paymentIntentId: paymentIntentId,
      );
      return StripeCheckoutOutcome.success;
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return StripeCheckoutOutcome.cancelled;
      }
      debugPrint('[Stripe] ${e.error.message}');
      return StripeCheckoutOutcome.failed;
    } catch (e, st) {
      debugPrint('[Stripe] checkout plan error: $e\n$st');
      return StripeCheckoutOutcome.failed;
    }
  }

  String _extractPaymentIntentId(String clientSecret) {
    final idx = clientSecret.indexOf('_secret_');
    if (idx <= 0) return clientSecret;
    return clientSecret.substring(0, idx);
  }

  Future<StripeCheckoutOutcome> _activateFreePlan(StripePlan plan) async {
    try {
      final auth = Get.find<AuthService>();
      if (!auth.isLoggedIn.value || auth.accessToken.value.isEmpty) {
        await AdsVariable.markPurchased();
        return StripeCheckoutOutcome.success;
      }
      await _confirmAndSyncPremium(
        paymentIntentId: 'free_${DateTime.now().millisecondsSinceEpoch}',
      );
      return StripeCheckoutOutcome.success;
    } catch (_) {
      return StripeCheckoutOutcome.failed;
    }
  }

  Future<void> _confirmAndSyncPremium({
    required String paymentIntentId,
  }) async {
    try {
      final auth = Get.find<AuthService>();
      if (!auth.isLoggedIn.value || auth.accessToken.value.isEmpty) {
        await AdsVariable.markPurchased();
        return;
      }
      final (ok, _) = await _repo.confirmPayment(
        accessToken: auth.accessToken.value,
        paymentIntentId: paymentIntentId,
      );
      if (ok) {
        await auth.syncPremiumFromServer();
      } else {
        await auth.applyLocalPremiumFromPurchase();
      }
    } catch (_) {
      await AdsVariable.markPurchased();
      try {
        await Get.find<AuthService>().applyLocalPremiumFromPurchase();
      } catch (_) {}
    }
  }

  Future<String> _resolvePremiumPlanId() async {
    // Keep explicit env override highest priority for controlled testing.
    if (StripeConfig.premiumPlanId.isNotEmpty) {
      return StripeConfig.premiumPlanId;
    }

    final plans = await _repo.fetchPlans(interval: 'yearly');
    if (plans.isEmpty) return '';

    StripePlan? pickByName(List<StripePlan> list) {
      for (final p in list) {
        final n = p.name.toLowerCase();
        if (n.contains('premium') || n.contains('pro') || n.contains('paid')) {
          return p;
        }
      }
      return null;
    }

    final paidPlans = plans.where((p) => p.price > 0).toList();
    final preferredPaidByName = pickByName(paidPlans);
    if (preferredPaidByName != null) return preferredPaidByName.id;

    if (paidPlans.isNotEmpty) {
      paidPlans.sort((a, b) => b.price.compareTo(a.price));
      return paidPlans.first.id;
    }

    final preferredAnyByName = pickByName(plans);
    if (preferredAnyByName != null) return preferredAnyByName.id;
    return plans.first.id;
  }
}
