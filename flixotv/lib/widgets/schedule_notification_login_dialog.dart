import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/ui/tv/auth/tv_auth_flow.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

/// Asks the user to sign in before scheduling a program notification.
///
/// Returns `true` if the user chose Login and a login flow was opened.
Future<bool> promptLoginForScheduleNotification(
  BuildContext context, {
  required bool isTvHost,
  VoidCallback? onSessionEstablished,
}) async {
  // Avoid pushing a route while navigator is in the middle of a transition/build.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return false;

  final shouldLogin = await showDialog<bool>(
    context: context,
    barrierDismissible: !isTvHost,
    barrierColor: AppColors.black.withValues(alpha: isTvHost ? 0.72 : 0.45),
    builder: (dialogContext) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: isTvHost ? 48.w : 24.w),
        backgroundColor: AppColors.transparent,
        elevation: 0,
        child: _ScheduleLoginDialogContent(
          isTvHost: isTvHost,
          onCancel: () => Navigator.of(dialogContext).pop(false),
          onLogin: () => Navigator.of(dialogContext).pop(true),
        ),
      );
    },
  );

  if (shouldLogin != true || !context.mounted) return false;

  if (isTvHost) {
    await openTvLoginScreen(
      onSessionEstablished: onSessionEstablished ?? () {},
    );
  } else {
    await Get.toNamed(AppRoutes.LOGIN);
    onSessionEstablished?.call();
  }
  return true;
}

class _ScheduleLoginDialogContent extends StatefulWidget {
  const _ScheduleLoginDialogContent({
    required this.isTvHost,
    required this.onCancel,
    required this.onLogin,
  });

  final bool isTvHost;
  final VoidCallback onCancel;
  final VoidCallback onLogin;

  @override
  State<_ScheduleLoginDialogContent> createState() =>
      _ScheduleLoginDialogContentState();
}

class _ScheduleLoginDialogContentState
    extends State<_ScheduleLoginDialogContent> {
  final _cancelFocus = FocusNode(debugLabel: 'schedule_login_cancel');
  final _loginFocus = FocusNode(debugLabel: 'schedule_login_action');

  @override
  void initState() {
    super.initState();
    if (widget.isTvHost) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loginFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _cancelFocus.dispose();
    _loginFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final body = Container(
      constraints: BoxConstraints(maxWidth: widget.isTvHost ? 520.w : 400.w),
      padding: EdgeInsets.fromLTRB(22.w, 24.h, 22.w, 20.h),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(widget.isTvHost ? 24.r : 20.r),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowColor,
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomText(
            AppStrings.scheduleNotificationLoginTitle,
            fontSize: widget.isTvHost ? 22.sp : 20.sp,
            fontFamily: AppStrings.interSemiBold,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
          12.verticalSpace,
          CustomText(
            AppStrings.scheduleNotificationLoginMessage,
            fontSize: widget.isTvHost ? 16.sp : 14.sp,
            fontFamily: AppStrings.interRegular,
            color: context.planDetailTextColor,
            maxLines: 4,
          ),
          24.verticalSpace,
          widget.isTvHost
              ? FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ScheduleLoginDialogButton(
                          label: AppStrings.cancel,
                          isPrimary: false,
                          focusNode: _cancelFocus,
                          focusOrder: const NumericFocusOrder(0),
                          useTvFocus: true,
                          moveRightTo: _loginFocus,
                          onPressed: widget.onCancel,
                        ),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: _ScheduleLoginDialogButton(
                          label: AppStrings.loginAction,
                          isPrimary: true,
                          focusNode: _loginFocus,
                          focusOrder: const NumericFocusOrder(1),
                          useTvFocus: true,
                          moveLeftTo: _cancelFocus,
                          onPressed: widget.onLogin,
                        ),
                      ),
                    ],
                  ),
                )
              : Row(
                  children: [
                    Expanded(
                      child: _ScheduleLoginDialogButton(
                        label: AppStrings.cancel,
                        isPrimary: false,
                        useTvFocus: false,
                        onPressed: widget.onCancel,
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: _ScheduleLoginDialogButton(
                        label: AppStrings.loginAction,
                        isPrimary: true,
                        useTvFocus: false,
                        onPressed: widget.onLogin,
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );

    if (!widget.isTvHost) return body;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.onCancel();
      },
      child: FocusScope(
        autofocus: true,
        child: body,
      ),
    );
  }
}

