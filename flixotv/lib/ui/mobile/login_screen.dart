import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/app_open_ad_manager.dart';
import 'package:iptv_demo/ads/banner_ad_widget.dart';
import 'package:iptv_demo/ads/native_ad_widget.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';
import 'package:iptv_demo/ui/mobile/sign_up_screen.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:pinput/pinput.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppOpenAdManager.instance.showOnLoginIfColdStart(
        delay: const Duration(milliseconds: 600),
      );
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (email.isEmpty || password.isEmpty) {
      showAppToast(
        title: 'Error',
        message: 'Please enter email and password',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Get.find<AuthService>();
    final (success, message) = await auth.login(
      email: email,
      password: password,
    );

    setState(() => _isLoading = false);

    if (success) {
      final home = await resolveHomeRouteForPlatform();
      Get.offAllNamed(home);
    } else {
      showAppToast(
        title: 'Login Failed',
        message: message,
        isError: true,
      );
    }
  }

  Future<void> _openForgotPasswordBottomSheet() async {
    final emailCtrl = TextEditingController();
    bool isLoading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 15.w,
                right: 15.w,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Container(
                padding: EdgeInsets.all(24.h),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CustomText(
                        'Forgot Password',
                        textAlign: TextAlign.center,
                        fontFamily: AppStrings.interExtraBold,
                        fontSize: 26.sp,
                        color: context.textPrimary,
                        maxLines: 1,
                      ),
                    ),
                    8.verticalSpace,
                    Center(
                      child: CustomText(
                        'Enter your email to receive OTP.',
                        textAlign: TextAlign.center,
                        fontFamily: AppStrings.interRegular,
                        fontSize: 14.sp,
                        color: context.textSecondary,
                        maxLines: 1,
                      ),
                    ),
                    24.verticalSpace,
                    CustomText(
                      AppStrings.accountEmail,
                      fontFamily: AppStrings.interMedium,
                      fontSize: 14.sp,
                      color: context.textSecondary,
                      maxLines: 1,
                    ),
                    10.verticalSpace,
                    TextField(
                      controller: emailCtrl,
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
                          fontFamily: AppStrings.interRegular,
                          fontSize: 14.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    24.verticalSpace,
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () async {
                              final email = emailCtrl.text.trim();
                              if (email.isEmpty || !GetUtils.isEmail(email)) {
                                showAppToast(
                                  title: 'Invalid Email',
                                  message: 'Please enter a valid email address',
                                  isError: true,
                                );
                                return;
                              }

                              setSheetState(() => isLoading = true);
                              final auth = Get.find<AuthService>();
                              final (success, message) =
                                  await auth.forgotPassword(email: email);
                              setSheetState(() => isLoading = false);

                              if (!success) {
                                showAppToast(
                                  title: 'Request Failed',
                                  message: message,
                                  isError: true,
                                );
                                return;
                              }

                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              showAppToast(
                                title: 'OTP Sent',
                                message: message,
                              );
                              if (!mounted) return;
                              Future.delayed(const Duration(milliseconds: 250),
                                  () {
                                if (!mounted) return;
                                _openVerifyOtpBottomSheet(email);
                              });
                            },
                      child: Container(
                        height: 64.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: AppColors.white)
                              : CustomText(
                                  AppStrings.sendOtp,
                                  color: AppColors.white,
                                  fontFamily: AppStrings.interSemiBold,
                                  fontSize: 18.sp,
                                  maxLines: 1,
                                ),
                        ),
                      ),
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

  Future<void> _openVerifyOtpBottomSheet(String email) async {
    final otpCtrl = TextEditingController();
    bool isLoading = false;
    final secondsLeft = ValueNotifier<int>(30);
    Timer? timer;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (sheetContext) {
        timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
          if (!sheetContext.mounted || secondsLeft.value <= 0) {
            t.cancel();
            return;
          }
          secondsLeft.value -= 1;
        });

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final pinTheme = PinTheme(
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
            );

            return Padding(
              padding: EdgeInsets.only(
                left: 15.w,
                right: 15.w,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
              ),
              child: Container(
                padding: EdgeInsets.all(24.h),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: CustomText(
                        AppStrings.verifyOtp,
                        textAlign: TextAlign.center,
                        fontFamily: AppStrings.interExtraBold,
                        fontSize: 26.sp,
                        color: context.textPrimary,
                        maxLines: 1,
                      ),
                    ),
                    8.verticalSpace,
                    Center(
                      child: CustomText(
                        'Enter the OTP sent to $email',
                        textAlign: TextAlign.center,
                        fontFamily: AppStrings.interRegular,
                        fontSize: 14.sp,
                        color: context.textSecondary,
                        maxLines: 1,
                      ),
                    ),
                    24.verticalSpace,
                    CustomText(
                      AppStrings.otpCode,
                      fontFamily: AppStrings.interMedium,
                      fontSize: 14.sp,
                      color: context.textSecondary,
                      maxLines: 1,
                    ),
                    10.verticalSpace,
                    Center(
                      child: Pinput(
                        controller: otpCtrl,
                        length: 6,
                        keyboardType: TextInputType.number,
                        defaultPinTheme: pinTheme,
                        focusedPinTheme: pinTheme.copyDecorationWith(
                          border: Border.all(color: AppColors.primary),
                        ),
                        submittedPinTheme: pinTheme.copyDecorationWith(
                          border: Border.all(color: AppColors.primary),
                        ),
                        separatorBuilder: (_) => 8.horizontalSpace,
                      ),
                    ),
                    24.verticalSpace,
                    GestureDetector(
                      onTap: isLoading
                          ? null
                          : () async {
                              final otp = otpCtrl.text.trim();
                              if (otp.length < 4) {
                                showAppToast(
                                  title: 'Invalid OTP',
                                  message: 'Please enter a valid OTP',
                                  isError: true,
                                );
                                return;
                              }

                              setSheetState(() => isLoading = true);
                              final auth = Get.find<AuthService>();
                              final (success, message) =
                                  await auth.verifyOtp(email: email, otp: otp);
                              setSheetState(() => isLoading = false);

                              if (!success) {
                                showAppToast(
                                  title: 'Verification Failed',
                                  message: message,
                                  isError: true,
                                );
                                return;
                              }

                              if (!sheetContext.mounted) return;
                              Navigator.of(sheetContext).pop();
                              Get.toNamed(
                                AppRoutes.RESET_PASSWORD,
                                arguments: {'email': email},
                              );
                            },
                      child: Container(
                        height: 64.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: AppColors.primaryGradient,
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: isLoading
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
                    12.verticalSpace,
                    Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: secondsLeft,
                        builder: (_, value, __) {
                          if (value > 0) {
                            return CustomText(
                              'Resend OTP in 00:${value.toString().padLeft(2, '0')}',
                              fontFamily: AppStrings.interMedium,
                              fontSize: 13.sp,
                              color: context.textSecondary,
                              maxLines: 1,
                            );
                          }
                          return TextButton(
                            onPressed: () async {
                              setSheetState(() => isLoading = true);
                              final auth = Get.find<AuthService>();
                              final (success, message) =
                                  await auth.forgotPassword(email: email);
                              setSheetState(() => isLoading = false);

                              showAppToast(
                                title: success ? 'OTP Sent' : 'Request Failed',
                                message: message,
                                isError: !success,
                              );
                              if (!success) return;
                              secondsLeft.value = 30;
                              timer?.cancel();
                              timer = Timer.periodic(
                                const Duration(seconds: 1),
                                (t) {
                                  if (!sheetContext.mounted ||
                                      secondsLeft.value <= 0) {
                                    t.cancel();
                                    return;
                                  }
                                  secondsLeft.value -= 1;
                                },
                              );
                            },
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
            );
          },
        );
      },
    );

    timer?.cancel();
    secondsLeft.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            children: [
              100.verticalSpace,
              Center(
                child: Image.asset(
                  Assets.images.login.logo.path,
                  height: 100.h,
                  width: 100.w,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.cover,
                ),
              ),
              20.verticalSpace,
              CustomText(
                AppStrings.login,
                fontFamily: AppStrings.interExtraBold,
                fontSize: 40.sp,
                color: context.textPrimary,
                maxLines: 1,
              ),
              CustomText(
                AppStrings.loginSubtitle,
                fontFamily: AppStrings.interRegular,
                fontSize: 18.sp,
                color: context.textSecondary,
                maxLines: 1,
              ),
              50.verticalSpace,
              Container(
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 15.w),
                padding: EdgeInsets.all(40.h),
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(15.r),
                  border: Border.all(color: context.borderColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Email
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
                          fontFamily: AppStrings.interRegular,
                          fontSize: 16.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    30.verticalSpace,
        
                    // Password
                    CustomText(
                      AppStrings.password,
                      fontFamily: AppStrings.interMedium,
                      fontSize: 16.sp,
                      color: context.textSecondary,
                      maxLines: 1,
                    ),
                    10.verticalSpace,
                    TextField(
                      controller: _passwordCtrl,
                      obscureText: _isObscure,
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
                            Assets.images.login.password.path,
                            height: 25.h,
                            width: 25.w,
                            fit: BoxFit.contain,
                          ),
                        ),
                        suffixIcon: GestureDetector(
                          onTap: () => setState(() => _isObscure = !_isObscure),
                          child: Icon(
                            _isObscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 25.sp,
                            color: context.appIconColor,
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
                        hintText: AppStrings.passwordHint,
                        hintStyle: TextStyle(
                          fontFamily: AppStrings.interRegular,
                          fontSize: 16.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    5.verticalSpace,
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        onTap: _openForgotPasswordBottomSheet,
                        child: CustomText(
                          AppStrings.forgotPassword,
                          fontFamily: AppStrings.interBold,
                          fontSize: 14.sp,
                          color: AppColors.primary,
                          maxLines: 1,
                        ),
                      ),
                    ),
                    35.verticalSpace,
        
                    // Login button
                    GestureDetector(
                      onTap: _isLoading ? null : _login,
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
                                    color: AppColors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CustomText(
                                    AppStrings.login,
                                    color: AppColors.white,
                                    fontFamily: AppStrings.interSemiBold,
                                    fontSize: 20.sp,
                                    maxLines: 1,
                                  ),
                                  25.horizontalSpace,
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: const NativeAdWidget(authScreen: true),
              ),
              2.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    AppStrings.newToPlatform,
                    color: context.textPrimary,
                    fontFamily: AppStrings.interMedium,
                    fontSize: 15.sp,
                    maxLines: 1,
                  ),
                  5.horizontalSpace,
                  InkWell(
                    onTap: () => Get.to(() => const SignUpScreen()),
                    child: GradientText(
                      AppStrings.requestAccount,
                      colors: AppColors.primaryGradient,
                      style: TextStyle(
                        fontFamily: AppStrings.interBold,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ],
              ),
              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
