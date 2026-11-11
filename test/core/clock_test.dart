// Testes de Clock e IdGenerator — cobre CA-3.1 (SPEC-001) e RN-004, RN-005

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/time/clock.dart';
import 'package:my_sweet_home/core/id/id_generator.dart';

import '../fakes/fake_clock.dart';
import '../fakes/sequential_id_generator.dart';

void main() {
  group('FakeClock — tempo congelado (CA-3.1)', () {
    test('retorna o instante inicial exato', () {
      final clock = FakeClock(DateTime.utc(2026, 3, 10, 12, 0));
      expect(clock.nowUtc(), DateTime.utc(2026, 3, 10, 12, 0));
    });

    test('advance(1 day) move para o dia seguinte', () {
      final clock = FakeClock(DateTime.utc(2026, 3, 10, 12, 0));
      clock.advance(const Duration(days: 1));
      expect(clock.nowUtc(), DateTime.utc(2026, 3, 11, 12, 0));
    });

    test('advance with zero duration does not change', () {
      final clock = FakeClock(DateTime.utc(2026, 3, 10));
      clock.advance(Duration.zero);
      expect(clock.nowUtc(), DateTime.utc(2026, 3, 10));
    });

    test('setTo altera para o instante especificado', () {
      final clock = FakeClock(DateTime.utc(2026, 1, 1));
      clock.setTo(DateTime.utc(2030, 12, 31));
      expect(clock.nowUtc(), DateTime.utc(2030, 12, 31));
    });

    test('nowUtc sempre retorna UTC', () {
      final clock = FakeClock(DateTime.utc(2026, 3, 10, 12, 0));
      expect(clock.nowUtc().isUtc, isTrue);
    });

    test('setTo with local time converts to UTC', () {
      // Garantia: FakeClock sempre normaliza para UTC
      final localTime = DateTime(2026, 3, 10, 12, 0); // sem especificar UTC
      final clock = FakeClock(localTime);
      expect(clock.nowUtc().isUtc, isTrue);
    });

    test('todayUtc returns only date without time', () {
      final clock = FakeClock(DateTime.utc(2026, 3, 10, 23, 59));
      final today = clock.todayUtc();
      expect(today.year, 2026);
      expect(today.month, 3);
      expect(today.day, 10);
      expect(today.hour, 0);
      expect(today.minute, 0);
    });

    test('advance accumulated over multiple days', () {
      final clock = FakeClock(DateTime.utc(2026, 2, 28)); // fev 28
      clock.advance(const Duration(days: 1));
      expect(
        clock.nowUtc(),
        DateTime.utc(2026, 3, 1),
      ); // Mar 1 (2026 is not a leap year)
    });
  });

  group('SystemClock — sanidade', () {
    test('nowUtc returns UTC and is close to now', () {
      final clock = SystemClock();
      final before = DateTime.now().toUtc();
      final now = clock.nowUtc();
      final after = DateTime.now().toUtc();
      expect(now.isUtc, isTrue);
      expect(now.isAfter(before) || now.isAtSameMomentAs(before), isTrue);
      expect(now.isBefore(after) || now.isAtSameMomentAs(after), isTrue);
    });
  });

  group('SequentialIdGenerator (RN-005)', () {
    test('first ID is id-001', () {
      final gen = SequentialIdGenerator();
      expect(gen.newId(), 'id-001');
    });

    test('IDs are sequential', () {
      final gen = SequentialIdGenerator();
      expect(gen.newId(), 'id-001');
      expect(gen.newId(), 'id-002');
      expect(gen.newId(), 'id-003');
    });

    test('reset volta para id-001', () {
      final gen = SequentialIdGenerator();
      gen.newId();
      gen.newId();
      gen.reset();
      expect(gen.newId(), 'id-001');
    });

    test('prefix customizado', () {
      final gen = SequentialIdGenerator(prefix: 'bill');
      expect(gen.newId(), 'bill-001');
    });

    test('start customizado', () {
      final gen = SequentialIdGenerator(start: 10);
      expect(gen.newId(), 'id-010');
    });

    test('two generators are independent', () {
      final a = SequentialIdGenerator();
      final b = SequentialIdGenerator(prefix: 'x');
      a.newId();
      a.newId();
      expect(a.newId(), 'id-003');
      expect(b.newId(), 'x-001');
    });
  });

  group('UuidV7Generator (RN-005)', () {
    test('gera string no formato UUID v7', () {
      const gen = UuidV7Generator();
      final id = gen.newId();
      // UUID: 8-4-4-4-12 caracteres hexadecimais
      expect(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
        ).hasMatch(id),
        isTrue,
        reason: 'UUID v7 mal formatado: $id',
      );
    });

    test('version nibble is 7', () {
      const gen = UuidV7Generator();
      final id = gen.newId();
      // Segment 3 (after second comma) starts with '7'
      final parts = id.split('-');
      expect(parts[2].startsWith('7'), isTrue);
    });

    test('two consecutive IDs are different', () {
      const gen = UuidV7Generator();
      final a = gen.newId();
      final b = gen.newId();
      expect(a, isNot(equals(b)));
    });
  });
}
