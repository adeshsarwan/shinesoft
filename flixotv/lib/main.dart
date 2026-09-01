import 'dart:async';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/ad_id_service.dart';
import 'package:iptv_demo/ads/ad_mob_bootstrap.dart';
import 'package:iptv_demo/ads/app_open_ad_manager.dart';
import 'package:iptv_demo/constant/app_theme.dart';
import 'package:iptv_demo/constant/stripe_config.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/routes/app_pages.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/app_bindings.dart';
import 'package:iptv_demo/services/theme_service.dart';
import 'package:iptv_demo/ui/tv/tv_app.dart';
import 'package:iptv_demo/utils/push_token_util.dart';
import 'package:media_kit/media_kit.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await AppStrings.init();
  debugPrint(
    '[FCM background] id=${message.messageId} '
    'notification=${message.notification?.title} data=${message.data}',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AdIdService.init();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await Firebase.initializeApp();
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  Stripe.publishableKey = StripeConfig.publishableKey;
  await AdMobBootstrap.configureAndInitialize();
  AppOpenAdManager.instance.initialize();
  MediaKit.ensureInitialized();

  if (!kIsWeb) {
    attachFcmTokenRefreshListener();
    // Defer FCM — calling getToken during heavy startup causes SERVICE_NOT_AVAILABLE.
    unawaited(
      Future<void>.delayed(const Duration(seconds: 4), prefetchFcmToken),
    );
  }

  // Initialize ThemeService before runApp so saved theme is ready immediately
  final themeService = Get.put(ThemeService(), permanent: true);
  await themeService.onInit();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<bool> _isTvDevice() async {
    if (kIsWeb) return false;

    final info = DeviceInfoPlugin();
    final androidInfo = await info.androidInfo;
    return androidInfo.systemFeatures.contains('android.software.leanback');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isTvDevice(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final isTv = snapshot.data ?? false;
        if (isTv) {
          Get.find<ThemeService>().isDarkMode.value = true;
          return const TvApp();
        }
        return const MobileApp();
      },
    );
  }
}

class MobileApp extends StatelessWidget {
  const MobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Get.find<ThemeService>();

    return ScreenUtilInit(
      designSize: const Size(412, 915),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return Obx(() {
          final isDark = themeService.isDarkMode.value;
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: AppStrings.appTitle,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
            initialRoute: AppRoutes.SPLASH,
            getPages: AppPages.pages,
            initialBinding: AppBindings(),
          );
        });
      },
    );
  }
}
