/// Stripe **publishable** key (safe in the client). Test mode.
///
/// **Never** put your **secret** key (`sk_...`) in Flutter code or in the repo.
/// The secret must live only on your backend when you call
/// `stripe.paymentIntents.create(...)`.
abstract final class StripeConfig {
  StripeConfig._();

  /// Test publishable key (replace with `pk_live_...` for production).
  // static const String publishableKey =
  //     'pk_test_51TQkgPINrj9sezwqPIFm0TXy38hplsbUiPovH0nEpliYjqqhOhC4GclwrNAQXOBXLD8m7TdIY203xpyCj18EpTpr00EsNSa90C';

//live key
  static const String publishableKey =
      'pk_live_51T4gycJGxw8tPZYuTvSbhLHNT9rLV6h9nf3rkTWYjAWCCCWvSxS1CxD25q8CalJdTr8zHXXXpxZkER1mMOZRJ0Ba00e0VQ8Pqd';

  /// Premium plan amount sent to backend create-intent API.
  static const int premiumAmount = 99;

  static const String premiumDescription = 'Flixo Premium Yearly';

  /// Backend subscription plan id used by `POST /payment/confirm-payment`.
  /// Set at build/run time:
  /// `--dart-define=STRIPE_PREMIUM_PLAN_ID=<mongo-plan-id>`
  static const String premiumPlanId = String.fromEnvironment(
    'STRIPE_PREMIUM_PLAN_ID',
    defaultValue: '',
  );
}
