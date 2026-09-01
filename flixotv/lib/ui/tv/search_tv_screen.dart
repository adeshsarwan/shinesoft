import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/ads/ad_list_utils.dart';
import 'package:iptv_demo/ads/adsVariable.dart';
import 'package:iptv_demo/ads/native_ad_widget.dart';
import 'package:iptv_demo/ads/tv_ad_policy.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/ui/tv/player_tv_screen.dart';
import 'package:iptv_demo/ui/tv/widgets/tv_card.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

/// TV search with D-pad / remote focus: search field → category chips → results
/// (channel row + favorite), same filtering behaviour as mobile [SearchScreen].
class SearchTvScreen extends StatefulWidget {
  const SearchTvScreen({super.key});

  @override
  State<SearchTvScreen> createState() => _SearchTvScreenState();
}

class _SearchTvScreenState extends State<SearchTvScreen> {
  static const int _adInterval = 8;
  late final IptvController controller;
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;
  late final FocusNode _searchFocusNode;
  final FocusNode _chipsRowFocusNode = FocusNode(debugLabel: 'tv_search_chip_row');
  final List<FocusNode> _chipFocusNodes = [];
  bool _chipsRowHasPrimaryFocus = false;
  bool _isTypingInSearch = false;
  bool _isSearchFieldFocused = false;
  Timer? _searchDebounce;
  String _searchQuery = '';
  String _selectedCategory = AppStrings.all;
  bool _isTv = false;

  static const double _kOrderSearch = 2;
  static const double _kOrderChipBase = 20;
  static const double _kOrderResultsBase = 100;
  static const double _kOrderFavoritesBase = 10000;

  @override
  void initState() {
    super.initState();
    controller = Get.find<IptvController>();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_onScroll);
    _searchFocusNode = FocusNode(debugLabel: 'tv_search_field');
    _searchFocusNode.addListener(() {
      if (!mounted) return;
      setState(() => _isSearchFieldFocused = _searchFocusNode.hasFocus);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
    });
    unawaited(
      TvAdPolicy.isTv.then((v) {
        if (mounted) setState(() => _isTv = v);
      }),
    );
    unawaited(_loadCategory(_selectedCategory));
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

