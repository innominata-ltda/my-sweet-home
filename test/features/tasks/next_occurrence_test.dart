import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/tasks/domain/next_occurrence_policy.dart';

void main() {
  final policy = DefaultNextOccurrencePolicy();

  test('CA-1.1: "every 15 days", completion 10/03 -> 25/03', () {
    final rule = RecurrenceRule.tryParse(
      'FREQ=DAILY;INTERVAL=15',
      dtStart: DateTime.utc(2026, 3, 1),
    )!;

    final scheduledFor = DateTime.utc(2026, 3, 1);
    final completedAt = DateTime.utc(2026, 3, 10);

    final next = policy.next(
      rule: rule,
      scheduledFor: scheduledFor,
      completedAt: completedAt,
    );

    expect(next, DateTime.utc(2026, 3, 25));
  });

  test(
    'CA-1.2: "todo dia 10", conclusão atrasada 12/03 -> 10/04 (não 12/04)',
    () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;BYMONTHDAY=10',
        dtStart: DateTime.utc(2026, 3, 10),
      )!;

      final scheduledFor = DateTime.utc(2026, 3, 10);
      final completedAt = DateTime.utc(2026, 3, 12);

      final next = policy.next(
        rule: rule,
        scheduledFor: scheduledFor,
        completedAt: completedAt,
      );

      expect(next, DateTime.utc(2026, 4, 10));
    },
  );
}
