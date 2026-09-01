import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/profile_controller.dart';
import 'package:iptv_demo/model/user_profile.dart';
import 'package:iptv_demo/ads/inline_ad_slot.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: context.appIconColor,
            size: 20.sp,
          ),
          onPressed: () => Get.back(),
        ),
        title: CustomText(
          AppStrings.profile,
          color: context.textPrimary,
          fontSize: 18.sp,
          fontFamily: AppStrings.interSemiBold,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),
            );
          }
          final p = controller.profile.value;
          if (p == null) {
            return _buildError(context);
          }
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAvatarCard(context, p),
                24.verticalSpace,
                _buildInfoCard(
                  context,
                  children: [
                    _buildRow(context, AppStrings.profileFieldName, p.name),
                    _divider(context),
                    _buildRow(context, AppStrings.profileFieldEmail, p.email),
                    if (p.role != null && p.role!.isNotEmpty) ...[
                      _divider(context),
                      _buildRow(context, AppStrings.profileFieldRole, p.role!),
                    ],
                    if (p.phone != null && p.phone!.isNotEmpty) ...[
                      _divider(context),
                      _buildRow(context, AppStrings.profileFieldPhone, p.phone!),
                    ],
                  ],
                ),
                24.verticalSpace,
                const StackedAdFooter(horizontal: 0),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off_outlined, size: 56.sp, color: context.planDetailTextColor),
          16.verticalSpace,
          CustomText(
            controller.errorMessage.value,
            textAlign: TextAlign.center,
            color: context.planDetailTextColor,
            fontSize: 15.sp,
            fontFamily: AppStrings.interRegular,
            maxLines: 6,
          ),
          28.verticalSpace,
          GestureDetector(
            onTap: () => controller.load(),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 28.w, vertical: 14.h),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: CustomText(
                AppStrings.retry,
                color: AppColors.white,
                fontSize: 15.sp,
                fontFamily: AppStrings.interSemiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarCard(BuildContext context, UserProfile p) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.cardBorderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72.w,
            height: 72.w,
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
            alignment: Alignment.center,
            child: CustomText(
              p.initials,
              color: AppColors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              fontFamily: AppStrings.interBold,
              maxLines: 1,
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  p.displayName,
                  color: context.textPrimary,
                  fontSize: 18.sp,
                  fontFamily: AppStrings.interSemiBold,
                  fontWeight: FontWeight.w600,
                  maxLines: 2,
                ),
                if (p.email.isNotEmpty && p.displayName != p.email) ...[
                  6.verticalSpace,
                  CustomText(
                    p.email,
                    color: context.planDetailTextColor,
                    fontSize: 13.sp,
                    fontFamily: AppStrings.interRegular,
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.planCardBg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(children: children),
    );
  }

  Widget _divider(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: context.dividerColor);
  }

  Widget _buildRow(BuildContext context, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88.w,
            child: CustomText(
              label,
              color: context.planCardTextColor,
              fontSize: 12.sp,
              fontFamily: AppStrings.interSemiBold,
              maxLines: 2,
            ),
          ),
          Expanded(
            child: CustomText(
              value,
              color: context.textPrimary,
              fontSize: 14.sp,
              fontFamily: AppStrings.interRegular,
              maxLines: 8,
            ),
          ),
        ],
      ),
    );
  }
}
