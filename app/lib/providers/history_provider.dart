import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guidance_detail.dart';
import '../models/inspection.dart';
import '../models/inspection_detail.dart';
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

final historyDetailProvider = FutureProvider.family<InspectionDetail, String>((ref, id) async {
  if (id.startsWith('insp-')) {
    // Return mock InspectionDetail for demo/testing
    final isDefect = id == 'insp-20260602-001' || id == 'insp-20260602-003';
    
    return InspectionDetail(
      inspectionId: id,
      inspectorId: 'inspector-123',
      imageUrl: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=800',
      overlayImageUrl: isDefect
          ? 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=800'
          : null,
      status: 'completed',
      qualityState: isDefect ? 'defect' : 'good',
      annotationDomain: id == 'insp-20260602-001'
          ? 'surface_treatment'
          : (id == 'insp-20260602-002' ? 'pipe_weld' : (id == 'insp-20260602-003' ? 'pump_tower' : 'internal_cargo')),
      canonicalClassName: isDefect ? 'crack_paint' : null,
      ontologyId: isDefect ? 'surface_treatment.crack.paint' : null,
      confidenceScore: isDefect ? 0.942 : null,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      completedAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 58)),
      guidance: isDefect
          ? const GuidanceDetail(
              cause: '반복 하중 또는 용접부 결함으로 인한 균열 발생',
              action: [
                '해당 구역 즉시 작업 중단',
                '관리자에게 보고 후 비파괴 검사(NDT) 일정 조율',
                '보수 용접부 그라인딩 가공 처리'
              ],
              reinspection: '보수 완료 후 재촬영 및 AI 재검사 필수',
              caution: '이 안내는 참고용입니다. 전문 검사원의 최종 판단을 따르십시오.',
            )
          : null,
    );
  }

  final repo = ref.watch(inspectionRepositoryProvider);
  return repo.getDetail(id);
});
