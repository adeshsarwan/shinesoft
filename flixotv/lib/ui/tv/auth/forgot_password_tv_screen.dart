import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/ui/tv/auth/tv_auth_route_args.dart';
import 'package:iptv_demo/ui/tv/auth/tv_auth_widgets.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class ForgotPasswordTvScreen extends StatefulWidget {
  const ForgotPasswordTvScreen({super.key});

  @override
  State<ForgotPasswordTvScreen> createState() => _ForgotPasswordTvScreenState();
}

class _ForgotPasswordTvScreenState extends State<ForgotPasswordTvScreen> {
  final _emailCtrl = TextEditingController();
  late final FocusNode _emailFocus;
  bool _loading = false;
  late final TvAuthRouteArgs _args;

  @override
  void initState() {
    super.initState();
    _args = TvAuthRouteArgs.from(Get.arguments);
    _emailFocus = FocusNode(debugLabel: 'tv_forgot_email');
  }

  @override
  void dispose() {
    _emailFocus.dispose();
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
    setState(() => _loading = true);
    final auth = Get.find<AuthService>();
    final (ok, msg) = await auth.forgotPassword(email: email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      showAppToast(title: 'Request Failed', message: msg, isError: true);
      return;
    }
    showAppToast(title: 'OTP Sent', message: msg);
    await Get.toNamed<void>(
      AppRoutes.VERIFY_OTP_TV,
      arguments: _args.withEmail(email),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: TvAuthScaffold(
        primaryFieldFocus: _emailFocus,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TvAuthLogo(height: 88),
              16.verticalSpace,
              CustomText(
                AppStrings.recoverPasswordTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppStrings.interExtraBold,
                  fontSize: 28.sp,
                  color: context.textPrimary,
                ),
              ),
              10.verticalSpace,
              CustomText(
                AppStrings.recoverPasswordSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppStrings.interRegular,
                  fontSize: 15.sp,
                  color: context.textSecondary,
                ),
              ),
              32.verticalSpace,
              TvAuthFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.accountEmail,
                      style: TextStyle(
                        fontFamily: AppStrings.interMedium,
                        fontSize: 15.sp,
                        color: context.textSecondary,
                      ),
                    ),
                    10.verticalSpace,
                    TvAuthTextField(
                      focusNode: _emailFocus,
                      controller: _emailCtrl,
                      focusOrder: const NumericFocusOrder(10),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      style: TextStyle(
                        color: context.textPrimary,
                        fontFamily: AppStrings.interRegular,
                        fontSize: 15.sp,
                      ),
                      decoration: tvAuthFieldDecoration(
                        context,
                        assetPath: Assets.images.login.mail.path,
                        hint: AppStrings.emailHint,
                      ),
                    ),
                    24.verticalSpace,
                    TvAuthGradientButton(
                      focusOrder: const NumericFocusOrder(20),
                      label: AppStrings.sendOtp,
                      loading: _loading,
                      onPressed: _sendOtp,
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
