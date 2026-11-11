library;

import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/sync/domain/column_version.dart';
import 'package:my_sweet_home/core/sync/domain/sync_table_registry.dart';
import 'package:my_sweet_home/core/sync/domain/version_vector.dart';
import 'package:my_sweet_home/data/sync/change_source.dart';

/// Fake of [ChangeSource] for isolated applier and synchronization tests.
class FakeChangeSource implements ChangeSource {
  List<ColumnVersion> programmedChanges = [];
  VersionVector programmedLocalVector = VersionVector.empty;
  Failure? failure;

  @override
  Future<Result<List<ColumnVersion>, Failure>> changesNotCoveredBy(
    VersionVector peer,
    Set<SyncArea> areas,
  ) async {
    final f = failure;
    if (f != null) {
      return Err(f);
    }
    final filtered = programmedChanges
        .where((c) => !peer.covers(c.hlc))
        .toList();
    return Ok(filtered);
  }

  @override
  Future<VersionVector> localVector() async => programmedLocalVector;
}
