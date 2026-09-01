import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/static_locale_data.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/controller/profile_controller.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/model/country_item.dart';
import 'package:iptv_demo/model/user_profile.dart';
import 'package:iptv_demo/repositories/iptv_repository.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/services/stripe_payment_service.dart';
import 'package:iptv_demo/ui/tv/auth/tv_auth_flow.dart';
import 'package:iptv_demo/utils/post_auth_home_route.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

const String _kProfileControllerTag = 'tv_my_space_profile';

/// Left rail categories for TV My Space.
enum TvMySpaceCategory { signIn, profile, subscription, general, account }

/// Right pane drill-in (same screen, divider layout preserved).
enum TvMySpaceRightDetail {
  none,
  profileDetail,
  countryList,
  premiumManage,
}

class TvMySpaceScreen extends StatefulWidget {
  const TvMySpaceScreen({
    super.key,
    this.initialCategory = TvMySpaceCategory.profile,
  });

  final TvMySpaceCategory initialCategory;

  @override
  State<TvMySpaceScreen> createState() => _TvMySpaceScreenState();
}

class _TvMySpaceScreenState extends State<TvMySpaceScreen> {
  late TvMySpaceCategory _cat;
  TvMySpaceRightDetail _detail = TvMySpaceRightDetail.none;
  final IptvController _iptv = Get.find<IptvController>();
  Worker? _authWorker;

