import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/routes/app_routes.dart';
import 'package:iptv_demo/services/auth_service.dart';
import 'package:iptv_demo/utils/notification_platform.dart';
import 'package:iptv_demo/utils/push_token_util.dart';
import 'package:iptv_demo/ui/tv/player_tv_screen.dart';
import 'package:iptv_demo/ui/tv/search_tv_screen.dart';
import 'package:iptv_demo/ui/tv/tv_my_space_screen.dart';
import 'package:iptv_demo/ui/tv/widgets/tv_card.dart';
import 'package:iptv_demo/ui/tv/widgets/tv_section.dart';
import 'package:iptv_demo/ui/tv/widgets/tv_side_nav.dart';
import 'package:iptv_demo/ui/tv/widgets/tv_top_nav.dart';
import 'package:iptv_demo/widgets/app_toast.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class HomeTvScreen extends StatefulWidget {
  const HomeTvScreen({super.key});

  @override
  State<HomeTvScreen> createState() => _HomeTvScreenState();
}

class _HomeTvScreenState extends State<HomeTvScreen> {
  TvSideNavItem _sideSelected = TvSideNavItem.home;
  final _navKey = GlobalKey<TvSideNavState>();
  DateTime? _lastBackPressAt;

  static const _preferred = ['Movies', 'Sports', 'News', 'Entertainment'];

  @override
  void initState() {
    super.initState();
    _warmUpTvPushIfLoggedIn();
    // Register hardware key handler for back button at app level
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
  }

