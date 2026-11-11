import 'package:my_sweet_home/features/ocr/domain/column_detector.dart';
import 'package:my_sweet_home/features/ocr/domain/models/ocr_document.dart';

/// Alias to maintain compatibility with task/document names.
typedef DatetimeParser = DateTimeParser;

/// Pure parser responsible for identifying and extracting date and time from
/// textos de cupons fiscais e documentos de OCR ([OcrDocument] / [OcrRow]).
final class DateTimeParser {
  const DateTimeParser();

  /// Extracts issuance date/time from an [OcrDocument].
  DateTime? parseDocument(OcrDocument doc) {
    if (doc.lines.isEmpty) return null;
    return parseLines(doc.lines);
  }

  /// Extracts issuance date/time from a list of [OcrRow]s.
  DateTime? parseRows(List<OcrRow> rows) {
    if (rows.isEmpty) return null;
    final rowTexts = rows
        .map((r) => r.text)
        .where((t) => t.trim().isNotEmpty)
        .toList();
    if (rowTexts.isEmpty) return null;
    final ocrLines = rowTexts
        .map(
          (t) => OcrTextLine(
            text: t,
            boundingBox: const OcrBoundingBox(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
            ),
            confidence: 1.0,
          ),
        )
        .toList();
    return parseLines(ocrLines);
  }

  /// Extracts issuance date/time from a list of [OcrTextLine]s.
  DateTime? parseLines(List<OcrTextLine> lines) {
    if (lines.isEmpty) return null;

    final candidates = <_DateCandidate>[];

    for (var i = 0; i < lines.length; i++) {
      final lineText = lines[i].text;
      if (_isNegatedLine(lineText)) continue;

      final parsed = _parseLineCandidate(lineText);
      if (parsed != null) {
        final score = _scoreLine(lineText);
        candidates.add(
          _DateCandidate(
            year: parsed.year,
            month: parsed.month,
            day: parsed.day,
            hour: parsed.hour,
            minute: parsed.minute,
            second: parsed.second,
            hasTime: parsed.hasTime,
            score: score,
            lineIndex: i,
          ),
        );
      }
    }

    if (candidates.isEmpty) {
      // Fallback: tentar no texto corrido de todas as linhas
      final fullText = lines.map((l) => l.text).join(' ');
      return parseText(fullText);
    }

    // Sort candidates by score (highest first) and time presence
    candidates.sort((a, b) {
      if (a.score != b.score) return b.score.compareTo(a.score);
      if (a.hasTime != b.hasTime) return a.hasTime ? -1 : 1;
      return a.lineIndex.compareTo(b.lineIndex);
    });

    final best = candidates.first;
    var hour = best.hour;
    var minute = best.minute;
    var second = best.second;

    // If best candidate lacks time, search time in nearby lines or with HORA
    if (!best.hasTime) {
      final foundTime = _searchTimeInLines(lines, best.lineIndex);
      if (foundTime != null) {
        hour = foundTime.hour;
        minute = foundTime.minute;
        second = foundTime.second;
      }
    }

    return DateTime.utc(best.year, best.month, best.day, hour, minute, second);
  }

  /// Extrai a data/hora a partir de uma string de texto.
  DateTime? parseText(String text) {
    if (text.trim().isEmpty) return null;

    final cleanedText = _cleanOcrNoise(text);
    final lines = cleanedText.split('\n');

    if (lines.length > 1) {
      final ocrLines = lines
          .map(
            (t) => OcrTextLine(
              text: t,
              boundingBox: const OcrBoundingBox(
                top: 0,
                left: 0,
                right: 0,
                bottom: 0,
              ),
              confidence: 1.0,
            ),
          )
          .toList();
      return parseLines(ocrLines);
    }

    if (_isNegatedLine(cleanedText)) return null;

    final parsed = _parseLineCandidate(cleanedText);
    if (parsed == null) return null;

    return DateTime.utc(
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
    );
  }

