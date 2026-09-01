import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/ad_list_utils.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/ads/banner_ad_widget.dart';
import 'package:iptv_demo/ads/native_ad_widget.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/ui/mobile/video_player_screen.dart';
import 'package:iptv_demo/widgets/home_channel_now_strip.dart';
import 'package:shimmer/shimmer.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  static const double _categoryChipSpacing = 12;
  static const double _categoryChipHorizontalPadding = 18;
  static const double _categoryListHorizontalPadding = 18;
  static const int _channelAdInterval = 8;
  static const int _sectionAdInterval = 2;
  final Map<String, GlobalKey> _categoryChipKeys = <String, GlobalKey>{};

  void _focusCategoryOnHome(IptvController controller, String categoryId) {
    final normalizedCategory = categoryId.trim().toLowerCase();
    controller.pendingHomeCategoryCenterId = normalizedCategory;
    controller.selectCategory(normalizedCategory);
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: AppColors.liveBadgeBackground,
        borderRadius: BorderRadius.circular(4.r),
      ),
      child: CustomText(
        AppStrings.live,
        color: AppColors.liveBadgeText,
        fontSize: 10.sp,
        fontWeight: FontWeight.w700,
        fontFamily: AppStrings.interBold,
      ),
    );
  }

  List<String> _orderedHomeSectionTitles(
    Map<String, List<IptvChannel>> categories,
  ) {
    final preferred = ['Movies', 'Sports', 'News', 'Science', 'Entertainment'];
    final keys = categories.keys
        .where((key) => key != 'All' && (categories[key]?.isNotEmpty ?? false))
        .toList();
    final ordered = <String>[];
    for (final title in preferred) {
      if (keys.contains(title)) ordered.add(title);
    }
    final remaining = keys.where((k) => !ordered.contains(k)).toList()..sort();
    ordered.addAll(remaining);
    return ordered;
  }

  List<Widget> _buildAllCategorySections(
    BuildContext context,
    IptvController controller,
    Map<String, List<IptvChannel>> categories,
  ) {
    final sectionTitles = _orderedHomeSectionTitles(categories);
    if (sectionTitles.isEmpty) return const [SizedBox()];

    return [
      for (var i = 0; i < sectionTitles.length; i++) ...[
        _buildSection(
          context,
          sectionTitles[i],
          categories[sectionTitles[i]] ?? [],
          controller,
        ),
        if (AdsVariable.shouldShowAds &&
            i != sectionTitles.length - 1 &&
            (i + 1) % _sectionAdInterval == 0)
          _buildInlineNativeAd(horizontal: 12),
        if (i != sectionTitles.length - 1) SizedBox(height: 14.h),
      ],
      20.verticalSpace,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IptvController>();

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Obx(() {
        // Rebuild lists when premium / auth status changes (hide ad slots).
        if (Get.isRegistered<AuthService>()) {
          final auth = Get.find<AuthService>();
          auth.isPremiumUser.value;
          auth.isLoggedIn.value;
          auth.currentProfile.value;
          AdsVariable.isPurchased.value;
          auth.hasAdFreeAccess;
        } else {
          AdsVariable.isPurchased.value;
        }

        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = controller.selectedCategory.value.toLowerCase() ==
                AppStrings.all.toLowerCase()
            ? controller.getHomeDisplayChannels(controller.filteredChannels)
            : controller.categorizedChannels(controller.filteredChannels);
        final hasAnyChannels = controller.allChannels.isNotEmpty;
        final hasVisible = controller.filteredChannels.isNotEmpty;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            12.verticalSpace,
            _buildCategoryChips(
              context: context,
              controller: controller,
            ),
            if (AdsVariable.shouldShowAds) ...[
              8.verticalSpace,
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: const BannerAdWidget(),
              ),
            ],
            10.verticalSpace,
            Expanded(
              child: !hasAnyChannels
                  ? _buildFetchEmptyState(context, controller)
                  : !hasVisible
                      ? _buildNoMatchState(context, controller)
                      : SingleChildScrollView(
                          controller: controller.scrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: controller.selectedCategory.value
                                        .toLowerCase() ==
                                    AppStrings.all.toLowerCase()
                                ? _buildAllCategorySections(
                                    context,
                                    controller,
                                    categories,
                                  )
                                : [
                                    _buildSingleCategorySortedSection(
                                      context,
                                      controller,
                                    ),
                                    20.verticalSpace,
                                  ],
                          ),
                        ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildFetchEmptyState(
      BuildContext context, IptvController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.tv_off_rounded,
                      size: 64.r,
                      color: context.textSecondary.withValues(alpha: 0.45),
                    ),
                    20.verticalSpace,
                    CustomText(
                      'No channels available',
                      textAlign: TextAlign.center,
                      fontSize: 18.sp,
                      fontFamily: AppStrings.interBold,
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    10.verticalSpace,
                    CustomText(
                      'No channels were found. Check your playlist or internet connection, then try again.',
                      textAlign: TextAlign.center,
                      fontSize: 14.sp,
                      fontFamily: AppStrings.interRegular,
                      color: context.textSecondary,
                    ),
                    24.verticalSpace,
                    FilledButton(
                      onPressed: () => controller.fetchChannels(),
                      style: FilledButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 28.w,
                          vertical: 14.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: CustomText(
                        'Retry',
                        fontSize: 15.sp,
                        fontFamily: AppStrings.interSemiBold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoMatchState(BuildContext context, IptvController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off_rounded,
                      size: 64.r,
                      color: context.textSecondary.withValues(alpha: 0.45),
                    ),
                    20.verticalSpace,
                    CustomText(
                      'No channels match',
                      textAlign: TextAlign.center,
                      fontSize: 18.sp,
                      fontFamily: AppStrings.interBold,
                      color: context.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                    10.verticalSpace,
                    CustomText(
                      AppStrings.noChannelsMatchHint,
                      textAlign: TextAlign.center,
                      fontSize: 14.sp,
                      fontFamily: AppStrings.interRegular,
                      color: context.textSecondary,
                    ),
                    20.verticalSpace,
                    OutlinedButton(
                      onPressed: () => controller.resetHomeBrowseFilters(),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: CustomText(
                        AppStrings.resetBrowseFilters,
                        fontSize: 15.sp,
                        fontFamily: AppStrings.interSemiBold,
                        color: AppColors.primary,
                      ),
                    ),
                    12.verticalSpace,
                    TextButton(
                      onPressed: () {
                        controller.selectedIndex.value = 3;
                      },
                      child: CustomText(
                        AppStrings.goToSettings,
                        fontSize: 15.sp,
                        fontFamily: AppStrings.interSemiBold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryChips({
    required BuildContext context,
    required IptvController controller,
  }) {
    return Obx(() {
      final channelCategories = controller.categoryIds;
      for (final id in channelCategories) { 
        _categoryChipKeys.putIfAbsent(id, () => GlobalKey());
      }

      double trailingCenterInset() {
        if (channelCategories.isEmpty) return 0;
        final viewportWidth = MediaQuery.sizeOf(context).width;
        final lastId = channelCategories.last;
        final lastCtx = _categoryChipKeys[lastId]?.currentContext;
        final box = lastCtx?.findRenderObject();
        final lastChipWidth = box is RenderBox
            ? box.size.width
            : (140.w + _categoryChipSpacing.w);

        // Minimal spacer required so the last chip can reach center.
        final inset = (viewportWidth / 2) -
            (lastChipWidth / 2) -
            _categoryListHorizontalPadding.w;
        return inset.clamp(24.0, 96.0);
      }

      void ensureCategoryVisible(String categoryId) {
        final chipContext = _categoryChipKeys[categoryId]?.currentContext;
        if (chipContext == null) return;
        Scrollable.ensureVisible(
          chipContext,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          alignment: 0.5,
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final pendingCenterId = controller.pendingHomeCategoryCenterId;
        if (pendingCenterId.isNotEmpty) {
          controller.pendingHomeCategoryCenterId = '';
          controller.lastHomeCategoryAutoScroll =
              controller.selectedCategory.value;
          ensureCategoryVisible(pendingCenterId);
          return;
        }

        final selectedCategoryId = controller.selectedCategory.value;
        if (controller.lastHomeCategoryAutoScroll.isEmpty) {
          // Keep initial layout compact; center only after explicit user action.
          controller.lastHomeCategoryAutoScroll = selectedCategoryId;
          return;
        }
        if (selectedCategoryId != controller.lastHomeCategoryAutoScroll) {
          controller.lastHomeCategoryAutoScroll = selectedCategoryId;
          ensureCategoryVisible(selectedCategoryId);
        }
      });
      return SizedBox(
        height: 58.h,
        width: double.infinity,
        child: SingleChildScrollView(
          controller: controller.homeCategoryScrollController,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: _categoryListHorizontalPadding.w,
            vertical: 5.h,
          ),
          child: Row(
            children: [
              for (final categoryId in channelCategories)
                Builder(
                  builder: (_) {
                    final isSelected =
                        controller.selectedCategory.value == categoryId;
                    return InkWell(
                      onTap: () {
                        if (!isSelected) {
                          controller.selectCategory(categoryId);
                        }
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ensureCategoryVisible(categoryId);
                        });
                      },
                      child: Padding(
                        key: _categoryChipKeys[categoryId],
                        padding: EdgeInsets.symmetric(vertical: 2.h),
                        child: Container(
                          margin:
                              EdgeInsets.only(right: _categoryChipSpacing.w),
                          padding: EdgeInsets.symmetric(
                            horizontal: _categoryChipHorizontalPadding.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: AppColors.primaryGradient)
                                : null,
                            color: isSelected ? null : context.chipUnselectedBg,
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          alignment: Alignment.center,
                          child: CustomText(
                            controller.categoryLabel(categoryId),
                            color: isSelected
                                ? AppColors.white
                                : context.textPrimary,
                            fontFamily: AppStrings.interSemiBold,
                            fontSize: 16.sp,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(width: trailingCenterInset()),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSingleCategorySortedSection(
    BuildContext context,
    IptvController controller,
  ) {
    final pagedSorted =
        controller.channelsSortedByTitle(controller.visibleChannels.toList());
    if (pagedSorted.isEmpty) return const SizedBox();
    final showAds = AdsVariable.shouldShowAds;
    final adSlots = showAds ? pagedSorted.length ~/ _channelAdInterval : 0;
    final listItemsCount = pagedSorted.length + adSlots;

    final title = controller.categoryLabel(controller.selectedCategory.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: CustomText(
            title,
            fontSize: 20.sp,
            fontFamily: AppStrings.interExtraBold,
            fontWeight: FontWeight.w800,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          itemCount: listItemsCount + 1,
          itemBuilder: (_, i) {
            if (i == listItemsCount) {
              return Obx(() {
                if (controller.isPaginationLoading.value) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                if (controller.hasMoreVisibleChannels) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: 6.h),
                    child: Center(
                      child: CustomText(
                        'Scroll to load more',
                        color: context.textSecondary,
                        fontSize: 12.sp,
                        fontFamily: AppStrings.interRegular,
                        maxLines: 1,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              });
            }
            if (AdListUtils.isListAdSlot(i, _channelAdInterval)) {
              return _buildInlineNativeAd(horizontal: 0);
            }
            final channelIndex =
                AdListUtils.contentIndexForListIndex(i, _channelAdInterval);
            return _buildFocusedCategoryListCard(
              controller: controller,
              channel: pagedSorted[channelIndex],
            );
          },
        ),
      ],
    );
  }

  Widget _buildFocusedCategoryListCard({
    required IptvController controller,
    required IptvChannel channel,
  }) {
    final ctx = Get.context!;
    return GestureDetector(
      onTap: () {
        openChannelPlayer(channel);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: ctx.cardBg,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                color: ctx.inputFill,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: controller.validUrl(channel.logo),
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) =>
                      Icon(Icons.tv, color: ctx.textMuted),
                ),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: CustomText(
                          channel.titleWithLanguage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          fontSize: 16.sp,
                          fontFamily: AppStrings.interBold,
                          color: ctx.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      8.horizontalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6.w, vertical: 2.h),
                        decoration: BoxDecoration(
                          color: AppColors.liveBadgeBackground,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: CustomText(
                          AppStrings.live,
                          color: AppColors.liveBadgeText,
                          fontSize: 12.sp,
                          fontFamily: AppStrings.interBold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  4.verticalSpace,
                  CustomText(
                    controller.getSubtitle(channel),
                    fontSize: 14.sp,
                    color: ctx.textSecondary,
                    fontFamily: AppStrings.interRegular,
                    fontWeight: FontWeight.w500,
                  ),
                  HomeChannelNowStrip(
                    channel: channel,
                    controller: controller,
                    compact: true,
                  ),
                ],
              ),
            ),
            10.horizontalSpace,
            Obx(() {
              final isFav = controller.isFavoriteChannel(channel);
              return GestureDetector(
                onTap: () => controller.toggleFavoriteChannel(channel),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav
                      ? AppColors.heart
                      : ctx.textSecondary.withValues(alpha: 0.4),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<IptvChannel> list,
    IptvController controller,
  ) {
    if (list.isEmpty) return const SizedBox();

    if (title == AppStrings.news) {
      return _buildNewsSection(context, title, list, controller);
    }

    final filteredChannels = list;

    final screenH = MediaQuery.sizeOf(context).height;
    final rowHeight = (screenH * 0.34).clamp(240.h, 360.h);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                title,
                fontSize: 20.sp,
                fontFamily: AppStrings.interExtraBold,
                fontWeight: FontWeight.w800,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _focusCategoryOnHome(controller, title),
                child: Row(
                  children: [
                    CustomText(
                      AppStrings.viewAll,
                      color: AppColors.linkBlue,
                      fontSize: 14.sp,
                      fontFamily: AppStrings.interBold,
                      fontWeight: FontWeight.bold,
                    ),
                    4.horizontalSpace,
                    Image.asset(
                      Assets.images.rightArrow.path,
                      width: 10.w,
                      height: 10.h,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: rowHeight + 8.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.only(left: 12.w, right: 12.w),
            itemCount: filteredChannels.length,
            itemBuilder: (_, i) =>
                _buildHorizontalCard(context, controller, filteredChannels[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildNewsSection(
    BuildContext context,
    String title,
    List<IptvChannel> list,
    IptvController controller,
  ) {
    final filteredChannels = list;
    final showAds = AdsVariable.shouldShowAds;
    final adSlots = showAds ? filteredChannels.length ~/ _channelAdInterval : 0;
    final listItemsCount = filteredChannels.length + adSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(context, title, controller),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: listItemsCount,
          itemBuilder: (_, i) {
            if (AdListUtils.isListAdSlot(i, _channelAdInterval)) {
              return _buildInlineNativeAd(horizontal: 12);
            }
            final channelIndex =
                AdListUtils.contentIndexForListIndex(i, _channelAdInterval);
            return _buildNewsCard(
                context, filteredChannels[channelIndex], controller);
          },
        ),
      ],
    );
  }

  Widget _buildInlineNativeAd({required double horizontal}) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontal.w, vertical: 6.h),
      child: const NativeAdWidget(),
    );
  }

  Widget _buildNewsCard(
    BuildContext context,
    IptvChannel channel,
    IptvController controller,
  ) {
    return Obx(() {
      final isFav = controller.isFavoriteChannel(channel);

      return GestureDetector(
        onTap: () {
          openChannelPlayer(channel);
        },
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            color: Get.context!.cardBg,
            borderRadius: BorderRadius.circular(18.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 55.h,
                width: 55.w,
                padding: EdgeInsets.all(8.h),
                decoration: BoxDecoration(
                  color: Get.context!.subtleTint,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: CachedNetworkImage(
                  imageUrl: controller.validUrl(channel.logo),
                  fit: BoxFit.contain,
                  placeholder: (_, __) => Shimmer.fromColors(
                    baseColor: AppColors.grey300,
                    highlightColor: AppColors.base,
                    child: Container(color: Get.context!.cardBg),
                  ),
                  errorWidget: (_, __, ___) => Icon(Icons.image, size: 30.h),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: CustomText(
                            channel.titleWithLanguage,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            fontSize: 16.sp,
                            fontFamily: AppStrings.interBold,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: Get.context!.chipUnselectedBg,
                            borderRadius: BorderRadius.circular(4.r),
                          ),
                          child: CustomText(
                            controller.getQuality(channel),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: AppStrings.interRegular,
                            color: Get.context!.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    4.verticalSpace,
                    CustomText(
                      controller.getSubtitle(channel),
                      fontSize: 14.sp,
                      color: context.textSecondary,
                      fontFamily: AppStrings.interRegular,
                      fontWeight: FontWeight.w500,
                    ),
                    HomeChannelNowStrip(
                      channel: channel,
                      controller: controller,
                      compact: true,
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              10.horizontalSpace,
              GestureDetector(
                onTap: () => controller.toggleFavoriteChannel(channel),
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav
                      ? AppColors.heart
                      : Get.context!.textSecondary.withValues(alpha: 0.4),
                  size: 25.h,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _sectionHeader(
    BuildContext context,
    String title,
    IptvController controller,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(
            title,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            fontFamily: AppStrings.interExtraBold,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => _focusCategoryOnHome(controller, title),
            child: Row(
              children: [
                CustomText(
                  AppStrings.viewAll,
                  color: AppColors.linkBlue,
                  fontSize: 14.sp,
                  fontFamily: AppStrings.interBold,
                  fontWeight: FontWeight.bold,
                ),
                4.horizontalSpace,
                Image.asset(
                  Assets.images.rightArrow.path,
                  width: 10.w,
                  height: 10.h,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _horizontalCardWidth(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return (w * 0.66).clamp(300.w, 400.w);
  }

  Widget _buildHorizontalCard(
    BuildContext context,
    IptvController controller,
    IptvChannel channel,
  ) {
    return GestureDetector(
      onTap: () {
        openChannelPlayer(channel);
      },
      child: Container(
        width: _horizontalCardWidth(context),
        margin: EdgeInsets.only(right: 12.w),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(15.r),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.05),
              blurRadius: 8.r,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15.r),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(15.r),
                      ),
                      child: Container(
                        color: context.subtleTint,
                        padding: EdgeInsets.all(16.r),
                        child: ClipRRect(
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: context.cardBg,
                            alignment: Alignment.center,
                            child: CachedNetworkImage(
                              imageUrl: controller.validUrl(channel.logo),
                              fit: BoxFit.contain,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: context.chipUnselectedBg,
                                highlightColor: context.subtleTint,
                                child: Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: context.cardBg,
                                ),
                              ),
                              errorWidget: (context, url, error) => Icon(
                                Icons.broken_image,
                                color: AppColors.grey,
                                size: 40.r,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.r),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          channel.titleWithLanguage,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          fontWeight: FontWeight.w700,
                          fontSize: 14.sp,
                          fontFamily: AppStrings.interBold,
                        ),
                        4.verticalSpace,
                        CustomText(
                          controller.getSubtitle(channel),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          fontSize: 12.sp,
                          color: context.textSecondary,
                          fontFamily: AppStrings.interRegular,
                        ),
                        HomeChannelNowStrip(
                          channel: channel,
                          controller: controller,
                          compact: true,
                        ),
                      ],
                    ),
                  ),
                  // Padding(
                  //   padding: EdgeInsets.symmetric(horizontal: 8.w),
                  //   child: CustomText(
                  //     AppStrings.featuredContent,
                  //     color: context.textMuted,
                  //     fontSize: 12.sp,
                  //     fontFamily: AppStrings.interRegular,
                  //     fontWeight: FontWeight.w500,
                  //   ),
                  // ),
                  SizedBox(height: 12.h),
                ],
              ),
              Positioned(
                top: 8.h,
                right: 8.w,
                child: _buildLiveBadge(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
