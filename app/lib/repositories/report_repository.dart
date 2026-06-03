import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/report.dart';

class ReportRepository {
  const ReportRepository(this._dio);
  final Dio _dio;

  Future<Report> createReport({
    required String inspectionId,
    required List<bool> actionChecks,
    String? note,
    String status = 'pending',
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/reports',
      data: {
        'inspection_id': inspectionId,
        'action_checks': actionChecks,
        'note': note,
        'status': status,
      },
    );
    return Report.fromJson(resp.data!);
  }
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.read(dioProvider)),
);
