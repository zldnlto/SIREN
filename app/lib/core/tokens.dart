import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // linear.app near-black canvas and surface ladders
  static const background = Color(0xFF010102); // Deepest Canvas Polarity
  static const surface = Color(0xFF0F1011); // Surface 1 - cards
  static const surfaceVariant = Color(0xFF141516); // Surface 2
  static const surfaceTertiary = Color(0xFF18191A); // Surface 3
  static const surfaceOverlay = Color(0xFF000000);

  // Linear lavender-blue confidence accents
  static const primary = Color(0xFF5E6AD2); // Lavender
  static const primaryDark = Color(0xFF5E69D1); // Focus variant
  static const primaryLight = Color(0xFF828FFF); // Hover variant
  static const primaryContainer = Color(0xFF141516);

  static const secondary = Color(0xFF141516); // Surface 2
  static const secondaryDark = Color(0xFF0F1011);
  static const secondaryLight = Color(0xFF18191A);

  // Semantic mappings
  static const good = Color(0xFF27A644); // Success Green
  static const warning = Color(0xFFF1C21B); // Warning Yellow
  static const defect = Color(0xFFDA1E28); // Error Red
  static const critical = Color(0xFFDA1E28);

  static const severityGoodContainer = Color(0xFF0F2616);
  static const severityWarningContainer = Color(0xFF262100);
  static const severityDefectContainer = Color(0xFF260F0F);
  static const severityCriticalContainer = Color(0xFF1C0A0A);

  // Content on surfaces
  static const onBackground = Color(0xFFF7F8F8); // Light gray Ink
  static const onSurface = Color(0xFFF7F8F8);
  static const onSurfaceVariant = Color(0xFFD0D6E0); // Ink Muted
  static const onSurfaceMuted = Color(0xFF8A8F98); // Ink Subtle
  static const onPrimary = Color(0xFFFFFFFF);

  // Accent
  static const accent = Color(0xFF5E6AD2); // Lavender-Blue

  // Disabled
  static const disabled = Color(0xFF62666D); // Ink Tertiary
  static const onDisabled = Color(0xFF8A8F98);

  // Border / divider (hairlines)
  static const border = Color(0xFF23252A); // Hairline
  static const borderSubtle = Color(0xFF34343A); // Hairline Strong
  static const borderCloud = Color(0xFF3E3E44); // Hairline Tertiary

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
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double section = 96;

  static const double touchTargetMin = 40.0; // Linear compact touch target min
  static const double marginMobile = 16.0;
}

// ─── Border Radius ────────────────────────────────────────────────────────────

abstract final class AppRadius {
  // linear.app rounded corner hierarchy
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8; // buttons, form inputs
  static const double lg = 12; // pricing/feature cards
  static const double xl = 16; // screenshot panels
  static const double xxl = 24;
  static const double full = 9999; // pill / circles

  static const borderXs = BorderRadius.all(Radius.circular(xs));
  static const borderSm = BorderRadius.all(Radius.circular(sm));
  static const borderMd = BorderRadius.all(Radius.circular(md));
  static const borderLg = BorderRadius.all(Radius.circular(lg));
  static const borderXl = BorderRadius.all(Radius.circular(xl));
  static const borderFull = BorderRadius.all(Radius.circular(full));
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
// Inter — display, body, labels, UI
// JetBrains Mono — inspection IDs, metric values, code blocks

abstract final class AppTextStyles {
  // Display & Headline (LINE Seed Sans KR at weights 400-800)
  static final TextStyle displayHero = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 80,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    height: 1.05,
    letterSpacing: -2.0,
  );

  static final TextStyle displayLarge = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 56,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    height: 1.1,
    letterSpacing: -1.5,
  );

  static final TextStyle headlineXl = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    height: 1.15,
    letterSpacing: -0.8,
  );

  static final TextStyle headlineLg = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static final TextStyle headlineMd = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 22,
    fontWeight: FontWeight.w500,
    color: AppColors.onBackground,
    height: 1.25,
    letterSpacing: -0.3,
  );

  static final TextStyle headlineSm = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.4,
    letterSpacing: -0.1,
  );

  // Section header — eyebrow above headings
  static final TextStyle sectionHeader = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 13,
    fontWeight: FontWeight.w700,
    color: AppColors.primary, // Eyebrow in signature lavender-blue
    height: 1.3,
    letterSpacing: 0.3,
  );

  // Body
  static final TextStyle bodyLg = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
    letterSpacing: -0.05,
  );

  static final TextStyle bodyStrong = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static final TextStyle bodyMd = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
    letterSpacing: 0,
  );

  static final TextStyle bodySm = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.5,
    letterSpacing: 0,
  );

  // Label
  static final TextStyle labelLg = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.2,
    letterSpacing: 0,
  );

  static final TextStyle labelMd = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
    letterSpacing: 0,
  );

  static final TextStyle labelSm = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceMuted,
    letterSpacing: 0,
    height: 1.4,
  );

  // Mono — JetBrains Mono
  static final TextStyle monoLg = GoogleFonts.jetBrainsMono(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static final TextStyle monoMd = GoogleFonts.jetBrainsMono(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static final TextStyle monoSm = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  // Button
  static final TextStyle buttonLg = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 0,
    height: 1.2,
  );

  static final TextStyle buttonMd = const TextStyle(
    fontFamily: 'LINE Seed Sans KR',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 0,
    height: 1.2,
  );

  // Fallback aliases for other screens' legacy style references
  static final TextStyle titleLg = headlineLg;
  static final TextStyle titleMd = headlineMd;
  static final TextStyle titleSm = headlineSm;
}

// ─── Shadows ─────────────────────────────────────────────────────────────────

abstract final class AppShadows {
  static const List<BoxShadow> sm = [];

  static const List<BoxShadow> md = [];

  static const List<BoxShadow> lg = [];

  static const List<BoxShadow> primaryGlow = [];

  static const List<BoxShadow> accentGlow = [];
}

// ─── Animation Durations ─────────────────────────────────────────────────────

abstract final class AppDurations {
  static const instant = Duration.zero;
  static const exit = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 220);
  static const slow = Duration(milliseconds: 300);
}

abstract final class AppCurves {
  static const enter = Curves.easeOut;
  static const exit = Curves.easeIn;
  static const standard = Curves.easeInOut;
}
