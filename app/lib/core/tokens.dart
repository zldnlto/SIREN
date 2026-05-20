import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Colors ──────────────────────────────────────────────────────────────────

abstract final class AppColors {
  // Surface hierarchy (OLED dark, navy-tinted layers)
  static const background = Color(0xFF0E0E0E);
  static const surface = Color(0xFF1E233D);
  static const surfaceVariant = Color(0xFF252B45);
  static const surfaceTertiary = Color(0xFF2D3354);

  // Primary — Steel Blue
  static const primary = Color(0xFF3498DB);
  static const primaryDark = Color(0xFF2980B9);
  static const primaryLight = Color(0xFF5DADE2);
  static const primaryContainer = Color(0xFF1A3A5C);

  // Severity
  static const good = Color(0xFF2ECC71); // 양호
  static const warning = Color(0xFFFFD60A); // 주의
  static const defect = Color(0xFFE74C3C); // 결함
  static const critical = Color(0xFFC0392B); // 위험

  static const severityGoodContainer = Color(0xFF1A3D2B);
  static const severityWarningContainer = Color(0xFF3D3300);
  static const severityDefectContainer = Color(0xFF3D1A1A);
  static const severityCriticalContainer = Color(0xFF2D0F0F);

  // Content on surfaces
  static const onBackground = Color(0xFFF0F4F8);
  static const onSurface = Color(0xFFE2E8F0);
  static const onSurfaceVariant = Color(0xFF94A3B8);
  static const onSurfaceMuted = Color(0xFF64748B);
  static const onPrimary = Color(0xFFFFFFFF); // primary 버튼 위 텍스트

  // Accent — Safety Yellow (CTA / warning 겸용)
  static const accent = Color(0xFFFFD60A);

  // Disabled
  static const disabled = Color(0xFF3D4460);
  static const onDisabled = Color(0xFF64748B);

  // Border / divider
  static const border = Color(0xFF2D3354); // surfaceTertiary 기준
  static const borderSubtle =
      Color(0xFF252B45); // surfaceVariant 기준 — surface와 구분됨

  // Destructive — UI 파괴 액션(삭제·취소)용. critical과 동일 계열이나 semantic 분리
  static const destructive = critical;
}

// ─── Breakpoints ─────────────────────────────────────────────────────────────

abstract final class AppBreakpoints {
  static const double tablet = 600;
}

// ─── Spacing ─────────────────────────────────────────────────────────────────

abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double x2l = 48;
  static const double x3l = 64;
}

// ─── Border Radius ────────────────────────────────────────────────────────────

abstract final class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;

  static const borderXs = BorderRadius.all(Radius.circular(xs));
  static const borderSm = BorderRadius.all(Radius.circular(sm));
  static const borderMd = BorderRadius.all(Radius.circular(md));
  static const borderLg = BorderRadius.all(Radius.circular(lg));
  static const borderXl = BorderRadius.all(Radius.circular(xl));
  static const borderFull = BorderRadius.all(Radius.circular(full));
}

// ─── Text Styles ──────────────────────────────────────────────────────────────
//
// IBM Plex Sans  — body, labels, UI
// IBM Plex Mono  — inspection IDs, metric values, defect codes

abstract final class AppTextStyles {
  // Display
  static final TextStyle displayLg = GoogleFonts.ibmPlexSans(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    letterSpacing: -0.5,
  );

  static final TextStyle displaySm = GoogleFonts.ibmPlexSans(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.onBackground,
    letterSpacing: -0.3,
  );

  // Title
  static final TextStyle titleLg = GoogleFonts.ibmPlexSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
  );

  static final TextStyle titleMd = GoogleFonts.ibmPlexSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onBackground,
  );

  static final TextStyle titleSm = GoogleFonts.ibmPlexSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  // Section header — used in report sections
  static final TextStyle sectionHeader = GoogleFonts.ibmPlexSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurfaceVariant,
    letterSpacing: 0.8,
  );

  // Body
  static final TextStyle bodyLg = GoogleFonts.ibmPlexSans(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.6,
  );

  static final TextStyle bodyMd = GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    height: 1.5,
  );

  static final TextStyle bodySm = GoogleFonts.ibmPlexSans(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
    height: 1.4,
  );

  // Label
  static final TextStyle labelLg = GoogleFonts.ibmPlexSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
  );

  static final TextStyle labelMd = GoogleFonts.ibmPlexSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceVariant,
  );

  static final TextStyle labelSm = GoogleFonts.ibmPlexSans(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurfaceMuted,
    letterSpacing: 0.3,
  );

  // Mono — inspection IDs, metric values, defect codes
  static final TextStyle monoLg = GoogleFonts.ibmPlexMono(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.onSurface,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final TextStyle monoMd = GoogleFonts.ibmPlexMono(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  static final TextStyle monoSm = GoogleFonts.ibmPlexMono(
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
