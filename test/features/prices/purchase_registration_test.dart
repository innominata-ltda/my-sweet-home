import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/core/result/result.dart';
import 'package:my_sweet_home/features/prices/data/prices_repository_provider.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_item.dart';
import 'package:my_sweet_home/features/prices/domain/purchase/purchase_repository.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/store_list_provider.dart';
import 'package:my_sweet_home/features/prices/presentation/purchase_registration_page.dart';
import 'package:my_sweet_home/features/prices/presentation/purchases_history_screen.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';

class _FakePurchaseRepo implements PurchaseRepository {
  List<Purchase> purchases = [];

  @override
  Future<Result<void, Failure>> save(Purchase purchase) async {
    purchases.add(purchase);
    return const Ok(null);
  }

  @override
  Future<Result<Purchase?, Failure>> findById(String id) async =>
      Ok(purchases.where((p) => p.id == id).firstOrNull);

  @override
  Future<Result<List<Purchase>, Failure>> getAll() async =>
      Ok(List.of(purchases));

  @override
  Future<Result<void, Failure>> delete(String id) async {
    purchases.removeWhere((p) => p.id == id);
    return const Ok(null);
  }

  @override
  Future<Result<void, Failure>> restore(String id) async => const Ok(null);
}

void main() {
  group('T-B08: Accessibility in manual purchases and history', () {
    testWidgets(
      'Botão salvar compra e botão remover item possuem tooltip e rótulo semântico pt-BR',
      (tester) async {
        final store = Store(
          id: 'store_1',
          name: 'Mercado Central',
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        );
        final product = Product(
          id: 'prod_1',
          canonicalName: 'Arroz 5kg',
          categoryId: 'cat_food',
          defaultUnit: Unit.kg,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 1),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              storeListProvider.overrideWith((ref) => Future.value([store])),
              productListProvider.overrideWith(
                (ref) => Future.value([product]),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('pt'),
              home: PurchaseRegistrationPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Check save purchase button on AppBar
        expect(find.byTooltip('Salvar compra'), findsOneWidget);
        expect(find.bySemanticsLabel('Salvar compra'), findsOneWidget);

        // 2. Add an item to display remove item button
        await tester.tap(find.text('Adicionar Item'));
        await tester.pumpAndSettle();

        // 3. Check remove item button on card
        expect(find.byTooltip('Remover item'), findsOneWidget);
        expect(find.bySemanticsLabel('Remover item'), findsOneWidget);
      },
    );

    testWidgets(
      'Botão excluir compra e FAB de nova compra possuem tooltip e rótulo semântico pt-BR no histórico',
      (tester) async {
        final fakeRepo = _FakePurchaseRepo();
        fakeRepo.purchases = [
          Purchase(
            id: 'p1',
            storeId: 'store_1',
            date: DateTime.utc(2026, 3, 15),
            totalAmount: const Money(3500),
            discountAmount: Money.zero,
            items: const [
              PurchaseItem(
                id: 'i1',
                productId: 'prod_1',
                rawDescription: 'Arroz 5kg',
                quantity: Quantity(5000, Unit.kg),
                unitPrice: Money(3500),
                totalPrice: Money(3500),
              ),
            ],
          ),
        ];

        await tester.pumpWidget(
          ProviderScope(
            overrides: [purchaseRepositoryProvider.overrideWithValue(fakeRepo)],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('pt'),
              home: PurchasesHistoryScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Check delete purchase button on list
        expect(find.byTooltip('Excluir compra'), findsOneWidget);
        expect(find.bySemanticsLabel('Excluir compra'), findsOneWidget);

        // 2. Verificar FAB de nova compra
        expect(find.byTooltip('Nova Compra'), findsOneWidget);
        expect(find.bySemanticsLabel('Nova Compra'), findsOneWidget);
      },
    );
  });
}
