import 'package:package_info_plus/package_info_plus.dart';

final packageInfo = PackageInfo.fromPlatform();

class AppStrings {
  AppStrings._();
   static String appVersion = '';

  static Future<void> init() async {
    final packageInfo = await PackageInfo.fromPlatform();
    appVersion = 'App Version ${packageInfo.version} - Flixo TV';
  }

  static const String inter = 'Inter';
  static const String interRegular = 'InterRegular';
  static const String interMedium = 'InterMedium';
  static const String interSemiBold = 'InterSemiBold';
  static const String interBold = 'InterBold';
  static const String interExtraBold = 'InterExtraBold';
  static const String interBlack = 'InterBlack';

  static const String appName = 'Flixo TV';

  static const String appTitle = 'Flixo TV';
  static const String globalIptv = 'Global IPTV';
  static const String login = 'Login';
  static const String signUp = 'Sign Up';
  static const String importPlaylist = 'Import Playlist';
  static const String watchNow = 'Watch Now';
  static const String startWatching = 'Start Watching';
  static const String yourChannels = 'Your Channels';
  static const String browseImportedChannels = 'Browse your imported channels';
  static const String addPlaylistHelp =
      'Add your IPTV playlist by pasting the URL below';
  static const String playlistHint = 'e.g. https://yourlink.com/playlist.m3u';
  static const String loginSubtitle = 'IPTV Navigator Pilot Dashboard';
  static const String signUpSubtitle = 'The Precision Navigator for IPTV';
  static const String createAccount = 'Create Account';
  static const String createAccountSubtitle =
      'Join 10,000+ pilots navigating the digital stream.';
  static const String accountEmail = 'ACCOUNT EMAIL';
  static const String emailAddress = 'EMAIL ADDRESS';
  static const String fullName = 'FULL NAME';
  static const String password = 'PASSWORD';
  static const String securePassword = 'SECURE PASSWORD';
  static const String forgotPassword = 'Forgot Password?';
  static const String recoverPasswordTitle = 'Recover Password';
  static const String recoverPasswordSubtitle =
      'Enter your email and we will send you an OTP.';
  static const String sendOtp = 'Send OTP';
  static const String verifyOtp = 'Verify OTP';
  static const String verifyOtpTitle = 'OTP Verification';
  static const String verifyOtpSubtitle = 'Please enter the OTP sent to';
  static const String otpCode = 'OTP CODE';
  static const String otpHint = '000000';
  static const String resendOtp = 'Resend OTP';
  static const String resetPassword = 'Reset Password';
  static const String createNewPassword = 'Create New Password';
  static const String resetPasswordSubtitle =
      'Set a new password to access your account.';
  static const String newPassword = 'NEW PASSWORD';
  static const String confirmPassword = 'CONFIRM PASSWORD';
  static const String emailHint = 'pilot@streamline.com';
  static const String fullNameHint = 'Commander Shepard';
  static const String passwordHint = 'Enter Password';
  static const String keepAuthenticated = 'Keep me authenticated for 30 days';
  static const String loginWith = 'Or Login With';
  static const String signUpWith = 'Or Sign up With';
  static const String google = 'Google';
  static const String facebook = 'Facebook';
  static const String newToPlatform = 'New to the platform?';
  static const String requestAccount = 'Request Account';
  static const String alreadyMember = 'Already a member? ';
  static const String returnToLogin = 'Return to Login';
  static const String agreeTo = 'I agree to the ';
  static const String termsOfFlight = 'Terms of Flight';
  static const String andText = ' and ';
  static const String privacyProtocols = 'Privacy Protocols.';
  static const String searchChannels = 'Search 10,000+ channels...';
  static const String viewAll = 'VIEW ALL';
  static const String live = 'LIVE';
  static const String featuredContent = 'Dune: Part Two';
  static const String all = 'All';
  static const String movies = 'Movies';
  static const String sports = 'Sports';
  static const String news = 'News';
  static const String science = 'Science';
  static const String entertainment = 'Entertainment';

