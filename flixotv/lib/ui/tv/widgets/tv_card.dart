import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/controller/iptv_controller.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

enum TvCardStyle { grid, list, news }

class TvCard extends StatefulWidget {
  const TvCard({
    super.key,
    required this.channel,
    required this.onPressed,
    this.onFocused,
    this.gridWidth,
    this.focusNode,
    this.style = TvCardStyle.grid,
  });

  final IptvChannel channel;
  final VoidCallback onPressed;
  final VoidCallback? onFocused;
  final double? gridWidth;
  final FocusNode? focusNode;
  final TvCardStyle style;

  @override
  State<TvCard> createState() => _TvCardState();
}

class _TvCardState extends State<TvCard> {
  bool _isFocused = false;
  bool _isFavoriteFocused = false;
  final FocusNode _internalCardFocusNode = FocusNode(debugLabel: 'tv_card_main');
  final FocusNode _favoriteFocusNode = FocusNode(debugLabel: 'tv_card_favorite');

  FocusNode get _cardFocusNode => widget.focusNode ?? _internalCardFocusNode;

  @override
  void dispose() {
    _internalCardFocusNode.dispose();
    _favoriteFocusNode.dispose();
    super.dispose();
  }

  /// Stable pseudo-progress for the reference-style bar (replace with EPG when available).
  double _gridProgressValue(IptvChannel ch) {
    final id = ch.channelId.isNotEmpty ? ch.channelId : ch.title;
    if (id.isEmpty) return 0.66;
    var h = 0;
    for (var i = 0; i < id.length; i++) {
      h = 31 * h + id.codeUnitAt(i);
    }
    h = h.abs() % 18;
    return (0.55 + h / 100.0).clamp(0.55, 0.73);
  }