  static String _cleanOcrNoise(String text) {
    if (text.isEmpty) return text;
    var result = text;
    // Replaces 'O'/'o' with '0' in numeric date/time context (e.g. 21/O9/2O26 -> 21/09/2026)
    result = result.replaceAllMapped(
      RegExp(
        r'(?<=\d|[\/\.\-\:\s])[Oo](?=\d|[\/\.\-\:\s]|$)|(?<=\b)[Oo](?=\d)',
      ),
      (_) => '0',
    );
    // Replaces 'I'/'i'/'l'/'|'/'!' with '1' in numeric date/time context (e.g. 2I/09/2026 -> 21/09/2026)
    result = result.replaceAllMapped(
      RegExp(
        r'(?<=\d|[\/\.\-\:\s])[Ii|l!](?=\d|[\/\.\-\:\s]|$)|(?<=\b)[Ii|l!](?=\d)',
      ),
      (_) => '1',
    );
    return result;
  }

  static bool _isNegatedLine(String text) {
    final upper = text.toUpperCase();

    // If line has explicit issuance/purchase indicator, not denied
    if (upper.contains('EMISSAO') ||
        upper.contains('EMISSÃO') ||
        upper.contains('EMITIDO') ||
        upper.contains('DATA DA COMPRA') ||
        upper.contains('DT EMISSAO') ||
        upper.contains('DATA EMISSAO')) {
      return false;
    }

    return upper.contains('VAL:') ||
        upper.contains('VALIDADE') ||
        upper.contains('VENC') ||
        upper.contains('FABRICACAO') ||
        upper.contains('FAB:');
  }

  static int _scoreLine(String text) {
    final upper = text.toUpperCase();

    // Penalizar linhas de CNPJ, CPF, Chave de Acesso, IE, Telefone
    if (upper.contains('CNPJ') ||
        upper.contains('C.N.P.J') ||
        upper.contains('CPF') ||
        upper.contains('C.P.F') ||
        upper.contains('CHAVE') ||
        upper.contains('TELEFONE') ||
        upper.contains('TEL:') ||
        upper.contains('INSCRICAO') ||
        upper.contains('I.E.') ||
        (upper.contains('PROTOCOLO') && !upper.contains('DATA')) ||
        (upper.contains('AUTORIZACAO') &&
            !upper.contains('DATA') &&
            !upper.contains('NFC-E'))) {
      return -500;
    }

    var score = 10;
    if (upper.contains('EMISSAO') ||
        upper.contains('EMISSÃO') ||
        upper.contains('EMITIDO')) {
      score += 100;
    }
    if (upper.contains('DATA DA COMPRA') ||
        upper.contains('DATA/HORA') ||
        upper.contains('DT EMISSAO') ||
        upper.contains('DT. EMISSAO') ||
        upper.contains('DATA EMISSAO') ||
        upper.contains('DATA DE AUTORIZACAO') ||
        upper.contains('DATA DE AUTORIZAÇÃO') ||
        upper.contains('DATA DE AUTORLZACAO')) {
      score += 80;
    } else if (upper.contains('NFC-E') ||
        upper.contains('SERIE') ||
        upper.contains('SÉRIE')) {
      score += 65;
    } else if (upper.contains('DATA') ||
        upper.contains('DT.') ||
        upper.contains('DT ')) {
      score += 50;
    }

    // Bonus for explicit 4-digit year (20xx/19xx), much more reliable than 2 digits in OCR
    if (RegExp(r'\b(20\d{2}|19\d{2})\b').hasMatch(upper)) {
      score += 25;
    }
    return score;
  }

