import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';

/// Centralised Material theme configuration.
/// Every colour value comes from [AppColors] – no raw hex here.
class AppTheme {
  AppTheme._();

  // ── Light theme ────────────────────────────────────────────────────────────

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardLight,
        onSurface: AppColors.textPrimaryLight,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navBarLight,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardLight,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.dividerLight),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.textMutedLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.grey300;
        }),
      ),
      textTheme: const TextTheme(
        bodyLarge:  TextStyle(color: AppColors.textPrimaryLight),
        bodyMedium: TextStyle(color: AppColors.textSecondaryLight),
        bodySmall:  TextStyle(color: AppColors.textMutedLight),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillLight,
        hintStyle: const TextStyle(color: AppColors.textMutedLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  // ── Dark theme ─────────────────────────────────────────────────────────────

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.cardDark,
        onSurface: AppColors.textPrimaryDark,
      ),
      scaffoldBackgroundColor: AppColors.scaffoldDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.navBarDark,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.dividerDark),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.textMutedDark;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.dividerDark;
        }),
      ),
      textTheme: const TextTheme(
        bodyLarge:  TextStyle(color: AppColors.textPrimaryDark),
        bodyMedium: TextStyle(color: AppColors.textSecondaryDark),
        bodySmall:  TextStyle(color: AppColors.textMutedDark),
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFillDark,
        hintStyle: const TextStyle(color: AppColors.textMutedDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