  String _quality(IptvChannel ch) {
    final t = ch.title.toLowerCase();
    if (t.contains('4k')) return '4K';
    if (t.contains('576')) return '576';
    if (t.contains('hd')) return 'HD';
    return AppStrings.live;
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.style) {
      case TvCardStyle.news:
        return _buildNewsCard();
      case TvCardStyle.list:
        return _buildListCard();
      case TvCardStyle.grid:
        return _buildGridCard();
    }
  }

  // ── Grid card ─────────────────────────────────────────────────────────────
  // Same semantics as mobile search cards: [context.cardBg], [context.subtleTint]
  // frame, [context.inputFill] thumb, [CustomText], shared LIVE badge colours.

  Widget _buildGridCard() {
    final controller = Get.find<IptvController>();
    final quality = _quality(widget.channel);
    final cardWidth = widget.gridWidth ?? _uniformGridWidth(context);

    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) widget.onFocused?.call();
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onPressed();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: SizedBox(
            width: cardWidth,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isFocused
                      ? AppColors.secondary
                      : context.cardBorderColor,
                  width: _isFocused ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _isFocused
                        ? AppColors.secondary.withValues(alpha: 0.30)
                        : AppColors.black.withValues(alpha: 0.07),
                    blurRadius: _isFocused ? 18 : 8,
                    spreadRadius: _isFocused ? 1.2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ColoredBox(
                      color: context.subtleTint,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: AspectRatio(
                              aspectRatio: 2.2,
                              child: ColoredBox(
                                color: AppColors.black,
                                child: widget.channel.logo.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: controller
                                            .validUrl(widget.channel.logo),
                                        fit: BoxFit.contain,
                                        errorWidget: (_, __, ___) =>
                                            const _FallbackLogo(),
                                      )
                                    : const _FallbackLogo(),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: _LiveBadge(label: quality),
                          ),
                        ],
                      ),
                    ),
                    ColoredBox(
                      color: context.cardBg,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomText(
                              widget.channel.titleWithLanguage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFamily: AppStrings.interSemiBold,
                              color: context.textPrimary,
                            ),
                            const SizedBox(height: 3),
                            CustomText(
                              controller.getSubtitle(widget.channel),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              fontFamily: AppStrings.interRegular,
                              color: context.textSecondary,
                            ),
                            const SizedBox(height: 6),
                            _ThemedProgressBar(
                              value: _gridProgressValue(widget.channel),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _uniformGridWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Keep all channel cards aligned and clean across TV sizes.
    return (screenWidth * 0.175).clamp(280.0, 320.0);
  }

  Widget _buildFocusableFavoriteIcon({
    required IptvController controller,
    required double size,
    VoidCallback? onArrowLeft,
    VoidCallback? onArrowUpDown,
  }) {
    return Focus(
      focusNode: _favoriteFocusNode,
      onFocusChange: (f) => setState(() => _isFavoriteFocused = f),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
          controller.toggleFavoriteChannel(widget.channel);
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowLeft) {
          onArrowLeft?.call();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowUp ||
            key == LogicalKeyboardKey.arrowDown) {
          // Keep vertical navigation anchored to the card item.
          onArrowUpDown?.call();
          return KeyEventResult.handled;
        }
        if (key == LogicalKeyboardKey.arrowRight) {
          // Prevent jumping to another section from favorite icon.
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              controller.toggleFavoriteChannel(widget.channel);
              return null;
            },
          ),
        },
        child: Obx(() {
          final isFav = controller.isFavoriteChannel(widget.channel);
          return GestureDetector(
            onTap: () => controller.toggleFavoriteChannel(widget.channel),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isFavoriteFocused
                    ? AppColors.secondary.withValues(alpha: 0.12)
                    : AppColors.transparent,
                border: Border.all(
                  color: _isFavoriteFocused
                      ? AppColors.secondary
                      : AppColors.transparent,
                ),
              ),
              child: Icon(
                isFav ? Icons.favorite : Icons.favorite_border,
                color: isFav
                    ? AppColors.heart
                    : _isFavoriteFocused
                        ? AppColors.secondary
                        : context.textSecondary.withValues(alpha: 0.5),
                size: size,
              ),
            ),
          );
        }),
      ),
    );
  }

  // ── List card (single-category full list, same as mobile) ─────────────────

  Widget _buildListCard() {
    final controller = Get.find<IptvController>();
    final quality = _quality(widget.channel);

    return Focus(
      focusNode: _cardFocusNode,
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) widget.onFocused?.call();
      },
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _favoriteFocusNode.requestFocus();
          setState(() => _isFavoriteFocused = true);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isFocused
                          ? AppColors.secondary
                          : context.cardBorderColor,
                      width: _isFocused ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isFocused
                            ? AppColors.secondary.withValues(alpha: 0.18)
                            : AppColors.black.withValues(alpha: 0.05),
                        blurRadius: _isFocused ? 14 : 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Logo
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: context.logoBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: CachedNetworkImage(
                          imageUrl: controller.validUrl(widget.channel.logo),
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) =>
                              Icon(Icons.tv, color: context.textMuted),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: CustomText(
                                    widget.channel.titleWithLanguage,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppStrings.interBold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _LiveBadge(label: quality),
                              ],
                            ),
                            const SizedBox(height: 2),
                            CustomText(
                              controller.getSubtitle(widget.channel),
                              fontSize: 12,
                              fontFamily: AppStrings.interRegular,
                              color: context.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFocusableFavoriteIcon(
                controller: controller,
                size: 22,
                onArrowLeft: () => _cardFocusNode.requestFocus(),
                onArrowUpDown: () => _cardFocusNode.requestFocus(),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }

  // ── News card ─────────────────────────────────────────────────────────────

  Widget _buildNewsCard() {
    final controller = Get.find<IptvController>();
    final quality = _quality(widget.channel);

    return Focus(
      focusNode: _cardFocusNode,
      onFocusChange: (f) {
        setState(() => _isFocused = f);
        if (f) widget.onFocused?.call();
      },
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          _favoriteFocusNode.requestFocus();
          setState(() => _isFavoriteFocused = true);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: FocusableActionDetector(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed();
              return null;
            },
          ),
        },
        child: GestureDetector(
          onTap: widget.onPressed,
          child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Row(
            children: [
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 130),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isFocused
                          ? AppColors.secondary
                          : context.cardBorderColor,
                      width: _isFocused ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _isFocused
                            ? AppColors.secondary.withValues(alpha: 0.18)
                            : AppColors.black.withValues(alpha: 0.04),
                        blurRadius: _isFocused ? 14 : 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.subtleTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: controller.validUrl(widget.channel.logo),
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => Icon(
                            Icons.image,
                            size: 26,
                            color: context.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: CustomText(
                                    widget.channel.titleWithLanguage,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: AppStrings.interBold,
                                    color: context.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Padding(
                                  padding: const EdgeInsets.only(top: 1),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: context.chipUnselectedBg,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: CustomText(
                                      quality,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: AppStrings.interSemiBold,
                                      color: context.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            CustomText(
                              controller.getSubtitle(widget.channel),
                              fontSize: 11,
                              fontFamily: AppStrings.interRegular,
                              color: context.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFocusableFavoriteIcon(
                controller: controller,
                size: 20,
                onArrowLeft: () => _cardFocusNode.requestFocus(),
                onArrowUpDown: () => _cardFocusNode.requestFocus(),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

// ── Progress (theme track + shared [AppColors.progress]) ──────────────────────

class _ThemedProgressBar extends StatelessWidget {
  const _ThemedProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return SizedBox(
      height: 5,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.progress,
                  borderRadius: BorderRadius.circular(2.5),
                ),
                child: const SizedBox(height: 5, width: double.infinity),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── LIVE / quality badge (same tokens as mobile search rows) ─────────────────

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isLive = label == AppStrings.live;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      margin: const EdgeInsets.only(top: 5, right: 7),
      decoration: BoxDecoration(
        color: isLive
            ? AppColors.liveBadgeBackground
            : label == '4K'
                ? AppColors.badge4kBackground
                : label == 'HD'
                    ? AppColors.badgeHdBackground
                    : AppColors.liveBadgeBackground,
        borderRadius: BorderRadius.circular(4),
      ),
      child: CustomText(
        label,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        fontFamily: AppStrings.interBold,
        color: isLive ? AppColors.liveBadgeText : AppColors.white,
        maxLines: 1,
      ),
    );
  }
}

// ── Fallback logo ─────────────────────────────────────────────────────────────

class _FallbackLogo extends StatelessWidget {
  const _FallbackLogo();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.black,
      child: Center(
        child: Icon(Icons.tv, color: context.textMuted, size: 36),
      ),
    );
  }
}
