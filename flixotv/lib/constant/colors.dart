import 'package:flutter/material.dart';

/// Single source of truth for every color in the app.
///
/// Naming convention:
///   - Static constants without a suffix  → light-mode value (or theme-neutral)
///   - Static constants with `Dark` suffix → dark-mode override
///
/// Usage in widgets:
///   • Prefer `context.xxx` (ThemeExtensions) for anything that changes between
///     light and dark mode.
///   • Use `AppColors.xxx` directly only for truly theme-neutral values
///     (brand colors, status colors, player overlay colors, etc.).
class AppColors {
  AppColors._();

  // ─────────────────────────────────────────────────────────────────────────
  // BRAND / ACCENT  (theme-neutral – same in both modes)
  // ─────────────────────────────────────────────────────────────────────────

  /// Deep blue – primary brand color.
  static const Color primary = Color(0xFF212996);

  /// Purple – secondary brand color.
  static const Color secondary = Color(0xFF8410A5);

  /// Gradient used on buttons, chips, badges: [secondary → primary].
  static const List<Color> primaryGradient = [secondary, primary];

  /// Blue used for links and "View All" labels.
  static const Color linkBlue = Color(0xFF005AB6);

  // ─────────────────────────────────────────────────────────────────────────
  // STATUS / SEMANTIC  (theme-neutral)
  // ─────────────────────────────────────────────────────────────────────────

  /// LIVE badge background (light blue).
  static const Color liveBadgeBackground = Color(0xFFABC7FF);

  /// LIVE badge text (dark blue).
  static const Color liveBadgeText = Color(0xFF00458E);

  /// 4K quality badge background.
  static const Color badge4kBackground = Color(0xFF2563EB);

  /// HD quality badge background.
  static const Color badgeHdBackground = Color(0xFF16A34A);

  /// Favourite / heart icon.
  static const Color heart = Color(0xFFBA1A1A);

  /// Sign-out button text & border tint.
  static const Color danger = Color(0xFFBA1A1A);

  /// Progress bar fill.
  static const Color progress = Color(0xFF475F89);

  // ─────────────────────────────────────────────────────────────────────────
  // ALWAYS-WHITE / ALWAYS-BLACK  (theme-neutral)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);

  // ─────────────────────────────────────────────────────────────────────────
  // PLAYER / VIDEO OVERLAY  (always dark – shown over video)
  // ─────────────────────────────────────────────────────────────────────────

  /// Scrim gradient stop (80 % black).
  static const Color playerScrim = Color(0xCC000000);

  /// Control bar background.
  static const Color playerControlBar = Color(0x8C000000); // ~55 % black

  /// Slider active track.
  static const Color playerSliderActive = Colors.redAccent;

  /// Slider inactive track.
  static const Color playerSliderInactive = Color(0x80FFFFFF); // 50 % white

  /// Player text / icon colour.
  static const Color playerForeground = Colors.white;

  // ─────────────────────────────────────────────────────────────────────────
  // TV SIDE-NAV  (always dark panel – shown over dark background)
  // ─────────────────────────────────────────────────────────────────────────

  /// Side-nav panel background.
  static const Color tvNavBackground = Color(0xFF0E0E16);

  /// Active icon / label in side-nav.
  static const Color tvNavActiveItem = Colors.white;

  /// Inactive icon in side-nav.
  static const Color tvNavInactiveIcon = Color(0xFF6B6B7B);

  /// Inactive label in side-nav.
  static const Color tvNavInactiveLabel = Color(0xFF8A8A9A);

  /// Focused item highlight (10 % white).
  static const Color tvNavFocusedBg = Color(0x1AFFFFFF);

  /// Selected item highlight (5 % white).
  static const Color tvNavSelectedBg = Color(0x0DFFFFFF);

  /// Divider / separator (6 % white).
  static const Color tvNavDivider = Color(0x0FFFFFFF);

  /// Edge separator (7 % white).
  static const Color tvNavEdge = Color(0x12FFFFFF);

  // ─────────────────────────────────────────────────────────────────────────
  // TV BANNER FOCUS  (theme-neutral accent)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color tvBannerFocus = Color(0xFF6C3CE1);

