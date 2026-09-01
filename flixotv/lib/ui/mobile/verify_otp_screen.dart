import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:pinput/pinput.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpCtrl = TextEditingController();
  bool _isLoading = false;
  late final String _email;
  final ValueNotifier<int> _secondsLeft = ValueNotifier<int>(30);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _email =
        args is Map<String, dynamic> ? (args['email'] as String? ?? '') : '';
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _secondsLeft.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _secondsLeft.value = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft.value <= 0) {
        timer.cancel();
        return;
      }
      _secondsLeft.value -= 1;
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrl.text.trim();
    if (_email.isEmpty) {
      showAppToast(
        title: 'Missing Email',
        message: 'Please restart forgot password flow.',
        isError: true,
      );
      return;
    }

    if (otp.length < 4) {
      showAppToast(
        title: 'Invalid OTP',
        message: 'Please enter a valid OTP.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Get.find<AuthService>();
    final (success, message) = await auth.verifyOtp(email: _email, otp: otp);
    setState(() => _isLoading = false);

    if (success) {
      showAppToast(title: 'OTP Verified', message: message);
      Get.toNamed(AppRoutes.RESET_PASSWORD, arguments: {'email': _email});
      return;
    }

    showAppToast(title: 'Verification Failed', message: message, isError: true);
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft.value > 0) return;
    if (_email.isEmpty) return;
    final auth = Get.find<AuthService>();
    final (success, message) = await auth.forgotPassword(email: _email);
    showAppToast(
      title: success ? 'OTP Sent' : 'Request Failed',
      message: message,
      isError: !success,
    );
    if (success) _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.scaffoldBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: CustomText(
          AppStrings.verifyOtp,
          color: context.textPrimary,
          fontFamily: AppStrings.interSemiBold,
          fontSize: 18.sp,
          maxLines: 1,
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15.w),
          child: Column(
            children: [
              50.verticalSpace,
              CustomText(
                AppStrings.verifyOtpTitle,
                textAlign: TextAlign.center,
                fontFamily: AppStrings.interExtraBold,
                fontSize: 28.sp,
                color: context.textPrimary,
                maxLines: 2,
              ),
              10.verticalSpace,
              CustomText(
                '${AppStrings.verifyOtpSubtitle}\n$_email',
                textAlign: TextAlign.center,
                fontFamily: AppStrings.interRegular,
                fontSize: 14.sp,
                color: context.textSecondary,
                maxLines: 3,
              ),
              30.verticalSpace,
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(30.h),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.otpCode,
                      fontFamily: AppStrings.interBold,
                      fontSize: 14.sp,
                      color: context.textSecondary,
                      maxLines: 1,
                    ),
                    10.verticalSpace,
                    Center(
                      child: Pinput(
                        controller: _otpCtrl,
                        length: 6,
                        keyboardType: TextInputType.number,
                        defaultPinTheme: PinTheme(
                          width: 48.w,
                          height: 56.h,
                          textStyle: TextStyle(
                            fontSize: 20.sp,
                            color: context.textPrimary,
                            fontFamily: AppStrings.interSemiBold,
                          ),
                          decoration: BoxDecoration(
                            color: context.inputFill,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: context.borderColor),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 48.w,
                          height: 56.h,
                          textStyle: TextStyle(
                            fontSize: 20.sp,
                            color: context.textPrimary,
                            fontFamily: AppStrings.interSemiBold,
                          ),
                          decoration: BoxDecoration(
                            color: context.inputFill,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(color: AppColors.primary),
                          ),
                        ),
                        separatorBuilder: (_) => 8.horizontalSpace,
                      ),
                    ),
                    25.verticalSpace,
                    GestureDetector(
                      onTap: _isLoading ? null : _verifyOtp,
                      child: Container(
                        height: 62.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: AppColors.white)
                              : CustomText(
                                  AppStrings.verifyOtp,
                                  color: AppColors.white,
                                  fontFamily: AppStrings.interSemiBold,
                                  fontSize: 18.sp,
                                  maxLines: 1,
                                ),
                        ),
                      ),
                    ),
                    15.verticalSpace,
                    Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: _secondsLeft,
                        builder: (_, value, __) {
                          if (value > 0) {
                            return CustomText(
                              'Resend OTP in 00:${value.toString().padLeft(2, '0')}',
                              color: context.textSecondary,
                              fontFamily: AppStrings.interMedium,
                              fontSize: 13.sp,
                              maxLines: 1,
                            );
                          }
                          return TextButton(
                            onPressed: _resendOtp,
                            child: CustomText(
                              AppStrings.resendOtp,
                              color: AppColors.primary,
                              fontFamily: AppStrings.interSemiBold,
                              fontSize: 14.sp,
                              maxLines: 1,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
