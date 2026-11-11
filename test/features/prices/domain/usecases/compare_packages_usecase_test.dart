import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/domain/usecases/compare_packages_usecase.dart';

void main() {
  late ComparePackagesUseCase useCase;

  setUp(() {
    useCase = const ComparePackagesUseCase();
  });

  test('deve comparar leite 1L e 200ml corretamente (CA-2.1)', () {
    // CA-2.1 Dado leite 1L a R$ 4,29 e leite 200ml a R$ 1,20,
    // when compared, then normalized is R$ 4.29/L and R$ 6.00/L
    // and 1L is indicated as cheaper.
    final result = useCase([
      PackageInput(
        id: 'A',
        price: Money(429), // R$ 4,29
        quantity: Quantity(1000, Unit.l), // 1 L
      ),
      PackageInput(
        id: 'B',
        price: Money(120), // R$ 1,20
        quantity: Quantity(200000, Unit.ml), // 200 ml
      ),
    ]);

    expect(result.isOk, isTrue);
    final packages = result.valueOrNull!;
    expect(packages.length, 2);

    final pkgA = packages[0];
    expect(pkgA.id, 'A');
    expect(pkgA.normalizedPrice, Money(429));
    expect(pkgA.normalizedUnit, Unit.l);
    expect(pkgA.isCheapest, isTrue);

    final pkgB = packages[1];
    expect(pkgB.id, 'B');
    expect(pkgB.normalizedPrice, Money(600)); // R$ 6,00
    expect(pkgB.normalizedUnit, Unit.l);
    expect(pkgB.isCheapest, isFalse);
  });

  test('must not compare different dimensions like rice(kg) and milk(L) (CA-2.2, RN-054)', () {
    // CA-2.2 Given rice (kg) and milk (L), when user attempts to compare,
    // comparison is not offered.
    final result = useCase([
      PackageInput(
        id: 'A',
        price: Money(500),
        quantity: Quantity(1000, Unit.kg),
      ),
      PackageInput(
        id: 'B',
        price: Money(400),
        quantity: Quantity(1000, Unit.l),
      ),
    ]);

    expect(result.isErr, isTrue);
    expect(result.failureOrNull, isA<ValidationFailure>());
  });

  test('deve retornar vazio se lista for vazia', () {
    final result = useCase([]);
    expect(result.isOk, isTrue);
    expect(result.valueOrNull, isEmpty);
  });

  test('deve tratar empates corretamente', () {
    final result = useCase([
      PackageInput(
        id: 'A',
        price: Money(1000),
        quantity: Quantity(1000, Unit.kg), // 1 kg
      ),
      PackageInput(
        id: 'B',
        price: Money(500),
        quantity: Quantity(500000, Unit.g), // 500 g -> R$ 10,00/kg
      ),
    ]);

    expect(result.isOk, isTrue);
    final packages = result.valueOrNull!;
    expect(packages[0].isCheapest, isTrue);
    expect(packages[1].isCheapest, isTrue);
  });
}
