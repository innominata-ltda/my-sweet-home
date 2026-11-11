import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/sync/domain/hlc.dart';

void main() {
  group('Hlc (Hybrid Logical Clock)', () {
    const siteA = 'device-a';
    const siteB = 'device-b';

    test('initial creation and constructors', () {
      const zero = Hlc.zero(siteA);
      expect(zero.millis, equals(0));
      expect(zero.counter, equals(0));
      expect(zero.siteId, equals(siteA));

      final nowHlc = Hlc.now(siteId: siteA, nowMillis: 1000);
      expect(nowHlc.millis, equals(1000));
      expect(nowHlc.counter, equals(0));
      expect(nowHlc.siteId, equals(siteA));
    });

    test('send advances clock and increments counter if same millisecond', () {
      final hlc0 = Hlc.now(siteId: siteA, nowMillis: 1000);

      // Evento no mesmo milissegundo: incrementa contador
      final hlc1 = hlc0.send(1000);
      expect(hlc1.millis, equals(1000));
      expect(hlc1.counter, equals(1));
      expect(hlc1.siteId, equals(siteA));

      final hlc2 = hlc1.send(1000);
      expect(hlc2.millis, equals(1000));
      expect(hlc2.counter, equals(2));

      // Event in forward millisecond: resets counter and updates millis
      final hlc3 = hlc2.send(2000);
      expect(hlc3.millis, equals(2000));
      expect(hlc3.counter, equals(0));

      // Event in backward millisecond (physical clock went back): preserves millis and increments counter
      final hlc4 = hlc3.send(1500);
      expect(hlc4.millis, equals(2000));
      expect(hlc4.counter, equals(1));
    });

    test('receive updates clock maintaining monotonicity between nodes', () {
      final local = Hlc(millis: 1000, counter: 5, siteId: siteA);
      final remote = Hlc(millis: 1000, counter: 8, siteId: siteB);

      // 1. Same local and remote millis, local clock at 1000:
      // counter deve ser max(local, remote) + 1 = 9
      final next1 = local.receive(remote, 1000);
      expect(next1.millis, equals(1000));
      expect(next1.counter, equals(9));
      expect(next1.siteId, equals(siteA)); // preserves local siteId

      // 2. Remote has higher millis: millis advances to remote and counter becomes remote.counter + 1
      final remoteAhead = Hlc(millis: 2000, counter: 3, siteId: siteB);
      final next2 = local.receive(remoteAhead, 1500);
      expect(next2.millis, equals(2000));
      expect(next2.counter, equals(4));

      // 3. Current local physical clock is ahead of both:
      // millis advances to nowMillis and counter resets
      final next3 = local.receive(remote, 3000);
      expect(next3.millis, equals(3000));
      expect(next3.counter, equals(0));

      // 4. Local millis ahead of remote and nowMillis:
      final localAhead = Hlc(millis: 5000, counter: 2, siteId: siteA);
      final remoteBehind = Hlc(millis: 4000, counter: 10, siteId: siteB);
      final next4 = localAhead.receive(remoteBehind, 4500);
      expect(next4.millis, equals(5000));
      expect(next4.counter, equals(3));
    });

    test('receive rejects remote clock with drift exceeding 24h (RN-320, HLC drift)', () {
      final local = Hlc(millis: 1000, counter: 0, siteId: siteA);
      const dayAndOneSecond = 24 * 60 * 60 * 1000 + 1000;
      final remoteFuture = Hlc(
        millis: 1000 + dayAndOneSecond,
        counter: 0,
        siteId: siteB,
      );

      expect(
        () => local.receive(remoteFuture, 1000),
        throwsA(isA<ClockDriftException>()),
      );

      // Within 24h does not throw
      const exactly24h = 24 * 60 * 60 * 1000;
      final remoteOk = Hlc(
        millis: 1000 + exactly24h,
        counter: 0,
        siteId: siteB,
      );
      expect(() => local.receive(remoteOk, 1000), returnsNormally);
    });

    test('strict ordering (RN-320): millis -> counter -> siteId', () {
      final h1 = Hlc(millis: 1000, counter: 0, siteId: 'a');
      final h2 = Hlc(millis: 1000, counter: 0, siteId: 'b');
      final h3 = Hlc(millis: 1000, counter: 1, siteId: 'a');
      final h4 = Hlc(millis: 2000, counter: 0, siteId: 'a');

      expect(h1 < h2, isTrue);
      expect(h2 < h3, isTrue);
      expect(h3 < h4, isTrue);

      expect(h4 > h3, isTrue);
      expect(h3 >= h2, isTrue);
      expect(h1 <= h1, isTrue);

      final list = [h4, h2, h1, h3];
      list.sort();
      expect(list, equals([h1, h2, h3, h4]));
    });

    test('pack and parse are bijective and preserve lexicographical ordering identical to compareTo', () {
      final h1 = Hlc(millis: 1729600000000, counter: 0, siteId: 'device-01');
      final h2 = Hlc(millis: 1729600000000, counter: 1, siteId: 'device-01');
      final h3 = Hlc(millis: 1729600000000, counter: 1, siteId: 'device-02');
      final h4 = Hlc(millis: 1729600000999, counter: 0, siteId: 'device-01');

      final p1 = h1.pack();
      final p2 = h2.pack();
      final p3 = h3.pack();
      final p4 = h4.pack();

      expect(p1.compareTo(p2), lessThan(0));
      expect(p2.compareTo(p3), lessThan(0));
      expect(p3.compareTo(p4), lessThan(0));

      expect(Hlc.parse(p1), equals(h1));
      expect(Hlc.parse(p2), equals(h2));
      expect(Hlc.parse(p3), equals(h3));
      expect(Hlc.parse(p4), equals(h4));
    });

    test('parse throws FormatException on malformed strings', () {
      expect(() => Hlc.parse(''), throwsFormatException);
      expect(() => Hlc.parse('curto'), throwsFormatException);
      // packed >= 31 chars but without colon after position 24
      expect(
        () => Hlc.parse('2026-10-22T10:00:00.000Zsemcolons_longo_aqui'),
        throwsFormatException,
      );
      // packed >= 31 chars com 1º colon mas sem 2º colon
      expect(
        () => Hlc.parse('2026-10-22T10:00:00.000Z:sem_segundo_colon_longo'),
        throwsFormatException,
      );
    });

    test('counter overflow advances millis by 1 and resets counter preserving monotonicity', () {
      final hlcAtMax = Hlc(
        millis: 1000,
        counter: Hlc.maxCounter,
        siteId: siteA,
      );

      // send at same millis with counter at limit: advances millis and resets counter
      final advancedSend = hlcAtMax.send(1000);
      expect(advancedSend.millis, equals(1001));
      expect(advancedSend.counter, equals(0));
      expect(advancedSend > hlcAtMax, isTrue);

      // receive with counter at limit: advances millis and resets counter
      final remoteAtMax = Hlc(
        millis: 1000,
        counter: Hlc.maxCounter,
        siteId: siteB,
      );
      final advancedReceive = hlcAtMax.receive(remoteAtMax, 1000);
      expect(advancedReceive.millis, equals(1001));
      expect(advancedReceive.counter, equals(0));
      expect(advancedReceive > hlcAtMax, isTrue);
    });

    test(
      'parse suporta ISO UTC sem milissegundos e preserva chave do site',
      () {
        final parsed = Hlc.parse('2026-10-22T10:00:00Z:00005:device-alpha');
        expect(parsed.counter, equals(5));
        expect(parsed.siteId, equals('device-alpha'));
        expect(
          parsed.millis,
          equals(DateTime.parse('2026-10-22T10:00:00Z').millisecondsSinceEpoch),
        );
      },
    );

    test('ClockDriftException toString', () {
      const ex = ClockDriftException(
        remoteMillis: 2000,
        localMillis: 1000,
        maxDriftMillis: 500,
      );
      expect(
        ex.toString(),
        contains('ClockDriftException: excessive clock drift'),
      );
    });

    test('igualdade e hashCode', () {
      final a1 = Hlc(millis: 500, counter: 2, siteId: 'x');
      final a2 = Hlc(millis: 500, counter: 2, siteId: 'x');
      final b = Hlc(millis: 500, counter: 2, siteId: 'y');

      expect(a1, equals(a2));
      expect(a1.hashCode, equals(a2.hashCode));
      expect(a1, isNot(equals(b)));
      expect(a1.toString(), equals(a1.pack()));
    });
  });
}
