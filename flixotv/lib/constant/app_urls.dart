/// Common URL (and related HTTP) constants for the IPTV backend.
abstract final class AppUrls {
  AppUrls._();

  /// API root including `/api/v1` (no trailing slash).
  // static const String apiBase = 'https://iptvapi.shineinfosoft.in/api/v1';

  static const String apiBase = 'https://api.snapdockapp.com/iptv/api/v1';

  // —— Auth ———————————————————————————————————————————————————————————————
  static const String authLogin = '$apiBase/auth/login';
  static const String authRefresh = '$apiBase/auth/refresh';
  static const String authLogout = '$apiBase/auth/logout';
  static const String authRegister = '$apiBase/auth/register';
  static const String otpSendOtp = '$apiBase/otp/send-otp';
  static const String otpVerifyOtp = '$apiBase/otp/verify-otp';
  static const String authResetPassword = '$apiBase/auth/reset-password';
  static const String authProfile = '$apiBase/auth/profile';
  static const String authDelete = '$apiBase/auth/delete';

  // —— Notifications ——————————————————————————————————————————————————————
  static const String notificationsSchedule = '$apiBase/notifications/schedule';
  static const String notificationsCancelSchedule =
      '$apiBase/notifications/cancel/schedule';
  static const String notificationsCheckSchedule =
      '$apiBase/notifications/check/schedule';

  /// Channel EPG / program list for schedule UI (append Mongo `_id`).
  static const String channelProgramsBase = '$apiBase/channels/programs/';

  /// `POST` body: `{ "amount": <int>, "description": "<text>" }`.
  /// Response JSON must include `clientSecret` (or nested under `data`) for Stripe Payment Sheet.
  /// Create the PaymentIntent on your server with your Stripe **secret** key — never in the app.
  ///
  /// Override in dev builds when needed:
  /// `flutter run --dart-define=STRIPE_API_BASE=http://10.0.2.2:5002/api/v1`
  static const String stripeApiBase = String.fromEnvironment(
    'STRIPE_API_BASE',
    defaultValue: apiBase,
  );
  static const String stripeCreatePaymentIntent =
      '$stripeApiBase/payment/create-intent';
  static const String stripeConfirmPayment = '$stripeApiBase/payment/confirm-payment';
  static const String stripePlans = '$stripeApiBase/plans';

  // —— Content ————————————————————————————————————————————————————————————
  static const String channelsList = '$apiBase/channels/list';
  static const String channelInfoBase = '$apiBase/channels/info/';
  static const String category = '$apiBase/category';
  static const String countriesList = '$apiBase/countries';
  static const String languagesList = '$apiBase/language';

  /// EPG-style schedule for a channel (e.g. `StarSports2.in/69f9e4cb773ce9e7b89340e6`).
  /// Query: `limit`, optional `date=YYYY-MM-DD` (omit for server “today”).
  static String channelGuides(String channelId, String channelDbId) =>
      '$apiBase/guides/$channelId/$channelDbId';

  /// Append channel id or path segment (trailing slash included).
  static const String streamsBase = '$apiBase/streams/';

  /// Value for the `Cookie` header when the API expects a visitor id.
  static const String visitorCookie =
      'visitor_id=c972a33c-5312-4c09-ba40-98488c16a035';
}
