import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';

void main() {
  group('PurchaseItem', () {
    test('CA-1.1: 3 x R\$ 4,29 = R\$ 12,87', () {
      final item = PurchaseItem(
        id: '1',
        productId: 'prod1',
        quantity: const Quantity(3000, Unit.un), // 3 unidades
        unitPrice: const Money(429), // R$ 4,29
        totalPrice: const Money(1287), // R$ 12,87
      );

      expect(item.hasValidTotal, isTrue);
    });

    test(
      'CA-1.2: 0,734 kg x R\$ 39,90/kg = R\$ 29,29 (tolerância 1 centavo)',
      () {
        final item = PurchaseItem(
          id: '2',
          productId: 'prod2',
          quantity: const Quantity(734, Unit.kg), // 0,734 kg
          unitPrice: const Money(3990), // R$ 39,90/kg
          totalPrice: const Money(2929), // R$ 29,29
        );

        expect(item.hasValidTotal, isTrue);
      },
    );

    test('Detects invalid total', () {
      final item = PurchaseItem(
        id: '3',
        productId: 'prod3',
        quantity: const Quantity(2000, Unit.un), // 2 unidades
        unitPrice: const Money(500), // R$ 5,00
        totalPrice: const Money(1005), // R$ 10,05 (errado, deveria ser 10,00)
      );

      expect(item.hasValidTotal, isFalse);
    });
  });

  group('Purchase', () {
    test('CA-1.3: Total difference shows discrepancy (RN-050)', () {
      final item1 = PurchaseItem(
        id: '1',
        productId: 'prod1',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(4000), // R$ 40,00
        totalPrice: const Money(4000),
      );
      final item2 = PurchaseItem(
        id: '2',
        productId: 'prod2',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(4740), // R$ 47,40
        totalPrice: const Money(4740),
      );

      final purchase = Purchase(
        id: 'p1',
        storeId: 's1',
        date: DateTime.utc(2026, 9, 25),
        items: [item1, item2],
        totalAmount: const Money(
          9000,
        ), // R$ 90,00 informado, mas itens somam R$ 87,40
        discountAmount: Money.zero,
      );

      expect(purchase.hasDivergence, isTrue);
      expect(purchase.divergence, const Money(260)); // Divergence of R$ 2.60
      expect(purchase.expectedTotal, const Money(8740));
    });

    test('Purchase without discrepancy', () {
      final item = PurchaseItem(
        id: '1',
        productId: 'prod1',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(4000),
        totalPrice: const Money(4000),
      );

      final purchase = Purchase(
        id: 'p1',
        storeId: 's1',
        date: DateTime.utc(2026, 9, 25),
        items: [item],
        totalAmount: const Money(4000),
        discountAmount: Money.zero,
      );

      expect(purchase.hasDivergence, isFalse);
      expect(purchase.divergence, Money.zero);
    });

    test('Compra com desconto', () {
      final item = PurchaseItem(
        id: '1',
        productId: 'prod1',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(5000),
        totalPrice: const Money(5000),
      );

      final purchase = Purchase(
        id: 'p1',
        storeId: 's1',
        date: DateTime.utc(2026, 9, 25),
        items: [item],
        totalAmount: const Money(4500),
        discountAmount: const Money(500), // R$ 5,00 de desconto
      );

      expect(purchase.hasDivergence, isFalse);
      expect(purchase.expectedTotal, const Money(4500));
    });
  });
}
