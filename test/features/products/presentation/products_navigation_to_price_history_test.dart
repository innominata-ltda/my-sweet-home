import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/product_detail_page.dart';
import 'package:my_sweet_home/features/products/presentation/products_page.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_detail_provider.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';

void main() {
  final testProduct = Product(
    id: 'prod_1',
    canonicalName: 'Leite Integral 1L',
    categoryId: 'cat_dairy',
    defaultUnit: Unit.l,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 1),
  );

  testWidgets(
    'ProductsPage possui ação de acompanhar preços que navega com productId',
    (tester) async {
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: '/produtos',
        routes: [
          GoRoute(
            path: '/produtos',
            builder: (context, state) => const ProductsPage(),
          ),
          GoRoute(
            path: '/compras/historico-precos',
            builder: (context, state) {
              navigatedRoute = state.uri.toString();
              return const Scaffold(body: Text('Tela Historico de Precos'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productListProvider.overrideWith(
              (ref) => Future.value([testProduct]),
            ),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Leite Integral 1L'), findsOneWidget);
      final priceButton = find.byTooltip('Acompanhar preços');
      expect(priceButton, findsOneWidget);

      await tester.tap(priceButton);
      await tester.pumpAndSettle();

      expect(navigatedRoute, '/compras/historico-precos?productId=prod_1');
      expect(find.text('Tela Historico de Precos'), findsOneWidget);
    },
  );

  testWidgets(
    'ProductDetailPage possui botão de acompanhar preços na AppBar e no corpo',
    (tester) async {
      String? navigatedRoute;

      final router = GoRouter(
        initialLocation: '/produtos/prod_1',
        routes: [
          GoRoute(
            path: '/produtos/:id',
            builder: (context, state) =>
                ProductDetailPage(productId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/compras/historico-precos',
            builder: (context, state) {
              navigatedRoute = state.uri.toString();
              return const Scaffold(body: Text('Tela Historico de Precos'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProvider('prod_1')
                .overrideWith((ref) => Future.value(testProduct)),
            productAliasesProvider('prod_1')
                .overrideWith((ref) => Future.value([])),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Leite Integral 1L'), findsOneWidget);
      expect(find.text('Acompanhar histórico de preços'), findsOneWidget);

      // Click body button
      await tester.tap(find.text('Acompanhar histórico de preços'));
      await tester.pumpAndSettle();

      expect(navigatedRoute, '/compras/historico-precos?productId=prod_1');
      expect(find.text('Tela Historico de Precos'), findsOneWidget);
    },
  );
}
