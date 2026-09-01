import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:iptv_demo/constant/colors.dart';
import 'package:iptv_demo/constant/strings.dart';
import 'package:iptv_demo/constant/theme_extensions.dart';
import 'package:iptv_demo/gen/assets.gen.dart';
import 'package:iptv_demo/widgets/custom_text.dart';
import 'package:simple_gradient_text/simple_gradient_text.dart';

void tvAuthHideKeyboard() {
  _TvAuthTextFieldState.endActiveEditing();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
}

/// Fixed height so prefix icon, text, and suffix align on one row.
double tvAuthInputHeight() => 56.h;

void tvAuthScrollFocusIntoView(FocusNode node) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!node.hasFocus) return;
    final ctx = node.context;
    if (ctx == null || !ctx.mounted) return;
    final ro = ctx.findRenderObject();
    if (ro == null || !ro.attached) return;
    Scrollable.maybeOf(ctx)?.position.ensureVisible(
          ro,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0.2,
        );
  });
}

void tvAuthMoveFocus(BuildContext context, {required bool forward}) {
  tvAuthHideKeyboard();
  if (forward) {
    FocusScope.of(context).nextFocus();
  } else {
    FocusScope.of(context).previousFocus();
  }
}

/// Full-screen shell: back bar + scroll + keyboard inset padding.
class TvAuthScaffold extends StatefulWidget {
  const TvAuthScaffold({
    super.key,
    required this.child,
    required this.primaryFieldFocus,
    this.onBackPressed,
    this.showBackButton = true,
  });

  final Widget child;
  final FocusNode primaryFieldFocus;
  final VoidCallback? onBackPressed;
  final bool showBackButton;

  @override
  State<TvAuthScaffold> createState() => _TvAuthScaffoldState();
}

class _TvAuthScaffoldState extends State<TvAuthScaffold> {
  bool _keyboardOpen() => MediaQuery.viewInsetsOf(context).bottom > 0;

  void _handlePop() {
    if (_keyboardOpen() || _TvAuthTextFieldState.hasActiveEditor) {
      tvAuthHideKeyboard();
      return;
    }
    if (!widget.showBackButton) return;
    if (widget.onBackPressed != null) {
      widget.onBackPressed!();
    } else {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handlePop();
      },
      child: Scaffold(
        backgroundColor: context.scaffoldBg,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.showBackButton)
                TvAuthTopBar(
                  firstFieldFocus: widget.primaryFieldFocus,
                  onBack: _handlePop,
                )
              else
                SizedBox(height: 12.h),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      EdgeInsets.fromLTRB(56.w, 12.h, 56.w, bottom + 48.h),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: widget.child,
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

class TvAuthTopBar extends StatefulWidget {
  const TvAuthTopBar({
    super.key,
    required this.firstFieldFocus,
    required this.onBack,
  });

  final FocusNode firstFieldFocus;
  final VoidCallback onBack;

  @override
  State<TvAuthTopBar> createState() => _TvAuthTopBarState();
}

class _TvAuthTopBarState extends State<TvAuthTopBar> {
  final _backFocus = FocusNode(debugLabel: 'tv_auth_back');
  bool _focused = false;

  @override
  void dispose() {
    _backFocus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.firstFieldFocus.requestFocus();
      tvAuthScrollFocusIntoView(widget.firstFieldFocus);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      widget.onBack();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 4.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FocusTraversalOrder(
          order: const NumericFocusOrder(0),
          child: Focus(
            focusNode: _backFocus,
            onFocusChange: (f) {
              setState(() => _focused = f);
              if (f) tvAuthScrollFocusIntoView(_backFocus);
            },
            onKeyEvent: _onKey,
            child: GestureDetector(
              onTap: widget.onBack,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: _focused ? AppColors.primary : AppColors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: context.textPrimary,
                      size: 22.sp,
                    ),
                    8.horizontalSpace,
                    CustomText(
                      'Back',
                      style: TextStyle(
                        fontFamily: AppStrings.interSemiBold,
                        fontSize: 16.sp,
                        color: context.textPrimary,
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
}

class TvAuthLogo extends StatelessWidget {
  const TvAuthLogo({super.key, this.height = 100});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Image.asset(
        Assets.images.login.logo.path,
        height: height.h,
        filterQuality: FilterQuality.high,
        fit: BoxFit.contain,
      ),
    );
  }
}

class TvAuthFormCard extends StatelessWidget {
  const TvAuthFormCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 720.w),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(32.h),
        decoration: BoxDecoration(
          color: context.cardBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: context.borderColor),
        ),
        child: child,
      ),
    );
  }
}

