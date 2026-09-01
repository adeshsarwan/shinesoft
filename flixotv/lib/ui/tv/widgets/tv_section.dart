import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/model/channel_model.dart';
import 'package:iptv_demo/ui/tv/widgets/tv_card.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class TvSection extends StatefulWidget {
  const TvSection({
    super.key,
    required this.title,
    required this.channels,
    required this.onCardPressed,
    this.onViewAll,
    this.cardStyle = TvCardStyle.grid,
  });

  final String title;
  final List<IptvChannel> channels;
  final ValueChanged<IptvChannel> onCardPressed;
  final VoidCallback? onViewAll;
  final TvCardStyle cardStyle;

  @override
  State<TvSection> createState() => _TvSectionState();
}

class _TvSectionState extends State<TvSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.channels.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Section header ──────────────────────────────────────────────
        Row(
          children: [
            CustomText(
              widget.title,
              color: context.tvSectionTitleColor,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              maxLines: 1,
            ),
          ],
        ),
        (widget.cardStyle == TvCardStyle.news ? 14 : 8).verticalSpace,

        // ── Content ─────────────────────────────────────────────────────
        if (widget.cardStyle == TvCardStyle.news ||
            widget.cardStyle == TvCardStyle.list)
          // Vertical list (news / list style)
          Column(
            children: [
              ...widget.channels.map((ch) => TvCard(
                    channel: ch,
                    onPressed: () => widget.onCardPressed(ch),
                    style: widget.cardStyle,
                  )),
              if (widget.onViewAll != null)
                _InlineExploreMoreButton(onPressed: widget.onViewAll!),
            ],
          )
        else
          // Horizontal scroll (grid style)
          _HorizontalTvCards(
            rowId: widget.title.toLowerCase(),
            channels: widget.channels,
            onCardPressed: widget.onCardPressed,
            onViewAll: widget.onViewAll,
          ),
      ],
    );
  }
}

class _HorizontalTvCards extends StatefulWidget {
  const _HorizontalTvCards({
    required this.rowId,
    required this.channels,
    required this.onCardPressed,
    this.onViewAll,
  });

  final String rowId;
  final List<IptvChannel> channels;
  final ValueChanged<IptvChannel> onCardPressed;
  final VoidCallback? onViewAll;

  @override
  State<_HorizontalTvCards> createState() => _HorizontalTvCardsState();
}

class _HorizontalTvCardsState extends State<_HorizontalTvCards> {
  late final ScrollController _controller;
  late List<GlobalKey> _itemKeys;
  late List<FocusNode> _focusNodes;
  bool _rowHasPrimaryFocus = false;

  static final Set<String> _visitedRows = <String>{};
  static final Map<String, int> _lastFocusedByRow = <String, int>{};

