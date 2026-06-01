import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // IBM Carbon Gray 100 Dark theme canvas polarity
  static const background = Color(0xFF161616); // Inverse Canvas - Dark
  static const surface = Color(0xFF262626); // Inverse Surface 1 - Dark card
  static const surfaceVariant = Color(0xFF161616);
  static const surfaceTertiary = Color(0xFF393939); // Gray-80
  static const surfaceOverlay = Color(0xFF262626);

  // IBM Blue confidence accents
  static const primary = Color(0xFF0F62FE); // IBM Blue
  static const primaryDark = Color(0xFF002D9C);
  static const primaryLight = Color(0xFF0050E6);
  static const primaryContainer = Color(0xFF262626);

  static const secondary = Color(0xFF393939); // Gray-80
  static const secondaryDark = Color(0xFF161616);
  static const secondaryLight = Color(0xFF525252);

  // Semantic mappings faithfully following Carbon
  static const good = Color(0xFF24A148); // Success (Green-50)
  static const warning = Color(0xFFF1C21B); // Warning (Yellow-30)
  static const defect = Color(0xFFDA1E28); // Error (Red-60)
  static const critical = Color(0xFFDA1E28);

  static const severityGoodContainer = Color(0xFF1A3D2B);
  static const severityWarningContainer = Color(0xFF3D3300);
  static const severityDefectContainer = Color(0xFF3D1A1A);
  static const severityCriticalContainer = Color(0xFF2D0F0F);

  // Content on surfaces
  static const onBackground = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFC6C6C6); // Inverse Ink Muted
  static const onSurfaceMuted = Color(0xFF8D8D8D); // Inverse Ink Subtle
  static const onPrimary = Color(0xFFFFFFFF); // primary 버튼 위 텍스트

  // Accent
  static const accent = Color(0xFF0F62FE); // IBM Blue

  // Disabled
  static const disabled = Color(0xFF525252);
  static const onDisabled = Color(0xFF8D8D8D);

  // Border / divider (Carbon hairlines)
  static const border = Color(0xFF393939); // Gray-80 border
  static const borderSubtle = Color(0xFF262626);
  static const borderCloud = Color(0xFFE0E0E0); // Hairline Cloud

  // Semantic mappings
  static const tertiary = primary;
  static const error = defect;

  // Destructive
  static const destructive = defect;
}

// ─── Breakpoints ─────────────────────────────────────────────────────────────

abstract final class AppBreakpoints {
  static const double tablet = 600;
}

abstract final class AppSpacing {
  static const double xxs = 4; // xxs
  static const double xs = 8; // xs
  static const double sm = 12; // sm
  static const double md = 16; // md
  static const double lg = 24; // lg
  static const double xl = 32; // xl
  static const double xxl = 48; // xxl
  static const double section = 96; // section

  static const double touchTargetMin = 48.0; // Carbon touch-target-min
  static const double marginMobile = 16.0;
}

// ─── Border Radius ────────────────────────────────────────────────────────────

abstract final class AppRadius {
  // Flat-square Carbon aesthetics
  static const double xs = 0;
  static const double sm = 0;
  static const double md = 0;
  static const double lg = 0;
  static const double xl = 0;
  static const double xxl = 0;
  static const double full = 9999; // Only circular icon button / avatars

  static const borderXs = BorderRadius.zero;
  static const borderSm = BorderRadius.zero;
  static const borderMd = BorderRadius.zero;
  static const borderLg = BorderRadius.zero;
  static const borderXl = BorderRadius.zero;
  static const borderFull = BorderRadius.all(Radius.circular(full));
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
// IBM Plex Sans  — display, body, labels, UI
// IBM Plex Mono  — inspection IDs, metric values, code blocks

abstract final class AppTextStyles {
  // Display & Headline (IBM Plex Sans at light weight 300)
  static final TextStyle displayHero = GoogleFonts.ibmPlexSans(
    fontSize: 76,
    fontWeight: FontWeight.w300, // Light displaying
    color: AppColors.onBackground,
    height: 1.17,
    letterSpacing: -0.5,
  );

  static final TextStyle displayLarge = GoogleFonts.ibmPlexSans(
    fontSize: 60,
    fontWeight: FontWeight.w300,
    color: AppColors.onBackground,
    height: 1.17,
    letterSpacing: -0.4,
  );

  static final TextStyle headlineXl = GoogleFonts.ibmPlexSans(
    fontSize: 42,
    fontWeight: FontWeight.w300,
    color: AppColors.onBackground,
    height: 1.2,
  );

  static final TextStyle headlineLg = GoogleFonts.ibmPlexSans(
    fontSize: 32,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
    height: 1.25,
  );

  static final TextStyle headlineMd = GoogleFonts.ibmPlexSans(
    fontSize: 24,
    fontWeight: FontWeight.w400,
    color: AppColors.onBackground,
    height: 1.33,
  );

  static final TextStyle headlineSm = GoogleFonts.ibmPlexSans(
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.4,
  );

  // Section header — eyebrow above headings (Carbon sentence case 14px)
  static final TextStyle sectionHeader = GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.29,
    letterSpacing: 0.16,
  );

  // Body
  static final TextStyle bodyLg = GoogleFonts.ibmPlexSans(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static final TextStyle bodyStrong = GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.29,
    letterSpacing: 0.16,
  );

  static final TextStyle bodyMd = GoogleFonts.ibmPlexSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5, // functional UI body
    letterSpacing: 0.16, // Carbon precision detail
  );

  static final TextStyle bodySm = GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.29,
    letterSpacing: 0.16,
  );

  // Label
  static final TextStyle labelLg = GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.29,
    letterSpacing: 0.16,
  );

  static final TextStyle labelMd = GoogleFonts.ibmPlexSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.33,
    letterSpacing: 0.32,
  );

  static final TextStyle labelSm = GoogleFonts.ibmPlexSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceMuted,
    letterSpacing: 0.32,
    height: 1.33,
  );

  // Mono — IBM Plex Mono
  static final TextStyle monoLg = GoogleFonts.ibmPlexMono(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static final TextStyle monoMd = GoogleFonts.ibmPlexMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static final TextStyle monoSm = GoogleFonts.ibmPlexMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  // Button
  static final TextStyle buttonLg = GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onPrimary,
    letterSpacing: 0.16,
    height: 1.29,
  );

  static final TextStyle buttonMd = GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onPrimary,
    letterSpacing: 0.16,
    height: 1.29,
  );

  // Fallback aliases for other screens' legacy style references
  static final TextStyle titleLg = headlineLg;
  static final TextStyle titleMd = headlineMd;
  static final TextStyle titleSm = headlineSm;
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
