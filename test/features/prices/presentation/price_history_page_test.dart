import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/prices/domain/price_point/price_stats.dart';
import 'package:my_sweet_home/features/prices/domain/store/store.dart';
import 'package:my_sweet_home/features/prices/presentation/price_history_page.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/price_history_provider.dart';
import 'package:my_sweet_home/features/prices/presentation/providers/store_list_provider.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';

void main() {
  final testProducts = [
    Product(
      id: 'prod_1',
      canonicalName: 'Arroz Branco 1kg',
      categoryId: 'cat_food',
      defaultUnit: Unit.kg,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
    Product(
      id: 'prod_2',
      canonicalName: 'Feijão Preto 1kg',
      categoryId: 'cat_food',
      defaultUnit: Unit.kg,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    ),
  ];

  testWidgets('Renders empty state when no products exist', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productListProvider.overrideWith((ref) => Future.value([])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PriceHistoryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Histórico de Preços'), findsOneWidget);
    expect(
      find.text('Ainda sem preços. Registre uma compra para começar.'),
      findsOneWidget,
    );
  });

  testWidgets('Renders product selector and switches active product', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productListProvider.overrideWith((ref) => Future.value(testProducts)),
          storeListProvider.overrideWith(
            (ref) => Future.value([
              Store(
                id: 's1',
                name: 'Mercado A',
                createdAt: DateTime.utc(2026, 1, 1),
                updatedAt: DateTime.utc(2026, 1, 1),
              ),
            ]),
          ),
          priceHistoryProvider.overrideWith((ref, args) => Future.value([])),
          priceStatsProvider.overrideWith(
            (ref, id) => Future.value(
              const PriceStats(
                observationsCount: 1,
                averagePrice: Money(500),
                windowDays: 30,
              ),
            ),
          ),
          cheapestStoresProvider.overrideWith((ref, id) => Future.value([])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PriceHistoryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pesquisar produto'), findsOneWidget);
    expect(find.text('Arroz Branco 1kg'), findsOneWidget);

    // Search and select second product via autocomplete
    await tester.enterText(find.byType(TextFormField), 'Feijão');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Feijão Preto 1kg').last);
    await tester.pumpAndSettle();

    expect(find.text('Feijão Preto 1kg'), findsOneWidget);
  });

  testWidgets('Renders product selector with pre-selected productId', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productListProvider.overrideWith((ref) => Future.value(testProducts)),
          storeListProvider.overrideWith((ref) => Future.value([])),
          priceHistoryProvider.overrideWith((ref, args) => Future.value([])),
          priceStatsProvider.overrideWith(
            (ref, id) => Future.value(
              const PriceStats(
                observationsCount: 1,
                averagePrice: Money(650),
                windowDays: 30,
              ),
            ),
          ),
          cheapestStoresProvider.overrideWith((ref, id) => Future.value([])),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: PriceHistoryPage(productId: 'prod_2'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Feijão Preto 1kg'), findsOneWidget);
  });
}
