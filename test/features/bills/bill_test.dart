import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';
import 'package:my_sweet_home/features/bills/domain/bill.dart';
import 'package:my_sweet_home/features/bills/domain/bill_payment.dart';
import 'package:my_sweet_home/features/expenses/domain/models/category.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fakes/fake_bill_repository.dart';
import '../../fakes/sequential_id_generator.dart';

void main() {
  group('Bill e BillRepository (RN-130)', () {
    late FakeBillRepository repository;
    late SequentialIdGenerator idGenerator;

    setUp(() {
      idGenerator = SequentialIdGenerator(prefix: 'bill');
      repository = FakeBillRepository(idGenerator);
    });

    test('Cadastra conta fixa com valor fixo', () async {
      final recurrence = RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!;
      final newBill = NewBill(
        title: 'Aluguel',
        categoryId: const CategoryId('cat-1'),
        dueDay: 5,
        recurrence: recurrence,
        amount: const Money(120000), // R$ 1200,00
        isEstimated: false,
        noticeDays: 3,
      );

      final result = await repository.upsert(newBill);
      expect(result.isOk, isTrue);

      final bill = result.valueOrNull!;
      expect(bill.id, 'bill-001');
      expect(bill.title, 'Aluguel');
      expect(bill.amount, const Money(120000));
      expect(bill.isEstimated, isFalse);

      final active = await repository.active();
      expect(active.valueOrNull, hasLength(1));
    });

    test('Cadastra conta fixa com valor estimado', () async {
      final recurrence = RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!;
      final newBill = NewBill(
        title: 'Luz',
        categoryId: const CategoryId('cat-2'),
        dueDay: 10,
        recurrence: recurrence,
        amount: const Money(15000), // R$ 150,00 estimado
        isEstimated: true,
      );

      final result = await repository.upsert(newBill);

      final bill = result.valueOrNull!;
      expect(bill.title, 'Luz');
      expect(bill.isEstimated, isTrue);
      expect(bill.amount, const Money(15000));
    });

    test('Cadastra conta fixa com valor variavel (sem estimativa)', () async {
      final recurrence = RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!;
      final newBill = NewBill(
        title: 'Água',
        categoryId: const CategoryId('cat-3'),
        dueDay: 15,
        recurrence: recurrence,
        amount: null,
        isEstimated: false,
      );

      final result = await repository.upsert(newBill);

      final bill = result.valueOrNull!;
      expect(bill.title, 'Água');
      expect(bill.isEstimated, isFalse);
      expect(bill.amount, isNull);
    });

    test('Bill igualdade (hashCode e ==)', () {
      final recurrence = RecurrenceRule.tryParse('FREQ=MONTHLY;INTERVAL=1')!;
      final b1 = Bill(
        id: '1',
        title: 'A',
        categoryId: const CategoryId('c1'),
        dueDay: 1,
        recurrence: recurrence,
        amount: const Money(100),
        isEstimated: false,
      );
      final b2 = Bill(
        id: '1',
        title: 'A',
        categoryId: const CategoryId('c1'),
        dueDay: 1,
        recurrence: recurrence,
        amount: const Money(100),
        isEstimated: false,
      );
      final b3 = Bill(
        id: '2',
        title: 'A',
        categoryId: const CategoryId('c1'),
        dueDay: 1,
        recurrence: recurrence,
        amount: const Money(100),
        isEstimated: false,
      );

      expect(b1, equals(b2));
      expect(b1.hashCode, equals(b2.hashCode));
      expect(b1, isNot(equals(b3)));
    });

    test('BillPayment igualdade, hashCode e propriedades', () {
      final due = DateTime(2026, 10, 15);
      final paid = DateTime(2026, 10, 14);
      final p1 = BillPayment(
        id: 'bp-1',
        billId: 'b-1',
        dueOn: due,
        paidOn: paid,
        paidAmount: const Money(15000),
      );
      final p2 = BillPayment(
        id: 'bp-1',
        billId: 'b-1',
        dueOn: due,
        paidOn: paid,
        paidAmount: const Money(15000),
      );
      final p3 = BillPayment(id: 'bp-2', billId: 'b-1', dueOn: due);

      expect(p1, equals(p1));
      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
      expect(p1, isNot(equals('other')));
      expect(p3.paidOn, isNull);
      expect(p3.paidAmount, isNull);
    });
  });
}
