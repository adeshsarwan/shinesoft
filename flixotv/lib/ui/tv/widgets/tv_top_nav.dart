import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

class TvTopNav extends StatefulWidget {
  const TvTopNav({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.categories,
    required this.onSearchPressed,
    required this.onSignInPressed,
    this.onLeftEdge,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<String> categories;
  final VoidCallback onSearchPressed;
  final VoidCallback onSignInPressed;
  final VoidCallback? onLeftEdge;

  @override
  State<TvTopNav> createState() => _TvTopNavState();
}

class _TvTopNavState extends State<TvTopNav> {
  final _scrollCtrl = ScrollController();
  late List<FocusNode> _focusNodes;
  bool _tabRowHasPrimaryFocus = false;
  int _lastCenteredSelectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(
      widget.categories.length,
      (i) => FocusNode(debugLabel: 'tab_$i'),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureVisible(widget.selectedIndex);
    });
  }

  @override
  void didUpdateWidget(TvTopNav old) {
    super.didUpdateWidget(old);

    if (widget.categories.length != old.categories.length) {
      for (final n in _focusNodes) {
        n.dispose();
      }
      _focusNodes = List.generate(
        widget.categories.length,
        (i) => FocusNode(debugLabel: 'tab_$i'),
      );
      _lastCenteredSelectedIndex = -1;
    }

    if (widget.selectedIndex != old.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureVisible(widget.selectedIndex);
        _lastCenteredSelectedIndex = widget.selectedIndex;
      });
    }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _ensureVisible(int index) {
    if (index < 0 || index >= _focusNodes.length) return;
    final ctx = _focusNodes[index].context;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _centerSelectedCategoryIfNeeded() {
    final idx = widget.selectedIndex;
    if (idx < 0 || idx >= _focusNodes.length) return;
    if (_lastCenteredSelectedIndex == idx) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _ensureVisible(idx);
      _lastCenteredSelectedIndex = idx;
    });
  }

  @override
  Widget build(BuildContext context) {
    _centerSelectedCategoryIfNeeded();
    return Container(
      color: context.tvTopNavBg,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                Expanded(
                  child: Focus(
                    onFocusChange: (f) {
                      if (!f) {
                        _tabRowHasPrimaryFocus = false;
                        return;
                      }
                      if (_tabRowHasPrimaryFocus || _focusNodes.isEmpty) return;
                      _tabRowHasPrimaryFocus = true;
                      final maxIdx = _focusNodes.length - 1;
                      final target = widget.selectedIndex.clamp(0, maxIdx);
                      _focusNodes[target].requestFocus();
                      _ensureVisible(target);
                    },
                    child: SingleChildScrollView(
                      controller: _scrollCtrl,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          for (int i = 0; i < widget.categories.length; i++)
                            _Tab(
                              focusNode: _focusNodes[i],
                              label: widget.categories[i].toUpperCase(),
                              isSelected: widget.selectedIndex == i,
                              onPressed: () => widget.onTabSelected(i),
                              onLeftEdge: i == 0 ? widget.onLeftEdge : null,
                              onFocused: () {
                                _ensureVisible(i);
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: context.dividerColor,
          ),
        ],
      ),
    );
  }
}



class _NavIconButton extends StatefulWidget {
  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<_NavIconButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (_, event) {
          if (event is! KeyDownEvent) return KeyEventResult.ignored;
          final k = event.logicalKey;
          if (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: widget.onPressed,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              widget.icon,
              size: 22,
              color: _focused
                  ? context.tvFocusedTabColor
                  : context.tvUnfocusedTabColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tab ───────────────────────────────────────────────────────────────────────

class _Tab extends StatefulWidget {
  const _Tab({
    required this.focusNode,
    required this.label,
    required this.isSelected,
    required this.onPressed,
    this.onLeftEdge,
    this.onFocused,
  });

  final FocusNode focusNode;
  final String label;
  final bool isSelected;
  final VoidCallback onPressed;
  final VoidCallback? onLeftEdge;
  final VoidCallback? onFocused;

  @override
  State<_Tab> createState() => _TabState();
}

class _TabState extends State<_Tab> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (f) widget.onFocused?.call();
      },
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final k = event.logicalKey;

        if (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter) {
          widget.onPressed();
          return KeyEventResult.handled;
        }

        if (k == LogicalKeyboardKey.arrowLeft && widget.onLeftEdge != null) {
          widget.onLeftEdge!();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: SizedBox(
          height: 44,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Focus pill — can appear on any focused tab
              if (_focused)
                Positioned(
                  top: 6,
                  bottom: 6,
                  left: 4,
                  right: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: context.tvFocusPillBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),

              // Label
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: widget.isSelected
                    ? ShaderMask(
                        blendMode: BlendMode.srcIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: AppColors.primaryGradient,
                        ).createShader(bounds),
                        child: CustomText(
                          widget.label,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                          maxLines: 1,
                        ),
                      )
                    : CustomText(
                        widget.label,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _focused
                            ? context.tvFocusedTabColor
                            : context.tvUnfocusedTabColor,
                        maxLines: 1,
                      ),
              ),

              // Bottom indicator — selected only
              if (widget.isSelected)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    height: 3,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: AppColors.primaryGradient,
                      ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
