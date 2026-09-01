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
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class SignUpTvScreen extends StatefulWidget {
  const SignUpTvScreen({super.key});

  @override
  State<SignUpTvScreen> createState() => _SignUpTvScreenState();
}

class _SignUpTvScreenState extends State<SignUpTvScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  late final FocusNode _nameFocus;
  late final FocusNode _emailFocus;
  late final FocusNode _passwordFocus;
  bool _obscure = true;
  bool _agreed = false;
  bool _loading = false;
  late final TvAuthRouteArgs _args;

  @override
  void initState() {
    super.initState();
    _args = TvAuthRouteArgs.from(Get.arguments);
    _nameFocus = FocusNode(debugLabel: 'tv_signup_name');
    _emailFocus = FocusNode(debugLabel: 'tv_signup_email');
    _passwordFocus = FocusNode(debugLabel: 'tv_signup_password');
  }

  @override
  void dispose() {
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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
    if (!_agreed) {
      showAppToast(
        title: 'Error',
        message: 'Please agree to terms and privacy policy',
        isError: true,
      );
      return;
    }
    setState(() => _loading = true);
    final auth = Get.find<AuthService>();
    final (ok, msg) = await auth.register(
      name: name,
      email: email,
      password: password,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      showAppToast(title: 'Registration Failed', message: msg, isError: true);
      return;
    }
    showAppToast(
      title: 'Account Created',
      message: 'Registration successful! Please login.',
    );
    Get.offNamed<void>(
      AppRoutes.LOGIN_TV,
      arguments: _args.onSessionEstablished,
    );
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
        primaryFieldFocus: _nameFocus,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TvAuthLogo(height: 88),
              16.verticalSpace,
              CustomText(
                AppStrings.signUp,
                style: TextStyle(
                  fontFamily: AppStrings.interExtraBold,
                  fontSize: 30.sp,
                  color: context.textPrimary,
                ),
              ),
              8.verticalSpace,
              CustomText(
                AppStrings.signUpSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppStrings.interRegular,
                  fontSize: 15.sp,
                  color: context.textSecondary,
                ),
              ),
              28.verticalSpace,
              TvAuthFormCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.createAccount,
                      style: TextStyle(
                        fontFamily: AppStrings.interBold,
                        fontSize: 18.sp,
                        color: context.textPrimary,
                      ),
                    ),
                    4.verticalSpace,
                    CustomText(
                      AppStrings.createAccountSubtitle,
                      style: TextStyle(
                        fontFamily: AppStrings.interMedium,
                        fontSize: 14.sp,
                        color: context.textSecondary,
                      ),
                    ),
                    24.verticalSpace,
                    _fieldLabel(AppStrings.fullName),
                    8.verticalSpace,
                    TvAuthTextField(
                      focusNode: _nameFocus,
                      controller: _nameCtrl,
                      focusOrder: const NumericFocusOrder(10),
                      textInputAction: TextInputAction.next,
                      style: _fieldStyle(context),
                      decoration: tvAuthFieldDecoration(
                        context,
                        assetPath: Assets.images.login.person.path,
                        hint: AppStrings.fullNameHint,
                      ),
                    ),
                    18.verticalSpace,
                    _fieldLabel(AppStrings.emailAddress),
                    8.verticalSpace,
                    TvAuthTextField(
                      focusNode: _emailFocus,
                      controller: _emailCtrl,
                      focusOrder: const NumericFocusOrder(15),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: _fieldStyle(context),
                      decoration: tvAuthFieldDecoration(
                        context,
                        assetPath: Assets.images.login.mail.path,
                        hint: AppStrings.emailHint,
                      ),
                    ),
                    18.verticalSpace,
                    _fieldLabel(AppStrings.password),
                    8.verticalSpace,
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
                    20.verticalSpace,
                    TvAuthTermsCheckbox(
                      agreed: _agreed,
                      onToggle: () => setState(() => _agreed = !_agreed),
                    ),
                    24.verticalSpace,
                    TvAuthGradientButton(
                      focusOrder: const NumericFocusOrder(30),
                      label: AppStrings.signUp,
                      loading: _loading,
                      onPressed: _register,
                    ),
                  ],
                ),
              ),
              24.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    AppStrings.alreadyMember,
                    style: TextStyle(
                      fontFamily: AppStrings.interMedium,
                      fontSize: 15.sp,
                      color: context.textPrimary,
                    ),
                  ),
                  6.horizontalSpace,
                  TvAuthGradientLink(
                    focusOrder: const NumericFocusOrder(40),
                    label: AppStrings.returnToLogin,
                    onPressed: () {
                      Get.offNamed<void>(
                        AppRoutes.LOGIN_TV,
                        arguments: _args.onSessionEstablished,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return CustomText(
      text,
      style: TextStyle(
        fontFamily: AppStrings.interBold,
        fontSize: 14.sp,
        color: context.textSecondary,
      ),
    );
  }
}
