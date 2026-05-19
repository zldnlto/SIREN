import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inspection.dart';
import '../repositories/inspection_repository.dart';

class RunInspectionUseCase {
  const RunInspectionUseCase(this._repo);
  final InspectionRepository _repo;

  Future<Inspection> call(String annotationDomain) async {
    return _repo.create(annotationDomain);
  }
}

final runInspectionUseCaseProvider = Provider<RunInspectionUseCase>(
  (ref) => RunInspectionUseCase(ref.read(inspectionRepositoryProvider)),
);
