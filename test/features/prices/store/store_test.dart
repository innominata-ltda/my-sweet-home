import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/features/prices/domain/store/cnpj.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';

void main() {
  group('Store entity', () {
    final now = DateTime.utc(2026, 10, 14, 12, 0);
    final cnpj = Cnpj.create('11.222.333/0001-81').valueOrNull!;

    test('creation, copyWith, equality and hashCode', () {
      final s1 = Store(
        id: 's-1',
        name: 'Supermercado Central',
        cnpj: cnpj,
        address: 'Rua das Flores, 123',
        latitude: -23.55052,
        longitude: -46.633308,
        createdAt: now,
        updatedAt: now,
      );

      final s2 = Store(
        id: 's-1',
        name: 'Supermercado Central',
        cnpj: cnpj,
        address: 'Rua das Flores, 123',
        latitude: -23.55052,
        longitude: -46.633308,
        createdAt: now,
        updatedAt: now,
      );

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));

      final sCopied = s1.copyWith(
        name: 'Supermercado Novo',
        address: 'Av. Paulista, 1000',
        latitude: -23.56,
        longitude: -46.65,
        updatedAt: now.add(const Duration(hours: 1)),
      );

      expect(sCopied.id, s1.id);
      expect(sCopied.name, 'Supermercado Novo');
      expect(sCopied.address, 'Av. Paulista, 1000');
      expect(sCopied.latitude, -23.56);
      expect(sCopied.longitude, -46.65);
      expect(sCopied == s1, isFalse);
    });
  });
}
