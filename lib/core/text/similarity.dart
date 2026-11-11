/// String similarity measurement (SPEC-001).
///
/// Pure Dart implementation — no external dependencies.
/// Combines Jaro-Winkler with token-set ratio for robust matching.
library;

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

/// Returns a similarity score between [a] and [b] in the range [0.0, 1.0].
///
/// Strategy:
/// - Special case: both empty → 1.0; only one empty → 0.0
/// - Combines character-level Jaro-Winkler with token-level token-set ratio,
///   taking the **maximum** of both scores.
///
/// Examples:
/// ```dart
/// similarity('leite', 'leite')              // → 1.0
/// similarity('leite', 'cafe')               // → < 0.3
/// similarity('leite integral', 'leite int') // → >= 0.8
/// ```
double similarity(String a, String b) {
  final aT = a.trim();
  final bT = b.trim();

  if (aT.isEmpty && bT.isEmpty) return 1.0;
  if (aT.isEmpty || bT.isEmpty) return 0.0;

  final jw = jaroWinkler(aT, bT);
  final rawTokA = _rawTokens(aT);
  final rawTokB = _rawTokens(bT);
  if (rawTokA.length == 1 && rawTokB.length == 1) {
    if (!_isPlausibleSameToken(rawTokA.first, rawTokB.first)) {
      return jw > 0.80 ? 0.80 : jw;
    }
    return jw;
  }

  final ts = _tokenSetRatioFromTokens(rawTokA, rawTokB);
  if (ts == 0.0) {
    // Incompatible multi-token phrases (e.g. "creme leite" vs "creme dental"):
    // limit Jaro-Winkler to avoid false positive matches.
    return jw * 0.65;
  }
  return jw > ts ? jw : ts;
}

// ---------------------------------------------------------------------------
// Jaro-Winkler
// ---------------------------------------------------------------------------

/// Computes the Jaro-Winkler score between [s1] and [s2].
double jaroWinkler(String s1, String s2) {
  if (s1 == s2) return 1.0;

  final jaro = _jaro(s1, s2);

  // Common prefix (up to 4 characters)
  var prefixLen = 0;
  final maxPrefix = s1.length < s2.length ? s1.length : s2.length;
  final limit = maxPrefix < 4 ? maxPrefix : 4;
  for (var i = 0; i < limit; i++) {
    if (s1[i] == s2[i]) {
      prefixLen++;
    } else {
      break;
    }
  }

  return jaro + prefixLen * 0.1 * (1.0 - jaro);
}

double _jaro(String s1, String s2) {
  final len1 = s1.length;
  final len2 = s2.length;

  if (len1 == 0 && len2 == 0) return 1.0;
  if (len1 == 0 || len2 == 0) return 0.0;

  final matchRange = ((len1 > len2 ? len1 : len2) / 2).floor() - 1;
  final range = matchRange < 0 ? 0 : matchRange;

  final s1Matches = List<bool>.filled(len1, false);
  final s2Matches = List<bool>.filled(len2, false);

  var matches = 0;
  var transpositions = 0;

  // Find matches
  for (var i = 0; i < len1; i++) {
    final start = (i - range) < 0 ? 0 : i - range;
    final end = (i + range + 1) > len2 ? len2 : i + range + 1;
    for (var j = start; j < end; j++) {
      if (s2Matches[j] || s1[i] != s2[j]) continue;
      s1Matches[i] = true;
      s2Matches[j] = true;
      matches++;
      break;
    }
  }

  if (matches == 0) return 0.0;

  // Count transpositions
  var k = 0;
  for (var i = 0; i < len1; i++) {
    if (!s1Matches[i]) continue;
    while (!s2Matches[k]) {
      k++;
    }
    if (s1[i] != s2[k]) transpositions++;
    k++;
  }

  final m = matches.toDouble();
  return (m / len1 + m / len2 + (m - transpositions / 2) / m) / 3.0;
}

// ---------------------------------------------------------------------------
// Token-set ratio
// ---------------------------------------------------------------------------

