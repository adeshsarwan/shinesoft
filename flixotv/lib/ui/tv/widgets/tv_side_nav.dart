import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/widgets/custom_text.dart';

enum TvSideNavItem { home, favorites, search, schedule, mySpace }

class TvSideNav extends StatefulWidget {
  const TvSideNav({
    super.key,
    required this.selected,
    required this.onItemSelected,
  });

  static const double railWidth = 52.0;
  static const double expandedWidth = 186.0;

  final TvSideNavItem selected;
  final ValueChanged<TvSideNavItem> onItemSelected;

  @override
  State<TvSideNav> createState() => TvSideNavState();
}

class TvSideNavState extends State<TvSideNav>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
  bool _expanded = false;

  final List<FocusNode> _focusNodes = List.generate(
    _navItems.length,
    (i) => FocusNode(debugLabel: 'nav_$i'),
  );

  static const _navItems = [
    (item: TvSideNavItem.home, icon: Icons.home_outlined, label: 'Home'),
    (
      item: TvSideNavItem.favorites,
      icon: Icons.favorite_border_rounded,
      label: 'Favorites'
    ),
    (item: TvSideNavItem.search, icon: Icons.search, label: 'Search'),
    (
      item: TvSideNavItem.mySpace,
      icon: Icons.account_circle_outlined,
      label: 'My Space'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _anim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    for (final n in _focusNodes) {
      n.dispose();
    }
    super.dispose();
  }

  bool get isExpanded => _expanded;

  void open() {
    if (_expanded) return;
    setState(() => _expanded = true);
    _ctrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes[0].requestFocus();
    });
  }

  void close() {
    if (!_expanded) return;
    setState(() => _expanded = false);
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final t = _anim.value;
        final w = TvSideNav.railWidth +
            (TvSideNav.expandedWidth - TvSideNav.railWidth) * t;

        return SizedBox(
          width: w,
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.tvNavBackground,
                    boxShadow: t > 0.01
                        ? [
                            BoxShadow(
                              color: AppColors.black.withValues(
                                  alpha: (context.isDark ? 0.45 : 0.2) * t),
                              blurRadius: 20,
                              offset: const Offset(4, 0),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.35 * t,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: AppColors.primaryGradient,
                        ),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(18.r),
                          bottomRight: Radius.circular(18.r),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.transparent,
                        AppColors.tvNavEdge,
                        AppColors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 60,
                      width: w,
                      child: Center(
                        child: Image.asset(
                          Assets.images.logoWithoutBg.path,
                          width: 70.w,
                          height: 70.h,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: context.isDark
                          ? AppColors.white.withValues(alpha: 0.1)
                          : context.borderColor.withValues(alpha: 0.2),
                    ),
                    4.verticalSpace,
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_navItems.length, (i) {
                          final e = _navItems[i];
                          return _NavItem(
                            focusNode: _focusNodes[i],
                            icon: e.icon,
                            label: e.label,
                            selected: widget.selected == e.item,
                            animT: t,
                            railWidth: TvSideNav.railWidth,
                            onPressed: () {
                              widget.onItemSelected(e.item);
                              close();
                            },
                            onFocusGained: () {
                              if (!_expanded) {
                                setState(() => _expanded = true);
                                _ctrl.forward();
                              }
                            },
                            onFocusLost: () {
                              Future.delayed(const Duration(milliseconds: 100),
                                  () {
                                if (!mounted) return;
                                final hasFocus =
                                    _focusNodes.any((n) => n.hasFocus);
                                if (!hasFocus) close();
                              });
                            },
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.focusNode,
    required this.icon,
    required this.label,
    required this.selected,
    required this.animT,
    required this.railWidth,
    required this.onPressed,
    required this.onFocusGained,
    required this.onFocusLost,
  });

  final FocusNode focusNode;
  final IconData icon;
  final String label;
  final bool selected;
  final double animT;
  final double railWidth;
  final VoidCallback onPressed;
  final VoidCallback onFocusGained;
  final VoidCallback onFocusLost;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _focused = false;

  double get _labelOpacity => ((widget.animT - 0.35) / 0.65).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final isActive = widget.selected || _focused;
    final tileBg = _focused
        ? (context.isDark
            ? AppColors.tvNavFocusedBg
            : AppColors.primary.withValues(alpha: 0.1))
        : widget.selected
            ? (context.isDark
                ? AppColors.tvNavSelectedBg
                : AppColors.primary.withValues(alpha: 0.14))
            : AppColors.transparent;

    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (f) {
          widget.onFocusGained();
        } else {
          widget.onFocusLost();
        }
      },
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent) return KeyEventResult.ignored;
        final k = event.logicalKey;
        if (k == LogicalKeyboardKey.select || k == LogicalKeyboardKey.enter) {
          widget.onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: tileBg,
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withValues(alpha: 0.85)
                  : AppColors.transparent,
              width: isActive ? 1.2 : 0,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 10,
                      spreadRadius: -2,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              if (widget.selected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: AppColors.primaryGradient,
                      ),
                    ),
                  ),
                ),
              if (_focused && !widget.selected)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 2.5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ClipRect(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final iconSlotWidth = constraints.maxWidth < widget.railWidth
                        ? constraints.maxWidth
                        : widget.railWidth;
                    return Row(
                      children: [
                        SizedBox(
                          width: iconSlotWidth,
                          child: Center(
                            child: Icon(
                              widget.icon,
                              size: 19,
                              color: isActive
                                  ? AppColors.tvNavActiveItem
                                  : AppColors.tvNavInactiveIcon,
                            ),
                          ),
                        ),
                        if (widget.animT > 0.05)
                          Expanded(
                            child: Opacity(
                              opacity: _labelOpacity,
                              child: CustomText(
                                widget.label,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                color: isActive
                                    ? AppColors.tvNavActiveItem
                                    : AppColors.tvNavInactiveLabel,
                                fontSize: 13,
                                fontWeight: widget.selected
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
