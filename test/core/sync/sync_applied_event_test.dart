import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/sync_applied_event.dart';

void main() {
  group('SyncAppliedEvent', () {
    test('instantiates and formats toString', () {
      const event = SyncAppliedEvent(
        householdId: 'h-1',
        fromSiteId: 'site-2',
        touchedTables: {'tasks'},
        touchedRowIds: {'row-3'},
        changesAppliedCount: 5,
      );

      expect(event.householdId, 'h-1');
      expect(event.fromSiteId, 'site-2');
      expect(event.touchedTables, {'tasks'});
      expect(event.touchedRowIds, {'row-3'});
      expect(event.changesAppliedCount, 5);
      expect(
        event.toString(),
        'SyncAppliedEvent(household: h-1, from: site-2, changes: 5)',
      );
    });
  });
}
