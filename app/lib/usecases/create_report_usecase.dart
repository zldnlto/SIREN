import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/report.dart';
import '../repositories/report_repository.dart';

class CreateReportUseCase {
  const CreateReportUseCase(this._repo);
  final ReportRepository _repo;

  Future<Report> call({
    required String inspectionId,
    required List<bool> actionChecks,
    String? note,
    String status = 'pending',
  }) async {
    if (inspectionId.isEmpty) {
      throw ArgumentError('검사 ID는 필수입니다.');
    }
    return await _repo.createReport(
      inspectionId: inspectionId,
      actionChecks: actionChecks,
      note: note,
      status: status,
    );
  }
}

final createReportUseCaseProvider = Provider<CreateReportUseCase>(
  (ref) => CreateReportUseCase(ref.read(reportRepositoryProvider)),
);
