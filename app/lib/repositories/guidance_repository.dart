import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
import '../models/guidance_response.dart';

class GuidanceRepository {
  const GuidanceRepository(this._dio);
  final Dio _dio;

  Future<GuidanceResponse> getByOntologyId(String ontologyId) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/guidance',
      queryParameters: {'ontology_id': ontologyId},
    );
    return GuidanceResponse.fromJson(resp.data!);
  }
}

final guidanceRepositoryProvider = Provider<GuidanceRepository>(
  (ref) => GuidanceRepository(ref.read(dioProvider)),
);
