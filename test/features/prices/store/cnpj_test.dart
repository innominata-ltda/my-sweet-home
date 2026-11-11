import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/store/cnpj.dart';

void main() {
  group('Cnpj', () {
    test('accepts valid CNPJ with punctuation', () {
      final res = Cnpj.create('11.222.333/0001-81');
      expect(res.isOk, isTrue);
      expect(res.valueOrNull!.value, '11222333000181');
    });

    test('rejects CNPJ with fewer than 14 digits', () {
      final res = Cnpj.create('11.222.333/0001-8');
      expect(res.isErr, isTrue);
      final failure = res.failureOrNull as ValidationFailure;
      expect(failure.fields.containsKey('cnpj'), isTrue);
    });

    test('rejects CNPJ with all identical digits', () {
      final res = Cnpj.create('11.111.111/1111-11');
      expect(res.isErr, isTrue);
    });

    test('rejects CNPJ with invalid first check digit', () {
      // 11.222.333/0001-81 is valid. 80 would be invalid.
      final res = Cnpj.create('11.222.333/0001-80');
      expect(res.isErr, isTrue);
    });

    test('rejects CNPJ with invalid second check digit', () {
      // 11.222.333/0001-81 is valid. 82 would be invalid.
      final res = Cnpj.create('11.222.333/0001-82');
      expect(res.isErr, isTrue);
    });
  });
}
