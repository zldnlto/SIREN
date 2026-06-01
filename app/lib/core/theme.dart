import 'package:flutter/material.dart';
import 'tokens.dart';

const kDefectColor = AppColors.defect;
const kGoodColor = AppColors.good;
const kAccentColor = AppColors.primary;

// shortestSide(dp) 기준 breakpoint — supported_devices.md 참고
const double kTabletBreakpoint = 600;
const double kDesktopBreakpoint = 960;

ThemeData buildAppTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSurface,
      secondaryContainer: AppColors.surface,
      tertiary: AppColors.tertiary,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.border,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      color: AppColors.surface, // Night surface
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderXl, // Sentry rounded.xl (12px)
        side: BorderSide(color: AppColors.border, width: 1), // 1px Hairline Violet
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.white, // Inverted Primary CTA (White on dark)
        foregroundColor: AppColors.background, // Deep Violet Midnight text
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin), // 44px
        textStyle: AppTextStyles.buttonLg,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd, // Sentry rounded.md (8px)
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primaryContainer, // Ghost button fill (rgba(255,255,255,0.18))
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin), // 44px
        foregroundColor: AppColors.onSurface,
        textStyle: AppTextStyles.buttonMd,
        side: BorderSide.none, // Ghost button has no borders
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd, // Sentry rounded.md (8px)
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderSm, // Sentry rounded.sm (6px)
        borderSide: BorderSide(color: AppColors.borderSubtle, width: 1), // 1px Hairline Cool
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: BorderSide(color: AppColors.borderSubtle, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: BorderSide(color: AppColors.secondary, width: 1.5), // Violet focus outline
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: BorderSide(color: AppColors.error, width: 1.5), // Pink error outline
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderSm,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
  );
}
