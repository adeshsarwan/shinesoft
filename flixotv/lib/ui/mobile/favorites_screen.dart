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

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late IptvController controller = Get.find<IptvController>();
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  String _selectedCategory = AppStrings.all;
  static const int _adInterval = 8;
  static const double _listHorizontalPadding = 12;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    controller.applyFavoritesFilters(
      categoryId: _selectedCategory,
      query: _searchController.text,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    unawaited(controller.loadMoreFavorites());
  }

  void _syncFavoritesFilters() {
    controller.applyFavoritesFilters(
      categoryId: _selectedCategory,
      query: _searchController.text,
    );
  }

  Widget _buildCategoryChips({
    required IptvController controller,
  }) {
    return Obx(() {
      final channelCategories = controller.categoryIds;
      if (!channelCategories.contains(_selectedCategory)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _selectedCategory = AppStrings.all);
          _syncFavoritesFilters();
        });
      }
      return SizedBox(
        height: 50.h,
        width: double.infinity,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: channelCategories.length,
          padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 7.h),
          itemBuilder: (_, i) {
            final categoryId = channelCategories[i];
            final isSelected = _selectedCategory == categoryId;
            return InkWell(
              onTap: () {
                if (!mounted) return;
                setState(() {
                  _selectedCategory = categoryId;
                });
                _syncFavoritesFilters();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          12.verticalSpace,
          _buildSearchBar(controller),
          _buildCategoryChips(controller: controller),
          if (AdsVariable.shouldShowAds) ...[
            8.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: _listHorizontalPadding.w),
              child: const BannerAdWidget(),
            ),
          ],
          12.verticalSpace,
          Expanded(
            child: Obx(() {
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

              controller.favoriteChannels.length;
              final allFavorites = controller.getFavoriteChannels();
              final visibleFavorites =
                  controller.favoritesVisibleChannels.toList();

              if (visibleFavorites.isEmpty &&
                  !controller.isFavoritesPaginationLoading.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.favorite_border,
                        size: 64.w,
                        color: AppColors.textMuted,
                      ),
                      16.verticalSpace,
                      CustomText(
                        allFavorites.isEmpty
                            ? 'No favorites yet'
                            : 'No favorites found',
                        fontSize: 16.sp,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                );
              }

              final showAds = AdsVariable.shouldShowAds;
              final adSlots =
                  showAds ? visibleFavorites.length ~/ _adInterval : 0;
              final hasFooter = controller.favoritesHasMore ||
                  controller.isFavoritesPaginationLoading.value;

              return ListView.builder(
                controller: _scrollController,
                padding:
                    EdgeInsets.symmetric(horizontal: _listHorizontalPadding.w),
                itemCount: visibleFavorites.length + adSlots + (hasFooter ? 1 : 0),
                itemBuilder: (context, index) {
                  final listEnd = visibleFavorites.length + adSlots;
                  if (hasFooter && index == listEnd) {
                    if (controller.isFavoritesPaginationLoading.value) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.h),
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
                    }
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
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

                  if (AdListUtils.isListAdSlot(index, _adInterval)) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 6.h),
                      child: const NativeAdWidget(),
                    );
                  }

                  final favorite = visibleFavorites[
                      AdListUtils.contentIndexForListIndex(index, _adInterval)];
                  return _buildFavoriteCard(favorite);
                },
              );
            }),
          ),
        ],
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
              style: TextStyle(fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: AppStrings.searchChannels,
                hintStyle: TextStyle(
                  color: context.textSecondary.withValues(alpha: 0.5),
                  fontSize: 14.sp,
                  fontFamily: AppStrings.interRegular,
                ),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
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
        ],
      ),
    );
  }

  void _performSearch(String query) {
    _syncFavoritesFilters();
    setState(() {});
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 4.h),
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
    );
  }

  Widget _buildFavoriteCard(IptvChannel channel) {
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      8.horizontalSpace,
                      _buildLiveBadge(),
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
            12.horizontalSpace,
            Obx(() {
              final isFav = controller.isFavoriteChannel(channel);
              return GestureDetector(
                onTap: () {
                  controller.toggleFavoriteChannel(channel);
                  _syncFavoritesFilters();
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
