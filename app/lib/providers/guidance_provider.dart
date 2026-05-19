import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/guidance_response.dart';
import '../repositories/guidance_repository.dart';

final guidanceProvider =
    FutureProvider.autoDispose.family<GuidanceResponse, String>(
  (ref, ontologyId) =>
      ref.read(guidanceRepositoryProvider).getByOntologyId(ontologyId),
);
