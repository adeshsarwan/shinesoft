import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class VerifyOtpTvScreen extends StatefulWidget {
  const VerifyOtpTvScreen({super.key});

  @override
  State<VerifyOtpTvScreen> createState() => _VerifyOtpTvScreenState();
}

class _VerifyOtpTvScreenState extends State<VerifyOtpTvScreen> {
  final _otpCtrl = TextEditingController();
  late final FocusNode _otpFocus;
  bool _loading = false;
  late final TvAuthRouteArgs _args;
  final ValueNotifier<int> _secondsLeft = ValueNotifier<int>(30);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _args = TvAuthRouteArgs.from(Get.arguments);
    _otpFocus = FocusNode(debugLabel: 'tv_verify_otp');
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _secondsLeft.dispose();
    _otpFocus.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _secondsLeft.value = 30;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft.value <= 0) {
        timer.cancel();
      } else {
        _secondsLeft.value -= 1;
      }
    });
  }

  String get _email => _args.email ?? '';

  Future<void> _verify() async {
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
    setState(() => _loading = true);
    final auth = Get.find<AuthService>();
    final (ok, msg) = await auth.verifyOtp(email: _email, otp: otp);
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) {
      showAppToast(title: 'Verification Failed', message: msg, isError: true);
      return;
    }
    showAppToast(title: 'OTP Verified', message: msg);
    Get.toNamed<void>(
      AppRoutes.RESET_PASSWORD_TV,
      arguments: _args.withEmail(_email),
    );
  }

  Future<void> _resendOtp() async {
    if (_secondsLeft.value > 0 || _email.isEmpty) return;
    final auth = Get.find<AuthService>();
    final (ok, msg) = await auth.forgotPassword(email: _email);
    showAppToast(
      title: ok ? 'OTP Sent' : 'Request Failed',
      message: msg,
      isError: !ok,
    );
    if (ok) _startResendTimer();
  }

  TextStyle _fieldStyle(BuildContext context) {
    return TextStyle(
      fontFamily: AppStrings.interSemiBold,
      fontSize: 22.sp,
      color: context.textPrimary,
      letterSpacing: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: TvAuthScaffold(
        primaryFieldFocus: _otpFocus,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 720.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const TvAuthLogo(height: 88),
              16.verticalSpace,
              CustomText(
                AppStrings.verifyOtpTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppStrings.interExtraBold,
                  fontSize: 28.sp,
                  color: context.textPrimary,
                ),
              ),
              10.verticalSpace,
              CustomText(
                '${AppStrings.verifyOtpSubtitle}\n$_email',
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
                      AppStrings.otpCode,
                      style: TextStyle(
                        fontFamily: AppStrings.interMedium,
                        fontSize: 15.sp,
                        color: context.textSecondary,
                      ),
                    ),
                    10.verticalSpace,
                    TvAuthTextField(
                      focusNode: _otpFocus,
                      controller: _otpCtrl,
                      focusOrder: const NumericFocusOrder(10),
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      style: _fieldStyle(context),
                      decoration: tvAuthFieldDecoration(
                        context,
                        assetPath: Assets.images.login.mail.path,
                        hint: AppStrings.otpHint,
                      ),
                    ),
                    24.verticalSpace,
                    TvAuthGradientButton(
                      focusOrder: const NumericFocusOrder(20),
                      label: AppStrings.verifyOtp,
                      loading: _loading,
                      onPressed: _verify,
                    ),
                    16.verticalSpace,
                    Center(
                      child: ValueListenableBuilder<int>(
                        valueListenable: _secondsLeft,
                        builder: (_, value, __) {
                          final canResend = value <= 0;
                          return TvAuthLinkButton(
                            focusOrder: const NumericFocusOrder(30),
                            label: canResend
                                ? AppStrings.resendOtp
                                : 'Resend OTP in 00:${value.toString().padLeft(2, '0')}',
                            onPressed: canResend ? _resendOtp : () {},
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
