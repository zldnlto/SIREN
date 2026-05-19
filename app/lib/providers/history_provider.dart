import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/inspection.dart';
import '../repositories/inspection_repository.dart';

final historyProvider =
    FutureProvider.autoDispose<List<Inspection>>((ref) async {
  // TODO: implement list endpoint when available
  return [];
});

final inspectionDetailProvider =
    FutureProvider.autoDispose.family<Inspection, String>(
  (ref, id) => ref.read(inspectionRepositoryProvider).getById(id),
);
