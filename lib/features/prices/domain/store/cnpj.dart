import 'package:my_sweet_home/core/result/result.dart';

/// CNPJ validado.
class Cnpj {
  Cnpj._(this.value);

  /// Creates a CNPJ validating check digits.
  /// Returns [ValidationFailure] if invalid.
  static Result<Cnpj, ValidationFailure> create(String rawValue) {
    final clean = rawValue.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.length != 14) {
      return const Err(
        ValidationFailure(fields: {'cnpj': 'O CNPJ deve ter 14 dígitos.'}),
      );
    }

    if (RegExp(r'^(\d)\1*$').hasMatch(clean)) {
      return const Err(
        ValidationFailure(
          fields: {'cnpj': 'CNPJ não pode ter todos os dígitos iguais.'},
        ),
      );
    }

    final digits = clean.split('').map(int.parse).toList();

    // Validation of first digit
    int sum1 = 0;
    const weights1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    for (int i = 0; i < 12; i++) {
      sum1 += digits[i] * weights1[i];
    }
    final rem1 = sum1 % 11;
    final digit1 = rem1 < 2 ? 0 : 11 - rem1;
    if (digits[12] != digit1) {
      return const Err(ValidationFailure(fields: {'cnpj': 'CNPJ inválido.'}));
    }

    // Validation of second digit
    int sum2 = 0;
    const weights2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    for (int i = 0; i < 13; i++) {
      sum2 += digits[i] * weights2[i];
    }
    final rem2 = sum2 % 11;
    final digit2 = rem2 < 2 ? 0 : 11 - rem2;
    if (digits[13] != digit2) {
      return const Err(ValidationFailure(fields: {'cnpj': 'CNPJ inválido.'}));
    }

    return Ok(Cnpj._(clean));
  }

  /// Clean CNPJ value (14 digits, no punctuation).
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Cnpj && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
