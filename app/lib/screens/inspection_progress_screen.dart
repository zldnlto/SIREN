import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/inspection_provider.dart';
import '../widgets/toast.dart';

class InspectionProgressScreen extends ConsumerStatefulWidget {
  const InspectionProgressScreen({super.key, required this.inspectionId});
  final String inspectionId;

  @override
  ConsumerState<InspectionProgressScreen> createState() =>
      _InspectionProgressScreenState();
}

class _InspectionProgressScreenState
    extends ConsumerState<InspectionProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runDetection());
  }

  void _runDetection() {
    ref.read(inspectionProvider.notifier).runDetection(widget.inspectionId);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);

    ref.listen(inspectionProvider, (prev, next) {
      final route = next.nextRoute;
      if (route != null && prev?.nextRoute == null) {
        context.goNamed(route, extra: widget.inspectionId);
      }
      if (next.error != null && prev?.error == null) {
        Toast.show(context, '검사 중 오류가 발생했습니다.', type: ToastType.error);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('검사 진행 중'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.isDetecting) ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  Text(
                    'AI 결함 분석 중...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '잠시만 기다려 주세요.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ] else if (state.error != null) ...[
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 24),
                  Text(
                    '검사에 실패했습니다.',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _runDetection,
                    child: const Text('다시 시도'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('홈으로 돌아가기'),
                  ),
                ] else ...[
                  const CircularProgressIndicator(),
                  const SizedBox(height: 24),
                  const Text('준비 중...'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
