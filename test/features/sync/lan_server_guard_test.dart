import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/features/sync/domain/lan_server_guard.dart';

import '../../fakes/fake_clock.dart';

void main() {
  group('LanServerGuard (RN-406, RN-407, CA-2.4, CA-2.5)', () {
    late FakeClock clock;
    late SecurityLimits limits;
    late LanServerGuard guard;

    setUp(() {
      clock = FakeClock(DateTime.utc(2026, 3, 15, 12, 0, 0));
      limits = const SecurityLimits(
        lanMaxConcurrentConnections: 2,
        lanMaxAuthFailures: 5,
        lanAuthFailureWindow: Duration(minutes: 1),
        lanBanDuration: Duration(minutes: 5),
      );
      guard = LanServerGuard(limits: limits, clock: clock);
    });

    test('allows up to 2 concurrent connections and rejects 3rd (CA-2.4)', () {
      expect(guard.tryAcquire('192.168.1.10'), isTrue);
      expect(guard.tryAcquire('192.168.1.11'), isTrue);

      // 3rd concurrent connection must be rejected immediately
      expect(guard.tryAcquire('192.168.1.12'), isFalse);

      // Releasing a connection allows new attempt
      guard.release();
      expect(guard.tryAcquire('192.168.1.12'), isTrue);
    });

    test(
      'endereço com 5 falhas em 1 minuto é banido por 5 minutos (CA-2.5)',
      () {
        const remoteIp = '192.168.1.50';

        for (var i = 0; i < 4; i++) {
          guard.recordAuthFailure(remoteIp);
          clock.advance(const Duration(seconds: 10));
        }

        // On 4th failure, should still be able to retry connection
        expect(guard.tryAcquire(remoteIp), isTrue);
        guard.release();

        // 5ª falha dentro da janela de 1 minuto dispara o ban
        guard.recordAuthFailure(remoteIp);

        // Now IP is banned
        expect(guard.tryAcquire(remoteIp), isFalse);

        // Advance 4 minutes (still within 5 min ban period)
        clock.advance(const Duration(minutes: 4));
        expect(guard.tryAcquire(remoteIp), isFalse);

        // Advance another 1 minute and 1 second (past 5 minute ban)
        clock.advance(const Duration(seconds: 61));
        expect(guard.tryAcquire(remoteIp), isTrue);
      },
    );

    test('failures outside 1-minute window do not accumulate for ban', () {
      const remoteIp = '192.168.1.60';

      for (var i = 0; i < 4; i++) {
        guard.recordAuthFailure(remoteIp);
        clock.advance(
          const Duration(seconds: 30),
        ); // total 120s: first ones already left the window
      }

      guard.recordAuthFailure(remoteIp);

      // As failures spaced beyond 1 minute, does not reach 5 in window
      expect(guard.tryAcquire(remoteIp), isTrue);
    });

    test('banning an IP does not affect other IPs', () {
      const badIp = '192.168.1.100';
      const goodIp = '192.168.1.200';

      for (var i = 0; i < 5; i++) {
        guard.recordAuthFailure(badIp);
      }

      expect(guard.tryAcquire(badIp), isFalse);
      expect(guard.tryAcquire(goodIp), isTrue);
    });
  });
}
