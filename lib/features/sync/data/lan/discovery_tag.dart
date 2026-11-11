import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../domain/sync_batch.dart';

/// Gerador e validador de etiquetas rotativas de descoberta LAN (RN-411, CA-2.9).
///
/// Does not reveal household ID, device ID or nickname in plaintext.
/// Rotaciona a cada 24h: base64url(HMAC-SHA256(Kd, yyyy-mm-dd UTC))[0..22].
final class DiscoveryTag {
  final HouseholdKey key;

  DiscoveryTag(this.key);

  /// Returns tag for a specific date in UTC.
  Future<String> tagFor(DateTime utc) async {
    final kd = await _deriveKd();
    final dateStr = _formatDateUtc(utc);
    final mac = await Hmac.sha256().calculateMac(
      utf8.encode(dateStr),
      secretKey: kd,
    );
    final b64 = base64Url.encode(mac.bytes).replaceAll('=', '');
    return b64.substring(0, 22);
  }

  /// Conjunto de etiquetas aceitas para o momento atual (hoje e ontem em UTC para virada de dia).
  Future<Set<String>> acceptedAt(DateTime utc) async {
    final today = utc;
    final yesterday = utc.subtract(const Duration(days: 1));
    final tagToday = await tagFor(today);
    final tagYesterday = await tagFor(yesterday);
    return {tagToday, tagYesterday};
  }

  Future<SecretKey> _deriveKd() async {
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: SecretKey(key.bytes),
      info: utf8.encode('msh-discovery-v2'),
    );
  }

  static String _formatDateUtc(DateTime utc) {
    final d = utc.toUtc();
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
