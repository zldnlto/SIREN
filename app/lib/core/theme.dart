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
      color: AppColors.surface, // Carbon Inverse Surface 1
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // IBM Carbon 0px Sharp corners
        side: BorderSide(color: AppColors.border, width: 1), // 1px Gray-80 hairline
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary, // Confident IBM Blue primary CTA
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin), // 48px Touch target
        textStyle: AppTextStyles.buttonLg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // IBM Carbon 0px Sharp corners
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.transparent, // Ghost / Tertiary button transparent fill
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin), // 48px Touch target
        foregroundColor: AppColors.primary, // IBM Blue text
        textStyle: AppTextStyles.buttonMd,
        side: const BorderSide(color: AppColors.primary, width: 1), // Blue 1px hairline border
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // IBM Carbon 0px Sharp corners
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.zero, // IBM Carbon 0px Sharp corners
        borderSide: BorderSide(color: AppColors.border, width: 1), // 1px Gray-80 hairline
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.primary, width: 2), // Carbon's 2px focus border
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.error, width: 2), // Carbon's 2px error border
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.error, width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 11), // Carbon spec vertical 11px
    ),
  );
}
