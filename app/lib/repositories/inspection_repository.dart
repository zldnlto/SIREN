import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/detection_result.dart';
import '../models/inspection.dart';

class InspectionRepository {
  const InspectionRepository(this._dio);
  final Dio _dio;

  Future<Inspection> create(String annotationDomain) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/inspections',
      data: {'annotation_domain': annotationDomain},
    );
    return Inspection.fromJson(resp.data!);
  }

  Future<DetectionResult> detect(String inspectionId) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/inspections/$inspectionId/detect',
    );
    return DetectionResult.fromJson(resp.data!);
  }

  Future<Inspection> getById(String inspectionId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/inspections/$inspectionId',
    );
    return Inspection.fromJson(resp.data!);
  }
}

final inspectionRepositoryProvider = Provider<InspectionRepository>(
  (ref) => InspectionRepository(ref.read(dioProvider)),
);
