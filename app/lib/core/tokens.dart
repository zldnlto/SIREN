import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Sentry's dark violet-midnight canvas polarity
  static const background = Color(0xFF1F1633); // Dark Canvas / Ink-deep
  static const surface = Color(0xFF150F23); // Night - Card surface / Primary
  static const surfaceVariant = Color(0xFF1F1633); // Ink-deep
  static const surfaceTertiary = Color(0xFF422082); // Deep Violet
  static const surfaceOverlay = Color(0xFF1F1633);

  // Accents
  static const primary = Color(0xFFFFFFFF); // CTA Inverted primary on dark
  static const primaryDark = Color(0xFFE5E7EB);
  static const primaryLight = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF3F3849); // On dark faint

  static const secondary = Color(0xFF6A5FC1); // Violet Link
  static const secondaryDark = Color(0xFF422082);
  static const secondaryLight = Color(0xFF79628C);

  // Sentry-inspired Accent colors
  static const lime = Color(0xFFC2EF4E); // Electric Lime
  static const pink = Color(0xFFFA7FAA); // Hot Pink

  // Severity (Mapped to Sentry tones)
  static const good = Color(0xFFC2EF4E); // 양호 (Electric Lime)
  static const warning = Color(0xFFFFD60A); // 주의 (Yellow)
  static const defect = Color(0xFFFA7FAA); // 결함 (Hot Pink)
  static const critical = Color(0xFFFA7FAA); // 위험 (Hot Pink)

  static const severityGoodContainer = Color(0xFF1A3D2B);
  static const severityWarningContainer = Color(0xFF3D3300);
  static const severityDefectContainer = Color(0xFF3D1A1A);
  static const severityCriticalContainer = Color(0xFF2D0F0F);

  // Content on surfaces
  static const onBackground = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFFFFFFFF);
  static const onSurfaceVariant = Color(0xFFBDB8C0); // On Dark Muted
  static const onSurfaceMuted = Color(0xFF79628C); // Mid Violet
  static const onPrimary = Color(0xFF1F1633); // Inverted Text on primary white

  // Accent
  static const accent = Color(0xFFC2EF4E); // Electric Lime

  // Disabled
  static const disabled = Color(0xFF3F3849);
  static const onDisabled = Color(0xFFBDB8C0);

  // Hairline / Borders
  static const border = Color(0xFF362D59); // Hairline Violet
  static const borderSubtle = Color(0xFFCFCFDB); // Hairline Cool
  static const borderCloud = Color(0xFFE5E7EB); // Hairline Cloud

  // Semantic mappings for standard Material theme fields
  static const tertiary = lime;
  static const error = pink;

  // Destructive
  static const destructive = defect;
}

// ─── Breakpoints ─────────────────────────────────────────────────────────────

abstract final class AppBreakpoints {
  static const double tablet = 600;
}

abstract final class AppSpacing {
  static const double xxs = 2; // xxs
  static const double xs = 4; // xs
  static const double sm = 8; // sm
  static const double md = 12; // md
  static const double lg = 16; // lg
  static const double xl = 24; // xl
  static const double xxl = 32; // xxl
  static const double section = 96; // section

  static const double touchTargetMin = 44.0; // Sentry touch-target-min
  static const double marginMobile = 16.0;
}

// ─── Border Radius ────────────────────────────────────────────────────────────

abstract final class AppRadius {
  // Sentry's rounded borders scale
  static const double xs = 4;
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 10;
  static const double xl = 12;
  static const double xxl = 18;
  static const double full = 9999;

  static const borderXs = BorderRadius.all(Radius.circular(xs));
  static const borderSm = BorderRadius.all(Radius.circular(sm));
  static const borderMd = BorderRadius.all(Radius.circular(md));
  static const borderLg = BorderRadius.all(Radius.circular(lg));
  static const borderXl = BorderRadius.all(Radius.circular(xl));
  static const borderFull = BorderRadius.all(Radius.circular(full));
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
// Rubik  — body, labels, UI
// Monaco / JetBrains Mono  — inspection IDs, metric values, code blocks

abstract final class AppTextStyles {
  // Display & Headline (Sentry custom display sans substitute)
  static final TextStyle displayHero = GoogleFonts.rubik(
    fontSize: 88,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    height: 1.2,
  );

  static final TextStyle displayLarge = GoogleFonts.rubik(
    fontSize: 60,
    fontWeight: FontWeight.w500,
    color: AppColors.onBackground,
    height: 1.1,
  );

  static final TextStyle headlineXl = GoogleFonts.rubik(
    fontSize: 30,
    fontWeight: FontWeight.w500,
    color: AppColors.onBackground,
    height: 1.2,
  );

  static final TextStyle headlineLg = GoogleFonts.rubik(
    fontSize: 27,
    fontWeight: FontWeight.w500,
    color: AppColors.onBackground,
    height: 1.25,
  );

  static final TextStyle headlineMd = GoogleFonts.rubik(
    fontSize: 24,
    fontWeight: FontWeight.w500,
    color: AppColors.onBackground,
    height: 1.25,
  );

  static final TextStyle headlineSm = GoogleFonts.rubik(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.25,
  );

  // Section header — eyebrow above headings
  static final TextStyle sectionHeader = GoogleFonts.rubik(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  // Body
  static final TextStyle bodyLg = GoogleFonts.rubik(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 2.0, // airy marketing line height
  );

  static final TextStyle bodyStrong = GoogleFonts.rubik(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static final TextStyle bodyMd = GoogleFonts.rubik(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    height: 1.5, // functional UI body
  );

  static final TextStyle bodySm = GoogleFonts.rubik(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.43,
  );

  // Label
  static final TextStyle labelLg = GoogleFonts.rubik(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
    height: 1.14,
  );

  static final TextStyle labelMd = GoogleFonts.rubik(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  static final TextStyle labelSm = GoogleFonts.rubik(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceMuted,
    letterSpacing: 0.25,
    height: 1.8,
  );

  // Mono — Sentry code Monaco/Menlo (Substituted with JetBrains Mono)
  static final TextStyle monoLg = GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static final TextStyle monoMd = GoogleFonts.jetBrainsMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static final TextStyle monoSm = GoogleFonts.jetBrainsMono(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  // Button
  static final TextStyle buttonLg = GoogleFonts.rubik(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
    letterSpacing: 0.2, // caps with tracking
    height: 1.14,
  );

  static final TextStyle buttonMd = GoogleFonts.rubik(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onPrimary,
    letterSpacing: 0.2,
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
