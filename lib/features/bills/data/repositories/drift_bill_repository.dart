import 'package:drift/drift.dart' hide Column;
import 'package:my_sweet_home/core/id/deterministic_id.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';

class DriftBillRepository implements BillRepository {
  final db.AppDatabase _db;
  final IdGenerator _idGenerator;
  final DeterministicIdGenerator _deterministicIdGen;

  DriftBillRepository(
    this._db, {
    IdGenerator? idGenerator,
    DeterministicIdGenerator? deterministicIdGen,
  }) : _idGenerator = idGenerator ?? const UuidV7Generator(),
       _deterministicIdGen =
           deterministicIdGen ?? const UuidV5DeterministicIdGenerator();

  /// Returns deterministic ID for bill payment of [billId] on [dueOn] (RN-324, CA-5.4).
  String deterministicPaymentId(BillId billId, DateTime dueOn) {
    final iso =
        '${dueOn.year.toString().padLeft(4, '0')}-${dueOn.month.toString().padLeft(2, '0')}-${dueOn.day.toString().padLeft(2, '0')}';
    return _deterministicIdGen.forOccurrence(billId, iso);
  }

  Bill _map(db.Bill data) {
    return Bill(
      id: data.id,
      title: data.title,
      categoryId: CategoryId(data.categoryId ?? 'cat_other'),
      dueDay: data.dueDay,
      recurrence: RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!,
      amount: data.amountCents != null ? Money(data.amountCents!) : null,
      isEstimated: data.isAmountVariable,
      noticeDays: data.reminderDaysBefore,
      isPaused: !data.isActive,
    );
  }

  @override
  Future<Result<Bill, Failure>> upsert(NewBill b) async {
    try {
      final id = b.id ?? _idGenerator.newId();
      final companion = db.BillsCompanion.insert(
        id: id,
        title: b.title,
        amountCents: Value(b.amount?.cents),
        isAmountVariable: b.isEstimated,
        dueDay: b.dueDay,
        categoryId: Value(b.categoryId.value),
        reminderDaysBefore: Value(b.noticeDays),
        isActive: const Value(true),
      );

      await _db
          .into(_db.bills)
          .insert(companion, mode: InsertMode.insertOrReplace);

      final row = await (_db.select(
        _db.bills,
      )..where((t) => t.id.equals(id))).getSingle();
      return Ok(_map(row));
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao salvar conta: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> pause(BillId id) async {
    try {
      await (_db.update(_db.bills)..where((t) => t.id.equals(id))).write(
        const db.BillsCompanion(isActive: Value(false)),
      );
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao pausar conta: $e', cause: e));
    }
  }

  @override
  Future<Result<void, Failure>> delete(BillId id) async {
    try {
      await _db.transaction(() async {
        // 1. Unlink expenses associated with this recurring bill to preserve history
        // e evitar violacao de chave estrangeira (foreign key constraint).
        await (_db.update(_db.expenses)..where((t) => t.billId.equals(id)))
            .write(const db.ExpensesCompanion(billId: Value(null)));

        // 2. Desassociar despesas vinculadas por expenseId nas faturas/pagamentos
        final payments = await (_db.select(
          _db.billPayments,
        )..where((t) => t.billId.equals(id))).get();
        final expenseIds = payments
            .map((p) => p.expenseId)
            .whereType<String>()
            .toList();
        if (expenseIds.isNotEmpty) {
          await (_db.update(_db.expenses)..where((t) => t.id.isIn(expenseIds)))
              .write(const db.ExpensesCompanion(billId: Value(null)));
        }

        // 3. Excluir ocorrencias/faturas da conta
        await (_db.delete(
          _db.billPayments,
        )..where((t) => t.billId.equals(id))).go();

        // 4. Excluir a conta fixa
        await (_db.delete(_db.bills)..where((t) => t.id.equals(id))).go();
      });
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao excluir conta: $e', cause: e));
    }
  }

  @override
  Future<Result<List<Bill>, Failure>> active() async {
    try {
      final rows = await (_db.select(
        _db.bills,
      )..where((t) => t.isActive.equals(true))).get();
      return Ok(rows.map(_map).toList());
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao listar contas: $e', cause: e));
    }
  }

  @override
  Future<Result<Bill?, Failure>> byId(BillId id) async {
    try {
      final row = await (_db.select(
        _db.bills,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return const Ok(null);
      return Ok(_map(row));
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao buscar conta: $e', cause: e));
    }
  }
}