  // ─────────────────────────────────────────────────────────────────────────
  // PREMIUM BOTTOM-SHEET GRADIENT  (theme-neutral)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color premiumGradientStart = Color(0xFF8E2DE2);
  static const Color premiumGradientEnd   = Color(0xFF4A00E0);
  static const List<Color> premiumGradient = [premiumGradientStart, premiumGradientEnd];

  // ─────────────────────────────────────────────────────────────────────────
  // USER PROFILE  (theme-neutral)
  // ─────────────────────────────────────────────────────────────────────────

  static const Color avatarBackground    = Color(0xFF369BB7);
  static const Color avatarBorder        = Color(0xFFEBDCFF);
  static const Color premiumBadgeText    = Color(0xFF260058);

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT-MODE SURFACES
  // ─────────────────────────────────────────────────────────────────────────

  /// Page / scaffold background.
  static const Color scaffoldLight       = Color(0xFFFFFFFF);

  /// App-bar / bottom-nav background.
  static const Color navBarLight         = Colors.white;

  /// Card background.
  static const Color cardLight           = Colors.white;

  /// Input / search field fill.
  static const Color inputFillLight      = Color(0xFFF2F4F7);

  /// Search field fill (slightly lighter).
  static const Color searchFillLight     = Color(0xFFF5F5F5);

  /// Unselected chip background.
  static const Color chipUnselectedLight = Color(0xFFEEEEEE);

  /// Divider / separator.
  static const Color dividerLight        = Color(0xFFE5E7EB);

  /// Logo / thumbnail container background.
  static const Color logoBgLight         = Color(0xFFF5F5F5);

  /// Subtle tint for icon containers (news cards, etc.).
  static const Color subtleTintLight     = Color(0xFFF1F5F9);

  /// Card border.
  static const Color cardBorderLight     = Color(0xFFE8EAF0);

  /// General border.
  static const Color borderLight         = Color(0xFFC1C6D5);

  /// Settings tile background.
  static const Color settingsTileLight   = Colors.white;

  /// Settings icon container background.
  static const Color settingsIconBgLight = Color(0xFFE7E8EA);

  /// Plan / subscription card background.
  static const Color planCardLight       = Color(0xFFF2F4F6);

  /// Bottom-nav selected item background.
  static const Color navSelectedLight    = Color(0xFFEFF6FF);

  // ─────────────────────────────────────────────────────────────────────────
  // CHANNEL SCHEDULE (mobile — light)
  // ─────────────────────────────────────────────────────────────────────────

  /// Schedule screen scaffold background.
  static const Color channelScheduleScaffold = Color(0xFFF7F9FC);

  /// Back arrow / header accent on schedule.
  static const Color channelScheduleHeaderAccent = Color(0xFF2F80ED);

  /// 48×48 logo chrome fill (`#E6E8EB`).
  static const Color channelScheduleThumbnailFill = Color(0xFFE6E8EB);

  /// Progress bar track under active program.
  static const Color channelScheduleProgressTrack = Color(0xFFE8ECF0);

  /// TV scaffold background.
  static const Color tvScaffoldLight     = Color(0xFFF3F4F6);

  // ─────────────────────────────────────────────────────────────────────────
  // LIGHT-MODE TEXT
  // ─────────────────────────────────────────────────────────────────────────

  static const Color textPrimaryLight    = Color(0xFF191C1E);
  static const Color textSecondaryLight  = Color(0xFF414753);
  static const Color textMutedLight      = Color(0xFF727785);
  static const Color iconColorLight      = Color(0xFF64748B);
  static const Color planCardTextLight   = Color(0xFF64748B);
  static const Color planDetailTextLight = Color(0xFF414751);
  static const Color tvSectionTitleLight = Color(0xFF111827);
  static const Color tvSubtitleLight     = Color(0xFF6B7280);
  static const Color tvTabUnfocusedLight = Color(0xFF999999);
  static const Color tvTabFocusedLight   = Color(0xFF333333);

  // ─────────────────────────────────────────────────────────────────────────
  // DARK-MODE SURFACES
  // ─────────────────────────────────────────────────────────────────────────

  /// Page / scaffold background.
  static const Color scaffoldDark        = Color(0xFF0F0F14);

