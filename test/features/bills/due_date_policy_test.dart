import 'package:my_sweet_home/features/bills/domain/due_date_policy.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DueDatePolicy (CA-1.2)', () {
    late DueDatePolicy policy;

    setUp(() {
      policy = const StandardDueDatePolicy();
    });

    test('dueDay 31 em fevereiro de 2026 -> 2026-02-28', () {
      final date = policy.dueDateFor(
        dueDay: 31,
        month: const YearMonth('2026-02'),
      );
      expect(date, DateTime.utc(2026, 2, 28));
    });

    test('dueDay 30 em fevereiro de 2026 -> 2026-02-28', () {
      final date = policy.dueDateFor(
        dueDay: 30,
        month: const YearMonth('2026-02'),
      );
      expect(date, DateTime.utc(2026, 2, 28));
    });

    test('dueDay 29 em ano bissexto (fevereiro de 2024) -> 2024-02-29', () {
      final date = policy.dueDateFor(
        dueDay: 29,
        month: const YearMonth('2024-02'),
      );
      expect(date, DateTime.utc(2024, 2, 29));
    });

    test('dueDay 31 em ano bissexto (fevereiro de 2024) -> 2024-02-29', () {
      final date = policy.dueDateFor(
        dueDay: 31,
        month: const YearMonth('2024-02'),
      );
      expect(date, DateTime.utc(2024, 2, 29));
    });

    test('dueDay 31 em abril de 2026 -> 2026-04-30', () {
      final date = policy.dueDateFor(
        dueDay: 31,
        month: const YearMonth('2026-04'),
      );
      expect(date, DateTime.utc(2026, 4, 30));
    });

    test('dueDay 15 em fevereiro de 2026 -> 2026-02-15', () {
      final date = policy.dueDateFor(
        dueDay: 15,
        month: const YearMonth('2026-02'),
      );
      expect(date, DateTime.utc(2026, 2, 15));
    });
  });
}
