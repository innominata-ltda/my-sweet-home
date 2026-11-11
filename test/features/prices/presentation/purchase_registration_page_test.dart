import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/store_list_provider.dart';
import 'package:my_sweet_home/features/prices/presentation/purchase_registration_page.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';

void main() {
  testWidgets('Renders PurchaseRegistrationPage correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PurchaseRegistrationPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(PurchaseRegistrationPage), findsOneWidget);
    expect(find.text('Nova Compra'), findsOneWidget);
  });

  testWidgets(
    'Renders long store name in store selector without overflow (T-B04)',
    (tester) async {
      final longNameStore = Store(
        id: 'store_long',
        name: 'Supermercado e Hipermercado Integrado de Alimentos e Bebidas do Brasil Ltda',
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storeListProvider.overrideWith(
              (ref) => Future.value([longNameStore]),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PurchaseRegistrationPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap dropdown to open it
      await tester.tap(find.byType(DropdownButtonFormField<Store>));
      await tester.pumpAndSettle();

      // Verify DropdownMenuItem contains the store name and does not crash
      expect(find.text(longNameStore.name), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Renders draft item with product dropdown and quick add product button (T-B03/T-B07)',
    (tester) async {
      final testProduct = Product(
        id: 'prod_1',
        canonicalName: 'Café Torrado 500g',
        categoryId: 'cat_food',
        defaultUnit: Unit.un,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productListProvider.overrideWith(
              (ref) => Future.value([testProduct]),
            ),
            storeListProvider.overrideWith(
              (ref) => Future.value([
                Store(
                  id: 's1',
                  name: 'Mercado',
                  createdAt: DateTime.utc(2026, 1, 1),
                  updatedAt: DateTime.utc(2026, 1, 1),
                ),
              ]),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: PurchaseRegistrationPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap "Adicionar Item"
      await tester.tap(find.text('Adicionar Item'));
      await tester.pumpAndSettle();

      // Verify product dropdown and quick add product button tooltip exist
      expect(find.byTooltip('Novo produto'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Tap "Novo produto" and verify dialog opens
      await tester.tap(find.byTooltip('Novo produto'));
      await tester.pumpAndSettle();

      expect(find.text('Novo Produto'), findsOneWidget);
      expect(find.textContaining('Nome Canônico'), findsOneWidget);
    },
  );
}
