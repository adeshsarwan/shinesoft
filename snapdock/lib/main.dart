import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:videodownloader/core/ads_services/app_open_ads_service.dart';
import 'package:videodownloader/core/constants/prefs_constants.dart';
import 'package:videodownloader/core/state/premium_state.dart';
import 'package:videodownloader/core/storage/shared_preferences/shared_prefs.dart';
import 'package:videodownloader/core/theme/color_utility.dart';
import 'package:videodownloader/screens/auth/login_screen.dart';
import 'package:videodownloader/screens/auth/signup_screen.dart';
import 'package:videodownloader/screens/home_screen/home_screen.dart';
import 'package:videodownloader/screens/splash_screen/splash_screen.dart';
import 'l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

ValueNotifier<Locale> appLocaleNotifier = ValueNotifier<Locale>(const Locale('en'));

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase may fail on unsupported platforms; allow app to continue
  }
  await SharedPrefs.init();

  // Configure Stripe (test mode with publishable key)
  Stripe.publishableKey =
  'pk_live_51T4gycJGxw8tPZYuTvSbhLHNT9rLV6h9nf3rkTWYjAWCCCWvSxS1CxD25q8CalJdTr8zHXXXpxZkER1mMOZRJ0Ba00e0VQ8Pqd';
      // 'pk_test_51T4gycJGxw8tPZYuuePywdIDXdWw0N9gC5LFwLrEbCsqppPY0PrNO00utlufUeOVqv5nceJz8VW63jd9Esnzw9s300ZIcDVSx2';
      
  Stripe.merchantIdentifier = 'videodownloader.app';
  await Stripe.instance.applySettings();
  if (Platform.isAndroid) {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = "VideoDownloader";
  }
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize App Open Ads only for non-premium users
  var isPremiumSaved =
      SharedPrefs.getData(PrefsConstants.isPremiumUser) as bool?;
  PremiumState.isPremium.value = isPremiumSaved ?? false;

  if (!PremiumState.isPremium.value) {
    await AppOpenAdsService().initialize();
  }
  
  // Keep test-device configuration only in debug builds.
  if (kDebugMode) {
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(
        testDeviceIds: ['A97B5C5902E042474AFB9E104E3AF5D6'],
      ),
    );
  }
  
  // Reset tracking for testing (remove this in production)
  // await AppOpenAdsService().resetTracking();
  // Start loading the ad early for non-premium users
  if (!PremiumState.isPremium.value) {
    AppOpenAdsService().preloadAd();
  }

  // Load saved locale
  var selectedLang = SharedPrefs.getData(PrefsConstants.selectedLanguage);
  if (selectedLang != null && selectedLang.isNotEmpty) {
    appLocaleNotifier.value = Locale(selectedLang);
  }
  runApp(Phoenix(child: MyApp()));
}

class MyApp extends StatefulWidget {
  MyApp({super.key});
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale>(
      valueListenable: appLocaleNotifier,
      builder: (context, locale, child) {
        return MaterialApp(
          locale: locale,
          title: 'Video Downloader',
          debugShowCheckedModeBanner: false,
          initialRoute: '/',
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('hi'),
            Locale('ja'),
            Locale('ru'),
            Locale('fil'),
          ],
          routes: {
            '/': (context) => const SpalshScreen(),
            '/home': (context) => HomePageScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
          },
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: ColorUtils.hexToColor(primaryColorBlue),
            ),
          ),
        );
      },
    );
  }
}