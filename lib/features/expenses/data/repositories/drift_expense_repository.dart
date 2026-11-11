import 'package:drift/drift.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/trash/trash_policy.dart';
import 'package:my_sweet_home/data/database/database.dart' as db_pkg;
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:my_sweet_home/features/expenses/domain/models/expense.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';
import 'package:my_sweet_home/features/expenses/domain/repositories/expense_repository.dart';

class DriftExpenseRepository implements ExpenseRepository {
  final db_pkg.AppDatabase db;
  final Clock clock;
  final IdGenerator idGenerator;
  final TrashPolicy trashPolicy;

  DriftExpenseRepository({
    required this.db,
    required this.clock,
    required this.idGenerator,
    required this.trashPolicy,
  });

  @override
  Future<Result<Expense, Failure>> add(NewExpense e, {String? rrule}) async {
    try {
      final now = clock.nowUtc();

      if (rrule != null && rrule.isNotEmpty) {
        final ruleId = idGenerator.newId();
        await db
            .into(db.recurringRules)
            .insert(
              db_pkg.RecurringRulesCompanion.insert(
                id: ruleId,
                kind: 'expense',
                rrule: rrule,
                startsOn: e.occurredOn.toIso8601String().substring(0, 10),
                amountCents: Value(e.amount.cents),
                categoryId: Value(e.categoryId?.value),
                title: e.description ?? '',
                lastMaterializedOn: const Value(null),
              ),
            );

        return Ok(
          Expense(
            id: ExpenseId(ruleId),
            amount: e.amount,
            occurredOn: DateTime.parse(
              '${e.occurredOn.toIso8601String().substring(0, 10)}T00:00:00Z',
            ),
            description: e.description,
            notes: e.notes,
            categoryId: e.categoryId,
            recurringRuleId: ruleId,
            billId: e.billId,
            purchaseId: e.purchaseId,
            createdAt: now,
          ),
        );
      }

      final id = idGenerator.newId();
      await db
          .into(db.expenses)
          .insert(
            db_pkg.ExpensesCompanion.insert(
              id: id,
              amountCents: e.amount.cents,
              occurredOn: e.occurredOn.toIso8601String().substring(0, 10),
              categoryId: Value(e.categoryId?.value),
              description: Value(e.description),
              notes: Value(e.notes),
              billId: Value(e.billId),
              purchaseId: Value(e.purchaseId),
              createdAt: Value(now.toIso8601String()),
            ),
          );

      return Ok(
        Expense(
          id: ExpenseId(id),
          amount: e.amount,
          occurredOn: DateTime.parse(
            '${e.occurredOn.toIso8601String().substring(0, 10)}T00:00:00Z',
          ),
          description: e.description,
          notes: e.notes,
          categoryId: e.categoryId,
          billId: e.billId,
          purchaseId: e.purchaseId,
          createdAt: now,
        ),
      );
    } catch (err) {
      return Err(
        StorageFailure(detail: 'Erro ao adicionar despesa', cause: err),
      );
    }
  }

