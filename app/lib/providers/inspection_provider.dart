import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    this.error,
  });

  final Inspection? inspection;
  final DetectionResult? result;
  final bool isCreating;
  final bool isDetecting;
  final String? error;

  bool get isLoading => isCreating || isDetecting;

  InspectionState copyWith({
    Inspection? inspection,
    DetectionResult? result,
    bool? isCreating,
    bool? isDetecting,
    String? error,
  }) =>
      InspectionState(
        inspection: inspection ?? this.inspection,
        result: result ?? this.result,
        isCreating: isCreating ?? this.isCreating,
        isDetecting: isDetecting ?? this.isDetecting,
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
}

final inspectionProvider =
    NotifierProvider<InspectionNotifier, InspectionState>(
  InspectionNotifier.new,
);
