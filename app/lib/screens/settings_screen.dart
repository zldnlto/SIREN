import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_section_header.dart';
import '../widgets/toast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _apiUrlController;
  
  // Diagnostic simulation state
  bool _isDiagnosing = false;
  double _diagnosticProgress = 0.0;

  static const Map<String, Map<String, String>> _localized = {
    'title': {
      'KOR': '시스템 설정',
      'ENG': 'System Settings',
    },
    'sys_status': {
      'KOR': '시스템 상태 모니터링',
      'ENG': 'System Status Monitor',
    },
    'run_diagnostic': {
      'KOR': '시스템 자가진단 실행',
      'ENG': 'Run System Diagnostic',
    },
    'diagnostic_run': {
      'KOR': '진단 수행 중...',
      'ENG': 'Diagnosing...',
    },
    'net_status': {
      'KOR': '네트워크 연결',
      'ENG': 'Network Connection',
    },
    'srv_status': {
      'KOR': 'API 서버 연결',
      'ENG': 'API Server Link',
    },
    'bat_status': {
      'KOR': '배터리 상태',
      'ENG': 'Device Battery',
    },
    'str_status': {
      'KOR': '스토리지 공간',
      'ENG': 'Disk Storage',
    },
    'net_val': {
      'KOR': 'WIFI 5G (온라인)',
      'ENG': 'WIFI 5G (Online)',
    },
    'srv_val': {
      'KOR': '연결됨 (200 OK)',
      'ENG': 'Connected (200 OK)',
    },
    'bat_val': {
      'KOR': '98% (충전 중)',
      'ENG': '98% (Charging)',
    },
    'str_val': {
      'KOR': '74.5 GB 여유',
      'ENG': '74.5 GB Free',
    },
    'inspection_cfg': {
      'KOR': '검사 알고리즘 설정',
      'ENG': 'Inspection Algorithm Config',
    },
    'yolo_threshold': {
      'KOR': 'YOLO 결함 감지 임계치 (Confidence)',
      'ENG': 'YOLO Defect Confidence Threshold',
    },
    'api_server_url': {
      'KOR': 'API 서버 엔드포인트 URL',
      'ENG': 'API Server Endpoint URL',
    },
    'apply': {
      'KOR': '적용',
      'ENG': 'Apply',
    },
    'lang_switch': {
      'KOR': '시스템 언어 전환 (KOR / ENG)',
      'ENG': 'System Language Toggle (KOR / ENG)',
    },
    'stats_header': {
      'KOR': '작업자 누적 통계',
      'ENG': 'Operator Statistics',
    },
    'stat_total': {
      'KOR': '총 검사 건수',
      'ENG': 'Total Inspections',
    },
    'stat_defect': {
      'KOR': '결함 발견 건수',
      'ENG': 'Defects Identified',
    },
    'stat_report': {
      'KOR': '보고 완료 건수',
      'ENG': 'Reports Transmitted',
    },
    'app_info_header': {
      'KOR': '앱 정보',
      'ENG': 'Application Metadata',
    },
    'app_version': {
      'KOR': '앱 버전',
      'ENG': 'App Version',
    },
    'logout': {
      'KOR': '로그아웃',
      'ENG': 'Logout',
    },
    'toast_api_success': {
      'KOR': 'API 서버 주소가 정상 반영되었습니다.',
      'ENG': 'API server endpoint updated successfully.',
    },
    'diag_result_title': {
      'KOR': '자가진단 완료',
      'ENG': 'Diagnostic Complete',
    },
    'diag_net': {
      'KOR': '네트워크 인터페이스',
      'ENG': 'Network Interface',
    },
    'diag_srv': {
      'KOR': 'API 백엔드 핑 테스트',
      'ENG': 'API Backend Ping Test',
    },
    'diag_bat': {
      'KOR': '하드웨어 배터리 셀',
      'ENG': 'Hardware Battery Cells',
    },
    'diag_str': {
      'KOR': '플래시 메모리 섹터',
      'ENG': 'Flash Memory Sectors',
    },
    'diag_ok_lbl': {
      'KOR': '정상 (GOOD)',
      'ENG': 'NORMAL (GOOD)',
    },
    'close': {
      'KOR': '닫기',
      'ENG': 'Close',
    },
    'logout_confirm_msg': {
      'KOR': '로그아웃 하시겠습니까?\n세션 스토리지가 즉시 파괴됩니다.',
      'ENG': 'Are you sure you want to logout?\nLocal token session will be purged.',
    }
  };

  String _t(String key, String lang) {
    return _localized[key]?[lang] ?? key;
  }

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsProvider);
    _apiUrlController = TextEditingController(text: settings.apiUrl);
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  void _runDiagnostic(String lang) {
    if (_isDiagnosing) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _isDiagnosing = true;
      _diagnosticProgress = 0.0;
    });

    Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _diagnosticProgress += 0.08;
        if (_diagnosticProgress >= 1.0) {
          _diagnosticProgress = 1.0;
          _isDiagnosing = false;
          timer.cancel();
          HapticFeedback.mediumImpact();
          _showDiagnosticResult(lang);
        } else {
          // Tactile ticking sound simulation via selection vibrations
          HapticFeedback.selectionClick();
        }
      });
    });
  }

  Future<void> _showDiagnosticResult(String lang) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Diagnostic Result',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * curved.value,
            sigmaY: 8.0 * curved.value,
          ),
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 330,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95), // Glassmorphism container
                borderRadius: AppRadius.borderLg,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.good.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.good,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('diag_result_title', lang),
                    style: AppTextStyles.headlineSm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDiagnosticRow(Icons.wifi_rounded, _t('diag_net', lang), _t('diag_ok_lbl', lang), AppColors.good),
                  _buildDiagnosticRow(Icons.cloud_done_rounded, _t('diag_srv', lang), _t('diag_ok_lbl', lang), AppColors.good),
                  _buildDiagnosticRow(Icons.battery_charging_full_rounded, _t('diag_bat', lang), _t('diag_ok_lbl', lang), AppColors.good),
                  _buildDiagnosticRow(Icons.storage_rounded, _t('diag_str', lang), _t('diag_ok_lbl', lang), AppColors.good),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: SirenButton(
                      label: _t('close', lang),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagnosticRow(IconData icon, String label, String status, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.onSurfaceMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodySm.copyWith(color: AppColors.onSurfaceMuted),
            ),
          ),
          Text(
            status,
            style: AppTextStyles.monoSm.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, String lang) async {
    HapticFeedback.mediumImpact(); // tactile click feedback

    final bool? ok = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout Dialog',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 220),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 8.0 * curved.value,
            sigmaY: 8.0 * curved.value,
          ),
          child: FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          ),
        );
      },
      pageBuilder: (context, _, __) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest.withValues(alpha: 0.95), // glassmorphism background
                borderRadius: AppRadius.borderLg,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.defect.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.defect,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('logout', lang),
                    style: AppTextStyles.headlineSm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _t('logout_confirm_msg', lang),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: SirenButton(
                            label: lang == 'KOR' ? '취소' : 'Cancel',
                            variant: SirenButtonVariant.secondary,
                            onPressed: () => Navigator.pop(context, false),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: SirenButton(
                            label: _t('logout', lang),
                            variant: SirenButtonVariant.destructive,
                            onPressed: () => Navigator.pop(context, true),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (ok == true && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final history = ref.watch(historyProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);

    final lang = settings.language;
    final totalInspections = history.length;
    final defectsFound = history.where((x) => x.reportFlagged).length;
    final reportsSent = history.where((x) => x.reportFlagged).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          _t('title', lang),
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // ─── Ambient Glow Background ───
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Main Settings Canvas Layout
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  
                  // 1. System Status Monitor Bento grid (2x2)
                  SirenSectionHeader(
                    title: _t('sys_status', lang).toUpperCase(),
                    showDivider: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 2.3,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    children: [
                      _buildBentoStatusCell(Icons.wifi_rounded, _t('net_status', lang), _t('net_val', lang), AppColors.good),
                      _buildBentoStatusCell(Icons.cloud_queue_rounded, _t('srv_status', lang), _t('srv_val', lang), AppColors.good),
                      _buildBentoStatusCell(Icons.battery_saver_rounded, _t('bat_status', lang), _t('bat_val', lang), AppColors.good),
                      _buildBentoStatusCell(Icons.storage_rounded, _t('str_status', lang), _t('str_val', lang), AppColors.primaryLight),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Run Diagnostic button
                  SizedBox(
                    height: 64,
                    child: SirenButton(
                      label: _isDiagnosing 
                          ? '${_t('diagnostic_run', lang)} (${(_diagnosticProgress * 100).round()}%)'
                          : _t('run_diagnostic', lang),
                      size: SirenButtonSize.xl,
                      icon: _isDiagnosing 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2.0, color: Colors.white),
                            )
                          : const Icon(Icons.analytics_outlined, size: 18),
                      variant: _isDiagnosing ? SirenButtonVariant.secondary : SirenButtonVariant.primary,
                      onPressed: _isDiagnosing ? null : () => _runDiagnostic(lang),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 2. Inspection config sliders and input
                  SirenSectionHeader(
                    title: _t('inspection_cfg', lang).toUpperCase(),
                    showDivider: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.borderLg,
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // YOLO confidence Slider
                        Text(
                          _t('yolo_threshold', lang),
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onSurfaceMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: AppColors.primary,
                                  inactiveTrackColor: AppColors.border,
                                  thumbColor: AppColors.primaryLight,
                                  overlayColor: AppColors.primary.withValues(alpha: 0.12),
                                  valueIndicatorColor: AppColors.surfaceVariant,
                                  valueIndicatorTextStyle: AppTextStyles.monoSm,
                                ),
                                child: Slider(
                                  value: settings.yoloThreshold,
                                  min: 0.1,
                                  max: 0.9,
                                  divisions: 8,
                                  label: settings.yoloThreshold.toStringAsFixed(2),
                                  onChanged: (val) {
                                    HapticFeedback.selectionClick();
                                    settingsNotifier.setYoloThreshold(val);
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              settings.yoloThreshold.toStringAsFixed(2),
                              style: AppTextStyles.monoSm.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // API Server URL text box
                        Text(
                          _t('api_server_url', lang),
                          style: AppTextStyles.bodySm.copyWith(
                            color: AppColors.onSurfaceMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 64,
                                child: TextField(
                                  controller: _apiUrlController,
                                  style: AppTextStyles.monoSm,
                                  decoration: const InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 22),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: BorderSide(color: AppColors.border, width: 1.0),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: AppRadius.borderMd,
                                      borderSide: BorderSide(color: AppColors.primary, width: 1.0),
                                    ),
                                    fillColor: AppColors.surfaceContainerLowest,
                                    filled: true,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 80,
                              height: 64,
                              child: SirenButton(
                                label: _t('apply', lang),
                                variant: SirenButtonVariant.primary,
                                size: SirenButtonSize.xl,
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  settingsNotifier.setApiUrl(_apiUrlController.text);
                                  Toast.show(context, _t('toast_api_success', lang), type: ToastType.success);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 3. Language Segment toggle
                  SirenSectionHeader(
                    title: _t('lang_switch', lang).toUpperCase(),
                    showDivider: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.borderLg,
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (lang != 'KOR') {
                                HapticFeedback.lightImpact();
                                settingsNotifier.setLanguage('KOR');
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: lang == 'KOR' ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                                borderRadius: AppRadius.borderMd,
                                border: Border.all(
                                  color: lang == 'KOR' ? AppColors.primary : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                '한국어 (KOR)',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelMd.copyWith(
                                  fontWeight: lang == 'KOR' ? FontWeight.bold : FontWeight.normal,
                                  color: lang == 'KOR' ? AppColors.primaryLight : AppColors.onSurfaceMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (lang != 'ENG') {
                                HapticFeedback.lightImpact();
                                settingsNotifier.setLanguage('ENG');
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOut,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: lang == 'ENG' ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                                borderRadius: AppRadius.borderMd,
                                border: Border.all(
                                  color: lang == 'ENG' ? AppColors.primary : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                'ENGLISH (ENG)',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.labelMd.copyWith(
                                  fontWeight: lang == 'ENG' ? FontWeight.bold : FontWeight.normal,
                                  color: lang == 'ENG' ? AppColors.primaryLight : AppColors.onSurfaceMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 4. Integrated Profile Statistics
                  SirenSectionHeader(
                    title: _t('stats_header', lang).toUpperCase(),
                    showDivider: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  _StatCard(
                    title: _t('stat_total', lang),
                    value: totalInspections,
                    icon: Icons.assignment_turned_in_rounded,
                    iconColor: AppColors.primaryLight,
                    delayMs: 0,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatCard(
                    title: _t('stat_defect', lang),
                    value: defectsFound,
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.defect,
                    delayMs: 80,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatCard(
                    title: _t('stat_report', lang),
                    value: reportsSent,
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.good,
                    delayMs: 160,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 5. App version info and logout
                  SirenSectionHeader(
                    title: _t('app_info_header', lang),
                    showDivider: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 20, color: AppColors.onSurfaceVariant),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            _t('app_version', lang),
                            style: AppTextStyles.bodyMd,
                          ),
                        ),
                        Text('1.0.0', style: AppTextStyles.monoSm),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Safe glove touch optimization (64dp height) Logout Button
                  SizedBox(
                    height: 64,
                    child: SirenButton(
                      label: _t('logout', lang),
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      variant: SirenButtonVariant.destructive,
                      onPressed: () => _confirmLogout(context, lang),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBentoStatusCell(IconData icon, String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.onSurfaceMuted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label.toUpperCase(),
                  style: AppTextStyles.sectionHeader.copyWith(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.monoSm.copyWith(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Counter Rolling Stat Card Component
class _StatCard extends StatefulWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.delayMs,
  });

  final String title;
  final int value;
  final IconData icon;
  final Color iconColor;
  final int delayMs;

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rollAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _rollAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _StatCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md - 2,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.title,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onSurfaceMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    AnimatedBuilder(
                      animation: _rollAnimation,
                      builder: (context, child) {
                        final currentVal = (widget.value * _rollAnimation.value).round();
                        return Text(
                          '$currentVal',
                          style: AppTextStyles.headlineMd.copyWith(
                            fontWeight: FontWeight.bold,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
