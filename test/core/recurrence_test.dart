// ignore_for_file: prefer_const_declarations

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/recurrence/recurrence_rule.dart';

void main() {
  // Helpers
  DateTime utc(int year, int month, int day) => DateTime.utc(year, month, day);

  group('RecurrenceRule.tryParse — invalid rules', () {
    test('string vazia retorna null', () {
      expect(RecurrenceRule.tryParse(''), isNull);
    });

    test('sem FREQ retorna null', () {
      expect(RecurrenceRule.tryParse('INTERVAL=1;COUNT=3'), isNull);
    });

    test('FREQ desconhecido retorna null', () {
      expect(RecurrenceRule.tryParse('FREQ=YEARLY'), isNull);
    });

    test('invalid INTERVAL returns null', () {
      expect(RecurrenceRule.tryParse('FREQ=DAILY;INTERVAL=0'), isNull);
    });

    test('aceita prefixo RRULE:', () {
      final rule = RecurrenceRule.tryParse(
        'RRULE:FREQ=DAILY;COUNT=1',
        dtStart: utc(2026, 1, 1),
      );
      expect(rule, isNotNull);
    });

    test('unknown fields are ignored', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY;COUNT=1;WKST=MO;BYSETPOS=1',
        dtStart: utc(2026, 1, 1),
      );
      expect(rule, isNotNull);
    });
  });

  group('FREQ=DAILY — basic', () {
    test('COUNT=3 a partir de 2026-03-01', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY;COUNT=3',
        dtStart: utc(2026, 3, 1),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 3, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 3, 1), utc(2026, 3, 2), utc(2026, 3, 3)]);
    });

    test('INTERVAL=2 com UNTIL', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY;INTERVAL=2;UNTIL=20260110T000000Z',
        dtStart: utc(2026, 1, 1),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 1, 31))
          .toList();
      expect(result, [
        utc(2026, 1, 1),
        utc(2026, 1, 3),
        utc(2026, 1, 5),
        utc(2026, 1, 7),
        utc(2026, 1, 9),
      ]);
    });

    test('UNTIL without occurrences before from returns empty', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY;COUNT=3',
        dtStart: utc(2026, 1, 1),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 2, 1), utc(2026, 12, 31))
          .toList();
      expect(result, isEmpty);
    });

    test(
      'occurrencesBetween includes from and to when matching recurrence rule',
      () {
        final rule = RecurrenceRule.tryParse(
          'FREQ=DAILY',
          dtStart: utc(2026, 1, 1),
        )!;
        final result = rule
            .occurrencesBetween(utc(2026, 1, 3), utc(2026, 1, 5))
            .toList();
        expect(result, [utc(2026, 1, 3), utc(2026, 1, 4), utc(2026, 1, 5)]);
      },
    );
  });

  group('FREQ=WEEKLY', () {
    test('BYDAY=MO;COUNT=3 a partir de 2026-03-02 (segunda)', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=WEEKLY;BYDAY=MO;COUNT=3',
        dtStart: utc(2026, 3, 2),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 3, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 3, 2), utc(2026, 3, 9), utc(2026, 3, 16)]);
    });

    test('BYDAY=SA,SU;COUNT=4 starting from 2026-03-07 (Saturday)', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=WEEKLY;BYDAY=SA,SU;COUNT=4',
        dtStart: utc(2026, 3, 7),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 3, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [
        utc(2026, 3, 7),
        utc(2026, 3, 8),
        utc(2026, 3, 14),
        utc(2026, 3, 15),
      ]);
    });

    test('sem BYDAY repete no mesmo dia da semana', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=WEEKLY;COUNT=3',
        dtStart: utc(2026, 3, 4), // quarta
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 3, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 3, 4), utc(2026, 3, 11), utc(2026, 3, 18)]);
    });

    test('INTERVAL=2 a cada 2 semanas', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=WEEKLY;INTERVAL=2;COUNT=3',
        dtStart: utc(2026, 1, 5), // segunda
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 1, 5), utc(2026, 1, 19), utc(2026, 2, 2)]);
    });

    test('BYDAY with multiple days and UNTIL', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=WEEKLY;BYDAY=MO,WE,FR;UNTIL=20260113T000000Z',
        dtStart: utc(2026, 1, 5), // segunda
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 1, 31))
          .toList();
      expect(result, [
        utc(2026, 1, 5), // MO
        utc(2026, 1, 7), // WE
        utc(2026, 1, 9), // FR
        utc(2026, 1, 12), // MO
        // 14/01 WE is beyond UNTIL(13/01)
      ]);
    });
  });

  group('FREQ=MONTHLY', () {
    test('BYMONTHDAY=15;COUNT=3 a partir de 2026-01-15', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;BYMONTHDAY=15;COUNT=3',
        dtStart: utc(2026, 1, 15),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 1, 15), utc(2026, 2, 15), utc(2026, 3, 15)]);
    });

    test('BYMONTHDAY=31;COUNT=3 — borda: fevereiro clamp para 28', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=3',
        dtStart: utc(2026, 1, 31),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [
        utc(2026, 1, 31),
        utc(2026, 2, 28), // non-leap February
        utc(2026, 3, 31),
      ]);
    });

    test(
      'BYMONTHDAY=31;COUNT=2 a partir de 2026-04-01 — abril clamp para 30',
      () {
        final rule = RecurrenceRule.tryParse(
          'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=2',
          dtStart: utc(2026, 4, 1),
        )!;
        final result = rule
            .occurrencesBetween(utc(2026, 4, 1), utc(2026, 12, 31))
            .toList();
        expect(result, [
          utc(2026, 4, 30), // abril tem 30 dias
          utc(2026, 5, 31),
        ]);
      },
    );

    test('INTERVAL=2;BYMONTHDAY=1;COUNT=3', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;INTERVAL=2;BYMONTHDAY=1;COUNT=3',
        dtStart: utc(2026, 1, 1),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 1, 1), utc(2026, 3, 1), utc(2026, 5, 1)]);
    });

    test('without BYMONTHDAY repeats on same day of month', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;COUNT=3',
        dtStart: utc(2026, 1, 20),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 1, 20), utc(2026, 2, 20), utc(2026, 3, 20)]);
    });

    test('BYMONTHDAY=29 in non-leap February -> 28', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;BYMONTHDAY=29;COUNT=3',
        dtStart: utc(2026, 1, 29),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [
        utc(2026, 1, 29),
        utc(2026, 2, 28), // 2026 is not a leap year
        utc(2026, 3, 29),
      ]);
    });

    test('BYMONTHDAY=30 in non-leap February -> 28', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;BYMONTHDAY=30;COUNT=3',
        dtStart: utc(2026, 1, 30),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 1, 30), utc(2026, 2, 28), utc(2026, 3, 30)]);
    });

    test('BYMONTHDAY=31 em ano bissexto — fevereiro clamp para 29', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;BYMONTHDAY=31;COUNT=3',
        dtStart: utc(2028, 1, 31), // 2028 is a leap year
      )!;
      final result = rule
          .occurrencesBetween(utc(2028, 1, 1), utc(2028, 12, 31))
          .toList();
      expect(result, [
        utc(2028, 1, 31),
        utc(2028, 2, 29), // 2028 is a leap year
        utc(2028, 3, 31),
      ]);
    });
  });

  group('nextAfter', () {
    test('FREQ=DAILY nextAfter(2026-01-05) → 2026-01-06', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY',
        dtStart: utc(2026, 1, 1),
      )!;
      expect(rule.nextAfter(utc(2026, 1, 5)), utc(2026, 1, 6));
    });

    test('nextAfter returns null when COUNT is exhausted', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY;COUNT=3',
        dtStart: utc(2026, 1, 1),
      )!;
      // Occurrences: 01/01, 02/01, 03/01. nextAfter(03/01) -> null
      expect(rule.nextAfter(utc(2026, 1, 3)), isNull);
    });

    test('nextAfter within occurrences works', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=WEEKLY;BYDAY=MO;COUNT=5',
        dtStart: utc(2026, 3, 2),
      )!;
      expect(rule.nextAfter(utc(2026, 3, 9)), utc(2026, 3, 16));
    });

    test('nextAfter before start returns first occurrence', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY;COUNT=3',
        dtStart: utc(2026, 5, 1),
      )!;
      expect(rule.nextAfter(utc(2026, 1, 1)), utc(2026, 5, 1));
    });

    test('MONTHLY nextAfter', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;BYMONTHDAY=15',
        dtStart: utc(2026, 1, 15),
      )!;
      expect(rule.nextAfter(utc(2026, 3, 15)), utc(2026, 4, 15));
    });
  });

  group('DTSTART embutido', () {
    test('DTSTART in string takes precedence over dtStart parameter', () {
      final rule = RecurrenceRule.tryParse(
        'DTSTART=20260301T000000Z;FREQ=DAILY;COUNT=2',
        dtStart: utc(2026, 1, 1), // ignorado
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 3, 1), utc(2026, 3, 2)]);
    });

    test('DTSTART sem hora (YYYYMMDD)', () {
      final rule = RecurrenceRule.tryParse(
        'DTSTART=20260501;FREQ=DAILY;COUNT=2',
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 5, 1), utc(2026, 5, 2)]);
    });
  });

  group('toString', () {
    test('represents rule as readable string', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;INTERVAL=2;BYMONTHDAY=15;COUNT=3',
        dtStart: utc(2026, 1, 15),
      )!;
      expect(rule.toString(), contains('MONTHLY'));
      expect(rule.toString(), contains('INTERVAL=2'));
      expect(rule.toString(), contains('COUNT=3'));
      expect(rule.toString(), contains('BYMONTHDAY=15'));
    });
  });

  group('occurrencesBetween — bordas de intervalo', () {
    test('from > to retorna vazio', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY',
        dtStart: utc(2026, 1, 1),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 6, 1), utc(2026, 1, 1))
          .toList();
      expect(result, isEmpty);
    });

    test('from == to and matches occurrence returns one element', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY',
        dtStart: utc(2026, 1, 1),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 5), utc(2026, 1, 5))
          .toList();
      expect(result, [utc(2026, 1, 5)]);
    });

    test('UNTIL matching exact boundary includes occurrence', () {
      final rule = RecurrenceRule.tryParse(
        'FREQ=DAILY;UNTIL=20260103T000000Z',
        dtStart: utc(2026, 1, 1),
      )!;
      final result = rule
          .occurrencesBetween(utc(2026, 1, 1), utc(2026, 12, 31))
          .toList();
      expect(result, [utc(2026, 1, 1), utc(2026, 1, 2), utc(2026, 1, 3)]);
    });
  });

  group('Coverage extras', () {
    test('toString() com UNTIL e BYDAY', () {
      final rule1 = RecurrenceRule.tryParse(
        'FREQ=DAILY;UNTIL=20261231T235959Z',
      );
      expect(
        rule1?.toString(),
        'RecurrenceRule(FREQ=DAILY;UNTIL=2026-12-31 23:59:59.000Z)',
      );

      final rule2 = RecurrenceRule.tryParse('FREQ=WEEKLY;BYDAY=MO,WE,FR');
      expect(rule2?.toString(), 'RecurrenceRule(FREQ=WEEKLY;BYDAY=MO,WE,FR)');
    });

    test('UNTIL bloqueia em DAILY e WEEKLY e MONTHLY', () {
      final daily = RecurrenceRule.tryParse(
        'FREQ=DAILY;UNTIL=20260102T000000Z',
        dtStart: DateTime.utc(2026, 1, 1),
      );
      final dailyOccs = daily
          ?.occurrencesBetween(
            DateTime.utc(2026, 1, 1),
            DateTime.utc(2026, 1, 5),
          )
          .toList();
      expect(dailyOccs, [DateTime.utc(2026, 1, 1), DateTime.utc(2026, 1, 2)]);

      final weekly = RecurrenceRule.tryParse(
        'FREQ=WEEKLY;BYDAY=MO;UNTIL=20260113T000000Z',
        dtStart: DateTime.utc(2026, 1, 5),
      );
      // Jan 5, 2026 is Monday. Jan 12 is Monday. Jan 19 is > 13th.
      final weeklyOccs = weekly
          ?.occurrencesBetween(
            DateTime.utc(2026, 1, 5),
            DateTime.utc(2026, 1, 20),
          )
          .toList();
      expect(weeklyOccs, [DateTime.utc(2026, 1, 5), DateTime.utc(2026, 1, 12)]);

      final monthly = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;BYMONTHDAY=15;UNTIL=20260216T000000Z',
        dtStart: DateTime.utc(2026, 1, 15),
      );
      final monthlyOccs = monthly
          ?.occurrencesBetween(
            DateTime.utc(2026, 1, 15),
            DateTime.utc(2026, 3, 15),
          )
          .toList();
      expect(monthlyOccs, [
        DateTime.utc(2026, 1, 15),
        DateTime.utc(2026, 2, 15),
      ]);
    });

    test('INTERVAL longo cruza ano em MONTHLY', () {
      final monthly = RecurrenceRule.tryParse(
        'FREQ=MONTHLY;INTERVAL=14;BYMONTHDAY=1',
        dtStart: DateTime.utc(2026, 1, 1),
      );
      final occs = monthly
          ?.occurrencesBetween(
            DateTime.utc(2026, 1, 1),
            DateTime.utc(2027, 12, 31),
          )
          .take(2)
          .toList();
      // Jan 2026 + 14 months = March 2027
      expect(occs, [DateTime.utc(2026, 1, 1), DateTime.utc(2027, 3, 1)]);
    });

    test('dtStart nulo usa fallback utc(0)', () {
      // tryParse sem dtStart usa utc(0).
      // Testing occurrences close to year 0
      final rule = RecurrenceRule.tryParse('FREQ=DAILY;COUNT=1');
      final occs = rule
          ?.occurrencesBetween(DateTime.utc(-1), DateTime.utc(1))
          .toList();
      expect(occs?.isNotEmpty, true);
      expect(occs?.first, DateTime.utc(0));
    });
  });
}
