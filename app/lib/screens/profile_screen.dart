import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../providers/auth_provider.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_section_header.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text('프로필', style: AppTextStyles.titleMd),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.surfaceVariant,
                child: Icon(
                  Icons.person_rounded,
                  size: 44,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '현장 검사원',
                textAlign: TextAlign.center,
                style: AppTextStyles.titleMd,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'SIREN 현장 태블릿 앱',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              const SirenSectionHeader(title: '앱 정보', showDivider: true),
              const SizedBox(height: AppSpacing.sm),
              const _InfoTile(
                icon: Icons.info_outline_rounded,
                label: '앱 버전',
                value: '1.0.0',
              ),
              const Spacer(),
              SirenButton(
                label: '로그아웃',
                icon: const Icon(Icons.logout_rounded),
                variant: SirenButtonVariant.destructive,
                onPressed: () => _confirmLogout(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final ok = await ConfirmDialog.show(
      context,
      title: '로그아웃',
      message: '로그아웃 하시겠습니까?',
      confirmLabel: '로그아웃',
    );
    if (ok && context.mounted) {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    }
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
