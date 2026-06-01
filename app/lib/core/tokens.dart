import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Surface hierarchy (OLED dark, utilitarian sharp layers)
  static const background = Color(0xFF0E0E0E);
  static const surface = Color(0xFF131313);
  static const surfaceVariant = Color(0xFF1C1B1B); // low
  static const surfaceTertiary = Color(0xFF201F1F); // container
  static const surfaceOverlay = Color(0xFF2A2A2A); // high

  // Primary — Steel Blue (overridePrimaryColor #3498DB)
  static const primary = Color(0xFF3498DB);
  static const primaryDark = Color(0xFF2980B9);
  static const primaryLight = Color(0xFF5DADE2);
  static const primaryContainer = Color(0xFF1A3A5C);

  // Secondary — Deep Navy (overrideSecondaryColor #1E233D)
  static const secondary = Color(0xFF1E233D);
  static const secondaryDark = Color(0xFF13172B);
  static const secondaryLight = Color(0xFF2D3354);

  // Severity & Accent
  static const good = Color(0xFF2ECC71); // 양호 (Green)
  static const warning = Color(0xFFFFD60A); // 주의 (Safety Yellow / overrideTertiaryColor #FFD60A)
  static const defect = Color(0xFFFF3B30); // 결함 (Danger Red)
  static const critical = Color(0xFFC0392B); // 위험 (Dark Red)

  static const severityGoodContainer = Color(0xFF1A3D2B);
  static const severityWarningContainer = Color(0xFF3D3300);
  static const severityDefectContainer = Color(0xFF3D1A1A);
  static const severityCriticalContainer = Color(0xFF2D0F0F);

  // Content on surfaces
  static const onBackground = Color(0xFFE5E2E1);
  static const onSurface = Color(0xFFE5E2E1);
  static const onSurfaceVariant = Color(0xFFBFC7D2);
  static const onSurfaceMuted = Color(0xFF89929B);
  static const onPrimary = Color(0xFFFFFFFF); // primary 버튼 위 텍스트

  // Accent — Safety Yellow (overrideTertiaryColor #FFD60A)
  static const accent = Color(0xFFFFD60A);

  // Disabled
  static const disabled = Color(0xFF353534);
  static const onDisabled = Color(0xFF89929B);

  // Border / divider
  static const border = Color(0xFF3F4850); // outlineVariant
  static const borderSubtle = Color(0xFF1E233D); // secondary

  // Destructive — UI 파괴 액션용
  static const destructive = defect;
}

// ─── Breakpoints ─────────────────────────────────────────────────────────────

abstract final class AppBreakpoints {
  static const double tablet = 600;
}

// ─── Spacing ─────────────────────────────────────────────────────────────────

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8; // stack-sm
  static const double md = 16; // gutter, stack-md
  static const double lg = 24; // stack-lg
  static const double xl = 32; // margin-tablet
  static const double x2l = 48;
  static const double x3l = 64;

  static const double touchTargetMin = 56.0; // touch-target-min
  static const double marginMobile = 20.0; // margin-mobile
}

// ─── Border Radius ────────────────────────────────────────────────────────────

abstract final class AppRadius {
  // Sharp (0px) corners for all industrial components
  static const double xs = 0;
  static const double sm = 0;
  static const double md = 0;
  static const double lg = 0;
  static const double xl = 0;
  static const double full = 0;

  static const borderXs = BorderRadius.zero;
  static const borderSm = BorderRadius.zero;
  static const borderMd = BorderRadius.zero;
  static const borderLg = BorderRadius.zero;
  static const borderXl = BorderRadius.zero;
  static const borderFull = BorderRadius.zero;
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
//
// Work Sans  — body, labels, UI
// JetBrains Mono  — inspection IDs, metric values, defect codes (Stitch labelFont)

abstract final class AppTextStyles {
  // Display & Headline
  static final TextStyle headlineLg = GoogleFonts.workSans(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    height: 40 / 34,
    letterSpacing: -0.02 * 34,
  );

  static final TextStyle headlineMd = GoogleFonts.workSans(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    height: 34 / 28,
    letterSpacing: -0.01 * 28,
  );

  static final TextStyle headlineSm = GoogleFonts.workSans(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 28 / 22,
  );

  // Section header — used in report sections
  static final TextStyle sectionHeader = GoogleFonts.workSans(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.8,
  );

  // Body
  static final TextStyle bodyLg = GoogleFonts.workSans(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    height: 26 / 18,
  );

  static final TextStyle bodyMd = GoogleFonts.workSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 24 / 16,
  );

  static final TextStyle bodySm = GoogleFonts.workSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  // Label
  static final TextStyle labelLg = GoogleFonts.workSans(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 20 / 14,
  );

  static final TextStyle labelMd = GoogleFonts.workSans(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
    height: 16 / 12,
  );

  static final TextStyle labelSm = GoogleFonts.workSans(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceMuted,
    letterSpacing: 0.3,
  );

    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  // Button
  static final TextStyle buttonLg = GoogleFonts.ibmPlexSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.2,
  );

  static final TextStyle buttonMd = GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onPrimary,
    letterSpacing: 0.2,
  );
}

// ─── Shadows ─────────────────────────────────────────────────────────────────

abstract final class AppShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 0)),
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(color: Color(0x29000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  // Blue glow — primary interactive elements
  static const List<BoxShadow> primaryGlow = [
    BoxShadow(color: Color(0x4D3498DB), blurRadius: 12, offset: Offset(0, 2)),
  ];

  // Yellow glow — warning / accent states
  static const List<BoxShadow> accentGlow = [
    BoxShadow(color: Color(0x33FFD60A), blurRadius: 10, offset: Offset(0, 2)),
  ];
}

// ─── Animation Durations ─────────────────────────────────────────────────────

abstract final class AppDurations {
  static const instant = Duration.zero;
  static const exit = Duration(milliseconds: 100); // exit은 enter보다 짧게
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 300);
}

abstract final class AppCurves {
  static const enter = Curves.easeOut;
  static const exit = Curves.easeIn;
  static const standard = Curves.easeInOut;
}
