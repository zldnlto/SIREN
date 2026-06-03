import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api_client.dart';
import '../models/detection_result.dart';
import '../models/inspection.dart';
import '../models/inspection_detail.dart';

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

  Future<void> uploadImage(String inspectionId, XFile image) async {
    final bytes = await image.readAsBytes();
    final filename = image.name.isNotEmpty ? image.name : 'inspection.jpg';
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    await _dio.post<void>('/inspections/$inspectionId/upload', data: formData);
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

  Future<InspectionDetail> getDetail(String inspectionId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/dashboard/inspections/$inspectionId',
    );
    return InspectionDetail.fromJson(resp.data!);
  }

  Future<Inspection> report(String inspectionId) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      '/inspections/$inspectionId',
      data: {'report_flagged': true},
    );
    return Inspection.fromJson(resp.data!);
  }

  Future<Inspection> updateDomain(String inspectionId, String annotationDomain) async {
    final resp = await _dio.patch<Map<String, dynamic>>(
      '/inspections/$inspectionId',
      data: {'annotation_domain': annotationDomain},
    );
    return Inspection.fromJson(resp.data!);
  }
}

final inspectionRepositoryProvider = Provider<InspectionRepository>(
  (ref) => InspectionRepository(ref.read(dioProvider)),
);