  /// App-bar / bottom-nav background.
  static const Color navBarDark          = Color(0xFF16161E);

  /// Card background.
  static const Color cardDark            = Color(0xFF1C1C26);

  /// Input / search field fill.
  static const Color inputFillDark       = Color(0xFF23232F);

  /// Unselected chip background.
  static const Color chipUnselectedDark  = Color(0xFF23232F);

  /// Divider / separator.
  static const Color dividerDark         = Color(0xFF2A2A38);

  /// Logo / thumbnail container background.
  static const Color logoBgDark          = Color(0xFF12121A);

  /// Card border.
  static const Color cardBorderDark      = Color(0xFF2A2A38);

  /// General border.
  static const Color borderDark          = Color(0xFF2A2A38);

  /// Settings icon container background.
  static const Color settingsIconBgDark  = Color(0xFF23232F);

  /// TV focus pill background (primary at 20 % opacity).
  static const Color tvFocusPillDark     = Color(0x33212996);

  /// Bottom-nav selected item background (primary at 25 % opacity).
  static const Color navSelectedDark     = Color(0x40212996);

  // ─────────────────────────────────────────────────────────────────────────
  // DARK-MODE TEXT
  // ─────────────────────────────────────────────────────────────────────────

  static const Color textPrimaryDark     = Color(0xFFF0F0F5);
  static const Color textSecondaryDark   = Color(0xFFC0C0D0);
  static const Color textMutedDark       = Color(0xFF5A5A6E);
  static const Color iconColorDark       = Color(0xFFB0B0C8);
  static const Color planCardTextDark    = Color(0xFF7878A0);
  static const Color tvSectionTitleDark  = Color(0xFFF0F0F5);
  static const Color tvSubtitleDark      = Color(0xFFB5B5CC);
  static const Color tvTabUnfocusedDark  = Color(0xFF5A5A6E);
  static const Color tvTabFocusedDark    = Color(0xFFF0F0F5);

  // ─────────────────────────────────────────────────────────────────────────
  // LEGACY ALIASES  (kept for backward-compat; prefer context.xxx instead)
  // ─────────────────────────────────────────────────────────────────────────

  /// @deprecated Use context.scaffoldBg
  static const Color scaffoldBackground  = scaffoldLight;

  /// @deprecated Use context.textPrimary
  static const Color textPrimary         = textPrimaryLight;

  /// @deprecated Use context.textSecondary
  static const Color textSecondary       = textSecondaryLight;

  /// @deprecated Use context.textMuted
  static const Color textMuted           = textMutedLight;

  /// @deprecated Use context.borderColor
  static const Color border              = borderLight;

  /// @deprecated Use context.inputFill
  static const Color inputFill           = inputFillLight;

  static const Color cardTint            = Color(0xFFEDEFF2);
  static const Color grey50              = Color(0xFFFAFAFA);
  static const Color grey100             = Color(0xFFF5F5F5);
  static const Color grey200             = Color(0xFFEEEEEE);
  static const Color grey300             = Color(0xFFE0E0E0);
  static const Color grey                = Colors.grey;
  static const Color grey1               = scaffoldLight;
  static const Color grey2               = Color(0xFFE2E8F0);
  static const Color blueGrey            = Color(0xFF64748B);
  static const Color base                = scaffoldLight;
  static const Color bottomIconbg        = navSelectedLight;

  // Settings legacy aliases
  static const Color userProfilePictureBG          = avatarBackground;
  static const Color userProfilePictureBorder       = avatarBorder;
  static const Color userProfilePremiumBadgeText    = premiumBadgeText;
  static const Color currentPlanInfoCardBackground  = planCardLight;
  static const Color currentPlanInfoCardTextColor   = planCardTextLight;
  static const Color currentPlanInfoTexteColor      = planDetailTextLight;
  static const Color settingsIconsColor             = Color(0xFF005DA7);
  static const Color settingsIconsBGColor           = settingsIconBgLight;
  static const Color signOutButtonTextColor         = danger;
  static final  Color signOutButtonBorderColor      = danger.withValues(alpha: 0.1);
  static final  Color shadowColor                   = const Color(0xFF191C1E).withValues(alpha: 0.1);
}
