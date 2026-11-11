/// Recurrence materialization tests — covers RN-017 and CA-10.1 (SPEC-001)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/bootstrap.dart';
import 'package:my_sweet_home/core/recurrence/materializer.dart';
import 'package:my_sweet_home/core/result/result.dart';

import '../fakes/fake_clock.dart';
import '../fakes/fake_materializer.dart';

void main() {
  group('T-23: Recurrence materialization (RN-017, CA-10.1)', () {
    test('CA-10.1: materialization runs once for all 3 kinds in bootstrap '
        'and reopening on same day creates no new occurrence', () async {
      final fakeClock = FakeClock(DateTime.utc(2026, 3, 10, 8, 0));

      final expenseMat = FakeMaterializer(
        kind: RecurrenceKind.expense,
        pendingCount: 2,
      );
      final billMat = FakeMaterializer(
        kind: RecurrenceKind.bill,
        pendingCount: 1,
      );
      final taskMat = FakeMaterializer(
        kind: RecurrenceKind.task,
        pendingCount: 3,
      );

      final useCase = DefaultMaterializeRecurrences(
        materializers: [expenseMat, billMat, taskMat],
        clock: fakeClock,
      );

      // 1ª abertura do app no dia 2026-03-10
      final firstResult = await bootstrap(useCase);

      expect(firstResult.isOk, isTrue);
      final firstCounts = firstResult.valueOrNull!;
      expect(firstCounts[RecurrenceKind.expense], 2);
      expect(firstCounts[RecurrenceKind.bill], 1);
      expect(firstCounts[RecurrenceKind.task], 3);

      expect(expenseMat.callCount, 1);
      expect(billMat.callCount, 1);
      expect(taskMat.callCount, 1);
      expect(expenseMat.calledInstants.single, DateTime.utc(2026, 3, 10, 8, 0));
      expect(billMat.calledInstants.single, DateTime.utc(2026, 3, 10, 8, 0));
      expect(taskMat.calledInstants.single, DateTime.utc(2026, 3, 10, 8, 0));

      // Simula reabertura do app mais tarde no mesmo dia (ex.: 14:00)
      fakeClock.advance(const Duration(hours: 6));
      expect(fakeClock.nowUtc(), DateTime.utc(2026, 3, 10, 14, 0));

      final secondResult = await bootstrap(useCase);

      expect(secondResult.isOk, isTrue);
      final secondCounts = secondResult.valueOrNull!;
      expect(secondCounts[RecurrenceKind.expense], 0);
      expect(secondCounts[RecurrenceKind.bill], 0);
      expect(secondCounts[RecurrenceKind.task], 0);

      // Cada materializador foi chamado 2 vezes (1 por abertura), mas 2ª vez retornou 0
      expect(expenseMat.callCount, 2);
      expect(billMat.callCount, 2);
      expect(taskMat.callCount, 2);
      expect(expenseMat.calledInstants.last, DateTime.utc(2026, 3, 10, 14, 0));
    });

    test('returns Err with first failure when a materializer fails', () async {
      final fakeClock = FakeClock(DateTime.utc(2026, 3, 10, 8, 0));

      final expenseMat = FakeMaterializer(
        kind: RecurrenceKind.expense,
        pendingCount: 2,
      );
      final billMat = FakeMaterializer(
        kind: RecurrenceKind.bill,
        failure: const StorageFailure(detail: 'disk read error'),
      );
      final taskMat = FakeMaterializer(
        kind: RecurrenceKind.task,
        pendingCount: 3,
      );

      final useCase = DefaultMaterializeRecurrences(
        materializers: [expenseMat, billMat, taskMat],
        clock: fakeClock,
      );

      final result = await bootstrap(useCase);

      expect(result.isErr, isTrue);
      final failure = result.failureOrNull;
      expect(failure, isA<StorageFailure>());
      expect((failure as StorageFailure).detail, 'disk read error');

      // Aborts on first error: taskMat was not called
      expect(expenseMat.callCount, 1);
      expect(billMat.callCount, 1);
      expect(taskMat.callCount, 0);
    });

    test('all 3 kinds are supported by RecurrenceKind enum', () {
      expect(RecurrenceKind.values, hasLength(3));
      expect(
        RecurrenceKind.values,
        containsAll([
          RecurrenceKind.expense,
          RecurrenceKind.bill,
          RecurrenceKind.task,
        ]),
      );
    });

    test('lista vazia de materializadores retorna Ok vazio', () async {
      final fakeClock = FakeClock(DateTime.utc(2026, 3, 10, 8, 0));
      final useCase = DefaultMaterializeRecurrences(
        materializers: [],
        clock: fakeClock,
      );

      final result = await bootstrap(useCase);

      expect(result.isOk, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('direct use case execution without bootstrap helper', () async {
      final fakeClock = FakeClock(DateTime.utc(2026, 3, 10, 8, 0));
      final mat = FakeMaterializer(
        kind: RecurrenceKind.expense,
        pendingCount: 4,
      );
      final useCase = DefaultMaterializeRecurrences(
        materializers: [mat],
        clock: fakeClock,
      );

      final result = await useCase();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull![RecurrenceKind.expense], 4);
    });

    test('multiple materializers of same kind accumulate in count', () async {
      final fakeClock = FakeClock(DateTime.utc(2026, 3, 10, 8, 0));
      final taskMat1 = FakeMaterializer(
        kind: RecurrenceKind.task,
        pendingCount: 2,
      );
      final taskMat2 = FakeMaterializer(
        kind: RecurrenceKind.task,
        pendingCount: 5,
      );

      final useCase = DefaultMaterializeRecurrences(
        materializers: [taskMat1, taskMat2],
        clock: fakeClock,
      );

      final result = await useCase();

      expect(result.isOk, isTrue);
      expect(result.valueOrNull![RecurrenceKind.task], 7);
    });

    test(
      'advancing day in clock allows new materialization on next day',
      () async {
        final fakeClock = FakeClock(DateTime.utc(2026, 3, 10, 8, 0));
        final expenseMat = FakeMaterializer(
          kind: RecurrenceKind.expense,
          pendingCount: 2,
        );

        final useCase = DefaultMaterializeRecurrences(
          materializers: [expenseMat],
          clock: fakeClock,
        );

        final day1Result = await bootstrap(useCase);
        expect(day1Result.valueOrNull![RecurrenceKind.expense], 2);

        // Advances to next day and adds new pending recurrences
        fakeClock.advance(const Duration(days: 1));
        expect(fakeClock.nowUtc(), DateTime.utc(2026, 3, 11, 8, 0));
        expenseMat.pendingCount = 3;

        final day2Result = await bootstrap(useCase);
        expect(day2Result.valueOrNull![RecurrenceKind.expense], 3);
        expect(expenseMat.callCount, 2);
      },
    );
  });
}
