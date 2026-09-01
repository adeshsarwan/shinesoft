import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      showAppToast(
        title: 'Invalid Email',
        message: 'Please enter a valid email address.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Get.find<AuthService>();
    final (success, message) = await auth.forgotPassword(email: email);
    setState(() => _isLoading = false);

    if (success) {
      showAppToast(title: 'OTP Sent', message: message);
      Get.toNamed(AppRoutes.VERIFY_OTP, arguments: {'email': email});
      return;
    }

    showAppToast(title: 'Request Failed', message: message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 15.w),
            child: Column(
              children: [
                8.verticalSpace,
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20.r),
                    onTap: Get.back,
                    child: Padding(
                      padding: EdgeInsets.all(4.r),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.textPrimary,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),
                22.verticalSpace,
                Center(
                  child: Image.asset(
                    Assets.images.login.logo.path,
                    height: 100.h,
                    width: 100.w,
                    filterQuality: FilterQuality.high,
                    fit: BoxFit.cover,
                  ),
                ),
                18.verticalSpace,
                CustomText(
                  AppStrings.recoverPasswordTitle,
                  textAlign: TextAlign.center,
                  fontFamily: AppStrings.interExtraBold,
                  fontSize: 38.sp,
                  color: context.textPrimary,
                ),
                6.verticalSpace,
                CustomText(
                  AppStrings.recoverPasswordSubtitle,
                  textAlign: TextAlign.center,
                  fontFamily: AppStrings.interRegular,
                  fontSize: 16.sp,
                  color: context.textSecondary,
                ),
                42.verticalSpace,
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(36.h),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.accountEmail,
                        fontFamily: AppStrings.interMedium,
                        fontSize: 16.sp,
                        color: context.textSecondary,
                        maxLines: 1,
                      ),
                      10.verticalSpace,
                      TextField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        textAlignVertical: TextAlignVertical.center,
                        cursorColor: context.textPrimary,
                        style: TextStyle(
                          fontFamily: AppStrings.interRegular,
                          fontSize: 14.sp,
                          color: context.textPrimary,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.fromLTRB(10.w, 10.h, 0, 10.h),
                            child: Image.asset(
                              Assets.images.login.mail.path,
                              height: 20.h,
                              width: 20.w,
                              fit: BoxFit.contain,
                            ),
                          ),
                          prefixIconConstraints: BoxConstraints(
                            minHeight: 40.h,
                            minWidth: 40.w,
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 20.h,
                            horizontal: 15.w,
                          ),
                          filled: true,
                          fillColor: context.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            borderSide: BorderSide.none,
                          ),
                          hintText: AppStrings.emailHint,
                          hintStyle: TextStyle(
                            color: context.textSecondary,
                            fontFamily: AppStrings.interRegular,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      35.verticalSpace,
                      GestureDetector(
                        onTap: _isLoading ? null : _sendOtp,
                        child: Container(
                          height: 70.h,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CustomText(
                                      AppStrings.sendOtp,
                                      color: AppColors.white,
                                      fontFamily: AppStrings.interSemiBold,
                                      fontSize: 20.sp,
                                      maxLines: 1,
                                    ),
                                    20.horizontalSpace,
                                    Image.asset(
                                      Assets.images.login.enter.path,
                                      height: 20.h,
                                      width: 20.w,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                20.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