  static _ParsedDateTimeResult? _parseLineCandidate(String text) {
    var cleaned = _cleanOcrNoise(text);

    // Remove CNPJ and CPF patterns from string to avoid false positives
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{2}[\.\s]?\d{3}[\.\s]?\d{3}[\/\s]?\d{4}[\-\s]?\d{2}\b'),
      ' ',
    );
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d{3}[\.\s]?\d{3}[\.\s]?\d{3}[\-\s]?\d{2}\b'),
      ' ',
    );

    // 1. Tentar ISO yyyy-MM-dd
    final isoMatch = RegExp(
      r'\b(20\d{2}|19\d{2})[\/\.\-]\s*([0-1]?\d)[\/\.\-]\s*([0-3]?\d)(?:[T\s]+([0-2]?\d)[\:\.]\s*([0-5]?\d)(?:[\:\.]\s*([0-5]?\d))?)?\b',
    ).firstMatch(cleaned);

    if (isoMatch != null) {
      final y = int.parse(isoMatch.group(1)!);
      final m = int.parse(isoMatch.group(2)!);
      final d = int.parse(isoMatch.group(3)!);

      if (_isValidDate(y, m, d)) {
        final h = isoMatch.group(4) != null ? int.parse(isoMatch.group(4)!) : 0;
        final min = isoMatch.group(5) != null
            ? int.parse(isoMatch.group(5)!)
            : 0;
        final s = isoMatch.group(6) != null ? int.parse(isoMatch.group(6)!) : 0;

        if (_isValidTime(h, min, s)) {
          return _ParsedDateTimeResult(
            year: y,
            month: m,
            day: d,
            hour: h,
            minute: min,
            second: s,
            hasTime: isoMatch.group(4) != null,
          );
        }
      }
    }

    // 2. Tentar dd/MM/yyyy ou dd/MM/yy
    final brMatch = RegExp(
      r'\b([0-3]?\d)\s*[\/\.\-]\s*([0-1]?\d)\s*[\/\.\-]\s*(20\d{2}|19\d{2}|\d{2})\b',
    ).firstMatch(cleaned);

    if (brMatch != null) {
      final d = int.parse(brMatch.group(1)!);
      final m = int.parse(brMatch.group(2)!);
      final rawY = int.parse(brMatch.group(3)!);
      final y = rawY < 100 ? (rawY < 50 ? 2000 + rawY : 1900 + rawY) : rawY;

      if (_isValidDate(y, m, d)) {
        final timeResult = _extractTimeFromText(
          cleaned,
          excludeMatchRange: brMatch,
        );

        return _ParsedDateTimeResult(
          year: y,
          month: m,
          day: d,
          hour: timeResult?.hour ?? 0,
          minute: timeResult?.minute ?? 0,
          second: timeResult?.second ?? 0,
          hasTime: timeResult != null,
        );
      }
    }

    // 3. Tentar dd/MES/yyyy ou dd MES yyyy (ex: 21/SET/2026, 21 DE SETEMBRO DE 2026)
    final textMonthMatch = RegExp(
      r'\b([0-3]?\d)\s*(?:de|\/|\.|\-|\s)\s*(JAN(?:EIRO)?|FEV(?:EREIRO)?|MAR(?:ÇO|CO)?|ABR(?:IL)?|MAI(?:O)?|JUN(?:HO)?|JUL(?:HO)?|AGO(?:STO)?|SET(?:EMBRO)?|OUT(?:UBRO)?|NOV(?:EMBRO)?|DEZ(?:EMBRO)?)\s*(?:de|\/|\.|\-|\s)\s*(20\d{2}|19\d{2}|\d{2})\b',
      caseSensitive: false,
    ).firstMatch(cleaned);

    if (textMonthMatch != null) {
      final d = int.parse(textMonthMatch.group(1)!);
      final monthStr = textMonthMatch.group(2)!.toUpperCase();
      final m = _parseMonthText(monthStr);
      final rawY = int.parse(textMonthMatch.group(3)!);
      final y = rawY < 100 ? (rawY < 50 ? 2000 + rawY : 1900 + rawY) : rawY;

      if (m != null && _isValidDate(y, m, d)) {
        final timeResult = _extractTimeFromText(
          cleaned,
          excludeMatchRange: textMonthMatch,
        );

        return _ParsedDateTimeResult(
          year: y,
          month: m,
          day: d,
          hour: timeResult?.hour ?? 0,
          minute: timeResult?.minute ?? 0,
          second: timeResult?.second ?? 0,
          hasTime: timeResult != null,
        );
      }
    }

    return null;
  }

  static int? _parseMonthText(String monthStr) {
    final m = monthStr.toUpperCase();
    if (m.startsWith('JAN')) return 1;
    if (m.startsWith('FEV')) return 2;
    if (m.startsWith('MAR')) return 3;
    if (m.startsWith('ABR')) return 4;
    if (m.startsWith('MAI')) return 5;
    if (m.startsWith('JUN')) return 6;
    if (m.startsWith('JUL')) return 7;
    if (m.startsWith('AGO')) return 8;
    if (m.startsWith('SET')) return 9;
    if (m.startsWith('OUT')) return 10;
    if (m.startsWith('NOV')) return 11;
    if (m.startsWith('DEZ')) return 12;
    return null;
  }

  static _ParsedTime? _extractTimeFromText(
    String text, {
    Match? excludeMatchRange,
  }) {
    var textToSearch = text;
    if (excludeMatchRange != null) {
      textToSearch =
          '${text.substring(0, excludeMatchRange.start)} ${text.substring(excludeMatchRange.end)}';
    }

    // Formato 14h30m15s / 14h30 / 14h30min
    final hmsMatch = RegExp(
      r'\b([0-2]?\d)\s*h\s*([0-5]?\d)?(?:\s*m(?:in)?s?\s*([0-5]?\d)?\s*s?)?\b',
      caseSensitive: false,
    ).firstMatch(textToSearch);

    if (hmsMatch != null) {
      final h = int.parse(hmsMatch.group(1)!);
      final m = hmsMatch.group(2) != null ? int.parse(hmsMatch.group(2)!) : 0;
      final s = hmsMatch.group(3) != null ? int.parse(hmsMatch.group(3)!) : 0;
      if (_isValidTime(h, m, s)) {
        return _ParsedTime(h, m, s);
      }
    }

    // Format HH:mm:ss or HH:mm or HH.mm.ss (with possible suffixes hs/hrs/h/min)
    final colonMatch = RegExp(
      r'\b([0-2]?\d)\s*[\:\.]\s*([0-5]\d)(?:\s*[\:\.]\s*([0-5]\d))?(?:\s*(?:hs?|hrs?|h|min))?\b',
      caseSensitive: false,
    ).firstMatch(textToSearch);

    if (colonMatch != null) {
      final h = int.parse(colonMatch.group(1)!);
      final m = int.parse(colonMatch.group(2)!);
      final s = colonMatch.group(3) != null
          ? int.parse(colonMatch.group(3)!)
          : 0;
      if (_isValidTime(h, m, s)) {
        return _ParsedTime(h, m, s);
      }
    }

    return null;
  }

  static _ParsedTime? _searchTimeInLines(
    List<OcrTextLine> lines,
    int dateLineIndex,
  ) {
    // Verificar linha atual e vizinhas (±2)
    for (var offset in [0, 1, -1, 2, -2]) {
      final idx = dateLineIndex + offset;
      if (idx >= 0 && idx < lines.length) {
        final time = _extractTimeFromText(lines[idx].text);
        if (time != null) return time;
      }
    }

    // Search in lines containing word HORA
    for (final line in lines) {
      if (line.text.toUpperCase().contains('HORA')) {
        final time = _extractTimeFromText(line.text);
        if (time != null) return time;
      }
    }

    return null;
  }

  static bool _isValidDate(int year, int month, int day) {
    if (month < 1 || month > 12) return false;
    if (day < 1 || day > 31) return false;
    if (year < 1980 || year > 2099) return false;
    final dt = DateTime.utc(year, month, day);
    return dt.year == year && dt.month == month && dt.day == day;
  }

  static bool _isValidTime(int hour, int minute, int second) {
    return hour >= 0 &&
        hour <= 23 &&
        minute >= 0 &&
        minute <= 59 &&
        second >= 0 &&
        second <= 59;
  }
}

class _DateCandidate {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final bool hasTime;
  final int score;
  final int lineIndex;

  const _DateCandidate({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    required this.hasTime,
    required this.score,
    required this.lineIndex,
  });
}

class _ParsedDateTimeResult {
  final int year;
  final int month;
  final int day;
  final int hour;
  final int minute;
  final int second;
  final bool hasTime;

  const _ParsedDateTimeResult({
    required this.year,
    required this.month,
    required this.day,
    required this.hour,
    required this.minute,
    required this.second,
    required this.hasTime,
  });
}

class _ParsedTime {
  final int hour;
  final int minute;
  final int second;

  const _ParsedTime(this.hour, this.minute, [this.second = 0]);
}
