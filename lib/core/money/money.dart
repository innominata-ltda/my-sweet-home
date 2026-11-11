/// Representation of monetary amounts in integer cents.
///
/// All monetary operations in the application MUST use [Money]. The use of [double]
/// for money is forbidden outside of [Money.fromDouble] (RN-001, RN-002).
///
/// Implemented as an `extension type` over `int` for zero allocation cost
/// in large lists (implicit ADR in plan.md of SPEC-001).
library;

extension type const Money(int cents) implements Object {
  // ---------------------------------------------------------------------------
  // Arithmetic — closed under Money (RN-001)
  // ---------------------------------------------------------------------------

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);
  bool operator <(Money other) => cents < other.cents;
  bool operator <=(Money other) => cents <= other.cents;
  bool operator >(Money other) => cents > other.cents;
  bool operator >=(Money other) => cents >= other.cents;

  /// Multiplication by an integer factor.
  Money times(int factor) => Money(cents * factor);

  /// Multiplies and rounds to the nearest cent.
  /// Usage: unit price × quantity in thousandths.
  Money timesRatio(int numerator, int denominator) {
    assert(denominator != 0, 'denominator must not be zero');
    return Money(((cents * numerator) / denominator).round());
  }

  /// Divides [this] into [parts] integer installments, distributing the remainder.
  ///
  /// Example: Money(100).split(3) → [34, 33, 33]  (sum = 100)
  /// Never loses cents: first installment(s) receive the remainder.
  List<Money> split(int parts) {
    assert(parts > 0, 'parts must be positive');
    final base = cents ~/ parts;
    final remainder = cents % parts;
    return List<Money>.generate(
      parts,
      (i) => i < remainder ? Money(base + 1) : Money(base),
    );
  }

  // ---------------------------------------------------------------------------
  // Constant values
  // ---------------------------------------------------------------------------

  static const Money zero = Money(0);

  // ---------------------------------------------------------------------------
  // Parsing pt-BR (RN-002, CA-1.3)
  // ---------------------------------------------------------------------------

  /// Attempts to parse a pt-BR formatted string to [Money].
  ///
  /// Accepted formats:
  ///   - `"12"` → Money(1200)
  ///   - `"12,3"` → Money(1230)
  ///   - `"12,30"` → Money(1230)
  ///   - `"1.234,56"` → Money(123456)
  ///   - `"R$ 1.234,56"` → Money(123456)
  ///   - `"-12,50"` → Money(-1250)
  ///
  /// Returns `null` if the format is not recognized.
  static Money? tryParsePtBr(String raw) {
    // Strip whitespace, currency symbol, and thousands separators
    var s = raw
        .trim()
        .replaceAll(RegExp(r'R\$\s*'), '')
        .replaceAll('.', '')
        .trim();

    // Negative sign
    final negative = s.startsWith('-');
    if (negative) s = s.substring(1);

    // Validate: allowed digits with at most one comma
    if (!RegExp(r'^\d+(?:,\d{1,2})?$').hasMatch(s)) return null;

    int cents;
    if (s.contains(',')) {
      final parts = s.split(',');
      final intPart = int.parse(parts[0]);
      final decStr = parts[1].padRight(2, '0'); // "3" → "30"
      final decPart = int.parse(decStr);
      cents = intPart * 100 + decPart;
    } else {
      cents = int.parse(s) * 100;
    }

    return Money(negative ? -cents : cents);
  }

  /// Converts from a [double] — **only for user input and OCR**.
  ///
  /// Prefer `tryParsePtBr` whenever possible. This constructor exists for the
  /// rare cases where input is supplied directly as double (e.g., OCR reader
  /// return value without raw string). Rounds to the nearest cent.
  // ignore: prefer_constructors_over_static_methods
  static Money fromDouble(double value) => Money((value * 100).round());

  // ---------------------------------------------------------------------------
  // Formatting pt-BR (CA-1.1)
  // ---------------------------------------------------------------------------

  /// Formats as `R$ 1.234,56`.
  ///
  /// Negative values → `R$ -1.234,56`.
  String formatPtBr() {
    final abs = cents.abs();
    final reais = abs ~/ 100;
    final centavos = abs % 100;

    // Manual thousands separator (no external intl dependency in pure core)
    final reaisStr = _formatThousands(reais);
    final centStr = centavos.toString().padLeft(2, '0');

    final sign = cents < 0 ? '-' : '';
    return 'R\$ $sign$reaisStr,$centStr';
  }

  static String _formatThousands(int n) {
    final s = n.toString();
    if (s.length <= 3) return s;
    final buf = StringBuffer();
    final offset = s.length % 3;
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (i - offset) % 3 == 0) buf.write('.');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  // Note: extension type cannot override Object.toString().
  // Call formatPtBr() explicitly or Money.toString will not be available.
}
