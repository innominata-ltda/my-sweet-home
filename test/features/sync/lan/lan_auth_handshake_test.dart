import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/config/security_limits.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/sync/data/lan/frame_reader.dart';
import 'package:my_sweet_home/features/sync/data/lan/lan_auth_handshake.dart';
import 'package:my_sweet_home/features/sync/domain/sync_batch.dart';

void main() {
  group('LanAuthHandshake (RN-403, RN-404, RN-408, CA-2.1, CA-2.3)', () {
    late HouseholdKey keyA;
    late HouseholdKey keyB;
    late SecurityLimits limits;

    setUp(() {
      keyA = HouseholdKey(List.generate(32, (i) => i));
      keyB = HouseholdKey(List.generate(32, (i) => i ^ 0xFF));
      limits = const SecurityLimits(
        lanPreAuthMaxBytes: 4096,
        lanPreAuthTimeout: Duration(milliseconds: 300),
      );
    });

    test(
      'handshake with same key establishes same session key (RN-403)',
      () async {
        final clientToServer = StreamController<List<int>>();
        final serverToClient = StreamController<List<int>>();

        final handshakeServer = LanAuthHandshake(
          key: keyA,
          randomBytes: (n) =>
              Uint8List.fromList(List.generate(n, (i) => 0xAA ^ i)),
        );
        final handshakeClient = LanAuthHandshake(
          key: keyA,
          randomBytes: (n) =>
              Uint8List.fromList(List.generate(n, (i) => 0xBB ^ i)),
        );

        final serverReader = FrameReader(clientToServer.stream);
        final clientReader = FrameReader(serverToClient.stream);

        try {
          final serverFuture = handshakeServer.runAsServer(
            serverReader,
            serverToClient.sink,
            limits,
          );
          final clientFuture = handshakeClient.runAsClient(
            clientReader,
            clientToServer.sink,
            limits,
          );

          final results = await Future.wait<Result<LanSession, Failure>>([
            serverFuture,
            clientFuture,
          ]);
          expect(results[0].isOk, isTrue);
          expect(results[1].isOk, isTrue);

          final serverSession = results[0].valueOrNull!;
          final clientSession = results[1].valueOrNull!;

          expect(
            serverSession.sessionKey.bytes,
            equals(clientSession.sessionKey.bytes),
          );
        } finally {
          await serverReader.cancel();
          await clientReader.cancel();
          unawaited(clientToServer.close());
          unawaited(serverToClient.close());
        }
      },
    );

    test('client without household key rejects server challenge with badProof (RN-403, CA-2.1)', () async {
      final clientToServer = StreamController<List<int>>();
      final serverToClient = StreamController<List<int>>();

      final handshakeServer = LanAuthHandshake(
        key: keyA,
        randomBytes: (n) => Uint8List.fromList(List.generate(n, (i) => 0x11)),
      );
      final handshakeClientWrong = LanAuthHandshake(
        key: keyB, // different key
        randomBytes: (n) => Uint8List.fromList(List.generate(n, (i) => 0x22)),
      );

      final serverReader = FrameReader(clientToServer.stream);
      final clientReader = FrameReader(serverToClient.stream);

      try {
        final serverFuture = handshakeServer.runAsServer(
          serverReader,
          serverToClient.sink,
          limits,
        );
        final clientFuture = handshakeClientWrong.runAsClient(
          clientReader,
          clientToServer.sink,
          limits,
        );

        final results = await Future.wait<Result<LanSession, Failure>>([
          serverFuture,
          clientFuture,
        ]);
        final serverRes = results[0];
        final clientRes = results[1];

        // Client detects invalid sp
        expect(clientRes.isErr, isTrue);
        final clientFailure = clientRes.failureOrNull as LanAuthFailure;
        expect(clientFailure.kind, equals(LanAuthFailureKind.badProof));

        // Server receives no proof and times out
        expect(serverRes.isErr, isTrue);
        final serverFailure = serverRes.failureOrNull as LanAuthFailure;
        expect(serverFailure.kind, equals(LanAuthFailureKind.timeout));
      } finally {
        await serverReader.cancel();
        await clientReader.cancel();
        unawaited(clientToServer.close());
        unawaited(serverToClient.close());
      }
    });

    test(
      'server rejects client with forged cp proof (badProof) (RN-403)',
      () async {
        final clientToServer = StreamController<List<int>>();
        final serverToClient = StreamController<List<int>>();

        final handshakeServer = LanAuthHandshake(
          key: keyA,
          randomBytes: (n) => Uint8List.fromList(List.generate(n, (i) => 0x11)),
        );

        final serverReader = FrameReader(clientToServer.stream);
        final clientReader = FrameReader(serverToClient.stream);

        try {
          final serverFuture = handshakeServer.runAsServer(
            serverReader,
            serverToClient.sink,
            limits,
          );

          // Client sends valid Hello
          final cn = Uint8List(32);
          final helloPayload = utf8.encode(
            jsonEncode({'v': 2, 'cn': base64Url.encode(cn)}),
          );
          final h1 = ByteData(4)..setUint32(0, helloPayload.length);
          clientToServer.add(h1.buffer.asUint8List());
          clientToServer.add(helloPayload);

          // Client reads Challenge from server
          final challenge = await clientReader.next(
            maxBytes: 4096,
            timeout: const Duration(seconds: 1),
          );
          expect(challenge, isNotNull);

          // Client responds with forged cp (32 bytes of 0xFF)
          final forgedCp = Uint8List.fromList(List.filled(32, 0xFF));
          final proofPayload = utf8.encode(
            jsonEncode({'v': 2, 'cp': base64Url.encode(forgedCp)}),
          );
          final h2 = ByteData(4)..setUint32(0, proofPayload.length);
          clientToServer.add(h2.buffer.asUint8List());
          clientToServer.add(proofPayload);

          final serverRes = await serverFuture;
          expect(serverRes.isErr, isTrue);
          final failure = serverRes.failureOrNull as LanAuthFailure;
          expect(failure.kind, equals(LanAuthFailureKind.badProof));
        } finally {
          await serverReader.cancel();
          await clientReader.cancel();
          unawaited(clientToServer.close());
          unawaited(serverToClient.close());
        }
      },
    );

    test(
      'client with old protocol version is rejected with oldProtocol',
      () async {
        final clientToServer = StreamController<List<int>>();
        final serverToClient = StreamController<List<int>>();

        final handshakeServer = LanAuthHandshake(
          key: keyA,
          randomBytes: Uint8List.new,
        );

        final serverReader = FrameReader(clientToServer.stream);

        try {
          final serverFuture = handshakeServer.runAsServer(
            serverReader,
            serverToClient.sink,
            limits,
          );

          // Client sends frame with version 1
          final payload = utf8.encode(jsonEncode({'v': 1, 'cn': 'base64cn'}));
          final header = ByteData(4)..setUint32(0, payload.length);
          clientToServer.add(header.buffer.asUint8List());
          clientToServer.add(payload);

          final serverRes = await serverFuture;
          expect(serverRes.isErr, isTrue);
          final failure = serverRes.failureOrNull as LanAuthFailure;
          expect(failure.kind, equals(LanAuthFailureKind.oldProtocol));
        } finally {
          await serverReader.cancel();
          unawaited(clientToServer.close());
          unawaited(serverToClient.close());
        }
      },
    );

    test('data larger than 4 KB before proof is rejected with tooLarge (RN-404, CA-2.1)', () async {
      final clientToServer = StreamController<List<int>>();
      final serverToClient = StreamController<List<int>>();

      final handshakeServer = LanAuthHandshake(
        key: keyA,
        randomBytes: Uint8List.new,
      );

      final serverReader = FrameReader(clientToServer.stream);

      try {
        final serverFuture = handshakeServer.runAsServer(
          serverReader,
          serverToClient.sink,
          limits,
        );

        // Declares 5 KB frame (> 4096 bytes)
        final header = ByteData(4)..setUint32(0, 5000);
        clientToServer.add(header.buffer.asUint8List());

        final serverRes = await serverFuture;
        expect(serverRes.isErr, isTrue);
        final failure = serverRes.failureOrNull as LanAuthFailure;
        expect(failure.kind, equals(LanAuthFailureKind.tooLarge));
      } finally {
        await serverReader.cancel();
        unawaited(clientToServer.close());
        unawaited(serverToClient.close());
      }
    });

    test(
      'timeout in pre-authentication phase returns timeout (RN-404)',
      () async {
        final clientToServer = StreamController<List<int>>();
        final serverToClient = StreamController<List<int>>();

        final handshakeServer = LanAuthHandshake(
          key: keyA,
          randomBytes: Uint8List.new,
        );

        final serverReader = FrameReader(clientToServer.stream);

        try {
          final serverFuture = handshakeServer.runAsServer(
            serverReader,
            serverToClient.sink,
            const SecurityLimits(
              lanPreAuthMaxBytes: 4096,
              lanPreAuthTimeout: Duration(milliseconds: 50),
            ),
          );

          // Sends nothing through clientToServer
          final serverRes = await serverFuture;
          expect(serverRes.isErr, isTrue);
          final failure = serverRes.failureOrNull as LanAuthFailure;
          expect(failure.kind, equals(LanAuthFailureKind.timeout));
        } finally {
          await serverReader.cancel();
          unawaited(clientToServer.close());
          unawaited(serverToClient.close());
        }
      },
    );

    test('nonces unicos geram sessionKeys distintas a cada conexao (RN-408, CA-2.3)', () async {
      final h1 = LanAuthHandshake(
        key: keyA,
        randomBytes: (n) => Uint8List.fromList(List.generate(n, (i) => i + 1)),
      );
      final h2 = LanAuthHandshake(
        key: keyA,
        randomBytes: (n) => Uint8List.fromList(List.generate(n, (i) => i + 10)),
      );

      final c2s1 = StreamController<List<int>>();
      final s2c1 = StreamController<List<int>>();
      final r1 = FrameReader(c2s1.stream);
      final cr1 = FrameReader(s2c1.stream);

      LanSession s1;
      try {
        final fServer1 = h1.runAsServer(r1, s2c1.sink, limits);
        final fClient1 = h2.runAsClient(cr1, c2s1.sink, limits);
        s1 = (await Future.wait<Result<LanSession, Failure>>([
          fServer1,
          fClient1,
        ]))[0].valueOrNull!;
      } finally {
        await r1.cancel();
        await cr1.cancel();
        unawaited(c2s1.close());
        unawaited(s2c1.close());
      }

      final h3 = LanAuthHandshake(
        key: keyA,
        randomBytes: (n) => Uint8List.fromList(List.generate(n, (i) => i + 20)),
      );
      final h4 = LanAuthHandshake(
        key: keyA,
        randomBytes: (n) => Uint8List.fromList(List.generate(n, (i) => i + 30)),
      );

      final c2s2 = StreamController<List<int>>();
      final s2c2 = StreamController<List<int>>();
      final r2 = FrameReader(c2s2.stream);
      final cr2 = FrameReader(s2c2.stream);

      LanSession s2;
      try {
        final fServer2 = h3.runAsServer(r2, s2c2.sink, limits);
        final fClient2 = h4.runAsClient(cr2, c2s2.sink, limits);
        s2 = (await Future.wait<Result<LanSession, Failure>>([
          fServer2,
          fClient2,
        ]))[0].valueOrNull!;
      } finally {
        await r2.cancel();
        await cr2.cancel();
        unawaited(c2s2.close());
        unawaited(s2c2.close());
      }

      // Session keys must be completely different
      expect(s1.sessionKey.bytes, isNot(equals(s2.sessionKey.bytes)));
    });
  });
}