/// TV text field: D-pad highlights without keyboard until Select; Down moves on.
class TvAuthTextField extends StatefulWidget {
  const TvAuthTextField({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.decoration,
    required this.focusOrder,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.maxLength,
    this.inputFormatters,
    this.style,
    this.showFocusBorder = true,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final InputDecoration decoration;
  final FocusOrder focusOrder;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final TextStyle? style;
  final bool showFocusBorder;

  @override
  State<TvAuthTextField> createState() => _TvAuthTextFieldState();
}

class _TvAuthTextFieldState extends State<TvAuthTextField> {
  static _TvAuthTextFieldState? _activeEditor;

  static bool get hasActiveEditor => _activeEditor?._editing == true;

  static void endActiveEditing() {
    _activeEditor?._stopEditing(keepFocus: true);
  }

  bool _highlighted = false;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (_activeEditor == this) _activeEditor = null;
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    if (!mounted) return;
    final hasFocus = widget.focusNode.hasFocus;
    setState(() => _highlighted = hasFocus);
    if (hasFocus) {
      tvAuthScrollFocusIntoView(widget.focusNode);
    } else {
      _stopEditing(keepFocus: false);
    }
  }

  void _startEditing() {
    if (_editing) return;
    setState(() => _editing = true);
    _activeEditor = this;
    widget.focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod<void>('TextInput.show');
  }

  void _stopEditing({required bool keepFocus}) {
    if (!_editing) return;
    setState(() => _editing = false);
    if (_activeEditor == this) _activeEditor = null;
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    if (keepFocus) {
      widget.focusNode.requestFocus();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      if (!_editing) {
        _startEditing();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.goBack ||
        key == LogicalKeyboardKey.browserBack) {
      if (_editing) {
        _stopEditing(keepFocus: true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    final traversal = _handleTraversalKey(key);
    if (traversal == KeyEventResult.handled) return traversal;

    return KeyEventResult.ignored;
  }

  KeyEventResult _handleTraversalKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight) {
      _stopEditing(keepFocus: false);
      tvAuthMoveFocus(context, forward: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft) {
      _stopEditing(keepFocus: false);
      tvAuthMoveFocus(context, forward: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final field = TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      readOnly: !_editing,
      showCursor: _editing,
      enableInteractiveSelection: _editing,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      obscureText: widget.obscureText,
      maxLength: widget.maxLength,
      maxLines: 1,
      inputFormatters: widget.inputFormatters,
      textAlignVertical: TextAlignVertical.center,
      cursorColor: context.textPrimary,
      style: widget.style,
      decoration: widget.maxLength != null
          ? widget.decoration.copyWith(counterText: '')
          : widget.decoration,
    );

    final borderedField = widget.showFocusBorder
        ? AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: _highlighted ? AppColors.primary : AppColors.transparent,
                width: 2,
              ),
            ),
            child: field,
          )
        : field;

    final child = widget.showFocusBorder
        ? SizedBox(height: tvAuthInputHeight(), child: borderedField)
        : Align(alignment: Alignment.center, child: borderedField);

    return FocusTraversalOrder(
      order: widget.focusOrder,
      child: Focus(
        onKeyEvent: _onKey,
        child: child,
      ),
    );
  }
}

/// Password field with integrated, D-pad focusable visibility toggle.
class TvAuthPasswordField extends StatefulWidget {
  const TvAuthPasswordField({
    super.key,
    required this.focusNode,
    required this.controller,
    required this.fieldFocusOrder,
    required this.visibilityFocusOrder,
    required this.obscureText,
    required this.onToggleVisibility,
    required this.decoration,
    this.textInputAction,
    this.style,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final FocusOrder fieldFocusOrder;
  final FocusOrder visibilityFocusOrder;
  final bool obscureText;
  final VoidCallback onToggleVisibility;
  final InputDecoration decoration;
  final TextInputAction? textInputAction;
  final TextStyle? style;

  @override
  State<TvAuthPasswordField> createState() => _TvAuthPasswordFieldState();
}

class _TvAuthPasswordFieldState extends State<TvAuthPasswordField> {
  bool _visibilityFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFieldFocus);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFieldFocus);
    super.dispose();
  }

  void _onFieldFocus() {
    if (mounted) setState(() {});
  }

  bool get _fieldFocused => widget.focusNode.hasFocus;

  bool get _shellFocused => _fieldFocused || _visibilityFocused;

  InputDecoration _innerDecoration(BuildContext context) {
    return widget.decoration.copyWith(
      filled: false,
      fillColor: AppColors.transparent,
      isDense: true,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: EdgeInsets.only(right: 4.w),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: tvAuthInputHeight(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: context.inputFill,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: _shellFocused ? AppColors.primary : AppColors.transparent,
            width: 2,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TvAuthTextField(
                focusNode: widget.focusNode,
                controller: widget.controller,
                focusOrder: widget.fieldFocusOrder,
                obscureText: widget.obscureText,
                textInputAction: widget.textInputAction,
                style: widget.style,
                showFocusBorder: false,
                decoration: _innerDecoration(context),
              ),
            ),
            TvAuthVisibilityToggle(
              focusOrder: widget.visibilityFocusOrder,
              obscure: widget.obscureText,
              onToggle: widget.onToggleVisibility,
              integrated: true,
              onFocusChanged: (focused) {
                if (_visibilityFocused != focused) {
                  setState(() => _visibilityFocused = focused);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// D-pad focusable show/hide password control.
class TvAuthVisibilityToggle extends StatefulWidget {
  const TvAuthVisibilityToggle({
    super.key,
    required this.focusOrder,
    required this.obscure,
    required this.onToggle,
    this.integrated = false,
    this.onFocusChanged,
  });

  final FocusOrder focusOrder;
  final bool obscure;
  final VoidCallback onToggle;
  final bool integrated;
  final ValueChanged<bool>? onFocusChanged;

  @override
  State<TvAuthVisibilityToggle> createState() => _TvAuthVisibilityToggleState();
}

class _TvAuthVisibilityToggleState extends State<TvAuthVisibilityToggle> {
  final _focusNode = FocusNode(debugLabel: 'tv_auth_visibility');
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowRight) {
      tvAuthMoveFocus(context, forward: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp ||
        key == LogicalKeyboardKey.arrowLeft) {
      tvAuthMoveFocus(context, forward: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      widget.onToggle();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: widget.focusOrder,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (f) {
          setState(() => _focused = f);
          widget.onFocusChanged?.call(f);
          if (f) tvAuthScrollFocusIntoView(_focusNode);
        },
        onKeyEvent: _onKey,
        child: GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: widget.integrated ? 48.w : 48.w,
            height: widget.integrated ? 48.h : 48.h,
            margin: widget.integrated
                ? EdgeInsets.only(right: 8.w)
                : EdgeInsets.zero,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _focused
                  ? (widget.integrated
                      ? AppColors.primary.withValues(alpha: 0.14)
                      : context.inputFill)
                  : AppColors.transparent,
              borderRadius: BorderRadius.circular(
                widget.integrated ? 8.r : 12.r,
              ),
              border: widget.integrated
                  ? null
                  : Border.all(
                      color:
                          _focused ? AppColors.primary : context.borderColor,
                      width: 2,
                    ),
            ),
            child: Icon(
              widget.obscure
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 22.sp,
              color: _focused ? AppColors.primary : context.appIconColor,
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration tvAuthFieldDecoration(
  BuildContext context, {
  required String assetPath,
  double iconSize = 20,
  required String hint,
  Widget? suffix,
}) {
  return InputDecoration(
    isDense: true,
    prefixIcon: SizedBox(
      width: 52.w,
      child: Center(
        child: IgnorePointer(
          child: Image.asset(
            assetPath,
            height: iconSize.h,
            width: iconSize.w,
            fit: BoxFit.contain,
          ),
        ),
      ),
    ),
    suffixIcon: suffix == null ? null : ExcludeFocus(child: suffix),
    prefixIconConstraints: BoxConstraints(
      minWidth: 52.w,
      maxWidth: 52.w,
    ),
    suffixIconConstraints: suffix != null
        ? BoxConstraints(minHeight: 48.h, minWidth: 48.w)
        : null,
    contentPadding: EdgeInsets.symmetric(horizontal: 12.w),
    filled: true,
    fillColor: context.inputFill,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.r),
      borderSide: BorderSide.none,
    ),
    hintText: hint,
    hintStyle: TextStyle(
      fontFamily: AppStrings.interRegular,
      fontSize: 15.sp,
      color: context.textSecondary,
    ),
  );
}

/// TV action button — activates only on Select/Enter, not on focus.
class TvAuthGradientButton extends StatefulWidget {
  const TvAuthGradientButton({
    super.key,
    required this.label,
    required this.loading,
    required this.onPressed,
    this.trailing,
    this.focusOrder = const NumericFocusOrder(30),
  });

  final String label;
  final bool loading;
  final VoidCallback onPressed;
  final Widget? trailing;
  final FocusOrder focusOrder;

  @override
  State<TvAuthGradientButton> createState() => _TvAuthGradientButtonState();
}

class _TvAuthGradientButtonState extends State<TvAuthGradientButton> {
  final _focusNode = FocusNode(debugLabel: 'tv_auth_action');
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _activate() {
    if (!widget.loading) widget.onPressed();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      tvAuthMoveFocus(context, forward: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      tvAuthMoveFocus(context, forward: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      _activate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: widget.focusOrder,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (f) {
          setState(() => _focused = f);
          if (f) tvAuthScrollFocusIntoView(_focusNode);
        },
        onKeyEvent: _onKey,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 60.h,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: _focused ? AppColors.white : AppColors.transparent,
              width: 2,
            ),
          ),
          child: widget.loading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.white),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomText(
                      widget.label,
                      style: TextStyle(
                        color: AppColors.white,
                        fontFamily: AppStrings.interSemiBold,
                        fontSize: 17.sp,
                      ),
                    ),
                    if (widget.trailing != null) ...[
                      16.horizontalSpace,
                      widget.trailing!,
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class TvAuthLinkButton extends StatefulWidget {
  const TvAuthLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.focusOrder = const NumericFocusOrder(50),
  });

  final String label;
  final VoidCallback onPressed;
  final FocusOrder focusOrder;

  @override
  State<TvAuthLinkButton> createState() => _TvAuthLinkButtonState();
}

class _TvAuthLinkButtonState extends State<TvAuthLinkButton> {
  final _focusNode = FocusNode(debugLabel: 'tv_auth_link');
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      tvAuthMoveFocus(context, forward: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      tvAuthMoveFocus(context, forward: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: widget.focusOrder,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (f) {
          setState(() => _focused = f);
          if (f) tvAuthScrollFocusIntoView(_focusNode);
        },
        onKeyEvent: _onKey,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: _focused ? AppColors.primary : AppColors.transparent,
              width: 2,
            ),
          ),
          child: CustomText(
            widget.label,
            style: TextStyle(
              fontFamily: AppStrings.interSemiBold,
              fontSize: 14.sp,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

class TvAuthGradientLink extends StatefulWidget {
  const TvAuthGradientLink({
    super.key,
    required this.label,
    required this.onPressed,
    this.focusOrder = const NumericFocusOrder(40),
  });

  final String label;
  final VoidCallback onPressed;
  final FocusOrder focusOrder;

  @override
  State<TvAuthGradientLink> createState() => _TvAuthGradientLinkState();
}

class _TvAuthGradientLinkState extends State<TvAuthGradientLink> {
  final _focusNode = FocusNode(debugLabel: 'tv_auth_gradient_link');
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      tvAuthMoveFocus(context, forward: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      tvAuthMoveFocus(context, forward: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      widget.onPressed();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: widget.focusOrder,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (f) {
          setState(() => _focused = f);
          if (f) tvAuthScrollFocusIntoView(_focusNode);
        },
        onKeyEvent: _onKey,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: _focused ? AppColors.primary : AppColors.transparent,
              width: 2,
            ),
          ),
          child: GradientText(
            widget.label,
            colors: AppColors.primaryGradient,
            style: TextStyle(
              fontFamily: AppStrings.interBold,
              fontSize: 15.sp,
            ),
          ),
        ),
      ),
    );
  }
}

/// Focusable terms row for sign-up (order in traversal chain).
class TvAuthTermsCheckbox extends StatefulWidget {
  const TvAuthTermsCheckbox({
    super.key,
    required this.agreed,
    required this.onToggle,
    this.focusOrder = const NumericFocusOrder(25),
  });

  final bool agreed;
  final VoidCallback onToggle;
  final FocusOrder focusOrder;

  @override
  State<TvAuthTermsCheckbox> createState() => _TvAuthTermsCheckboxState();
}

class _TvAuthTermsCheckboxState extends State<TvAuthTermsCheckbox> {
  final _focusNode = FocusNode(debugLabel: 'tv_auth_terms');
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      tvAuthMoveFocus(context, forward: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      tvAuthMoveFocus(context, forward: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter) {
      widget.onToggle();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: widget.focusOrder,
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (f) {
          setState(() => _focused = f);
          if (f) tvAuthScrollFocusIntoView(_focusNode);
        },
        onKeyEvent: _onKey,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.r),
            border: Border.all(
              color: _focused ? AppColors.primary : AppColors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 24.w,
                height: 24.h,
                child: widget.agreed
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_rounded,
                            size: 18.sp,
                            color: AppColors.white,
                          ),
                        ),
                      )
                    : DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.all(color: context.borderColor),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
              ),
              10.horizontalSpace,
              Expanded(
                child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13.sp),
                      children: [
                        TextSpan(
                          text: AppStrings.agreeTo,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontFamily: AppStrings.interMedium,
                          ),
                        ),
                        TextSpan(
                          text: AppStrings.termsOfFlight,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontFamily: AppStrings.interSemiBold,
                          ),
                        ),
                        TextSpan(
                          text: AppStrings.andText,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontFamily: AppStrings.interMedium,
                          ),
                        ),
                        TextSpan(
                          text: AppStrings.privacyProtocols,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontFamily: AppStrings.interSemiBold,
                          ),
                        ),
                      ],
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
