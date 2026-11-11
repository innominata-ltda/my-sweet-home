import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../../../core/config/security_limits.dart';
import '../../../../core/result/result.dart';
import '../../domain/sync_batch.dart';
import 'frame_reader.dart';

/// Failure types in LAN authentication handshake (RN-403, RN-404, RN-408).
enum LanAuthFailureKind { badProof, oldProtocol, timeout, tooLarge }

/// Failure during LAN authentication handshake.
final class LanAuthFailure extends Failure {
  final LanAuthFailureKind kind;

  const LanAuthFailure(this.kind);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanAuthFailure &&
          runtimeType == other.runtimeType &&
          kind == other.kind;

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() => 'LanAuthFailure(kind: $kind)';
}

/// Authenticated session containing ephemeral session key (Ks) and secure peer metadata (RN-408, RN-412).
final class LanSession {
  final HouseholdKey sessionKey;
  final String? remoteSiteId;
  final String? remoteDeviceName;

  const LanSession({
    required this.sessionKey,
    this.remoteSiteId,
    this.remoteDeviceName,
  });
}

/// Mutual authentication challenge-response for local network (RN-403, RN-404, RN-408, RN-412).
final class LanAuthHandshake {
  final HouseholdKey key;
  final Uint8List Function(int) randomBytes;

  LanAuthHandshake({required this.key, required this.randomBytes});

  /// Executa o handshake do lado do servidor (responde ao Hello, desafia e verifica a prova).
  Future<Result<LanSession, Failure>> runAsServer(
    FrameReader r,
    Sink<List<int>> w,
    SecurityLimits l, {
    String? localSiteId,
    String? localDeviceName,
  }) async {
    try {
      // 1. Receber Hello {v: 2, cn: 32B}
      final helloFrame = await _readPreAuthFrame(r, l);
      if (helloFrame.isErr) return Err(helloFrame.failureOrNull!);

      final helloMap = _parseJson(helloFrame.valueOrNull!);
      if (helloMap == null || helloMap['v'] != 2) {
        return const Err(LanAuthFailure(LanAuthFailureKind.oldProtocol));
      }
      final cnBase64 = helloMap['cn'] as String?;
      if (cnBase64 == null) {
        return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
      }
      final cn = base64Url.decode(cnBase64);
      if (cn.length != 32) {
        return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
      }

      // 2. Gerar sn (32B) e calcular Ka e sp
      final sn = randomBytes(32);
      final ka = await _deriveKa();
      final expectedSp = await _computeHmac(ka, [0x73, ...cn, ...sn]);

      // 3. Enviar Challenge {v: 2, sn: sn, sp: sp}
      final challengePayload = utf8.encode(
        jsonEncode({
          'v': 2,
          'sn': base64Url.encode(sn),
          'sp': base64Url.encode(expectedSp),
        }),
      );
      _writeFrame(w, challengePayload);

      // 4. Receber Proof {v: 2, cp: cp}
      final proofFrame = await _readPreAuthFrame(r, l);
      if (proofFrame.isErr) return Err(proofFrame.failureOrNull!);

      final proofMap = _parseJson(proofFrame.valueOrNull!);
      if (proofMap == null || proofMap['v'] != 2) {
        return const Err(LanAuthFailure(LanAuthFailureKind.oldProtocol));
      }
      final cpBase64 = proofMap['cp'] as String?;
      if (cpBase64 == null) {
        return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
      }
      final cp = base64Url.decode(cpBase64);
      final expectedCp = await _computeHmac(ka, [0x63, ...cn, ...sn]);

      if (!_constantTimeEqual(cp, expectedCp)) {
        return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
      }

      // 5. Derive session key Ks
      final sessionKey = await _deriveKs(cn, sn);

      // 6. Secure exchange of identifier and nickname post-proof (RN-412)
      final clientInfoFrame = await _readPreAuthFrame(r, l);
      if (clientInfoFrame.isErr) return Err(clientInfoFrame.failureOrNull!);

      final clientInfo = await _decryptWithKs(
        sessionKey,
        clientInfoFrame.valueOrNull!,
      );
      final remoteSiteId = clientInfo?['siteId'] as String?;
      final remoteDeviceName = clientInfo?['name'] as String?;

      final serverInfoPayload = await _encryptWithKs(sessionKey, {
        'siteId': localSiteId ?? '',
        'name': localDeviceName ?? '',
      });
      _writeFrame(w, serverInfoPayload);

      return Ok(
        LanSession(
          sessionKey: sessionKey,
          remoteSiteId: remoteSiteId?.isNotEmpty == true ? remoteSiteId : null,
          remoteDeviceName: remoteDeviceName?.isNotEmpty == true
              ? remoteDeviceName
              : null,
        ),
      );
    } on FrameTooLargeException {
      return const Err(LanAuthFailure(LanAuthFailureKind.tooLarge));
    } on TimeoutException {
      return const Err(LanAuthFailure(LanAuthFailureKind.timeout));
    } catch (_) {
      return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
    }
  }