  void _warmUpTvPushIfLoggedIn() {
    if (!Get.isRegistered<AuthService>()) return;
    final auth = Get.find<AuthService>();
    if (!auth.isLoggedIn.value) return;
    if (auth.registeredPlatform.value == authPlatformTv) {
      unawaited(ensureTvPushReadyAfterLogin());
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    super.dispose();
  }

  // Hardware key handler — catches back button before Flutter routing
  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.goBack ||
        k == LogicalKeyboardKey.browserBack ||
        k == LogicalKeyboardKey.escape) {
      // Ignore back events while this route is not visible (e.g. Player is on top).
      final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? false;
      if (!isCurrentRoute) return false;

      final nav = _navKey.currentState;
      if (nav != null && nav.isExpanded) {
        nav.close();
        return true; // consumed
      }

      // Require a second back press shortly after the first to exit.
      final now = DateTime.now();
      final pressedRecently = _lastBackPressAt != null &&
          now.difference(_lastBackPressAt!) < const Duration(seconds: 2);
      _lastBackPressAt = now;

      if (!pressedRecently) {
        showAppToast(
          title: AppStrings.appName,
          message: 'Press back again to exit',
        );
        return true;
      }

      SystemNavigator.pop();
      return true;
    }
    return false;
  }

  void _openPlayer(IptvChannel channel) {
    openChannelPlayerTv(channel);
  }

  void _handleSideNav(TvSideNavItem item) {
    setState(() => _sideSelected = item);
    final controller = Get.find<IptvController>();
    switch (item) {
      case TvSideNavItem.home:
        controller.selectCategory(AppStrings.all);
        break;
      case TvSideNavItem.favorites:
        break;
      case TvSideNavItem.schedule:
        Get.toNamed(AppRoutes.SCHEDULE_TV);
        break;
      case TvSideNavItem.search:
        break;
      case TvSideNavItem.mySpace:
        break;
    }
  }

  List<String> _orderedSectionTitles(
      Map<String, List<IptvChannel>> byCategory) {
    final available = byCategory.keys
        .where((k) => k.toLowerCase() != 'all' && byCategory[k]!.isNotEmpty)
        .toList();
    final remaining = available.where((t) => !_preferred.contains(t)).toList()
      ..sort();
    return [
      ..._preferred.where(available.contains),
      ...remaining,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IptvController>();

    return Scaffold(
      backgroundColor: context.tvScaffoldBg,
      body: SafeArea(
        child: Row(
          children: [
            // ── Side nav ──────────────────────────────────────────────────
            TvSideNav(
              key: _navKey,
              selected: _sideSelected,
              onItemSelected: _handleSideNav,
            ),

            // ── Main content ──────────────────────────────────────────────
            Expanded(
              child: _ContentArea(
                navKey: _navKey,
                child: _sideSelected == TvSideNavItem.search
                    ? const SearchTvScreen()
                    : _sideSelected == TvSideNavItem.favorites
                        ? const _TvFavoritesView()
                    : _sideSelected == TvSideNavItem.mySpace
                        ? const TvMySpaceScreen()
                        : Column(
                            children: [
                              Obx(() {
                                final categoryIds = controller.categoryIds;
                                final selectedCat = controller
                                    .selectedCategory.value
                                    .toLowerCase();
                                final selIdx = categoryIds.indexWhere(
                                    (id) => id.toLowerCase() == selectedCat);

                                return TvTopNav(
                                  categories: categoryIds
                                      .map((id) => controller.categoryLabel(id))
                                      .toList(),
                                  selectedIndex: selIdx < 0 ? 0 : selIdx,
                                  onTabSelected: (i) {
                                    if (i >= 0 && i < categoryIds.length) {
                                      controller.selectCategory(categoryIds[i]);
                                    }
                                  },
                                  onSearchPressed: () => setState(() =>
                                      _sideSelected = TvSideNavItem.search),
                                  onSignInPressed: () =>
                                      Get.toNamed(AppRoutes.LOGIN_TV),
                                  onLeftEdge: () =>
                                      _navKey.currentState?.open(),
                                );
                              }),
                              Expanded(
                                child: Obx(() {
                                  if (controller.isLoading.value) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                          color: AppColors.secondary),
                                    );
                                  }

                                  final selectedCat = controller
                                      .selectedCategory.value
                                      .toLowerCase();
                                  final isAll = selectedCat ==
                                      AppStrings.all.toLowerCase();
                                  final byCategory =
                                      controller.categorizedChannels(
                                          controller.filteredChannels);

                                  if (isAll) {
                                    final titles =
                                        _orderedSectionTitles(byCategory);
                                    if (titles.isEmpty) return _empty();
                                    return ListView(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 20, vertical: 16),
                                      children: [
                                        // const TvHomeHeroAd(),
                                        // 24.verticalSpace,
                                        for (var i = 0; i < titles.length; i++) ...[
                                          TvSection(
                                            title: titles[i],
                                            channels: controller
                                                .getPopularActiveHomeChannels(
                                                    byCategory[titles[i]] ?? []),
                                            cardStyle:
                                                titles[i].toLowerCase() == 'news'
                                                    ? TvCardStyle.news
                                                    : TvCardStyle.grid,
                                            onCardPressed: _openPlayer,
                                            onViewAll: () =>
                                                controller.selectCategory(
                                                    titles[i].toLowerCase()),
                                          ),
                                          28.verticalSpace,
                                        ],
                                      ],
                                    );
                                  } else {
                                    final matchKey = byCategory.keys.firstWhere(
                                      (k) => k.toLowerCase() == selectedCat,
                                      orElse: () => '',
                                    );
                                    final channels =
                                        controller.channelsSortedByTitle(
                                            byCategory[matchKey] ?? []);
                                    if (channels.isEmpty) return _empty();

                                    final isNews = selectedCat == 'news';
                                    final displayTitle =
                                        controller.categoryLabel(selectedCat);

                                    return _TvSingleCategoryList(
                                      title: displayTitle,
                                      channels: channels,
                                      isNews: isNews,
                                      onOpenPlayer: _openPlayer,
                                    );
                                  }
                                }),
                              ),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _empty() => Center(
        child: CustomText(
          'No channels available',
          color: context.tvSubtitleColor,
          fontSize: 16,
          maxLines: 1,
        ),
      );
}

class _TvFavoritesView extends StatefulWidget {
  const _TvFavoritesView();

  @override
  State<_TvFavoritesView> createState() => _TvFavoritesViewState();
}

class _TvFavoritesViewState extends State<_TvFavoritesView> {
  final ScrollController _scrollController = ScrollController();
  List<FocusNode> _focusNodes = <FocusNode>[];
  List<GlobalKey> _itemKeys = <GlobalKey>[];
  int _lastFocusedIndex = 0;
  int _previousCount = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Get.find<IptvController>().applyFavoritesFilters(
      categoryId: AppStrings.all,
      query: '',
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    unawaited(Get.find<IptvController>().loadMoreFavorites());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _rebuildFocusItems(int count) {
    for (final node in _focusNodes) {
      node.dispose();
    }
    _focusNodes = List.generate(
      count,
      (i) => FocusNode(debugLabel: 'fav_card_$i'),
    );
    _itemKeys = List.generate(count, (_) => GlobalKey());
  }

  void _ensureVisible(int index) {
    if (index < 0 || index >= _itemKeys.length) return;
    final ctx = _itemKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: 0.2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<IptvController>();
    return Obx(() {
      controller.favoriteChannels.length;
      final allFavorites = controller.getFavoriteChannels();
      final favorites = controller.favoritesVisibleChannels.toList();
      if (favorites.isEmpty &&
          !controller.isFavoritesPaginationLoading.value) {
        if (allFavorites.isEmpty) {
        return Center(
          child: CustomText(
            'No favorite channels yet',
            color: context.tvSubtitleColor,
            fontSize: 16,
            maxLines: 1,
          ),
        );
        }
        return const SizedBox.shrink();
      }

      if (favorites.length != _previousCount) {
        _rebuildFocusItems(favorites.length);
        _previousCount = favorites.length;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || favorites.isEmpty) return;
          final target = _lastFocusedIndex.clamp(0, favorites.length - 1);
          _focusNodes[target].requestFocus();
          _ensureVisible(target);
        });
      }

      return ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          CustomText(
            AppStrings.favorites.toUpperCase(),
            color: context.tvSectionTitleColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            maxLines: 1,
          ),
          16.verticalSpace,
          for (var i = 0; i < favorites.length; i++)
            KeyedSubtree(
              key: _itemKeys[i],
              child: TvCard(
                channel: favorites[i],
                focusNode: _focusNodes[i],
                onFocused: () {
                  _lastFocusedIndex = i;
                  _ensureVisible(i);
                },
                onPressed: () => openChannelPlayerTv(favorites[i]),
                style: TvCardStyle.list,
              ),
            ),
          if (controller.isFavoritesPaginationLoading.value)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (controller.favoritesHasMore)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: CustomText(
                  'Scroll to load more',
                  color: context.tvSubtitleColor,
                  fontSize: 14,
                  maxLines: 1,
                ),
              ),
            ),
        ],
      );
    });
  }
}

