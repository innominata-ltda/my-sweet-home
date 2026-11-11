import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/recurrence/materializer.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/data/database/database.dart' as db_pkg;

final class ExpenseMaterializer implements RecurrenceMaterializer {
  final db_pkg.AppDatabase db;
  final IdGenerator idGenerator;
  final DeterministicIdGenerator deterministicIdGen;

  ExpenseMaterializer({
    required this.db,
    required this.idGenerator,
    this.deterministicIdGen = const UuidV5DeterministicIdGenerator(),
  });

  @override
  RecurrenceKind get kind => RecurrenceKind.expense;

  @override
  Future<Result<int, Failure>> materializeUpTo(DateTime instant) async {
    try {
      int count = 0;
      final nowIso = instant.toIso8601String();

      await db.transaction(() async {
        final rules = await (db.select(
          db.recurringRules,
        )..where((t) => t.kind.equals('expense'))).get();

        for (final ruleRow in rules) {
          final startsOnDate = _parseUtc(ruleRow.startsOn);
          final rrule = RecurrenceRule.tryParse(
            ruleRow.rrule,
            dtStart: startsOnDate,
          );
          if (rrule == null) continue;

          final fromDate = ruleRow.lastMaterializedOn != null
              ? _parseUtc(ruleRow.lastMaterializedOn!)
                    .add(const Duration(days: 1))
              : startsOnDate;

          final occurrences = rrule
              .occurrencesBetween(fromDate, instant)
              .toList();
          if (occurrences.isEmpty) continue;

          final existingExpenses = await (db.select(
            db.expenses,
          )..where((t) => t.recurringRuleId.equals(ruleRow.id))).get();

          final existingDates = existingExpenses
              .map((e) => e.occurredOn)
              .toSet();
          DateTime? lastMaterialized;

          for (final occ in occurrences) {
            final occIso = occ.toIso8601String().substring(0, 10);

            if (!existingDates.contains(occIso)) {
              final id = deterministicIdGen.forOccurrence(ruleRow.id, occIso);
              await db
                  .into(db.expenses)
                  .insert(
                    db_pkg.ExpensesCompanion.insert(
                      id: id,
                      amountCents: ruleRow.amountCents ?? 0,
                      occurredOn: occIso,
                      categoryId: Value(ruleRow.categoryId),
                      description: Value(ruleRow.title),
                      recurringRuleId: Value(ruleRow.id),
                      createdAt: Value(nowIso),
                    ),
                    mode: InsertMode.insertOrIgnore,
                  );
              count++;
            }
            if (lastMaterialized == null || occ.isAfter(lastMaterialized)) {
              lastMaterialized = occ;
            }
          }

          if (lastMaterialized != null) {
            final lastMaterializedIso = lastMaterialized
                .toIso8601String()
                .substring(0, 10);
            bool shouldUpdate = false;
            if (ruleRow.lastMaterializedOn == null) {
              shouldUpdate = true;
            } else {
              final currentLast = _parseUtc(ruleRow.lastMaterializedOn!);
              if (lastMaterialized.isAfter(currentLast)) {
                shouldUpdate = true;
              }
            }
            if (shouldUpdate) {
              await (db.update(
                db.recurringRules,
              )..where((t) => t.id.equals(ruleRow.id))).write(
                db_pkg.RecurringRulesCompanion(
                  lastMaterializedOn: Value(lastMaterializedIso),
                ),
              );
            }
          }
        }
      });
      return Ok(count);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao materializar recorrentes', cause: e),
      );
    }
  }

  DateTime _parseUtc(String ymd) {
    final parts = ymd.split('-');
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
