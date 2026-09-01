import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/ui/mobile/favorites_screen.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/ads/app_open_ad_manager.dart';
import 'package:iptv_demo/ads/banner_ad_widget.dart';
import 'package:iptv_demo/ads/interstitial_ad_manager.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/utils/premium_access.dart';
import 'package:iptv_demo/ui/mobile/home_screen.dart';
import 'package:iptv_demo/ui/mobile/search_screen.dart';
import 'package:iptv_demo/ui/mobile/settings_screen.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class BottomNavigation extends StatefulWidget {
  const BottomNavigation({super.key});

  @override
  State<BottomNavigation> createState() => _BottomNavigationState();
}

class _BottomNavigationState extends State<BottomNavigation> {
  final IptvController controller = Get.find<IptvController>();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final List<Widget> screens = [
    HomeScreen(),
    const SearchScreen(),
    const FavoritesScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        if (auth.isLoggedIn.value) {
          unawaited(auth.syncPremiumFromServer());
        }
      }
      AppOpenAdManager.instance.showOnHomeIfColdStart(
        delay: const Duration(milliseconds: 500),
      );
      InterstitialAdManager.instance.preload();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currentIndex =
          controller.selectedIndex.value.clamp(0, screens.length - 1);
      if (Get.isRegistered<AuthService>()) {
        final auth = Get.find<AuthService>();
        auth.isPremiumUser.value;
        auth.isLoggedIn.value;
        auth.currentProfile.value;
        AdsVariable.isPurchased.value;
      }
      final showPremiumButton = !userHasPremiumAccess;
      return Scaffold(
        key: _scaffoldKey,
        backgroundColor: context.scaffoldBg,
        appBar: AppBar(
          toolbarHeight: 56.h,
          backgroundColor: context.navBarBg,
          title: CustomText(
            AppStrings.appName,
            fontFamily: AppStrings.interBold,
            fontSize: 22.sp,
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true,
          leading: Padding(
            padding: EdgeInsets.only(left: 12.w, top: 8.h, bottom: 13.h),
            child: Image.asset(
              Assets.images.logoWithoutBg.path,
              width: 32.w,
              height: 32.w,
               
                fit: BoxFit.contain,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.search, color: context.appIconColor, size: 26.r),
              onPressed: () {
                controller.selectedIndex.value = 1;
              },
            ),
            if (showPremiumButton)
              Padding(
                padding: EdgeInsets.only(right: 8.w),
                child: GestureDetector(
                  onTap: () => Get.toNamed(AppRoutes.PREMIUM),
                  child: Image.asset(
                    Assets.images.premiumIcon.path,
                    height: 32.r,
                    width: 32.r,
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(child: screens[currentIndex]),
            if (AdsVariable.shouldShowAds && currentIndex == 3)
              const BannerAdWidget(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: context.navBarBg,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildNavItem(
                    icon: Assets.images.bottomNavigation.home.path,
                    selectedIcon:
                        Assets.images.bottomNavigation.selectedHome.path,
                    label: AppStrings.home,
                    index: 0,
                    isSelected: currentIndex == 0,
                  ),
                  _buildNavItem(
                    icon: Assets.images.bottomNavigation.search.path,
                    selectedIcon:
                        Assets.images.bottomNavigation.selectedSearch.path,
                    label: AppStrings.search,
                    index: 1,
                    isSelected: currentIndex == 1,
                  ),
                  _buildNavItem(
                    icon: Assets.images.bottomNavigation.favorite.path,
                    selectedIcon:
                        Assets.images.bottomNavigation.selectedFavorite.path,
                    label: AppStrings.favorites,
                    index: 2,
                    isSelected: currentIndex == 2,
                  ),
                  _buildNavItem(
                    icon: Assets.images.bottomNavigation.setting.path,
                    selectedIcon: Assets.images.bottomNavigation.setting.path,
                    label: AppStrings.settings,
                    index: 3,
                    isSelected: currentIndex == 3,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem({
    required String icon,
    required String selectedIcon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        controller.selectedIndex.value = index;
      },
      child: Container(
        constraints: BoxConstraints(
          minWidth: 48.w,
          minHeight: 48.h,
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected
              ? context.navSelectedBg
              : AppColors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              isSelected ? selectedIcon : icon,
              width: 24.r,
              height: 24.r,
              fit: BoxFit.contain,
            ),
            4.verticalSpace,
            GradientText(
              label,
              colors: isSelected
                  ? AppColors.primaryGradient
                  : [context.textMuted, context.textMuted],
              style: TextStyle(
                fontSize: 11.sp,
                fontFamily: AppStrings.interMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