class _ScheduleLoginDialogButton extends StatefulWidget {
  const _ScheduleLoginDialogButton({
    required this.label,
    required this.isPrimary,
    required this.onPressed,
    required this.useTvFocus,
    this.focusNode,
    this.focusOrder,
    this.moveLeftTo,
    this.moveRightTo,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onPressed;
  final bool useTvFocus;
  final FocusNode? focusNode;
  final FocusOrder? focusOrder;
  final FocusNode? moveLeftTo;
  final FocusNode? moveRightTo;

  @override
  State<_ScheduleLoginDialogButton> createState() =>
      _ScheduleLoginDialogButtonState();
}

class _ScheduleLoginDialogButtonState extends State<_ScheduleLoginDialogButton> {
  bool _focused = false;

  void _activate() => widget.onPressed();

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.arrowRight && widget.moveRightTo != null) {
      widget.moveRightTo!.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft && widget.moveLeftTo != null) {
      widget.moveLeftTo!.requestFocus();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter) {
      _activate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  BoxDecoration _tvDecoration(BuildContext context) {
    if (_focused) {
      if (widget.isPrimary) {
        return BoxDecoration(
          gradient: const LinearGradient(colors: AppColors.primaryGradient),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: AppColors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.55),
              blurRadius: 16,
              spreadRadius: 1,
            ),
          ],
        );
      }
      return BoxDecoration(
        color: context.tvFocusPillBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.primary, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      );
    }

    if (widget.isPrimary) {
      return BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: context.borderColor.withValues(alpha: 0.8),
          width: 1,
        ),
      );
    }

    return BoxDecoration(
      color: context.isDark
          ? context.chipUnselectedBg
          : AppColors.white.withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(14.r),
      border: Border.all(color: context.borderColor, width: 1),
    );
  }

  Color _tvLabelColor(BuildContext context) {
    if (!_focused) {
      return widget.isPrimary
          ? AppColors.white.withValues(alpha: 0.75)
          : context.planDetailTextColor.withValues(alpha: 0.7);
    }
    return widget.isPrimary ? AppColors.white : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.useTvFocus) {
      final baseColor = widget.isPrimary
          ? AppColors.primary
          : (context.isDark ? context.chipUnselectedBg : AppColors.white);
      return GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(vertical: 14.h),
          decoration: BoxDecoration(
            color: widget.isPrimary ? AppColors.primary : baseColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: widget.isPrimary
                  ? AppColors.transparent
                  : context.borderColor,
            ),
          ),
          child: CustomText(
            widget.label,
            fontSize: 15.sp,
            fontFamily: AppStrings.interSemiBold,
            color: widget.isPrimary
                ? AppColors.white
                : context.planDetailTextColor,
          ),
        ),
      );
    }

    final button = Focus(
      focusNode: widget.focusNode,
      onFocusChange: (focused) {
        if (_focused != focused) {
          setState(() => _focused = focused);
        }
      },
      onKeyEvent: _onKey,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.select): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        },
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTap: _activate,
            child: AnimatedScale(
              scale: _focused ? 1.04 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                alignment: Alignment.center,
                height: 52.h,
                decoration: _tvDecoration(context),
                child: CustomText(
                  widget.label,
                  fontSize: 16.sp,
                  fontFamily: AppStrings.interSemiBold,
                  fontWeight: _focused ? FontWeight.w700 : FontWeight.w500,
                  color: _tvLabelColor(context),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.focusOrder == null) return button;

    return FocusTraversalOrder(
      order: widget.focusOrder!,
      child: button,
    );
  }
}
