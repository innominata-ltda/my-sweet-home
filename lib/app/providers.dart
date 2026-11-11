import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/storage/cloud_storage_port.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart';
import 'package:my_sweet_home/data/storage/google_drive_storage_adapter.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError();
});

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final idGeneratorProvider = Provider<IdGenerator>(
  (ref) => const UuidV7Generator(),
);

final trashPolicyProvider = Provider<TrashPolicy>((ref) {
  return DriftTrashPolicy(
    db: ref.watch(databaseProvider),
    clock: ref.watch(clockProvider),
  );
});

final cloudStoragePortProvider = Provider<CloudStoragePort>((ref) {
  return GoogleDriveStorageAdapter();
});
