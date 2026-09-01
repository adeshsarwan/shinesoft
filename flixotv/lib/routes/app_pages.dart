import 'package:get/get.dart';
import '../controller/profile_controller.dart';
import '../ui/mobile/splash_screen.dart';
import '../ui/mobile/login_screen.dart';
import '../ui/mobile/sign_up_screen.dart';
import '../ui/mobile/forgot_password_screen.dart';
import '../ui/mobile/verify_otp_screen.dart';
import '../ui/mobile/reset_password_screen.dart';
import '../ui/mobile/bottom_navigation.dart';
import '../ui/mobile/premium_screen.dart';
import '../ui/mobile/import_playlist_screen.dart';
import '../ui/mobile/country_select_screen.dart';
import '../ui/mobile/language_select_screen.dart';
import '../ui/mobile/channel_schedule_screen.dart';
import '../ui/mobile/profile_screen.dart';
import '../ui/mobile/settings_screen.dart';
import '../ui/tv/auth/forgot_password_tv_screen.dart';
import '../ui/tv/auth/login_tv_screen.dart';
import '../ui/tv/auth/reset_password_tv_screen.dart';
import '../ui/tv/auth/sign_up_tv_screen.dart';
import '../ui/tv/auth/verify_otp_tv_screen.dart';
import '../ui/tv/home_tv_screen.dart';
import '../ui/tv/schedule_tv_screen.dart';
import 'app_routes.dart';

class AppPages {
  static final pages = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashScreen(),
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
    ),
    GetPage(
      name: AppRoutes.SIGN_UP,
      page: () => const SignUpScreen(),
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.VERIFY_OTP,
      page: () => const VerifyOtpScreen(),
    ),
    GetPage(
      name: AppRoutes.RESET_PASSWORD,
      page: () => const ResetPasswordScreen(),
    ),
    GetPage(
      name: AppRoutes.HOME,
      page: () => const BottomNavigation(),
    ),
    GetPage(
      name: AppRoutes.LOGIN_TV,
      page: () => const LoginTvScreen(),
    ),
    GetPage(
      name: AppRoutes.SIGN_UP_TV,
      page: () => const SignUpTvScreen(),
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD_TV,
      page: () => const ForgotPasswordTvScreen(),
    ),
    GetPage(
      name: AppRoutes.VERIFY_OTP_TV,
      page: () => const VerifyOtpTvScreen(),
    ),
    GetPage(
      name: AppRoutes.RESET_PASSWORD_TV,
      page: () => const ResetPasswordTvScreen(),
    ),
    GetPage(
      name: AppRoutes.HOME_TV,
      page: () => const HomeTvScreen(),
    ),
    GetPage(
      name: AppRoutes.SCHEDULE_TV,
      page: () => const ScheduleTvScreen(),
    ),
    GetPage(
      name: AppRoutes.PREMIUM,
      page: () => const PremiumScreen(),
    ),
    GetPage(
      name: AppRoutes.IMPORT_PLAYLIST,
      page: () => const ImportPlaylistScreen(),
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => const SettingsScreen(),
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => const ProfileScreen(),
      binding: BindingsBuilder(() {
        Get.lazyPut(ProfileController.new);
      }),
    ),
    GetPage(
      name: AppRoutes.LANGUAGE_SELECT,
      page: () => const LanguageSelectScreen(),
    ),
    GetPage(
      name: AppRoutes.COUNTRY_SELECT,
      page: () => const CountrySelectScreen(),
    ),
    GetPage(
      name: AppRoutes.CHANNEL_SCHEDULE,
      page: () => const ChannelScheduleScreen(),
    ),
  ];
}
