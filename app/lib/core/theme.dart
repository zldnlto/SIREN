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
      color: AppColors.surface, // Linear Surface 1 (#0F1011)
      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg, // Linear cards use rounded.lg (12px)
        side: BorderSide(color: AppColors.border, width: 1), // 1px hairline border (#23252A)
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.primary, // Signature Lavender primary CTA
        foregroundColor: AppColors.onPrimary,
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin), // 40px compact target
        textStyle: AppTextStyles.buttonLg,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd, // linear.app buttons use rounded.md (8px)
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        elevation: 0,
        backgroundColor: AppColors.surface, // button-secondary uses surface-1
        minimumSize: const Size.fromHeight(AppSpacing.touchTargetMin), // 40px compact target
        foregroundColor: AppColors.onSurface, // Light Ink text
        textStyle: AppTextStyles.buttonMd,
        side: const BorderSide(color: AppColors.border, width: 1), // 1px hairline border
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd, // linear.app buttons use rounded.md (8px)
        ),
      ),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.borderMd, // linear.app inputs use rounded.md (8px)
        borderSide: BorderSide(color: AppColors.border, width: 1), // 1px hairline border
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.border, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.primary, width: 1.5), // Lavender focus ring
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: BorderSide(color: AppColors.error, width: 1.5),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8), // linear.app compact padding
    ),
  );
}
