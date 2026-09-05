import 'package:flutter/material.dart';

/// Design tokens ported from the BiteSync WeChat mini-program
/// (`miniprogram/styles/variables.wxss`), so the Flutter app keeps the same
/// soft-green, card-based health look.
class AppColors {
  const AppColors._();

  // ── Primary (soft green) ──
  static const primary = Color(0xFF6FCF97);
  static const primaryLight = Color(0xFFE8F8EF);
  static const primaryDark = Color(0xFF4BAE78);

  // ── Functional ──
  static const success = Color(0xFF27AE60);
  static const warning = Color(0xFFEB5757);
  static const warningLight = Color(0xFFFEF0F0);

  // ── Text ──
  static const textPrimary = Color(0xFF1F1F1F);
  static const textSecondary = Color(0xFF8A8A8A);
  static const textTertiary = Color(0xFFBEBEBE);

  // ── Background ──
  static const background = Color(0xFFF7F8F6);
  static const cardBackground = Color(0xFFFFFFFF);
  static const border = Color(0xFFEDEDED);

  // ── Macro nutrients (low saturation, restrained) ──
  static const protein = Color(0xFF6DBF8A);
  static const carbs = Color(0xFFF0C274);
  static const fat = Color(0xFFE8A0A0);
  static const proteinBg = Color(0xFFEDF7F1);
  static const carbsBg = Color(0xFFFEF8EC);
  static const fatBg = Color(0xFFFDF0F0);
}

/// Spacing scale, ported 1:1 (rpx / 2 == logical px at the mini-program's
/// base scale) from `variables.wxss`.
class AppSpacing {
  const AppSpacing._();

  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 18.0;
  static const xl = 28.0;
  static const xxl = 40.0;
  static const pagePadding = 16.0;
}

class AppRadius {
  const AppRadius._();

  static const sm = 4.0;
  static const md = 8.0;
  static const lg = 14.0;
  static const full = 999.0;
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      surface: AppColors.cardBackground,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'PingFang SC',
  );

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardBackground,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide.none,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textTertiary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );
}
