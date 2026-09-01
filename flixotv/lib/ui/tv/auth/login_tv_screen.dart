import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/banner_ad_widget.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/ui/tv/auth/tv_auth_route_args.dart';
import 'package:iptv_demo/ui/tv/auth/tv_auth_widgets.dart';
import 'package:iptv_demo/utils/notification_platform.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';
import 'package:iptv_demo/utils/push_token_util.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class LoginTvScreen extends StatefulWidget {
  const LoginTvScreen({super.key});

  @override
  State<LoginTvScreen> createState() => _LoginTvScreenState();
}

class _LoginTvScreenState extends State<LoginTvScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final FocusNode _emailFocus;
  late final FocusNode _passwordFocus;
  bool _obscure = true;
  bool _loading = false;
  late final TvAuthRouteArgs _args;

  @override
  void initState() {
    super.initState();
    _args = TvAuthRouteArgs.from(Get.arguments);
    _emailFocus = FocusNode(debugLabel: 'tv_login_email');
    _passwordFocus = FocusNode(debugLabel: 'tv_login_password');
  }

  @override
  void dispose() {
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _openRoute(String route) {
    Get.toNamed<void>(route, arguments: _args.onSessionEstablished);
  }

  Future<void> _submit() async {
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
    setState(() => _loading = true);
    final auth = Get.find<AuthService>();
    final (ok, msg) = await auth.login(email: email, password: password);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      showAppToast(title: 'Login Failed', message: msg, isError: true);
      return;
    }
    if (auth.registeredPlatform.value == authPlatformTv) {
      await ensureTvPushReadyAfterLogin();
    }
    tvAuthHideKeyboard();
    final callback = _args.onSessionEstablished;
    if (callback != null) {
      Get.back<void>();
      callback();
    } else {
      final home = await resolveHomeRouteForPlatform();
      Get.offAllNamed<void>(home);
    }
  }

  TextStyle _fieldStyle(BuildContext context) {
    return TextStyle(
      fontFamily: AppStrings.interRegular,
      fontSize: 15.sp,
      color: context.textPrimary,
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
              const TvAuthLogo(),
              20.verticalSpace,
              CustomText(
                AppStrings.login,
                style: TextStyle(
                  fontFamily: AppStrings.interExtraBold,
                  fontSize: 34.sp,
                  color: context.textPrimary,
                ),
              ),
              8.verticalSpace,
              CustomText(
                AppStrings.loginSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppStrings.interRegular,
                  fontSize: 16.sp,
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
                      textInputAction: TextInputAction.next,
                      style: _fieldStyle(context),
                      decoration: tvAuthFieldDecoration(
                        context,
                        assetPath: Assets.images.login.mail.path,
                        hint: AppStrings.emailHint,
                      ),
                    ),
                    24.verticalSpace,
                    CustomText(
                      AppStrings.password,
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
                      fieldFocusOrder: const NumericFocusOrder(20),
                      visibilityFocusOrder: const NumericFocusOrder(21),
                      obscureText: _obscure,
                      onToggleVisibility: () =>
                          setState(() => _obscure = !_obscure),
                      textInputAction: TextInputAction.done,
                      style: _fieldStyle(context),
                      decoration: tvAuthFieldDecoration(
                        context,
                        assetPath: Assets.images.login.password.path,
                        iconSize: 24,
                        hint: AppStrings.passwordHint,
                      ),
                    ),
                    5.verticalSpace,
                    Align(
                      alignment: Alignment.centerRight,
                      child: TvAuthLinkButton(
                        focusOrder: const NumericFocusOrder(15),
                        label: AppStrings.forgotPassword,
                        onPressed: () => _openRoute(AppRoutes.FORGOT_PASSWORD_TV),
                      ),
                    ),
                    28.verticalSpace,
                    TvAuthGradientButton(
                      focusOrder: const NumericFocusOrder(30),
                      label: AppStrings.login,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
              28.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    AppStrings.newToPlatform,
                    style: TextStyle(
                      fontFamily: AppStrings.interMedium,
                      fontSize: 15.sp,
                      color: context.textPrimary,
                    ),
                  ),
                  8.horizontalSpace,
                  TvAuthGradientLink(
                    focusOrder: const NumericFocusOrder(40),
                    label: AppStrings.requestAccount,
                    onPressed: () => _openRoute(AppRoutes.SIGN_UP_TV),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