/// Tokenizes and evaluates head noun alignment and modifier coverage.
double _tokenSetRatioFromTokens(List<String> rawTokA, List<String> rawTokB) {
  if (rawTokA.isEmpty && rawTokB.isEmpty) return 1.0;
  if (rawTokA.isEmpty || rawTokB.isEmpty) return 0.0;

  // Exact token anagram
  if (rawTokA.length == rawTokB.length) {
    final tokA = List<String>.from(rawTokA)..sort();
    final tokB = List<String>.from(rawTokB)..sort();
    if (_join(tokA) == _join(tokB)) {
      return 1.0;
    }
  }

  final shorter = rawTokA.length <= rawTokB.length ? rawTokA : rawTokB;
  final longer = rawTokA.length <= rawTokB.length ? rawTokB : rawTokA;

  final headSim = _headTokenSimilarity(shorter.first, longer.first);
  if (headSim < 0.85) {
    return 0.0;
  }

  // Single-token in shorter vs multiple in longer
  if (shorter.length == 1) {
    if (shorter.first.length < 3 || headSim < 0.88) {
      return 0.0;
    }
    if (longer.length >= 2 && _compoundDisqualifiers.contains(longer[1])) {
      return 0.70 * headSim;
    }
    return 0.86 * headSim;
  }

  // 2+ tokens in shorter: all shorter tokens must be covered in longer
  var sumSim = 0.0;
  final usedIndices = <int>{};
  for (var i = 0; i < shorter.length; i++) {
    final ts = shorter[i];
    var bestTokenSim = 0.0;
    var bestIdx = -1;
    for (var j = 0; j < longer.length; j++) {
      if (usedIndices.contains(j)) continue;
      final sim = i == 0 && j == 0
          ? _headTokenSimilarity(ts, longer[j])
          : _tokenSimilarity(ts, longer[j]);
      if (sim > bestTokenSim) {
        bestTokenSim = sim;
        bestIdx = j;
      }
    }
    if (bestTokenSim < 0.75) {
      return 0.0;
    }
    if (bestIdx >= 0) {
      usedIndices.add(bestIdx);
    }
    sumSim += bestTokenSim;
  }

  final avgSim = sumSim / shorter.length;
  return (0.90 + 0.10 * avgSim).clamp(0.0, 1.0);
}

double _headTokenSimilarity(String t1, String t2) {
  if (t1 == t2) return 1.0;
  if (t1.length < 3 || t2.length < 3) {
    final shortTok = t1.length <= t2.length ? t1 : t2;
    final longTok = t1.length <= t2.length ? t2 : t1;
    if (shortTok.length == 2 && longTok.startsWith(shortTok)) {
      return 0.85;
    }
    return 0.0;
  }
  if (!_isPlausibleSameToken(t1, t2)) return 0.0;
  return jaroWinkler(t1, t2);
}

double _tokenSimilarity(String t1, String t2) {
  if (t1 == t2) return 1.0;
  // 1-2 character abbreviations in modifiers
  if (t1.length <= 2 || t2.length <= 2) {
    final shortTok = t1.length <= t2.length ? t1 : t2;
    final longTok = t1.length <= t2.length ? t2 : t1;
    if (_compoundDisqualifiers.contains(longTok)) {
      return 0.0;
    }
    if (shortTok.length == 2 && longTok.startsWith(shortTok)) {
      return 0.85;
    }
    if (shortTok.isNotEmpty && longTok.startsWith(shortTok[0])) {
      return 0.80;
    }
    return 0.0;
  }
  if (!_isPlausibleSameToken(t1, t2)) return 0.0;
  return jaroWinkler(t1, t2);
}

/// Checks whether two tokens of 3+ characters can represent the same word
/// (prefix abbreviation in receipts, inflections, or up to 1-2 OCR errors),
/// preventing distinct phonetic collisions like "sobrecoxa" vs "sobremesa".
bool _isPlausibleSameToken(String t1, String t2) {
  if (t1 == t2) return true;
  final shortTok = t1.length <= t2.length ? t1 : t2;
  final longTok = t1.length <= t2.length ? t2 : t1;

  // Prefix abbreviation in receipt items (e.g. "energ" -> "energetico", "int" -> "integral")
  if (shortTok.length >= 3 && longTok.startsWith(shortTok)) {
    return true;
  }

  // 5+ letter prefix abbreviation with up to 1 OCR error (e.g. "niner" -> "mineral")
  if (shortTok.length >= 5 &&
      longTok.length > shortTok.length &&
      _editDistance(shortTok, longTok.substring(0, shortTok.length)) <= 1) {
    return true;
  }

  // Without being prefix, length difference cannot exceed 2 characters
  if (longTok.length - shortTok.length > 2) {
    return false;
  }

  final dist = _editDistance(t1, t2);
  final maxLen = longTok.length;
  if (maxLen <= 3) {
    return dist <= 1 &&
        shortTok.length >= 2 &&
        t1[0] == t2[0] &&
        t1[1] == t2[1];
  }
  if (maxLen <= 7) {
    return dist <= 1;
  }
  return dist <= 2;
}

int _editDistance(String s1, String s2) {
  final m = s1.length;
  final n = s2.length;
  var prev = List<int>.generate(n + 1, (j) => j);
  var curr = List<int>.filled(n + 1, 0);
  for (var i = 1; i <= m; i++) {
    curr[0] = i;
    for (var j = 1; j <= n; j++) {
      final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
      final del = prev[j] + 1;
      final ins = curr[j - 1] + 1;
      final sub = prev[j - 1] + cost;
      var minVal = del < ins ? del : ins;
      if (sub < minVal) minVal = sub;
      curr[j] = minVal;
    }
    final tmp = prev;
    prev = curr;
    curr = tmp;
  }
  return prev[n];
}

List<String> _rawTokens(String s) =>
    s.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

String _join(List<String> tokens) => tokens.join(' ');

const _compoundDisqualifiers = <String>{
  'palha',
  'doce',
  'frita',
  'queijo',
  'alho',
  'condensado',
  'coco',
  'sanitaria',
  'oxigenada',
};
