import 'package:flutter/material.dart';

/// Design tokens ported from the BiteSync WeChat mini-program
/// (`miniprogram/styles/variables.wxss`), so the Flutter app keeps the same
/// soft-blue, card-based health look.
class AppColors {
  const AppColors._();

  // ── Primary (soft blue) ──
  static const primary = Color(0xFF62B5E5);
  static const primaryLight = Color(0xFFE8F5FC);
  static const primaryDark = Color(0xFF3D91BE);

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

  static const darkPrimary = Color(0xFF00AEFF);
  static const darkBackground = Color(0xFF000000);
  static const darkCard = Color(0xFF0D0D0D);
  static const darkSurface = Color(0xFF121212);
  static const darkInput = Color(0xFF101010);
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

ThemeData buildLightTheme() {
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

ThemeData buildDarkTheme() {
  const primary = AppColors.darkPrimary;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
    primary: primary,
    onPrimary: Colors.black,
    surface: AppColors.darkBackground,
    onSurface: Colors.white,
  );
  final darkColorScheme = colorScheme.copyWith(
    surface: AppColors.darkBackground,
    surfaceDim: AppColors.darkBackground,
    surfaceBright: AppColors.darkSurface,
    surfaceContainerLowest: AppColors.darkBackground,
    surfaceContainerLow: AppColors.darkCard,
    surfaceContainer: AppColors.darkCard,
    surfaceContainerHigh: AppColors.darkSurface,
    surfaceContainerHighest: AppColors.darkSurface,
    onSurface: Colors.white,
    onSurfaceVariant: Colors.white.withValues(alpha: 0.70),
    outline: Colors.white.withValues(alpha: 0.20),
    outlineVariant: Colors.white.withValues(alpha: 0.10),
  );
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: darkColorScheme,
    scaffoldBackgroundColor: AppColors.darkBackground,
    canvasColor: AppColors.darkBackground,
    fontFamily: 'PingFang SC',
  );
  final darkSecondary = Colors.white.withValues(alpha: 0.70);
  final darkTertiary = Colors.white.withValues(alpha: 0.45);

  return base.copyWith(
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBackground,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.w700,
      ),
    ),
    textTheme: base.textTheme.copyWith(
      displayLarge: base.textTheme.displayLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      displayMedium: base.textTheme.displayMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      displaySmall: base.textTheme.displaySmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: base.textTheme.titleSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.textTheme.labelSmall?.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.darkCard),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: const BorderSide(color: primary),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.darkInput,
      labelStyle: TextStyle(color: darkSecondary, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: darkTertiary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.darkBackground,
      selectedItemColor: primary,
      unselectedItemColor: darkTertiary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
    dividerColor: Colors.white.withValues(alpha: 0.10),
    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primary),
    chipTheme: base.chipTheme.copyWith(
      selectedColor: primary,
      secondarySelectedColor: primary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(primary),
      trackColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.35)),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected) ? primary : null,
      ),
      checkColor: const WidgetStatePropertyAll(Colors.black),
    ),
    radioTheme: RadioThemeData(
      fillColor: const WidgetStatePropertyAll(primary),
    ),
    sliderTheme: base.sliderTheme.copyWith(
      activeTrackColor: primary,
      thumbColor: primary,
      overlayColor: primary.withValues(alpha: 0.18),
    ),
  );
}

ThemeData buildAppTheme() => buildLightTheme();