  @override
  void dispose() {
    _scrollController.dispose();
    _searchDebounce?.cancel();
    _chipsRowFocusNode.dispose();
    for (final node in _chipFocusNodes) {
      node.dispose();
    }
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _syncChipFocusNodes(int count) {
    if (_chipFocusNodes.length == count) return;
    for (final node in _chipFocusNodes) {
      node.dispose();
    }
    _chipFocusNodes
      ..clear()
      ..addAll(
        List.generate(
          count,
          (i) => FocusNode(debugLabel: 'tv_search_chip_$i'),
        ),
      );
  }

  /// Scrolls the nearest [Scrollable] so the currently focused widget stays on screen.
  void _ensurePrimaryFocusVisible() {
    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null || !mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ctx.mounted) return;
      final ro = ctx.findRenderObject();
      if (ro == null) return;
      Scrollable.maybeOf(ctx)?.position.ensureVisible(
        ro,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.12,
      );
    });
  }

  void _openChannel(IptvChannel channel) {
    openChannelPlayerTv(channel);
  }

  void _showSoftKeyboard() {
    _isTypingInSearch = true;
    _searchFocusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  void _finishTyping() {
    _isTypingInSearch = false;
    _searchFocusNode.unfocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  void _onSearchChanged(String value) {
    _isTypingInSearch = true;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) return;
      final q = value.trim().toLowerCase();
      setState(() => _searchQuery = q);
      controller.applySearchFilters(
        categoryId: _selectedCategory,
        query: value,
      );
    });
  }

  bool _matchesSearch(IptvChannel channel, String query) {
    if (query.isEmpty) return true;
    final title = channel.title.toLowerCase();
    final group = channel.group.toLowerCase();
    final country = channel.country.toLowerCase();
    return title.contains(query) || group.contains(query) || country.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          children: [
            SizedBox(height: 10.h),
            _buildSearchBar(controller),
            _buildCategoryChips(controller: controller),
            10.verticalSpace,
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchResults(),
                    SizedBox(height: 25.h),
                  ],
                ),
              ),
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
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(_kOrderSearch),
              child: Focus(
                onFocusChange: (hasFocus) {
                  if (!hasFocus) return;
                  _ensurePrimaryFocusVisible();
                },
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  final key = event.logicalKey;
                  if (_isTypingInSearch) {
                    if (key == LogicalKeyboardKey.escape ||
                        key == LogicalKeyboardKey.goBack ||
                        key == LogicalKeyboardKey.browserBack) {
                      _finishTyping();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  }
                  if (key == LogicalKeyboardKey.arrowDown) {
                    _finishTyping();
                    if (_chipFocusNodes.isNotEmpty) {
                      _chipFocusNodes.first.requestFocus();
                    } else {
                      FocusScope.of(context).nextFocus();
                    }
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.select ||
                      key == LogicalKeyboardKey.enter) {
                    _showSoftKeyboard();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: false,
                  onTap: _showSoftKeyboard,
                  onTapOutside: (_) => _finishTyping(),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _finishTyping(),
                  onEditingComplete: _finishTyping,
                  onChanged: _onSearchChanged,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 15.sp,
                    fontFamily: AppStrings.interRegular,
                  ),
                  cursorColor: AppColors.primary,
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
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      borderSide: BorderSide(
                        color: _isSearchFieldFocused
                            ? AppColors.secondary
                            : context.borderColor.withValues(alpha: 0.3),
                        width: _isSearchFieldFocused ? 2 : 1,
                      ),
                    ),
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(left: 15.w, right: 6.w),
                      child: Image.asset(Assets.images.searchGradientIcon.path),
                    ),
                    prefixIconConstraints: BoxConstraints(
                      maxHeight: 32.h,
                      maxWidth: 44.w,
                    ),
                    filled: true,
                    fillColor: context.searchFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15.r),
                      borderSide: const BorderSide(
                        color: AppColors.secondary,
                        width: 2.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips({
    required IptvController controller,
  }) {
    return Obx(() {
      final categories = controller.categoryIds;
      _syncChipFocusNodes(categories.length);
      return SizedBox(
        height: 50.h,
        width: double.infinity,
        child: Focus(
          focusNode: _chipsRowFocusNode,
          onFocusChange: (hasFocus) {
            if (!hasFocus) {
              _chipsRowHasPrimaryFocus = false;
              return;
            }
            if (_chipsRowHasPrimaryFocus || _chipFocusNodes.isEmpty) return;
            _chipsRowHasPrimaryFocus = true;
            _chipFocusNodes.first.requestFocus();
          },
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 8.h),
            child: Row(
              children: [
                for (var i = 0; i < categories.length; i++)
                  FocusTraversalOrder(
                    order: NumericFocusOrder(_kOrderChipBase + i.toDouble()),
                    child: _TvSearchCategoryChip(
                      focusNode: _chipFocusNodes[i],
                      label: controller.categoryLabel(categories[i]),
                      selected: _selectedCategory == categories[i],
                      onSelected: () {
                        if (!mounted) return;
                        setState(() => _selectedCategory = categories[i]);
                        unawaited(_loadCategory(categories[i]));
                      },
                      onFocused: _ensurePrimaryFocusVisible,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildSearchResults() {
    return Obx(() {
      if (controller.isSearchCatalogLoading.value &&
          controller.searchFilteredChannels.isEmpty) {
        return SizedBox(
          height: 200.h,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          ),
        );
      }

      final query = _searchQuery;
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
        return SizedBox(
          height: 220.h,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48.w, color: context.textMuted),
                12.verticalSpace,
                CustomText(
                  AppStrings.noChannelsFound,
                  fontSize: 16.sp,
                  color: context.textMuted,
                  fontFamily: AppStrings.interMedium,
                ),
              ],
            ),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAllCategory)
            ..._buildGroupedCategorySections(results, _kOrderResultsBase)
          else
            _buildResultsSection(
              title: controller.categoryLabel(_selectedCategory).toUpperCase(),
              channels: results,
              orderBase: _kOrderResultsBase,
            ),
          if (isAllCategory && favoriteResults.isNotEmpty) ...[
            16.verticalSpace,
            _buildResultsSection(
              title: AppStrings.yourFavorites,
              channels: favoriteResults,
              orderBase: _kOrderFavoritesBase,
            ),
          ],
          _buildSearchPaginationFooter(),
        ],
      );
    });
  }

  Widget _buildResultsSection({
    required String title,
    required List<IptvChannel> channels,
    required double orderBase,
  }) {
    final adSlots = (!_isTv && AdsVariable.shouldShowAds)
        ? channels.length ~/ _adInterval
        : 0;
    final listItemCount = channels.length + adSlots;
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
            AppStrings.noChannelsFound,
            fontSize: 14.sp,
            color: context.textSecondary,
            fontFamily: AppStrings.interRegular,
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: listItemCount,
            itemBuilder: (context, index) {
              final channelIndex = index;
              final rowOrder = orderBase + index;
              return FocusTraversalOrder(
                order: NumericFocusOrder(rowOrder),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 12.h),
                  child: TvCard(
                    channel: channels[channelIndex],
                    style: TvCardStyle.news,
                    onPressed: () => _openChannel(channels[channelIndex]),
                    onFocused: _ensurePrimaryFocusVisible,
                  ),
                ),
              );
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
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.secondary),
          ),
        );
      }
      
      return const SizedBox.shrink();
    });
  }

  List<Widget> _buildGroupedCategorySections(
      List<IptvChannel> channels, double startOrderBase) {
    final grouped = controller.groupSearchChannelsByCategory(channels);
    if (grouped.isEmpty) {
      return [
        _buildResultsSection(
          title: AppStrings.searchResults,
          channels: const [],
          orderBase: startOrderBase,
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

    var nextOrder = startOrderBase;
    final widgets = <Widget>[];
    for (var i = 0; i < sortedKeys.length; i++) {
      final key = sortedKeys[i];
      if (i > 0) {
        widgets.add(16.verticalSpace);
      }
      widgets.add(
        _buildResultsSection(
          title: key.toUpperCase(),
          channels: grouped[key]!,
          orderBase: nextOrder,
        ),
      );
      nextOrder += grouped[key]!.length + 50;
    }
    return widgets;
  }
}

class _TvSearchCategoryChip extends StatefulWidget {
  const _TvSearchCategoryChip({
    required this.focusNode,
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.onFocused,
  });

  final FocusNode focusNode;
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final VoidCallback onFocused;

  @override
  State<_TvSearchCategoryChip> createState() => _TvSearchCategoryChipState();
}

class _TvSearchCategoryChipState extends State<_TvSearchCategoryChip> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (hasFocus) {
          setState(() => _focused = hasFocus);
          if (hasFocus) widget.onFocused();
        },
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          if (event.logicalKey == LogicalKeyboardKey.select ||
              event.logicalKey == LogicalKeyboardKey.enter) {
            widget.onSelected();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: InkWell(
          onTap: widget.onSelected,
          borderRadius: BorderRadius.circular(26.r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            height: 52.h,
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: widget.selected
                  ? const LinearGradient(colors: AppColors.primaryGradient)
                  : null,
              color: widget.selected ? null : context.chipUnselectedBg,
              borderRadius: BorderRadius.circular(26.r),
              border: Border.all(
                color: _focused ? AppColors.secondary : AppColors.transparent,
                width: _focused ? 2 : 0,
              ),
              boxShadow: _focused && !widget.selected
                  ? [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: CustomText(
              widget.label,
              color: widget.selected ? AppColors.white : context.textPrimary,
              fontFamily: AppStrings.interSemiBold,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }
}

