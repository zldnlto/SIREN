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
      secondaryContainer: AppColors.surfaceVariant,
      tertiary: AppColors.tertiary,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surfaceVariant,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // Sharp (0px) corners
        side: BorderSide(color: AppColors.borderSubtle, width: 2), // 2px Bold border (secondary)
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin), // 56px
        textStyle: AppTextStyles.buttonLg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Sharp (0px) corners
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin), // 56px
        foregroundColor: AppColors.onSurface,
        textStyle: AppTextStyles.buttonMd,
        side: const BorderSide(color: AppColors.primary, width: 2), // 2px Border
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Sharp (0px) corners
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 2), // 2px primary focus border
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    ),
  );
}
