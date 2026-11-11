import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/providers.dart';
import 'package:my_sweet_home/features/extras/data/repositories/drift_checklist_repository.dart';
import 'package:my_sweet_home/features/extras/domain/repositories/checklist_repository.dart';

final checklistRepositoryProvider = Provider<ChecklistRepository>((ref) {
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(clockProvider);
  final idGen = ref.watch(idGeneratorProvider);
  return DriftChecklistRepository(db: db, clock: clock, idGenerator: idGen);
});
