import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/constant/static_locale_data.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/services/theme_service.dart';
import 'package:iptv_demo/ads/inline_ad_slot.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final IptvController _controller = Get.find<IptvController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(Get.find<AuthService>().syncPremiumFromServer());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              15.verticalSpace,
              _buildUserProfileSection(),
              _buildCurrentPlanSection(),
              30.verticalSpace,
              _buildGeneralSettingsSection(),
              _buildAccountSettingsSection(),
              28.verticalSpace,
              _buildVersionInfo(),
              32.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserProfileSection() {
    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.PROFILE),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.all(15.w),
        margin: EdgeInsets.symmetric(horizontal: 15.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowColor,
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          image: context.isDark
              ? null
              : DecorationImage(
                  image: AssetImage(Assets.images.settings.accountCardBg.path),
                  fit: BoxFit.fill,
                ),
          color: context.isDark ? context.cardBg : null,
        ),
        child: Stack(
          children: [
            if (!context.isDark)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
              ),
            Obx(() {
              final auth = Get.find<AuthService>();
              final email = auth.userEmail.value;
              final display = email.isNotEmpty
                  ? email.split('@').first
                  : AppStrings.profile;
              final initials = _initialsFromEmail(email);
              return Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 80.w,
                    height: 80.w,
                    decoration: BoxDecoration(
                      color: AppColors.avatarBackground,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.isDark
                            ? AppColors.primary.withValues(alpha: 0.4)
                            : AppColors.avatarBorder,
                        width: 3.w,
                      ),
                    ),
                    child: Center(
                      child: CustomText(
                        initials,
                        color: AppColors.white,
                        fontSize: 35.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppStrings.interBold,
                        maxLines: 1,
                      ),
                    ),
                  ),
                  15.horizontalSpace,
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          display,
                          color: context.textPrimary,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: AppStrings.interSemiBold,
                          maxLines: 1,
                        ),
                        if (email.isNotEmpty) ...[
                          4.verticalSpace,
                          CustomText(
                            email,
                            color: context.planDetailTextColor,
                            fontSize: 12.sp,
                            fontFamily: AppStrings.interRegular,
                            maxLines: 1,
                          ),
                        ],
                        if (auth.isPremiumUser.value) ...[
                          8.verticalSpace,
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: context.isDark
                                  ? AppColors.primary.withValues(alpha: 0.2)
                                  : AppColors.avatarBorder,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.stars_rounded,
                                  color: context.isDark
                                      ? AppColors.secondary
                                      : AppColors.premiumBadgeText,
                                  size: 15.sp,
                                ),
                                4.horizontalSpace,
                                CustomText(
                                  'PREMIUM',
                                  color: context.isDark
                                      ? AppColors.secondary
                                      : AppColors.premiumBadgeText,
                                  fontSize: 15.sp,
                                  fontFamily: AppStrings.interSemiBold,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.planDetailTextColor,
                    size: 28.sp,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  String _initialsFromEmail(String email) {
    if (email.isEmpty) return '?';
    final local =
        email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (local.length >= 2) {
      return local.substring(0, 2).toUpperCase();
    }
    if (local.isNotEmpty) return local[0].toUpperCase();
    return email[0].toUpperCase();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final d = date.day.toString().padLeft(2, '0');
    final m = months[date.month - 1];
    final y = date.year;
    return '$d $m $y';
  }

  String _normalizePlanTitle(String? rawPlan, bool isPremium) {
    final plan = (rawPlan ?? '').trim();
    if (plan.isNotEmpty) {
      final lower = plan.toLowerCase();
      if (lower.endsWith('plan')) {
        return '${plan[0].toUpperCase()}${plan.substring(1)}';
      }
      return '${plan[0].toUpperCase()}${plan.substring(1)} Plan';
    }
    return isPremium ? AppStrings.adsFreePlan : 'Free Plan';
  }

  String _formatCost({
    required String? amountFormatted,
    required double? amount,
    required String? currency,
    required bool isPremium,
  }) {
    final code = (currency ?? '').trim().toUpperCase();
    final formatted = (amountFormatted ?? '').trim();
    if (formatted.isNotEmpty) {
      if (code.isEmpty) return formatted;
      final lower = formatted.toLowerCase();
      final hasCurrency = lower.startsWith(code.toLowerCase()) ||
          lower.startsWith('₹') ||
          lower.startsWith('\$') ||
          lower.startsWith('€');
      return hasCurrency ? formatted : '$code $formatted';
    }
    if (amount != null) {
      final value = amount % 1 == 0 ? amount.toInt().toString() : amount.toStringAsFixed(2);
      if (code.isEmpty) return value;
      return '$code $value';
    }
    return isPremium ? 'Paid' : '0';
  }

  String _costWithCycleSuffix({
    required String costText,
    required String? rawCycle,
  }) {
    final cycle = (rawCycle ?? '').trim().toLowerCase();
    if (costText == '0' || costText == '—') return costText;
    if (cycle == 'yearly' || cycle == 'annual' || cycle == 'year') {
      return '$costText / year';
    }
    if (cycle == 'monthly' || cycle == 'month') {
      return '$costText / month';
    }
    if (cycle == 'weekly' || cycle == 'week') {
      return '$costText / week';
    }
    return costText;
  }

  void _showSignOutConfirmDialog() {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (BuildContext dialogContext) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
          backgroundColor: AppColors.transparent,
          elevation: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 20.h),
            decoration: BoxDecoration(
              color: dialogContext.cardBg,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: dialogContext.borderColor, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomText(
                  AppStrings.signOutConfirmTitle,
                  fontSize: 20.sp,
                  fontFamily: AppStrings.interSemiBold,
                  fontWeight: FontWeight.w600,
                  color: dialogContext.textPrimary,
                ),
                12.verticalSpace,
                CustomText(
                  AppStrings.signOutConfirmMessage,
                  fontSize: 14.sp,
                  fontFamily: AppStrings.interRegular,
                  color: dialogContext.planDetailTextColor,
                  maxLines: 4,
                ),
                24.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: dialogContext.isDark
                                ? dialogContext.chipUnselectedBg
                                : AppColors.white,
                            borderRadius: BorderRadius.circular(14.r),
                            border:
                                Border.all(color: dialogContext.borderColor),
                          ),
                          child: CustomText(
                            AppStrings.cancel,
                            fontSize: 15.sp,
                            fontFamily: AppStrings.interSemiBold,
                            color: dialogContext.planDetailTextColor,
                          ),
                        ),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          Navigator.of(dialogContext).pop();
                          await Get.find<AuthService>().logout();
                          Get.offAllNamed(AppRoutes.LOGIN);
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          decoration: BoxDecoration(
                            color: AppColors.signOutButtonTextColor
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(
                              color: AppColors.signOutButtonBorderColor,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout,
                                color: AppColors.signOutButtonTextColor,
                                size: 18.sp,
                              ),
                              6.horizontalSpace,
                              CustomText(
                                AppStrings.signOutConfirmAction,
                                fontSize: 15.sp,
                                fontFamily: AppStrings.interSemiBold,
                                color: AppColors.signOutButtonTextColor,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountConfirmDialog() {
    bool deleting = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext ctx,
              void Function(void Function()) setDialogState) {
            return Dialog(
              insetPadding: EdgeInsets.symmetric(horizontal: 24.w),
              backgroundColor: AppColors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 20.h),
                decoration: BoxDecoration(
                  color: ctx.cardBg,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: ctx.borderColor, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadowColor,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomText(
                      AppStrings.deleteAccountConfirmTitle,
                      fontSize: 20.sp,
                      fontFamily: AppStrings.interSemiBold,
                      fontWeight: FontWeight.w600,
                      color: AppColors.signOutButtonTextColor,
                    ),
                    12.verticalSpace,
                    CustomText(
                      AppStrings.deleteAccountConfirmMessage,
                      fontSize: 14.sp,
                      fontFamily: AppStrings.interRegular,
                      color: ctx.planDetailTextColor,
                      maxLines: 6,
                    ),
                    if (deleting) ...[
                      20.verticalSpace,
                      Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                    if (!deleting) 24.verticalSpace,
                    if (!deleting)
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Navigator.of(ctx).pop(),
                              child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                decoration: BoxDecoration(
                                  color: ctx.isDark
                                      ? ctx.chipUnselectedBg
                                      : AppColors.white,
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(color: ctx.borderColor),
                                ),
                                child: CustomText(
                                  AppStrings.cancel,
                                  fontSize: 15.sp,
                                  fontFamily: AppStrings.interSemiBold,
                                  color: ctx.planDetailTextColor,
                                ),
                              ),
                            ),
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                if (deleting) return;
                                setDialogState(() => deleting = true);
                                final (ok, msg) = await Get.find<AuthService>()
                                    .deleteAccount();
                                if (!ctx.mounted) return;
                                Navigator.of(ctx).pop();
                                if (ok) {
                                  Get.offAllNamed(AppRoutes.LOGIN);
                                } else {
                                  showAppToast(
                                    title: 'Error',
                                    message: msg,
                                    isError: true,
                                  );
                                }
                              },
                              child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(vertical: 14.h),
                                decoration: BoxDecoration(
                                  color: AppColors.signOutButtonTextColor
                                      .withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(14.r),
                                  border: Border.all(
                                    color: AppColors.signOutButtonTextColor,
                                    width: 2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.delete_forever_rounded,
                                      color: AppColors.signOutButtonTextColor,
                                      size: 18.sp,
                                    ),
                                    6.horizontalSpace,
                                    CustomText(
                                      AppStrings.deleteAccountConfirmAction,
                                      fontSize: 15.sp,
                                      fontFamily: AppStrings.interSemiBold,
                                      color: AppColors.signOutButtonTextColor,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentPlanSection() {
    return Obx(() {
      final auth = Get.find<AuthService>();
      final isPremium = auth.isPremiumUser.value;
      final profile = auth.currentProfile.value;
      final hasActiveSubscription = isPremium ||
          (profile?.subscriptionPlan?.trim().isNotEmpty ?? false) ||
          profile?.renewalDate != null ||
          (profile?.subscriptionAmount != null &&
              (profile!.subscriptionAmount ?? 0) > 0);
      final planTitle = _normalizePlanTitle(profile?.subscriptionPlan, isPremium);
      final renewalText = _formatDate(profile?.renewalDate);
      final baseCostText = _formatCost(
        amountFormatted: profile?.subscriptionAmountFormatted,
        amount: profile?.subscriptionAmount,
        currency: profile?.subscriptionCurrency,
        isPremium: isPremium,
      );
      final planCostText = _costWithCycleSuffix(
        costText: baseCostText,
        rawCycle: profile?.billingCycle,
      );
      return Container(
        padding: EdgeInsets.all(20.w),
        margin: EdgeInsets.symmetric(horizontal: 15.w),
        decoration: BoxDecoration(
          color: context.planCardBg,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  AppStrings.currentPlan,
                  color: context.planCardTextColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: AppStrings.interSemiBold,
                ),
                if (isPremium)
                  Image.asset(Assets.images.settings.verified.path,
                      width: 20.w, height: 20.h),
              ],
            ),
            10.verticalSpace,
            Row(
              children: [
                CustomText(
                  planTitle,
                  color: context.textPrimary,
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: AppStrings.interSemiBold,
                ),
              ],
            ),
            16.verticalSpace,
            _buildPlanDetail('Renewal Date:', renewalText),
            12.verticalSpace,
            _buildPlanDetail('Plan Cost:', planCostText),
            if (hasActiveSubscription) ...[
              // No extra spacing here unless you render action buttons for premium.
              // Row(
              //   children: [
              //     Expanded(
              //       child: GestureDetector(
              //         onTap: () => _showCancelSubscriptionDialog(auth),
              //         child: Container(
              //           height: 48.h,
              //           decoration: BoxDecoration(
              //             color: context.isDark
              //                 ? context.chipUnselectedBg
              //                 : AppColors.white,
              //             borderRadius: BorderRadius.circular(25.r),
              //             border: Border.all(color: context.borderColor),
              //           ),
              //           child: Center(
              //             child: CustomText(
              //               'Cancel Plan',
              //               color: AppColors.signOutButtonTextColor,
              //               fontSize: 16.sp,
              //               fontWeight: FontWeight.w600,
              //               fontFamily: AppStrings.interSemiBold,
              //             ),
              //           ),
              //         ),
              //       ),
              //     ),
              //     12.horizontalSpace,
              //     Expanded(
              //       child: GestureDetector(
              //         onTap: () async {
              //           await Get.toNamed(AppRoutes.PREMIUM);
              //           await auth.syncPremiumFromServer();
              //         },
              //         child: Container(
              //           height: 48.h,
              //           decoration: BoxDecoration(
              //             gradient: LinearGradient(colors: AppColors.primaryGradient),
              //             borderRadius: BorderRadius.circular(25.r),
              //           ),
              //           child: Row(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: [
              //               CustomText(
              //                 'Upgrade Plan',
              //                 color: AppColors.white,
              //                 fontSize: 16.sp,
              //                 fontWeight: FontWeight.w600,
              //                 fontFamily: AppStrings.interSemiBold,
              //               ),
              //               5.horizontalSpace,
              //               Icon(Icons.arrow_forward_ios_rounded,
              //                   color: AppColors.white, size: 14.w),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ] else ...[
              24.verticalSpace,
              GestureDetector(
                onTap: () async {
                  await Get.toNamed(AppRoutes.PREMIUM);
                  await auth.syncPremiumFromServer();
                },
                child: Container(
                  width: double.infinity,
                  height: 48.h,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomText(
                        AppStrings.manageSubscription,
                        color: AppColors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                        fontFamily: AppStrings.interSemiBold,
                      ),
                      5.horizontalSpace,
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: AppColors.white, size: 16.w),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildPlanDetail(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          label,
          color: context.planDetailTextColor,
          fontSize: 16.sp,
          fontFamily: AppStrings.interRegular,
        ),
        CustomText(
          value,
          color: context.textPrimary,
          fontSize: 16.sp,
          fontFamily: AppStrings.interMedium,
        ),
      ],
    );
  }

  Widget _buildGeneralSettingsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.generalSettings,
            color: context.planDetailTextColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            fontFamily: AppStrings.interSemiBold,
          ),
          15.verticalSpace,

          // Dark Mode toggle
          Obx(() {
            final themeService = Get.find<ThemeService>();
            return _buildSettingItem(
              icon: themeService.isDarkMode.value
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              title: 'Dark Mode',
              subtitle: themeService.isDarkMode.value
                  ? 'Dark theme enabled'
                  : 'Light theme enabled',
              onTap: () => themeService.toggleTheme(),
              showToggle: true,
              toggleValue: themeService.isDarkMode.value,
            );
          }),
          15.verticalSpace,

          Obx(() {
            final code = _controller.selectedCountryCode.value;
            return _buildSettingItem(
              icon: Icons.public_outlined,
              title: 'Channel Country',
              subtitle: countryNameForCode(code),
              onTap: () => Get.toNamed(AppRoutes.COUNTRY_SELECT),
              showArrow: true,
            );
          }),
          32.verticalSpace,
        ],
      ),
    );
  }

  Widget _buildAccountSettingsSection() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            AppStrings.accountSettings,
            color: context.planDetailTextColor,
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            fontFamily: AppStrings.interSemiBold,
          ),
          15.verticalSpace,
          _buildSettingItem(
            icon: Icons.delete_forever_outlined,
            title: AppStrings.deleteAccount,
            subtitle: AppStrings.deleteAccountSubtitle,
            onTap: _showDeleteAccountConfirmDialog,
            destructive: true,
            showArrow: true,
          ),
          15.verticalSpace,
          _buildSettingItem(
            icon: Icons.logout_rounded,
            title: AppStrings.signOut,
            subtitle: AppStrings.signOutSubtitle,
            onTap: _showSignOutConfirmDialog,
            destructive: true,
            showArrow: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool showArrow = false,
    bool showToggle = false,
    bool toggleValue = false,
    bool destructive = false,
  }) {
    final danger = AppColors.signOutButtonTextColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.settingsTileBg,
          borderRadius: BorderRadius.circular(20.r),
          border: destructive
              ? Border.all(
                  color: AppColors.signOutButtonBorderColor, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: destructive
                    ? danger.withValues(alpha: 0.12)
                    : context.settingsIconBg,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                icon,
                color: destructive ? danger : AppColors.primary,
                size: 25.w,
              ),
            ),
            15.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    color: destructive ? danger : context.textPrimary,
                    fontSize: 18.sp,
                    fontFamily: AppStrings.interSemiBold,
                  ),
                  if (subtitle.trim().isNotEmpty) ...[
                    2.verticalSpace,
                    CustomText(
                      subtitle,
                      color: context.planDetailTextColor,
                      fontSize: 14.sp,
                      fontFamily: AppStrings.interRegular,
                      maxLines: 2,
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              Icon(
                Icons.arrow_forward_ios,
                color: destructive
                    ? danger.withValues(alpha: 0.5)
                    : AppColors.grey,
                size: 16.w,
              )
            else if (showToggle)
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: toggleValue,
                  onChanged: (value) => onTap(),
                  activeThumbColor: AppColors.white,
                  activeTrackColor: AppColors.primary,
                  inactiveThumbColor: AppColors.currentPlanInfoCardTextColor,
                  inactiveTrackColor: AppColors.currentPlanInfoTexteColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Center(
      child: CustomText(
        AppStrings.appVersion,
        color: context.planDetailTextColor,
        fontSize: 12.sp,
        fontFamily: AppStrings.interRegular,
      ),
    );
  }

}
