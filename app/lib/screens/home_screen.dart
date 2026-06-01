import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/tokens.dart';
import '../models/annotation_domain.dart';
import '../providers/inspection_provider.dart';
import '../widgets/domain_chip.dart';
import '../widgets/siren_button.dart';
import '../widgets/siren_section_header.dart';
import '../widgets/toast.dart';

const _kSelectableDomains = [
  AnnotationDomain.surfaceTreatment,
  AnnotationDomain.welding,
  AnnotationDomain.cutting,
  AnnotationDomain.cable,
  AnnotationDomain.pipe,
  AnnotationDomain.foamSpray,
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  AnnotationDomain _selectedDomain = _kSelectableDomains.first;

  @override
  Widget build(BuildContext context) {
    final inspectionState = ref.watch(inspectionProvider);

    ref.listen(inspectionProvider, (prev, next) {
      if (next.inspection != null &&
          prev?.inspection == null &&
          !next.isCreating) {
        context.pushNamed('progress', extra: next.inspection!.id);
      }
      if (next.error != null && prev?.error == null) {
        Toast.show(context, '검사 생성에 실패했습니다.', type: ToastType.error);
      }
    });

    final isTablet =
        MediaQuery.of(context).size.shortestSide >= AppBreakpoints.tablet;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'SIREN',
          style: AppTextStyles.headlineMd.copyWith(
            color: AppColors.primary, // Signature Lavender
            fontWeight: FontWeight.w600, // Linear custom display weight
            letterSpacing: -0.4, // Linear Display negative tracking
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: AppColors.onSurface),
            onPressed: () => context.go('/history'),
            tooltip: '검사 이력',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SirenSectionHeader(
                title: '검사 영역 선택',
                showDivider: true,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: _kSelectableDomains.map((domain) {
                  return DomainChip(
                    domain: domain,
                    isSelected: domain == _selectedDomain,
                    onTap: () => setState(() => _selectedDomain = domain),
                  );
                }).toList(),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.center,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isTablet ? 480 : double.infinity,
                  ),
                  child: SirenButton(
                    label: '새 검사 시작',
                    icon: const Icon(Icons.camera_alt_rounded),
                    onPressed:
                        inspectionState.isLoading ? null : _startInspection,
                    isLoading: inspectionState.isCreating,
                    size: SirenButtonSize.lg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startInspection() {
    ref.read(inspectionProvider.notifier).start(_selectedDomain.apiValue);
  }
}
