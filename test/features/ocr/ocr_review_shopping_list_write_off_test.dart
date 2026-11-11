import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_sweet_home/app/l10n/app_localizations.dart';
import 'package:my_sweet_home/core/money/money.dart';
import 'package:my_sweet_home/core/quantity/quantity.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/models/receipt_item_draft.dart';
import 'package:my_sweet_home/features/ocr/domain/save_receipt_use_case.dart';
import 'package:my_sweet_home/features/ocr/presentation/ocr_review_screen.dart';
import 'package:my_sweet_home/features/products/domain/matcher.dart';
import 'package:my_sweet_home/features/products/domain/product.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_item.dart';
import 'package:my_sweet_home/features/shopping/domain/models/shopping_list.dart';

void main() {
  final sampleProduct = Product(
    id: 'prod-1',
    canonicalName: 'Arroz 5kg',
    categoryId: 'alimentos',
    defaultUnit: Unit.kg,
    createdAt: DateTime(2026, 9, 21),
    updatedAt: DateTime(2026, 9, 21),
  );

  final sampleDraft = ReceiptDraft(
    store: const StoreDraft(name: 'Mercado Teste'),
    purchasedAt: DateTime(2026, 9, 21, 14, 30),
    items: [
      ReceiptItemDraft(
        rawDescription: 'ARROZ 5KG',
        quantity: const Quantity(1000, Unit.un),
        unitPrice: const Money(2500),
        totalPrice: const Money(2500),
        confidence: 0.95,
        selected: true,
        match: ProductMatch(
          product: sampleProduct,
          origin: const ExactSeedAlias(),
          score: 1.0,
        ),
      ),
    ],
    total: const Money(2500),
    confidence: 0.95,
  );

  final activeList = ShoppingList(
    id: 'list-1',
    name: 'Mercado Semanal',
    createdAt: DateTime(2026, 9, 20),
    items: const [
      ShoppingItem(
        id: 's-item-1',
        rawText: 'Arroz',
        parsedName: 'Arroz 5kg',
        productId: 'prod-1',
      ),
    ],
  );

  testWidgets(
    'T-19 (RN-201, RN-087) — Oferece baixa na lista de compras ativa e envia writeOffShoppingListId quando aceito',
    (tester) async {
      SaveOptions? capturedOptions;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(
            draft: sampleDraft,
            availableShoppingLists: [activeList],
            onSaveWithOptions: (_, options) => capturedOptions = options,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pumpAndSettle();

      // Deve abrir o dialog oferecendo baixa na lista de compras
      expect(find.text('Baixar itens da lista de compras'), findsOneWidget);
      expect(
        find.text(
          'Deseja dar baixa nos itens desta compra na lista de compras "Mercado Semanal"?',
        ),
        findsOneWidget,
      );

      // Toca em "Sim, dar baixa"
      await tester.tap(find.text('Sim, dar baixa'));
      await tester.pumpAndSettle();

      expect(capturedOptions, isNotNull);
      expect(capturedOptions?.writeOffShoppingListId, equals('list-1'));
    },
  );

  testWidgets(
    'T-19 (RN-201, RN-087) — Permite recusar a baixa na lista de compras e salvar sem dar baixa',
    (tester) async {
      SaveOptions? capturedOptions;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: OcrReviewScreen(
            draft: sampleDraft,
            availableShoppingLists: [activeList],
            onSaveWithOptions: (_, options) => capturedOptions = options,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Save button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Salvar'));
      await tester.pumpAndSettle();

      expect(find.text('Baixar itens da lista de compras'), findsOneWidget);

      // Tap "No"
      await tester.tap(find.text('Não'));
      await tester.pumpAndSettle();

      expect(capturedOptions, isNotNull);
      expect(capturedOptions?.writeOffShoppingListId, isNull);
    },
  );
}
