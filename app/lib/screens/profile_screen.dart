import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../providers/auth_provider.dart';
import '../providers/history_provider.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_section_header.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final history = ref.watch(historyProvider);
    
    // Dynamic inspection engine statistics calculations
    final totalInspections = history.length;
    final defectsFound = history.where((x) => x.reportFlagged).length;
    final reportsSent = history.where((x) => x.reportFlagged).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          '프로필',
          style: AppTextStyles.headlineSm.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // ─── Ambient Auroral Glow Background ───
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
            
            // Main content layout
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profile Identity HUD
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              width: 2,
                            ),
                          ),
                          child: const CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.surfaceVariant,
                            child: Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          '현장 검사원',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMd.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'SIREN 현장 태블릿 앱',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMd.copyWith(
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // SaaS Dashboard Bento Grid Statistics Section
                  const SirenSectionHeader(
                    title: 'SYSTEM STATISTICS',
                    showDivider: true,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Staggered Entry Dashboard Cards
                  _StatCard(
                    title: '총 검사 건수',
                    value: totalInspections,
                    icon: Icons.assignment_turned_in_rounded,
                    iconColor: AppColors.primaryLight,
                    delayMs: 0,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatCard(
                    title: '결함 발견 건수',
                    value: defectsFound,
                    icon: Icons.warning_amber_rounded,
                    iconColor: AppColors.defect,
                    delayMs: 80,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _StatCard(
                    title: '보고 완료 건수',
                    value: reportsSent,
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: AppColors.good,
                    delayMs: 160,
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // System Metadata Settings
                  const SirenSectionHeader(
                    title: '앱 정보',
                    showDivider: true,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _InfoTile(
                    icon: Icons.info_outline_rounded,
                    label: '앱 버전',
                    value: '1.0.0',
                  ),
                  const Spacer(),

                  // Safe glove touch optimization (64dp height) Logout Button
                  SizedBox(
                    height: 64,
                    child: SirenButton(
                      label: '로그아웃',
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      variant: SirenButtonVariant.destructive,
                      onPressed: () => _confirmLogout(context, ref),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    HapticFeedback.mediumImpact(); // Premium tactile click feedback

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
                color: const Color(0xFF0F1115).withValues(alpha: 0.9), // glassmorphism background
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
                    '로그아웃',
                    style: AppTextStyles.headlineSm.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '로그아웃 하시겠습니까?\n세션 스토리지가 즉시 파괴됩니다.',
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
                            label: '취소',
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
                            label: '로그아웃',
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
}

// Staggered Entry Card with Counter Rolling Micro-interaction
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

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label, style: AppTextStyles.bodyMd)),
          Text(value, style: AppTextStyles.monoSm),
        ],
      ),
    );
  }
}

