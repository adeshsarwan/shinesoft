import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/ui/mobile/video_player_screen.dart';
import 'package:iptv_demo/utils/premium_access.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'interstitial_ad_manager.dart';

class PremiumBottomSheet extends StatefulWidget {
  final IptvChannel channel;
  final VoidCallback onChannelUnlocked;

  const PremiumBottomSheet({
    super.key,
    required this.channel,
    required this.onChannelUnlocked,
  });

  @override
  State<PremiumBottomSheet> createState() => _PremiumBottomSheetState();
}

class _PremiumBottomSheetState extends State<PremiumBottomSheet> {
  @override
  void initState() {
    super.initState();
    InterstitialAdManager.instance.preload();
  }

  Future<void> _onWatchAdTap() async {
    final channel = widget.channel;
    Get.back();
    Get.to(() => PlayerScreen(channel: channel));
  }

  @override
  Widget build(BuildContext context) {
    if (userHasPremiumAccess) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
        widget.onChannelUnlocked();
      });
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      bottom: true,
      child: SingleChildScrollView(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 52.h),
              padding: EdgeInsets.only(
                top: 84.h,
                bottom: (20.h).clamp(20.0, 56.0),
              ),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(25.r),
                  topRight: Radius.circular(25.r),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        CustomText(
                          "Watch - Watch Ad First",
                          textAlign: TextAlign.center,
                          fontSize: 20.sp,
                          fontFamily: AppStrings.interSemiBold,
                          color: context.textPrimary,
                          maxLines: 1,
                        ),
                        10.verticalSpace,
                        CustomText(
                          "One short ad to unlock this Channel",
                          textAlign: TextAlign.center,
                          fontSize: 14.sp,
                          color: context.textSecondary,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                  30.verticalSpace,
                  Divider(height: 1, color: context.dividerColor),
                  20.verticalSpace,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50.h,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: AppColors.premiumGradient,
                              ),
                              borderRadius: BorderRadius.circular(30.r),
                            ),
                            child: TextButton(
                              onPressed: _onWatchAdTap,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomText(
                                    "Watch",
                                    color: AppColors.white,
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    maxLines: 1,
                                  ),
                                  8.horizontalSpace,
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 6.w,
                                      vertical: 1.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.white,
                                      borderRadius: BorderRadius.circular(4.r),
                                    ),
                                    child: CustomText(
                                      "Ad",
                                      color: AppColors.secondary,
                                      fontSize: 10.sp,
                                      fontWeight: FontWeight.w700,
                                      maxLines: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        15.horizontalSpace,
                        Expanded(
                          child: Container(
                            height: 50.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30.r),
                              border: Border.all(
                                color: AppColors.secondary,
                                width: 2,
                              ),
                            ),
                            child: TextButton(
                              onPressed: () => Get.back(),
                              child: CustomText(
                                "Cancel",
                                color: AppColors.secondary,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                maxLines: 1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: 120.w,
                  height: 120.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.cardBg,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      Assets.images.ads.bottomSheetHeaderIcon.path,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12.h,
              right: 16.w,
              child: IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.close, color: context.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
