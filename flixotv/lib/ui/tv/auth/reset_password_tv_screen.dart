import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/ui/tv/auth/tv_auth_route_args.dart';
import 'package:iptv_demo/ui/tv/auth/tv_auth_widgets.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class ResetPasswordTvScreen extends StatefulWidget {
  const ResetPasswordTvScreen({super.key});

  @override
  State<ResetPasswordTvScreen> createState() => _ResetPasswordTvScreenState();
}

class _ResetPasswordTvScreenState extends State<ResetPasswordTvScreen> {
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  late final FocusNode _passwordFocus;
  late final FocusNode _confirmFocus;
  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  late final TvAuthRouteArgs _args;

  @override
  void initState() {
    super.initState();
    _args = TvAuthRouteArgs.from(Get.arguments);
    _passwordFocus = FocusNode(debugLabel: 'tv_reset_password');
    _confirmFocus = FocusNode(debugLabel: 'tv_reset_confirm');
  }

  @override
  void dispose() {
    _passwordFocus.dispose();
    _confirmFocus.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _email => _args.email ?? '';

  Future<void> _reset() async {
    final pass = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();
    if (pass.length < 6) {
      showAppToast(
        title: 'Weak Password',
        message: 'Password should be at least 6 characters.',
        isError: true,
      );
      return;
    }
    if (pass != confirm) {
      showAppToast(
        title: 'Password Mismatch',
        message: 'Password and confirm password must match.',
        isError: true,
      );
      return;
    }
    if (_email.isEmpty) {
      showAppToast(
        title: 'Missing Email',
        message: 'Please restart forgot password flow.',
        isError: true,
      );
      return;
    }
    setState(() => _loading = true);
    final auth = Get.find<AuthService>();
    final (ok, msg) =
        await auth.resetPassword(email: _email, newPassword: pass);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      showAppToast(title: 'Reset Failed', message: msg, isError: true);
      return;
    }
    showAppToast(title: 'Password Reset', message: msg);
    Get.offAllNamed<void>(
      AppRoutes.LOGIN_TV,
      arguments: _args.onSessionEstablished,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: TvAuthScaffold(
        showBackButton: false,
        primaryFieldFocus: _passwordFocus,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TvAuthLogo(height: 88),
              16.verticalSpace,
              CustomText(
                AppStrings.createNewPassword,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppStrings.interExtraBold,
                  fontSize: 28.sp,
                  color: context.textPrimary,
                ),
              ),
              32.verticalSpace,
              TvAuthFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.newPassword,
                      style: TextStyle(
                        fontFamily: AppStrings.interMedium,
                        fontSize: 15.sp,
                        color: context.textSecondary,
                      ),
                    ),
                    10.verticalSpace,
                    TvAuthPasswordField(
                      focusNode: _passwordFocus,
                      controller: _passwordCtrl,
                      fieldFocusOrder: const NumericFocusOrder(10),
                      visibilityFocusOrder: const NumericFocusOrder(11),
                      obscureText: _obscure1,
                      onToggleVisibility: () =>
                          setState(() => _obscure1 = !_obscure1),
                      textInputAction: TextInputAction.next,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15.sp,
                        fontFamily: AppStrings.interRegular,
                      ),
                      decoration: _passwordDeco(context),
                    ),
                    20.verticalSpace,
                    CustomText(
                      AppStrings.confirmPassword,
                      style: TextStyle(
                        fontFamily: AppStrings.interMedium,
                        fontSize: 15.sp,
                        color: context.textSecondary,
                      ),
                    ),
                    10.verticalSpace,
                    TvAuthPasswordField(
                      focusNode: _confirmFocus,
                      controller: _confirmCtrl,
                      fieldFocusOrder: const NumericFocusOrder(15),
                      visibilityFocusOrder: const NumericFocusOrder(16),
                      obscureText: _obscure2,
                      onToggleVisibility: () =>
                          setState(() => _obscure2 = !_obscure2),
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 15.sp,
                        fontFamily: AppStrings.interRegular,
                      ),
                      decoration: _passwordDeco(context),
                    ),
                    28.verticalSpace,
                    TvAuthGradientButton(
                      focusOrder: const NumericFocusOrder(20),
                      label: AppStrings.resetPassword,
                      loading: _loading,
                      onPressed: _reset,
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

  InputDecoration _passwordDeco(BuildContext context) {
    return InputDecoration(
      hintText: AppStrings.passwordHint,
      contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
      filled: true,
      fillColor: context.inputFill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide.none,
      ),
    );
  }
}
