import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../models/inspection.dart';
import '../providers/history_provider.dart';
import '../widgets/quality_badge.dart';

class HistoryListScreen extends ConsumerWidget {
  const HistoryListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('검사 이력')),
      body: historyAsync.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('검사 이력이 없습니다.'))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, i) => _HistoryTile(inspection: list[i]),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 12),
              Text('이력을 불러올 수 없습니다.\n$e'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(historyProvider),
                child: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.inspection});
  final Inspection inspection;

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('yyyy.MM.dd HH:mm').format(inspection.createdAt.toLocal());

    return Card(
      child: ListTile(
        title: Text(inspection.annotationDomain),
        subtitle: Text(dateStr),
        trailing: QualityBadge(
          qualityState:
              inspection.status == 'defect_detected' ? 'defect' : 'good',
        ),
        onTap: () => context
            .pushNamed('history-detail', pathParameters: {'id': inspection.id}),
      ),
    );
  }
}
