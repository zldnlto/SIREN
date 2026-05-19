import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/inspection_provider.dart';
import '../widgets/toast.dart';

const _kDomains = [
  '표면처리',
  '용접',
  '절단',
  '케이블',
  '파이프',
  '폼스프레이',
];

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedDomain = _kDomains.first;

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('SIREN 검사'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.go('/history'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '검사 영역 선택',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _kDomains.map((domain) {
                  final selected = domain == _selectedDomain;
                  return ChoiceChip(
                    label: Text(domain),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedDomain = domain),
                  );
                }).toList(),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: inspectionState.isLoading ? null : _startInspection,
                icon: inspectionState.isCreating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                label: const Text('새 검사 시작'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startInspection() {
    ref.read(inspectionProvider.notifier).start(_selectedDomain);
  }
}