class _TvSingleCategoryList extends StatefulWidget {
  const _TvSingleCategoryList({
    required this.title,
    required this.channels,
    required this.isNews,
    required this.onOpenPlayer,
  });

  final String title;
  final List<IptvChannel> channels;
  final bool isNews;
  final ValueChanged<IptvChannel> onOpenPlayer;

  @override
  State<_TvSingleCategoryList> createState() => _TvSingleCategoryListState();
}

class _TvSingleCategoryListState extends State<_TvSingleCategoryList> {
  late final ScrollController _scrollController;
  late List<GlobalKey> _itemKeys;
  late List<FocusNode> _focusNodes;
  int _lastFocusedIndex = -1;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _itemKeys = List.generate(widget.channels.length, (_) => GlobalKey());
    _focusNodes = List.generate(
      widget.channels.length,
      (i) => FocusNode(debugLabel: 'single_cat_$i'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _focusNodes.isEmpty) return;
      // Ensure single-category page always starts with a focus target.
      _focusNodes.first.requestFocus();
      _ensureVisible(0);
    });
  }

  @override
  void didUpdateWidget(covariant _TvSingleCategoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channels.length != widget.channels.length) {
      _itemKeys = List.generate(widget.channels.length, (_) => GlobalKey());
      for (final n in _focusNodes) {
        n.dispose();
      }
      _focusNodes = List.generate(
        widget.channels.length,
        (i) => FocusNode(debugLabel: 'single_cat_$i'),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _ensureVisible(int index) {
    final ctx = _itemKeys[index].currentContext;
    if (ctx == null) return;
    final movingUp = _lastFocusedIndex >= 0 && index < _lastFocusedIndex;
    _lastFocusedIndex = index;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      alignment: movingUp ? 0.08 : 0.92,
      alignmentPolicy: movingUp
          ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
          : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          CustomText(
            widget.title,
            color: context.tvSectionTitleColor,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            maxLines: 1,
          ),
          10.verticalSpace,
          for (var i = 0; i < widget.channels.length; i++)
            KeyedSubtree(
              key: _itemKeys[i],
              child: TvCard(
                channel: widget.channels[i],
                focusNode: _focusNodes[i],
                onFocused: () => _ensureVisible(i),
                onPressed: () => widget.onOpenPlayer(widget.channels[i]),
                style: widget.isNews ? TvCardStyle.news : TvCardStyle.list,
              ),
            ),
        ],
      ),
    );
  }
}

// ── Content area — intercepts left arrow ONLY from the leftmost tab ───────────

class _ContentArea extends StatelessWidget {
  const _ContentArea({
    required this.navKey,
    required this.child,
  });

  final GlobalKey<TvSideNavState> navKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // No KeyboardListener here — left arrow navigation is handled naturally
    // by Flutter's focus system. The drawer opens only when the first tab
    // in TvTopNav explicitly calls navKey.currentState?.open().
    return child;
  }
}