  @override
  Future<Result<Expense, Failure>> update(
    ExpenseId id,
    NewExpense e, {
    String? rrule,
  }) async {
    try {
      final now = clock.nowUtc();

      final currentExpense = await (db.select(
        db.expenses,
      )..where((tbl) => tbl.id.equals(id.value))).getSingleOrNull();

      if (currentExpense == null) {
        return Err(NotFoundFailure(what: 'Expense ${id.value} not found'));
      }

      String? ruleId = currentExpense.recurringRuleId;

      if (rrule != null && rrule.isNotEmpty) {
        if (ruleId != null) {
          await (db.update(
            db.recurringRules,
          )..where((tbl) => tbl.id.equals(ruleId!))).write(
            db_pkg.RecurringRulesCompanion(
              rrule: Value(rrule),
              amountCents: Value(e.amount.cents),
              title: Value(e.description ?? ''),
              categoryId: Value(e.categoryId?.value),
            ),
          );
        } else {
          ruleId = idGenerator.newId();
          await db
              .into(db.recurringRules)
              .insert(
                db_pkg.RecurringRulesCompanion.insert(
                  id: ruleId,
                  kind: 'expense',
                  rrule: rrule,
                  startsOn: e.occurredOn.toIso8601String().substring(0, 10),
                  amountCents: Value(e.amount.cents),
                  categoryId: Value(e.categoryId?.value),
                  title: e.description ?? '',
                  lastMaterializedOn: const Value(null),
                ),
              );
        }
      }

      final updatedRows =
          await (db.update(
            db.expenses,
          )..where((tbl) => tbl.id.equals(id.value))).write(
            db_pkg.ExpensesCompanion(
              amountCents: Value(e.amount.cents),
              occurredOn: Value(
                e.occurredOn.toIso8601String().substring(0, 10),
              ),
              categoryId: Value(e.categoryId?.value),
              description: Value(e.description),
              notes: Value(e.notes),
              recurringRuleId: Value(ruleId),
              updatedAt: Value(now.toIso8601String()),
            ),
          );

      if (updatedRows == 0) {
        return Err(NotFoundFailure(what: 'Expense ${id.value} not found'));
      }

      final row = await (db.select(
        db.expenses,
      )..where((tbl) => tbl.id.equals(id.value))).getSingle();
      return Ok(_mapToDomain(row));
    } catch (err) {
      return Err(
        StorageFailure(detail: 'Erro ao atualizar despesa', cause: err),
      );
    }
  }

  Future<db_pkg.RecurringRule?> getRecurringRule(String ruleId) async {
    try {
      return await (db.select(
        db.recurringRules,
      )..where((tbl) => tbl.id.equals(ruleId))).getSingleOrNull();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<String?> getRecurringRrule(String ruleId) async {
    final rule = await getRecurringRule(ruleId);
    return rule?.rrule;
  }

  @override
  Future<Result<TrashTicket, Failure>> remove(ExpenseId id) async {
    return trashPolicy.softDelete('expenses', id.value);
  }

  @override
  Future<Result<List<Expense>, Failure>> ofMonth(
    YearMonth m, {
    CategoryId? category,
  }) async {
    try {
      final bounds = m.bounds;
      final startIso = bounds.start.toIso8601String().substring(0, 10);
      final endIso = bounds.end.toIso8601String().substring(0, 10);

      final query = db.select(db.expenses)
        ..where((tbl) => tbl.deletedAt.isNull())
        ..where((tbl) => tbl.occurredOn.isBetweenValues(startIso, endIso));

      if (category != null) {
        query.where((tbl) => tbl.categoryId.equals(category.value));
      }

      query.orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.occurredOn, mode: OrderingMode.desc),
      ]);

      final rows = await query.get();
      return Ok(rows.map<Expense>(_mapToDomain).toList());
    } catch (err) {
      return Err(
        StorageFailure(detail: 'Erro ao buscar despesas do mês', cause: err),
      );
    }
  }

  @override
  Future<Result<Expense?, Failure>> byId(ExpenseId id) async {
    try {
      final query = db.select(db.expenses)
        ..where((tbl) => tbl.id.equals(id.value));
      final row = await query.getSingleOrNull();
      if (row == null || row.deletedAt != null) return const Ok(null);
      return Ok(_mapToDomain(row));
    } catch (err) {
      return Err(
        StorageFailure(detail: 'Erro ao buscar despesa por id', cause: err),
      );
    }
  }

  Expense _mapToDomain(db_pkg.Expense row) {
    return Expense(
      id: ExpenseId(row.id),
      amount: Money(row.amountCents),
      occurredOn: DateTime.parse('${row.occurredOn}T00:00:00Z'),
      description: row.description,
      notes: row.notes,
      categoryId: row.categoryId != null ? CategoryId(row.categoryId!) : null,
      recurringRuleId: row.recurringRuleId,
      billId: row.billId,
      purchaseId: row.purchaseId,
      createdAt: row.createdAt != null ? DateTime.parse(row.createdAt!) : null,
      updatedAt: row.updatedAt != null ? DateTime.parse(row.updatedAt!) : null,
      deletedAt: row.deletedAt != null ? DateTime.parse(row.deletedAt!) : null,
    );
  }
}
