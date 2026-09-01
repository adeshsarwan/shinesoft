import 'dart:async';

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
import 'package:cached_network_image/cached_network_image.dart';
import 'package:iptv_demo/ui/mobile/video_player_screen.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final IptvController controller;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  String _selectedCategory = AppStrings.all;
  static const int _adInterval = 8;
  static const double _listHorizontalPadding = 12;

  @override
  void initState() {
    super.initState();
    controller = Get.find<IptvController>();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    unawaited(_loadCategory(_selectedCategory));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategory(String categoryId) async {
    await controller.loadSearchChannelsForCategory(categoryId);
    if (!mounted) return;
    controller.applySearchFilters(
      categoryId: categoryId,
      query: _searchController.text,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    unawaited(controller.loadMoreSearch());
  }

  void _syncSearchFilters() {
    controller.applySearchFilters(
      categoryId: _selectedCategory,
      query: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        body: Column(
          children: [
            const SizedBox(height: 10),
            _buildSearchBar(controller),
            _buildCategoryChips(controller: controller),
            if (AdsVariable.shouldShowAds) ...[
              8.verticalSpace,
              Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: _listHorizontalPadding.w),
                child: const BannerAdWidget(),
              ),
            ],
            12.verticalSpace,
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(IptvController controller) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                if (!mounted) return;
                _performSearch(value);
              },
              decoration: InputDecoration(
                hintText: AppStrings.searchChannels,
                hintStyle: TextStyle(
                  color: context.textSecondary.withValues(alpha: 0.5),
                  fontSize: 14.sp,
                  fontFamily: AppStrings.interRegular,
                ),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                prefixIcon: Padding(
                  padding: EdgeInsets.only(
                    left: 15.w,
                    right: 6.w,
                  ),
                  child: Image.asset(Assets.images.searchGradientIcon.path),
                ),
                prefixIconConstraints: BoxConstraints(
                  maxHeight: 30.h,
                  maxWidth: 40.w,
                ),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                        icon: Icon(
                          Icons.close_rounded,
                          color: context.textSecondary.withValues(alpha: 0.7),
                          size: 20.w,
                        ),
                      ),
                filled: true,
                fillColor: context.searchFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          // 10.horizontalSpace,
          // Container(
          //   height: 46.h,
          //   width: 48.w,
          //   alignment: Alignment.center,
          //   decoration: BoxDecoration(
          //     gradient: const LinearGradient(colors: AppColors.primaryGradient),
          //     borderRadius: BorderRadius.circular(12.r),
          //   ),
          //   child: Icon(Icons.add, color: AppColors.white, size: 24.r),
          // ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    _syncSearchFilters();
    setState(() {});
  }

  bool _matchesSearch(IptvChannel channel, String query) {
    if (query.isEmpty) return true;
    final title = channel.title.toLowerCase();
    final group = channel.group.toLowerCase();
    final country = channel.country.toLowerCase();
    return title.contains(query) ||
        group.contains(query) ||
        country.contains(query);
  }

  Widget _buildCategoryChips({
    required IptvController controller,
  }) {
    return Obx(() {
      final categories = controller.categoryIds;
      return SizedBox(
        height: 50.h,
        width: double.infinity,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 7.h),
          itemBuilder: (_, i) {
            final categoryId = categories[i];
            final isSelected = _selectedCategory == categoryId;
            return InkWell(
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _selectedCategory = categoryId;
                });
                unawaited(_loadCategory(categoryId));
              },
              child: Container(
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: AppColors.primaryGradient)
                      : null,
                  color: isSelected ? null : context.chipUnselectedBg,
                  borderRadius: BorderRadius.circular(25.r),
                ),
                alignment: Alignment.center,
                child: CustomText(
                  controller.categoryLabel(categoryId),
                  color: isSelected ? AppColors.white : context.textPrimary,
                  fontFamily: AppStrings.interSemiBold,
                  fontSize: 16.sp,
                ),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildSearchResults() {
    return Obx(() {
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

      if (controller.isSearchCatalogLoading.value &&
          controller.searchFilteredChannels.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final query = _searchController.text.trim().toLowerCase();
      final isAllCategory =
          _selectedCategory.toLowerCase() == AppStrings.all.toLowerCase();
      final results = controller.searchFilteredChannels.toList();
      final resultKeys =
          results.map((c) => c.channelFeedListDedupeKey).toSet();
      final favoriteResults = controller
          .getFavoriteChannels()
          .where((channel) => _matchesSearch(channel, query))
          .where(
            (channel) => !resultKeys.contains(channel.channelFeedListDedupeKey),
          )
          .toList();

      if (results.isEmpty &&
          !controller.isSearchPaginationLoading.value &&
          !controller.searchHasMore &&
          (!isAllCategory || favoriteResults.isEmpty)) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search_off, size: 48.w, color: context.textMuted),
              12.verticalSpace,
              CustomText(
                'No channels found',
                fontSize: 16.sp,
                color: context.textMuted,
                fontFamily: AppStrings.interMedium,
              ),
            ],
          ),
        );
      }

      return SingleChildScrollView(
        controller: _scrollController,
        padding: EdgeInsets.symmetric(horizontal: _listHorizontalPadding.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isAllCategory)
              ..._buildGroupedCategorySections(results)
            else
              _buildResultsSection(
                title:
                    controller.categoryLabel(_selectedCategory).toUpperCase(),
                channels: results,
              ),
            if (isAllCategory && favoriteResults.isNotEmpty) ...[
              16.verticalSpace,
              _buildResultsSection(
                title: 'YOUR FAVORITES',
                channels: favoriteResults,
              ),
            ],
            _buildSearchPaginationFooter(),
            const SizedBox(height: 25),
          ],
        ),
      );
    });
  }

  Widget _buildResultsSection({
    required String title,
    required List<IptvChannel> channels,
  }) {
    final showAds = AdsVariable.shouldShowAds;
    final adSlots = showAds ? channels.length ~/ _adInterval : 0;
    final listItemsCount = channels.length + adSlots;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          title,
          fontSize: 12.sp,
          fontFamily: AppStrings.interBold,
          color: context.textSecondary,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(height: 12.h),
        if (channels.isEmpty)
          CustomText(
            'No channels found',
            fontSize: 14.sp,
            color: context.textSecondary,
            fontFamily: AppStrings.interRegular,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listItemsCount,
            itemBuilder: (context, index) {
              if (AdListUtils.isListAdSlot(index, _adInterval)) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: const NativeAdWidget(),
                );
              }

              final channelIndex =
                  AdListUtils.contentIndexForListIndex(index, _adInterval);
              return _buildResultCard(channels[channelIndex]);
            },
          ),
      ],
    );
  }

  Widget _buildSearchPaginationFooter() {
    return Obx(() {
      if (controller.isSearchPaginationLoading.value) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          child: const Center(child: CircularProgressIndicator()),
        );
      }
      if (controller.searchHasMore) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Center(
            child: CustomText(
              'Scroll to load more',
              color: context.textSecondary,
              fontSize: 12.sp,
              fontFamily: AppStrings.interRegular,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    });
  }

  List<Widget> _buildGroupedCategorySections(List<IptvChannel> channels) {
    final grouped = controller.groupSearchChannelsByCategory(channels);
    if (grouped.isEmpty) {
      return [
        _buildResultsSection(
          title: 'SEARCH RESULTS',
          channels: const [],
        ),
      ];
    }

    final preferredOrder = controller.categoryIds
        .map((id) => controller.categoryLabel(id))
        .where((label) => label.toLowerCase() != AppStrings.all.toLowerCase())
        .toList();

    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        final ia = preferredOrder.indexOf(a);
        final ib = preferredOrder.indexOf(b);
        if (ia == -1 && ib == -1) return a.compareTo(b);
        if (ia == -1) return 1;
        if (ib == -1) return -1;
        return ia.compareTo(ib);
      });

    return [
      for (var i = 0; i < sortedKeys.length; i++) ...[
        if (i > 0) 16.verticalSpace,
        _buildResultsSection(
          title: sortedKeys[i].toUpperCase(),
          channels: grouped[sortedKeys[i]]!,
        ),
      ],
    ];
  }

  Widget _buildResultCard(IptvChannel channel) {
    return GestureDetector(
      onTap: () {
        openChannelPlayer(channel);
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: context.cardBg,
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
                color: context.inputFill,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: CachedNetworkImage(
                  imageUrl: controller.validUrl(channel.logo),
                  fit: BoxFit.contain,
                  errorWidget: (context, url, error) =>
                      Icon(Icons.tv, color: context.textMuted),
                ),
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
                          color: context.textPrimary,
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
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: AppStrings.interBold,
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
                  ),
                ],
              ),
            ),
            10.horizontalSpace,
            Obx(() {
              final isFav = controller.isFavoriteChannel(channel);
              return GestureDetector(
                onTap: () {
                  if (mounted) {
                    controller.toggleFavoriteChannel(channel);
                  }
                },
                child: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav
                      ? AppColors.heart
                      : context.textSecondary.withValues(alpha: 0.4),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