  int _totalItemsFor(bool hasExplore) =>
      widget.channels.length + (hasExplore ? 1 : 0);

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    final total = _totalItemsFor(widget.onViewAll != null);
    _itemKeys = List.generate(total, (_) => GlobalKey());
    _focusNodes = List.generate(
      total,
      (i) => FocusNode(debugLabel: 'tv_card_$i'),
    );
  }

  @override
  void didUpdateWidget(covariant _HorizontalTvCards oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldTotal =
        oldWidget.channels.length + (oldWidget.onViewAll != null ? 1 : 0);
    final newTotal = _totalItemsFor(widget.onViewAll != null);
    if (oldTotal != newTotal) {
      _itemKeys = List.generate(newTotal, (_) => GlobalKey());
      for (final node in _focusNodes) {
        node.dispose();
      }
      _focusNodes = List.generate(
        newTotal,
        (i) => FocusNode(debugLabel: 'tv_card_$i'),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  int _focusedCardIndex() {
    for (var i = 0; i < _focusNodes.length; i++) {
      if (_focusNodes[i].hasFocus) return i;
    }
    return -1;
  }

  void _ensureItemVisible(int index, {required bool movingLeft}) {
    final itemContext = _itemKeys[index].currentContext;
    if (itemContext == null) return;
    Scrollable.ensureVisible(
      itemContext,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: movingLeft ? 0.08 : 0.92,
      alignmentPolicy: movingLeft
          ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
          : ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = _uniformGridWidth(context);
    final rowHeight = _responsiveRowHeight(cardWidth);
    final hasExplore = widget.onViewAll != null;
    final totalItems = widget.channels.length + (hasExplore ? 1 : 0);

    return SizedBox(
      // Responsive row height so focused cards never clip on different TVs.
      height: rowHeight,
      child: Focus(
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final current = _focusedCardIndex();
          if (current < 0) return KeyEventResult.ignored;

          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (current >= _focusNodes.length - 1) {
              // Explicit hard stop at row end.
              return KeyEventResult.handled;
            }
            final next = current + 1;
            _focusNodes[next].requestFocus();
            _ensureItemVisible(next, movingLeft: false);
            return KeyEventResult.handled;
          }

          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (current <= 0) return KeyEventResult.ignored;
            final prev = current - 1;
            _focusNodes[prev].requestFocus();
            _ensureItemVisible(prev, movingLeft: true);
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        onFocusChange: (f) {
          if (!f) {
            _rowHasPrimaryFocus = false;
            return;
          }
          if (_rowHasPrimaryFocus || _focusNodes.isEmpty) return;
          _rowHasPrimaryFocus = true;

          final maxCardIndex =
              widget.channels.isEmpty ? 0 : widget.channels.length - 1;
          final hasVisited = _visitedRows.contains(widget.rowId);
          final remembered = _lastFocusedByRow[widget.rowId] ?? 0;
          final target = hasVisited ? remembered.clamp(0, maxCardIndex) : 0;

          _focusNodes[target].requestFocus();
          _ensureItemVisible(target, movingLeft: target == 0);
          _visitedRows.add(widget.rowId);
        },
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          physics: const BouncingScrollPhysics(),
          // Enough edge room so first/last focused cards are not cut.
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          itemCount: totalItems,
          separatorBuilder: (_, __) => 8.horizontalSpace,
          itemBuilder: (_, i) {
            if (i == widget.channels.length && hasExplore) {
              return KeyedSubtree(
                key: _itemKeys[i],
                child: SizedBox(
                width: cardWidth,
                child: _InlineExploreMoreCard(
                  focusNode: _focusNodes[i],
                  onFocused: () => _ensureItemVisible(i, movingLeft: false),
                  onPressed: widget.onViewAll!,
                ),
                ),
              );
            }
            return KeyedSubtree(
              key: _itemKeys[i],
              child: TvCard(
                channel: widget.channels[i],
                onPressed: () => widget.onCardPressed(widget.channels[i]),
                onFocused: () {
                  _ensureItemVisible(i, movingLeft: false);
                if (i < widget.channels.length) {
                  _lastFocusedByRow[widget.rowId] = i;
                  _visitedRows.add(widget.rowId);
                }
                },
                focusNode: _focusNodes[i],
                gridWidth: cardWidth,
                style: TvCardStyle.grid,
              ),
            );
          },
        ),
      ),
    );
  }

  double _uniformGridWidth(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return (screenWidth * 0.175).clamp(280.0, 320.0);
  }

  double _responsiveRowHeight(double cardWidth) {
    final imageHeight = (cardWidth - 24) / 2.2; // flatter image panel
    const cardStaticHeight = 86.0; // compact metadata + progress area
    const focusAndListPadding = 56.0; // keep focus border/glow safe
    return imageHeight + cardStaticHeight + focusAndListPadding;
  }
}

// ── End-of-list actions ───────────────────────────────────────────────────────

class _InlineExploreMoreButton extends StatefulWidget {
  const _InlineExploreMoreButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_InlineExploreMoreButton> createState() =>
      _InlineExploreMoreButtonState();
}

class _InlineExploreMoreButtonState extends State<_InlineExploreMoreButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      onFocusChange: (f) {
        setState(() => _focused = f);
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _focused
                ? AppColors.secondary.withValues(alpha: 0.1)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _focused ? AppColors.secondary : AppColors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline_rounded,
                size: 16,
                color: _focused ? AppColors.primary : AppColors.linkBlue,
              ),
              8.horizontalSpace,
              CustomText(
                'EXPLORE MORE',
                color: _focused ? AppColors.primary : AppColors.linkBlue,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineExploreMoreCard extends StatefulWidget {
  const _InlineExploreMoreCard({
    required this.onPressed,
    required this.focusNode,
    this.onFocused,
  });
  final VoidCallback onPressed;
  final FocusNode focusNode;
  final VoidCallback? onFocused;

  @override
  State<_InlineExploreMoreCard> createState() => _InlineExploreMoreCardState();
}

class _InlineExploreMoreCardState extends State<_InlineExploreMoreCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: widget.focusNode,
      onFocusChange: (f) => setState(() => _focused = f),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _focused ? AppColors.secondary : context.cardBorderColor,
              width: _focused ? 2 : 1,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 20,
                  color: _focused ? AppColors.primary : AppColors.linkBlue,
                ),
                10.horizontalSpace,
                CustomText(
                  'EXPLORE MORE',
                  color: _focused ? AppColors.primary : AppColors.linkBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