  /// Executa o handshake do lado do cliente (inicia Hello, verifica Challenge e envia Proof).
  Future<Result<LanSession, Failure>> runAsClient(
    FrameReader r,
    Sink<List<int>> w,
    SecurityLimits l, {
    String? localSiteId,
    String? localDeviceName,
  }) async {
    try {
      // 1. Gerar cn (32B) e enviar Hello {v: 2, cn: cn}
      final cn = randomBytes(32);
      final helloPayload = utf8.encode(
        jsonEncode({'v': 2, 'cn': base64Url.encode(cn)}),
      );
      _writeFrame(w, helloPayload);

      // 2. Receber Challenge {v: 2, sn: sn, sp: sp}
      final challengeFrame = await _readPreAuthFrame(r, l);
      if (challengeFrame.isErr) return Err(challengeFrame.failureOrNull!);

      final challengeMap = _parseJson(challengeFrame.valueOrNull!);
      if (challengeMap == null || challengeMap['v'] != 2) {
        return const Err(LanAuthFailure(LanAuthFailureKind.oldProtocol));
      }
      final snBase64 = challengeMap['sn'] as String?;
      final spBase64 = challengeMap['sp'] as String?;
      if (snBase64 == null || spBase64 == null) {
        return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
      }
      final sn = base64Url.decode(snBase64);
      final sp = base64Url.decode(spBase64);
      if (sn.length != 32) {
        return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
      }

      final ka = await _deriveKa();
      final expectedSp = await _computeHmac(ka, [0x73, ...cn, ...sn]);
      if (!_constantTimeEqual(sp, expectedSp)) {
        return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
      }

      // 3. Calcular cp e enviar Proof {v: 2, cp: cp}
      final cp = await _computeHmac(ka, [0x63, ...cn, ...sn]);
      final proofPayload = utf8.encode(
        jsonEncode({'v': 2, 'cp': base64Url.encode(cp)}),
      );
      _writeFrame(w, proofPayload);

      // 4. Derive session key Ks
      final sessionKey = await _deriveKs(cn, sn);

      // 5. Secure exchange of identifier and nickname post-proof (RN-412)
      final clientInfoPayload = await _encryptWithKs(sessionKey, {
        'siteId': localSiteId ?? '',
        'name': localDeviceName ?? '',
      });
      _writeFrame(w, clientInfoPayload);

      final serverInfoFrame = await _readPreAuthFrame(r, l);
      if (serverInfoFrame.isErr) return Err(serverInfoFrame.failureOrNull!);

      final serverInfo = await _decryptWithKs(
        sessionKey,
        serverInfoFrame.valueOrNull!,
      );
      final remoteSiteId = serverInfo?['siteId'] as String?;
      final remoteDeviceName = serverInfo?['name'] as String?;

      return Ok(
        LanSession(
          sessionKey: sessionKey,
          remoteSiteId: remoteSiteId?.isNotEmpty == true ? remoteSiteId : null,
          remoteDeviceName: remoteDeviceName?.isNotEmpty == true
              ? remoteDeviceName
              : null,
        ),
      );
    } on FrameTooLargeException {
      return const Err(LanAuthFailure(LanAuthFailureKind.tooLarge));
    } on TimeoutException {
      return const Err(LanAuthFailure(LanAuthFailureKind.timeout));
    } catch (_) {
      return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
    }
  }

  Future<Result<Uint8List, Failure>> _readPreAuthFrame(
    FrameReader r,
    SecurityLimits l,
  ) async {
    final frame = await r.next(
      maxBytes: l.lanPreAuthMaxBytes,
      timeout: l.lanPreAuthTimeout,
    );
    if (frame == null) {
      return const Err(LanAuthFailure(LanAuthFailureKind.badProof));
    }
    return Ok(frame);
  }

  void _writeFrame(Sink<List<int>> w, List<int> payload) {
    final header = ByteData(4)..setUint32(0, payload.length);
    w.add(header.buffer.asUint8List());
    w.add(payload);
  }

  Map<String, dynamic>? _parseJson(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<SecretKey> _deriveKa() async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: SecretKey(key.bytes),
      info: utf8.encode('msh-lan-auth-v2'),
    );
  }

  Future<HouseholdKey> _deriveKs(List<int> cn, List<int> sn) async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final salt = [...cn, ...sn];
    final ksSecret = await hkdf.deriveKey(
      secretKey: SecretKey(key.bytes),
      nonce: salt,
      info: utf8.encode('msh-lan-session-v2'),
    );
    final bytes = await ksSecret.extractBytes();
    return HouseholdKey(bytes);
  }

  Future<List<int>> _computeHmac(SecretKey key, List<int> data) async {
    final mac = await Hmac.sha256().calculateMac(data, secretKey: key);
    return mac.bytes;
  }

  Future<Uint8List> _encryptWithKs(
    HouseholdKey ks,
    Map<String, dynamic> data,
  ) async {
    final nonce = randomBytes(12);
    final cleartext = utf8.encode(jsonEncode(data));
    final secretBox = await AesGcm.with256bits().encrypt(
      cleartext,
      secretKey: SecretKey(ks.bytes),
      nonce: nonce,
    );
    final bb = BytesBuilder(copy: false)
      ..add(nonce)
      ..add(secretBox.cipherText)
      ..add(secretBox.mac.bytes);
    return bb.toBytes();
  }

  Future<Map<String, dynamic>?> _decryptWithKs(
    HouseholdKey ks,
    List<int> bytes,
  ) async {
    if (bytes.length < 28) return null; // 12 nonce + 16 mac
    final nonce = bytes.sublist(0, 12);
    final mac = Mac(bytes.sublist(bytes.length - 16));
    final cipherText = bytes.sublist(12, bytes.length - 16);
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final cleartext = await AesGcm.with256bits().decrypt(
      secretBox,
      secretKey: SecretKey(ks.bytes),
    );
    final decoded = jsonDecode(utf8.decode(cleartext));
    if (decoded is Map<String, dynamic>) return decoded;
    return null;
  }

  bool _constantTimeEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
