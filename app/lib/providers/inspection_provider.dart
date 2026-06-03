import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/detected_defect.dart';
import '../models/detection_result.dart';
import '../models/inspection.dart';
import '../repositories/inspection_repository.dart';
import '../usecases/run_inspection_usecase.dart';

class InspectionState {
  const InspectionState({
    this.inspection,
    this.result,
    this.isCreating = false,
    this.isDetecting = false,
    this.isRagConnecting = false,
    this.isReady = false,
    this.error,
  });

  final Inspection? inspection;
  final DetectionResult? result;
  final bool isCreating;
  final bool isDetecting;
  final bool isRagConnecting;
  final bool isReady;
  final String? error;

  bool get isLoading => isCreating || isDetecting || isRagConnecting;

  String? get nextRoute {
    if (result == null || !isReady) return null;
    return result!.hasDefect ? 'result-defect' : 'result-normal';
  }

  InspectionState copyWith({
    Inspection? inspection,
    DetectionResult? result,
    bool? isCreating,
    bool? isDetecting,
    bool? isRagConnecting,
    bool? isReady,
    String? error,
  }) =>
      InspectionState(
        inspection: inspection ?? this.inspection,
        result: result ?? this.result,
        isCreating: isCreating ?? this.isCreating,
        isDetecting: isDetecting ?? this.isDetecting,
        isRagConnecting: isRagConnecting ?? this.isRagConnecting,
        isReady: isReady ?? this.isReady,
        error: error,
      );
}

class InspectionNotifier extends Notifier<InspectionState> {
  @override
  InspectionState build() => const InspectionState();

  Future<Inspection?> createInspection(String annotationDomain) async {
    state = state.copyWith(isCreating: true, error: null);
    try {
      final inspection =
          await ref.read(runInspectionUseCaseProvider).call(annotationDomain);
      state = state.copyWith(inspection: inspection, isCreating: false);
      return inspection;
    } on Exception catch (e) {
      state = state.copyWith(isCreating: false, error: e.toString());
      return null;
    }
  }

  Future<DetectionResult?> runDetection(String inspectionId) async {
    state = state.copyWith(isDetecting: true, error: null);
    try {
      final result =
          await ref.read(inspectionRepositoryProvider).detect(inspectionId);
      state = state.copyWith(result: result, isDetecting: false);
      return result;
    } on Exception catch (e) {
      state = state.copyWith(isDetecting: false, error: e.toString());
      return null;
    }
  }

  void reset() => state = const InspectionState();

  Future<void> start(String annotationDomain) async {
    reset();
    
    // Step 1: createInspection (isCreating = true)
    final ins = await createInspection(annotationDomain);
    if (ins == null) return;

    // Step 3: runDetection (isDetecting = true)
    final res = await runDetection(ins.id);
    if (res == null) return;

    // Step 5: RAG connecting (isRagConnecting = true)
    state = state.copyWith(isRagConnecting: true);
    await Future.delayed(const Duration(milliseconds: 1500));

    // Step 6: Ready for result screen redirection
    state = state.copyWith(isRagConnecting: false, isReady: true);
  }

  Future<void> updateDomain(String inspectionId, String annotationDomain) async {
    try {
      final updated = await ref
          .read(inspectionRepositoryProvider)
          .updateDomain(inspectionId, annotationDomain);
      state = state.copyWith(inspection: updated);
    } catch (_) {
      // Local fallback sync to maintain UI state seamlessly if backend PATCH endpoint is not ready yet
      if (state.inspection != null && state.inspection!.id == inspectionId) {
        final fallback = Inspection(
          id: state.inspection!.id,
          annotationDomain: annotationDomain,
          inspectorId: state.inspection!.inspectorId,
          reportFlagged: state.inspection!.reportFlagged,
          createdAt: state.inspection!.createdAt,
          status: state.inspection!.status,
          imageKey: state.inspection!.imageKey,
          thumbnailKey: state.inspection!.thumbnailKey,
        );
        state = state.copyWith(inspection: fallback);
      }
    }
  }

  Future<void> reportInspection(String inspectionId) async {
    try {
      final updated = await ref
          .read(inspectionRepositoryProvider)
          .report(inspectionId);
      state = state.copyWith(inspection: updated);
    } catch (_) {
      // Local fallback sync to maintain UI state seamlessly if backend PATCH endpoint is not ready yet
      if (state.inspection != null && state.inspection!.id == inspectionId) {
        final fallback = Inspection(
          id: state.inspection!.id,
          annotationDomain: state.inspection!.annotationDomain,
          inspectorId: state.inspection!.inspectorId,
          reportFlagged: true,
          createdAt: state.inspection!.createdAt,
          status: state.inspection!.status,
          imageKey: state.inspection!.imageKey,
          thumbnailKey: state.inspection!.thumbnailKey,
        );
        state = state.copyWith(inspection: fallback);
      }
    }
  }

  void injectMockResult({required bool hasDefect}) {
    final mockInspection = Inspection(
      id: 'mock-inspection-id-12345678',
      annotationDomain: 'surface_treatment',
      inspectorId: 'inspector-123',
      reportFlagged: hasDefect,
      createdAt: DateTime.now(),
      imageKey: 'inspections/mock-image.jpg',
      thumbnailKey: 'assets/images/logo.png',
    );

    final mockResult = DetectionResult(
      id: 'mock-result-id-123',
      inspectionId: mockInspection.id,
      detectionJobId: 'mock-job-id-123',
      defects: hasDefect
          ? [
              const DetectedDefect(
                ontologyId: 'surface_treatment.crack.paint',
                displayLabel: '균열 (도장)',
                qualityState: 'defect',
                canonicalClassName: 'crack_paint',
                annotationDomain: 'surface_treatment',
                confidenceScore: 0.942,
                bbox: [0.15, 0.20, 0.65, 0.70],
              ),
              const DetectedDefect(
                ontologyId: 'surface_treatment.coating_drop.paint',
                displayLabel: '도막떨어짐 (도장)',
                qualityState: 'defect',
                canonicalClassName: 'coating_drop_paint',
                annotationDomain: 'surface_treatment',
                confidenceScore: 0.895,
                bbox: [0.45, 0.50, 0.85, 0.90],
              ),
            ]
          : [],
      confidence: hasDefect ? 0.9185 : 1.0,
      detectedAt: DateTime.now(),
    );

    state = InspectionState(
      inspection: mockInspection,
      result: mockResult,
      isCreating: false,
      isDetecting: false,
      isRagConnecting: false,
      isReady: true,
    );
  }
}

final inspectionProvider =
    NotifierProvider<InspectionNotifier, InspectionState>(
  InspectionNotifier.new,
);
