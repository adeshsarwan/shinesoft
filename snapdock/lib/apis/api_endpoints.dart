class ApiEndpoints {

  static const baseUrl = "https://api.snapdockapp.com";

  // Instagram/facebook video download production /Live API
  // static const liveInstagramDownload = "https://instagram-kf1h.onrender.com/instagram-download";
  static const liveInstagramDownload = "$baseUrl/instagram-download";

  // Auth API
  static const login = "$baseUrl/login";
  static const register = "$baseUrl/register";
  static const forgotPassword = "$baseUrl/forgot-password";
  static const resetPassword = "$baseUrl/reset-password";
  static const logout = "$baseUrl/logout";
  static const deleteAccount = "$baseUrl/delete-account";

  // YouTube Download API
  static const youtubeDownload = "https://vidssave.com/api/proxy";

  //stripe apis:
  static const stripeCreatePaymentIntent = "$baseUrl/create-payment-intent";
  static const stripePaymentStatus = "$baseUrl/payment-status";
  static const getPlans = "$baseUrl/plans";
  static const getMySubscription = "$baseUrl/my-subscription";


}