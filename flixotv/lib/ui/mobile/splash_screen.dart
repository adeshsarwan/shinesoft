import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/ads/app_open_ad_manager.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';
import 'package:iptv_demo/utils/premium_access.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 2));

    final auth = Get.find<AuthService>();
    await AdsVariable.loadPersistedPurchase(
      includeAuthPremium: auth.isLoggedIn.value,
    );
    if (auth.isLoggedIn.value) {
      await auth.syncPremiumFromServer();
    }

    final route =
        await resolveSplashDestination(isLoggedIn: auth.isLoggedIn.value);

    // App-open on phone only — TV cold start skips it (poor fill + wastes a request).
    final isTv = await isAndroidTvLeanbackDevice();
    if (shouldShowAppOpenAd && !isTv) {
      AppOpenAdManager.instance.prepareColdStartForRoute(route);
    }

    Get.offAllNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Image.asset(
          Assets.images.appLogo.path,
          height: 200.h,
          width: 200.w,
          filterQuality: FilterQuality.high,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
