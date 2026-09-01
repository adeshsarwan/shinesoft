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

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isObscure = true;
  bool _isConfirmObscure = true;
  bool _isLoading = false;
  late final String _email;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments;
    _email =
        args is Map<String, dynamic> ? (args['email'] as String? ?? '') : '';
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _passwordCtrl.text.trim();
    final confirmPassword = _confirmPasswordCtrl.text.trim();

    if (_email.isEmpty) {
      showAppToast(
        title: 'Missing Email',
        message: 'Please restart forgot password flow.',
        isError: true,
      );
      return;
    }

    if (password.length < 6) {
      showAppToast(
        title: 'Weak Password',
        message: 'Password should be at least 6 characters.',
        isError: true,
      );
      return;
    }

    if (password != confirmPassword) {
      showAppToast(
        title: 'Password Mismatch',
        message: 'Password and confirm password must match.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = Get.find<AuthService>();
    final (success, message) = await auth.resetPassword(
      email: _email,
      newPassword: password,
    );
    setState(() => _isLoading = false);

    if (success) {
      showAppToast(title: 'Password Reset', message: message);
      Get.offAllNamed(AppRoutes.LOGIN);
      return;
    }

    showAppToast(title: 'Reset Failed', message: message, isError: true);
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
                    fit: BoxFit.cover,
                  ),
                ),
                18.verticalSpace,
                CustomText(
                  AppStrings.createNewPassword,
                  textAlign: TextAlign.center,
                  fontFamily: AppStrings.interExtraBold,
                  fontSize: 36.sp,
                  color: context.textPrimary,
                ),
                6.verticalSpace,
                CustomText(
                  AppStrings.resetPasswordSubtitle,
                  textAlign: TextAlign.center,
                  fontFamily: AppStrings.interRegular,
                  fontSize: 16.sp,
                  color: context.textSecondary,
                ),
                38.verticalSpace,
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(15.r),
                    border: Border.all(color: context.borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        AppStrings.newPassword,
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
                            onTap: () =>
                                setState(() => _isObscure = !_isObscure),
                            child: Icon(
                              _isObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 24.sp,
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
                            color: context.textSecondary,
                            fontFamily: AppStrings.interRegular,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      30.verticalSpace,
                      CustomText(
                        AppStrings.confirmPassword,
                        fontFamily: AppStrings.interMedium,
                        fontSize: 16.sp,
                        color: context.textSecondary,
                        maxLines: 1,
                      ),
                      10.verticalSpace,
                      TextField(
                        controller: _confirmPasswordCtrl,
                        obscureText: _isConfirmObscure,
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
                            onTap: () => setState(
                              () => _isConfirmObscure = !_isConfirmObscure,
                            ),
                            child: Icon(
                              _isConfirmObscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 24.sp,
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
                            color: context.textSecondary,
                            fontFamily: AppStrings.interRegular,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                      35.verticalSpace,
                      GestureDetector(
                        onTap: _isLoading ? null : _resetPassword,
                        child: Container(
                          width: double.infinity,
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
                              : Center(
                                  child: CustomText(
                                    AppStrings.resetPassword,
                                    color: AppColors.white,
                                    fontFamily: AppStrings.interSemiBold,
                                    fontSize: 20.sp,
                                    maxLines: 1,
                                  ),
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
