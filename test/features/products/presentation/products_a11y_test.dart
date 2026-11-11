import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/data/database/database.dart' hide Product;
import 'package:my_sweet_home/features/products/data/product_dao.dart';
import 'package:my_sweet_home/features/products/data/product_repository_provider.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/products/presentation/product_detail_page.dart';
import 'package:my_sweet_home/features/products/presentation/products_page.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_detail_provider.dart';
import 'package:my_sweet_home/features/products/presentation/providers/product_list_provider.dart';
import 'package:my_sweet_home/features/products/presentation/widgets/product_suggestion_dialog.dart';
import 'package:my_sweet_home/design_system/components/app_error_state.dart';
import 'package:my_sweet_home/design_system/components/app_loading.dart';

import '../../../fakes/fake_clock.dart';
import '../../../fakes/sequential_id_generator.dart';

void main() {
  testWidgets(
    'Acessibilidade do diálogo de sugestão e dos chips (A11Y-2, A11Y-3)',
    (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productDetailProvider('1').overrideWith(
              (ref) => Product(
                id: '1',
                canonicalName: 'Mandioca',
                categoryId: 'hortifruti',
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
                  alias: 'Macaxeira',
                  normalizedAlias: 'macaxeira',
                  source: AliasSource.user,
                  createdAt: DateTime(2026),
                ),
              ],
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('pt'),
            home: ProductDetailPage(productId: '1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verificar A11Y-2 e A11Y-3 nos chips de apelido
      final exception = tester.takeException();
      expect(exception, isNull);

      // O InputChip tem um delete button internamente
      final chipFinder = find.byType(InputChip);
      expect(chipFinder, findsOneWidget);

      // Verify semantic label of delete button (A11Y-3)
      // l10n.productRemoveAliasA11y('Macaxeira') => 'Remover apelido Macaxeira'
      final tooltipFinder = find.byTooltip('Remover apelido Macaxeira');
      expect(tooltipFinder, findsOneWidget);

      // Verify touch targets on page (A11Y-2)
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      // 2. Verify suggestion dialog
      await tester.pumpWidget(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('pt'),
          home: Scaffold(
            body: ProductSuggestionDialog(
              productName: 'Mandioca',
              alias: 'Macaxeira',
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Dialog must have two buttons with explicit semantic labels
      final yesSemantics = tester.getSemantics(
        find.bySemanticsLabel('Sim, Macaxeira é o mesmo que Mandioca'),
      );
      expect(yesSemantics.label, 'Sim, Macaxeira é o mesmo que Mandioca');

      final noSemantics = tester.getSemantics(
        find.bySemanticsLabel('Não, são coisas diferentes'),
      );
      expect(noSemantics.label, 'Não, são coisas diferentes');

      // Both buttons have same visual weight (OutlinedButton) - verified by typing here
      expect(find.byType(OutlinedButton), findsNWidgets(2));

      // Verify touch targets in dialog (A11Y-2)
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));

      handle.dispose();
    },
  );

  testWidgets(
    'Selecionar sinônimo como nome padrão de exibição (RN-035) atualiza canonicalName e mantém histórico/apelidos',
    (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final clock = FakeClock(DateTime.utc(2026, 10, 17, 12, 0));
      final idGen = SequentialIdGenerator();
      final dao = ProductDao(db, idGen, clock);

      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_hortifruti',
              name: 'Hortifruti',
              kind: 'product',
              iconKey: 'eco',
            ),
          );

      final createRes = await dao.create(
        const NewProduct(
          canonicalName: 'Mandioca',
          categoryId: 'cat_hortifruti',
          defaultUnit: Unit.kg,
        ),
      );
      final product = createRes.valueOrNull!;
      await dao.addAlias(product.id, 'Macaxeira', AliasSource.seed);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [productRepositoryProvider.overrideWithValue(dao)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('pt'),
            home: ProductDetailPage(productId: product.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Before click, header displays "Mandioca"
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text('Mandioca'),
        ),
        findsWidgets,
      );

      // Tap "Macaxeira" chip to make it default name
      await tester.tap(find.widgetWithText(InputChip, 'Macaxeira'));
      await tester.pumpAndSettle();

      // Verify default name is now "Macaxeira" and searching for "mandioca" returns "Macaxeira"
      final searchByOldAlias = await dao.search('mandioca');
      expect(searchByOldAlias.valueOrNull, hasLength(1));
      expect(searchByOldAlias.valueOrNull!.first.canonicalName, 'Macaxeira');
    },
  );

  testWidgets(
    'Separar apelido como outro produto (RN-036) cria produto independente, migra histórico de preços e registra negação',
    (tester) async {
      final db = AppDatabase.memory();
      addTearDown(db.close);
      final clock = FakeClock(DateTime.utc(2026, 10, 17, 12, 0));
      final idGen = SequentialIdGenerator();
      final dao = ProductDao(db, idGen, clock);

      await db
          .into(db.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'cat_hortifruti',
              name: 'Hortifruti',
              kind: 'product',
              iconKey: 'eco',
            ),
          );

      final createRes = await dao.create(
        const NewProduct(
          canonicalName: 'Banana Prata',
          categoryId: 'cat_hortifruti',
          defaultUnit: Unit.kg,
        ),
      );
      final bananaPrata = createRes.valueOrNull!;
      await dao.addAlias(bananaPrata.id, 'Banana Nanica', AliasSource.seed);

      // Simulate purchase and price point recorded as "BANANA NANICA 1KG"
      await db
          .into(db.purchases)
          .insert(
            PurchasesCompanion.insert(
              id: 'pur-1',
              purchasedAt: '2026-10-17T10:00:00.000Z',
              totalCents: 699,
              source: 'ocr',
            ),
          );
      await db
          .into(db.purchaseItems)
          .insert(
            PurchaseItemsCompanion.insert(
              id: 'item-nanica',
              purchaseId: 'pur-1',
              productId: Value(bananaPrata.id),
              rawDescription: 'BANANA NANICA 1KG',
              quantityMilli: 1000,
              unit: 'kg',
              unitPriceCents: 699,
              totalPriceCents: 699,
              position: 1,
            ),
          );
      await db
          .into(db.pricePoints)
          .insert(
            PricePointsCompanion.insert(
              id: 'pp-nanica',
              productId: Value(bananaPrata.id),
              observedAt: '2026-10-17T10:00:00.000Z',
              unitPriceCents: 699,
              normalizedPriceCents: 699,
              quantityMilli: 1000,
              unit: 'kg',
              purchaseItemId: const Value('item-nanica'),
              source: 'ocr',
            ),
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [productRepositoryProvider.overrideWithValue(dao)],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('pt'),
            home: ProductDetailPage(productId: bananaPrata.id),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap action/removal button of "Banana Nanica" chip
      await tester.tap(find.byTooltip('Remover apelido Banana Nanica'));
      await tester.pumpAndSettle();

      // Escolher "Separar como outro produto"
      expect(find.text('Separar como outro produto'), findsOneWidget);
      await tester.tap(find.text('Separar como outro produto'));
      await tester.pumpAndSettle();

      // Verificar que agora existem 2 produtos independentes ("Banana Prata" e "Banana Nanica")
      final searchNanica = await dao.search('banana nanica');
      expect(searchNanica.valueOrNull, hasLength(1));
      final bananaNanica = searchNanica.valueOrNull!.first;
      expect(bananaNanica.id, isNot(bananaPrata.id));
      expect(bananaNanica.canonicalName, 'Banana Nanica');

      // Verify price point of "BANANA NANICA 1KG" migrated to new product
      final pricePoint = await (db.select(
        db.pricePoints,
      )..where((tbl) => tbl.id.equals('pp-nanica'))).getSingle();
      expect(pricePoint.productId, bananaNanica.id);

      // Verify denial was registered in original product (RN-028, RN-036)
      final denials = await db.select(db.productDenials).get();
      expect(
        denials.any(
          (d) =>
              d.productId == bananaPrata.id &&
              d.normalizedText == 'banana nanica',
        ),
        isTrue,
      );
    },
  );

  group(
    'T-B04: ProductsPage acessibilidade e estados oficiais do Design System',
    () {
      testWidgets('FAB has tooltip and semantic label', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [productListProvider.overrideWith((ref) async => [])],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('pt'),
              home: ProductsPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Novo Produto'), findsOneWidget);
        expect(find.bySemanticsLabel('Novo Produto'), findsOneWidget);
      });

      testWidgets('Exibe AppLoading no estado de carregamento', (tester) async {
        final completer = Completer<List<Product>>();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productListProvider.overrideWith((ref) => completer.future),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('pt'),
              home: ProductsPage(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(AppLoading), findsOneWidget);
      });

      testWidgets('Exibe AppErrorState no estado de erro', (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              productListProvider.overrideWithValue(
                AsyncError(Exception('falha'), StackTrace.empty),
              ),
            ],
            child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: Locale('pt'),
              home: ProductsPage(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(AppErrorState), findsOneWidget);
        expect(find.text('Erro ao carregar produtos.'), findsOneWidget);
      });
    },
  );
}
