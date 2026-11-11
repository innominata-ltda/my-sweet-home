/// Normalization of product names for search and matching (SPEC-001).
///
/// All functions are pure and stateless — without external dependencies.
library;

// ---------------------------------------------------------------------------
// pt-BR stopwords + units of measure / packaging
// ---------------------------------------------------------------------------

const _stopwords = <String>{
  'de',
  'da',
  'do',
  'das',
  'dos',
  'e',
  'em',
  'com',
  'para',
  'por',
  'um',
  'uma',
  'kg',
  'g',
  'ml',
  'l',
  'lt',
  'un',
  'und',
  'pct',
  'cx',
  'caixa',
  'pacote',
  'unid',
};

/// Pattern: quantity / packaging unit at the end (e.g. 1L, 500G, 1.5L, 12X1L).
/// Also matches at the start (e.g. 12X1L AGUA).
final _unitPattern = RegExp(
  r'(?:^|\s)\d+(?:[.,]\d+)?(?:x\d+(?:[.,]\d+)?)?(?:kg|g|ml|l|lt|un|und|pct)\b',
  caseSensitive: false,
);

// ---------------------------------------------------------------------------
// Accent transliteration map -> ASCII
// ---------------------------------------------------------------------------

const _accentMap = <String, String>{
  '\u00e0': 'a',
  '\u00e1': 'a',
  '\u00e2': 'a',
  '\u00e3': 'a',
  '\u00e4': 'a',
  '\u00e5': 'a',
  '\u00e8': 'e',
  '\u00e9': 'e',
  '\u00ea': 'e',
  '\u00eb': 'e',
  '\u00ec': 'i',
  '\u00ed': 'i',
  '\u00ee': 'i',
  '\u00ef': 'i',
  '\u00f2': 'o',
  '\u00f3': 'o',
  '\u00f4': 'o',
  '\u00f5': 'o',
  '\u00f6': 'o',
  '\u00f9': 'u',
  '\u00fa': 'u',
  '\u00fb': 'u',
  '\u00fc': 'u',
  '\u00fd': 'y',
  '\u00ff': 'y',
  '\u00e7': 'c',
  '\u00f1': 'n',
};

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Normalizes raw product name for comparison and search.
///
/// Steps (in order):
/// 1. Lowercase
/// 2. Accent transliteration
/// 3. Remove quantity/unit patterns (e.g., `1L`, `500G`, `12X1L`)
/// 4. Remove punctuation and non-alphanumeric characters
/// 5. Remove pt-BR stopwords
/// 6. Collapse whitespace and trim
///
/// Examples:
/// ```dart
/// normalizeProductName('LEITE INTEGRAL 1L') // → 'leite integral'
/// normalizeProductName('PAO DE SAL')        // → 'pao sal'
/// ```
String normalizeProductName(String raw) {
  if (raw.trim().isEmpty) return '';

  // 1. Lowercase
  var s = raw.toLowerCase();

  // 2. Transliterate accents (char by char via runes — safe for ASCII)
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    final ch = s[i];
    buf.write(_accentMap[ch] ?? ch);
  }
  s = buf.toString();

  // 3. Remove unit/quantity patterns
  s = s.replaceAll(_unitPattern, ' ');

  // 4. Remove punctuation and special characters (keep letters, digits, spaces, dots)
  s = s.replaceAll(RegExp(r'[^\w\s.]'), ' ');

  // 5. Tokenize, clean OCR digits in alphabetic words, filter stopwords and rebuild
  final tokens = s
      .split(RegExp(r'\s+'))
      .map(_cleanOcrWordDigits)
      .where((t) => t.isNotEmpty && !_stopwords.contains(t))
      .toList();

  return tokens.join(' ');
}

String _cleanOcrWordDigits(String token) {
  if (token == 'a0' || token == 'd0' || token == 'n0') {
    return '${token[0]}o';
  }
  if (RegExp(r'^[a-z]+[08][a-z]+$').hasMatch(token)) {
    return token.replaceAll('0', 'o').replaceAll('8', 'b');
  }
  return token;
}
