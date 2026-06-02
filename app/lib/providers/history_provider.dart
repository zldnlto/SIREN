import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inspection.dart';
import '../repositories/inspection_repository.dart';

class HistoryNotifier extends Notifier<List<Inspection>> {
  @override
  List<Inspection> build() {
    // Return initial mock variety to enable instant premium dashboard demo experience
    return [
      Inspection(
        id: 'insp-20260602-001',
        annotationDomain: 'surface_treatment',
        inspectorId: 'inspector-123',
        reportFlagged: true,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: 'completed',
        thumbnailKey: 'assets/images/logo.png',
      ),
      Inspection(
        id: 'insp-20260602-002',
        annotationDomain: 'pipe_weld',
        inspectorId: 'inspector-123',
        reportFlagged: false,
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 4)),
        status: 'completed',
        thumbnailKey: 'assets/images/logo.png',
      ),
      Inspection(
        id: 'insp-20260602-003',
        annotationDomain: 'pump_tower',
        inspectorId: 'inspector-123',
        reportFlagged: true,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        status: 'completed',
        thumbnailKey: 'assets/images/logo.png',
      ),
      Inspection(
        id: 'insp-20260602-004',
        annotationDomain: 'internal_cargo',
        inspectorId: 'inspector-123',
        reportFlagged: false,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        status: 'completed',
        thumbnailKey: 'assets/images/logo.png',
      ),
    ];
  }

  void addInspection(Inspection inspection) {
    if (state.any((x) => x.id == inspection.id)) return;
    state = [inspection, ...state];
  }

  Future<void> reportInspection(String id) async {
    try {
      // Background delegation PATCH request trigger
      await ref.read(inspectionRepositoryProvider).updateDomain(id, 'surface_treatment');
    } catch (_) {}

    state = state.map((x) {
      if (x.id == id) {
        return Inspection(
          id: x.id,
          annotationDomain: x.annotationDomain,
          inspectorId: x.inspectorId,
          reportFlagged: true, // Mark reported
          createdAt: x.createdAt,
          status: x.status,
          imageKey: x.imageKey,
          thumbnailKey: x.thumbnailKey,
        );
      }
      return x;
    }).toList();
  }

  void updateDomain(String id, String domain) {
    state = state.map((x) {
      if (x.id == id) {
        return Inspection(
          id: x.id,
          annotationDomain: domain, // Update domain
          inspectorId: x.inspectorId,
          reportFlagged: x.reportFlagged,
          createdAt: x.createdAt,
          status: x.status,
          imageKey: x.imageKey,
          thumbnailKey: x.thumbnailKey,
        );
      }
      return x;
    }).toList();
  }
}

final historyProvider = NotifierProvider<HistoryNotifier, List<Inspection>>(
  HistoryNotifier.new,
);

final inspectionDetailProvider = Provider.family<Inspection?, String>((ref, id) {
  final list = ref.watch(historyProvider);
  final found = list.where((x) => x.id == id);
  if (found.isNotEmpty) return found.first;
  return null;
});