  // Settings Screen
  static const String currentPlan = 'CURRENT PLAN';
  static const String adsFreePlan = 'Ads Free Plan';
  static const String renewalDateLabel = 'Renewal Date:';
  static const String monthlyCostLabel = 'Monthly Cost:';
  static const String manageSubscription = 'Manage Subscription';
  static const String generalSettings = 'GENERAL SETTINGS';
  static const String accountSettings = 'ACCOUNT';
  static const String language = 'Language';
  static const String country = 'Country';
  static const String playbackQuality = 'Playback Quality';
  static const String pushNotifications = 'Push Notifications';
  static const String liveAlertsUpdates = 'Live alerts & updates';
  static const String signOut = 'Sign Out';
  static const String signOutSubtitle = 'Sign out on this device';
  static const String signOutConfirmTitle = 'Sign out?';
  static const String signOutConfirmMessage =
      'Are you sure you want to sign out?';
  static const String signOutConfirmAction = 'Sign out';
  static const String profile = 'Profile';
  static const String profileFieldName = 'NAME';
  static const String profileFieldEmail = 'EMAIL';
  static const String profileFieldRole = 'ROLE';
  static const String profileFieldPhone = 'PHONE';
  static const String retry = 'Retry';
  static const String deleteAccount = 'Delete account';
  static const String deleteAccountSubtitle =
      'Permanently remove your account and data';
  static const String deleteAccountConfirmTitle = 'Delete account?';
  static const String deleteAccountConfirmMessage =
      'This cannot be undone. Your account and associated data will be permanently removed.';
  static const String deleteAccountConfirmAction = 'Delete';
  // static const String appVersion = 'App Version 1.0.0-Flixo TV';
  static const String selectLanguage = 'Select language';
  static const String selectCountry = 'Select country';
  static const String filteringChannels = 'Filtering channels...';
  static const String cancel = 'Cancel';
  static const String scheduleNotificationLoginTitle = 'Sign in required';
  static const String scheduleNotificationLoginMessage =
      'Please login first to schedule a notification for this program.';
  static const String loginAction = 'Login';

  // Sections
  static const String searchResults = 'SEARCH RESULTS';
  static const String yourFavorites = 'YOUR FAVORITES';
  static const String noChannelsFound = 'No channels found';
  static const String noChannelsMatchHint =
      'Try another category, clear your search, or change language and country in Settings.';
  static const String resetBrowseFilters = 'Reset search & category';
  static const String goToSettings = 'Go to Settings';
  static const String favorites = 'Favorites';
  static const String settings = 'Settings';
  static const String home = 'Home';
  static const String search = 'Search';
  static const String loadingVideo = 'Loading video...';

  // Premium Screen
  static const String pureEntertainment = 'Pure Entertainment';
  static const String premiumSubtitle =
      'Say goodbye to interruptions. Upgrade to Streamline Ads-Free and enjoy a seamless viewing experience.';
  static const String mostPopular = 'MOST POPULAR';
  static const String upgradeOption = 'UPGRADE OPTION';
  static const String adsFreePro = 'Ads-Free Pro';
  static const String perYear = '     /Year';
  static const String cancellationPolicy = 'Cancel anytime. No hidden fees.';
  static const String featureZeroAds = 'Zero Commercial Interruptions';
  static const String featurePriorityStream =
      'Priority Global High-Speed Streaming';
  static const String featureDedicatedSupport = '24/7 Dedicated Support Access';
  static const String featureOfflineDownloads = 'Unlimited Offline Downloads';
  static const String upgradeButtonText = 'UPGRADE TO ADS-FREE';
  static const String premiumPaymentSuccess =
      'Welcome to Premium! Your subscription is active.';
  static const String premiumPaymentCancelled = 'Checkout was cancelled.';
  static const String premiumPaymentFailed =
      'Payment could not be completed. Ensure the Stripe backend endpoint is configured.';
  static const String trialInfo = '7-day free trial included for new members.';
}
