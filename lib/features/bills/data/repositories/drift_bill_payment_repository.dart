import 'package:drift/drift.dart' hide Column;
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/data/database/database.dart' as db;
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment_repository.dart';
import 'package:my_sweet_home/features/expenses/domain/models/year_month.dart';

class DriftBillPaymentRepository implements BillPaymentRepository {
  final db.AppDatabase _db;

  DriftBillPaymentRepository(this._db);

  BillPayment _map(db.BillPayment data) {
    return BillPayment(
      id: data.id,
      billId: data.billId ?? '',
      dueOn: DateTime.parse(data.dueOn),
      paidOn: data.paidOn != null ? DateTime.parse(data.paidOn!) : null,
      paidAmount: data.amountCents != null ? Money(data.amountCents!) : null,
    );
  }

  @override
  Future<Result<List<BillPayment>, Failure>> ofMonth(YearMonth m) async {
    try {
      final start = DateTime.utc(
        int.parse(m.iso.substring(0, 4)),
        int.parse(m.iso.substring(5, 7)),
      ).toIso8601String();
      final year = int.parse(m.iso.substring(0, 4));
      final month = int.parse(m.iso.substring(5, 7));
      final end = DateTime.utc(
        month == 12 ? year + 1 : year,
        month == 12 ? 1 : month + 1,
      ).toIso8601String();

      final rows = await (_db.select(
        _db.billPayments,
      )..where((t) => t.dueOn.isBetweenValues(start, end))).get();

      return Ok(rows.map(_map).toList());
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao listar pagamentos: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<BillPayment, Failure>> markPaid(
    BillPaymentId id, {
    required Money amount,
    required DateTime paidOn,
  }) async {
    try {
      await (_db.update(_db.billPayments)..where((t) => t.id.equals(id))).write(
        db.BillPaymentsCompanion(
          status: const Value('paid'),
          amountCents: Value(amount.cents),
          paidOn: Value(paidOn.toUtc().toIso8601String()),
        ),
      );

      final row = await (_db.select(
        _db.billPayments,
      )..where((t) => t.id.equals(id))).getSingle();
      return Ok(_map(row));
    } catch (e) {
      return Err(StorageFailure(detail: 'Erro ao pagar conta: $e', cause: e));
    }
  }

  @override
  Future<Result<BillPayment, Failure>> unmarkPaid(BillPaymentId id) async {
    try {
      await (_db.update(_db.billPayments)..where((t) => t.id.equals(id))).write(
        const db.BillPaymentsCompanion(
          status: Value('pending'),
          amountCents: Value(null),
          paidOn: Value(null),
        ),
      );

      final row = await (_db.select(
        _db.billPayments,
      )..where((t) => t.id.equals(id))).getSingle();
      return Ok(_map(row));
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao desmarcar pagamento: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<List<BillPayment>, Failure>> historyOf(BillId id) async {
    try {
      final rows =
          await (_db.select(_db.billPayments)
                ..where((t) => t.billId.equals(id))
                ..orderBy([
                  (t) => OrderingTerm(
                    expression: t.dueOn,
                    mode: OrderingMode.desc,
                  ),
                ]))
              .get();
      return Ok(rows.map(_map).toList());
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao carregar histórico: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<int, Failure>> upsertOccurrences(
    List<BillPayment> payments,
  ) async {
    try {
      int count = 0;
      await _db.transaction(() async {
        for (final p in payments) {
          final companion = db.BillPaymentsCompanion.insert(
            id: p.id,
            billId: Value(p.billId),
            dueOn: p.dueOn.toUtc().toIso8601String(),
            paidOn: Value(p.paidOn?.toUtc().toIso8601String()),
            amountCents: Value(p.paidAmount?.cents),
            status: p.paidOn != null ? 'paid' : 'pending',
          );

          await _db
              .into(_db.billPayments)
              .insert(companion, mode: InsertMode.insertOrIgnore);
          count++;
        }
      });
      return Ok(count);
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao inserir ocorrências: $e', cause: e),
      );
    }
  }

  @override
  Future<Result<BillPayment?, Failure>> byId(BillPaymentId id) async {
    try {
      final row = await (_db.select(
        _db.billPayments,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row == null) return const Ok(null);
      return Ok(_map(row));
    } catch (e) {
      return Err(
        StorageFailure(detail: 'Erro ao buscar pagamento: $e', cause: e),
      );
    }
  }
}
