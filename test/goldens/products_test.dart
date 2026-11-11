import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/products_page.dart';
import 'package:my_sweet_home/features/products/presentation/product_detail_page.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_detail_provider.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';

void main() {
  testWidgets('ProductsPage golden test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productListProvider.overrideWith(
            (ref) => [
              Product(
                id: '1',
                canonicalName: 'Banana Prata',
                categoryId: 'frutas',
                defaultUnit: Unit.kg,
                createdAt: DateTime(2026),
                updatedAt: DateTime(2026),
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProductsPage),
      matchesGoldenFile('products_page.png'),
    );
  });

  testWidgets('ProductDetailPage golden test', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productDetailProvider('1').overrideWith(
            (ref) => Product(
              id: '1',
              canonicalName: 'Banana Prata',
              categoryId: 'frutas',
              defaultUnit: Unit.kg,
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ),
          productAliasesProvider('1').overrideWith(
            (ref) => [
              ProductAlias(
                id: 'a1',
                productId: '1',
                alias: 'Banana Nanica',
                normalizedAlias: 'banana nanica',
                source: AliasSource.user,
                createdAt: DateTime(2026),
              ),
            ],
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ProductDetailPage(productId: '1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProductDetailPage),
      matchesGoldenFile('product_detail_page.png'),
    );
  });
}