  @override
  void initState() {
    super.initState();
    final auth = Get.find<AuthService>();
    _cat = auth.isLoggedIn.value
        ? widget.initialCategory
        : TvMySpaceCategory.signIn;
    _authWorker = ever(auth.isLoggedIn, (dynamic logged) {
      if (!mounted) return;
      if (logged == false) {
        _disposeProfileController();
        setState(() {
          _cat = TvMySpaceCategory.signIn;
          _detail = TvMySpaceRightDetail.none;
        });
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(auth.syncPremiumFromServer());
    });
  }

  void _disposeProfileController() {
    if (Get.isRegistered<ProfileController>(tag: _kProfileControllerTag)) {
      Get.delete<ProfileController>(tag: _kProfileControllerTag);
    }
  }

  @override
  void dispose() {
    _authWorker?.dispose();
    _disposeProfileController();
    super.dispose();
  }

  void _selectCategory(TvMySpaceCategory c) {
    if (_cat == c && _detail == TvMySpaceRightDetail.none) return;
    setState(() {
      _cat = c;
      _detail = TvMySpaceRightDetail.none;
    });
  }

  void _openDetail(TvMySpaceRightDetail d) {
    if (d == TvMySpaceRightDetail.profileDetail) {
      if (!Get.isRegistered<ProfileController>(tag: _kProfileControllerTag)) {
        Get.put(ProfileController(), tag: _kProfileControllerTag);
      } else {
        unawaited(
            Get.find<ProfileController>(tag: _kProfileControllerTag).load());
      }
    }
    setState(() => _detail = d);
  }

  void _closeDetail() {
    if (_detail == TvMySpaceRightDetail.profileDetail) {
      _disposeProfileController();
    }
    setState(() => _detail = TvMySpaceRightDetail.none);
  }

  String _initialsFromEmail(String email) {
    if (email.isEmpty) return '?';
    final local =
        email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (local.length >= 2) return local.substring(0, 2).toUpperCase();
    if (local.isNotEmpty) return local[0].toUpperCase();
    return email[0].toUpperCase();
  }

  String _sectionCapsHeader() {
    switch (_detail) {
      case TvMySpaceRightDetail.profileDetail:
        return AppStrings.profile.toUpperCase();
      case TvMySpaceRightDetail.countryList:
        return AppStrings.selectCountry.toUpperCase();
      case TvMySpaceRightDetail.premiumManage:
        return AppStrings.upgradeOption.toUpperCase();
      case TvMySpaceRightDetail.none:
        break;
    }
    switch (_cat) {
      case TvMySpaceCategory.signIn:
        return AppStrings.login.toUpperCase();
      case TvMySpaceCategory.profile:
        return AppStrings.profile.toUpperCase();
      case TvMySpaceCategory.subscription:
        return AppStrings.currentPlan;
      case TvMySpaceCategory.general:
        return AppStrings.generalSettings;
      case TvMySpaceCategory.account:
        return AppStrings.accountSettings;
    }
  }

  String _paneTitle() {
    switch (_cat) {
      case TvMySpaceCategory.signIn:
        return AppStrings.login;
      case TvMySpaceCategory.profile:
        return AppStrings.profile;
      case TvMySpaceCategory.subscription:
        return AppStrings.manageSubscription;
      case TvMySpaceCategory.general:
        return AppStrings.generalSettings;
      case TvMySpaceCategory.account:
        return AppStrings.accountSettings;
    }
  }

  String _paneSubtitle() {
    switch (_cat) {
      case TvMySpaceCategory.signIn:
        return '';
      case TvMySpaceCategory.profile:
        return 'Avatar, display name and signed-in email.';
      case TvMySpaceCategory.subscription:
        return 'Plan status, upgrades and Stripe checkout.';
      case TvMySpaceCategory.general:
        return 'Country / region.';
      case TvMySpaceCategory.account:
        return 'Delete your Flixo account on this device.';
    }
  }

  void _showSignOutDialog() {
    showDialog<void>(
      context: context,
      barrierColor: AppColors.black.withValues(alpha: 0.7),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 520.w),
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color.lerp(dialogContext.cardBg, AppColors.primary, 0.18) ??
                        dialogContext.cardBg,
                    Color.lerp(dialogContext.cardBg, AppColors.black, 0.08) ??
                        dialogContext.cardBg,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 28,
                    spreadRadius: -6,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomText(
                    AppStrings.signOutConfirmTitle,
                    fontSize: 22.sp,
                    fontFamily: AppStrings.interSemiBold,
                    color: dialogContext.textPrimary,
                  ),
                  14.verticalSpace,
                  CustomText(
                    AppStrings.signOutConfirmMessage,
                    fontSize: 16.sp,
                    color: dialogContext.planDetailTextColor,
                  ),
                  24.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: _TvDialogActionButton(
                          label: AppStrings.cancel,
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ),
                      12.horizontalSpace,
                      Expanded(
                        child: _TvDialogActionButton(
                          label: AppStrings.signOutConfirmAction,
                          isDanger: true,
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            await Get.find<AuthService>().logout();
                            // After logout, reload browse data as guest before
                            // navigating back to TV home.
                            await _iptv.fetchCategories();
                            _iptv.resetHomeBrowseFilters();
                            await _iptv.fetchChannels(reset: true);
                            final dest = await resolveSplashDestination(
                                isLoggedIn: false);
                            Get.offAllNamed(dest);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteAccountDialog() {
    bool deleting = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: AppColors.black.withValues(alpha: 0.72),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: AppColors.transparent,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 560.w),
                child: Container(
                  padding: EdgeInsets.all(24.w),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.lerp(ctx.cardBg, AppColors.signOutButtonTextColor,
                                0.16) ??
                            ctx.cardBg,
                        Color.lerp(ctx.cardBg, AppColors.black, 0.08) ??
                            ctx.cardBg,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.signOutButtonTextColor
                            .withValues(alpha: 0.2),
                        blurRadius: 28,
                        spreadRadius: -6,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomText(
                        AppStrings.deleteAccountConfirmTitle,
                        fontSize: 22.sp,
                        fontFamily: AppStrings.interSemiBold,
                        color: AppColors.signOutButtonTextColor,
                      ),
                      14.verticalSpace,
                      CustomText(
                        AppStrings.deleteAccountConfirmMessage,
                        fontSize: 16.sp,
                        color: ctx.planDetailTextColor,
                      ),
                      if (deleting) ...[
                        24.verticalSpace,
                        const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      if (!deleting) ...[
                        24.verticalSpace,
                        Row(
                          children: [
                            Expanded(
                              child: _TvDialogActionButton(
                                label: AppStrings.cancel,
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ),
                            12.horizontalSpace,
                            Expanded(
                              child: _TvDialogActionButton(
                                label: AppStrings.deleteAccountConfirmAction,
                                isDanger: true,
                                onPressed: () async {
                                  if (deleting) return;
                                  setDialogState(() => deleting = true);
                                  final (ok, msg) =
                                      await Get.find<AuthService>()
                                          .deleteAccount();
                                  if (!ctx.mounted) return;
                                  Navigator.pop(ctx);
                                  if (ok) {
                                    final dest = await resolveSplashDestination(
                                        isLoggedIn: false);
                                    Get.offAllNamed(dest);
                                  } else {
                                    showAppToast(
                                      title: 'Error',
                                      message: msg,
                                      isError: true,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    const shellGradient = <Color>[
      Color(0xFF441032),
      Color(0xFF1B0D22),
      Color(0xFF08080F),
    ];
    final themedContext = Theme.of(context);
    return Theme(
      data: themedContext.copyWith(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.transparent,
        colorScheme: themedContext.colorScheme.copyWith(
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
        backgroundColor: AppColors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _AnimatedMySpaceBackdrop(),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: shellGradient,
                  stops: [0.0, 0.46, 1.0],
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.88, -0.7),
                    radius: 1.3,
                    colors: [
                      AppColors.primary.withValues(alpha: isDark ? 0.09 : 0.06),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      AppColors.secondary
                          .withValues(alpha: isDark ? 0.07 : 0.05),
                      AppColors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Obx(() {
                final logged = Get.find<AuthService>().isLoggedIn.value;
                if (!logged) {
                  return FocusTraversalGroup(
                    policy: OrderedTraversalPolicy(),
                    child: _TvMySpaceGuestHero(
                      onOpenLogin: () {
                        openTvLoginScreen(
                          onSessionEstablished: () {
                            if (!mounted) return;
                            setState(() {
                              _cat = TvMySpaceCategory.profile;
                              _detail = TvMySpaceRightDetail.none;
                            });
                            unawaited(Get.find<AuthService>()
                                .syncPremiumFromServer());
                          },
                        );
                      },
                    ),
                  );
                }
                return FocusTraversalGroup(
                  policy: OrderedTraversalPolicy(),
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 14.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22.r),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xAA1B1328),
                            Color(0x8A120E1E),
                          ],
                        ),
                        border: Border.all(
                          color: AppColors.white.withValues(alpha: 0.16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 26,
                            spreadRadius: -8,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding:
                                  EdgeInsets.fromLTRB(8.w, 20.h, 8.w, 16.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ShaderMask(
                                    blendMode: BlendMode.srcIn,
                                    shaderCallback: (bounds) =>
                                        const LinearGradient(
                                      colors: AppColors.primaryGradient,
                                    ).createShader(bounds),
                                    child: CustomText(
                                      'My Space',
                                      style: TextStyle(
                                        fontFamily: AppStrings.interExtraBold,
                                        fontSize: 26.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                  ),
                                  6.verticalSpace,
                                  CustomText(
                                    'Account, subscription & app preferences',
                                    style: TextStyle(
                                      fontFamily: AppStrings.interRegular,
                                      fontSize: 13.sp,
                                      color: context.tvSubtitleColor,
                                      height: 1.3,
                                    ),
                                  ),
                                  18.verticalSpace,
                                  Expanded(
                                    child: ListView(
                                      children: [
                                        _LeftCategoryTile(
                                          order: const NumericFocusOrder(22),
                                          autofocus:
                                              _cat == TvMySpaceCategory.profile,
                                          icon: Icons.person_outline_rounded,
                                          title: AppStrings.profile,
                                          subtitle:
                                              'Your name, email & premium status',
                                          selected:
                                              _cat == TvMySpaceCategory.profile,
                                          onSelect: () => _selectCategory(
                                              TvMySpaceCategory.profile),
                                        ),
                                        8.verticalSpace,
                                        _LeftCategoryTile(
                                          order: const NumericFocusOrder(28),
                                          autofocus: _cat ==
                                              TvMySpaceCategory.subscription,
                                          icon: Icons.subscriptions_outlined,
                                          title: AppStrings.manageSubscription,
                                          subtitle: 'Plan, renewal & billing',
                                          selected: _cat ==
                                              TvMySpaceCategory.subscription,
                                          onSelect: () => _selectCategory(
                                              TvMySpaceCategory.subscription),
                                        ),
                                        8.verticalSpace,
                                        _LeftCategoryTile(
                                          order: const NumericFocusOrder(34),
                                          autofocus:
                                              _cat == TvMySpaceCategory.general,
                                          icon: Icons.tune_rounded,
                                          title: AppStrings.generalSettings,
                                          subtitle: 'Country & region',
                                          selected:
                                              _cat == TvMySpaceCategory.general,
                                          onSelect: () => _selectCategory(
                                              TvMySpaceCategory.general),
                                        ),
                                        8.verticalSpace,
                                        _LeftCategoryTile(
                                          order: const NumericFocusOrder(40),
                                          autofocus:
                                              _cat == TvMySpaceCategory.account,
                                          icon: Icons.manage_accounts_outlined,
                                          title: AppStrings.accountSettings,
                                          subtitle:
                                              AppStrings.deleteAccountSubtitle,
                                          selected:
                                              _cat == TvMySpaceCategory.account,
                                          onSelect: () => _selectCategory(
                                              TvMySpaceCategory.account),
                                        ),
                                      ],
                                    ),
                                  ),
                                  12.verticalSpace,
                                  FocusTraversalOrder(
                                    order: const NumericFocusOrder(900),
                                    child: _TvCompactActionTile(
                                      label: AppStrings.signOut,
                                      destructive: true,
                                      onPressed: _showSignOutDialog,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 70.h),
                            child: VerticalDivider(
                              width: 28.w,
                              thickness: 1,
                              color:
                                  context.borderColor.withValues(alpha: 0.55),
                            ),
                          ),
                          Expanded(
                            flex: 7,
                            child: Padding(
                              padding:
                                  EdgeInsets.fromLTRB(8.w, 30.h, 8.w, 10.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (_detail != TvMySpaceRightDetail.none) ...[
                                    FocusTraversalOrder(
                                      order: const NumericFocusOrder(6),
                                      child: _TvCompactActionTile(
                                        label: 'Back',
                                        icon: Icons.arrow_back_ios_new_rounded,
                                        onPressed: _closeDetail,
                                      ),
                                    ),
                                    14.verticalSpace,
                                    CustomText(
                                      _sectionCapsHeader(),
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        letterSpacing: 1.35,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white70,
                                        fontFamily: AppStrings.interSemiBold,
                                      ),
                                    ),
                                    14.verticalSpace,
                                  ] else ...[
                                    CustomText(
                                      _paneTitle(),
                                      style: TextStyle(
                                        fontFamily: AppStrings.interBold,
                                        fontSize: 24.sp,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.white,
                                      ),
                                    ),
                                    6.verticalSpace,
                                    CustomText(
                                      _paneSubtitle(),
                                      style: TextStyle(
                                        fontFamily: AppStrings.interRegular,
                                        fontSize: 14.sp,
                                        color: AppColors.white70,
                                      ),
                                    ),
                                    18.verticalSpace,
                                  ],
                                  Expanded(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 280),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, animation) {
                                        final slide = Tween<Offset>(
                                          begin: const Offset(0.03, 0),
                                          end: Offset.zero,
                                        ).animate(animation);
                                        return FadeTransition(
                                          opacity: animation,
                                          child: SlideTransition(
                                              position: slide, child: child),
                                        );
                                      },
                                      child: KeyedSubtree(
                                        key: ValueKey('$_cat$_detail'),
                                        child: _buildRightBody(context),
                                      ),
                                    ),
                                  ),
                                  Center(
                                    child: CustomText(
                                      AppStrings.appVersion,
                                      fontSize: 11.sp,
                                      color: AppColors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightBody(BuildContext context) {
    switch (_detail) {
      case TvMySpaceRightDetail.countryList:
        return _TvCountryListPanel(
          onPicked: () => _closeDetail(),
        );
      case TvMySpaceRightDetail.profileDetail:
        return _TvProfileDetailPanel(tag: _kProfileControllerTag);
      case TvMySpaceRightDetail.premiumManage:
        return _TvPremiumManagePanel(
          onDone: () => _closeDetail(),
        );
      case TvMySpaceRightDetail.none:
        break;
    }

    switch (_cat) {
      case TvMySpaceCategory.signIn:
        return Center(
          child: CustomText(
            'Use Log In on the welcome screen.',
            fontSize: 16.sp,
            color: context.tvSubtitleColor,
            textAlign: TextAlign.center,
          ),
        );
      case TvMySpaceCategory.profile:
        return _RightProfileSummary(
          initialsFn: _initialsFromEmail,
          orderBase: 100,
          onOpenDetail: () => _openDetail(TvMySpaceRightDetail.profileDetail),
        );
      case TvMySpaceCategory.subscription:
        return _RightSubscriptionSummary(
          orderBase: 100,
          onManage: () => _openDetail(TvMySpaceRightDetail.premiumManage),
          onOpenProfile: () => _selectCategory(TvMySpaceCategory.profile),
        );
      case TvMySpaceCategory.general:
        return _RightGeneralPane(
          controller: _iptv,
          orderBase: 100,
          onCountry: () => _openDetail(TvMySpaceRightDetail.countryList),
        );
      case TvMySpaceCategory.account:
        return _RightAccountPane(
          orderBase: 100,
          onDelete: _showDeleteAccountDialog,
        );
    }
  }
}

/// Logged-out My Space — centered hero similar to streaming TV account gates.
class _TvMySpaceGuestHero extends StatelessWidget {
  const _TvMySpaceGuestHero({required this.onOpenLogin});

  final VoidCallback onOpenLogin;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: const [
                Color(0xFF3A1530),
                Color(0xFF140814),
                AppColors.black,
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        const CustomPaint(painter: _MySpaceStarfieldPainter()),
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 620.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  Assets.images.logoWithoutBg.path,
                  width: 200.w,
                  height: 200.h,
                  filterQuality: FilterQuality.high,
                  fit: BoxFit.contain,
                ),
                32.verticalSpace,
                CustomText(
                  '${AppStrings.login} to ${AppStrings.appName}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppStrings.interExtraBold,
                    fontSize: 36.sp,
                    color: AppColors.white,
                    height: 1.15,
                  ),
                ),
                16.verticalSpace,
                CustomText(
                  AppStrings.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppStrings.interRegular,
                    fontSize: 17.sp,
                    color: AppColors.grey2,
                    height: 1.35,
                  ),
                ),
                40.verticalSpace,
                FocusTraversalOrder(
                  order: const NumericFocusOrder(1),
                  child: _GuestHeroLoginButton(onPressed: onOpenLogin),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 20.h,
          child: Center(
            child: CustomText(
              AppStrings.appVersion,
              fontSize: 11.sp,
              color: context.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _GuestHeroLoginButton extends StatefulWidget {
  const _GuestHeroLoginButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_GuestHeroLoginButton> createState() => _GuestHeroLoginButtonState();
}

class _GuestHeroLoginButtonState extends State<_GuestHeroLoginButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          scale: _focused ? 1.03 : 1.0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 320.w,
            height: 58.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: _focused
                    ? context.isDark
                        ? AppColors.white
                        : AppColors.primary.withValues(alpha: 0.9)
                    : context.borderColor.withValues(alpha: 0.65),
                width: _focused ? 2.2 : 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.62),
                        blurRadius: 26,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: CustomText(
              AppStrings.login,
              style: TextStyle(
                color: AppColors.white,
                fontFamily: AppStrings.interSemiBold,
                fontSize: 20.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MySpaceStarfieldPainter extends CustomPainter {
  const _MySpaceStarfieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    for (var i = 0; i < 160; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height * 0.72;
      final r = rnd.nextDouble() * 1.5 + 0.25;
      final paint = Paint()
        ..color =
            AppColors.white.withValues(alpha: rnd.nextDouble() * 0.5 + 0.1);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Left category row ───────────────────────────────────────────────────────

class _LeftCategoryTile extends StatefulWidget {
  const _LeftCategoryTile({
    required this.order,
    this.autofocus = false,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelect,
  });

  final FocusOrder order;
  final bool autofocus;
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onSelect;

  @override
  State<_LeftCategoryTile> createState() => _LeftCategoryTileState();
}

class _LeftCategoryTileState extends State<_LeftCategoryTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final selected = widget.selected;
    final borderColor = selected
        ? context.borderColor.withValues(alpha: 0.85)
        : (_focused ? AppColors.primary : AppColors.transparent);
    final bg = selected
        ? context.chipUnselectedBg.withValues(alpha: 0.95)
        : (_focused
            ? context.chipUnselectedBg.withValues(alpha: 0.55)
            : AppColors.transparent);
    return FocusTraversalOrder(
      order: widget.order,
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onSelect();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onSelect,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 13.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: borderColor,
                width: selected || _focused ? 1.5 : 0,
              ),
              color: bg,
            ),
            child: Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.white.withValues(alpha: 0.2)
                        : AppColors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    widget.icon,
                    color: selected || _focused
                        ? AppColors.white
                        : AppColors.white.withValues(alpha: 0.85),
                    size: 22.sp,
                  ),
                ),
                14.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        widget.title,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                        fontFamily: AppStrings.interSemiBold,
                      ),
                      4.verticalSpace,
                      CustomText(
                        widget.subtitle,
                        fontSize: 13.sp,
                        color: AppColors.white70,
                        maxLines: 2,
                        fontFamily: AppStrings.interRegular,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.white70,
                  size: 26.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Profile summary ─────────────────────────────────────────────────────────

class _RightProfileSummary extends StatelessWidget {
  const _RightProfileSummary({
    required this.initialsFn,
    required this.orderBase,
    required this.onOpenDetail,
  });

  final String Function(String email) initialsFn;
  final int orderBase;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final auth = Get.find<AuthService>();
      final email = auth.userEmail.value;
      final display =
          email.isNotEmpty ? email.split('@').first : AppStrings.profile;
      final initials = initialsFn(email);
      return ListView(
        padding: EdgeInsets.only(top: 4.h),
        children: [
          FocusTraversalOrder(
            order: NumericFocusOrder(orderBase.toDouble()),
            child: _FocusableSettingRow(
              onPressed: onOpenDetail,
              child: Container(
                padding: EdgeInsets.all(18.w),
                decoration: BoxDecoration(
                  color: context.chipUnselectedBg.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: context.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 76.r,
                      height: 76.r,
                      decoration: BoxDecoration(
                        color: AppColors.avatarBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                          width: 2,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: CustomText(
                        initials,
                        color: AppColors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppStrings.interBold,
                      ),
                    ),
                    20.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            display,
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: context.textPrimary,
                              fontFamily: AppStrings.interSemiBold,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            8.verticalSpace,
                            CustomText(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: context.tvSubtitleColor,
                                fontFamily: AppStrings.interRegular,
                              ),
                            ),
                          ],
                          if (auth.isPremiumUser.value) ...[
                            10.verticalSpace,
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 10.w, vertical: 4.h),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: CustomText(
                                'PREMIUM',
                                fontSize: 13.sp,
                                fontFamily: AppStrings.interSemiBold,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: context.tvSubtitleColor,
                      size: 30.sp,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _RightSubscriptionSummary extends StatelessWidget {
  const _RightSubscriptionSummary({
    required this.orderBase,
    required this.onManage,
    required this.onOpenProfile,
  });

  final int orderBase;
  final VoidCallback onManage;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.only(top: 4.h),
      children: [
        Obx(() {
          final auth = Get.find<AuthService>();
          final premium = auth.isPremiumUser.value;
          final email = auth.userEmail.value;
          final profile = auth.currentProfile.value;
          final renewalText = _renewalCustomText(profile, premium);
          final monthlyText = _monthlyCostCustomText(profile, premium);
          final paymentMethod = _paymentMethodCustomText(profile, premium);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: premium
                        ? ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: AppColors.primaryGradient,
                            ).createShader(bounds),
                            child: CustomText(
                              AppStrings.adsFreePlan,
                              style: TextStyle(
                                fontFamily: AppStrings.interExtraBold,
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w800,
                                color: AppColors.white,
                                height: 1.2,
                              ),
                            ),
                          )
                        : CustomText(
                            'Free plan',
                            style: TextStyle(
                              fontFamily: AppStrings.interExtraBold,
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              color: context.textPrimary,
                              height: 1.2,
                            ),
                          ),
                  ),
                  if (premium)
                    Image.asset(
                      Assets.images.settings.verified.path,
                      width: 26.r,
                      height: 26.r,
                    ),
                ],
              ),
              10.verticalSpace,
              CustomText(
                premium
                    ? 'Premium is active on this account. Manage renewal and receipts below.'
                    : 'Upgrade for an ad-free experience and premium playback.',
                style: TextStyle(
                  fontFamily: AppStrings.interRegular,
                  fontSize: 15.sp,
                  color: AppColors.white70,
                  height: 1.4,
                ),
              ),
              22.verticalSpace,
              if (!premium)
                Row(
                  children: [
                    Expanded(
                      child: _TvSubscriptionGradientButton(
                        order: NumericFocusOrder(orderBase.toDouble()),
                        autofocus: true,
                        label: 'Upgrade',
                        onPressed: onManage,
                      ),
                    ),
                    14.horizontalSpace,
                    Expanded(
                      child: _TvSubscriptionOutlineButton(
                        order: NumericFocusOrder((orderBase + 1).toDouble()),
                        label: 'Payment details',
                        onPressed: onManage,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: context.chipUnselectedBg.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: context.borderColor.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        'Payment details',
                        style: TextStyle(
                          color: context.textPrimary,
                          fontFamily: AppStrings.interSemiBold,
                          fontSize: 15.sp,
                        ),
                      ),
                      6.verticalSpace,
                      CustomText(
                        paymentMethod,
                        style: TextStyle(
                          color: context.tvSubtitleColor,
                          fontFamily: AppStrings.interRegular,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              28.verticalSpace,
              Divider(
                height: 1,
                color: context.dividerColor.withValues(alpha: 0.45),
              ),
              20.verticalSpace,
              CustomText(
                AppStrings.accountEmail,
                style: TextStyle(
                  fontFamily: AppStrings.interSemiBold,
                  fontSize: 12.sp,
                  letterSpacing: 0.6,
                  color: AppColors.white70,
                ),
              ),
              8.verticalSpace,
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: CustomText(
                      email.isEmpty ? '—' : email,
                      style: TextStyle(
                        fontFamily: AppStrings.interMedium,
                        fontSize: 17.sp,
                        color: context.textPrimary,
                      ),
                    ),
                  ),
                  FocusTraversalOrder(
                    order: NumericFocusOrder((orderBase + 2).toDouble()),
                    child: Focus(
                      onKeyEvent: (node, event) {
                        if (event is! KeyDownEvent) {
                          return KeyEventResult.ignored;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.select ||
                            event.logicalKey == LogicalKeyboardKey.enter) {
                          onOpenProfile();
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: InkWell(
                        onTap: onOpenProfile,
                        borderRadius: BorderRadius.circular(8.r),
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 8.h),
                          child: CustomText(
                            'Update',
                            style: TextStyle(
                              fontFamily: AppStrings.interBold,
                              fontSize: 15.sp,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              28.verticalSpace,
              Divider(
                height: 1,
                color: context.dividerColor.withValues(alpha: 0.45),
              ),
              20.verticalSpace,
              CustomText(
                'This device',
                style: TextStyle(
                  fontFamily: AppStrings.interSemiBold,
                  fontSize: 12.sp,
                  letterSpacing: 0.6,
                  color: AppColors.white70,
                ),
              ),
              12.verticalSpace,
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: context.chipUnselectedBg.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: context.borderColor.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.tv_rounded,
                      size: 28.sp,
                      color: context.textPrimary,
                    ),
                    16.horizontalSpace,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomText(
                            'Flixo on TV',
                            style: TextStyle(
                              fontFamily: AppStrings.interSemiBold,
                              fontSize: 16.sp,
                              color: context.textPrimary,
                            ),
                          ),
                          4.verticalSpace,
                          CustomText(
                            'Signed in on this device',
                            style: TextStyle(
                              fontFamily: AppStrings.interRegular,
                              fontSize: 13.sp,
                              color: AppColors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              18.verticalSpace,
              _planRow(context, AppStrings.renewalDateLabel, renewalText),
              12.verticalSpace,
              _planRow(context, AppStrings.monthlyCostLabel, monthlyText),
            ],
          );
        }),
      ],
    );
  }

  String _paymentMethodCustomText(UserProfile? profile, bool premium) {
    if (!premium) return 'No payment yet';
    final method = profile?.paymentMethod?.trim();
    if (method == null || method.isEmpty) return 'Premium subscription active';
    return 'Method: $method';
  }

  String _renewalCustomText(UserProfile? profile, bool premium) {
    if (!premium) return '—';
    final date = profile?.renewalDate;
    if (date == null) return 'Auto-renew enabled';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  String _monthlyCostCustomText(UserProfile? profile, bool premium) {
    if (!premium) return '0';
    final amount = profile?.subscriptionAmount;
    final cycle = (profile?.billingCycle ?? '').toLowerCase();
    final currency = (profile?.subscriptionCurrency ?? 'USD').toUpperCase();
    String symbol;
    switch (currency) {
      case 'INR':
        symbol = '₹';
        break;
      case 'USD':
        symbol = '\$';
        break;
      case 'EUR':
        symbol = '€';
        break;
      default:
        symbol = '$currency ';
    }
    if (amount != null) {
      final monthly = (cycle.contains('year') || cycle.contains('annual'))
          ? (amount / 12)
          : amount;
      return '$symbol${monthly.toStringAsFixed(2)}';
    }
    // Fallback to known premium price if backend doesn't return billing data.
    return '$symbol${(99 / 12).toStringAsFixed(2)}';
  }

  Widget _planRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CustomText(
          label,
          fontSize: 15.sp,
          color: context.planDetailTextColor,
          fontFamily: AppStrings.interRegular,
        ),
        CustomText(
          value,
          fontSize: 15.sp,
          color: context.textPrimary,
          fontFamily: AppStrings.interMedium,
        ),
      ],
    );
  }
}

class _TvSubscriptionGradientButton extends StatefulWidget {
  const _TvSubscriptionGradientButton({
    required this.order,
    required this.label,
    required this.onPressed,
    this.autofocus = false,
  });

  final FocusOrder order;
  final String label;
  final VoidCallback onPressed;
  final bool autofocus;

  @override
  State<_TvSubscriptionGradientButton> createState() =>
      _TvSubscriptionGradientButtonState();
}

class _TvSubscriptionGradientButtonState
    extends State<_TvSubscriptionGradientButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: widget.order,
      child: Focus(
        autofocus: widget.autofocus,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 52.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.primaryGradient),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: _focused ? AppColors.white : AppColors.transparent,
                width: _focused ? 2 : 0,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: CustomText(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.white,
                fontFamily: AppStrings.interSemiBold,
                fontSize: 15.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TvSubscriptionOutlineButton extends StatefulWidget {
  const _TvSubscriptionOutlineButton({
    required this.order,
    required this.label,
    required this.onPressed,
  });

  final FocusOrder order;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_TvSubscriptionOutlineButton> createState() =>
      _TvSubscriptionOutlineButtonState();
}

class _TvSubscriptionOutlineButtonState
    extends State<_TvSubscriptionOutlineButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: widget.order,
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 52.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.chipUnselectedBg,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: _focused
                    ? AppColors.primary
                    : context.borderColor.withValues(alpha: 0.75),
                width: _focused ? 2 : 1,
              ),
            ),
            child: CustomText(
              widget.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.textPrimary,
                fontFamily: AppStrings.interSemiBold,
                fontSize: 15.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RightGeneralPane extends StatelessWidget {
  const _RightGeneralPane({
    required this.controller,
    required this.orderBase,
    required this.onCountry,
  });

  final IptvController controller;
  final int orderBase;
  final VoidCallback onCountry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.white.withValues(alpha: context.isDark ? 0.08 : 0.3),
                AppColors.white.withValues(alpha: context.isDark ? 0.03 : 0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(
              color: AppColors.white
                  .withValues(alpha: context.isDark ? 0.12 : 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.black
                    .withValues(alpha: context.isDark ? 0.18 : 0.08),
                blurRadius: 14,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            children: [
              Obx(() {
                final code = controller.selectedCountryCode.value;
                return FocusTraversalOrder(
                  order: NumericFocusOrder(orderBase.toDouble()),
                  child: _FocusableSettingRow(
                    onPressed: onCountry,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    focusedFillColor:
                        context.chipUnselectedBg.withValues(alpha: 0.55),
                    focusedBorderColor:
                        context.borderColor.withValues(alpha: 0.9),
                    showFocusShadow: false,
                    child: _RightListRow(
                      title: AppStrings.country,
                      subtitle: countryNameForCode(code),
                      showChevron: true,
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedMySpaceBackdrop extends StatefulWidget {
  const _AnimatedMySpaceBackdrop();

  @override
  State<_AnimatedMySpaceBackdrop> createState() =>
      _AnimatedMySpaceBackdropState();
}

class _AnimatedMySpaceBackdropState extends State<_AnimatedMySpaceBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, __) {
          final t = _controller.value;
          final offsetA = (t - 0.5) * 60;
          final offsetB = (0.5 - t) * 48;
          return Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 56 + offsetA,
                right: -110,
                child: _GlowOrb(
                  size: 360,
                  color: AppColors.primary.withValues(alpha: 0.13),
                ),
              ),
              Positioned(
                bottom: -140 + offsetB,
                left: -120,
                child: _GlowOrb(
                  size: 420,
                  color: AppColors.secondary.withValues(alpha: 0.1),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ),
      ),
    );
  }
}

class _RightAccountPane extends StatelessWidget {
  const _RightAccountPane({
    required this.orderBase,
    required this.onDelete,
  });

  final int orderBase;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final danger = AppColors.signOutButtonTextColor;
    return ListView(
      children: [
        FocusTraversalOrder(
          order: NumericFocusOrder(orderBase.toDouble()),
          child: _FocusableSettingRow(
            onPressed: onDelete,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            focusedFillColor: AppColors.transparent,
            focusedBorderColor: AppColors.signOutButtonTextColor,
            child: _RightListRow(
              title: AppStrings.deleteAccount,
              subtitle: AppStrings.deleteAccountSubtitle,
              showChevron: true,
              titleColor: danger,
              subtitleColor: context.tvSubtitleColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _RightListRow extends StatelessWidget {
  const _RightListRow({
    required this.title,
    required this.subtitle,
    this.showChevron = false,
    this.titleColor,
    this.subtitleColor,
  });

  final String title;
  final String subtitle;
  final bool showChevron;
  final Color? titleColor;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: 6.h,
        horizontal: 6.w,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        title,
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: titleColor ?? AppColors.white,
                        fontFamily: AppStrings.interSemiBold,
                      ),
                    ),
                  ],
                ),
                if (subtitle.isNotEmpty) ...[
                  4.verticalSpace,
                  CustomText(
                    subtitle,
                    fontSize: 13.sp,
                    color: subtitleColor ?? AppColors.white70,
                    maxLines: 3,
                    fontFamily: AppStrings.interRegular,
                  ),
                ],
              ],
            ),
          ),
          if (showChevron)
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.white70,
              size: 22.sp,
            ),
        ],
      ),
    );
  }
}

class _TvCompactActionTile extends StatefulWidget {
  const _TvCompactActionTile({
    required this.label,
    required this.onPressed,
    this.icon,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool destructive;

  @override
  State<_TvCompactActionTile> createState() => _TvCompactActionTileState();
}

class _TvCompactActionTileState extends State<_TvCompactActionTile> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final accent =
        widget.destructive ? AppColors.signOutButtonTextColor : AppColors.white;
    final baseBg = widget.destructive
        ? AppColors.signOutButtonTextColor.withValues(alpha: 0.14)
        : context.chipUnselectedBg;
    final focusBg = widget.destructive
        ? AppColors.transparent
        : AppColors.white.withValues(alpha: 0.18);
    final borderBase = widget.destructive
        ? AppColors.signOutButtonTextColor.withValues(alpha: 0.9)
        : context.borderColor.withValues(alpha: 0.65);

    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(12.r),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(AppColors.transparent),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 11.h),
            decoration: BoxDecoration(
              color: _focused ? focusBg : baseBg,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _focused ? accent : borderBase,
                width: _focused ? 2 : 1,
              ),
              boxShadow: _focused && !widget.destructive
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 18,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16.sp,
                    color: _focused ? accent : context.textPrimary,
                  ),
                  8.horizontalSpace,
                ],
                CustomText(
                  widget.label,
                  fontSize: 14.sp,
                  color: widget.destructive
                      ? AppColors.white
                      : context.textPrimary,
                  fontFamily: AppStrings.interSemiBold,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TvDialogActionButton extends StatefulWidget {
  const _TvDialogActionButton({
    required this.label,
    required this.onPressed,
    this.isDanger = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool isDanger;

  @override
  State<_TvDialogActionButton> createState() => _TvDialogActionButtonState();
}

class _TvDialogActionButtonState extends State<_TvDialogActionButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final baseColor =
        widget.isDanger ? AppColors.signOutButtonTextColor : AppColors.primary;
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            height: 48.h,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _focused
                  ? baseColor.withValues(alpha: 0.94)
                  : baseColor.withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _focused ? AppColors.white : AppColors.white24,
                width: _focused ? 2 : 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: baseColor.withValues(alpha: 0.4),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: CustomText(
              widget.label,
              fontSize: 15.sp,
              color: AppColors.white,
              fontFamily: AppStrings.interSemiBold,
            ),
          ),
        ),
      ),
    );
  }
}

class _FocusableSettingRow extends StatefulWidget {
  const _FocusableSettingRow({
    required this.onPressed,
    required this.child,
    this.padding,
    this.focusedFillColor,
    this.focusedBorderColor,
    this.showFocusShadow = true,
  });

  final VoidCallback onPressed;
  final Widget child;
  final EdgeInsets? padding;
  final Color? focusedFillColor;
  final Color? focusedBorderColor;
  final bool showFocusShadow;

  @override
  State<_FocusableSettingRow> createState() => _FocusableSettingRowState();
}

class _FocusableSettingRowState extends State<_FocusableSettingRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.select ||
            event.logicalKey == LogicalKeyboardKey.enter) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Padding(
        padding: widget.padding ??
            EdgeInsets.symmetric(horizontal: 7.w, vertical: 4.h),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          scale: _focused ? 1.002 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            decoration: BoxDecoration(
              gradient: null,
              color: _focused
                  ? (widget.focusedFillColor ??
                      AppColors.primary
                          .withValues(alpha: context.isDark ? 0.22 : 0.12))
                  : AppColors.transparent,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: _focused
                    ? (widget.focusedBorderColor ??
                        AppColors.primary.withValues(alpha: 0.95))
                    : context.borderColor.withValues(alpha: 0.0),
                width: _focused ? 1.6 : 1,
              ),
              boxShadow: _focused && widget.showFocusShadow
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 18,
                        spreadRadius: -3,
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                borderRadius: BorderRadius.circular(14.r),
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Inline country list ─────────────────────────────────────────────────────

class _TvCountryListPanel extends StatefulWidget {
  const _TvCountryListPanel({required this.onPicked});

  final VoidCallback onPicked;

  @override
  State<_TvCountryListPanel> createState() => _TvCountryListPanelState();
}

class _TvCountryListPanelState extends State<_TvCountryListPanel> {
  List<CountryItem> _countries = <CountryItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await Get.find<IptvRepository>().fetchCountries();
      if (res.statusCode == 200 && res.body.isNotEmpty) {
        _countries = parseCountriesFromApiBody(res.body);
      }
    } catch (_) {
      _countries = <CountryItem>[];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iptv = Get.find<IptvController>();
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.secondary));
    }
    if (_countries.isEmpty) {
      return Center(
        child: CustomText(
          'No countries available from API.',
          fontSize: 15.sp,
          color: context.tvSubtitleColor,
        ),
      );
    }
    return Obx(() {
      final current = iptv.selectedCountryCode.value.toUpperCase();
      return ListView.separated(
        padding: EdgeInsets.only(top: 8.h),
        itemCount: _countries.length,
        separatorBuilder: (_, __) => 10.verticalSpace,
        itemBuilder: (ctx, i) {
          final item = _countries[i];
          final selected = current == item.code.toUpperCase();
          return _FocusableSelectableRow(
            order: NumericFocusOrder((120 + i).toDouble()),
            selected: selected,
            onPressed: () async {
              await iptv.setCountryFilter(item.code);
              widget.onPicked();
            },
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 28.h,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: context.chipUnselectedBg,
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: CustomText(
                    item.flag,
                    fontSize: 12.sp,
                    fontFamily: AppStrings.interSemiBold,
                    color: context.textPrimary,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: CustomText(
                    item.name,
                    fontSize: 16.sp,
                    fontFamily: AppStrings.interSemiBold,
                    color: context.textPrimary,
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.primary, size: 22.sp),
              ],
            ),
          );
        },
      );
    });
  }
}

class _FocusableSelectableRow extends StatefulWidget {
  const _FocusableSelectableRow({
    required this.order,
    required this.selected,
    required this.onPressed,
    required this.child,
  });

  final FocusOrder order;
  final bool selected;
  final VoidCallback onPressed;
  final Widget child;

  @override
  State<_FocusableSelectableRow> createState() =>
      _FocusableSelectableRowState();
}

class _FocusableSelectableRowState extends State<_FocusableSelectableRow> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? AppColors.secondary
        : (widget.selected ? AppColors.primary : context.borderColor);
    final background = _focused
        ? context.chipUnselectedBg.withValues(alpha: 0.78)
        : (widget.selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : context.settingsTileBg);

    return FocusTraversalOrder(
      order: widget.order,
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: borderColor,
                width: _focused || widget.selected ? 2 : 1,
              ),
              boxShadow: _focused
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.18),
                        blurRadius: 14,
                        spreadRadius: -2,
                      ),
                    ]
                  : null,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

// ── Profile API detail ───────────────────────────────────────────────────────

class _TvProfileDetailPanel extends StatelessWidget {
  const _TvProfileDetailPanel({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<ProfileController>(tag: tag);
    return Obx(() {
      if (c.isLoading.value) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.secondary));
      }
      final p = c.profile.value;
      if (p == null) {
        return ListView(
          children: [
            CustomText(
              c.errorMessage.value,
              fontSize: 15.sp,
              color: context.planDetailTextColor,
            ),
            20.verticalSpace,
            FilledButton(
              onPressed: () => c.load(),
              child: CustomText(AppStrings.retry, color: AppColors.white),
            ),
          ],
        );
      }
      return ListView(
        children: [
          _profileCard(context, p),
          20.verticalSpace,
          _infoBlock(context, p),
        ],
      );
    });
  }

  Widget _profileCard(BuildContext context, UserProfile p) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: context.cardBorderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              color: AppColors.avatarBackground,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: CustomText(
              p.initials,
              color: AppColors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.bold,
              fontFamily: AppStrings.interBold,
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  p.displayName,
                  fontSize: 18.sp,
                  fontFamily: AppStrings.interSemiBold,
                  color: context.textPrimary,
                ),
                if (p.email.isNotEmpty && p.displayName != p.email) ...[
                  6.verticalSpace,
                  CustomText(
                    p.email,
                    fontSize: 13.sp,
                    color: context.planDetailTextColor,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoBlock(BuildContext context, UserProfile p) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.planCardBg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        children: [
          _row(context, AppStrings.profileFieldName, p.name),
          Divider(color: context.dividerColor),
          _row(context, AppStrings.profileFieldEmail, p.email),
          if (p.role != null && p.role!.isNotEmpty) ...[
            Divider(color: context.dividerColor),
            _row(context, AppStrings.profileFieldRole, p.role!),
          ],
          if (p.phone != null && p.phone!.isNotEmpty) ...[
            Divider(color: context.dividerColor),
            _row(context, AppStrings.profileFieldPhone, p.phone!),
          ],
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String k, String v) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.w,
            child: CustomText(
              k,
              fontSize: 13.sp,
              color: context.planDetailTextColor,
              fontFamily: AppStrings.interSemiBold,
            ),
          ),
          Expanded(
            child: CustomText(
              v,
              fontSize: 15.sp,
              color: context.textPrimary,
              fontFamily: AppStrings.interRegular,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Premium (Stripe) inline ───────────────────────────────────────────────────

class _TvPremiumManagePanel extends StatefulWidget {
  const _TvPremiumManagePanel({required this.onDone});

  final VoidCallback onDone;

  @override
  State<_TvPremiumManagePanel> createState() => _TvPremiumManagePanelState();
}

class _TvPremiumManagePanelState extends State<_TvPremiumManagePanel> {
  bool _paying = false;

  Future<void> _upgrade() async {
    if (_paying) return;
    setState(() => _paying = true);
    try {
      final stripe = Get.find<StripePaymentService>();
      final outcome = await stripe.checkoutPremiumYearly();
      if (!mounted) return;
      switch (outcome) {
        case StripeCheckoutOutcome.success:
          showAppToast(
            title: AppStrings.appName,
            message: AppStrings.premiumPaymentSuccess,
          );
          unawaited(Get.find<AuthService>().syncPremiumFromServer());
          widget.onDone();
        case StripeCheckoutOutcome.cancelled:
          showAppToast(
            title: AppStrings.appName,
            message: AppStrings.premiumPaymentCancelled,
          );
        case StripeCheckoutOutcome.failed:
          showAppToast(
            title: AppStrings.appName,
            message: AppStrings.premiumPaymentFailed,
            isError: true,
          );
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        CustomText(
          AppStrings.pureEntertainment,
          fontSize: 26.sp,
          fontFamily: AppStrings.interBold,
          color: context.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        12.verticalSpace,
        CustomText(
          AppStrings.premiumSubtitle,
          fontSize: 15.sp,
          color: AppColors.white70,
        ),
        24.verticalSpace,
        Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.primary, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                AppStrings.adsFreePro,
                fontSize: 28.sp,
                fontFamily: AppStrings.interBold,
                color: context.textPrimary,
              ),
              8.verticalSpace,
              CustomText(
                '₹ 99${AppStrings.perYear}',
                fontSize: 20.sp,
                color: context.textSecondary,
              ),
              16.verticalSpace,
              CustomText(
                AppStrings.cancellationPolicy,
                fontSize: 14.sp,
                color: AppColors.white70,
              ),
              18.verticalSpace,
              _featureRow(AppStrings.featureZeroAds),
              _featureRow(AppStrings.featurePriorityStream),
              _featureRow(AppStrings.featureDedicatedSupport),
              _featureRow(AppStrings.featureOfflineDownloads),
              24.verticalSpace,
              FocusTraversalOrder(
                order: const NumericFocusOrder(130),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _paying ? null : _upgrade,
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 18.h),
                      backgroundColor: AppColors.primary,
                    ),
                    child: _paying
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : CustomText(
                            AppStrings.upgradeButtonText,
                            fontSize: 15.sp,
                            color: AppColors.white,
                            fontFamily: AppStrings.interBold,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureRow(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Row(
        children: [
          Icon(Icons.verified_rounded, color: AppColors.secondary, size: 18.sp),
          8.horizontalSpace,
          Expanded(
            child: CustomText(
              text,
              fontSize: 14.sp,
              color: AppColors.white,
              fontFamily: AppStrings.interMedium,
            ),
          ),
        ],
      ),
    );
  }
}
