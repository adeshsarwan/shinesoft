import 'package:flutter/material.dart';
import 'colors.dart';

/// BuildContext extension – every theme-aware color in one place.
///
/// All values delegate to the named constants in [AppColors] so there is
/// a single source of truth.  Add new semantic tokens here; never inline
/// raw hex values in widget files.
extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Scaffold / page background ────────────────────────────────────────────
  Color get scaffoldBg =>
      isDark ? AppColors.scaffoldDark : AppColors.scaffoldLight;

  // ── App-bar / bottom-nav background ──────────────────────────────────────
  Color get navBarBg =>
      isDark ? AppColors.navBarDark : AppColors.navBarLight;

  // ── Card background ───────────────────────────────────────────────────────
  Color get cardBg =>
      isDark ? AppColors.cardDark : AppColors.cardLight;

  // ── Input / text-field fill ───────────────────────────────────────────────
  Color get inputFill =>
      isDark ? AppColors.inputFillDark : AppColors.inputFillLight;

  // ── Search-bar fill ───────────────────────────────────────────────────────
  Color get searchFill =>
      isDark ? AppColors.inputFillDark : AppColors.searchFillLight;

  // ── Unselected chip / filter pill background ──────────────────────────────
  Color get chipUnselectedBg =>
      isDark ? AppColors.chipUnselectedDark : AppColors.chipUnselectedLight;

  // ── Divider / separator ───────────────────────────────────────────────────
  Color get dividerColor =>
      isDark ? AppColors.dividerDark : AppColors.dividerLight;

  // ── Logo / thumbnail container background ────────────────────────────────
  Color get logoBg =>
      isDark ? AppColors.logoBgDark : AppColors.logoBgLight;

  // ── Subtle tint (news icon bg, shimmer base, etc.) ────────────────────────
  Color get subtleTint =>
      isDark ? AppColors.cardDark : AppColors.subtleTintLight;

  // ── Text ──────────────────────────────────────────────────────────────────
  Color get textPrimary =>
      isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

  Color get textSecondary =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  Color get textMuted =>
      isDark ? const Color(0xFF8888A0) : AppColors.textMutedLight;

  // ── Icon colour (app-bar, nav icons) ─────────────────────────────────────
  Color get appIconColor =>
      isDark ? AppColors.iconColorDark : AppColors.iconColorLight;

  // ── Borders ───────────────────────────────────────────────────────────────
  Color get borderColor =>
      isDark ? AppColors.borderDark : AppColors.borderLight;

  Color get cardBorderColor =>
      isDark ? AppColors.cardBorderDark : AppColors.cardBorderLight;

  // ── Settings ──────────────────────────────────────────────────────────────
  Color get settingsTileBg =>
      isDark ? AppColors.cardDark : AppColors.settingsTileLight;

  Color get settingsIconBg =>
      isDark ? AppColors.settingsIconBgDark : AppColors.settingsIconBgLight;

  // ── Plan / subscription card ──────────────────────────────────────────────
  Color get planCardBg =>
      isDark ? AppColors.cardDark : AppColors.planCardLight;

  Color get planCardTextColor =>
      isDark ? AppColors.planCardTextDark : AppColors.planCardTextLight;

  Color get planDetailTextColor =>
      isDark ? AppColors.textSecondaryDark : AppColors.planDetailTextLight;

  // ── Bottom-nav selected item background ───────────────────────────────────
  Color get navSelectedBg =>
      isDark ? AppColors.navSelectedDark : AppColors.navSelectedLight;

  // ── TV scaffold ───────────────────────────────────────────────────────────
  Color get tvScaffoldBg =>
      isDark ? AppColors.scaffoldDark : AppColors.tvScaffoldLight;

  // ── TV top-nav bar ────────────────────────────────────────────────────────
  Color get tvTopNavBg =>
      isDark ? AppColors.navBarDark : AppColors.navBarLight;

  // ── TV section title ──────────────────────────────────────────────────────
  Color get tvSectionTitleColor =>
      isDark ? AppColors.tvSectionTitleDark : AppColors.tvSectionTitleLight;

  // ── TV card background ────────────────────────────────────────────────────
  Color get tvCardBg =>
      isDark ? AppColors.cardDark : AppColors.cardLight;

  // ── TV card subtitle / secondary text ────────────────────────────────────
  Color get tvSubtitleColor =>
      isDark ? AppColors.tvSubtitleDark : AppColors.tvSubtitleLight;

  // ── TV top-nav focus pill ─────────────────────────────────────────────────
  Color get tvFocusPillBg =>
      isDark ? AppColors.tvFocusPillDark : const Color(0xFFF0EBFF);

  // ── TV top-nav tab text ───────────────────────────────────────────────────
  Color get tvUnfocusedTabColor =>
      isDark ? AppColors.tvTabUnfocusedDark : AppColors.tvTabUnfocusedLight;

  Color get tvFocusedTabColor =>
      isDark ? AppColors.tvTabFocusedDark : AppColors.tvTabFocusedLight;
}
