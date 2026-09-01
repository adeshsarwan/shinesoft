import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/banner_ad_widget.dart';
import 'package:iptv_demo/ads/native_ad_widget.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _isObscure = true;
  bool _agreedToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      showAppToast(
        title: 'Error',
        message: 'Please fill all fields',
        isError: true,
      );
      return;
    }

    if (!_agreedToTerms) {
      showAppToast(
        title: 'Error',
        message: 'Please agree to terms and privacy policy',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    final auth = Get.find<AuthService>();
    final (success, message) = await auth.register(
      name: name,
      email: email,
      password: password,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;
      await Get.offAllNamed(AppRoutes.LOGIN);
      showAppToast(
        title: 'Account Created',
        message: message.isNotEmpty
            ? message
            : 'Registration successful! Please login.',
      );
    } else {
      showAppToast(
        title: 'Registration Failed',
        message: message,
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: true,
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
                AppStrings.signUp,
                fontFamily: AppStrings.interExtraBold,
                fontSize: 30.sp,
                color: context.textPrimary,
                maxLines: 1,
              ),
              CustomText(
                AppStrings.signUpSubtitle,
                fontFamily: AppStrings.interRegular,
                fontSize: 14.sp,
                color: context.textSecondary,
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
                    CustomText(
                      AppStrings.createAccount,
                      fontFamily: AppStrings.interBold,
                      fontSize: 20.sp,
                      color: context.textPrimary,
                      maxLines: 1,
                    ),
                    5.verticalSpace,
                    CustomText(
                      AppStrings.createAccountSubtitle,
                      fontFamily: AppStrings.interMedium,
                      fontSize: 15.sp,
                      color: context.textSecondary,
                    ),
                    30.verticalSpace,
        
                    // Name
                    CustomText(
                      AppStrings.fullName,
                      fontFamily: AppStrings.interBold,
                      fontSize: 14.sp,
                      color: context.textSecondary,
                      maxLines: 1,
                    ),
                    10.verticalSpace,
                    TextField(
                      controller: _nameCtrl,
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
                            Assets.images.login.person.path,
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
                        hintText: AppStrings.fullNameHint,
                        hintStyle: TextStyle(
                          fontFamily: AppStrings.interRegular,
                          fontSize: 16.sp,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                    30.verticalSpace,
        
                    // Email
                    CustomText(
                      AppStrings.emailAddress,
                      fontFamily: AppStrings.interBold,
                      fontSize: 14.sp,
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
                            Assets.images.login.email.path,
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
                      AppStrings.securePassword,
                      fontFamily: AppStrings.interBold,
                      fontSize: 14.sp,
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
                            color: context.textPrimary,
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
                    30.verticalSpace,
        
                    // Terms checkbox
                    Row(
                      children: [
                        InkWell(
                          onTap: () =>
                              setState(() => _agreedToTerms = !_agreedToTerms),
                          child: _agreedToTerms
                              ? Container(
                                  height: 20.h,
                                  width: 20.w,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    size: 15.h,
                                    color: AppColors.white,
                                  ),
                                )
                              : Container(
                                  height: 20.h,
                                  width: 20.w,
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: context.borderColor),
                                    borderRadius: BorderRadius.circular(6.r),
                                  ),
                                ),
                        ),
                        5.horizontalSpace,
                        Flexible(
                          child: RichText(
                            overflow: TextOverflow.fade,
                            text: TextSpan(
                              style: TextStyle(fontSize: 14.sp),
                              children: [
                                TextSpan(
                                  text: AppStrings.agreeTo,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontFamily: AppStrings.interMedium,
                                  ),
                                ),
                                TextSpan(
                                  text: AppStrings.termsOfFlight,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontFamily: AppStrings.interSemiBold,
                                  ),
                                ),
                                TextSpan(
                                  text: AppStrings.andText,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontFamily: AppStrings.interMedium,
                                  ),
                                ),
                                TextSpan(
                                  text: AppStrings.privacyProtocols,
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontFamily: AppStrings.interSemiBold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    30.verticalSpace,
        
                    // Sign up button
                    GestureDetector(
                      onTap: _isLoading ? null : _register,
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
                                    AppStrings.signUp,
                                    color: AppColors.white,
                                    fontFamily: AppStrings.interSemiBold,
                                    fontSize: 20.sp,
                                    maxLines: 1,
                                  ),
                                  25.horizontalSpace,
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 20.h,
                                    color: AppColors.white,
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
              // 8.verticalSpace,
              // Padding(
              //   padding: EdgeInsets.symmetric(horizontal: 15.w),
              //   child: const BannerAdWidget(authScreen: true),
              // ),
              12.verticalSpace,
              35.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    AppStrings.alreadyMember,
                    color: context.textPrimary,
                    fontFamily: AppStrings.interMedium,
                    fontSize: 15.sp,
                    maxLines: 1,
                  ),
                  5.horizontalSpace,
                  InkWell(
                    onTap: () => Get.back(),
                    child: GradientText(
                      AppStrings.returnToLogin,
                      colors: AppColors.primaryGradient,
                      style: TextStyle(
                        fontFamily: AppStrings.interBold,
                        fontSize: 15.sp,
                      ),
                    ),
                  ),
                ],
              ),
              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
