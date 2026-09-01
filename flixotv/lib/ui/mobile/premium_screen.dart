import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/repositories/stripe_repository.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/services/stripe_payment_service.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  bool _isPaying = false;
  bool _isLoadingPlans = true;
  final List<StripePlan> _plans = <StripePlan>[];
  int _selectedPlanIndex = 0;

  StripePlan? get _selectedPlan =>
      _plans.isEmpty ? null : _plans[_selectedPlanIndex.clamp(0, _plans.length - 1)];

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _isLoadingPlans = true);
    try {
      final stripe = Get.find<StripePaymentService>();
      final plans = await stripe.fetchAllPlans();
      final activePlans = plans.where((p) => p.isActive).toList();
      activePlans.sort((a, b) {
        final orderA = _planOrder(a);
        final orderB = _planOrder(b);
        if (orderA != orderB) return orderA.compareTo(orderB);
        return a.price.compareTo(b.price);
      });
      if (!mounted) return;
      setState(() {
        _plans
          ..clear()
          ..addAll(activePlans);
        _selectedPlanIndex = 0;
      });
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        title: AppStrings.appName,
        message: 'Could not load subscription plans.',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoadingPlans = false);
    }
  }

  int _planOrder(StripePlan plan) {
    final name = plan.name.toLowerCase();
    final interval = plan.interval.toLowerCase();
    if (name.contains('basic')) return 0;
    if (interval == 'yearly' || interval == 'annual') return 1;
    return 2;
  }

  String _currencySymbol(String currency) {
    switch (currency.toLowerCase()) {
      case 'inr':
        return '₹';
      case 'usd':
        return '\$';
      case 'eur':
        return '€';
      default:
        return currency.toUpperCase();
    }
  }

  String _intervalLabel(String interval) {
    switch (interval.toLowerCase()) {
      case 'yearly':
      case 'annual':
        return 'year';
      case 'monthly':
        return 'month';
      default:
        return interval.toLowerCase();
    }
  }

  bool _isBasicPlan(StripePlan plan) =>
      plan.name.toLowerCase().contains('basic') || plan.price <= 0;

  String _headlineForPlan(StripePlan plan) {
    if (_isBasicPlan(plan)) return 'Live TV Starter';
    return 'Ads-Free Pro';
  }

  String _subLineForPlan(StripePlan plan) {
    if (_isBasicPlan(plan)) {
      return 'Start watching instantly with essential channels.';
    }
    return 'Premium experience for uninterrupted Live TV.';
  }

  String _footerForPlan(StripePlan plan) {
    if (plan.trialDays > 0) {
      return '${plan.trialDays}-day free trial included for new members.';
    }
    if (_isBasicPlan(plan)) {
      // return 'Upgrade anytime to unlock premium streaming benefits.';
      return '';
    }
    return '';
  }

  List<String> _featuresForPlan(StripePlan plan) {
    if (_isBasicPlan(plan)) {
      return const [
        'Access to essential live channels',
        'Standard streaming quality',
        'Quick channel switching',
        'Upgrade-ready profile and watch history',
      ];
    }
    return const [
      'Zero commercial interruptions',
      'Priority global high-speed streaming',
      'Premium sports and movie channels',
      '24/7 dedicated customer support',
      'Multi-device premium access',
    ];
  }

  Future<void> _onUpgradeTap() async {
    final selectedPlan = _selectedPlan;
    if (selectedPlan == null) return;
    if (_isPaying) return;
    setState(() => _isPaying = true);
    try {
      final stripe = Get.find<StripePaymentService>();
      final outcome = await stripe.checkoutPlan(selectedPlan);
      if (!mounted) return;
      switch (outcome) {
        case StripeCheckoutOutcome.success:
          try {
            await Get.find<AuthService>().syncPremiumFromServer();
          } catch (_) {}
          showAppToast(
            title: AppStrings.appName,
            message: AppStrings.premiumPaymentSuccess,
          );
          if (!mounted) return;
          Navigator.of(context).maybePop(true);
          return;
        case StripeCheckoutOutcome.cancelled:
          showAppToast(
            title: AppStrings.appName,
            message: AppStrings.premiumPaymentCancelled,
          );
          return;
        case StripeCheckoutOutcome.failed:
          showAppToast(
            title: AppStrings.appName,
            message: AppStrings.premiumPaymentFailed,
            isError: true,
          );
          return;
      }
    } finally {
      if (mounted) setState(() => _isPaying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeaderSection(context),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  children: [
                    30.verticalSpace,
                    _buildTitleSection(context),
                    24.verticalSpace,
                    _buildPlansCarousel(context),
                    24.verticalSpace,
                    _buildPremiumCard(context, _selectedPlan),
                    40.verticalSpace,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 15.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Get.back(),
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 32.w,
                  height: 32.w,
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: context.appIconColor,
                    size: 20.h,
                  ),
                ),
              ),
              10.horizontalSpace,
              CustomText(
                AppStrings.appName,
                fontFamily: AppStrings.interBold,
                fontSize: 20.sp,
                color: context.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ],
          ),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppColors.grey,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                Assets.images.inApp.defaultProfile.path,
                width: 40.w,
                height: 40.w,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.person, color: AppColors.white, size: 20.w);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection(BuildContext context) {
    return Column(
      children: [
        CustomText(
          AppStrings.pureEntertainment,
          fontSize: 36.sp,
          fontFamily: AppStrings.interExtraBold,
          color: context.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        15.verticalSpace,
        CustomText(
          AppStrings.premiumSubtitle,
          fontSize: 18.sp,
          fontFamily: AppStrings.interRegular,
          color: context.textSecondary,
          textAlign: TextAlign.center,
          height: 1.5,
        ),
      ],
    );
  }

  Widget _buildPlansCarousel(BuildContext context) {
    if (_isLoadingPlans) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_plans.isEmpty) {
      return Column(
        children: [
          CustomText(
            'No plans available right now',
            fontSize: 15.sp,
            fontFamily: AppStrings.interSemiBold,
            color: context.textSecondary,
          ),
          12.verticalSpace,
          OutlinedButton(
            onPressed: _loadPlans,
            child: const CustomText('Retry', maxLines: 1),
          ),
        ],
      );
    }
    return Column(
      children: [
        CarouselSlider.builder(
          itemCount: _plans.length,
          itemBuilder: (_, index, __) {
            final plan = _plans[index];
            final selected = index == _selectedPlanIndex;
            return _buildPlanCarouselCard(context, plan, selected);
          },
          options: CarouselOptions(
            height: 185.h,
            viewportFraction: 0.86,
            enlargeCenterPage: true,
            enableInfiniteScroll: _plans.length > 1,
            onPageChanged: (index, _) {
              setState(() => _selectedPlanIndex = index);
            },
          ),
        ),
        10.verticalSpace,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_plans.length, (index) {
            final selected = index == _selectedPlanIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: EdgeInsets.symmetric(horizontal: 4.w),
              width: selected ? 18.w : 7.w,
              height: 7.h,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : context.dividerColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildPlanCarouselCard(
    BuildContext context,
    StripePlan plan,
    bool selected,
  ) {
    final symbol = _currencySymbol(plan.currency);
    final perText = _intervalLabel(plan.interval);
    final gradientColors = selected
        ? AppColors.primaryGradient
        : <Color>[context.cardBg, context.cardBg];
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        color: selected ? null : context.cardBg,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: selected ? AppColors.transparent : context.cardBorderColor,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: selected ? 0.16 : 0.07),
            blurRadius: selected ? 16 : 8,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            plan.name,
            fontSize: 18.sp,
            fontFamily: AppStrings.interBold,
            color: selected ? AppColors.white : context.textPrimary,
          ),
          6.verticalSpace,
          CustomText(
            plan.description.isEmpty ? '${plan.name} Plan' : plan.description,
            maxLines: 2,
            fontSize: 12.sp,
            fontFamily: AppStrings.interRegular,
            color: selected
                ? AppColors.white.withValues(alpha: 0.9)
                : context.textSecondary,
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CustomText(
                '$symbol ${plan.price.round()}',
                fontSize: 30.sp,
                fontFamily: AppStrings.interExtraBold,
                color: selected ? AppColors.white : context.textPrimary,
              ),
              Padding(
                padding: EdgeInsets.only(left: 6.w, bottom: 6.h),
                child: CustomText(
                  '/$perText',
                  fontSize: 13.sp,
                  fontFamily: AppStrings.interMedium,
                  color: selected
                      ? AppColors.white.withValues(alpha: 0.95)
                      : context.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, StripePlan? plan) {
    if (plan == null) return const SizedBox.shrink();
    final symbol = _currencySymbol(plan.currency);
    final intervalText = _intervalLabel(plan.interval);
    final features = _featuresForPlan(plan);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardBg,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.55),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          if (plan.isPopular)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: AppColors.primaryGradient),
                    borderRadius: BorderRadius.only(
                      topRight: Radius.circular(23.r),
                      bottomLeft: Radius.circular(16.r),
                    ),
                  ),
                  child: CustomText(
                    AppStrings.mostPopular,
                    fontSize: 12.sp,
                    fontFamily: AppStrings.interBold,
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(22.w, plan.isPopular ? 8.h : 20.h, 22.w, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  '${plan.name} Plan',
                  fontSize: 14.sp,
                  fontFamily: AppStrings.interBold,
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                5.verticalSpace,
                CustomText(
                  _headlineForPlan(plan),
                  fontSize: 27.sp,
                  fontFamily: AppStrings.interBold,
                  color: context.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
                6.verticalSpace,
                CustomText(
                  _subLineForPlan(plan),
                  fontSize: 14.sp,
                  fontFamily: AppStrings.interRegular,
                  color: context.textSecondary,
                ),
                14.verticalSpace,
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$symbol ${plan.price.round()}',
                        style: TextStyle(
                          fontSize: 48.sp,
                          fontFamily: AppStrings.interBold,
                          color: context.textPrimary,
                        ),
                      ),
                      TextSpan(
                        text: ' /$intervalText',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontFamily: AppStrings.interRegular,
                          color: context.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                CustomText(
                  'What\'s included',
                  fontSize: 15.sp,
                  fontFamily: AppStrings.interBold,
                  color: context.textPrimary,
                ),
                18.verticalSpace,
                for (final feature in features) _buildFeatureItem(context, feature),
                20.verticalSpace,
                GestureDetector(
                  onTap: _isPaying ? null : _onUpgradeTap,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        height: 64.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20.r),
                          gradient: LinearGradient(
                            colors: AppColors.primaryGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.linkBlue.withValues(alpha: 0.22),
                              blurRadius: 20,
                              spreadRadius: 0.5,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Center(
                          child: CustomText(
                            plan.price <= 0
                                ? 'Continue with ${plan.name}'
                                : 'Choose ${plan.name}',
                            fontSize: 16.sp,
                            fontFamily: AppStrings.interBold,
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (_isPaying)
                        Positioned.fill(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.black.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: SizedBox(
                              width: 28.w,
                              height: 28.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (_footerForPlan(plan).isNotEmpty) ...[
                  18.verticalSpace,
                  Center(
                    child: CustomText(
                      _footerForPlan(plan),
                      fontSize: 13.sp,
                      fontFamily: AppStrings.interRegular,
                      color: context.textSecondary,
                    ),
                  ),
                ],
                22.verticalSpace,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, String feature) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20.w,
            height: 20.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: AppColors.primaryGradient),
            ),
            child: Icon(
              Icons.verified_rounded,
              size: 12.r,
              color: AppColors.white,
            ),
          ),
          10.horizontalSpace,
          Expanded(
            child: CustomText(
              feature,
              fontSize: 14.sp,
              fontFamily: AppStrings.interSemiBold,
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
